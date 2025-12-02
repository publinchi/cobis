/************************************************************************/
/*   Archivo              :   genafopr.sp                               */
/*   Stored procedure     :   sp_genera_afect_productos                 */
/*   Base de datos        :   cob_cartera                               */
/*   Producto             :   Cartera                                   */
/*   Disenado por         :   Fabian de la Torre                        */
/*   Fecha de escritura   :   Jul. 1997                                 */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Procedimiento que realiza la insercion de registros para           */
/*   realizar abonos automaticos a operaciones de cartera               */
/************************************************************************/
/*                      MODIFICACIONES                                  */
/************************************************************************/
/*   FECHA        AUTOR                     RAZON                       */
/*   09-05-2017   Milton Custode            validacion cuentas AHO      */
/*   02-22-2019   Adriana Giler             validacion cuentas AHO FP   */
/*   12-08-2019   Luis Ponce                Pago Grupal con debito batch*/
/*   17/03/2020   Luis Ponce         CDIG AJUSTE EN BATCH POR CONTROL DE*/
/*                                   COMMIT EN SPS'S DE AHORROS         */
/*   27/03/2020   Luis Ponce         CDIG Ajustes migracion a Java      */
/*   06/08/2020   Sandro Vallejo     Debitos Paralelo                   */
/*   20/10/2021   G. Fernandez       Ingreso de nuevo campo de          */
/*                                       solidario en ca_abono_det      */
/************************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_genera_afect_productos')
   drop proc sp_genera_afect_productos
go
create proc sp_genera_afect_productos
@s_user                  login,
@s_term                  varchar(30),
@s_ofi                   smallint,
@s_date                  datetime,
@s_sesn                  int       = null,   -- FCP Interfaz Ahorros
@i_operacionca           int,
@i_aceptar_anticipos     char(1)   = null,
@i_tipo_reduccion        char(1)   = null,
@i_tipo_cobro            char(1)   = null,
@i_tipo_aplicacion       char(1)   = null,
@i_forma_pago            catalogo  = null,
@i_cuenta                cuenta    = null,
@i_cheque                int       = null,
@i_cod_banco             catalogo  = null,
@i_debug                 char(1)   = 'N',
@i_en_linea              char(1)   = 'N',
@i_cotizacion            money     = 1.00,
@i_num_dec               smallint  = 2,
@i_fecha_proceso         datetime  = null,
@i_ciudad_nacional       int       = NULL,
@i_tipo_grupal           CHAR(1)   = NULL, --LPO TEC Pago Grupal con debito batch
@i_control_intentos      char(1)   = 'S'   --SVA Debitos Paralelo 

as declare
@w_secuencial             int,
@w_secuencial_cr          int,
@w_error                  int,
@w_op_moneda              int,
@w_op_oficina             int,
@w_sp_name                descripcion,
@w_nid                    tinyint,
@w_di_intento             smallint,
@w_monto                  money,
@w_fecha_proceso          datetime,
@w_banco                  cuenta,
@w_commit                 char(1),
@w_valor_debitado         money,
@w_pagos                  money,
@w_retencion              smallint,
@w_est_cancelado          int,
@w_est_vigente            tinyint,
@w_ssn                    int,
@w_msg                    varchar(100),
@w_mmdc                   money,
@w_saldo_disponible       money,
@w_causa                  varchar(20),
@w_pcobis                 tinyint,
@w_div                    smallint,
@w_is_batch               char(1),
@w_cc_estado              catalogo,
@w_ah_stado               catalogo,
@w_tflexible              catalogo,
@w_op_tipo_amortiza       catalogo,
@w_est_vencido            int,
@w_monto_vencido          money,
@w_monto_pagado_vig       money,
@w_monto_disponible       money,
@w_ah_estado              varchar(5),
--@w_cre_grp              VARCHAR(10),
@w_toperacion             VARCHAR(10),
@w_por_ahorro             MONEY, --varchar(255),
@w_ahorro_ind             MONEY,
@w_cliente                INT,
@w_cta_grp                cuenta,
@w_div_vigente            int,
@w_ente_grupal            int,
@w_saldo_disponiblef      money,
@w_saldo_contable         money,
@w_cuenta                 int

SELECT @w_por_ahorro = 0
if @i_en_linea ='S'
   select @w_is_batch = 'N'
else
   select @w_is_batch = 'S'

--- PARAMETRO CREDITO GRUPALES IYU
/*
SELECT @w_cre_grp = pa_char
FROM cobis..cl_parametro
WHERE pa_nemonico = 'CREGRP'
AND pa_producto = 'CCA'
*/

--- CARGADO DE VARIABLES DE TRABAJO
select
@w_sp_name              = 'sp_genera_afect_productos',
@w_commit               = 'N',
@w_est_cancelado        = 3,
@w_est_vigente          = 1,
@w_est_vencido          = 2,
@w_causa                = 310 ---Para efectos del consulta de disponible no afecta
                              ---el envio de esta variable
select @w_tflexible = ''

select @w_tflexible = pa_char
from   cobis..cl_parametro
where  pa_producto  = 'CCA'
and    pa_nemonico  = 'TFLEXI'
set transaction isolation level read uncommitted


if exists(select 1 from cobis..cl_dias_feriados  ---NO INTENTA DE DEBITO CUANDO ES FESTIVO
where df_ciudad = @i_ciudad_nacional
and   df_fecha  = @i_fecha_proceso)
begin

   --- DETERMINAR EL NUMERO DE INTENTOS
   if exists(select 1 from ca_dividendo
   where di_operacion = @i_operacionca
   and   di_fecha_ven = @i_fecha_proceso)
   begin

      update ca_dividendo set
      di_intento = 0
      from ca_dividendo
      where di_operacion = @i_operacionca
      and   di_fecha_ven = @i_fecha_proceso

   end

   return 0
end

--- LECTURA DE LA FORMA DE PAGO
select @w_retencion     = cp_retencion,
       @w_pcobis     = isnull(cp_pcobis,0)
from   ca_producto
where  cp_producto             = @i_forma_pago
and    isnull(cp_pago_aut,'N') = 'S'

if @@rowcount = 0  return 0 -- NO SE EJECUTA NADA POR NO SER AUTOMATICO

--LGU: no hace nada si no es interfase cobis
if @w_pcobis = 99 return 0  -- NO SE EJECUTA NADA POR SER NO COBIS

if @w_retencion <> 0 begin
   select @w_error = 710002, @w_msg = 'LAS FORMAS DE PAGO AUTOMATICA NO ADMITEN DIAS DE RETENCION'
   goto ERROR
end


select @w_nid = pa_tinyint
from  cobis..cl_parametro
where pa_nemonico = 'NID'
and   pa_producto = 'CCA'

if @@rowcount = 0 select @w_nid = 5

--- DATOS DE LA OPERACION
select
@w_op_moneda         = op_moneda,
@w_fecha_proceso     = op_fecha_ult_proceso,
@w_op_oficina        = op_oficina,
@i_aceptar_anticipos = isnull(@i_aceptar_anticipos, op_aceptar_anticipos), -- FCP Interfaz Ahorros
@i_tipo_reduccion    = isnull(@i_tipo_reduccion,    op_tipo_reduccion),    -- FCP Interfaz Ahorros
@i_tipo_cobro        = isnull(@i_tipo_cobro,        op_tipo_cobro),        -- FCP Interfaz Ahorros
@i_tipo_aplicacion   = isnull(@i_tipo_aplicacion,   op_tipo_aplicacion),   -- FCP Interfaz Ahorros
@w_banco             = op_banco,
@w_op_tipo_amortiza  = op_tipo_amortizacion,
@w_toperacion         = op_toperacion,
@w_cliente          = op_cliente
from   ca_operacion
where  op_operacion   = @i_operacionca

if @@rowcount = 0 return 0


--- DETERMINAR EL NUMERO DE INTENTOS
select @w_di_intento = 0

if exists(select 1 from ca_dividendo
where di_operacion = @i_operacionca
and   di_estado   <> @w_est_cancelado
and   di_fecha_ven = @w_fecha_proceso)
begin

   select @w_di_intento = 0

end else begin

   select @w_div = isnull(min(di_dividendo),0)
   from ca_dividendo
   where di_operacion = @i_operacionca
  and di_estado  = 2

  ---si no hay Vencidos
  if @w_div = 0
     return 0

   --validar los intentos pero con la minima cuota vencida
   select @w_di_intento = di_intento
   from ca_dividendo
   where di_operacion = @i_operacionca
   and   di_dividendo = @w_div

end

-- SI EL NUMERO DE INTENTOS SUPERA EL PERMITIDO SE TERMINA EL PROCESO
if @w_di_intento >= @w_nid
begin
    print 'genafopr.sp saliooo @w_di_intento ' +  cast (@w_di_intento as varchar)  + '  @w_nid  ' +  cast (@w_nid as varchar)
    return 0
end

--- REGISTRAR QUE VAMOS A REALIZAR UN NUEVO INTENTO
if @i_control_intentos = 'S'   --SVA Debitos Paralelo 
begin
   update ca_dividendo set
   di_intento = @w_di_intento + 1
   --from ca_dividendo --LPO CDIG Ajustes migracion a Java
   where di_operacion = @i_operacionca
   and   di_dividendo = @w_div

   if @@error <> 0 begin
      select @w_error = 710002, @w_msg = 'ERROR AL ACTUALIZAR NUMERO DE INTENTOS'
      return 0
   end
end

if @@trancount = 0 begin
   select @w_commit = 'S'
   begin tran
end

-- BORRAR LOS ABONOS PENDIENTES NO APLICADOS
delete ca_abono_det
from   ca_abono
where  abd_operacion     = @i_operacionca
and    ab_operacion      = abd_operacion
and    ab_secuencial_ing = abd_secuencial_ing
and    ab_estado        in ('ING','SUS','E')
and    ab_secuencial_pag = 0
and    ab_cuota_completa = 'S'

if @@error <> 0 begin
   select @w_error = 710002, @w_msg = 'ERROR AL ELIMINAR DETALLE DE ABONOS PENDIENTES'
   goto ERROR
end

--- BORRAR EL DETALLE DE LOS ABONOS PENDIENTES NO APLICADOS
delete ca_abono
where  ab_operacion      = @i_operacionca
and    ab_estado        in ('ING','SUS','E')
and    ab_secuencial_pag = 0
and    ab_cuota_completa = 'S'

if @@error <> 0 begin
   select @w_error = 710002, @w_msg = 'ERROR AL ELIMINAR ABONOS PENDIENTES'
   goto ERROR
end

if @w_commit = 'S' begin
   select @w_commit = 'N'
   commit tran
end

---VALIDAR SI ESTA ACTIVA PARA SEGUIR
if @w_pcobis = 4  --CUENTA DE AHORROS
begin
   if 'S' = (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' and pa_producto = 'CCA')
   begin --inicio  existe validacion con cobis-ahorros
       exec @w_error = cob_cartera..sp_verifica_cuenta_aho --SVA Debitos Paralelo
       @i_operacion  =  'VAHO4',
       @i_cuenta     =  @i_cuenta,
       @o_ah_estado  =  @w_ah_estado out
                              
       if @w_ah_estado = null or @w_ah_estado = ''
       begin
           select @w_ah_stado = ah_estado
           from cob_ahorros..ah_cuenta
           where ah_cta_banco = @i_cuenta
           if @@rowcount = 0
           begin
              select @w_error = 351523, @w_msg = 'ERROR CUENTA DE AHORROS NO EXISTE'
              goto ERROR
           end
           else
           begin
               if @w_ah_stado <> 'A'
               begin
                  select @w_error = 701043, @w_msg = 'ERROR CUENTA DE AHORROS INACTIVA O CANCELADA'
                  goto ERROR
               end
           end
       end
   end
end

---EN CARTERA EXISTE LA FORMA DE PAGO DEBITOA A CUENTAS CORRIENTES
---SE DEJA ESTA CONSULTA PARA VALIDAR CUANDO SEA EL CASO
if @w_pcobis = 3
begin
    exec @w_error = cob_cartera..sp_verifica_cuenta_cte --SVA Debitos Paralelo
    @i_operacion  =  'VCTE4',
    @i_cuenta     =  @i_cuenta,
    @o_ah_estado  =  @w_ah_estado OUT
                
    if @w_ah_estado = null or @w_ah_estado = ''
    begin
       select @w_error = 351522, @w_msg = 'ERROR CUENTA CORRIENTE NO EXISTE'
       goto ERROR
    end
    else
    begin
        if @w_cc_estado  <> 'A'
        begin
           select @w_error = 701043, @w_msg = 'ERROR CUENTA CORRIENTE INACTIVA O CANCELADA'
           goto ERROR
        end
    end
end

if @w_pcobis in (3,4)  --- SOLO AHORROS y CORRIENTES
begin

    select @w_mmdc = pa_money
    from   cobis..cl_parametro
    where  pa_nemonico = 'MMDC'
    and    pa_producto = 'CCA'
    ----PRINT 'genafopr.sp anes de ejecutar cob_interface..sp_calcula_sin_impuesto @i_en_linea : '  + cast (@i_en_linea as varchar)
    
    --AGI. 21-FEB-19  
    -- cob_cuenta..sp_calcula_sin_impuesto no se encuentra compilado
    /*
    exec @w_error = cob_interface..sp_calcula_sin_impuesto
    @s_ofi         = @s_ofi,                  ---OFICINA QUE EJECUTA LA CONSULTA
    @i_pit         = 'S',                     ---INDICADOR PARA NO REALIZAR ROLLBACK
    @i_cta_banco   = @i_cuenta,               ---NUMERO DE CUENTA
    @i_tipo_cta    = @w_pcobis,               ---PRODUCTO DE LA CUENTA
    @i_fecha       = @s_date,                 ---FECHA DE LA CONSULTA
    @i_causa       = @w_causa,                ---CAUSA DE DEBITO (para verificar si cobra IVA)
    @i_is_batch    = @w_is_batch,
    @o_valor       = @w_saldo_disponible out  ---VALOR PARA REALIZAR LA ND

    if @w_error <> 0  or @@error <> 0
    begin
      PRINT 'genafopr.sp salio de cob_cuentas..sp_calcula_sin_impuesto con este error : ' + cast(@w_error as varchar)
       select @w_error = 252074, @w_msg = 'ERROR EJECUTANDO cob_cuentas..sp_calcula_sin_impuesto'
       goto ERROR
    end
    if ( @w_saldo_disponible < @w_mmdc)
    begin
       select @w_error = 710152, @w_msg = 'ERROR CUENTA SIN DISPONIBLE'
       goto ERROR

    end
    */ --AGI. 21-FEB-19
end

--- DETERMINAR EL MONTO EXIGIBLE DEL PRESTAMO
if @w_op_tipo_amortiza != @w_tflexible
begin
   --- DETERMINAR EL MONTO EXIGIBLE DEL PRESTAMO
   select @w_monto = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from ca_amortizacion, ca_dividendo
   where am_operacion  = @i_operacionca
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_estado    <> @w_est_cancelado
   and   am_estado    <> @w_est_cancelado
   and   di_fecha_ven <= @w_fecha_proceso

   if @w_monto <= 0 return 0  -- sin no hay valor a aplicar, salir
end
else
begin

   select @w_monto_vencido    = 0,
          @w_monto_pagado_vig = 0,
          @w_monto_disponible = 0

   --- DETERMINAR EL MONTO_VENCIDO DEL PRESTAMO PARA PAGOS FLEXIBLES
   select @w_monto_vencido = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from ca_amortizacion, ca_dividendo
   where am_operacion  = @i_operacionca
   and   am_operacion = di_operacion
 and   am_dividendo  = di_dividendo
   and   di_estado     = @w_est_vencido
   and   am_estado    <> @w_est_cancelado
   and   di_fecha_ven  < @w_fecha_proceso

   --- DETERMINAR EL MONTO_PAGADO DE LA CUOTA VIGENTE
   select @w_monto_pagado_vig = isnull(sum(am_pagado),0)
   from ca_amortizacion, ca_dividendo
   where am_operacion  = @i_operacionca
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_fecha_ven  = @w_fecha_proceso

   --- DETERMINAR EL VALOR DISPONIBLE O COMPROMISO DE PAGO
   select @w_monto_disponible = isnull(dt_valor_disponible,0)
   from cob_credito..cr_disponibles_tramite, cob_cartera..ca_dividendo
   where dt_operacion_cca = @i_operacionca
   and   dt_operacion_cca = di_operacion
   and   dt_dividendo     = di_dividendo
   and   di_fecha_ven     = @w_fecha_proceso
   
   select @w_monto = isnull(@w_monto_vencido + @w_monto_disponible - @w_monto_pagado_vig,0)

   if @w_monto <= 0 or @w_monto_pagado_vig > @w_monto_disponible return 0  -- sin no hay valor a aplicar, salir

end

--- DETERMINAR EL MONTO DE PAGOS INGRESADOS O NO APLICADOS AL PRESTAMO
select @w_pagos = isnull(sum(abd_monto_mpg),0)
from ca_abono, ca_abono_det
where ab_operacion      = @i_operacionca
and   ab_operacion      = abd_operacion
and   ab_secuencial_ing = abd_secuencial_ing
and   ab_estado        in ('ING','NA')
and   abd_tipo         in ('PAG','CON')
and   ab_fecha_pag      <= @w_fecha_proceso

--- DESCONTAR DEL VALOR EXIGIBLE EL VALOR REGISTRADO EN PAGOS PENDIENTES DE APLICAR
select @w_monto = @w_monto - @w_pagos

--- SALIR SI NO HAY VALOR A PAGAR
if @w_monto < 0.01
   return 0

--AGI 21-FEB-19. VALIDAR EL DISPONIBLE DE LA CUENTA, SI NO CUBRE SE DEBITA TODO LO QUE TENGA
if @w_pcobis = 4 --SVA Debitos Paralelo
begin
   select @w_cuenta = ah_cuenta
   from   cob_ahorros..ah_cuenta
   where  ah_cta_banco = @i_cuenta

   exec @w_error = cob_ahorros..sp_ahcalcula_saldo
   @i_cuenta           = @w_cuenta,
   @i_fecha            = @i_fecha_proceso,
   @i_is_batch         = @w_is_batch,
   @o_saldo_para_girar = @w_saldo_disponiblef out,
   @o_saldo_contable   = @w_saldo_contable  out

   if @w_error <> 0  return @w_error  
end   

/*
if @w_pcobis = 3 --SVA Debitos Paralelo
begin
   select @w_cuenta = cc_ctacte
   from   cob_cuentas..cc_ctacte
   where  cc_cta_banco = @i_cuenta

   exec @w_error = cob_cuentas..sp_calcula_saldo
   @i_cuenta           = @w_cuenta,
   @i_fecha            = @i_fecha_proceso,
   @i_is_batch         = @w_is_batch,
   @o_saldo_para_girar = @w_saldo_disponiblef out,
   @o_saldo_contable   = @w_saldo_contable  out

   if @w_error <> 0  return @w_error  
end   
*/

if @w_saldo_disponiblef <= @w_monto and @w_saldo_disponiblef > 0
   select @w_monto = @w_saldo_disponiblef

--AGI FIN   
   
--- GENERAR EL PAGO AUTOMATICO

exec @w_secuencial = sp_gen_sec
@i_operacion = @i_operacionca

if @@trancount = 0 begin
   select @w_commit = 'S'
   begin tran
end

insert ca_abono (
ab_secuencial_ing,  ab_secuencial_rpa,     ab_secuencial_pag,
ab_operacion,       ab_fecha_ing,          ab_fecha_pag,
ab_cuota_completa,  ab_aceptar_anticipos,  ab_tipo_reduccion,
ab_tipo_cobro,      ab_dias_retencion_ini, ab_dias_retencion,
ab_estado,          ab_usuario,            ab_oficina,
ab_terminal,        ab_tipo,               ab_tipo_aplicacion,
ab_nro_recibo )
values(
@w_secuencial,      0,                     0,
@i_operacionca,     @w_fecha_proceso,      @w_fecha_proceso,
'S',                @i_aceptar_anticipos,  @i_tipo_reduccion,
@i_tipo_cobro,      @w_retencion,          @w_retencion,
'ING',              @s_user,               @w_op_oficina,
@s_term,            'PAG',                 @i_tipo_aplicacion,
0)

if @@error <> 0 begin
   select @w_error = 710294, @w_msg = 'ERROR AL INSERTAR ABONO AUTOMATICO'
   goto ERROR
end

insert into ca_abono_det (
abd_secuencial_ing,    abd_operacion,       abd_tipo,
abd_concepto,
abd_cuenta,            abd_beneficiario,    abd_moneda,
abd_monto_mpg,         abd_monto_mop,       abd_monto_mn,
abd_cotizacion_mpg,    abd_cotizacion_mop,  abd_tcotizacion_mpg,
abd_tcotizacion_mop,   abd_cheque,          abd_cod_banco,
abd_solidario)                                              --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
values(
@w_secuencial,         @i_operacionca,      'PAG',
@i_forma_pago,
isnull(@i_cuenta,''), 'DB.AUT',             @w_op_moneda,
@w_monto,              @w_monto,            @w_monto,
@i_cotizacion,         @i_cotizacion,       'N',
'N',                   @i_cheque,           @i_cod_banco,
'N')

if @@error <> 0 begin
   select @w_error = 710295, @w_msg = 'ERROR AL INSERTAR LOS DETALLES DEL PAGO AUTOMATICO'
   goto ERROR
end

-- LGU: para no limitar a un solo tipo de operacion a los grupales
--if @w_toperacion = @w_cre_grp
---------if exists (select 1 from cobis..cl_tabla t, cobis..cl_catalogo c where t.tabla = 'ca_grupal' and t.codigo = c.tabla and c.codigo = @w_toperacion) OR
---------   exists (select 1 from cobis..cl_tabla t, cobis..cl_catalogo c where t.tabla = 'ca_interciclo' and t.codigo = c.tabla and c.codigo = @w_toperacion)
---------begin
---------   /*PROCENTAJE DE AHORRO INDIVIDUAL*/
---------   exec @w_error = cob_cartera..sp_run_rule_generico
---------       @s_user         = @s_user,
---------       @s_sesn            = @s_sesn,
---------       @s_term            = @s_term,
---------       @s_date            = @s_date,
---------       @s_ofi            = @s_ofi,
---------       @i_abrev_regla  = 'CREGRP',  -- Es el nombre de la Regla para los GRUPALES
---------       @i_banco           = @i_operacionca,
---------       @i_var_nombre1     = 'MNT',
---------       @i_var_valor1     = @w_monto,
---------       @o_resultado    = @w_por_ahorro OUT
---------
---------   if @w_error <> 0 or @@error <> 0
---------   begin
---------      if @@trancount = 0 select @w_commit = 'N'
---------      goto ERRORDEBITO
---------   end

   /*********************************************/
   --select @w_por_ahorro = 1 --DEFINIR EN REGLAS
   --SELECT @w_ahorro_ind = (@w_monto * CONVERT(INT,@w_por_ahorro)) / 100
   --select @w_ahorro_ind = -1*@w_ahorro_ind

   /*insert into ca_abono_det (
   abd_secuencial_ing,    abd_operacion,       abd_tipo,
   abd_concepto,
   abd_cuenta,            abd_beneficiario,    abd_moneda,
   abd_monto_mpg,         abd_monto_mop,       abd_monto_mn,
   abd_cotizacion_mpg,    abd_cotizacion_mop,  abd_tcotizacion_mpg,
   abd_tcotizacion_mop,   abd_cheque,          abd_cod_banco,
   abd_solidario)                                             --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
   values(
   @w_secuencial,         @i_operacionca,      'AHV',
   @i_forma_pago,
   isnull(@i_cuenta,''), 'DB.AUT',             @w_op_moneda,
   (-1*@w_por_ahorro),    (-1*@w_por_ahorro),  (-1*@w_por_ahorro),
   @i_cotizacion,         @i_cotizacion,       'N',
   'N',                   NULL,                 @i_cod_banco,
   'N')

   if @@error <> 0 begin
      select @w_error = 710295, @w_msg = 'ERROR AL INSERTAR LOS DETALLES DEL PAGO AUTOMATICO'
      goto ERROR
   end
   */
--end

insert into ca_abono_prioridad (
ap_secuencial_ing, ap_operacion,     ap_concepto, ap_prioridad)
select
@w_secuencial,     @i_operacionca,   ro_concepto, ro_prioridad
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_fpago not in ('L')
order  by ro_concepto

if @@error <> 0 begin
   select @w_error = 710225, @w_msg = 'ERROR AL INSERTAR LOS PRIORIDADES DE APLICACION DEL PAGO'
   goto ERROR
end

if @w_commit = 'S' begin
   select @w_commit = 'N'
   commit tran
end

IF @i_tipo_grupal = 'G'  --LPO TEC cuando sea una operacion G (grupal) solo debe crear el abono pero no realizar el pago por aqui, el pago se hace luego, con el esquema de pagos grupales.
   RETURN 0
   

---CALCULO DEL SECUENCIAL PARA PROCESO FUERA DE LINEA (ESTE PROCESO SE EJECUTA SIEMPRE FUERA DE LINEA)
update cobis..ba_secuencial set
-- @w_ssn    = case when se_numero > 2147483000 then 100 else se_numero + 100 end,  --LPO CDIG Ajustes migracion a Java
se_numero = case when se_numero > 2147483000 then 100 else se_numero + 100 END
WHERE se_numero IS NOT NULL

if @@error <> 0 begin
   select @w_error = 710002, @w_msg = 'ERROR AL GENERAR EL SECUENCIAL'
   goto ERROR
end

select @w_ssn = se_numero  --LPO CDIG Ajustes migracion a Java
from cobis..ba_secuencial


--- DEBITAR LA CUENTA, REGISTAR Y APLICAR EL PAGO AUTOMATICO
--select @w_monto = @w_monto+ @w_por_ahorro
select @w_valor_debitado = @w_monto


--PRINT @w_por_ahorro
--SELECT @w_monto    = isnull((@w_monto + @w_por_ahorro),0)

if @@trancount = 0 begin
   select @w_commit = 'S'
   begin tran
END

-- GENERAR LA NOTA DEBITO A LA CUENTA
exec @w_error = sp_afect_prod_cobis
@s_ssn          = @w_ssn,
@s_user         = @s_user,
@s_term         = @s_term,
@s_date         = @s_date,
@s_ofi          = @s_ofi,
@i_en_linea     = @i_en_linea,
@i_debug        = @i_debug,
@i_fecha        = @w_fecha_proceso,
@i_cuenta       = @i_cuenta,
@i_producto     = @i_forma_pago,
@i_monto        = @w_monto,
@i_mon          = @w_op_moneda,
@i_operacionca  = @i_operacionca,
@i_alt          = @i_operacionca,
@i_sec_tran_cca = @w_secuencial,
@o_monto_real   = @w_valor_debitado out

if @w_error <> 0 or @@error <> 0 begin
   if @@trancount = 0 select @w_commit = 'N'
   goto ERRORDEBITO
end

-- LGU: para no limitar a un solo tipo de operacion a los grupales
--if @w_toperacion = @w_cre_grp
if exists (select 1 from cobis..cl_tabla t, cobis..cl_catalogo c where t.tabla = 'ca_grupal' and t.codigo = c.tabla and c.codigo = @w_toperacion) OR
   exists (select 1 from cobis..cl_tabla t, cobis..cl_catalogo c where t.tabla = 'ca_interciclo' and t.codigo = c.tabla and c.codigo = @w_toperacion)
begin
   select @w_cta_grp = op_cuenta, -- FALTA VALIDACION DE CUENTA
          @w_ente_grupal = op_operacion
         FROM ca_operacion
         WHERE op_operacion = @i_operacionca


   select @w_div_vigente = isnull(max(di_dividendo),0)
   from   ca_dividendo
   where  di_operacion   = @i_operacionca
   and    di_estado      = @w_est_vigente

   -- GENERAR LA NOTA CREDITO A LA CUENTA
   /*exec @w_secuencial_cr = sp_gen_sec
   @i_operacion = @i_operacionca
   IF @w_secuencial_cr = 0
   BEGIN
   select @w_error = 710225, @w_msg = 'ERROR AL GENERAR SECUENCIAL DE CREDITO GRUPAL'
      goto ERROR
   END

   EXEC @w_ssn = ADMIN...rp_ssn
   IF @w_ssn = 0
   BEGIN
   select @w_error = 710225, @w_msg = 'ERROR AL GENERAR SSN DE CREDITO GRUPAL'
      goto ERROR
   END

   exec @w_error = sp_afect_prod_cobis
   @s_ssn    = @w_ssn,
   @s_user         = @s_user,
   @s_term         = @s_term,
   @s_date         = @s_date,
   @s_ofi          = @s_ofi,
   @i_en_linea     = @i_en_linea,
   @i_debug        = @i_debug,
   @i_fecha        = @w_fecha_proceso,
   @i_cuenta       = @w_cta_grp, 
   @i_producto     = 'NCAH',
   @i_monto        = @w_por_ahorro,
   @i_mon          = @w_op_moneda,
   @i_operacionca  = @i_operacionca,
   @i_alt          = @i_operacionca,
   @i_sec_tran_cca = @w_secuencial_cr,
   @i_grupal       = 'S'
   --@o_monto_real   = @w_valor_debitado out

   if @w_error <> 0 or @@error <> 0 begin
      if @@trancount = 0 select @w_commit = 'N'
      goto ERRORDEBITO
   end
   print 'ahorro'*/
   if 'S' = (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' and pa_producto = 'CCA')
   begin --inicio existe validacion con cobis-ahorros
      IF EXISTS (SELECT 1 FROM cob_ahorros..ah_ahorro_individual
                      WHERE ai_cliente = @w_cliente
                  AND ai_operacion = @i_operacionca
                      AND ai_cta_grupal = @w_cta_grp)
      BEGIN
              UPDATE cob_ahorros..ah_ahorro_individual
              SET ai_saldo_individual = ai_saldo_individual + @w_por_ahorro
              WHERE ai_cliente = @w_cliente
            AND ai_operacion = @i_operacionca
              AND ai_cta_grupal = @w_cta_grp
      END
      ELSE
      BEGIN
              INSERT INTO cob_ahorros..ah_ahorro_individual(ai_cta_grupal, ai_operacion, ai_cliente, ai_saldo_individual)
              VALUES (@w_cta_grp,@i_operacionca,@w_cliente,@w_por_ahorro)
      END
   end --fin existe validacion con cobis-ahorros


   --LGU-ini: esta tabla se llena a demanda
   /**************
   if exists(select 1 from ca_control_pago
               where cp_grupo = @w_ente_grupal
               and cp_operacion = @i_operacionca
               and cp_dividendo = @w_div_vigente)
   begin
      delete from ca_control_pago
               where cp_grupo = @w_cta_grp
               and cp_operacion = @i_operacionca
               and cp_dividendo = @w_div_vigente
   end

   INSERT INTO ca_control_pago
         VALUES(@w_ente_grupal,@i_operacionca,@w_cta_grp,@w_div_vigente,@w_monto,@w_monto,0,@w_monto,@w_por_ahorro,0)
   *********/
   --LGU-ini: esta tabla se llena a demanda
end -- control para operaciones grupales


if @w_monto <> @w_valor_debitado  begin

   -- ACTUALIZAR EL DETALLE DE PAGO
   update ca_abono_det set
   abd_monto_mn  = @w_valor_debitado,
   abd_monto_mpg = @w_valor_debitado,
   abd_monto_mop = @w_valor_debitado
   where  abd_operacion      = @i_operacionca
   and    abd_secuencial_ing = @w_secuencial

   if @@error <> 0  begin
      select @w_error = 708152, @w_msg = 'ERROR AL ACTUALIZAR EN EL PAGO EL VALOR EFECTIVAMENTE DEBITADO'
      goto ERROR
   end

end

update ca_abono set
ab_estado          = 'P',
ab_cuota_completa  = 'N'
where ab_operacion      = @i_operacionca
and   ab_secuencial_ing = @w_secuencial

if @@error <> 0 begin
   select @w_error = 708152, @w_msg = 'ERROR AL MARCAR EL PAGO COMO DEBITADO'
   goto ERROR
end

-- APLICAR EN CARTERA EL ABONO
exec @w_error = sp_registro_abono
@s_user           = @s_user,
@s_term           = @s_term,
@s_date           = @s_date,
@s_ofi            = @s_ofi,
@i_secuencial_ing = @w_secuencial,
@i_en_linea       = 'N',
@i_operacionca    = @i_operacionca,
@i_fecha_proceso  = @w_fecha_proceso,
@i_cotizacion     = @i_cotizacion

if @w_error <> 0  or @@error <> 0 begin
   select @w_msg = 'ERROR AL REGISTRAR EL PAGO (sp_registro_abono)'
   goto ERROR
end

update ca_secuencial_atx set
sa_secuencial_cca = ab_secuencial_rpa
from ca_abono
where ab_operacion      = @i_operacionca
and   ab_secuencial_ing = @w_secuencial
and   sa_operacion      = @w_banco
and   sa_secuencial_cca = @w_secuencial

if @@error <> 0 begin
   select
   @w_error = 708152, @w_msg = 'NO SE PUEDE ACTUALIZAR SECUENCIALES DE ATX '
   goto ERROR
end

if @w_retencion <= 0  begin

   -- APLICACION DEL PAGO
   exec @w_error = sp_cartera_abono
   @s_sesn           = @s_sesn,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_secuencial_ing = @w_secuencial,
   @i_en_linea       = 'N',
   @i_operacionca    = @i_operacionca,
   @i_fecha_proceso  = @w_fecha_proceso,
   @i_cotizacion     = @i_cotizacion

   if @w_error <> 0 or @@error <> 0 begin
      select @w_msg = 'ERROR AL APLICAR EL PAGO (sp_cartera_abono)'
      goto ERROR
   end

end

if @w_commit = 'S' begin
   select @w_commit = 'N'
   commit tran
end

return 0

ERRORDEBITO:

   if @w_commit = 'S'  begin
      select @w_commit = 'N'
      rollback tran
   end

   select @w_msg = substring(mensaje,1,40)
   from cobis..cl_errores
   where numero = @w_error
   if @@rowcount = 0  select @w_msg = convert(varchar, @w_error ) + 'SIN DESCRIPCION'

   update  ca_abono_det set
   abd_beneficiario = substring(abd_beneficiario,1,10) + isnull(@w_msg,'')
   where   abd_operacion      = @i_operacionca
   and     abd_secuencial_ing = @w_secuencial

   if @@error <> 0 begin
      select @w_error = 710002, @w_msg = 'ERROR AL ACTUALIZAR DETALLE DEL PAGO --BENEFICIARIO'
      goto ERROR
   end

   update  ca_abono set
   ab_estado = 'E'
   where   ab_operacion      = @i_operacionca
   and     ab_secuencial_ing = @w_secuencial
   if @@error <> 0 begin
      select @w_error = 710002, @w_msg = 'ERROR AL MARCAR EL ABONO COMO ERRONEO'
      goto ERROR
   end

   select @w_msg = 'ERROR AL EJECUTAR LA AFECTACION AL PRODUCTO COBIS'
   goto ERROR

ERROR:

if @w_commit = 'S' begin
   select @w_commit = 'N'
   rollback tran
end

update  ca_abono set
ab_estado = 'E'
where   ab_operacion      = @i_operacionca
and     ab_secuencial_ing = @w_secuencial

if @@error <> 0
begin
   select    @w_error = 708152, @w_msg = 'NO SE PUEDE ACTUALIZAR ESTADO DEL PAGO'
   --goto ERROR LPO CDIG evitar ciclo infinito
end

if @i_en_linea = 'S' begin

   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,
   @i_msg   = @w_msg,
   @i_num   = @w_error
      
end else begin

   select @w_secuencial = isnull(@w_secuencial, 7999)

   exec sp_errorlog
   @i_fecha       = @s_date,
   @i_error       = @w_error,
   @i_usuario     = @s_user,
   @i_tran        = @w_secuencial,
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = @w_banco,
   @i_descripcion = @w_msg,
   @i_rollback    = 'N'
   
end

--return 0  -- para que el batch 1 no registre dos veces el mismo error

RETURN @w_error --LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS

GO
