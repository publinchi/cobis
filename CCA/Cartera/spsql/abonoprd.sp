/************************************************************************/
/*      Archivo:                abonoprd.sp                             */
/*      Stored procedure:       sp_abono_otros_productos                */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           R Garces, F Yacelga(SYSCONSULTING)      */
/*      Fecha de escritura:     Ene 1998                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*				PROPOSITO				*/
/*	Aplicar pagos desde otros productos                             */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abono_otros_productos')
    drop proc sp_abono_otros_productos
go

create proc sp_abono_otros_productos(

   @s_sesn             int          = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              smallint     = null,
   @s_term             varchar (30) = null,
   @i_fecha            datetime     = null,
   @i_banco            cuenta       = null,
   @i_cuenta           cuenta       = null,
   @i_moneda	       tinyint      = null,
   @i_monto            money        = null,
   @i_cotizacion_mpg   float        = 1,
   @i_cotizacion_mop   float        = 1,
   @i_tcotizacion_mpg  char(1)      = 'N',
   @i_tcotizacion_mop  char(1)      = 'N', 
   @i_fpago            catalogo     = null,
   @i_beneficiario     descripcion  = null   
)

as
declare
   @w_today              datetime,
   @w_return             int,
   @w_sp_name            varchar(32),
   @w_error              int,
   @w_operacionca        int,
   @w_reduccion          char(1),
   @w_cobro              char(1),
   @w_ult_proceso        datetime,
   @w_tipo_aplicacion    char(1),
   @w_p_int              int,
   @w_p                  varchar(3),
   @w_prioridad          varchar(255),
   @w_sec                int,
   @w_monto_mop          money,
   @w_monto_mn           money,
   @w_decimales          tinyint,
   @w_moneda_op          tinyint

select @w_sp_name = 'sp_abono_otros_productos'

select 
@w_operacionca     = op_operacion,
@w_reduccion       = op_tipo_reduccion,
@w_cobro           = op_tipo_cobro,
@w_ult_proceso     = op_fecha_ult_proceso,
@w_tipo_aplicacion = op_tipo_aplicacion,
@w_moneda_op       = op_moneda
from ca_operacion 
where op_banco = @i_banco

if @@rowcount = 0 
begin
   select @w_error =  701025
   goto ERROR
end

/** MANEJO DE DECIMALES **/
exec @w_return = sp_decimales
@i_moneda      = @w_moneda_op,
@o_decimales   = @w_decimales out

if @w_return != 0  
begin
   select @w_error =  @w_return 
   goto ERROR
end

select
@w_monto_mop = round(@i_monto * @i_cotizacion_mpg/@i_cotizacion_mop,@w_decimales),
@w_monto_mn  = round(@i_monto * @i_cotizacion_mpg,@w_decimales)


/**CREACION DE TABLAS TEMPORALES **/
create table #total_prioridad(
prioridad int,
total money
)

if @@fetch_status != 0
begin
   select @w_error = 700000 -- CAMBIAR NUMERO DE ERROR
   goto ERROR         
end  


create table #estado_concepto (
concepto catalogo,
estado smallint
)      

if @@fetch_status <> 0
begin
   select @w_error = 700000 -- CAMBIAR NUMERO DE ERROR
   goto ERROR         
end  


exec @w_return = sp_ing_detabono_int
@s_user	           = @s_user,
@s_date	           = @s_date,
@s_sesn	           = @s_sesn,
@i_accion	   = 'I',
@i_encerar	   = 'S', 
@i_tipo	           = 'PAG',
@i_concepto	   = @i_fpago,
@i_cuenta	   = @i_cuenta,
@i_moneda	   = @i_moneda,
@i_beneficiario    = @i_beneficiario,
@i_monto_mpg	   = @i_monto,
@i_monto_mop	   = @w_monto_mop , 	
@i_monto_mn	   = @w_monto_mn,
@i_cotizacion_mpg  = @i_cotizacion_mpg,
@i_cotizacion_mop  = @i_cotizacion_mop,
@i_tcotizacion_mpg = @i_tcotizacion_mpg,
@i_tcotizacion_mop = @i_tcotizacion_mop


if @w_return <> 0 
begin
   select @w_error =  @w_return
   goto ERROR
end


select @w_prioridad = ''
      
declare cursor_prioridades cursor for
select ro_prioridad
from  ca_rubro_op, ca_concepto
where ro_operacion = @w_operacionca
and   ro_concepto  = co_concepto
and   ro_fpago     not in ('L','B')
for read only

open cursor_prioridades

fetch cursor_prioridades into @w_p_int

while   @@fetch_status = 0 
begin
   if (@@fetch_status = -1) 
   begin
      select @w_error = 710004
      goto ERROR
   end  

   select @w_p = convert(varchar(3), @w_p_int)

   if @w_prioridad =''
      select @w_prioridad = @w_p      
   else
      select @w_prioridad = @w_prioridad + ';' + @w_p      

   fetch cursor_prioridades into  @w_p_int
end
close cursor_prioridades
deallocate cursor_prioridades

select @w_prioridad = @w_prioridad + '#'

exec @w_return = sp_ing_abono_int
@s_user	           = @s_user,
@s_term	           = @s_term,
@s_date	           = @s_date,
@s_sesn	           = @s_sesn,
@s_ofi 	           = @s_ofi,
@t_trn	           = 7058,
@i_accion          = 'I',
@i_banco           = @i_banco,
@i_tipo	           = 'PAG',
@i_fecha_vig       = @w_ult_proceso,
@i_ejecutar        = 'S',
@i_retencion	   = 0,
@i_cuota_completa  = 'N',
@i_anticipado      = 'S',
@i_tipo_reduccion  = @w_reduccion,
@i_proyectado      = @w_cobro,
@i_tipo_aplicacion = @w_tipo_aplicacion,
@i_prioridades     = @w_prioridad,
@o_secuencial_ing  = @w_sec out

if @w_return <> 0 
begin
   select @w_error =  @w_return
   goto ERROR
end


return 0

ERROR:
   return @w_error

go
