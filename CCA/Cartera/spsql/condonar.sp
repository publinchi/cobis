/************************************************************************/
/*  Archivo:              condonar.sp                                   */
/*  Stored procedure:     sp_abono_condonaciones                        */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Credito y Cartera                             */
/*  Disenado por:         Fabian de la Torre                            */  
/*  Fecha de escritura:   Abril 01 de 1997                              */ 
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
/*              PROPOSITO                                               */
/*  Procedimiento que realiza el abono de los rubros condonados         */
/*  de Cartera.                                                         */
/*                               CAMBIOS                                */
/*      FECHA        AUTOR            CAMBIO                            */
/*      FEB-2003     Elcira Pelaez    personalizacion BAC               */
/*      JUL-2022     Kevin Rodríguez  Cancelación de divs y operación   */
/*      AGO-2022     Kevin Rodríguez  R191162 Valida monto aplicado y   */
/*                                    registrado                        */
/*      NOV-2023     K. Rodriguez     Actualiza valor despreciab        */
/************************************************************************/  


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abono_condonaciones')
   drop proc sp_abono_condonaciones
go

---Inc-23822 Partiendo de la version 3  junio - 30 -2011

create proc sp_abono_condonaciones
@s_ofi                  smallint,
@s_sesn                 int,
@s_user                 login,
@s_term                 varchar (30) = NULL,
@s_date                 datetime     = NULL,
@i_secuencial_ing       int,
@i_secuencial_pag       int,
@i_secuencial_rpa       int,
@i_div_vigente          int,
@i_fecha_pago           datetime = NULL,
@i_en_linea             char(1) = 'N',
@i_tipo_cobro           char(1) = 'A',
@i_operacionca          int,
@i_dividendo            int = 0,
@i_cancela              char(1) = 'N',
@i_num_dec              smallint           

as 
declare 
@w_return               int,
@w_sp_name              varchar(30),
@w_concepto             catalogo,
@w_est_cancelado        smallint,
@w_est_vigente          smallint,
@w_est_novigente        smallint,
@w_monto_rubro          money,
@w_monto_con            float,
@w_monto_con1           money,
@w_dividendo            int,
@w_tcotizacion          char(1),
@w_cotizacion           float,
@w_fecha_ven            datetime,
@w_fpago                char(1),
@w_ro_tipo_rubro        catalogo,
@w_dias_cuota           int,
@w_di_estado            int,
@w_tasa_prepago         float,
@w_dias                 int,
@w_monto_acum           float,
@w_monto_acum1          money,
@w_op_moneda            smallint,
@w_tramite              int,
@w_min_fecha_ven       datetime,
@w_saldo_capital       money,
@w_deuda_OTROS         money,
@w_deuda_CAP           money,
@w_saldo_IMO           money,
@w_saldo_INT           money,
@w_con_tot_CONDONAR    money,
@w_fecha_ult_proceso   datetime,
@w_cancelar_div        char(1),    -- KDR Bandera que define si debe cancelar el dividendo 
@w_total_div           money,      -- KDR Saldo del dividendo
@w_vlr_despreciable    float,      -- KDR Saldo no considerado de acuerdo al numero de decimales 
@w_saldo_oper          money,      -- KDR Saldo de la operación 
@w_bandera_be          char(1),    -- KDR Bandera que indica que es ejecutado desde Backend (i_en_linea = N)
@w_monto_cond_trn      money,
@w_monto_cond_abn      money,
@w_secuencial_pag      int


-- CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name       = 'sp_abono_condonaciones',
@w_con_tot_CONDONAR = 0,
@w_est_cancelado = 3,
@w_est_vigente   = 1,
@w_est_novigente = 0,
@w_saldo_capital  = 0,
@w_deuda_OTROS    = 0,
@w_deuda_CAP      = 0,
@w_saldo_IMO      = 0,
@w_saldo_INT      = 0

select @w_vlr_despreciable = 1.0 / power(10, (@i_num_dec + 2))

select @w_op_moneda = op_moneda,
       @w_fecha_ult_proceso = op_fecha_ult_proceso,
	   @w_tramite   = op_tramite
from ca_operacion
where op_operacion = @i_operacionca

select @w_min_fecha_ven = min(di_fecha_ven)
from ca_dividendo
where di_operacion = @i_operacionca
and di_estado  in(1,2)


select @w_saldo_capital = isnull(sum(am_cuota + am_gracia - am_pagado),0)
from   ca_amortizacion, ca_rubro_op
where  am_operacion  = @i_operacionca
and    ro_operacion  = am_operacion
and    ro_concepto   = am_concepto 
and    ro_tipo_rubro = 'C'

if @w_saldo_capital is null
   select @w_saldo_capital = 0
   

select @w_saldo_INT = isnull(sum(am_cuota + am_gracia - am_pagado),0)
from   ca_amortizacion, ca_rubro_op,ca_dividendo
where  am_operacion  = @i_operacionca
and    ro_operacion  = am_operacion
and    ro_concepto   = am_concepto 
and    ro_tipo_rubro = 'I'
and    di_operacion = am_operacion
and    di_dividendo = am_dividendo
and    di_estado in (1,2)

if @w_saldo_INT is null
   select @w_saldo_INT = 0

select @w_saldo_IMO = isnull(sum(am_cuota + am_gracia - am_pagado),0)
from   ca_amortizacion, ca_rubro_op,ca_dividendo
where  am_operacion  = @i_operacionca
and    ro_operacion  = am_operacion
and    ro_concepto   = am_concepto 
and    ro_tipo_rubro = 'M'
and    di_operacion = am_operacion
and    di_dividendo = am_dividendo
and    di_estado in (1,2)

if @w_saldo_IMO is null
   select @w_saldo_IMO = 0

select @w_deuda_CAP = isnull(sum(am_cuota + am_gracia - am_pagado),0)
from   ca_amortizacion, ca_rubro_op,ca_dividendo
where  am_operacion  = @i_operacionca
and    ro_operacion  = am_operacion
and    ro_concepto   = am_concepto 
and    ro_tipo_rubro = 'C'
and    di_operacion = am_operacion
and    di_dividendo = am_dividendo
and    di_estado in (1,2)

if @w_deuda_CAP is null
   select @w_deuda_CAP = 0



select @w_deuda_OTROS = isnull(sum(am_cuota + am_gracia - am_pagado),0)
from   ca_amortizacion, ca_rubro_op,ca_dividendo
where  am_operacion  = @i_operacionca
and    ro_operacion  = am_operacion
and    ro_concepto   = am_concepto 
and    ro_tipo_rubro  not in ( 'C','I','M')
and    di_operacion = am_operacion
and    di_dividendo = am_dividendo
and    di_estado in (1,2)

if @w_deuda_OTROS is null
    select @w_deuda_OTROS = 0

select @w_con_tot_CONDONAR  = (@w_deuda_CAP + @w_deuda_OTROS + @w_saldo_INT + @w_saldo_IMO)
if @w_con_tot_CONDONAR is null
   select @w_con_tot_CONDONAR = 0

insert into ca_datos_condonaciones  values (@i_operacionca,@i_secuencial_pag,@w_min_fecha_ven,@w_saldo_capital,
                                            @w_saldo_INT,  @w_saldo_IMO,     @w_deuda_CAP,    @w_deuda_OTROS,
                                            @w_con_tot_CONDONAR,             @w_fecha_ult_proceso)


-- RUBROS A SER CONDONADOS       
declare cursor_condonaciones cursor for
select
abd_concepto, 
abd_monto_mop,
abd_cotizacion_mop,
abd_tcotizacion_mop
from ca_abono_det
where abd_secuencial_ing = @i_secuencial_ing
and   abd_operacion      = @i_operacionca
and   abd_tipo           = 'CON'
for read only

open cursor_condonaciones

fetch cursor_condonaciones into 
@w_concepto,
@w_monto_con,
@w_cotizacion,
@w_tcotizacion

while   @@fetch_status = 0 begin 
 --WHILE CURSOR PRINCIPAL

   if (@@fetch_status = -1) 
      return 708999

   --VALIDAR QUE EL VALOR NO SUPERE EL ACUMULADO POR CONCEPTO
   select @w_monto_acum = isnull(sum(am_acumulado - am_pagado),0)
   from   ca_amortizacion
   where  am_operacion = @i_operacionca
   and    am_concepto  = @w_concepto
  
   if @w_op_moneda <> 0
   begin
      select @w_monto_con1  = round(isnull(@w_monto_con * @w_cotizacion,0),0)
      select @w_monto_acum1 = round(isnull(@w_monto_acum * @w_cotizacion,0),0)
   end

   if @w_monto_con1 > @w_monto_acum1  
      return 710514
   
   
     -- CURSOR DE DIVIDENDOS 
  if @i_dividendo = 0
   declare cursor_dividendos cursor for
   select
   di_dividendo,
   di_fecha_ven,
   di_dias_cuota,
   di_estado
   from ca_dividendo
   where di_operacion = @i_operacionca
   and di_estado     != @w_est_cancelado
   order by di_dividendo
   for read only
 else
   declare cursor_dividendos cursor for
   select
   di_dividendo,
   di_fecha_ven,
   di_dias_cuota,
   di_estado
   from ca_dividendo
   where di_operacion = @i_operacionca
   and di_estado     != @w_est_cancelado
   and di_dividendo   = @i_dividendo
   order by di_dividendo
   for read only
   
   open cursor_dividendos

   fetch cursor_dividendos into 
   @w_dividendo,
   @w_fecha_ven,
   @w_dias_cuota,
   @w_di_estado

   while @@fetch_status = 0 begin
      -- CURSOR DIVIDENDOS 

      if (@@fetch_status = -1) 
         return 708999

      select @w_dias = @w_dias_cuota

      -- MONTO DEL RUBRO A CONDONAR 
      exec @w_return = sp_monto_pago_rubro
      @i_operacionca   = @i_operacionca,
      @i_dividendo     = @w_dividendo,
      @i_tipo_cobro    = 'A',
      @i_fecha_pago    = @i_fecha_pago,
      @i_dividendo_vig = @i_div_vigente,
      @i_concepto      = @w_concepto,
      @o_monto         = @w_monto_rubro out

      if @w_return != 0
         return @w_return


      select 
      @w_fpago          = ro_fpago,
      @w_ro_tipo_rubro  = ro_tipo_rubro,
      @w_tasa_prepago   = ro_porcentaje
      from ca_rubro_op
      where ro_operacion = @i_operacionca
        and ro_concepto  = @w_concepto

      
      -- APLICACION DE LA CONDONACION
      
      exec @w_return      = sp_abona_rubro
      @s_ofi              = @s_ofi,
      @s_sesn             = @s_sesn,
      @s_user             = @s_user,
      @s_date             = @s_date,
      @s_term             = @s_term,
      @i_secuencial_pag   = @i_secuencial_pag,      
      @i_operacionca      = @i_operacionca,
      @i_dividendo        = @w_dividendo,
      @i_concepto         = @w_concepto,
      @i_monto_pago       = @w_monto_con,
      @i_monto_prioridad  = @w_monto_rubro, 
      @i_monto_rubro      = @w_monto_rubro,
      @i_tipo_cobro       = @i_tipo_cobro,
      @i_fpago            = @w_fpago,
      @i_en_linea         = @i_en_linea,
      @i_fecha_pago       = @i_fecha_pago,
      @i_condonacion      = 'S',
      @i_cotizacion       = @w_cotizacion,
      @i_tcotizacion      = @w_tcotizacion,
      @i_tipo_rubro       = @w_ro_tipo_rubro,   
      @i_dias_pagados     = @w_dias,
      @i_tasa_pago        = @w_tasa_prepago,
      @o_sobrante_pago    = @w_monto_con out

      if (@w_return != 0) 
         return @w_return
      
        
	  /*LÓGICA PARA CANCELAR UN DIVIDENDO SI LA CONDONACIÓN CUBRIO TODA LA CUOTA*/
	  select @w_cancelar_div  = 'N'
	  
	  if (@i_tipo_cobro = 'A')
	  begin
	     select @w_total_div = isnull(sum(am_acumulado+am_gracia-am_pagado),0)
         from   ca_amortizacion, ca_rubro_op,ca_concepto
         where  am_operacion = @i_operacionca
         and    ro_operacion = am_operacion
         and    ro_concepto  = am_concepto
         and    ro_concepto  = co_concepto
         and    am_estado      <> @w_est_cancelado
         and   (--between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir
                (    am_dividendo between @w_dividendo and @w_dividendo + charindex (ro_fpago, 'A')
           and not(co_categoria in ('S','A') and am_secuencia > 1)
          )
          or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @w_dividendo)
         )
		 
		 select @w_total_div = isnull(@w_total_div,0)
		 select @w_total_div = (abs(@w_total_div) + @w_total_div)/2.0
         
         if @w_total_div < @w_vlr_despreciable 
            select @w_cancelar_div = 'S'
	  end
	  
	  if (@i_tipo_cobro = 'P')
	  begin
	     select @w_total_div = isnull(sum(am_cuota+am_gracia-am_pagado),0)
         from   ca_amortizacion, ca_rubro_op,ca_concepto
         where  am_operacion = @i_operacionca
         and    ro_operacion = am_operacion
         and    ro_concepto  = am_concepto
         and    ro_concepto  = co_concepto
         and    am_estado      <> @w_est_cancelado
         and   (--between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir
                (    am_dividendo between @w_dividendo and @w_dividendo + charindex (ro_fpago, 'A')
           and not(co_categoria in ('S','A') and am_secuencia > 1)
          )
          or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @w_dividendo)
         )
		 
		 select @w_total_div = isnull(@w_total_div,0)
		 select @w_total_div = (abs(@w_total_div) + @w_total_div)/2.0
         
         if @w_total_div < @w_vlr_despreciable 
            select @w_cancelar_div = 'S'
	  end
	  
      if @w_cancelar_div = 'S' --and @i_cancela = 'N'
      begin 
	     update ca_dividendo set    
         di_estado    = @w_est_cancelado,
         di_fecha_can = @w_fecha_ult_proceso
         where  di_operacion = @i_operacionca
         and    di_dividendo = @w_dividendo
         
         if @@error <>0  begin
            close cursor_dividendos
            deallocate cursor_dividendos
            return 710002 -- 
         end
		 
	     update ca_amortizacion
         set    am_estado = @w_est_cancelado
         from   ca_amortizacion
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_dividendo
         
         if @@error <>0 begin
            close cursor_dividendos
            deallocate cursor_dividendos
            return 710002
         end
		 
		 if @w_di_estado = @w_est_vigente and @i_cancela = 'N' 
		 begin
		    
			-- VIGENTE EL SIGUIENTE
            update ca_dividendo
            set    di_estado = @w_est_vigente
            where  di_operacion = @i_operacionca
            and    di_dividendo = @w_dividendo + 1
            and    di_estado    = @w_est_novigente
            
            if @@error <>0  begin
               close cursor_dividendos
               deallocate cursor_dividendos
               return 710002
            end
            
            update ca_amortizacion
            set    am_estado = @w_est_vigente
            from   ca_amortizacion 
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_dividendo + 1
            and    am_estado    = @w_est_novigente
            
            if @@error <>0 begin
               close cursor_dividendos
               deallocate cursor_dividendos
               return 710002
            end
		 end
	  end  -- FIN @w_cancelar_div = 'S' 
	  
	  if @w_monto_con <= 0 
      begin
          --SALIR DEL CURSOR DE DIVIDENDOS 
         break 
      end
	  

      fetch cursor_dividendos into
      @w_dividendo,
      @w_fecha_ven,
      @w_dias_cuota,
	  @w_di_estado
   end
   close cursor_dividendos
   deallocate cursor_dividendos
 
   fetch cursor_condonaciones into @w_concepto,@w_monto_con,@w_cotizacion,
   @w_tcotizacion
   

end -- WHILE CURSOR PRINCIPAL
close cursor_condonaciones
deallocate cursor_condonaciones


-- Comprobar el monto total de la condonación es igual al monto de la transacción
-- [Se realiza esta comprobación por si los conceptos a condonar fueron pagados por un pago con de fecha valor]

select @w_monto_cond_abn = sum(abd_monto_mop)
from ca_abono_det
where abd_secuencial_ing = @i_secuencial_ing
and   abd_operacion      = @i_operacionca
and   abd_tipo           = 'CON'

select @w_monto_cond_trn = sum(dtr_monto)
from ca_det_trn
where dtr_operacion = @i_operacionca
and dtr_secuencial  = @i_secuencial_pag
and dtr_afectacion = 'C'

select @w_monto_cond_trn = round(isnull(@w_monto_cond_trn, 0), @i_num_dec),
       @w_monto_cond_abn = round(isnull(@w_monto_cond_abn, 0), @i_num_dec)

if (@w_monto_cond_abn <> @w_monto_cond_trn)
begin
   return 725172 
end
-- FIN COMPROBACIÓN DE MONTOS
        
update ca_abono
set    ab_estado           = 'A',
       ab_secuencial_rpa   = @i_secuencial_rpa
where  ab_secuencial_ing   = @i_secuencial_ing
and    ab_operacion        = @i_operacionca
if @@error != 0 return 705048


---EL CODIGO VALOR DE LOS CONCEPTOS CONDONADOS EN LA TRANSACCION RPA
---DEBEN TENER EL MISMO CODIGO VALOR DE LOS CONCEPTOS DE LA TRANSACCION PAG
create table #ca_codvalor_condonados(
    operacion          int      null,
    secuencial         int      null,
    concepto           catalogo null,
    codvalor            int      null
   )    

insert into #ca_codvalor_condonados
select dtr_operacion,dtr_secuencial,dtr_concepto,dtr_codvalor
from ca_det_trn
where dtr_operacion = @i_operacionca
and dtr_secuencial = @i_secuencial_pag
and dtr_estado <> 7

update ca_det_trn
set dtr_codvalor = codvalor
from #ca_codvalor_condonados
where dtr_operacion = @i_operacionca
and dtr_secuencial = @i_secuencial_rpa
and secuencial     = @i_secuencial_pag
and operacion      = dtr_operacion
and concepto       = dtr_concepto


--- PROCESO PARA CANCELAR TOTALMENTE LA OPERACION
exec sp_calcula_saldo
     @i_operacion = @i_operacionca,
     @i_tipo_pago = @i_tipo_cobro,
     @o_saldo     = @w_saldo_oper out

if @w_saldo_oper < @w_vlr_despreciable
begin

   if @i_en_linea = 'N'
      select @w_bandera_be = 'S'
   else
      select @w_bandera_be = 'N'
   
   if @w_tramite is not null
   begin
      exec @w_return = cob_custodia..sp_activar_garantia
           @i_opcion         = 'C',
           @i_tramite        = @w_tramite,
           @i_modo           = 2,
           @i_operacion      = 'I',
           @s_date           = @s_date,
           @s_user           = @s_user,
           @s_term           = @s_term,
           @s_ofi            = @s_ofi,
           @i_bandera_be     = @w_bandera_be
      
      if @w_return <> 0
         return @w_return
   end
   
   update ca_operacion
   set    op_estado = @w_est_cancelado
   where  op_operacion = @i_operacionca
   
   if @@error <> 0
      return 710002
	  
   update ca_dividendo
   set    di_estado    = @w_est_cancelado,
          di_fecha_can = @w_fecha_ult_proceso
   where  di_operacion = @i_operacionca
     and  di_estado    <> 3
   
   update ca_amortizacion
   set    am_estado = @w_est_cancelado
   where  am_operacion = @i_operacionca
   
   if @@error <> 0
   begin
      return 710002
   end 

end
      

return 0
go



