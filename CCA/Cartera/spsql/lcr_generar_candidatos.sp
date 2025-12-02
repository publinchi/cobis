

/*************************************************************************/
/*   ARCHIVO:         lcr_generar_candidatos.sp                          */
/*   NOMBRE LOGICO:   sp_lcr_generar_candidatos                           */
/*   Base de datos:   cob_cartera                                         */
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


use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_lcr_generar_candidatos')
    drop proc sp_lcr_generar_candidatos
go
create proc sp_lcr_generar_candidatos (
    @i_param1           datetime   =   null ,
	@i_forzar           char(1)    = 'N'-- FECHA DE PROCESO
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
@w_cabecera         varchar(5000),
@w_op_vigentes      int,
@w_transacciones    int,
@w_procesos         int,
@w_usuarios_app     int,
@w_fecha_proceso    datetime,
@w_id_alerta        int,
@w_ente             int,
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
@w_acronym                   varchar(30),
@w_cargo_gerente   int ,
@w_fecha_corte  datetime ,
@w_fecha_corrida_ant datetime , 
@w_destino2    varchar(5000),
@w_columna  varchar(5000),
@w_col_id  int ,
@w_comando varchar(5000),
@w_nom_cabecera varchar(5000),
@w_nom_columnas varchar(5000),
@w_cont_columnas INT, 
@w_destino     VARCHAR(5000),
@w_errores     VARCHAR(5000),
@w_sql         VARCHAR(5000), 
@w_comilla     char(1) 



create table  #lcr_riesgo_max  (
variable_1     varchar(255),   
operator_1     varchar(255), 
variable_2     varchar(255),   
operator_2     varchar(255),
variable_3     varchar(255),   
operator_3     varchar(255), 
result_1       varchar(255)
)

declare @resultadobcp table (linea varchar(max))

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select @w_dia_generar = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'DECLCR'
and    pa_producto = 'CLI'


select @w_cargo_gerente = pa_smallint
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CGEOFI'
and    pa_producto = 'CCA'

if @@rowcount = 0 select @w_cargo_gerente = 1 

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


/* FECHA PROCESO */
if(@i_param1 is null)
begin
	select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
end
else
begin
	select @w_fecha_proceso = @i_param1
end

select @w_fecha_corte = @w_fecha_proceso


if @i_forzar = 'N' begin 
   
   select @w_fecha_corte = dateadd(dd, -1, @w_fecha_proceso)
    
   while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_corte) 
      select @w_fecha_corte= dateadd(dd,-1,@w_fecha_corte)  
   
   if datepart(ww, @w_fecha_corte) =  datepart(ww, @w_fecha_proceso) return 0 
	
end 

select @w_fecha_corrida_ant = max (cc_fecha_ing) from ca_lcr_candidatos

select @w_fecha_corrida_ant = isnull(@w_fecha_corrida_ant , '01/01/1900') 

select 
mca_fecha                = convert(varchar,do_fecha,111),
mca_banco                = do_banco,
mca_operacion            = do_operacion,
mca_fecha_desembolso     = do_fecha_concesion,
mca_grupo                = do_grupo,
mca_oficina              = do_oficina,
mca_oficial_id           = do_oficial,
mca_cliente              = do_codigo_cliente,
mca_ciclo                = convert(varchar(3),isnull(do_numero_ciclos,1)),
mca_edad_mora            = do_dias_mora_365,
mca_atraso_max_ant       = convert(int,0)         ,
mca_atraso_max_act       = do_atraso_grupal       ,
mca_toperacion           = do_tipo_operacion
into #maestro_cartera
from cob_conta_super..sb_dato_operacion
where do_fecha      = @w_fecha_corte
and   do_aplicativo = 7
and  do_fecha_concesion > @w_fecha_corrida_ant   
and   do_estado_cartera in (1,3)

delete #maestro_cartera 
from   ca_lcr_candidatos 
where  mca_cliente = cc_cliente 

--Elimina clientes con actividad denegada
delete #maestro_cartera 
from cobis..cl_negocio_cliente
where mca_cliente  = nc_ente 
and   nc_actividad_ec in (select C.codigo from cobis..cl_catalogo C, cobis..cl_tabla T
						where  C.tabla = T.codigo
						and    T.tabla = 'cl_actividad_lcr' )
						

--CALCULO DE MAXIMO DE DIAS DE ATRASO CICLO ANTERIOR 
select 
grupo         = mca_grupo,
ciclo         = mca_ciclo -1
into #grupos_ciclo
from #maestro_cartera
where mca_ciclo >= 2

select 
ogrupo       =  do_grupo,
dias_atraso  =  max(do_atraso_grupal),
ociclo       =  do_numero_ciclos
into #atraso_anterior
from cob_conta_super..sb_dato_operacion,#grupos_ciclo
where grupo = do_grupo
and   ciclo  = do_numero_ciclos
group by do_grupo,do_numero_ciclos

update #maestro_cartera set 
mca_atraso_max_ant = dias_atraso 
from #atraso_anterior
where mca_grupo = ogrupo 
and   mca_ciclo = ociclo +1



select 
cliente           =  mca_cliente, 
operacion         =  max(mca_operacion),  
cont_lcr          =  sum(case when mca_toperacion = 'REVOLVENTE' then 1 else 0 end ),
dias_mora         =  max(mca_edad_mora),
atraso_ant        =  max(mca_atraso_max_ant),
atraso_act        =  max(mca_atraso_max_act)       
into #datos_clientes
from #maestro_cartera
group by mca_cliente
having max(mca_edad_mora)   <2 
and  sum(case when mca_toperacion = 'REVOLVENTE' then 1 else 0 end ) = 0 
and max(mca_atraso_max_ant)  <2
and max(mca_atraso_max_act)  <2



select 
operacion          = mca_operacion,
fecha_liq          = mca_fecha_desembolso,
grupo              = mca_grupo,
nom_grupo          = convert(varchar(120),null),
oficina            = mca_oficina,
cliente            = mca_cliente,
nombre             = convert(varchar(255),null),
gerente            = convert(varchar(24),null),
asesor_id          = mca_oficial_id,
asesor             = convert(varchar(24),null),
riesgo_ind_ext     = convert(char(1),null),
riesgo_matriz      = convert(varchar(50),null),
dias_m             =  dias_mora,
atraso_an          =  atraso_ant,
atraso_ac          =  atraso_act
into #clientes_1
from #maestro_cartera , #datos_clientes 
where operacion  = mca_operacion


update #clientes_1 set 
nom_grupo = gr_nombre 
from cobis..cl_grupo 
where grupo = gr_grupo


update #clientes_1 set 
nombre =    isnull(p_p_apellido, ' ')+' ' +isnull(p_s_apellido, ' ')+' ' +isnull(en_nombre, ' ')
from cobis..cl_ente 
where cliente  = en_ente 
															
update #clientes_1 set 
gerente = fu_login 
from cobis..cl_oficina, cobis..cl_funcionario
where of_oficina = fu_oficina
and   fu_oficina = oficina
and   fu_cargo   = @w_cargo_gerente

update #clientes_1 set 
asesor = fu_login 
from cobis..cc_oficial, cobis..cl_funcionario
where oc_funcionario   = fu_funcionario 
and   oc_oficial       = asesor_id 

update #clientes_1 set 
riesgo_ind_ext =  isnull(ea_nivel_riesgo_cg,'A'),
riesgo_matriz  =  isnull(ea_nivel_riesgo,'A')
from cobis..cl_ente_aux
where cliente  =  ea_ente 


--MANEJO DE LA REGLA 


select @w_rule_id =  rl_id from cob_pac..bpl_rule where rl_acronym = 'LCRRMAX'
		
if @@rowcount > 0 begin		   
	
   insert into #lcr_riesgo_max
   select 
   variable_1= cr1.cr_max_value , 
   operator_1= cr1.cr_operator,  
   variable_2= cr2.cr_max_value, 
   operator_2= cr2.cr_operator,  
   variable_3= cr3.cr_max_value, 
   operator_3= cr3.cr_operator,  
   result_1  = cr4.cr_max_value  
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

select @w_ente = 0

while 1=1 begin

   select top 1
   @w_ente       = cliente,
   @w_calif      = isnull(riesgo_ind_ext, 'C'),
   @w_matriz     = isnull(riesgo_matriz, 'A1')
   from #clientes_1
   where cliente  > @w_ente
   order by cliente asc
   
   if @@rowcount = 0 break
	
   select @w_result = result_1
   from #lcr_riesgo_max
    where ((operator_1 = '=' and variable_1 = 'CC')  or (operator_1 = 'cualquier valor'))
   and    (variable_2  = @w_calif AND operator_2 = '=')
   and    ((operator_3 = '=' and variable_3 = @w_matriz) or (operator_3 = 'cualquier valor')) 
	
   if @w_result = 'NO' delete #clientes_1 where cliente = @w_ente
   
  
	
end



delete #clientes_1 
where dias_m >=2 
or  atraso_an >=2  
or atraso_ac >=2

delete #clientes_1 
from   ca_lcr_candidatos 
where  cliente = cc_cliente 


--TABLA DE LA PANTALLA
insert into ca_lcr_candidatos (
cc_fecha_ing           ,cc_fecha_liq            	,cc_grupo,        
cc_nom_grupo           ,cc_oficina              	,cc_cliente,      
cc_nombre              ,cc_gerente           	    ,cc_asesor)  
select 
@w_fecha_corte,        fecha_liq,                   grupo,   
nom_grupo,             oficina,                     cliente,
nombre,                gerente,                     asesor     
from #clientes_1
 
delete  ca_lcr_candidatos 
where cc_cliente in ( select io_campo_1 from cob_workflow..wf_inst_proceso where io_campo_4 = 'REVOLVENTE' and io_estado = 'EJE' )  
and cc_respuesta is null 

delete  ca_lcr_candidatos 
where cc_cliente in (select op_cliente from ca_operacion where @w_fecha_proceso between op_fecha_ini and op_fecha_fin and op_toperacion = 'REVOLVENTE')
and cc_respuesta is null


drop table #lcr_riesgo_max

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