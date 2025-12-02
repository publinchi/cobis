/************************************************************************/
/*      NOMBRE LOGICO:          proycuot.sp                             */
/*      NOMBRE FISICO:          sp_proyeccion_cuota                     */
/*      BASE DE DATOS:          cob_cartera                             */
/*      PRODUCTO:               Cartera                                 */
/*      DISENADO POR:           R Garces                                */
/*      FECHA DE ESCRITURA:     Ene 1998                                */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Simula la ejecucion del batch hasta una fecha dada y retorna        */
/*  los valores a pagar en esa fecha                                    */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA             AUTOR                   RAZON                     */
/*  13/MAY/2020       Luis Ponce              CDIG Ajustes exec sp_batch*/
/* 11/01/2021         P.Narvaez         Rubros anticipados, CoreBase    */
/* 09/03/2023         G. Fernandez      S785516 Cambios para Op. grupal */
/* 14/03/2023         G. Fernandez      B797169 Correccion de calculo de*/
/*                                      montos vigentes y sumatoria     */
/* 14/03/2023         G. Fernandez      B797169 Ing. parametro timeout  */
/* 14/03/2023         K. Rodríguez      S785526 Ajustes situación grupal*/
/* 06/06/2023	      M. Cordova		Cambio columna op_calificacion  */
/*									    de char(1) a catalogo			*/
/* 22/08/2023	      G. Fernandez		R213576 Se cambia tipo de dato  */
/*									    a int para los dias de prestamo */
/* 21/09/2023         K. Rodríguez      R215866 Se comenta cálculo de   */
/*                                      multa para precancelaciones     */
/* 27/11/2023         E. Medina         Filtro de operaciones anualdas  */
/*                                      R220205                         */
/* 04/01/2024         D. Morales        R221303:Se suma op_cuota +rubros*/
/*                                      de tipo O,Q y v                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_proyeccion_cuota')
    drop proc sp_proyeccion_cuota
go

create proc sp_proyeccion_cuota (
@s_user             varchar(14)  = null,
@s_date             datetime     = null,
@s_ofi              smallint     = null,
@s_term             varchar (30) = null,
@t_timeout          int          = null,
@i_banco            varchar(24)  = null,
@i_fecha            datetime     = null,
@i_debug            char(1)      = null,
@i_tipo_cobro       char(1)      = null,
@i_dividendo        int          = 0,
@i_tipo_proyeccion  char(1)      = null,
@i_formato_fecha    int          = null,
@i_monto_pago       money        = null,
@i_tasa_prepago     float        = 0,
@i_dias_vence       int          = 0,
@i_extracto         char(1)      = 'N',      -- JAR REQ 175 Pequeña Empresa
@i_proy             char(1)      = 'S',      -- JAR REQ 175 Pequeña Empresa
@i_operacion        char(1)      = 'I',
@i_desde_sit_grupal char(1)      = 'N',      -- KDR Desde Proceso de Situación Grupal
@o_saldo            money        = null out, -- JAR REQ 175 Pequeña Empresa
@o_saldo_prox       money        = null out  -- JAR REQ 175 Pequeña Empresa
)
as

declare
@w_sp_name            varchar(32),
@w_error              int,
@w_estado_op          smallint,
@w_operacionca        int,
@w_fecha_calculada    varchar(10),
@w_oficina_op         smallint,
@w_op_moneda          smallint,
@w_monto_op           money,
@w_cuota_op           money,
@w_cliente            int,
@w_fecha_ult_proceso  datetime,
@w_nombre             varchar(64),
@w_periodo_int        smallint,
@w_tdividendo         varchar(10),
@w_dias_anio          smallint,
@w_base_calculo       char(1),
@w_cod_cliente        int,
@w_tipo_cobro         char(1),
@w_num_periodo_d      smallint,
@w_pago_caja          char(1),
@w_periodo_d          varchar(10),
@w_migrada            varchar(24),
@w_estado             smallint,
@w_clase              varchar(10),
@w_toperacion         varchar(10),
@w_cedula             varchar(30),
@w_monto              money,
@w_valor_vencido      money,
@w_saldo_op           money,
@w_sector             catalogo,
@w_est_vigente        tinyint,
@w_est_vencido        tinyint,
@w_est_cancelado      tinyint,
@w_est_anulado        tinyint,
@w_est_novigente      tinyint,
@w_est_credito        tinyint,
@w_est_castigado      tinyint,
@w_est_suspenso       tinyint,
@w_num_dec            tinyint,
@w_tasa_comprecan     float,
@w_iva_comprecan      float,
@w_dividendo_medio    smallint,
@w_mul_precan         money,
@w_total_precan       money,
@w_dias_prestamo      int,
@w_limite_comprecan   int,
@w_cobrar_comprecan   char(1),
@w_comprecan          varchar(10),
@w_comprecan_ref      catalogo,
@w_iva_comprecan_ref  catalogo,
@w_anticipado         char(1),
@w_div_vencido        char(1),
@w_count              int,
@w_max_registros      int,
@w_banco              cuenta,
@w_fecha_proceso      datetime,
@w_nombre_grupo       descripcion,
@w_cap_vigente        money,
@w_int_vigente        money,
@w_otros_vigente      money,
@w_total_vigente      money,
@w_cap_vencido        money,
@w_int_vencido        money,
@w_imo_vencido        money,
@w_otros_vencido      money,
@w_total_vencido      money,
@w_monto_novig_cap    money,
@w_monto_novig_int    money,
@w_monto_novig_otros  money,
@w_total_novigente    money,
@w_deuda_actual       money,
@w_saldo_total        money,
@w_estado_des         varchar(24),
@w_max_dias_proyeccion int

/* CREACION DE TABLAS TEMPORALES USADAS POR EL PROCESO BATCH */
create table #rubro_mora (ro_concepto  varchar(10))

create table #ca_operacion_aux (
op_operacion          int,
op_banco              varchar(24),
op_toperacion         varchar(10),
op_moneda             tinyint,
op_oficina            smallint,
op_oficial            smallint,
op_fecha_ult_proceso  datetime,
op_dias_anio          int,
op_estado             int,
op_sector             varchar(10),
op_cliente            int,
op_fecha_liq          datetime,
op_fecha_ini          datetime,
op_dias_clausula      int,
op_calificacion       catalogo,
op_clase              varchar(10),
op_base_calculo       char(1) null,
op_periodo_int        smallint,
op_tdividendo         varchar(10),
op_causacion          char(1) null,
op_est_cobranza       varchar(10) null,
op_monto              money null,
op_fecha_fin          datetime,
op_numero_reest       int  null,
op_num_renovacion     int  null,
op_destino            varchar(10),
op_tramite            int,
op_renovacion         char(1),
op_gar_admisible      char(1),
op_tipo               char(1),
op_edad               int,
op_periodo_cap        smallint,
op_plazo              smallint,
op_tplazo             varchar(10),
op_tipo_amortizacion  varchar(10),
op_opcion_cap         char(1),
op_reestructuracion   char(1),
op_clausula_aplicada  char(1),
op_naturaleza         char(1),
op_fecha_prox_segven  datetime  null,
op_suspendio          char(1)  null,
op_fecha_suspenso     datetime null
)

select @w_sp_name = 'sp_proyeccion_cuota'

select
@w_estado_op          = op_estado,
@w_operacionca        = op_operacion,
@w_op_moneda          = op_moneda,
@w_oficina_op         = op_oficina,
@w_cliente            = op_cliente,
@w_nombre             = op_nombre,
@w_periodo_int        = op_periodo_int,
@w_tdividendo         = op_tdividendo,
@w_dias_anio          = op_dias_anio,
@w_base_calculo       = op_base_calculo,
@w_tipo_cobro         = op_tipo_cobro,
@w_pago_caja          = op_pago_caja,
@w_migrada            = isnull(op_migrada,op_banco),
@w_estado             = op_estado,
@w_clase              = op_clase,
@w_toperacion         = op_toperacion,
@w_cod_cliente        = op_cliente,
@w_periodo_d          = op_tdividendo,
@w_num_periodo_d      = op_periodo_int,
@w_sector             = op_sector,
@w_fecha_ult_proceso  =  op_fecha_ult_proceso,
@w_dias_prestamo      = datediff(dd,op_fecha_ini,op_fecha_ult_proceso)
from ca_operacion with (nolock)
where op_banco = @i_banco

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_castigado  = @w_est_castigado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_credito    = @w_est_credito   out

if @@error <> 0
begin
    set @w_error = 708201
    goto ERROR
end

--Parametro de validación de número de días para proyección de cuotas
select @w_max_dias_proyeccion = pa_int
from cobis..cl_parametro
where pa_nemonico ='MDPC'

--Se obtine fecha de proceso
select @w_fecha_proceso = fp_fecha 
from cobis..ba_fecha_proceso

--- DECIMALES
exec sp_decimales
@i_moneda    = @w_op_moneda,
@o_decimales = @w_num_dec out

select 
@w_anticipado = 'N',
@w_monto = 0
   
/* CONTROLES ANTES DE INICIAR LA PROYECCION DE CUOTA */
if (@w_max_dias_proyeccion < datediff(day,@w_fecha_proceso,@i_fecha))
begin
    set @w_error = 725278
    goto ERROR
end

if (@w_estado_op in (@w_est_novigente,@w_est_cancelado,@w_est_suspenso,@w_est_credito)and @i_operacion = 'I')
begin
    set @w_error = 710334
    goto ERROR
end

if @w_fecha_ult_proceso > @i_fecha begin
    set @w_error = 724641  --NO SE PERMITEN CONSULTAS AL PASADO
    goto ERROR
end

if (@i_operacion = 'I')
begin
   if exists (select 1 from ca_rubro_op where ro_operacion = @w_operacionca
           and ro_fpago = 'A')
   select @w_anticipado = 'S'
   
   begin tran  -- evitar que los cambios sean permanentes
   
   if @w_fecha_ult_proceso < @i_fecha begin
   
      /* EJECUCION DEL BATCH HASTA LA FECHA INDICADA */
      exec @w_error     = sp_batch
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_ofi            = @s_ofi,
      @i_en_linea       = 'N',
      @i_banco          = @i_banco,
      @i_siguiente_dia  = @i_fecha,
      @i_pry_pago       = 'S',
      @i_param1         = 0,   --LPO CDIG Ajustes exec sp_batch
      @i_param4         = 'P', --LPO CDIG Ajustes exec sp_batch
      @i_control_fecha  = 'N'  --LPO CDIG Ajustes exec sp_batch
      
      if @w_error <> 0 goto ERROR
   
   end
   
   --Si no se ha pagado los rubros anticipados del dividendo actual, se los debe cobrar primero, se valida con vencidos para no duplicar
   select @w_div_vencido = 'N'
   if exists(select 1 from ca_dividendo where di_operacion = @w_operacionca and di_estado = @w_est_vencido)
     select @w_div_vencido = 'S'
   
   
   if @i_tipo_cobro = 'A' begin
      --En los rubros anticipados se coloca el valor proyectado ya que se debe cobrar al inicio el dividendo
      if @w_anticipado = 'S'
         select @w_monto = sum(case when am_cuota + am_gracia - am_pagado  < 0 then 0
                                    when am_cuota + am_gracia - am_pagado >= 0 then am_cuota + am_gracia - am_pagado end )
         from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
         where am_operacion = @w_operacionca
         and di_operacion = am_operacion
         and di_estado  in (@w_est_vencido,@w_est_vigente )
         and   (@w_div_vencido = 'N' or am_dividendo = di_dividendo + charindex (ro_fpago, 'A'))
         and   (@w_div_vencido = 'S' or am_dividendo between di_dividendo and di_dividendo + charindex (ro_fpago, 'A'))--Anticipados no pagados se incluyen en el valor a pagar
         and am_operacion = ro_operacion
         and di_operacion = ro_operacion
         and am_concepto  = ro_concepto
         and ro_fpago     = 'A'
   
      select @w_monto = isnull(@w_monto,0) + sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0
                                                 when am_acumulado + am_gracia - am_pagado >= 0 then am_acumulado + am_gracia - am_pagado end)
      from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
      where am_operacion = @w_operacionca
      and di_operacion = am_operacion
      and di_estado  in (@w_est_vencido,@w_est_vigente )
      and am_dividendo = di_dividendo
      and am_operacion = ro_operacion
      and di_operacion = ro_operacion
      and am_concepto  = ro_concepto
      and ro_fpago     <> 'A'
   
   end else begin
   
      select
      @w_monto =  isnull(sum(am_cuota - am_pagado + am_gracia),0)
      from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
      where am_operacion = @w_operacionca
      and di_operacion = am_operacion
      and di_estado   in (@w_est_vencido,@w_est_vigente )
      and (@w_div_vencido = 'N' or am_dividendo = di_dividendo + charindex (ro_fpago, 'A'))
      and (@w_div_vencido = 'S' or am_dividendo between di_dividendo and di_dividendo + charindex (ro_fpago, 'A'))--Anticipados no pagados se incluyen en el valor a pagar
      and am_operacion = ro_operacion
      and di_operacion = ro_operacion
      and am_concepto  = ro_concepto
   
   end
   
   select @w_saldo_op = isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end),0)
   from ca_amortizacion with (nolock)
   where am_operacion = @w_operacionca
   and am_estado   <> @w_est_cancelado
   
   /* -- KDR 21/09/2023 Se comenta sección de multa de precancelación, ya que no aplica a esta version
   -- DETERMINAR SI EXISTE MULTA POR PRECANCELACIÓN
   
   --SI SE PRECANCELA EL PRESTAMOS ANTES DEL 50% DE LAS CUOTAS SE PAGA UNA MULTA
   select @w_limite_comprecan = pa_int
   from cobis..cl_parametro
   where pa_nemonico ='NCMPRE'
   
   select @w_comprecan    = 'COMPRECAN', @w_cobrar_comprecan = 'N'
   
   if @w_dias_prestamo > @w_limite_comprecan  select @w_cobrar_comprecan = 'S'
   else select @w_cobrar_comprecan = 'N'
   
   
   if @w_cobrar_comprecan = 'S' begin
   
      select @w_dividendo_medio = max(di_dividendo)/2
      from cob_cartera..ca_dividendo
      where di_operacion = @w_operacionca
   
      if exists (select 1 from ca_dividendo
      where di_operacion = @w_operacionca
      and   di_dividendo = @w_dividendo_medio
      and   di_fecha_ven >= @w_fecha_ult_proceso)
         select @w_cobrar_comprecan = 'S'
      else
         select @w_cobrar_comprecan = 'N'
   
   end
   
   if  @w_cobrar_comprecan = 'S'
   begin
   
      select
      @w_comprecan_ref   = ru_referencial
      from   cob_cartera..ca_rubro
      where  ru_toperacion = @w_toperacion
      and    ru_moneda     = @w_op_moneda
      and    ru_concepto   = @w_comprecan
   
      if @@rowcount = 0 begin
         select @w_error = 701178
         goto ERROR
      end
   
      -- DETERMINAR LA TASA DE LA COMISION POR PRECANCELACIÓN
      select
      @w_tasa_comprecan  = vd_valor_default / 100
      from   ca_valor, ca_valor_det
      where  va_tipo   = @w_comprecan_ref
      and    vd_tipo   = @w_comprecan_ref
      and    vd_sector = @w_sector -- sector comercial
   
      if @@rowcount = 0 begin
          select @w_error = 701085
          goto ERROR
      end
   
      select
      @w_iva_comprecan_ref   = ru_referencial
      from   cob_cartera..ca_rubro
      where  ru_toperacion = @w_toperacion
      and    ru_moneda     = @w_op_moneda
      and    ru_concepto   = 'IVA_COMPRE'
   
      if @@rowcount = 0 begin
         select @w_error = 701178
         goto ERROR
      end
   
      -- DETERMINAR LA TASA DE LA COMISION POR PRECANCELACIÓN
      select
      @w_iva_comprecan  = vd_valor_default / 100
      from   ca_valor, ca_valor_det
      where  va_tipo   = @w_iva_comprecan_ref
      and    vd_tipo   = @w_iva_comprecan_ref
      and    vd_sector = @w_sector -- sector comercial
   
      if @@rowcount = 0 begin
          select @w_error = 701085
          goto ERROR
      end
   
   end
   */ -- FIN KDR 21/09/2023
   
    /*CALCU:AR EL VALOR DE LA COMISION POR PRECANCELACIÓN Y SU RESPECTIVO IVA */
   select @w_mul_precan   =  round(@w_saldo_op * @w_tasa_comprecan, @w_num_dec)
   select @w_mul_precan   = @w_mul_precan + round(@w_mul_precan * @w_iva_comprecan, @w_num_dec)
   select @w_total_precan = @w_saldo_op + isnull(@w_mul_precan,0)
   
   
   select @w_valor_vencido = isnull(sum(am_cuota - am_pagado + am_gracia),0)
   from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
   where am_operacion = @w_operacionca
   and   di_operacion = am_operacion 
   and   di_operacion = ro_operacion
   and   ro_concepto  = am_concepto
   and   di_estado    = @w_est_vencido
   and   am_dividendo = di_dividendo + charindex (ro_fpago, 'A') --Rubros anticipados
   
   rollback tran  -- evitar que los cambios sean permanentes
   
   /*CONSULTA DE LOS DATOS GENERADOS*/
   create table #ca_datos_tmp (
   cedula       varchar(30) null,
   fecha_cal    varchar(10) null,
   monto_vig    money       null,
   monto_ven    money       null)
   
   select @w_cedula = en_ced_ruc
   from  cobis..cl_ente
   where en_ente  = @w_cliente
   
   select @w_fecha_calculada = convert(varchar(10),@i_fecha,@i_formato_fecha)
   
   insert into #ca_datos_tmp  values (
   @w_cedula,@w_fecha_calculada, @w_monto, @w_valor_vencido )
   
   select
   'CEDULA/RUC'         = isnull(cedula,''),
   'FECHA DE CALCULO '  = fecha_cal,
   'MONTO (VIG + VENC)' = isnull(monto_vig,0),
   'MONTO VENCIDO'      = isnull(monto_ven,0)
   from #ca_datos_tmp
   
   select @w_total_precan
end

/*  Operaciones Grupales  */
if (@i_operacion = 'G')
begin
   /*  Creación de tablas temporales  */
   if exists (select 1 from sysobjects where name = '#ca_datos_proyeccion_tmp')
      drop table #ca_datos_proyeccion_tmp
      
   create table #ca_datos_proyeccion_tmp (
   cliente            descripcion null,
   estado_op          varchar(30) null,
   monto_vig_cap      money       null,
   monto_vig_int      money       null,
   monto_vig_otros    money       null,
   monto_vig_total    money       null,
   monto_ven_cap      money       null,
   monto_ven_int      money       null,
   monto_ven_imo      money       null,
   monto_ven_otros    money       null,
   monto_ven_total    money       null,
   monto_deu_act      money       null,
   monto_novig_cap    money       null,
   monto_novig_int    money       null,
   monto_novig_otros  money       null,
   monto_sal_tot      money       null)
   
   if exists (select 1 from sysobjects where name = '#ca_lista_operaciones')
      drop table #ca_lista_operaciones
   
   create table #ca_lista_operaciones(
      op_id                  int      identity(1,1),
      op_estado              tinyint,
      op_operacion           int,
      op_banco               cuenta,
      op_moneda              tinyint,
      op_cliente             int,
      op_nombre              descripcion,
      op_monto               money,
      op_cuota               money,
      op_toperacion          catalogo,
      op_sector              catalogo,
      op_fecha_ult_proceso   datetime,
      op_dias_prestamo       int
   )
   
   insert into #ca_lista_operaciones
   select
   op_estado,
   op_operacion,
   op_banco,
   op_moneda,
   op_cliente,
   op_nombre,
   op_monto,
   op_cuota,
   op_toperacion,
   op_sector,
   op_fecha_ult_proceso,
   datediff(dd,op_fecha_ini,op_fecha_ult_proceso)
   from ca_operacion with (nolock)
   where op_grupal='S'
   and op_ref_grupal = @i_banco
   and op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_suspenso,@w_est_credito)
   
   select @w_nombre_grupo = op_nombre from ca_operacion
   where op_banco =  @i_banco

   select @w_max_registros = count(1)
   from #ca_lista_operaciones
   
   select @w_count = 1
      
   while @w_count <= @w_max_registros
   begin
   begin tran  -- evitar que los cambios sean permanentes
      select
      @w_estado_op          = op_estado,
      @w_operacionca        = op_operacion,
	  @w_banco              = op_banco,
      @w_op_moneda          = op_moneda,
      @w_cliente            = op_cliente,
      @w_nombre             = op_nombre,
	  @w_monto_op           = op_monto, 
      @w_cuota_op           = op_cuota,	  
      @w_toperacion         = op_toperacion,
      @w_sector             = op_sector,
      @w_fecha_ult_proceso  = op_fecha_ult_proceso,
      @w_dias_prestamo      = op_dias_prestamo
      from #ca_lista_operaciones
      where op_id = @w_count
	  
	  select @w_cuota_op = @w_cuota_op + isnull(sum(ro_valor),0)
      from  ca_rubro_op with (nolock)
      where ro_operacion = @w_operacionca
      and ro_fpago = 'P'
      and ro_tipo_rubro in ('Q', 'V', 'O')
	  
	  if exists (select 1 from ca_rubro_op where ro_operacion = @w_operacionca and ro_fpago = 'A')
         select @w_anticipado = 'S'

      if @w_fecha_ult_proceso < @i_fecha begin
      
         /* EJECUCION DEL BATCH HASTA LA FECHA INDICADA */
         exec @w_error     = sp_batch
         @s_user           = @s_user,
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_ofi            = @s_ofi,
         @i_en_linea       = 'N',
         @i_banco          = @w_banco,
         @i_siguiente_dia  = @i_fecha,
         @i_pry_pago       = 'S',
         @i_param1         = 0,
         @i_param4         = 'P',
         @i_control_fecha  = 'N' 
         
         if @w_error <> 0 goto ERROR
      
      end
	  
	  SELECT @w_cap_vigente       = 0,
	         @w_int_vigente       = 0,
			 @w_otros_vigente     = 0,
			 @w_total_vigente     = 0,
			 @w_cap_vencido       = 0, 
			 @w_int_vencido       = 0, 
			 @w_imo_vencido       = 0, 
			 @w_otros_vencido     = 0, 
			 @w_total_vencido     = 0,
			 @w_monto_novig_cap   = 0,
			 @w_monto_novig_int   = 0,
	         @w_monto_novig_otros = 0,
			 @w_total_novigente   = 0
      
      --Si no se ha pagado los rubros anticipados del dividendo actual, se los debe cobrar primero, se valida con vencidos para no duplicar
      select @w_div_vencido = 'N'
      if exists(select 1 from ca_dividendo where di_operacion = @w_operacionca and di_estado = @w_est_vencido)
         select @w_div_vencido = 'S'
      
	  /*  Tipo de cobro Acumulado  */
      if @i_tipo_cobro = 'A' begin
	     
         /*  Montos de capital vigente  */
         --En los rubros anticipados se coloca el valor proyectado ya que se debe cobrar al inicio el dividendo
         if @w_anticipado = 'S'
            select @w_cap_vigente = sum(case when am_cuota + am_gracia - am_pagado  < 0 then 0
                                             when am_cuota + am_gracia - am_pagado >= 0 then am_cuota + am_gracia - am_pagado end )
            from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
            where am_operacion = @w_operacionca
            and di_operacion = am_operacion
            and di_estado    = @w_est_vigente 
            and   (@w_div_vencido = 'N' or am_dividendo = di_dividendo + charindex (ro_fpago, 'A'))
            and   (@w_div_vencido = 'S' or am_dividendo between di_dividendo and di_dividendo + charindex (ro_fpago, 'A'))--Anticipados no pagados se incluyen en el valor a pagar
            and am_operacion = ro_operacion
            and di_operacion = ro_operacion
            and am_concepto  = ro_concepto
      	    and ro_tipo_rubro = 'C'
            and ro_fpago     = 'A'
      
         select @w_cap_vigente = isnull(@w_cap_vigente,0) + 
		                         sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0
                                          when am_acumulado + am_gracia - am_pagado >= 0 then am_acumulado + am_gracia - am_pagado end)
         from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
         where am_operacion = @w_operacionca
         and di_operacion = am_operacion
         and di_estado    = @w_est_vigente 
         and am_dividendo = di_dividendo
         and am_operacion = ro_operacion
         and di_operacion = ro_operacion
         and am_concepto  = ro_concepto
         and ro_tipo_rubro = 'C'
         and ro_fpago     <> 'A'
         
         /*  Montos de interés vigente  */
         if @w_anticipado = 'S'
            select @w_int_vigente = sum(case when am_cuota + am_gracia - am_pagado  < 0 then 0
                                             when am_cuota + am_gracia - am_pagado >= 0 then am_cuota + am_gracia - am_pagado end )
            from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
            where am_operacion = @w_operacionca
            and di_operacion = am_operacion
            and di_estado    = @w_est_vigente 
            and   (@w_div_vencido = 'N' or am_dividendo = di_dividendo + charindex (ro_fpago, 'A'))
            and   (@w_div_vencido = 'S' or am_dividendo between di_dividendo and di_dividendo + charindex (ro_fpago, 'A'))--Anticipados no pagados se incluyen en el valor a pagar
            and am_operacion = ro_operacion
            and di_operacion = ro_operacion
            and am_concepto  = ro_concepto
      	    and ro_tipo_rubro = 'I'
            and ro_fpago     = 'A'
      
         select @w_int_vigente = isnull(@w_int_vigente,0) + 
		                         sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0
                                          when am_acumulado + am_gracia - am_pagado >= 0 then am_acumulado + am_gracia - am_pagado end)
         from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
         where am_operacion = @w_operacionca
         and di_operacion = am_operacion
         and di_estado    = @w_est_vigente 
         and am_dividendo = di_dividendo
         and am_operacion = ro_operacion
         and di_operacion = ro_operacion
         and am_concepto  = ro_concepto
         and ro_tipo_rubro = 'I'
         and ro_fpago     <> 'A'
         
         /*  Montos de otros cargos vigente  */
         if @w_anticipado = 'S'
            select @w_otros_vigente = sum(case when am_cuota + am_gracia - am_pagado  < 0 then 0
                                               when am_cuota + am_gracia - am_pagado >= 0 then am_cuota + am_gracia - am_pagado end )
            from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
            where am_operacion = @w_operacionca
            and di_operacion = am_operacion
            and di_estado    = @w_est_vigente 
            and   (@w_div_vencido = 'N' or am_dividendo = di_dividendo + charindex (ro_fpago, 'A'))
            and   (@w_div_vencido = 'S' or am_dividendo between di_dividendo and di_dividendo + charindex (ro_fpago, 'A'))--Anticipados no pagados se incluyen en el valor a pagar
            and am_operacion = ro_operacion
            and di_operacion = ro_operacion
            and am_concepto  = ro_concepto
      	  and ro_tipo_rubro not in ('C', 'I')
            and ro_fpago     = 'A'
      
         select @w_otros_vigente = isnull(@w_otros_vigente,0) + 
		                           isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0
                                                   when am_acumulado + am_gracia - am_pagado >= 0 then am_acumulado + am_gracia - am_pagado end),0)
         from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
         where am_operacion = @w_operacionca
         and di_operacion = am_operacion
         and di_estado    = @w_est_vigente 
         and am_dividendo = di_dividendo
         and am_operacion = ro_operacion
         and di_operacion = ro_operacion
         and am_concepto  = ro_concepto
         and ro_tipo_rubro not in ('C', 'I')
         and ro_fpago     <> 'A'
      
      end 
	  else 
	      /*  Tipo de cobro Proyectado  */
	  begin

         select @w_cap_vigente =  isnull(sum(am_cuota - am_pagado + am_gracia),0)
         from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
         where am_operacion = @w_operacionca
         and di_operacion = am_operacion
         and di_estado    = @w_est_vigente
         and (@w_div_vencido = 'N' or am_dividendo = di_dividendo + charindex (ro_fpago, 'A'))
         and (@w_div_vencido = 'S' or am_dividendo between di_dividendo and di_dividendo + charindex (ro_fpago, 'A'))--Anticipados no pagados se incluyen en el valor a pagar
         and am_operacion = ro_operacion
         and di_operacion = ro_operacion
         and am_concepto  = ro_concepto
         and ro_tipo_rubro = 'C'
         
         select @w_int_vigente =  isnull(sum(am_cuota - am_pagado + am_gracia),0)
         from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
         where am_operacion = @w_operacionca
         and di_operacion = am_operacion
         and di_estado    = @w_est_vigente
         and (@w_div_vencido = 'N' or am_dividendo = di_dividendo + charindex (ro_fpago, 'A'))
         and (@w_div_vencido = 'S' or am_dividendo between di_dividendo and di_dividendo + charindex (ro_fpago, 'A'))--Anticipados no pagados se incluyen en el valor a pagar
         and am_operacion = ro_operacion
         and di_operacion = ro_operacion
         and am_concepto  = ro_concepto
         and ro_tipo_rubro = 'I'
         
         select @w_otros_vigente =  isnull(sum(am_cuota - am_pagado + am_gracia),0)
         from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op (nolock)
         where am_operacion = @w_operacionca
         and di_operacion = am_operacion
         and di_estado    = @w_est_vigente 
         and (@w_div_vencido = 'N' or am_dividendo = di_dividendo + charindex (ro_fpago, 'A'))
         and (@w_div_vencido = 'S' or am_dividendo between di_dividendo and di_dividendo + charindex (ro_fpago, 'A'))--Anticipados no pagados se incluyen en el valor a pagar
         and am_operacion = ro_operacion
         and di_operacion = ro_operacion
         and am_concepto  = ro_concepto
         and ro_tipo_rubro not in ('C', 'I')
      
      end
      
      /*  Sumatoria de montos vigentes */
      select @w_total_vigente = isnull(@w_cap_vigente + @w_int_vigente + @w_otros_vigente,0)
     
      /*  Montos de capital vencido  */
      select @w_cap_vencido = isnull(sum(am_cuota - am_pagado + am_gracia),0)
      from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
      where am_operacion = @w_operacionca
      and   di_operacion = am_operacion 
      and   di_operacion = ro_operacion
      and   ro_concepto  = am_concepto
      and   ro_tipo_rubro = 'C'  -- rubro capital
      and   di_estado    = @w_est_vencido
      and   am_dividendo = di_dividendo + charindex (ro_fpago, 'A') --Rubros anticipados
      
	  /*  Montos de interés vencido  */
      select @w_int_vencido = isnull(sum(am_cuota - am_pagado + am_gracia),0)
      from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
      where am_operacion = @w_operacionca
      and   di_operacion = am_operacion 
      and   di_operacion = ro_operacion
      and   ro_concepto  = am_concepto
      and   ro_tipo_rubro = 'I'  ---- rubro interes
      and   di_estado    = @w_est_vencido
      and   am_dividendo = di_dividendo + charindex (ro_fpago, 'A') --Rubros anticipados
      
	  /*  Montos de mora vencido  */
      select @w_imo_vencido = isnull(sum(am_cuota - am_pagado + am_gracia),0)
      from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
      where am_operacion = @w_operacionca
      and   di_operacion = am_operacion 
      and   di_operacion = ro_operacion
      and   ro_concepto  = am_concepto
      and   ro_tipo_rubro = 'M'  ---- rubro mora
      and   di_estado    = @w_est_vencido
      and   am_dividendo = di_dividendo + charindex (ro_fpago, 'A') --Rubros anticipados
      
	  /*  Montos de otros rubros vencido  */
      select @w_otros_vencido = isnull(sum(am_cuota - am_pagado + am_gracia),0)
      from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
      where am_operacion = @w_operacionca
      and   di_operacion = am_operacion 
      and   di_operacion = ro_operacion
      and   ro_concepto  = am_concepto
      and   ro_tipo_rubro not in ('C', 'I', 'M')  ---- rubro mora
      and   di_estado    = @w_est_vencido
      and   am_dividendo = di_dividendo + charindex (ro_fpago, 'A') --Rubros anticipados
      
      select @w_total_vencido = isnull(@w_cap_vencido+@w_int_vencido+@w_imo_vencido+@w_otros_vencido,0)
      
      /*  Montos de capital vigente  */
      select @w_monto_novig_cap = isnull(sum(am_cuota - am_pagado + am_gracia),0)
      from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
      where am_operacion = @w_operacionca
      and   di_operacion = am_operacion 
      and   di_operacion = ro_operacion
      and   ro_concepto  = am_concepto
      and   ro_tipo_rubro = 'C'  -- rubro capital
      and   di_estado    = @w_est_novigente
      and   am_dividendo = di_dividendo + charindex (ro_fpago, 'A') --Rubros anticipados
      
	  --Se comenta no aplica calculo de intereses y otros rubros
	  /*
      select @w_monto_novig_int = isnull(sum(am_cuota - am_pagado + am_gracia),0)
      from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
      where am_operacion = @w_operacionca
      and   di_operacion = am_operacion 
      and   di_operacion = ro_operacion
      and   ro_concepto  = am_concepto
      and   ro_tipo_rubro = 'I'  ---- rubro interes
      and   di_estado    = @w_est_novigente
      and   am_dividendo = di_dividendo + charindex (ro_fpago, 'A') --Rubros anticipados
      
      select @w_monto_novig_otros = isnull(sum(am_cuota - am_pagado + am_gracia),0)
      from  ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
      where am_operacion = @w_operacionca
      and   di_operacion = am_operacion 
      and   di_operacion = ro_operacion
      and   ro_concepto  = am_concepto
      and   ro_tipo_rubro not in ('C', 'I')  ---- rubro mora
      and   di_estado    = @w_est_novigente
      and   am_dividendo = di_dividendo + charindex (ro_fpago, 'A') --Rubros anticipados
	  */
      
      select @w_total_novigente = isnull(@w_monto_novig_cap+@w_monto_novig_int+@w_monto_novig_otros,0)
   
      rollback tran  -- evitar que los cambios sean permanentes
	  
      select @w_estado_des = es_descripcion from ca_estado where es_codigo = @w_estado_op
      select @w_deuda_actual = @w_total_vencido + @w_total_vigente,
             @w_saldo_total  = @w_total_vencido + @w_total_vigente + @w_total_novigente
				
      insert into #ca_datos_proyeccion_tmp  values (
      @w_nombre,@w_estado_des, 
      @w_cap_vigente, @w_int_vigente, @w_otros_vigente, @w_total_vigente,
      @w_cap_vencido, @w_int_vencido, @w_imo_vencido, @w_otros_vencido, @w_total_vencido, @w_deuda_actual,
      @w_monto_novig_cap, @w_monto_novig_int, @w_monto_novig_otros, @w_saldo_total)
		 
	  if @i_desde_sit_grupal = 'S'
	  begin
	    
         if object_id('tempdb..#situacion_grupal') is not null
         begin
            insert into #situacion_grupal values(
	        @w_cliente,       @w_nombre,       @w_cuota_op,    @w_monto_op,
	        @w_cap_vencido,   @w_int_vencido,  @w_imo_vencido, @w_otros_vencido, 
	        @w_total_vencido, @w_cap_vigente,  @w_int_vigente, @w_otros_vigente, 
	        @w_total_vigente, @w_deuda_actual, @w_saldo_total)		
         end		 
	  
	  end

      select @w_count = @w_count + 1
	  
   end

   if @i_desde_sit_grupal = 'N' --No viene desde Situación Grupal
   begin
      select 
      'NOMBRE_GRUPO'     = @w_nombre_grupo,
      'FECHA_PROCESO'    = convert(varchar(24),@w_fecha_proceso,@i_formato_fecha),
      'FECHA_PROYECTADA' = convert(varchar(24),@i_fecha,@i_formato_fecha)
      
      select
      'CLIENTE'      = isnull(cliente,''),
      'ESTADO'       = isnull(estado_op,''),
      'CAP_VEN'      = isnull(monto_ven_cap,0),
      'INT_VEN'      = isnull(monto_ven_int,0),
      'IMO_VEN'      = isnull(monto_ven_imo,0),
      'OTROS_VEN'    = isnull(monto_ven_otros,0),
      'TOTAL_VEN'    = isnull(monto_ven_total,0),
      'CAP_VIG'      = isnull(monto_vig_cap,0),
      'INT_VIG'      = isnull(monto_vig_int,0),
      'OTROS_VIG'    = isnull(monto_vig_otros,0),
      'TOTAL_VIG'    = isnull(monto_vig_total,0),
      'DEUDA_ACT'    = isnull(monto_deu_act,0),
      'CAP_NOVIG'    = isnull(monto_novig_cap,0),
      'INT_NOVIG'    = isnull(monto_novig_int,0),
      'OTROS_NOVIG'  = isnull(monto_novig_otros,0),
      'SALDO_TOT'    = isnull(monto_sal_tot,0)
      from #ca_datos_proyeccion_tmp
      
      select 
      'CAP_VEN_SUM'      = sum(monto_ven_cap),
      'INT_VEN_SUM'      = sum(monto_ven_int),
      'IMO_VEN_SUM'      = sum(monto_ven_imo),
      'OTROS_VEN_SUM'    = sum(monto_ven_otros),
      'TOTAL_VEN_SUM'    = sum(monto_ven_total),
      'CAP_VIG_SUM'      = sum(monto_vig_cap),
      'INT_VIG_SUM'      = sum(monto_vig_int),
      'OTROS_VIG_SUM'    = sum(monto_vig_otros),
      'TOTAL_VIG_SUM'    = sum(monto_vig_total),
      'DEUDA_ACT_SUM'    = sum(monto_deu_act),
      'CAP_NOVIG_SUM'    = sum(monto_novig_cap),
      'INT_NOVIG_SUM'    = sum(monto_novig_int),
      'OTROS_NOVIG_SUM'  = sum(monto_novig_otros),
      'SALDO_TOT_SUM'    = sum(monto_sal_tot)
      from #ca_datos_proyeccion_tmp
   
   end
     
end

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug='N',
   @t_file='',
   @t_from=@w_sp_name,
   @i_num = @w_error
   return @w_error
go
