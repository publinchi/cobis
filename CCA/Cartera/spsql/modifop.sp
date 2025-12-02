/************************************************************************/
/*   NOMBRE LOGICO:      modifop.sp                                     */
/*   NOMBRE FISICO:      sp_modificar_operacion                         */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Fabian de la Torre, Rodrigo Garces             */
/*   FECHA DE ESCRITURA: Ene. 1998                                      */
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
/*                              PROPOSITO                               */
/*      Modifica una operacion de Cartera con sus rubros asociados y su */
/*      tabla de amortizacion                                           */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      LRE  05/Ene/2017                Incluir concepto de Agrupamiento*/
/*                                      de Operaciones                  */
/*     15/04/2019       A. Giler        Operaciones Grupales            */
/*     01/07/2019       A. Giler        Ajustes Originador              */
/* 06/Ene/2021   P.Narvaez  Tipo de Reestructuracion/Tipo Renovacion    */
/*     06/Ene/2022   G. Fernandez       Ingreso de nuevo parametro de   */
/*                                      grupo contable                  */
/*     08/Mar/2022  Kevin Rodríguez    Validacion dia pago y fecha fija */
/*                                     de dividendos especiales         */
/*     22/03/2022   Kevin Rodríguez    Cambio Val defecto de param grupo*/
/*     18/10/2023   Kevin Rodiguez     R217473 Recalculo valor rubros Q */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_modificar_operacion')
    drop proc sp_modificar_operacion
go
create proc sp_modificar_operacion
   @s_user                       login         = null,
   @s_sesn                       int           = null,
   @s_date                       datetime      = null,
   @s_term                       varchar(30)   = null,
   @s_ofi                        smallint      = null,
   @i_calcular_tabla             char(1)       = 'N',
   @i_tabla_nueva                char(1)       = 'S',
   @i_operacionca                int           = null,
   @i_banco                      cuenta        = null,
   @i_anterior                   cuenta        = null,
   @i_migrada                    cuenta        = null,
   @i_tramite                    int           = null,
   @i_cliente                    int           = null,
   @i_nombre                     descripcion   = null,
   @i_sector                     catalogo      = null,
   @i_toperacion                 catalogo      = null,
   @i_oficina                    smallint      = null,
   @i_moneda                     tinyint       = null,
   @i_comentario                 varchar(255)  = null,
   @i_oficial                    smallint      = null,
   @i_fecha_ini                  datetime      = null,
   @i_fecha_fin                  datetime      = null,
   @i_fecha_ult_proceso          datetime      = null,
   @i_fecha_pri_cuot             datetime      = null,
   @i_fecha_liq                  datetime      = null,
   @i_fecha_reajuste             datetime      = null,
   @i_monto                      money         = null,
   @i_monto_aprobado             money         = null,
   @i_destino                    catalogo      = null,
   @i_lin_credito                cuenta        = null,
   @i_ciudad                     int           = null,
   @i_estado                     tinyint       = null,
   @i_periodo_reajuste           smallint      = null,
   @i_reajuste_especial          char(1)       = null,
   @i_tipo                       char(1)       = null,
   @i_forma_pago                 catalogo      = null,
   @i_cuenta                     cuenta        = null,
   @i_dias_anio                  smallint      = null,
   @i_tipo_amortizacion          varchar(10)   = null,
   @i_cuota_completa             char(1)       = null,
   @i_tipo_cobro                 char(1)       = null,
   @i_tipo_reduccion             char(1)       = null,
   @i_aceptar_anticipos          char(1)       = null,
   @i_precancelacion             char(1)       = null,
   @i_tipo_aplicacion            char(1)       = null,
   @i_tplazo                     catalogo      = null,
   @i_plazo                      int           = null,
   @i_tdividendo                 catalogo      = null,
   @i_periodo_cap                int           = null,
   @i_periodo_int                int           = null,
   @i_dist_gracia                char(1)       = null,
   @i_gracia_cap                 int           = null,
   @i_gracia_int                 int           = null,
   @i_dia_fijo                   int           = null,
   @i_cuota                      money         = null,
   @i_evitar_feriados            char(1)       = null,
   @i_num_renovacion             int           = null,
   @i_renovacion                 char(1)       = null,
   @i_mes_gracia                 tinyint       = null,
   @i_formato_fecha              int           = 101,
   @i_upd_clientes               char(1)       = null,
   @i_dias_gracia                smallint      = null,
   @i_reajustable                char(1)       = null,
   @i_dias_clausula              int           = null,
   @i_periodo_crecimiento        smallint      = null,
   @i_tasa_crecimiento           float         = null,
   @i_control_tasa               char(1)       = 'S',
   @i_direccion                  tinyint       = null,
   @i_opcion_cap                 char(1)       = null,
   @i_tasa_cap                   float         = null,
   @i_dividendo_cap              smallint      = null,
   @i_tipo_cap                   char(1)       = null,
   @i_clase_cartera              catalogo      = null,
   @i_tipo_crecimiento           char(1)       = null,
   @i_num_reest                  int           = null,
   @i_base_calculo               char(1)       = null,
   @i_ult_dia_habil              char(1)       = null,
   @i_recalcular                 char(1)       = null,
-- @i_tasa_equivalente           char(1)       = null,
   @i_origen_fondos              catalogo      = null,
   @i_fondos_propios             char(1)       = 'N' ,
   @i_ref_exterior               cuenta        = null,
   @i_sujeta_nego                char(1)       = null,
   @i_num_operacion_cex          cuenta        = null,
   @i_ref_red                    varchar(24)   = null,
   @i_tipo_redondeo              tinyint       = null,
   @i_tipo_empresa               catalogo      = null,
   @i_validacion                 catalogo      = null,
   @i_causacion                  char(1)       = null,
   @i_tramite_ficticio           int           = null,
   @i_grupo_fact                 int           = null,
   @i_convierte_tasa             char(1)       = null,
   @i_usar_tequivalente          char(1)       = null,
   @i_bvirtual                   char(1)       = null,
   @i_extracto                   char(1)       = null,
   @i_fec_embarque               datetime      = null,
   @i_fec_dex                    datetime      = null,
   @i_num_deuda_ext              cuenta        = null,
   @i_num_comex                  cuenta        = null,
   @i_pago_caja                  char(1)       = null,
   @i_nace_vencida               char(1)       = null,
   @i_calcula_devolucion         char(1)       = null,
   @i_oper_pas_ext               varchar(64)   = null,
   @i_reestructuracion           char(1)       = null,
   @i_mora_retroactiva           char(1)       = null,
   @i_prepago_desde_lavigente    char(1)       = null,
   @i_valida_param               char(1)       = null,
   @i_tasa             		      float		     = null,
   @i_grupal                     char(1)       = null,      --LRE 06/ENE/2017
   @i_dia_pago                   int           = null,      --LRE 08/ABR/2019
   @i_fecha_fija                 char(1)       = 'S',       --LRE 08/ABR/2019
   @i_regenera_rubro             char(1)       = 'S',       --AGI 28/MAY/2019
   @i_grupo                      int           = null,      --AGI TeCreemos     -- KDR Se respeta el parámetro enviado
   @i_ref_grupal                 cuenta        = null,      --AGI TeCreemos
   @i_es_grupal                  char(1)       = 'N',       --AGI TeCreemos
   @i_fondeador                  tinyint       = null,       --AGI TeCreemos
   @i_fecha_dispersion           datetime      = null,
   @i_cliente_1                  varchar(200)  = null,  
   @i_cliente_2                  varchar(200)  = null,  
   @i_cliente_3                  varchar(200)  = null,  
   @i_cliente_4                  varchar(200)  = null,  
   @i_cliente_5                  varchar(200)  = null,      
   @i_monto_1                    varchar(200)  = null,     
   @i_monto_2                    varchar(200)  = null,  
   @i_monto_3                    varchar(200)  = null,  
   @i_monto_4                    varchar(200)  = null,  
   @i_monto_5                    varchar(200)  = null,
   @i_monto_6                    varchar(200)  = null,
   @i_tipo_renovacion            char(1)       = null,
   @i_tipo_reest                 char(1)       = null,
   @i_grupo_contable             catalogo      = null, --GFP 06/Ene/2022
   @i_recalc_rubs_enl            char(1)       = 'S'   --KDR Recalcular Rubros Q (versión Enlace)

   
as

declare
   @w_sp_name          descripcion,
   @w_return           int,
   @w_error            int,
   @w_toperacion       catalogo, -- LGU para controlar interciclos
   @w_sector_cli       catalogo,
   @w_sector_ger       catalogo,
   @w_concepto_interes catalogo,
   @w_tasa_aplicar     catalogo,
   @w_porcentaje       float,
   @w_tasa_referencial catalogo,
   @w_modalidad        char(1),
   @w_periodicidad     char(1),
   @w_operacionca      int,
   @w_sector           char(1),
   @w_tdividendo       char(1),
   @w_fpago            char(1),
   @w_opt_direccion    tinyint,
   @w_tasa_equivalente char(1),
   @w_est_novigente    smallint,
   @w_ref_grupal       cuenta,
   @w_grupo            int,
   @w_estado_op        int,
   @w_contador         int,
   @w_pos              int,
   @w_secuencia        int,
   @w_cadena           varchar(200),
   @w_valor            varchar(15),
   @w_monto_hijas      money,
   @w_monto            money,
   @w_recalculo_rubs   char(1)
   

select @w_tasa_equivalente = null

if @i_fecha_pri_cuot is null
   select @i_fecha_pri_cuot = @i_fecha_ini

-- CODIGO DEL RUBRO INT
select @w_concepto_interes = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

-- CARGAR VALORES INICIALES
select @w_sp_name = 'sp_modificar_operacion'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out

--OBTENCION DE LA PRIMERA DIRECCION DEL CLIENTE
set rowcount 1

if @i_direccion is null
   select @w_opt_direccion = opt_direccion
   from ca_operacion_tmp
   where opt_banco = @i_banco

if @w_opt_direccion is not null
   select @i_direccion = @w_opt_direccion
else begin
   select @i_direccion = di_direccion
   from cobis..cl_direccion
   where di_ente   = @i_cliente
   and di_vigencia = 'S'
   order by di_direccion
   set transaction isolation level read uncommitted
end

set rowcount 0

-- CONTROL DE LA TASA IBC ANTES DE CREAR LA OP
If ((@i_operacionca is not null) and (@i_banco is null))
begin
    select @i_banco = op_banco
    from ca_operacion
    where op_operacion = @i_operacionca
end

select
@w_operacionca      = opt_operacion,
@w_sector           = opt_sector,
@w_tdividendo       = opt_tdividendo,
@w_estado_op        = opt_estado,
@w_toperacion       = opt_toperacion, -- LGU para controlar interciclos
@w_grupo            = opt_grupo,
@w_monto            = opt_monto
from ca_operacion_tmp
where opt_banco      = @i_banco


select @i_operacionca = @w_operacionca 

--LGU-INI: 2017-06-30  levanta control
/**********************
if exists (select 1 from ca_desembolso
           where dm_operacion = @w_operacionca
           and dm_estado      in ('I','NA')) and
   -- LGU para que no valide en el caso de interciclo
   NOT exists(select 1 from cobis..cl_tabla t, cobis..cl_catalogo c where t.tabla = 'ca_interciclo' and t.codigo = c.tabla and c.codigo = @w_toperacion)
begin
   select @w_error = 710473
   goto ERROR
end
********************/

-- KDR 03/03/2021 Si los tipos de dividendos son especiales, no debe tener valores de control día pago(N), fecha fija (N) y dia de pago(0).
if @i_tdividendo in ('W','28D','35D','Q','14D')
begin
   if @i_fecha_fija = 'S' or @i_dia_pago > 0
   begin
      select @w_error = 725141  -- Tipo dividendo no admite fecha fija, día pago fijo, ni control dia de pago, revisar parametrización o condiciones de amortización
      goto ERROR
   end
end

-- Solo valida matrices para operaciones en estado por desembolsar -- Cuando este sp es llamado desde FrontEnd
if @w_estado_op != @w_est_novigente
   select @i_valida_param = 'N'

select
@w_tasa_aplicar     = rot_referencial,
@w_porcentaje       = rot_porcentaje,
@w_fpago            = rot_fpago
from ca_rubro_op_tmp
where rot_operacion = @w_operacionca
and   rot_concepto  = @w_concepto_interes

select @w_tasa_referencial = vd_referencia
from ca_valor_det
where vd_tipo   =  @w_tasa_aplicar
and   vd_sector =  @w_sector

select
@w_modalidad         = tv_modalidad,
@w_periodicidad      = tv_periodicidad
from ca_tasa_valor
where tv_nombre_tasa = @w_tasa_referencial
and tv_estado        = 'V'

if @w_tasa_referencial = 'TCERO' begin
   if @w_fpago = 'P'
      select @w_modalidad = 'V'

   if @w_fpago = 'A'
      select @w_modalidad = 'A'

   select  @w_periodicidad = @w_tdividendo
end

exec @w_return    = sp_rubro_control_ibc
@i_operacionca    = @w_operacionca,
@i_concepto       = @w_concepto_interes,
@i_porcentaje     = @w_porcentaje,
@i_periodo_o      = @w_periodicidad,
@i_modalidad_o    = @w_modalidad,
@i_num_periodo_o  = 1

if @w_return != 0 begin
   print 'modifop...Mensaje Informativo Tasa Total de Interes supera el maximo permitido..'
   print '@w_return' + cast(@w_return as varchar(20))
   --select @w_error = 710094
   --goto   ERROR
end

--INI AGI 16abr19  Si es grupal validar consistencia de datos.

if @i_es_grupal = 'S'
begin
    --Creando temporal
    create table ##grupales   
    (
      secuencia numeric identity,
      cliente   int null,
      valor     money null
    )
       
    --Descomponer Cadena Clientes
    select @w_contador = 1
    while @w_contador <= 5
    begin
        if @w_contador = 1 
          select @w_cadena = @i_cliente_1
        
        if @w_contador = 2
            select @w_cadena = @i_cliente_2
            
        if @w_contador = 3 
            select @w_cadena = @i_cliente_3
                
        if @w_contador = 4
            select @w_cadena = @i_cliente_4
                        
        if @w_contador = 5 
            select @w_cadena = @i_cliente_5
                            
        while @w_cadena > ''
        begin         
            select @w_pos = charindex('|', @w_cadena)
            if @w_pos = 0
                select @w_valor = ltrim(rtrim(@w_cadena))
            else    
                select @w_valor = ltrim(rtrim(substring(@w_cadena, 1, @w_pos -1)))
            
            
            if ltrim(rtrim(@w_cadena)) = ltrim(rtrim(@w_valor))
                select @w_cadena = '|'
            else
               select @w_cadena = substring(@w_cadena, @w_pos+1,len(@w_cadena))
            
            if @w_valor > '' and isnumeric(@w_valor) = 1
            begin
                insert ##grupales values (convert(int,@w_valor), 0)
            end
                   
            if ltrim(rtrim(@w_cadena)) = '|'
                select @w_cadena = ''            
        end
        
        select @w_contador = @w_contador + 1
    end

    --Descomponer Cadena de Valores
    select @w_contador  = 1,
           @w_secuencia = 1
    while @w_contador <= 6
    begin
        if @w_contador = 1 
          select @w_cadena = @i_monto_1
        
        if @w_contador = 2
            select @w_cadena = @i_monto_2
                
        if @w_contador = 3 
            select @w_cadena = @i_monto_3

        if @w_contador = 4
            select @w_cadena = @i_monto_4
            
        if @w_contador = 5 
            select @w_cadena = @i_monto_5
            
        if @w_contador = 6
            select @w_cadena = @i_monto_6
        
        while @w_cadena > ''
        begin      
            select @w_pos = charindex('|', @w_cadena)
            if @w_pos = 0
                select @w_valor = ltrim(rtrim(@w_cadena))
            else    
                select @w_valor = ltrim(rtrim(substring(@w_cadena, 1, @w_pos -1)))
            
            
            if ltrim(rtrim(@w_cadena)) = ltrim(rtrim(@w_valor))
                select @w_cadena = '|'
            else
               select @w_cadena = substring(@w_cadena, @w_pos+1,len(@w_cadena))
            
            if @w_valor > '' and isnumeric(@w_valor) = 1
            begin
                update ##grupales 
                set valor = convert(money, @w_valor)
                where secuencia = @w_secuencia
            end
                   
            if ltrim(rtrim(@w_cadena)) = '|'
                select @w_cadena = ''            
                
            select @w_secuencia = @w_secuencia + 1
        end
        select @w_contador = @w_contador + 1
    end
    
    --Monto de los individuales no supere el valor del padre
    select @w_monto_hijas = sum(valor) 
    from ##grupales 

    if @w_monto_hijas <> @w_monto
    begin     
         print 'ERROR: SUMA DE MONTOS DE OPERACIONES INDIVIDUALES ES DIFERENTE AL MONTO DE LA OPERACION PADRE'
         return 70204
    end

    --Clientes individuales pertenezca al grupo indicado
    if exists(select 1 from ##grupales
              where cliente not in (select cg_ente from cobis..cl_cliente_grupo
                                     where cg_grupo = @w_grupo))
    begin     
        print 'ERROR: EXISTEN CLIENTES DE OPERACIONES HIJAS QUE NO PERTENECEN AL GRUPO '
        return 70205
    end

    --Clientes individuales pertenezca al grupo indicado
    if exists(select 1 from ##grupales
              where cliente not in (select cg_ente from cobis..cl_cliente_grupo
                                     where cg_grupo = @w_grupo
                                       and cg_estado = 'V'))
    begin     
        print 'ERROR: EXISTEN CLIENTES DE OPERACIONES HIJAS QUE ESTAN INACTIVAS EN EL GRUPO'
        return 70205
    end


    --Que todos los clientes tengas valores en prestamo
   if exists(select 1 from ##grupales
              where valor is null or valor = 0)
    begin     
        print 'ERROR: EXISTEN CLIENTES QUE NO HAN ASIGNADO VALOR A LA OPERACION'
        return 70205
    end
    
    drop table ##grupales  
end
--FIN AGI

begin tran

   -- Proceso de recalculo de valor rubros calculados(versión Enlace) Parte 1: Respaldo e eliminación	
   if @i_recalc_rubs_enl = 'S'
   begin   
      exec @w_return = sp_recalcula_rubros_enl
      @s_user              = @s_user,
      @s_date              = @s_date,
      @s_term              = @s_term,
      @s_ofi               = @s_ofi,
      @i_operacion         = 'D',
      @i_banco             = @i_banco,
      @i_tdividendo        = @i_tdividendo,
	  @i_periodo_int       = @i_periodo_int,
      @i_recalc_rubs_enl   = @i_recalc_rubs_enl,
      @o_recalculo_rubs    = @w_recalculo_rubs out -- Bandera para volver a ingresar los rubros eliminados
      
      if @w_return != 0 begin
         select @w_error = @w_return
         goto ERROR
      end
   end

   exec @w_return = sp_modificar_operacion_int                                                                                                                         
   @s_user                      = @s_user,
   @s_sesn                      = @s_sesn,
   @s_date                      = @s_date,
   @s_term                      = @s_term,
   @s_ofi                       = @s_ofi,
   @i_calcular_tabla            = @i_calcular_tabla,
   @i_tabla_nueva               = @i_tabla_nueva,
   @i_operacionca               = @i_operacionca,
   @i_banco                     = @i_banco,
   @i_anterior                  = @i_anterior,
   @i_migrada                   = @i_migrada,
   @i_tramite                   = @i_tramite,
   @i_cliente                   = @i_cliente,
   @i_nombre                    = @i_nombre,
   @i_sector                    = @i_sector,
   @i_toperacion                = @i_toperacion,
   @i_oficina                   = @i_oficina,
   @i_moneda                    = @i_moneda,
   @i_comentario                = @i_comentario,
   @i_oficial                   = @i_oficial,
   @i_fecha_ini                 = @i_fecha_ini,
   @i_fecha_fin                 = @i_fecha_fin,
   @i_fecha_ult_proceso         = @i_fecha_ini,  ----@i_fecha_ult_proceso,
   @i_fecha_liq                 = @i_fecha_liq,
   @i_fecha_reajuste            = @i_fecha_reajuste,
   @i_monto                     = @i_monto,
   @i_monto_aprobado            = @i_monto_aprobado,
   @i_destino                   = @i_destino,
   @i_lin_credito               = @i_lin_credito,
   @i_ciudad                    = @i_ciudad,
   @i_estado                    = @i_estado,
   @i_periodo_reajuste          = @i_periodo_reajuste,
   @i_reajuste_especial         = @i_reajuste_especial,
   @i_tipo                      = @i_tipo,
   @i_forma_pago                = @i_forma_pago,
   @i_cuenta                    = @i_cuenta,
   @i_dias_anio                 = @i_dias_anio,
   @i_tipo_amortizacion         = @i_tipo_amortizacion,
   @i_cuota_completa            = @i_cuota_completa,
   @i_tipo_cobro                = @i_tipo_cobro,
   @i_tipo_reduccion            = @i_tipo_reduccion,
   @i_aceptar_anticipos         = @i_aceptar_anticipos,
   @i_precancelacion            = @i_precancelacion,
   @i_tipo_aplicacion           = @i_tipo_aplicacion,
   @i_tplazo                    = @i_tplazo,
   @i_plazo                     = @i_plazo,
   @i_tdividendo                = @i_tdividendo,
   @i_periodo_cap               = @i_periodo_cap,
   @i_periodo_int               = @i_periodo_int,
   @i_dist_gracia               = @i_dist_gracia,
   @i_gracia_cap                = @i_gracia_cap,
   @i_gracia_int                = @i_gracia_int,
   @i_dia_fijo                  = @i_dia_fijo,
   @i_fecha_pri_cuot            = @i_fecha_pri_cuot,
   @i_cuota                     = @i_cuota,
   @i_evitar_feriados           = @i_evitar_feriados,
   @i_num_renovacion            = @i_num_renovacion,
   @i_renovacion                = @i_renovacion,
   @i_mes_gracia                = @i_mes_gracia,
   @i_formato_fecha             = @i_formato_fecha,
   @i_upd_clientes              = @i_upd_clientes,
   @i_dias_gracia               = @i_dias_gracia,
   @i_reajustable               = @i_reajustable,
   @i_dias_clausula             = @i_dias_clausula,
   @i_periodo_crecimiento       = @i_periodo_crecimiento,
   @i_tasa_crecimiento          = @i_tasa_crecimiento,
   @i_control_tasa              = @i_control_tasa,
   @i_direccion                 = @i_direccion,
   @i_opcion_cap                = @i_opcion_cap,
   @i_tasa_cap                  = @i_tasa_cap,
   @i_dividendo_cap             = @i_dividendo_cap,
   @i_tipo_cap                  = @i_tipo_cap,
   @i_tipo_crecimiento          = @i_tipo_crecimiento,
   @i_num_reest                 = @i_num_reest,
   @i_base_calculo              = @i_base_calculo,
   @i_ult_dia_habil             = @i_ult_dia_habil,
   @i_recalcular                = @i_recalcular,
   @i_tasa_equivalente          = @w_tasa_equivalente,   --@i_tasa_equivalente,
   @i_clase_cartera             = @i_clase_cartera,
   @i_tipo_empresa              = @i_tipo_empresa,
   @i_validacion                = @i_validacion,
   @i_origen_fondos             = @i_origen_fondos,
   @i_fondos_propios            = @i_fondos_propios,
   @i_ref_exterior              = @i_ref_exterior,
   @i_sujeta_nego               = @i_sujeta_nego,
   @i_ref_red                   = @i_ref_red,
   @i_tipo_redondeo             = @i_tipo_redondeo,
   @i_causacion                 = @i_causacion,
   @i_tramite_ficticio          = @i_tramite_ficticio,
   @i_grupo_fact                = @i_grupo_fact,
   @i_convierte_tasa            = @i_convierte_tasa,
-- @i_tasa_equivalente          = @i_tasa_equivalente,
   @i_bvirtual                  = @i_bvirtual,
   @i_extracto                  = @i_extracto,
   @i_fec_embarque              = @i_fec_embarque,
   @i_fec_dex                   = @i_fec_dex,
   @i_num_deuda_ext             = @i_num_deuda_ext,
   @i_num_comex                 = @i_num_comex,
   @i_pago_caja                 = @i_pago_caja,
   @i_nace_vencida              = @i_nace_vencida,
   @i_calcula_devolucion        = @i_calcula_devolucion,
   @i_oper_pas_ext              = @i_oper_pas_ext,
   @i_reestructuracion          = @i_reestructuracion,
   @i_mora_retroactiva          = @i_mora_retroactiva,
   @i_prepago_desde_lavigente   = @i_prepago_desde_lavigente,
   @i_valida_param              = @i_valida_param,
   @i_tasa                      = @i_tasa,
   @i_grupal                    = @i_grupal,                 --LRE 06/ENE/2017
   @i_dia_pago                  = @i_dia_pago,               --LRE 08/ABR/2019
   @i_fecha_fija                = @i_fecha_fija,             --LRE 08/ABR/2018
   @i_regenera_rubro            = @i_regenera_rubro,         --AGI 28/MAY/2019
   @i_grupo                     = @i_grupo,                  --AGI TeCreemos
   @i_ref_grupal                = @i_ref_grupal,             --AGI TeCreemos
   @i_es_grupal                 = @i_es_grupal,              --AGI TeCreemos
   @i_fondeador                 = @i_fondeador,           --AGI TeCreemos
   @i_fecha_dispersion          = @i_fecha_dispersion,        --AGI. 
   @i_tipo_renovacion           = @i_tipo_renovacion,
   @i_tipo_reest                = @i_tipo_reest,
   @i_grupo_contable            = @i_grupo_contable           --GFP 06/Ene/2022
   
   if @w_return != 0 begin
      select @w_error = @w_return
      goto   ERROR
   end
   
   -- Proceso de recalculo de valor rubros calculados(versión Enlace) Parte 2: Registro
   if @i_recalc_rubs_enl = 'S' and @w_recalculo_rubs = 'S'
   begin
      
      exec @w_return = sp_recalcula_rubros_enl
      @s_user              = @s_user,
      @s_date              = @s_date,
      @s_term              = @s_term,
      @s_ofi               = @s_ofi,
      @i_operacion         = 'I',
      @i_banco             = @i_banco,
      @i_tdividendo        = @i_tdividendo,
	  @i_periodo_int       = @i_periodo_int,
      @i_recalc_rubs_enl   = @i_recalc_rubs_enl
      
      if @w_return != 0 begin
         select @w_error = @w_return
         goto ERROR
      end
	  
   end

  if not exists(select 1
                from ca_operacion_tmp
                where opt_banco = @i_banco)
   begin
      select @w_error  = 701049
      goto ERROR
   end

--INI AGI 16ABR19 -Si la oper padre se modifican las hijas

if @i_es_grupal = 'S'
begin

    if @i_banco is null
        select @i_banco = op_banco from ca_operacion where op_operacion = @i_operacionca
        
    exec @w_return = sp_modificar_operacion_grp
         @s_user           = @s_user,
         @s_sesn           = @s_sesn,
         @s_date           = @s_date,
         @s_term           = @s_term,
         @s_ofi            = @s_ofi,
         @i_ref_grupal     = @i_banco,
         @i_grupo          = @w_grupo,
         @i_calcular_tabla = @i_calcular_tabla,
         @i_tabla_nueva    = @i_tabla_nueva,
         @i_control_tasa   = @i_control_tasa,
         @i_recalcular     = @i_recalcular,
         @i_cliente_1      = @i_cliente_1,
         @i_cliente_2      = @i_cliente_2,
         @i_cliente_3      = @i_cliente_3,
         @i_cliente_4      = @i_cliente_4,
         @i_cliente_5      = @i_cliente_5,
         @i_monto_1        = @i_monto_1,
         @i_monto_2        = @i_monto_2,
         @i_monto_3        = @i_monto_3,
         @i_monto_4        = @i_monto_4,
         @i_monto_5        = @i_monto_5,
         @i_monto_6        = @i_monto_6,
		 @i_grupo_contable = @i_grupo_contable   --GFP 06/Ene/2022
                 
    if @w_return != 0 
    begin
        select @w_error = @w_return
        goto   ERROR
    end
end
--FIN AGI

commit tran

return 0

ERROR:

exec  cobis..sp_cerror
      @t_debug  = 'N',
      @t_file   = null,
      @t_from   = @w_sp_name,
      @i_num    = @w_error
--      @i_cuenta = @i_banco

return @w_error

go

