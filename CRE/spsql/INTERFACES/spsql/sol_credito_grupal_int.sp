/************************************************************************/
/*  Archivo:                sol_credito_grupal_int.sp                   */
/*  Stored procedure:       sp_sol_credito_grupal_int                   */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Crédito                                     */
/*  Disenado por:           Patricio Mora                               */
/*  Fecha de Documentacion: 02/Sep/2021                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Verificar los datos enviados mediante el servicio REST de creación  */
/*  o actualización de crédito grupal GFI.                              */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*     FECHA        AUTOR            RAZON                              */
/*  02/09/2021      pmora        Emision Inicial                        */
/*  10/09/2021      wlo          Ajuste ORI-S526469-GFI                 */
/*  17/03/2022      pmoreno      Emplear usuario entregado en parametros*/
/*                               para crear tramite                     */
/* 22/03/2021      pmoreno       Cambio de canal a 3 para servicio rest */
/* 23/03/2022      wlopez        Mejora, control de creacion            */
/*                               de instancias de proceso               */
/* 23/03/2022      pmoreno       Se envia w_tipo a sp_crear_oper_sol_wf */
/* 04/04/2022      pquezada      Cambio en envío de codigo oficina      */
/* 26/04/2022      dmorales       Se omite campos en operacion U  		*/
/* 27/04/2022      dmorales      Se valida actualizacion contr_estado	*/
/* 10/11/2022      dmorales     R196611-Se comenta el exec sp_borrar_tmp*/
/* 11/11/2022      dmorales     R196611 Se añade validacion para update */
/*                                desde DFA                             */
/************************************************************************/
use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_sol_credito_grupal_int')
    drop proc sp_sol_credito_grupal_int
go

create procedure sp_sol_credito_grupal_int
(
       @s_ssn                    int            = null,
       @s_user                   varchar(30)    = null,
       @s_sesn                   int            = null,
       @s_term                   varchar(30)    = null,
       @s_date                   datetime       = null,
       @s_srv                    varchar(30)    = null,
       @s_lsrv                   varchar(30)    = null,
       @s_rol                    smallint       = null,
       @s_ofi                    smallint       = null,
       @s_org_err                char(1)        = null,
       @s_error                  int            = null,
       @s_sev                    tinyint        = null,
       @s_msg                    descripcion    = null,
       @s_org                    char(1)        = null,
       @s_culture                varchar(10)    = null,
       @t_rty                    char(1)        = null,
       @t_trn                    int            = null,
       @t_debug                  char(1)        = 'N',
       @t_file                   varchar(14)    = null,
       @t_from                   varchar(30)    = null,
       @i_canal                  tinyint        = 3,      -- Canal: 0=Frontend  1=Batch   2=Workflow  3=Servicio Rest
       @i_tipo                   catalogo       = 'ORI',
       @i_sector                 catalogo       = null,
       @i_fecha_ini              datetime       = null,
       @i_banco                  cuenta         = null,
       @i_operacionca            int            = null,
       @i_operacion              char(1),
       @i_ciudad                 int,
       @i_ciudad_destino         int,
       @i_cliente                int,
       @i_codeudor               int,
       @i_comentario             varchar(255),
       @i_destino                catalogo,
       @i_formato_fecha          int,
       @i_grupal                 char(1),
       @i_moneda                 tinyint,
       @i_monto                  money,
       @i_monto_aprobado         money,
       @i_origen_fondos          catalogo       = null,
       @i_nombre                 descripcion,
       @i_num_renovacion         int,
       @i_numero_reest           int,
       @i_oficial                smallint,
       @i_oficina                smallint,
       @i_periodo_cap            int,
       @i_periodo_int            int,
       @i_plazo                  int,
       @i_toperacion             catalogo,
       @i_tplazo                 catalogo,
       @i_tramite                int,
       @o_inst_proceso           int            = null out,
       @o_siguiente_alterno      varchar(255)   = null out,
       @o_tramite                int            = null out
)
as
declare
       @w_error                  int,
       @w_return                 int,
       @w_sp_name                varchar(100),
       @w_sp_name1               varchar(100),
       @w_codigo_proceso         smallint,
       @w_process_id             varchar(30),
       @w_secuencial             numeric,
       @w_inst_proceso           int,
       @w_siguiente_alterno      varchar(255),
       @w_tipo                   char(1),
       @w_tramite                int,
       @w_usuario_tr             login,
	   @w_estado				 char(1),
       @w_param_regularizar      varchar(30),
       @w_actividad              varchar(30)

select @w_usuario_tr = fu_login 
from cobis..cl_funcionario 
where fu_funcionario = (select oc_funcionario from cobis..cc_oficial where oc_oficial = @i_oficial)

select @i_canal = 3 -- PMO, asigna canal de servicio rest

select @w_sp_name      = 'sp_sol_credito_grupal_int',
       @w_inst_proceso = 0,
       @w_error        = 0,
       @w_return       = 0,
       @w_tramite      = 0

select @w_codigo_proceso = pr_codigo_proceso 
from   cob_workflow..wf_proceso 
where  pr_nemonico = @i_tipo
if @@rowcount = 0
begin
   select @w_return = 2110175 --Debe enviar un tipo de Flujo
   goto ERROR
end

select @w_secuencial = max(bph_codsequential) 
from   cob_fpm..fp_bankingproductshistory 
where  bph_product_id = @i_toperacion 
if @@rowcount = 0
begin   
   select @w_return = 2110176 --Debe enviar el tipo de Operacion
   goto ERROR
end

select @w_process_id = pph_process_id  
from   cob_fpm..fp_processbyproducthistory 
where  bph_codsequentialfk = @w_secuencial 
and    pph_flow_id         = @w_codigo_proceso
if @@rowcount = 0
begin
   select @w_return = 2110177 --No se encontro un proceso para el tipo de flujo y operacion enviada
   goto ERROR
end

if @w_process_id in('ORI','REN','RES','REF')
begin
   if @w_process_id = 'ORI'
   begin
      select @w_tipo = 'O'
   end
   
   if @w_process_id = 'REN'
   begin
      select @w_tipo = 'R'
   end
   
   if @w_process_id = 'RES'
   begin
      select @w_tipo = 'E'
   end
   
   if @w_process_id = 'REF'
   begin
      select @w_tipo = 'F'
   end
end
else
begin
   select @w_error = 2110177 --No se encontro un proceso para el tipo de flujo y operacion enviada
   goto ERROR
end
 
--Validaciones
exec @w_return = cob_interface..sp_val_credito_grupal_int
     @i_canal             = @i_canal,
     @i_tipo              = @w_tipo,
     @i_sector            = @i_sector,
     @i_fecha_ini         = @i_fecha_ini,
     @i_ciudad            = @i_ciudad,
     @i_ciudad_destino    = @i_ciudad_destino,
     @i_cliente           = @i_cliente,
     @i_codeudor          = @i_codeudor,
     @i_comentario        = @i_comentario,
     @i_destino           = @i_destino,
     @i_formato_fecha     = @i_formato_fecha,
     @i_grupal            = @i_grupal,
     @i_moneda            = @i_moneda,
     @i_monto             = @i_monto,
     @i_monto_aprobado    = @i_monto_aprobado,
     @i_origen_fondos     = @i_origen_fondos,
     @i_nombre            = @i_nombre,
     @i_num_renovacion    = @i_num_renovacion,
     @i_numero_reest      = @i_numero_reest,
     @i_oficial           = @i_oficial,
     @i_oficina           = @i_oficina,
     @i_periodo_cap       = @i_periodo_cap,
     @i_periodo_int       = @i_periodo_int,
     @i_plazo             = @i_plazo,
     @i_toperacion        = @i_toperacion,
     @i_tplazo            = @i_tplazo,
     @i_tramite           = @i_tramite

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   select @w_return  = @w_error
   goto ERROR
end


select @i_fecha_ini = cast(@i_fecha_ini as date) --DMO SE OMITE HORA ENVIADA

if (@w_error = 0 and @i_operacion = 'I')
begin

   exec @w_return = cob_cartera..sp_crear_oper_sol_wf
        @s_ssn            = @s_ssn,
        @s_user           = @w_usuario_tr, --@s_user, PMO
        @s_sesn           = @s_sesn,
        @s_term           = @s_term,
        @s_date           = @s_date,
        @s_srv            = @s_srv,
        @s_lsrv           = @s_lsrv,
        @s_rol            = @s_rol,
        @s_ofi            = @i_oficina, --PQU oficina del trámite @s_ofi,
        @i_ciudad         = @i_ciudad,
        @i_ciudad_destino = @i_ciudad_destino,
        @i_cliente        = @i_cliente,
        @i_codeudor       = @i_codeudor,
        @i_comentario     = @i_comentario,
        @i_destino        = @i_destino,
        @i_fecha_ini      = @i_fecha_ini,
        @i_formato_fecha  = @i_formato_fecha,
        @i_grupal         = @i_grupal,
        @i_moneda         = @i_moneda,
        @i_monto          = @i_monto,
        @i_monto_aprobado = @i_monto_aprobado,
        @i_no_acepta      = @i_origen_fondos,
        @i_nombre         = @i_nombre,
        @i_num_renovacion = @i_num_renovacion,
        @i_numero_reest   = @i_numero_reest,
        @i_oficial        = @i_oficial,
        @i_oficina        = @i_oficina,
        @i_periodo_cap    = @i_periodo_cap,
        @i_periodo_int    = @i_periodo_int,
        @i_plazo          = @i_plazo,
        @i_sector         = @i_sector,
        @i_tipo           = @w_tipo,
        @i_toperacion     = @i_toperacion,
        @i_tplazo         = @i_tplazo,
        @i_tramite        = @i_tramite,
        @o_tramite        = @w_tramite out
   
   select @w_error = @w_return
   if @w_return != 0 or @@error != 0
   begin
      select @w_return  = @w_error
      goto ERROR
   end

   select @w_sp_name1     = 'cob_workflow..sp_inicia_proceso_wf'

   exec @w_return            = @w_sp_name1--cob_workflow..sp_inicia_proceso_wf
        @s_ssn               = @s_ssn,
        @s_user              = @w_usuario_tr, --@s_user, PMO
        @s_sesn              = @s_sesn,
        @s_term              = @s_term,
        @s_date              = @s_date,
        @s_srv               = @s_srv,
        @s_lsrv              = @s_lsrv,
        @s_rol               = @s_rol,
        @s_ofi               = @i_oficina, --PQU oficina del trámite @s_ofi,
        @s_culture           = @s_culture,
        @i_login             = @w_usuario_tr, --@s_user, PMO
        @i_id_proceso        = @w_codigo_proceso,
        @i_campo_1           = @i_cliente,
        @i_canal             = @i_canal,
        @i_campo_3           = 0,
        @i_id_empresa        = 1,
        @i_campo_4           = @i_toperacion,
        @i_campo_5           = 0,
        @i_campo_6           = 0.0,
        @i_campo_7           = 'S',
        @i_tipo_cliente      = 'S',
        @t_trn               = 73506,
        @o_siguiente         = @w_inst_proceso      out,
        @o_siguiente_alterno = @w_siguiente_alterno out

   select @w_error = @w_return
   if @w_return != 0 or @@error != 0
   begin
      select @w_return  = @w_error
      goto ERROR
   end

   if @w_inst_proceso > 0
   begin
      select @w_sp_name1 = 'cob_workflow..sp_m_inst_proceso_wf'

      exec @w_return       = @w_sp_name1--cob_workflow..sp_m_inst_proceso_wf
           @s_ssn          = @s_ssn,
           @s_user         = @w_usuario_tr, --@s_user, PMO
           @s_sesn         = @s_sesn,
           @s_term         = @s_term,
           @s_date         = @s_date,
           @s_srv          = @s_srv,
           @s_lsrv         = @s_lsrv,
           @s_rol          = @s_rol,
           @s_ofi          = @i_oficina, --PQU oficina del trámite @s_ofi,
           @i_login        = @w_usuario_tr, --@s_user, PMO
           @i_id_inst_proc = @w_inst_proceso,
           @i_campo_1      = @i_cliente,
           @i_campo_3      = @w_tramite,
           @i_id_empresa   = 1,
           @i_campo_4      = @i_toperacion,
           @i_operacion    = 'U',
           @i_campo_5      = 0,
           @i_campo_6      = 0.0,
           @t_trn          = 73506

      select @w_error = @w_return
      if @w_return != 0 or @@error != 0
      begin
         select @w_return  = @w_error
         goto ERROR
      end
   end

   if @w_error = 0
   begin
      --Mostrar instancia de proceso corto, instancia de proceso largo, numero de tramite
      select @o_inst_proceso      = @w_inst_proceso,
             @o_siguiente_alterno = @w_siguiente_alterno,
             @o_tramite           = @w_tramite
   end

end

if (@w_error = 0 and @i_operacion = 'U')
begin
   
   if @i_tramite = 0 or @i_tramite is null
   begin 
		select
		@w_return = 2110179
      ---@w_msg    = 'Debe enviar numero de tramite para Actualizar.'
 
		goto ERROR
   end
   
   select @w_estado = tr_estado from cob_credito..cr_tramite where tr_tramite = @i_tramite
   
    -- DMO Un trámite aprobado no puede ser actualizado 
   if( @w_estado  <> 'N')
   begin
		select
		@w_return = 2110395
		---@w_msg    = 'Un trámite aprobado no puede ser actualizado.'
       goto ERROR
   end 
   
   
   --DMO SE VALIDA QUE SE ENCUENRE EN LA ETAPA CORRRECTA DE REGULARIZACION
   select @w_param_regularizar =  pa_char from cobis..cl_parametro with(nolock)
                                  where pa_nemonico = 'PMODFA'
								  
								  
	select @w_actividad =  ia_nombre_act from 
    cob_workflow..wf_inst_proceso with(nolock)
    inner join cob_workflow..wf_inst_actividad with(nolock)  on io_id_inst_proc = ia_id_inst_proc
    inner join cob_workflow..wf_actividad  with(nolock) on ia_codigo_act = ac_codigo_actividad
    where io_campo_3 = @i_tramite
    and ia_estado in ('ACT', 'INA')	  
    
	if( @w_param_regularizar is null or  isnull(@w_param_regularizar, '') != isnull(@w_actividad, ''))
	begin
	    select @w_return = 2110402
		---@w_msg    = 'Solo es posible modificar desde actividad de regularización'
       goto ERROR
	end
	
	
   select 	@i_banco 	= op_banco,
			@i_cliente	= op_cliente
     from cob_cartera..ca_operacion
    where op_tramite = @i_tramite
       
   ---PASAR A TEMPORALES CON LOS ULTIMOS DATOS
   exec @w_return          = cob_cartera..sp_pasotmp
        @s_term            = @s_term,
        @s_user            = @w_usuario_tr, --@s_user, PMO
        @i_banco           = @i_banco,
        @i_operacionca     = 'S',
        @i_dividendo       = 'S',
        @i_amortizacion    = 'S',
        @i_cuota_adicional = 'S',
        @i_rubro_op        = 'S',
        @i_nomina          = 'S'
       
   select @w_error = @w_return
   if @w_return != 0 or @@error != 0
   begin
      select @w_return  = @w_error
      goto ERROR
   end

   exec @w_return = cob_cartera..sp_modificar_oper_sol_wf
        @s_ssn            = @s_ssn,
        @s_user           = @w_usuario_tr, --@s_user, PMO
        @s_sesn           = @s_sesn,
        @s_term           = @s_term,
        @s_date           = @s_date,
        @s_srv            = @s_srv,
        @s_lsrv           = @s_lsrv,
        @s_ofi            = @i_oficina, --PQU oficina del trámite @s_ofi,
        @i_banco          = @i_banco,
        @i_ciudad         = @i_ciudad,
        @i_ciudad_destino = @i_ciudad_destino,
        @i_cliente        = @i_cliente, 
        @i_comentario     = @i_comentario,
        @i_destino        = @i_destino,
        @i_formato_fecha  = @i_formato_fecha,
        @i_grupal         = @i_grupal,
        @i_moneda         = @i_moneda,
        @i_monto          = @i_monto,
        @i_monto_aprobado = @i_monto_aprobado,
        @i_no_acepta      = @i_origen_fondos,
        @i_nombre         = @i_nombre,
        @i_num_renovacion = @i_num_renovacion,
        @i_oficial        = @i_oficial,
        @i_oficina        = @i_oficina,
        @i_operacionca    = @i_operacionca,
        @i_periodo_cap    = @i_periodo_cap,
        @i_periodo_int    = @i_periodo_int,
        @i_plazo          = @i_plazo,
        --@i_sector       = @i_sector, DMO SECTOR NO SE PUEDE ACTUALIZAR
        @i_tipo           = @w_tipo,
        --@i_toperacion     = @i_toperacion, DMO TOPERACION NO SE PUEDE ACTUALIZAR
        @i_tplazo         = @i_tplazo,
        @i_tramite        = @i_tramite

   select @w_error = @w_return
   if @w_return != 0 or @@error != 0
   begin
      select @w_return  = @w_error
      goto ERROR
   end
   
   --DMO ACTUALIZA OPERACIONES HIJAS
   exec @w_return = cob_credito..sp_actualiza_op_cre
        @s_user                 = @s_user,
        @s_date                 = @s_date,
        @s_ofi                  = @s_ofi,
        @s_term                 = @s_term,
		@i_operacion            = 'G',
		@i_banco                = @i_banco
		
     select @w_error = @w_return
   if @w_return != 0 or @@error != 0
   begin
      select @w_return  = @w_error
      goto ERROR
   end
   
      -- BORRAR TEMPORALES
   exec @w_return = cob_cartera..sp_borrar_tmp 
        @i_banco  = @i_banco,
        @s_user   = @w_usuario_tr, --@s_user, PMO
        @s_term   = @s_term
       
   select @w_error = @w_return
   if @w_return != 0 or @@error != 0
   begin
      select @w_return  = @w_error
      goto ERROR
   end

end

return @w_return

ERROR:
    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = @w_return
    return @w_return
go
