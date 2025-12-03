/************************************************************************/
/*   Archivo:             autofincol.sp                                 */
/*   Stored procedure:    sp_autofinancia_colateral                     */
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
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_autofinancia_colateral')
   drop proc sp_autofinancia_colateral
go
---Ultima Version feb.25.2015
create proc sp_autofinancia_colateral
   @s_user           login          = null,
   @s_ofi            smallint       = null,
   @s_term           varchar(30)    = null,
   @s_date           datetime       = null,
   @i_tramite        int,
   @i_deudas_pagadas money,
   @i_debug          char           = 'N'
as
declare
   @w_error          int,
   @w_op_operacion   int,
   @w_cod_gar_fng       catalogo,
   @w_cod_gar_usaid     catalogo,
   @w_cod_iva_fng       catalogo,
   @w_parametro_fng     catalogo,
   @w_parametro_usaid   catalogo,
   @w_colateral         catalogo,
   @w_garantia          varchar(64),
   @w_tipo_garantia                varchar(10),
   @w_cto_asociado      catalogo,
   @w_monto_total       money,
   @w_smmlv             money,
   @w_fecha_proceso     datetime,
   @w_tasa_fng          float,
   @w_tasa_fng2         float,
   @w_porc_gar          float,
   @w_monto_gar         money,
   @w_num_smmlv         float,
   @w_cont              tinyint,
   @w_porc_iva_fng      float,
   @w_comision          money,
   @w_iva_comision      money
      
   
begin
   select @w_op_operacion = op_operacion
   from   ca_operacion (rowlock)
   where  op_tramite = @i_tramite
   
   -- PARAMETRO DE LA GARANTIA DE FNG
   -- CODIGO PADRE GARANTIA DE FNG
   select @w_cod_gar_fng = pa_char
   from cobis..cl_parametro
   where pa_producto  = 'GAR'
   and   pa_nemonico  = 'CODFNG'
   set transaction isolation level read uncommitted

   -- PARAMETRO DE LA GARANTIA DE FNG
   select @w_parametro_fng = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'COFNGD'
   set transaction isolation level read uncommitted

   select @w_colateral = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'GARFNG'
   
   -- PARAMETRO SALARIO MINIMO
   select @w_smmlv = pa_money
   from   cobis..cl_parametro
   where  pa_producto = 'MIS'
   and    pa_nemonico = 'SMLV'
   set transaction isolation level read uncommitted
   
   -- PARAMETRO IVA COMISION FNG
   select @w_cod_iva_fng = pa_char
   from cobis..cl_parametro
   where pa_producto  = 'CCA'
   and   pa_nemonico  = 'IVFNGD'
   set transaction isolation level read uncommitted
   
   select @w_fecha_proceso = fp_fecha
   from cobis..ba_fecha_proceso

   select w_tipo_garantia   = tc_tipo_superior,
          w_tipo            = tc_tipo,
          estado            = 'I',
          w_garantia        = cu_codigo_externo,
          w_porc_gar        = gp_porcentaje
   into #garantias_operacion_gtabla
   from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta, cob_custodia..cu_tipo_custodia
   Where cu_tipo = tc_tipo
   and   tc_tipo_superior = @w_colateral
   and   gp_tramite  = @i_tramite
   and   gp_garantia = cu_codigo_externo
   and   cu_estado  <> 'A'
   
   if @@ROWCOUNT > 0
   begin
      select @w_garantia        = w_garantia,
             @w_tipo_garantia   = w_tipo_garantia,
             @w_porc_gar        = w_porc_gar
      from #garantias_operacion_gtabla
     
      select @w_porc_iva_fng = 0
      
      select @w_porc_iva_fng = ro_porcentaje
      from cob_cartera..ca_rubro_op
      where ro_operacion = @w_op_operacion
      and   ro_concepto = @w_cod_iva_fng

      -- PRIMERO DETERMINAR CUAL CONCEPTO DE COLATERAL TIENE
      if exists (select 1
                 from   ca_rubro_op_tmp
                 where  rot_operacion = @w_op_operacion
                 and    rot_concepto  = @w_parametro_fng)
      and @w_tipo_garantia = @w_cod_gar_fng
      begin   
         -- DETERMINAR MONTO TOTAL
         select @w_num_smmlv = @i_deudas_pagadas / @w_smmlv
         -- OBTIENE TASA DE COMISION FNG
         exec @w_error = sp_calcula_tasa_fng
         @i_fecha_proceso = @w_fecha_proceso,
         @i_monto_smmlv   = @w_num_smmlv,
         @o_tasa          = @w_tasa_fng out
         
         if @w_error <> 0
            return @w_error
         --Formula: VF=VI/(1-C-IC)
         
         select @w_tasa_fng = @w_tasa_fng / 100.0
         select @w_monto_total = round(@i_deudas_pagadas/(1-@w_tasa_fng-((@w_porc_iva_fng / 100.0) * @w_tasa_fng)),0)
         
         select @w_cont = 0
         
         /* REALIZA 4 ITERACIONES PARA ENCONTRAR LA TASA CORRECTA */
         while @w_cont < 4
         begin
            /* SI LLEGA A LA ULTIMA ITERACION RETORNA ERROR YA QUE NO SE PUDO ESTABLECER LA TASA CORRECTA */
            select @w_cont = @w_cont + 1
            if @w_cont = 4
               return 724030
               
            select @w_num_smmlv = @w_monto_total / @w_smmlv
            -- OBTIENE TASA DE COMISION FNG
            exec @w_error = sp_calcula_tasa_fng
            @i_fecha_proceso = @w_fecha_proceso,
            @i_monto_smmlv   = @w_num_smmlv,
            @o_tasa          = @w_tasa_fng2 out
                 
            if @w_error <> 0
               return @w_error

            select @w_tasa_fng2 = @w_tasa_fng2 / 100.0
            
            if @w_tasa_fng = @w_tasa_fng2
               break
            else
            begin           
               select @w_monto_total = round(@i_deudas_pagadas/(1-@w_tasa_fng2-((@w_porc_iva_fng / 100.0) * @w_tasa_fng2)),0)
               select @w_tasa_fng = @w_tasa_fng2
            end
         end
         
         if @w_error <> 0
            return @w_error
         
         select @w_comision = round(@w_monto_total * @w_tasa_fng,0),
                @w_iva_comision = round(@w_comision * (@w_porc_iva_fng / 100.0),0)

         select @w_monto_total = @i_deudas_pagadas
                               + @w_comision
                               + @w_iva_comision                
      end
      else -- SINO TIENE COMISION ENTONCES QUITAR EL ASOCIADO
      begin
         select @w_cto_asociado = ''

         select @w_cto_asociado = rot_concepto_asociado
         from   ca_rubro_op_tmp
         where  rot_operacion = @w_op_operacion
         and    rot_concepto = @w_parametro_fng

	      delete ca_amortizacion_tmp
	      where amt_operacion = @w_op_operacion
	      and amt_concepto    in (@w_parametro_fng, @w_cto_asociado)

         if @@error <> 0
         begin
            PRINT 'gentabla.sp Error upd ca_amortizacion_tmp rubro fng'
            return  710002
         end


         delete ca_rubro_op_tmp
	     where rot_operacion = @w_op_operacion
	     and rot_concepto    in (@w_parametro_fng, @w_cto_asociado)

         if @@error <> 0
         begin
            PRINT 'gentabla.sp Error upd ca_amortizacion_tmp rubro fng'
            return  710002
         end
         select @w_monto_total = @i_deudas_pagadas
      end
      
      --print 'autofinanciacol.sp->'+' @w_monto_total:'+cast(@w_monto_total as varchar)+' @w_comision: '+cast(@w_comision as varchar) + ' @w_porc_gar: '+cast(@w_porc_gar as varchar)
      update ca_rubro_op
      set ro_valor          = @w_comision,
          ro_base_calculo   = @w_monto_total
      where ro_operacion = @w_op_operacion
      and   ro_concepto = @w_parametro_fng
      
      update ca_rubro_op_tmp
      set rot_valor          = @w_comision,
          rot_base_calculo   = @w_monto_total
      where rot_operacion = @w_op_operacion
      and   rot_concepto = @w_parametro_fng
      
      update ca_rubro_op
      set ro_valor          = @w_iva_comision,
          ro_base_calculo   = @w_comision
      where ro_operacion = @w_op_operacion
      and   ro_concepto = @w_cod_iva_fng
      
      update ca_rubro_op_tmp
      set rot_valor          = @w_iva_comision,
          rot_base_calculo   = @w_comision
      where rot_operacion = @w_op_operacion
      and   rot_concepto = @w_cod_iva_fng
      
      select @w_monto_gar = @w_monto_total * @w_porc_gar / 100
      
      --print '@w_garantia: '+cast(@w_garantia as varchar) + ' @i_tramite: '+cast(@i_tramite as varchar)
      update cob_credito..cr_gar_propuesta
      set gp_valor_resp_garantia = @w_monto_gar
      where gp_tramite = @i_tramite
      and   gp_garantia = @w_garantia
     
     update cob_custodia..cu_custodia
     set cu_valor_actual = @w_monto_gar
     where cu_codigo_externo = @w_garantia
   end
   else
   begin
      select @w_monto_total = @i_deudas_pagadas
   end 
     
   update ca_operacion
   set op_monto = @w_monto_total,
       op_monto_aprobado = @w_monto_total
   where op_tramite = @i_tramite

   update cob_credito..cr_tramite
   set tr_monto_solicitado = @w_monto_total
   where tr_tramite = @i_tramite
   
   update ca_operacion_tmp
   set opt_monto = @w_monto_total,
       opt_monto_aprobado = @w_monto_total
   where opt_tramite = @i_tramite
   
   update ca_rubro_op
   set ro_valor = @w_monto_total
   where ro_operacion = @w_op_operacion
   and   ro_concepto = 'CAP'
   
   update ca_rubro_op_tmp
   set rot_valor = @w_monto_total
   where rot_operacion = @w_op_operacion
   and   rot_concepto = 'CAP'
   
  delete cob_cartera..ca_dividendo_tmp
  where dit_operacion = @w_op_operacion
  
  delete cob_cartera..ca_amortizacion_tmp
  where amt_operacion = @w_op_operacion
  
   exec @w_error = sp_modificar_operacion_int
   @s_user              = @s_user,
   @s_sesn              = 1,
   @s_date              = @w_fecha_proceso,
   @s_ofi               = @s_ofi,
   @s_term              = @s_term,
   @i_calcular_tabla    = 'S', 
   @i_tabla_nueva       = 'S',        --Mroa: Se cambia de 'D' a 'S' para recalcular la tabla de ca_dividendo
   @i_salida            = 'N',
   @i_operacionca       = @w_op_operacion,
   @i_banco             = @w_op_operacion
   
   if @w_error <> 0
         return @w_error

   return 0
end
go