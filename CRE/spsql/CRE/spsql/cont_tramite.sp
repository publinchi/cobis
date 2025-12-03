/************************************************************************/
/*  Archivo:                cont_tramite.sp                             */
/*  Stored procedure:       sp_cont_tramite                             */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
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
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_cont_tramite')
    drop proc sp_cont_tramite
go

create proc sp_cont_tramite(
   @s_date               datetime    = NULL,
   @s_ofi                smallint    = NULL,
   @s_user               login       = NULL,
   @s_term               descripcion = NULL,
   @t_file               varchar(14) = NULL,
   @i_tramite            int,
   @i_operacion          char(1)     = null,
   @i_monto              money       = null,
   @i_fecha_valor	 datetime    = null, 
   @i_secuencial	 int         = null,        
   @i_origen             char(1)     = 'C',-- C = Credito D = Desembolso P = pago
   @i_pit                char(1)     = 'N'
)
as

declare
   @w_sp_name            varchar(32),  /* NOMBRE STORED PROC */
   @w_return             int,
   @w_estado             char(1),
   @w_monto              money,
   @w_moneda             tinyint,
   @w_oficina            smallint,
   @w_contabilizado      char(1),
   @w_tipo               char(1),
   @w_original           int,
   @w_contabilizado_ant  char(1),
   @w_monto_ant          money,
   @w_moneda_ant         tinyint,
   @w_dif_monto          money,
   @w_mon_def            tinyint,
   @w_tcotizacion        char(1),
   @w_cotizacion         money,
   @w_monto_mn           money,
   @w_banco              varchar(24),
   @w_secuencial         int,
   @w_estado_trn         char(10),
   @w_secuencial2        int,
   @w_perfil             char(10),
   @w_codvalor1          int,
   @w_af_codvalor1       char(1),
   @w_codvalor2          int,
   @w_af_codvalor2       char(1),
   @w_linea_credito      int,
   @w_contab_linea	 char(1),
   @w_cod_capital        catalogo,
   @w_fecha_ref		 datetime,
   @w_toperacion	 catalogo,
   @w_moneda_linea       tinyint,
   @w_moneda_cupo        tinyint,
   @w_valor_cupo         money,
   @w_cotiza_cupo        money,
   @w_trm		 money,
   @w_trm_dolar          money,
   @w_trm_ipc            money,
   @w_cod_ipc            tinyint,
   @w_utilizado_ant      money,
   @w_estado_ant         char(1),
   @w_gerente            smallint,
   @w_operacion          int,
   @w_li_tipo            char(1),
   @w_tipo_tr            char(1),
   @w_val_count          int,
   @w_num_dec            int,
   @w_par_mlocal         tinyint,
   @w_par_decimales      tinyint,
   @w_rowcount           int

 
   
SELECT @w_sp_name = 'sp_cont_tramite'
SELECT @w_contabilizado = 'N'


/*** Consulta Parametros Generales ***/
-- MONEDA LOCAL DEFAULT DE CREDITO
SELECT @w_par_mlocal = pa_tinyint
FROM cobis..cl_parametro
WHERE pa_producto  = 'CRE' 
  and pa_nemonico  = 'MLOCR'

if @w_par_mlocal is null or @@rowcount = 0
BEGIN
      /* Error, no existe valor de Parametro */
      SELECT @w_return = 2110312

      exec cobis..sp_cerror
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = @w_return
      return @w_return
END

-- NUMERO DE DECIMALES
SELECT 	@w_par_decimales = pa_tinyint
FROM cobis..cl_parametro
WHERE pa_producto = 'CTE'
  and pa_nemonico = 'DCI'

if @w_par_decimales is null or @@rowcount = 0
BEGIN
      /* Error, no existe valor de Parametro */
      SELECT @w_return = 2110313

      exec cobis..sp_cerror
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = @w_return
      return @w_return
END


-- ENCONTRAR LOS DATOS DEL TRAMITE QUE NOS PERMITAN VALIDAR EL PROCESO DE REGISTRO CONTABLE
SELECT
  @w_estado        = tr_estado,
  @w_monto         = tr_monto,
  @w_moneda        = tr_moneda,
  @w_oficina       = tr_oficina,
  @w_contabilizado = tr_contabilizado,
  @w_tipo          = tr_tipo,
  @w_linea_credito = tr_linea_credito,
  @w_gerente	 = tr_oficial
FROM cr_tramite
WHERE tr_tramite = @i_tramite

if @@rowcount = 0
BEGIN
   /* REGISTRO NO EXISTE */
   exec cobis..sp_cerror1
   @t_from  = @w_sp_name,
   @i_num   = 2101005,
   @i_pit   = @i_pit
   return 1 
END

if @w_linea_credito is not null
BEGIN
   SELECT @w_contab_linea = tr_contabilizado,
          @w_moneda_linea = tr_moneda,
          @w_li_tipo      = li_tipo
   FROM cr_tramite, cr_linea
   WHERE tr_tramite = li_tramite
   and  li_numero = @w_linea_credito
END   

-- Todos los cupos van en moneda pesos
IF exists(SELECT 	1 
          FROM 	cobis..cl_moneda
          WHERE   mo_moneda = @w_par_mlocal
            and     mo_decimales  = 'S')

   SELECT @w_num_dec = @w_par_decimales 
ELSE
   SELECT @w_num_dec = 0


SELECT @w_moneda_linea = isnull(@w_moneda_linea, @w_moneda)

-- REALIZAR LAS VALIDACIONES SOBRE EL TRAMITE
if @w_tipo not in ('O','C')
BEGIN
   /* EL TRAMITE A CONTABILIZAR NO ES OPERACION ESPECIFICA NI CUPO DE CREDITO */
   exec cobis..sp_cerror1
   @t_from  = @w_sp_name,
   @i_num   = 2101088,
   @i_pit   = @i_pit
   return 1 
END


if @w_estado <> 'A' and @i_operacion = 'I'
BEGIN
   /* TRAMITE NO ESTA APROBADO */
   exec cobis..sp_cerror1
   @t_from  = @w_sp_name,
   @i_num   = 2101090,
   @i_pit   = @i_pit
   return 1 
END

-- SI LA OPERACION ES "E" EGRESO O "A" AUMENTO, HAY QUE PASA EL VALOR DEL PARAMETRO @i_monto
-- A LA VARIABLE @w_monto
if @i_operacion in ('E','A')
   SELECT @w_monto = isnull(@i_monto,0)

-- PARA EL CASO DE CUPOS DE CREDITO, CUANDO ES RENOVACION Y ESTAMOS INGRESANDO,
-- SOLAMENTE SE CONTABILIZA LA DIFERENCIA EN MONTO ENTRE EL CUPO ORIGINAL Y EL NUEVO

if @w_tipo = 'C' and @i_operacion = 'I'
BEGIN
   -- ENCONTRAR DATOS DEL CUPO
   SELECT
   @w_original = li_original
   from cr_linea
   WHERE li_tramite = @i_tramite

   if @w_original is not null and @w_original > 0
   BEGIN
      -- ENCONTRAR DATOS DEL TRAMITE
      SELECT
      @w_contabilizado_ant = tr_contabilizado,
      @w_monto_ant         = li_monto,
      @w_moneda_ant        = li_moneda,
      @w_utilizado_ant     = li_utilizado,
      @w_estado_ant        = li_estado
      from cr_linea, cr_tramite
      WHERE li_tramite = tr_tramite
      and   li_numero  = @w_original

      -- VERIFICAR LA DIFERENCIA EN MONTO
      -- SOLAMENTE SI EL CUPO ANTERIOR ESTA CONTABILIZADO
      if @w_contabilizado_ant = 'S' and @w_estado_ant is null
      BEGIN
         SELECT @w_dif_monto = @w_monto - @w_monto_ant

         if @w_dif_monto < 0
            -- DEBO DISMINUIR LO QUE TENGO CONTABILIZADO
            SELECT @i_operacion = 'E',
                   @w_monto     = @w_dif_monto * (-1)
         else
            SELECT @w_monto = @w_dif_monto
      END

      if @w_contabilizado_ant = 'S' and @w_estado_ant = 'V'
         SELECT @w_monto = @w_monto_ant - @w_utilizado_ant

   END
END

-- ENCONTRAR LA COTIZACION Y EL VALOR DEL TRAMITE EN MONEDA LOCAL
-- ENCONTRAR EL CODIGO DE LA MONEDA LOCAL
SELECT @w_mon_def = pa_tinyint
from cobis..cl_parametro
WHERE pa_producto = 'CRE'
and   pa_nemonico = 'MLOCR'
set transaction isolation level read uncommitted


   -- OBTENER LOS MONTOS EN MONEDA LOCAL
if @i_operacion in ('I','E','A') 
BEGIN
   SELECT 
   @w_tcotizacion = 'N',
   @w_cotizacion  = isnull(cv_valor,1),
   @w_monto_mn    = isnull(@w_monto * cv_valor,0)
   from cob_conta..cb_vcotizacion
   WHERE cv_moneda = @w_moneda
   and cv_fecha = (SELECT max(cv_fecha)
                       from   cob_conta..cb_vcotizacion
                       WHERE  cv_moneda = @w_moneda
		       and cv_fecha  <=  isnull(@i_fecha_valor, @s_date))

   if @@rowcount = 0 and @w_moneda <> @w_mon_def
   BEGIN
      /* ERROR, NO EXISTE COTIZACION PARA LA MONEDA  */
      exec cobis..sp_cerror1
      @t_from  = @w_sp_name,
      @i_num   = 2101091,
      @i_pit   = @i_pit
      return 1       
   END

   if @w_moneda = @w_mon_def
      SELECT
      @w_tcotizacion = 'N',
      @w_monto_mn    = @w_monto,
      @w_cotizacion  = 1

END


-- SI EL MONTO ES IGUAL A CERO, SALIR SIN REALIZAR NINGUN PROCESO 
if @w_monto = 0
   return 0

-- ENCONTRAR EL CODIGO DEL CONCEPTO CAPITAL
   SELECT @w_cod_capital = pa_char
   from cobis..cl_parametro
   WHERE pa_producto = 'CCA'
   and pa_nemonico = 'CAP'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0
   BEGIN
      /* REGISTRO NO EXISTE */
      exec cobis..sp_cerror1
      @t_from  = @w_sp_name,
      @i_num   = 2101005,
      @i_pit   = @i_pit
      return 1 
   END

BEGIN TRAN
   -- PONER EN UNA VARIABLE EL NUMERO DE TRAMITE TRANSFORMADO A CARACTER
   SELECT @w_banco = convert(varchar(24),@i_tramite)
 
   -- SI EL TIPO DE OPERACION ES R (REVERSA, VERIFICAR EL ESTADO DE LA TRANSACCION
   -- INGRESADA ANTERIORMENTE, ACTUALIZAR EL ESTAD0 DE DICHA TRANSACCION A RV
   if @i_operacion = 'R'
   BEGIN
      -- ENCONTRAR EL ESTADO DE LA TRANSACCION INGRESADA
/*      SELECT
      @w_secuencial = tr_secuencial,
      @w_fecha_ref  = tr_fecha_ref,
      @w_estado_trn = tr_estado
      from cr_transaccion
      WHERE tr_banco      = @w_banco
      -- and   tr_toperacion = @w_tipo
      and   tr_tran       in ("APC", "API", "APR")
      and   tr_operacion = @i_tramite
      and   tr_estado <> "RV"
 
      -- ACTUALIZAR EL ESTADO DE LA TRANSACCION A "RV"
      update cr_transaccion set
      tr_estado = "RV"
      WHERE tr_secuencial = @w_secuencial
      and   tr_fecha_ref = @w_fecha_ref

      if @@error != 0
      BEGIN
             --ERROR, ACTUALIZANDO TRANSACCION EN CARTERA 
            exec cobis..sp_cerror1
            @t_from  = @w_sp_name,
            @i_num   = 2105039,
            @i_pit   = @i_pit
            return 1
      END

      if @w_estado_trn = "CON"
      BEGIN
         -- SI EL ESTADO ES CON (CONTABILIZADO), INGRESO UNA NUEVA TRANSACCION 
         -- QUE ANULE LA ANTERIOR
    
         -- ENCUENTRO EL SECUENCIAL PARA LA TRANSACCION
         exec @w_secuencial2 = cob_cartera..sp_gen_sec
                @i_operacion = -99

         -- INSERTO LA CABECERA DE LA TRANSACCION
         insert into cr_transaccion (
         tr_fecha_mov,   tr_toperacion,   tr_moneda,
         tr_operacion,   tr_tran,         tr_secuencial,
         tr_en_linea,    tr_banco,        tr_dias_calc,
         tr_ofi_oper,    tr_ofi_usu,      tr_usuario,
         tr_terminal,    tr_fecha_ref,    tr_secuencial_ref,
         tr_estado,      tr_gerente,	  tr_producto )		--ZR
         SELECT 
         @s_date,        tr_toperacion,   tr_moneda,
         tr_operacion,   "REV",           @w_secuencial2,
         tr_en_linea,    tr_banco,        tr_dias_calc,
         tr_ofi_oper,    tr_ofi_usu,      tr_usuario,
         tr_terminal,    isnull(@i_fecha_valor,@s_date), @w_secuencial, 
         "ING",          @w_gerente,	  21		--ZR
         from cr_transaccion
         WHERE tr_secuencial = @w_secuencial
         and   tr_fecha_ref = @w_fecha_ref

         if @@error != 0
         BEGIN
            -- ERROR, AL CREAR CABECERA DE TRANSACCION DE CCA
            exec cobis..sp_cerror1
            @t_from  = @w_sp_name,
            @i_num   = 2103030,
            @i_pit   = @i_pit
            return 1
         END

         --emg ab-18-01 Busqueda de la operacion para insertar en ca_det_trn
         SELECT @w_operacion  = tr_operacion
         from   cr_transaccion
         WHERE tr_secuencial = @w_secuencial
         and   tr_fecha_ref = @w_fecha_ref

         if @@error != 0
         BEGIN
             --ERROR, AL CREAR CABECERA DE TRANSACCION DE CCA
            exec cobis..sp_cerror1
            @t_from  = @w_sp_name,
            @i_num   = 2103030,
            @i_pit   = @i_pit
            return 1
         END  


         -- INSERTAR LOS DETALLES DE LA TRANSACCION
         insert into cr_det_trn (
         dtr_secuencial,    dtr_operacion, dtr_dividendo,      dtr_concepto,
         dtr_estado,        dtr_periodo,         dtr_codvalor,
      dtr_monto,         dtr_monto_mn,       dtr_moneda,
         dtr_cotizacion,    dtr_tcotizacion,    dtr_afectacion,
         dtr_cuenta,        dtr_beneficiario,   dtr_monto_cont,
         dtr_producto )
         SELECT
         @w_secuencial2,    @w_operacion,dtr_dividendo,      dtr_concepto,
         dtr_estado,        dtr_periodo,        dtr_codvalor,
         round(dtr_monto,@w_num_dec),  round(dtr_monto_mn,@w_num_dec),dtr_moneda,
         dtr_cotizacion,    dtr_tcotizacion,    dtr_afectacion,
         dtr_cuenta,        dtr_beneficiario,   dtr_monto_cont,
         21
         from cr_det_trn
         WHERE dtr_secuencial = @w_secuencial

         if @@error != 0
         BEGIN
            --ERROR, INSERTANDO DETALLE DE TRANSACCION
            exec cobis..sp_cerror1
            @t_from  = @w_sp_name,
            @i_num   = 2103032,
            @i_pit   = @i_pit
            return 1
         END
      END
*/
      -- ACTUALIZAR EL CAMPO tr_contabilizado DE LA TABLA cr_tramite
    if @i_origen  = 'C'  -- dba : 07/oct/99
    BEGIN
      update cr_tramite set
      tr_contabilizado = 'N'
      WHERE tr_tramite = @i_tramite

      if @@error != 0
      BEGIN
         /* ERROR, ACTUALIZANDO CAMPO tr_contabilizado */
         exec cobis..sp_cerror1
         @t_from  = @w_sp_name,
         @i_num   = 2105040,
         @i_pit   = @i_pit
         return 1
      END
    END
   END  -- FIN DE REVERSA


   -- PARA INGRESO/EGRESO, INGRESAR LA CABECERA DE LA TRANSACCION Y SUS RESPECTIVOS DETALLES
   else
   BEGIN
      -- ENCONTRAR EL NUMERO SECUENCIAL PARA LA TRANSACCION
/*      exec @w_secuencial = cob_cartera..sp_gen_sec
            @i_operacion = -99

      -- DETERMINAR EL TIPO DE TRANSACCION QUE VOY A INSERTAR SEGUN EL TIPO DE TRAMITE
      if @w_tipo = "C"
      BEGIN
         SELECT
         @w_perfil   = "APC",
         @w_codvalor1 = 1,
	 @w_toperacion = "ZCUP"

	SELECT 	@w_val_count = count(1)
	from 	cr_linea, cr_lin_ope_moneda
	WHERE	om_linea	= li_numero
	and 	om_producto 	="TCR"
	and     li_tramite 	= @i_tramite

        if @w_val_count  <> 0
         SELECT @w_codvalor1 = 3


	SELECT 	@w_val_count = count(1)
	from 	cr_linea
	WHERE   li_tramite 	= @i_tramite
	and     li_tipo 	= "S"

        if @w_val_count  <> 0
         SELECT @w_codvalor1 = 4
        
      END


   if @w_tipo = "C"
   BEGIN
      SELECT @w_li_tipo      = li_tipo
      from  cr_linea
      WHERE li_tramite = @i_tramite
   END   


      if @w_tipo = "C" and @w_li_tipo =  "O" --tipo de cupo solicitud
	BEGIN	
		SELECT @w_perfil = "APR"
	 	SELECT @w_toperacion = "ZOPE"	   
         	SELECT @w_codvalor1 = 2

	END 


      if @w_tipo = "O"
      BEGIN
         if @w_contab_linea = 'S'
	        SELECT @w_perfil = "API"
	 else
		SELECT @w_perfil = "APR"


         if @w_tipo = "O" and  @w_contab_linea = 'S'  and   @w_li_tipo =  "O" 
		SELECT @w_perfil = "APR"

         -- Credito, Pagos
         if @i_origen in ('C', 'P')  or @w_perfil = 'APR'
            SELECT @w_codvalor1 = 2
         else
            SELECT @w_codvalor1 = 2

	 SELECT @w_toperacion = "ZOPE"
         SELECT @w_codvalor2 = 2
      END



      -- DETERMINAR LA AFECTACION (DEBITO, CREDITO) PARA CADA ASIENTO, SEGUN LA OPERACION
      if @i_operacion = "I" or @i_operacion = "A"
         SELECT 
         @w_af_codvalor1 = "C",
         @w_af_codvalor2 = "D"
     else
         SELECT 
         @w_af_codvalor1 = "D",
         @w_af_codvalor2 = "C"

      -- INGRESAR LA CABECERA DE LA TRANSACCION
      insert into cr_transaccion (
      tr_fecha_mov,   tr_toperacion,   tr_moneda,
      tr_operacion,   tr_tran,         tr_secuencial,
      tr_en_linea,    tr_banco,        tr_dias_calc,
      tr_ofi_oper,    tr_ofi_usu,      tr_usuario,
      tr_terminal,    tr_fecha_ref,    tr_secuencial_ref,
      tr_estado,      tr_gerente,      tr_producto )
      values (
     @s_date,        @w_toperacion,   			@w_moneda,
      @i_tramite,     @w_perfil,       			@w_secuencial,
      "S",            @w_banco,        			0,
      @w_oficina,     @s_ofi,          			@s_user,
      @s_term,        isnull(@i_fecha_valor,@s_date),  	0,
      "ING",          @w_gerente,			21)


      if @@error != 0
      BEGIN
           --ERROR, AL CREAR CABECERA DE TRANSACCION EN CARTERA
         exec cobis..sp_cerror1
         @t_from  = @w_sp_name,
         @i_num   = 2103030,
         @i_pit   = @i_pit
         return 1
      END      

         --Busqueda de la operacion para insertar en ca_det_trn
         SELECT @w_operacion  = tr_operacion
         from   cr_transaccion
         WHERE tr_secuencial = @w_secuencial
         and   tr_fecha_ref = @w_fecha_ref

         if @@error != 0
         BEGIN
            --ERROR, AL CREAR CABECERA DE TRANSACCION DE CCA
            exec cobis..sp_cerror1
            @t_from  = @w_sp_name,
            @i_num   = 2103030,
            @i_pit   = @i_pit
            return 1
         END  


          --INICIO CAMBIO DBA: 08/OCT/99
          -- desde Credito   tipo Original
        if (@i_origen = 'C' and @w_tipo = 'O') 
        BEGIN
           SELECT @w_moneda_cupo = @w_moneda_linea
           SELECT @w_valor_cupo = isnull(@w_monto_mn / cv_valor,0),
                  @w_cotiza_cupo  = isnull(cv_valor,1)
           from cob_conta..cb_vcotizacion
           WHERE cv_moneda = @w_moneda_linea
           and cv_fecha = (SELECT max(cv_fecha)
                       from   cob_conta..cb_vcotizacion
                       WHERE  cv_moneda = @w_moneda_linea
		       and cv_fecha  <=  isnull(@i_fecha_valor, @s_date))
        END
        else
        BEGIN
           SELECT @w_moneda_cupo = @w_moneda
           SELECT @w_valor_cupo = @w_monto
           SELECT @w_cotiza_cupo = @w_cotizacion
        END

          --si es pago de desembolso se graba con moneda del cupo
        if  @i_origen = 'P' 
            SELECT @w_moneda_cupo = @w_moneda_linea

          --FIN CAMBIO DBA: 08/OCT/99

         -- INGRESAR EL ASIENTO PARA LA CUENTA DE APROBACIONES NO DESEMBOLSADAS
         insert into cr_det_trn (
         dtr_secuencial,    dtr_operacion,dtr_dividendo,      dtr_concepto,
         dtr_estado,        dtr_periodo,        dtr_codvalor,
         dtr_monto,         dtr_monto_mn,       dtr_moneda,
         dtr_cotizacion,    dtr_tcotizacion,    dtr_afectacion,
         dtr_cuenta,        dtr_beneficiario,   dtr_monto_cont,
         dtr_producto )
         values (
         @w_secuencial,     @i_tramite,         0,            @w_cod_capital,
         0,                 0,                  @w_codvalor1,
         round(@w_valor_cupo,@w_num_dec),round(@w_monto_mn,@w_num_dec),@w_moneda_cupo,
         @w_cotiza_cupo,    @w_tcotizacion,     @w_af_codvalor1,
         "00000",           "CRE",              0.00,
         21 )


         if @@error != 0
         BEGIN
            --ERROR, INSERTANDO DETALLE DE LA TRANSACCION
            exec cobis..sp_cerror1
            @t_from  = @w_sp_name,
            @i_num   = 2103032,
            @i_pit   = @i_pit
            return 1
         END      
      
      if @i_origen  = 'C' and @w_tipo = 'O' and  @w_perfil <> 'APR'
      BEGIN
	insert into cr_det_trn (
	dtr_secuencial, dtr_operacion,dtr_dividendo, dtr_concepto,
	dtr_estado, dtr_periodo, dtr_codvalor,
	dtr_monto,  dtr_monto_mn, dtr_moneda,
	dtr_cotizacion, dtr_tcotizacion, dtr_afectacion,
	dtr_cuenta, dtr_beneficiario, dtr_monto_cont,
        dtr_producto)
	values (
	@w_secuencial, 	 @w_operacion,    0, 	@w_cod_capital,
	0, 		     0, 		@w_codvalor2,
	round(@w_monto,@w_num_dec), round(@w_monto_mn,@w_num_dec), 	@w_moneda,
	@w_cotizacion, 	     @w_tcotizacion, 	@w_af_codvalor2,
	"00000", 	     "CRE", 		0.00,
        21)

	if @@error != 0
	BEGIN
             --ERROR, INSERTANDO DETALLE DE LA TRANSACCION
            exec cobis..sp_cerror1
            @t_from  = @w_sp_name,
            @i_num   = 2103032,
            @i_pit   = @i_pit
  	    return 1
	END
      END
*/
      -- ACTUALIZAR EL CAMPO tr_contabilizado DE LA TABLA cr_tramite
    if @i_origen  = 'C'
    BEGIN
      update cr_tramite set
      tr_contabilizado = 'S'
      WHERE tr_tramite = @i_tramite

      if @@error != 0
      BEGIN
         /* ERROR, ACTUALIZANDO CAMPO tr_contabilizado */
         exec cobis..sp_cerror1
         @t_from  = @w_sp_name,
         @i_num   = 2105040,
         @i_pit   = @i_pit
         return 1
      END
     END
   END  -- FIN DE OPERACION "I","E","A"
commit tran

return 0

GO

