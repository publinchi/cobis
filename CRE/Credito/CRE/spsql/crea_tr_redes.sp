/************************************************************************/
/*  Archivo:                crea_tr_redes.sp                            */
/*  Stored procedure:       sp_crea_tr_redes                            */
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

if exists(select 1 from sysobjects where name ='sp_crea_tr_redes')
    drop proc sp_crea_tr_redes
go

create proc sp_crea_tr_redes
(
   @s_ssn                int = null,
   @s_user               login = null,
   @s_sesn               int = null,
   @s_term               varchar(30) = null,
   @s_date               datetime = null,
   @s_srv                varchar(30) = null,
   @s_lsrv               varchar(30) = null,
   @s_ofi                smallint = NULL,
   @s_rol                int = null,
   @s_org_err            char(1) = null,
   @s_error              int = null,
   @s_sev                tinyint = null,
   @s_msg                descripcion = null,
   @s_org                char(1) = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = 21020,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_tipo               char(1) = null,
   @i_truta              tinyint = null,
   @i_toperacion         catalogo = null,
   @i_deudor             int = null,
   @i_cliente            int = null,
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
   @i_producto           catalogo = null,
   @i_monto              money = 0,
   @i_moneda             tinyint = 0,
   @i_periodo            catalogo = null,
   @i_num_periodos       smallint = 0,
   @i_destino            catalogo = null,
   @i_ciudad_destino     int = null,
   @i_cuenta_corriente   cuenta = null,
   @i_estado             char(1) = null,
   @i_clase              catalogo = null,
   @i_subtipo            char(1) = null,
   @i_margen_redescuento float = null,
   @i_concepto_credito   catalogo = null,
   @i_mercado_objetivo   catalogo = null,
   @i_tipo_productor     varchar(24) = null,
   @i_valor_proyecto     money = null,
   @i_fecha_inicio       datetime = null,
   @i_num_dias           smallint = null,
   @i_sindicado          char(1) = null,
   @i_asociativo         char(1) = null,
   @i_incentivo          char(1) = null,
   @i_elegible           char(1) = null,
   @i_forward            char(1) = null,
   @i_tramite_activa     int = null,
   @i_montop             money = null,
   @i_sujcred            catalogo = null,
   @i_fabrica            catalogo = null,
   @i_callcenter         catalogo = null,
   @i_apr_fabrica        catalogo = null,
   @i_monto_solicitado   money = 0,
   @i_tipo_plazo	     catalogo = null,
   @i_tipo_cuota_cat     catalogo = null,
   @i_plazo_tra          smallint = 0,
   @i_cuota_aproximada	 money = 0,
   @i_fuente_recurso	 varchar(10) = null,
   @i_tipo_credito	     char(1) = null,
   @i_migrado	         varchar(16) = null,
   @o_tramite            int = null out
 
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
   @w_etapa		 tinyint,
   @w_etapa_ant		 tinyint,
   @w_paso		 tinyint,
   @w_login_oficial	 login,
   @w_estacion_ofi	 smallint,
   @w_estacion_ant	 smallint,
   @w_prioridad	         tinyint,
   @w_paso_ofi		 tinyint,
   @w_estacion		 smallint,
   @w_programa           varchar(40),
   @w_tr_fabrica      catalogo,
   @w_tr_apr_fabrica  catalogo,
   @w_tr_callcenter   catalogo,
   @w_rowcount        int


select @w_sp_name = 'sp_crea_tr_redes'
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

/* obtengo la ruta de redescuento */
select @w_truta = pa_tinyint
from cobis..cl_parametro 
where pa_nemonico = 'TRUTRE'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

   if @w_rowcount = 0
   begin
      /** Error, no existe valor de Parametro **/
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2101084
      return 1    
   end


select @i_ciudad = of_ciudad
from   cobis..cl_oficina
where  of_oficina = @i_oficina_tr
set transaction isolation level read uncommitted

select @i_usuario_tr = isnull(@i_usuario_tr, @s_user)

if @i_estado = 'A'
begin
   select @i_fecha_apr = isnull(@i_fecha_apr, @s_date),
	  @i_usuario_apr = isnull(@i_usuario_apr, @s_user)
end



select @i_tipo = isnull(@i_tipo, 'O')

select @w_clase_cartera = '1'  -- Los creditos de redescuento son comerciales

-- INICIO DE TRANSACCION ***********
begin tran
   /* NUMERO SECUENCIAL DE TRAMITE */
   exec cobis..sp_cseqnos
   @t_debug = @t_debug,
   @t_file  = @t_file, 
   @t_from  = @w_sp_name,
   @i_tabla = 'cr_tramite',
   @o_siguiente = @w_tramite out

   if @w_tramite = NULL
   begin
      /* NO EXISTE TABLA EN TABLA DE SECUENCIALES*/
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2101007

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
   tr_aprob_gar, tr_cont_admisible,
   tr_margen_redescuento, tr_subtipo,
   tr_mercado_objetivo, tr_tipo_productor, tr_valor_proyecto, 
   tr_sindicado, tr_asociativo, tr_incentivo,
   tr_elegible, tr_forward, tr_montop,
   tr_monto_desembolsop, tr_sujcred, tr_fabrica, 
   tr_callcenter, tr_apr_fabrica,tr_monto_solicitado,
   tr_tipo_plazo, tr_tipo_cuota, tr_plazo,
   tr_cuota_aproximada,   tr_fuente_recurso,  tr_tipo_credito,
   tr_migrado)
   values (
   @w_tramite, @i_tipo, @i_oficina_tr,
   @i_usuario_tr, @w_today, @i_oficial,
   @i_sector, @i_ciudad, @i_estado,
   @i_nivel_ap, @i_fecha_apr, @i_usuario_apr,
   @w_truta, 0, null,
   null, null, null,
   null, null, @i_cliente,  
   null, @i_fecha_inicio, @i_num_dias,
   null, null, @w_numero_linea,
   @i_toperacion, @i_producto, @i_monto, 
   @i_moneda, @i_periodo, @i_num_periodos,
   @i_destino, @i_ciudad_destino, @i_cuenta_corriente,
   0, @i_clase,'N', 
   'N', @i_concepto_credito, 		 --emg Jun-19-01 cambio tipo de concepto y aprobacion de garantias
   '3', 'N',   		
   @i_margen_redescuento, @i_subtipo,
   @i_mercado_objetivo, @i_tipo_productor, @i_valor_proyecto, 
   @i_sindicado,  @i_asociativo, @i_incentivo,
   @i_elegible,   @i_forward, @i_montop,
   @i_montop,     @i_sujcred, @i_fabrica, 
   @i_callcenter, @i_apr_fabrica, @i_monto_solicitado,
   @i_tipo_plazo, @i_tipo_cuota_cat, @i_plazo_tra,
   @i_cuota_aproximada,   @i_fuente_recurso,  @i_tipo_credito,
   @i_migrado)

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
   aprob_gar, cont_admisible,sujcred, fabrica, 
   callcenter, apr_fabrica)		
   values(
   @s_ssn, @t_trn, 'N',
   @s_date, @s_user, @s_term,
   @s_ofi, 'cr_tramite', @s_lsrv,
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
   @i_clase, 'N', '3',	
   '3', 'N',@i_sujcred, @i_fabrica, 
   @i_callcenter, @i_apr_fabrica)		

   if @@error <> 0 
   begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103003

      return 2103003
   end    

   -- INSERTAR LOS REGISTROS EN LA TABLA CR_DEUDORES DESDE cr_Deudores
   insert into cr_deudores (
   de_tramite, de_cliente, de_rol,
   de_ced_ruc)
   select
   @w_tramite, de_cliente, de_rol, de_ced_ruc
   from cob_credito..cr_deudores
   where de_tramite = @i_tramite_activa

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

   /* obtener la etapa inicial de la ruta */
   select @w_etapa = pa_etapa,
          @w_paso  = pa_paso
   from   cr_pasos, cr_etapa
   where  pa_etapa = et_etapa
   and    pa_truta = @w_truta
   and    et_tipo = 'I'

   /* Enviar a la estacion de la etapa inicial de redescuento */
   select @w_programa = et_asignacion
   from   cr_etapa
   where  et_etapa = @w_etapa

   if @w_programa is null
   begin
      print 'Revisar Ruta Parametrizada de Redescuento'
      return 1
   end

   select @w_tr_fabrica      = tr_fabrica,
          @w_tr_apr_fabrica  = tr_apr_fabrica,
		@w_tr_callcenter   = tr_callcenter  
   from   cr_tramite 
   where  tr_tramite         = @i_tramite_activa

   update cr_tramite
   set    tr_fabrica      = @w_tr_fabrica,
          tr_apr_fabrica  = @w_tr_apr_fabrica,
		tr_callcenter   = @w_tr_callcenter  
   where  tr_tramite      = @w_tramite

    /* EJECUTO EL PROGRAMA ASOCIADO A LA ETAPA */
   exec @w_return = @w_programa
   @s_ssn     = @s_ssn,
   @s_user    = @s_user,
   @s_date    = @s_date,
   @i_tramite = @w_tramite,
   @i_etapa   = @w_etapa,
   @o_estacion = @w_estacion out

   if @w_return <> 0
      return @w_return

	select	@w_estacion_ant = isnull(rt_estacion_sus,rt_estacion)
	from	cr_ruta_tramite,
		cr_corresp_sib
	where	rt_tramite = @i_tramite_activa
	and	rt_etapa   = convert(int,codigo)
	and	tabla	   = 'T22'
        set transaction isolation level read uncommitted

        select  @w_etapa_ant 	= ee_etapa  
	from    cr_etapa_estacion 
	where   ee_etapa 	= @w_etapa
	and     ee_estacion= @w_estacion_ant
	and     ee_estado  = 'A'
	set transaction isolation level read uncommitted

   -- ENVIA A LA MISMA ESTACION QUE PASO ANTERIORMENTE
   if (@w_estacion_ant is not null and @w_etapa_ant is not null)
   begin
     select @w_estacion = @w_estacion_ant
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
	
        return 2101022
   end


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

                return 2101023
   end	

   /* Verificar si el oficial esta haciendo el ingreso de datos */

   if @i_usuario_tr = @w_login_oficial
   begin
      /*comprobar si la estacion del oficial está en la ruta*/
	select 	@w_paso_ofi = pa_paso
        from   	cr_pasos, cr_etapa_estacion, cr_estacion
	where	pa_truta = @w_truta
	and	pa_etapa = ee_etapa
        and     ee_estacion = es_estacion
	and     es_estacion = @w_estacion_ofi
        and     ee_estacion = @w_estacion_ofi		--ZR OPTIMIZACION 

	if @@rowcount = 0
	begin
	/* estacion de oficial no esta en ruta del trámite */
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 2101024

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
   @w_today, @w_prioridad,'C')	
   
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

   /* Insercion en cr_destino_tramite */
   insert into cr_destino_tramite (
   dt_tramite,   dt_cliente,   dt_destino,
   dt_valor,     dt_rol,       dt_unidad,
   dt_costo)
   select 
   @w_tramite,   dt_cliente,   dt_destino,
   dt_valor,     dt_rol,       dt_unidad,
   dt_costo
   from cr_destino_tramite
   where dt_tramite = @i_tramite_activa
      
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

commit tran

select @o_tramite = @w_tramite


GO

