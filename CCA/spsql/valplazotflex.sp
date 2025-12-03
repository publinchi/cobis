/************************************************************************/
/*      Archivo:                valplazotflex.sp                        */
/*      Stored procedure:       sp_validar_plazo_tflex                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     May. 2014                               */
/*      Nro. procedure          11                                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Valida el plazo de la tabla flexible                            */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-09-04     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/************************************************************************/  

use cob_cartera
go
--- SECCION:ERRORES no quitar esta seccion
delete cobis..cl_errores where numero between 70011001 and 70011999
go
insert into cobis..cl_errores values(70011001, 0, 'No se encuentra el numero de operacion')
insert into cobis..cl_errores values(70011002, 0, 'La operacion sobrepasa el limite del plazo para la garantia')
insert into cobis..cl_errores values(70011003, 0, 'El Valor del Parametro <FUSAID> para USAID No Existe. Revise la Parametrizacion')
insert into cobis..cl_errores values(70011004, 0, 'La Fecha Final del Credito Excede el Valor del Parametro <FUSAID> para USAID. Revise la Parametrizacion')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_validar_plazo_tflex')
   drop proc sp_validar_plazo_tflex
go

---NR000392
create proc sp_validar_plazo_tflex
   @i_operacion         int
as
declare
   @w_error                int,
   @w_op_tramite           int,
   @w_op_plazo             smallint,
   @w_plazo_meses          smallint,
   @w_plazot121            int,
   @w_gar_op               varchar(64),
   @w_cod_gar_fng          catalogo,
   @w_usaid                int,
   @w_param_fusaid         catalogo,
   @w_op_fecha_fin         datetime,
   @w_op_moneda            smallint,
   @w_op_toperacion        catalogo,
   @w_op_tplazo            catalogo
begin
   select @w_op_tramite    = opt_tramite,
          @w_plazo_meses   = datediff(MONTH, opt_fecha_ini, opt_fecha_fin)
                           + case
                                when datepart(DAY, opt_fecha_ini) = datepart(DAY, opt_fecha_fin) then 0
                                else 1
                             end,
          @w_op_plazo      = opt_plazo,
          @w_op_fecha_fin  = opt_fecha_fin,
          @w_op_moneda     = opt_moneda,
          @w_op_toperacion = opt_toperacion,
          @w_op_tplazo     = opt_tplazo
   from   ca_operacion_tmp
   where  opt_operacion = @i_operacion
   
   if @@rowcount = 0
      return 70011001

   --- CODIGO PADRE DE GARANTIAS FNG
   select @w_cod_gar_fng = pa_char
   from   cobis..cl_parametro with (nolock)
   where  pa_producto  = 'GAR'
   and    pa_nemonico  = 'CODFNG'

   select @w_gar_op = cu_tipo
   from   cob_credito..cr_gar_propuesta with (nolock),
          cob_custodia..cu_custodia  with (nolock)                           
   where  gp_garantia = cu_codigo_externo
   and    gp_tramite  = @w_op_tramite                   
   and    cu_tipo    in (select tc_tipo
                         from cob_custodia..cu_tipo_custodia  with (nolock)
                         where  tc_tipo_superior  = @w_cod_gar_fng)
   and   ( (cu_estado      <> 'A' and   gp_est_garantia  <> 'A') )
        
   if @w_gar_op  is not null
   begin
      select @w_plazot121 = 0

      exec @w_error = cob_credito..sp_resp_plazo_max_gar
           @t_trn             = 22284,
           @i_tipo_garantia   = @w_gar_op,
           @i_tipo_consulta   = 'T',
           @o_valor           =  @w_plazot121 out  
      
      if @w_error != 0
         return @w_error

      if @w_plazo_meses > @w_plazot121
      begin
         return 70011002
      end
   end

   select tipo       = cg_tipo_garantia,
          moneda     = cg_moneda
   into   #temporal
   from   cob_custodia..cu_convenios_garantia
   where  cg_estado = 'V'

   select @w_usaid = 0

   select @w_usaid = 1
   from   cob_custodia..cu_custodia,
          cob_credito..cr_gar_propuesta,
          #temporal t
   where  gp_tramite    = @w_op_tramite
   and    gp_garantia   = cu_codigo_externo
   and    cu_tipo       = t.tipo

   if @w_usaid = 1
   begin
      --Validacion Fecha Fin de Contrato USAID
      select @w_param_fusaid = pa_datetime
      from   cobis..cl_parametro
      where  pa_nemonico = 'FUSAID'
      and    pa_producto = 'GAR'

      if @w_param_fusaid is null
      begin
         return 70011003
      end

      if @w_op_fecha_fin > @w_param_fusaid 
      begin
         return 70011004
      end
   end

   exec @w_error = sp_valida_plazo
        @i_operacion    = 'I',
        @i_operacionca  = @i_operacion,
        @i_moneda       = @w_op_moneda,
        @i_toperacion   = @w_op_toperacion,
        @i_tplazo       = @w_op_tplazo,
        @i_plazo        = @w_op_plazo

   if @w_error != 0
      return @w_error

   return 0
end
go
