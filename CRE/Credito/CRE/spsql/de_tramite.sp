/************************************************************************/
/*  Archivo:                de_tramite.sp                               */
/*  Stored procedure:       sp_de_tramite                               */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Felipe Borja                                */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Felipe Borja     Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_de_tramite' and type = 'P')
   drop proc sp_de_tramite
go

create proc sp_de_tramite(
   @s_ssn                    int          = null,
   @s_user                   login        = null,
   @s_sesn                   int          = null,
   @s_term                   varchar(30)  = null,
   @s_date                   datetime     = null,
   @s_srv                    varchar(30)  = null,
   @s_lsrv                   varchar(30)  = null,
   @s_rol                    smallint     = null,
   @s_ofi                    smallint     = null,
   @s_org_err                char(1)      = null,
   @s_error                  int          = null,
   @s_sev                    tinyint      = null,
   @s_msg                    descripcion  = null,
   @s_org                    char(1)      = null,
   @t_rty                    char(1)      = null,
   @t_trn                    smallint     = null,
   @t_debug                  char(1)      = 'N',
   @t_file                   varchar(14)  = null,
   @t_from                   varchar(30)  = null,
   @i_operacion              char(1)      = null,
   @i_tramite                int          = null,
   @i_toperacion             catalogo     = null,
   /* registro anterior */
   @i_w_tipo                 char(1)      = null,
   @i_w_truta                tinyint      = null,
   @i_w_oficina_tr           smallint     = null,
   @i_w_usuario_tr           login        = null,
   @i_w_fecha_crea           datetime     = null,
   @i_w_oficial              smallint     = null,
   @i_w_sector               catalogo     = null,
   @i_w_ciudad               int          = null,
   @i_w_estado               char(1)      = null,
   --@i_w_nivel_ap             tinyint      = null,
   --@i_w_fecha_apr            datetime     = null,
   --@i_w_usuario_apr          login        = null,
   @i_w_numero_op            int          = null,
   @i_w_numero_op_banco      cuenta       = null,
   @i_w_proposito            catalogo     = null,
   @i_w_razon                catalogo     = null,
   @i_w_txt_razon            varchar(255) = null,
   @i_w_efecto               catalogo     = null,
   @i_w_cliente              int          = null,
   @i_w_grupo                int          = null,
   @i_w_fecha_inicio         datetime     = null,
   @i_w_num_dias             smallint     = 0,
   @i_w_per_revision         catalogo     = null,
   @i_w_condicion_especial   varchar(255) = null,
   @i_w_linea_credito        int          = null,
   @i_w_toperacion           catalogo     = null,
   @i_w_producto             catalogo     = null,
   @i_w_monto                money        = 0,
   @i_w_moneda               tinyint      = 0,
   @i_w_periodo              catalogo     = null,
   @i_w_num_periodos         smallint     = 0,
   @i_w_destino              catalogo     = null,
   @i_w_ciudad_destino       int          = null,
   --@i_w_cuenta_corriente     cuenta       = null,
   --@i_w_garantia_limpia      char         = null,
   @i_w_renovacion           smallint     = null,
   --@i_w_oficial_conta        smallint   = null,
   --@i_w_cem                  money      = null,
   @i_tran_servicio          char(1)      = 'S',   --DAG
   @i_migra                  char(1)      = 'N'   --Bandera para reconocer lineas migradas
)
as
declare
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_linea_credito      int,
   @w_operacion          int,
   @w_operacion_banco    cuenta,
   @w_tipo_tramite       char(1),
   @w_garantia_t         varchar(64),   -- SPA
   @w_valor_resp_garantia money,         -- SPA
   @w_codigo_externo     varchar(64),
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo               varchar(64),
   @w_custodia           int,
   @w_moneda             tinyint,
   @w_disponible         money,
   @w_valor_cot_mga      money,
   @w_disponible_nue     money,
   @w_toperacion         catalogo,
   @w_cuenta             cuenta,
   @w_numero_banco       cuenta,
   @w_negocio            varchar(16),
   @w_op_tipo            char(1),
   @w_est_anulado        tinyint,
   @w_error              int

set @w_sp_name = 'sp_de_tramite'

/* Debug */
/*********/

if @t_debug = 'S'
begin
    exec cobis..sp_begin_debug @t_file = @t_file
    select '/** Stored Procedure **/ ' = @w_sp_name,
      s_ssn        = @s_ssn,
      s_user         = @s_user,
      s_sesn         = @s_sesn,
      s_term         = @s_term,
      s_date         = @s_date,
      s_srv        = @s_srv,
      s_lsrv         = @s_lsrv,
      s_rol        = @s_rol,
      s_ofi        = @s_ofi,
      s_org_err      = @s_org_err,
      s_error        = @s_error,
      s_sev        = @s_sev,
      s_msg        = @s_msg,
      s_org        = @s_org,
      t_rty        = @t_rty,
      t_trn        = @t_trn,
      t_debug        = @t_debug,
      t_file         = @t_file,
      t_from         = @t_from,
      i_operacion      = @i_operacion,
      i_tramite      = @i_tramite,
      i_w_tipo       = @i_w_tipo,
      i_w_truta      = @i_w_truta,
      i_w_oficina_tr       = @i_w_oficina_tr,
      i_w_usuario_tr       = @i_w_usuario_tr,
      i_w_fecha_crea       = @i_w_fecha_crea,
      i_w_oficial      = @i_w_oficial,
      i_w_sector       = @i_w_sector,
      i_w_ciudad       = @i_w_ciudad,
      i_w_estado       = @i_w_estado,
      --i_w_nivel_ap       = @i_w_nivel_ap,
      --i_w_fecha_apr      = @i_w_fecha_apr,
      --i_w_usuario_apr      = @i_w_usuario_apr,
      i_w_numero_op      = @i_w_numero_op,
      i_w_numero_op_banco    = @i_w_numero_op_banco,
      i_w_proposito      = @i_w_proposito,
      i_w_razon      = @i_w_razon,
      i_w_txt_razon      = @i_w_txt_razon,
      i_w_efecto       = @i_w_efecto,
      i_w_cliente      = @i_w_cliente,
      i_w_grupo      = @i_w_grupo,
      i_w_fecha_inicio     = @i_w_fecha_inicio,
      i_w_num_dias       = @i_w_num_dias,
      i_w_per_revision     = @i_w_per_revision,
      i_w_condicion_especial     = @i_w_condicion_especial,
      i_w_linea_credtio    = @i_w_linea_credito,
      i_w_toperacion       = @i_w_toperacion,
      i_w_producto       = @i_w_producto,
      i_w_monto      = @i_w_monto,
      i_w_moneda       = @i_w_moneda,
      i_w_periodo      = @i_w_periodo,
      i_w_num_periodos     = @i_w_num_periodos,
      i_w_destino      = @i_w_destino,
      i_w_ciudad_destino     = @i_w_ciudad_destino,
      --i_w_cuenta_corriente     = @i_w_cuenta_corriente,
      --i_w_garantia_limpia    = @i_w_garantia_limpia,
      i_w_renovacion       = @i_w_renovacion
      --i_w_oficial_conta    = @i_w_oficial_conta,
      -- i_w_cem         = @i_w_cem
    exec cobis..sp_end_debug
end

select @w_tipo_tramite = tr_tipo,
       @w_toperacion   = tr_toperacion
from   cr_tramite
where  tr_tramite      = @i_tramite

select  @w_operacion = null

select @w_operacion       = op_operacion,
       @w_operacion_banco = op_banco,
       @w_op_tipo         = op_tipo
from   cob_cartera..ca_operacion
where  op_tramite         = @i_tramite

BEGIN TRAN

if @i_tran_servicio = 'S' begin
    /** Transaccion de Servicio **/
    insert into ts_tramite
        (secuencial, tipo_transaccion, clase, fecha, usuario, terminal,
         oficina, tabla, lsrv, srv, tramite, tipo, oficina_tr, usuario_tr,
         fecha_crea, oficial, sector, ciudad, estado,
         numero_op, numero_op_banco, proposito, razon,
         txt_razon, efecto, cliente, grupo, fecha_inicio, num_dias, per_revision,
         condicion_especial, linea_credito, toperacion, producto,
         monto, moneda, periodo, num_periodos, destino, ciudad_destino,
         renovacion
        )
    select
         @s_ssn, @t_trn, 'B', @s_date, @s_user, @s_term,
         @s_ofi, 'cr_tramite', @s_lsrv, @s_srv, @i_tramite, tr_tipo, tr_oficina, tr_usuario,
         tr_fecha_crea, tr_oficial, tr_sector, tr_ciudad, tr_estado,
         tr_numero_op, tr_numero_op_banco, tr_proposito, tr_razon,
         tr_txt_razon, tr_efecto, tr_cliente, tr_grupo, tr_fecha_inicio, tr_num_dias, tr_per_revision,
         tr_condicion_especial, tr_linea_credito, tr_toperacion, tr_producto,
         tr_monto, tr_moneda, tr_periodo, tr_num_periodos, tr_destino, tr_ciudad_destino,
         tr_renovacion
    from cr_tramite
    where tr_tramite = @i_tramite
    if @@error != 0
    begin
        set @w_error = 2103003 -- Error en insercion de transaccion de servicio
        goto ERROR
    end
end

if @w_operacion is not null
begin
    -- ELIMINACION DEL REGISTRO CCA
    -- NO SE LO VA A HACER, QUEDA PARA ANALISIS EN CASO DE MEJOR PERFORMANCE EN EL BANCO
    -- exec @w_return = cob_cartera..sp_borra_tablas_cca @i_operacionca = @w_operacion,
    --                                                   @i_banco       = @w_operacion_banco
    -- if @w_return != 0
    -- begin
    --     set @w_error = @w_return
    --     goto ERROR
    -- end

    -- ACTUALIZA EL ESTADO DE LA OPERACION DE CCA
    exec @w_return = cob_cartera..sp_estados_cca @o_est_anulado = @w_est_anulado out
    if @w_return != 0
    begin
        set @w_error = @w_return
        goto ERROR
    end

    update cob_cartera..ca_operacion
    set    op_estado    = @w_est_anulado
    where  op_operacion = @w_operacion
    if @@rowcount != 1
    begin
        set @w_error = 141183 -- No existe la operacion de cartera
        goto ERROR
    end
end
    -- Eliminacion de Registros de Tablas Asociadas
    -- NO SE LO VA A HACER, QUEDA PARA ANALISIS EN CASO DE MEJOR PERFORMANCE EN EL BANCO
    -- delete cr_documento where do_tramite = @i_tramite
    -- delete cr_deudores where de_tramite = @i_tramite
    -- delete cr_instrucciones where in_tramite = @i_tramite
    -- delete cr_excepciones where ex_tramite = @i_tramite
    -- delete cr_observaciones where ob_tramite = @i_tramite
    -- delete cr_ob_lineas where ol_tramite = @i_tramite
    -- delete cr_ruta_tramite where rt_tramite = @i_tramite
    -- delete cr_datos_tramites where dt_tramite = @i_tramite
    -- delete cr_op_renovar where or_tramite = @i_tramite
    -- delete cr_ctalin_cancelar where cc_tramite = @i_tramite
    -- delete cr_anticipo where an_tram_anticipo = @i_tramite
    -- delete cr_gar_anteriores where ga_tramite = @i_tramite
    -- delete cr_modif_tramite where mt_tramite = @i_tramite
    -- delete cr_financiamientos where fi_tramite = @i_tramite
    -- delete cr_desembolso where dm_operacion = @w_operacion
    -- delete cob_custodia..cu_poliza_asociada where pa_tramite = @i_tramite


    -- Si es descuento de documentos borra los registros relacionados
    -- --------------------------------------------------------------
    if @w_op_tipo = 'D'
    begin
        exec @w_return = sp_fgrupos
                @s_ssn  = @s_ssn,
                @s_date = @s_date,
                @s_user = @s_user,
                @s_term = @s_term,
                @s_ofi  = @s_ofi,
                @s_srv  = @s_srv,
                @s_lsrv = @s_lsrv,
                @t_rty  = @t_rty,
                @t_trn  = 21971, --@t_trn,
                @t_debug  = @t_debug,
                @t_file  = @t_file,
                @t_from  = @t_from,
                @i_operacion = D,
                @i_tramite = @i_tramite,
                @i_toperacion = @i_toperacion
        if @w_return != 0
        begin
            set @w_error = @w_return
            goto ERROR
        end
    end

    -- Libera garantias asociadas al tramite y actualiza su disponible
    -- NO SE LO VA A HACER, QUEDA PARA ANALISIS EN CASO DE MEJOR PERFORMANCE EN EL BANCO
    -- exec @w_return = sp_lib_gar_asociada @s_date    = @s_date,
    --                                      @i_tramite = @i_tramite
    -- if @w_error != 0
    -- begin
    --     set @w_error = @w_return
    --     goto ERROR
 -- end


    -- ACTUALIZA EL ESTADO DE LA GARANTIA DEL TRAMITE
    update cob_credito..cr_gar_propuesta
    set    gp_est_garantia = 'C'
    where  gp_tramite      = @i_tramite


    -- Borrar linea de credito y datos de la linea
    -- -------------------------------------------
    select @w_linea_credito = li_numero,
           @w_cuenta        = NULL,--li_cuenta,
           @w_numero_banco  = li_num_banco
    from   cr_linea
    where  li_tramite = @i_tramite
    if @@rowcount > 0
    begin
        if @i_migra = 'S'
        begin
            delete cobis..cl_det_producto
            where  dp_det_producto = 21
            and    dp_cuenta       = @w_numero_banco
            if @@error != 0
            begin
                set @w_error = 220054 -- Error: hubo un error al eliminar los registros
                goto ERROR
            end
                -- SI ES LINEA DE SOBREGIRO, ACTUALIZA EN CUENTAS CORRIENTES EL NUMERO DE LA LINEA
                -- if @w_toperacion = (select pa_char from cobis..cl_parametro where pa_producto = 'CRE' and pa_nemonico = 'SBR' )
                -- BEGIN
                --     update cob_cuentas..cc_sobregiro
                --     set    sb_linea    = null
                --     from   cob_cuentas..cc_ctacte
                --     where  sb_cuenta   = cc_ctacte
                --     and    sb_tipo     = 'C'
                --     and    cc_cta_banco= @w_cuenta
                -- END
        end

        delete cr_linea where li_numero = @w_linea_credito
        delete cr_lin_moneda where lm_linea = @w_linea_credito
        delete cr_lin_ope where lo_linea = @w_linea_credito
        delete cr_lin_ope_moneda where om_linea = @w_linea_credito
    end

    -- PRORROGA (MODIFICACION DE LA LINEA)
    -- select @w_linea_credito = pr_numero
    -- from   cr_prorroga
    -- where  pr_tramite = @i_tramite
    -- if @@rowcount > 0
    -- begin
    --     set @w_linea_credito = -1 * @w_linea_credito
    --     delete cr_linea where li_numero = @w_linea_credito
    --     delete cr_lin_moneda where lm_linea = @w_linea_credito
    --     delete cr_lin_ope where lo_linea = @w_linea_credito
    --     delete cr_lin_ope_moneda where om_linea = @w_linea_credito
    --     delete cr_prorroga where pr_tramite = @i_tramite
    -- end


    if @w_tipo_tramite = 'F'
    begin
        delete cob_comext..ce_relacion_cca_cex_act
        where  ra_operacion_cca = @w_operacion
    end

    delete cr_facturas
    where  fa_tramite = @i_tramite

    -- update cob_custodia..cu_negocio_dd
    -- set    nd_tramite = null
    -- where  nd_tramite = @i_tramite

    -- BORRAR TRAMITE
    -- NO SE LO VA A HACER, QUEDA PARA ANALISIS EN CASO DE MEJOR PERFORMANCE EN EL BANCO
    -- DELETE cr_tr_datos_adicionales
    -- WHERE  tr_tramite = @i_tramite

    -- DELETE cr_tramite
    -- WHERE  tr_tramite = @i_tramite
    -- begin
    --     set @w_error = 2108034 -- NO EXISTE TRAMITE
    --     goto ERROR
    -- end

    update cr_tramite
    set    tr_estado  = 'Z'
    where  tr_tramite = @i_tramite
    if @@rowcount != 1
    begin
        set @w_error = 2108034 -- NO EXISTE TRAMITE
        goto ERROR
    end
commit tran
return 0

ERROR:
    while @@trancount > 0 rollback tran
    exec cobis..sp_cerror @t_debug = @t_debug,
                          @t_file  = @t_file,
                          @t_from  = @w_sp_name,
                          @i_num   = @w_error
    return @w_error

GO
