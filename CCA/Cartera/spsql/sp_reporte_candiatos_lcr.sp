use cob_cartera
go
/*************************************************************************/
/*   ARCHIVO:         sp_reporte_candiatos_lcr.sp                        */
/*   NOMBRE LOGICO:   sp_reporte_candiatos_lcr                           */
/*   Base de datos:   cob_credito                                        */
/*   PRODUCTO:        Credito                                            */
/*   Fecha de escritura:   Enero 2018                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante legal.            */
/*************************************************************************/
/*                     PROPOSITO                                         */
/*  Permite insertar alertas de los clientes cada semana, si se estan en */
/*  Listas negras o Negativ File                                         */
/*************************************************************************/
/*                     MODIFICACIONES                                    */
/*   FECHA         AUTOR            RAZON                                */
/* 09/Ene/2018    Maria Jose Taco   Emision inicial                      */
/*************************************************************************/

if exists(select 1 from sysobjects where name = 'sp_reporte_candiatos_lcr')
    drop proc sp_reporte_candiatos_lcr
go
create proc sp_reporte_candiatos_lcr (
    @t_show_version     bit         =   0,
    @i_param1           datetime   =   null -- FECHA DE PROCESO
)as
declare
@w_sp_name          varchar(20),
@w_s_app            varchar(50),
@w_path             varchar(255),  
@w_msg              varchar(200),  
@w_return           int,
@w_dia              varchar(2),
@w_mes              varchar(2),
@w_anio             varchar(4),
@w_fecha_r          varchar(10),
@w_file_rpt         varchar(40),
@w_file_rpt_1       varchar(140),
@w_file_rpt_1_out   varchar(140),
@w_bcp              varchar(2000),
@w_ultimo_dia       int,
@w_cabecera         varchar(30),
@w_op_vigentes      int,
@w_transacciones    int,
@w_procesos         int,
@w_usuarios_app     int,
@w_fecha_proceso    datetime,
@w_id_alerta        int,
@w_ente_eje         int,
@w_result           varchar(2),
@w_cc               varchar(64),
@w_matriz           varchar(64),
@w_riesgo           varchar(64),
@w_dias_atraso      int,
@w_calif            varchar(64),
@w_error            int,
@w_values           varchar(255),
@w_variables        varchar(255),
@w_result_values    varchar(255),
@w_parent           int,
@w_fecha_inicio	  datetime,
@w_ciudad_nacional  int,
@w_dia_generar      int,
@w_fecha_final	  int,
@w_dia_restar 	  int,
@w_fecha_hasta	  datetime,
@w_rule_id                   int,
@w_acronym                   varchar(30)

declare @w_regla_LCRRMAX table (
   variable_1     varchar(255),   
   operator_1     varchar(255), 
   variable_2     varchar(255),   
   operator_2     varchar(255),
   variable_3     varchar(255),   
   operator_3     varchar(255), 
   result_1       varchar(255),
   UNIQUE NONCLUSTERED (variable_1, variable_2,variable_3)
)

IF OBJECT_ID('tempdb..#clientes_1') IS NOT NULL DROP TABLE #clientes_1
create table #clientes_1(
   codigo             int,
   nombre             varchar(64),
   primer_apellido    varchar(64),
   segundo_apellido   varchar(64),
   riesgo_ind_ext     char(1),
   riesgo_matriz      varchar(50),
   gerente            varchar(64),
   asesor             varchar(64)
)

create nonclustered index idx on #clientes_1 (codigo)

select @i_param1 = fp_fecha from cobis..ba_fecha_proceso
--select @w_sp_name = 'sp_reporte_candiatos_lcr'


/* FECHA PROCESO */
if(@i_param1 is null)
begin
	select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
end
else
begin
	select @w_fecha_proceso = @i_param1
end

select @w_ultimo_dia = datepart(weekday,@w_fecha_proceso)

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select @w_dia_generar = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'DECLCR'
and    pa_producto = 'CLI'


if (@w_ultimo_dia != @w_dia_generar)  -- validar el siguiente dia habil
begin
	select  @w_fecha_hasta  = dateadd(day,@w_dia_generar,  dateadd(day,-@w_ultimo_dia,@w_fecha_proceso))
	--select  'INICIO' = @w_fecha_hasta  

	while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_hasta) 
		select @w_fecha_hasta= dateadd(DAY,-1,@w_fecha_hasta)  
    --select @w_fecha_hasta as FechaFinal
end
else
begin
	select  @w_fecha_hasta  = @w_fecha_proceso
	while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_hasta) 
		select @w_fecha_hasta= dateadd(DAY,-1,@w_fecha_hasta)  

end
	
print '1er habil antes del viernes ' + convert(varchar,  @w_fecha_hasta) + '  ' +
      'FProceso ' + convert(varchar, @w_fecha_proceso)

if @w_fecha_hasta <>   @w_fecha_proceso
begin
	print ' NO ejecuta, es menor o mayor al viernes habil'
	Return 0
end
else
begin
	print ' SI ejecuta y le coloco como viernes'
	select  @w_fecha_hasta  = dateadd(day,@w_dia_generar,  dateadd(DAY,-@w_ultimo_dia,@w_fecha_proceso))
end 



-- -------------------------------------------------------------------------------
-- DIRECCION DEL ARCHIVO A GENERAR
-- -------------------------------------------------------------------------------
select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

--truncate table ca_reporte_control_tmp

select @w_path = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 7 -- CARTERA

select @w_mes         = substring(convert(varchar,@w_fecha_proceso, 101),1,2)
select @w_dia         = substring(convert(varchar,@w_fecha_proceso, 101),4,2)
select @w_anio        = substring(convert(varchar,@w_fecha_proceso, 101),7,4)

select @w_fecha_r = @w_anio + @w_mes + @w_dia

select @w_file_rpt = 'REPORTE_CANDIDATOS'
select @w_file_rpt_1     = @w_path + @w_file_rpt + '_' + @w_fecha_r + '.txt'
select @w_file_rpt_1_out = @w_path + @w_file_rpt + '_' + @w_fecha_r + '.err'

set @w_cabecera = 'REPORTE DE CANDIDATOS'

/* PARAMETROS */
select @w_dias_atraso = pa_int from cobis..cl_parametro where pa_nemonico = 'DRELCR'


--IF OBJECT_ID('tempdb..#clientes_1') IS NOT NULL DROP TABLE #clientes_1
IF OBJECT_ID('tempdb..#ca_det_ciclo') IS NOT NULL DROP TABLE #ca_det_ciclo
IF OBJECT_ID('tempdb..#ca_op_ciclo') IS NOT NULL DROP TABLE #ca_op_ciclo
--IF OBJECT_ID('tempdb..#regla_LCRRMAX') IS NOT NULL DROP TABLE #regla_LCRRMAX

select @w_acronym = 'LCRRMAX'
select @w_rule_id =  rl_id from cob_pac..bpl_rule where rl_acronym = @w_acronym
	
	
if @@rowcount > 0 begin		   
	
   insert into @w_regla_LCRRMAX
   select 
   cr1.cr_max_value as variable_1, 
   cr1.cr_operator  as operator_1,
   cr2.cr_max_value as variable_2,
   cr2.cr_operator  as operator_2,
   cr3.cr_max_value as variable_3,
   cr3.cr_operator  as operator_3,
   cr4.cr_max_value as result_1    
   from  cob_pac..bpl_condition_rule cr1
   inner join cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent 
   inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
   inner join cob_pac..bpl_condition_rule cr4 on cr3.cr_id = cr4.cr_parent
   where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_rule_id 
                   and rv_status = 'PRO')
   and cr1.cr_parent is null
   and cr4.cr_is_last_son = 'true'  	   
   
end

--Universo fuera de ListasNegras y NegativeFile
insert into #clientes_1
select ea_ente, 
	   en_nombre, 
	   p_p_apellido,
	   p_s_apellido,
	   ea_nivel_riesgo_cg,
	   ea_nivel_riesgo,
	   
	   (select top 1 fu_nombre from cobis..cl_oficina, cobis..cl_funcionario
	   	where of_oficina = fu_oficina
	   	and fu_oficina = (select top 1 op_oficina from cob_cartera..ca_operacion, cobis..cc_oficial
	   	where op_oficial = oc_oficial
	   	and op_cliente = en_ente
	   	order by op_operacion desc)
	   	and fu_cargo = (select pa_smallint from cobis..cl_parametro where pa_nemonico = 'CGEOFI')),
	   (select top 1 fu_nombre from cobis..cl_funcionario, cobis..cc_oficial 
	   	where fu_funcionario = oc_funcionario and oc_oficial = (select top 1 op_oficial from cob_cartera..ca_operacion
	   	                                                        where op_cliente = en_ente order by op_operacion desc )) 
from cobis..cl_ente, cobis..cl_ente_aux
where en_ente = ea_ente
and (ea_lista_negra = 'N' or ea_lista_negra is null)
and (ea_negative_file = 'N' or ea_negative_file is null)
order by ea_ente asc
--Eliminar clientes con creditos activos
delete #clientes_1
where codigo in (select io_campo_1 from cob_workflow..wf_inst_proceso
where io_campo_4 = 'REVOLVENTE'
and io_estado = 'EJE')

delete #clientes_1
where codigo in (select op_cliente from cob_cartera..ca_operacion
where op_estado not in (0,3,99)
and op_toperacion = 'REVOLVENTE')


--Elimina clientes con atraso en cuotas de los 2 ultimos ciclos
select dc_cliente 
into #ca_det_ciclo
from cob_cartera..ca_det_ciclo, cob_cartera..ca_dividendo
where dc_operacion  = di_operacion
and dc_operacion in (select top 2 op_operacion from cob_cartera..ca_operacion
					where op_cliente = dc_cliente
					and op_estado <> 6 -- Anulado
					order by op_operacion desc)
and datediff(dd,di_fecha_can ,di_fecha_ini) >= @w_dias_atraso
order by dc_ciclo_grupo desc

delete #clientes_1
where codigo in (select dc_cliente from #ca_det_ciclo)

--Elimina clientes con actividad denegada
delete #clientes_1
where codigo in (select nc_ente from cobis..cl_negocio_cliente 
					where nc_actividad_ec in ( select C.codigo from cobis..cl_catalogo C, cobis..cl_tabla T
						where C.tabla = T.codigo
						and T.tabla = 'cl_actividad_lcr' ))


/* Obtengo clientes con operaciones */
select dc_cliente
into #ca_op_ciclo 
from cob_cartera..ca_det_ciclo, #clientes_1
where dc_cliente = codigo

delete #clientes_1
where codigo not in (select dc_cliente from #ca_op_ciclo)

--select * from #clientes_1


select @w_ente_eje = 0
while 1=1
begin
	PRINT '1..'+ (CONVERT( VARCHAR(24), GETDATE(), 121))
	select TOP 1
	@w_ente_eje   = codigo,
	@w_calif      = isnull(riesgo_ind_ext, 'A1'),
	@w_matriz     = isnull(riesgo_matriz, 'C')
	from #clientes_1
	where codigo  > @w_ente_eje
	order by codigo ASC
	if @@rowcount = 0
		break

		
	select @w_cc = 'CC'
	
    select @w_result = result_1
    from @w_regla_LCRRMAX
    where ((operator_1 = '=' and variable_1 = @w_cc) 
       or (operator_1 = 'cualquier valor' AND variable_1 = ''))
    and variable_2 = @w_matriz
    and ((operator_1 = '=' and variable_3 = @w_calif) 
    or (operator_3 = 'cualquier valor' AND variable_3 = ''))
	
	if(@w_result = 'NO')
	begin
		delete #clientes_1
		where codigo = @w_ente_eje
	end
end

/* Inserta clientes candidatos en tabla para generacion de archivo */
truncate table cobis..cl_cliente_candidato_tmp
insert into cobis..cl_cliente_candidato_tmp
select * from #clientes_1

SELECT @w_bcp = @w_s_app + 's_app bcp -auto -login ' + 'cobis..cl_cliente_candidato_tmp' + ' out ' + @w_file_rpt_1 + ' -c -C ACP -t"" -b 5000 -e' + @w_file_rpt_1_out + ' -config ' + @w_s_app + 's_app.ini'
PRINT '===> ' + @w_bcp 


--Ejecucion para Generar Archivo Datos
exec @w_return = xp_cmdshell @w_bcp

if @w_return <> 0 
begin
  select @w_return = 70146,
  @w_msg = 'Fallo el BCP'
  goto ERROR_PROCESO
end

return 0

ERROR_PROCESO:
     select @w_msg = isnull(@w_msg, 'ERROR GENRAL DEL PROCESO')
	exec cobis..sp_errorlog 
	@i_fecha        = @w_fecha_proceso,
	@i_error        = @w_error,
	@i_usuario      = 'usrbatch',
	@i_tran         = 1,
	@i_descripcion  = @w_msg,
	@i_tran_name    =null,
	@i_rollback     ='S'
	return @w_error


go