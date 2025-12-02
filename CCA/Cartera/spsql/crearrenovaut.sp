/************************************************************************/
/*      Archivo:                crearrenovaut.sp                        */
/*      Stored procedure:       sp_crear_renovacion_automatica          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Maria Jose Taco                         */
/*      Fecha de escritura:     13/07/2017                              */
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
/*      Crea renovaciones automaticas para los creditos grupales        */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA          AUTOR             DESCRIPCION                    */
/*      13/Jul/2017    Ma. Jose Taco     Emision inicial                */
/*      18/Ago/2017    LGU               Proceso por OP y generacion    */
/*                                       de XML                         */
/*      28/Ago/2017   Ma. Jose Taco      Aumentar io_campo5 para guardar*/
/*                                       tramite anterior               */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crear_renovacion_automatica')
   drop proc sp_crear_renovacion_automatica
go
create proc sp_crear_renovacion_automatica
   @s_ssn               int          = null,
   @s_user              login        = null,
   @s_sesn              int          = null,
   @s_ofi               smallint     = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   @i_filas             int          = 0,
   @i_param1            varchar(255) = NULL, -- fecha proceso
   @i_param2            VARCHAR(20)  = NULL

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
   @w_promocion         char(1),
   @w_banca             varchar(10),
   @w_banco             varchar(24),
   @w_tipo              char(1),
   @w_ciudad_nacional   int,
   @w_fecha_habil       datetime,
   @w_fondos_propios    char(1),
   @w_origen_fondos     varchar(10),
   @w_operacion_out     int,
   @w_tramite_out       int,
   @w_inst_proc         int,
   @w_fecha_proceso     datetime,
   @w_msg               VARCHAR(100),
   @w_user              VARCHAR(20),
   @w_en_linea          CHAR(1),
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
   
   @w_to_direccion      TINYINT ,
   @w_to_tipo           CHAR(1) ,
   @w_to_tipo_empresa   VARCHAR (10),
   @w_oficinal_grupo    int,
   @w_promocion_aux     char(1)
   
	
--CARGAR VALORES INICIALES
select @w_sp_name   = 'sp_crear_renovacion_automatica',
       @w_nem_flujo = 'SOLCRGRSTD', -- LGU: FLUJO DEFINITIVO
       @w_en_linea  = 'N'

select @w_id_flujo      = pr_codigo_proceso,
       @w_flujo_version = pr_version_prd
  from cob_workflow..wf_proceso
 where pr_nemonico = @w_nem_flujo

--DIAS VENCIMIENTO OPERACION GRUPAL
select @w_dias_vto = pa_tinyint
  from cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'DVOG'

if @@rowcount = 0
begin
   SELECT @w_error = 70122 --NO EXISTE PARAMETRO PARA DIAS DE VENCIMIENTO EN LA OPERACION GRUPAL
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
(to_banco        VARCHAR (64)  ,
 to_oper         INT     null,
 to_error        CHAR(1) NULL,
 to_direccion    TINYINT NULL,
 to_tipo         CHAR(1) NULL,
 to_tipo_empresa VARCHAR (10) NULL )


create table #tmp1(
	tramite  int,
	cliente  int,
	monto    money null,
	montoa   money NULL,
	cuenta   VARCHAR(32) NULL ,
	participa VARCHAR(2) NULL 
)

select @w_fecha_proceso = convert(datetime, @i_param1,101)

select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

select
   @w_path_destino = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 7

select @w_mes         = substring(convert(varchar,@w_fecha_proceso, 101),1,2)
select @w_dia         = substring(convert(varchar,@w_fecha_proceso, 101),4,2)
select @w_anio        = substring(convert(varchar,@w_fecha_proceso, 101),7,4)

select @w_fecha_r = @w_mes + @w_dia + @w_anio

select @w_file_cl = 'renovar'

select @w_file_cl_in    = @w_path_destino + @w_fecha_r + '_' + @w_file_cl + '.txt'
select @w_file_cl_out   = @w_path_destino + @w_fecha_r + '_' + @w_file_cl + '.log'



select @w_bcp = 'select ''REPORTE DE RENOVACION DE PRESTAMOS '', '' '', '' '', '' ''' + 
                ' UNION ALL select ''FECHA'', ''ERROR'', ''PRESTAMO'', ''DESCRIPCION''' + 
                ' union all SELECT convert(varchar,er_fecha_proc,101),  convert(varchar,er_error),  er_cuenta, er_descripcion'+
                ' FROM cob_cartera..ca_errorlog WHERE er_fecha_proc = ' + '''' + convert(varchar,@w_fecha_proceso,101) + ''''  +
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

IF @i_param2 <> '00'
BEGIN
	PRINT ' BANCO: ' + @i_param2
	insert into #tmp_operaciones (to_banco)
	select 
		distinct 
		(a.tg_referencia_grupal)
	  from cob_credito..cr_tramite_grupal a,
	       cob_cartera..ca_operacion b,
	       cob_cartera..ca_operacion c
	 where b.op_cliente   = a.tg_grupo
	   and b.op_tramite   = a.tg_tramite
	   and b.op_banco     = @i_param2
	   and a.tg_nueva_op is null
	   and b.op_estado = 3
	   AND a.tg_operacion = c.op_operacion
	   AND c.op_estado NOT IN (0,99,3,6)
END 
ELSE
BEGIN        
	PRINT ' BANCO: TODOS'
	SET ROWCOUNT @i_filas
	insert into #tmp_operaciones (to_banco)
	select 
		distinct 
		(a.tg_referencia_grupal)
	  from cob_credito..cr_tramite_grupal a,
	       cob_cartera..ca_operacion b,
	       cob_cartera..ca_operacion c
	 where b.op_cliente   = a.tg_grupo
	   and b.op_tramite   = a.tg_tramite
	   and (b.op_fecha_fin   >= @w_fecha_ven AND
	        b.op_fecha_fin   < @w_fecha_habil)
	   and a.tg_nueva_op is null
	   and b.op_estado = 3
	   AND a.tg_operacion = c.op_operacion
	   AND c.op_estado NOT IN (0,99,3,6)
	SET ROWCOUNT 0
END

PRINT '/////////////////////////////////////////////////////////////////////////'
PRINT 'fecha ini ==> '  + convert(VARCHAR, @w_fecha_ven) +  ' fechas_fin  ==> ' + convert(VARCHAR, @w_fecha_habil)
PRINT '/////////////////////////////////////////////////////////////////////////'




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
        @w_operacion       = to_oper,
        @w_to_direccion    = to_direccion   ,
        @w_to_tipo         = to_tipo        ,
        @w_to_tipo_empresa = to_tipo_empresa
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
           @w_ciudad     = op_ciudad,
           @w_promocion  = op_promocion,
           @w_banca      = op_banca,
           @w_origen_fondos  = op_origen_fondos,
    	   @w_fondos_propios = op_fondos_propios
	from cob_cartera..ca_operacion
    where op_operacion  = @w_operacion

    --Oficial del grupo
    select @w_oficinal_grupo = gr_oficial
    from cobis..cl_grupo
    where gr_grupo = @w_cliente
        
    if @w_oficinal_grupo is not null
       select @w_oficial = @w_oficinal_grupo
            
	select @w_user = fu_login
	from   cobis..cc_oficial, cobis..cl_funcionario
	where  oc_funcionario = fu_funcionario
	and    oc_oficial     = @w_oficial 
	    
    print 'OP : '+ convert (varchar(15),@w_operacion) + ' BANCO : ' + @w_banco + ' USR: ' + @w_user + ' GR: ' + convert(VARCHAR, @w_cliente)

	IF EXISTS(select 1 from cob_workflow..wf_inst_proceso where io_campo_1 = @w_cliente and io_estado = 'EJE')
    BEGIN
		print' BATCH GRUPO TIENE TRAMITE EN EJECUCION   GR: ' + convert(VARCHAR, @w_cliente)
         select @w_error = 150001 -- NO EXISTE OFICIAL
         select @w_msg = ' GRUPO TIENE TRAMITE EN EJECUCION   GR: ' + convert(VARCHAR, @w_cliente)
         goto ERROR
    END 

    
    -- VALIDAR EXSITENCIA DE OFICIALES
    IF NOT EXISTS(select 1 from cobis..cc_oficial, cobis..cl_funcionario where  oc_funcionario = fu_funcionario
              and    oc_oficial     = @w_oficial   )
    BEGIN
         select @w_error = 150003 -- NO EXISTE OFICIAL
         select @w_msg = 'No existe oficial: ' + convert(VARCHAR, @w_oficial)
         goto ERROR
    END 
    -- VALIDAR CLIENTES ACTIVOS
    IF EXISTS( SELECT 1 FROM cobis..cl_ente_aux,cobis..cl_cliente_grupo 
       WHERE ea_ente = cg_ente AND ea_estado <> 'A'
       AND cg_grupo = @w_cliente)
    BEGIN
         select @w_error = 103145 -- NO ES CLIENTE ACTIVO
         select @w_msg = 'Algun integrante del grupo no es un Cliente. GR=' + convert(VARCHAR, @w_cliente)
         goto ERROR
    end

	-- VALIDAR ESTADO DEL GRUPO
	IF EXISTS( SELECT 1 FROM cobis..cl_grupo WHERE gr_grupo=@w_cliente AND gr_estado='C')
	BEGIN
         select @w_error = 103147 -- GRUPO CANCELADO
         select @w_msg = 'El Grupo tiene estado Cancelado. GR=' + convert(VARCHAR, @w_cliente)
         goto ERROR
	END


	-- VALIDAR ESTADO USURAIO EN WF
	IF NOT EXISTS (select 1 from cob_workflow..wf_usuario where us_login = @w_user and us_estado_usuario = 'ACT')
	BEGIN
         select @w_error = 3107592 -- USUARIO NO ACTIVO EN WORKFLOW
         select @w_msg = 'Usuario no activo. USER=' + convert(VARCHAR, @w_user)
         goto ERROR
	END
    
     	    
    select @w_tipo     = tr_tipo
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
    BEGIN TRY 
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
		    @i_campo_7     = 'S',              -- grupal S/N/null
		    @i_ruteo       = 'M',
		    @i_id_empresa  = 1,
		    @o_siguiente   = @w_inst_proc out, -- LGU obtener la instancia de proceso
		    @o_siguiente_alterno = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
		    @s_user        = @w_user,
		    @s_ofi         = @w_oficina,
		    @i_ofi_inicio  = @w_oficina,
		    @s_rol         = 3,
		    @s_ssn         = @s_ssn,
		    @s_srv         = 'srv',
		    @s_term        = 'consola',
		    @s_lsrv        = 'lsrv',
		    @s_date        = @w_fecha_proceso,
		    @s_sesn        = @s_sesn,
		    @s_org         = 'U'
	END TRY
	BEGIN CATCH     
        select @w_error = @@ERROR
        IF @w_return <> 0
	       select @w_error = @w_return
	    --if @w_return <> 0
	    begin
	       select @w_sp_name = 'cob_workflow..sp_inicia_proceso_wf'
	       select @w_msg = 'Error al ejecutar inicio proceso'
	       goto ERROR
	    end
    END CATCH
    
    --SACAR SECUENCIALES SESIONES
    exec @s_ssn = sp_gen_sec
    @i_operacion  = -1
    
    exec @s_sesn = sp_gen_sec
    @i_operacion  = -1
    
    --///////////////////////////////
    --CREA OPERACION Y TRAMITE
    --///////////////////////////////
    BEGIN TRY 
	    exec @w_return = cob_cartera..sp_crear_oper_sol_wf
			@i_en_linea   = @w_en_linea,
		    @i_tipo           = @w_tipo,
		    @i_tramite        = 0,
		    @i_cliente        = @w_cliente,
		    @i_nombre         = @w_nombre,
		    @i_codeudor       = 0,
		    @i_toperacion     = @w_toperacion,
		    @i_oficina        = @w_oficina,
		    @i_moneda         = @w_moneda,
		    @i_comentario     = 'Operacion renovada/creada desde Batch',
		    @i_oficial        = @w_oficial,
		    @i_fecha_ini      = @w_fecha_ven,
		    @i_monto          = @w_monto,
		    @i_monto_aprobado = @w_monto,
		    @i_destino        = @w_destino,
		    @i_ciudad         = @w_ciudad,
		    @i_formato_fecha  = 0,
		    @i_numero_reest   = 0,
		    @i_num_renovacion = 0,
		    @i_grupal         = 'S',
		    @i_banca          = @w_banca,
		    @i_promocion      = @w_promocion,
		    @i_acepta_ren     = 'S',
		    @i_emprendimiento = 'S',
		    @i_fondos_propios = @w_fondos_propios,
		    @i_origen_fondos  = @w_origen_fondos,
		    @t_trn            = 77100,
		    @i_automatica     = 'S',
		    @o_operacion      = @w_operacion_out out,
		    @o_tramite        = @w_tramite_out  out,
		    @s_user           = @w_user,
		    @s_ofi            = @w_oficina,
		    @s_rol            = 3,
		    @s_ssn            = @s_ssn,
		    @s_srv            = 'srv',
		    @s_term           = 'consola',
		    @s_lsrv           = 'lsrv',
		    @s_date           = @w_fecha_proceso,
		    @s_sesn           = @s_sesn,
		    @s_org            = 'U'
	END TRY
	BEGIN CATCH 
	   print 'Batch Ingreso Error'
       select @w_error   = @w_return,
              @w_sp_name = 'cob_cartera..sp_crear_oper_sol_wf'
       goto ERROR
    END CATCH 

    -- actualizar valores del padre
    UPDATE cob_cartera..ca_operacion SET
       op_direccion    =  @w_to_direccion    ,
       op_tipo         =  @w_to_tipo         ,
       op_tipo_empresa =  @w_to_tipo_empresa 
	WHERE op_operacion = @w_operacion_out    
	-- crear el tramite nuevo con los valores del tramite padre
	delete #tmp1

	insert into #tmp1
	SELECT 
        p.tg_tramite tramite,
        p.tg_cliente cliente,
    	p.tg_monto   monto,
	    p.tg_monto_aprobado montoa ,
	    p.tg_cuenta         cuenta ,
	    p.tg_participa_ciclo      participa
    from cob_credito..cr_tramite_grupal p 
	where p.tg_tramite  = @w_tramite
	
	update cob_credito..cr_tramite_grupal  set
    	tg_monto = monto,
		tg_monto_aprobado = montoa,
		tg_cuenta  = cuenta,
		tg_participa_ciclo = participa
    from #tmp1
	where tramite  = @w_tramite
	and tg_tramite = @w_tramite_out
	AND tg_cliente  = cliente

    if @@error <> 0
    begin
        select @w_error = 150001 -- ERROR EN ACTUALIZACION,
        select @w_msg = 'Error al actualizar TR renovado'
        goto ERROR
    end

	update cob_credito..cr_tramite_grupal set
    	tg_nueva_op = @w_operacion_out
    where tg_tramite  = @w_tramite
    if @@error <> 0
    begin
        select @w_error = 150001 -- ERROR EN ACTUALIZACION,
        select @w_msg = 'Error al actualizar OP a renovar'
        goto ERROR
    end

    -- LGU-ini. generar el XML
    --Tramite
    update cob_workflow..wf_inst_proceso 
    set io_campo_3 = @w_tramite_out,
	    io_campo_5 = @w_tramite
    where io_id_inst_proc = @w_inst_proc

    SELECT @w_inst_proc = io_id_inst_proc FROM cob_workflow..wf_inst_proceso WHERE io_campo_3 = @w_tramite_out
    if @@rowcount = 0
    begin
        select @w_error = 150002 -- ERROR EN INSERCION,
        select @w_msg = 'No existe informacion para esa instancia de proceso'
        goto ERROR
    end

	
	IF NOT EXISTS (SELECT 1 FROM cob_credito..cr_deudores WHERE de_tramite = @w_tramite_out) 
	BEGIN
		INSERT INTO cob_credito..cr_deudores
		SELECT @w_tramite_out, de_cliente, de_rol, de_ced_ruc, de_segvida, de_cobro_cen
		FROM cob_credito..cr_deudores 
		WHERE de_tramite = @w_tramite

	    if @@error <> 0
	    begin
	        select @w_error = 150002 -- ERROR EN ACTUALIZACION,
	        select @w_msg = 'Error al insertar OP a renovar'
	        goto ERROR
	    end
	END
	ELSE
	BEGIN
		UPDATE cob_credito..cr_deudores SET 
			de_cliente = @w_cliente, 
			de_rol     = 'G',
			de_ced_ruc = NULL , 
			de_segvida = NULL, 
			de_cobro_cen = 'N'
		WHERE de_tramite = @w_tramite_out
	    if @@error <> 0
	    begin
	        select @w_error = 150003 -- ERROR EN ACTUALIZACION,
	        select @w_msg = 'Error al actualizar OP a renovar'
	        goto ERROR
	    end
	END
	   
	--/////////////////////////////////
	--CREAR XML
	--/////////////////////////////////
	BEGIN TRY
	    exec @w_return = cob_credito..sp_grupal_xml
	    	@i_en_linea   = @w_en_linea,
	        @i_inst_proc  = @w_inst_proc,
	        @i_origen     = ' - RENOVACION'
	END TRY 
	BEGIN CATCH
        select @w_error = 150003 -- ERROR AL EJECUTAR SP DE XML,
        select @w_msg = 'Error al generar XML de OP a Renovar'
        goto ERROR
    END CATCH
    -- LGU-fin. generar el XML

    if @w_commit = 'S'
    begin
       commit tran  -- Fin atomicidad de la transaccion
       select @w_commit = 'N'
    end


	SELECT @w_msg = 'Terminado con Exito',
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
	print 'BATCH ERROR1  : ' + @w_banco + ' - ' + @w_msg + ' ERROR1  : ' + convert(VARCHAR,@w_error)

	IF EXISTS(select 1 from cob_workflow..wf_inst_proceso where io_campo_1 = @w_cliente and io_estado = 'EJE')
		print' 1.- BATCH GRUPO TIENE TRAMITE EN EJECUCION   GR: ' + convert(VARCHAR, @w_cliente)

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


      PRINT @w_bcp
      exec @w_error = xp_cmdshell @w_bcp



UPDATE cobis..ba_parametro SET pa_valor = '00'
WHERE pa_batch = 7080 AND pa_parametro = 2


RETURN 0

GO

