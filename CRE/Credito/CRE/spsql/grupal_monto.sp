/********************************************************************/
/*   NOMBRE LOGICO:         sp_grupal_monto                         */
/*   NOMBRE FISICO:         grupal_monto.sp                         */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          J. Escobar                              */
/*   FECHA DE ESCRITURA:    23-Abr-2019                             */
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
/*   SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito            */
/*   Guardar informacion de los prestamos grupales                  */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA        AUTOR          RAZON                              */
/*  23-Abr-2019   J. Escobar     Emision Inicial                    */
/*  01-Jun-2021   P. Quezada     Ajustes para GFI                   */
/*  14-Jul-2021   C. Veintemilla Ajustes para GFI                   */
/*  22-Jul-2021   P. Mora        Ajustes para GFI                   */
/*  31-Ago-2021   J. Mieles      Ajustes para GFI                   */
/*  13-Oct-2021   W. Lopez       ORI-S544332-GFI                    */
/*  26-Nov-2021   W. Lopez       ORI-S542854-GFI                    */
/*  05-Ene-2022   P. Mora        ORI-S575044-GFI                    */
/*  10-Mar-2022   D. Morales     Se corrige actualizacion de        */
/*                               operacion gruapal                  */
/*  15-Mar-2022   D. Morales     Se corrige actualizacion de        */
/*                               operacion gruapal y sus tramites   */
/*                               individuales                       */
/*  26-Abr-2022   D. Morales     Cuando integrante no participa se  */
/*                               coloca campos con valores inciales */
/*  10-Jun-2022   D. Morales     Correccion para validar roles      */
/*  24-Jun-2022   D. Morales     Validacion de integrantes operacion*/
/*  30-Jun-2022   D. Morales     Validacion de operacion hija       */
/*  20-Jul-2022   B. Duenas      Ingreso ts_tramite_grupal          */
/*  03-Ago-2022   B. Duenas      Se quita validacion cuando viene   */
/*                               desde la interfaz                  */
/*  15-Sep-2022   D. Morales     R-192772: Optimizacion de          */
/*                               transacciones                      */
/*  24-Nov-2022   B. Duenas      S736964: Correccion pantalla       */
/*                               montos integrantes                 */
/*  24-Nov-2022   B. Duenas      S736969: cambios para renov/reest  */
/*                               grupal                             */
/*  23-Feb-2023   B. Duenas      B756575:validaciones montos min/max*/
/*                               grupal                             */
/*  17-Mar-2023   B. Duenas      Validar estado catalogo            */
/*  11-Abr-2023   P. Jarrin      S784659: Cambios por Control de TEA*/
/*  19-Abr-2023   D. Morales     S784515: Añade operacion F         */
/*  29-May-2023   D. Morales     S792445-APP: Se añade consulta para*/
/*                               la de op hijas a renovar           */
/*  13-Jun-2023   D. Morales     S840145-APP: Se añade corrige      */
/*                               valida del sector                  */
/*  22-Jun-2023   D. Morales     Se valida integrante pago solidario*/
/*  26-Jun-2023   D. Morales     Se modifica operacion Q para       */
/*                               credito tipo R y F                 */
/*  27-Jun-2023   D. Morales     Se añade validación de estados para*/
/*                               operación F                        */
/*  29-Jun-2023   B. Duenas      Se asocia beneficiaros del ente al */
/*                               tramite                            */
/*  29-Jun-2023   P. Jarrin      S840149:Flujo Renovar o Refinanciar*/
/*  03-Jul-2023   D. Morales     Se valida monto para op a renovar  */
/*  11-Jul-2023   B. Duenas      Se agrega direccion default        */
/*  10-Oct-2023   P. Jarrin      S908205: Buscador Destino Economico*/
/*  23-Oct-2023   P. Jarrin.     Ajuste Tasa S923938-R214406        */
/*  15-Nov-2023   D. Morales     R219297: Se comenta codigo valida  */
/*                               valida grupo                       */
/*  18-Dec-2023   B. Duenas      R221684-Cambio registro TS         */
/*  02-Abr-2024   D. Morales.   R229984:Se añade logica para modificar*/
/*                               registros de cr_op_renovar por ente*/
/*  30-Jul-2024   D. Morales.    R240986:Se añade estados en        */
/*                               operacion Q                        */
/*  16-Ago-2024   D. Morales.    R240986:Se añade estado 6 en       */
/*                               operacion F                        */
/*  29-Ago-2024   D. Morales.    R240986:Se añade estado 6 en       */
/*                               validacion de montos renovacion    */
/*  14-Feb-2025   G. Romero      Req 251290 Tasa de interes mora    */
/********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_grupal_monto')
    drop proc sp_grupal_monto
go

create proc sp_grupal_monto (
        @i_operacion              char(1),
        @i_grupo                  int            = null,
        @i_tramite                int            = null,
        @i_ente                   int            = null,
        @i_monto                  money          = 0,
        @s_ssn                    int            = null,
        @s_sesn                   int            = null,
        @s_ofi                    smallint       = null,
        @s_rol                    smallint       = null,
        @s_user                   login          = null,
        @s_date                   datetime       = null,
        @s_term                   descripcion    = null,
        @s_culture                varchar(10)    = null,
        @t_debug                  char(1)        = 'N',
        @t_file                   varchar(10)    = null,
        @t_from                   varchar(32)    = null,
		@t_show_version           bit            = 0,
        @t_trn                    int            = null,
        @s_srv                    varchar(30)    = null,
        @s_lsrv                   varchar(30)    = null,
        @i_cheque                 int            = null,
        @i_modo                   int            = null,
        @i_participa_ciclo        char(1)        = null,         -- LPO Santander
        @i_tg_monto_aprobado      money          = null,         -- LPO Santander
        @i_ahorro                 money          = null,         -- LPO Santander
        @i_monto_max              money          = null,         -- LPO Santander
        @i_bc_ln                  char(10)       = null,         -- LPO Santander
        @i_tr_cod_actividad       catalogo       = null,         -- PQU integración
        @i_sector                 catalogo       = null,
        @i_monto_recomendado      money          = null,
        @i_canal                  tinyint        = null,         -- Canal: 0=Frontend 1=Batch 2=Workflow 3=Rest 20=APP
        @i_desde_interfaz         char(1)        = 'N',
        @i_tipo_credito           char(1)        = null, 
        @i_custipo_credito        catalogo       = null,
        @i_pre_filtro             varchar(30)    = null,
        @i_num_integrantes        int            = null,            
        @o_msg1                   varchar(1200)  = null output,  -- LGU  para mostrar las alertas del porcentaje y monto maximo
        @o_msg2                   varchar(100)   = null output,  -- LGU  para mostrar las alertas del porcentaje y monto maximo
        @o_msg3                   varchar(100)   = null output,  -- LGU  para mostrar las alertas del porcentaje y monto maximo
        @o_msg4                   varchar(100)   = null output   -- LGU  para mostrar las alertas del porcentaje y monto maximo
)
as
declare
        @w_msg_error              varchar(132),
        @w_nomlar                 varchar(132),
        @w_operacionca            int,
        @w_fecha_ini              datetime,
        @w_fecha_fin              datetime,
        @w_fecha_liq              datetime,
        @w_monto                  money,
        @w_moneda                 tinyint,
        @w_oficina                smallint,
        @w_banco                  cuenta,
        @w_cliente                int,
        @w_nombre                 descripcion,
        @w_estado                 smallint,
        @w_op_direccion           tinyint,
        @w_lin_credito            cuenta,
        @w_tipo_amortizacion      catalogo,
        @w_cuota                  money,
        @w_periodo_cap            int,
        @w_periodo_int            int,
        @w_base_calculo           char(1),
        @w_dias_anio              smallint,
        @w_plazo                  tinyint,
        @w_tplazo                 char(1),
        @w_plazo_no_vigente       tinyint,
        @w_min_fecha_vig          datetime,
        @w_est_novigente          smallint,
        @w_formato_fecha          int,
        @w_return                 int,
        @w_tipo                   char(1),
        @w_nombre_grupo           varchar(64),
        @w_sector                 varchar(30),
        @w_toperacion             varchar(10),
        @w_oficial                smallint,
        @w_fecha_crea             datetime,
        @w_destino                varchar(10),
        @w_ciudad                 int,
        @w_banca                  catalogo,
        @w_val_ahorro_vol         float ,         -- LGU porc. ahorro_voluntario
        @w_error                  int,            
        @w_sp_name                varchar(32),    
        @w_promocion              char(1),        --LPO Santander
        @w_acepta_ren             char(1),        --LPO Santander
        @w_no_acepta              char(1000),     --LPO Santander
        @w_emprendimiento         char(1),        --LPO Santander
        @w_suma_montos            money,          
        @w_msg                    varchar(100),   -- LGU mensaje de error en las reglas
        @w_multiplo               money,          -- LGU, control de multiplos de 500 o 100
        @w_suma_montos_aprob      money,          -- LPO Ajustes definicion de nuevos campos Santander
        @w_actualiza_movil        varchar(1),
        @w_parm_ofi_movil         smallint,
        @w_ciclo_grupo            int,
        @w_num_ant                int,
        @w_num_comunes_ant        int,
        @w_num_act                int,
        @w_num_comunes_act        int,
        @w_tramite_anterior       int,
        @w_debe_validar           char(1),
        @w_cambiar_valor          char(1),
        @w_count                  int,
        @w_origen_fondos          catalogo,       --PQU integracion
        @w_dia_pago               tinyint,        --PQU integracion
        @w_cod_sector             smallint,          
        --INI WLO_S544332
        @w_tg_referencia_grupal   varchar(15),
        @w_existe_op_hija         smallint,
        @w_op_monto_hija          money,
        @w_op_tramite_hija        int,
        @w_op_banco_hija          cuenta,
        @w_op_operacion_hija      int,
        @w_est_novigente_cca      tinyint,
        @w_est_anulado_cca        tinyint,
        @w_est_credito_cca        tinyint,
        @w_estado_op_cca          tinyint,
        @w_est_rechazado_tr       char(2),
        @w_est_ing_tr             char(2),
        @w_estado_tr              char(2),
        @w_tr_monto               money,
        @w_tr_monto_soli          money,
        @w_tr_plazo               smallint,
        @w_tr_tplazo              catalogo,
        @w_tr_origen_fondos       catalogo,
        @w_tr_num_dias            smallint,
        @w_tr_promocion           char(1),
        --FIN WLO_S544332
        @w_op_monto_padre         money,
        @w_ssn                    int,
        @w_tr_tipo                char(1),
        @w_monto_min              money,
        @w_monto_max              money,
        @w_monto_renova           money,
        @w_saldo                  money,
        @w_capitaliza             char(1),
        @w_monedatr               int,
        @w_valor_campo            varchar(200),
        @w_product_id             varchar(10),
        @w_destino_eco            varchar(30),
        --Variables beneficiaros
        @w_seguro                 varchar(10),
        @w_tramite_seguro         int,
        @w_tipo_cre               catalogo,
        @w_subtipo_cre            char(1),
        @w_filtro                 varchar(30),
        @w_tasa                   float,
		@w_tasa_mora              float, --Req 251290
		@w_tasa_mora_aux          float, --Req 251290
		@w_cod_cred               tinyint, --Req 251290
        @w_capitaliza_padre       char(1),
		@w_num_integrantes        int,
		@w_operacion_cca          int,
		@w_ref_grupal             cuenta

select @w_est_novigente = 0,
       @w_formato_fecha = 101,
       @w_sp_name = 'sp_grupal_monto',
       @w_sector     = '',
       @w_product_id = ''  

if @t_show_version = 1    --Req 251290
begin
    print 'Stored procedure %1!, Version 1.1.1'  
    print @w_sp_name
    return 0
end	   

select @w_destino_eco = pa_char
from cobis..cl_parametro
where pa_nemonico = 'DESECO'
and pa_producto   = 'CRE'

SELECT @w_cod_cred=es_codigo 
FROM cob_cartera..ca_estado
WHERE es_descripcion='CREDITO'
       
-- validaciones para Insercion y Modificacion
if(@i_tramite is not null and @i_participa_ciclo = 'S' and @i_modo = 2)
begin
   select  @w_toperacion = tr_toperacion,
           @w_monedatr   = tr_moneda,
           @w_sector     = tr_sector
    from cob_credito.dbo.cr_tramite ct 
    where tr_tramite = @i_tramite

    -- VALIDACION DEL MONTO APROBADO 
     select @w_monto_min = dt_monto_min,
            @w_monto_max = dt_monto_max
     from   cob_cartera..ca_default_toperacion
     where  dt_toperacion = @w_toperacion
     and    dt_moneda     = @w_monedatr
    
    if isnull(@i_monto,0) > 0 and 
      (isnull(@w_monto_min,0) > 0 or isnull(@w_monto_max,0) > 0) and 
      (@i_monto < @w_monto_min or @i_monto > @w_monto_max)
    begin
       select @w_valor_campo  = 'Cliente: ' + (select en_nomlar from cobis..cl_ente where en_ente = @i_ente)
       select @w_error = 21110120
       goto ERROR_CONCAT
    end
    
    
    if(@i_custipo_credito = 'R' or @i_custipo_credito = 'F')
    begin
        
        select @w_monto_renova = 0 
        
        declare cur_operaciones cursor read_only for
        select op_operacion, or_capitaliza from cob_credito..cr_op_renovar
        inner join cob_cartera..ca_operacion on op_ref_grupal = or_num_operacion
        where or_tramite = @i_tramite
        and op_cliente = @i_ente
        and op_grupo = @i_grupo
        and op_estado not in (0, 3, 9, 66, 6)
        
        open cur_operaciones
        fetch next from cur_operaciones into  @w_operacionca, @w_capitaliza
    
        while @@fetch_status = 0
        begin
            select @w_saldo = 0
            if(@w_capitaliza = 'N')
            begin
                    select @w_saldo =   isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)  -- Monto de la operación Base
                                            from   cob_cartera..ca_amortizacion , cob_cartera..ca_rubro_op
                                            where  am_operacion = @w_operacionca
                                            and    ro_operacion = am_operacion
                                            and    am_concepto  = ro_concepto
                                            and    ro_tipo_rubro in ('C')
            
            end
            else if (@w_capitaliza = 'S')
            begin
                    select @w_saldo =   isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)  -- Monto de la operación Base
                                            from   cob_cartera..ca_amortizacion , cob_cartera..ca_rubro_op
                                            where  am_operacion = @w_operacionca
                                            and    ro_operacion = am_operacion
                                            and    am_concepto  = ro_concepto
                                            and    ro_tipo_rubro in ('C','I')
            end
            else if(@w_capitaliza = 'T')
            begin
                    select @w_saldo =   isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)  -- Monto de la operación Base
                                            from   cob_cartera..ca_amortizacion , cob_cartera..ca_rubro_op
                                            where  am_operacion = @w_operacionca
                                            and    ro_operacion = am_operacion
                                            and    am_concepto  = ro_concepto
                                            and    ro_tipo_rubro in ('C','I')
            
                    select @w_saldo = @w_saldo + isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0) -- Monto de la operación Base
                                                from cob_cartera..ca_amortizacion,
                                                cob_cartera..ca_dividendo
                                                where am_operacion = di_operacion and
                                                am_operacion = @w_operacionca and 
                                                am_dividendo = di_dividendo and
                                                am_concepto not in('CAP', 'INT') and
                                                di_estado not in (0)
            end
            
            select @w_monto_renova  = @w_monto_renova + @w_saldo
            
            fetch next from cur_operaciones into  @w_operacionca, @w_capitaliza
        end
        
        close cur_operaciones
        deallocate  cur_operaciones
        
        if( @w_monto_renova > @i_tg_monto_aprobado )
        begin
            select @w_valor_campo  = '-Cliente: ' + (select en_nomlar from cobis..cl_ente where en_ente = @i_ente)
            select @w_error = 2110431
            goto ERROR_CONCAT
        end 
    end
    
    
    -- VALIDACION DESTINO ECONOMICO POR SECTOR DE CARTERA
   if (@w_sector is null)
    begin
        select @w_error = 2110126
        goto ERROR
    end
    
    select @w_product_id = bp_product_id 
    from cob_fpm..fp_bankingproducts 
    where bp_name = (select ltrim(rtrim(b.valor)) 
                        from cobis..cl_tabla a, cobis..cl_catalogo b 
                    where a.codigo = b.tabla 
                        and a.tabla = 'cl_sector_neg' 
                        and b.codigo = @w_sector)
                        
    if not exists (select 1
                    from cob_fpm..fp_dictionaryfields , cob_fpm..fp_unitfunctionalityvalues
                    where dc_fields_id     = dc_fields_id_fk
                    and bp_product_id_fk = @w_product_id
                    and uf_delete        = 'N'
                    and upper(dc_name)   = upper(@w_destino_eco)
                    and uf_value         = @i_tr_cod_actividad)
    begin
        select @w_valor_campo  = '- Cliente: ' + (select en_nomlar from cobis..cl_ente where en_ente = @i_ente)
        select @w_error = 2110415 --Destino Económico no parametrizado para el Sector de Cartera
        goto ERROR_CONCAT
    end 
end

select         @w_est_novigente_cca    = 0,
               @w_est_anulado_cca      = 6,
               @w_est_credito_cca      = 99
      
--Estados de cartera
exec @w_return = cob_cartera..sp_estados_cca
     @o_est_novigente  = @w_est_novigente_cca out,
     @o_est_anulado    = @w_est_anulado_cca   out,
     @o_est_credito    = @w_est_credito_cca   out
if @w_return != 0
begin
    select @w_error = @w_return
    goto ERROR
end


select @w_parm_ofi_movil = pa_smallint from cobis..cl_parametro where pa_nemonico = 'OFIAPP' and pa_producto = 'CRE'

if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if @i_tramite is null or @i_ente is null -- LGU: para llamado desde mantenimiento de Grupos
    begin
        select @w_error = 2101001 --CAMPOS NOT NULL CON VALORES NULOS
        goto ERROR
    end
end

if @i_operacion = 'I' -- LGU: 22/AGO/2017 insertar un cliente desde MANTENIMIENTO DE GRUPOS
begin
    if exists(select 1 from cr_tramite_grupal where tg_tramite = @i_tramite and tg_cliente = @i_ente)
    begin
        select @w_error = 2101002  -- REGISTRO YA EXISTE
        goto ERROR
    end

    select @w_val_ahorro_vol = tr_porc_garantia from cr_tramite where tr_tramite = @i_tramite

    select @w_val_ahorro_vol = isnull( @w_val_ahorro_vol , (select pa_int from cobis..cl_parametro where pa_nemonico = 'VAHVO' and pa_producto = 'CRE' ))

    insert into cr_tramite_grupal (
        tg_tramite           ,    tg_grupo             ,    tg_cliente           ,
        tg_monto             ,    tg_grupal            ,    tg_operacion         ,
        tg_prestamo          ,
        tg_referencia_grupal ,    tg_cuenta            ,    tg_cheque            ,
        tg_participa_ciclo   ,    tg_monto_aprobado    ,    tg_ahorro            ,
        tg_monto_max         ,    tg_bc_ln             ,    tg_incremento        ,
        tg_monto_ult_op      ,    tg_monto_max_calc    ,    tg_monto_min_calc    ,
        tg_destino           ,    tg_sector            ,    tg_monto_recomendado)  --PQU se añade destino
        select top 1 -- <<------------ EL PRIMER REGISTRO SOLAMENTE
            tg_tramite           ,    tg_grupo             ,    @i_ente              ,
            0                    ,    'S'                  ,    (select op_operacion from cob_cartera..ca_operacion where op_tramite = @i_tramite),
            tg_referencia_grupal          ,
            tg_referencia_grupal ,    tg_cuenta            ,    tg_cheque            ,
            'N'                  ,    0                    ,    @w_val_ahorro_vol    ,
            null                 ,    null                 ,    null                 ,
            null                 ,    null                 ,    null                 ,
            @i_sector,                @i_tr_cod_actividad  ,    @i_monto_recomendado
        from cr_tramite_grupal
        where tg_tramite = @i_tramite
   --Recuperar datos insercion en las ts
         insert into cob_credito..ts_tramite_grupal                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    tramite,               grupo,                       
         cliente,                monto,                 grupal, 
         operacion,              prestamo,              referencia_grupal,
         cuenta,                 cheque,                participa_ciclo,
         monto_aprobado,         ahorro,                monto_max, 
         bc_ln,                  incremento,            monto_ult_op,
         monto_max_calc,         nueva_op,              monto_min_calc,
         conf_grupal,            destino,               sector, 
         monto_recomendado,      estado,                id_rechazo,
         descripcion_rechazo)  
         select                   
         @s_ssn,                  21848,               'N',
         @s_date,                 @s_user,             @s_term,
         @s_ofi,                  'cr_tramite_grupal', @s_lsrv,
         @s_srv,                  @i_tramite,          tg_grupo,
         @i_ente,                 tg_monto,            tg_grupal, 
         tg_operacion,            tg_prestamo,         tg_referencia_grupal,
         tg_cuenta,               tg_cheque,           tg_participa_ciclo,
         tg_monto_aprobado,       tg_ahorro,           tg_monto_max, 
         tg_bc_ln,                tg_incremento,       tg_monto_ult_op,
         tg_monto_max_calc,       tg_nueva_op,         tg_monto_min_calc,
         tg_conf_grupal,          tg_destino,          tg_sector, 
         tg_monto_recomendado,    tg_estado,           tg_id_rechazo,
         tg_descripcion_rechazo 
         from cob_credito..cr_tramite_grupal
         where tg_cliente  = @i_ente 
         and tg_tramite    = @i_tramite
         --ERROR EN CREACION DE TRANSACCION DE SERVICIO
         if @@error <> 0 begin
            select @w_error = 1720049
            goto ERROR
         end
    if @@error <> 0
    begin
        select @w_error = 150000 -- ERROR EN INSERCION
        goto ERROR
    end

 -- LGU-ini 22/AGO/2017  RECALCULAR MONTO MAXIMO Y PORC. DE INCREMENTO
    exec @w_return = sp_grupal_monto
    @s_ssn         = @s_ssn ,
    @s_rol         = @s_rol ,
    @s_ofi         = @s_ofi ,
    @s_sesn        = @s_sesn ,
    @s_user        = @s_user ,
    @s_term        = @s_term ,
    @s_date        = @s_date ,
    @s_srv         = @s_srv ,
    @s_lsrv        = @s_lsrv ,
    @i_operacion   = 'R',
    @i_tramite     = @i_tramite,
    @i_modo        = 1
    
 -- LGU-ini 22/AGO/2017  RECALCULAR MONTO MAXIMO Y PORC. DE INCREMENTO
    exec @w_return = sp_grupal_monto
    @s_ssn         = @s_ssn ,
    @s_rol         = @s_rol ,
    @s_ofi         = @s_ofi ,
    @s_sesn        = @s_sesn ,
    @s_user        = @s_user ,
    @s_term        = @s_term ,
    @s_date        = @s_date ,
    @s_srv         = @s_srv ,
    @s_lsrv        = @s_lsrv ,
    @i_operacion   = 'Q',
    @i_tramite     = @i_tramite,
    @i_modo        = 1

    if @w_return <> 0
    begin
        select @w_error = 2110319 --'Error al determinar MONTO MAX Y PORCENTAJE DE INCREMENTO'
        goto ERROR
    end
    -- LGU-ini 22/AGO/2017  RECALCULAR MONTO MAXIMO Y PORC. DE INCREMENTO
    return 0
end

if @i_operacion = 'U'  -- Modificar el valor de la solicitud de un cliente del tramite del grupo
begin
 if @i_modo = 2 
  begin -- validar reconformacion grupal
        select @w_cambiar_valor = 'S',
               @w_debe_validar = 'N'
        --SMO Si la solicitud anterior fue rechazada
        
        /*select @w_tramite_anterior = max(tg_tramite)
        from cob_credito..cr_tramite_grupal
        where tg_grupo = @i_grupo
        and tg_tramite < @i_tramite
        --si la solcitud anterior fue rechazada o cancelada
        
        --Consulta si todos los registros fueron actualizados previamente
        select @w_count = count(tg_tramite )
        from cob_credito..cr_tramite_grupal
        where tg_tramite    = @i_tramite
        and tg_conf_grupal is null
        
        if @w_count = 0
         begin -- si no hay registros null
            update cob_credito..cr_tramite_grupal -- se ponen todos null para que vuelva a validar porque es una nueva actualizacion de todos los montos
            set tg_conf_grupal = null
            where tg_grupo     = @i_grupo
            and tg_tramite     = @i_tramite
         end
        --Consulta si existe algun registro con valor null
        select @w_count = count(tg_tramite)
        from cob_credito..cr_tramite_grupal
        where tg_tramite    = @i_tramite
        and tg_conf_grupal is null
        
        if @w_count = 1
         begin  -- si solo hay un registro null
            select @w_debe_validar = 'S' -- para validar la conformacion en este update
         end     
        else
            select @w_debe_validar = 'N' -- para validar la conformacion en este update
        */    
        update cob_credito..cr_tramite_grupal -- para evitar que los otros updates validen nuevamente
        set tg_conf_grupal   = @w_debe_validar
        where tg_tramite     = @i_tramite
        and tg_cliente       = @i_ente
        
        select * from  cr_tramite_grupal tg where tg_tramite = @i_tramite
        select @w_ciclo_grupo = gr_num_ciclo from cobis..cl_grupo where gr_grupo = @i_grupo
        
        /*if(@w_ciclo_grupo >= 1) --CVA se desabilita para nueva version
        begin
            -- LGU-ini: 2017-06-22 control de montos multiplos de 100
            select @w_multiplo = pa_money from cobis..cl_parametro
            where pa_producto = 'CCA'
            and pa_nemonico = 'MUL100'
                    
            select @w_multiplo = isnull(@w_multiplo, 100)
            -- LGU-fin: 2017-06-22 control de montos multiplos de 100
        end    
        else
        begin
            -- LGU-ini: 2017-06-22 control de montos multiplos de 500
            select @w_multiplo = pa_money from cobis..cl_parametro
            where pa_producto  = 'CCA'
            and pa_nemonico  = 'MUL500'
            
            select @w_multiplo = isnull(@w_multiplo, 100)
            -- LGU-fin: 2017-06-22 control de montos multiplos de 500
        end*/
        
        -- ACHP se cambia para que el monto aprobado sea el tg_monto y
        -- el monto solicitado sea el monto aprobado.
        if ((@i_tg_monto_aprobado <> 0) and (@i_monto = 0))
         begin
            select  @w_error = 2110320 --'Error el monto solicitado del cliente no puede ser 0 si se ingresa monto autorizado '
            goto ERROR
         end
                
        -- LGU-ini: 2017-06-22 control de montos multiplos de 100
        /*if (@i_tg_monto_aprobado % @w_multiplo) = 0
        begin    CVA Se quita validacion para multiplico de 100 o 500 */
        
        
        --DMO SI NO PARTICIPA SE QUITAN VALORES 
        if(@i_participa_ciclo  = 'N')
        begin 
            select  @i_tg_monto_aprobado = 0 ,
                    @i_monto = 0,
                    @i_tr_cod_actividad = null ,
                    @i_sector = null,
                    @i_monto_recomendado  = 0,
                    @i_ahorro = 0, 
                    @i_monto_max = 0
                    
            if exists(select 1 from cob_credito..cr_pago_solidario 
                        where ps_tramite_grupal = @i_tramite 
                        and ps_ente_solidario = @i_ente)
            begin               
                select @w_nomlar = en_nomlar from cobis..cl_ente where en_ente = @i_ente
                select @w_error = 2110428 -- Los participantes que realizarion pagos solidarios deben participar. Revisar el participante: 
                select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
                goto ERROR
            end
        end 
        
          --Recuperar datos antes de actualizar para insercion en las ts
         insert into cob_credito..ts_tramite_grupal                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    tramite,               grupo,                       
         cliente,                monto,                 grupal, 
         operacion,              prestamo,              referencia_grupal,
         cuenta,                 cheque,                participa_ciclo,
         monto_aprobado,         ahorro,                monto_max, 
         bc_ln,                  incremento,            monto_ult_op,
         monto_max_calc,         nueva_op,              monto_min_calc,
         conf_grupal,            destino,               sector, 
         monto_recomendado,      estado,                id_rechazo,
         descripcion_rechazo)  
         select                   
         @s_ssn,                  21847,               'A',
         @s_date,                 @s_user,             @s_term,
         @s_ofi,                  'cr_tramite_grupal', @s_lsrv,
         @s_srv,                  @i_tramite,          tg_grupo,
         @i_ente,                 tg_monto,            tg_grupal, 
         tg_operacion,            tg_prestamo,         tg_referencia_grupal,
         tg_cuenta,               tg_cheque,           tg_participa_ciclo,
         tg_monto_aprobado,       tg_ahorro,           tg_monto_max, 
         tg_bc_ln,                tg_incremento,       tg_monto_ult_op,
         tg_monto_max_calc,       tg_nueva_op,         tg_monto_min_calc,
         tg_conf_grupal,          tg_destino,          tg_sector, 
         tg_monto_recomendado,    tg_estado,           tg_id_rechazo,
         tg_descripcion_rechazo 
         from cob_credito..cr_tramite_grupal
         where tg_cliente  = @i_ente 
         and tg_tramite    = @i_tramite
         and tg_grupo      = @i_grupo
         --ERROR EN CREACION DE TRANSACCION DE SERVICIO
         if @@error <> 0 begin
            select @w_error = 1720049
            goto ERROR
         end
         
            update cr_tramite_grupal
            set    tg_monto             = @i_tg_monto_aprobado,  --ACHP - Se cambia por conceptos
                   tg_participa_ciclo   = @i_participa_ciclo,    --LPO Santander
                   tg_monto_aprobado    = @i_monto,              --ACHP - Se cambia por conceptos - es el monto solicitado
                   tg_ahorro            = @i_ahorro,             --LPO Santander
                   tg_monto_max         = @i_monto_max,          --LPO Santander
                   tg_bc_ln             = @i_bc_ln,              --LPO Santander
                   tg_destino           = @i_sector,   --PQU
                   tg_sector            = @i_tr_cod_actividad,
                   tg_monto_recomendado = @i_monto_recomendado 
            where  tg_tramite           = @i_tramite
            and    tg_cliente           = @i_ente
            and    tg_grupo             = @i_grupo
            
            if @@error != 0
           begin
                select @w_nomlar = ' ID: ' + cast(@i_ente as varchar)
                select @w_error = 2110396
                select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
                goto ERROR
           end
           
           --Recuperar datos despues de actualizar para insercion en las ts
         insert into cob_credito..ts_tramite_grupal                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    tramite,               grupo,                       
         cliente,                monto,                 grupal, 
         operacion,              prestamo,              referencia_grupal,
         cuenta,                 cheque,                participa_ciclo,
         monto_aprobado,         ahorro,                monto_max, 
         bc_ln,                  incremento,            monto_ult_op,
         monto_max_calc,         nueva_op,              monto_min_calc,
         conf_grupal,            destino,               sector, 
         monto_recomendado,      estado,                id_rechazo,
         descripcion_rechazo)  
         select                   
         @s_ssn,                  21847,               'D',
         @s_date,                 @s_user,             @s_term,
         @s_ofi,                  'cr_tramite_grupal', @s_lsrv,
         @s_srv,                  @i_tramite,          tg_grupo,
         @i_ente,                 tg_monto,            tg_grupal, 
         tg_operacion,            tg_prestamo,         tg_referencia_grupal,
         tg_cuenta,               tg_cheque,           tg_participa_ciclo,
         tg_monto_aprobado,       tg_ahorro,           tg_monto_max, 
         tg_bc_ln,                tg_incremento,       tg_monto_ult_op,
         tg_monto_max_calc,       tg_nueva_op,         tg_monto_min_calc,
         tg_conf_grupal,          tg_destino,          tg_sector, 
         tg_monto_recomendado,    tg_estado,           tg_id_rechazo,
         tg_descripcion_rechazo 
         from cob_credito..cr_tramite_grupal
         where tg_cliente  = @i_ente 
         and tg_tramite    = @i_tramite
         and tg_grupo      = @i_grupo
         --ERROR EN CREACION DE TRANSACCION DE SERVICIO
         if @@error <> 0 begin
            select @w_error = 1720049
            goto ERROR
         end
            
                    
            --MONTO GRUPAL
            if @w_debe_validar = 'S'
             begin
                if @w_tramite_anterior is not null and  exists (select 1 from cob_credito..cr_tramite where tr_tramite = @w_tramite_anterior and tr_estado in ('X','Z'))
                 begin
                    select @w_num_ant = count (tg_cliente) from  cr_tramite_grupal tg where tg_tramite = @w_tramite_anterior and tg_monto_aprobado > 0
                    select @w_num_comunes_ant = count (tg_cliente)  from  cr_tramite_grupal tg where tg_tramite = @w_tramite_anterior and tg_monto_aprobado > 0 and tg_cliente in
                        (select tg_cliente from  cr_tramite_grupal tg where tg_tramite = @i_tramite)
                                
                    select @w_num_act = count (tg_cliente) from  cr_tramite_grupal tg where tg_tramite = @i_tramite and tg_monto_aprobado > 0
                    select @w_num_comunes_act = count (tg_cliente) from  cr_tramite_grupal tg where tg_tramite = @i_tramite and tg_monto_aprobado > 0 and tg_cliente in
                        (select tg_cliente from  cr_tramite_grupal tg where tg_tramite = @w_tramite_anterior)
        
                    if @w_num_ant = @w_num_comunes_ant and @w_num_act = @w_num_comunes_act and @w_num_ant = @w_num_act
                    begin
                        print 'smo valida  no cambio el grupo'  
                        select
                            @w_error = 2110139
                        goto ERROR
                    end
                    else
                        print 'SMO VALIDA SI cambio el grupo'
                 end 
                else
                    print 'SMO VALIDA  no existe tramite anterior o el tramite anterior no fue rechazado'
             end
            else
                print 'SMO VALIDA NO ENTRA A VALIDAR '+ convert(varchar(10),@i_tramite) +' valida cliente '+ convert(varchar(10),@i_ente)
        --end 
        /*else CVA  Se quita validacion si es multiplo de 100 o 500
        begin
            select @w_error = 99 --  Debe Ingresar los Montos
            select @w_msg = 'Para: ' + (select en_nombre + ' ' + p_p_apellido from cobis..cl_ente where en_ente = @i_ente) +
                            '. [' + convert(varchar, @i_tg_monto_aprobado) + '] no es multiplo de [' + convert(varchar,@w_multiplo)+']        .'
            goto ERROR
        end*/
  end

   else if @i_modo = 4
    begin
     select @w_existe_op_hija = 0
     select @w_nomlar = ' ID: ' + cast(@i_ente as varchar)
     
     if not exists (select 1
       from cr_tramite_grupal  
      where tg_tramite = @i_tramite
        and tg_cliente = @i_ente
        and tg_grupo   = @i_grupo)
    BEGIN
        select @w_error = 2101006 --EL CLIENTE NO ESTA ASOCIADO AL TRAMTIE GRUPAL 
        select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
        goto ERROR
    END
     --numero de operacion grupal
     select @w_tg_referencia_grupal = op_banco
     from   cob_cartera..ca_operacion
     where  op_tramite = @i_tramite  
     
    if @w_tg_referencia_grupal is null
     begin
        select @w_error = 2101007 --REFERENCIA GRUPAL NO EXISTE PARA EL CLIENTE 
        select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
        goto ERROR
     end
     
     if exists (select 1        
         from cob_cartera..ca_operacion with (nolock)
        where op_cliente    = @i_ente
          and op_ref_grupal = @w_tg_referencia_grupal)
    BEGIN
        select @w_existe_op_hija = 1 
    END 

    --DMO SE ACTUALIZA TASA OPERACION HIJAS
    exec @w_return =  cob_credito..sp_actualiza_tasa_grupal   
         @s_user             = @s_user,
         @s_term             = @s_term,
         @s_ofi              = @s_ofi,
         @s_date             = @s_date,     
         @i_tramite          =  @i_tramite,
         @i_operacion        = 'Q',      
         @i_num_integrantes  = @i_num_integrantes,
         @o_tasa             = @w_tasa out
    
    if @w_return <> 0
    begin
        select @w_error = @w_return
        goto ERROR
    end    
    

     if @i_participa_ciclo = 'S' and @w_existe_op_hija = 0
      begin
         --crear la operacion hija de la operacion padre
         exec @w_return = cob_credito..sp_crear_op_hija
              @s_ssn       = @s_ssn,
              @s_user      = @s_user,
              @s_sesn      = @s_sesn,
              @s_term      = @s_term,
              @s_date      = @s_date,
              @s_srv       = @s_srv,
              @s_lsrv      = @s_lsrv,
              @s_rol       = @s_rol,
              @s_ofi       = @s_ofi,
              @t_debug     = @t_debug,
              @t_file      = @t_file,
              @t_from      = @t_from,
              @i_tramite   = @i_tramite, --numero de tramite grupal
              @i_grupo     = @i_grupo,   --numero de grupo
              @i_ente      = @i_ente,    --numero de ente de integrante
              @i_custipo_credito = @i_custipo_credito,
              @i_tasa      = @w_tasa,
              @o_banco     = @w_banco    output
        if @w_return != 0
         begin
            select @w_error = @w_return
            goto ERROR
         end
         select @w_op_tramite_hija = op_tramite
         from cob_cartera.dbo.ca_operacion
         where op_banco = @w_banco
         --Asociar beneficiaros del ente al trámite
         if exists(select 1 from cobis.dbo.cl_beneficiario_seguro cbs where bs_nro_operacion = @i_ente * -1 and bs_tramite is null and bs_producto = 1)
         and not exists(select 1 from cobis.dbo.cl_beneficiario_seguro cbs where bs_tramite = @w_op_tramite_hija and bs_producto = 7)
         begin
            select @w_seguro = pa_char
            from cobis.dbo.cl_parametro
            where pa_nemonico = 'SEGCOL'
            
            insert into cobis.dbo.cl_beneficiario_seguro 
                  (bs_nro_operacion,            bs_producto,   bs_tipo_id,       bs_ced_ruc,                bs_nombres, bs_apellido_paterno, 
                   bs_apellido_materno,         bs_porcentaje, bs_parentesco,    bs_secuencia,              bs_ente,    bs_fecha_mod, 
                   bs_fecha_nac,                bs_telefono,   bs_direccion,     bs_provincia,              bs_ciudad,  bs_parroquia, 
                   bs_codpostal,                bs_localidad,  bs_ambos_seguros, bs_tramite,                bs_seguro)
            SELECT @w_op_tramite_hija * -1,     7,             bs_tipo_id,       bs_ced_ruc,                bs_nombres, bs_apellido_paterno, 
                   bs_apellido_materno,         bs_porcentaje, bs_parentesco,    bs_secuencia,              bs_ente,    getdate(), 
                   bs_fecha_nac,                bs_telefono,   (case when bs_direccion is null then '||' else bs_direccion end),     bs_provincia,              bs_ciudad,  bs_parroquia, 
                   bs_codpostal,                bs_localidad,  bs_ambos_seguros, @w_op_tramite_hija,        @w_seguro 
            FROM cobis.dbo.cl_beneficiario_seguro 
            WHERE bs_nro_operacion = @i_ente * -1 
            AND bs_producto = 1
            and bs_tramite is null
            if @@error != 0
            begin
                select  @w_error    = 725041              
                GOTO ERROR
            end
         end
         set @w_op_tramite_hija = null
         
      end
     else if (@w_existe_op_hija = 1)
      begin
        --INI WLO_S544332
        select @w_tg_referencia_grupal = null,
               @w_existe_op_hija       = 0   ,--No existe
               @w_banco                = null,
               @w_estado_op_cca        = null,
               @w_est_rechazado_tr     = 'X',
               @w_est_ing_tr           = 'N',
               @w_estado_tr            = null,
               @w_error                = 0
        
        --numero de operacion grupal
        select @w_tg_referencia_grupal = op_banco
        from   cob_cartera..ca_operacion
        where  op_tramite = @i_tramite
        
        if @@rowcount = 1 and @w_tg_referencia_grupal is not null
         begin
           --buscar datos de la operacion hija
           select @w_op_monto_hija     = op_monto,
                  @w_op_tramite_hija   = op_tramite,
                  @w_op_banco_hija     = op_banco,
                  @w_op_operacion_hija = op_operacion,
                  @w_existe_op_hija    = 1            --Existe
           from   cob_cartera..ca_operacion with (nolock)
           where  op_cliente    = @i_ente
           and    op_ref_grupal = @w_tg_referencia_grupal
         end
         
        --modificacion en operacion y tramite cuando el integrante participe y no participe
       --actualizacion en operacion y tramite hijo cuando el integrante no participe
       if @i_participa_ciclo = 'N'
        begin
          select @w_estado_op_cca = @w_est_anulado_cca,
                 @w_estado_tr     = @w_est_rechazado_tr
        end

       --actualizacion en operacion y tramite hijo cuando el integrante no participe
       if @i_participa_ciclo = 'S'
        begin
          select @w_estado_op_cca = @w_est_credito_cca,
                 @w_estado_tr     = @w_est_ing_tr
        end

       --actualizacion de estado operacion hija
       update cob_cartera..ca_operacion
       set    op_estado = @w_estado_op_cca
       where  op_operacion = @w_op_operacion_hija

       if @@error != 0
       begin
          select @w_error = 710002
          goto ERROR
       end
       else  --PQU
       --PQU se corrige esto if @w_error = 0
       begin
          --actualizacion de estado tramite hijo
          update cob_credito..cr_tramite
          set    tr_estado = @w_estado_tr
          where  tr_tramite = @w_op_tramite_hija

          if @@error != 0
           begin
             select @w_error = 2110396
             select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
             goto ERROR
           end
       end

      --actualizacion tipo tramite hijo 
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
            set tr_tipo    = @w_tipo_cre,
                tr_subtipo = @w_subtipo_cre              
          where tr_tramite = @w_op_tramite_hija

        if @@error != 0
        begin
         select @w_error = 2110396
         select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
         goto ERROR
        end
        
        
        if (@w_tipo_cre  = 'O' or @i_participa_ciclo = 'N') and exists(select 1 from cob_credito..cr_op_renovar where or_tramite = @w_op_tramite_hija)
        begin
            delete cob_credito..cr_op_renovar where or_tramite = @w_op_tramite_hija
            if @@error != 0
            begin
                select @w_error = 2110396
                select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
                goto ERROR
            end
        end
        else if (@w_tipo_cre != 'O' or @i_participa_ciclo = 'S') and not exists(select 1 from cob_credito..cr_op_renovar where or_tramite = @w_op_tramite_hija)
        begin

            select @w_capitaliza_padre  = or_capitaliza     
            from   cob_credito..cr_op_renovar
            where  or_tramite = @i_tramite
            
            --Insertar en la cr_op_renovar para la hija
            insert into cob_credito..cr_op_renovar 
            (or_tramite,     or_num_operacion,   or_producto,    or_capitaliza,          or_login,   or_fecha_ingreso)
            select 
            @w_op_tramite_hija, op_banco,           'CCA',          @w_capitaliza_padre,    @s_user,    @s_date
            from cob_cartera..ca_operacion
            inner join cob_credito..cr_op_renovar  on op_ref_grupal = or_num_operacion
            where or_tramite =  @i_tramite
            and op_cliente   = @i_ente
            and op_estado not in (99,3, 0, 6)
            
            select @w_error = @@error
            if @w_error != 0
            begin
                select @w_error = 2110396
                select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
                goto ERROR
            end 
        
        end
        
      end   
      
       if @i_participa_ciclo = 'S'
        begin
          --actualizacion de monto,sector y destino de operacion cartera hija
          select @w_op_monto_hija = null


          select 'FECHA VEN ' = di_fecha_ven  from cob_cartera.dbo.ca_dividendo cd 
          where di_operacion = @w_op_operacion_hija
          and di_dividendo  = 1 
          
          
          exec @w_return = cob_cartera..sp_xsell_actualiza_monto_op
               @i_banco           = @w_op_banco_hija,
               @s_user            = @s_user,
               @s_term            = @s_term,
               @s_ofi             = @s_ofi,
               @s_date            = @s_date,
               @i_monto_nuevo     = @i_tg_monto_aprobado,
             --@i_sector          = @i_sector,  --No se puede modificar sector en registro de montos
               @i_destino         = @i_sector,
               @i_grupal          = 'S',
               @i_tasa            = @w_tasa,
               @o_monto_calculado = @w_op_monto_hija out

          if @w_return != 0
           begin
             select @w_error = @w_return
             goto ERROR
           end
           
           select 'FECHA VEN ' = di_fecha_ven  from cob_cartera.dbo.ca_dividendo cd 
          where di_operacion = @w_op_operacion_hija
          and di_dividendo  = 1 
           
          --actualizacion de monto,sector y destino de tramite hijo
          select @w_tr_monto         = tr_monto,
                 @w_tr_monto_soli    = tr_monto_solicitado,
                 @w_tr_plazo         = tr_plazo,
                 @w_tr_tplazo        = tr_tipo_plazo,
                 @w_tr_origen_fondos = tr_origen_fondos,
                 @w_tr_num_dias      = tr_num_dias,
                 @w_tr_promocion     = tr_promocion,
                 @w_op_monto_hija    = op_monto
          from   cr_tramite,
                 cob_cartera..ca_operacion
          where  tr_tramite = op_tramite
          and    tr_tramite = @w_op_tramite_hija
        
          exec @w_return = sp_up_tramite_cca
               @s_date               = @s_date,
               @s_lsrv               = @s_lsrv,
               @s_ofi                = @s_ofi,
               @s_sesn               = @s_sesn,
               @s_srv                = @s_srv,
               @s_ssn                = @s_ssn,
               @s_term               = @s_term,
               @s_user               = @s_user,
               @i_plazo              = @w_tr_plazo, 
               @i_tplazo             = @w_tr_tplazo,
               @i_w_plazo            = @w_tr_plazo,
               @i_w_tplazo           = @w_tr_tplazo,
               @i_tramite            = @w_op_tramite_hija,
               @i_monto              = @w_op_monto_hija,
               @i_monto_solicitado   = @i_monto,
               @i_origen_fondos      = @w_tr_origen_fondos,
               @i_num_dias           = @w_tr_num_dias,
               @i_promocion          = @w_tr_promocion,
               @i_w_monto            = @w_tr_monto,
               @i_w_monto_solicitado = @w_tr_monto_soli,
             --@i_sector             = @i_sector,   --No se puede modificar sector en registro de montos
               @i_destino            = @i_tr_cod_actividad               
          if @w_return != 0
           begin
             select @w_error = @w_return
             goto ERROR
           end
           
           select 'FECHA VEN ' = di_fecha_ven  from cob_cartera.dbo.ca_dividendo cd 
          where di_operacion = @w_op_operacion_hija
          and di_dividendo  = 1 
          
           --Asociar beneficiaros del ente al trámite
           if exists(select 1 from cobis.dbo.cl_beneficiario_seguro cbs where bs_nro_operacion = @i_ente * -1 and bs_tramite is null and bs_producto = 1)
           and not exists(select 1 from cobis.dbo.cl_beneficiario_seguro cbs where bs_tramite = @w_op_tramite_hija and bs_producto = 7)
           begin
              select @w_seguro = pa_char
              from cobis.dbo.cl_parametro
              where pa_nemonico = 'SEGCOL'
              
              insert into cobis.dbo.cl_beneficiario_seguro 
                    (bs_nro_operacion,            bs_producto,   bs_tipo_id,       bs_ced_ruc,                bs_nombres, bs_apellido_paterno, 
                     bs_apellido_materno,         bs_porcentaje, bs_parentesco,    bs_secuencia,              bs_ente,    bs_fecha_mod, 
                     bs_fecha_nac,                bs_telefono,   bs_direccion,     bs_provincia,              bs_ciudad,  bs_parroquia, 
                     bs_codpostal,                bs_localidad,  bs_ambos_seguros, bs_tramite,                bs_seguro)
              SELECT @w_op_tramite_hija * -1,     7,             bs_tipo_id,       bs_ced_ruc,                bs_nombres, bs_apellido_paterno, 
                     bs_apellido_materno,         bs_porcentaje, bs_parentesco,    bs_secuencia,              bs_ente,    getdate(), 
                     bs_fecha_nac,                bs_telefono,   bs_direccion,     bs_provincia,              bs_ciudad,  bs_parroquia, 
                     bs_codpostal,                bs_localidad,  bs_ambos_seguros, @w_op_tramite_hija,        @w_seguro 
              FROM cobis.dbo.cl_beneficiario_seguro 
              WHERE bs_nro_operacion = @i_ente * -1 
              AND bs_producto = 1
              and bs_tramite is null
              if @@error != 0
              begin
                  select  @w_error    = 725041              
                  GOTO ERROR
              end
           end
           end
      --print 'No se crea la operación para el cliente ' + convert(varchar(10),@i_ente)
      end     
	  --Req ini 251290 TASA MORATORIA
	  
	  
         select @w_ref_grupal    = op_banco,
		        @w_operacion_cca = op_operacion
           from cob_cartera..ca_operacion
          where op_tramite = @i_tramite  
	 
		 select @w_num_integrantes = count(*)
               from cob_cartera..ca_operacion 
              where op_ref_grupal = @w_ref_grupal
                and op_estado =   @w_cod_cred

		 if @w_num_integrantes = @i_num_integrantes --Evaluo regla cuando todos los integrantes estén ingresados
		 begin
		 
	        exec @w_return =  cob_credito..sp_actualiza_tasa_grupal   
                 @s_user             = @s_user,
                 @s_term             = @s_term,
                 @s_ofi              = @s_ofi,
                 @s_date             = @s_date,     
                 @i_tramite          =  @i_tramite,
                 @i_operacion        = 'M',      
                 @i_num_integrantes  = @i_num_integrantes,
                 @o_tasa_mora        = @w_tasa_mora out
    
	        if @w_return <> 0
	        begin
               select @w_error = @w_return
               goto ERROR
	        end
	        if @w_tasa_mora is null 
	           select @w_tasa_mora=0
		  
	        select @w_tasa_mora_aux =  isnull(ro_porcentaje,0) 
		      from cob_cartera..ca_rubro_op
             where ro_operacion = @w_operacion_cca
               and ro_concepto = 'IMO'
	       
	        if (@w_tasa_mora <> @w_tasa_mora_aux) and (@w_tasa_mora <> 0) 
            begin
			    
               update cob_cartera..ca_rubro_op
			      set ro_porcentaje = @w_tasa_mora
                 from cob_cartera..ca_operacion 
                where ro_operacion = op_operacion
			      and ro_concepto = 'IMO'
			      and op_ref_grupal = @w_ref_grupal
                  and op_estado =    @w_cod_cred

               --update padre
               update cob_cartera..ca_rubro_op
                  set ro_porcentaje= @w_tasa_mora
                where ro_concepto= 'IMO'
                  and ro_operacion = @w_operacion_cca
	            	   
            end	 -- if (@w_tasa_mora <> @w_tasa_mora_aux)  
		 end --if @w_num_integrantes = @i_num_integrantes	  
	  --Req fin 251290
	  
    end
    --FIN WLO_S544332
    
   else if (@i_modo = 3)
    begin
	

        /*PQU se comenta temporalmente esto, hasta que se establezcan reglas con Finca Impact
        exec @w_return = sp_grupal_monto
        @s_ssn     = @s_ssn ,
        @s_rol     = @s_rol ,
        @s_ofi     = @s_ofi ,
        @s_sesn    = @s_sesn ,
        @s_user    = @s_user ,
        @s_term    = @s_term ,
        @s_date    = @s_date ,
        @s_srv     = @s_srv ,
        @s_lsrv    = @s_lsrv ,
        @i_operacion = 'R',
        @i_tramite   = @i_tramite
        
        if @w_return <> 0
        begin
            select @w_error = 21008,
                    @w_msg   = 'Error al determinar MONTO MAX Y PORCENTAJE DE INCREMENTO'
            goto ERROR
        end
        
        */ --fIN PQU 
        --Validacion de que la Directiva participe
        if @i_desde_interfaz = 'N'
        begin
           if exists(
            select 1 from 
            (select distinct cg_rol 
            from cobis..cl_cliente_grupo 
            inner join 
            cob_credito..cr_tramite_grupal 
            on cg_ente   = tg_cliente 
            where cg_estado  = 'V'
            and tg_tramite =  @i_tramite
            and cg_grupo   = tg_grupo
            and tg_monto   > 0
            and tg_participa_ciclo = 'S') as G
           RIGHT join 
               (select b.codigo 
               from   cobis..cl_tabla a,cobis..cl_catalogo b
               where  a.tabla = 'cl_rol_controlar' 
               and a.codigo = b.tabla
               and b.estado = 'V') as R
           on  G.cg_rol = R.codigo
           WHERE G.cg_rol IS NULL 
          )
           begin
               select @w_error = 2108051 --LOS INTEGRANTES DEL COMITE DEBEN PARTICIPAR
               goto ERROR
           end
        end
       
        
      -- LGU-INI: control de porcentaje y montos maximos 2017-06-21
      /*PQU se comenta temporalmente esto, hasta que se establezcan reglas con Finca Impact
      exec @w_return = sp_grupal_reglas
      @i_tramite = @i_tramite,
      @i_id_rule = 'VAL_TRAMITE',
      @o_msg1    = @o_msg1  output,
      @o_msg2    = @o_msg2  output,
      @o_msg3    = @o_msg3  output
      select @o_msg1 = @o_msg1 + '-' + @o_msg2 + '-' + @o_msg3+ '-' +@o_msg4
      -- LGU-FIN: control de porcentaje y montos maximos 2017-06-21
      */
     select @w_suma_montos       = sum(tg_monto),
            @w_suma_montos_aprob = sum(tg_monto_aprobado) --ACHP - Solicitado
       from cr_tramite_grupal
      where tg_tramite = @i_tramite
        and tg_participa_ciclo = 'S' --WLO_S544332
     -- Inicio Se copia de sp_pasa_cartera_interciclo porque los datos no quedaban consistentes
      select @w_operacionca       = op_operacion,
             @w_fecha_liq         = convert(varchar(10),op_fecha_liq,@w_formato_fecha),
             @w_moneda            = op_moneda,
             @w_fecha_ini         = convert(varchar(10),op_fecha_ini,@w_formato_fecha),
             @w_fecha_fin         = convert(varchar(10),op_fecha_fin,@w_formato_fecha),
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
             @w_plazo             = op_plazo,
             @w_tplazo            = op_tplazo,
             @w_banca             = op_banca,
             @w_promocion         = op_promocion,     --LPO Santander
             @w_acepta_ren        = op_acepta_ren,    --LPO Santander
             @w_no_acepta         = op_no_acepta,     --LPO Santander
             @w_emprendimiento    = op_emprendimiento --LPO Santander
        from cob_cartera..ca_operacion
       where op_tramite = @i_tramite
     
     select @w_plazo_no_vigente = count(1) - 1,
            @w_min_fecha_vig    = convert(varchar(10),min(di_fecha_ini),@w_formato_fecha)
       from cob_cartera..ca_dividendo
      where di_operacion = @w_operacionca --@w_tg_operacion
        and di_estado    = @w_est_novigente
        
        --Se añade validacion por problemas en montos
     if(@w_suma_montos > 0)
      begin
        -- CVA Inicio de copia de temporales porque despues queda inconsistente la data
        select @w_operacionca       = op_operacion,
               @w_fecha_liq         = convert(varchar(10),op_fecha_liq,@w_formato_fecha),
               @w_moneda            = op_moneda,
               @w_fecha_ini         = convert(varchar(10),op_fecha_ini,@w_formato_fecha),
               @w_fecha_fin         = convert(varchar(10),op_fecha_fin,@w_formato_fecha),
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
               @w_plazo             = op_plazo,
               @w_tplazo            = op_tplazo,
               @w_banca             = op_banca,
               @w_promocion         = op_promocion,        --LPO Santander
               @w_acepta_ren        = op_acepta_ren,       --LPO Santander
               @w_no_acepta         = op_no_acepta,        --LPO Santander
               @w_emprendimiento    = op_emprendimiento,   --LPO Santander
               @w_destino           = op_destino,          --PQU integracion                   
               @w_dia_pago          = op_dia_fijo          --PQU integracion
          from cob_cartera..ca_operacion
         where op_tramite = @i_tramite
       
          /*PQU este código no se está usando       
       -- BORRAR TEMPORALES
        exec @w_return = cob_cartera..sp_borrar_tmp
             @i_banco  = @w_banco,
             @s_user   = @s_user,
             @s_term   = @s_term
             
        if @w_return <> 0  --OJO controlar bien el error
        return @w_return
                
        ---PASAR A TEMPRALES CON LOS ULTIMOS DATOS
         exec @w_return          = cob_cartera..sp_pasotmp
             @s_term            = @s_term,
             @s_user            = @s_user,
             @i_banco           = @w_banco,
             @i_operacionca     = 'S',
             @i_dividendo       = 'S',
             @i_amortizacion    = 'S',
             @i_cuota_adicional = 'S',
             @i_rubro_op        = 'S',
             @i_nomina          = 'S'
            
         if @w_return <> 0  --Controlar bien el error
            return @w_return
            
         select @w_origen_fondos = tr_origen_fondos,  --PQU integracion
                @w_ciudad        = tr_ciudad_destino
           from cr_tramite
          where tr_tramite = @i_tramite
        */  -- fin PQU 
                    
        
        --DMO SE ACTUALIZA OPERACION PADRE
        exec @w_return =  cob_credito..sp_actualiza_grupal
        @i_banco        = @w_banco  ,
        @i_tramite      =  @i_tramite,
        @i_desde_cca    = 'N'
        
        if @w_return <> 0
        begin
            select @w_error = @w_return
            goto ERROR
        end    

        --DMO SE ELIMINA TEMPORALES, YA QUE sp_actualiza_grupal TRABAJA EN DEFINITIVAS
        if exists( select 1 from cob_cartera..ca_operacion_tmp where opt_banco = @w_banco)
        begin
            exec    @w_return = cob_cartera..sp_borrar_tmp
                @s_user       = @s_user,
                 --@s_sesn       = @s_sesn,
                @s_term       = @s_term,
                @i_desde_cre  = 'S',
                @i_banco      = @w_banco
        
            if @w_return != 0 
            begin
                select @w_error = @w_return
                goto   ERROR
            end
        end
        
        select @w_op_monto_padre  = op_monto
          from cob_cartera..ca_operacion
         where op_tramite = @i_tramite
        
        update cob_credito..cr_tramite 
        set tr_monto = @w_op_monto_padre ,
            tr_monto_solicitado = @w_suma_montos
        where tr_tramite = @i_tramite
        
        if @@error != 0
           begin
             select @w_error = 2110397
             goto ERROR
           end
        
        if @o_msg1 is not null
         begin
            print ' ALERTA 1: ' + @o_msg1 --'<<< Existen Prestamos que SUPERAN EL INCREMENTO PERMITIDO>>>'
         end
        if @o_msg2 is not null
         begin
            print ' ALERTA 2: ' + @o_msg2 --'<<<Existen Prestamos que SUPERAN EL MONTO MAXIMO>>>'
         end
        if @o_msg3 is not null
         begin
            print ' ALERTA 3: ' + @o_msg3 --'<<<Existen Prestamos que SUPERAN EL MONTO MAXIMO>>>'
         end
      end
     else
      begin
        select @w_error = 2110133 --Debe Ingresar los Montos
        goto ERROR
      end
    end
 return 0
end


if @i_operacion = 'D' -- Eliminar un cliente del tramite del grupo
begin
    select @w_monto = tg_monto
    from cr_tramite_grupal
    where tg_tramite = @i_tramite
    and tg_cliente = @i_ente
    
    select @w_monto = isnull(@w_monto ,0)
    
    begin tran
       --Recuperar datos antes de borrar para insercion en las ts
         insert into cob_credito..ts_tramite_grupal                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    tramite,               grupo,                       
         cliente,                monto,                 grupal, 
         operacion,              prestamo,              referencia_grupal,
         cuenta,                 cheque,                participa_ciclo,
         monto_aprobado,         ahorro,                monto_max, 
         bc_ln,                  incremento,            monto_ult_op,
         monto_max_calc,         nueva_op,              monto_min_calc,
         conf_grupal,            destino,               sector, 
         monto_recomendado,      estado,                id_rechazo,
         descripcion_rechazo)  
         select                   
         @s_ssn,                  21846,               'B',
         @s_date,                 @s_user,             @s_term,
         @s_ofi,                  'cr_tramite_grupal', @s_lsrv,
         @s_srv,                  @i_tramite,          tg_grupo,
         @i_ente,                 tg_monto,            tg_grupal, 
         tg_operacion,            tg_prestamo,         tg_referencia_grupal,
         tg_cuenta,               tg_cheque,           tg_participa_ciclo,
         tg_monto_aprobado,       tg_ahorro,           tg_monto_max, 
         tg_bc_ln,                tg_incremento,       tg_monto_ult_op,
         tg_monto_max_calc,       tg_nueva_op,         tg_monto_min_calc,
         tg_conf_grupal,          tg_destino,          tg_sector, 
         tg_monto_recomendado,    tg_estado,           tg_id_rechazo,
         tg_descripcion_rechazo 
         from cob_credito..cr_tramite_grupal
         where tg_cliente  = @i_ente 
         and tg_tramite    = @i_tramite
         --ERROR EN CREACION DE TRANSACCION DE SERVICIO
         if @@error <> 0 begin
            select @w_error = 1720049
            goto ERROR
         end
    
    
    
    
        delete cr_tramite_grupal
        where tg_tramite = @i_tramite
        and tg_cliente = @i_ente
        
        if @@error <> 0
        begin
            select @w_error = 150004 -- ERROR EN ELIMINACION
            goto ERROR
        end

        -- LGU-ini 22/ago/2017 regenerar la operacion, si elimina un cliente que solicita prestamo
        if @w_monto > 0
        begin
            exec @w_return = sp_grupal_monto
                @s_ssn       = @s_ssn ,
                @s_rol       = @s_rol ,
                @s_ofi       = @s_ofi ,
                @s_sesn      = @s_sesn ,
                @s_user      = @s_user ,
                @s_term      = @s_term ,
                @s_date      = @s_date ,
                @s_srv       = @s_srv ,
                @s_lsrv      = @s_lsrv ,
                @i_operacion = 'U',
                @i_tramite   = @i_tramite,
                @i_ente      = @i_ente,
                @i_modo      = 3
                
            if @w_return <> 0
            begin
                select @w_error = @w_return
                goto ERROR
            end
        end
    -- LGU-fin 22/ago/2017 regenerar la operacion, si elimina un cliente que solicita prestamo
    commit
    return 0
end

if @i_operacion = 'R' -- Calcula reglas
begin
    print 'Ingreso a Operacion R'
    -- LGU-INI: control de porcentaje y montos maximos 2017-06-21
    if exists(select 1 from cr_tramite_grupal tg where tg_tramite = @i_tramite) ----  LGU: para recalcular siempre - and ( tg_monto_max_calc is null or ------- tg_monto_ult_op is null ))
    begin
        exec @w_return      = sp_grupal_reglas
             @s_ssn         = @s_ssn ,
             @s_rol         = @s_rol ,
             @s_ofi         = @s_ofi ,
             @s_sesn        = @s_sesn ,
             @t_trn         = 1111    ,
             @s_user        = @s_user ,
             @s_term        = @s_term ,
             @s_date        = @s_date ,
             @s_srv         = @s_srv ,
             @s_lsrv        = @s_lsrv ,
             @i_tramite     = @i_tramite,
             @i_valida_part = 'N', --para que valide las reglas para los que no participan
             @i_id_rule     = 'INC_GRP'  -- encontral el % incremento y monto de ultima operacion cancelada
        if @w_return <> 0
        begin
            select @w_error = @w_return
            goto ERROR
        end
        
        exec @w_return      = sp_grupal_reglas
             @s_ssn         = @s_ssn ,
             @s_rol         = @s_rol ,
             @s_ofi         = @s_ofi ,
             @s_sesn        = @s_sesn ,
             @t_trn         = 1111    ,
             @s_user        = @s_user ,
             @s_term        = @s_term ,
             @s_date        = @s_date ,
             @s_srv         = @s_srv ,
             @s_lsrv        = @s_lsrv ,
             @i_tramite     = @i_tramite,
             @i_valida_part = 'N', --para que valide las reglas para los que no participan
             @i_id_rule     = 'MONTO_GRP'  -- encontrar el monto maximo del cliente
            
        if @w_return <> 0
        begin
            select @w_error = @w_return
            goto ERROR
        end
        -- LGU: 22/ago/2017 para que retorne si es llamado desde mantenimiento de GRUPOS
        if @i_modo = 1 return 0
    end
            -- LGU-FIN: control de porcentaje y montos maximos 2017-06-21
end

if @i_operacion = 'Q' -- consulta: valores de la solicitud de los integrantes del grupo
begin
    --PQU se añadió esto ya que un integrante puede ser luego añadido
    select @i_grupo = tr_grupo
    from   cob_credito..cr_tramite
    where  tr_tramite = @i_tramite
    
    insert into cr_tramite_grupal 
            (tg_tramite, tg_cliente, tg_monto, tg_grupal, tg_grupo,tg_participa_ciclo )
        select
            @i_tramite,   cg_ente  ,0        ,'S'       ,@i_grupo ,'N'
        from cobis..cl_grupo, cobis..cl_cliente_grupo cg
        where gr_grupo = @i_grupo
        and gr_grupo = cg_grupo
        and  cg_estado='V'
        and cg_ente not in (select tg_cliente from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
        
    select @w_tr_tipo = tr_tipo from cob_credito..cr_tramite where tr_tramite = @i_tramite
    --fin PQU
    
    --APP MOVIL
    if(@i_canal = 20 and @i_tipo_credito = 'R')
    begin
        select 'cliente'             = tg_cliente,
              'nombre'              = (select en_nomlar from cobis..cl_ente where en_ente = tg.tg_cliente),
              'monto'               =  tg_monto,
              'cuenta'              = (select ea_cta_banco from cobis..cl_ente_aux where ea_ente=tg.tg_cliente ),
              'cheque'              = tg_cheque,
              'participa_ciclo'     = tg_participa_ciclo,               --LPO Santander
              'monto_aprobado'      = isnull(tg_monto_aprobado,0),      --LPO Santander
              'ahorro'              = isnull(tg_ahorro,0),              --LPO Santander
              'monto_max'           = isnull(tg_monto_max_calc,0),      --LPO Santander
              'incremento'          = case when (gr_num_ciclo = 0 or tg_monto_ult_op = 999999999)  then tg_monto_max_calc else (tg_monto_ult_op*(1+tg_incremento/100)) end,
              'listas_negras'       = tg_bc_ln,                         --LPO Santander
              'role'                = cg_rol,
              'cycleNumber'         = isnull(cg_nro_ciclo,0),
              'rfc'                 = en_nit,
              'liquidguarantee'     = 0,
              'risklevel'           = (isnull(en_calificacion,'')),
              'destino'             = tg_sector,                       --PQU Finca
              'sector'              = tg_destino,
              'monto_recomendado'   = tg_monto_recomendado,
              'nroOp'               = ca.op_banco,
              'capitalBalance'      = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)                    
                                              from cob_cartera..ca_amortizacion
                                              where am_operacion = op_operacion 
                                              and am_concepto = 'CAP'),
              'interestBalance'     = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                              from cob_cartera..ca_amortizacion -- DFL: Se agregan campos
                                              where op_operacion = am_operacion
                                              and am_concepto = 'INT'),0),
              'otherBalance'        = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                              from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                              where am_operacion = di_operacion and
                                              am_operacion = op_operacion and
                                              am_dividendo = di_dividendo and
                                              am_concepto not in('CAP', 'INT') and
                                              di_estado not in (0)),0),
               'totalBalance'       = ((isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                from cob_cartera..ca_amortizacion -- DFL: Se agregan campos
                                                where op_operacion = am_operacion
                                                and am_concepto in ('INT', 'CAP')),0)) + 
                                                (isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                                where am_operacion = di_operacion and
                                                am_operacion = op_operacion and
                                                am_dividendo = di_dividendo and
                                                am_concepto not in('CAP', 'INT') and
                                                di_estado not in (0)),0))),
               'saldoVencido'       = (isnull((select sum(am_acumulado - am_pagado + am_gracia)
                                                from 
                                                cob_cartera..ca_dividendo,
                                                cob_cartera..ca_amortizacion
                                                where di_operacion = ca.op_operacion
                                                and di_operacion = am_operacion
                                                and di_dividendo = am_dividendo
                                                and di_estado = 2),0)),
               'tipo_credito'        = @i_tipo_credito,
               'sector_desc'         = (select (se_descripcion + ' ' + '('+ se_codigo +')') 
                                          from cobis..cl_subactividad_ec 
                                         where se_estado =    'V'
                                           and se_codigo = tg_sector)
        from cob_credito..cr_tramite_grupal tg
        inner join cob_cartera..ca_operacion ca on ca.op_operacion = tg.tg_operacion
        inner join cobis..cl_ente ce on ce.en_ente = tg.tg_cliente
        inner join cobis..cl_cliente_grupo cg on cg.cg_ente = tg.tg_cliente and cg.cg_grupo = tg.tg_grupo
        inner join cobis..cl_grupo gr on gr.gr_grupo = tg.tg_grupo  
        where tg_tramite = @i_tramite
        and cg.cg_estado = 'V'
        and ca.op_estado not in (0, 3,9,66,6)  
        and tg_participa_ciclo = 'S'
        and ca.op_ref_grupal is not null
        
        if (@@rowcount = 0)
        begin
            select @w_error = 2110125
            goto ERROR
        end
        
        return 0
    end
    
    --Renovacion
    if(@w_tr_tipo in ('R', 'F'))
    begin
       select @w_tg_referencia_grupal = isnull(op_banco,'')
         from cob_cartera..ca_operacion with (nolock)
        where op_tramite = @i_tramite     
       
       select 'cliente'             = tg_cliente,
              'nombre'              = (select en_nomlar from cobis..cl_ente where en_ente = tg.tg_cliente),
              'monto'               =  tg_monto,
              'cuenta'              = (select ea_cta_banco from cobis..cl_ente_aux where ea_ente=tg.tg_cliente ),
              'cheque'              = tg_cheque,
              'participa_ciclo'     = tg_participa_ciclo,               --LPO Santander
              'monto_aprobado'      = isnull(tg_monto_aprobado,0),      --LPO Santander
              'ahorro'              = isnull(tg_ahorro,0),              --LPO Santander
              'monto_max'           = isnull(tg_monto_max_calc,0),      --LPO Santander
              'incremento'          = case when (gr_num_ciclo = 0 or tg_monto_ult_op = 999999999)  then tg_monto_max_calc else (tg_monto_ult_op*(1+tg_incremento/100)) end,
              'listas_negras'       = tg_bc_ln,                         --LPO Santander
              'role'                = cg_rol,
              'cycleNumber'         = isnull(cg_nro_ciclo,0),
              'rfc'                 = en_nit,
              'liquidguarantee'     = ((isnull(tr_porc_garantia,0))*tg_monto/100),
              'risklevel'           = (isnull(en_calificacion,'')),
              'destino'             = tg_sector,                       --PQU Finca
              'sector'              = tg_destino,
              'monto_recomendado'   = tg_monto_recomendado,
              'nroOp'               = isnull((select STRING_AGG(ca.op_banco, ', ')
                                            from cob_cartera..ca_operacion ca
                                            inner join cob_credito..cr_op_renovar cr on ca.op_ref_grupal = cr.or_num_operacion
                                            where cr.or_tramite = tg.tg_tramite 
                                            and tg.tg_cliente = ca.op_cliente
                                            and ca.op_estado not in (0, 3, 6, 9, 66)) ,''),
              'capitalBalance'      = (select isnull(sum(isnull(am_cuota, 0) + isnull(am_gracia, 0) - isnull(am_pagado, 0)), 0)
                                            from cob_cartera..ca_operacion ca
                                            inner join cob_credito..cr_op_renovar cr on ca.op_ref_grupal = cr.or_num_operacion
                                            inner join cob_cartera..ca_amortizacion on am_operacion = ca.op_operacion and am_concepto = 'CAP'
                                            where cr.or_tramite = tg.tg_tramite 
                                            and tg.tg_cliente = ca.op_cliente
                                            and ca.op_estado not in (0, 3, 6, 9, 66)),
              'interestBalance'     = isnull((select isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)), 0)
                                                from cob_cartera..ca_operacion ca
                                                inner join cob_credito..cr_op_renovar cr on ca.op_ref_grupal = cr.or_num_operacion
                                                inner join cob_cartera..ca_amortizacion on am_operacion = ca.op_operacion
                                                where am_concepto = 'INT'
                                                and cr.or_tramite = tg.tg_tramite
                                                and tg.tg_cliente = ca.op_cliente
                                                and ca.op_estado not in (0, 3, 6, 9, 66)),0),
              'otherBalance'        = isnull((select isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)), 0)
                                                from cob_cartera..ca_operacion ca
                                                inner join cob_credito..cr_op_renovar cr on ca.op_ref_grupal = cr.or_num_operacion
                                                inner join cob_cartera..ca_amortizacion on am_operacion = ca.op_operacion
                                                inner join cob_cartera..ca_dividendo on am_operacion = di_operacion
                                                and am_operacion = ca.op_operacion
                                                and am_dividendo = di_dividendo
                                                where am_concepto not in ('CAP', 'INT')
                                                and di_estado not in (0)
                                                and cr.or_tramite = tg.tg_tramite
                                                and tg.tg_cliente = ca.op_cliente
                                                and ca.op_estado not in (0, 3, 6, 9, 66)),0),
               'totalBalance'       = (isnull((
                                            select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                            from cob_cartera..ca_operacion ca
                                            inner join cob_credito..cr_op_renovar cr on ca.op_ref_grupal = cr.or_num_operacion
                                            inner join cob_cartera..ca_amortizacion on am_operacion = ca.op_operacion
                                            where am_concepto in ('CAP', 'INT')
                                            and cr.or_tramite = tg.tg_tramite
                                            and tg.tg_cliente = ca.op_cliente
                                            and ca.op_estado not in (0, 3, 6, 9, 66)), 0)
                                        + isnull((
                                            select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                            from cob_cartera..ca_operacion ca
                                            inner join cob_credito..cr_op_renovar cr on ca.op_ref_grupal = cr.or_num_operacion
                                            inner join cob_cartera..ca_amortizacion on am_operacion = ca.op_operacion
                                            inner join cob_cartera..ca_dividendo on am_operacion = di_operacion
                                            and am_operacion = ca.op_operacion
                                            and am_dividendo = di_dividendo
                                            where am_concepto not in ('CAP', 'INT')
                                            and di_estado not in (0)
                                            and cr.or_tramite = tg.tg_tramite
                                            and tg.tg_cliente = ca.op_cliente
                                            and ca.op_estado not in (0, 3, 6, 9, 66)), 0)),
               'saldoVencido'         = 0,
               'tipo_credito'         = (case when EXISTS (select 1
                                                             from cob_cartera..ca_operacion ca
                                                            inner join cob_credito..cr_op_renovar cr on ca.op_ref_grupal = cr.or_num_operacion
                                                            where cr.or_tramite = tg.tg_tramite 
                                                              and tg.tg_cliente = ca.op_cliente
                                                              and ca.op_estado not in (0, 3, 6, 9, 66))
                                              then (                                              
                                                  case when EXISTS (select 1 from cob_credito..cr_tramite t with (nolock), cob_cartera..ca_operacion o with (nolock) 
                                                                       where t.tr_tramite = o.op_tramite and op_ref_grupal = @w_tg_referencia_grupal
                                                                         and o.op_cliente =  tg.tg_cliente)
                                                  then (select  case tr_subtipo when 'R' THEN 'R'
                                                                                when 'N' THEN 'F'
                                                                                else tr_tipo
                                                                                 end 
                                                                       from cob_credito..cr_tramite t with (nolock), cob_cartera..ca_operacion o with (nolock) 
                                                                      where t.tr_tramite = o.op_tramite and op_ref_grupal = @w_tg_referencia_grupal
                                                                        and o.op_cliente =  tg.tg_cliente)
                                                  else (select case ct.tr_subtipo when 'R' THEN 'R'
                                                                                  when 'N' THEN 'F'
                                                                                  else ct.tr_tipo
                                                                                  end)
                                                  end)
                                              else 'O'
                                              end),
               'sector_desc'          = (select (se_descripcion + ' ' + '('+ se_codigo +')') 
                                           from cobis..cl_subactividad_ec 
                                          where se_estado =    'V'
                                            and se_codigo = tg_sector)                                            
        from cob_credito..cr_tramite_grupal tg
       inner join cob_credito..cr_tramite ct on ct.tr_tramite = tg.tg_tramite
       inner join cobis..cl_ente ce on ce.en_ente = tg.tg_cliente
       inner join cobis..cl_cliente_grupo cg on cg.cg_ente = tg.tg_cliente and cg.cg_grupo = tg.tg_grupo
       inner join cobis..cl_grupo gr on gr.gr_grupo = tg.tg_grupo            
       where cg.cg_grupo = @i_grupo    
       and cg.cg_estado = 'V'
       and tg.tg_tramite = @i_tramite
       
      if (@@rowcount = 0 and @i_canal = 3)
      begin
          select @w_error = 2110125
          goto ERROR
      end
    end
    --Reestructuracion, financiamiento
    else if(@w_tr_tipo in ('E'))
    begin
        select 'cliente'             = tg_cliente,
               'nombre'              = (select en_nomlar from cobis..cl_ente where en_ente = tg.tg_cliente),
               'monto'               = case when (tg_monto = 0 or tg_monto is null) then (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)
                                                                                          from cob_cartera..ca_amortizacion
                                                                                          where am_operacion = op_operacion 
                                                                                          and am_concepto = 'CAP')
                                       else tg_monto end,
               'cuenta'              = (select ea_cta_banco from cobis..cl_ente_aux where ea_ente=tg.tg_cliente ),
               'cheque'              = tg_cheque,
               'participa_ciclo'     = 'S',               --LPO Santander
               'monto_aprobado'      = case when (tg_monto_aprobado = 0 or tg_monto_aprobado is null) then (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)
                                                                                                            from cob_cartera..ca_amortizacion
                                                                                                            where am_operacion = op_operacion 
                                                                                                            and am_concepto = 'CAP')
                                       else tg_monto_aprobado end,      --LPO Santander
               'ahorro'              = isnull(tg_ahorro,0),              --LPO Santander
               'monto_max'           = isnull(tg_monto_max_calc,0),      --LPO Santander
               'incremento'          = case when (gr_num_ciclo = 0 or tg_monto_ult_op = 999999999)  then tg_monto_max_calc else (tg_monto_ult_op*(1+tg_incremento/100)) end,
               'listas_negras'       = tg_bc_ln,                         --LPO Santander
               'role'                = cg_rol,
               'cycleNumber'         = isnull(cg_nro_ciclo,0),
               'rfc'                 = en_nit,
               'liquidguarantee'     = ((isnull(tr_porc_garantia,0))*tg_monto/100),
               'risklevel'           = (isnull(en_calificacion,'')),
               'destino'             = tg_sector,                       --PQU Finca
               'sector'              = tg_destino,
               'monto_recomendado'   = case when (tg_monto_recomendado = 0 or tg_monto_recomendado is null) then (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)                    
                                                                                                                  from cob_cartera..ca_amortizacion
                                                                                                                  where am_operacion = op_operacion 
                                                                                                                  and am_concepto = 'CAP')
                                        else tg_monto_recomendado end,
               'nroOp'               = ca.op_banco,
               'capitalBalance'      = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)                    
                                               from cob_cartera..ca_amortizacion
                                               where am_operacion = op_operacion 
                                               and am_concepto = 'CAP'),
               'interestBalance'     = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                               from cob_cartera..ca_amortizacion -- DFL: Se agregan campos
                                               where op_operacion = am_operacion
                                               and am_concepto = 'INT'),0),
               'otherBalance'        = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                               from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                               where am_operacion = di_operacion and
                                               am_operacion = op_operacion and
                                               am_dividendo = di_dividendo and
                                               am_concepto not in('CAP', 'INT') and
                                               di_estado not in (0)),0),
                'totalBalance'       = ((isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                 from cob_cartera..ca_amortizacion -- DFL: Se agregan campos
                                                 where op_operacion = am_operacion
                                                 and am_concepto in ('INT', 'CAP')),0)) + 
                                                 (isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                 from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                                 where am_operacion = di_operacion and
                                                 am_operacion = op_operacion and
                                                 am_dividendo = di_dividendo and
                                                 am_concepto not in('CAP', 'INT') and
                                                 di_estado not in (0)),0))),
               'saldoVencido'        = 0,                                                
               'tipo_credito'        = ct.tr_tipo,
               'sector_desc'         = (select (se_descripcion + ' ' + '('+ se_codigo +')') 
                                          from cobis..cl_subactividad_ec 
                                         where se_estado =    'V'
                                           and se_codigo = tg_sector)              
        from cob_cartera..ca_operacion ca
        inner join cob_credito..cr_op_renovar cr on ca.op_ref_grupal = cr.or_num_operacion
        inner join cob_credito..cr_tramite_grupal tg on cr.or_tramite = tg.tg_tramite and tg.tg_cliente = ca.op_cliente
        inner join cobis..cl_ente ce on ce.en_ente = tg.tg_cliente
        inner join cobis..cl_cliente_grupo cg on cg.cg_ente = tg.tg_cliente and cg.cg_grupo = tg.tg_grupo
        inner join cob_credito..cr_tramite ct on ct.tr_tramite = tg.tg_tramite
        inner join cobis..cl_grupo gr on gr.gr_grupo = tg.tg_grupo            
        where cr.or_tramite = @i_tramite
        and cg.cg_grupo = @i_grupo    
        and cg.cg_estado = 'V'
        and ca.op_estado not in (0, 3, 6, 9,66)  
        
       if (@@rowcount = 0 and @i_canal = 3)
       begin
           select @w_error = 2110125
           goto ERROR
       end         
       
    end
    else
    begin
       if exists(select 1 from cr_tramite_grupal tg where tg_tramite = @i_tramite)
       begin
           select
               'cliente'             = tg_cliente,
               'nombre'              = (select en_nomlar from cobis..cl_ente where en_ente = tg.tg_cliente),
               'monto'               =  tg_monto,
               'cuenta'              = (select ea_cta_banco from cobis..cl_ente_aux where ea_ente=tg.tg_cliente ),
               'cheque'              = tg_cheque,
               'participa_ciclo'     = tg_participa_ciclo,               --LPO Santander
               'monto_aprobado'      = isnull(tg_monto_aprobado,0),      --LPO Santander
               'ahorro'              = isnull(tg_ahorro,0),              --LPO Santander
               'monto_max'           = isnull(tg_monto_max_calc,0),      --LPO Santander
               'incremento'          = case when (gr_num_ciclo = 0 or tg_monto_ult_op = 999999999)  then tg_monto_max_calc else (tg_monto_ult_op*(1+tg_incremento/100)) end,
               'listas_negras'       = tg_bc_ln,                         --LPO Santander
               'role'                = cg_rol,
               'cycleNumber'         = isnull(cg_nro_ciclo,0),
               'rfc'                 = en_nit,
               'liquidguarantee'     = ((isnull(tr_porc_garantia,0))*tg_monto/100),
               'risklevel'           = (isnull(en_calificacion,'')),
               'destino'             = tg_sector,                       --PQU Finca
               'sector'              = tg_destino,
               'monto_recomendado'   = tg_monto_recomendado,
               'nroOp'               = '',
               'capitalBalance'      = 0,
               'interestBalance'     = 0,
               'otherBalance'        = 0,
               'totalBalance'        = 0,
               'saldoVencido'        = 0,              
               'tipo_credito'        = 'O',
               'sector_desc'         = (select (se_descripcion + ' ' + '('+ se_codigo +')') 
                                          from cobis..cl_subactividad_ec 
                                         where se_estado =    'V'
                                           and se_codigo = tg_sector)               
           from  cr_tramite_grupal tg,cobis..cl_cliente_grupo cg, cobis..cl_ente,  cob_credito..cr_tramite, cobis..cl_grupo
           where tg_tramite = @i_tramite
           and   tg_cliente = cg_ente
           and   cg_estado  ='V'
           and   tg_cliente = en_ente
           and   tg_tramite = tr_tramite
           and   gr_grupo   = tg_grupo
           and   cg_grupo   = @i_grupo
       
           if (@@rowcount = 0 and @i_canal = 3)
           begin
               select @w_error = 2110125
               goto ERROR
           end
       
           return 0
       end
       else
       begin
           select @i_operacion = 'G'
       end
    end
    
end

if @i_operacion = 'G' -- consulta de los miembros del grupo que van a solicitar el prestamo
begin
    select
        'cliente' = cg_ente,
        'nombre'  = (select en_nomlar from cobis..cl_ente where en_ente = cg.cg_ente),
        'monto'   = 0
    from cobis..cl_grupo, cobis..cl_cliente_grupo cg
    where gr_grupo  = @i_grupo
    and   gr_grupo  = cg_grupo
    and   cg_estado = 'V'

    insert into cr_tramite_grupal (tg_tramite, tg_cliente, tg_monto, tg_grupal, tg_grupo )
    select
        @i_tramite,
        cg_ente,
        0,
        'S',
        @i_grupo
    from cobis..cl_grupo, cobis..cl_cliente_grupo cg
    where gr_grupo = @i_grupo
    and gr_grupo = cg_grupo
    and  cg_estado='V'

    if @@error <> 0
    begin
        select @w_error = 150000 -- ERROR EN INSERCION
        goto ERROR
    end
    return 0
end

if @i_operacion = 'C' -- consulta: para servicio de recuperar data de la solicitud - para enviar a la movil - sp_grupal_xml
begin
    if exists( select 1 from cr_tramite_grupal tg where tg_tramite = @i_tramite )
    begin
        declare @i_inst_proc int
        select @i_inst_proc = io_id_inst_proc,
               @i_grupo     = io_campo_1
        from cob_workflow..wf_inst_proceso where io_campo_3 = @i_tramite

        exec cob_pac..sp_grupo_busin
        @i_operacion       = 'M',
        @i_grupo           = @i_grupo,
        @t_trn             = 800,
        @o_actualiza_movil = @w_actualiza_movil output

        select
        'applicationDate'       = (select format(op_fecha_liq,'yyyy-MM-ddTHH:mm:ss.fffZ')),
        'applicationType'       = op_toperacion,
        'groupAgreeRenew'       = TR.tr_acepta_ren,
        'groupAmount'           = op_monto,
        'groupCycle'            = isnull(G.gr_num_ciclo,0),
        'groupName'             = G.gr_nombre,
        'groupNumber'           = G.gr_grupo,
        'office'                = (select of_nombre from cobis..cl_oficina where of_filial = 1 and of_oficina = TR.tr_oficina),
        'officer'               = (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial
                                          where oc_funcionario = fu_funcionario and oc_oficial = TR.tr_oficial),
        'processinstance'       = @i_inst_proc,
        'promotion'             = TR.tr_promocion,
        'rate'                  = convert (varchar(30),(select ro_porcentaje from cob_cartera..ca_rubro_op
                                           where  ro_operacion = OP.op_operacion
                                           and OP.op_tramite = TR.tr_tramite
                                           and ro_concepto  = 'int')),
        'reasonNotAccepting'    = tr_no_acepta,
        'term'                  = tr_plazo,
        'flagModifyApplication' = @w_actualiza_movil
        from cob_cartera..ca_operacion OP,cobis..cl_grupo G, cob_credito..cr_tramite TR
        where OP.op_tramite=TR.tr_tramite
        and   OP.op_cliente=G.gr_grupo
        and   TR.tr_tramite =@i_tramite
    end
    return 0
end

if @i_operacion = 'X' -- Se consulta actividad del crédito
begin
     select @w_filtro = '%' + @i_pre_filtro + '%'
    
     select 'codigo'      = se_codigo,
            'descripcion' = (se_descripcion + ' ' + '('+ se_codigo +')') 
    from cobis..cl_subactividad_ec
      where se_estado =    'V'
        and (se_codigo like @w_filtro or UPPER(se_descripcion) like UPPER(@w_filtro))
        
return 0
end

if @i_operacion = 'Y' -- Se consulta sector del crédito
begin
    select @w_cod_sector = codigo from cobis..cl_tabla where tabla = 'cc_sector'

    select
          'codigo' = codigo,
          'valor'  = valor
    from cobis..cl_catalogo
    where tabla = @w_cod_sector
return 0
end

if @i_operacion = 'Z' -- Se consulta oficiales
begin
 if exists (select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite)
  begin
    select
          'codigo'         = c.oc_oficial,    --WLO_S542854
          'funcionario'    = a.fu_nombre
    from  cobis..cl_funcionario a, cob_credito..cr_tramite b,
          cobis..cc_oficial c                 --WLO_S542854
    where a.fu_funcionario = c.oc_funcionario --WLO_S542854
    and   c.oc_oficial     = b.tr_oficial     --WLO_S542854
    and   a.fu_oficina     = b.tr_oficina
    and   b.tr_tramite     = @i_tramite
    union
    select
          'codigo'       = oc_oficial,        --WLO_S542854
          'funcionario'  = fu_nombre
    from  cobis..cl_funcionario,
          cobis..cc_oficial
    where fu_oficina     = @s_ofi
    and   fu_funcionario = oc_funcionario
  end
 else
  begin
    select
          'codigo'       = oc_oficial,        --WLO_S542854
          'funcionario'  = fu_nombre
    from  cobis..cl_funcionario,
          cobis..cc_oficial
    where fu_oficina     = @s_ofi
    and   fu_funcionario = oc_funcionario
  end
 return 0
end


if @i_operacion = 'F' -- consulta: valores de la solicitud de los integrantes del grupo que no participan
begin
    select @w_tr_tipo = tr_tipo from cob_credito..cr_tramite where tr_tramite = @i_tramite

    if(@w_tr_tipo not in ('R', 'F'))
    begin
        select @w_error = 2110416
        goto ERROR
    end
    
    select 
    'cliente'             = ca.op_cliente,
    'nombre'              = (select isnull(en_nombre + ' ','') + isnull(p_s_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido,'')
                            from cobis..cl_ente where en_ente = ca.op_cliente ),
    'nroOp'               = ca.op_banco,
    'capitalBalance'      = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)                    
                                                from cob_cartera..ca_amortizacion
                                                where am_operacion = op_operacion 
                                                and am_concepto = 'CAP'),
    'interestBalance'     = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                from cob_cartera..ca_amortizacion -- DFL: Se agregan campos
                                                where op_operacion = am_operacion
                                                and am_concepto = 'INT'),0),
    'otherBalance'        = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                                where am_operacion = di_operacion and
                                                am_operacion = op_operacion and
                                                am_dividendo = di_dividendo and
                                                am_concepto not in('CAP', 'INT') and
                                                di_estado not in (0)),0),
    'totalBalance'       = ((isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                    from cob_cartera..ca_amortizacion -- DFL: Se agregan campos
                                                    where op_operacion = am_operacion
                                                    and am_concepto in ('INT', 'CAP')),0)) + 
                                                    (isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                    from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                                    where am_operacion = di_operacion and
                                                    am_operacion = op_operacion and
                                                    am_dividendo = di_dividendo and
                                                    am_concepto not in('CAP', 'INT') and
                                                    di_estado not in (0)),0)))
    from cob_credito..cr_op_renovar cr
    inner join cob_cartera..ca_operacion ca on cr.or_num_operacion = ca.op_ref_grupal
    inner join cob_credito..cr_tramite_grupal tg on cr.or_tramite = tg.tg_tramite and tg.tg_cliente = ca.op_cliente
    where tg_participa_ciclo = 'N'
    and tg_tramite = @i_tramite
    and ca.op_estado not in (0, 3,9,66, 6)
    order by ca.op_cliente
    
    if @@rowcount = 0
    begin
        select @w_error = 2110419 
        goto ERROR
    end 
end


return 0

ERROR_CONCAT:
   select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo , @w_error, @s_culture)
   goto ERROR

ERROR:
    begin --Devolver mensaje de Error
        while @@trancount > 0 rollback

        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_msg   = @w_msg_error,
             @i_num   = @w_error
        return @w_error
    end
    
go
