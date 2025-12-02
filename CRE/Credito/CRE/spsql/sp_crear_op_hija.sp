/********************************************************************/
/*   NOMBRE LOGICO:         sp_crear_op_hija                        */
/*   NOMBRE FISICO:         sp_crear_op_hija.sp                     */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          W. Lopez                                */
/*   FECHA DE ESCRITURA:    13-Oct-2021                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Crea una operacion hija de una operacion grupal                */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA        AUTOR        RAZON                                */
/*  13-Oct-2021   W. Lopez     Emision Inicial-ORI-S544332-GFI      */
/*  12-Ene-2022   C. Obando    Se agrega dato para garantias grupo  */
/*  09-Mar-2022   D. Morales   Se comenta codigo temporalmente      */
/*  10-Mar-2022   D. Morales   Se forza actualizacion de monto      */
/*  16-Mar-2022   D. Morales   Se comenta update tg_monto de tramite*/
/*                             individual                           */
/*  12-Jul-2022   D. Morales   Se envia @i_fecha_ven_pc al crear op */
/*  24-Nov-2022   B. Duenas    S736964: Correccion pantalla         */
/*                             montos integrantes                   */
/*  24-Nov-2022   B. Duenas    S736969: cambios para renov/reest    */
/*                             grupal                               */
/*  27-Jun-2023   D. Morales   Se modica operaciones sobre la tabla */
/*                             cr_op_renovar                        */
/*  29-Jun-2023   P. Jarrin    S840149:Flujo Renovar o Refinanciar  */
/*  06-Jul-2023   D. Morales   Se en envia op_tipo padre en @i_tipo */
/*  18-Ago-2023   D. Morales   R213534:Se en envia @i_dia_pago para */
/*                             crear op hija                        */
/*  02-Oct-23     D. Morales   R216450: Se valida operacion padre   */
/*                             antes de crear renvacion hija        */
/*  23-Oct-2023   P. Jarrin.   Ajuste Tasa S923938-R214406          */
/********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name = 'sp_crear_op_hija' and type = 'P')
    drop procedure sp_crear_op_hija
go

create procedure sp_crear_op_hija
(
   @s_ssn                       int         = null,
   @s_user                      varchar(30) = null,
   @s_sesn                      int         = null,
   @s_term                      varchar(30) = null,
   @s_date                      datetime    = null,
   @s_srv                       varchar(30) = null,
   @s_lsrv                      varchar(30) = null,
   @s_rol                       smallint    = null,
   @s_ofi                       smallint    = null,
   @t_debug                     char(1)     = 'N',
   @t_file                      varchar(14) = null,
   @t_from                      varchar(30) = null,
   @i_tramite                   int,               --numero de tramite grupal
   @i_grupo                     int,               --numero de grupo
   @i_ente                      int,               --numero de ente de integrante
   @i_custipo_credito           catalogo    = null,--tipo credito
   @i_tasa                      float       = null,
   @o_banco                     cuenta      = null output

)
as
declare
   @w_return                    int,
   @w_error                     int,
   @w_sp_name                   varchar(30),
   @w_mjs                       varchar(255),
   @w_cliente                   int,
   @w_nombre                    descripcion,
   @w_sector                    catalogo,
   @w_toperacion                catalogo,
   @w_oficina                   smallint,
   @w_moneda                    tinyint,
   @w_comentario                varchar(255),
   @w_oficial                   smallint,
   @w_fecha_ini                 datetime,  
   @w_fecha_fin                 datetime,
   @w_fecha_ult_proceso         datetime,
   @w_fecha_liq                 datetime,
   @w_fecha_reajuste            datetime,
   @w_monto                     money,
   @w_monto_aprobado            money,
   @w_destino                   catalogo,
   @w_lin_credito               cuenta,
   @w_ciudad                    int,
   @w_estado                    tinyint,
   @w_periodo_reajuste          smallint,
   @w_reajuste_especial         char(1),
   @w_tipo                      char(1),
   @w_forma_pago                catalogo,
   @w_cuenta                    cuenta,
   @w_dias_anio                 smallint,
   @w_tipo_amortizacion         varchar(30),
   @w_cuota_completa            char(1),
   @w_tipo_cobro                char(1),
   @w_tipo_reduccion            char(1),
   @w_aceptar_anticipos         char(1),
   @w_precancelacion            char(1),
   @w_num_dec                   tinyint,
   @w_tplazo                    catalogo,
   @w_plazo                     smallint,
   @w_tdividendo                catalogo,
   @w_periodo_cap               smallint,
   @w_periodo_int               smallint,
   @w_tasa                      float,
   @w_gracia_cap                smallint,
   @w_gracia_int                smallint,
   @w_dist_gracia               char(1),
   @w_tipo_cambio               char(1),
   @w_fecha_fija                char(1),
   @w_dia_pago                  tinyint,
   @w_cuota_fija                char(1),
   @w_evitar_feriados           char(1),
   @w_tipo_producto             char(1),
   @w_renovacion                char(1),
   @w_mes_gracia                tinyint,
   @w_tipo_aplicacion           char(1),
   @w_reajustable               char(1),
   @w_est_novigente             tinyint,
   @w_est_credito               tinyint,
   @w_dias_dividendo            int,
   @w_dias_aplicar              int,
   @w_periodo_crecimiento       smallint,
   @w_tipo_empresa              catalogo ,
   @w_validacion                catalogo ,
   @w_fondos_propios            char(1),
   @w_fec_embarque              datetime,
   @w_fec_dex                   datetime,
   @w_ref_exterior              cuenta,
   @w_sujeta_nego               char(1),
   @w_ref_red                   varchar(24),
   @w_convierte_tasa            char(1),
   @w_tasa_equivalente          char(1),
   @w_tipo_linea                catalogo,
   @w_num_deuda_ext             cuenta ,
   @w_num_comex                 cuenta,
   @w_oper_pas_ext              varchar(64),
   @w_promocion                 char(1),
   @w_grupo                     int,
   @w_clte_hija                 int,
   @w_acepta_ren                char(1),
   @w_no_acepta                 char(1000),
   @w_emprendimiento            char(1),
   @w_banca                     catalogo,
   @w_tasa_crecimiento          float,
   @w_origen_fondos             catalogo,
   @w_operacion                 int,
   @w_banco                     cuenta,
   @w_banco_padre               cuenta,
   @w_numero_reest              int,
   @w_sal_min_cla_car           int,
   @w_sal_min_vig               money,
   @w_base_calculo              char(1),
   @w_ult_dia_habil             char(1),
   @w_recalcular                char(1),
   @w_prd_cobis                 tinyint,
   @w_tipo_redondeo             tinyint,
   @w_causacion                 char(1),
   @w_subtipo_linea             catalogo,
   @w_bvirtual                  char(1),
   @w_extracto                  char(1),
   @w_reestructuracion          char(1),
   @w_subtipo                   char(1),
   @w_naturaleza                char(1),
   @w_pago_caja                 char(1),
   @w_nace_vencida              char(1),
   @w_valor_rubro               money,
   @w_calcula_devolucion        char(1),
   @w_concepto_interes          catalogo,
   @w_est_cancelado             tinyint,
   @w_clase_cartera             catalogo,
   @w_dias_gracia               smallint,
   @w_tasa_referencial          catalogo,
   @w_porcentaje                float,
   @w_modalidad                 char(1),
   @w_periodicidad              char(1),
   @w_tasa_aplicar              catalogo,
   @w_entidad_convenio          catalogo,
   @w_mora_retroactiva          char(1),
   @w_prepago_desde_lavigente   char(1),
   @w_rowcount                  int,
   @w_control_dia_pago          char(1),
   @w_pa_dimive                 tinyint,
   @w_pa_dimave                 tinyint,
   @w_tr_tipo                   char(1),
   @w_monto_seguros             money,
   @w_default1                  varchar(50),
   @w_default2                  varchar(50),
   @w_secuencial                int,
   @w_intentos                  int,
   @w_cnt_intentos              int,
   @w_oper_hija                 int,
   @w_sesion                    int,
   @w_tramite                   int,
   @w_mensaje                   varchar(100),
   @w_val_ahorro_vol            int,
   @w_fecha_venc                datetime,
   @w_monto_odp                 money,
   @w_tretiro_odp               catalogo,
   @w_banco_odp                 catalogo,
   @w_lote_odp                  int,
   @w_odp_generada              varchar(20),
   @w_convenio                  varchar(10),
   @w_fecha_odp                 datetime,
   @w_secuencia_odp             int,
   @w_cuenta_aho_grupal         cuenta,
   @w_sec_hijas                 varchar(200),
   @w_bco_tec                   catalogo,
   @w_operacion_hija            int,
   @w_monto_op_hija             money,
   @w_tramite_hija              int,
   @w_monto_solic_hija          money,
   @w_grupo_contable            char(1),
   @w_cod_actividad             catalogo,
   @w_tipo_hija                 char(1),
   @w_op_tipo_padre             char(1),
   @w_op_anterior_padre         varchar(24),
   @w_capitaliza_padre          char(1),
   @w_banco_anterior_hija       varchar(24),
   @w_tipo_padre                char(1),
   @w_tipo_cre                  catalogo,
   @w_subtipo_cre               char

select @w_sp_name   = 'sp_crear_op_hija',
       @w_return    = 0,
       @w_error     = 0,
       @w_tasa      = null

--Creacion de operaciones hijas tomar datos del padre
select @w_operacion         = op_operacion,
       @w_banco_padre       = op_banco,
       @w_toperacion        = op_toperacion,
       @w_tramite           = op_tramite,
       @w_oficina           = op_oficina,
       @w_moneda            = op_moneda,
       @w_oficial           = op_oficial,
       @w_fecha_ini         = op_fecha_ini,
       @w_lin_credito       = op_lin_credito,
       @w_ciudad            = op_ciudad,
       @w_forma_pago        = op_forma_pago,
       @w_cuenta            = op_cuenta,
       @w_dia_pago          = op_dia_fijo,
       @w_origen_fondos     = op_origen_fondos,
       @w_tipo_empresa      = op_tipo_empresa,
       @w_validacion        = op_validacion,
       @w_fondos_propios    = op_fondos_propios,
       @w_ref_red           = op_nro_red,
       @w_convierte_tasa    = op_convierte_tasa,
       @w_tasa_equivalente  = op_usar_tequivalente,
       @w_fec_embarque      = op_fecha_embarque,
       @w_fec_dex           = op_fecha_dex,
       @w_num_deuda_ext     = op_num_deuda_ext,
       @w_num_comex         = op_num_comex,
       @w_reestructuracion  = op_reestructuracion,
       @w_tipo_cambio       = op_tipo_cambio, 
       @w_numero_reest      = op_numero_reest,
       @w_oper_pas_ext      = op_codigo_externo,
       @w_banca             = op_banca,
       @w_promocion         = op_promocion,
       @w_acepta_ren        = op_acepta_ren,
       @w_no_acepta         = op_no_acepta,
       @w_emprendimiento    = op_emprendimiento,
       @w_plazo             = op_plazo,
       @w_tplazo            = op_tplazo,
       @w_tdividendo        = op_tdividendo,
       @w_periodo_cap       = op_periodo_cap,
       @w_periodo_int       = op_periodo_int,
       @w_grupo             = op_grupo,
       @w_sector            = op_sector,  ---PQU se toma el sector del padre
       @w_op_anterior_padre = op_anterior,
	   @w_op_tipo_padre     = op_tipo
from   cob_cartera..ca_operacion
where  op_tramite = @i_tramite
              
select @w_dias_gracia = max(di_gracia_disp)
from   cob_cartera..ca_dividendo
where  di_operacion = @w_operacion
      
select @w_dias_gracia = isnull(@w_dias_gracia, 0)
          
if (@i_tasa is not null or @i_tasa > 0) 
begin      
	select @w_tasa = @i_tasa
end
else
begin
	select @w_tasa = ro_porcentaje
	  from cob_cartera..ca_rubro_op
	 where ro_operacion = @w_operacion
	   and ro_concepto = 'INT'
end
     
select @w_clte_hija = min(tg_cliente)
from   cob_credito..cr_tramite_grupal
where  tg_tramite         = @i_tramite
and    tg_participa_ciclo = 'S'
    
select @w_fecha_venc = di_fecha_ven
from   cob_cartera..ca_dividendo
where  di_operacion  = @w_operacion
and    di_dividendo  = 1

select @w_tipo_padre = tr_tipo 
from cob_credito..cr_tramite
where tr_tramite = @i_tramite
select @w_tipo_hija = 'O'

if(@w_tipo_padre != 'O')
begin

   select @w_banco_anterior_hija = op_banco
   from   cob_cartera..ca_operacion
   where  op_ref_grupal =  @w_op_anterior_padre
          and op_cliente    =  @i_ente 
          and op_estado     not in (99,3, 0, 6)
             
   if exists (select 1 from cob_cartera..ca_operacion
        inner join cob_credito..cr_op_renovar on op_ref_grupal = or_num_operacion
        where or_tramite =  @i_tramite
        and op_cliente = @i_ente
        and op_estado not in (99,3, 0, 6))
   begin
      select @w_tipo_hija = @w_tipo_padre
      select @w_capitaliza_padre  = or_capitaliza     
      from   cob_credito..cr_op_renovar
      where  or_tramite = @i_tramite
   end
   --fin PQU2   
end

--obtener datos de tramite grupal
select @w_cliente          = tg_cliente,
       @w_monto            = tg_monto,
       @w_nombre           = en_nomlar,
       @w_cod_actividad    = tg_sector,
       @w_destino          = tg_destino,
       @w_monto_solic_hija = tg_monto_aprobado
from   cob_credito..cr_tramite_grupal,
       cobis..cl_ente
where  tg_tramite         = @i_tramite
and    tg_participa_ciclo = 'S'
and    tg_cliente         = @i_ente
and    tg_cliente         = en_ente       
   
if @@rowcount = 0
begin
   --No existe cliente de tramite grupal
   select @w_return = 2110125
   goto SALIR
end

select @w_grupo_contable = pa_char from cobis..cl_parametro 
where pa_nemonico = 'GRCOGR' and pa_producto = 'CRE'

if(@w_dia_pago > 0)
begin
	select @w_fecha_fija   = 'S'
end
else
begin
	select @w_fecha_fija   = 'N',
	       @w_dia_pago     = 0
end


exec @w_return = cob_cartera..sp_crear_operacion
     @s_user              = @s_user,
     @s_sesn              = @s_sesn,
     @s_ssn               = @s_ssn,
     @s_ofi               = @s_ofi ,
     @s_date              = @s_date,
     @s_term              = @s_term,
     @i_cliente           = @w_cliente,
     @i_nombre            = @w_nombre,
     @i_sector            = @w_sector,
     @i_toperacion        = @w_toperacion,
     @i_oficina           = @w_oficina,
     @i_moneda            = @w_moneda,
     @i_comentario        = @w_comentario,
     @i_oficial           = @w_oficial,
     @i_fecha_ini         = @w_fecha_ini,
     @i_monto             = @w_monto,
     @i_monto_aprobado    = @w_monto,
     @i_destino           = @w_destino,
     @i_cod_actividad     = @w_cod_actividad,
     @i_lin_credito       = @w_lin_credito,
     @i_ciudad            = @w_ciudad,
     @i_forma_pago        = @w_forma_pago,
     @i_cuenta            = @w_cuenta,
     @i_formato_fecha     = 101,
     @i_dia_pago          = @w_dia_pago,
     @i_clase_cartera     = @w_sector,
     @i_origen_fondos     = @w_origen_fondos,
     @i_tipo_empresa      = @w_tipo_empresa,
     @i_validacion        = @w_validacion,
     @i_fondos_propios    = @w_fondos_propios,
     @i_ref_red           = @w_ref_red,
     @i_convierte_tasa    = @w_convierte_tasa,
     @i_tasa_equivalente  = @w_tasa_equivalente,
     @i_fec_embarque      = @w_fec_embarque,
     @i_fec_dex           = @w_fec_dex,
     @i_num_deuda_ext     = @w_num_deuda_ext,
     @i_num_comex         = @w_num_comex,
     @i_reestructuracion  = @w_reestructuracion,
     @i_tipo_cambio       = @w_tipo_cambio,
     @i_numero_reest      = @w_numero_reest,
     @i_oper_pas_ext      = @w_oper_pas_ext,
     @i_en_linea          = 'N',
     @i_banca             = @w_banca,
     @i_promocion         = @w_promocion,
     @i_acepta_ren        = @w_acepta_ren,
     @i_no_acepta         = @w_no_acepta,
     @i_emprendimiento    = @w_emprendimiento,
     @i_plazo             = @w_plazo,
     @i_tplazo            = @w_tplazo,
     @i_tdividendo        = @w_tdividendo,
     @i_periodo_cap       = @w_periodo_cap,
     @i_periodo_int       = @w_periodo_int,
     @i_ref_grupal        = @w_banco_padre,
     @i_grupo             = @w_grupo,
     @i_fecha_ven_pc      = @w_fecha_venc, 
     @i_es_grupal         = 'N',
     @i_grupal            = 'S',
     @i_no_banco          = 'S',
     @i_tasa              = @w_tasa,
     @i_tipo              = @w_op_tipo_padre,
     @i_grupo_contable    = @w_grupo_contable,
     @i_anterior          = @w_banco_anterior_hija,
	 @i_fecha_fija        = @w_fecha_fija,
     @o_banco             = @w_banco out

if @w_return != 0
begin
   --Error creando Operacion Hija
   goto SALIR
end

--Pasar a Definitivas
exec @w_return = cob_cartera..sp_operacion_def
     @i_banco = @w_banco,
     @s_date  = @s_date,
     @s_sesn  = @s_sesn,
     @s_user  = @s_user,
     @s_ofi   = @s_ofi

if @w_return != 0
begin
   --Error Pasando Operacion Hija a Definitivas
   select @w_return = 725036
   goto SALIR
end
   
select @w_operacion_hija = op_operacion,
       @w_monto_op_hija  = op_monto,
       @w_tramite_hija   = op_tramite
from   cob_cartera..ca_operacion
where  op_banco = @w_banco
   
update cob_credito..cr_tramite_grupal
set    tg_operacion = @w_operacion_hija,
       tg_prestamo  = @w_banco
       --tg_monto     = @w_monto_op_hija
where  tg_cliente   = @w_cliente 
and    tg_tramite   = @i_tramite

select @w_error = @@error
if @w_error != 0
begin
   select @w_mjs    = 'Error al actualizar operacion hija en tramite grupal',
          @w_return = @w_error
   goto SALIR
end

update cob_credito..cr_tramite
set    tr_monto_solicitado  = @w_monto_solic_hija,
       tr_monto             = @w_monto_op_hija
where  tr_tramite           = @w_tramite_hija

select @w_error = @@error
if @w_error != 0
begin
   select @w_mjs    = 'Error al actualizar tramite hijo',
          @w_return = @w_error
   goto SALIR
end

if (@i_custipo_credito is not null)
begin
    if @i_custipo_credito = 'R' 
    begin
        select @w_tipo_cre = 'R'
        select @w_subtipo_cre = 'R'
    end
    else if @i_custipo_credito = 'F'
    begin
        select @w_tipo_cre = 'R'
        select @w_subtipo_cre = 'N'
    end       
    else
    begin
        select @w_tipo_cre = @i_custipo_credito
        select @w_subtipo_cre = ''
    end
               
    update cob_credito..cr_tramite
       set tr_tipo     = @w_tipo_cre,
           tr_subtipo  = @w_subtipo_cre
     where tr_tramite  = @w_tramite_hija

    select @w_error = @@error
    if @w_error != 0
    begin
       select @w_mjs    = 'Error al actualizar tramite hijo',
              @w_return = @w_error
       goto SALIR
    end     
end

--PQU2
if @w_tipo_hija != 'O' and @i_tramite != @w_tramite_hija
begin
   --Insertar en la cr_op_renovar para la hija
   insert into cob_credito..cr_op_renovar 
   (or_tramite,     or_num_operacion,   or_producto,    or_capitaliza,          or_login,   or_fecha_ingreso)
   select 
   @w_tramite_hija, op_banco,           'CCA',          @w_capitaliza_padre,    @s_user,    @s_date
   from cob_cartera..ca_operacion
   inner join cob_credito..cr_op_renovar  on op_ref_grupal = or_num_operacion
   where or_tramite =  @i_tramite
   and op_cliente   = @i_ente
   and op_estado not in (99,3, 0, 6)
   
   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mjs    = 'Error al actualizar operacion hija en tramite grupal',
             @w_return = @w_error
      goto SALIR
   end 
   
end
--fin PQU2   


exec @w_return = cob_cartera..sp_borrar_tmp
     @i_banco  = @w_banco,
     @s_sesn   = @s_sesn,
     @s_user   = @s_user,
     @s_term   = @s_ofi

if @w_return != 0 
begin
   select @w_return = 725037
   goto SALIR
end

select @o_banco = @w_banco

SALIR:
return @w_return

ERROR:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_return
   return @w_return
go
