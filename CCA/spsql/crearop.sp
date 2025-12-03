/************************************************************************/
/*      Archivo:                crearop.sp                              */
/*      Stored procedure:       sp_crear_operacion                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre, Rodrigo Garces      */
/*      Fecha de escritura:     Ene. 1998                               */
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
/*      Crea una operacion de Cartera con sus rubros asociados y su     */
/*      tabla de amortizacion                                           */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Oct.23/98   Nydia Velasco NVR        Cambio tipo dato           */
/*                                                                      */
/*      11/May/99   Ramiro Buitron (CONTEXT) Personalizacion CORFINSURA */
/*                                           Incorporacion parametros de*/
/*                                           origen de fondos, ref rede.*/
/*      05/Ene/2017 Lorena Regalado          Incorporar concepto de     */
/*                                           Agrupamiento de Operaciones*/
/*      22/May/2017 Jorge Salazar            CGS-S112643                */
/*      13/May2017  Jorge Salazar            Parametros de entrada      */
/*                                           @i_tdividendo              */
/*                                           @i_periodo_cap             */
/*                                           @i_periodo_int             */
/*      09/Abr/2019 Adriana Giler            Campos de Grupales         */
/*      16/Abr/2019 Adriana Giler            Validar Campos de Grupales */
/*      08/May/2019 Adriana Giler            Enlace con Tramite         */
/*      10/Jun/2019 Luis Ponce               Crear OP.Grupal Te Creemos */
/*      05/Jul/2019  Adriana Giler      Operacion RefREn GrupalTeCreemos*/
/*      10/Jul/2019 Lorena Regalado          Crear Op. Interciclo       */
/*      02/Jul/2020 Luis Castellanos         CDIG Manejo Deudor-Codeudor*/
/*      17/Jul/2020 Luis Ponce           CDIG Nuevos campos Renovaciones*/
/*      PNA  17/Nov/2020                TipoPlazo Anual a Mensual       */
/*     06/Ene/2021   P.Narvaez  Tipo de Reestructuracion/Tipo Renovacion*/
/*      JUL-21-2021    Ricardo Rincon   se agrega @i_plazo a ejecucion  */
/*                                      de sp_tramite_cca               */
/*      19/Oct/2021 William Lopez            ORI-S544332-GFI            */
/*      06/Ene/2022 Guisela Fernandez        Ingreso de campo para      */
/*                                           grupo contable             */
/*      14/Ene/2022 Guisela Fernandez    Se obtiene el sector de la     */
/*                                       tabla temporal                 */
/*      09/03/2022  Kevin Rodríguez      Cambio de valor por defecto de */
/*                                       parámetro de fecha fija de pago*/
/*      22/03/2022  Kevin Rodríguez      Valor por defecto de grupo     */
/*      06/05/2022  Kevin Rodríguez      Ajustes creación trámite y oper*/
/*      24/11/2022  bduenas             S736964: Se agrega cod_actividad*/
/*      19/05/2023  Guisela Fernandez   S825268 Se comenta validacion de*/
/*                                      grupo contable                  */
/*      22/05/2023  Guisela Fernandez   S825268 Si se aplica validacion */
/*                                      de grupo contable               */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crear_operacion')
   drop proc sp_crear_operacion
go
create proc sp_crear_operacion
   @s_user              login        = null,
   @s_sesn              int          = null,
   @s_ssn               int          = null,
   @s_ofi               smallint     = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   --@t_trn               INT          = NULL,
   @i_anterior          cuenta       = null,
   @i_migrada           cuenta       = null,
   @i_tramite           int          = null,
   @i_cliente           int          = 0,
   @i_nombre            descripcion  = null,
   @i_sector            catalogo     = null,
   @i_cod_actividad     catalogo     = null,
   @i_toperacion        catalogo     = null,
   @i_oficina           smallint     = null,
   @i_moneda            tinyint      = null,
   @i_comentario        varchar(255) = null,
   @i_oficial           smallint     = null,
   @i_fecha_ini         datetime     = null,
   @i_monto             money        = null,
   @i_monto_aprobado    money        = null,
   @i_destino           catalogo     = null,
   @i_lin_credito       cuenta       = null,
   @i_ciudad            int          = null,
   @i_forma_pago        catalogo     = null,
   @i_cuenta            cuenta       = null,
   @i_formato_fecha     int          = 101,
   @i_no_banco          char(1)      = null,
   @i_dia_pago          int          = null,
   @i_clase_cartera     catalogo     = null,
   @i_origen_fondos     catalogo     = null,
   @i_tipo_empresa      catalogo     = null,
   @i_validacion        catalogo     = null,
   @i_fondos_propios    char(1)      = null,
   @i_ref_exterior      cuenta       = null,
   @i_sujeta_nego       char(1)      = 'N' ,
   @i_ref_red           varchar(24)  = null,
   @i_convierte_tasa    char(1)      = null,
   @i_tasa_equivalente  char(1)      = null,
   @i_fec_embarque      datetime     = null,
   @i_fec_dex           datetime     = null,
   @i_num_deuda_ext     cuenta       = null,
   @i_num_comex         cuenta       = null,
   @i_batch_dd          char(1)      = null,
   @i_tramite_hijo      int          = null,
   @i_reestructuracion  char(1)      = null,
   @i_tipo_cambio       char(1)      = null,
   @i_numero_reest      int          = null,
   @i_oper_pas_ext      varchar(64)  = null,
   @i_en_linea          char(1)      = 'S',
   @i_banca             catalogo     = null,
   @i_salida            char(1)      = 'S',
   @i_grupal            char(1)      = 'N', --LRE 05/Ene/2017
   @i_promocion         char(1)      = null, --LPO Santander
   @i_acepta_ren        char(1)      = null, --LPO Santander
   @i_no_acepta         char(1000)   = null, --LPO Santander
   @i_emprendimiento    char(1)      = null, --LPO Santander
   @i_tasa              float        = null, --JSA Santander
   @i_plazo             int          = null,
   @i_tplazo            catalogo     = null,
   @i_tdividendo        catalogo     = null,
   @i_periodo_cap       int          = null,
   @i_periodo_int       int          = null,
   @i_fecha_fija        char(1)      = null,   --LRE 08/ABR/2019  -- KDR Se respeta lo que viene como parámetrod
   --@i_grupo             varchar(10)  = '',    --AGI TeCreemos --LPO TEC el grupo debe ser INT.
   @i_ref_grupal        cuenta       = null, --AGI TeCreemos
   @i_es_grupal         char(1)      = 'N',  --AGI TeCreemos
   @i_fondeador         tinyint      = null, --AGI TeCreemos
   @i_cliente_1         varchar(200)  = null,
   @i_cliente_2         varchar(200)  = null,
   @i_cliente_3         varchar(200)  = null,
   @i_cliente_4         varchar(200)  = null,
   @i_cliente_5         varchar(200)  = null,
   @i_monto_1           varchar(200)  = null,
   @i_monto_2           varchar(200)  = null,
   @i_monto_3           varchar(200)  = null,
   @i_monto_4           varchar(200)  = null,
   @i_monto_5           varchar(200)  = null,
   @i_monto_6           varchar(200)  = null,   
   --PQU anadir parametro tasa interes, fecha primera cuota, ahorro esperado
   --LPO TEC Se pasa grupo, fecha ven primera cuota, y @i_tasa_grupal, ahorro esperado no aplica.
   @i_grupo             INT           = NULL, --LPO TEC
   @i_fecha_ven_pc      DATETIME      = NULL, --LPO TEC
   @i_tasa_grupal       FLOAT         = NULL, --LPO TEC
   @i_tipo              char(1)       = NULL, --"O",  --AGI TEC
   @i_ciudad_destino    int           = NULL, --AGI TEC
   @i_es_interciclo     char(1)       = NULL, --LRE TEC
   @i_simulacion        char(1)       = 'N',
   @i_desde_front_cca   char(1)       = 'N',  --LCA CDIG Manejo Codeudor
   @i_codeudor          int           = null, --LCA CDIG Manejo Codeudor
   @i_gracia_cap        INT           = NULL, --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_gracia_int        INT           = NULL, --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_dist_gracia       char(1)       = NULL, --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones    
   @i_periodo_reajuste  SMALLINT      = NULL, --LPO CDIG APIS II
   @i_reajuste_especial char(1)       = NULL, --LPO CDIG APIS II
   @i_dias_anio         SMALLINT      = NULL, --LPO CDIG APIS II
   @i_tipo_amortizacion VARCHAR(30)   = NULL, --LPO CDIG APIS II
   @i_cuota_completa    CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_tipo_cobro        CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_tipo_reduccion    CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_aceptar_anticipos CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_precancelacion    CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_tipo_aplicacion   CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_evitar_feriados   CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_renovac           CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_mes_gracia        INT           = NULL, --LPO CDIG APIS II
   @i_reajustable       CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_base_calculo      CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_causacion         CHAR(1)       = NULL, --LPO CDIG APIS II
   @i_nace_vencida      CHAR(1)       = NULL, --LPO CDIG APIS II
   
   /*LPO CDIG Operaciones Pasivas INICIO*/
   @i_tipo_acreedor     catalogo      = NULL,
   @i_num_cont          VARCHAR(100)  = NULL,
   @i_numreg_bc         VARCHAR(25)   = NULL,
   @i_tipo_deuda        catalogo      = NULL,
   @i_fecha_aut         datetime      = NULL,
   @i_num_aut           VARCHAR(100)  = NULL,
   @i_num_facilidad     VARCHAR(25)   = NULL,
   @i_forma_reposicion  catalogo      = NULL,
   @i_causa_fin_sub     catalogo      = NULL,
   @i_mercado_obj_fin   catalogo      = NULL,   
   /*LPO CDIG Operaciones Pasivas FIN*/
   @i_tipo_renovacion   char(1)       = null,
   @i_tipo_reest        char(1)       = null,
   @i_grupo_contable    catalogo      = null, --GFP 06/Ene/2022
   
   @o_banco             cuenta        = null output
   
as
declare
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_pa_char           catalogo,
   @w_direccion         tinyint,
   @w_banco             cuenta,
   @w_operacionca       int,
   @w_operacionca1      int, --ALMP
   @w_sector_cli        catalogo,
   @w_sector_ger        catalogo,
   @w_fecha_proceso     datetime,   --HRE Ref 001 04/03/2002
   @w_dias_contr        int,        --HRE Ref 001 04/03/2002
   @w_dias_hoy          int,        --HRE Ref 001 04/03/2002
   @w_rowcount          int,
   @w_contador          int,
   @w_pos               int,
   @w_secuencia         int,
   @w_cadena            varchar(200),
   @w_valor             varchar(15),
   @w_grupo             int,
   @w_monto_hijas       money,
   @w_ced_ruc           varchar(30),
   @w_nombre            varchar(60),
   @w_tramite           int,
   @w_ced_ruc_codeudor  varchar(20), --LCA CDIG Manejo Codeudor
   @w_linea             VARCHAR(25),
   @w_cant_oper         INT, -- ALMP BORRAR
   @w_cant_rubros       INT, -- ALMP BORRAR
   @w_cant_dividendos   INT, -- ALMP BORRAR
   @w_cant_amortizacion INT, -- ALMP BORRAR
   @w_desde_crea_grupal char(1)      -- KDR Identifica operación Grupal [Hija]



/* CARGAR VALORES INICIALES */
select @w_sp_name  = 'sp_crear_operacion'--,
--PQU integracion no tiene que generar número largo @i_no_banco = 'N' -- LGU cambio S x N para que genere numero largo

SELECT @w_linea = @i_lin_credito --LPO CDIG Operaciones Pasivas

/* DIAS CONTROL TRAMITE */
select @w_dias_contr = pa_smallint
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'DCTRA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   exec cobis..sp_cerror
       @t_debug='N',
       @t_file = null,
       @t_from =@w_sp_name,
       @i_num = 710215
--       @i_cuenta= ' '
       return 1
end

select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7  -- 7 pertence a Cartera

select @w_dias_hoy = datediff(dd,@i_fecha_ini,@w_fecha_proceso)

if @w_dias_hoy > @w_dias_contr begin
   exec cobis..sp_cerror
       @t_debug='N',
       @t_file = null,
       @t_from =@w_sp_name,
       @i_num = 710212
--       @i_cuenta= ' '
       return 1
end

/* Fin Ref 001  */

if (@i_monto is null or @i_monto = 0)  and(@i_toperacion <> 'REVOLVENTE')
begin
  PRINT 'crearop.sp no puede llegar el valor de creacion en NULL o 0'
  return 724621 --VALOR DEBE SER MAYOR A CERO --708154
end

--LA DIRECCION INICIAL ES LA No.1 LA CUAL SE MODIFICA UNA VEZ SE CREA LA OBLIGACION
--POR LA PANTALLA DE PARAMETROS EN LA CREACION MISMA O ACTUALIZACIOn
select @w_direccion = min(di_direccion)
from cobis..cl_direccion
where di_ente    = @i_cliente
and di_vigencia  = 'S'
and di_principal = 'S'
set transaction isolation level read uncommitted

--PQU esto quitar de aqui, el sp principal  hara las validaciones y que este en la historia de interface de creacion de operaciones grupales, pero ahi ya vendra la informacion de las individuales en bloques en el WS y estara grabado en tablas temporales segun la estructura de la tabla temporal
--LPO TEC Entonces se asigna @w_grupo = @i_grupo y se comenta este codigo
select  @w_grupo = isnull(@i_grupo,0) --LPO TEC  -- KDR Se establece valor de parámetro si este viene en null.
/*
--INI AGI 16abr19  Si es grupal validar consistencia de datos.

select  @w_grupo = convert(int, @i_grupo)
if @i_es_grupal = 'S'
begin
    --Creando temporal

    create table #grupales
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
                insert #grupales values (convert(int,@w_valor), 0)
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
                update #grupales
                set valor = convert(money, @w_valor)
                where secuencia = @w_secuencia
            end

            if ltrim(rtrim(@w_cadena)) = '|'
                select @w_cadena = ''

            select @w_secuencia = @w_secuencia + 1
        end
        select @w_contador = @w_contador + 1
    end

    delete #grupales
    where valor <= 0
       or valor =  null

    --Monto de los individuales no supere el valor del padre
    select @w_monto_hijas = sum(valor)
    from #grupales

    if @w_monto_hijas <> @i_monto
    begin
         print 'ERROR: SUMA DE MONTOS DE OPERACIONES INDIVIDUALES ES DIFERENTE AL MONTO DE LA OPERACION PADRE'
         return 70204
    end

    --Clientes individuales pertenezca al grupo indicado
    if exists(select 1 from #grupales
              where cliente not in (select cg_ente from cobis..cl_cliente_grupo
                                     where cg_grupo = @w_grupo))
    begin
        print 'ERROR: EXISTEN CLIENTES DE OPERACIONES HIJAS QUE NO PERTENECEN AL GRUPO '
        return 70205
    end

    --Clientes individuales pertenezca al grupo indicado
    if exists(select 1 from #grupales
              where cliente not in (select cg_ente from cobis..cl_cliente_grupo
                                     where cg_grupo = @w_grupo
                                       and cg_estado = 'V'))
    begin
        print 'ERROR: EXISTEN CLIENTES DE OPERACIONES HIJAS QUE ESTAN INACTIVAS EN EL GRUPO'
        return 70205
    end


    --Que todos los clientes tengas valores en prestamo
   if exists(select 1 from #grupales
              where valor is null or valor = 0)
    begin
        print 'ERROR: EXISTEN CLIENTES QUE NO HAN ASIGNADO VALOR A LA OPERACION'
        return 70205
    end
end
--FIN AGI
*/
--LPO TEC FIN Entonces se asigna @w_grupo = @i_grupo y se comenta este codigo
--fin PQU quitar codigo

/*Si el tipo de plazo es Anual, se cambia a Mensual, para colocar como entero el plazo
recalculado en procesos como reestructuras, abonos extraordinarios u otros*/

if @i_tplazo = 'A' and isnull(@i_tdividendo,'M') = 'M'
begin
   select @i_plazo = @i_plazo *(a.td_factor/b.td_factor)
   from ca_tdividendo a, ca_tdividendo b
   where a.td_tdividendo = @i_tplazo
   and   b.td_tdividendo = 'M'

   select @i_tplazo = 'M'
end

--GFP Validacion de asignacion por defecto de grupo contable
if @i_grupo_contable is null
begin 
    --Ese valor se pone por defecto cuando el parámetro @i_grupo_contable es null, pero es un error
    select @i_grupo_contable = pa_char from cobis..cl_parametro 
    where pa_nemonico = 'GRCODF' and pa_producto = 'CCA'
    if @@rowcount = 0
     begin
         select @w_error = 101077
         goto ERROR
    end
end

--DMO CAMBIO PARA QUE CIUDAD NO VAYA EN 0 PARA SIMULUCAION 
if @i_simulacion='S' and @i_ciudad = 0
begin 
    select top 1 @i_ciudad = ci_ciudad  from cobis..cl_ciudad
end

if @i_en_linea = 'S'
   begin tran

-- CREACIÓN DEL TRÁMITE
if @i_tramite is NULL --PQU aumentar un and si la operacion no es grupal, porque si es grupal se hace desde el sp_crear_oper_sol_wf
--AND @i_grupal <> 'S'  --LPO TEC Entonces se coloca condicion de diferente de Grupal.
and @i_es_grupal = 'N'  --AGC Si no hay un tramite puede entrar por individuales o por hijas
and @i_simulacion = 'N'
begin
--INI AGI  Crear Codeudores - Tramite

    IF @i_tipo IS NULL 
       SELECT @i_tipo = 'O'
       
    if (@i_ref_grupal is not null and @i_ref_grupal <> '') and @i_grupal = 'S'  --KDR Identifica Op. Grupal Hija
       select @w_desde_crea_grupal = 'S'
    else
       select @w_desde_crea_grupal = 'N'
       
    -- KDR Se obtiene sector para trámite, ya que es obligatorio
    select @i_sector = isnull(@i_sector, dt_clase_sector)
    from ca_default_toperacion
    where dt_toperacion = @i_toperacion
    and   dt_moneda     = @i_moneda
        
    exec @w_return = cob_credito..sp_tramite_cca
    @s_ssn                = @s_ssn,
    @s_user               = @s_user,
    @s_sesn               = @s_sesn,
    @s_term               = @s_term,
    @s_date               = @s_date,
    @s_ofi                = @s_ofi,
    @t_trn                = 21020,
    @i_oficina_tr         = @i_oficina,
    @i_usuario_tr         = @s_user,
    @i_fecha_crea         = @s_date,
    @i_oficial            = @i_oficial,
    @i_sector             = @i_sector,
    @i_ciudad             = @i_ciudad,
    @i_fecha_apr          = @s_date,
    @i_usuario_apr        = @s_user,
    @i_toperacion         = @i_toperacion,
    @i_producto           = 'CCA',
    @i_monto              = @i_monto,
    @i_tipo               = @i_tipo,
    @i_moneda             = @i_moneda,
    @i_periodo            = @i_tplazo,
    @i_destino            = @i_destino,
    @i_cod_actividad      = @i_cod_actividad,
    @i_cliente            = @i_cliente,
    @i_clase              = @i_clase_cartera,
    @i_monto_mn           = @i_monto,
    @i_monto_des          = @i_monto,
    --INI AGI 05JUL19
    @i_ciudad_destino     = @i_ciudad_destino,
    @i_banco              = @w_banco,
    @i_num_periodos       = @i_plazo,
    @i_plazo              = @i_plazo,
    @i_grupal             = @i_grupal,
    @i_promocion          = @i_promocion,
    @i_acepta_ren         = @i_acepta_ren,
    @i_no_acepta          = @i_no_acepta,
    @i_emprendimiento     = @i_emprendimiento,
    @i_desde_cartera        = 'S',               --AMP para que no actualice el opt_banco
    @i_monto_aprobado     = @i_monto_aprobado, --@i_tg_monto_aprobado,
    @i_origen_fondos      = @i_origen_fondos,  --WLO_S544332
    --FIN AGI
    @i_desde_crea_grupal  = @w_desde_crea_grupal, --KDR Identifica Op. Grupal Hija
    @o_tramite            = @w_tramite out
    
    if @w_return <> 0
    begin
       select @w_error = @w_return
       goto ERROR
    end
    
    if @w_desde_crea_grupal = 'S'       -- Si se crea un tramite Grupal, Cartera asume que ya existe un trámite y que fue creado fuera de CCA
       select @i_tramite = @w_tramite

end

exec @w_return              = sp_crear_operacion_int
     @s_user                = @s_user,
     @s_sesn                = @s_sesn,
     @s_ofi                 = @s_ofi,
     @s_date                = @s_date,
     @s_term                = @s_term,
     @i_anterior            = @i_anterior,
     @i_migrada             = @i_migrada,
     @i_cliente             = @i_cliente,
     @i_nombre              = @i_nombre,
     @i_sector              = @i_sector,
     @i_tramite             = @i_tramite,
     @i_toperacion          = @i_toperacion,
     @i_oficina             = @i_oficina,
     @i_moneda              = @i_moneda,
     @i_comentario          = @i_comentario,
     @i_oficial             = @i_oficial,
     @i_fecha_ini           = @i_fecha_ini,
     @i_monto               = @i_monto,
     @i_monto_aprobado      = @i_monto_aprobado,
     @i_destino             = @i_destino,
     @i_lin_credito         = @i_lin_credito,
     @i_ciudad              = @i_ciudad,
     @i_forma_pago          = @i_forma_pago,
     @i_cuenta              = @i_cuenta,
     @i_formato_fecha       = @i_formato_fecha,
     @i_periodo_crecimiento = 0,
     @i_tasa_crecimiento    = 0,
     @i_direccion           = @w_direccion,
     @i_clase_cartera       = @i_clase_cartera,
     @i_origen_fondos       = @i_origen_fondos,
     @i_fondos_propios      = @i_fondos_propios,
     @i_tipo_empresa        = @i_tipo_empresa,
     @i_validacion          = @i_validacion,
     @i_ref_exterior        = @i_ref_exterior,
     @i_sujeta_nego         = @i_sujeta_nego,
     @i_ref_red             = @i_ref_red,
     @i_convierte_tasa      = @i_convierte_tasa,
     @i_tasa_equivalente    = @i_tasa_equivalente,
     @i_fec_embarque        = @i_fec_embarque,
     @i_fec_dex             = @i_fec_dex,
     @i_num_deuda_ext       = @i_num_deuda_ext,
     @i_num_comex           = @i_num_comex,
     @i_no_banco            = @i_no_banco,
     @i_batch_dd            = @i_batch_dd,
     @i_tramite_hijo        = @i_tramite_hijo,
     @i_reestructuracion    = @i_reestructuracion,
     @i_subtipo             = @i_tipo_cambio,
     @i_numero_reest        = @i_numero_reest,
     @i_oper_pas_ext        = @i_oper_pas_ext,
     @i_dia_pago            = @i_dia_pago,
     @i_banca               = @i_banca,
     @i_salida              = @i_salida,
     @i_grupal              = @i_grupal,        --LRE 05/Ene/2017
     @i_promocion           = @i_promocion,     --LPO Santander
     @i_acepta_ren          = @i_acepta_ren,    --LPO Santander
     @i_no_acepta           = @i_no_acepta,     --LPO Santander
     @i_emprendimiento      = @i_emprendimiento,--LPO Santander
     @i_tasa                = @i_tasa,          --JSA Santander
     @i_plazo               = @i_plazo,
     @i_tplazo              = @i_tplazo,
     @i_tdividendo          = @i_tdividendo,
     @i_periodo_cap         = @i_periodo_cap,
     @i_periodo_int         = @i_periodo_int,
     @i_fecha_fija          = @i_fecha_fija,   --LRE 08/ABR/2018
     @i_gracia_cap          = @i_gracia_cap,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
     @i_gracia_int          = @i_gracia_int,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
     @i_dist_gracia         = @i_dist_gracia,  --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones              
     @i_grupo               = @w_grupo,        --AGI TeCreemos
     @i_ref_grupal          = @i_ref_grupal,   --AGI TeCreemos
     @i_es_grupal           = @i_es_grupal,    --AGI TeCreemos
     @i_fondeador           = @i_fondeador, --AGI TeCreemos
     --PQU enviar tasa interes, ahorro esperado y fecha vencimiento primera cuota
     --LPO TEC Entonces se pasan los paremetros fecha ven primera cuota, y @i_tasa_grupal, grupo (ya se estaba pasando) y el ahorro esperado no aplica.
     @i_fecha_ven_pc        = @i_fecha_ven_pc,  --LPO TEC
     @i_tasa_grupal         = @i_tasa_grupal,   --LPO TEC
     @i_es_interciclo       = @i_es_interciclo, --LRE TEC
     @i_periodo_reajuste    = @i_periodo_reajuste, --LPO CDIG APIS II
     @i_reajuste_especial   = @i_reajuste_especial, --LPO CDIG APIS II
     @i_tipo                = @i_tipo,              --LPO CDIG APIS II
     @i_dias_anio           = @i_dias_anio,         --LPO CDIG APIS II
     @i_tipo_amortizacion   = @i_tipo_amortizacion, --LPO CDIG APIS II
     @i_cuota_completa      = @i_cuota_completa,    --LPO CDIG APIS II
     @i_tipo_cobro          = @i_tipo_cobro,        --LPO CDIG APIS II
     @i_tipo_reduccion      = @i_tipo_reduccion,    --LPO CDIG APIS II
     @i_aceptar_anticipos   = @i_aceptar_anticipos, --LPO CDIG APIS II
     @i_precancelacion      = @i_precancelacion,    --LPO CDIG APIS II
     @i_tipo_aplicacion     = @i_tipo_aplicacion,   --LPO CDIG APIS II
     @i_evitar_feriados     = @i_evitar_feriados,   --LPO CDIG APIS II
     @i_renovacion          = @i_renovac,           --LPO CDIG APIS II
     @i_mes_gracia          = @i_mes_gracia,        --LPO CDIG APIS II
     @i_reajustable         = @i_reajustable,       --LPO CDIG APIS II
     @i_base_calculo        = @i_base_calculo,
     @i_causacion           = @i_causacion,
     @i_nace_vencida        = @i_nace_vencida,
     @i_tipo_acreedor       = @i_tipo_acreedor,
     @i_num_cont            = @i_num_cont,
     @i_numreg_bc           = @i_numreg_bc,
     @i_tipo_deuda          = @i_tipo_deuda,
     @i_fecha_aut           = @i_fecha_aut,
     @i_num_aut             = @i_num_aut,
     @i_num_facilidad       = @i_num_facilidad,
     @i_forma_reposicion    = @i_forma_reposicion,
     @i_causa_fin_sub       = @i_causa_fin_sub,
     @i_mercado_obj_fin     = @i_mercado_obj_fin,
     @i_tipo_renovacion     = @i_tipo_renovacion,
     @i_tipo_reest          = @i_tipo_reest,
     @i_grupo_contable      = @i_grupo_contable, --GFP 06/Ene/2022
     @o_banco               = @o_banco output

if @w_return != 0 begin
   select @w_error = @w_return
   goto ERROR
end

if @i_tramite is null
   select @i_tramite = @w_tramite

--GFP 14/Ene/2022 Se obtiene el @i_sector con que se genero el prestamo
--INI AGI 09JUL19
select @w_banco       = opt_banco,
       @w_operacionca = opt_operacion,
       @i_sector      = opt_sector
from ca_operacion_tmp
where opt_banco = @o_banco
--FIN AGI

--Actualizar la operacion con el tramite
update ca_operacion_tmp with (rowlock)
set opt_tramite = @i_tramite
where opt_banco = @o_banco

--INI AGI 05JUL19  Actualizar el dato de tramite
update cob_credito..cr_tramite
set  tr_numero_op       = @w_operacionca,
     tr_numero_op_banco = @o_banco,
     tr_sector          = @i_sector
where  tr_tramite   = @i_tramite
--FIN AGI


--LCA CDIG Manejo Codeudor INICIO
if @i_desde_front_cca = 'S' AND @i_simulacion = 'N' --LPO CDIG Simulacion Creacion de Operaciones
begin
select
@w_ced_ruc = en_ced_ruc,
@w_nombre  = rtrim(isnull(p_p_apellido,''))+' '+rtrim(isnull(p_s_apellido,''))+' '+rtrim(isnull(en_nombre,''))
from  cobis..cl_ente
where en_ente = @i_cliente
--PRINT CONVERT(VARCHAR, @@rowcount)
set transaction isolation level read uncommitted

if @w_ced_ruc is null or @w_nombre is null
begin
--   PRINT CONVERT(VARCHAR, @@rowcount) + ' ' + @w_ced_ruc + ' ' + @w_nombre
   select @w_error = 710200  --No existe cliente solicitado
   goto ERROR
end

--PRINT 'REGISTRAR DEUDOR PRINCIPAL'
exec @w_return = sp_codeudor_tmp
@s_sesn        = @s_sesn,
@s_user        = @s_user,
@i_borrar      = 'S',
@i_secuencial  = 1,
@i_titular     = @i_cliente,
@i_operacion   = 'A',
@i_codeudor    = @i_cliente,
@i_ced_ruc     = @w_ced_ruc,
@i_rol         = 'D',
@i_externo     = 'N',
@i_banco       = @w_banco

if @w_return != 0
begin
   select @w_error = @w_return
   goto ERROR
end

--PRINT 'VERIFICAR ENVIO DE CODEUDOR'
if isnull(@i_codeudor, 0) != 0
begin
--   PRINT 'CONSULTAR INFORMACION DEL CODEUDOR'
   select @w_ced_ruc_codeudor = en_ced_ruc
   from cobis..cl_ente
   where  en_ente = @i_codeudor
   set transaction isolation level read uncommitted

   if @w_ced_ruc_codeudor is null
   begin
      select @w_error = 710200  --No existe cliente solicitado
      goto ERROR
   end
--   PRINT 'REGISTRAR CODEUDOR'
   exec @w_return = sp_codeudor_tmp
   @s_sesn        = @s_sesn,
   @s_user        = @s_user,
   @i_borrar      = 'N',
   @i_secuencial  = 2,
   @i_titular     = @i_cliente,
   @i_operacion   = 'A',
   @i_codeudor    = @i_codeudor,
   @i_ced_ruc     = @w_ced_ruc_codeudor,
   @i_rol         = 'C',
   @i_externo     = 'N',
   @i_banco       = @w_banco
      
   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR
   end
end
end
--LCA CDIG Manejo Codeudor FIN

if @i_es_grupal = 'N'  --AGC Si no hay un tramite puede entrar por individuales o por hijas
and @i_simulacion = 'N'
begin

    select @w_ced_ruc = en_ced_ruc,
           @w_nombre  = rtrim(isnull(p_p_apellido,''))+' '+rtrim(isnull(p_s_apellido,''))+' '+rtrim(isnull(en_nombre,''))
    from  cobis..cl_ente
    where en_ente = @i_cliente
    set transaction isolation level read uncommitted

    if @w_ced_ruc is null or @w_nombre is null
    begin
        select @w_error = 710200  --No existe cliente solicitado
       goto ERROR
    end
    
    if not exists (select  1
       from    cob_credito..cr_deudores,
       cobis..cl_ente
       where   de_tramite = @i_tramite
       and     de_cliente = @i_cliente
       and     de_cliente = en_ente
       and     en_ente    > 0
       and     de_tramite > 0
       and     de_cliente > 0)
    begin

       --PRINT 'REGISTRAR DEUDOR PRINCIPAL'
       exec @w_return = cob_credito..sp_deudores
            @s_date            = @s_date,
            @s_ssn             = @s_ssn ,
            @s_user            = @s_user,
            @s_term            = @s_term,
            @s_ofi             = @s_ofi ,
            @s_sesn            = @s_sesn,
            @t_trn             = 21013,
            @i_operacion       = 'I',
            @i_tramite         = @i_tramite,
            @i_cliente         = @i_cliente,
            @i_rol             = 'D',
            @i_ced_ruc         = @w_ced_ruc,
            @i_banco           = @o_banco,
            @i_cobro_cen       = 'N'
       
       if @w_return != 0
       begin
           print 'error'
          select @w_error = @w_return
          goto ERROR
       end
    
    end

end


--PQU Este codigo igual quitar de aqui ya que la creacion de las operaciones hijas se hara en un proceso asincrinico
--LPO TEC Entonces se comenta este codigo
/*
--Crear Grupales
if @i_es_grupal = 'S'
begin
    exec @w_return = sp_crear_operacion_grp
         @s_user           = @s_user,
         @s_sesn           = @s_sesn,
         @s_ssn            = @s_ssn ,
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_ofi            = @s_ofi,
         @i_opcion         = 'I',
         @i_ref_grupal     = @o_banco,
         @i_grupo          = @i_grupo,
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
         @i_monto_6        = @i_monto_6
    if @w_return != 0 begin
       select @w_error = @w_return
       goto ERROR
    end
end
*/
--LPO TEC FIN Entonces se comenta este codigo
--fin PQU quitar de aqui

if @i_en_linea = 'S'
   commit tran

return 0

ERROR:

if @i_en_linea = 'S'
begin
   while @@trancount > 0
      rollback

   exec cobis..sp_cerror
      @t_debug  = 'N',
      @t_file   = null,
      @t_from   = @w_sp_name,
      @i_num    = @w_error
--      @i_cuenta = ' '
end
ELSE
begin

   exec sp_errorlog
        @i_fecha       = @s_date,
        @i_error       = @w_error,
        @i_usuario     = @s_user,
        @i_tran        = 7000,
        @i_tran_name   = '',
        @i_rollback    = 'S',
        @i_cuenta      = @i_toperacion
end

return @w_error

go


