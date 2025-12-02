/********************************************************************/
/*   NOMBRE LOGICO:         sp_scoring_cli                          */
/*   NOMBRE FISICO:         sp_scoring_cli.sp                       */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          P. Jarrin.                              */
/*   FECHA DE ESCRITURA:    01-Mar-2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Proceso de scoring de los clientes de manera de evaluar su     */
/*   probabilidad de incumplimiento de pago de sus créditos.        */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   01-Mar-2023        P. Jarrin.       Emision Inicial - S784696  */
/*   22-May-2023        P. Jarrin.       Ajustes Review  - S832393  */
/*   10-Oct-2023        B. Duenas.       Ajustes redmine  - R217005 */
/*   16-Oct-2023        B. Duenas.       Ajustes nemónico Garantia  */
/*                                       Personal                   */
/*   24-Oct-2023        B. Duenas.       Se desglosa productos      */
/*   17-Nov-2023        B. Duenas.       R219551 Se optimiza proceso*/
/*   30-Nov-2023        B. Duenas.       R220623 Cambio tipo de dato*/
/*   19-Sep-2024        B. Duenas.       R246363 Remover tipo reno- */
/*                                       vación y garantías vigentes*/
/********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_scoring_cli')
   drop proc sp_scoring_cli
go

create proc sp_scoring_cli(
        @s_ssn                      int         = null,
        @s_user                     login       = null,
        @s_sesn                     int         = null,
        @s_term                     descripcion = null,
        @s_date                     datetime    = null,
        @s_srv                      varchar(30) = null,
        @s_lsrv                     varchar(30) = null,
        @s_rol                      smallint    = null,
        @s_ofi                      smallint    = null,
        @s_org_err                  char(1)     = null,
        @s_culture                  varchar(10) = 'NEUTRAL',
        @s_error                    int         = null,
        @s_sev                      tinyint     = null,
        @s_msg                      descripcion = null,
        @s_org                      char(1)     = null,
        @t_rty                      char(1)     = null,
        @t_trn                      int         = null,
        @t_debug                    char(1)     = 'N',
        @t_file                     varchar(14) = null,
        @t_from                     varchar(30) = null,
        @t_show_version             bit         = 0,
        @i_cliente                  int         ,
        @o_valor_z                  float     = 0 out
)
as
declare 
        @w_sp_name                varchar(32),
        @w_sp_msg                 varchar(100),
        @w_return                 int,
        @w_error                  int,
        @w_producto_cd            catalogo,
        @w_producto_gs            catalogo,
        @w_producto_mbc           catalogo,
        @w_tipo_personal          varchar(10),
        @w_producto_scoring       varchar(10),      
        @w_variables              varchar(64),
        @w_return_variable        varchar(25),
        @w_return_results         varchar(25),
        @w_return_results_rule    varchar(25),
        @w_last_condition_parent  varchar(10),
        @w_sexo                   varchar(10),
        @w_return_sexo            float,      
        @w_calificacion           varchar(10),
        @w_return_calificacion    float,
        @w_restru                 varchar(10),
        @w_return_restru          float,
        @w_fiduciaria             varchar(10),
        @w_return_fiduciaria      float,      
        @w_prod_cre_cd            varchar(10),
        @w_return_prod_cre_cd     float,
        @w_prod_cre_gs            varchar(10),
        @w_return_prod_cre_gs     float,
        @w_prod_cre_mbc           varchar(10),
        @w_return_prod_cre_mbc    float,      
        @w_edad                   int,      
        @w_ciclo                  int,  
        @w_porcentaje_tasa        float,
        @w_valor_z                float,
        @w_valor_0                float,
        @w_valor_1                float,
        @w_valor_2                float,
        @w_valor_3                float,
        @w_valor_4                float,
        @w_valor_5                float,
        @w_valor_6                float,
        @w_valor_7                float,
        @w_valor_8                float,
        @w_valor_9                float,
        @w_valor_10               float,
        --variables de tablas
        @w_cod_rule_cat           int,
        @w_cod_rule_res           int,
        @w_cod_rule_cia           int,
        @w_cod_rule_exo           int,
        @w_cod_rule_dcd           int,
        @w_cod_rule_dgs           int,
        @w_cod_rule_mbc           int
        
        declare @w_regla_RSCCATEGOR table(
        operador1          varchar(20),  --operador1,      
        variable_1         varchar(255), --categoria
        result_1           varchar(10) --RESULTADO
        )
        
        declare @w_regla_RSCREFIRES table(
        operador1          varchar(20),  --operador1,      
        variable_1         varchar(255), --categoria
        result_1           varchar(10) --RESULTADO
        )
        
        declare @w_regla_RSCFIDUCIA table(
        operador1          varchar(20),  --operador1,      
        variable_1         varchar(255), --categoria
        result_1           varchar(10) --RESULTADO
        )
        
        declare @w_regla_RSCSEXO table(
        operador1          varchar(20),  --operador1,      
        variable_1         varchar(255), --categoria
        result_1           varchar(10) --RESULTADO
        )
        
        declare @w_regla_RSCPRODCD table(
        operador1          varchar(20),  --operador1,      
        variable_1         varchar(255), --categoria
        result_1           varchar(10) --RESULTADO
        )
        
        declare @w_regla_RSCPRODGS table(
        operador1          varchar(20),  --operador1,      
        variable_1         varchar(255), --categoria
        result_1           varchar(10) --RESULTADO
        )
        
        declare @w_regla_RSCPRODMBC table(
        operador1          varchar(20),  --operador1,      
        variable_1         varchar(255), --categoria
        result_1           varchar(10) --RESULTADO
        )
        
        
        
select  @w_sp_name                = 'sp_scoring_cli',
        @w_variables              = '',
        @w_return_variable        = '',
        @w_return_results         = '',
        @w_return_results_rule    = '',
        @w_last_condition_parent  = '',
        @w_sexo                   = '',
        @w_return_sexo            = 0,
        @w_calificacion           = '',
        @w_return_calificacion    = 0,
        @w_restru                 = '',
        @w_return_restru          = 0,
        @w_fiduciaria             = '',
        @w_return_fiduciaria      = 0,
        @w_prod_cre_cd            = '',
        @w_return_prod_cre_cd     = 0,
        @w_prod_cre_gs            = '',
        @w_return_prod_cre_gs     = 0,
        @w_prod_cre_mbc           = '',
        @w_return_prod_cre_mbc    = 0,
        @w_edad                   = 0,
        @w_ciclo                  = 0,
        @w_porcentaje_tasa        = 0,
        @w_valor_z                = 0,
        @w_valor_0                = 0,
        @w_valor_1                = 0,
        @w_valor_2                = 0,
        @w_valor_3                = 0,
        @w_valor_4                = 0,
        @w_valor_5                = 0,
        @w_valor_6                = 0,
        @w_valor_7                = 0,
        @w_valor_8                = 0,
        @w_valor_9                = 0,
        @w_valor_10               = 0
  
select @w_producto_cd = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'PRODCD'
   and pa_producto   = 'CRE'

select @w_producto_gs = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'PRODGS'
   and pa_producto   = 'CRE'

select @w_producto_mbc = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'PROMBC'
   and pa_producto   = 'CRE'

select @w_tipo_personal = pa_char
  from cobis..cl_parametro
 where pa_producto = 'GAR'
   and pa_nemonico = 'GARGPE' 
  
select @w_producto_scoring = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'PROSCO'
   and pa_producto   = 'CRE'
   


--Validacion regla en produccion
if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSCCATEGOR' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
    select @w_return  = 725109
    goto ERROR_FIN  
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSCREFIRES' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
    select @w_return  = 725109
    goto ERROR_FIN  
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSCFIDUCIA' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
    select @w_return  = 725109
    goto ERROR_FIN  
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSCSEXO' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
    select @w_return  = 725109
    goto ERROR_FIN  
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSCPRODCD' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
    select @w_return  = 725109
    goto ERROR_FIN  
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSCPRODGS' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
    select @w_return  = 725109
    goto ERROR_FIN  
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSCPRODMBC' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
    select @w_return  = 725109
    goto ERROR_FIN  
end

--Insercion de condiciones en las tablas de reglas
select @w_cod_rule_cat = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSCCATEGOR'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
 
insert into @w_regla_RSCCATEGOR 
select cr1.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr3 on cr1.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_cod_rule_cat
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'

select @w_cod_rule_res = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSCREFIRES'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
 
insert into @w_regla_RSCREFIRES 
select cr1.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr3 on cr1.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_cod_rule_res
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'

select @w_cod_rule_cia = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSCFIDUCIA'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
 
insert into @w_regla_RSCFIDUCIA 
select cr1.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr3 on cr1.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_cod_rule_cia
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'


select @w_cod_rule_exo = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSCSEXO'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
 
insert into @w_regla_RSCSEXO    
select cr1.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr3 on cr1.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_cod_rule_exo
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'

select @w_cod_rule_dcd = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSCPRODCD'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
 
insert into @w_regla_RSCPRODCD  
select cr1.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr3 on cr1.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_cod_rule_dcd
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'

select @w_cod_rule_dgs = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSCPRODGS'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
 
insert into @w_regla_RSCPRODGS  
select cr1.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr3 on cr1.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_cod_rule_dgs
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'


select @w_cod_rule_mbc = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSCPRODMBC'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
 
insert into @w_regla_RSCPRODMBC 
select cr1.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr3 on cr1.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_cod_rule_mbc
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'
           
--Calificacion o Categoria del cliente
select  @w_variables              = '',
        @w_return_variable        = '',
        @w_return_results         = '',
        @w_return_results_rule    = '',
        @w_last_condition_parent  = ''
        
select @w_calificacion = case when en_calificacion is null or en_calificacion = '' then 'N' else en_calificacion end
from cobis..cl_ente
where en_ente = @i_cliente

SELECT @w_return_calificacion = convert(float, isnull(result_1, 0))
FROM @w_regla_RSCCATEGOR
where 
case trim(operador1) when '='
                       then (select case when (@w_calificacion = variable_1) then 1 else 0 end)
                     when '>'
                       then (select case when (@w_calificacion > variable_1) then 1 else 0 end) 
                     when '<'
                       then (select case when (@w_calificacion < variable_1) then 1 else 0 end) 
                     when '<>'
                       then (select case when (@w_calificacion <> variable_1) then 1 else 0 end)
                     when 'ANYVALUE'
                       then (select case when (@w_calificacion is not null) then 1 else 0 end)
                     when 'ISNULL'
                       then (select case when (@w_calificacion is null) then 1 else 0 end) 
end = 1


--Creditos refinanciados o reestructurados
if exists (select 1 
            from cob_cartera..ca_operacion with (NOLOCK), cob_credito..cr_tramite  with (NOLOCK)
           where op_estado not in (0,3,6,99)
             and op_cliente = @i_cliente
             and op_cliente = tr_cliente
             and op_tramite = tr_tramite 
             and tr_tipo in ('E','F'))
begin
    select @w_restru = 'S'
end
else
begin
    select @w_restru = 'N'
end               

SELECT @w_return_restru = convert(float, isnull(result_1, 0))
FROM @w_regla_RSCREFIRES
where 
case trim(operador1) when '='
                       then (select case when (@w_restru = variable_1) then 1 else 0 end)
                     when '>'
                       then (select case when (@w_restru > variable_1) then 1 else 0 end) 
                     when '<'
                       then (select case when (@w_restru < variable_1) then 1 else 0 end) 
                     when '<>'
                       then (select case when (@w_restru <> variable_1) then 1 else 0 end)
                     when 'ANYVALUE'
                       then (select case when (@w_restru is not null) then 1 else 0 end)
                     when 'ISNULL'
                       then (select case when (@w_restru is null) then 1 else 0 end) 
end = 1

--Garantias Fiduciarias          
if exists (select 1 
             from cob_cartera.dbo.ca_operacion with (NOLOCK), cob_credito..cr_tramite  with (NOLOCK), cob_credito..cr_gar_propuesta with (NOLOCK), 
                  cob_custodia..cu_custodia with (NOLOCK)
           where op_estado not in (0,3,6,99)
             and op_cliente        = @i_cliente
             and op_cliente        = tr_cliente
             and op_tramite        = tr_tramite
             and op_tramite        = gp_tramite
             and gp_garantia       = cu_codigo_externo
             and cu_tipo           = @w_tipo_personal
             and cu_estado         in (SELECT eg_estado 
                                       FROM cob_custodia.dbo.cu_estados_garantia 
                                       where lower(eg_descripcion) like '%vigente%'))
begin
    select @w_fiduciaria = 'S'
end
else
begin
    select @w_fiduciaria = 'N'
end               

SELECT @w_return_fiduciaria = convert(float, isnull(result_1, 0))
FROM @w_regla_RSCFIDUCIA
where 
case trim(operador1) when '='
                       then (select case when (@w_fiduciaria = variable_1) then 1 else 0 end)
                     when '>'
                       then (select case when (@w_fiduciaria > variable_1) then 1 else 0 end) 
                     when '<'
                       then (select case when (@w_fiduciaria < variable_1) then 1 else 0 end) 
                     when '<>'
                       then (select case when (@w_fiduciaria <> variable_1) then 1 else 0 end)
                     when 'ANYVALUE'
                       then (select case when (@w_fiduciaria is not null) then 1 else 0 end)
                     when 'ISNULL'
                       then (select case when (@w_fiduciaria is null) then 1 else 0 end) 
end = 1

             
--Sexo del Cliente
select @w_sexo = isnull(p_sexo,'')
  from cobis..cl_ente
 where en_ente = @i_cliente

SELECT @w_return_sexo = convert(float, isnull(result_1, 0))
FROM @w_regla_RSCSEXO
where 
case trim(operador1) when '='
                       then (select case when (@w_sexo = variable_1) then 1 else 0 end)
                     when '>'
                       then (select case when (@w_sexo > variable_1) then 1 else 0 end) 
                     when '<'
                       then (select case when (@w_sexo < variable_1) then 1 else 0 end) 
                     when '<>'
                       then (select case when (@w_sexo <> variable_1) then 1 else 0 end)
                     when 'ANYVALUE'
                       then (select case when (@w_sexo is not null) then 1 else 0 end)
                     when 'ISNULL'
                       then (select case when (@w_sexo is null) then 1 else 0 end) 
                    
end = 1

--Producto Credito CD 
if exists (select 1 from cob_cartera..ca_operacion with (NOLOCK)
            where op_estado not in (0,3,6,99)
              and op_cliente    = @i_cliente
              and op_toperacion in (select trim(value) from string_split(@w_producto_cd, ';')))
begin
    select @w_prod_cre_cd = 'S'
end
else
begin
    select @w_prod_cre_cd = 'N'
end               

SELECT @w_return_prod_cre_cd = convert(float, isnull(result_1, 0))
FROM @w_regla_RSCPRODCD
where 
case trim(operador1) when '='
                       then (select case when (@w_prod_cre_cd = variable_1) then 1 else 0 end)
                     when '>'
                       then (select case when (@w_prod_cre_cd > variable_1) then 1 else 0 end) 
                     when '<'
                       then (select case when (@w_prod_cre_cd < variable_1) then 1 else 0 end) 
                     when '<>'
                       then (select case when (@w_prod_cre_cd <> variable_1) then 1 else 0 end)
                     when 'ANYVALUE'
                       then (select case when (@w_prod_cre_cd is not null) then 1 else 0 end)
                     when 'ISNULL'
                       then (select case when (@w_prod_cre_cd is null) then 1 else 0 end) 
end = 1

--Producto Credito GS
if exists (select 1 from cob_cartera..ca_operacion with (NOLOCK)
            where op_estado not in (0,3,6,99)
              and op_cliente    = @i_cliente
              and op_toperacion in (select trim(value) from string_split(@w_producto_gs, ';')))
begin
    select @w_prod_cre_gs = 'S'
end
else
begin
    select @w_prod_cre_gs = 'N'
end

SELECT @w_return_prod_cre_gs = convert(float, isnull(result_1, 0))
FROM @w_regla_RSCPRODGS
where 
case trim(operador1) when '='
                       then (select case when (@w_prod_cre_gs = variable_1) then 1 else 0 end)
                     when '>'
                       then (select case when (@w_prod_cre_gs > variable_1) then 1 else 0 end) 
                     when '<'
                       then (select case when (@w_prod_cre_gs < variable_1) then 1 else 0 end) 
                     when '<>'
                       then (select case when (@w_prod_cre_gs <> variable_1) then 1 else 0 end)
                     when 'ANYVALUE'
                       then (select case when (@w_prod_cre_gs is not null) then 1 else 0 end)
                     when 'ISNULL'
                       then (select case when (@w_prod_cre_gs is null) then 1 else 0 end) 
end = 1

--Producto Credito MBC
if exists (select 1 from cob_cartera..ca_operacion with (NOLOCK)
           where op_estado not in (0,3,6,99)
             and op_cliente    = @i_cliente
             and op_toperacion  in (select trim(value) from string_split(@w_producto_mbc, ';')))
begin
    select @w_prod_cre_mbc = 'S'
end
else
begin
    select @w_prod_cre_mbc = 'N'
end

SELECT @w_return_prod_cre_mbc = convert(float, isnull(result_1, 0))
FROM @w_regla_RSCPRODMBC
where 
case trim(operador1) when '='
                       then (select case when (@w_prod_cre_mbc = variable_1) then 1 else 0 end)
                     when '>'
                       then (select case when (@w_prod_cre_mbc > variable_1) then 1 else 0 end) 
                     when '<'
                       then (select case when (@w_prod_cre_mbc < variable_1) then 1 else 0 end) 
                     when '<>'
                       then (select case when (@w_prod_cre_mbc <> variable_1) then 1 else 0 end)
                     when 'ANYVALUE'
                       then (select case when (@w_prod_cre_mbc is not null) then 1 else 0 end)
                     when 'ISNULL'
                       then (select case when (@w_prod_cre_mbc is null) then 1 else 0 end) 
end = 1

--Ciclo Cliente
select @w_ciclo = isnull(en_nro_ciclo,0)
  from cobis..cl_ente  
 where en_ente = @i_cliente

--Edad Cliente
select @w_edad = datediff(yy,p_fecha_nac,getdate())
  from cobis..cl_ente  
 where en_ente = @i_cliente

--Tasa Nominal
select @w_porcentaje_tasa = max(isnull(ro_porcentaje,0)) / 100
  from cob_cartera..ca_rubro_op 
 where ro_concepto = 'INT'
   and ro_operacion in (select op_operacion
                          from cob_cartera..ca_operacion with (NOLOCK)
                         where op_estado not in (0,3,6,99)
                           and op_cliente = @i_cliente)
 

-- Valor Z
if (OBJECT_ID('tempdb.dbo.#tmp_data','U')) is not null
begin
  drop table #tmp_data
end
create table #tmp_data
(
    d_name    varchar(256) null,
    d_values  float null
)

insert into #tmp_data
select dc_name, uf_value
  from cob_fpm..fp_dictionaryfields , cob_fpm..fp_unitfunctionalityvalues
 where dc_fields_id     = dc_fields_id_fk
   and bp_product_id_fk = @w_producto_scoring
   and uf_delete        = 'N'
 order by  dc_fields_id  

select @w_valor_0  = d_values from #tmp_data where d_name = 'B0'
select @w_valor_1  = d_values from #tmp_data where d_name = 'B1'
select @w_valor_2  = d_values from #tmp_data where d_name = 'B2'
select @w_valor_3  = d_values from #tmp_data where d_name = 'B3'
select @w_valor_4  = d_values from #tmp_data where d_name = 'B4'
select @w_valor_5  = d_values from #tmp_data where d_name = 'B5'
select @w_valor_6  = d_values from #tmp_data where d_name = 'B6'
select @w_valor_7  = d_values from #tmp_data where d_name = 'B7'
select @w_valor_8  = d_values from #tmp_data where d_name = 'B8'
select @w_valor_9  = d_values from #tmp_data where d_name = 'B9'
select @w_valor_10 = d_values from #tmp_data where d_name = 'B10'

select @w_valor_z = @w_valor_0 + @w_valor_1 * @w_return_restru + @w_valor_2 * @w_return_fiduciaria + @w_valor_3 * @w_ciclo + 
                    @w_valor_4 * @w_return_calificacion + @w_valor_5 * @w_return_sexo + @w_valor_6 * @w_edad + @w_valor_7 * @w_porcentaje_tasa + 
                    @w_valor_8 * @w_return_prod_cre_cd + @w_valor_9 * @w_return_prod_cre_gs + @w_valor_10 * @w_return_prod_cre_mbc 

select @o_valor_z = @w_valor_z
       
return 0

ERROR_FIN:
select @o_valor_z = 0

exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_return
return @w_return

go
