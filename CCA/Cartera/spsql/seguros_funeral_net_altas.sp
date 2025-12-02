/************************************************************************/
/*   Archivo:              seguros_funeral_net_altas.sp                 */
/*   Stored procedure:     sp_seguro_funeral_net_altas		   	        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Nolberto Vite		                        */
/*   Fecha de escritura:   25 Junio 2018                                */
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
/*   Genera el reporte de los clientes identificados con la cuenta N2   */
/*    “Superdigital” con el Producto 01 y Sub-Producto 25.              */
/*                                                                      */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      25/06/2018     NVI             Emision Inicial                  */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_seguro_funeral_net_altas')
   drop proc sp_seguro_funeral_net_altas
go

create proc sp_seguro_funeral_net_altas
(
 @i_param1  DATETIME = null 
)
as 

declare
@w_sp_name             varchar(32),          
@w_path_destino        varchar(200), 
@w_s_app               varchar(40),
@w_cmd                 varchar(5000),
@w_destino             varchar(255),
@w_errores             varchar(255),
@w_comando             varchar(6000),
@w_error               int, 
@w_path                varchar(255),
@w_mensaje             varchar(100),
@w_fecha_proc          datetime,
@w_ffecha              int,
@w_col_id              int,
@w_columna             varchar(50),
@w_cabecera            varchar(5000),
@w_destino_cabecera    varchar(255),
@w_destino_lineas      varchar(255)

TRUNCATE TABLE seguros_funeral_net_altas_tmp

select @w_fecha_proc = fp_fecha from cobis..ba_fecha_proceso
select @w_ffecha = 103 

create table #seguros_funeral_net_altas(
 ra_ente				int				null,
 ra_identificador  		varchar(64)     null,
 ra_apellido_paterno   	varchar(64)		null,
 ra_apellido_materno   	varchar(64)		null,
 ra_nombre				varchar(100)	null,
 ra_fecha_de_emision	varchar(10)	null,
 ra_edad				tinyint			null
)

insert into seguros_funeral_net_altas_tmp
select 
'IDENTIFICADOR',
'APELLIDO PATERNO',
'APELLIDO MATERNO',
'NOMBRE',
'FECHA DE EMISION',
'EDAD'

--Datos de Credito para tipo 01 y subtipo 0025
insert into #seguros_funeral_net_altas
SELECT 
	op_cliente,
	op_banco,
	'',
	'',
	'',
	convert(varchar(10),op_fecha_liq,103),
	''
FROM cob_cartera..ca_operacion
WHERE op_estado = 1
and op_fecha_liq = @w_fecha_proc

--Datos del Cliente 		   
update 	#seguros_funeral_net_altas set 
	ra_nombre    		   =  isnull(en_nombre,'')+' '+isnull(p_s_nombre,''),  	   
	ra_apellido_paterno    =  isnull(p_p_apellido,''),  		   
	ra_apellido_materno    =  isnull(p_s_apellido,''),                  		   
	ra_edad                =  datediff(year, isnull(p_fecha_nac,@w_fecha_proc), @w_fecha_proc)
from cobis..cl_ente 
where en_ente = ra_ente 

insert into seguros_funeral_net_altas_tmp(
	ra_identificador,  	
    ra_apellido_paterno,
    ra_apellido_materno,
    ra_nombre,			
    ra_fecha_de_emision,
    ra_edad			
)
select 
	ra_identificador,  	
	ra_apellido_paterno,
	ra_apellido_materno,
	ra_nombre,			
	ra_fecha_de_emision,
	ra_edad			
from #seguros_funeral_net_altas	
	
----------------------------------------
--	Generar Archivo Plano
----------------------------------------
select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'
	
	
select @w_path = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 7
		
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..seguros_funeral_net_altas_tmp out '

select 	@w_destino= @w_path + 'FUNERAL_NET_ALTAS_' +  replace(CONVERT(varchar(10), @w_fecha_proc, @w_ffecha),'/', '')+ '.txt',
	    @w_errores  = @w_path + 'FUNERAL_NET_ALTAS_' +  replace(CONVERT(varchar(10), @w_fecha_proc, @w_ffecha),'/', '')+ '.err'
	
select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -T -e ' + @w_errores + ' -t"|" ' + '-config ' + @w_s_app + 's_app.ini'

PRINT ' CMD: ' + @w_comando 

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select
   @w_error = 724680,
   @w_mensaje = 'Error generando Archivo de Seguros Funeral Net Altas'
   goto ERROR
end

return 0

ERROR:
exec cobis..sp_errorlog 
	@i_fecha        = @w_fecha_proc,
	@i_error        = @w_error,
	@i_usuario      = 'usrbatch',
	@i_tran         = 26004,
	@i_descripcion  = @w_mensaje,
	@i_tran_name    =null,
	@i_rollback     ='S'
return @w_error

go

