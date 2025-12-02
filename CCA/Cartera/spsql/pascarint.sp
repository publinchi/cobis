/************************************************************************/
/*  Archivo:                pascarint.sp                                */
/*  Stored procedure:       sp_pasa_cartera_interciclo                  */
/*  Base de datos:          cob_cartera                                 */
/*  Producto:               Cartera                                     */
/*  Disenado por:           Jorge Salazar                               */
/*  Fecha de escritura:     30-Mar-2017                                 */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Pasar a cartera el tramite de credito interciclo                    */
/************************************************************************/
/*                               MODIFICACIONES                         */
/*     FECHA        AUTOR                    RAZON                      */
/*    24/Jun/2022     KDR              Nuevo parámetro sp_liquid        */
/*                                                                      */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pasa_cartera_interciclo')
    drop proc sp_pasa_cartera_interciclo
go

---NR.499 Normalizacion Cartera

create proc sp_pasa_cartera_interciclo
(
   @s_ssn             int = null,
   @s_sesn            int = null,
   @s_ofi             smallint,
   @s_rol             smallint = 3,
   @s_user            login,
   @s_date            datetime,
   @s_term            descripcion,
   @i_tramite         int,
   @i_formato_fecha   int = 101
)
as declare
   @w_sp_name                varchar(30),
   @w_return                 int,
   @w_operacion              int,
   @w_banco                  cuenta,
   @w_monto                  money,
   @w_moneda                 tinyint,
   @w_fecha_ini              datetime,
   @w_fecha_fin              datetime,
   @w_fecha_liq              datetime,
   @w_tipo                   char(1) ,
   @w_oficina                smallint,
   @w_siguiente              int,
   @w_est_novigente          smallint,
   @w_estado                 smallint,
   @w_dias                   int,
   @w_num_oficial            smallint,
   @w_filial                 tinyint,
   @w_cliente                int,
   @w_direccion              int,
   @w_operacionca            int,
   @w_reestructuracion       char(1),     -- RRB: 02-21-2002 Circular 50
   @w_num_reest              int,         -- RRB: 02-21-2002 Circular 50
   @w_op_direccion           tinyint,
   @w_rowcount               int,
   @w_lin_credito            cuenta,
   @w_tramite_cupo           int,
   @w_fecha_aprob            datetime,
   @w_valor_seguros          money,
   @w_monto_cre              money,
   @w_periodo_cap            int,
   @w_periodo_int            int,
   @w_base_calculo           char(1),
   @w_dias_anio              smallint,
   @w_dist_gracia            char(1),
   @w_gracia_cap             int,
   @w_secuencial             int,
   @w_tipo_amortizacion      catalogo,
   @w_porc_gar_grupal        float,
   @w_porc_gar_interciclo    float,
   @w_servidor               varchar(30),
--   @w_tg_operacion           int,   LGU es la misma @w_operacionca hija
   @w_cta_grupal             cuenta,
   @w_cta_cliente            cuenta,  --- LGU para la cuenta de la cr_tramite grupal
   @w_plazo_no_vigente       tinyint,
--   @w_max_fecha_nvigente     datetime,  LGU no se usa
   @w_dias_plazo             tinyint,
   @w_saldo_individual       money,
   @w_ah_cta_banco           cuenta,
   @w_disponible             money,
   @w_banco_generado         cuenta,
   @w_monto_gar_interciclo   money,
   @w_monto_gar_grupal       money,
--   @w_tg_prestamo            cuenta,  LGU es el mismo @w_banco hija
   @w_plazo                  tinyint,
   @w_min_fecha_vig          datetime,
   @w_tplazo                 char(1),
   @w_plazo_en_dias          tinyint,
   @w_codigo_externo         varchar(64),
   @w_tdividendo             smallint,
   @w_tg_referencia_grupal   varchar(15),
   @w_tramite_grupal         int,
   @w_tg_grupo               int,
   @w_nombre                 descripcion,
   --@w_ncre_ahorro            varchar(30),  LGU ya no aplica xq se realiza en la pantalla de desembolso
   @w_tipo_flujo             varchar(10),
   @w_cuota                  money

set rowcount 0

---  VARIABLES DE TRABAJO
select @w_sp_name       = 'sp_pasa_cartera_interciclo',
       @w_est_novigente = 0


-- Parametro Porcentaje Garantia Grupal
select @w_porc_gar_grupal = pa_float
  from cobis..cl_parametro
 where pa_nemonico = 'PGARGR'
   and pa_producto = 'CCA'

if @@rowcount = 0
begin
   print 'NO EXISTE PARAMETRO'
   return 101077
end

-- Parametro Porcentaje Garantia Interciclo
select @w_porc_gar_interciclo = pa_float
  from cobis..cl_parametro
 where pa_nemonico = 'PGARIN'
   and pa_producto = 'CCA'

if @@rowcount = 0
begin
   print 'NO EXISTE PARAMETRO'
   return 101077
end

-- Parametro Nombre de Servidor
select @w_servidor = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'SRVCFP' -- NOMBRE DE SERVIDOR CTS PARA CAMBIO FECHA PROCESO
   and pa_producto = 'BAT'

if @@rowcount = 0
begin
   print 'NO EXISTE PARAMETRO'
   return 101077
end

-- PARAMETRO NOTA DE CREDITO CARTERA
-- LGU-ini ya no aplica porque se realiza en la pantalla de desembolso
/*
select @w_ncre_ahorro = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'NCRAHO' --INTERES CORRIENTE
   and pa_producto = 'CCA'

if @@rowcount = 0
begin
   print 'NO EXISTE PARAMETRO'
   return 101077
end
*/

-- LGU-fin ya no aplica porque se realiza en la pantalla de desembolso
select @w_operacionca       = op_operacion,
       @w_fecha_liq         = convert(varchar(10),op_fecha_liq,@i_formato_fecha),
       @w_monto             = op_monto,
       @w_moneda            = op_moneda,
       @w_fecha_ini         = convert(varchar(10),op_fecha_ini,@i_formato_fecha),
       @w_fecha_fin         = convert(varchar(10),op_fecha_fin,@i_formato_fecha),
       @w_oficina           = op_oficina,
       @w_banco             = op_banco,
       @w_cliente           = op_cliente,
       @w_nombre            = op_nombre,
       @w_estado            = op_estado,
       @w_op_direccion      = op_direccion,
       @w_lin_credito       = op_lin_credito,
       @w_tipo_amortizacion = op_tipo_amortizacion,
       @w_cuota             = op_cuota,
       @w_periodo_cap       = op_periodo_cap,
       @w_periodo_int       = op_periodo_int,
       @w_base_calculo      = op_base_calculo,
       @w_dias_anio         = op_dias_anio,
       -- LGU-ini  se comenta para obtenerlo en el primer select de la operacion
       --@w_ah_cta_banco      = op_cuenta, -- tomar el numero de cuenta
       --@w_monto_gar_grupal  = op_monto * @w_porc_gar_grupal / 100,
       @w_plazo             = op_plazo,
       @w_tipo_flujo        = tr_grupal, -- LGU 2017-06-30  para controlar el tipo de prestamo: grupal(S), interciclo(N), individual(null)
       @w_tplazo            = op_tplazo
       -- LGU-ini  se comenta para obtenerlo en el primer select de la operacion
 from ca_operacion, cob_credito..cr_tramite
 where op_tramite = @i_tramite
 and op_tramite   = tr_tramite


IF @w_tipo_flujo = 'N' -- LGU 2017-06-30  para controlar el tipo de prestamo: grupal(S), interciclo(N), individual(null)
begin
    -- Datos de tramite grupal del cliente
    select
           @w_tg_grupo             = tg_grupo,
           @w_tg_referencia_grupal = tg_referencia_grupal,
           @w_tramite_grupal       = tg_tramite,  -- LGU 19/abr/2017
           @w_cta_grupal           = (select op_cuenta from cob_cartera..ca_operacion where op_banco = tg.tg_referencia_grupal )
      from cob_credito..cr_tramite_grupal tg
     where tg_operacion = @w_operacionca

    if @@rowcount = 0
    begin
       print 'TRAMITE NO EXISTE O NO SE ENCUENTRA EN ESTADO VALIDO PARA ESTA TAREA'
       return 2101183
    end
END

-- Cuenta grupal asociada al prestamo del cliente
-- LGU-ini  se comenta para obtenerlo en el primer select de la operacion
/*
select @w_cta_grupal       = op_cuenta,
       @w_monto_gar_grupal = op_monto * @w_porc_gar_grupal / 100,
       @w_plazo            = op_plazo,
       @w_tplazo           = op_tplazo
  from ca_operacion
 where op_operacion = @w_operacionca --@w_tg_operacion

if @@rowcount = 0
begin
   print 'NO SE ENCUENTRA EL PRESTAMO'
   return 70005001
end
*/
-- LGU-fin  se comenta para obtenerlo en el primer select de la operacion


-- Periodos de dividendos no vigentes y fecha inicial de operacion de cliente
select @w_plazo_no_vigente = count(1) - 1,
       @w_min_fecha_vig    = convert(varchar(10),min(di_fecha_ini),@i_formato_fecha)
  from ca_dividendo
 where di_operacion = @w_operacionca --@w_tg_operacion
   and di_estado    = @w_est_novigente

-- LGU 24/abr/2017 no se usa
/*
select @w_max_fecha_nvigente = convert(varchar(10),di_fecha_ven,@i_formato_fecha)
  from ca_dividendo
 where di_operacion = @w_operacionca -- @w_tg_operacion
   and di_dividendo in (select max(di_dividendo) - 1
                          from ca_dividendo
                         where di_operacion = @w_operacionca --@w_tg_operacion
                           and di_estado    = @w_est_novigente)
*/

-- Plazo en dias
-- LGU-ini 24/abr/2017 no se usa
/*
select @w_dias_plazo = td_factor
  from ca_tdividendo
 where td_tdividendo = @w_tplazo*/

--select @w_plazo_en_dias = isnull(@w_plazo_no_vigente * @w_dias_plazo,0)   -- LGU 24/abr/2017 no hay interfase con AHO


IF @w_tipo_flujo = 'N' -- LGU 2017-06-30  para controlar el tipo de prestamo: grupal(S), interciclo(N), individual(null)
begin
	-- Monto del porcentaje garantia interciclo
	select @w_monto_gar_interciclo = @w_monto * @w_porc_gar_interciclo / 100

	-- Garantia Liquida por monto total del prestamo
	/* SACAR SECUENCIALES SESIONES */
	exec @s_ssn = sp_gen_sec
	     @i_operacion  = -1

	exec @w_return         = cob_custodia..sp_custodia_automatica
	     @s_ssn            = @s_ssn,
	     @s_date           = @s_date,
	     @s_user           = @s_user,
	     @s_term           = @s_term,
	     @s_ofi            = @s_ofi,
	     @t_trn            = 19090,
	     @t_debug          = 'N',
	     @i_operacion      = 'L',
	     @i_tipo_custodia  = 'AHORRO',
	     @i_tramite        = @i_tramite,
	     @i_valor_inicial  = @w_monto_gar_interciclo, --valor total de la garantía interciclo
	     @i_moneda         = @w_moneda,
	     @i_garante        = @w_cliente,
	     @i_fecha_ing      = @s_date,
	     @i_cliente        = @w_cliente,
	     @i_clase          = 'C',
	     @i_filial         = 1,
	     @i_oficina        = @s_ofi,
	     @i_ubicacion      = 'DEFAULT',
	     @o_codigo_externo = @w_codigo_externo out

	if @w_return <> 0
	   return @w_return
END

-- LGU-ini 24/abr/2017 comentado porque no hay interfase con AHO
-- LGU-ini: control para validar o no con cobis-ahorros
if 'S' = (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' -- existe validacion con cobis-ahorros
         and pa_producto = 'CCA')
begin
    -- Fondos disponibles del cliente en Cuenta Grupal
    select @w_saldo_individual = isnull(ai_saldo_individual,0)
    from cob_ahorros..ah_ahorro_individual
    where ai_cliente    = @w_cliente
    and ai_cta_grupal = @w_cta_grupal

   -- LGU: ejecuta esto ssi existe cobis-ahorros
   if @w_saldo_individual - @w_monto_gar_grupal > @w_monto_gar_interciclo
   begin
      -- Bloqueo de Valor de la Garantia en Cuenta Grupal
      /* SACAR SECUENCIALES SESIONES */
      exec @s_ssn = sp_gen_sec
           @i_operacion  = -1

      exec @s_sesn = sp_gen_sec
           @i_operacion  = -1

      exec @w_return      = cob_ahorros..sp_tr_bloq_val_ah
           @s_ssn         = @s_ssn,
           @s_srv         = @w_servidor,
           @s_lsrv        = @w_servidor,
           @s_user        = @s_user,
           @s_sesn        = @s_sesn,
           @s_term        = @s_term,
           @s_date        = @s_date,
           @s_ofi         = @s_ofi, -- Localidad origen transaccion
           @s_rol         = @s_rol,
           @s_org         = 'S',
           @t_rty         = 'N',
           @t_trn         = 217,
           @i_cta         = @w_cta_grupal,
           @i_mon         = @w_moneda,
           @i_accion      = 'B',
           @i_causa       = '6',
           @i_valor       = @w_monto_gar_interciclo, --valor total de la garantía
           @i_aut         = @s_user,
           @i_plazo       = @w_plazo_en_dias, --plazo en días de la operación
           @i_observacion = 'BLOQUEO POR LC',
           @i_automatico  = 'S',
           @i_ngarantia   = @w_codigo_externo

      if @w_return <> 0
         return @w_return
   end
   else
   begin
      -- Bloqueo de saldo parcial de valor de garantia de cuenta grupal
      if @w_saldo_individual - @w_monto_gar_grupal > 0
      begin
         -- Bloqueo de Valor de la Garantia en Cuenta Grupal
         select @w_saldo_individual = @w_saldo_individual - @w_monto_gar_grupal,
                @w_monto_gar_grupal = 0
         -- SACAR SECUENCIALES SESIONES
         exec @s_ssn = sp_gen_sec
              @i_operacion  = -1

         exec @s_sesn = sp_gen_sec
              @i_operacion  = -1

         exec @w_return      = cob_ahorros..sp_tr_bloq_val_ah
              @s_ssn         = @s_ssn,
              @s_srv         = @w_servidor,
              @s_lsrv        = @w_servidor,
              @s_user        = @s_user,
              @s_sesn        = @s_sesn,
              @s_term        = @s_term,
              @s_date        = @s_date,
              @s_ofi         = @s_ofi, -- Localidad origen transaccion
              @s_rol         = @s_rol,
              @s_org         = 'S',
              @t_rty         = 'N',
              @t_trn         = 217,
              @i_cta         = @w_cta_grupal,
              @i_mon         = @w_moneda,
              @i_accion      = 'B',
              @i_causa       = '6',
              @i_valor       = @w_saldo_individual, --valor parcial de la garantía interciclo
              @i_aut         = @s_user,
              @i_plazo       = @w_plazo_en_dias, --plazo en días de la operación
              @i_observacion = 'BLOQUEO POR LC',
              @i_automatico  = 'S',
              @i_ngarantia   = @w_codigo_externo

         if @w_return <> 0
            return @w_return
      end

      select @w_monto_gar_interciclo = @w_monto_gar_interciclo - (@w_saldo_individual - @w_monto_gar_grupal)

      -- Algoritmo temporal: numero de cuentas individuales vendran en el cursor
      select top 1 @w_ah_cta_banco = isnull(ah_cta_banco,''),
                   @w_disponible   = isnull(ah_disponible,0)
        from cob_ahorros..ah_cuenta with (nolock)
       where ah_cliente = @w_cliente
         and ah_moneda  = @w_moneda
         and ah_estado  in('A','G')
         and ah_prod_banc <> 0--@i_prod_bancario
    order by ah_disponible desc

      if @@rowcount = 0
      begin
         print 'CLIENTE NO TIENE CUENTAS DISPONIBLES PARA EL SERVICIO'
         return 70005001
      end

      if @w_disponible > @w_monto_gar_interciclo
      begin
         -- Bloqueo de Valor de la Garantia en Cuenta Individual
         /* SACAR SECUENCIALES SESIONES */
         exec @s_ssn = sp_gen_sec
              @i_operacion  = -1

         exec @s_sesn = sp_gen_sec
              @i_operacion  = -1

         exec @w_return      = cob_ahorros..sp_tr_bloq_val_ah
              @s_ssn         = @s_ssn,
              @s_srv         = @w_servidor,
              @s_lsrv        = @w_servidor,
              @s_user        = @s_user,
              @s_sesn        = @s_sesn,
              @s_term        = @s_term,
              @s_date        = @s_date,
              @s_ofi         = @s_ofi, -- Localidad origen transaccion
              @s_rol         = @s_rol,
              @s_org         = 'S',
              @t_rty         = 'N',
              @t_trn         = 217,
              @i_cta         = @w_ah_cta_banco,
              @i_mon         = @w_moneda,
              @i_accion      = 'B',
              @i_causa       = '6',
              @i_valor       = @w_monto_gar_interciclo, --valor parcial de la garantía interciclo
              @i_aut         = @s_user,
              @i_plazo       = @w_plazo_en_dias, --plazo en días de la operación
              @i_observacion = 'BLOQUEO POR LC',
              @i_automatico  = 'S',
              @i_ngarantia   = @w_codigo_externo

         if @w_return <> 0
            return @w_return
      end

   end
end
-- LGU-fin: control para validar o no con cobis-ahorros



---INC. 117110
---CUANDO UN TRAMITE SE HA DILIGENCIADO CON SEGURO VOLUNTARIO
---HAY CAMPOS DEL TRAMTIE QUE DEBEN SER IGUALES ANTES DE PASAR A CARTERA AL DESEMBOLSO
---POR QUE PRECISAMENTE EN ESTE PUNTO ES DONDE SE ACTAULIZA EL CAMPO FINAL DEL MONTO
---DE LA OPERACION, ESTE CAMPO NO DEBE SER DIFERENTE

---VALOR DE LOS SEGUROS
select @w_valor_seguros = 0
select @w_valor_seguros = isnull(sum(isnull(ps_valor_mensual,0) * isnull(datediff(mm,as_fecha_ini_cobertura,as_fecha_fin_cobertura),0)),0)
  from cob_credito..cr_seguros_tramite with (nolock),
       cob_credito..cr_asegurados      with (nolock),
       cob_credito..cr_plan_seguros_vs
 where st_tramite           = @i_tramite
   and st_secuencial_seguro = as_secuencial_seguro
   and as_plan              = ps_codigo_plan
   and st_tipo_seguro       = ps_tipo_seguro
   and ps_estado            = 'V'
   and as_tipo_aseg         = (case when ps_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)

if @w_valor_seguros > 0
begin
   select @w_monto_cre = 0
   select @w_monto_cre = isnull(tr_monto_solicitado,0)  --tr_monto contiene el valor con seguros
     from cob_credito..cr_tramite with (nolock)
    where tr_tramite = @i_tramite

   if @w_monto <> @w_monto_cre
   begin
     PRINT 'Diferencias tr_monto_solititado ' +  cast (@w_monto_cre as varchar) + 'op_monto: ' + cast(@w_monto as varchar) + ' Valor Seguros: ' + cast(@w_valor_seguros as varchar)
     return 2101231
   end
end
---INC54396  SI LA OBLIGACION POR ALGUN MOTIVO SE PASO YA A ESTADO VIGENTE
---          NO SE PUEDE PASAR POR ESTE PROGRAMA POR QUE SE DAÑA
if @w_estado = 1
begin
   PRINT 'LA OPERACION YA SE DESEMBOLSO, NO SE PUEDE PASAR A CARTERA'
   return 708152
end


if @w_lin_credito is not null
begin
    select @w_tramite_cupo = li_tramite,
           @w_fecha_aprob  = li_fecha_aprob
      from cob_credito..cr_linea
     where li_num_banco = @w_lin_credito

    if @w_fecha_aprob is null
    begin
        ---print 'pasacart.sp entro a poner la fecha : ' + cast (@w_tramite_cupo as varchar)
       update cob_credito..cr_linea
          set li_fecha_aprob = tr_fecha_apr
         from cob_credito..cr_tramite with (nolock),
              cob_credito..cr_linea with (nolock)
        where tr_tramite =  @w_tramite_cupo
          and tr_tramite = li_tramite
          and tr_estado  = 'A'
          and tr_tipo    = 'C'
    end

end

select @w_direccion = di_direccion
  from cobis..cl_direccion
 where di_ente = @w_cliente
   and di_direccion = @w_op_direccion
set transaction isolation level read uncommitted

select @w_tipo = pd_tipo
  from cobis..cl_producto
 where pd_producto = 7
set transaction isolation level read uncommitted

if not exists (select 1 from ca_transaccion
                where tr_operacion = @w_operacionca
                  and tr_estado    <> 'NCO')
   select @w_banco = convert(varchar(24),@w_operacionca)


-- ACTUALIZACION DE DATOS OPERACION INTERCICLO
update ca_operacion
   set op_estado = @w_est_novigente,
       op_banco  = @w_banco  --- EL NUEVO NUMERO BANCO SE GENERARA EN LA LIQUIDACION
 where op_tramite = @i_tramite

if @@error <> 0 return 710002


-- BORRAR TEMPORALES
exec @w_return = sp_borrar_tmp
     @i_banco  = @w_banco,
     @s_user   = @s_user,
     @s_term   = @s_term

if @w_return <> 0
   return @w_return


---PASAR A TEMPRALES CON LOS ULTIMOS DATOS
exec @w_return          = sp_pasotmp
     @s_term            = @s_term,
     @s_user            = @s_user,
     @i_banco           = @w_banco,
     @i_operacionca     = 'S',
     @i_dividendo       = 'S',
     @i_amortizacion    = 'S',
     @i_cuota_adicional = 'S',
     @i_rubro_op        = 'S',
     @i_nomina          = 'S'

if @w_return <> 0
   return @w_return


exec @w_return = sp_modificar_operacion
     @s_user                  =  @s_user,
     @s_term                  =  @s_term,
     @s_date                  =  @s_date,
     @s_ofi                   =  @s_ofi,
     @i_operacionca           =  @w_operacionca,
     @i_banco                 =  @w_banco,
     @i_fecha_ini             =  @w_min_fecha_vig,
     @i_monto                 =  @w_monto,
     @i_monto_aprobado        =  @w_monto,
     @i_plazo                 =  @w_plazo_no_vigente,
     @i_cuota                 =  0,
     @i_tipo_amortizacion     =  @w_tipo_amortizacion,
     @i_periodo_cap           =  @w_periodo_cap,
     @i_periodo_int           =  @w_periodo_int,
     @i_dias_anio             =  @w_dias_anio,
     @i_base_calculo          =  @w_base_calculo,
     @i_gracia_cap            =  0,
     @i_gracia_int            =  0,
     @i_tplazo                =  @w_tplazo,
     @i_tdividendo            =  @w_tplazo,
     @i_calcular_tabla        =  'S'

if @w_return <> 0
   return @w_return


exec @w_return          = sp_pasodef
     @i_banco           = @w_banco,
     @i_operacionca     = 'S',
     @i_dividendo       = 'S',
     @i_amortizacion    = 'S',
     @i_cuota_adicional = 'S',
     @i_rubro_op        = 'S',
     @i_relacion_ptmo   = 'S',
     @i_nomina          = 'S',
     @i_acciones        = 'S',
     @i_valores         = 'S'

if @w_return <> 0
   return @w_return


select @w_num_oficial = fu_funcionario
  from cobis..cl_funcionario
 where fu_login = @s_user
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount <> 1 return 701051

---  Creacion de Registro en cl_det_producto
select @w_dias = datediff(dd, @w_fecha_ini, @w_fecha_fin)

exec cobis..sp_cseqnos
@t_from      = @w_sp_name,
@i_tabla     = 'cl_det_producto',
@o_siguiente = @w_siguiente out

delete from cobis..cl_det_producto
 where dp_cuenta   = @w_banco
   and dp_producto = 7

if @@error <> 0 return 710003

select @w_filial = of_filial
  from cobis..cl_oficina
 where of_oficina = @w_oficina
set transaction isolation level read uncommitted

insert into cobis..cl_det_producto (
dp_det_producto, dp_oficina,       dp_producto,
dp_tipo,         dp_moneda,        dp_fecha,
dp_comentario,   dp_monto,         dp_cuenta,
dp_estado_ser,   dp_autorizante,   dp_oficial_cta,
dp_tiempo,       dp_valor_inicial, dp_tipo_producto,
dp_tprestamo,    dp_valor_promedio,dp_rol_cliente,
dp_filial,       dp_cliente_ec,    dp_direccion_ec)
values (
@w_siguiente,    @s_ofi,         7,
@w_tipo,         @w_moneda,      @w_fecha_ini,
'OP. CREDITO APROBADA',   @w_monto,       @w_banco,
'V',             @w_num_oficial, @w_num_oficial,
@w_dias,         0,              '0',
0,               0,              'T',
@w_filial,       @w_cliente,     @w_direccion)

if @@error <> 0 return 710001

---  Creacion de Registros de Clientes
insert into cobis..cl_cliente (
cl_cliente,  cl_det_producto, cl_rol,  cl_ced_ruc,  cl_fecha)
select
de_cliente,  @w_siguiente,    de_rol,  de_ced_ruc,  @s_date
from    cob_credito..cr_deudores
where   de_tramite   = @i_tramite

if @@error <> 0 return 710001


-- DESEMBOLSO CREDITO INTERCICLO
-- LGU-ini ya se hizo en la pantalla de creacion de la forma de desembolso
/**************************************
exec @w_return         = sp_desembolso
     @s_ofi            = @s_ofi,
     @s_term           = @s_term,
     @s_user           = @s_user,
     @s_date           = @s_date,
     @i_nom_producto   = 'CCA',
     @i_producto       = @w_ncre_ahorro, -- Nota de Credito
     @i_cuenta         = @w_ah_cta_banco,
     @i_beneficiario   = @w_nombre,
     @i_ente_benef     = @w_cliente,
     @i_oficina_chg    = @s_ofi,
     @i_banco_ficticio = @w_operacionca,
     @i_banco_real     = @w_banco,
     @i_fecha_liq      = @w_min_fecha_vig,--@w_fecha_ini,
     @i_monto_ds       = @w_monto,
     @i_moneda_ds      = @w_moneda,
     @i_tcotiz_ds      = 'COT',
     @i_cotiz_ds       = 1.0,
     @i_cotiz_op       = 1.0,
     @i_tcotiz_op      = 'COT',
     @i_moneda_op      = @w_moneda,
     @i_operacion      = 'I',
     @i_externo        = 'N',
     @i_grupal         = 'N' -- LGU para interciclo

if @w_return <> 0  return @w_return
***********************************************/
-- LGU-fin ya se hizo en la pantalla de creacion de la forma de desembolso

---  LIQUIDACION AUTOMATICA

if exists(select 1 from cob_cartera..ca_desembolso
           where dm_operacion = @w_operacionca
             and dm_secuencial > 0
             and dm_desembolso > 0)
             and @w_estado =  @w_est_novigente
begin

   exec @w_return         = sp_liquida
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @s_term           = @s_term,
        @s_user           = @s_user,
        @i_banco_ficticio = @w_banco,
        @i_banco_real     = @w_banco,
        @i_fecha_liq      = @w_min_fecha_vig,--@w_fecha_ini,
		@i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
        @o_banco_generado = @w_banco_generado out

   if @w_return <> 0  return @w_return

   --- Validar si viene reestructurado de credito y colocar Numero de reestructuraciones en 0

   if exists (select 1 from cob_credito..cr_tramite
               where tr_tramite = @i_tramite
                 and tr_reestructuracion = 'S')

           update ca_operacion
              set op_reestructuracion = 'S',
                  op_numero_reest = 0
            where op_tramite = @i_tramite
   else
           update ca_operacion
              set op_reestructuracion = 'N',
                  op_numero_reest = 0
            where op_tramite = @i_tramite


   --- BORRAR TEMPORALES
   exec @w_return = sp_borrar_tmp
        @i_banco  = @w_banco,
        @s_user   = @s_user,
        @s_term   = @s_term

   if @w_return <> 0  return @w_return

   --Actualizacion op_comentario con operacion grupal
   update ca_operacion
      set op_comentario = @w_banco_generado
---------------->>>>>>>>>>>          op_forma_pago = 'NDAH'
    where op_banco = @w_banco_generado

    IF @w_tipo_flujo = 'N' -- LGU 2017-06-30  para controlar el tipo de prestamo: grupal(S), interciclo(N), individual(null)
    begin
    	-- LGU-INI 13-abr-2017 actualizar tabla de tramites grupales
    	select @w_cta_cliente = ea_cta_banco
    	from cobis..cl_ente_aux
    	where ea_ente = @w_cliente

    	update cob_credito..cr_tramite_grupal set
    	   tg_prestamo = @w_banco_generado,
    	   tg_cuenta   = @w_cta_cliente
    	where tg_grupo = @w_tg_grupo
    	and tg_cliente  = @w_cliente
    	and tg_operacion = @w_operacionca

       -- Actualizacion al prestamo grupal
       exec @w_return    = sp_actualiza_grupal
            @i_banco     = @w_tg_referencia_grupal, -- LGU 13/abr/2017  ---@w_banco_generado,
            @i_desde_cca = 'N'  -- LGU 13/abr/2017  para actualizar saldos del padre grupal

       if @w_return <> 0  return @w_return


       -- LGU-ini: crear la tabla de control de pago
       exec @w_return = sp_grupo_control_pago
            @i_banco  = @w_tg_referencia_grupal,
            @i_opcion = 'E' -- EMRGENTE

       if @w_return <> 0  return @w_return
       -- LGU-fin: crear la tabla de control de pago

       -- Mantenimiento de Ciclos
       exec @w_return         = cob_cartera..sp_man_ciclo
            @i_modo           = 'I',
            @i_grupal         = 'N',
            @i_operacion      = @w_operacionca,
            @i_tramite_grupal = @w_tramite_grupal,
            @i_cuenta_aho_grupal = @w_cta_grupal, -- LGU mando la cuenta grupal
            @i_grupo          = @w_tg_grupo,
            @i_cliente        = @w_cliente

       if @w_return <> 0  return @w_return

    END

    -- actualiza el numero de ciclo del cliente
    update cobis..cl_ente set en_nro_ciclo = isnull(en_nro_ciclo, 0) + 1
    where en_ente = @w_cliente
    -- LGU-FIN 13-abr-2017 actualizar tabla de tramites grupales


end

return 0

go

