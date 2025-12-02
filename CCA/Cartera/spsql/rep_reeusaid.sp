/************************************************************************/
/*   Archivo:             rep_reeusaid.sp                               */
/*   Stored procedure:    sp_rep_reestr_usaid                           */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            cartera						               	*/
/*   Disenado por:        Luis Carlos Moreno C.			                */
/*   Fecha de escritura:  Diciembre/2011                                */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios	                */
/*	propiedad de "MACOSA", representantes exclusivos para	            */
/*  el Ecuador de "NCR".                      			                */
/*  Su uso no autorizado queda expresamente prohibido asi como  		*/
/*  cualquier alteracion o agregado hecho por alguno de sus    			*/
/*  usuarios sin el debido consentimiento por escrito de la    			*/
/*  Presidencia Ejecutiva de MACOSA o su representante.    			    */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Generar un reporte mensual con reestructuraciones con garantia USAID*/
/*  con la siguiente estructura:                                        */
/*  - Cliente                                                           */
/*  - No. Obligacion                                                    */
/*  - Saldo Capital                                                     */
/*  - Nueva fecha de vencimiento                                        */
/*  - Motivo reestructuracion                                           */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA     AUTOR             RAZON                                   */
/*  15-11-11  L.Moreno          Emisión Inicial - Req: 254              */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_reestr_usaid')
   drop proc sp_rep_reestr_usaid
go

create procedure sp_rep_reestr_usaid
@i_param1       datetime = null,
@i_param2       datetime = null

as

declare @w_cod_gar_usad         varchar(10),
        @w_sp_name              varchar(32),
        @w_sp_name_batch        varchar(50),
        @w_fecha_proceso	    datetime,
        @w_fecha_ini            datetime,
        @w_fecha_fin            datetime,
        @w_s_app                varchar(30),
        @w_path                 varchar(255),
		@w_error                int,
		@w_col_id               int,
		@w_columna              varchar(50),
		@w_cabecera             varchar(1000),
		@w_comando              varchar(1000),
		@w_cmd                  varchar(300),
		@w_msg				    varchar(100),
		@w_cont_reg			    int,
		@w_nombre_plano         varchar(200),
		@w_plano_errores        varchar(200),
		@w_nombre_plano_det     varchar(200),
		@w_fecha_arch           varchar(8),
		@w_hora_arch            varchar(4)
set nocount on

select @w_sp_name   = 'sp_rep_reestr_usaid'

-- OBTIENE EL RANGO DE FECHAS DEL MES
select @w_cont_reg  = 0
select @w_fecha_ini = @i_param1,
       @w_fecha_fin = @i_param2

if @w_fecha_ini is null
begin
  select @w_error = 2101084, @w_msg = 'ERROR, NO SE ENCUENTRA LA FECHA INICIAL'
  goto ERROR_INF
end

if @w_fecha_fin is null
begin
  select @w_error = 2101084, @w_msg = 'ERROR, NO SE ENCUENTRA LA FECHA FINAL'
  goto ERROR_INF
end

--CREA TABLA TEMPORAL PARA ALMACENAR LA INFORMACION DEL REPORTE
if not object_id('reporte_reestruct_tmp') is null
   drop table reporte_reestruct_tmp

create table reporte_reestruct_tmp
(
   rr_cliente        int          null,
   rr_obligacion     varchar(24)  null,
   rr_sld_capital    money        null,
   rr_nva_fec_vcto   varchar(10)  null,
   rr_mot_reest      varchar(100) null,
)

/* CALCULA FECHA DE PROCESO */
select @w_fecha_proceso = max(do_fecha)
from cob_conta_super..sb_dato_operacion with (nolock)
where do_aplicativo = 7

/* OBTIENE CODIGO GARANTIA COLATERAL USAID */
select @w_cod_gar_usad = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'CODUSA'

-- OBTIENE DATOS PARA EL INFORME
insert into cob_cartera..reporte_reestruct_tmp(
rr_cliente                            ,rr_obligacion               ,rr_sld_capital             ,
rr_nva_fec_vcto                       ,rr_mot_reest)
select
op_cliente                            ,op_banco                    ,op_monto                   , 
convert(varchar(10),op_fecha_fin,103) ,tr_motivo
from cob_cartera..ca_transaccion with (nolock),
     cob_cartera..ca_operacion with (nolock),
     cob_credito..cr_tramite with (nolock),
     cob_credito..cr_gar_propuesta with (nolock),
     cob_custodia..cu_custodia with (nolock),
     cob_custodia..cu_tipo_custodia with (nolock)
where op_operacion      = tr_operacion
and   tr_numero_op      = op_operacion
and   op_tramite        = gp_tramite
and   gp_garantia       = cu_codigo_externo
and   cu_tipo           = tc_tipo
and   tc_tipo_superior  = @w_cod_gar_usad
and   tr_tran           = 'RES'
and   cu_estado         = 'V'
and   tr_tipo           = 'E'
and   cr_tramite.tr_estado = 'A'
and   op_estado in (1,2,9,4)
and   tr_fecha_mov between @w_fecha_ini and @w_fecha_fin
and   ca_transaccion.tr_estado <> 'RV'

/*********************************************************************************/
/*        GENERA ARCHIVO PLANO CON EL REPORTE DE GARANTIAS REESTRUCTURADAS       */
/*********************************************************************************/
/* Asigna variables para el nombre del archivo */
select @w_fecha_arch    = substring(convert(varchar(10),@w_fecha_proceso,103),1,2)+ substring(convert(varchar(10),@w_fecha_proceso,103),4,2)+substring(convert(varchar(10),@w_fecha_proceso,103),7,4),
       @w_hora_arch     = substring(convert(varchar,GetDate(),108),1,2) + substring(convert(varchar,GetDate(),108),4,2),
       @w_sp_name_batch = 'cob_cartera..sp_rep_reestr_usaid'

/* Obtiene el path donde se va a generar el informe : VBatch\Clientes\Listados */
select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente = @w_sp_name_batch

if @@rowcount = 0 begin
  select @w_error = 2101084, @w_msg = 'ERROR EN LA BUSQUEDA DEL PATH EN LA TABLA ba_batch'
  goto ERROR_INF
end

/* Obtiene el parametro de la ubicacion del kernel\bin en el servidor */
select @w_s_app   = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM' and
      pa_nemonico = 'S_APP'
                                                                                                                                                                                                                                                       
if @@rowcount = 0 begin
  select @w_error = 2101084, @w_msg = 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
  goto ERROR_INF
end

/* Obtiene los nombres de los informes */
select @w_nombre_plano     = @w_path + 'REPO_CRE_REEST_' + @w_fecha_arch+'_'+@w_hora_arch+'.txt',
       @w_plano_errores    = @w_path + 'REPO_CRE_REEST_' + @w_fecha_arch+'_'+@w_hora_arch+'.err',
       @w_nombre_plano_det = @w_path + 'REPO_CRE_REEST_det.txt'

/*-------------------------------------------------------------------------------------*/
/*             GENERA ENCABEZADO INFORME - ARCHIVO: REPO_CRE_REEST.txt       */
/*-------------------------------------------------------------------------------------*/
/* Obtiene texto para el encabezado de las columnas */
select @w_col_id   = 0,
  @w_columna  = '',
  @w_cabecera = ''
while 1 = 1
begin
   set rowcount 1
   select @w_columna = c.name,
          @w_col_id  = c.colid
   from sysobjects o, syscolumns c
   where o.id    = c.id and
         o.name  = 'reporte_reestruct_tmp' and
         c.colid > @w_col_id
   order by c.colid
   if @@rowcount = 0
   begin
      set rowcount 0
	  break
   end
   select @w_cabecera = @w_cabecera + @w_columna + '^|'
end

/*Escribir encabezado de las columnas */
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0
begin
   select @w_error = 808022, @w_msg = 'ERROR AL ESCRIBIR ENCABEZADO DEL INFORME.'
   goto ERROR_INF
end

/*-------------------------------------------------------------------------------------*/
/*             GENERA DETALLE INFORME - ARCHIVO: PLANO_ACT_CLI_det.txt          */
/*-------------------------------------------------------------------------------------*/
/* Genera detalle del informe en el archivo */
select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..reporte_reestruct_tmp out '
select @w_comando = @w_cmd + @w_nombre_plano_det + ' -c -e' + @w_plano_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'
exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
  select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
  print @w_comando
  goto ERROR_INF
end
else begin
  select @w_comando = 'del ' + @w_plano_errores
  exec @w_error = xp_cmdshell @w_comando
  if @w_error <> 0 begin
     select @w_error = 808022, @w_msg = 'ERROR AL BORRAR EL ARCHIVO DE ERRORES BCP.'
     print @w_comando
     goto ERROR_INF
  end
end

/*-------------------------------------------------------------------------------------*/
/*           GENERA INFORME FINAL - ARCHIVO: PLANO_ACT_CLI.AAAAMMDD_HHMMSS.txt  */
/*-------------------------------------------------------------------------------------*/
/* Une los archivos encabezado, detalle y totales */
select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_nombre_plano_det + ' ' + @w_nombre_plano
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_error = 808022, @w_msg = 'ERROR EN LA GENERACION DEL INFORME FINAL.'
   goto ERROR_INF
end

/* Solamente deja el archivo definitivo, se eliminan los archivos temporales */
select @w_comando = 'del ' + @w_nombre_plano_det
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_error = 808022, @w_msg = 'ERROR AL ELIMINAR ARCHIVOS TEMPORALES DE TRABAJO.'
   print @w_comando
   goto ERROR_INF
end
                                                                                                                                                                                                                
if @w_error <> 0 begin
   select @w_error = 808022, @w_msg = 'ERROR AL ELIMINAR ARCHIVOS TEMPORALES DE TRABAJO.'
   print @w_comando
   goto ERROR_INF
end
                                                                                                                                                                                                              
if @w_error <> 0 begin
   select @w_error = 808022, @w_msg = 'ERROR AL ELIMINAR ARCHIVOS TEMPORALES DE TRABAJO.'
   print @w_comando
   goto ERROR_INF
end

return 0

ERROR_INF:
                                                                                                                                                                                                                                                 
exec sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = @w_error, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return 1
go