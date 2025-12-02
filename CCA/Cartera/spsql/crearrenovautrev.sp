/************************************************************************/
/*      Archivo:                crearrenovautrev.sp                     */
/*      Stored procedure:       sp_crear_renovacion_automatica_rev      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Paul Ortiz Vera                         */
/*      Fecha de escritura:     28/Ene/2019                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCORP"                                                     */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Crea renovaciones automaticas para los creditos Revolventes     */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA          AUTOR             DESCRIPCION                    */
/*      28/Ene/2019    P. Ortiz Vera     Emision inicial                */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crear_renovacion_automatica_rev')
   drop proc sp_crear_renovacion_automatica_rev
go
create proc sp_crear_renovacion_automatica_rev
   @s_ssn               int          = null,
   @s_user              login        = null,
   @s_sesn              int          = null,
   @s_ofi               smallint     = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   @i_filas             int          = 0,
   @i_param1            varchar(255) = null, -- fecha proceso
   @i_param2            varchar(20)  = null

as
declare
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_dias_vto          tinyint,
   @w_fecha_vto         datetime,
   @w_nem_flujo         varchar(10),
   @w_id_flujo          smallint,
   @w_flujo_version     smallint,
   @w_operacion         int,
   @w_nombre            varchar(64),
   @w_fecha_ven         datetime,
   @w_monto             money,
   @w_tramite           int,
   @w_cliente           int,
   @w_toperacion        varchar(10),
   @w_oficina           int,
   @w_moneda            tinyint,
   @w_oficial           smallint,
   @w_destino           varchar(10),
   @w_ciudad            int,
   @w_banco             varchar(24),
   @w_tipo              char(1),
   @w_ciudad_nacional   int,
   @w_fecha_habil       datetime,
   @w_tramite_out       int,
   @w_inst_proc         int,
   @w_fecha_proceso     datetime,
   @w_msg               varchar(100),
   @w_user              varchar(20),
   @w_en_linea          char(1),
   @w_commit            char(1),

   @w_s_app             varchar(40),
   @w_fecha_r           varchar(10),
   @w_mes               varchar(2),
   @w_dia               varchar(2),
   @w_anio              varchar(4),
   @w_bcp               varchar(2000),
   @w_path_destino      varchar(200),
   @w_file_cl           varchar(40),
   @w_file_cl_in        varchar(140),
   @w_file_cl_out       varchar(140),
   
   @w_oficinal_cliente  int,
   @w_subtipo           char(1),
   @w_plazo_ant         catalogo,
   @w_ofi_lcr           smallint
   
	
--CARGAR VALORES INICIALES
select @w_sp_name   = 'sp_crear_renovacion_automatica_rev',
       @w_nem_flujo = 'CREINREV', -- POV: FLUJO DEFINITIVO
       @w_en_linea  = 'N'

select @w_id_flujo      = pr_codigo_proceso,
       @w_flujo_version = pr_version_prd
  from cob_workflow..wf_proceso
 where pr_nemonico = @w_nem_flujo

--DIAS VENCIMIENTO OPERACION REVOLVENTE
select @w_dias_vto = pa_tinyint from cobis..cl_parametro with (nolock) where pa_producto = 'CCA' and pa_nemonico = 'DVOR'
--Oficina Defecto Pantalla de Autorizar Promocion LCR
select @w_ofi_lcr = pa_smallint from cobis..cl_parametro with (nolock) where pa_producto = 'CRE' and pa_nemonico = 'OFILCR'

if @@rowcount = 0
begin
   select @w_error = 70199 --NO EXISTE PARAMETRO PARA DIAS DE VENCIMIENTO EN LA OPERACION REVOLVENTE
   goto ERROR
end

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @@rowcount = 0 begin
   select @w_error = 101024
   goto ERROR
end

-- CREACION DE TABLAS TEMPORALES
create table #tmp_operaciones
(to_banco        varchar (64)  ,
 to_oper         INT     null,
 to_error        CHAR(1) null,
 to_direccion    TINYINT null,
 to_tipo         CHAR(1) null,
 to_tipo_empresa varchar (10) null )


create table #tmp1(
	tramite  int,
	cliente  int,
	monto    money null,
	montoa   money null,
	cuenta   varchar(32) null ,
	participa varchar(2) null 
)

if(@i_param1 is not null)
begin
	select @w_fecha_proceso = convert(datetime, @i_param1,101)
end
else
begin
	select @w_fecha_proceso = convert(datetime, fp_fecha,101) from cobis..ba_fecha_proceso
end


select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

select @w_path_destino = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 7

select @w_dia         = substring(convert(varchar,@w_fecha_proceso, 101),4,2)
select @w_mes         = substring(convert(varchar,@w_fecha_proceso, 101),1,2)
select @w_anio        = substring(convert(varchar,@w_fecha_proceso, 101),7,4)

select @w_fecha_r = @w_mes + @w_dia + @w_anio

select @w_file_cl = 'renovar_lcr'

select @w_file_cl_in    = @w_path_destino + @w_fecha_r + '_' + @w_file_cl + '.txt'
select @w_file_cl_out   = @w_path_destino + @w_fecha_r + '_' + @w_file_cl + '.log'



select @w_bcp = 'select ''REPORTE DE RENOVACION DE PRESTAMOS '', '' '', '' '', '' ''' + 
                ' UNION ALL select ''FECHA'', ''ERROR'', ''PRESTAMO'', ''DESCRIPCION''' + 
                ' union all select convert(varchar,er_fecha_proc,101),  convert(varchar,er_error),  er_cuenta, er_descripcion'+
                ' from cob_cartera..ca_errorlog where er_fecha_proc = ' + '''' + convert(varchar,@w_fecha_proceso,101) + ''''  +
                ' and er_usuario = ''renobat'' and er_tran = 7777  '
select @w_bcp = 'bcp "' + @w_bcp + '" queryout '

select @w_bcp = @w_bcp + @w_file_cl_in + ' -b5000 -c' + @w_s_app + 's_app.ini -T -e' + @w_file_cl_out   


select @w_fecha_ven   = dateadd(dd,@w_dias_vto,@w_fecha_proceso)
select @w_fecha_habil = dateadd(dd,1,@w_fecha_ven)
exec @w_return = sp_dia_habil
   @i_fecha  = @w_fecha_habil,
   @i_ciudad = @w_ciudad_nacional,
   @o_fecha  = @w_fecha_habil out

if @w_return <> 0
   goto ERROR

if @i_param2 <> '00'
begin
	print ' BANCO: ' + @i_param2
	insert into #tmp_operaciones (to_banco)
	select distinct	(c.op_banco)
	from cob_credito..cr_tramite a,
	   cob_cartera..ca_operacion c,
	   cob_workflow..wf_inst_proceso d
	where c.op_cliente   = a.tr_cliente
	and c.op_tramite   = a.tr_tramite
	and c.op_banco     = @i_param2
	and c.op_estado not in (2,4)
	and d.io_campo_3 = tr_tramite
	and d.io_campo_4 = 'REVOLVENTE'
end 
else
begin        
	print ' BANCO: TODOS'
	set rowcount @i_filas
	insert into #tmp_operaciones (to_banco)
	select distinct (c.op_banco)
	from cob_credito..cr_tramite a,
	   cob_cartera..ca_operacion c,
	   cob_workflow..wf_inst_proceso d
	where c.op_cliente   = a.tr_cliente
	and c.op_tramite   = a.tr_tramite
	and (c.op_fecha_fin   >= @w_fecha_ven and
	    c.op_fecha_fin   < @w_fecha_habil)
	and c.op_estado not in (2,4)
	and d.io_campo_3 = tr_tramite
	and d.io_campo_4 = 'REVOLVENTE'
	   
	set rowcount 0
end

print '/////////////////////////////////////////////////////////////////////////'
print 'fecha ini ==> '  + convert(varchar, @w_fecha_ven) +  ' fechas_fin  ==> ' + convert(varchar, @w_fecha_habil)
print '/////////////////////////////////////////////////////////////////////////'




update #tmp_operaciones
   set to_oper         = op_operacion,
       to_error        = 'N',
       to_direccion    = op_direccion, 
       to_tipo         = op_tipo,
       to_tipo_empresa = op_tipo_empresa
  from cob_cartera..ca_operacion
 where to_banco= op_banco

select @w_operacion = 0
while (1=1)
begin
	select @w_error = 0
    select @w_msg = ''
    
    select top 1 
        @w_banco           = to_banco, 
        @w_operacion       = to_oper
      from #tmp_operaciones
    where to_oper > @w_operacion
    order by to_oper asc
    
    if (@@rowcount =0)        BREAK
    
    select @w_nombre     = op_nombre,
           @w_banco      = op_banco,
           @w_fecha_ven  = op_fecha_fin,
           @w_monto      = op_monto,
           @w_tramite    = op_tramite,
           @w_cliente    = op_cliente,
           @w_toperacion = op_toperacion,
           @w_oficina    = op_oficina,
           @w_moneda     = op_moneda,
           @w_oficial    = op_oficial,
           @w_destino    = op_destino,
           @w_ciudad     = op_ciudad
	from cob_cartera..ca_operacion
    where op_operacion  = @w_operacion
	
	
	
    --Oficial/Tipo del Cliente
    select @w_oficinal_cliente = en_oficial,
    	   @w_subtipo          = en_subtipo
    from cobis..cl_ente
    where en_ente = @w_cliente
        
    if @w_oficinal_cliente is not null
       select @w_oficial = @w_oficinal_cliente
            
	select @w_user = fu_login
	from   cobis..cc_oficial, cobis..cl_funcionario
	where  oc_funcionario = fu_funcionario
	and    oc_oficial     = @w_oficial 
	
    print 'OP : '+ convert (varchar(15),@w_operacion) + ' BANCO : ' + @w_banco + ' USR: ' + @w_user + ' GR: ' + convert(varchar, @w_cliente)

	if exists(select 1 from cob_workflow..wf_inst_proceso where io_campo_1 = @w_cliente and io_estado = 'EJE' and io_campo_4 = 'REVOLVENTE')
    begin
		print' BATCH CLIENTE REVOLVENTE TIENE TRAMITE EN EJECUCION   GR: ' + convert(varchar, @w_cliente)
         select @w_error = 150001 -- NO EXISTE OFICIAL
         select @w_msg = ' CLIENTE REVOLVENTE TIENE TRAMITE EN EJECUCION   GR: ' + convert(varchar, @w_cliente)
         goto ERROR
    end 

    
    -- VALIDAR EXSITENCIA DE OFICIALES
    if not exists(select 1 from cobis..cc_oficial, cobis..cl_funcionario where  oc_funcionario = fu_funcionario
              and    oc_oficial     = @w_oficial   )
    begin
         select @w_error = 150003 -- NO EXISTE OFICIAL
         select @w_msg = 'No existe oficial: ' + convert(varchar, @w_oficial)
         goto ERROR
    end 
    -- VALIDAR CLIENTE ACTIVO
    if exists( select 1 from cobis..cl_ente_aux where ea_ente = @w_cliente and ea_estado <> 'A')
    begin
         select @w_error = 103145 -- NO ES CLIENTE ACTIVO
         select @w_msg = 'El Cliente no esta activo. ID=' + convert(varchar, @w_cliente)
         goto ERROR
    end
	
	-- VALIDAR ESTADO USURAIO EN WF
	if not exists (select 1 from cob_workflow..wf_usuario where us_login = @w_user and us_estado_usuario = 'ACT')
	begin
         select @w_error = 3107592 -- USUARIO NO ACTIVO EN WORKFLOW
         select @w_msg = 'Usuario no activo. USER=' + convert(varchar, @w_user)
         goto ERROR
	end
    
    
    select @w_tipo     = tr_tipo,
    	   @w_plazo_ant= tr_periodicidad_lcr
    from cob_credito..cr_tramite
    where tr_tramite =  @w_tramite
    
    --SACAR SECUENCIALES SESIONES
    exec @s_ssn = sp_gen_sec
         @i_operacion = -1
    
    exec @s_sesn = sp_gen_sec
         @i_operacion = -1
    
     -- Atomicidad en la transaccion
     if @@trancount = 0
     begin
        select @w_commit = 'S'
        begin tran
     end
    
    --///////////////////////////////
    --INICIA PROCESO WORKFLOW
    --///////////////////////////////
    begin try 
	    exec @w_return = cob_workflow..sp_inicia_proceso_wf
		    @t_trn         = 73506,
		    @i_login       = @w_user,
		    @i_id_proceso  = @w_id_flujo,      --id dep flujo
		    @i_version     = @w_flujo_version, -- version
		    @i_campo_1     = @w_cliente,       -- cliente
		    @i_campo_3     = 0,
		    @i_campo_4     = @w_toperacion,    -- tipo de flujo
		    @i_campo_5     = 0,
		    @i_campo_6     = 0.00,
		    @i_campo_7     = @w_subtipo,              -- GRUPAL, PERSONA NATURAL, PERSONA JURIDICA
		    @i_ruteo       = 'M',
		    @i_id_empresa  = 1,
		    @o_siguiente   = @w_inst_proc out, -- LGU obtener la instancia de proceso
		    @o_siguiente_alterno = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
		    @s_user        = @w_user,
		    @s_ofi         = @w_oficina,
		    @i_ofi_inicio  = @w_ofi_lcr,
		    @s_rol         = 3,
		    @s_ssn         = @s_ssn,
		    @s_srv         = 'srv',
		    @s_term        = 'consola',
		    @s_lsrv        = 'lsrv',
		    @s_date        = @w_fecha_proceso,
		    @s_sesn        = @s_sesn,
		    @s_org         = 'U'
	end try
	begin catch     
        select @w_error = @@ERROR
        IF @w_return <> 0
	       select @w_error = @w_return
	    --if @w_return <> 0
	    begin
	       select @w_sp_name = 'cob_workflow..sp_inicia_proceso_wf'
	       select @w_msg = 'Error al ejecutar inicio proceso'
	       goto ERROR
	    end
    end catch
    
    --SACAR SECUENCIALES SESIONES
    exec @s_ssn = sp_gen_sec
    @i_operacion  = -1
    
    exec @s_sesn = sp_gen_sec
    @i_operacion  = -1
    
    --///////////////////////////////
    --CREA TRAMITE
    --///////////////////////////////
    begin try 
	    print 'Antes de crear tramite'
	    
	    print 'INICIA PRINTS'
	    Print '@w_tipo ' + convert(varchar,@w_tipo)
		Print '@w_oficina ' + convert(varchar,@w_oficina)
		Print '@w_fecha_ven ' + convert(varchar,@w_fecha_ven)
		Print '@w_oficial ' + convert(varchar,@w_oficial)
		Print '@w_ciudad ' + convert(varchar,@w_ciudad)
		Print '@w_toperacion ' + convert(varchar,@w_toperacion)
		Print '@w_monto ' + convert(varchar,@w_monto)
		Print '@w_moneda ' + convert(varchar,@w_moneda)
		Print '@w_destino ' + convert(varchar,@w_destino)
		Print '@w_ciudad ' + convert(varchar,@w_ciudad)
		Print '@w_cliente ' + convert(varchar,@w_cliente)
		Print '@w_plazo_ant ' + convert(varchar,@w_plazo_ant)
		Print '@w_user ' + convert(varchar,@w_user)
		Print '@s_ssn ' + convert(varchar,@s_ssn)
		Print '@w_fecha_proceso ' + convert(varchar,@w_fecha_proceso)
		Print '@s_sesn ' + convert(varchar,@s_sesn)
	    print 'FINALIZA PRINTS'
	    
	    exec @w_return = cob_credito..sp_tramite_cca 
	    	@i_tipo				= @w_tipo,
			@i_oficina_tr		= @w_oficina,
			@i_fecha_crea		= @w_fecha_ven,
			@i_oficial			= @w_oficial,
			@i_sector			= 'S',
			@i_ciudad			= @w_ciudad,
			@i_toperacion		= @w_toperacion,
			@i_producto			= @w_toperacion,
			@i_monto			= @w_monto,
			@i_moneda			= @w_moneda,
			@i_destino			= @w_destino,
			@i_ciudad_destino	= @w_ciudad,
			@i_cliente			= @w_cliente,
			@i_tplazo_lcr		= @w_plazo_ant,
			@i_operacion		= 'I',
			@o_tramite			= @w_tramite_out out,
			@s_user				= @w_user,
			@s_term				= 'consola',
			@s_ofi				= @w_oficina,
			@s_ssn				= @s_ssn,
			@s_lsrv				= 'lsrv',
			@s_date				= @w_fecha_proceso
	end try
	begin catch 
		select @w_error = @@ERROR
		print 'El return: ' + convert(varchar,@w_return)
		print 'El error: ' + convert(varchar,@w_error)
		if @w_return <> 0
		   select @w_error = @w_return
		--if @w_return <> 0
		begin
		   print 'Batch Ingreso Error'
	       select @w_error   = @w_return,
	              @w_sp_name = 'cob_credito..sp_tramite_cca'
	       goto ERROR
       end
    end catch 

    -- POV-ini. generar el XML
    --Tramite
    update cob_workflow..wf_inst_proceso 
    set io_campo_3 = @w_tramite_out,
	    io_campo_5 = @w_tramite
    where io_id_inst_proc = @w_inst_proc

    select @w_inst_proc = io_id_inst_proc from cob_workflow..wf_inst_proceso where io_campo_3 = @w_tramite_out
    if @@rowcount = 0
    begin
        select @w_error = 150002 -- ERROR EN INSERCION,
        select @w_msg = 'No existe informacion para esa instancia de proceso'
        goto ERROR
    end

	
	if not exists (select 1 from cob_credito..cr_deudores where de_tramite = @w_tramite_out) 
	begin
		insert into cob_credito..cr_deudores
		select @w_tramite_out, de_cliente, de_rol, de_ced_ruc, de_segvida, de_cobro_cen
		from cob_credito..cr_deudores 
		where de_tramite = @w_tramite

	    if @@error <> 0
	    begin
	        select @w_error = 150002 -- ERROR EN ACTUALIZACION,
	        select @w_msg = 'Error al insertar OP a renovar'
	        goto ERROR
	    end
	end
	else
	begin
		update cob_credito..cr_deudores set 
			de_cliente = @w_cliente, 
			de_rol     = 'G',
			de_ced_ruc = null , 
			de_segvida = null, 
			de_cobro_cen = 'N'
		where de_tramite = @w_tramite_out
	    if @@error <> 0
	    begin
	        select @w_error = 150003 -- ERROR EN ACTUALIZACION,
	        select @w_msg = 'Error al actualizar OP a renovar'
	        goto ERROR
	    end
	end
	   
	--/////////////////////////////////
	--CREAR XML
	--/////////////////////////////////
	/*begin try
	    exec @w_return = cob_credito..sp_grupal_xml
	    	@i_en_linea   = @w_en_linea,
	        @i_inst_proc  = @w_inst_proc,
	        @i_origen     = ' - RENOVACION'
	end try 
	begin catch
        select @w_error = 150003 -- ERROR AL EJECUTAR SP DE XML,
        select @w_msg = 'Error al generar XML de OP a Renovar'
        goto ERROR
    end catch
    -- POV-fin. generar el XML*/
	
	--SACAR SECUENCIALES SESIONES
    exec @s_ssn = sp_gen_sec
         @i_operacion = -1
    
    exec @s_sesn = sp_gen_sec
         @i_operacion = -1
    
	
	/* Rutear actividad */
	exec @w_error = cob_cartera..sp_ruteo_actividad_wf
	@s_ssn     		   =  @s_ssn, 
	@s_user            =  @w_user,
	@s_sesn            =  @s_sesn,
	@s_term            =  'consola',
	@s_date            =  @w_fecha_proceso,
	@s_srv             =  'srv',
	@s_lsrv            =  'lsrv',
	@s_ofi             =  @w_oficina,
	@i_tramite     	   =  @w_tramite_out,
	@i_param_etapa     =  'ETINGR',
	@i_pa_producto     =  'CRE'
	
	if ((@@error <> 0) or (@w_error <> 0))
	begin
		--select @w_error = 150003 -- ERROR EN ACTUALIZACION,
        select @w_msg = 'ERROR NO FUE POSIBLE RUTEAR LA ACTIVIDAD!'
        goto ERROR
	end
	
	
    if @w_commit = 'S'
    begin
       commit tran  -- Fin atomicidad de la transaccion
       select @w_commit = 'N'
    end


	select @w_msg = 'Terminado con Exito',
	       @w_error = 0
    exec sp_errorlog
         @i_fecha       = @w_fecha_proceso,
         @i_error       = @w_error,
         @i_descripcion = @w_msg,
         @i_usuario     = 'renobat',
         @i_tran        = 7777,
         @i_tran_name   = @w_sp_name,
         @i_cuenta      = @w_banco,
         @i_rollback    = 'N'

    goto SIGUIENTE

ERROR:
    if @w_commit = 'S'
    begin
        rollback tran
        select @w_commit = 'N'
    end
	print 'BATCH ERROR1  : ' + @w_banco + ' - ' + @w_msg + ' ERROR1  : ' + convert(varchar,@w_error)

	if exists(select 1 from cob_workflow..wf_inst_proceso where io_campo_1 = @w_cliente and io_estado = 'EJE' and io_campo_4 = 'REVOLVENTE')
		print' 1.- BATCH CLIENTE REVOLVENTE TIENE TRAMITE EN EJECUCION   GR: ' + convert(varchar, @w_cliente)

    exec sp_errorlog
         @i_fecha       = @w_fecha_proceso,
         @i_error       = @w_error,
         @i_descripcion = @w_msg,
         @i_usuario     = 'renobat',
         @i_tran        = 7777,
         @i_tran_name   = @w_sp_name,
         @i_cuenta      = @w_banco,
         @i_rollback    = 'S'

    while @@trancount > 0 rollback tran
    select @w_commit = 'N'

SIGUIENTE:
end  -- while de operaciones


      print @w_bcp
      exec @w_error = xp_cmdshell @w_bcp


--ACTUALIZAR CON EL BATCH QUE SE CREA
update cobis..ba_parametro set pa_valor = '00'
where pa_batch = 7080 and pa_parametro = 2


RETURN 0

GO

