/***********************************************************************/
/*	Archivo:			    convenios.sp                               */
/*	Stored procedure:		sp_convenios                               */
/*	Base de Datos:			cob_credito                                */
/*	Producto:			    Credito	                                   */
/*	Disenado por:			Patricia Garzon                            */
/*	Fecha de Documentacion: 	01/Mar/2001                            */
/***********************************************************************/
/*			IMPORTANTE		       		                               */
/*	Este programa es parte de los paquetes bancarios propiedad de      */ 
/*	"MACOSA",representantes exclusivos para el Ecuador de la           */
/*	AT&T							                                   */                          
/*	Su uso no autorizado queda expresamente prohibido asi como         */
/*	cualquier autorizacion o agregado hecho por alguno de sus          */
/*	usuario sin el debido consentimiento por escrito de la             */
/*	Presidencia Ejecutiva de MACOSA o su representante	               */
/***********************************************************************/
/*			PROPOSITO				                                   */
/*	Este stored procedure permite crear los tr mites para la carga     */ 
/*	masiva de operaciones de Convenios                                 */
/*								                                       */
/***********************************************************************/
/*			MODIFICACIONES				                               */
/*	FECHA		AUTOR			RAZON		                           */
/*      01/mar/2001     Patricia Garzon         Emision inicial        */
/***********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_convenios')
   drop proc sp_convenios
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_convenios (
   @s_ssn                int = null,
   @s_user               login = null,
   @s_sesn               int = null,
   @s_term               varchar(30) = null,
   @s_date               datetime = null,
   @s_srv                varchar(30) = null,
   @s_lsrv               varchar(30) = null,
   @s_ofi                smallint = NULL,
   @s_rol                int = null,
   @s_org_err             char(1) = null,
   @s_error               int = null,
   @s_sev                 tinyint = null,
   @s_msg                 descripcion = null,
   @s_org                 char(1) = null,
   @t_rty                 char(1)  = null,
   @t_trn                smallint = 21020,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_tipo               char(1) = null,
   @i_oficina_tr         smallint = null,
   @i_usuario_tr         login = null,
   @i_fecha_crea         datetime = null,
   @i_oficial            smallint = null,
   @i_sector             catalogo = null,
   @i_ciudad             int = null,
   @i_nivel_ap           tinyint = null,
   @i_fecha_apr          datetime = null,
   @i_usuario_apr        login = null,
   @i_banco              cuenta = null,
   @i_linea_credito      cuenta = null,     
   @i_toperacion         catalogo = null,
   @i_producto           catalogo = null,
   @i_monto              money = 0,
   @i_moneda             tinyint = 0,
   @i_periodo            catalogo = null,
   @i_num_periodos       smallint = 0,
   @i_destino            catalogo = null,
   @i_ciudad_destino     int = null,
   @i_cuenta_corriente   cuenta = null,
   @i_cliente            int = null,   
   @i_estado             char(1) = null,
   @o_tramite            int = null out,
   @i_clase              catalogo = null   
   
)
as


declare
   @w_today           datetime,     -- FECHA DEL DIA
   @w_return          int,          -- VALOR QUE RETORNA
   @w_sp_name         varchar(32),  -- NOMBRE STORED PROC
   @w_tramite         int,
   @w_truta           tinyint,
   @w_numero_linea    int,
   @w_clase_cartera   varchar(10),
   @w_estacion		 smallint,
   @w_etapa		 tinyint,
   @w_paso		 tinyint,
   @w_login_oficial	 login,
   @w_estacion_ofi	 smallint,
   @w_prioridad	         tinyint,
   @w_paso_ofi		 tinyint,
   @w_rowcount           int


select @w_sp_name = 'sp_convenios'
select @w_today = @s_date	


if @i_linea_credito is not null
begin
   select
   @w_numero_linea = li_numero
   from      cob_credito..cr_linea
   where   li_num_banco = @i_linea_credito

   if @@rowcount = 0
   begin
      /** REGISTRO NO EXISTE **/
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2101010
      return 1    
   end
end

/* obtengo la ruta de convenios */
select
@w_truta = pa_tinyint
from cobis..cl_parametro 
where pa_nemonico = 'TRUTAO'
and pa_producto = 'CRE'
set transaction isolation level read uncommitted


-- OBTENCION DE PARAMETROS NO ENVIADOS ***********
select @i_usuario_tr = isnull(@i_usuario_tr, @s_user)

select
@i_ciudad = of_ciudad
from   cobis..cl_oficina
where  of_oficina = @i_oficina_tr
set transaction isolation level read uncommitted

if @i_estado = "A"
begin
   select @i_fecha_apr = isnull(@i_fecha_apr, @s_date),
	  @i_usuario_apr = isnull(@i_usuario_apr, @s_user)
end

select @i_tipo = isnull(@i_tipo, "O")

if @i_clase is null
begin
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
end


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
      --return 1 
      return 2101007
   end

   /* INSERCION EN LA TABLA CR_TRAMITE */

   insert into cr_tramite (
   tr_tramite, tr_tipo, tr_oficina,
   tr_usuario, tr_fecha_crea, tr_oficial,
   tr_sector, tr_ciudad, tr_estado,
   tr_nivel_ap, tr_fecha_apr, tr_usuario_apr,
   tr_truta, tr_secuencia, tr_numero_op,
   tr_numero_op_banco, tr_proposito, tr_razon,
   tr_txt_razon, tr_efecto, tr_cliente,
   tr_grupo, tr_fecha_inicio, tr_num_dias,
   tr_per_revision, tr_condicion_especial, tr_linea_credito,
   tr_toperacion, tr_producto, tr_monto, 
   tr_moneda, tr_periodo, tr_num_periodos,
   tr_destino, tr_ciudad_destino, tr_cuenta_corriente,
   tr_renovacion, tr_clase ,tr_sobrepasa, 
   tr_reestructuracion, tr_concepto_credito,   
   tr_aprob_gar, tr_cont_admisible)		
   values (
   @w_tramite, @i_tipo, @i_oficina_tr,
   @i_usuario_tr, @w_today, @i_oficial,
   @i_sector, @i_ciudad, @i_estado,
   @i_nivel_ap, @i_fecha_apr, @i_usuario_apr,
   @w_truta, 0, null,
   null, null, null,
   null, null, @i_cliente,  
   null, null, null,
   null, null, @w_numero_linea,
   @i_toperacion, @i_producto, @i_monto, 
   @i_moneda, @i_periodo, @i_num_periodos,
   @i_destino, @i_ciudad_destino, @i_cuenta_corriente,
   0, @i_clase,'N', 
   'N', '3', 		 --emg Jun-19-01 cambio tipo de concepto y aprobacion de garantias
   '3', 'N')   		

   if @@error <> 0 
   begin
      /* ERROR EN INSERCION DE REGISTRO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103001

      --return 1 
      return 2103001
   end

   -- TRANSACCION DE SERVICIO
   insert into ts_tramite (
   secuencial, tipo_transaccion, clase,
   fecha, usuario, terminal,
   oficina, tabla, lsrv,
   srv, tramite, tipo,
   oficina_tr, usuario_tr, fecha_crea,
   oficial, sector, ciudad,
   estado, nivel_ap, fecha_apr,
   usuario_apr, truta, secuencia,
   numero_op, numero_op_banco, proposito,
   razon, txt_razon, efecto,
   cliente, grupo, fecha_inicio,
   num_dias, per_revision, condicion_especial,
   linea_credito, toperacion, producto,
   monto, moneda, periodo,
   num_periodos, destino, ciudad_destino,
   cuenta_corriente, renovacion,
   clasecca, reestructuracion, concepto_credito, 	
   aprob_gar, cont_admisible)		
   values(
   @s_ssn, @t_trn, "N",
   @s_date, @s_user, @s_term,
   @s_ofi, "cr_tramite", @s_lsrv,
   @s_srv, @w_tramite, @i_tipo,
   @i_oficina_tr, @i_usuario_tr, @w_today,
   @i_oficial, @i_sector, @i_ciudad,
   @i_estado, @i_nivel_ap, @i_fecha_apr,
   @i_usuario_apr, @w_truta, 0,
   null, null, null,
   null, null, null,
   @i_cliente, null, null,    
   null, null, null,
   @w_numero_linea, @i_toperacion, @i_producto,
   @i_monto, @i_moneda, @i_periodo,
   @i_num_periodos, @i_destino, @i_ciudad_destino,
   @i_cuenta_corriente, 0,
   @i_clase, 'N', '3',	--emg Jun-19-01 cambio de concepto  y aprob garantia 
   '3', 'N')		

   if @@error <> 0 
   begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103003
      --return 1 
      return 2103003
   end    

   -- INSERTAR LOS REGISTROS EN LA TABLA CR_DEUDORES DESDE COBIS..CL_CLIENTE
   insert into cr_deudores (
   de_tramite, de_cliente, de_rol,
   de_ced_ruc)
   select
   @w_tramite, cl_cliente, cl_rol,cl_ced_ruc
   from cobis..cl_det_producto, cobis..cl_cliente
   where dp_cuenta = @i_banco
   and   dp_producto = 7
   and   cl_det_producto = dp_det_producto

   if @@error <> 0 
      begin
      /* ERROR EN INSERCION DE REGISTRO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103001
      --return 1 
      return 2103001
   end


   /* insercion en la tabla de tramites reservados */
   insert into cr_lin_reservado		--SBU 07/ago/2001
   values (@w_tramite, @i_cliente, @w_numero_linea,
           @i_linea_credito, @i_toperacion, @i_producto, 
           @i_moneda, @i_monto, @i_monto)

   if @@error <> 0 
   begin
      /* Error en insercion de registro */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103001        
      --return 1 
      return 2103001
   end


   /**** Verificacion de estaciones ****/
   /* obtener el login del oficial */
   select @w_login_oficial = fu_login
   from   cobis..cc_oficial, cobis..cl_funcionario   
   where  oc_oficial = @i_oficial
   and    oc_funcionario = fu_funcionario
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0
   begin
   /* oficial no existe en funcionarios */
	exec cobis..sp_cerror
	@t_debug = @t_debug,
	@t_file  = @t_file, 
	@t_from  = @w_sp_name,
	@i_num   = 2101022
	--return 1 	
        return 2101022
   end

   /* obtener la etapa inicial de la ruta */
   select @w_etapa = pa_etapa,
          @w_paso  = pa_paso
   from   cr_pasos, cr_etapa
   where  pa_etapa = et_etapa
   and    pa_truta = @w_truta
   and    et_tipo = 'I'

   /* Comprobar que exista una estacion valida para usuario_tr,
   en la etapa inicial de la ruta */
   select @w_estacion = ee_estacion
   from   cr_etapa_estacion, cr_estacion 
   where  ee_etapa = @w_etapa
   and    ee_estacion = es_estacion
   and    es_usuario = @i_usuario_tr
   and    ee_estado = 'A'   

   if @@rowcount = 0
   begin
	/** registro no existe **/
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 2101012
		--return 1 	
                return 2101012
   end

   select @w_paso = 1


   /* Comprobar que el oficial tenga una estacion */
   select @w_estacion_ofi = es_estacion
   from	cr_estacion
   where es_usuario = @w_login_oficial

   if @@rowcount = 0
   begin
	/* oficial no tiene estacion de trabajo asignada */
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 2101023
		--return 1 	
                return 2101023
   end	

   /* Verificar si el oficial esta haciendo el ingreso de datos */
   if @i_usuario_tr = @w_login_oficial
   begin
      /*comprobar si la estacion del oficial est  en la ruta*/
	select 	@w_paso_ofi = pa_paso
        from   	cr_pasos, cr_etapa_estacion, cr_estacion
	where	pa_truta = @w_truta
	and	pa_etapa = ee_etapa
        and     ee_estacion = es_estacion
	and     es_estacion = @w_estacion_ofi
        and     ee_estacion = @w_estacion_ofi		--ZR OPTIMIZACION 

	if @@rowcount = 0
	begin
	/* estacion de oficial no esta en ruta del tr mite */
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 2101024
		--return 1 	
                return 2101024
	end
   end


   /** Obtener prioridad **/
   SELECT @w_prioridad = tt_prioridad
   from   cr_tipo_tramite
   where  tt_tipo = @i_tipo

   if @@rowcount = 0
   begin
      select @w_prioridad = 1
   end


   /**** INSERTAR EL PRIMER REGISTRO EN cr_ruta_tramite ***/
   insert into cr_ruta_tramite (
   rt_tramite,rt_secuencia,rt_truta,
   rt_paso,rt_etapa,rt_estacion,
   rt_llegada,rt_prioridad,rt_abierto)
   values (
   @w_tramite,1,@w_truta,
   @w_paso,@w_etapa,@w_estacion,
   @w_today, @w_prioridad,"C")	
   
   If @@error <> 0 
   begin
      /* Error en insercion de registro */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103001
      --return 1 
      return 2103001
   end

commit tran

select @o_tramite = @w_tramite
go

