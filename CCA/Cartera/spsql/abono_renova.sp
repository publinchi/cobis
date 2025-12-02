/******************************************************************************************/
/* abono_renova.sp Este programa Inserta los abonos que faltan defecto 2537               */
/******************************************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'ca_sin_abono')
   drop table ca_sin_abono
go

create table ca_sin_abono
(
   oper int,
   sec  int
)
go

--select count(1) from ca_sin_abono
go

if exists (select 1 from sysobjects where name = 'sp_pagos_renovacion')
   drop proc sp_pagos_renovacion
go

create proc sp_pagos_renovacion 

as
declare
@w_migrada         cuenta,
@w_banco           cuenta,
@w_operacion       int,   
@w_registros       int,
@w_hora            datetime,
@w_error           int,
@w_secuencial      int,
@w_estado          tinyint,
@w_sec_ing         int,
@w_fecha_cierre    datetime,
@w_fecha_pag       datetime,
@w_sec_ref         int,
@w_monto_mn        money,
@w_monto_mop       money,
@w_monto_mpg       money,
@w_cotizacion_mop  float,
@w_tcotizacion_mop char(1),
@w_usuario         login,
@w_terminal        catalogo,
@w_oficina_usu     int,
@w_op_banco        cuenta



select @w_registros  = 0


select @w_hora = convert(char(10), getdate(),8)

print 'carevisahc.sp A procesar = ' + cast(@w_hora as varchar)


select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select 
       oper,
       sec
from ca_sin_abono
order by oper
open cursor_operacion

fetch cursor_operacion
into  @w_operacion,
      @w_secuencial

--while @@fetch_status not in (-1 ,0)
while @@fetch_status = 0
begin
   select @w_registros = @w_registros +1
   
  --El secuencial de Ingreso
  
  --Recuperar historia antes de hacer cualquier cambio
    select @w_op_banco = op_banco
    from ca_operacion
    where op_operacion = @w_operacion

  
    exec  sp_restaurar
    @i_banco = @w_op_banco

  
   set rowcount 1
   select @w_sec_ing = isnull(max(ap_secuencial_ing ),1)
   from ca_abono_prioridad a
   where ap_operacion = @w_operacion
   and ap_concepto = 'CAP'
   and not exists (select 1 from ca_abono_det
                   where abd_operacion = @w_operacion
                   and a.ap_secuencial_ing = abd_secuencial_ing )
   set rowcount 0
  
   select @w_fecha_pag        = tr_fecha_mov,
   @w_sec_ref          = isnull(tr_secuencial_ref,1),
   @w_monto_mn         = dtr_monto_mn,
   @w_monto_mop        = dtr_monto,
   @w_monto_mpg        = dtr_monto_mn,
   @w_cotizacion_mop   = dtr_cotizacion,
   @w_tcotizacion_mop  =   dtr_tcotizacion,
   @w_usuario          = tr_usuario,
   @w_terminal         = tr_terminal,
   @w_oficina_usu      = tr_ofi_usu
   from ca_transaccion,
        ca_det_trn
   where tr_operacion = @w_operacion
   and tr_secuencial  = @w_secuencial
   and dtr_operacion  = tr_operacion
   and dtr_secuencial = tr_secuencial
   and dtr_concepto in ('VAC0','VAC2')

  if  @@rowcount > 0 and @w_sec_ing > 1 and @w_sec_ref > 1
  begin
         
--     PRINT 'ACTUALIZAR oper %1!' + cast(@w_op_banco as varchar)
         
	  insert into ca_abono
             (ab_secuencial_ing,     ab_secuencial_rpa,      ab_secuencial_pag,          ab_operacion,      ab_fecha_ing,
              ab_fecha_pag,          ab_cuota_completa,      ab_aceptar_anticipos,       ab_tipo_reduccion, ab_tipo_cobro,
              ab_dias_retencion_ini, ab_dias_retencion,      ab_estado,                  ab_usuario,        ab_oficina,
			  ab_terminal,           ab_tipo,                ab_tipo_aplicacion,         ab_nro_recibo,     ab_tasa_prepago,
              ab_dividendo,          ab_calcula_devolucion,  ab_prepago_desde_lavigente, ab_extraordinario)	  
      values (@w_sec_ing,            @w_sec_ref,             @w_secuencial,              @w_operacion ,     @w_fecha_pag,
              @w_fecha_pag,          'N',                    'S',                        'N',               'A',
              0,                     0,                      'A',                        @w_usuario,        @w_oficina_usu,
              @w_terminal,           'PAG',                  'D',                        0,                 0.0,
              0,                     'N',                    'N',                        null)
	
	  insert into ca_abono_det
             (abd_secuencial_ing, abd_operacion,      abd_tipo,            abd_concepto,        abd_cuenta,
              abd_beneficiario,   abd_moneda,         abd_monto_mpg,       abd_monto_mop,       abd_monto_mn,
              abd_cotizacion_mpg, abd_cotizacion_mop, abd_tcotizacion_mpg, abd_tcotizacion_mop, abd_cheque,
              abd_cod_banco,      abd_inscripcion,    abd_carga)	  
      values (@w_sec_ing,         @w_operacion,       'PAG',               'CARTERA',           '0',
              'PAGO RENOVACION',  0,                  @w_monto_mpg,        @w_monto_mop,        @w_monto_mn,
              1,                  @w_cotizacion_mop,  'T',                 'T',                 0,
              '',                 0,                  0)

end
else
  PRINT 'abono_renova.sp NO EXISTE SEC  Oper  banco ' + cast(@w_secuencial as varchar) + cast(@w_operacion as varchar) + cast(@w_op_banco as varchar)


   fetch cursor_operacion
   into  @w_operacion,
         @w_secuencial
end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

print 'pago_renova.sp Finalizo  = ' + cast(@w_registros as varchar) + cast(@w_hora as varchar)

return 0
go

