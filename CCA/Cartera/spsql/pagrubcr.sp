/************************************************************************/
/*   Archivo:              pagrubcr.sp                                  */
/*   Stored procedure:     sp_abono_rubros_colchon                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         ELcira Pelaez                                */   
/*   Fecha de escritura:   nov-17-2001                                  */ 
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                             PROPOSITO                                */
/*   Procedimiento que realiza el abono de mora pagado con el           */
/*      colchon de descuento de documentos                              */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abono_rubros_colchon')
   drop proc sp_abono_rubros_colchon
go

create proc sp_abono_rubros_colchon
@s_ofi                  smallint,
@s_sesn                 int,
@s_user                 login,
@s_term                 varchar (30) = NULL,
@s_date                 datetime     = NULL,
@i_secuencial_ing       int,
@i_secuencial_pag       int,
@i_div_vigente          int,
@i_fecha_pago           datetime = NULL,
@i_en_linea             char(1) = 'N',
@i_tipo_cobro           char(1) = 'A',
@i_operacionca          int,
@i_dividendo            int = 0

as 
declare 
@w_return             int,
@w_sp_name            varchar(30),
@w_concepto           catalogo,
@w_est_cancelado      smallint,
@w_est_novigente      smallint,
@w_monto_rubro        money,
@w_monto_con          money,
@w_dividendo          int,
@w_tcotizacion        char(1),
@w_cotizacion         money,
@w_fecha_ven          datetime,
@w_fpago              char(1)



/** CARGADO DE VARIABLES DE TRABAJO **/
select 
@w_sp_name   = 'sp_abono_rubros_colchon',
@w_est_cancelado = 3,
@w_est_novigente = 0


/** RUBROS A SER CUBIERTOS POR EL COLCHON **/      
declare cursor_condonaciones cursor for
select
abd_concepto, 
abd_monto_mop,
abd_cotizacion_mop,
abd_tcotizacion_mop
from ca_abono_det
where abd_secuencial_ing = @i_secuencial_ing
and  abd_operacion = @i_operacionca
and   abd_tipo = 'COL'
for read only

open cursor_condonaciones

fetch cursor_condonaciones 
into @w_concepto,@w_monto_con,@w_cotizacion,@w_tcotizacion

--while   @@fetch_status not in (-1,0) 
while   @@fetch_status = 0
begin 

 
  if @i_dividendo = 0
   declare cursor_dividendos cursor for
   select
   di_dividendo,
   di_fecha_ven
   from ca_dividendo
   where di_operacion = @i_operacionca
   and di_estado != @w_est_cancelado
   for read only
 else
   declare cursor_dividendos cursor for
   select
   di_dividendo,
   di_fecha_ven
   from ca_dividendo
   where di_operacion = @i_operacionca
   and di_estado != @w_est_cancelado
   and di_dividendo = @i_dividendo
   for read only
   
   open cursor_dividendos

   fetch cursor_dividendos into @w_dividendo,@w_fecha_ven

   --while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin
    
        update ca_rubro_op
        set ro_valor = ro_valor - @w_monto_con
        where ro_operacion = @i_operacionca
        and ro_concepto = 'COL'
        if @@error != 0 return 710317


      exec @w_return = sp_monto_pago_rubro
      @i_operacionca = @i_operacionca,
      @i_dividendo = @w_dividendo,
      @i_tipo_cobro = @i_tipo_cobro,
      @i_fecha_pago = @i_fecha_pago,
      @i_dividendo_vig = @i_div_vigente,
      @i_concepto = @w_concepto,
      @o_monto   = @w_monto_rubro out

      if @w_return != 0
         return @w_return


      select @w_fpago = ro_fpago from ca_rubro_op
             where ro_operacion = @i_operacionca
               and ro_concepto  = @w_concepto
     

      exec @w_return = sp_abona_rubro
      @s_ofi         = @s_ofi,
      @s_sesn         = @s_sesn,
      @s_user        = @s_user,
      @s_date         = @s_date,
      @s_term         = @s_term,
      @i_secuencial_pag   = @i_secuencial_pag,     
      @i_operacionca       = @i_operacionca,
      @i_dividendo      = @w_dividendo,
      @i_concepto      = @w_concepto,
      @i_monto_pago      = @w_monto_con,
      @i_monto_prioridad  = @w_monto_rubro,   
      @i_monto_rubro      = @w_monto_rubro,
      @i_tipo_cobro      = @i_tipo_cobro,
      @i_fpago              = @w_fpago,
      @i_en_linea      = @i_en_linea,
      @i_fecha_pago      = @i_fecha_pago,
/*      @i_fecha_ven      = @w_fecha_ven,  */
      @i_condonacion     = 'S',
      @i_colchon     = 'S',
      @i_cotizacion      = @w_cotizacion,
      @i_tcotizacion     = @w_tcotizacion,
      @o_sobrante_pago    = @w_monto_con out

      if (@w_return != 0) 
         return @w_return


      if @w_monto_con <= 0 
      begin
         break 
      end

      fetch cursor_dividendos into @w_dividendo,@w_fecha_ven
   end
   close cursor_dividendos
   deallocate cursor_dividendos
 
   fetch cursor_condonaciones into @w_concepto,@w_monto_con,@w_cotizacion,
   @w_tcotizacion
   

end 
close cursor_condonaciones
deallocate cursor_condonaciones




return 0
go


