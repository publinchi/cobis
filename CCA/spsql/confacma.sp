/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                confacma.sp                             */
/*      Procedimiento:          sp_consulta_fac_masivos                 */
/*      Disenado por:           Juan Bernardo Quinche                   */
/*      Fecha de escritura:     19 de Mayo de 2008                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Consulta la informacion  para generar el archivo de recaudos    */
/*               plano por convenios, siguiendo parametros              */
/*      Realiza el la validacion del archivo de recaudos recibido y     */
/*              actualiza la cartera invocando el proceso de cartera    */
/************************************************************************/
/*      operaciones: I - retorna informacion de                         */
/*                   Q - Consulta, creando el archivo del plano y los   */
/*                   R - Retorna los resultados                         */
/*                   M - Mantenimiento limpia las tablas si existen     */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR          RAZON                                    */
/*  DIC.2015    Elcira Pelaez  NR.556 BANCAMIA-Ajuste fecha encabezado  */
/************************************************************************/

use cob_cartera 
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'sp_consulta_fac_masivos')
   drop proc sp_consulta_fac_masivos
go


create procedure sp_consulta_fac_masivos
   @i_oficina        int          =  null,
   @t_trn            char         =  null,
   @t_debug          char         =  'N',
   @i_linea          catalogo     =  null,
   @i_formato_fecha  int          =  103,
   @i_operacion      char         =  'Q' ,
   @i_reg_ini        int          =  0,
   @i_convenio       int          =  1,
   @i_fecha_proc     datetime     =  null,
   @i_en_linea       char(1)      =  'S',
   @i_ubicacion      varchar(64)  =  null
as 

declare 
   @w_error             int,
   @w_sp_name           descripcion,
   @w_tipo_cobro        char,
   @w_cobra_iva         char,
   @w_costo_recaudo     money,
   @w_porc_recaudo      money,
   @w_tipo_iva          descripcion,
   @w_delimit           char,
   @w_anchofijo         char,
   @w_reg_totales       int,
   @w_nit_bancamia      varchar(30),
   @w_suma_pagos        money,
   @w_suma_serv         money,
   @w_fecha_str         varchar(10),
   @w_fecha_str2        varchar(10),
   @w_msg               varchar(255),
   @w_fecha_proceso     datetime,
   @w_siguiente_dia     datetime,
   @w_ciudad_nacional   int,
   @w_pos               int,
   @w_banco             cuenta,
   @w_fecha_error       datetime,
   @w_fecha_proc        datetime,
   @w_sp_name_batch     varchar(30),
   @w_s_app             varchar(30),
   @w_path              varchar(255),
   @w_fecha_arch        varchar(10),
   @w_comando           varchar(1000),
   @w_nombre_plano      varchar(200),
   @w_nombre_pie        varchar(200),
   @w_nombre_planoPie   varchar(200),
   @w_plano_errores     varchar(200),
   @w_plano_erroresPie  varchar(200),
   @w_cmd               varchar(300),
   @w_dia               varchar(2),
   @w_mes               varchar(2),
   @w_anio              varchar(4),
   @w_pie_archivo       varchar(400),
   @w_sig_dia_reporte   datetime,
   @w_siguiente_diar    datetime

if isnull(@i_operacion,'x') not in ('R','Q','O') return 0

--- EL CODIGO DEL CONVENIO ES OBLIGATORIO
if @i_convenio is null  begin
   select @w_error = 70001, 
          @w_msg = 'Es necesario el codigo del convenio'
   goto ERROR
end


--- RETORNO DE REGISTROS GENERADOS EN EL HISTORICO 
if @i_operacion = 'R' begin
   select
   fh_banco,
   convert(varchar,fh_fecha_ven, @i_formato_fecha),
   fh_cedula,
   fh_valor,
   fh_valor_recaudo
   from  ca_facturacion_recaudos_his
   where fh_codigo= @i_convenio
   and   fh_fecha = @w_fecha_proceso
   
   return 0
   
end   --- operacion ='R' 

---SE CONSIDERA COMO FECHA DE PROCESO LA DE CIERRE DE CARTERA
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_fecha_error = @w_fecha_proceso

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
if @@rowcount = 0 begin
   select @w_error = 101024
   goto ERROR
end
 
exec @w_error = sp_dia_habil 
@i_fecha  = @w_fecha_proceso,
@i_ciudad = @w_ciudad_nacional,
@o_fecha  = @w_siguiente_dia out

if @w_error <>0 goto ERROR

select @w_fecha_proceso = @w_siguiente_dia

---SACAR LA FECHA DEL SIGUINTE DIA HABIL PARA LA CABECERA DEL REPORTE
select @w_siguiente_diar =  dateadd(dd,1,@w_siguiente_dia)

exec @w_error = sp_dia_habil 
@i_fecha  = @w_siguiente_diar,
@i_ciudad = @w_ciudad_nacional,
@o_fecha  = @w_sig_dia_reporte out

if @w_error <>0 goto ERROR

--- VARIABLES DE TRABAJO 
select 
@w_sp_name      = 'sp_consulta_fac_masivos',
@w_error        = 0,
@w_fecha_str    = substring( convert(varchar,@w_sig_dia_reporte,112),1,10),
@w_fecha_str2   = substring( convert(varchar,(DATEADD(day, 1, @w_fecha_proceso)),112),1,10), 
@i_oficina      = case @i_operacion when 'Q' then null else @i_oficina end

select @w_nit_bancamia = fi_ruc
from cobis..cl_filial
where fi_filial = 1

select @w_nit_bancamia = '9002150711'

select 
@w_tipo_cobro    = cr_tipo_cobro,
@w_costo_recaudo = case cr_tipo_cobro when 'V' then cr_valor else 0 end,
@w_cobra_iva     = cr_cobra_iva,
@w_tipo_iva      = cr_tipo_iva,
@w_delimit       = cr_delimit,
@w_anchofijo     = cr_anchofijo
from  ca_convenio_recaudo
where cr_codigo= @i_convenio

if @@rowcount=0 begin
   select @w_error=710580, @w_msg = 'NO SE ENCUENTRA EL CONVENIO EN LA TABLA ca_convenio_recaudo'
   goto ERROR
end

truncate table ca_temp_conv_baloto

--- REPORTAR LOS PRESTAMOS CON CUOTAS VENCIDAS O VIGENTES EN LA FECHA DE VENCIMIENTO 
insert into ca_temp_conv_baloto
select 
rep_banco      = op_banco,
rep_cliente    = op_cliente,
rep_sector     = op_sector,
rep_opera      = op_operacion,
rep_cedula     = 'SIN_DATO',
rep_nom        = isnull(op_nombre,''),
rep_ofi        = op_oficina,
rep_cuota      = min(di_dividendo),
rep_valor_rec  = 0,
rep_valor_iva  = 0,
fech_ini       = @w_fecha_proceso,
fech_venc      = min(di_fecha_ven),
rep_valor      = sum(am_cuota + am_gracia - am_pagado) + @w_costo_recaudo,
rep_convenio   = @i_convenio
from ca_operacion, ca_dividendo, ca_amortizacion
where op_estado    in (1,2)
and   op_naturaleza = 'A'
and  (di_estado     = 2  or (di_estado = 1 and di_fecha_ven = @w_fecha_proceso))
and   op_oficina    = isnull(@i_oficina, op_oficina) 
and   op_operacion  = di_operacion
and   op_operacion  = am_operacion
and   di_dividendo  = am_dividendo
and   op_migrada is null
group by op_banco, op_cliente, op_sector, op_operacion, isnull(op_nombre,''), op_oficina


if @@error <> 0 begin
   select @w_error=710001, @w_msg = 'ERROR AL GENERAR TABLA TEMPORAL CON DATOS DEL CONVENIO'
   goto ERROR
end

---DETERMINAR PRESTAMOS SIN CUOTAS VENCIDAS 
select  op_banco, op_cliente, op_sector,op_operacion, op_nombre, op_oficina 
into #operaciones
from ca_operacion
where op_estado    in (1,2)
and   op_naturaleza = 'A'
and   op_migrada is null
and   op_oficina    = isnull(@i_oficina, op_oficina) 


delete #operaciones
from ca_temp_conv_baloto, #operaciones o
where o.op_operacion = rep_opera

--- INSERTAR LA CUOTA VIGENTE DE LOS PRESTAMO NO REPORTADOS EN LA CONSULTA ANTERIOR 
insert into ca_temp_conv_baloto
select 
rep_banco      = op_banco,
rep_cliente    = op_cliente,
rep_sector     = op_sector,
rep_opera      = op_operacion,
rep_cedula     = 'SIN_DATO',
rep_nom        = isnull(op_nombre,''),
rep_ofi        = op_oficina,
rep_cuota      = min(di_dividendo),
rep_valor_rec  = 0,
rep_valor_iva  = 0,
fech_ini       = @w_fecha_proceso,
fech_venc      = min(di_fecha_ven),
rep_valor      = sum(am_cuota + am_gracia - am_pagado) + @w_costo_recaudo,
rep_convenio   = @i_convenio
from #operaciones , ca_dividendo, ca_amortizacion
where di_estado     = 1
and   op_operacion  = di_operacion
and   op_operacion  = am_operacion
and   di_dividendo  = am_dividendo
group by op_banco, op_cliente, op_sector, op_operacion, isnull(op_nombre,''), op_oficina


if @@error <> 0 begin
   select @w_error=710001, @w_msg = 'ERROR AL GENERAR TABLA TEMPORAL CON DATOS DEL CONVENIO'
   goto ERROR
end

--- DETERMINAR LA CEDULA DE LOS CLIENTES 
update ca_temp_conv_baloto set
rep_cedula = en_ced_ruc
from cobis..cl_ente
where en_ente = rep_cliente

if @@error <> 0 begin
   select @w_error=710002, @w_msg = 'ERROR AL DETERMINAR LA CEDULA DEL CLIENTE'
   goto ERROR
end
                   
if @w_cobra_iva = 'S' begin

   ---DETERMINAR EL VALOR DE IVA A COBRAR
   update ca_temp_conv_baloto set
   rep_valor_iva = rep_valor_rec * vd_valor_default
   from ca_valor_det
   where  vd_sector = rep_sector
   and    vd_tipo   = @w_tipo_iva
   
   if @@error <> 0 begin
      select @w_error=710002, @w_msg = 'ERROR DETERMINAR EL VALOR DE IVA A COBRAR'
      goto ERROR
   end
   
end

--- INGRESAR BORRANDO LAS TABLAS CON LOS DATOS A GENERAR
truncate table temp_planos

if @@error <> 0 begin
   select @w_error=710003, @w_msg = 'ERROR AL TRUNCAR TABLA temp_planos'
   goto ERROR
end

--- BORRAR HISTORICO DE REGISTROS GENERADOS 
delete cob_cartera..ca_facturacion_recaudos_his
where fh_fecha = @w_fecha_proceso
and   fh_codigo= @i_convenio

if @@error <> 0 begin
   select @w_error=710003, @w_msg = 'ERROR AL BORRAR REGISTROS DEL HISTRICO ca_facturacion_recaudos_his'
   goto ERROR
end

truncate table ca_planos_baloto

--- GENERAR CABECERA DEL ARCHIVO

insert into temp_planos
select 
dbo.cadena_zeros('1',2) +
dbo.cadena_zeros(@w_nit_bancamia,13) +
@w_fecha_str2 +
@w_fecha_str +   
@w_fecha_str2 +
dbo.cadena_zeros('0',3)+   
replicate(' ',42)

if @@error <> 0 begin
   select @w_error = 710227, @w_msg = 'ERROR AL GENERAR LA CABECERA DEL ARCHIVO DE CONVENIO'
   goto ERROR
end

--- GENERAR CUERPO DEL ARCHIVO 

insert into ca_facturacion_recaudos_his(
fh_codigo,        fh_fecha,           fh_banco,       
fh_operacion,     fh_valor,           fh_valor_recaudo,  
fh_iva_recaudo,   fh_fecha_ven,       fh_cedula,      
fh_dividendo )
select
rep_conv,         fech_ini,           rep_banco,      
rep_opera,        rep_valor,          rep_valor_rec,     
rep_valor_iva,    fech_venc,          substring(rep_cedula,1,14),     
rep_cuota
from ca_temp_conv_baloto
where rep_valor > 0

if @@error <> 0 begin
   select @w_error = 710230, @w_msg = 'ERROR AL GENERAR HISTORICO DE REGISTROS A ENVIAR ca_facturacion_recaudos_his'
   goto ERROR
end

insert into temp_planos
select
dbo.cadena_zeros('2',2) +
dbo.cadena_zeros(rep_cedula, 21) +
dbo.cadena_zeros(rep_banco,  14) +
dbo.cadena_zeros(9999,4) +
dbo.cadena_zeros(convert(varchar,cast(round(rep_valor,    0) as int)), 13) +
dbo.cadena_zeros(convert(varchar,cast(round(rep_valor_rec,0) as int)), 13) +
dbo.cadena_zeros(convert(varchar,cast(round(rep_valor_iva,0) as int)), 13) +
replicate(' ',4)         
from ca_temp_conv_baloto
where rep_valor > 0

if @@error <> 0 begin
   select @w_error = 710228
   goto ERROR
end

insert into temp_planos
select
dbo.cadena_zeros('2',2) +
dbo.cadena_zeros(ps_cedula, 21) +
dbo.cadena_zeros(ps_banco,  14) +
dbo.cadena_zeros(ps_oficina,4)  +
dbo.cadena_zeros(convert(varchar,cast(round(ps_valor,0) as int)), 13) +
dbo.cadena_zeros('0', 13) +
dbo.cadena_zeros('0', 13) +
replicate(' ',4)         
from ca_pagos_sicredito

if @@error <> 0 begin
   select @w_error = 710228
   goto ERROR
end

--- GENERAR PIE DEL ARCHIVO     

select 
@w_reg_totales = count(1),
@w_suma_pagos  = isnull(sum(rep_valor),0),
@w_suma_serv   = isnull(sum(rep_valor_rec + rep_valor_iva),0)
from ca_temp_conv_baloto
where rep_valor > 0

select 
@w_reg_totales = @w_reg_totales + count(1),
@w_suma_pagos  = @w_suma_pagos  + isnull(sum(isnull(ps_valor,0)), 0)
from ca_pagos_sicredito

-- DE ARCHIVO
select @w_pie_archivo  = dbo.cadena_zeros('3',2) +  dbo.cadena_zeros( convert(varchar,cast(round(@w_reg_totales,0) as int)),9 ) +
                       dbo.cadena_zeros( substring(convert(varchar,@w_suma_pagos),1,patindex('%.%',convert(varchar,@w_suma_pagos))-1),18 ) +
                       dbo.cadena_zeros( convert(varchar,cast(round(@w_suma_serv,0) as int)),18 )+   replicate(' ',37)

                       ---REORGANIZAR PLANO ANTES DE GENERAR
insert into ca_planos_baloto
select s,substring(s,1,2)
from temp_planos
if @@error <> 0 begin
   select @w_error = 710584, @w_msg = 'ERROR AL GENERAR ORGANIZADOR DE BALOTOS'
   goto ERROR
end


truncate table temp_planos
---INSERTAR ORNEDANDO POR EL CAMPO pie VALORES 01-02-03
insert into temp_planos
select s from ca_planos_baloto 
order by pie

---  GENERAR PLANO   
select @w_sp_name_batch = 'cob_cartera..sp_pagosca'
select @w_fecha_arch = convert(varchar(10), @w_fecha_proceso, 112)
select @w_anio = substring(@w_fecha_arch,1,4)
select @w_mes = substring(@w_fecha_arch,5,2)
select @w_dia = substring(@w_fecha_arch,7,2)
select @w_fecha_arch = @w_dia + @w_mes + @w_anio

--- RUTA DE DESTINO DEL ARCHIVO A GENERAR 
select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente = @w_sp_name_batch

if @@rowcount = 0 begin
   select @w_error = 2101084, @w_msg = 'ERROR EN LA BUSQUEDA DEL PATH EN LA TABLA ba_batch'
   goto ERROR
end

--- OBTENIENDO EL PARAMETRO DE LA UBIACION DEL kernel\bin EN EL SERVIDOR
select @w_s_app   = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

if @@rowcount = 0 begin
   select @w_error = 2101084, @w_msg = 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
   goto ERROR
end
---waitfor delay '00:00:10'
select
@w_nombre_plano  = @w_path + 'CMM_GTECHINV_'+@w_fecha_arch+'.txt',
@w_plano_errores = @w_path + 'CMM_GTECHINV_'+@w_fecha_arch+'.err',
@w_cmd           = @w_s_app + 's_app bcp -auto -login cob_cartera..temp_planos out ',
@w_comando  = @w_cmd + @w_path + 'PIE.TXT' + ' -b5000 -c -e' + @w_plano_errores + ' -t' + '"' +'|'+ '"' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
   print @w_comando
   goto ERROR
end

 
----GENERAR PLANO Y CABECERA
select @w_nombre_pie = @w_path + 'PIE.TXT'

select @w_comando = 'echo '  +  @w_pie_archivo   + ' >> '  + @w_nombre_pie

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + @w_nombre_plano
    print @w_comando
    PRINT @w_error
end

--UNIFICAR
select @w_comando = 'TYPE ' +  @w_nombre_pie  + ' >> '  +  @w_pie_archivo 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error uniendo archivos Archivo: ' + @w_nombre_plano
    print @w_comando
    PRINT @w_error
end
--Antes de renombrar el archivo, eliminar el que existe
select @w_comando  = 'del '  + @w_path + 'CMM_GTECHINV_'+@w_fecha_arch+'.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error eliminando nombre: ' + @w_nombre_pie
    print @w_comando
    PRINT @w_error
end


--Renombrar el archivo conel nombre final
select @w_comando  = 'ren ' + @w_nombre_pie + ' ' + 'CMM_GTECHINV_'+@w_fecha_arch+'.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error actualizando nombre: ' + @w_nombre_pie
    print @w_comando
    PRINT @w_error
end


return 0


ERROR:

if @i_en_linea = 'S' begin

   exec cobis..sp_cerror 
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg
   
end else begin 

   exec sp_errorlog 
   @i_fecha       = @w_fecha_error,
   @i_error       = @w_error, 
   @i_usuario     = 'OPERADOR', 
   @i_tran        = 7999,
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = '',
   @i_rollback    = 'S',
   @i_descripcion = @w_msg
   
end

return @w_error

go

