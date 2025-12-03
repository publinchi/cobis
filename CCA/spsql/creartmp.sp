/************************************************************************/
/*      Archivo:                creartmp.sp                             */
/*      Stored procedure:       sp_crear_tmp                            */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre, Rodrigo Garces      */
/*      Fecha de escritura:     Ene. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Manejo de tablas temporales antes de modificar operaciones,     */
/*      generar un desembolso parcial, o restructurar una tabla.        */
/****************************MODIFICACIONES******************************/
/*  Oct/20/2020   P.Narvaez    Reestructuraciones desde Cartera CoreBase*/
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crear_tmp')
	drop proc sp_crear_tmp
go
create proc sp_crear_tmp
@s_user                 login,
@s_term                 varchar(30), 
@i_banco		cuenta,
@i_accion               char(1),
@i_externo              char(1) = 'S',
@i_bloquear_salida      char(1) = 'N',    
@i_saldo_reest          money   = 0,    
@o_banco_nuevo          cuenta = null out,
@t_trn                  INT       = NULL        
as
declare @w_error		int ,
	@w_sp_name		descripcion,   
        @w_return               int,
        @w_operacion_orig       int,
        @w_operacion_nueva      int,
        @w_saldo_cap            money,
        @w_fecha_ult_proceso    datetime,
        @w_num_div              int,
        @w_tipo_amortizacion    catalogo,
        @w_operacionca          int,
        @w_dit_fecha_ven        datetime,
        @w_dias_pasar           smallint,
        @w_concepto             catalogo,
        @w_valor_rubro		money,
        @w_divcap_original      smallint,
        @w_tipo_rotativo        varchar(30),
        @w_tipo                 char(1),
        @w_dividendo_cap        smallint,
        @w_opcion_cap           char(1),
        @w_dividendos_gracia    smallint,
        @w_dividendo_vig        smallint,
        @w_div_vig              int,  --RBU
        @w_flag_reest           smallint,
        @w_rowcount             int

select  @w_sp_name = 'sp_crear_tmp'

if @i_accion = 'A' begin  

   exec @w_return      = sp_pasotmp  
   @s_user             = @s_user,
   @s_term             = @s_term,   
   @i_banco            = @i_banco,
   @i_operacionca      = 'S',
   @i_dividendo        = 'S',
   @i_amortizacion     = 'S',
   @i_cuota_adicional  = 'S',
   @i_rubro_op         = 'S',
   @i_relacion_ptmo    = 'S',
   @i_nomina           = 'S',   
   @i_valores          = 'S', 
   @i_acciones         = 'S'  

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

end

/* RESTRUCTURACIONES */
if @i_accion = 'R' begin 

   select 
   @w_operacion_orig    = op_operacion,
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
   @w_flag_reest        = op_divcap_original
   from ca_operacion
   where op_banco = @i_banco

   exec @w_return      = sp_pasotmp
   @s_user             = @s_user,
   @s_term             = @s_term,  
   @i_banco            = @i_banco,
   @i_operacionca      = 'S',
   @i_dividendo        = 'S',
   @i_amortizacion     = 'S',
   @i_cuota_adicional  = 'S',
   @i_rubro_op         = 'S',
   @i_relacion_ptmo    = 'S',
   @i_nomina           = 'S',
   @i_valores          = 'S',
   @i_acciones         = 'S' 

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end  

   select @w_saldo_cap = sum(am_cuota)
   from   ca_amortizacion,ca_rubro_op
   where  am_operacion  = @w_operacion_orig
   and    ro_operacion  = am_operacion
   and    ro_concepto   = am_concepto
   and    ro_tipo_rubro = 'C'

   /* Si no se ingresa un saldo a capitalizar o distribuir, solo se toma el capital por vencer para
      redistribuirlo en la nueva tabla si fuere el caso y se mantienen cuotas vencidas si las tuviere*/ 
   if @i_saldo_reest <= 0

      select @w_saldo_cap = sum(am_cuota)
      from   ca_amortizacion,ca_rubro_op, ca_dividendo
      where  am_operacion  = @w_operacion_orig
      and    ro_operacion  = am_operacion
      and    am_operacion  = di_operacion
      and    ro_operacion  = di_operacion
      and    di_dividendo  = am_dividendo
      and    ro_concepto   = am_concepto
      and    di_estado     = 0
      and    ro_tipo_rubro = 'C'

   /*En reestructura de varias operaciones, a la operacion final se le incrementan
     los saldos de las otras operaciones a reestructurar*/
   if @i_saldo_reest > 0
      select @w_saldo_cap = @i_saldo_reest
   
   update ca_operacion_tmp set
   opt_cuota     = 0,
   opt_monto     = @w_saldo_cap,
   opt_fecha_ini = @w_fecha_ult_proceso
   where opt_operacion = @w_operacion_orig

   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end

   /* ACTUALIZACION DE LOS RUBROS TIPO CAPITAL */
   
   declare cursor_rubros cursor for
   select ro_concepto
   from   ca_rubro_op
   where  ro_operacion  = @w_operacion_orig
   and    ro_tipo_rubro =  ('C')
   for read only

   open  cursor_rubros
   fetch cursor_rubros into
   @w_concepto
   
   while   @@fetch_status = 0 begin
   
      if (@@fetch_status = -1) begin
         select @w_error = 710004
         goto ERROR
      end 
      select @w_valor_rubro = sum(am_cuota+am_gracia-am_pagado)
      from   ca_amortizacion
      where  am_operacion  = @w_operacion_orig
      and    am_concepto   = @w_concepto

      if @i_saldo_reest <= 0

         select @w_valor_rubro = sum(am_cuota)
         from   ca_amortizacion,ca_rubro_op, ca_dividendo
         where  am_operacion  = @w_operacion_orig
         and    ro_operacion  = am_operacion
         and    am_operacion  = di_operacion
         and    ro_operacion  = di_operacion
         and    di_dividendo  = am_dividendo
         and    ro_concepto   = am_concepto
         and    di_estado     = 0
         and    ro_tipo_rubro = 'C'

      if @i_saldo_reest > 0
         select @w_valor_rubro = @i_saldo_reest
   
      update ca_rubro_op_tmp
      set    rot_valor     = @w_valor_rubro
      where  rot_operacion = @w_operacion_orig
      and    rot_concepto  = @w_concepto
   
      if (@@error <> 0) begin
         select @w_error = 710002
         goto ERROR
      end
   
      fetch   cursor_rubros into
      @w_concepto
   end
   
   close cursor_rubros
   deallocate cursor_rubros    

   if @i_bloquear_salida = 'N' select @i_banco


   /* BORRAR ACCIONES Y VALORES FUERA DE RANGO */
   select @w_div_vig = di_dividendo
   from ca_dividendo
   where di_operacion = @w_operacion_orig
   and   di_estado = 1

   select @w_div_vig = isnull(@w_div_vig,9999) 

   if isnull(@w_flag_reest, 0) > 0  begin
      delete ca_dividendo_tmp
       where dit_operacion = @w_operacion_orig
         and dit_dividendo < @w_div_vig

      if @@error <> 0 begin
         select @w_error = 710003
         goto ERROR
      end

      delete ca_amortizacion_tmp
       where amt_operacion = @w_operacion_orig
        and amt_dividendo < @w_div_vig

      if @@error <> 0 begin
         select @w_error = 710003
         goto ERROR
      end

      update ca_dividendo_tmp
         set dit_dividendo = dit_dividendo - @w_div_vig +1
       where dit_operacion = @w_operacion_orig

      if @@error <> 0 begin
         select @w_error = 710002
         goto ERROR
      end

      update ca_amortizacion_tmp
         set amt_dividendo = amt_dividendo - @w_div_vig + 1
       where amt_operacion = @w_operacion_orig

      if @@error <> 0 begin
         select @w_error = 710002
         goto ERROR
      end
   end
   else begin
      delete ca_dividendo_tmp
       where dit_operacion = @w_operacion_orig

      if @@error <> 0 begin
         select @w_error = 710003
         goto ERROR
      end

      delete ca_amortizacion_tmp
       where amt_operacion = @w_operacion_orig

      if @@error <> 0 begin
         select @w_error = 710003
         goto ERROR
      end
   end

   delete ca_acciones_tmp
   where act_operacion = @w_operacion_orig
   and   act_div_fin < @w_div_vig

   if @@error <> 0 begin
      select @w_error = 710003
      goto ERROR
   end

   delete ca_valores_tmp
   where vat_operacion = @w_operacion_orig
   and   vat_dividendo < @w_div_vig

   if @@error <> 0 begin
      select @w_error = 710003
      goto ERROR
   end

   update ca_acciones_tmp set
   act_div_ini = act_div_ini - @w_div_vig + 1,
   act_div_fin = act_div_fin - @w_div_vig + 1,
   act_divf_ini = act_divf_ini - @w_div_vig + 1,
   act_divf_fin = act_divf_fin - @w_div_vig + 1
   where act_operacion = @w_operacion_orig

   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end

   update ca_acciones_tmp set
   act_div_fin = 1
   where act_operacion = @w_operacion_orig
   and act_div_fin < 1

   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end


   update ca_valores_tmp set
   vat_dividendo = vat_dividendo - @w_div_vig + 1
   where vat_operacion = @w_operacion_orig

   if @@error <> 0 
   begin
      select @w_error = 710002
      goto ERROR
   end


end


/* DESEMBOLSOS PARCIALES */
if @i_accion = 'D' begin  

   exec @w_operacion_nueva = sp_gen_sec
        @i_operacion   = -1

   /*CREDITO ROTATIVO*/

   select @w_tipo_rotativo = pa_char   
   from cobis..cl_parametro            
   where pa_nemonico = 'ROT'           
   and pa_producto   = 'CCA'           
   set transaction isolation level read uncommitted
                                    
   select 
   @w_operacion_orig    = op_operacion,
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
   @w_divcap_original   = op_divcap_original,
   @w_tipo              = op_tipo, 
   @w_opcion_cap        = op_opcion_cap, 
   @w_dividendo_cap     = op_dividendo_cap 
   from ca_operacion
   where op_banco = @i_banco

   select @w_dividendo_vig = di_dividendo
   from ca_dividendo
   where di_operacion = @w_operacion_orig
   and   di_estado    = 1

   if @w_dividendo_vig is null and @w_tipo_rotativo <> 'O' 
   begin
      select @w_error = 701179 
      goto ERROR
   end
   else begin
      exec @w_return      = sp_pasotmp
      @s_user             = @s_user,
      @s_term             = @s_term,  
      @i_banco            = @i_banco,
      @i_operacionca      = 'S',
      @i_dividendo        = 'S',
      @i_amortizacion     = 'N',
      @i_cuota_adicional  = 'S',
      @i_rubro_op         = 'S',
      @i_relacion_ptmo    = 'S',   
      @i_nomina           = 'S'  

      if @w_return != 0 begin
         select @w_error = @w_return
         goto ERROR
      end
   end
   /* SI SE TRATA DE UNA CAPITALIZACION, DETERMINAR EL NUMERO DE DIVIDENDOS */
   /* DE GRACIA DE CAPITAL RESTANTES */

   if isnull(@w_opcion_cap ,'N') != 'N' begin
      select @w_dividendo_vig = di_dividendo 
      from   ca_dividendo
      where  di_operacion     = @w_operacion_orig
      and    di_estado        = 1

      if @w_dividendo_vig < @w_dividendo_cap
         select @w_dividendos_gracia = @w_dividendo_cap - @w_dividendo_vig  
   end
  
   update ca_operacion_tmp set
   opt_operacion = @w_operacion_nueva,
   opt_banco     = convert(varchar(20),@w_operacion_nueva),
   opt_cuota     = 0,
   opt_gracia_cap= isnull(@w_dividendos_gracia,opt_gracia_cap)
   where opt_operacion = @w_operacion_orig

   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end
    
   select @w_num_div = count(*)
   from ca_dividendo_tmp
   where dit_operacion = @w_operacion_orig
   and   dit_estado not in (0,1) --NoVig, Vig
   
   delete ca_dividendo_tmp
   where dit_operacion = @w_operacion_orig
   and   dit_estado not in (0,1) 
   
   if @@error <> 0 begin
      select @w_error = 71003
      goto ERROR
   end

   update ca_dividendo_tmp set
   dit_operacion = @w_operacion_nueva,
   dit_dividendo = dit_dividendo - @w_num_div  
   where dit_operacion = @w_operacion_orig
   
   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end

   /* MODIFICACION DE LAS FECHAS DEL PRIMER DIVIDENDO */

   select @w_dias_pasar = pa_smallint
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'DDP'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 return 710083
   
   select @w_dit_fecha_ven = dit_fecha_ven
   from   ca_dividendo_tmp
   where  dit_operacion   = @w_operacion_nueva
   and    dit_dividendo   = 1

   if @w_tipo = @w_tipo_rotativo  begin                                           
      update ca_dividendo_tmp set                  
      dit_fecha_ini          = @w_fecha_ult_proceso
      where  dit_operacion   = @w_operacion_nueva  
      and    dit_dividendo   = 1                   
   end                                             
   else begin
      if datediff(dd,@w_fecha_ult_proceso,@w_dit_fecha_ven) >= @w_dias_pasar begin
         update ca_dividendo_tmp set
         dit_fecha_ini          = @w_fecha_ult_proceso
         where  dit_operacion   = @w_operacion_nueva
         and    dit_dividendo   = 1
      end
      else begin
         update ca_dividendo_tmp set
         dit_dividendo          = dit_dividendo - 1
         where dit_operacion    = @w_operacion_nueva

         if @@error != 0 return 710002

         update ca_dividendo_tmp set
         dit_fecha_ini          = @w_fecha_ult_proceso,
         dit_fecha_ven          = B.di_fecha_ven
         from ca_dividendo_tmp,ca_dividendo B
         where dit_operacion    = @w_operacion_nueva
         and   dit_dividendo    = 1
         and   B.di_operacion   = @w_operacion_orig
         and   B.di_dividendo   = @w_num_div + 2

         if @@error != 0 return 710002

         delete ca_dividendo_tmp
         where dit_operacion    = @w_operacion_nueva
         and   dit_dividendo    = 0

         if @@error != 0 return 710003
      end
   end
   if @@error != 0 return 71002
   
   update ca_cuota_adicional_tmp set
   cat_operacion = @w_operacion_nueva,
   cat_cuota     = 0
   where cat_operacion = @w_operacion_orig

   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end

   
   update ca_rubro_op_tmp set
   rot_operacion = @w_operacion_nueva
   where rot_operacion = @w_operacion_orig
   and   rot_tipo_rubro <> 'C'
   
   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end

   update ca_rubro_op_tmp set
   rot_operacion = @w_operacion_nueva,
   rot_valor     = 0
   where rot_operacion  = @w_operacion_orig
   and   rot_tipo_rubro = 'C'

   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end

   /* PRESTAMOS DE TIPO ROTATIVOS */
   if @w_divcap_original is not null begin
      select @w_num_div = count(*)              
      from ca_dividendo
      where di_operacion = @w_operacion_orig
      and   di_estado    in (0,1) 
      
      if @w_num_div < @w_divcap_original   begin
         select @w_divcap_original = @w_divcap_original - @w_num_div

         /* AUMENTAR LOS DIVIDENDOS NECESARIOS PARA CUBRIR */
         /* EL NUEVO PRESTAMO */
         exec @w_return    = sp_completar_div
         @i_operacion_nueva= @w_operacion_nueva,
         @i_operacion_orig = @w_operacion_orig,
         @i_diferencia     = @w_divcap_original 

         if @w_return != 0
         begin
            select @w_error = @w_return
            goto   ERROR
         end
      end
   end

   exec @w_return      = sp_pasotmp
   @s_user             = @s_user,
   @s_term             = @s_term,  
   @i_banco            = @i_banco,
   @i_operacionca      = 'S',
   @i_dividendo        = 'S',
   @i_amortizacion     = 'S',
   @i_cuota_adicional  = 'S',
   @i_rubro_op         = 'S',
   @i_relacion_ptmo    = 'S',
   @i_nomina           = 'S' 

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end   

   if @i_externo = 'S'
      select @w_operacion_nueva
   else
      select @o_banco_nuevo = convert(varchar(20),@w_operacion_nueva)
      

end

   
return 0

ERROR:

if @i_externo = 'S'
begin
   exec cobis..sp_cerror
   @t_debug='N',         
   @t_file = null,
   @t_from =@w_sp_name,   
   @i_num = @w_error
--   @i_cuenta= ' '
   return @w_error  
end
else
   return @w_error  

go




