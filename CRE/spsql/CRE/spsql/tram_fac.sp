/************************************************************************/
/*  Archivo:                tram_fac.sp                                 */
/*  Stored procedure:       sp_tram_fac                                 */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_tram_fac')
    drop proc sp_tram_fac
go

create proc sp_tram_fac (
   @s_ssn                int         = null,
   @s_user               login       = null,
   @s_sesn               int         = null,
   @s_term               varchar(30) = null,
   @s_date               datetime    = null,
   @s_srv                varchar(30) = null,
   @s_lsrv               varchar(30) = null,
   @s_ofi                smallint    = NULL,
   @s_rol                int         = null,
   @s_org_err            char(1)     = null,
   @s_error              int         = null,
   @s_sev                tinyint     = null,
   @s_msg                descripcion = null,
   @s_org                char(1)     = null,
   @t_rty                char(1)     = null,
   @t_trn                smallint    = 21020,
   @t_debug              char(1)     = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_tipo               char(1)     = null,
   @i_oficina_tr         smallint    = null,
   @i_usuario_tr         login       = null,
   @i_fecha_crea         datetime    = null,
   @i_oficial            smallint    = null,
   @i_sector             catalogo    = null,
   @i_ciudad             int         = null,
   @i_nivel_ap           tinyint     = null,
   @i_fecha_apr          datetime    = null,
   @i_usuario_apr        login       = null,
   @i_banco              cuenta      = null,
   @i_linea_credito      cuenta      = null,     
   @i_toperacion         catalogo    = null,
   @i_producto           catalogo    = null,
   @i_monto              money       = 0,
   @i_moneda             tinyint     = 0,
   @i_periodo            catalogo    = null,
   @i_num_periodos       smallint    = 0,
   @i_destino            catalogo    = null,
   @i_ciudad_destino     int         = null,
   @i_cuenta_corriente   cuenta      = null,
   @i_cliente            int         = null,   
   @i_estado             char(1)     = null,
   @i_clase              catalogo    = null,  --pga 8nov2001  
   @i_tramite_padre      int         = null,  --pga 8nov2001
   @i_truta              tinyint     = null, 
   @o_tramite            int         = null out
)
as


declare
   @w_today              datetime,     -- FECHA DEL DIA
   @w_return             int,          -- VALOR QUE RETORNA
   @w_sp_name            varchar(32),  -- NOMBRE STORED PROC
   @w_tramite            int,
   @w_truta              tinyint,
   @w_numero_linea       int,
   @w_clase_cartera      varchar(10),
   @w_estacion		 smallint,
   @w_etapa		 tinyint,
   @w_paso		 tinyint,
   @w_login_oficial	 login,
   @w_estacion_ofi	 smallint,
   @w_prioridad	         tinyint,
   @w_paso_ofi		 tinyint


select @w_sp_name = 'sp_tram_fac'
select @w_today = @s_date	
--print 'estoy en  sp_tram_fac %1! tram padre %2!', @i_truta, @i_tramite_padre              
select @i_tipo = isnull(@i_tipo, 'O')

	exec @w_return = cob_credito..sp_clasif_cartera
	@i_toperacion = @i_toperacion,
	@i_moneda = @i_moneda,
	@i_salida = 'S',
	@i_monto = @i_monto,
	@i_tipo = 'O',
	@o_clase_cartera = @w_clase_cartera out
	if @w_return <> 0
	  return @w_return

	select @i_clase = @w_clase_cartera



-- INICIO DE TRANSACCION ***********
begin tran
   /* NUMERO SECUENCIAL DE TRAMITE */
   exec cobis..sp_cseqnos
   @t_debug = @t_debug,
   @t_file  = @t_file, 
   @t_from  = @w_sp_name,
   @i_tabla = 'cr_tramite',
   @o_siguiente = @w_tramite out

   if @w_tramite is NULL
   begin
      /* NO EXISTE TABLA EN TABLA DE SECUENCIALES*/
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2101007
      return 1 
   end

   /* INSERCION EN LA TABLA CR_TRAMITE */

   insert into cr_tramite (
   tr_tramite,          tr_tipo,               tr_oficina,
   tr_usuario,          tr_fecha_crea,         tr_oficial,
   tr_sector,           tr_ciudad,             tr_estado,
   tr_nivel_ap,    tr_fecha_apr,          tr_usuario_apr,
   tr_truta,            tr_secuencia,          tr_numero_op,
   tr_numero_op_banco,  tr_proposito,          tr_razon,
   tr_txt_razon,        tr_efecto,             tr_cliente,
   tr_grupo,            tr_fecha_inicio,       tr_num_dias,
   tr_per_revision,     tr_condicion_especial, tr_linea_credito,
   tr_toperacion,       tr_producto,           tr_monto, 
   tr_moneda,           tr_periodo,            tr_num_periodos,
   tr_destino,          tr_ciudad_destino,     tr_cuenta_corriente,
   tr_renovacion,       tr_clase,              tr_sobrepasa, 
   tr_reestructuracion, tr_concepto_credito,   tr_aprob_gar,        
   tr_cont_admisible)		
   values (
   @w_tramite,    @i_tipo,           @i_oficina_tr,
   @i_usuario_tr, @w_today,          @i_oficial,
   @i_sector,     @i_ciudad,         @i_estado,
   @i_nivel_ap,   @w_today,          @i_usuario_apr,
   @i_truta,      0,                 null,
   null,          null,              null,
   null,          null,              @i_cliente,  
   null,          null,              null,
   null,          null,              null,
   @i_toperacion, @i_producto,       @i_monto, 
   @i_moneda,     @i_periodo,        @i_num_periodos,
   @i_destino,    @i_ciudad_destino, @i_cuenta_corriente,
   0,             @i_clase,          'N', 
   'N',           '3', 		     '3', 
   'N')   		
   if @@error <> 0 
   begin
      /* ERROR EN INSERCION DE REGISTRO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103001
      return 1 
   end

   -- TRANSACCION DE SERVICIO
   insert into ts_tramite (
   secuencial,    tipo_transaccion, clase,            fecha,            usuario,      terminal,
   oficina,       tabla,            lsrv,             srv,              tramite,      tipo,
   oficina_tr,    usuario_tr,       fecha_crea,       oficial,          sector,       ciudad,
   estado,        nivel_ap,         fecha_apr,        usuario_apr,      truta,        secuencia,
   numero_op,     numero_op_banco,  proposito,        razon,            txt_razon,    efecto,
   cliente,       grupo,            fecha_inicio,     num_dias,         per_revision, condicion_especial,
   linea_credito, toperacion,       producto,         monto,            moneda,       periodo,
   num_periodos,  destino,          ciudad_destino,   cuenta_corriente, renovacion,
   clasecca,      reestructuracion, concepto_credito, aprob_gar,        cont_admisible)		
   values(
   @s_ssn,          @t_trn,        'N',               @s_date,        @s_user,    @s_term,
   @s_ofi,          'cr_tramite',  @s_lsrv,           @s_srv,         @w_tramite, @i_tipo,
   @i_oficina_tr,   @i_usuario_tr, @w_today,          @i_oficial,     @i_sector,  @i_ciudad,
   @i_estado,       @i_nivel_ap,   @w_today,          @i_usuario_apr, @i_truta,   0,
   null,            null,          null,              null,           null,       null,
   @i_cliente,      null,          null,              null,           null,       null,
   null,            @i_toperacion, @i_producto,       @i_monto,       @i_moneda,  @i_periodo,
   @i_num_periodos, @i_destino,    @i_ciudad_destino, @i_cuenta_corriente, 0,
   @i_clase,        'N',           '3',	              '3',            'N')		

   if @@error <> 0 
   begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103003
      return 1 
   end    

   -- INSERTAR LOS REGISTROS EN LA TABLA CR_DEUDORES DESDE COBIS..CL_CLIENTE

   insert into cr_deudores (
   de_tramite, de_cliente, de_rol,  de_ced_ruc)
   select
   @w_tramite, @i_cliente, 'D',  en_ced_ruc
   from cobis..cl_ente
   where en_ente = @i_cliente

   if @@error <> 0 
      begin
      /* ERROR EN INSERCION DE REGISTRO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103001
      return 1 
   end


   /**** INSERTAR EL PRIMER REGISTRO EN cr_ruta_tramite ***/
   insert into cr_ruta_tramite (
   rt_tramite, rt_secuencia, rt_truta,
   rt_paso,    rt_etapa,     rt_estacion,
   rt_llegada, rt_prioridad, rt_abierto)
   select   
   @w_tramite, rt_secuencia, rt_truta,
   rt_paso,    rt_etapa,     rt_estacion,
   rt_llegada, rt_prioridad, rt_abierto
   from cob_credito..cr_ruta_tramite 
   where rt_tramite = @i_tramite_padre

   If @@error <> 0 
   begin
      /* Error en insercion de registro */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103001
      return 1 
   end

commit tran

select @o_tramite = @w_tramite

GO
