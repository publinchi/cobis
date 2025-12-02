/************************************************************************/
/*   NOMBRE LOGICO:      abonoatx.sp                                    */
/*   NOMBRE FISICO:      sp_abono_atx                                   */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Z.BEDON                                        */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Ingreso de abonos por ATX, y Reversas                           */
/*      P: Insercion de abonos                                          */
/*      R: Reversas de Abonos                                           */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      Enero     1998    Z.Bedon      Emision Inicial                  */
/*   06/Oct/10       Johan Ardila      Req 151 - Contraofertas          */
/*   28/Feb/19       Adriana Giler     Incluye Pago con Débito A.       */
/*   22/Mar/19       Jack Bermeo       Se elimina funcionalidad de      */
/*                                     valida caja, update totales y    */
/*                                     ejecución remota.                */
/*   24/Jun/19       Adriana Giler     Incluye Pago de Oficina Movil    */
/*   12/Jul/19       Luis Ponce        Pagos OP.Grupal e Interciclos    */
/*   19/Jul/19       Luis Ponce        Reversas Pagos Grupal-Interciclos*/
/*   23/Jun/2021     Aldair Fortiche   Se modifican pagos y reversos    */
/*                                     para atx teller                  */
/*   22/Sep/2021     Kevin Rodr�guez   Variables de salida Saldo anteri-*/
/*                                     or y saldo actual de CAP e INT   */
/*   19/Nov/2021     Guisela Fernandez Aumento de envio de paramtros a  */
/*                                     sp_pago_cartera y sp_fecha_valor */
/*   12/Abr/2022     Carlos Tiguaque   Dias feriados nacionales         */
/*   27/May/2022     Juan C. Guzman    Validacion reversos desde teller */
/*   16/Mar/2023     Kevin Rodríguez   S795163 Pago con f. pago Cheque  */
/*   28/Jul/2023     Guisela Fernandez S857741 Validación de licitud    */
/*   19/Sep/2023     Kevin Rodríguez   R215618  Param tipo red. null    */
/*   29/Sep/2023     Kevin Rodríguez   R216294 Validar fecha de pago ATX*/
/************************************************************************/
use cob_cartera

go

if exists (select 1 from sysobjects where name = 'sp_abono_atx')
           drop proc sp_abono_atx
go

CREATE  proc sp_abono_atx
@s_ssn                  int              = null,
@s_user                 login            = null,
@s_term                 varchar(30)      = null,
@s_date                 datetime         = null,
@s_sesn                 int              = null,
@s_ofi                  smallint         = null,
@s_rol                  smallint         = null,
@s_org                  char(1)          = null,
@s_srv                  varchar(30)      = null,
@s_ssn_branch           int              = null,
@s_lsrv                 varchar(30)      = null,
@t_debug                char(1)          = 'N',
@t_file                 varchar(20)      = null,
@t_from                 descripcion      = null,
@t_corr                 char(1)          = 'N',
@t_ssn_corr             int              = null,
@t_trn                  smallint,
@t_user                 login            = null,
@t_term                 varchar(30)      = null,
@t_srv                  varchar(30)      = null,
@t_ofi                  smallint         = null,
@t_rol                  smallint         = null,
@t_rty                  char(1)          = NULL,
@i_banco                cuenta,
@i_beneficiario         descripcion,
@i_tipo                 char(3)          = NULL,
@i_fecha_vig            datetime         = NULL,
@i_ejecutar             char(1)          = 'S',
@i_retencion            smallint         = 0,
@i_en_linea             char(1)          = 'S',
@i_producto             varchar(10),     --  Aqui esta llegando la Categoria de la forma de pago
@i_monto_mpg            money            = 0,
@i_monto                money            = 0,
@i_monto_max            money            = 0,
@i_cuenta               varchar(24)      = null,
@i_debito_me            money            = 0,
@i_moneda               tinyint,
@i_efectivo_mn          money            = 0,
@i_efectivo_me          money            = 0,
@i_chq_mn               money            = 0,
@i_chq_me               money            = 0,
@i_prop                 money            = 0,
@i_plaz                 money            = 0,
@i_nocaja               char(1)          = 'N',
@i_nofactura            smallint         = 0,
@t_ejec                 char(1)          = 'N',
@i_sld_caja             money            = 0,
@i_idcierre             int              = 0,
@i_filial               smallint         = 1,
@i_idcaja               int              = 0,
@i_fecha_valor_a        datetime         = null,
@i_tipo_reduccion       char(1)          = null,
@i_no_cheque            int              = 0,
@i_inscripcion          int              = 0,
@i_carga                int              = 0,
@i_porcentaje           float            = 0.0,
@i_observacion          varchar(255)     = '',
@o_alerta_cli           varchar(40)      = null out,
@o_secuencial_ing       int              = null out,
@o_sec_efectivo_mn      varchar(24)      = null out,
@o_sec_efectivo_me      varchar(24)      = null out,
@o_sec_chq_mn           varchar(24)      = null out,
@o_sec_chq_me           varchar(24)      = null out,
@o_sec_trn              varchar(24)      = null out,
@o_monto_cap            money            = null out,
@o_monto_int            money            = null out,
@o_monto_iva            money            = null out,
@o_monto_mpy            money            = null out,
@o_monto_imo            money            = null out,
@o_monto_sgd            money            = null out,
@o_monto_otr            money            = null out,
@o_numcuotas_can        smallint         = null out,
@o_numtot_cuotas        smallint         = null out,
@o_tramite              int              = null out,
@o_oficial              varchar(12)      = null out,
@o_cedula               varchar(20)      = null out,
@o_des_fuente           varchar(20)      = null out,
@o_oficina              smallint         = null out,
@o_saldo_ant_capital    money            = null out,
@o_saldo_act_capital    money            = null out,
@o_saldo_act_interes    money            = null out,
-- GFP 12-11-2021 Parametros para licitud de fondos
@o_consep               char(1)          = null out,
@o_ssn                  int              = null out,
@o_monto                money            = null out,
-- Parámetros salida factura electrónica
@o_guid                 varchar(36)      = null out,
@o_fecha_registro       varchar(10)      = null out,
@o_ssn_fact             int              = null out,
@o_orquestador_fact     char(1)          = null out

as
declare
@w_sp_name              descripcion,
@w_fecha                datetime,
@w_pago_atx             char(1),
@w_secuencial_ing       int,
@w_error                int,
@w_efectivo             money,
@w_cheque   money,
@w_factor               int,
@w_signo                char(1),
@w_estado               varchar(1),
@w_operacionca          int,
@w_cp_categoria_c       catalogo,
@w_cp_categoria_e       catalogo,
@w_cp_categoria_d       catalogo,
@w_cp_categoria         catalogo,
@w_dia_habil            char(1),
@w_producto             catalogo,
@w_retencion            smallint,
@w_ciudad_ofi           int,
@w_fecha_ult_proceso    datetime,
@w_monto_pago           money,    -- Monto de Pago, ya sea EFECTIVO o CHEQUE
@w_moneda               tinyint,
@w_decimales_pago       float,
@w_moneda_op            smallint,
@w_moneda_mn            smallint,
@w_num_dec_op           int,
@w_num_dec_n            smallint,
@w_pago_caja            char(1),
@w_secuencial_pag       int,
@w_op_tipo              char(1),
@w_ente                 int,
@w_valida_ente          char(1),
@w_rowcount             int,
@w_alerta_cli           varchar(40),
@w_reloj1               int,
@w_reloj2               int,
@w_reloj3               int,
@w_reloj4               int,
@w_reloj5               int,
@w_reloj6               int,
@w_reloj7               int,
@w_reloj8               int,
@w_reloj9               int,
@w_reloj10              int,
@w_reloj11              int,
@w_reloj12              int,
@w_cuota                money,         -- JAR REQ 151
@w_msg_matriz           varchar(255),  -- 331
@w_mensaje              varchar(80),   -- 353
@w_des_alianza          varchar(255),   -- 353
@w_cursor_open          char(1),
@w_fpag_emovil          catalogo,
@w_ofi_movil            SMALLINT,
@w_tipo_grupal          CHAR(1), --LPO TEC Pago OP Grupal e Interciclos
@w_codigo_cli           CHAR(1),
@w_valor                varchar(140),
@w_aplica_licitud       CHAR(1),
@w_ciudad_nacional      int,
@w_max_ssn              int,
@w_val_licitud_efec     CHAR(1)


if @t_ssn_corr is null
   select @t_ssn_corr = @s_ssn_branch

--NOMBRE DEL SP Y FECHA DE HOY
select @w_sp_name = 'sp_abono_atx'

select @w_ciudad_nacional = pa_int --Consulta Parametro ciudad nacional
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @i_efectivo_mn <> 0 and @i_chq_mn <> 0
begin
   select @w_error = 725280 -- Error, solo se admite una única forma de pago ya sea efectivo o cheque, revisar montos.
   goto ERROR 
end

if @i_efectivo_mn < 0 or @i_chq_mn < 0
begin
   select @w_error = 725281 -- Error, monto en efectivo o cheque con valor negativo
   goto ERROR 
end

-- Monto de Pago
if @i_efectivo_mn > 0
   select @w_monto_pago = @i_efectivo_mn

if @i_chq_mn > 0
   select @w_monto_pago = @i_chq_mn


if @i_cuenta is null
    select @i_cuenta = '100100',
           @w_moneda = 0

if  @i_debito_me <> 0
   select @w_cp_categoria_d = 'NDAH_FINAN'

select @w_dia_habil = 'N'
select @w_cursor_open = 'N'

--OBTENER PARAMETROS
Select @w_fpag_emovil = pa_char
from  cobis..cl_parametro
where pa_nemonico = 'FPAEFM'

if @@rowcount = 0
begin
   select @w_error = 101077
   goto ERROR
end

Select @w_ofi_movil  = pa_smallint
from  cobis..cl_parametro
where pa_nemonico = 'COFCM'

if @@rowcount = 0
begin
   select @w_error = 101077
   goto ERROR
end

Select @w_val_licitud_efec  = pa_char
from  cobis..cl_parametro
where pa_producto = 'MIS'
and   pa_nemonico = 'VCONE'

if @@rowcount = 0
begin
   select @w_error = 101077
   goto ERROR
end


-- CIUDAD DE LA OFICINA EN QUE ESTA RADICADO EL CREDITO
select
@w_ciudad_ofi        = of_ciudad,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_moneda_op         = op_moneda,
@w_pago_caja         = isnull(op_pago_caja,'S'),
@w_operacionca       = op_operacion,
@w_op_tipo           = op_tipo,
@w_ente              = op_cliente,
@w_cuota             = op_cuota    -- JAR REQ 151
from ca_operacion, cobis..cl_oficina noholdlock
where op_banco   = @i_banco
and   op_oficina = of_oficina

if @@rowcount = 0
begin
   select @w_error = 701025
   goto ERROR
end

/*DETERMINA EL TIPO DE OPERACION ((G)rupal, (I)nterciclo, I(N)dividual)*/ --LPO TEC Pago OP. Grupal e Interciclos
EXEC @w_error = sp_tipo_operacion
     @i_banco  = @i_banco,
     @o_tipo   = @w_tipo_grupal out

IF @w_error <> 0
BEGIN
   RETURN @w_error
END

select @w_reloj1  = sum(@w_operacionca * 100 + 1)
select @w_reloj2  = sum(@w_operacionca * 100 + 2)
select @w_reloj3  = sum(@w_operacionca * 100 + 3)
select @w_reloj4  = sum(@w_operacionca * 100 + 4)
select @w_reloj5  = sum(@w_operacionca * 100 + 5)
select @w_reloj6  = sum(@w_operacionca * 100 + 6)
select @w_reloj7  = sum(@w_operacionca * 100 + 7)
select @w_reloj8  = sum(@w_operacionca * 100 + 8)
select @w_reloj9  = sum(@w_operacionca * 100 + 9)
select @w_reloj10 = sum(@w_operacionca * 100 + 10)
select @w_reloj11 = sum(@w_operacionca * 100 + 11)
select @w_reloj12 = sum(@w_operacionca * 100 + 12)

--exec sp_reloj @w_reloj1

select @w_codigo_cli = codigo,
       @w_valor      = valor
from cobis..cl_ente X, cobis..cl_catalogo
where  en_ente = @w_ente
and codigo = X.en_accion
AND tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_accion_cliente')


select @w_alerta_cli = (select case codigo
                               when 'NIN' then ''
                               else valor
                               end
                        from   cobis..cl_catalogo
                        where  tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_accion_cliente')
                        and    codigo = X.en_accion)
from   cobis..cl_ente X
where  en_ente = @w_ente


select @o_alerta_cli = @w_alerta_cli
if @w_op_tipo = 'R'
  select @w_pago_caja  =  'N'

if @w_pago_caja  =  'N'
begin
   select @w_error = 710307
   goto ERROR
end

-- DECIMALES DE LA OPERACION
exec @w_error = sp_decimales
@i_moneda       = @w_moneda_op,
@o_decimales    = @w_num_dec_op out,
@o_mon_nacional = @w_moneda_mn  out,
@o_dec_nacional = @w_num_dec_n  out

if @@error != 0 or  @w_error <> 0
    goto ERROR

if @s_date <> @w_fecha_ult_proceso
begin
   select @w_error = 725304 -- La fecha valor de la operación es menor a la fecha proceso. Favor validar con Back Office de Cartera
   goto ERROR
end


if @t_trn = 7224 and @w_cp_categoria_c in ('CHLO','CHOT','CHGE') begin

   while @w_dia_habil = 'N'
   begin
      select @i_fecha_vig = dateadd (dd, 1, @i_fecha_vig)

      select df_fecha
      from cobis..cl_dias_feriados
      where df_ciudad in (@w_ciudad_ofi, @w_ciudad_nacional)
      and   df_fecha  = @i_fecha_vig

      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted

      if @w_rowcount =0
         select @w_dia_habil = 'S'
   end
end

-- Determinar si la transaccion es ejecutada por el REENTRY del SAIP
if @t_user is not null begin
   select
   @s_user = @t_user,
   @s_term = @t_term,
   @s_srv  = @t_srv,
   @s_ofi  = @t_ofi,
   @s_rol  = @t_rol
end

--exec sp_reloj @w_reloj2


--exec sp_reloj @w_reloj3

--Modo de correccion
if @t_corr = 'N'
begin
   select @w_factor = 1,
          @w_signo = 'C',
          @w_estado = null
end
else
begin
   select @w_factor = -1,
          @w_signo = 'D',
          @w_estado = 'R'
end

--AGI 06MAR19.  Si aplica tipo de reducci�n de Cuota
if @i_tipo_reduccion = 'S'
   select  @i_tipo_reduccion = 'C'
--AGI

BEGIN TRAN

if @t_corr = 'N'
begin
    if @w_monto_pago <> 0
    begin

        if @s_ofi = @w_ofi_movil  --Pago por oficina movil
            select @w_producto = @w_fpag_emovil
        else
        begin
		
          -- Validar que las formas de pago sean de categoría EFECTIVO o CHEQUE.
          select @w_producto       = @i_producto,
                 @w_cp_categoria   = cp_categoria
          from ca_producto
          where cp_producto = @i_producto
          and cp_atx = 'S'
          and cp_categoria in ('EFEC', 'CHBC')				 
		  
		  if @@rowcount = 0 
          begin
             select @w_error = 725282 -- Error, no existe forma de pago o la forma de pago no es admitida para Teller
             goto ERROR
          end
				  
          if @w_cp_categoria = 'CHBC' -- Para categoría CHBC(Cheque) se toma los días de retención de la forma de pago.
		  begin
		     
			 if @i_chq_mn <= 0
			 begin
                select @w_error = 725283 -- Error, no se proporcionó monto según la categoría de la forma de pago.
                goto ERROR
			 end
			 
		     select @w_retencion = isnull(cp_retencion, 0)
             from ca_producto
             where cp_producto = @i_producto
          end
		  
          if @w_cp_categoria = 'EFEC'
		  begin
		     
             if @i_efectivo_mn <= 0
			 begin
                select @w_error = 725283 -- Error, no se proporcionó monto según la categoría de la forma de pago.
                goto ERROR	 
			 end
		  end
		  
        end

        select @w_decimales_pago  = @w_monto_pago  - floor(@w_monto_pago)

        if @w_decimales_pago > 0 and @w_num_dec_n = 0
        begin
            select @w_error = 710468
            goto ERROR
        end

        IF @w_tipo_grupal = 'G' --LPO TEC. Pagos OP. Grupal e Interciclos
        BEGIN
            exec    @w_error            = cob_cartera..sp_ing_detabono
                    @i_accion           = 'G',
                    @i_encerar          = 'S',
                    @i_concepto         = @i_producto,
                    @i_moneda           = @i_moneda,
                    @i_monto_mpg        = @w_monto_pago,
                    @i_no_cheque        = @i_no_cheque,
                    @i_inscripcion      = @i_inscripcion,
                    @i_carga            = @i_carga,
                    @i_banco            = @i_banco,
                    @i_porcentaje       = @i_porcentaje,
                    @i_fecha_vig        = @i_fecha_vig,
                    @i_tipo             = NULL,
                    @s_user             = @s_user,
                    @s_term             = @s_term,
                    @s_date             = @s_date,
                    @s_sesn             = @s_sesn,
                    @o_secuencial_ing   = @w_secuencial_ing out

           if @w_error != 0
              goto ERROR

        END
        ELSE
        BEGIN

           SELECT @o_saldo_ant_capital = sum(am_acumulado + am_gracia - am_pagado)
           FROM ca_amortizacion,
             ca_rubro_op
           WHERE am_operacion = @w_operacionca
           AND   am_operacion = ro_operacion
           AND   am_concepto  = ro_concepto
           AND   ro_tipo_rubro = 'C'
		   
           -- GFP identificacion si aplica licitud
		   select @w_aplica_licitud = 'N'
		   if @w_val_licitud_efec = 'S'
		   begin
		       if @s_ssn_branch is not null and @w_cp_categoria = 'EFEC'
               select @w_aplica_licitud = 'S'
		   end
		   else 
		   begin
		      if @s_ssn_branch is not null
              select @w_aplica_licitud = 'S'
		   end

           exec @w_error = sp_pago_cartera
                @s_user           = @s_user,
                @s_term           = @s_term,
                @s_date           = @s_date ,
                @s_sesn           = @s_sesn,
                @s_ofi            = @s_ofi,
                @s_ssn            = @s_ssn,
                @s_srv            = @s_srv,
                --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos
                @s_ssn_branch     = @s_ssn_branch,
                @s_lsrv           = @s_lsrv,
                @s_rol            = @s_rol,
                @s_org            = @s_org,
                @t_ssn_corr       = @t_ssn_corr,
                @t_debug          = @t_debug,
                @t_file           = @t_file,
                @t_from           = @t_from,
                @t_trn            = @t_trn,
                --GFP 18-11-2021 Fin de parametros solo utilizados para licitud de fondos
                @i_banco          = @i_banco,
                @i_beneficiario   = @i_beneficiario,
                @i_fecha_vig      = @s_date,
                @i_ejecutar       = 'S',
                @i_en_linea       = 'S',
                @i_producto       = @w_producto,
                @i_monto_mpg      = @w_monto_pago,
                @i_cuenta         = @i_cuenta,
                @i_moneda         = @i_moneda,
                @i_dividendo      = @i_nofactura,
                @i_tipo_reduccion = @i_tipo_reduccion,
				@i_retencion      = @w_retencion,
                @i_aplica_licitud = @w_aplica_licitud,
                @o_secuencial_ing = @w_secuencial_ing out,
                --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos
                @o_consep         = @o_consep out,
                @o_ssn            = @o_ssn out,
                @o_monto          = @o_monto out,
                @o_guid           = @o_guid out,
                @o_fecha_registro = @o_fecha_registro out,
                @o_ssn_fact       = @o_ssn_fact out,
                @o_orquestador_fact = @o_orquestador_fact out

           if @w_error <> 0
              goto ERROR

           SELECT @o_saldo_act_capital = sum(am_acumulado + am_gracia - am_pagado)
           FROM ca_amortizacion,
             ca_rubro_op
           WHERE am_operacion = @w_operacionca
           AND   am_operacion = ro_operacion
           AND   am_concepto  = ro_concepto
           AND   ro_tipo_rubro = 'C'

           SELECT @o_saldo_act_interes = sum(am_acumulado + am_gracia - am_pagado)
           FROM ca_amortizacion,
             ca_rubro_op
           WHERE am_operacion = @w_operacionca
           AND   am_operacion = ro_operacion
           AND   am_concepto  = ro_concepto
           AND   ro_tipo_rubro = 'I'

        END

        select @o_sec_efectivo_mn = convert(varchar,isnull(@w_secuencial_ing,0))
    end

   --exec sp_reloj @w_reloj4

   --INSERTA TANTO PARA CHEQUE COMO PARA EFECTIVO
   if @w_monto_pago <> 0
   BEGIN
       insert into ca_secuencial_atx (
       sa_operacion ,      sa_ssn_corr ,     sa_producto,              sa_secuencial_cca,
       sa_secuencial_ssn,  sa_oficina,       sa_fecha_ing,             sa_fecha_real,
       sa_estado,    sa_ejecutar,    sa_valor_efe,             sa_valor_cheq,
       sa_error)
       values(@i_banco,    @t_ssn_corr,      @w_producto,              @w_secuencial_ing,
       isnull(@s_ssn,0),   isnull(@s_ofi,0), isnull(@s_date,''),       getdate(),
       'A',               @i_ejecutar,      isnull(@i_efectivo_mn,0), isnull(@i_chq_me,0),
       0)
    END

   --exec sp_reloj @w_reloj5

   --exec sp_reloj @w_reloj6

   /**********************************************/
   -- GYA BPT Requerimiento FO-002
   -- Se ejecuta el procedimiento para valorar la  nota y porcentaje de la operaci�n.
   -- JAR REQ 151. Se cambia de ubicacion para que la validacion se haga
   -- Teniendo en cuenta el pago actual
   /**********************************************/
   exec @w_error = cob_cartera..sp_valop
      @i_banco          = @i_banco,
      @i_cliente        = @w_ente,
      @i_operacion      = 'V',
      @i_fecha_pro      = @s_date,
      @i_cuota_ant      = @w_cuota,           -- JAR REQ 151
      @i_tipo_reduccion = @i_tipo_reduccion   -- JAR REQ 151

   if @w_error <> 0
      goto ERROR

   -- INI JAR REQ 218 - ALERTAS CUPOS
   exec @w_error = cob_credito..sp_alertas
      @i_cliente = @w_ente

   if @w_error <> 0 goto ERROR
   -- FIN JAR REQ 218

   select @o_sec_efectivo_me = isnull(@o_sec_efectivo_me,'0.00')
   select @o_sec_chq_mn      = isnull(@o_sec_chq_mn,'0.00')
   select @o_sec_chq_me      = isnull(@o_sec_chq_me,'0.00')
   select @o_sec_efectivo_mn = isnull(@o_sec_efectivo_mn,'0.00')

end

-- RETORNAR SECUENCIAL PARA EL RECIBO
select @o_sec_trn = convert(varchar,@s_ssn)

if @t_corr = 'S'  begin
   if not exists (select sa_secuencial_cca
                  from   cob_cartera..ca_secuencial_atx
                  where  sa_ssn_corr  = @t_ssn_corr
                  and    sa_fecha_ing = @s_date
                  and    sa_oficina   = isnull(@s_ofi,0)
                  and    sa_operacion = @i_banco
                  and    sa_estado = 'A')
   begin
       select @w_error =  701025
       goto ERROR
   end

   select @w_max_ssn = max(sa_ssn_corr) 
   from  ca_secuencial_atx
   where sa_fecha_ing  = @s_date
   and   sa_operacion  = @i_banco
   and   sa_estado     = 'A'
   
   if @t_ssn_corr < @w_max_ssn 
   begin
      select @w_error = 725147
      goto ERROR
   end

   declare
      reversar_tran cursor
      for    select sa_secuencial_cca
             from   cob_cartera..ca_secuencial_atx
             where  sa_ssn_corr  = @t_ssn_corr
             and    sa_fecha_ing = @s_date
             and    sa_oficina   = isnull(@s_ofi,0)
             and    sa_operacion = @i_banco
             and    sa_estado = 'A'    --def 6657
             order  by sa_ssn_corr, sa_secuencial_cca desc
      for read only

   declare @w_secuencial int
   open reversar_tran
   fetch reversar_tran
   into @w_secuencial

   select @w_cursor_open = 'S'

   while @@fetch_status = 0--not in (-1,0) -jpe
   begin
      select @w_secuencial_pag = 0

      IF @w_tipo_grupal = 'G'
      BEGIN
         SELECT   @w_secuencial_pag    = co_secuencial
         FROM     ca_corresponsal_trn
         WHERE    co_codigo_interno    = @w_operacionca
         AND      co_accion            = 'I'
         AND      co_estado            = 'P'
         and      co_secuencial        = @w_secuencial

         if @w_secuencial_pag <> 0
         begin
            exec @w_error   = cob_cartera..sp_reversos_pagos_grupales
            @s_user         = @s_user,
            @s_term         = @s_term,
            @s_date         = @s_date,
            @s_sesn         = @s_sesn,
            @i_operacion    = 'U',
            @i_banco        = @i_banco,
            @i_estado       = 'P',
            @i_secuencial   = @w_secuencial

            if @@error != 0 or  @w_error <> 0
               goto ERROR

            update cob_cartera..ca_secuencial_atx
            set    sa_estado            = 'R'
            where  sa_operacion         = @i_banco
            and    sa_secuencial_cca    = @w_secuencial
            and    sa_ssn_corr          = @t_ssn_corr
            and    sa_fecha_ing         = @s_date
            and    sa_oficina           = isnull(@s_ofi,0)
         end
         ELSE
         BEGIN
            if exists (   SELECT    1
                          FROM      ca_corresponsal_trn
                          WHERE     co_codigo_interno    = @w_operacionca
                          AND       co_accion            = 'I'
                          AND       co_estado            = 'I'
                          and       co_secuencial        = @w_secuencial)
            BEGIN
                if @@error != 0 or  @w_error <> 0
                begin
                   select @w_error =  711093
                   goto ERROR
                end
            END
         END
      end
      ELSE
      BEGIN
         select @w_secuencial_pag = ab_secuencial_pag
         from   ca_abono
         where  ab_secuencial_ing = @w_secuencial
         and    ab_operacion      = @w_operacionca

         if @w_secuencial_pag <> 0
         begin
            exec  @w_error  = cob_cartera..sp_fecha_valor
            @s_srv          = @s_srv,
            @s_user         = @s_user,
            @s_term         = @s_term,
            @s_ofi          = @s_ofi,
            @s_rol          = @s_rol,
            @s_ssn          = @s_ssn,
            @s_lsrv         = @s_lsrv,
            @s_date         = @s_date,
            @s_sesn         = @s_sesn,
            @s_org          = @s_org,
            @t_trn          = 7049,
            @t_ssn_corr     = @t_ssn_corr,
            @t_debug        = @t_debug,
            @t_file         = @t_file,
            @i_banco        = @i_banco,
            @i_secuencial   = @w_secuencial_pag,
            @i_operacion    = 'R',
            @i_observacion  = @i_observacion,
            @i_es_atx       = 'S',
            @i_en_linea     = @i_en_linea,
            @i_aplica_licitud = 'S',
            @o_guid           = @o_guid out,
            @o_fecha_registro = @o_fecha_registro out,
            @o_ssn            = @o_ssn_fact out,
            @o_orquestador_fact = @o_orquestador_fact out

            if @@error != 0 or  @w_error <> 0
            begin
               goto ERROR
            end

            update cob_cartera..ca_secuencial_atx
            set    sa_estado            = 'R'
            where  sa_operacion         = @i_banco
            and    sa_secuencial_cca    = @w_secuencial
            and    sa_ssn_corr          = @t_ssn_corr
            and    sa_fecha_ing         = @s_date
            and    sa_oficina           = isnull(@s_ofi,0)
         END
         ELSE
         begin
            exec @w_error     = sp_eliminar_pagos
            @t_trn            = 7036,
            @i_banco          = @i_banco,
            @i_operacion      = 'D',
            @i_secuencial_ing = @w_secuencial,
            @i_en_linea       = @i_en_linea

            if @@error != 0 or  @w_error <> 0
            goto ERROR

            update cob_cartera..ca_secuencial_atx
            set    sa_estado            = 'E'
            where  sa_operacion         = @i_banco
            and    sa_secuencial_cca    = @w_secuencial
            and    sa_ssn_corr          = @t_ssn_corr
            and    sa_fecha_ing         = @s_date
            and    sa_oficina           = isnull(@s_ofi,0)
         end
      end

      fetch reversar_tran into @w_secuencial
   end

   close reversar_tran
   deallocate reversar_tran
end

select @w_cursor_open = 'N'


--exec sp_reloj @w_reloj8

if @i_efectivo_mn <> 0 or @i_chq_me <> 0 begin
   select
   @w_efectivo = @i_efectivo_mn,
   @w_cheque = @i_chq_me

end

--exec sp_reloj @w_reloj9

--- VALIDACION DE CLIENTE REQ 520 IFJ
/*if exists (select 1 from cob_remesas..re_trans_alerta
           where ta_transaccion = @t_trn
           and ta_estado = 'V')  begin
   exec cobis..sp_ente_bloqueado
   @t_trn       = 175,
   @i_operacion = 'B',
   @i_ente      = @w_ente,
   @o_retorno   = @w_valida_ente output
end
else
   select @w_valida_ente = 'N'*/

--exec sp_reloj @w_reloj10


--exec sp_reloj @w_reloj11
---SACAR EL ESTADO DE LA TRANSACCIONES

if @t_corr = 'N'
begin
   IF @w_tipo_grupal <> 'G'
   BEGIN
       select @w_estado = ab_estado
       from   ca_abono
       where ab_operacion = @w_operacionca
       and   ab_secuencial_ing =  @w_secuencial_ing

       if @@rowcount = 0
       begin
           select @w_error =  711020
          goto ERROR
       end
   END
   ELSE
   begin
      update cob_cartera..ca_secuencial_atx  set
      sa_estado = 'A' -- Para el ATX estar en el modulo es estar aplicada
      where  sa_operacion = @i_banco
      and    sa_secuencial_cca = @w_secuencial_ing
   end
end

/*select @w_des_alianza = isnull((al_nemonico + ' - ' + al_nom_alianza), '  ')
  from cobis..cl_alianza_cliente with (nolock),
       cobis..cl_alianza         with (nolock)
  where ac_ente    = @w_ente
    and ac_alianza = al_alianza
    and al_estado  = 'V'
    and ac_estado  = 'V'


if @w_des_alianza is not null
begin
  select @w_mensaje = 'CLIENTE PERTENECE A ALIANZA ' + @w_des_alianza
  print @w_mensaje
end*/

-- CONSULTAR LOS DATOS PARA LA BOLETA DE IMPRESION
exec sp_consulta_abono_atx
@s_sesn                    = @s_sesn,
@s_ssn                     = @s_ssn,
@s_user                    = @s_user,
@s_date                    = @s_date,
@s_ofi                     = @s_ofi,
@s_term                    = @s_term,
@s_srv                     = @s_srv,
@i_secuencial_ing          = @w_secuencial_ing,
@i_operacionca             = @w_operacionca,
@i_en_linea                = 'S',
@i_total                   = @i_monto_mpg,
@o_monto_cap               = @o_monto_cap     out,
@o_monto_int               = @o_monto_int     out,
@o_monto_iva               = @o_monto_iva     out,
@o_monto_mpy               = @o_monto_mpy     out,
@o_monto_imo               = @o_monto_imo     out,
@o_monto_sgd               = @o_monto_sgd     out,
@o_monto_otr               = @o_monto_otr     out,
@o_numcuotas_can           = @o_numcuotas_can out,
@o_numtot_cuotas           = @o_numtot_cuotas out,
@o_tramite                 = @o_tramite       out,
@o_oficial                 = @o_oficial       out,
@o_cedula                  = @o_cedula        out,
@o_des_fuente              = @o_des_fuente    out,
@o_oficina                 = @o_oficina       out

if @@error != 0
   goto ERROR

--exec sp_reloj @w_reloj12


COMMIT TRAN


return 0

ERROR:
   if @w_cursor_open = 'S'
   begin
      close reversar_tran
      deallocate reversar_tran
   end

   while @@trancount > 0 ROLLBACK TRAN
   exec cobis..sp_cerror
   @t_debug  ='N',
   @t_file   = null,
   @t_from   = @w_sp_name,
   @i_num    = @w_error,
   @i_sev    = 1

   BEGIN TRAN
   --SE INSERTA EN LA TABLA CA_secuencial_atx PARA FACILITAR LAS REVISIONES POSTERIORES
   exec @w_secuencial_ing = sp_gen_sec @i_operacion = @w_operacionca

   insert into ca_secuencial_atx(
   sa_operacion ,      sa_ssn_corr ,   sa_producto,  sa_secuencial_cca ,
   sa_secuencial_ssn,  sa_oficina,     sa_fecha_ing, sa_fecha_real,
   sa_estado,          sa_ejecutar,    sa_valor_efe, sa_valor_cheq,
   sa_error)
   values(@i_banco,    @t_ssn_corr,      @i_producto, isnull(@w_secuencial_ing,0),
   isnull(@s_ssn,0),   isnull(@s_ofi,0), isnull(@s_date,''),      getdate(),
   'X',                @i_ejecutar,      isnull(@i_efectivo_mn,0), isnull(@i_chq_me,0),
   @w_error)

   COMMIT
   return @w_error

go
