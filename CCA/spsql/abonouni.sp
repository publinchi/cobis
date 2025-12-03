/************************************************************************/
/*   Archivo:              abonouni.sp                                  */
/*   Stored procedure:     sp_unificar_pagos                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Xavier Maldonado                             */
/*   Fecha de escritura:   Feb.2005                                     */
/************************************************************************/
/*                         IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*                                                                      */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre         Proposito                        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'tmp_pagos_uni')
   drop table tmp_pagos_uni 
go

create table tmp_pagos_uni
(ab_operacion      int null, 
 cp_producto       catalogo null,
 abd_cuenta        cuenta   null,
 ab_secuencial_i   int      null,
 ab_estado         char(3)  null,
 abd_monto_mpg     money    null,
 abd_monto_mop     money    null,
 abd_monto_mn      money    null
)
go

if exists (select 1 from sysobjects where name = 'sp_unificar_pagos')
   drop proc sp_unificar_pagos
go

create proc sp_unificar_pagos
   @i_fecha_proceso        datetime = null
as
declare 
   @w_error                int,
   @w_sp_name              descripcion,
   @w_ab_operacion         int,
   @w_forma_pago           catalogo,
   @w_fin                  int,
   @w_secuencial_or        int,
   @w_ab_fecha_pag         datetime,
   @w_secuencial_new       int,
   @w_abd_monto_mpg        money,
   @w_numero               int,
   @w_ab_tipo_reduccion    char(1),
   @w_abd_monto_mop        money,
   @w_ab_tipo_cobro        char(1),
   @w_abd_monto_mn         money,
   @w_secuencial_w         int,
   @w_ab_tipo_aplicacion   char(1),
   @w_concepto             catalogo,
   @w_prioridad            tinyint,
   @w_fecha_proceso        datetime,
   @s_user                 catalogo,
   @w_cuota_completa       char(1),
   @w_anticipado           char(1),
   @w_proyectado           char(1),
   @w_retencion            int,
   @w_secuencial_ing       int,
   @w_banco                cuenta,
   @w_user                 login,
   @w_descripcion          descripcion,
   @w_term                 catalogo,
   @w_cp_producto          catalogo,
   @w_secuencial_consulta  int,
   @w_ab_secuencial_ing    int,
   @w_ofi                  smallint,
   @w_numero_recibo        int,
   @w_abd_cuenta           cuenta,
   @w_secuencial_w1        int,
   @w_operacion            int, 
   @w_producto             catalogo, 
   @w_cuenta               cuenta,
   @w_ab_estado            char(3),
   @w_ab_estado_uni        char(3),
   @w_ab_estado_or         char(3),
   @w_secuencial_retro     int,
   @w_nro_oficinas_orig    int,
   
   @w_er                   int,
   @w_rc                   int,
   @w_exist                int,
   @w_valor                catalogo

select @w_sp_name  = 'sp_unificar_pagos'

-- FECHA PRODUCTO DE CARTERA
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

-- INSERTAR DATOS EN TABLA TEMPORAL ABONOS EN ESTADO APLICADOS E INGRESADOS
select ab_operacion,  ab_fecha_pag,       ab_tipo_reduccion, 
       ab_tipo_cobro, ab_tipo_aplicacion, count(1) numero
into   #abonos_ingresados
from   ca_abono, ca_operacion
where  ab_operacion = op_operacion
and    op_naturaleza = 'A'
and    op_estado     in (1,2,3,9,97,37)
and    ab_estado  in ('ING', 'A')
and    ab_fecha_pag = @i_fecha_proceso
group by ab_operacion,ab_fecha_pag, ab_tipo_reduccion, ab_tipo_cobro, ab_tipo_aplicacion
having count(1) > 1

select @w_exist = 1
from   ca_producto, ca_abono_det, A.ab_operacion
where  abd_operacion = A.ab_operacion
and    abd_secuencial_ing = A.ab_secuencial_ing
and    abd_tipo           = 'PAG'
and    cp_producto        = abd_concepto
and    cp_pcobis         in (3,4, 48)
and    cp_afectacion      = 'D'


if @w_exist = 1
   select @w_valor = 'CON'
   
-- INSERTAR LOS SECUENCIALES DE LAS CARACTERISTICAS
select A.ab_estado, A.ab_operacion, A.ab_secuencial_ing, 
       isnull(@w_valor, tr_estado)
into   #estado_original
from   #abonos_ingresados I, ca_abono A, ca_transaccion
where  A.ab_operacion = I.ab_operacion
and    A.ab_fecha_pag = I.ab_fecha_pag
and    A.ab_estado   in ('A', 'ING')
and    A.ab_tipo_reduccion = I.ab_tipo_reduccion
and    A.ab_tipo_cobro     = I.ab_tipo_cobro
and    A.ab_tipo_aplicacion = I.ab_tipo_aplicacion
and    tr_operacion = A.ab_operacion
and    tr_secuencial = A.ab_secuencial_rpa

-- INSERTAR DATOS EN TABLA TEMPORAL ABONOS APLICADOS
select ab_operacion,  ab_fecha_pag,       ab_tipo_reduccion,
       ab_tipo_cobro, ab_tipo_aplicacion, ab_secuencial_pag
into   #abonos_aplicados
from   ca_abono A
where  A.ab_estado  = 'A'
and    A.ab_fecha_pag = @i_fecha_proceso
and    exists(select 1 -- SOLO SE REVERSAN DE LAS OBLIGACIONES QUE UNIFICAN
              from   #abonos_ingresados
              where  ab_operacion        = A.ab_operacion
              and    ab_fecha_pag        = A.ab_fecha_pag
              and    ab_tipo_reduccion   = A.ab_tipo_reduccion
              and    ab_tipo_cobro       = A.ab_tipo_cobro
              and    ab_tipo_aplicacion  = A.ab_tipo_aplicacion)

-- PROCESO DE REVERSA MASIVA DE ABONOS APLICADOS
declare 
   cursor_reversa_abonos cursor 
   for select ab_operacion,  ab_fecha_pag,        ab_tipo_reduccion,
              ab_tipo_cobro, ab_tipo_aplicacion,  ab_secuencial_pag
       from   #abonos_aplicados
       order  by ab_operacion asc, ab_secuencial_pag desc
   for read only

open  cursor_reversa_abonos
   
fetch cursor_reversa_abonos
into  @w_ab_operacion,  @w_ab_fecha_pag,       @w_ab_tipo_reduccion,
      @w_ab_tipo_cobro, @w_ab_tipo_aplicacion, @w_secuencial_retro

while @@fetch_status = 0 
begin
   if @@fetch_status = -1 
   begin    
      PRINT '...en lectura del cursor cursor_leer_abonos'
      goto ERROR
   end
   
   select @w_nro_oficinas_orig = count(distinct ab_oficina)
   from   ca_abono
   where  ab_operacion       = @w_ab_operacion
   and    ab_fecha_pag       = @w_ab_fecha_pag
   and    ab_tipo_reduccion  = @w_ab_tipo_reduccion
   and    ab_tipo_cobro      = @w_ab_tipo_cobro
   and    ab_tipo_aplicacion = @w_ab_tipo_aplicacion
   
   if @w_nro_oficinas_orig > 1
   begin
      while @@trancount > 0 rollback
      
      fetch cursor_reversa_abonos
      into  @w_ab_operacion,  @w_ab_fecha_pag,       @w_ab_tipo_reduccion,
            @w_ab_tipo_cobro, @w_ab_tipo_aplicacion, @w_secuencial_retro
      
      CONTINUE
   end
   select @w_banco  = '',
          @w_ofi    = 0
   
   -- VERIFICA QUE NO EXISTA OTRAS OPERACIONES MANUALES
   if exists (select 1
              from   ca_transaccion
              where  tr_operacion   = @w_ab_operacion
              and    tr_secuencial > @w_secuencial_retro
              and    tr_estado     <> 'RV'
              and    tr_tran       in ('DES', 'IOC','RES','TCO','PRO','AJP','MPC','ETM','SUM','ACE','CAS'))
   begin
      select @w_error = 710075
      goto ERROR10
   end
   
   select @w_banco    =  op_banco
   from   ca_operacion
   where  op_operacion = @w_ab_operacion
   
   exec @w_error   = sp_fecha_valor
        @s_user          = 'abonouni',
        @s_term          = 'abonouni',
        @s_date          = @w_fecha_proceso,
        @i_banco         = @w_banco,
        @i_secuencial    = @w_secuencial_retro,
        @i_en_linea      = 'N',
        @i_operacion     = 'R'
   
   if @w_error <> 0 
   begin
      print '@w_error .. ' + cast(@w_error as varchar)
      goto ERROR10
   end
   ELSE
   begin
      update ca_abono
      set    ab_terminal          = 'UNIFICACION'
      from   ca_abono 
      where  ab_operacion         = @w_ab_operacion
      and    ab_secuencial_pag    = @w_secuencial_retro
   end
   
   goto SIGUIENTE20
   
   ERROR10:
   begin
      print 'ingresa en error 10'
      exec sp_errorlog
           @i_fecha     = @w_fecha_proceso,
           @i_error     = @w_error,
           @i_usuario   = 'OPERADOR',
           @i_tran      = 75000, 
           @i_tran_name = @w_sp_name,
           @i_rollback  = 'N',
           @i_cuenta    = @w_banco,
           @i_anexo     = ''    ----@w_anexo
          
      goto SIGUIENTE20
   end
   
   SIGUIENTE20:
   fetch cursor_reversa_abonos
   into  @w_ab_operacion,  @w_ab_fecha_pag,       @w_ab_tipo_reduccion,
         @w_ab_tipo_cobro, @w_ab_tipo_aplicacion, @w_secuencial_retro
end

close cursor_reversa_abonos 
deallocate cursor_reversa_abonos

-- CURSOR TABLA TEMPORAL
declare 
   cursor_leer_abonos cursor 
   for select ab_operacion,  ab_fecha_pag,        ab_tipo_reduccion,
              ab_tipo_cobro, ab_tipo_aplicacion,  numero
       from   #abonos_ingresados
   for read only
open  cursor_leer_abonos

fetch cursor_leer_abonos
into  @w_ab_operacion,  @w_ab_fecha_pag,       @w_ab_tipo_reduccion,
      @w_ab_tipo_cobro, @w_ab_tipo_aplicacion, @w_numero

while @@fetch_status = 0 
begin
   if @@fetch_status = -1 
   begin    
      PRINT '...en lectura del cursor cursor_leer_abonos'
      goto ERROR
   end
   
   select @w_nro_oficinas_orig = count(distinct ab_oficina)
   from   ca_abono
   where  ab_operacion       = @w_ab_operacion
   and    ab_fecha_pag       = @w_ab_fecha_pag
   and    ab_tipo_reduccion  = @w_ab_tipo_reduccion
   and    ab_tipo_cobro      = @w_ab_tipo_cobro
   and    ab_tipo_aplicacion = @w_ab_tipo_aplicacion
   
   if @w_nro_oficinas_orig > 1
   begin
      while @@trancount > 0 rollback
      BEGIN TRAN
      insert into ca_errorlog
            (er_fecha_proc,      er_error,   er_usuario,
             er_tran,            er_cuenta,  er_descripcion,
             er_anexo)
      values(@w_fecha_proceso,   1,          'OPERADOR',
             0,                  @w_banco,   'ESTA OBLIGACION TIENE PAGOS QUE NO SE PUEDEN UNIFICAR',
             'NUMERO DE OFICINAS ' + convert(varchar, @w_nro_oficinas_orig))
      
      COMMIT TRAN
      
      fetch cursor_leer_abonos
      into  @w_ab_operacion,  @w_ab_fecha_pag,       @w_ab_tipo_reduccion,
            @w_ab_tipo_cobro, @w_ab_tipo_aplicacion, @w_numero
      
      CONTINUE
   end
   
   select @w_secuencial_consulta  = 0,
          @w_secuencial_new = 0,
          @w_numero_recibo  = 0,
          @w_banco  = '',
          @w_ofi    = 0
   
   -- CALCULO DEL SEC. DE PAGO
   select @w_secuencial_consulta  =  max(ab_secuencial_ing)
   from   ca_abono
   where  ab_operacion       = @w_ab_operacion
   and    ab_fecha_pag       = @w_ab_fecha_pag
   and    ab_tipo_reduccion  = @w_ab_tipo_reduccion
   and    ab_tipo_cobro      = @w_ab_tipo_cobro
   and    ab_tipo_aplicacion = @w_ab_tipo_aplicacion
   
   if @@rowcount = 0
   begin
      select @w_error = 710245  ---710244
      goto ERROR1
   end
   
   -- OP_BANCO
   select @w_banco = op_banco,  
          @w_ofi   = op_oficina
   from   ca_operacion
   where  op_operacion  = @w_ab_operacion
   
   if @@rowcount = 0
   begin
      select @w_error = 710250
      goto ERROR1
   end
   
   -- SECUENCIAL DEL PAGO UNIFICADO
   exec @w_secuencial_new = sp_gen_sec
        @i_operacion      = @w_ab_operacion
   
   exec @w_error  = sp_numero_recibo
        @i_tipo    = 'P',
        @i_oficina = @w_ofi,
        @o_numero  = @w_numero_recibo out
            
   if @w_error != 0
   begin
      goto ERROR1
   end
   
   -- CABECERA
   -- INSERCION DE CA_ABONO
   insert into ca_abono
         (ab_operacion,      ab_fecha_ing,          ab_fecha_pag,
          ab_cuota_completa, ab_aceptar_anticipos,  ab_tipo_reduccion,
          ab_tipo_cobro,     ab_dias_retencion_ini, ab_dias_retencion,
          ab_estado,         ab_secuencial_ing,     ab_secuencial_rpa,
          ab_secuencial_pag, ab_usuario,            ab_terminal,
          ab_tipo,           ab_oficina,            ab_tipo_aplicacion,
          ab_nro_recibo,     ab_tasa_prepago,       ab_dividendo,
          ab_calcula_devolucion,                    ab_prepago_desde_lavigente)
   select ab_operacion,      ab_fecha_ing,          ab_fecha_pag,
          ab_cuota_completa, ab_aceptar_anticipos,  ab_tipo_reduccion,
          ab_tipo_cobro,     ab_dias_retencion_ini, ab_dias_retencion,
          'ING',             @w_secuencial_new,     0,
          0,                 'UNIFICACION',         'CONSOLA_UNIFICACION',
          ab_tipo,           ab_oficina,            ab_tipo_aplicacion,
          @w_numero_recibo,  ab_tasa_prepago,       ab_dividendo,                       ---ojo nro_recibo
          ab_calcula_devolucion,                    ab_prepago_desde_lavigente
   from   ca_abono
   where  ab_operacion       = @w_ab_operacion
   and    ab_fecha_pag       = @w_ab_fecha_pag
   and    ab_tipo_reduccion  = @w_ab_tipo_reduccion
   and    ab_tipo_cobro      = @w_ab_tipo_cobro
   and    ab_tipo_aplicacion = @w_ab_tipo_aplicacion
   and    ab_secuencial_ing  = @w_secuencial_consulta
   
   if @@error != 0 or @@rowcount = 0
   begin
      select @w_error = 710294
      goto ERROR1
   end
   
   -- INSERT DE CA_ABONO_PRIORIDAD
   insert into ca_abono_prioridad
         (ap_secuencial_ing,      ap_operacion,      ap_concepto,   ap_prioridad)
   select @w_secuencial_new,      ap_operacion,      ap_concepto,   ap_prioridad 
   from   ca_abono_prioridad
   where  ap_operacion      = @w_ab_operacion
   and    ap_secuencial_ing = @w_secuencial_consulta
   
   if @@error != 0 or @@rowcount = 0
   begin
      select @w_error = 710234
      goto ERROR1
   end
   
   -- DETALLE
   -- LOS NO APLICADOS o LOS APLICADOS NO CONTABILIZADOS
   insert into ca_abono_det
         (abd_secuencial_ing,       abd_operacion,             abd_tipo,
          abd_concepto,             abd_cuenta,                abd_beneficiario,
          abd_moneda,               abd_monto_mpg,             abd_monto_mop,
          abd_monto_mn,             abd_cotizacion_mpg,        abd_cotizacion_mop,
          abd_tcotizacion_mpg,      abd_tcotizacion_mop,       abd_cheque,
          abd_cod_banco,            abd_inscripcion,           abd_carga)
   select @w_secuencial_new,        abd_operacion,             abd_tipo,
          abd_concepto,             abd_cuenta,                max(abd_beneficiario),
          min(abd_moneda),          sum(abd_monto_mpg),        sum(abd_monto_mop),
          sum(abd_monto_mn),        avg(abd_cotizacion_mpg),   avg(abd_cotizacion_mop),
          max(abd_tcotizacion_mpg), max(abd_tcotizacion_mop),  max(abd_cheque),
          max(abd_cod_banco),       max(abd_inscripcion),      max(abd_carga)
   from   #estado_original, ca_abono_det
   where  abd_secuencial_ing = ab_secuencial_ing
   and    abd_operacion      = ab_operacion
   and    (ab_estado          = 'ING' or tr_estado         != 'CON')
   and    ab_operacion       = @w_ab_operacion
   group  by abd_operacion, abd_tipo, abd_concepto, abd_cuenta
   
   -- LOS APLICADOS CONTABILIZADOS
   insert into ca_abono_det
         (abd_secuencial_ing,       abd_operacion,             abd_tipo,
          abd_concepto,             abd_cuenta,                abd_beneficiario,
          abd_moneda,               abd_monto_mpg,             abd_monto_mop,
          abd_monto_mn,             abd_cotizacion_mpg,        abd_cotizacion_mop,
          abd_tcotizacion_mpg,      abd_tcotizacion_mop,       abd_cheque,
          abd_cod_banco,            abd_inscripcion,           abd_carga)
   select @w_secuencial_new,        abd_operacion,             abd_tipo,
          cp_producto_reversa,      abd_cuenta,                max(abd_beneficiario),
          min(abd_moneda),          sum(abd_monto_mpg),        sum(abd_monto_mop),
          sum(abd_monto_mn),        avg(abd_cotizacion_mpg),   avg(abd_cotizacion_mop),
          max(abd_tcotizacion_mpg), max(abd_tcotizacion_mop),  max(abd_cheque),
          max(abd_cod_banco),       max(abd_inscripcion),      max(abd_carga)
   from   #estado_original, ca_abono_det, ca_producto
   where  abd_secuencial_ing = ab_secuencial_ing
   and    abd_operacion      = ab_operacion
   and    (ab_estado         = 'A' and tr_estado = 'CON')
   and    ab_operacion       = @w_ab_operacion
   and    abd_concepto       = cp_producto
   group  by abd_operacion, abd_tipo, cp_producto_reversa, abd_cuenta
ERROR1:
   exec sp_errorlog
        @i_fecha     = @w_fecha_proceso,
        @i_error     = @w_error,
        @i_usuario   = 'OPERADOR',
        @i_tran      = 75000, 
        @i_tran_name = @w_sp_name,
        @i_rollback  = 'N',
        @i_cuenta    = @w_banco,
        @i_anexo     = ''    ----@w_anexo
    
   goto SIGUIENTE2
   
SIGUIENTE2:
   fetch cursor_leer_abonos
   into  @w_ab_operacion,  @w_ab_fecha_pag,       @w_ab_tipo_reduccion, 
         @w_ab_tipo_cobro, @w_ab_tipo_aplicacion, @w_numero
end

close cursor_leer_abonos 
deallocate cursor_leer_abonos 

return 0

ERROR:
print 'ingresa...en errror'
insert into ca_errorlog
      (er_fecha_proc,      er_error,      er_usuario,
       er_tran,            er_cuenta,     er_descripcion,
       er_anexo)
values(@w_fecha_proceso,   @w_error,      'OPERADOR',
       75000,               @w_banco,      @w_descripcion,
       'PAGOS_UNIFICADOS')
return @w_error    
go
