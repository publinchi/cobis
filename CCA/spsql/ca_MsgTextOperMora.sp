/***********************************************************************/
/*      Producto:                       Cartera                        */
/*      Disenado por:                   Elcira Pelaez                  */
/*      Fecha de Documentacion:         AGO-2014                       */
/*      Procedimiento                   ca_MsgTextOperMora.sp          */
/***********************************************************************/
/*                      IMPORTANTE                                     */
/*      Este programa es parte de los paquetes bancarios propiedad de  */
/*      'MACOSA',representantes exclusivos para el Ecuador de la       */
/*      AT&T                                                           */
/*      Su uso no autorizado queda expresamente prohibido asi como     */
/*      cualquier autorizacion o agregado hecho por alguno de sus      */
/*      usuario sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*      Este stored procedure genera un plano de los errores de un     */
/*      fecha dada       proceso batch 7925- CCA REPORTE DE ERRORES    */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/***********************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_MsgTextOperMora')
   drop proc sp_MsgTextOperMora
go
---SEP.08.2014
create proc sp_MsgTextOperMora (
   @i_param1 datetime  = null, --FECHA HASTA DONDE SE GENERA EL REPORTE
   @i_param2 smallint  = null, ---Mora Inicial
   @i_param3 smallint  = null  ---Mora Final
   

)
as

declare
@w_error            int,
@w_msg              varchar(250),
@w_sp_name          varchar(30),
@w_fecha_arch       varchar(10),
@w_comando          varchar(500),
@w_cmd              varchar(300),
@w_s_app            varchar(30),
@w_path_listados    varchar(250),
@w_archivo          varchar(300),
@w_batch            int,
@w_cabecera         varchar(250),
@w_fecha_proc       varchar(10),
@w_errores          varchar(250),
@w_fecha_corte      datetime,
@w_fecha_entrada    datetime

select @w_fecha_entrada = @i_param1

select @w_fecha_corte = max(do_fecha)
from cob_conta_super..sb_dato_operacion
where do_aplicativo = 7
and do_fecha <= @w_fecha_entrada 
if @@rowcount = 0
begin
   select @w_error = 1
   PRINT 'Error No hay DAtos para la fecha digitada'
   goto ERROR
end


if (@i_param2 > @i_param3) or (@i_param2 is null) or (@i_param3 is null)
begin
   PRINT 'Error en parametro dias de mora'
   select @w_error = 1
   goto ERROR
end

truncate table ca_plano_ors_959_msg_texto
truncate table ca_plano_ors_959_cabecera
  
-----INICIO
select cliente = do_codigo_cliente,do_tipo_operacion,'fec_ini_mora'=min(do_fecha_ini_mora)
into #cliente_mora_107
 from cob_conta_super..sb_dato_operacion with (nolock)
where do_aplicativo = 7
and do_fecha = @w_fecha_corte
and do_edad_mora > 0
and do_estado_cartera <> 4 ---No incluye los castigados
and do_oficina = 107
group by do_codigo_cliente,do_tipo_operacion


select do_codigo_cliente,'fecha_ini_mora'=min(do_fecha_ini_mora)
into #cliente_mora
 from cob_conta_super..sb_dato_operacion with (nolock)
where do_aplicativo = 7
and do_fecha = @w_fecha_corte
and do_edad_mora > 0
and do_estado_cartera <> 4 ---No incluye los castigados
and do_oficina <> 107
group by do_codigo_cliente

insert into #cliente_mora
select cliente,fec_ini_mora
from #cliente_mora_107

select do_codigo_cliente,
'diasMora'=datediff(dd,fecha_ini_mora,@w_fecha_corte),
'Cel1' = (select max(ltrim(rtrim(te_prefijo))+ltrim(rtrim(te_valor)))
           from cobis..cl_telefono,cobis..cl_direccion
            where te_ente = c.do_codigo_cliente
            and te_ente = di_ente
            and te_direccion in(1,2,3)
            and di_direccion = te_direccion
            and te_prefijo is not null
            and len(te_valor) = 7        
           and te_tipo_telefono = 'C'),

'Cel2'  =  (  select max(ltrim(rtrim(te_prefijo))+ltrim(rtrim(te_valor)))
              from cobis..cl_telefono,cobis..cl_direccion
              where te_ente = c.do_codigo_cliente
              and te_ente = di_ente
              and te_direccion  in (1,2,3)
              and di_direccion = te_direccion
              and te_prefijo is not null
              and len(te_valor) = 7
              and te_tipo_telefono = 'C')
into #telefonos
from #cliente_mora c

insert into  ca_plano_ors_959_msg_texto
select 
en_ente,
en_subtipo,
en_ced_ruc,
isnull(Cel1, Cel2),
Cel2,
substring(en_nombre,1,30),
substring(p_p_apellido,1,20) + ' ' + substring(p_s_apellido,1,20),
diasMora,
'Cliente Bancamia: El incumplimiento en pago de cuotas genera reporte negativo en centrales de riesgo, transcurridos 20 dias a partir del envio de este mensaje'
from #telefonos,
cobis..cl_ente with (nolock)
where en_ente = do_codigo_cliente
and diasMora between @i_param2 and @i_param3  --dias de mora digitados como parametro
and( Cel1 is not null or Cel2 is not null)

------FIN

 

---Datos Para Generar El plano
select @w_fecha_proc = convert(varchar, fp_fecha, 101)
from cobis..ba_fecha_proceso

if @@rowcount = 0 begin
   select @w_error = 2101084
   print  'ERROR AL OBTENER LA FECHA DE PROCESO'
   goto ERROR
end

select @w_fecha_arch    = substring(convert(varchar(10),@w_fecha_proc),1,2)+ substring(convert(varchar(10),@w_fecha_proc),4,2)+substring(convert(varchar(10),@w_fecha_proc),7,4)

-----------------GENERACION PLANO ----------------

insert into ca_plano_ors_959_cabecera
values ('CodCliente','TipoIdentifica','Identificacion','Celular1','Celular2','Nombres','Apellidos','NroDiaMora','Mensaje')
PRINT 'despues de insertar en la cabecera'

select @w_archivo = 'CA_MSG_TEXTO_OPERMORA_' + @w_fecha_arch 

select @w_s_app   = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

if @@rowcount = 0 begin
 print 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
 select @w_error = 2101084
 goto ERROR
end

select  @w_batch = ba_batch
from cobis..ba_batch
where ba_arch_fuente = 'cob_cartera..sp_MsgTextOperMora'

select @w_path_listados = ba_path_destino
from cobis..ba_batch
where ba_batch = @w_batch


select @w_comando  = 'ERASE ' +  @w_path_listados + @w_archivo + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + @w_archivo
    print @w_comando
	 select @w_error = 2101084
	 goto ERROR    
end


select @w_errores = @w_path_listados + @w_archivo + '.err'
select @w_cmd = @w_s_app + 's_app bcp cob_cartera..ca_plano_ors_959_cabecera out '
select @w_comando = @w_cmd + @w_path_listados + 'CABECERA.TXT' + ' -b5000 -c -e' + @w_errores + ' -t' + '"' + '\t' + '"' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 
begin
    print 'Error generando Archivo: ' + 'CABECERA.TXT'
    print @w_comando
	select @w_error = 2101084
	goto ERROR    
end

select @w_errores  = @w_path_listados + @w_archivo + '.err'
select @w_cmd      = @w_s_app + 's_app bcp cob_cartera..ca_plano_ors_959_msg_texto out '
select @w_comando  = @w_cmd + @w_path_listados + 'CUERPO.TXT' + ' -b5000 -c -e' + @w_errores + ' -t' + '"' +'\t'+ '"' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + 'CUERPO.TXT'
    print @w_comando
	select @w_error = 2101084
	goto ERROR    
end



---UNIR LOS DOS ARCHIVOS CUERPO.TXT  + CABECERA.TXT
select @w_comando = 'TYPE ' + @w_path_listados + 'CABECERA.TXT  ' + @w_path_listados + 'CUERPO.TXT >> '+ @w_path_listados + @w_archivo + '.txt'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 
begin
    print 'Error uniendo archivos Archivo: ' + @w_archivo
    select @w_error = 2101084
    goto ERROR    
end

select @w_comando  = 'ERASE ' + @w_path_listados + 'CUERPO.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'CUERPO.TXT'
    print @w_comando
    select @w_error = 2101084
   goto ERROR
end


select @w_comando  = 'ERASE ' + @w_path_listados + 'CABECERA.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'CABECERA.TXT'
    select @w_error = 2101084
    goto ERROR    
end


return 0


ERROR:
return @w_error

go


