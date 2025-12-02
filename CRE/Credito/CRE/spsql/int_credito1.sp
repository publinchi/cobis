/************************************************************************/
/*  Archivo:                int_credito1.sp                             */
/*  Stored procedure:       sp_int_credito1                             */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
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
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_int_credito1')
    drop proc sp_int_credito1
go

create proc sp_int_credito1 (
	@s_ssn          	int      = null,
	@s_user         	login    = null,
	@s_sesn			int    = null,
	@s_term         	descripcion = null,
	@s_date         	datetime = null,
	@s_srv			varchar(30) = null,
	@s_lsrv	  		varchar(30) = null,
	@s_rol			smallint = null,
	@s_ofi          	smallint  = null,
	@s_org_err		char(1) = null,
	@s_error		int = null,
	@s_sev			tinyint = null,
	@s_msg			descripcion = null,
    @s_org			char(1) = null,
	@t_rty          	char(1)  = null,
	@t_trn          	smallint = null,
	@t_debug        	char(1)  = 'N',
	@t_file         	varchar(14) = null,
	@t_from         	varchar(30) = null,
	@i_tramite      	int = NULL,
	@i_numero_op		int = NULL,
	@i_numero_op_banco	cuenta = NULL,
	@i_fecha_concesion	datetime = NULL,
	@i_fecha_fin		datetime = NULL,
	@i_monto		money = NULL,
	@i_tabla_temporal	char(1) = 'S'

)
as
declare
   @w_today		    datetime,
   @w_sp_name		varchar(32),
   @w_reversada     int,
   @w_return		int,
   @w_secuencia     smallint,
   @w_tipo_tr       char(1),
   @w_cliente       int,
   @w_of_ciudad     int,
   @w_fecha_ini     datetime,
   @w_tr_oficial    smallint,
   @w_territorial   smallint,
   @w_regional      smallint,
   @w_tr_oficina    smallint,
   @w_nro_feriados  int,
   @w_tiempo        int,
   @w_etapa         smallint,
   @w_estacion      smallint


/* INICIALIZACION DE VARIABLES */
select @w_today = @s_date
select @w_sp_name = 'sp_int_credito1'

/*****************************/
/* CODIGOS DE TRANSACCIONES  */

if (@t_trn <> 21889)
begin
    /* TIPO DE TRANSACCION NO CORRESPONDE */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 2101006
    return 1
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if
	@i_tramite is NULL or
	@i_numero_op is NULL or
	@i_numero_op_banco is NULL or
	@i_fecha_concesion is NULL or
        @i_fecha_fin is null or
	@i_monto is NULL
begin
    /* CAMPOS NOT NULL CON VALORES NULOS */
     exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = @w_sp_name,
     @i_num   = 2101001
     return 1
end



/* CHEQUEO DE EXISTENCIAS */
/**************************/
/*  SI YA SE LIQUIDO Y FUE REVERSADA, NO HACE NADA*/
SELECT @w_reversada = tr_numero_op,
@w_secuencia = tr_secuencia
FROM cob_credito..cr_tramite
WHERE tr_tramite = @i_tramite

if @w_reversada is not null
begin
   return 0
end


IF EXISTS (SELECT * FROM cob_credito..cr_tramite
	   WHERE tr_tramite = @i_tramite)
BEGIN
        /* TIPO DE TRAMITE */
        /*******************/
        select @w_tipo_tr  = tr_tipo
        from   cob_credito..cr_tramite
        where  tr_tramite = @i_tramite


        /* CODIGO CLIENTE DEUDOR PRINCIPAL */
        /***********************************/
        select @w_cliente  = de_cliente
        from   cob_credito..cr_deudores
        where  de_tramite = @i_tramite AND
        de_rol = 'D'


        begin tran

	/* ACTUALIZA EN EL TRAMITE EL TR_NUMERO_OP Y TR_NUMERO_OP_BANCO */
	UPDATE cr_tramite
	SET tr_numero_op = @i_numero_op,
	    tr_numero_op_banco = @i_numero_op_banco,
	    tr_fecha_concesion = @i_fecha_concesion,
	    tr_monto = @i_monto
	WHERE tr_tramite = @i_tramite

	if @@error <> 0
	begin
        	/* ERROR EN ACTUALIZACION DE REGISTRO */
	        exec cobis..sp_cerror
        	@t_debug = @t_debug,
	        @t_file  = @t_file,
        	@t_from  = @w_sp_name,
	        @i_num   = 2105001
        	return 1
	end

	/* ACTUALIZA EN HISTORICO EL NUMERO DE OPERACION */
	UPDATE cr_hist_credito
	SET ho_num_ope = @i_numero_op_banco,
	    ho_fecha_venc = @i_fecha_fin

	WHERE ho_num_tra = @i_tramite

	if @@error <> 0
	begin
        	/* ERROR EN ACTUALIZACION DE REGISTRO */
	        exec cobis..sp_cerror
        	@t_debug = @t_debug,
	        @t_file  = @t_file,
        	@t_from  = @w_sp_name,
	        @i_num   = 2105001
        	return 1
	end

   /*****GAP EF-045 BancaMia***/ --LPO 11/Feb/2009 INICIO

   select @w_tr_oficial = tr_oficial,
          @w_tr_oficina = tr_oficina,
          @w_fecha_ini  = rt_llegada,
          @w_etapa      = isnull(rt_etapa_sus,rt_etapa),
          @w_estacion   = isnull(rt_estacion_sus,rt_estacion)
   from cob_credito..cr_tramite,
        cob_credito..cr_ruta_tramite
   where tr_tramite   = rt_tramite
     and tr_tramite   = @i_tramite
     and rt_salida   is null

   select @w_regional    = of_zona ,
          @w_territorial = of_regional,
          @w_of_ciudad   = of_ciudad
   from cobis..cl_oficina
   where of_oficina = @w_tr_oficina

   select @w_nro_feriados = count (1)
   from cobis..cl_dias_feriados
   where df_ciudad  = @w_of_ciudad
     and df_fecha  >=  @w_fecha_ini
     and df_fecha  <=  @i_fecha_concesion
     and df_real    = 'S'

   select @w_tiempo = datediff(dd,@w_fecha_ini,@i_fecha_concesion) - @w_nro_feriados

   insert into cr_mov_tramite(
   mt_tramite,               mt_etapa,          mt_estacion,
   mt_tiempo,                mt_oficial,        mt_oficina,
   mt_regional,              mt_territorial
   )
   values(
   @i_tramite,               @w_etapa,          @w_estacion,
   @w_tiempo,                @w_tr_oficial,     @w_tr_oficina,
   @w_regional,              @w_territorial
   )

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

   /**************************/  --LPO 11/Feb/2009 FIN



        commit tran
        return 0

END
ELSE
begin
	 /*ERROR REGISTRO NO EXISTE */
        exec cobis..sp_cerror
	@t_debug = @t_debug,
        @t_file  = @t_file,
	@t_from  = @w_sp_name,
        @i_num   = 2101005
	return 1
end
go
