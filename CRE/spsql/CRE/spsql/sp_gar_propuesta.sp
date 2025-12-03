/**************************************************************************/
/*  Archivo:                    cr_gar_p.sp                               */
/*  Stored procedure:           sp_gar_propuesta                          */
/*  Base de Datos:              cob_credito                               */
/*  Producto:                   Credito                                   */
/*  Disenado por:               Myriam Davila                             */
/*  Fecha de Documentacion:     14/Ago/95                                 */
/**************************************************************************/
/*                          IMPORTANTE                                    */
/*  Este programa es parte de los paquetes bancarios propiedad de         */
/*  'COBISCORP'.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como            */
/*  cualquier autorizacion o agregado hecho por alguno de sus             */
/*  usuario sin el debido consentimiento por escrito de la                */
/*  Presidencia Ejecutiva de COBISCORP o su representante.                */
/**************************************************************************/
/*                          PROPOSITO                                     */
/*  Este stored procedure permite realizar operaciones DML                */
/*  Insert, Update, Delete, Search y Query en la tabla                    */
/*  cr_gar_propuesta                                                      */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA       AUTOR                            RAZON                    */
/*  14/Ago/95   Ivonne Ordonez      Emision Inicial                       */
/*  22/Ene/97   F. Arellano         Aumento campos deudor clase y estado  */
/*  06/Jun/97   M.Davila            Aumento de modo en 'S'                */
/*  10/Jun/97   F. Arellano         optimizacion                          */
/*  05/May/98   T. Granda           Implementacion de sentencias          */
/*                                  de manejo de cu_estado_credito        */
/*  11/May/98   Tatiana Granda      Nombre completo cliente               */
/*  12/Ago/98   Monica Vidal        Correccion Especifi.                  */
/*  09/Feb/99   S. Hernandez        Especif. CRE007                       */
/*  19/Ago/99   Dario Barco Leon    Personalizacion CORFINSURA            */
/*  05/Feb/01   Zulma Reyes(ZR)     GD00064 TEQUENDAMA                    */
/*  23/Dic/02   A. Núñez            Esp. CD00067                          */
/*  30/Ago/04   Luis Ponce          Optimizacion                          */
/*  10/Feb/06   John Jairo Rendon   Optimizacion                          */
/*  14/Mar/07   John Jairo Rendon   Optimizacion                          */
/*  30/08/2012  Acelis              Alcance 272                           */
/*  19/12/2012  Nini Salazar        Req343                                */
/*  13/04/2021  Patricio Mora       Integración IMPACT FINCA              */
/*  24/01/2022  William Lopez       ORI-S586466-GFI                       */
/*  17/05/2022  Dilan Morales       Se valida ente para que no exista     */
/*                                  duplicidad.                           */
/*  19/05/2022  Dilan Morales       Se valida que devuelva garante o      */
/*                                  cliente según la garantía             */
/*  26/09/2023  Bruno Duenas        Se agrega timeout                     */
/*  27/11/2023  Mariela Cabay       Se agrega validación canal workflow   */
/*  01/12/2023  Bruno Duenas        Se agrega validación canal workflow-2 */
/**************************************************************************/
use cob_credito
go

if exists (select * from sysobjects where name = 'sp_gar_propuesta')
   drop proc sp_gar_propuesta
go
---SEP.2014.117395

CREATE proc sp_gar_propuesta (
            @s_ssn                   int          = null,
            @s_user                  login        = null,
            @s_sesn                  int          = null,
            @s_term                  descripcion  = null,
            @s_date                  datetime     = null,
            @s_srv                   varchar(30)  = null,
            @s_lsrv                  varchar(30)  = null,
            @s_rol                   smallint     = null,
            @s_ofi                   smallint     = null,
            @s_org_err               char(1)      = null,
            @s_error                 int          = null,
            @s_sev                   tinyint      = null,
            @s_msg                   descripcion  = null,
            @s_org                   char(1)      = null,
            @t_rty                   char(1)      = null,
            @t_trn                   smallint     = null,
            @t_debug                 char(1)      = 'N',
            @t_file                  varchar(14)  = null,
            @t_from                  varchar(30)  = null,
            @t_timeout               int          = null,
            @i_operacion             char(1)      = null,
            @i_tramite               int          = null,
            @i_garantia              varchar(64)  = null,
            @i_clasificacion         char(1)      = 'a',
            @i_exceso                char(1)      = 'N',
            @i_monto_exceso          money        = 0,
            @i_deudor                int          = null,
            @i_clase                 char(1)      = null,
            @i_estado                char(1)      = null,
            @i_estado_credito        char(1)      = null,
            @i_modo                  tinyint      = 1,      --para traer todos los datos
            @i_porcentaje_resp       float        = null,   --SBU: 06/abr/2000
            @i_valor_resp_garantia   money        = null,
            @i_numero_operacion      cuenta       = null,
            @i_finagro               char(1)      = null,     --ANP
            @i_tipo_garantia         varchar(20)  = 'AUTOMATICA',
            @i_previa                char(1)      = null,
            @i_colat_adic            char(1)      = 'N',    --req343
            @i_crea_ext              char(1)      = null,
            @i_canal                 tinyint      = null,         -- Canal: 0=Frontend 1=Batch 2=Workflow 3=Rest
            @o_retorno               float        = null out 
)
as
declare
            @w_today                 datetime,     /* fecha del dia */
            @w_return                int,          /* valor que retorna */
            @w_sp_name               varchar(32),  /* nombre stored proc*/
            @w_existe                tinyint,      /* existe el registro*/
            @w_tramite               int,
            @w_garantia              varchar(64),
            @w_clasificacion         char(1),
            @w_exceso                char(1),
            @w_monto_exceso          money,
            @w_deudor                int ,
            @w_clase                 char(1),
            @w_estado                char(1),
            @w_gargpe                descripcion,
            @w_inspector             smallint,
            @w_garanti               varchar(64),
            @w_nombre                varchar(30),
            @w_propiet               varchar(50),
            @w_ftramite              int,
            @w_fvalor                money,
            @w_ffecha                datetime,
            @w_fcontador             int,
            @w_fsuma                 money,
            @w_porcentaje            float,
            @w_valor_cobertura       money,
            @w_valor_resp            money,
            @w_monto                 money,
            @w_fecha_mod             datetime,
            @w_porcentaje_resp       float,
            @w_valor_resp_garantia   money,
            @w_tipo_garantia         varchar(64),
            @w_valor                 varchar(30),
            @w_bandera               int,
            @w_garesp                varchar(10),
            @w_tr_toperacion         cuenta,
            @w_cobertura             float,
            @w_clase_custodia        char(1),
            @w_fecha_imax            datetime,
            @w_spid                  int,
            @w_tipo_gar              varchar(64),
            @w_control               char(1),
            @w_estado_obl            smallint,
            @w_cotizacion            float,
            @w_moneda_op             smallint,
            @w_monto_op              money,
            @w_monto_exeq            money,
            @w_monto_micro           money,
            @w_parametro_fng         catalogo,
            @w_cod_gar_fng           catalogo,
            @w_factor                float,
            @w_msg                   descripcion,
            @w_error                 int,
            @w_SMV                   money,
            @w_monto_SMV             money,
            @w_tipo_cust             varchar(64),
            @w_dir_neg               varchar(10),
            @w_mensaje               varchar(250),
            @w_depto_neg             int,
            @w_ciudad_neg            int,
            @w_actividad             varchar(10),
            @w_parametro1            smallint,
            @w_parametro2            smallint,
            @w_valor_actual          money,
            @w_valor_disponible      money,
            @w_param_musaid          int,
            @w_param_fusaid          datetime,
            @w_usaid                 int,
            @w_valor_reservado       money,
            @w_valor_desembolsado    money,
            @w_tipo_tr               char(1),
            @w_fecha_proceso         datetime,
            @w_deudor_cus            int,
            @w_fecha_cotizacion      datetime,
            @w_valor_cotiz           money,
            @w_cod_gar_fag           varchar(30),
            @w_cod_gar_usaid         varchar(30),
            @w_tipo_gar_padre        varchar(64),
            @w_destino_tram          catalogo,
            @w_tipo_productor        catalogo,
            @w_porc_desde            float,
            @w_porc_hasta            float,
            @w_colateral             varchar(255),
            @w_cod_colateral         catalogo,
            @w_es_colateral          char(1),
            @w_val_actual            money,
            @w_fag                   varchar(10),
            @w_valor_monto           money,
            @w_cod_gar_fng_banca     catalogo,
            @w_tipo_personal         catalogo,
            @o_valor_inf             float,
            @o_valor_sup             float,
            @w_valor_monto_tmp       float,
            @w_monto_tmp             float,
            @w_monto_SMV_tmp         decimal (20,10) , --float,
            @w_valida_ok             smallint, --req343
            @w_comparte_nue          char(1),  --req343
            @w_tipo_gar_ant          varchar(255),  --req343
            @w_comparte_ant          char(1),   --req343
            @w_si                    char(2)= 'Si',
            @w_no                    char(2)='No',
            @w_s                     char(1)= 'S',
            @w_n                     char(1)='N',
            @w_porcentaje_cobertura  float = null --WLO_S586466

select @w_today        = @s_date
select @w_spid         = @@spid * 100
select @w_sp_name      = 'sp_gar_propuesta'
select @w_es_colateral = 'N'

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

-- Parametro FAG        
select @w_fag = pa_char
from   cobis..cl_parametro
where  pa_producto = 'GAR'
and    pa_nemonico = 'CODFAG'        

select  @w_valor  = pa_char
from    cobis..cl_parametro
where   pa_producto = 'GAR'
and     pa_nemonico = 'FAG'
set transaction isolation level read uncommitted

select  @w_garesp = pa_char
from    cobis..cl_parametro
where   pa_producto = 'GAR'
and     pa_nemonico = 'GARESP'
set transaction isolation level read uncommitted

-- PARAMETRO PARA GARANTIAS FNG
select @w_parametro_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'

/*CODIGO PADRE GARANTIA DE FNG*/
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'

--- CODIGO PADRE GARANTIA DE FAG 
select @w_cod_gar_fag = pa_char
  from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
   and pa_nemonico = 'CODFAG'
set transaction isolation level read uncommitted

/* CODIGO PADRE GARANTIA DE USAID */
select @w_cod_gar_usaid = pa_char
  from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
   and pa_nemonico = 'CODUSA'
set transaction isolation level read uncommitted

/*PARAMETRO SALARIO MINIMO VITAL VIGENTE*/
select @w_SMV      = pa_money 
from   cobis..cl_parametro with (nolock)
where  pa_producto  = 'ADM'
and    pa_nemonico  = 'SMV'

/*PARAMETRO DIRECCION TIPO NEGOCIO*/
select @w_dir_neg  = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto  = 'MIS'
and    pa_nemonico  = 'TDN'

-- Ubicar garantia BANCA NUEVAS OPORTUNIDADES 036
select @w_cod_gar_fng_banca = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODOPO'

select @w_tipo_personal = pa_char
from cobis..cl_parametro
where pa_producto = 'GAR'
and pa_nemonico = 'GPE' 

select tc_tipo as tipo into #calfng
from cob_custodia..cu_tipo_custodia
where  tc_tipo_superior  = @w_cod_gar_fng

select @w_tipo_tr = tr_tipo
from    cob_credito..cr_tramite
where   tr_tramite = @i_tramite

select @w_tipo_gar = cu_tipo from cob_custodia..cu_custodia
where cu_codigo_externo = @i_garantia 

if  @w_tipo_gar  = @w_cod_gar_fng_banca and @w_tipo_tr in (select codigo_sib from cob_credito..cr_corresp_sib where tabla = 'T147')
begin
  print ' Tipo de Ruta no permite la creacion de Garantia Automatica '
  exec cobis..sp_cerror
  @t_from  = @w_sp_name,
  @i_num   = 143051
  return     143051
end

delete cr_superior_gp where sesion = @w_spid
delete cr_superior_gp_esp where sesion = @w_spid
delete cr_tipo_actual_gp where sesion = @w_spid
delete cr_garantias_gp  where sesion = @w_spid
delete cr_garantia_gp where sesion = @w_spid
delete cr_tramites_gp where sesion = @w_spid

insert into cr_superior_gp
select   tc_tipo,
         @w_spid
from     cob_custodia..cu_tipo_custodia
where    tc_tipo_superior = @w_valor
order by tc_tipo

insert into cr_superior_gp_esp
select   tc_tipo,
         @w_spid
from     cob_custodia..cu_tipo_custodia
where    tc_tipo_superior = @w_garesp
order by tc_tipo

insert into cr_superior_gp_esp
select   A.tc_tipo,
         @w_spid
from     cob_custodia..cu_tipo_custodia A,
         cr_superior_gp_esp B
where    A.tc_tipo_superior = tipo
and      B.sesion           = @w_spid
order by A.tc_tipo

select @w_tipo_tr = tr_tipo, @w_deudor_cus = tr_cliente
from cob_credito..cr_tramite
where tr_tramite = @i_tramite

--TABLA PARA GARANTIAS FAG

delete cr_tmp_garfag
where tg_sesion = @w_spid

insert into cr_tmp_garfag
select tc_tipo,@w_spid
from cob_custodia..cu_tipo_custodia
where tc_tipo = @w_valor
union
select tc_tipo, @w_spid
from cob_custodia..cu_tipo_custodia
where tc_tipo_superior = @w_valor
union
select tc_tipo ,@w_spid
from cob_custodia..cu_tipo_custodia
where tc_tipo_superior in (select tc_tipo
                           from  cob_custodia..cu_tipo_custodia
                           where  tc_tipo_superior = @w_valor)                           

/* Codigos de Transacciones */
if (@t_trn <> 21028 and @i_operacion = 'I') or
   (@t_trn <> 21128 and @i_operacion = 'U') or
   (@t_trn <> 21228 and @i_operacion = 'D') or
   (@t_trn <> 21428 and @i_operacion = 'S') or
   (@t_trn <> 21528 and @i_operacion = 'Q') or
   (@t_trn <> 21048 and @i_operacion = 'C')
   begin
      /* tipo de transaccion no corresponde */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101006
      return 1
   end

/*REQ 0212 BANCA RURAL*/
--Codigo de garantia que se esta anexando al tramite

select @w_tipo_gar = cu_tipo from cob_custodia..cu_custodia
where cu_codigo_externo = @i_garantia 

--Codigo PADRE de garantia que se esta anexando al tramite

select @w_tipo_gar_padre = tc_tipo_superior
from cob_custodia..cu_tipo_custodia
where tc_tipo = @w_tipo_gar 

select @w_comparte_nue = ca_comparte
from cob_custodia..cu_colat_adic
where ca_codigo_cust = @w_tipo_gar

-- Selecionar el codigo de destino economico del tramite y el tipo de productor
select @w_destino_tram = tr_destino, @w_tipo_productor = tr_tipo_productor
from cob_credito..cr_tramite
where tr_tramite = @i_tramite

if @w_tipo_gar_padre  = @w_cod_gar_fag
begin   
  select @w_es_colateral = 'S'
  if not exists(select 1 from cobis..cl_tabla a, cobis..cl_catalogo b
                where a.tabla = 'cr_destino_fag'
                and b.tabla = a.codigo
                and b.codigo = @w_destino_tram
                and b.estado = 'V')
    begin
 
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2110296
      return 2110296
    end
end       
else
begin
if @w_tipo_gar_padre  = @w_cod_gar_usaid --or @w_tipo_gar_padre  = @w_cod_gar_fng
  begin    
  select @w_es_colateral = 'S'
  if exists(select 1 from cobis..cl_tabla a, cobis..cl_catalogo b
            where a.tabla = 'cr_destino_fag'
            and b.tabla = a.codigo
            and b.codigo = @w_destino_tram
            and b.estado = 'V')
    begin
 
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2110261
      return 2110261
    end
 end
end 
  
/*FIN REQ 0212*/

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S'
begin

   select
   @w_tramite         = gp_tramite,
   @w_garantia        = gp_garantia,
   @w_clasificacion   = gp_clasificacion,
   @w_exceso          = gp_exceso,
   @w_monto_exceso    = gp_monto_exceso,
   @w_deudor          = gp_deudor,
   @w_clase           = gp_abierta,
   @w_estado          = gp_est_garantia,
   @w_porcentaje      = gp_porcentaje,
   @w_valor_resp      = gp_valor_resp_garantia,
   @w_fecha_mod       = gp_fecha_mod
   from  cob_credito..cr_gar_propuesta
   where gp_tramite   = @i_tramite
   and   gp_garantia  = @i_garantia

   if @@rowcount > 0
      select @w_existe = 1
   else
      select @w_existe = 0

   if @i_numero_operacion is not null
   begin
      select  @i_tramite    = op_tramite,
              @w_estado_obl = op_estado,
              @w_moneda_op  = op_moneda
      from    cob_cartera..ca_operacion
      where   op_banco = @i_numero_operacion

      select @i_tramite = isnull(@i_tramite ,0)
   end

  select @w_monto = case tr_moneda
              when   0 then tr_monto
              else   tr_montop
              end
   from     cr_tramite x
   where tr_tramite  = @i_tramite

   if @w_estado_obl not in (0,99)
   begin
      select @w_cotizacion = ct_valor
      from   cob_conta..cb_cotizacion
      where  ct_moneda = @w_moneda_op
      and   ct_fecha  between dateadd(dd,-15,@w_today) and @w_today
      order by ct_fecha asc

      select @w_monto  = case do_moneda when 0 then do_saldo_cap else do_saldo_cap * @w_cotizacion end
      from   cr_dato_operacion
      where  do_tipo_reg                 = 'D'
      and    do_codigo_producto          = 7
      and    do_numero_operacion_banco   = @i_numero_operacion
   end
   
   /*Salarios minimos con respecto al monto de la obligación*/
   
   select @w_monto_SMV = @w_monto / @w_SMV
   
end

   /**************************************************/
   /*Req 00212 - Validacion de cobertura comision FAG*/
   /**************************************************/

   select @w_tipo_productor = en_casilla_def
   from cobis..cl_ente
   where en_ente = @i_deudor

   select @w_tipo_cust            = cu_tipo,
          @w_porcentaje_cobertura = cu_porcentaje_cobertura --WLO_S586466
   from cob_custodia..cu_custodia
   where cu_codigo_externo = @i_garantia

   select @w_porc_desde = pc_porc_desde, @w_porc_hasta = pc_porc_hasta
   from cob_credito..cr_param_cob_gar
   where pc_tipo_gar = @w_tipo_cust and pc_tipo_prod = @w_tipo_productor
   and @w_monto_SMV between pc_monto_desde and pc_monto_hasta     
   
   if @i_porcentaje_resp > @w_porc_hasta or @i_porcentaje_resp < @w_porc_desde 
    begin
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2110262
      return 2110262
    end
   
   /********************************************/
   /* FIN Validacion de cobertura comision FAG */
   /********************************************/
     
/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin

   if @i_tramite is NULL
      or @i_garantia is NULL
      or @i_clasificacion is NULL
   begin
      /* Campos NOT NULL con valores nulos */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101001
      return 2101001
   end

   /***********************************************************************************************************************/
   /* LLS43246. Validacion para Adjuntar garantia especial segun el monto del tramite vs el parametro creado para tal fin */
   /***********************************************************************************************************************/
   select @w_valor_monto = pa_money
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CRE'
   and   pa_nemonico = 'SALMIN'

   if @w_valor_monto is null
   begin
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2110263
      return 2110263
   end

   if @w_monto <= @w_valor_monto  --Monto del tramite es inferior al monto del parametro
   begin

      if exists(select 1
                from cob_custodia..cu_custodia
                where cu_codigo_externo = @i_garantia
                and   cu_tipo           in (select codigo_sib from cob_credito..cr_corresp_sib where tabla = 'T65'))
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110264
         return 2110264
      end
   end

/* validacion de los montos */

if exists (select 1 from #calfng where tipo = @w_tipo_gar) 
begin

    select @w_monto_tmp = @w_monto 
    select @w_valor_monto_tmp = @w_valor_monto
    select @w_monto_SMV_tmp = cast(@w_monto_tmp / @w_valor_monto_tmp as float)

    exec @w_error = cob_cartera..sp_matriz_valor
      @i_matriz    = 'VAL_FNG',
      @i_fecha_vig = @w_fecha_proceso,
      @i_eje1      = @w_tipo_gar,
      @i_eje2      = @w_monto_SMV_tmp,
      @i_eje3      = @w_destino_tram,
      @o_valor     = @w_valida_ok out,
      @o_msg       = @w_msg   out

      if @w_error <> 0
      begin
        print 'Se presenta error en la parametrizacion de las matrices VAL_FNG'
        exec cobis..sp_cerror
        @t_debug  = @t_debug,
        @t_file   = @t_file,
        @t_from   = @w_sp_name,
        @i_num    = @w_error
      end

    --print ' valor es ' + cast(@w_valida_ok as varchar)
    if @w_valida_ok = 0
    begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110265
         return 2110265

    end
  end      
   /*************************************************************************/
   /* Validacion tramites de Reestructuracion: No se debe Agregar Garantias */
   /*************************************************************************/

   if @w_tipo_tr = 'E' and @i_operacion = 'I'
   begin
      
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2110266
      return 2110266
   end
   
   if @i_deudor is null  
      select @i_deudor = @w_deudor_cus

   if exists(select 1
             from cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia x, cob_custodia..cu_tipo_custodia y
             where gp_tramite         = @i_tramite
             and   gp_garantia        = cu_codigo_externo
             and   cu_tipo            = x.tc_tipo
             and   cu_estado          <> 'A'  --acelis mayo 29 2012
             and   x.tc_tipo_superior = y.tc_tipo
             and   y.tc_tipo_superior = '2000'
             and   cu_tipo not in (select ca_codigo_cust from cob_custodia..cu_colat_adic where ca_comparte = 'S'))--req343
             and   @i_operacion = 'I'
   begin

      --Buscar de que tipo es la garantia que anexo, si es de las 2000 no debe asociarse
      if exists(select 1
                from cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia x, cob_custodia..cu_tipo_custodia y
                where cu_codigo_externo  = @i_garantia
                and   cu_tipo            = x.tc_tipo
                and   x.tc_tipo_superior = y.tc_tipo
                and   y.tc_tipo_superior = '2000'
                and   cu_estado          in ('F', 'P', 'V', 'X'))   
      begin

         select @w_mensaje = 'No se permite anadir garantias colaterales porque ya tiene una colateral asociada al tramite '
 
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110267
         return 2110267
      end
   end   
   
   /**************************/
   /* INI Validaciones USAID */
   /**************************/

   select @w_fecha_cotizacion = max(ct_fecha)
   from cob_conta..cb_cotizacion, cob_custodia..cu_convenios_garantia
   where ct_moneda = cg_moneda
   and   cg_moneda <> 0
   and   cg_estado = 'V'

   select @w_valor_cotiz = ct_valor 
   from cob_conta..cb_cotizacion, cob_custodia..cu_convenios_garantia
   where ct_moneda = cg_moneda
   and   ct_fecha  = @w_fecha_cotizacion
   and   cg_moneda <> 0
   and   cg_estado = 'V'

   select @w_valor_actual = null, @w_valor_disponible = null
  
   select tipo = cg_tipo_garantia, disponible = cg_saldo_disponible * @w_valor_cotiz, moneda = cg_moneda
   into #temporal
   from cob_custodia..cu_convenios_garantia
   where cg_estado = 'V'

   select @w_usaid = 0

   select @w_usaid = 1
   from cob_custodia..cu_custodia, #temporal
   where cu_codigo_externo = @i_garantia
   and   cu_tipo           = tipo

   if @w_usaid = 1
   begin 

      select @w_valor_actual = cu_valor_actual, @w_valor_disponible = disponible
      from cob_custodia..cu_custodia, #temporal
      where cu_codigo_externo = @i_garantia
      and   cu_tipo           = tipo

      --Sumar las garantias de los tramites del dia
      select @w_valor_reservado = isnull(sum(cu_valor_actual),0)
      from cob_cartera..ca_operacion, cob_credito..cr_tramite, cob_credito..cr_gar_propuesta,
           cob_custodia..cu_custodia
      where op_estado    in (99,0)
      and   op_tramite   = tr_tramite
      and   tr_estado    not in ('Z')
      and   op_tramite   = gp_tramite
      and   gp_garantia  = cu_codigo_externo
      and   gp_fecha_mod = @w_fecha_proceso
      and   cu_tipo      in (select tipo from #temporal)
      and   gp_procesado is null      

      if @w_valor_disponible is null or @w_valor_disponible <= 0
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110268
         return 2110268
      end

      if @w_valor_actual is null or @w_valor_actual = 0
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110269
         return 2110269
      end

      if @w_valor_actual + @w_valor_reservado > @w_valor_disponible
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110270
         return 2110270
      end

      --Creditos desembolsados con garantias USAID del cliente
      select @w_valor_desembolsado = sum(isnull(op_monto,0))
      from cob_cartera..ca_operacion(nolock), cob_credito..cr_tramite(nolock), cob_credito..cr_gar_propuesta(nolock),
           cob_custodia..cu_custodia(nolock)
      where op_estado    <> 6
      and   op_cliente   = @i_deudor
      and   op_tramite   = tr_tramite
      and   tr_estado    not in ('Z')
      and   op_tramite   = gp_tramite
      and   gp_garantia  = cu_codigo_externo
      and   cu_tipo      in (select tipo from #temporal)

      select @w_param_musaid = pa_int
      from cobis..cl_parametro
      where pa_nemonico = 'MUSAID'
      and   pa_producto = 'GAR'

      if @w_param_musaid is null
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110271
         return 2110271
      end
 
      if @w_valor_desembolsado > (@w_SMV * @w_param_musaid)
      begin
         select @w_mensaje = 'El valor actual de la garantia excede el  valor del parametro <MUSAID> para USAID '
 
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110272
         return 2110272
      end

      --Validacion Fecha Fin de Contrato USAID
      select @w_param_fusaid = pa_datetime
      from cobis..cl_parametro
      where pa_nemonico = 'FUSAID'
      and   pa_producto = 'GAR'

      if @w_param_fusaid is null
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110274
         return 2110274
      end

      if @w_fecha_proceso > @w_param_fusaid 
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110275
         return 2110275
      end
   end

   select @w_parametro1 = 0
   select @w_parametro2 = 0

   --Revision existencia de parametrizacion Municipios-Tipo_Garantia
   if exists(select 1 from cob_custodia..cu_gar_municipio, cob_custodia..cu_custodia where cu_codigo_externo = @i_garantia and cu_tipo = gm_tipo)
      select @w_parametro1 = 1

   --Revision existencia de parametrizacion Actividades-Tipo_Garantia
   if exists(select 1 from cob_custodia..cu_gar_actividad, cob_custodia..cu_custodia where cu_codigo_externo = @i_garantia and cu_tipo = ga_tipo)
      select @w_parametro2 = 1

   --Existe Parametrizacion Municipios-TipoGarantia
   if @w_parametro1 = 1 begin

      select @w_tipo_cust = cu_tipo
      from cob_custodia..cu_custodia
      where cu_codigo_externo = @i_garantia

      select 
      @w_depto_neg  = di_provincia,
      @w_ciudad_neg = di_ciudad
      from cobis..cl_direccion  
      where di_ente = @i_deudor
      and   di_tipo = @w_dir_neg

      if not exists (select 1 
      from cob_custodia..cu_gar_municipio
      where  gm_tipo   = @w_tipo_cust
      and    gm_depto  = @w_depto_neg
      and    gm_ciudad = @w_ciudad_neg)

      begin

         select @w_mensaje = 'La Ciudad de Negocio del Deudor No esta Parametrizada (Municipios-TipoGarantia) '
 
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110276
         return 2110276
      end
   end

   --Existe Parametrizacion Actividades-TipoGarantia
   if @w_parametro2 = 1 begin

      select @w_tipo_cust = cu_tipo
      from cob_custodia..cu_custodia
      where cu_codigo_externo = @i_garantia

      select 
      @w_actividad = en_actividad
      from cobis..cl_ente
      where en_ente = @i_deudor

      if not exists (select 1 
      from cob_custodia..cu_gar_actividad
      where  ga_tipo       = @w_tipo_cust
      and    ga_actividad  = @w_actividad)

      begin

         select @w_mensaje = 'La actividad economica del deudor no corresponde al tipo de garantia asignado '

         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2110277
         return 2110277
      end
   end

   /**************************/
   /* FIN Validaciones USAID */
   /**************************/
end

--PQU Problemas integración
if exists(select 1
          from cob_credito..cr_gar_propuesta
          where gp_garantia = @i_garantia AND gp_tramite = @i_tramite) AND @i_operacion ='I'
    SELECT @i_operacion ='U'
--fin PQU

/* Insercion del registro */
/**************************/
if @i_operacion = 'I'
begin

   if @w_existe = 1
   begin
       /* Registro ya existe */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101002
      return 2101002
    end

   --LPO REQ. 266 Paquete 2 INICIO
   if @i_clase = 'C' --Garantia Cerrada
   begin
      if exists (select 1
                 from cr_gar_propuesta with (nolock),
                      cob_custodia..cu_custodia with (nolock)
                 where cu_codigo_externo = gp_garantia
                   and gp_garantia       = @i_garantia
                   and cu_estado         not in ('C','E','Z')
                )
      begin
         print 'Tipo de Garantia Cerrada, por favor escoja otra garantia.'
         /* Error en insercion  de gar_propuesta */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 1912030
         return 1912030
      end
   end
   --Codigo padre de todas las Garantias Colaterales
   select  @w_cod_colateral = pa_char
   from    cobis..cl_parametro
   where   pa_producto = 'GAR'
   and     pa_nemonico = 'COFIAD'
   
   if  @w_cod_colateral is null     
   select @w_cod_colateral ='2000'
   
   select @w_colateral = null
   
   select @w_colateral = ltrim(rtrim(tc_descripcion)),
          @w_tipo_gar_ant = cu_tipo
   from cr_gar_propuesta with (nolock),
        cob_custodia..cu_custodia with (nolock),
        cob_custodia..cu_tipo_custodia with (nolock)
   where cu_codigo_externo = gp_garantia
     and cu_estado         <> 'A' --acelis cc 272 mayo 2012
     and gp_tramite        = @i_tramite
     and tc_tipo           = cu_tipo
     and cu_tipo in (select tc_tipo
                     from cob_custodia..cu_tipo_custodia
                     where tc_tipo_superior in (select tc_tipo
                                                from cob_custodia..cu_tipo_custodia
                                                where tc_tipo_superior = @w_cod_colateral)
                     )
   
   select @w_comparte_ant = ca_comparte
   from cob_custodia..cu_colat_adic
   where ca_codigo_cust = @w_tipo_gar_ant

   if @w_colateral is not null
   begin
      select tc_tipo as tipo_sub 
      into #colateral
      from cob_custodia..cu_tipo_custodia
      where tc_tipo_superior = @w_cod_colateral
      
      if exists (select 1 from #colateral where tipo_sub = @w_tipo_gar_padre)
      begin
         print 'Credito esta respaldado con garantia ' + @w_colateral + ' no se puede asignar esta garantia.'
         /* Error en insercion  de gar_propuesta */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 1912030
         return 1912030      
      end
   end
 if not exists (select 1
                  from cob_custodia..cu_cliente_garantia with (nolock)
                  where /*cg_ente         = @i_deudor --PQU integraci?n, Yo puedo asociar garant?as de otros deudores
                  and*/ cg_codigo_externo = @i_garantia
                  --and cg_tipo_garante   in ('A','J','C')
                  )
   begin
      /* Cliente no es deudor o amparado */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2103052
      return 1
   end

   if exists (select 1
              from  cob_credito..cr_gar_propuesta with (nolock),
              cob_custodia..cu_custodia with (nolock),
              cob_credito..cr_tramite with (nolock)
              where gp_garantia       = @i_garantia
              and   cu_tipo           in (select tipo from cr_superior_gp_esp
                                          where sesion =  @w_spid)
              and   cu_codigo_externo = gp_garantia
              and   tr_tramite        = gp_tramite
              and   tr_estado         in ('A','T','D','P'))
   begin
     /* Error en insercion de registro */
     exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = @w_sp_name,
     @i_num   = 2108030
     return 2108030
   end

   insert into cr_tipo_actual_gp
   select cu_tipo , @w_spid
   from    cob_credito..cr_gar_propuesta,
   cob_custodia..cu_custodia,
   cr_superior_gp_esp A
   where gp_garantia = cu_codigo_externo
   and   A.tipo      = cu_tipo
   and   A.sesion    = @w_spid
   and   gp_tramite  = @i_tramite
   and   (gp_est_garantia <> 'C' and gp_est_garantia <> 'A')
   and   cu_estado   not in ('A','C','X','K')

   if exists ( select  1
   from    cr_tipo_actual_gp
   where   sesion = @w_spid)
   begin
      if exists (select 1
      from    cob_custodia..cu_custodia
      where   cu_codigo_externo = @i_garantia
      and     cu_estado not in ('A','C','X','K')
      and     cu_tipo in (select tipoa from cr_tipo_actual_gp where sesion = @w_spid))
      begin
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1912120
          return 1912120
     end
   end
   --emg May-24-01 No permitir asignar garantias a tramites si estado es X:vigente por Cancelar
   if @i_estado <> 'X'
   begin
     /* Fin Nueva Validacion*/

     --VALIDAR SI TIENE RUBRO COMISION FAG NO SE PUEDE ATAR TRAMITE
     select @w_control = 'S'
     select @w_tipo_gar = cu_tipo,
            @w_val_actual = cu_valor_actual
     from cob_custodia..cu_custodia
     where cu_codigo_externo = @i_garantia

     if exists (select tg_tipo from cr_tmp_garfag where tg_sesion = @w_spid and tg_tipo = @w_tipo_gar)
     begin
       if exists (select 1
                  from cr_tramite, cr_corresp_sib
                  where tr_tramite = @i_tramite
                  and codigo=tr_destino
                  and tabla = 'T13')
          select @w_control = 'N'
     end
     
     select tipo = tc_tipo
     into #fag
     from cob_custodia..cu_tipo_custodia
     where tc_tipo_superior = @w_fag
     
     if not exists (select 1 from #fag where tipo = @w_tipo_cust) 
     begin
        select @i_porcentaje_resp = round(@w_val_actual * (isnull(@w_porcentaje_cobertura,0) / @w_monto),2) --WLO_S586466
        select @i_valor_resp_garantia = @w_val_actual * (isnull(@w_porcentaje_cobertura,0) / 100)           --WLO_S586466
     end
     
    --GFP 16/12/2021 Valida si el porcentaje de garantia es distinto de null
    /*PQU 01/02/2022 esta validación no aplica 
    if @w_porcentaje_cobertura is not null
    begin
      EXEC @w_error = cob_custodia..sp_validacion_cobertura_gar
        @t_trn                = 19793,
        @i_operacion          = 'V',
        @i_tramite            = @i_tramite,
        @i_garantia           = @i_garantia

      if @w_error <> 0
      begin
         exec cobis..sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = @w_error

         return @w_error
      end
    end
    */  --fin PQU

     if @w_control = 'S'
     begin
        begin tran
        insert into cr_gar_propuesta(
        gp_tramite, gp_garantia, gp_clasificacion,
        gp_exceso, gp_monto_exceso, gp_abierta,
        gp_deudor, gp_est_garantia, gp_porcentaje,
        gp_valor_resp_garantia, gp_fecha_mod, gp_previa )
        values (
        @i_tramite, @i_garantia, @i_clasificacion,
        @i_exceso, @i_monto_exceso, @i_clase,
        @i_deudor, @i_estado, @i_porcentaje_resp,
        @i_valor_resp_garantia, @s_date, @i_previa )

        if @@error <> 0
        begin
           /* Error en insercion de registro */
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 2103001
           return 2103001
        end

        /* Transaccion de Servicio */
        /***************************/
        if @i_canal <> 2
        begin
         insert into ts_gar_propuesta
         values (
         @s_ssn, @t_trn, 'N',
         @s_date, @s_user, @s_term,
         @s_ofi,'cr_gar_propuesta', @s_lsrv,
         @s_srv, @i_tramite, @i_garantia,
         @i_clasificacion, @i_exceso,@i_monto_exceso,
         @i_clase, @i_deudor,@i_estado, @i_porcentaje_resp,
         @i_valor_resp_garantia, @w_fecha_mod, null, null )

         if @@error <> 0
         begin
            /* Error en insercion de transaccion de servicio */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2103003
            return 2103003
         end
        end
        commit tran
           
        --truncate table #gp_previa 
     end
     else
     begin
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 2108046
          return 2108046
     end

   end
   else --Estado diferente de X emg
       begin
       /* No se puede adjuntar garantias en estado X */
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name,
       @i_num   = 2103051
       return 2103051
   end

end

/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin
   if @w_existe = 0
   begin
      /* Registro a actualizar no existe */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2105002
      return 2105002
   end

   --INI WLO_S586466
   select @w_tipo_gar   = cu_tipo,
          @w_val_actual = cu_valor_actual
   from   cob_custodia..cu_custodia
   where  cu_codigo_externo = @i_garantia
   
   select @i_porcentaje_resp = round(@w_val_actual * (isnull(@w_porcentaje_cobertura,0) / @w_monto),2)
   select @i_valor_resp_garantia = @w_val_actual * (isnull(@w_porcentaje_cobertura,0) / 100)
   --FIN WLO_S586466

   begin tran

      if @i_modo = 0
      begin
        update cob_credito..cr_gar_propuesta  set
        gp_porcentaje = @i_porcentaje_resp, --SBU: 06/abr/2000
        gp_valor_resp_garantia = @i_valor_resp_garantia
        where  gp_tramite = @i_tramite
        and  gp_garantia = @i_garantia

        if @@error <> 0
        begin
           /* Error en actualizacion de registro */
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 2105001
           return 2105001
        end
      end
      else
      begin
        update cob_credito..cr_gar_propuesta  set
        gp_clasificacion = @i_clasificacion,
        gp_exceso = @i_exceso,
        gp_monto_exceso = @i_monto_exceso,
        gp_porcentaje = @i_porcentaje_resp,
        gp_valor_resp_garantia = @i_valor_resp_garantia,
        gp_fecha_mod = @w_fecha_mod
        where  gp_tramite = @i_tramite
        and  gp_garantia = @i_garantia

        if @@error <> 0
        begin
           /* Error en actualizacion de registro */
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 2105001
           return 2105001
        end
      end

      /* Transaccion de Servicio */
      /***************************/
      if @i_canal <> 2
      begin
         insert into ts_gar_propuesta
         values (
         @s_ssn, @t_trn, 'P',
         @s_date, @s_user, @s_term,
         @s_ofi, 'cr_gar_propuesta',@s_lsrv,@s_srv,
         @w_tramite, @w_garantia, @w_clasificacion,
         @w_exceso, @w_monto_exceso, @w_clase,
         @w_deudor, @w_estado, @w_porcentaje,
         @w_valor_resp, @s_date, 'N',null )
         
         
         if @@error <> 0
         begin
            /* Error en insercion de transaccion de servicio */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2103003
            return 2103003
         end
      end
      /* Transaccion de Servicio */
      /***************************/

      if @i_modo = 0  and @i_canal <> 2      --SBU: 11/may/2000
      begin
        insert into ts_gar_propuesta
        values (
        @s_ssn, @t_trn, 'A',
        @s_date, @s_user, @s_term,
        @s_ofi,'cr_gar_propuesta', @s_lsrv,
        @s_srv, @i_tramite, @i_garantia,
        @w_clasificacion, @w_exceso, @w_monto_exceso,
        @w_clase, @w_deudor,@w_estado, @i_porcentaje_resp,
        @i_valor_resp_garantia, @s_date, NULL, null )


        if @@error <> 0
        begin
           /* Error en insercion de transaccion de servicio */
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 2103003
           return 2103003
        end
      end
      else
      begin
        if @i_canal <> 2
        begin
           insert into ts_gar_propuesta
           values (
           @s_ssn, @t_trn, 'A',
           @s_date, @s_user, @s_term,
           @s_ofi,'cr_gar_propuesta', @s_lsrv,
           @s_srv, @i_tramite, @i_garantia,
           @i_clasificacion, @i_exceso, @i_monto_exceso,
           @w_clase, @w_deudor,@w_estado, @i_porcentaje_resp,
           @i_valor_resp_garantia, @s_date, NULL, null )
           
           if @@error <> 0
           begin
              /* Error en insercion de transaccion de servicio */
              exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 2103003
              return 2103003
           end
        end
      end

   commit tran
end

/* Eliminacion de registros */
/****************************/

if @i_operacion = 'D'
begin
   if @w_existe = 0
   begin
      /* Registro a eliminar no existe */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1907002
      return 1907002
   end
   ---113499 VAlidar si es tipo de tramite de Reestructuracion para quenopermita ELiminar Garantias
   if @w_tipo_tr = 'E'
   begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 1912121
           return 1912121
   end
   ---113499

   begin tran

   if @w_estado = 'F'
   begin
      exec @w_return = cob_custodia..sp_cambios_estado
      @s_user           = @s_user,
      @s_date           = @s_date,
      @s_term           = @s_term,
      @s_ofi            = @s_ofi,
      @i_operacion      = 'I',
      @i_estado_ini     = 'F',
      @i_estado_fin     = 'X',
      @i_codigo_externo = @i_garantia,
      @i_banderafe      = 'S',
      @i_tramite        = @i_tramite
      
      if @w_return <> 0
      begin
         rollback
         return @w_return
      end
   end

   delete cob_credito..cr_gar_propuesta
   where gp_tramite  = @i_tramite
   and   gp_garantia = @i_garantia
   
   delete cob_cartera..ca_rubro_colateral
   where ruc_tramite = @i_tramite
   and   (ruc_tipo_gar = @w_tipo_gar or ruc_tipo_gar is null)
   
   if @@error <> 0
   begin
      /*Error en eliminacion de registro */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2107001
      return 2107001
   end

   /* Transaccion de Servicio */
   /***************************/
   if @i_canal <> 2
   begin
      insert into ts_gar_propuesta
      values
      (@s_ssn,@t_trn,'B',         @s_date,          @s_user,   @s_term,        @s_ofi,   'cr_gar_propuesta', @s_lsrv,  @s_srv,
      @w_tramite,   @w_garantia, @w_clasificacion, @w_exceso, @w_monto_exceso,@w_clase, @w_deudor,          @w_estado,@w_porcentaje,
      @w_valor_resp,@w_fecha_mod,NULL, null)
      
      if @@error <> 0
      begin
         /* Error en insercion de transaccion de servicio */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2103003
         return 2103003
      end
   end

   /*elimino de otros tramites si es abierta y propuesta*/

   if (@w_estado = 'P' and @w_clase = 'A') begin
      -- elimino todas las excepciones asociadas a esta garantÝa en este tramite
      delete cob_credito..cr_excepciones
      where ex_tramite = @i_tramite
      and   ex_garantia = @i_garantia
   end

   if @w_estado = 'F'
   begin
      exec @w_return = cob_custodia..sp_cambios_estado
      @s_user           = @s_user,
      @s_date           = @s_date,
      @s_term           = @s_term,
      @s_ofi            = @s_ofi,
      @i_operacion      = 'I',
      @i_estado_ini     = 'F',
      @i_estado_fin     = 'X',
      @i_codigo_externo = @i_garantia,
      @i_banderafe      = 'S',
      @i_tramite        = @i_tramite
      
      if @w_return <> 0
      begin
         rollback
         return @w_return
       end
    end
    commit tran
end

/**** Search ****/
/****************/

if @i_operacion = 'S'
begin

   select @i_garantia = isnull(@i_garantia, ' ')

   if @i_modo = 0
   begin
      set rowcount 1
      SELECT
      'Tramite'         = gp_tramite,
      'Garantia'        = gp_garantia,
      'Clasificacion'   = gp_clasificacion,
      'Cubre Exceso'    = gp_exceso,
      'Monto Exceso'    = gp_monto_exceso,
      'Caracter'        = gp_abierta,
      'Estado'          = gp_est_garantia,
      'Avaluador'       = ' ',
      'Propietario'     = substring(convert(char(10), cg_ente) + cg_nombre, 1, 64),
      'Porcentaje'      = gp_porcentaje,
      'Valor respaldo'  = gp_valor_resp_garantia
      from cr_gar_propuesta G left outer join cob_custodia..cu_cliente_garantia 
      on    cg_codigo_externo = G.gp_garantia 
      --and   cg_tipo_garante  in ('J','C')
      where gp_tramite        = @i_tramite
      and   gp_est_garantia not in ('A','C')
      
    set rowcount 0
   end
   if @i_modo = 1
    begin    
      select 
      'Estado'          = c.cu_estado,
      'Est. Credito'    = c.cu_estado,          -- PMO Necesario para pintar estado en asociación de garantias
      'Numero'          = c.cu_codigo_externo,
      'Tipo'            = tc_descripcion,  --PQU este orden solo cambié porque estaban mapeando mal en la UF de asociación de garantías
      'Descripcion'     = tc_tipo,         --PQU este orden solo cambié porque estaban mapeando mal en la UF de asociación de garantías  
      'Clase'           = c.cu_abierta_cerrada,
      'Cliente'         = case when tc_tipo=@w_tipo_personal --DMO SE VALIDA QUE DEVUELVA GARANTE O CLIENTE SEGUN LA GARANTIA
                            then substring(convert(varchar(10),cu_garante) +  ' ' + (select en_nomlar from  cobis..cl_ente where en_ente = cu_garante) , 1, 64) 
                            else substring(convert(varchar(10),a.en_ente) +  ' ' + a.en_nomlar, 1, 64) end,
      'Valor Actual'    = c.cu_valor_actual,
      'Moneda'          = convert(varchar(2),c.cu_moneda),
      'MonedaValue'     = 0.00,
      'Valor inicial'   = c.cu_valor_inicial,
      'mrc'             = 0.00,
      'mrcValue'        = 0.00,
      'LastInspeccion'  = convert(varchar(10),c.cu_fecha_insp,103),
      'account'         = cu_plazo_fijo,
      'accountType'     = '',
      'depreciaPercent' = tc_porcentaje,
      'location'        = '',
      'identification'  = substring(convert(char(10), cg_ente) + cg_nombre, 1, 64),
      'policy'          = CASE c.cu_posee_poliza when 'S' then @w_si else @w_no end,
      'Fecha Avaluo'    = c.cu_fecha_avaluo,
      'DirecionPrenda'  = c.cu_direccion_prenda,
      '95139'           = 0,
      '95140'           = 0,
      '15234'           = cu_descripcion,
      '95141'           = cu_fecha_const,
      '95142'           = (select cu_fecha_modificacion from cob_custodia..cu_custodia where cu_estado='C' and cu_codigo_externo=c.cu_codigo_externo),
      '95143'           = 0,
      '95144'           = getdate(),
      '95145'           = case when tc_tipo=@w_tipo_personal then @w_s else @w_n end --INDICA SI ES GARANTIA PERSONAL
      from cob_credito..cr_gar_propuesta G left outer join cob_custodia..cu_cliente_garantia
      on    cg_codigo_externo   = G.gp_garantia,
      cob_custodia..cu_custodia c, cobis..cl_ente a,
      cob_custodia..cu_tipo_custodia
      where gp_tramite          = @i_tramite
      and   gp_garantia         > @i_garantia
      and   gp_garantia         = cu_codigo_externo
      and   a.en_ente           = gp_deudor
      and   cg_principal        = 'S' --DMO SE AÑADE VALIDACION PARA QUE NO EXISTA DUPLICIDAD
      and   cu_tipo     = tc_tipo
      and   c.cu_estado       not in ('A','C')
      order by gp_garantia

      if (@@rowcount = 0 and @i_canal = 3)
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 1901005
         return 1901005
      end

    end
   if @i_modo = 2
    begin
      select
      'Estado'         = c.cu_estado,
      'Est. Credito'   = NULL,--c.cu_estado_credito,
      'Caracter'       = c.cu_abierta_cerrada,
      'Numero'         = c.cu_codigo_externo,
      'Descripcion'    = substring(c.cu_descripcion, 1, 64),
      'Cliente'        = substring(convert(varchar(10),a.en_ente) +  ' ' + a.en_nomlar, 1, 64),
      'Moneda'         = c.cu_moneda,
      'Valor inicial'  = NULL,--isnull(c.cu_valor_refer_comis,c.cu_valor_inicial),
      'Valor Actual'   = NULL,--isnull(c.cu_valor_refer_comis,c.cu_valor_actual),
      '% Cobertura'    = gp_porcentaje,
      'Valor Respaldo' = gp_valor_resp_garantia,
      'Fecha Avaluo'   = convert(varchar(10),c.cu_fecha_insp,103),
      'Avaluador'      = ' ',
      ' '              = ''
      from  cr_gar_propuesta G, cob_custodia..cu_custodia c, cobis..cl_ente a
      where gp_tramite  =  @i_tramite
      and   gp_garantia >  @i_garantia
      and   gp_garantia =  cu_codigo_externo
      and   a.en_ente   =  gp_deudor
      and   c.cu_estado not in ('A','C')
      order by gp_garantia
    end
end

/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if @w_existe = 1
         select
              @w_tramite,
              @w_garantia,
              @w_clasificacion,
              @w_exceso,
              @w_monto_exceso,
              @w_clase,
              @w_deudor,
              @w_estado,
              @w_porcentaje,
              @w_valor_resp
    else
       begin
          /*Registro no existe */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 2101005
          return 2101005
       end
end

/**** Control de cobertura ****/
/******************************/
if @i_operacion = 'C'
begin

 /*************************************************************************/
   /* Validacion tramites de Reestructuracion: No se debe Agregar Garantias */
   /*************************************************************************/

   select @w_tipo_tr = tr_tipo, @w_deudor_cus = tr_cliente
   from cob_credito..cr_tramite
   where tr_tramite = @i_tramite

   if @w_tipo_tr = 'E'
   begin
      
      if @i_crea_ext <> 'S'
      begin
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 2110266
          return 2110266
      end
      else
      return 2110266
   end

   exec @w_error = cob_cartera..sp_matriz_garantias
   @s_date              = @s_date,
   @i_tramite           = @i_tramite,
   --@i_garantia          = @i_garantia,
   @i_porcentaje_resp   = @i_porcentaje_resp,
   @i_tipo_periodo      = 'P',
   @i_tipo_garantia     = @i_tipo_garantia,
   @i_crea_ext          = @i_crea_ext,
   @o_valor             = @w_factor out,
   @o_msg               = @w_msg out    
   
   if @w_error <> 0 begin
     if @i_crea_ext <> 'S'
      begin
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = @w_error
          return 1      
      end
      else
        return @w_error
   end

   select @o_retorno = @w_factor

   insert into cr_tramites_gp
          (tramite, operacion, moneda,
           porcentaje_resp, valor_resp,sesion) --ZR
   select  tr_tramite,
           tr_numero_op_banco,
           tr_moneda,
           gp_porcentaje,
           isnull(gp_valor_resp_garantia,0),
           @w_spid
   from cr_tramite, cr_gar_propuesta
   where tr_tramite = gp_tramite
   and   tr_estado   in ('A','T','D','P','N')
   and   gp_garantia =  @i_garantia
   and   gp_tramite  <> @i_tramite
end

return 0

go
