/************************************************************************/
/*   Archivo:             segmentacion_clientes.sp                      */
/*   Stored procedure:    segmentacion_clientes                         */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Bruno Duenas                                  */
/*   Fecha de escritura:  07-Marzo-2023                                 */
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
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                     PROPOSITO                                        */
/*   Se registran la segmentacion de clientes                           */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 07/Marzo/2023            BDU              Emision Inicial            */
/* 03/Mayo/2023             BDU              Se eliminan registros del  */
/*                                           dia en que se ejecuta el   */
/*                                           proceso (de existir)       */
/* 10/Octubre/2023          BDU              Ajustes redmine  - R217005 */
/* 19/Octubre/2023          BDU              Quitar reglas que no se usa*/
/* 20/Octubre/2023          BDU              Corregir logica resultado  */
/* 14/Noviembre/2023        BDU              R219551-Optimizar proceso  */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'segmentacion_clientes')
begin
   drop proc segmentacion_clientes
end   
go

create procedure segmentacion_clientes(
@i_param1   int      null
)
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_producto                 catalogo,
        @w_fecha_actual             datetime,
        @w_error                    int,
        @w_variables                varchar(64),
        @w_return_variable          varchar(25),
        @w_return_results           varchar(25),
        @w_last_condition_parent    varchar(10),
        @w_return_results_rule      varchar(25),
        @w_id                       int,
        @w_id_max                   int,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_num_ciclos               int,
        @w_ingreso                  money,
        @w_resultado_segmento       catalogo,
        @w_resultado_subsegmento    catalogo,
        @w_resultado_rango          catalogo,
        @w_riesgo_zona_negocio      catalogo,
        @w_riesgo_zona_domicilio    catalogo,
        @w_parroquia_neg            catalogo,
        @w_parroquia_dom            catalogo,
        @w_tipo_negocio             catalogo,
        @w_categoria                catalogo,
        @w_puntaje                  int,
        @w_nivel                    catalogo,
        @w_ipp                      int,
        @w_id_cliente               int,
        --reglas
        @w_code_rule_sub            int
        --Tablas de parametrizacion de reglas
        declare @w_regla_RSESUBSEGM table(
        operador           varchar(20),  --operador 
        variable_1_min     varchar(255), --Ingreso (Condicional minimo)
        variable_1_max     varchar(255), --Ingreso (Valor base)
        result_1           varchar(255), --SEGMENTO
        result_2           varchar(255), --SUBSEGMENT
        result_3           varchar(255), --RANGO
        result_4           varchar(255)  --RESULTADO
        )
        declare @w_code_rule_cat           int
        declare @w_regla_RSECATEGOR table(
        operador1          varchar(20),  --operador1,
        operador2          varchar(20),  --operador2        
        variable_1         varchar(255), --SEGMENTO
        variable_2         varchar(255), --CATEGORIA
        result_1           varchar(255) --RESULTADO
        )
        declare @w_regla_CICLO table(
        operador1           varchar(20),
        operador2           varchar(20),
        variable_1          varchar(255), --SEGMENTO
        variable_2_min      varchar(255), --CICLO_MIN,
        variable_2_max      varchar(255), --CICLO_MAX
        result_1            varchar(255)  --RESULTADO
        )
        declare @w_code_rule_ciclo  int
        declare @w_regla_IPP table(
        operador1           varchar(20),
        operador2           varchar(20),
        variable_1          varchar(255), --SEGMENTO
        variable_2_min      varchar(255), --IPP_MIN,
        variable_2_max      varchar(255), --IPP_MAX
        result_1            varchar(255)  --RESULTADO
        )
        declare @w_code_rule_ipp    int,
        @w_code_rule_gon    int
        declare @w_regla_RSERIESGON table(
        operador1          varchar(20),  --operador1,
        operador2          varchar(20),  --operador2        
        variable_1         varchar(255), --SEGMENTO
        variable_2         varchar(255), --RIESGO
        result_1           varchar(255) --RESULTADO
        )
        declare @w_code_rule_gov    int
        declare @w_regla_RSERIESGOV table(
        operador1          varchar(20),  --operador1,
        operador2          varchar(20),  --operador2        
        variable_1         varchar(255), --SEGMENTO
        variable_2         varchar(255), --RIESGO
        result_1           varchar(255) --RESULTADO
        )
        declare @w_code_rule_tip_neg    int
        declare @w_regla_RSETIPONEG table(
        operador1          varchar(20),  --operador1,
        operador2          varchar(20),  --operador2        
        variable_1         varchar(255), --SEGMENTO
        variable_2         varchar(255), --tipo
        result_1           varchar(255) --RESULTADO
        )
        
-- Informacion proceso batch
print 'INICIO PROCESO segmentacion: '  + convert(varchar, getdate(),120)

--print 'VALIDACION DE REGISTROS DEL HILO: '
if not exists(select 1
              from cr_hilos_segmentacion
              where hs_hilo = @i_param1)
begin
   update cr_hilos_segmentacion
   set hs_estado = 'P'
   where hs_hilo = @i_param1
   
   return 0
end

select @w_termina = 0

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..segmentacion_clientes'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end

/*
select @w_sarta = 21001,
       @w_batch = 21016
*/
--Parametros
select @w_tiempo = isnull(pa_int, 1)
from cobis..cl_parametro
where pa_nemonico = 'DBHS'
and pa_producto   = 'CLI'

--Validar que existan las reglas
if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSESUBSEGM' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
   select @w_termina = 1
   select @w_error  = 725109 
   goto ERROR
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSECATEGOR' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
   select @w_termina = 1
   select @w_error  = 725109 
   goto ERROR
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSECICLO' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
   select @w_termina = 1
   select @w_error  = 725109 
   goto ERROR
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSEIPP' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
   select @w_termina = 1
   select @w_error  = 725109 
   goto ERROR
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSERIESGON' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
   select @w_termina = 1
   select @w_error  = 725109 
   goto ERROR
end

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSERIESGOV' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
   select @w_termina = 1
   select @w_error  = 725109 
   goto ERROR
end
if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'RSETIPONEG' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
   select @w_termina = 1
   select @w_error  = 725109 
   goto ERROR
end

select @w_fecha_actual = getdate()


--sacar datos de las reglas
--Regla RSESUBSEGM
select @w_code_rule_sub = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSESUBSEGM'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'

insert into @w_regla_RSESUBSEGM 
select cr1.cr_operator, 
       cr1.cr_min_value as variable_1_min, 
       cr1.cr_max_value as variable_1_max,
       cr3.cr_max_value as result_1,
       cr4.cr_max_value as result_2,
       cr5.cr_max_value as result_3,
       cr6.cr_max_value as result_4
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr3 on cr1.cr_id = cr3.cr_parent
inner join cob_pac..bpl_condition_rule cr4 on cr3.cr_id = cr4.cr_parent
inner join cob_pac..bpl_condition_rule cr5 on cr4.cr_id = cr5.cr_parent
inner join cob_pac..bpl_condition_rule cr6 on cr5.cr_id = cr6.cr_parent
where cr1.rv_id = (select max(rv_id) 
                from cob_pac..bpl_rule_version 
                where rl_id = @w_code_rule_sub
                and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'
and cr4.cr_is_last_son = 'true'      
and cr5.cr_is_last_son = 'true'  
and cr6.cr_is_last_son = 'true' 

--Reglas RSECATEGOR

select @w_code_rule_cat = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSECATEGOR'--'CALIFICACION Y PROVISION'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
        
  
insert into @w_regla_RSECATEGOR 
select cr1.cr_operator,
       cr2.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr2.cr_max_value as variable_2_max,--Variable entrada 2
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join  cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_code_rule_cat
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'

--Regla ciclo
select @w_code_rule_ciclo = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSECICLO'--'CALIFICACION Y PROVISION'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
  
insert into @w_regla_CICLO  
select cr1.cr_operator,
       cr2.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr2.cr_min_value as variable_2_min,--Variable entrada 2 min
       cr2.cr_max_value as variable_2_max,--Variable entrada 2 max
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join  cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_code_rule_ciclo
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'

--Regla IPP
select @w_code_rule_ipp = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSEIPP'--'CALIFICACION Y PROVISION'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
  
insert into @w_regla_IPP  
select cr1.cr_operator,
       cr2.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr2.cr_min_value as variable_2_min,--Variable entrada 2 min
       cr2.cr_max_value as variable_2_max,--Variable entrada 2 max
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join  cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_code_rule_ipp
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'
--regla RIESGO negocio
select @w_code_rule_gon = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSERIESGON'--'CALIFICACION Y PROVISION'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
        
  
insert into @w_regla_RSERIESGON
select cr1.cr_operator,
       cr2.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr2.cr_max_value as variable_2_max,--Variable entrada 2
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join  cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_code_rule_gon
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'
--regla RIESGO Vivienda
select @w_code_rule_gov = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSERIESGOV'--'CALIFICACION Y PROVISION'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
        
  
insert into @w_regla_RSERIESGOV
select cr1.cr_operator,
       cr2.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr2.cr_max_value as variable_2_max,--Variable entrada 2
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join  cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_code_rule_gov
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'


--regla tipo  negocio
select @w_code_rule_tip_neg = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'RSETIPONEG'--'CALIFICACION Y PROVISION'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'
        
  
insert into @w_regla_RSETIPONEG
select cr1.cr_operator,
       cr2.cr_operator,
       cr1.cr_max_value as variable_1_max,--Variable entrada 1
       cr2.cr_max_value as variable_2_max,--Variable entrada 2
       cr3.cr_max_value as result_1 --Resultado
from  cob_pac..bpl_condition_rule cr1
inner join  cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = (select max(rv_id) 
                   from cob_pac..bpl_rule_version 
                   where rl_id = @w_code_rule_tip_neg
                   and rv_status = 'PRO')
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'

--print 'INICIO DE BUCLE PARA EJECUCIÓN DE REGLA: '  + convert(varchar, getdate(),120)
select @w_id = hs_inicio 
from cr_hilos_segmentacion
where hs_hilo = @i_param1

select @w_id_max = hs_fin 
from cr_hilos_segmentacion
where hs_hilo = @i_param1

while @w_id <= @w_id_max
begin
   ----print '********************** Registro ' + convert(varchar, @w_id) + ' **********************'
   --Inicializar variables
   select @w_puntaje                    = 0,
          @w_ingreso                    = 0,
          @w_ingreso                    = null,
          @w_categoria                  = null,
          @w_num_ciclos                 = null,
          @w_ipp                        = null,
          @w_riesgo_zona_negocio        = null,
          @w_riesgo_zona_domicilio      = null,
          @w_tipo_negocio               = null
          
   --Sacar datos del universo
   select @w_ingreso               = us_ingreso,
          @w_categoria             = us_categoria,
          @w_num_ciclos            = us_ciclos,
          @w_ipp                   = us_ipp,
          @w_riesgo_zona_negocio   = convert(varchar, us_riesgo_zona_negocio),
          @w_riesgo_zona_domicilio = convert(varchar, us_riesgo_zona_domicil),
          @w_tipo_negocio          = convert(varchar, us_tipo_neg),
          @w_id_cliente            = us_ente
   from cr_universo_segmentacion
   where us_id  = @w_id
  
   
   --Regla de subsegmento
   select @w_resultado_segmento = result_1, 
          @w_resultado_subsegmento = result_2,  
          @w_resultado_rango = result_3,   
          @w_puntaje = @w_puntaje + convert(int, result_4) 
   from @w_regla_RSESUBSEGM
   where 
   case trim(operador) when '>' 
                         then (select case when (@w_ingreso > convert(float,variable_1_max)) then 1 else 0 end) 
                       when '>=' 
                         then (select case when (@w_ingreso >= convert(float,variable_1_max)) then 1 else 0 end)
                       when '<>' 
                         then (select case when (@w_ingreso <> convert(float,variable_1_max)) then 1 else 0 end)
                       when '<' 
                         then (select case when (@w_ingreso < convert(float,variable_1_max)) then 1 else 0 end)
                       when '<=' 
                         then (select case when (@w_ingreso <= convert(float,variable_1_max)) then 1 else 0 end) 
                       when 'BETWEEN'
                         then (select case when (@w_ingreso BETWEEN convert(float,variable_1_min) AND convert(float,variable_1_max)) then 1 else 0 end)
                       when '='
                         then (select case when (@w_ingreso = convert(float,variable_1_max)) then 1 else 0 end)
                       when 'ANYVALUE'
                         then (select case when (@w_ingreso is not null) then 1 else 0 end)
                       when 'ISNULL'
                         then (select case when (@w_ingreso is null) then 1 else 0 end) 
                       end = 1
                       
   --Regla de categoria
   select @w_puntaje = @w_puntaje + convert(int, result_1) 
   from @w_regla_RSECATEGOR
   where 
   case trim(operador1) when '='
                          then (select case when (@w_resultado_segmento = variable_1) then 1 else 0 end)
                        when '>'
                          then (select case when (@w_resultado_segmento > variable_1) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_resultado_segmento < variable_1) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_resultado_segmento <> variable_1) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_resultado_segmento is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_resultado_segmento is null) then 1 else 0 end) 
                        end = 1
   and 
   case trim(operador2) when '='
                          then (select case when (@w_categoria = variable_2) then 1 else 0 end) 
                        when '>'
                          then (select case when (@w_categoria > variable_2) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_categoria < variable_2) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_categoria <> variable_2) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_categoria is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_categoria is null) then 1 else 0 end) 
                        end = 1
   
   
   
   --Regla de ciclo
   select @w_puntaje = @w_puntaje + convert(int, result_1) 
   from @w_regla_CICLO
   where 
   case trim(operador1) when '='
                          then (select case when (@w_resultado_segmento = variable_1) then 1 else 0 end) 
                        when '>'
                          then (select case when (@w_resultado_segmento > variable_1) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_resultado_segmento < variable_1) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_resultado_segmento <> variable_1) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_resultado_segmento is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_resultado_segmento is null) then 1 else 0 end) 
   end = 1
   and 
   case trim(operador2) when '>' 
                          then (select case when (@w_num_ciclos > convert(int,variable_2_max)) then 1 else 0 end) 
                        when '>=' 
                          then (select case when (@w_num_ciclos >= convert(int,variable_2_max)) then 1 else 0 end)
                        when '<>' 
                          then (select case when (@w_num_ciclos <> convert(int,variable_2_max)) then 1 else 0 end)
                        when '<' 
                          then (select case when (@w_num_ciclos < convert(int,variable_2_max)) then 1 else 0 end)
                        when '<=' 
                          then (select case when (@w_num_ciclos <= convert(int,variable_2_max)) then 1 else 0 end) 
                        when 'BETWEEN'
                          then (select case when (@w_num_ciclos BETWEEN convert(int,variable_2_min) AND convert(int,variable_2_max)) then 1 else 0 end)
                        when '='
                          then (select case when (@w_num_ciclos = convert(int,variable_2_max)) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_num_ciclos is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_num_ciclos is null) then 1 else 0 end) 
                        end = 1

   --Regla de ipp      
   select @w_puntaje = @w_puntaje + convert(int, result_1) 
   from @w_regla_IPP
   where 
   case trim(operador1) when '='
                          then (select case when (@w_resultado_segmento = variable_1) then 1 else 0 end) 
                        when '>'
                          then (select case when (@w_resultado_segmento > variable_1) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_resultado_segmento < variable_1) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_resultado_segmento <> variable_1) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_resultado_segmento is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_resultado_segmento is null) then 1 else 0 end) 
   end = 1
   and 
   case trim(operador2) when '>' 
                          then (select case when (@w_ipp > convert(int,variable_2_max)) then 1 else 0 end) 
                        when '>=' 
                          then (select case when (@w_ipp >= convert(int,variable_2_max)) then 1 else 0 end)
                        when '<>' 
                          then (select case when (@w_ipp <> convert(int,variable_2_max)) then 1 else 0 end)
                        when '<' 
                          then (select case when (@w_ipp < convert(int,variable_2_max)) then 1 else 0 end)
                        when '<=' 
                          then (select case when (@w_ipp <= convert(int,variable_2_max)) then 1 else 0 end) 
                        when 'BETWEEN'
                          then (select case when (@w_ipp BETWEEN convert(int,variable_2_min) AND convert(int,variable_2_max)) then 1 else 0 end)
                        when '='
                          then (select case when (@w_ipp = convert(int,variable_2_max)) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_ipp is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_ipp is null) then 1 else 0 end) 
                        end = 1
   --Regla de riesgo negocio
   select @w_puntaje = @w_puntaje + convert(int, result_1) 
   from @w_regla_RSERIESGON
   where 
   case trim(operador1) when '='
                          then (select case when (@w_resultado_segmento = variable_1) then 1 else 0 end) 
                        when '>'
                          then (select case when (@w_resultado_segmento > variable_1) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_resultado_segmento < variable_1) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_resultado_segmento <> variable_1) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_resultado_segmento is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_resultado_segmento is null) then 1 else 0 end) 
                        end = 1
   and 
   case trim(operador2) when '='
                          then (select case when (@w_riesgo_zona_negocio = variable_2) then 1 else 0 end)
                        when '>'
                          then (select case when (@w_riesgo_zona_negocio > variable_2) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_riesgo_zona_negocio < variable_2) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_riesgo_zona_negocio <> variable_2) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_riesgo_zona_negocio is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_riesgo_zona_negocio is null) then 1 else 0 end) 						  
                        end = 1
                             
   --Regla de riesgo vivienda

   select @w_puntaje = @w_puntaje + convert(int, result_1) 
   from @w_regla_RSERIESGOV
   where 
   case trim(operador1) when '='
                          then (select case when (@w_resultado_segmento = variable_1) then 1 else 0 end) 
                        when '>'
                          then (select case when (@w_resultado_segmento > variable_1) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_resultado_segmento < variable_1) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_resultado_segmento <> variable_1) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_resultado_segmento is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_resultado_segmento is null) then 1 else 0 end) 
                        end = 1
   and 
   case trim(operador2) when '='
                          then (select case when (@w_riesgo_zona_domicilio = variable_2) then 1 else 0 end)
						when '>'
                          then (select case when (@w_riesgo_zona_domicilio > variable_2) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_riesgo_zona_domicilio < variable_2) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_riesgo_zona_domicilio <> variable_2) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_riesgo_zona_domicilio is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_riesgo_zona_domicilio is null) then 1 else 0 end) 	
                        end = 1                                               
                                          
   --Regla de tipo de negocio

   select @w_puntaje = @w_puntaje + convert(int, result_1) 
   from @w_regla_RSETIPONEG
   where 
   case trim(operador1) when '='
                          then (select case when (@w_resultado_segmento = variable_1) then 1 else 0 end)
						when '>'
                          then (select case when (@w_resultado_segmento > variable_1) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_resultado_segmento < variable_1) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_resultado_segmento <> variable_1) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_resultado_segmento is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_resultado_segmento is null) then 1 else 0 end) 
                        end = 1
   and 
   case trim(operador2) when '='
                          then (select case when (@w_tipo_negocio = variable_2) then 1 else 0 end)
						when '>'
                          then (select case when (@w_tipo_negocio > variable_2) then 1 else 0 end) 
                        when '<'
                          then (select case when (@w_tipo_negocio < variable_2) then 1 else 0 end) 
                        when '<>'
                          then (select case when (@w_tipo_negocio <> variable_2) then 1 else 0 end)
                        when 'ANYVALUE'
                          then (select case when (@w_tipo_negocio is not null) then 1 else 0 end)
                        when 'ISNULL'
                          then (select case when (@w_tipo_negocio is null) then 1 else 0 end) 	
                        end = 1    


   ----print 'Puntaje Total: ' + convert(varchar, isnull(@w_puntaje, 0))
   --Insertar en la tabla el puntaje obtenido
   insert into cr_segmentacion_cliente(sc_fecha,           sc_segmento,           sc_subsegmento,
                                       sc_rango,           sc_puntaje,            sc_ente)
   values                             (getdate(),          @w_resultado_segmento, @w_resultado_subsegmento,
                                       @w_resultado_rango, @w_puntaje,            @w_id_cliente)
   if @@error <> 0
   begin
      select @w_mensaje = 'ERROR AL INGRESAR DATOS DE SEGMENTACION PARA EL CLIENTE ' + convert(varchar, @w_id_cliente)
      goto ERROR
   end
   
   NEXT_LINE:
     set @w_id = @w_id + 1
end

select @w_termina = 1
update cr_hilos_segmentacion
set hs_estado = 'P'
where hs_hilo = @i_param1
return 0

ERROR:
   update cr_hilos_segmentacion
   set hs_estado = 'E'
   where hs_hilo = @i_param1
   
   if @w_mensaje is null
   begin
      select @w_mensaje = mensaje
      from cobis..cl_errores 
      where numero = @w_error
   end
   
   if(@w_sarta is not null or @w_batch is not null)
   begin
      exec @w_retorno_ej = cobis..sp_ba_error_log
         @i_sarta   = @w_sarta,
         @i_batch   = @w_batch,
         @i_error   = @w_error,
         @i_detalle = @w_mensaje
   end
   if @w_termina = 0
   begin
      goto NEXT_LINE
   end
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
