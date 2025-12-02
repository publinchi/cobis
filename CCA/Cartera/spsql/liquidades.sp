/************************************************************************/
/*		Nombre Fisico:			liquidades.sp							*/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Nombre Logico:          sp_liquidades                           */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     12 de Febrero 1999                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA          AUTOR          CAMBIO                            */
/*      11/Dec/2002    Julio Cesar Quintero                             */
/*      05/sep/2005    ELcira P.         def 4620  BAC                  */
/*      10/OCT/2005    FDO CARVAJAL      DIFERIDOS REQ 389              */
/*      07/FEB/2007    Elcira Pelaez     def 7808                       */
/*      12/ABR/2007    Elcira Pelaez     NR-244 Pago Planifiadores      */
/*      23/abr/2010    Fdo Carvajal Interfaz Ahorros-CCA                */
/*      29/OCT/2010    Elcira Pelaez    Diferidos NR059                 */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_liquidades')
   drop proc sp_liquidades 
go

create proc sp_liquidades
(  @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_banco_ficticio   cuenta       = null,
   @i_banco_real       cuenta       = null,
   @i_fecha_liq        datetime     = null,
   @i_externo          char(1)      = 'S',
   @i_capitalizacion   char(1)      = 'N',
   @i_afecta_credito   char(1)      = 'S',
   @i_operacion_ach    char(1)      = null,
   @i_nom_producto     char(3)      = null,
   @i_tramite_batc     char(1)      = 'N',
   @i_tramite_hijo     int          = 0,
   @i_prenotificacion  int          = null,
   @i_carga            int          = null,
   @i_reestructura     char(1)      = null,
   @o_banco_generado   cuenta       = null out,
   @o_respuesta        char(1)      = null out
)
as

declare
   @w_sp_name              varchar(32),
   @w_error                int,
   @w_monto_gastos         money,
   @w_monto_op             money,
   @w_monto_des            money,
   @w_afectacion           char(1),
   @w_operacionca_ficticio int,
   @w_operacionca_real     int,
   @w_toperacion           catalogo,
   @w_oficina              int,
   @w_moneda               smallint,
   @w_fecha_ini            datetime,
   @w_fecha_fin            datetime,
   @w_est_vigente          tinyint,
   @w_est_cancelado        tinyint,
   @w_dm_producto          catalogo,
   @w_dm_cuenta            cuenta,
   @w_dm_beneficiario      descripcion,
   @w_moneda_n             tinyint,
   @w_dm_moneda            tinyint,
   @w_dm_desembolso        int,
   @w_dm_monto_mds         money,
   @w_dm_cotizacion_mds    float,
   @w_dm_tcotizacion_mds   char(1),
   @w_dm_cotizacion_mop    float,
   @w_dm_tcotizacion_mop   char(1),
   @w_dm_monto_mn          money,
   @w_dm_monto_mop         money,
   @w_ro_concepto          catalogo,
   @w_ro_valor_mn          money, 
   @w_ro_tipo_rubro        char(1),
   @w_estado_op            tinyint,
   @w_codvalor             int,
   @w_num_dec              tinyint,
   @w_num_dec_mn           tinyint,
   @w_tramite              int,
   @w_lin_credito          varchar(24),
   @w_monto                money,
   @w_tipo                 char(1),
   @w_secuencial           int,
   @w_sec_liq              int,
   @w_sector               catalogo,
   @w_ro_porcentaje        float,
   @w_oficial              smallint,
   @w_tplazo               catalogo,
   @w_plazo                int,
   @w_destino              catalogo,
   @w_ciudad               int,
   @w_num_renovacion       int,
   @w_di_fecha_ven         datetime,
   @w_int_ant              money,
   @w_int_ant_total        money,
   @w_min_dividendo        int,
   @w_operacionca          int,
   @w_operacion_real       int,
   @w_banco                cuenta,
   @w_cliente              int,
   @w_clase                catalogo,
   @w_opcion               char(1),
   @w_gar_admisible        char(1),
   @w_admisible            char(1),
   @w_tipo_garantia        tinyint,
   @w_grupo                int,
   @w_num_negocio          varchar(64),
   @w_num_doc              varchar(16),
   @w_proveedor            int,
   @w_producto             tinyint,
   @w_op_activa            int,
   @w_tasa_equivalente     char(1),
   @w_prod_cobis_ach       smallint,
   @w_categoria            catalogo,
   @w_fecha_ini_activa     datetime,
   @w_fecha_fin_activa     datetime,
   @w_fecha_ini_pasiva     datetime,
   @w_fecha_fin_pasiva     datetime,
   @w_fecha_liq_pasiva     datetime,
   @w_est_pasiva           tinyint,
   @w_op_pasiva            int,
   @w_banco_pasivo         cuenta,
   @w_op_monto_pasiva      money,
   @w_op_monto_activa      money,
   @w_porcentaje_redes     float,
   @w_intant               catalogo,
   @w_dias_anio            smallint,
   @w_monto_cex            money,
   @w_num_oper_cex         cuenta,
   @w_int_fac              catalogo,
   @w_moneda_local         smallint,
   @w_concepto_can         catalogo,
   @w_monto_mn             money,
   @w_cot_mn               money,
   @w_valor_amortizar      money,
   @w_tram_prov            int,
   @w_tramite_padre        int,
   @w_operacion_padre      int,
   @w_nominal_padre        float,
   @w_efa_padre            float,
   @w_ref_padre            catalogo,
   @w_signo_padre          char(1),
   @w_factor_padre         float,
   @w_saldo_real_pasiva    money,
   @w_valor_activas        money,
   @w_reestructuracion     char(1),
   @w_calificacion         catalogo,
   @w_parametro_amotot     catalogo, --- PILAS CON EL USO DE ESTA VARIABLE
   @w_concepto_amotot      catalogo,

   @w_valor_credito        money,
   @w_moneda_uvr           tinyint,
   @w_est_suspenso         tinyint,
   @w_tr_tipo              char(1), 
   @w_op_anterior          cuenta, 
   @w_monto_aprobado_cr    money,
   @w_op_numero_reest      int,
   @w_monto_desem_cca      money,
   @w_ro_valor             money,
   @w_rubro_timbac         catalogo, --- PILAS CON EL USO DE ESTA VARIABLE
   @w_parametro_timbac     varchar(30),
   @w_valor_timbac         money,
   @w_ro_fpago             catalogo,
   --
   @w_tipo_amortizacion    catalogo,
   @w_dias_div             int,
   @w_tdividendo           catalogo,
   @w_fecha_a_causar       datetime,
   @w_fecha_liq            datetime,
   @w_clausula             catalogo,
   @w_base_calculo         catalogo,
   @w_causacion            catalogo,
   @w_monto_validacion     money,
   @w_op_lin_credito       cuenta,
   @w_li_tramite           int,
   @w_minimo_sec           int,
   @w_monto_credito        money,
   @w_cotizacion           money,
   @w_fecha_ult_proceso    datetime,
   @w_op_codigo_externo    cuenta,
   @w_op_codigo_ext_pas    cuenta,
   @w_tr_contabilizado     char(1),
   @w_tipo_oficina_ifase   char(1),
   @w_oficina_ifase        int,
   @w_tipo_empresa         catalogo,
   @w_op_naturaleza        char(1),
   @w_concepto_intant      catalogo,
   @w_monto_total_mn       money,
   @w_cotizacion_des       float,
   @w_dtr_C                money,
   @w_dtr_D                money,
   @w_limite_ajuste        money,
   @w_diff                 money,
   @w_nombre               descripcion,
   @w_valor_tf             float,
   @w_tasa_ref             catalogo,
   @w_ts_fecha_referencial datetime,
   @w_ts_valor_referencial float,
   @w_est_diferido         tinyint, -- FCP 10/OCT/2006 - REQ 389 
   @w_codvalor_diferido    int,     -- FCP 10/OCT/2006 - REQ 389 
   @w_cod_capital          catalogo,-- FCP 10/OCT/2006 - REQ 389  
   @w_capitaliza           money,   -- FCP 10/OCT/2006 - REQ 389  
   @w_fecha_liq_val        datetime,
   @w_rowcount             int

-- VARIABLES INICIALES
select @w_sp_name       = 'sp_liquidades',
       @w_est_vigente   = 1,
       @w_est_cancelado = 3,
       @w_est_diferido  = 37, -- FCP 10/OCT/2006 - REQ 389 
       @w_dtr_C         = 0,
       @w_dtr_D         = 0

-- CONSULTA CODIGO DE MONEDA LOCAL
select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro
WHERE  pa_nemonico = 'MLO'
AND    pa_producto = 'ADM'
set transaction isolation level read uncommitted

-- CODIGO DEL MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 710120
   goto ERROR
end 

select @w_est_suspenso = es_codigo 
from   ca_estado 
where  upper(es_descripcion) like '%SUSPENSO%'

-- INICIO FCP 10/OCT/2006 - REQ 389
select @w_cod_capital  = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
set transaction isolation level read uncommitted
-- FIN FCP 10/OCT/2006 - REQ 389

if @s_date is null
begin
   select @s_date = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7
end

-- GENERACION DEL NUMERO OP_BANCO
if  @i_banco_real = @i_banco_ficticio
begin
   select @w_operacion_real    = op_operacion,
          @w_op_anterior       = op_anterior,
          @w_oficina           = op_oficina,
          @w_tramite           = op_tramite,
          @w_tipo              = op_tipo,
          @w_gar_admisible     = op_gar_admisible,
          @w_reestructuracion  = op_reestructuracion,
          @w_monto_validacion  = op_monto,
          @w_calificacion      = op_calificacion,
          @w_op_naturaleza     = op_naturaleza,
          @w_tipo_amortizacion = op_tipo_amortizacion
   from   ca_operacion
   where  op_banco = @i_banco_real
  
   --ENE-27-2005  ACTUALIZAR  LA OPERACION PARA QUE TOME EL DTF 
   if exists ( select 1 from ca_operacion_tmp
   where opt_operacion = @w_operacion_real)
   begin
      exec @w_error = sp_borrar_tmp
           @s_user       = @s_user,
           @s_sesn       = @s_sesn,
           @s_term       = @s_term,
           @i_desde_cre  = 'N',
           @i_banco      = @i_banco_real
      
      if @w_error != 0
      begin
--         PRINT 'liquidades.sp salio por error de sp_borrar_tmp @i_banco' + @i_banco_real
         select @w_error = @w_error
         goto ERROR
      end
   end
   
   if ltrim(rtrim(@w_tipo_amortizacion))  = 'MANUAL'
   begin
      exec @w_error = sp_pasotmp
           @s_user            = @s_user,
           @s_term            = @s_term,
           @i_banco           = @i_banco_real,
           @i_operacionca  = 'S',
           @i_dividendo    = 'S',
           @i_amortizacion = 'S',
           @i_cuota_adicional = 'S',
           @i_rubro_op     = 'S',
           @i_relacion_ptmo = 'S',
           @i_nomina       = 'S',
           @i_acciones     = 'S',
           @i_valores      = 'S'
      
      if @w_error != 0
      begin
--         PRINT 'liquidades.sp salio por error de sp_pasotmp @i_banco' + @i_banco_real
         goto ERROR
      end
      
      exec @w_error = sp_actualiza_tabla_manual
           @s_user              = @s_user,
           @s_sesn              = @s_sesn,
           @s_date              = @s_date,
           @s_ofi               = @s_ofi,
           @s_term              = @s_term,
           @i_operacionca       = @w_operacion_real,
           @i_crear_op           = 'S',
           @i_control_tasa      = 'S',
           @i_en_linea          = 'N'
      
      if @w_error != 0
      begin
--         print 'liquidades.sp ejecutando acttablamanual.sp'
         select @w_error = @w_error
         goto ERROR
      end
      
      exec @w_error = sp_pasodef
           @i_banco        = @i_banco_real,
           @i_operacionca  = 'S',
           @i_dividendo    = 'S',
           @i_amortizacion = 'S',
           @i_cuota_adicional = 'S',
           @i_rubro_op     = 'S',
           @i_relacion_ptmo = 'S',
           @i_nomina       = 'S',
           @i_acciones     = 'S',
           @i_valores      = 'S'
      
      if @w_error != 0
      begin
--         print 'liquidades.sp ejecutando pasodef.sp oper %1!  (MANUAL)' + @i_banco_real
         goto ERROR
      end
   end
   ELSE
   begin
      exec @w_error = sp_pasotmp
           @s_user            = @s_user,
           @s_term            = @s_term,
           @i_banco           = @i_banco_real,
           @i_operacionca  = 'S',
           @i_dividendo    = 'S',
           @i_amortizacion = 'N',
           @i_cuota_adicional = 'S',
           @i_rubro_op     = 'S',
           @i_relacion_ptmo = 'S',
           @i_nomina      = 'S',
           @i_acciones     = 'S',
           @i_valores      = 'S'
      
      if @w_error != 0
      begin
--         PRINT 'liquidades.sp salio por error de sp_pasotmp @i_banco' + @i_banco_real
         goto ERROR
      end
      
      if exists (select 1 from ca_amortizacion_tmp
               where amt_operacion = @w_operacion_real) and ltrim(rtrim(@w_tipo_amortizacion))  <> 'MANUAL'
      begin
         delete ca_amortizacion_tmp
         where amt_operacion = @w_operacion_real
      end
      
      exec @w_error = sp_modificar_operacion_int
           @s_user              = @s_user,
           @s_sesn              = @s_sesn,
           @s_date              = @s_date,
           @s_ofi               = @s_ofi,
           @s_term              = @s_term,
           @i_tipo_amortizacion = @w_tipo_amortizacion,
           @i_calcular_tabla    = 'S', 
           @i_tabla_nueva       = 'D',
           @i_salida            = 'N',
           @i_operacionca       = @w_operacion_real,
           @i_banco             = @i_banco_real
      
      if @w_error != 0
      begin
--         print 'liquidades.sp ejecutando modopint.sp oper' + @i_banco_real
         goto ERROR
      end
      
      exec @w_error = sp_pasodef
           @i_banco        = @i_banco_real,
           @i_operacionca  = 'S',
           @i_dividendo    = 'S',
           @i_amortizacion = 'S',
           @i_cuota_adicional = 'S',
           @i_rubro_op     = 'S',
           @i_relacion_ptmo = 'S',
           @i_nomina       = 'S',
           @i_acciones     = 'S',
           @i_valores      = 'S'
      
      if @w_error != 0
      begin
--         print 'liquidades.sp ejecutando pasodef.sp oper' + @i_banco_real
         goto ERROR
      end
      --ENE-27-2005  FIN ACTUALIZAR CON LA DTF DE LA FECHA
   end
            
   -- PARA OPERACIONES PASIVAS, AUMENTADO PARA INTERFACES CON COMEXT
   if @w_tipo = 'R'
      select @i_afecta_credito = 'N'
   
   if @w_tipo = 'C'
   begin
      --1 SI OPERACION ESTA RELACIONADA NO SE PUEDE DESEMBOLSAR
      --* SINO SE HA DESEMBOLSADO LA PASIVA
      select @w_fecha_ini_activa  = op_fecha_ini,
             @w_fecha_fin_activa  = op_fecha_fin
      from   ca_operacion
      where  op_operacion = @w_operacion_real
      
      select @w_op_pasiva        = rp_pasiva,
             @w_est_pasiva       = isnull(op_estado,0),
             @w_fecha_ini_pasiva = op_fecha_ini,
             @w_fecha_fin_pasiva = op_fecha_fin,
             @w_fecha_liq_pasiva = op_fecha_liq,
             @w_op_monto_pasiva  = isnull(op_monto, 0),
             @w_op_codigo_externo = op_codigo_externo
      from   ca_relacion_ptmo, ca_operacion
      WHERE  rp_activa = @w_operacion_real
      AND    rp_pasiva = op_operacion
      AND    op_estado <> 6
      
      if @@rowcount > 0
      begin
         if @w_est_pasiva <> 1  and @w_tipo <> 'R' --Vigente
         begin
            select @w_error = 708223
            goto ERROR
         end
         
         if @w_fecha_liq_pasiva <> @i_fecha_liq
         begin
            select @w_error = 708226
            goto ERROR
         end
      end 
      ELSE
      begin 
         select @w_error = 708227
         goto ERROR
      end
   end
   
   -- EN EL PRIMER DESEMBOLSO(LIQUIDACION)SE GENERA EL NUMERO BANCO
   
   if not exists (select 1
                  from   ca_transaccion
                  where  tr_operacion = @w_operacion_real)
   begin
      select @w_operacionca =  convert(int, @i_banco_ficticio)
      
      exec @w_error = sp_numero_oper
           @s_date        = @s_date,
           @i_oficina     = @w_oficina,
           @i_operacionca = @w_operacionca,
           @o_operacion   = @w_operacionca out,
           @o_num_banco   = @w_banco out
      
      if @w_error != 0
      begin
         goto ERROR
      end
      
      update ca_operacion
      set    op_banco = @w_banco
      where  op_banco = @i_banco_real
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
      
      update cobis..cl_det_producto
      set    dp_cuenta     = @w_banco,
             dp_comentario = 'OP. CARTERA'
      where  dp_producto = 7
      and    dp_cuenta = @i_banco_real
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
      
      select @i_banco_real      = @w_banco
      select @i_banco_ficticio  = @w_banco
      select @o_banco_generado  = @w_banco 
      
      -- CALCULO DEL MARGEN DE REDESCUENTO, CUANDO SE DESEMBOLSA LA ACTIVA
      -- LA OP.PASIVA DEBE YA ESTAR DESEMBOLSADA
      
      if @w_tipo = 'C'
      begin
         select @w_op_monto_activa = isnull(op_monto, 0)
         from   ca_operacion
         where  op_banco = @w_banco
         
         select @w_valor_activas = isnull(sum(rp_saldo_act),0)
         from   ca_relacion_ptmo
         where  rp_pasiva = @w_op_pasiva
         and   rp_activa  <> @w_operacion_real
         
         select @w_saldo_real_pasiva = isnull(@w_op_monto_pasiva  - @w_valor_activas,0)
         
         if @w_saldo_real_pasiva  >=  @w_op_monto_activa 
            select @w_porcentaje_redes = 100
         else 
            select @w_porcentaje_redes = round(isnull((@w_saldo_real_pasiva / convert(float, @w_op_monto_activa)), 0)  * 100,0)
         
         update ca_operacion
         set    op_margen_redescuento  = @w_porcentaje_redes
         where  op_banco = @w_banco
         
         update ca_operacion
         set    op_margen_redescuento  = @w_porcentaje_redes
         where  op_operacion = @w_op_pasiva
         
         update ca_operacion_his
         set    oph_margen_redescuento  = @w_porcentaje_redes,
                oph_codigo_externo      = @w_op_codigo_externo
         where  oph_operacion = @w_op_pasiva
         
         -- CONSULTA DE CODIGO EXTERNO DE LA PASIVA
         select @w_op_codigo_ext_pas = op_codigo_externo
         from   ca_operacion
         where  op_operacion   = @w_op_pasiva
         
         if @w_op_codigo_ext_pas is null
         begin    
            update ca_operacion
            set    op_codigo_externo   = @w_op_codigo_externo
            where  op_operacion        = @w_op_pasiva
         end
      end
   end
   ELSE
      select @w_banco = @i_banco_ficticio
end

select @w_operacionca_ficticio = op_operacion,
       @w_banco                = op_banco,
       @w_toperacion           = op_toperacion,
       @w_oficina              = op_oficina,
       @w_oficial              = op_oficial,
       @w_tplazo               = op_tplazo,
       @w_plazo                = op_plazo,
       @w_destino              = op_destino,
       @w_ciudad               = op_ciudad,
       @w_num_renovacion       = op_num_renovacion,
       @w_fecha_ini            = op_fecha_ini,
       @w_fecha_fin            = op_fecha_fin,
       @w_moneda               = op_moneda,
       @w_monto                = op_monto,
       @w_tramite              = op_tramite,
       @w_lin_credito          = op_lin_credito,
       @w_estado_op            = op_estado,
       @w_sector               = op_sector,
       @w_tipo                 = op_tipo,
       @w_fecha_ult_proceso    = op_fecha_ult_proceso,
       @w_cliente              = op_cliente,
       @w_clase                = op_clase,
       @w_tasa_equivalente     = op_usar_tequivalente,
       @w_dias_anio            = op_dias_anio,
       @w_gar_admisible        = op_gar_admisible,
       @w_reestructuracion     = op_reestructuracion,
       @w_calificacion         = op_calificacion,
       @w_tdividendo           = op_tdividendo,
       @w_fecha_liq            = op_fecha_liq,
       @w_clausula             = op_clausula_aplicada,
       @w_base_calculo         = op_base_calculo,
       @w_causacion            = op_causacion,
       @w_tipo_amortizacion    = op_tipo_amortizacion
from   ca_operacion
where  op_banco = @i_banco_ficticio

-- DETERMINAR EL VALOR DE COTIZACION DEL DIA
if @w_moneda = @w_moneda_local
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda,
      @i_fecha      = @w_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion output
end

-- FQ CAUSACION PASIVAS

if @w_estado_op != 0
begin
   if @w_tipo_amortizacion != 'MANUAL'
   begin
      select @w_dias_div = @w_dias_div * td_factor
      from   ca_tdividendo
      where  td_tdividendo = @w_tdividendo
   end
   else
   begin
      select @w_dias_div = max(di_dias_cuota)
      from   ca_dividendo
      where  di_operacion = @w_operacionca_ficticio
      and    di_estado = 1
   end
   
   if @w_tipo = 'R' -- PASIVAS
   begin
      select @w_error = 0,
             @w_fecha_a_causar = dateadd(dd, -1, @w_fecha_ult_proceso)
      
      exec @w_error = sp_calculo_diario_int
           @s_user              = @s_user,
           @s_term              = @s_term,
           @s_date              = @s_term,
           @s_ofi               = @s_ofi,
           @i_en_linea          = 'N',
           @i_toperacion        = @w_toperacion,
           @i_banco             = @w_banco,
           @i_operacionca       = @w_operacionca_ficticio,
           @i_moneda            = @w_moneda,
           @i_dias_anio         = @w_dias_anio,
           @i_sector            = @w_sector,
           @i_oficina           = @w_oficina,
           @i_fecha_liq         = @w_fecha_liq,
           @i_fecha_ini         = @w_fecha_ini,
           @i_fecha_proceso     = @w_fecha_a_causar,
           @i_tdividendo        = @w_tdividendo,
           @i_clausula_aplicada = @w_clausula,
           @i_base_calculo      = @w_base_calculo,
           @i_dias_interes      = @w_dias_div,
           @i_causacion         = @w_causacion,
           @i_tipo              = @w_tipo,
           @i_gerente           = @w_oficial,
           @i_cotizacion        = @w_cotizacion
      
      if @w_error != 0
         return @w_error
   end
end
-- CONTROLAR RANGO VALIDO DE FECHA DE LIQUIDACION
if @w_estado_op = 0 and (@i_fecha_liq < @w_fecha_ini or @i_fecha_liq > @s_date)
begin
   select @w_error = 710073 
   goto ERROR
end

select @w_di_fecha_ven = di_fecha_ven
from   ca_dividendo
where  di_operacion = @w_operacionca_ficticio
and    di_dividendo = 1

-- CONTROLAR RANGO VALIDO DE FECHA DE LIQUIDACION
if @w_estado_op = 0 and @i_fecha_liq > @w_di_fecha_ven 
begin
   --PRINT 'error de fechas No.2 710073 '
   select @w_error = 710073
   goto ERROR
end

if @w_estado_op > 0 
   select @i_fecha_liq = @w_fecha_ult_proceso

select @w_operacionca_real = op_operacion
from   ca_operacion
where  op_banco = @i_banco_real

select @w_min_dividendo = min(di_dividendo)
from   ca_dividendo
where  di_operacion    = @w_operacionca_real
and    di_estado      in (0, 1)

if @w_min_dividendo is null  --PARA ROTATIVOS CON DIVIDENDOS CANCELADOS
begin
   select @w_min_dividendo = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion    = @w_operacionca_real
end

select @w_gar_admisible = isnull(@w_gar_admisible, 'N')

if @w_tramite is not null 
begin
   exec @w_error = cob_custodia..sp_gar_admisible
        @s_date      = @s_date,
        @i_tramite   = @w_tramite,
        @o_admisible = @w_admisible out
   
   if @w_error <> 0
   begin
      select @w_error = 2108025
      goto ERROR
   end
   
   if @w_gar_admisible <> @w_admisible 
   begin
      update ca_operacion
      set    op_gar_admisible = @w_admisible
      where  op_operacion     = @w_operacionca_real
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
      
      update ca_operacion
      set    op_gar_admisible = @w_admisible
      where  op_operacion     = @w_operacionca_real
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
      
      select @w_gar_admisible = @w_admisible
   end
end
   
-- MANEJO DE DECIMALES
exec @w_error = sp_decimales
     @i_moneda       = @w_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_mn out

if @w_error != 0 
begin
   goto ERROR
end    

-- DETERMINAR EL SECUENCIAL DE DESEMBOLSO A APLICAR
select @w_secuencial = min(dm_secuencial)
from   ca_desembolso
where  dm_operacion  = @w_operacionca_real
and    dm_estado     = 'NA'
if @w_secuencial <= 0 or @w_secuencial is null
begin
   select @w_error = 701121
   goto ERROR
end

-- VERIFICACION DE QUE LOS MONTOS DESEMBOLSADOS + DESCUENTOS = CAPITAL
select @w_monto_op    = isnull(sum(ro_valor),0)
from   ca_rubro_op
where  ro_operacion  = @w_operacionca_ficticio
and    ro_tipo_rubro = 'C'  

select @w_monto_gastos = isnull(sum(ro_valor),0)
from   ca_rubro_op,
       ca_rubro
where  ro_operacion   = @w_operacionca_ficticio
and    ro_fpago       = 'L' 
and    ro_concepto    = ru_concepto
and    ru_banco        = 'S'
and    ru_toperacion   = @w_toperacion
and    ru_moneda       = @w_moneda

 select @w_monto_gastos = isnull(@w_monto_gastos,0)

if @w_estado_op = 0  --SOLO SE COBRAND ANTICIPADOS EN LA LIQUIDACION
begin
   if (@w_tipo = 'D' ) or (@w_tipo = 'F') 
   begin
      select @w_int_ant = round(isnull(sum(am_cuota),0),@w_num_dec)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion    = @w_operacionca_ficticio
      and    ro_operacion    = @w_operacionca_ficticio
      and    ro_concepto     = am_concepto
      and    ro_tipo_rubro   = 'I'
      and    ro_fpago        = 'A'
   end
   ELSE
   begin
      select @w_int_ant = round(isnull(sum(am_cuota),0),@w_num_dec)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion    = @w_operacionca_ficticio
      and    am_dividendo    = 1
      and    ro_operacion    = @w_operacionca_ficticio
      and    ro_concepto     = am_concepto
      and    ro_fpago        = 'A'
   end
   
   select @w_monto_gastos = @w_monto_gastos + isnull(@w_int_ant,0)
   
   -- SELECT PARA DETERMINAR EL INTERES TOTAL DE LA OPERACION
   select @w_int_ant_total = round(isnull(sum(am_cuota + am_gracia),0),@w_num_dec)
   from   ca_amortizacion,ca_rubro_op
   where  am_operacion  = @w_operacionca_ficticio
   and    ro_operacion  = @w_operacionca_ficticio
   and    ro_concepto   = am_concepto
   and    ro_tipo_rubro = 'I'
   and    ro_fpago      = 'T'
   
   select @w_monto_gastos = @w_monto_gastos + isnull(@w_int_ant_total,0)
   select @w_monto_gastos = round(@w_monto_gastos,@w_num_dec)
end

-- SI SE TRATA DE CAPITALIZACION, NO GENERAR GASTOS ANTICIPADOS
if @i_capitalizacion = 'S'
   select @w_monto_gastos = 0.00    

select @w_monto_des      = isnull(sum(dm_monto_mop),0),
       @w_cotizacion_des = isnull(avg(dm_cotizacion_mop),0)
from   ca_desembolso
where  dm_operacion    = @w_operacionca_real
and    dm_secuencial   = @w_secuencial

if @w_monto_op != @w_monto_gastos + @w_monto_des 
begin
   select @w_error = 710017
   goto ERROR
end


---EPB:21ABR2005:DEFECTO:3224
if @w_monto_op - round(@w_monto_gastos ,@w_num_dec) <= 0
begin
   select @w_error = 710556
   goto ERROR
end


-- GENERACION DEL NUMERO DE RECIBO DE LIQUIDACION
exec @w_error = sp_numero_recibo
     @i_tipo    = 'L',
     @i_oficina = @s_ofi, 
     @o_numero  = @w_sec_liq out

if @w_error != 0
begin
   goto ERROR
end

-- XMA  POR PEDIDO DEL BANCO - CIRCULAR 11
-- SI LA OPERACION ES RENOVADA MANTIENE LA CALIFICACION DE LA OPERACION ORIGINAL
-- POR TRAMITE DE REESTRUCTURACION

select @w_tr_tipo = tr_tipo
from   cob_credito..cr_tramite
where  tr_tramite = @w_tramite

if @@rowcount = 0
begin
  select @w_error = 710391
  goto ERROR
end

if @w_tr_tipo in ('E')
begin
   select @w_calificacion = op_calificacion,
          @w_tipo_empresa = op_tipo_empresa
   from   ca_operacion 
   where  op_banco = @w_op_anterior

   if @w_calificacion is null 
   begin
      select @w_error = 141138   
      goto ERROR
   end
   

   if exists (select    1
              from      cob_cartera..ca_operacion,
                        cob_credito..cr_op_renovar
              where     op_banco        = or_num_operacion
              and       op_tipo_empresa = 'C'
              and       or_tramite      = @w_tramite)
        update cob_cartera..ca_operacion
        set    op_tipo_empresa = 'C'
        where  op_tramite  = @w_tramite
           
   -- JCQ ACTUALIZACION CALIFICACION Y TIPO EMPRESA EN ca_operacion
   
   update ca_operacion
   set    op_calificacion = @w_calificacion,
          op_tipo_empresa = @w_tipo_empresa
   where  op_operacion    = @w_operacionca_real
   
   if @@error != 0
   begin
     select @w_error = 705076
     goto ERROR
   end
   

end

if exists (select 1 from ca_transaccion
where tr_operacion = @w_operacionca_real
and tr_tran = 'DES'
and tr_estado not in ('NCO','RV'))
begin
--   PRINT 'ERROR, Existe un desembolso que no ha sido reversado'
   select @w_error = 710088
   goto ERROR
end    
      

-- GENERACION DE RESPALDO PARA REVERSAS
exec @w_error = sp_historial    
     @i_operacionca = @w_operacionca_real,
     @i_secuencial  = @w_secuencial 

if @w_error != 0
begin
   select @w_error = @w_error
   goto ERROR
end


insert into ca_transaccion
      (tr_secuencial,        tr_fecha_mov,        tr_toperacion,
       tr_moneda,            tr_operacion,        tr_tran, 
       tr_en_linea,          tr_banco,            tr_dias_calc,
       tr_ofi_oper,          tr_ofi_usu,          tr_usuario,
       tr_terminal,          tr_fecha_ref,        tr_secuencial_ref,
       tr_estado,            tr_gerente,          tr_gar_admisible,
       tr_reestructuracion,  tr_calificacion,
       tr_observacion,    tr_fecha_cont, tr_comprobante)
values(@w_secuencial,        @s_date,             @w_toperacion,
       @w_moneda,            @w_operacionca_real, 'DES',
       'N',                  @i_banco_real,       @w_sec_liq,
       @w_oficina,           @s_ofi,              @s_user,
       @s_term,              @i_fecha_liq,        0,
       'ING',                @w_oficial,          isnull(@w_gar_admisible,''),
       isnull(@w_reestructuracion,''), isnull(@w_calificacion,''),
       '',           @s_date,      0)

if @@error !=0 
begin
--   print 'liquidades.sp insertando en ca_transaccion oper' + @i_banco_real
   select @w_error = 710001
   goto ERROR
end

-- INSERCION DEL DETALLE CONTABLE PARA LAS FORMAS DE PAGO
declare cursor_desembolso cursor
for select dm_desembolso,    dm_producto,          dm_cuenta,
           dm_beneficiario,  dm_monto_mds,
           dm_moneda,        dm_cotizacion_mds,    dm_tcotizacion_mds,
           dm_monto_mn,      dm_cotizacion_mop,    dm_tcotizacion_mop,
           dm_monto_mop
    from   ca_desembolso
    where  dm_secuencial = @w_secuencial 
    and    dm_operacion  = @w_operacion_real
    order  by dm_desembolso
    for read only

open cursor_desembolso

fetch cursor_desembolso
into  @w_dm_desembolso,   @w_dm_producto,       @w_dm_cuenta,
      @w_dm_beneficiario, @w_dm_monto_mds,
      @w_dm_moneda,       @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
      @w_dm_monto_mn,     @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
      @w_dm_monto_mop
   
while @@fetch_status = 0 
begin
   if (@@fetch_status = -1) 
   begin
      select @w_error = 701121
      goto ERROR
   end  
   
   select @w_prod_cobis_ach = isnull(cp_pcobis,0),  ---EPB:feb-06-2002
          @w_categoria      = cp_categoria
   from   ca_producto
   where  cp_producto = @w_dm_producto
      
   select @w_codvalor = cp_codvalor
  from   ca_producto
   where  cp_producto = @w_dm_producto
   
   if @@rowcount != 1
   begin
--      print 'liquidades.sp CONCEPTO1.....' + @w_dm_producto
      select @w_error = 701150
      goto ERROR
   end
   
   -- INSERCION DEL DETALLE DE LA TRANSACCION
   insert ca_det_trn
         (dtr_secuencial,    dtr_operacion,        dtr_dividendo,
          dtr_concepto,      dtr_estado,           dtr_periodo,
          dtr_codvalor,      dtr_monto,            dtr_monto_mn,
          dtr_moneda,        dtr_cotizacion,       dtr_tcotizacion,
          dtr_afectacion,    dtr_cuenta,           dtr_beneficiario,
          dtr_monto_cont)
   values(@w_secuencial,     @w_operacionca_real,  @w_dm_desembolso,
          @w_dm_producto,    1,                    0, 
          @w_codvalor,       @w_dm_monto_mds,      @w_dm_monto_mn,
          @w_dm_moneda,      @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
          'C',               @w_dm_cuenta,         @w_dm_beneficiario,
          0)
   
   if @@error !=0
   begin
--      print 'liquidades.sp insertando en ca_det_trn oper ' + @i_banco_real
      select @w_error = 710001  
      goto ERROR
   end 
   
   if  @w_prod_cobis_ach <> 0 
   begin
      select @w_oficina_ifase = @s_ofi
      
      select @w_tipo_oficina_ifase = dp_origen_dest
      from   ca_trn_oper, cob_conta..cb_det_perfil
      where  to_tipo_trn = 'DES'
      and    to_toperacion = @w_toperacion
      and    dp_empresa    = 1
      and    dp_producto   = 7
      and    dp_perfil     = to_perfil
      and    dp_codval     = @w_codvalor
      
      if @@rowcount = 0
      begin
         select @w_error = 710446
         goto ERROR
      end
      
      if @w_tipo_oficina_ifase = 'C'
      begin
         select @w_oficina_ifase = pa_int
         from   cobis..cl_parametro
         where  pa_nemonico = 'OFC'
         and    pa_producto = 'CON'
         set transaction isolation level read uncommitted
      end
      
      if @w_tipo_oficina_ifase = 'D'
      begin
         select @w_oficina_ifase = @w_oficina
      end
      
      -- AFECTACION A OTROS PRODUCTOS
      exec @w_error = sp_afect_prod_cobis
           @s_user               = @s_user,
           @s_date               = @s_date,
           @s_ssn                = @s_ssn,
           @s_sesn               = @s_sesn,
           @s_term               = @s_term,
           @s_srv                = @s_srv,
           @s_ofi                = @w_oficina_ifase,
           @i_fecha              = @i_fecha_liq,
           @i_en_linea           = 'N',
           @i_cuenta             = @w_dm_cuenta,
           @i_producto           = @w_dm_producto,
           @i_monto              = @w_dm_monto_mn,
           @i_mon                = @w_dm_moneda,  -- ELA FEB/2002 
           @i_beneficiario       = @w_dm_beneficiario,
           @i_monto_mpg          = @w_dm_monto_mds,
           @i_monto_mop          = @w_dm_monto_mop,
           @i_monto_mn           = @w_dm_monto_mn,
           @i_cotizacion_mop     = @w_dm_cotizacion_mop,
           @i_tcotizacion_mop    = @w_dm_tcotizacion_mop,
           @i_cotizacion_mpg     = @w_dm_cotizacion_mds,
           @i_tcotizacion_mpg    = @w_dm_tcotizacion_mds,
           @i_operacion_renovada = @w_operacion_real,
           @i_alt                = @w_operacion_real,
           @i_sec_tran_cca       = @w_secuencial,   -- FCP Interfaz Ahorros
           @o_num_renovacion     = @w_num_renovacion out
      
      if @w_error != 0
      begin
--         print 'liquidades.sp insertando en afpcobis.sp oper' + @i_banco_real
         goto ERROR
      end
   end
   
   -- INTERFAZ PARA SIPLA
   if @w_op_naturaleza = 'A'
   begin
      exec @w_error = sp_interfaz_otros_modulos
           @s_user       = @s_user,
           @i_cliente    = @w_cliente,
           @i_modulo     = 'CCA',
           @i_interfaz   = 'S',
           @i_modo       = 'I',
           @i_obligacion = @w_banco,
           @i_moneda     = @w_dm_moneda,
           @i_sec_trn    = @w_secuencial,
           @i_fecha_trn  = @i_fecha_liq,
           @i_desc_trn   = 'DESEMBOLSO DE CARTERA',
           @i_monto_trn  = @w_dm_monto_mop,
           @i_monto_trn  = @w_dm_monto_mop,
           @i_monto_des  = @w_dm_monto_mds,
           @i_gerente    = @s_user,
           @i_oficina    = @s_ofi,
           @i_cotizacion = @w_dm_cotizacion_mop,
           @i_forma_pago = @w_dm_producto,
           @i_categoria  = @w_categoria,
           @i_moneda_uvr = @w_moneda_uvr
      
      if @w_error != 0
      begin
--         print 'liquidades.sp insertando en interform.sp oper' + @i_banco_real
         goto ERROR
      end
   end
   
   fetch cursor_desembolso
   into  @w_dm_desembolso,   @w_dm_producto,       @w_dm_cuenta,
         @w_dm_beneficiario, @w_dm_monto_mds,
         @w_dm_moneda,       @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
         @w_dm_monto_mn,     @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
         @w_dm_monto_mop
end
   
close cursor_desembolso
deallocate cursor_desembolso

-- OBTENCION DE LA COTIZACION Y TIPO DE COTIZACION DE LA OPERACION
select @w_dm_cotizacion_mop  = dm_cotizacion_mop,
       @w_dm_tcotizacion_mop = dm_tcotizacion_mop
from   ca_desembolso
where  dm_operacion    = @w_operacionca_real
and    dm_secuencial   = @w_secuencial

-- INSERCION DEL DETALLE CONTABLE PARA LOS RUBROS AFECTADOS
declare cursor_rubro cursor
for select ro_concepto,ro_valor,ro_tipo_rubro,ro_fpago
    from   ca_rubro_op
    where  ro_operacion = @w_operacionca_ficticio
    and    ( ro_fpago  in ('L','A') or (ro_tipo_rubro = 'C') )
    and    ro_tipo_rubro <> 'I'  ---Salen en otro select
    order  by ro_concepto
    for read only

open cursor_rubro

fetch cursor_rubro
into  @w_ro_concepto, @w_ro_valor, @w_ro_tipo_rubro, @w_ro_fpago

while   @@fetch_status = 0 
begin
   if (@@fetch_status = -1) 
   begin
      select @w_error = 710004
      goto ERROR
   end
   
   select @w_tipo_garantia = 0  --NO ADMISIBLE
   
   if @w_ro_tipo_rubro = 'C'
   begin
      if @w_gar_admisible = 'S' 
         select @w_tipo_garantia = 1  --ADMISIBLE
      
      update ca_rubro_op
      set    ro_garantia  = ro_valor * @w_tipo_garantia
      where  ro_operacion = @w_operacionca_real
      and    ro_concepto  = @w_ro_concepto
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
      
     
      -- cambio de los campos am_correccion_xxx a la nueva tabla ca_correccion
      update ca_correccion
      set    co_liquida_mn = round (convert(float, am_cuota) * convert(float, @w_dm_cotizacion_mop), @w_num_dec_mn)
      from   ca_amortizacion, ca_rubro_op,ca_correccion
      where  ro_operacion = @w_operacionca_real
      and    am_operacion = @w_operacionca_real
      and    ro_operacion = am_operacion
      and    ro_concepto  = am_concepto
      and    ro_concepto  = @w_ro_concepto
      and    co_operacion = am_operacion
      and    co_concepto  = am_concepto 
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
   end
   
   -- COLOCAR COMO PAGADOS LOS RUBROS DEL DIVIDENDO 1 QUE SON ANT  <> de INTERESES
   if @w_ro_fpago = 'A'
   begin
      update ca_amortizacion
      set    am_pagado = am_cuota,
             am_estado = @w_est_cancelado
      from   ca_rubro_op
      where  am_operacion  = @w_operacionca_real
      and    (am_dividendo = 1 and @w_tipo != 'D' and @w_tipo != 'F')
      and    ro_operacion  = @w_operacionca_real
      and    am_concepto   = ro_concepto
      and    ro_tipo_rubro <> 'I'
      and    ro_fpago      = 'A'
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
      
      select @w_ro_valor =  am_cuota
      from   ca_amortizacion
      where  am_operacion  = @w_operacionca_real
      and    am_dividendo = 1 
      and    am_concepto     = @w_ro_concepto
     
   end
   
   -- SE ASUME QUE UNA OPERACION NUEVA NO TIENE ASIGNADA GARANTIA
   -- OBTENCION DE CODIGO VALOR DEL RUBRO
   select @w_codvalor = co_codigo * 1000  + 10  + 0 --@w_tipo_garantia
   from   ca_concepto
   where  co_concepto = @w_ro_concepto
   
   if @@rowcount != 1
   begin
--      print 'liquidades.sp CONCEPTO2.....' + @w_ro_concepto
      select @w_error = 701151
      goto ERROR
   end 
   
   select @w_ro_valor_mn =round(@w_ro_valor*@w_dm_cotizacion_mop,@w_num_dec_mn)
   select @w_ro_valor =round(@w_ro_valor,@w_num_dec_mn)
   
   if @w_ro_tipo_rubro = 'C'
      select @w_afectacion = 'D'
   else
      select @w_afectacion = 'C'
   
   -- INSERCION DEL DETALLE DE LA TRANSACCION
   insert ca_det_trn
         (dtr_secuencial,    dtr_operacion,       dtr_dividendo,        dtr_concepto,
          dtr_estado,        dtr_periodo,         dtr_codvalor,         dtr_monto,
          dtr_monto_mn,      dtr_moneda,          dtr_cotizacion,       dtr_tcotizacion,
          dtr_afectacion,    dtr_cuenta,          dtr_beneficiario,     dtr_monto_cont)
   values(@w_secuencial,     @w_operacionca_real, @w_min_dividendo,     @w_ro_concepto,
          1,                 0,                   @w_codvalor,          @w_ro_valor,
          @w_ro_valor_mn,    @w_moneda,           @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
          @w_afectacion,     '',                  '',                   0)
   
   if @@error !=0
   begin
--      print 'liquidades.sp insertando en ca_det_trn 2 oper' + @i_banco_real
      select @w_error = 710001 
      goto ERROR
   end
   
   --EPBSEP182004
   if @w_tipo != 'R' and @w_tramite is not null
   begin
      select @w_tr_contabilizado = tr_contabilizado
      from    cob_credito..cr_tramite
      where    tr_tramite in (select li_tramite
                              from   cob_credito..cr_tramite, cob_credito..cr_linea
                              where  tr_tramite = @w_tramite
                              and    li_numero  = tr_linea_credito 
                              and    li_tipo = 'O')
      
      if @w_ro_tipo_rubro = 'C' and   @w_tr_contabilizado = 'S'
      begin
         select @w_codvalor = co_codigo * 1000  + 990
         from   ca_concepto
         where  co_concepto = @w_ro_concepto
         
         -- INSERCION DEL DETALLE DE LA TRANSACCION
         insert ca_det_trn
               (dtr_secuencial,    dtr_operacion,       dtr_dividendo,        dtr_concepto,
                dtr_estado,        dtr_periodo,         dtr_codvalor,         dtr_monto,
                dtr_monto_mn,      dtr_moneda,          dtr_cotizacion,       dtr_tcotizacion,
                dtr_afectacion,    dtr_cuenta,          dtr_beneficiario,     dtr_monto_cont)
         values(@w_secuencial,     @w_operacionca_real, @w_min_dividendo,     @w_ro_concepto,
                1,                 0,                   @w_codvalor,          @w_ro_valor,
                @w_ro_valor_mn,    @w_moneda,           @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
                @w_afectacion,     '',                  '',                   0)
         
         if @@error !=0
         begin
--            print 'liquidades.sp insertando en ca_det_trn 3 oper' + @i_banco_real
            select @w_error = 710001 
            goto ERROR
         end
      end
   end
   --EPBSEP182004
   
   fetch cursor_rubro
   into @w_ro_concepto, @w_ro_valor, @w_ro_tipo_rubro, @w_ro_fpago
end

close cursor_rubro
deallocate cursor_rubro

---ENE-07-2005 VALIDACION DE LA GENERACION DEL DETALLE COMPLETO
select @w_limite_ajuste = pa_money
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'LAJUST'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
   select @w_limite_ajuste = 1

select @w_dtr_D = isnull(sum(dtr_monto_mn),0)
from   ca_det_trn
where  dtr_operacion = @w_operacionca_real
and    dtr_secuencial  = @w_secuencial
and    dtr_codvalor != 10990
and    dtr_afectacion = 'D'

select @w_dtr_C =  isnull(sum(dtr_monto_mn),0)
from   ca_det_trn
where  dtr_operacion = @w_operacionca_real
and    dtr_secuencial  = @w_secuencial
and    dtr_codvalor != 10990
and    dtr_afectacion = 'C'

if @w_dtr_D  <> @w_dtr_C
begin
   select @w_diff = (@w_dtr_D  - @w_dtr_C)
   
   if (@w_moneda <> @w_moneda_local) and (abs(@w_diff) <= @w_limite_ajuste)
      select   @w_diff = @w_diff   
   else
   begin
     select @w_error = 710551
     goto ERROR   
   end
end 

---ENE-07-2005 VALIDACION DE LA GENERACION DEL DETALLE COMPLETO
if (@w_tipo = 'D' ) or (@w_tipo = 'F')
begin  -- Documento Descontado 
   insert into ca_det_trn
         (dtr_secuencial,        dtr_operacion,        dtr_dividendo,
          dtr_concepto,          dtr_estado,           dtr_periodo,
          dtr_codvalor,          dtr_monto,            dtr_monto_mn,
          dtr_moneda,            dtr_cotizacion,       dtr_tcotizacion,
          dtr_afectacion,        dtr_cuenta,           dtr_beneficiario,
          dtr_monto_cont)
   select @w_secuencial,         @w_operacionca_real,  @w_min_dividendo,
          am_concepto,          1,                    0,
          co_codigo*1000+10+0,   am_cuota,            round(am_cuota*@w_dm_cotizacion_mop,@w_num_dec_mn),
          @w_moneda,             @w_dm_cotizacion_mop, '',
          'C',                   '',                   '',
          0
   from   ca_amortizacion, ca_concepto ,ca_rubro_op
   where  am_operacion  = @w_operacionca_ficticio
   and    am_concepto   = co_concepto
   and    ro_operacion  = @w_operacionca_ficticio
   and    ro_concepto   = am_concepto
   and    ro_tipo_rubro = 'I'
   and    ro_fpago      = 'A'
   
   if @@error != 0
   begin
--      print 'liquidades.sp insertando en ca_det_trn 4 oper' + @i_banco_real
      select @w_error = 710001
      goto ERROR
   end
   
   update ca_amortizacion
   set    am_pagado    = am_cuota,
          am_acumulado = 0
   from   ca_rubro_op
   where  am_operacion  = @w_operacionca_ficticio
   and    ro_operacion  = @w_operacionca_ficticio
   and    am_concepto   = ro_concepto
   and    ro_tipo_rubro = 'I'
   and    ro_fpago      = 'A'
   
   if @@error != 0
   begin
      select @w_error = 710002
      goto ERROR
   end
end 
ELSE
begin
   --* INSERCION DE LOS DETALLES CORRESPONDIENTES A
   --* LOS INTERESES PERIODICOS ANTICIPADOS
   insert into ca_det_trn
         (dtr_secuencial,        dtr_operacion,        dtr_dividendo,
          dtr_concepto,          dtr_estado,           dtr_periodo,
          dtr_codvalor,          dtr_monto,            dtr_monto_mn,
          dtr_moneda,            dtr_cotizacion,       dtr_tcotizacion,
          dtr_afectacion,        dtr_cuenta,           dtr_beneficiario,
          dtr_monto_cont)
   select @w_secuencial,         @w_operacionca_real,  @w_min_dividendo,
          am_concepto,          1,                    0,
          co_codigo*1000+10+0,   am_cuota,            round(am_cuota*@w_dm_cotizacion_mop,@w_num_dec_mn),
          @w_moneda,             @w_dm_cotizacion_mop, 'C',      
         'C',                    '',                   'REGISTRO INTERESES ANTICIPADOS',
          0
   from   ca_amortizacion, ca_concepto ,ca_rubro_op
   where  am_operacion = @w_operacionca_ficticio 
   and    am_dividendo = 1
   and    am_concepto  = co_concepto
   and    ro_operacion = @w_operacionca_ficticio 
   and    ro_concepto  = am_concepto
   and    ro_tipo_rubro= 'I'
   and    ro_fpago     = 'A'
   
   if @@error != 0
   begin
--      print 'liquidades.sp insertando en ca_det_trn 5 oper' + @i_banco_real
      select @w_error = 710001
      goto ERROR
   end
   
   update ca_amortizacion
   set    am_pagado    = am_cuota,
          am_estado    = @w_est_cancelado,
          am_acumulado = 0
   from   ca_rubro_op
   where  am_operacion = @w_operacionca_ficticio
   and    am_dividendo = 1
   and    ro_operacion = @w_operacionca_ficticio
   and    am_concepto  = ro_concepto
   and    ro_tipo_rubro = 'I'
   and    ro_fpago      = 'A'
   
   if @@error != 0
   begin
      select @w_error = 710002
      goto ERROR
   end
end

--* PONER VIGENTE LA OPERACION Y AL PRIMER DIVIDENDO
--* SI SE TRATA DE LA PRIMERA LIQUIDACION
if @w_estado_op = 0 
begin -- NO VIGENTE
   update ca_amortizacion
   set    am_pagado    = am_cuota,
          am_acumulado = 0,
          am_estado    = @w_est_cancelado
   from   ca_rubro_op
   where  am_operacion  = @w_operacionca_real
   and    (am_dividendo = 1 and @w_tipo != 'D' and @w_tipo != 'F')
   and    ro_operacion  = @w_operacionca_real
   and    am_concepto   = ro_concepto
   and    ro_tipo_rubro = 'I'  
   and    ro_fpago      = 'A'
   
   if @@error != 0
   begin
      select @w_error = 710002
      goto ERROR
   end
   
   -- INSERTAR TASAS EN CA_TASAS
   declare cursor_rubro cursor
   for select ro_concepto
       from   ca_rubro_op
       where  ro_operacion   = @w_operacionca_real
       and    ro_tipo_rubro  = 'I'
       for read only
   
   open cursor_rubro
   
   fetch cursor_rubro
   into  @w_ro_concepto
   
   while   @@fetch_status = 0 
   begin
      if (@@fetch_status = -1) begin
         select @w_error = 710004
         goto ERROR
      end
      
      -- HEREDAR LAS TASAS DEL PADRE
      if (@w_tipo = 'F') and (@i_tramite_batc = 'S') and (@i_tramite_hijo <> 0)
      begin
         exec @w_error = sp_consulta_tasas
              @i_operacionca = @w_operacionca_real,
              @i_dividendo   = 1,
              @i_concepto    = @w_ro_concepto,
              @i_sector      = @w_sector,
              @i_fecha       = @i_fecha_liq,
              @i_equivalente = @w_tasa_equivalente,
              @o_tasa        = @w_ro_porcentaje out
         
         if @w_error <> 0
         begin
            goto ERROR
         end
         
         select @w_tramite_padre = fa_tramite
         from   cob_credito..cr_facturas
         where  fa_tram_prov = @i_tramite_hijo
         
         if @@error != 0
         begin
            select @w_error = 710001
            goto ERROR
         end
         
         select @w_operacion_padre  = op_operacion
         from   ca_operacion
         where  op_tramite = @w_tramite_padre
         
         select @w_nominal_padre = ts_porcentaje,
                @w_efa_padre     = ts_porcentaje_efa,
                @w_ref_padre     = ts_referencial,
                @w_signo_padre   = ts_signo,
                @w_factor_padre  = ts_factor
         from   ca_tasas
         where  ts_operacion = @w_operacion_padre
         and    ts_concepto  = 'INTDES'
         
         if @@error != 0
         begin
            select @w_error = 710001
            goto ERROR
         end
         
         update ca_tasas
         set    ts_porcentaje     = @w_nominal_padre,
                ts_porcentaje_efa = @w_efa_padre,
                ts_referencial    = @w_ref_padre ,
                ts_signo          = @w_signo_padre,
                ts_factor         = @w_factor_padre
         where  ts_operacion =  @w_operacionca_real
         and    ts_concepto    = 'INTDES'
         
         if @@error != 0
         begin
            select @w_error = 710001
            goto ERROR
         end
      end
      ELSE
      begin
         exec @w_error = sp_consulta_tasas
              @i_operacionca = @w_operacionca_real,
              @i_dividendo   = 1,
              @i_concepto    = @w_ro_concepto,
              @i_sector      = @w_sector,
              @i_fecha       = @i_fecha_liq,
              @i_equivalente = @w_tasa_equivalente,
              @o_tasa        = @w_ro_porcentaje out
         
         if @w_error <> 0
         begin
            goto ERROR
         end
 end
      
      fetch cursor_rubro
      into @w_ro_concepto
   end
   
   close cursor_rubro
   deallocate cursor_rubro
   
   if @w_fecha_ini < @i_fecha_liq
   begin
      update ca_operacion
      set    op_estado            = @w_est_vigente,
             op_fecha_ult_proceso = @w_fecha_ini,
             op_fecha_liq         = @i_fecha_liq
      where  op_operacion = @w_operacionca_real
   end
   ELSE
   begin
      update ca_operacion
      set    op_estado            = @w_est_vigente,
             op_fecha_ult_proceso = @i_fecha_liq,
             op_fecha_liq         = @i_fecha_liq
      where  op_operacion = @w_operacionca_real
   end
   
   if @@error != 0
   begin
      select @w_error = 710002
      goto ERROR
   end 
   
   if (@w_tipo = 'D' ) or ( @w_tipo = 'F')
   begin
      update ca_dividendo
      set    di_estado = 1
      where  di_operacion = @w_operacionca_real
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
      
      update ca_amortizacion
      set    am_estado = 1
      where  am_operacion = @w_operacionca_real
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end 
   end
   ELSE
   begin
      update ca_dividendo
      set    di_estado = 1
      where  di_operacion = @w_operacionca_real
      and    di_dividendo = 1
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end 
      
      update ca_amortizacion
      set    am_estado = 1
      where  am_operacion  = @w_operacionca_real
      and    am_dividendo  = 1
      and    am_estado != 3
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end 
   end
   
   -- ACTUALIZACION DE FECHA DE DESEMBOLSO DE CREDITOS ASOCIACTIVOS 
   --***************************************************************
   exec @w_error = cob_credito..sp_in_cupos_asoc 
        @s_date            = @s_date,
        @i_operacion       = 'L',
        @i_operacionca     = @w_operacionca_real
   
   if @w_error != 0 
   begin
      select @w_error = 2108024
      goto ERROR
   end

   --if @i_externo = 'S'
   --   select @i_banco_real -- SALIDA PARA FRONTEND
   
   if (isnull(@w_tramite,0) = 0 and @i_afecta_credito = 'S') 
   begin
      select @w_monto_total_mn  = round(isnull((@w_monto_op * @w_cotizacion_des),0),@w_num_dec_mn)
      
      select @w_monto_des  = round(isnull((@w_monto_des * @w_cotizacion_des),0),@w_num_dec_mn)
      
      -- GENERAR UN TRAMITE EN CASO DE CREACION DIERECTA DESDE CARTERA
      exec @w_error = cob_credito..sp_tramite_cca
           @s_ssn            = @s_ssn,
           @s_user           = @s_user,
           @s_sesn           = @s_sesn,
           @s_term           = @s_term,
           @s_date           = @s_date,
           @s_srv            = @s_srv,
           @s_lsrv           = @s_lsrv,
           @s_ofi            = @s_ofi,
           @i_oficina_tr     = @w_oficina,
           @i_fecha_crea     = @i_fecha_liq,
           @i_oficial        = @w_oficial,
           @i_sector         = @w_sector,
           @i_banco          = @i_banco_real,
           @i_linea_credito  = @w_lin_credito,
           @i_toperacion     = @w_toperacion,
           @i_producto       = 'CCA',
           @i_monto          = @w_monto_op,
           @i_monto_mn       = @w_monto_total_mn,
           @i_monto_des      = @w_monto_des,
           @i_moneda         = @w_moneda,
           @i_periodo        = @w_tplazo,
           @i_num_periodos   = @w_plazo,
           @i_destino        = @w_destino,
           @i_ciudad_destino = @w_ciudad,
           @i_renovacion     = @w_num_renovacion,
           @i_clase          = @w_clase,
           @i_cliente        = @w_cliente,
           @o_tramite        = @w_tramite out
      
      if @w_error != 0
      begin
         select @w_error = 2108024
         goto ERROR
      end
      
      update ca_operacion 
      set    op_tramite = @w_tramite  --AUMENTADO
      where  op_banco = @i_banco_real
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
      
      -- ACTUALIZA HISTORICO Y EN CASO REVERSA NO SE PIERDA EL NUMERO DE TRAMITE ASIGNADO
      update ca_operacion_his
      set    oph_tramite = @w_tramite  --AUMENTADO
      where  oph_banco = @i_banco_real
      
      if @@error != 0
      begin
         select @w_error = 710002
         goto ERROR
      end
   end
   
   -- INDICAR A CREDITO QUE LA OPERACION HA SIDO LIQUIDADA
   if @i_afecta_credito = 'S'
   begin 
      exec @w_error = cob_credito..sp_int_credito1
           @s_ofi              = @s_ofi,
           @s_ssn              = @s_ssn,
           @s_sesn             = @s_sesn,
           @s_user             = @s_user,
           @s_term             = @s_term,
           @s_date             = @s_date,
           @s_srv              = @s_srv,
           @s_lsrv             = @s_lsrv,
           @t_trn              = 21889,
           @i_tramite          = @w_tramite,
           @i_numero_op        = @w_operacionca_real,
           @i_numero_op_banco  = @i_banco_real,
           @i_fecha_concesion  = @s_date,
           @i_fecha_fin        = @w_fecha_fin,
           @i_monto            = @w_monto,
           @i_tabla_temporal   = 'N'
      
      if @w_error != 0 
      begin
         select @w_error = 2108024
         goto ERROR
      end 
   end
end 
ELSE -- estado <> 0
begin 
   -- DESEMBOLSO PARCIAL
   exec @w_error = sp_desembolso_parcial
        @i_banco          = @i_banco_real,
        @i_banco_ficticio = @i_banco_ficticio 
   
   if @w_error != 0 
   begin
      goto ERROR
   end 
   
   -- CONTROL PARA NO DESEMBOLSAR MAS DE LO APROBADO EN MONEDA UVR
   -- MONTO APROBADO EN CREDITO
   if @w_moneda = @w_moneda_uvr
   begin
      select @w_monto_aprobado_cr = tr_admisible
      from   cob_credito..cr_tramite
      where  tr_tramite     = @w_tramite
   end
   ELSE
   begin
      select @w_monto_aprobado_cr = op_monto_aprobado
      from   cob_cartera..ca_operacion
      where  op_operacion   = @w_operacionca_real
   end
   
   -- cambio de los campos am_correccion_xxx a la nueva tabla ca_correccion
   select @w_monto_desem_cca = round(sum(co_liquida_mn), @w_num_dec_mn)
   from   ca_correccion
   where  co_operacion = @w_operacionca_real
   
   --fin cambio
   
   if (@w_monto_desem_cca > @w_monto_aprobado_cr) and (@w_monto_desem_cca - @w_monto_aprobado_cr) > 0.02
   begin
--     print 'liquidades.sp MONTO DESEMBOLSADO + MONTO A DESEMBOLSAR, SUPERA EL MONTO APROBADO'
     select @w_error = 1
     goto ERROR
   end
   
   -- ACTUALIZACION DE EL CAMPO op_numero_reest
   if @i_reestructura = 'S'
   begin
      update ca_operacion
      set    op_numero_reest = isnull(op_numero_reest,0) + 1
      --op_fecha_reest   = @i_fecha_liq   no existe en esta version 
      where  op_banco   = @i_banco_real
      
      if @@error != 0
      begin
         select @w_error = 705007
         goto ERROR
      end 
      select @w_op_numero_reest = @w_op_numero_reest + 1
   end
end

-- *********************************
-- PRODUCTO COBIS
select @w_producto = dt_prd_cobis
from   cob_cartera..ca_default_toperacion
where  dt_toperacion = @w_toperacion
and    dt_moneda     = @w_moneda

-- AFECTACION A LA LINEA EN CREDITO
if @w_lin_credito is not null
begin
   if @w_tipo = 'R'
      select @w_opcion = 'P'  -- PASIVA
   else
      select @w_opcion = 'A'  -- ACTIVA
   
   ---EPB 18ABR2005 esta validacion aplica solo si la moneda es diferenet de Pesos
   if @w_moneda <> 0
   begin
      
      select @w_monto_op = isnull(tr_montop,0)   ---monto en pesos sin descontar valores anticipados
      from   cob_credito..cr_tramite
      where  tr_tramite = @w_tramite
      
      if @w_monto_op = 0
      begin
         select @w_error = 710498
         goto ERROR
      end
   end
   
   exec @w_error = cob_credito..sp_utilizacion
        @s_ofi         = @s_ofi,
        @s_ssn         = @s_ssn,
        @s_sesn        = @s_sesn,
        @s_user        = @s_user,
        @s_term        = @s_term,
        @s_date        = @s_date,
        @s_srv         = @s_srv,
        @s_lsrv        = @s_lsrv,
        @s_rol         = @s_rol,
        @s_org         = @s_org,
        @t_trn         = 21888,
        @i_linea_banco = @w_lin_credito,
        @i_producto    = 'CCA',
        @i_toperacion  = @w_toperacion,
        @i_tipo        = 'D',
        @i_moneda      = @w_moneda,
        @i_monto       = @w_monto_op,
        @i_cliente     = @w_cliente ,
        @i_secuencial  = @w_secuencial,
        @i_tramite     = @w_tramite,
        @i_opcion      = @w_opcion,
        @i_opecca      = @w_operacionca_ficticio,
        @i_fecha_valor = @i_fecha_liq,
        @i_modo        = 0,
        @i_monto_cex   = @w_monto_cex,
        @i_numoper_cex = @w_num_oper_cex,
        @i_batch       = 'S'
   
   if @w_error != 0
   begin
      select @w_error = 2108024
      goto ERROR
   end
   
   if @w_banco is null
   begin
      select @w_banco = op_banco 
      from   ca_operacion 
      where  op_operacion = @w_operacionca_real
   end
end
ELSE
begin
   if @w_tipo <> 'R' 
   begin
      select @w_opcion = 'A'  --   SOLO OPERACIONES REDESCUENTO PARTE ACTIVA
      
      ---EPB 18ABR2005 esta validacion aplica solo si la moneda es diferenet de Pesos
      if @w_moneda <> 0
      begin
         select @w_monto_op = isnull(tr_montop,0)   ---monto en pesos sin descontar valores anticipados
         from   cob_credito..cr_tramite
         where  tr_tramite = @w_tramite
         
         if @w_monto_op = 0
         begin
            select @w_error = 710498
            goto ERROR
         end
      end
      
      exec @w_error = cob_credito..sp_utilizacion
           @s_ofi         = @s_ofi,
           @s_ssn         = @s_ssn,
           @s_sesn        = @s_sesn,
           @s_user        = @s_user,
           @s_term       = @s_term,
           @s_date        = @s_date,
           @s_srv         = @s_srv,
           @s_lsrv        = @s_lsrv,
           @s_rol         = @s_rol,
           @s_org         = @s_org,
           @t_trn         = 21888,
           @i_linea_banco = @w_lin_credito,
           @i_producto    = 'CCA',
           @i_toperacion  = @w_toperacion,
           @i_tipo        = 'D',
           @i_moneda      = @w_moneda,
           @i_monto       = @w_monto_op,
           @i_cliente     = @w_cliente,
           @i_secuencial  = @w_secuencial,
           @i_tramite     = @w_tramite,
           @i_opcion      = @w_opcion,
           @i_opecca      = @w_operacionca_ficticio,
           @i_fecha_valor = @i_fecha_liq,
           @i_modo        = 1,
           @i_batch       = 'S'
      
      if @w_error != 0
      begin
         select @w_error = 2108024
         goto ERROR
      end
   end --Tipo <> R
end--Else

--  MARCAR COMO APLICADOS LOS DESEMBOLSOS UTILIZADOS
if @w_prod_cobis_ach in (248,249) 
begin
   update ca_desembolso 
   set    dm_estado = 'I'
   where  dm_secuencial = @w_secuencial
   and    dm_operacion  = @w_operacionca_real
end -- PARA MBS
ELSE
begin
   update ca_desembolso 
   set    dm_estado          = 'A',
          dm_prenotificacion = @i_prenotificacion,
          dm_carga           = @i_carga
   where  dm_secuencial = @w_secuencial
   and    dm_operacion  = @w_operacionca_real
end -- actualizacion normal

if @@error <> 0
begin
   select @w_error = 710002
   goto ERROR
end

if (@w_tipo <> 'D'  and  @w_tipo <> 'F')
begin
   exec @w_error = cob_custodia..sp_activar_garantia
        @i_opcion     = 'L',
        @i_tramite    = @w_tramite,
        @i_modo       = 1,
        @i_operacion  = 'I',
        @s_date       = @s_date,
        @s_user       = @s_user,
        @s_term       = @s_term,
        @s_ofi        = @s_ofi,
        @i_bandera_be = 'N'
   
   if @w_error != 0
   begin
      while @@trancount > 1 rollback
      select @w_error = 2108025
      goto ERROR
   end 
   ELSE
   begin
      while @@trancount > 1 commit tran
   end
end

-- CONTROL PARA INTANT
select @w_intant = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INTANT'      -- pga 2nov2001
set transaction isolation level read uncommitted

select @w_int_fac = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INTFAC'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error =  710256
   goto ERROR
end

select @w_concepto_intant   = ro_concepto
from   ca_rubro_op
where  ro_operacion  = @w_operacionca_ficticio
and    ro_tipo_rubro = 'I'
and    ro_fpago = 'A'
and   ( (ro_concepto = @w_intant) or (ro_concepto = @w_int_fac))

if @@rowcount <> 0 
begin --EXISTE INTERES ANTICIPADO
   exec @w_error =  sp_pagos_por_amortizar
        @s_user             = @s_user,
        @s_ofi              = @s_ofi,
        @s_term             = @s_term,
        @s_date             = @s_date,
        @i_toperacion       = @w_toperacion,
        @i_reestructuracion = @w_reestructuracion,
        @i_gar_admisible    = @w_gar_admisible,
        @i_calificacion     = @w_calificacion,
        @i_operacionca      = @w_operacionca_ficticio,
        @i_oficial          = @w_oficial,
        @i_moneda           = @w_moneda,
        @i_oficina          = @w_oficina,
        @i_operacion        = 'I',
        @i_fecha_liq        = @i_fecha_liq,
        @i_banco_real       = @i_banco_real,
        @i_concepto_intant  = @w_concepto_intant,
        @i_cotizacion       = @w_cotizacion
   
   if @w_error != 0 
   begin
      select @w_error = @w_error
      goto ERROR
   end
end  --*Existe INTANT

if @w_tipo = 'C' 
begin
   select @w_op_pasiva = rp_pasiva
   FROM   ca_relacion_ptmo, ca_operacion
   WHERE  rp_activa = @w_operacionca_ficticio
   AND    rp_pasiva = op_operacion
   AND    op_estado <> 6
   
   select @w_banco_pasivo = tr_banco
   from   ca_transaccion
   where  tr_operacion =  @w_op_pasiva
   and    tr_tran = 'DES'
   
   if @w_banco_pasivo is not null 
   begin
      update ca_operacion
      set    op_banco = @w_banco_pasivo
      where  op_operacion = @w_op_pasiva
   end
end

/*if (@w_op_numero_reest >= 2) 
begin
   -- REALIZAR CAMBIO DE ESTADO DE LA OPERACION A SUSPENSO
   exec @w_error    = sp_cambio_estado_op
        @s_user          = @s_user,
        @s_term          = @s_term,
        @s_date          = @s_date,
        @s_ofi           = @s_ofi,
        @i_banco         = @i_banco_real,
        @i_fecha_proceso = @i_fecha_liq,
        @i_estado_ini    = @w_estado_op,
        @i_estado_fin    = @w_est_suspenso,
        @i_tipo_cambio   = 'M',
        @i_en_linea      = 'N'
       @i_gerente       = @w_oficial
        @i_moneda        = @w_moneda,
        @i_oficina       = @w_oficina,
        @i_operacionca   = @w_operacionca_real,
        @i_toperacion    = @w_toperacion       

   if @w_error != 0
   begin
      goto ERROR
   end 
end */

select @w_parametro_timbac = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'TIMBAC'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount =  0
begin  
   select @w_error = 710363
   goto ERROR
end

-- **************** Inicio LAM ***************
if exists(select 1   
          from   ca_rubro_op
          where  ro_operacion = @w_operacionca_ficticio
          and    ro_concepto  = @w_parametro_timbac
          and    ro_fpago     = 'B'
          and    ro_valor     > 0)
begin
   -- OBTENCION DE CODIGO VALOR DEL RUBRO
   select @w_codvalor = co_codigo * 1000  + 10  + 0,
          @w_rubro_timbac = co_concepto
   from   ca_concepto
   where  co_concepto  = @w_parametro_timbac
   
   if @@rowcount =  0
   begin  
      select @w_error = 710364
      goto ERROR
   end
   
   select @w_valor_timbac = ro_valor
   from   ca_rubro_op
   where  ro_operacion = @w_operacionca_ficticio
   and    ro_concepto  = @w_rubro_timbac
   and    ro_fpago     = 'B'
   
   exec @w_error = sp_conversion_moneda
        @s_date         = @s_date,
        @i_opcion       = 'L',
        @i_moneda_monto = @w_moneda,
        @i_moneda_resul = @w_moneda_local,
        @i_monto        = @w_valor_timbac,
        @i_fecha        = @i_fecha_liq,
        @o_monto_result = @w_monto_mn out,
        @o_tipo_cambio  = @w_cot_mn out
   
   insert ca_det_trn
         (dtr_secuencial,  dtr_operacion,           dtr_dividendo,
          dtr_concepto,    dtr_estado,              dtr_periodo,
          dtr_codvalor,    dtr_monto,               dtr_monto_mn,
          dtr_moneda,      dtr_cotizacion,          dtr_tcotizacion,
          dtr_afectacion,  dtr_cuenta,              dtr_beneficiario,
          dtr_monto_cont)
   values(@w_secuencial,   @w_operacionca_ficticio, 1,
          @w_rubro_timbac, 1,                       0,
          @w_codvalor,     @w_valor_timbac,         @w_valor_timbac,
          @w_moneda,       @w_cot_mn,               'C',
          'C',             '000000',                'RUBROS QUE ASUME EL BANCO',0)
   
   if @@error != 0
   begin
      select @w_error = 710001
      goto ERROR
   end
end

-- MODIFICACION SOLO DE LA PARTE DE INTERES
if ltrim(rtrim(@w_tipo_amortizacion))  = 'MANUAL'
begin
   exec @w_error = sp_reajuste_interes 
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @i_operacionca    = @w_operacionca_ficticio,   
        @i_fecha_proceso  = @i_fecha_liq,
        @i_banco          = @i_banco_real,
        @i_en_linea       = 'S'
   
   if @w_error != 0 
   begin
--      PRINT 'liquidades.sp salio por error de sp_reajuste_interes @i_banco' + @i_banco_real
      goto ERROR
   end  
end --Reajsute interes tabla manual

--VALIDAR QUE LA TASA ESTE CORRECTA CON LA FECHA DE LIQUIDACION
select @w_fecha_liq_val = op_fecha_liq
from ca_operacion
where op_operacion = @w_operacion_real

select @w_tasa_ref              = ts_tasa_ref,
       @w_ts_fecha_referencial  = ts_fecha_referencial,
       @w_ts_valor_referencial  = ts_valor_referencial
from ca_tasas
where ts_operacion = @w_operacion_real
and   ts_concepto = 'INT'

if @@rowcount > 0
begin
   if exists (select 1 from cobis..te_pizarra
              where pi_referencia = @w_tasa_ref)
   begin
      select @w_valor_tf = pi_valor
      from   cobis..te_pizarra
      where  @w_fecha_liq_val between pi_fecha_inicio and pi_fecha_fin
      and    pi_referencia = @w_tasa_ref
      
      if   @w_valor_tf != @w_ts_valor_referencial
      begin 
         select @w_error = 710571
         goto ERROR
      end
   end
end 

--FIN VALIDAR QUE LA TASA ESTE CORRECTA CON LA FECHA DE LIQUIDACION    

---NR-244
if exists (select 1 from ca_pago_planificador
           where  pp_operacion = @w_operacionca_ficticio
           and    pp_estado =  'I')
begin
   update ca_pago_planificador
   set pp_secuencial_des = @w_secuencial
   where    pp_operacion = @w_operacionca_ficticio
   and     pp_estado =  'I'
end
---NR-244
    
return 0

ERROR:
   return @w_error
go
