/************************************************************************/
/*  Archivo:                tramite_cca.sp                              */
/*  Stored procedure:       sp_tramite_cca                              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*     Este programa es parte de los paquetes bancarios que son         */
/*     comercializados por empresas del Grupo Empresarial Cobiscorp,    */
/*     representantes exclusivos para comercializar los productos y     */
/*     licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida   */
/*     y regida por las Leyes de la República de España y las           */
/*     correspondientes de la Unión Europea. Su copia, reproducción,    */
/*     alteración en cualquier sentido, ingeniería reversa,             */
/*     almacenamiento o cualquier uso no autorizado por cualquiera      */
/*     de los usuarios o personas que hayan accedido al presente        */
/*     sitio, queda expresamente prohibido; sin el debido               */
/*     consentimiento por escrito, de parte de los representantes de    */
/*     COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto    */
/*     en el presente texto, causará violaciones relacionadas con la    */
/*     propiedad intelectual y la confidencialidad de la información    */
/*     tratada; y por lo tanto, derivará en acciones legales civiles    */
/*     y penales en contra del infractor según corresponda.             */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Este programa crea el trámite correspondiente a la operación de     */
/*  cartera.                                                            */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*   FECHA             AUTOR             RAZON                          */
/*  23/04/2019        gguaman        Emision Inicial                    */
/*  04/05/2021    Paulina Quezada    Ajustes para GFI                   */
/*  21/05/2021    Alfredo Monroy     Si es llamado desde cartera        */
/*                                   mantiene opt_banco                 */
/*  01/06/2021    Paulina Quezada    Ajustes para GFI                   */
/*  08/06/2021    Paulina Quezada    ORI-B487250                        */
/*  18/10/2021    William Lopez      ORI-S544332-GFI                    */
/*  04/05/2022    Carlos Obando      ORI-R183343                        */
/*  05/05/2022    Paulina Quezada    Cambio por rubros calculados       */
/*  24/11/2022    bduenas            S736964: Se agrega cod_actividad   */
/*  26/09/2023    D. Morales         Se añade llamado a                 */
/*                                   sp_tr_datos_adicionales            */
/*  17/11/2023    Dilan Morales      R219589: Se añade destino por      */
/*                                   defecto grupales                   */
/*  07/06/2024    Dilan Morales      R236835: Se elimina código por     */
/*                                   inconsistencias                    */
/* **********************************************************************/
use cob_credito
go

if exists (select * from sysobjects where name = 'sp_tramite_cca')
   drop proc sp_tramite_cca
go

create proc sp_tramite_cca (
        @s_ssn                int           = null,
        @s_user               login         = null,
        @s_sesn               int           = null,
        @s_term               varchar(30)   = null,
        @s_date               datetime      = null,
        @s_srv                varchar(30)   = null,
        @s_lsrv               varchar(30)   = null,
        @s_ofi                smallint      = null,
        @s_culture            varchar(10)   = null,
        @t_trn                smallint      = 21020,
        @t_debug              char(1)       = 'N',
        @t_file               varchar(14)   = null,
        @t_from               varchar(30)   = null,
        @i_tipo               char(1)       = null,
        @i_oficina_tr         smallint      = null,
        @i_usuario_tr         login         = null,
        @i_fecha_crea         datetime      = null,
        @i_oficial            smallint      = null,
        @i_sector             catalogo      = null,
        @i_ciudad             int           = null,
        @i_nivel_ap           tinyint       = null,
        @i_fecha_apr          datetime      = null,
        @i_usuario_apr        login         = null,
        @i_banco              cuenta        = null,
        @i_linea_credito      cuenta        = null,
        @i_toperacion         catalogo      = null,
        @i_producto           catalogo      = null,
        @i_monto              money         = 0,
        @i_moneda             tinyint       = 0,
        @i_periodo            catalogo      = null,
        @i_num_periodos       smallint      = 0,
        @i_destino            catalogo      = null,
        @i_cod_actividad      catalogo      = null,
        @i_ciudad_destino     int           = null,
        @i_cuenta_corriente   cuenta        = null,
        @i_renovacion         smallint      = null,
        @i_cliente            int           = null,       --SBU: 02/mar/2000
        @i_clase              catalogo      = null,       --AUMENTAD O CLASE DE CARTERA 2/FEB/99
        @i_monto_mn           money         = null,       
        @i_monto_des          money         = null,       
        @i_grupal             char(1)       = null,       --MCU ingreso del rol grupal
        @i_promocion          char(1)       = null,       --LPO  Santander
        @i_acepta_ren         char(1)       = null,       --LPO Santander
        @i_no_acepta          char(1000)    = null,       --LPO Santander
        @i_emprendimiento     char(1)       = null,       --LPO Santander
        @i_participa_ciclo    char(1)       = null,       --LPO Santander
        @i_monto_aprobado     money         = null,       --LPO Santander
        @i_garantia           float         = null,       --LPO Santander
        @i_ahorro             money         = null,       --LPO Santander
        @i_monto_max          money         = null,       --LPO Santander
        @i_bc_ln              char(10)      = null,       --LPO Santander   
        @i_plazo              int           = null,       --Santander -- tr_plazo
        @i_tplazo             catalogo      = null,       --Santander -- tr_tipo_plazo
        @i_alianza            int           = null,       
        @i_experiencia_cli    char(1)       = null,       --Santander
        @i_monto_max_tr       money         = null,       --Santander
        @i_naturaleza         varchar(10)   = null,       
        @i_grupo              int           = null,       --PQU finca 
        @i_desde_cartera      char(1)       = null,       --AMP 2021-05-21 si es llamado desde cartera no cambiar opt_banco
        @i_origen_fondos      catalogo      = null,       --PQU Finca
        @i_desde_crea_grupal  char(1)       = 'N',        --PQU 05/05/2022
        @o_tramite            int           = null out
)
as
declare
        @w_today              datetime,                   -- FECHA DEL DIA
        @w_return             int,                        -- VALOR QUE RETORNA
        @w_sp_name            varchar(32),                -- NOMBRE STORED PROC
        @w_error              int,
        @w_tramite            int,                        
        @w_numero_linea       int,               
        @w_miembros           int,                        -- miembros que  conforman el grupo
        @w_operacion          int,                        -- Operacion temporal
        @w_max_tramite        int,                        -- LGU max tramite grupal
        @w_toperacion         varchar(10),                -- LGU tipo de operacion interciclo
        @w_grupo_id           int,                        -- LGU id  del grupo del interciclo
        @w_grupo              int,
        @w_tramite_ant        int,
        @w_fecha_pro          datetime,
        @w_max_tramite_grupal int,
        @w_cliente_tmp        int,
        @w_monto_ant          money,
        @w_parametro_dest_econom   varchar(30),
        @w_msg_error          varchar(132),
        @w_product_id         varchar(10),
        @w_destino_eco        varchar(30)

select @w_sp_name = 'sp_tramite_cca'

select @w_today = @s_date    --SMHB

if @i_linea_credito is not null
begin
   select  @w_numero_linea = li_numero
   from    cob_credito..cr_linea
   where   li_num_banco = @i_linea_credito
  
  if @@rowcount = 0
   begin
      /** REGISTRO NO EXISTE **/
    exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101010
    return 2101010
   end
end

-- OBTENCION DE PARAMETROS NO ENVIADOS ***********
select @i_usuario_tr = isnull(@i_usuario_tr, @s_user)

select @i_ciudad  = of_ciudad
from   cobis..cl_oficina
where  of_oficina = @i_oficina_tr
set transaction isolation level read uncommitted

select @i_fecha_apr   = isnull(@i_fecha_apr, @s_date)

select @i_usuario_apr = isnull(@i_usuario_apr, @s_user)

select @i_garantia    = (select pa_float from cobis..cl_parametro where pa_nemonico = 'PORCGP' and pa_producto = 'CCA')

select @i_renovacion  = isnull(@i_renovacion, 0)

if @i_tipo is null             --SBU interfaces
begin
   if @i_renovacion = 0
      select @i_tipo = 'O'
   else
      select @i_tipo = 'R'
end



if(@i_grupal = 'S') and @i_grupo > 0
begin
    select @w_parametro_dest_econom = pa_char 
    from cobis..cl_parametro with(nolock)
    where pa_producto = 'CRE'  
    and pa_nemonico = 'DESECG'
    if(@@rowcount = 0)
    begin
        select @w_error = 2110432
        select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje('DESECG', @w_error, @s_culture)
        exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_msg   = @w_msg_error,
                @i_num   = @w_error
        return @w_error
    end 

    select @i_cod_actividad = @w_parametro_dest_econom
    
    select @w_destino_eco = pa_char
    from cobis..cl_parametro
    where pa_nemonico = 'DESECO'
    and pa_producto   = 'CRE'
    if(@@rowcount = 0)
    begin
        select @w_error = 2110432
        select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje('DESECO', @w_error, @s_culture)
        exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_msg   = @w_msg_error,
                @i_num   = @w_error
        return @w_error
    end 
    
    if (@i_sector is null)
    begin
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2110126
        return 2110126
    end
    
    select @w_product_id = bp_product_id 
    from cob_fpm..fp_bankingproducts 
    where bp_name = (select ltrim(rtrim(b.valor)) 
                        from cobis..cl_tabla a, cobis..cl_catalogo b 
                    where a.codigo = b.tabla 
                        and a.tabla = 'cl_sector_neg' 
                        and b.codigo = @i_sector)
                        
    if not exists (select 1
                    from cob_fpm..fp_dictionaryfields , cob_fpm..fp_unitfunctionalityvalues
                    where dc_fields_id     = dc_fields_id_fk
                    and bp_product_id_fk = @w_product_id
                    and uf_delete        = 'N'
                    and upper(dc_name)   = upper(@w_destino_eco)
                    and uf_value         = @i_cod_actividad)
    begin
        select @w_error = 2110415
        select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje('. Revisar parámetro: DESECG', @w_error, @s_culture)
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_msg   = @w_msg_error,
        @i_num   = @w_error
        return @w_error --Destino Económico no parametrizado para el Sector de Cartera
    end 
end 


-- INICIO DE TRANSACCION ***********
begin tran
   /* NUMERO SECUENCIAL DE TRAMITE */
   exec cobis..sp_cseqnos
   @t_debug     = @t_debug,
   @t_file      = @t_file,
   @t_from      = @w_sp_name,
   @i_tabla     = 'cr_tramite',
   @o_siguiente = @w_tramite    out

   if @w_tramite is null
    begin      
    /* NO EXISTE TABLA EN TABLA DE SECUENCIALES*/
      exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name,
       @i_num   = 2101007
      return 2101007
    end
   
 -- MTA Validar fecha de creacion del tramite 
 select @w_fecha_pro = fp_fecha from cobis..ba_fecha_proceso 
   if (@w_today > @w_fecha_pro)
    begin
      exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name,
       @i_num   = 101140 --fecha incongruentes
      return 101140
    end 
   
   /* INSERCION EN LA TABLA CR_TRAMITE */
  insert into cr_tramite
   (tr_tramite,           tr_tipo,             tr_oficina,            tr_usuario,          tr_fecha_crea,          tr_oficial,          tr_sector,
    tr_ciudad,            tr_estado,           tr_nivel_ap,           tr_fecha_apr,        tr_usuario_apr,         tr_truta,            tr_secuencia,
    tr_numero_op,         tr_numero_op_banco,  tr_proposito,          tr_razon,            tr_txt_razon,           tr_efecto,           tr_cliente,
    tr_grupo,             tr_fecha_inicio,     tr_num_dias,           tr_per_revision,     tr_condicion_especial,  tr_linea_credito,    tr_toperacion,
    tr_producto,          tr_monto,            tr_moneda,             tr_periodo,          
    tr_num_periodos,      tr_destino,          tr_ciudad_destino,                          
    tr_cuenta_corriente,  tr_renovacion,       tr_clase,              tr_sobrepasa,        tr_reestructuracion,    tr_concepto_credito, tr_aprob_gar,
    tr_cont_admisible,    tr_montop,           tr_monto_desembolsop,  tr_grupal,           tr_promocion,           tr_acepta_ren,       tr_no_acepta,
    tr_emprendimiento,    tr_porc_garantia,    tr_plazo,              tr_tipo_plazo,       tr_alianza,             tr_experiencia,      tr_monto_max,
    tr_monto_solicitado,  tr_origen_fondos,    tr_moneda_solicitada,  tr_cod_actividad)                                              
  values                                                             
   (@w_tramite,           @i_tipo,             @i_oficina_tr,         @i_usuario_tr,       @w_today,               @i_oficial,          @i_sector,
    @i_ciudad,            'N',                 null,                  null,                null,                   0,                   0,           --WLO_S544332 se cambia el valor de los campos: tr_estado, tr_nivel_ap, tr_fecha_apr, tr_usuario_apr
    null,                 null,                null,                  null,                null,                   null,                @i_cliente,
    @i_grupo,             null,                null,                  null,                null,                   @w_numero_linea,     @i_toperacion,
    @i_producto,          @i_monto,            @i_moneda,             @i_periodo,          @i_num_periodos,        @i_destino,          @i_ciudad_destino,
    @i_cuenta_corriente,  @i_renovacion,       @i_clase,              'N',                 'N',                    '3',                 '3',
    'N',                  @i_monto_mn,         @i_monto_des,          @i_grupal,           @i_promocion,           @i_acepta_ren,       @i_no_acepta,
    @i_emprendimiento,    @i_garantia,         @i_plazo,              @i_tplazo,           @i_alianza,             @i_experiencia_cli,  @i_monto_max_tr,
    @i_monto,             @i_origen_fondos,    @i_moneda,             @i_cod_actividad)  --PQU Finca se añade origen fondos

   if @@error <> 0
    begin
      /* ERROR EN INSERCION DE REGISTRO */
      exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name,
       @i_num   = 2103001
      return 2103001
    end

   -- TRANSACCION DE SERVICIO
   insert into ts_tramite(
    secuencial,            tipo_transaccion,   clase,                 fecha,               usuario,                terminal,            oficina,    
    tabla,                 lsrv,               srv,                   tramite,             tipo,                   oficina_tr,          usuario_tr,
    fecha_crea,            oficial,            sector,                ciudad,              estado,                 nivel_ap,            fecha_apr,
    usuario_apr,           truta,              secuencia,             numero_op,           numero_op_banco,        proposito,           razon, 
    txt_razon,             efecto,             cliente,               grupo,               fecha_inicio,           num_dias,            per_revision, 
    condicion_especial,    linea_credito,      toperacion,            producto,            monto,                  moneda,              periodo,
    num_periodos,          destino,            ciudad_destino,        cuenta_corriente,    renovacion,             clasecca,            reestructuracion,
    concepto_credito,      aprob_gar,          cont_admisible,        alianza,             exp_cliente,            monto_max_tr)        --ZR1 y ZR2
   values(                                                                                                         
    @s_ssn,                @t_trn,             'N',                   @s_date,             @s_user,                @s_term,             @s_ofi, 
    'cr_tramite',          @s_lsrv,            @s_srv,                @w_tramite,          @i_tipo,                @i_oficina_tr,       @i_usuario_tr,
    @w_today,              @i_oficial,         @i_sector,             @i_ciudad,           'N',                    @i_nivel_ap,         @i_fecha_apr,
    @i_usuario_apr,        0,                  0,                     null,                null,                   null,                null,
    null,                  null,               @i_cliente,            null,                null,                   null,                null, 
    null,                  @w_numero_linea,  @i_toperacion,         @i_producto,         @i_monto,               @i_moneda,           @i_periodo,
    @i_num_periodos,       @i_destino,         @i_ciudad_destino,     @i_cuenta_corriente, @i_renovacion,          @i_clase,            'N',
    '3',                   '3',                'N',                   @i_alianza,          @i_experiencia_cli,     @i_monto_max_tr )            -- ZR1 y ZR2 --ZR y ZR1 emg Jun-19-01 cambio  concepto credito y aprob garantia

   if @@error <> 0
    begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
      exec cobis..sp_cerror
       @t_debug  = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name,
       @i_num   = 2103003
      return 2103003
    end
    
    
    exec @w_error         = cob_credito..sp_tr_datos_adicionales
         @s_ssn           = @s_ssn,
         @s_user          = @s_user,
         @s_sesn          = @s_sesn,
         @s_term          = @s_term,
         @s_date          = @s_date,
         @s_srv           = @s_srv,
         @s_lsrv          = @s_lsrv,
         @s_ofi           = @s_ofi,
         @t_trn           = 21118,
         @t_debug         = @t_debug,
         @t_file          = @t_file,
         @t_from          = @t_from,
         @t_show_version  = 0, -- Mostrar la version del programa
         @i_operacion     ='I',
         @i_tramite       = @w_tramite,
         @i_tipo_cartera  = @i_clase
    if @w_error != 0
    begin
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
       return @w_error
    end
    
if @i_desde_crea_grupal = 'N'   --PQU 05/05/2022
begin 
    select
    @w_operacion    = opt_operacion,
    @w_toperacion   = opt_toperacion 
   from   cob_cartera..ca_operacion_tmp
   where  opt_banco = @i_banco
end  --PQU 05/05/2022

   -- AMP 2021-05-21 SI ESTE SP ES LLAMADO DESDE CARTERA,LA VARIABLE @I_DESDE_CARTERA VIENE CON 'S'
   -- AMP 2021-05-21 EN SI VIENE VACIO QUIERE DECIR QUE VIENE DESDE ORIGINACION Y SOLO ALLI SE ACTUALIZA EL OPT_BANCO
--PQU 05/05/2022 IF isnull(@i_desde_cartera,'N') = 'N'

    --PQU actualizo el número del banco con el trámite porque así lo necesitan las UF
    --update cob_cartera..ca_operacion_tmp
    --set opt_banco = convert(VARCHAR(24), @w_tramite)
    --where opt_operacion = @w_operacion     
    --fin PQU

    -- LGU-ini 10/abr/2017 ver si es una interciclo
 if exists(select 1 from cobis..cl_tabla t, cobis..cl_catalogo c where t.tabla = 'ca_interciclo' and t.codigo = c.tabla and c.codigo = @w_toperacion)
  begin
 -- buscar el tramite, operacion y banco GRUPAL
    select @w_grupo_id = cg_grupo
    from   cobis..cl_cliente_grupo
    where  cg_ente = @i_cliente

    select @w_max_tramite = max(tg_tramite)
    from   cob_credito..cr_tramite_grupal
    where  tg_grupo = @w_grupo_id
        
    insert into cob_credito..cr_tramite_grupal
    (tg_tramite,             tg_grupo,           tg_cliente,   tg_monto,
     tg_grupal,              tg_operacion,       tg_prestamo,  tg_referencia_grupal,
     tg_participa_ciclo,     tg_monto_aprobado,  tg_ahorro,    tg_monto_max,           tg_bc_ln)
    select top 1
     tg_tramite,             @w_grupo_id,        @i_cliente,   @i_monto,
     @i_grupal,              @w_operacion,       @i_banco,     tg_referencia_grupal,
     @i_participa_ciclo,     @i_monto_aprobado,  @i_ahorro,    @i_monto_max,           @i_bc_ln
    from cob_credito..cr_tramite_grupal
    where tg_tramite = @w_max_tramite
        
    if @@error <> 0 
     begin
       /* ERROR EN INSERCION DE REGISTRO */
       exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2103001
       return 2103001
     end
  end
 else
begin
  if @i_grupal = 'S'
   begin
    --PARA operaciones GRUPALES
      select @w_miembros = count(1)
      from   cobis..cl_cliente_grupo
      where  cg_grupo = @i_grupo and cg_estado='V'  --PQU cambiar al grupo
      
      declare @w_val_ahorro_vol int
      
      select  @w_val_ahorro_vol = pa_int 
      from cobis..cl_parametro 
      where pa_nemonico = 'VAHVO' 
      and   pa_producto = 'CRE'
      
    --PRINT 'OBTENER NUMERO DE OPERACION DESDE TEMPORAL'
      if @i_desde_crea_grupal = 'N'   --PQU 05/05/2022
      begin
      select @w_operacion    = opt_operacion
      from   cob_cartera..ca_operacion_tmp
      where  opt_banco = @i_banco

    if @w_operacion is null or @i_banco is null
     begin
       /* ERROR EN INSERCION DE REGISTRO */
       exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2110386
       return 2110386
     end
      end        
--Obtiene el ultimo tramite del grupo
    select @w_max_tramite_grupal = max(tg_tramite)
    from   cob_credito..cr_tramite_grupal
    where  tg_grupo = @i_grupo --PQU cambio al grupo @i_cliente          

    insert into cob_credito..cr_tramite_grupal
    (tg_tramite,             tg_grupo,                       tg_cliente,        tg_monto,             tg_grupal,     tg_operacion,     tg_prestamo,  tg_referencia_grupal,
     tg_participa_ciclo,     tg_monto_aprobado,              tg_ahorro,         tg_monto_max,         tg_bc_ln)
     select       
     @w_tramite,             @i_grupo,                       cg_ente,           0,                    @i_grupal,     @w_operacion,     @i_banco,     @i_banco,
     'N',                    0,                              @w_val_ahorro_vol, @i_monto_max,         @i_bc_ln
     from cobis..cl_cliente_grupo
     where cg_grupo = @i_grupo and cg_estado='V'
                      
     if @@error <> 0
      begin
     /* ERROR EN INSERCION DE REGISTRO */
       exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2103001
       return 2103001
      end
    
   end    
end 

commit tran

select @o_tramite = @w_tramite


GO
