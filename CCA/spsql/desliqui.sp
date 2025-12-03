/******************************************************************/
/*  Archivo:            desliqui.sp                               */
/*  Stored procedure:   sp_desembolso_liquida                     */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Adriana Giler                             */
/*  Fecha de escritura: 07-Mar-2018                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Insercion del desembolso                                   */
/*   - Liquidación del desembolso                                 */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  26/mar/19        Adriana Giler      Desembolso Futuro         */
/*  31/Jul/19        Adriana Giler      Debito de Seguros         */
/*  27/02/20         Luis Ponce         CDIG. Quitar prints       */
/*  24/Jun/2022      KDR              Nuevo parámetro sp_liquid   */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_desembolso_liquida')
   drop proc sp_desembolso_liquida
go

create proc sp_desembolso_liquida
   @s_sesn                 int          = null,
   @s_date                 datetime,
   @s_user                 login        = null,
   @s_culture              varchar(10)  = null,
   @s_term                 varchar(30)  = null,
   @s_ssn                  int          = null,
   @s_org                  char(1)      = null,
   @s_srv                  varchar (30) = null,
   @s_ofi                  smallint     = null,
   @s_lsrv                 varchar (30) = null,
   @s_rol                  int          = null,
   @t_trn                  int          = null,
   @i_operacion            char(1),
   @i_banco_real           cuenta,
   @i_banco_ficticio       cuenta,
   @i_secuencial           int          = null,
   @i_desembolso           tinyint      = null,
   @i_producto             catalogo     = '',
   @i_cuenta               cuenta       = '',
   @i_oficina_chg          int          = 0,
   @i_beneficiario         descripcion  = '',
   @i_monto_ds             money        = null,
   @i_monto_ds_dec         money        = null,
   @i_moneda_ds            smallint     = null,
   @i_cotiz_ds             money        = null,
   @i_tcotiz_ds            char(1)      = null,
   @i_moneda_op            tinyint      = null,
   @i_cotiz_op             money        = null,
   @i_tcotiz_op            char(1)      = null,
   @i_pasar_tmp            char(1)      = null,
   @i_formato_fecha        int          = null,
   @i_consulta             char(1)      = null,
   @i_capitalizacion       char(1)      = 'N',
   @i_externo              char(1)      = 'S',
   @i_operacion_ach        char(1)      = null,
   @i_nom_producto         char(3)      = null,
   @i_cod_banco_ach        int          = null,
   @i_desde_cre            char(1)      = null,
   @i_cheque               int          = null,
   @i_prenotificacion      int          = null,
   @i_carga                int          = null,
   @i_concepto             varchar(255) = null,
   @i_fecha_liq            datetime     = null,
   @o_respuesta            char(1)      = null out,
   @o_secuencial           descripcion  = null out,
   @i_ente_benef           int          = null,
   @i_idlote               int          = null,
   @i_renovaciones         char(1)      = null,
   @i_origen               char(1)      = 'F',
   @i_crea_ext             char(1)      = null,
   @i_cruce_restrictivo    char(1)      = null,
   @i_destino_economico    char(1)      = null,
   @i_carta_autorizacion   char(1)      = null,
   @i_calcular_gmf         char(1)      = 'N',
   @i_tramite              int          = null,
   @i_grupal               char(1)      = null,
   @i_grupo_id             int          = null,
   @i_fecha_desembolso     datetime     = null,
   @i_regenera_rubro       char(1)      = null,
   @o_anticipado           money        = null out,
   @o_msg_msv              varchar(255) = null out


as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_fpago                varchar(20),
   @w_monto_ds             money,
   @w_monto                money,
   @w_contador             int,
   @w_pos                  int,
   @w_cliente              int,
   @w_toperacion           catalogo,
   @w_fecha_ini            datetime,
   @w_tplazo               catalogo,
   @w_plazo                smallint,
   @w_tdividendo           catalogo,
   @w_periodo_cap          smallint,
   @w_periodo_int          smallint,
   @w_gracia_cap           smallint,
   @w_gracia_int           smallint,
   @w_operacion            int,
   @w_cant_seguro          int,
   @w_sec_seguro           int,
   @w_secuencia_seguro     varchar(100),
   @w_num_tran             int,
   @w_num_temp             INT,
   @w_moneda_op            INT
   

SELECT @w_sp_name = 'sp_desembolso_liquida'


/*
select @w_fpago = pa_char
from cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'NCRAHO'
--print 'sp_desembolso_liquida: se obtiene valor de @w_fpago: ' + @w_fpago

if @@rowcount = 0
    select @w_error = 141140

If  @i_producto != @w_fpago
begin
    print 'Forma de Desembolso no Permitida'
    return 1
end
*/

select @w_operacion = op_operacion,
       @w_moneda_op = op_moneda
from ca_operacion where op_banco = @i_banco_real

IF @i_moneda_op IS NULL
   SELECT @i_moneda_op = @w_moneda_op
   


if @i_externo  = 'S'
   Begin tran  --Si no viene del originador desde acá se controla transaccionalidad, sino el originador ya tiene el control

    --INGRESAR DESEMBOLSO--
    -----------------------
	exec @w_error = cob_cartera..sp_desembolso
    @i_banco_ficticio   = @i_banco_ficticio,
    @i_banco_real       = @i_banco_real,
    @i_formato_fecha    = @i_formato_fecha,
    @i_origen           = 'B',
    @i_moneda_ds        = @i_moneda_ds,
    @i_moneda_op        = @i_moneda_op, --LPO CDIG Moneda de la operacion
    @i_producto         = @i_producto,
    @i_cuenta           = @i_cuenta,
    @i_monto_ds         = @i_monto_ds,
    @i_cotiz_ds         = @i_cotiz_ds,
    @i_cotiz_op         = @i_cotiz_op,
    @i_tcotiz_ds        = @i_tcotiz_ds   ,
    @i_tcotiz_op        = @i_tcotiz_op   ,
    @i_beneficiario     = @i_beneficiario,
    @t_trn              = @t_trn         ,
    @i_operacion        = @i_operacion,
    @i_pasar_tmp        = @i_pasar_tmp,
    @i_fecha_desembolso = @i_fecha_liq,
    @s_srv              = @s_srv ,
    @s_user             = @s_user,
    @s_term             = @s_term,
    @s_ofi              = @s_ofi  ,
    @s_rol              = @s_rol  ,
    @s_ssn              = @s_ssn  ,
    @s_lsrv             = @s_lsrv ,
    @s_date             = @s_date ,
    @s_sesn             = @s_sesn ,
    @s_org              = @s_org  ,
    @s_culture          = @s_culture,
    @i_externo          = 'N',
    @i_regenera_rubro   = @i_regenera_rubro,
    @i_grupal           = @i_grupal
    if @w_error != 0
       goto ERROR

    if @i_fecha_liq > @s_date
    begin

        --Actualiza la operación con la fecha futura de liquidaciÃƒÂ³n

        select
          @w_operacion         = opt_operacion,
          @w_toperacion        = opt_toperacion,
          @w_cliente           = opt_cliente,
          @w_plazo             = opt_plazo,
          @w_tplazo            = opt_tplazo,
          @w_tdividendo        = opt_tdividendo,
          @w_periodo_cap       = opt_periodo_cap,
          @w_periodo_int       = opt_periodo_int
        from ca_operacion_tmp
        where opt_banco =  @i_banco_real

         /* CREAR OPERACION TEMPORAL */
--		 print  'borra operacion temporal sp_borrar_tmp'
        exec @w_error = sp_borrar_tmp
        @i_banco  = @i_banco_real,
        @s_term   = @s_user,
        @s_user   = @s_user

--		print  'crea operacion temporal sp_borrar_tmp'
        if @w_error <> 0 return @w_error
        exec @w_error = sp_crear_tmp
        @s_user        = @s_user,
        @s_term        = @s_term,
        @i_banco       = @i_banco_real,
        @i_accion      = 'A'

        if @w_error <> 0 return @w_error
        exec @w_error = sp_modificar_operacion
             @s_user               = @s_user,
             @s_sesn               = @s_sesn,
             @s_date               = @s_date,
             @s_term               = @s_term,
             @s_ofi                = @s_ofi,
             @i_calcular_tabla     = 'S',
             @i_tabla_nueva        = 'S',
             @i_recalcular         = 'S',
             @i_cuota              = 0,
             @i_banco              = @i_banco_real,
             @i_operacionca       = @w_operacion,
             @i_fecha_ini         = @i_fecha_liq ,
             @i_plazo             = @w_plazo,
             @i_tplazo            = @w_tplazo,
             @i_periodo_cap       = @w_periodo_cap,
             @i_periodo_int       = @w_periodo_int,
             @i_toperacion        = @w_toperacion,
             @i_monto             = @w_monto,
             @i_cliente           = @w_cliente,
             @i_regenera_rubro    = @i_regenera_rubro,
             @i_grupal            = @i_grupal
--        print  'finaliza proceso sp_modificar_operacion'
        if @w_error != 0
           return @w_error

		--print 'comienza proceso sp_operacion_def'
        exec sp_operacion_def
        @i_banco = @i_banco_real,
        @s_date  = @s_date,
        @s_sesn  = @s_sesn,
        @s_user  = @s_user,
        @s_ofi   = @s_ofi

		--print  'borra operacion temporal sp_borrar_tmp'
        exec sp_borrar_tmp
        @i_banco  = @i_banco_real,
        @s_sesn   = @s_sesn,
        @s_user   = @s_user,
        @s_term   = @s_term

        if @i_externo  = 'S'
            while @@trancount > 0 commit tran

        return 0
    end

    --LIQUIDAR DESEMBOLSO--
    ------------------------
	--print 'Va al sp_liquida, con operación ' + convert(varchar, @i_banco_ficticio) + convert(varchar, @i_fecha_liq)
	exec @w_error = cob_cartera..sp_liquida
    @i_banco_ficticio  = @i_banco_ficticio,
    @i_banco_real      = @i_banco_real,
    @i_fecha_liq       = @i_fecha_liq,
    @i_externo         = 'N',
	@i_desde_cartera   = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
    @i_regenera_rubro  = @i_regenera_rubro,
    @i_grupal          = @i_grupal   ,
    @s_srv             = @s_srv      ,
    @s_user            = @s_user     ,
    @s_term            = @s_term     ,
    @s_ofi             = @s_ofi      ,
    @s_rol             = @s_rol      ,
    @s_ssn             = @s_ssn      ,
    @s_lsrv            = @s_lsrv     ,
    @s_date            = @s_date     ,
    @s_sesn            = @s_sesn     ,
    @s_org             = @s_org

	--print 'Terminó el sp_liquida'
    if @w_error != 0
	begin
	   print 'Fue a error en el sp_liquida'
       goto ERROR
	end

    --INI AGI 31JUL19  Cobro de Seguros
	--print 'comienza debito paquete seguros'
    execute @w_error = sp_debito_seguros
            @s_ssn            = @s_ssn,
            @s_sesn           = @s_ssn,
            @s_user           = @s_user,
            @s_date           = @s_date,
            @s_ofi            = @s_ofi,
            @i_operacion      = @w_operacion,
            @i_cta_grupal     = @i_cuenta,
            @i_moneda         = @i_moneda_ds,
            @i_fecha_proceso  = @i_fecha_liq,
            @i_oficina        = @s_ofi,
            @i_opcion         = 'D',
            @i_secuencial_trn = @s_ssn
    --print 'finaliza proceso debito paquete seguros '
    --FIN AGI
    if @w_error != 0
    begin
	    print 'Error en los debitos seguros'
        select @w_error,@i_externo
        goto ERROR
    end

    --Actualizo estado
	--print 'actualiza estado tabla seguros op'
    update ca_seguros_op
    set so_estado = 'A'
    from  cob_cartera..ca_seguros_op
    where so_operacion  = @w_operacion

    if @@error != 0
    begin
        select @w_error = 725044
        goto ERROR
    end

if @i_externo  = 'S'
    while @@trancount > 0 commit tran


return 0

ERROR:
    if @i_externo  = 'S'
        while @@trancount > 0 ROLLBACK TRAN

    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error

   return @w_error

GO
