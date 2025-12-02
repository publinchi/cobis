/***********************************************************************/
/*      Producto:                       Cartera                        */
/*      Disenado por:                   Elcira Pelaez                  */
/*      Fecha de Documentacion:         Feb-2013                       */
/*      Procedimiento                   ca_planoCanceladas.sp          */
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
/*      Este stored procedure genera un plano para las oficinas de     */
/*      Obligaciones canceladas  para unrango de fechas        de      */
/*      entrada como parametro Solicitado en BAncamia Por ORS 555      */
/*      este proceso es ejecutado por sp_planoCanceladas_Ext desde     */
/*      el proceso batch NRo. 7961                                     */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/***********************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_planoCanceladasXofi')
   drop proc sp_planoCanceladasXofi
go

create proc sp_planoCanceladasXofi (
   @i_oficina          int

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
@w_errores          varchar(250)

truncate table ca_plano_cancelads_x_ofi
   
insert into ca_plano_cancelads_x_ofi
select * from ca_canceladas_Ext_tmp
where oficina = @i_oficina

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

select @w_cabecera ='COD_OFICIN;NOMBRE_OFI;NRO_OBLIGACION;CED_CLIENTE;NOMBRE_CLIENTE'

select @w_archivo = 'CCA_CANCELADAS_' + @w_fecha_arch + '_OFI_' + convert(varchar(6),@i_oficina)

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
where ba_arch_fuente = 'cob_cartera..sp_planoCanceladas_Ext'

select @w_path_listados = ba_path_destino
from cobis..ba_batch
where ba_batch = @w_batch

select @w_comando  = 'ERASE ' + @w_path_listados + 'TITULOMZ.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'TITULOMZ.TXT'
    print @w_comando
    select @w_error = 2101084
   goto ERROR
end

select @w_comando  = 'ERASE ' +  @w_path_listados + @w_archivo + '.csv'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + @w_archivo
    print @w_comando
	 select @w_error = 2101084
	 goto ERROR    
end


select @w_errores  = @w_path_listados + @w_archivo + '.err'
select @w_cmd      = @w_s_app + 's_app bcp cob_cartera..ca_plano_cancelads_x_ofi out '
select @w_comando  = @w_cmd + @w_path_listados + 'TITULOMZ.TXT' + ' -b5000 -c -e' + @w_errores + ' -t' + '"' +';'+ '"' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + 'TITULOMZ.TXT'
    print @w_comando
	select @w_error = 2101084
	goto ERROR    
end

select @w_comando = 'echo ' +   @w_cabecera +  ' >> ' + @w_path_listados + @w_archivo + '.csv'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + @w_archivo
	select @w_error = 2101084
	goto ERROR    
end

select @w_comando = 'TYPE ' + @w_path_listados + 'TITULOMZ.TXT >> ' + @w_path_listados + @w_archivo + '.csv'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error uniendo archivos Archivo: ' + @w_archivo
    select @w_error = 2101084
    goto ERROR    
end

select @w_comando  = 'ERASE ' + @w_path_listados + 'TITULOMZ.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'TITULOMZ.TXT'
    select @w_error = 2101084
    goto ERROR    
end


return 0


ERROR:
return @w_error

go


