/************************************************************************/
/*   Archivo:             ca_clfinagro_xmorab.sp                        */
/*   Stored procedure:    sp_cam_lfinagro_xmora_batch                   */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez Burbano                         */
/*   Fecha de escritura:  AGO.2015                                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   cambio de línea de crédito de Liena finagro sustitutiva a Linea    */
/*   finagro agropecuaria segun parametro de mora                       */
/************************************************************************/
/*   AUTOR               FECHA        CAMBIO                            */
/*   EPB                 AGO.2015     Emision Inicial. NR 500 finagro   */
/*                                    Bancamia                          */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cam_lfinagro_xmora_batch')
   drop proc sp_cam_lfinagro_xmora_batch
go
SET ANSI_NULLS ON
GO
---AGO.12.2015
CREATE proc sp_cam_lfinagro_xmora_batch
   @s_user       login        = null,
   @i_banco      cuenta,
   @i_operacion  int
as declare              
   @w_error             int,
   @w_sp_name           varchar(64),
   @w_fecha_cca         datetime,
   @w_msg               varchar(255),
   @w_FINMOR            int,
   @w_saldo_CAP         money,
   @w_linOrigen         catalogo,
   @w_linea_destino     catalogo,
   @w_LFINMO            catalogo,
   @w_est_op            smallint,
   @w_moneda            smallint,
   @w_cliente           int,
   @w_min_div_ven       smallint,
   @w_min_fecha_ven     datetime,
   @w_fecha_ult_proceso datetime,
   @w_dias_mora         smallint,
   @w_dt_naturaleza    char(1),
   @w_dt_subtipo_linea catalogo,
   @w_dt_tipo_linea    catalogo,
   @w_dt_tipo          char(1),
   @w_secuencial       int,
   @w_observacion      char(62),
   @w_calificacion     char(1),
   @w_gar_admisible    char(1),
   @w_gerente          smallint,
   @w_oficina          int

select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select 
@w_sp_name           = 'sp_cam_lfinagro_xmora_batch'
    
--- OBTENER RESPALDO ANTES DEL CAMBIO DE ESTADO 

select @w_LFINMO = pa_char
from cobis..cl_parametro 
where pa_nemonico in ('LFINMO')
and pa_producto = 'CCA'
if @@rowcount = 0 
begin
   select @w_msg  = 'NO SE HA DEFINIDO EN CARTERA EL PARAMETRO GENERAL [LFINMO] - LINEA DESTINO'
   goto ERROR_FINAL
end

---DATOS DE LA LINEA DESTINO
select 
@w_dt_naturaleza    = dt_naturaleza, 
@w_dt_tipo          = dt_tipo,       
@w_dt_tipo_linea    = dt_tipo_linea, 
@w_dt_subtipo_linea = dt_subtipo_linea 
from ca_default_toperacion
where dt_toperacion = @w_LFINMO
if @@rowcount = 0 
begin
   select @w_msg =  'NO SE ENCUENTRA LINEA DESTINO PARA CAMBIO DE LINEA FIANGRO x MORA en T301'
   goto ERROR_FINAL
end


select @w_secuencial = 0
select @w_secuencial = isnull(cl_sec_tran,0)
from ca_oper_cambio_linea_x_mora 
where cl_banco = @i_banco
and   cl_estado = 'NA'

if @w_secuencial > 0
begin
   --- ACTUALIZACION DE LOS DATOS DE LA OPERACION
   update ca_operacion
   set
   op_toperacion         = @w_LFINMO,
   op_tipo               = @w_dt_tipo,
   op_tipo_linea         = @w_dt_tipo_linea,
   op_subtipo_linea      = @w_dt_subtipo_linea,
   op_naturaleza         = @w_dt_naturaleza,
   op_codigo_externo     = null,
   op_margen_redescuento = 0
   where op_operacion = @i_operacion
   if @@error <> 0
   begin
      select @w_msg =  'ERROR ACTUALIZANDO ca_operacion :' + cast ( @i_banco as varchar)
      goto ERROR_FINAL               
   end                               

   update ca_transaccion 
   set tr_estado =  'NCO'
   where tr_operacion = @i_operacion
   and tr_secuencial = @w_secuencial
   
      if @@error <> 0
      begin
         select @w_msg =  'ERROR INSERTANDO  en ca_transaccion la transaccion CLF: ' + cast ( @i_banco as varchar)
         goto ERROR_FINAL               
      end                               
   
   update  ca_oper_cambio_linea_x_mora
   set cl_estado   = 'P',
       cl_fecha_upd = @w_fecha_cca
   where cl_banco = @i_banco
   and   cl_estado = 'NA'      
   and   cl_sec_tran = @w_secuencial
   
   if @@error <> 0 
   begin
      select @w_msg =  'NO SE ACTUALIZO ESTADO  EN LA TABLA ca_oper_cambio_linea_x_mora ' + cast ( @i_banco as varchar)
      goto ERROR_FINAL
   end
   
end    ----SEcuencial > 0

return 0

ERROR_FINAL:
  begin
      PRINT ''
      exec sp_errorlog 
      @i_fecha       = @w_fecha_cca,
      @i_error       = 7999, 
      @i_tran        = null,
      @i_usuario     = @s_user, 
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = '',
      @i_rollback    = 'N',
      @i_descripcion = @w_msg,
      @i_anexo       = @w_msg
      return 1
   end

go
