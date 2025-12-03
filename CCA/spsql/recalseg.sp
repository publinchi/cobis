/************************************************************************/
/*      Archivo:                recalseg.sp                             */
/*      Stored procedure:       sp_recalculo_seguros_sinsol             */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira PElaez                           */
/*      Fecha de escritura:     ene. 2003                               */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Recalculo de seguros de vida con saldo insoluto  al dia de      */
/*      pago para los dividendos vencidos y vigentes a la fecha         */
/*      Este sp es llamado desde:                                       */
/*      consatx.sp - pagcart.sp para pagos por ATX                      */
/*      qrpagos    - para pagos por plataforma                          */
/*                             CAMBIOS                                  */
/*      Marzo/2/2006    Fabian Quintero      Gracia de seguros          */
/*      Ago/22/2007     John Jairo Rendon    Optimizacion OPT_224       */
/*     18-May-2022      K. Rodriguez         Cerrado cursor             */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_recalculo_seguros_sinsol')
   drop proc sp_recalculo_seguros_sinsol
go

create proc sp_recalculo_seguros_sinsol
@i_operacion         int,
@i_dividendo_desde   int = null-- PARA EL NR 502 (GRACIA DE RECALCULO DE SEGURO), ES EL DIVIDENDO VIGENTE AL QUE SE LE DIO GRACIA

as
declare
   @w_sp_name           varchar(30),
   @w_concepto          catalogo,
   @w_op_tdividendo     catalogo,
   @w_op_periodo_int    int,
   @w_dias_div          int,
   @w_div_vigente       smallint,
   @w_est_vigente       tinyint,
   @w_valor_seguro      money,
   @w_factor            float,
   @w_num_dec           smallint,
   @w_moneda            smallint,
   @w_return            int,
   @w_saldo_insoluto    money,
   @w_saldo_otros       money,
   @w_porcentaje        float,
   @w_error             int,
   @w_saldo_cap         money,
   @w_est_vencido       tinyint,
   @w_saldo_para_cuota  money,
   @w_monto             money,
   @w_saldo_imo         money,
   @w_fecha_fin         datetime,
   @w_tipo              char(1),
   @w_fecha_ult_proceso datetime,
   @w_op_estado         int,
   @w_segvida           catalogo,
   @w_numero_codeudores int,
   @w_estado_rubro      tinyint

-- INICIALIZACION VARIABLES
select @w_sp_name = 'sp_recalculo_seguros_sinsol',
       @w_concepto         = '',
       @w_div_vigente      = 0,
       @w_saldo_otros      = 0,
       @w_saldo_insoluto   = 0,
       @w_saldo_para_cuota = 0,
       @w_monto            = 0,
       @w_saldo_imo        = 0

select @w_est_vigente    = 1,
       @w_est_vencido    = 2

-- VALIDAR EXISTENCIA DE RUBROS  CON SALDO INSOLUTO
if (select count(1) from   ca_rubro_op
          where  ro_operacion = @i_operacion
          and    ro_fpago     in ('P','A')
          and    ro_saldo_insoluto = 'S') > 0
   select @w_est_vencido = @w_est_vencido
else
   return 0

--CODIGO DEL RUBRO SEGURO
select @w_segvida = pa_char 
from   cobis..cl_parametro
where  pa_producto  = 'CCA'
and    pa_nemonico = 'SEGURO'
set transaction isolation level read uncommitted

-- DATOS OPERACION 
select @w_op_tdividendo     = op_tdividendo,
       @w_op_periodo_int    = op_periodo_int,
       @w_moneda            = op_moneda,
       @w_monto             = op_monto,
       @w_fecha_fin         = op_fecha_fin,
       @w_tipo              = op_tipo,
       @w_fecha_ult_proceso = op_fecha_ult_proceso,
       @w_op_estado         = op_estado
from   ca_operacion
where  op_operacion   = @i_operacion



if @w_op_estado = 4
   return 0

---PARA LAS LINEAS TIPO LIBRANZA  EL RUBRO  DE SEGURO ES FIJO SIEMPRE
if (@w_tipo = 'V') or @w_fecha_ult_proceso >= @w_fecha_fin
   return 0

--NUMERO DE DECIMALES
exec @w_return = sp_decimales
     @i_moneda    = @w_moneda,
     @o_decimales = @w_num_dec out

if @w_return != 0 
   return  @w_return

--NUMERO DE DIAS POR DIVIDENDO
select @w_dias_div = td_factor * @w_op_periodo_int
from   ca_tdividendo
where  td_tdividendo = @w_op_tdividendo

-- CURSOR POR SI HAY MAS DE UN RUBRO DE SEGURO DE VIDA PARAMETRIZADO COMO FIJO
declare
   cursor_rubros_saldo_insoluto cursor
   for select ro_concepto, ro_porcentaje
       from   ca_rubro_op
       where  ro_operacion = @i_operacion
       and    ro_fpago     in ('P','A')
       and    ro_saldo_insoluto = 'S'
   for read only

open   cursor_rubros_saldo_insoluto

fetch cursor_rubros_saldo_insoluto
into  @w_concepto, @w_porcentaje

while   @@fetch_status = 0 -- WHILE CURSOR PRINCIPAL
begin
   if (@@fetch_status = -1) return 708999
   
   select @w_div_vigente = 0,
          @w_numero_codeudores = 0
   
   if  @w_porcentaje <= 0
   begin
       close cursor_rubros_saldo_insoluto          -- KDR 18/05/2022
       deallocate cursor_rubros_saldo_insoluto  
       select @w_error = 710387
       return @w_error
   end
   
   if @i_dividendo_desde is null
   begin
      select @w_div_vigente = di_dividendo
      from   ca_dividendo
      where  di_operacion = @i_operacion
      and    di_estado    = @w_est_vigente
      
      if @@rowcount = 0
         return 0
   end
   else
   begin
      select @w_div_vigente = @i_dividendo_desde
   end
   
   if @w_div_vigente = 0
   begin
      close cursor_rubros_saldo_insoluto          -- KDR 18/05/2022
      deallocate cursor_rubros_saldo_insoluto  
      return 0
   end
   
   if @w_div_vigente != 0
   begin
      -- INICIALIZAR VARIABLES
      select 
             @w_saldo_cap        = 0,
             @w_saldo_para_cuota = 0,
             @w_saldo_otros      = 0,
             @w_saldo_insoluto   = 0,
             @w_valor_seguro     = 0
      
      select @w_saldo_cap = isnull(sum(am_cuota - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  am_operacion = ro_operacion
      and    am_operacion   = @i_operacion
      and    am_concepto    = ro_concepto
      and    ro_tipo_rubro  = 'C'
      and    am_estado <> 3
      
      select @w_saldo_imo = isnull(sum(am_cuota - am_pagado),0)
      from ca_amortizacion, ca_rubro_op
      where  am_operacion = ro_operacion
      and    am_operacion = @i_operacion
      and    am_concepto  = ro_concepto
      and    am_dividendo < convert(smallint, @w_div_vigente + 1)
      and    ro_tipo_rubro = 'M'
      
      select @w_saldo_para_cuota  = (@w_saldo_cap) + @w_saldo_imo
      
      select @w_saldo_otros = isnull(sum(am_cuota - am_pagado),0)
      from   ca_amortizacion, ca_concepto
      where  am_operacion  = @i_operacion
      and    am_dividendo  <= @w_div_vigente
      and    am_concepto = co_concepto
      and    co_categoria in ('A','I','H','G','R','O','S') 
      
      select @w_saldo_insoluto = isnull(@w_saldo_para_cuota + @w_saldo_otros , 0)
      
      select @w_valor_seguro = @w_saldo_insoluto * @w_dias_div * (@w_porcentaje/100) / 360
      select @w_valor_seguro = round ( @w_valor_seguro,@w_num_dec)
      
      -- SE ACTUALIZA EL VALOR DEL SEGURO, DE ACUERDO AL NUMERO DE CODEUDORES CON SEGURO DE VIDA  --XMA 201
      if (select count(1) from ca_deudores_tmp
                 where dt_operacion  = @i_operacion) > 0
                 and (@w_segvida = @w_concepto)
      begin
         select @w_numero_codeudores = count(1)
         from ca_deu_segvida
         where dt_operacion  = @i_operacion
         and   dt_segvida = 'S'
         ---select @w_numero_codeudores = sum(@w_numero_codeudores + 1 ) --(deudor)
         select @w_valor_seguro   = round((@w_valor_seguro * @w_numero_codeudores),@w_num_dec)
      end
      
      --- ACTUALIZAR TABLA DE RUBROS PARA EL CONCEPTO    
      update ca_rubro_op
      set    ro_base_calculo = @w_saldo_insoluto,
             ro_valor        = @w_valor_seguro
      where  ro_operacion = @i_operacion
      and    ro_concepto  = @w_concepto   
      
      if @w_segvida = @w_concepto   --XMA 201
      begin
         select @w_estado_rubro =  am_estado
         from   ca_amortizacion
         where  am_operacion  = @i_operacion
         and    am_dividendo  = @w_div_vigente + 1
         and    am_concepto   = @w_concepto
         
         if @w_estado_rubro = 3   ---significa que el 1er div NOVIGENTE, tiene el SEGVIDA cancelado
            select @w_div_vigente = @w_div_vigente + 1
      end  
      
      --- ACTUALIZAR TABLA DE AMORTIZACION 
      update ca_amortizacion
      set    am_cuota     = @w_valor_seguro,
             am_acumulado = @w_valor_seguro
      from   ca_amortizacion
      where  am_operacion = @i_operacion
      and    am_dividendo = @w_div_vigente + 1
      and    am_concepto  = @w_concepto
      and    am_pagado    <= @w_valor_seguro
   end
   
   fetch cursor_rubros_saldo_insoluto
   into  @w_concepto, @w_porcentaje
end -- WHILE CURSOR RUBROS

close cursor_rubros_saldo_insoluto
deallocate cursor_rubros_saldo_insoluto


return 0
go
