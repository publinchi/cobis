/************************************************************************/
/*   Archivo:              vencicuotasxml.sp                            */
/*   Stored procedure:     sp_vencimientos_cuotas_xml                    */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Fecha de escritura:   Julio 2017                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Genera archivo xml con informacion de vencimiento de cuotas para   */
/*   envio de correo de aviso de vencimiento a deudores                 */
/*                              CAMBIOS                                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_vencimientos_cuotas_xml')
   drop proc sp_vencimientos_cuotas_xml
go

create proc sp_vencimientos_cuotas_xml
(
    @s_user          login       = null,
    @s_ofi           smallint    = null,
    @s_date          datetime    = null,
    @s_term          varchar(30) = null,
    @o_msg           varchar(255) = null out
)
as 

declare 
        @w_error            int,
        @w_mensaje          varchar(150),
        @w_sql              varchar(5000),
        @w_sql_bcp          varchar(5000),
        @w_ruta_xml         varchar(255),
        @w_sp_name          varchar(30),
        @w_msg              varchar(255),
        @w_nombre_xml       VARCHAR(200)

select @w_sp_name = 'sp_vencimientos_cuotas_xml'
declare @resultadobcp table (linea varchar(max))


declare
@w_fecha_respaldo  varchar(32)

SELECT
@w_fecha_respaldo  = replace(
convert(VARCHAR, getdate(),112) +'_' + 	substring(format(getdate(), 'yyyy-MM-ddTHH:mm:ss:ms'), 12,32)
, ':', '')

SELECT @w_nombre_xml = 'vencicuotas.xml'

select @w_ruta_xml = ba_path_destino
    from cobis..ba_batch 
    where ba_batch = 7076

if (@@error != 0 or @@rowcount != 1 or isnull(@w_ruta_xml, '') = '')
begin
   select @w_error = 724623
    goto ERROR_PROCESO
end


/* SACAR RESPALDO AL ARCHIVO Y PONERLO EN LA CARPETA HISTORICA */
SELECT @w_sql_bcp = 'copy ' + @w_ruta_xml + @w_nombre_xml + ' ' + @w_ruta_xml + 'history\' +
                    substring(@w_nombre_xml,1,charindex('.', @w_nombre_xml)-1) + '_' + @w_fecha_respaldo + '.xml'

PRINT ' SQL 1 ' + @w_sql_bcp

delete from @resultadobcp
insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

/*  BORRAR EL ARCHIVO */
select	@w_sql_bcp = 'del ' + @w_ruta_xml + @w_nombre_xml
delete from @resultadobcp
insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

PRINT ' SQL 2 ' + @w_sql_bcp


IF NOT EXISTS(SELECT 1 FROM cob_cartera..ca_vencimiento_cuotas prestamo)
BEGIN
	GOTO NO_DATOS
END 


select  @w_sql = 'select prestamo.vc_cliente as clienteId, ' +
      'prestamo.vc_fecha_proceso as fecha_proceso, ' +
      'prestamo.vc_cliente_name as clienteName, ' +
      'isnull(prestamo.vc_email,' + char(39) + char(32) + char(39) + ') as mail ,' +
      'prestamo.vc_op_fecha_liq as fecha_liq, ' +
      'prestamo.vc_op_moneda as moneda, ' +
      'prestamo.vc_di_fecha_vig as fecha_vig, ' +
      'prestamo.vc_di_dividendo as dividendo, ' +
      'prestamo.vc_di_monto as monto, ' +
      'oficina.of_nombre oficinaName, ' + 
      '(select isnull(vcd_referencia, ' + char(39) + char(32) + char(39) + ') as referencia, '+
              'isnull(vcd_institucion,' + char(39) + char(32) + char(39) + ') as institucion, '+
              'isnull(vcd_convenio,' + char(39) + char(32) + char(39) + ') as nro_convenio '+
       'from cob_cartera..ca_vencimiento_cuotas_det '+
       'where vcd_operacion = vc_operacion '+
       'and vcd_cliente = vc_cliente '+
      'order by vcd_institucion asc '+
       'FOR XML PATH(' + char(39) + 'Referencia'+ char (39) + '), TYPE ) '+
      'from  cobis..cl_oficina oficina, cob_cartera..ca_vencimiento_cuotas prestamo ' +
      'where oficina.of_oficina = prestamo.vc_op_oficina  ' +
      'for XML path(' + char(39) + 'Prestamos' + char(39) + '), ' +
      'root(' + char(39) + 'VencimientosCuotas' +  char(39) + '), elements ' 


select  @w_sql_bcp = 'bcp "' + @w_sql + '" queryout "' + @w_ruta_xml + @w_nombre_xml + '" -c -r -t\t -T'

delete from @resultadobcp
insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

select * from @resultadobcp

--SELECCIONA CON %ERROR% SI NO ENCUENTRA EN EL FORMATO: ERROR = 
if @w_mensaje is null
    select top 1 @w_mensaje =  linea 
        from @resultadobcp 
        where upper(linea) LIKE upper('%Error%')

if @w_mensaje is not null
begin
    select @w_error = 724625
    goto ERROR_PROCESO
end

return 0
   
ERROR_PROCESO:
    select @w_msg = mensaje
        from cobis..cl_errores with (nolock)
        where numero = @w_error
        set transaction isolation level read uncommitted
      
   select @w_msg = isnull(@w_msg, @w_mensaje)
      
   select @o_msg = ltrim(rtrim(@w_msg))
   select @o_msg
   return @w_error

NO_DATOS:
   SELECT @w_sql_bcp = 'echo NO_DATA> ' + @w_ruta_xml + @w_nombre_xml
   PRINT ' SQL ' + @w_sql_bcp 
   delete from @resultadobcp
   insert into @resultadobcp
   EXEC xp_cmdshell @w_sql_bcp

   RETURN 0


GO

