/************************************************************************/
/*   Nombre Fisico      :     cartsobr.sp                               */
/*   Nombre Logico   	:     sp_carterizacion_sobregiro                */
/*   Base de datos      :     cob_cartera                               */
/*   Producto           :     Credito y Cartera                         */
/*   Disenado por       :     Luis Alfonso Mayorga                      */
/*   Fecha de escritura :     Dic 2005                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
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
/*                           PROPOSITO                                  */
/*   Crear una  operación por efecto de la cartetización de un sobregiro*/
/*   El campo op_divcap_original de la ca_operacion será usado para     */
/*   guardar el número de dias de vencido del sobregiro                 */
/*   Este campo debe tenerse en cuenta en cualquier calculo de dias de  */
/*   vencimiento                                                        */
/*                        ACTUALIZACIONES                               */
/*  FECHA            AUTOR             RAZON                            */
/*  12/Abr/2006       Ivan Jimenez      Correccion RFP 609              */
/*  17/Jul/2007       FGQ               Correccion def.8494   BAC       */
/*  24/Jun/2021       KDR               Nuevo parámetro sp_liquid       */
/*    06/06/2023	 M. Cordova		  Cambio variable @i_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_carterizacion_sobregiro')
   drop proc sp_carterizacion_sobregiro
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

---PRINT 'VER. 9.0 Def.8494 EPB-Jul-17-2007'

create proc sp_carterizacion_sobregiro
   @s_user              login        = null,
   @s_sesn              int          = null,
   @s_ofi               smallint     = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   @t_debug             char(1)      = 'N',  -- IFJ Defecto 200 RFP 609
   @t_file              varchar(10)  = null, -- IFJ Defecto 200 RFP 609
   @i_cliente           int,
   @i_toperacion        catalogo,
   @i_oficina           smallint,
   @i_fecha_ini         datetime,
   @i_total_sobregiro   money,
   @i_lin_credito       cuenta       = null,
   @i_codigo_ext_gar    cuenta,
   @i_dias_vencido      smallint,
   @i_calificacion      catalogo,
   @i_procesa_batch     char(1)      = 'N',    -- OJO: N = CARGA DE DATOS PARA CARTERIZAR  S = PROCESO BATCH DE CARTERA
   @i_operacion         int          = 0  out 
   
as
declare
   @w_sp_name           varchar(30),
   @w_tran_count        int,
   @w_error             int,
   @w_count             int,
   @w_moneda            smallint,
   @w_operacionca       int,
   @w_direccion         tinyint,
   @w_direccion_lar     varchar(50),
   @w_fecha_proceso     datetime,   --HRE Ref 001 04/03/2002
   @w_dias_control      int,        --HRE Ref 001 04/03/2002
   @w_dias_hoy          int,        --HRE Ref 001 04/03/2002
   @w_banco             cuenta,
   @w_oficial           smallint,
   @w_sector            catalogo,
   @w_nombre            descripcion,
   @w_clase_cartera     catalogo,
   @w_origen_fondos     catalogo,
   @w_ciudad            int,
   @w_destino           catalogo,
   @w_tramite           int,
   @w_ruta              int,
   @w_mercado_obj       catalogo,
   @w_abierta_cerrada   char(1),
   @w_concepto          catalogo,
   @w_estado_gar        char(1),
   @w_identificacion    numero,      -- IFJ Defecto 200 RFP 609
   @w_descuentos        money,
   @w_desembolsar       money,
   @w_dias              smallint,
   @w_oficina           smallint,
   @w_direccion_det     int,
   @w_num_oficial       int,
   @w_siguiente         int,
   @w_filial            tinyint,
   @w_cs_secuencial     int,
   @w_rubro_segvida     varchar(30),
   @w_rowcount          int
   
   
select @w_sp_name = 'sp_carterizacion_sobregiro'
   
if @i_procesa_batch = 'N'
begin
   select @w_fecha_proceso = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7  -- 7 pertence a Cartera
   
   if not exists (select 1
                  from  ca_carteriza_sobregiros
                  where cs_estado_cateriza = 'I'
                  and   cs_cliente         = @i_cliente
                  and   cs_codigo_ext_gar  = @i_codigo_ext_gar)
   begin
      
      select @w_cs_secuencial = isnull(max(cs_secuencial),0)
      from ca_carteriza_sobregiros
      
      select @w_cs_secuencial = @w_cs_secuencial + 1
      
      
      insert into ca_carteriza_sobregiros
        (cs_secuencial,       cs_sesn,             cs_user,          cs_ofi,
         cs_date,             cs_term,          cs_cliente,
         cs_toperacion,       cs_oficina,       cs_fecha_ini,
         cs_total_sobregiro,  cs_lin_credito,   cs_codigo_ext_gar,
         cs_dias_vencido,     cs_calificacion,  cs_estado_cateriza,
         cs_estado_batch,     cs_operacion)
      values
        (@w_cs_secuencial,    @s_sesn,             @s_user,          @s_ofi,
         @s_date,             @s_term,          @i_cliente,
         @i_toperacion,       @i_oficina,       @w_fecha_proceso,   --@w_fecha_proceso = @i_fecha_ini,
         @i_total_sobregiro,  null,             @i_codigo_ext_gar,  --@i_lin_credito   = null
         @i_dias_vencido,     @i_calificacion,  'I',
         'N',                 null)
   
      if @@error != 0
      begin
         select @w_error = @@error
         goto ERROR
      end
   end   
   return 0
end
else
begin -- inicio @i_procesa_batch = S

   select @w_ruta = 3,
          @w_moneda = 0,
          @w_tran_count = @@trancount

   -- RUBRO DE SEGURO DE VIDA   
   select  @w_rubro_segvida = pa_char
   from    cobis..cl_parametro
   where   pa_nemonico = 'SEGURO'
   and     pa_producto = 'CCA'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
   begin
      select @w_error = 710215
      goto ERROR
   end


   -- DIAS CONTROL TRAMITE
   select @w_dias_control = pa_smallint
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'DCTRA'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
   begin
      select @w_error = 710215
      goto ERROR
   end
   
   -- OFICIAL DE SOBREGIROS
   select @w_oficial = pa_smallint
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'OFISOB'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
   begin
      select @w_error = 710215
      goto ERROR
   end
   
   -- SECTOR DE SOBREGIROS
   select @w_sector = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'SECSOB'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
   begin
      select @w_error = 710215
      goto ERROR
   end
   

   -- ORIGEN DE FONDOS DE SOBREGIROS
   select @w_origen_fondos = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'OFOSOB'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @@rowcount = 0
   begin
      select @w_error = 710215
      goto ERROR
   end
   
   -- DESTINO ECONOMICO DE SOBREGIROS
   select @w_destino = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'DESSOB'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
   begin
      select @w_error = 710215
      goto ERROR
   end
   
   -- DESTINO ECONOMICO DE SOBREGIROS
   select @w_concepto = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'CTOSOB'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
   begin
      select @w_error = 710416
      goto ERROR
   end
   
   if not exists(select 1
                 from   ca_producto
                 where  cp_producto = @w_concepto
                 and    cp_desembolso = 'S')
   begin
      select @w_error = 710416
      goto ERROR
   end
   
   -- CIUDAD DE LA OFICINA DEL SOBREGIRO
   select @w_ciudad = of_ciudad
   from   cobis..cl_oficina
   where  of_oficina = @i_oficina
   
   if @@rowcount = 0
   begin
      select @w_error = 701102
      goto ERROR
   end
   
   -- NOMBRE DEL DEUDOR
   select @w_nombre         = en_nomlar,
          @w_identificacion = en_ced_ruc  --IFJ Defecto 200 RFP 609
   from   cobis..cl_ente
   where  en_ente = @i_cliente
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
   begin
      select @w_error = 701054
      goto ERROR
   end
   
   select @w_mercado_obj = mo_mercado_objetivo
   from   cobis..cl_mercado_objetivo_cliente --(index cl_mercado_objetivo_Key prefetch 16)
   where  mo_ente = @i_cliente
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
      select @w_mercado_obj = ''
   
   -- CLASE DE CARTERA
   select @w_clase_cartera = '2'
   if (select count(1)
       from   ca_operacion
       where  op_cliente = @i_cliente
       and    op_clase = '4') = 1
   begin
      select @w_clase_cartera = '4'
   end
   ELSE
   begin
      if (select count(1)
          from   ca_operacion
          where  op_cliente = @i_cliente
          and    op_clase = '1') >= 1
      begin
         select @w_clase_cartera = '1'
      end
   end
   
   -- CONTROL DE DIAS DE CREACION
   select @w_fecha_proceso = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7  -- 7 pertence a Cartera
   
   select @w_dias_hoy = datediff(dd,@i_fecha_ini,@w_fecha_proceso)
   
   if @w_dias_hoy > @w_dias_control
   begin
      select @w_error = 710212
      goto ERROR
   end
   -- FIN REF 001
   
   --LA DIRECCION INICIAL ES LA No.1 LA CUAL SE MODIFICA UNA VEZ SE CREA LA OBLIGACION
   --POR LA PANTALLA DE PARAMETROS EN LA CREACION MISMA O ACTUALIZACIOn
   select @w_direccion = min(di_direccion) 
   from   cobis..cl_direccion
   where  di_ente    = @i_cliente
   and    di_vigencia  = 'S'
   and    di_principal = 'S'
   set transaction isolation level read uncommitted
   
   if @w_direccion is not null
   begin
      select @w_direccion_lar = di_descripcion
      from   cobis..cl_direccion
      where  di_ente    = @i_cliente
      and    di_direccion = @w_direccion
   end
   
   -- NUMERO DE TRAMITE
   exec cobis..sp_cseqnos
        @t_debug     = 'N',
        @t_file      = 'cartsobr.sp', 
        @t_from      = 'sp_carterizacion_sobregiros',
        @i_tabla     = 'cr_tramite',
        @o_siguiente = @w_tramite out
   
   if @@error != 0 or @w_tramite is NULL
   begin
      select @w_error = 2101007
      goto ERROR
   end
   
   exec @w_error = sp_crear_operacion_int
        @s_user                  = @s_user,
        @s_sesn                  = @s_sesn,
        @s_ofi                   = @s_ofi,
        @s_date                  = @s_date,
        @s_term                  = @s_term,
        @i_anterior              = null,
        @i_migrada               = null,
        @i_tramite               = @w_tramite,
        @i_cliente               = @i_cliente,
        @i_nombre                = @w_nombre,
        @i_sector                = @w_sector,
        @i_toperacion            = @i_toperacion,
        @i_oficina               = @i_oficina,
        @i_moneda                = @w_moneda,
        @i_comentario            = 'CARTERIZACION DE SOBREGIRO',
        @i_oficial               = @w_oficial,
        @i_fecha_ini             = @i_fecha_ini,
        @i_monto                 = @i_total_sobregiro,
        @i_monto_aprobado        = @i_total_sobregiro,
        @i_destino               = @w_destino,
        @i_lin_credito           = @i_lin_credito,
        @i_ciudad                = @w_ciudad,
        @i_forma_pago            = null,
        @i_cuenta                = null,
        @i_formato_fecha         = 101,
        @i_periodo_crecimiento   = 0,
        @i_tasa_crecimiento      = 0,
        @i_direccion             = @w_direccion,
        @i_clase_cartera         = @w_clase_cartera,
        @i_origen_fondos         = @w_origen_fondos,
        @i_fondos_propios        = 'S',
        @i_tipo_empresa          = 'B',
        @i_validacion            = null,
        @i_ref_exterior          = null,
        @i_sujeta_nego           = 'N',
        @i_ref_red               = null,
        @i_convierte_tasa        = null,
        @i_tasa_equivalente      = 'S',
        @i_fec_embarque          = null,
        @i_fec_dex               = null,
        @i_num_deuda_ext         = null,
        @i_num_comex             = null,
        @i_no_banco              = 'S',
        @i_batch_dd              = 'N',
        @i_tramite_hijo          = null,
        @i_reestructuracion      = 'N',
        @i_subtipo               = 'N',
        @i_numero_reest          = 0,
        @i_oper_pas_ext          = null,
        @i_salida                = 'N',
        @o_banco                 = @w_banco output
   
   if @w_error != 0
   begin
      select @w_error = @w_error
      goto ERROR
   end

   -- INICIO IFJ Defecto 200 RFP 609

   select @w_num_oficial = fu_funcionario
   from cobis..cl_funcionario
   where fu_login = @s_user
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount != 1 
   begin
      select @w_error = 701051
      goto ERROR
   end

   /*  Creacion de Registro en cl_det_producto  */
   select @w_dias          = datediff(dd, opt_fecha_ini, opt_fecha_fin),
          @w_oficina       = opt_oficina,      
          @w_direccion_det = opt_direccion
   from ca_operacion_tmp
   where opt_banco = @w_banco

   select @w_filial = of_filial
   from cobis..cl_oficina
   where of_oficina = @w_oficina
   set transaction isolation level read uncommitted

   exec cobis..sp_cseqnos
   @t_debug     = @t_debug,
   @t_file      = @t_file,
   @t_from      = @w_sp_name,
   @i_tabla     = 'cl_det_producto',
   @o_siguiente = @w_siguiente out

   delete cobis..cl_cliente
   from cobis..cl_det_producto
   where cl_det_producto = dp_det_producto
   and dp_producto       = 7
   and dp_cuenta         = @w_banco

   delete from cobis..cl_det_producto 
   where  dp_cuenta   = @w_banco
   and    dp_producto = 7


   insert into cobis..cl_det_producto (
   dp_det_producto, dp_oficina,       dp_producto,
   dp_tipo,         dp_moneda,        dp_fecha, 
   dp_comentario,   dp_monto,         dp_cuenta,
   dp_estado_ser,   dp_autorizante,   dp_oficial_cta, 
   dp_tiempo,       dp_valor_inicial, dp_tipo_producto,
   dp_tprestamo,    dp_valor_promedio,dp_rol_cliente,
   dp_filial,       dp_cliente_ec,    dp_direccion_ec)   
   values (
   @w_siguiente,    @w_oficina,        7, 
   'R',             0,                 @i_fecha_ini,
   'OP. CARTERA CL',@i_total_sobregiro,@w_banco, 
   'V',             @w_num_oficial,    @w_num_oficial,
   @w_dias,         0,                 '0',
   0,               0,                 'T',
   @w_filial,       @i_cliente,        @w_direccion)  

   if @@error != 0 
   begin
     PRINT 'cliente.sp  dp_cuenta' + @w_banco + 'dp det producto' + cast(@w_siguiente as varchar) + 'tipo R'   
     select @w_error  = 703027
     goto ERROR
   end

   /*  Creacion de Registros de Clientes  */
   
   insert into cob_credito..cr_deudores
      (de_tramite, de_cliente, de_rol, de_ced_ruc, de_segvida)
   values 
      (@w_tramite, @i_cliente, 'D', @w_identificacion, null)
   
   if @@error != 0 
   begin
      select @w_error = 703028
      goto ERROR
   end   
   
   insert into cobis..cl_cliente
      (cl_cliente,  cl_det_producto, cl_rol, cl_ced_ruc,  cl_fecha)
   values
      (@i_cliente, @w_siguiente, 'D', @w_identificacion, @i_fecha_ini)
  
   if @@error != 0 
   begin
      select @w_error = 703028
      goto ERROR
   end
   

   update cobis..cl_ente
   set en_cliente = 'S'
   where en_ente  = @i_cliente

   -- FIN IFJ Defecto 200 RFP 609   

   select @w_operacionca = opt_operacion
   from   ca_operacion_tmp
   where  opt_banco = @w_banco
   
   if @@rowcount = 0
   begin
      select @w_error = 703007
      goto ERROR
   end

   -- PASARLA A DEFINITIVAS
   exec @w_error = sp_pasodef
        @i_banco            = @w_banco,
        @i_operacionca      = 'S',   --@w_operacionca,
        @i_dividendo        = 'S',
        @i_amortizacion     = 'S',
        @i_cuota_adicional  = 'S',
        @i_rubro_op         = 'S',
        @i_relacion_ptmo    = 'S',
        @i_nomina           = 'S',
        @i_acciones         = 'S',
        @i_valores          = 'S'
   
   if @w_error != 0
   begin
      goto ERROR
   end

   -- ELIMINAR EL RUBRO DE SEGVIDA SI EL CLIENTE ES COMPANIA
   if (select en_subtipo from cobis..cl_ente where en_ente = @i_cliente) = 'C'
   begin
         print 'ENTRO A ELIMINAR'
         
         delete from   cob_cartera..ca_rubro_op
         where  ro_operacion = @w_operacionca
         and    ro_concepto = @w_rubro_segvida
   
         delete  from    cob_cartera..ca_amortizacion
         where   am_operacion = @w_operacionca
         and     am_concepto = @w_rubro_segvida


         delete from   cob_cartera..ca_rubro_op_tmp
         where  rot_operacion = @w_operacionca
         and    rot_concepto = @w_rubro_segvida
   
         delete  from    cob_cartera..ca_amortizacion_tmp
         where   amt_operacion = @w_operacionca
         and     amt_concepto = @w_rubro_segvida
   end
    
   -- INICIO IFJ Defecto 200 RFP 609
   select @w_descuentos = isnull(sum(am_cuota), 0)
   from   ca_rubro_op, ca_amortizacion
   where  am_operacion = @w_operacionca
   and    ro_operacion = @w_operacionca
   and    ro_fpago in ('A', 'L')
   and    am_concepto = ro_concepto
   and    am_dividendo = 1
   
   select @w_desembolsar = @i_total_sobregiro - @w_descuentos
   -- FIN IFJ Defecto 200 RFP 609
   
   -- CREAR REGISTRO DE DESEMBOLSO
   exec @w_error    = sp_desembolso
        @s_ofi            = @s_ofi,
        @s_term           = @s_term,
        @s_user           = @s_user,
        @s_date           = @s_date,
        @i_producto       = @w_concepto,  --LA MISMA FORMA DE PAGO ES LA DE DESEMBOLSO
        @i_cuenta         = 'AUTOMATICO',
        @i_beneficiario   = @w_nombre,
        @i_oficina_chg    = @s_ofi,
        @i_banco_ficticio = @w_banco,
        @i_banco_real     = @w_banco,
        @i_monto_ds       = @w_desembolsar,
        @i_tcotiz_ds      = 'N',
        @i_cotiz_ds       = 1,
        @i_tcotiz_op      = 'N',
        @i_cotiz_op       = 1,
        @i_moneda_op      = @w_moneda,
        @i_moneda_ds      = @w_moneda,
        @i_operacion      = 'I',
        @i_externo        = 'N',
        @i_concepto       = 'CARTERIZACION DE SOBREGIRO NO PAGA IMPUESTO DE TIMBRE'
   
   if @w_error != 0 
   begin
      goto ERROR  
   end
   
   -- CREAR REGISTRO DE TRAMITES
   insert into cob_credito..cr_tramite
         (tr_tramite,         tr_tipo,                tr_oficina,             tr_usuario,
          tr_fecha_crea,      tr_oficial,             tr_sector,              tr_ciudad,
          tr_estado,          tr_nivel_ap,            tr_fecha_apr,           tr_usuario_apr,
          tr_truta,           tr_secuencia,           tr_numero_op,           tr_numero_op_banco,
          tr_riesgo,          tr_aprob_por,           tr_nivel_por,           tr_comite,
          tr_acta,            tr_proposito,           tr_razon,               tr_txt_razon,
          tr_efecto,          tr_cliente,             tr_nombre,              tr_grupo,
          tr_fecha_inicio,    tr_num_dias,            tr_per_revision,        tr_condicion_especial,
          tr_linea_credito,   tr_toperacion,          tr_producto,            tr_monto,
          tr_moneda,          tr_periodo,             tr_num_periodos,        tr_destino,
          tr_ciudad_destino,  tr_cuenta_corriente,    tr_renovacion,          tr_fecha_concesion,
          tr_rent_actual,     tr_rent_solicitud,      tr_rent_recomend,       tr_prod_actual,
          tr_prod_solicitud,  tr_prod_recomend,       tr_clase,               tr_admisible,
          tr_noadmis,         tr_relacionado,         tr_pondera,             tr_contabilizado,
          tr_subtipo,         tr_tipo_producto,       tr_origen_bienes,       tr_localizacion,
          tr_plan_inversion,  tr_naturaleza,          tr_tipo_financia,       tr_sobrepasa,
          tr_elegible,        tr_forward,             tr_emp_emisora,         tr_num_acciones,
          tr_responsable,     tr_negocio,             tr_reestructuracion,    tr_concepto_credito,
          tr_aprob_gar,       tr_cont_admisible,      tr_mercado_objetivo,    tr_tipo_productor,
          tr_valor_proyecto,  tr_sindicado,           tr_asociativo,          tr_margen_redescuento,
          tr_fecha_ap_ant,    tr_llave_redes,         tr_incentivo,           tr_fecha_eleg,
          tr_op_redescuento,  tr_fecha_redes,         tr_solicitud,           tr_montop,
          tr_monto_desembolsop)
   select @w_tramite,         'O',                    op_oficina,             'migracion',
          op_fecha_ini,       @w_oficial,             op_sector,              op_ciudad,
          'A',                null,                   op_fecha_ini,           'Migracion',
          @w_ruta,            0,                      op_operacion,           op_banco,
          null,               'migracion',            null,                   null,
          null,               null,                   null,                   null,
          null,               op_cliente,             @w_nombre,              null,
          op_fecha_ini,       0,                      null,                   null,
          null,               op_toperacion,          'CCA',                  op_monto,
          op_moneda,          op_tplazo,              op_plazo,               op_destino,
          op_ciudad,          null,                   null,                   null,
          null,               null,                   null,                   null,
          null,               null,                   op_clase,               null,
          null,               null,                   null,                   'N',
          'O',                null,                   null,                   null,
          null,               null,                   null,                   'N',
          'N',                'N',                    null,                   null,
          null,               null,                   'N',                    'N',
          '3',                'N',                    @w_mercado_obj,         null,
          0,                  'N',                    ' ',                    0,
          op_fecha_ini,       op_codigo_externo,      'N',                    null,
          null,               op_fecha_ini,           null,                   @i_total_sobregiro,
          @i_total_sobregiro
   from   cob_cartera..ca_operacion
   where  op_operacion = @w_operacionca
   
   select @w_error = @@error, @w_count = @@rowcount
   
   if @w_error != 0 or @w_count = 0
   begin
      select @w_error = 710391
      goto ERROR
   end
   
   -- DATOS DE LA DIRECCION EN EL TRAMITE
   if @w_direccion is not null
   begin
      insert into cob_credito..cr_datos_tramites
            (dt_tramite, dt_toperacion,    dt_producto,
             dt_dato,    dt_valor)
      select @w_tramite, @i_toperacion,    'CCA',
             'DP',       @w_direccion_lar
   end
   
   -- RELACIONAR LA GARANTIA
   select @w_abierta_cerrada = cu_abierta_cerrada,
          @w_estado_gar      = cu_estado
   from   cob_custodia..cu_custodia
   where  cu_codigo_externo = @i_codigo_ext_gar
   and    cu_estado  in ('F','V')

   if @@rowcount = 0
   begin
      select @w_error = 701063
      goto ERROR
   end

   
   insert into cob_credito..cr_gar_propuesta
         (gp_tramite,               gp_garantia,         gp_clasificacion,
          gp_exceso,                gp_monto_exceso,     gp_abierta,
          gp_deudor,                gp_est_garantia,     gp_porcentaje,
          gp_valor_resp_garantia,   gp_fecha_mod,        gp_proceso)
   values(@w_tramite,               @i_codigo_ext_gar,   'a',
          null,                     0,                   @w_abierta_cerrada,
          @i_cliente,               @w_estado_gar,       null,
          null,                     @i_fecha_ini,    null)
   
   if @@error != 0
   begin
      select @w_error = 703019
      goto   ERROR
   end
   
   update ca_operacion
   set    op_divcap_original = @i_dias_vencido,
          op_calificacion    = @i_calificacion,
          op_estado          = 0
   where  op_operacion = @w_operacionca


   update ca_operacion_tmp
   set    opt_divcap_original = @i_dias_vencido,
          opt_calificacion    = @i_calificacion,
          opt_estado          = 0
   where  opt_operacion = @w_operacionca

   
   -- LLAMAR A LIQUIDA.SP
   exec @w_error = sp_liquida
        @s_ssn            = @s_sesn,
        @s_sesn           = @s_sesn,
        @s_user           = @s_user,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @s_rol            = 1,
        @s_term           = @s_term,
        @i_banco_ficticio = @w_banco,
        @i_banco_real     = @w_banco,
        @i_afecta_credito = 'N',
        @i_fecha_liq      = @i_fecha_ini,
        @i_tramite_batc   = 'N',
        @i_externo        = 'N',
		@i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
        @i_cca_sobregiro  = 'S'
   
   if @w_error <> 0
   begin
      goto ERROR
   end

   -- BORRAR LA TEMPORAL
   exec @w_error = sp_borrar_tmp
        @s_user      = @s_user,
        @s_term      = @s_term,
        @s_sesn      = @s_sesn,
        @i_desde_cre = 'N',
        @i_banco     = @w_banco
   
   if @w_error != 0
   begin
      goto ERROR
   end

   -- variable @i_operacion de retorno
   select @i_operacion = @w_operacionca
   select @i_operacion

   return 0
end      -- fin @i_procesa_batch = S

return 0

ERROR:

begin
   -- DESHACER TODA LA TRANSACCION
   while @@trancount > 0 ROLLBACK
   
   -- GRABAR EL ERROR EN CARTERA
   BEGIN TRAN
   exec sp_errorlog
        @i_fecha                = @s_date,
        @i_error                = @w_error,
        @i_usuario              = @s_user,
        @i_tran                 = 7000,
        @i_tran_name            = '',
        @i_rollback             = 'S',
        @i_cuenta               = @i_toperacion
  COMMIT
  while @@trancount < @w_tran_count BEGIN TRAN
  return @w_error
end

go
