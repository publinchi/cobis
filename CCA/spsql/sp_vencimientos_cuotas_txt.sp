use cob_cartera
go
/*************************************************************************/
/*   ARCHIVO:         sp_vencimientos_cuotas_txt.sp                      */
/*   NOMBRE LOGICO:   sp_vencimientos_cuotas_txt                         */
/*   Base de datos:   cob_cartera                                        */
/*   PRODUCTO:        Cartera                                            */
/*   Fecha de escritura:   Octubre 2019                                  */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante legal.            */
/*************************************************************************/
/*                     PROPOSITO                                         */
/*  Genera el reporte de vencimiento de cuotas en formato TXT            */
/*                                                                       */
/*************************************************************************/
/*                     MODIFICACIONES                                    */
/*   FECHA         AUTOR                       RAZON                     */
/* 11/Oct/2017     AAMD                     Emision inicial              */
/*  07/Nov/2019    AMG                      Reestructura de sp           */
/*************************************************************************/

if exists(select 1 from sysobjects where name = 'sp_vencimientos_cuotas_txt')
    drop proc sp_vencimientos_cuotas_txt
go
CREATE proc sp_vencimientos_cuotas_txt
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
        @w_path             varchar(255),
        @w_sp_name          varchar(30),
        @w_msg              varchar(255),
        @w_nombre           VARCHAR(5000),
        @w_s_app            varchar(40),
        @w_ffecha           int,
        @w_fec_proceso      datetime,
        @w_periodo          char(6),
        @w_cmd              varchar(5000),
        @w_destino          varchar(255),
        @w_errores          varchar(255),
        @w_comando          varchar(6000)

-- nombre del sp
select @w_sp_name = 'sp_vencimientos_cuotas_txt'
-- declare @resultadobcp table (linea varchar(max))

-- tipo de formato de la fecha
select @w_ffecha = 103

-- obtenemos el periodo y la fecha de proceso
select @w_periodo = left(convert(varchar,fp_fecha,112),6),
       @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso

-- nombre del archivo a generar 
SELECT @w_nombre = 'vencicuotas'

-- path de destino
select @w_path = pp_path_destino
  from cobis..ba_path_pro
 where pp_producto = 7

if (@@error != 0 or @@rowcount != 1 or isnull(@w_path, '') = '')
begin
   select @w_error = 724623
    goto ERROR_PROCESO
end

/*  BORRAR EL ARCHIVO TXT y ERR */
select  @w_sql_bcp = 'del ' + @w_path + @w_nombre+replace(CONVERT(varchar(10), @w_fec_proceso, @w_ffecha),'/', '')+ '.txt'
EXEC xp_cmdshell @w_sql_bcp;

select  @w_sql_bcp = 'del ' + @w_path + @w_nombre+replace(CONVERT(varchar(10), @w_fec_proceso, @w_ffecha),'/', '')+ '.err'
EXEC xp_cmdshell @w_sql_bcp;

IF NOT EXISTS(SELECT 1 FROM ca_vencimiento_cuotas)
BEGIN
  GOTO NO_DATOS
END

 SELECT 'ID Cliente' as clienteId,
    'Fecha Proceso' as fecha_proceso,
    'Nombre Cliente' as clienteName,
    'Mail' as mail,
    'Banco' as banco,
    'Tipo Operacion' as tipo_operacion,
    'Fecha Liquidacion' as fecha_liq,
    'Moneda' as moneda,
    'Fecha Vigencia' as fecha_vig,
    'Dividendo' as dividendo,
    'Monto' as monto,
    'Nombre Oficina'  as oficinaName
INTO cob_cartera..##tmp_vencimiento_cuotas
UNION ALL
select convert(varchar(10), vc_cliente) as clienteId, 
    convert(varchar(10), vc_fecha_proceso, 103) as fecha_proceso, 
    vc_cliente_name as clienteName, 
    isnull(vc_email,' ') as mail,
	vc_banco,
	vc_tipo_operacion,
    convert(varchar(10), vc_op_fecha_liq, 103) as fecha_liq, 
    convert(varchar(10), vc_op_moneda) as moneda, 
    convert(varchar(10), vc_di_fecha_vig, 103) as fecha_vig, 
    convert(varchar(10),vc_di_dividendo) as dividendo, 
    convert(varchar(50),vc_di_monto) as monto, 
    of_nombre as oficinaName
 from ca_vencimiento_cuotas inner join cobis..cl_oficina 
	on of_oficina = vc_op_oficina
 

 /* Generacion del archivo */
 select @w_s_app = pa_char
   from cobis..cl_parametro
  where pa_producto = 'ADM'
    and pa_nemonico = 'S_APP'

select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..##tmp_vencimiento_cuotas out '

select  @w_destino= @w_path + @w_nombre +  replace(CONVERT(varchar(10), @w_fec_proceso, @w_ffecha),'/', '')+ '.txt',
      @w_errores  = @w_path + @w_nombre +  replace(CONVERT(varchar(10), @w_fec_proceso, @w_ffecha),'/', '')+ '.err'

print 'Destino: ' + @w_destino
print 'Errores: ' + @w_errores

select @w_comando = @w_cmd + @w_destino + ' -c -t"|" -b 5000 -e ' + @w_errores + ' -config ' + @w_s_app + 's_app.ini'

PRINT ' CMD: ' + @w_comando 

exec @w_error = xp_cmdshell @w_comando


-- Eliminamos la tabla global
drop table ##tmp_vencimiento_cuotas;

if @w_error <> 0 begin
   select
   @w_error = 724681,
   @w_mensaje = 'Error generando Archivo de Vencimiento de cuotas'
   PRINT 'ERROR LABEL'
   goto ERROR
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
   SELECT @w_sql_bcp = 'echo NO_DATA> ' + @w_path + @w_nombre+ replace(CONVERT(varchar(10), @w_fec_proceso, @w_ffecha),'/', '')+ '.txt'
   PRINT ' SQL ' + @w_sql_bcp 
   EXEC xp_cmdshell @w_sql_bcp

   RETURN 0

ERROR:
exec cobis..sp_errorlog 
  @i_fecha        = @w_fec_proceso,
  @i_error        = @w_error,
  @i_usuario      = 'usrbatch',
  @i_tran         = 26004,
  @i_descripcion  = @w_mensaje,
  @i_tran_name    = null,
  @i_rollback     = 'S'

return @w_error

go
