/************************************************************************/
/*   Archivo:             tasanormal.sp                                 */
/*   Stored procedure:    sp_tasa_normalizacion                         */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Luis Carlos Moreno                            */
/*   Fecha de escritura:  2014/10                                       */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Realiza validaciones específicas del perfeccionamiento de la       */
/*   Normalizacion                                                      */ 
/************************************************************************/
/*            MODIFICACIONES                                            */
/*    FECHA                 AUTOR                     CAMBIO            */
/*   2014-09-24   Luis Carlos Moreno  Req436:Normalizacion Cartera      */
/*   2015-01-04   ACelis              Req499:Tasa para Clientes Especia.*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tasa_normalizacion')
   drop proc sp_tasa_normalizacion
go

create proc sp_tasa_normalizacion
   @s_user           login        = null,
   @s_ofi            smallint     = null,
   @s_term           varchar(30)  = null,
   @s_date           datetime     = null,
   @i_tramite        int,
   @i_tipo_norm      int,
   @i_debug          char         = 'N'
as
declare
   @w_error                int,
   @w_tasa                 float,
   @w_tasa_efa             float,
   @w_monto_total          float,
   @w_monto_pago           money,
   @w_interes              money,
   @w_interes_total        float,
   @w_op_operacion         int,
   @w_op_operacion_nueva   int,
   @w_op_cliente           int,
   @w_ro_porcentaje_efa    float,
   @w_secuencial_pag       int,
   @w_di_dias_cuota        int,
   @w_op_dias_anio         smallint,
   @w_op_base_calculo      char(1),
   @w_tipo_cam_norm        int,
   @w_campana              int,
   @w_spread               float,
   @w_msg                  varchar(255),
   @w_op_clase             char(10),
   @w_maneja_tasa          char(10),
   @w_toperacion           varchar(25),
   @w_util_matriz          smallint,
   @w_valor_excepcion      char(10)

begin

   select @w_monto_total = 0,
          @w_interes_total = 0

   -- OBTIENE TIPO DE CAMPANA PARA NORMALIZACION
   /* select @w_tipo_cam_norm = pa_int
   from cobis..cl_parametro
   where pa_nemonico = 'TCANOR'
   and pa_producto = 'CCA'

   if @@ROWCOUNT = 0
     return 708153
*/
   declare
      cur_anteriores cursor
      for select op_operacion, ro_porcentaje_efa
          from   cob_credito..cr_normalizacion (nolock),
                 ca_operacion (nolock),
                 ca_rubro_op (nolock)
          where  nm_tramite = @i_tramite
          and    op_banco   = nm_operacion
          and    ro_operacion = op_operacion
          and    ro_tipo_rubro = 'I'

   open cur_anteriores

   fetch cur_anteriores into @w_op_operacion, @w_ro_porcentaje_efa

   while @@FETCH_STATUS = 0
   begin
      select @w_secuencial_pag = isnull(max(tr_secuencial), 0)
      from   ca_transaccion
      where  tr_operacion = @w_op_operacion
      and    tr_tran      = 'PAG'
      and    tr_estado    <> 'RV'

      if @w_secuencial_pag = 0
      begin
         close cur_anteriores
         deallocate cur_anteriores
         return 70013001
      end

      select @w_monto_pago = 0
      select @w_monto_pago = dtr_monto
      from   ca_det_trn
      where  dtr_operacion = @w_op_operacion
      and    dtr_secuencial = @w_secuencial_pag
      and    dtr_concepto   like 'VAC%'

      if @w_monto_pago = 0
         return 70013002

      select @w_interes = cast(@w_monto_pago as float) * @w_ro_porcentaje_efa / 100.0

      if @i_debug = 'S'
      begin
         print 'OPERACION ' + convert(varchar, @w_op_operacion)
             + ' tasa_efa ' + convert(varchar, @w_ro_porcentaje_efa)
             + ' monto_ren ' + convert(varchar, @w_monto_pago)
             + ' para-interes ' + convert(varchar, @w_interes)
      end
      select @w_monto_total = @w_monto_total + @w_monto_pago,
             @w_interes_total = @w_interes_total + @w_interes
      --
      fetch cur_anteriores into @w_op_operacion, @w_ro_porcentaje_efa
   end

   close cur_anteriores
   deallocate cur_anteriores


   select @w_tasa_efa = round(@w_interes_total / @w_monto_total * 100.0, 4)



   if @i_debug = 'S'
   begin
      print 'Tasa ponderada EFA: ' + convert(varchar, isnull(@w_tasa_efa, 0))
   end

   select @w_op_operacion_nueva = op_operacion,
          @w_op_dias_anio       = op_dias_anio,
          @w_op_base_calculo    = op_base_calculo,
          @w_op_cliente         = op_cliente,
          @w_op_clase           = op_clase,
          @w_toperacion         = op_toperacion
   from   ca_operacion
   where  op_tramite = @i_tramite

   if @@ROWCOUNT = 0
      return 70013003

   --VALIDA SI EL CLIENTE ESTA INCLUIDO EN UN GRUPO DE CLIENTES ESPECIALES DE NORMALIZACION
   
   
   select @w_campana = cc_campana
   from cob_credito..cr_cliente_campana, cob_credito..cr_campana
   where cc_campana      = ca_codigo
   and   cc_cliente      = @w_op_cliente
   and   ca_tipo_campana = 3    -- tipo campaña normalizacion 3
   and   cc_estado       = 'V'
   and   ca_estado       = 'V'
   
   
   if isnull(@w_campana,0) <> 0 
   begin
      select @w_valor_excepcion =  pe_char
      from   cob_credito..cr_param_especiales_norm
      where  pe_campana  = @w_campana
      and    pe_tipo_campana = 3
      and    pe_tipo_normalizacion   = @i_tipo_norm
      and    pe_regla = 'TASA'
      and    pe_estado = 'V'
            
      if isnull(@w_valor_excepcion,'0')  = 'S'
      begin
       
         
         exec @w_error     = cob_cartera..sp_matriz_valor
         @i_matriz    = 'VAL_MATRIZ',
         @i_fecha_vig = @s_date,
         @i_eje1      = @w_toperacion,
         @i_eje2      = 'VAL_NORM',
         @o_valor     = @w_util_matriz out,
         @o_msg       = @w_msg out

         if @w_util_matriz = 0 return 0 --> LA MATRIZ NO ES UTILIZADA POR LA LINEA
         
         exec @w_error  = sp_matriz_valor
	        @i_matriz      = 'VAL_NORM',      
	        @i_fecha_vig   = @s_date,  
	        @i_eje1        = @i_tipo_norm,  
            @i_eje2        = @w_campana,  
            @i_eje3        = @w_op_clase,
	        @o_valor       = @w_spread out, 
	        @o_msg         = @w_msg    out

         if @w_error <> 0
            return @w_error
         
         
         select @w_tasa_efa = @w_tasa_efa + @w_spread
         
      end
      if @i_debug = 'S'
      begin
         print ' tasa final es...  ' + convert(varchar,    @w_tasa_efa)
      end    
   end

   select @w_di_dias_cuota = di_dias_cuota
   from   ca_dividendo
   where  di_operacion = @w_op_operacion_nueva
   and    di_dividendo = 1

   if @@ROWCOUNT = 0
      return 70013005

   exec @w_error = sp_conversion_tasas_int
        @i_periodo_o       = 'A',
        @i_modalidad_o     = 'V',
        @i_num_periodo_o   = 1,
        @i_tasa_o          = @w_tasa_efa,

        @i_periodo_d       = 'D',
        @i_modalidad_d     = 'V',
        @i_num_periodo_d   = @w_di_dias_cuota,
        @i_dias_anio       = @w_op_dias_anio,
        @i_num_dec         = 6,
        @o_tasa_d          = @w_tasa output
            
   if @w_error != 0
      return @w_error

   if @i_debug = 'S'
   begin
      print 'Tasa ponderada NOM: ' + convert(varchar, isnull(@w_tasa, -1))
          + ' a ' + convert(varchar, @w_di_dias_cuota) + ' VENCIDO'
   end

   update ca_rubro_op with (rowlock)
   set    ro_referencial      = 'TCERO',
          ro_signo            = '+',
          ro_factor           = @w_tasa_efa,
          ro_tipo_puntos      = 'E',
          ro_porcentaje_efa   = @w_tasa_efa,
          ro_porcentaje_aux   = @w_tasa_efa,
          ro_porcentaje       = @w_tasa
   where  ro_operacion = @w_op_operacion_nueva
   and    ro_tipo_rubro = 'I'

   if @@ROWCOUNT = 0 or @@error <> 0
      return 70013005




   update ca_rubro_op_tmp with (rowlock)
   set    rot_referencial      = 'TCERO',
          rot_signo            = '+',
          rot_factor           = @w_tasa_efa,
          rot_tipo_puntos      = 'E',
          rot_porcentaje_efa   = @w_tasa_efa,
          rot_porcentaje_aux   = @w_tasa_efa,
          rot_porcentaje       = @w_tasa
   where  rot_operacion = @w_op_operacion_nueva
   and    rot_tipo_rubro = 'I'

   if @@error <> 0
      return 70013005

   return 0
end
go
