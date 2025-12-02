/************************************************************************/
/*      NOMBRE LOGICO:          provisioncca.sp                         */
/*      NOMBRE FISICO:          sp_provision_cca                        */
/*      BASE DE DATOS:          cob_cartera                             */
/*      PRODUCTO:               Cartera                                 */
/*      DISENADO POR:           Adriana Giler                           */
/*      FECHA DE ESCRITURA:     15-May-2019                             */
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
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                            PROPOSITO                                 */
/* Generación de provisión mensual de cartera                           */
/************************************************************************/
/*                       MODIFICACIONES                                 */
/*                                                                      */
/*  FECHA          AUTOR      RAZON                                     */
/* 10/Oct/19       JLCC       Se cambia la tabla de donde               */
/*                            se obtiene la informacion                 */
/*                            para generar el reporte                   */
/* 21/Oct/19       AMG        Se rediseña el sp                         */
/* 19/May/21       KDR        Se calcula calificacion de                */
/*                            operación                                 */
/* 03/Sep/21       GFP        Validacion para prestamos                 */
/*                            reestructurados                           */
/* 01/Jun/22       AMO        Correccion de proceso masivo              */
/* 17/May/23       KDR        S809836 Calculo prov. en base a           */
/*                            peor calif. de cliente                    */
/* 06/Jun/2023     MCO		  Cambio variable @w_calif_op               */
/*				     		  de char(1) a catalogo			            */
/* 31/Oct/2023     KDR        R218306 Correccion proceso calif          */
/* 08/Ene/2024     KDR        R221691 Nueva col. calif OP y calif cli   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_provision_cca')
   drop proc sp_provision_cca
go

create proc sp_provision_cca
(  
   @i_param1  datetime = null 
)
as declare
   @w_s_app                 varchar(40),
   @w_cmd                   varchar(5000),
   @w_destino               varchar(255),
   @w_mensaje               varchar(100),
   @w_path                  varchar(255),
   @w_errores               varchar(255),
   @w_comando               varchar(6000),
   @w_error                 int,
   @w_operacion             int,
   @w_oper_sgte             int,
   @w_fec_proceso           datetime,
   @w_fecha_sgte_mes        datetime,
   @w_procesa               char(1),
   @w_ffecha                int,
   @w_max_operacion         int,   
   @w_est_cancelado         tinyint,
   @w_est_suspenso          tinyint,
   @w_est_diferido          tinyint,
   @w_est_vigente           tinyint,
   @w_est_vencido           tinyint,
   @w_est_novigente         tinyint,
   @w_est_credito           tinyint,
   @w_ope_provisiona        int,
   @w_ope_provisiona_sgte   int,
   @w_respaldo_mes          int,
   @w_fborrar               datetime,
   @w_dias_ven              int,
   @w_sector                catalogo,
   @w_cap_base_vig          money,
   @w_cap_base_ven          money,
   @w_cap_base_prov         money,
   @w_porc_cap_prov         float,
   @w_int_base_vig          money,
   @w_int_base_ven          money,
   @w_int_base_prov         money,
   @w_porc_int_prov         float,   
   @w_valor_prov_cap        money,
   @w_valor_prov_int        money,
   @w_porcentaje_prov       float,
   @w_calif_op              catalogo,      -- KDR 19May2021 Para calificación del préstamo --> MCO 05/06/2023 Se cambio el tipo de dato de char(1) a catalogo
   @w_calif_cli             catalogo,
   @w_ciudad_nacional       int,
   @w_banco_prov            cuenta,
   @w_nombre                varchar(50),
   @w_sql_bcp               varchar(50),
   @w_num_dias_reestructuracion tinyint,	-- GFP validacion de operaciones restructuradas
   @w_fecha_reest           datetime
   
   
/* ESTADOS DE CARTERA */
exec @w_error =sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,--3
@o_est_suspenso   = @w_est_suspenso  out,--9
@o_est_diferido   = @w_est_diferido  out,--8
@o_est_vigente    = @w_est_vigente   out,--1
@o_est_vencido    = @w_est_vencido   out,--2
@o_est_novigente  = @w_est_novigente out,--0
@o_est_credito    = @w_est_credito   out --99

if @w_error <> 0 goto ERROR
   
--PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
   
/* OBTENER VALOR DE RESPALDO */
Select @w_respaldo_mes = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'RESPRO'
and   pa_producto = 'CCA'

--GFP PARAMETRO DE NUMERO DE DIAS PARA CAMBIAR LA CALIFICACION
select @w_num_dias_reestructuracion = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'NDCCAL'
and    pa_producto = 'CCA'
   
/* OBTENIENDO DATOS */
select @w_procesa = 'N'

-- OBTENER FECHA PROCESO                                        --  KDR 19May2021 Asignación fecha proceso desde param1.
if @i_param1 is not null and @i_param1 <> ''
begin
	select @w_fec_proceso = convert (Datetime, @i_param1)
end
else
begin
   select @w_fec_proceso = fp_fecha
   from cobis..ba_fecha_proceso
end

/* VALIDANDO QUE SEA UN FIN DE MES */
select @w_procesa = 'N'

select @w_fecha_sgte_mes = dateadd(dd, 1, @w_fec_proceso)

if datepart(mm, @w_fecha_sgte_mes) = datepart(mm, @w_fec_proceso)
begin
    exec @w_error = sp_dia_habil 
         @i_fecha  = @w_fecha_sgte_mes,
         @i_ciudad = @w_ciudad_nacional,
         @o_fecha  = @w_fecha_sgte_mes  out
     
    if @w_error <> 0 goto ERROR
end
 
if datepart(mm, @w_fecha_sgte_mes) <> datepart(mm, @w_fec_proceso)            
    select @w_procesa = 'S'

if @w_procesa = 'S'
begin
    -- nombre del archivo a generar 
    select @w_nombre = 'CCA_PROVISION_MENSUAL_'
    
    --Se limpian los registros en la fecha de proceso
    delete ca_provision_cartera
    where pc_fecha_proceso = @w_fec_proceso
    
    --Se obtiene la fecha en la que se elminará el respaldo
    select @w_respaldo_mes = (@w_respaldo_mes - 1)*(-1)
    select @w_fborrar = dateadd(mm, @w_respaldo_mes, @w_fec_proceso)
    select @w_fborrar = dateadd(dd, -1, @w_fborrar)
    
    --Eliminando respaldo de los meses según parámetro
    set rowcount 5000
	
    while 1=1
    begin
        delete ca_provision_cartera
        where pc_fecha_proceso <= @w_fborrar 
        
        if @@rowcount = 0
            break
    end
    set rowcount 0
    
    ---------------------------------------
    -- Creando Temporal para trabajo
    ---------------------------------------
    select *
    into ##tmp_provision
    from ca_provision_cartera
    where 2 = 1

    if @@error != 0
    begin
        SELECT @w_mensaje = 'Error Creando Temporal de Trabajo'
        goto ERROR
    end

    create index idx1 on ##tmp_provision (pc_operacion)
	create index idx2 on ##tmp_provision (pc_sector, pc_dias_dev)

    select @w_operacion = 0
 
    select @w_max_operacion = max(do_operacion)
    from cob_conta_super..sb_dato_operacion
    where do_estado_cartera not in (@w_est_novigente, @w_est_credito, @w_est_cancelado)
		and do_fecha = @w_fec_proceso
    
    set rowcount 5000
	
    while 1=1 
    begin  
        insert into ##tmp_provision(
            pc_fecha_proceso
            , pc_operacion
            , pc_banco
            , pc_fult_proceso
            , pc_cliente
            , pc_nom_cliente
            , pc_oficina
            , pc_toperacion
            , pc_estado
            , pc_fecha_ini
            , pc_fecha_fin
            , pc_monto
            , pc_plazo
            , pc_tplazo
            , pc_sector
            , pc_val_capital
            , pc_val_interes
            , pc_dias_dev
            , pc_cap_vigente
            , pc_int_vigente
            , pc_cap_vencido
            , pc_int_vencido
            , pc_tasa
            , pc_porc_cap_prov
            , pc_cap_base_prov
            , pc_porc_int_prov
            , pc_int_base_prov
            , pc_porcentaje_prov
            , pc_valor_prov_cap
            , pc_valor_prov_int
			, pc_calificacion
			, pc_calif_cliente)
        select do_fecha
                , do_operacion
                , do_banco
                , do_fecha_proceso
                , do_codigo_cliente
                , en_nomlar
                , do_oficina
                , do_tipo_operacion
                , do_estado_cartera
                , do_fecha_concesion
                , do_fecha_vencimiento
                , do_monto
                , do_num_cuotas
                , do_tplazo
                , do_tipo_cartera
                , isnull(do_saldo_cap_total, 0.0)
                , isnull((select sum(dr_cuota - dr_pagado)      -- pc_val_interes
                  from cob_conta_super..sb_dato_operacion_rubro 
                  where dr_banco = a.do_banco
                  and dr_concepto = 'INT'
                  and dr_estado != @w_est_cancelado
				  AND dr_fecha = @w_fec_proceso),0)              
                , isnull(do_dias_mora_365, 0)                   -- pc_dias_dev
                , isnull(do_saldo_cap, 0.0)                     -- pc_cap_vigente               
                , isnull(do_saldo_int, 0.0)                     -- pc_int_vigente                       
                , isnull(do_cap_vencido, 0.0)                   -- pc_cap_vencido           
                , isnull(do_inte_vencido, 0.0)                  -- pc_int_vencidos                      
                , isnull(do_tasa, 0.0)                          -- pc_tasa                                 
                , 0.0
                , 0.0
                , 0.0
                , 0.0
                , 0.0
                , 0.0
                , 0.0
				, ''
				, ''
        from cob_conta_super..sb_dato_operacion as a inner join cobis..cl_ente
            on en_ente = do_codigo_cliente
        where do_operacion > @w_operacion
			and do_estado_cartera not in (@w_est_novigente, @w_est_credito, @w_est_cancelado)
			and do_fecha = @w_fec_proceso
        order by do_operacion
        
        if @@error != 0
        begin
            SELECT @w_mensaje = 'Error obteniendo Datos para Generación de Provisiones'
            goto ERROR
        end

        select @w_oper_sgte = isnull(max(pc_operacion),0)
        from ##tmp_provision
		    
        -- AMO 20220601 SE SUPRIME COMPARACION @w_operacion = 0, NO PERMITIA PROCESAR TODAS LAS OPERACIONES, SOLO EL PRIMER BLOQUE
        --if @w_max_operacion = @w_operacion or @w_operacion = 0 or  @w_operacion = @w_oper_sgte
        if @w_max_operacion = @w_operacion or  @w_operacion = @w_oper_sgte
            break    
            
        select @w_operacion = @w_oper_sgte        
    end
	
	set rowcount 0

	-- Calificación por Operación de los préstamos según parametrización
    select pc_operacion    as 'pcc_operacion', 
	       pc_cliente      as 'pcc_cliente', 
		   pt_calificacion as 'pcc_calif_op', 
		   pt_calificacion as 'pcc_calif_cli'
    into ##tmp_prov_calif
    from ##tmp_provision, ca_provision_tca
    where pt_tipo_car = pc_sector
    and pc_dias_dev between pt_dias_desde and  pt_dias_hasta
	
    create index idx1 on ##tmp_prov_calif (pcc_cliente)
    create index idx2 on ##tmp_prov_calif (pcc_operacion, pcc_cliente, pcc_calif_cli)
	
    -- Calificación por Cliente de los préstamos según parametrización
    update ##tmp_prov_calif 
    set pcc_calif_cli = (select max(pcc_calif_op) 
                        from ##tmp_prov_calif t 
                        where t.pcc_cliente = m.pcc_cliente 
                        group by t.pcc_cliente)  
    from ##tmp_prov_calif m
    where m.pcc_cliente = pcc_cliente
	
    /* OBTENER INFORMACIÓN DE PROVISIONAMIENTO */
    Select @w_ope_provisiona = min(pc_operacion)
    from ##tmp_provision
	
	set rowcount 5000

    while @w_ope_provisiona is not null
    begin    
        select @w_cap_base_vig     = pc_val_capital, 
               @w_int_base_vig     = pc_val_interes,   -- KDR 19May2021 Se considera el campo pc_val_interés envés de pc_int_vigente
               @w_cap_base_ven     = pc_cap_vencido,
               @w_int_base_ven     = pc_int_vencido,
               @w_dias_ven         = pc_dias_dev,
			   @w_sector           = pc_sector,
               @w_porc_cap_prov    = pt_saldo_cap,
               @w_porc_int_prov    = pt_saldo_int,
               @w_porcentaje_prov  = pt_provision,
			   @w_calif_cli        = pt_calificacion,   -- KDR 19May2021 Obtiene calificación, según sector préstamo y rango de días
			   @w_calif_op         = pcc_calif_op, 
               @w_banco_prov       = pc_banco
        from ##tmp_provision, ca_provision_tca, ##tmp_prov_calif 
        where pc_operacion  = @w_ope_provisiona
          and pt_tipo_car   = pc_sector
		  and pc_operacion  = pcc_operacion
		  and pc_cliente    = pcc_cliente
		  and pcc_calif_cli = pt_calificacion
          -- and pc_dias_dev between pt_dias_desde and  pt_dias_hasta
		  
        if @@rowcount = 0
		begin
		
		   select @w_banco_prov = pc_banco,
		          @w_sector     = pc_sector,
				  @w_dias_ven   = pc_dias_dev
		   from ##tmp_provision
           where pc_operacion  = @w_ope_provisiona
		   
           select @w_error = 70153, -- ERROR: NO EXISTE INFORMACION DE PROVISIONES
                  @w_mensaje = 'OP: '         + convert(varchar(24), @w_banco_prov) + ' ' +
				               'Sector: '     + convert(varchar(10), @w_sector)     + ' ' +
				               'Días venc: '  + convert(varchar(10), @w_dias_ven)
				  
            exec cob_cartera..sp_errorlog 
            @i_fecha        = @w_fec_proceso,
            @i_error        = @w_error,
            @i_usuario      = 'usrbatch',
            @i_tran         = 26004,
			@i_cuenta       = @w_banco_prov,
            @i_descripcion  = @w_mensaje,
            @i_tran_name    = 'sp_provision_cca',
            @i_rollback     = 'N' 
			
			goto SIGUIENTE_OPERACION

		end
        
        if @w_dias_ven >= 0
        begin 
            select @w_cap_base_prov  = @w_cap_base_vig * (@w_porc_cap_prov /100), 
                   @w_int_base_prov  = @w_int_base_vig * (@w_porc_int_prov /100)                                    
        end
        else
        begin
            select @w_cap_base_prov = 0.0, 
                   @w_int_base_prov = 0.0,
                   @w_porc_cap_prov = 0.0,
                   @w_porc_int_prov = 0.0,
                   @w_porcentaje_prov = 0.0,            
                   @w_mensaje = 'Fecha de último proceso de la operación ' + @w_banco_prov + ' es mayor a la fecha de proceso'
        
                   
            exec cob_cartera..sp_errorlog 
            @i_fecha        = @w_fec_proceso,
            @i_error        = @w_error,
            @i_usuario      = 'usrbatch',
            @i_tran         = 26004,
			@i_cuenta       = @w_banco_prov,
            @i_descripcion  = @w_mensaje,
            @i_tran_name    = 'sp_provision_cca',
            @i_rollback     = 'N'       
        end
        
        select @w_valor_prov_cap = @w_cap_base_prov * (@w_porcentaje_prov / 100),
               @w_valor_prov_int = @w_int_base_prov * (@w_porcentaje_prov / 100)
        
        --ACTUALIZANDO DATOS                       
        update ##tmp_provision
        set pc_porc_cap_prov   = isnull(@w_porc_cap_prov, 0.0),     
            pc_cap_base_prov   = isnull(@w_cap_base_prov, 0.0),  
            pc_porc_int_prov   = isnull(@w_porc_int_prov, 0.0),  
            pc_int_base_prov   = isnull(@w_int_base_prov, 0.0),
            pc_porcentaje_prov = isnull(@w_porcentaje_prov, 0.0),    
            pc_valor_prov_cap  = isnull(@w_valor_prov_cap, 0.0), 
            pc_valor_prov_int  = isnull(@w_valor_prov_int, 0.0),
			pc_calificacion    = isnull(@w_calif_op, ''),
			pc_calif_cliente   = isnull(@w_calif_cli, '')
        from ##tmp_provision
        where pc_operacion = @w_ope_provisiona
          
        if @@error != 0
        begin
            SELECT @w_mensaje = 'Error Actualizando datos de Provisiones Generadas'
            goto ERROR
        end
		
		--GFP Obtención de fecha de restructuracion
		select @w_fecha_reest = op_fecha_reest
		from ca_operacion with (nolock)
		where  op_operacion = @w_ope_provisiona
		
		if @@error != 0
        begin
            SELECT @w_mensaje = 'Error, Obtencion de fecha de reestructuración'
            goto ERROR
        end
		
		--GFP Validación para operaciones reestructuradas
		if (@w_fecha_reest is not null)
		begin
			if (@w_num_dias_reestructuracion > DATEDIFF(dd, @w_fecha_reest, @w_fec_proceso) )
			begin
				GOTO SIGUIENTE_OPERACION
			end
		end
			    
	    -- ACTUALIZA CALIFICACIÓN EN TABLA ca_operacion     -- KDR 12May2021
	    UPDATE ca_operacion with (rowlock)
	    set    op_calificacion = @w_calif_op
		where  op_operacion = @w_ope_provisiona
		     
		if @@error != 0
	    begin
	       SELECT @w_mensaje = 'Error Actualizando datos de calificación en tablas involucradas'
	       goto ERROR
	    END
		   
		GOTO SIGUIENTE_OPERACION
        -- Fin actualización de calificación
		
		-- Refrescar variables
		select @w_cap_base_vig     = null,
		       @w_int_base_vig     = null,
		       @w_cap_base_ven     = null,
		       @w_int_base_ven     = null,
		       @w_dias_ven         = null,
			   @w_sector           = null,
		       @w_porc_cap_prov    = null,
		       @w_porc_int_prov    = null,
		       @w_porcentaje_prov  = null,
			   @w_calif_cli        = null,
			   @w_calif_op         = null,
		       @w_banco_prov       = null
		
        SIGUIENTE_OPERACION:
        select @w_ope_provisiona = min(pc_operacion)
        from ##tmp_provision
        where pc_operacion > @w_ope_provisiona
    end            

    set rowcount 0

    ---------------------------------------
    -- Insertar de Temporal a real
    ---------------------------------------
    insert ca_provision_cartera
    select *
    from ##tmp_provision
    order by pc_operacion

    if @@error != 0
    begin
        SELECT @w_mensaje = 'Error pasando datos generados de Temporales a Reales'
        goto ERROR
    end

    ----------------------------------------
    --	Generar Archivo Plano
    ----------------------------------------

    select @w_s_app = pa_char
    from cobis..cl_parametro
    where pa_producto = 'ADM'
    and   pa_nemonico = 'S_APP'

    select @w_path = pp_path_destino
    from cobis..ba_path_pro
    where pp_producto = 7
            
    select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..##tmp_provision out '

    select 	@w_destino = @w_path + @w_nombre +  replace(CONVERT(varchar(10), @w_fec_proceso,103),'/', '')+ '.txt',
            @w_errores = @w_path + @w_nombre +  replace(CONVERT(varchar(10), @w_fec_proceso,103),'/', '')+ '.err'

    select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -T -e ' + @w_errores + ' -t"|" ' + '-config ' + @w_s_app + 's_app.ini'

    PRINT ' CMD: ' + @w_comando 

    exec @w_error = xp_cmdshell @w_comando
    
    if @w_error <> 0 
    begin
       select
       @w_error = 724681,
       @w_mensaje = 'Error generando Archivo de Provisiones Mensuales'
       goto ERROR
    end
    
	if object_id('tempdb..##tmp_provision') is not null
       drop table ##tmp_provision
	   
    if object_id('tempdb..##tmp_prov_calif') is not null
	   drop table ##tmp_prov_calif
	   
end -- Procesa 

return 0

ERROR:

if object_id('tempdb..##tmp_provision') is not null
  drop table ##tmp_provision
	   
if object_id('tempdb..##tmp_prov_calif') is not null
   drop table ##tmp_prov_calif

exec cob_cartera..sp_errorlog 
	@i_fecha        = @w_fec_proceso,
	@i_error        = @w_error,
	@i_usuario      = 'usrbatch',
	@i_tran         = 26004,
	@i_descripcion  = @w_mensaje,
	@i_tran_name    = 'sp_provision_cca',
	@i_rollback     = 'S'
    
return @w_error

go
