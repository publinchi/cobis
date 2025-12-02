/************************************************************************/
/*      Archivo:                rep_prorecpag.sp                        */
/*      Stored procedure:       sp_rep_prorecpag                        */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Jul. 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera datos para el reporte                                    */
/*      Plazo promedio de colocacion de cartera activa a cierre de mes  */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      MAR-18-2009    JBQ      GAP-CCA-048                             */
/*      SEP-28-2009    TSU      Optimizacion                            */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_prorecpag')
   drop proc sp_rep_prorecpag
go

create proc sp_rep_prorecpag (
    @i_fecha_ini  datetime  = null,  --Fecha de vencimientos inicial
    @i_fecha_fin  datetime  = null --Fecha de vencimientos final
)
as
declare
@w_sp_name            varchar(32),
@w_return             int,
@w_error              int,
@w_est_vigente        tinyint,
@w_est_vencido        tinyint,
@w_est_cancelado      tinyint,
@w_est_castigado      tinyint,
@w_est_suspenso       tinyint,
@w_par_cap            catalogo,
@w_par_int            catalogo,
@w_par_imo            catalogo,
@w_par_mip            catalogo,
@w_par_iva            catalogo

/*CREACION DE TABLA TEMPORAL PARA EL REPORTE */
if exists (select 1 from sysobjects where name = 'rep_prorecpag')
   drop table rep_prorecpag 

create table rep_prorecpag 
(
       tmp_nro_oper           int         null,  -- Numero de Operaciones
       tmp_cod_ofi            smallint    null,  --Codigo de la oficina de la operacion
       tmp_des_ofi            varchar(64) null,  --Descripcion de la oficina de la operacion
       tmp_cod_funcionario    smallint    null, 
       tmp_nombre_funcionario varchar(64) null,
       tmp_fecha_ven          datetime    null,  -- Fecha de vencimiento
       tmp_cap                money       null, 
       tmp_int                money       null, 
       tmp_imo                money       null, 
       tmp_mipymes            money       null, 
       tmp_ivamipymes         money       null, 
       tmp_otros              money       null,
       tmp_valor_total        money       null  
)

/* INICIALIZACION VARIABLES */
select
@w_sp_name   = 'sp_rep_prorecpag'

select @w_est_vigente = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'CANCELADO'

select @w_est_castigado = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'CASTIGADO'

select @w_est_suspenso = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'SUSPENSO'

select @w_par_cap = pa_char
from   cobis..cl_parametro 
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'

select @w_par_int = pa_char
from   cobis..cl_parametro 
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'

select @w_par_imo = pa_char
from   cobis..cl_parametro 
where  pa_producto = 'CCA'
and    pa_nemonico = 'IMO'

select @w_par_mip = pa_char
from   cobis..cl_parametro 
where  pa_producto = 'CCA'
and    pa_nemonico = 'MIPYME'

select @w_par_iva = pa_char
from   cobis..cl_parametro 
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAMIP'



-- CREA TABLA TEMPORAL CON OPERACIONES A VENCER EN LAS FECHAS DADAS
select operaciones = count(distinct op_operacion),
       oficina     = op_oficina,
       oficial     = op_oficial,
       rubro       = am_concepto,
       fecha_fin   = di_fecha_ven,
       saldo       = sum(am_cuota + am_gracia - am_pagado)
into  #tmp_oper
from  cob_cartera..ca_operacion,
      cob_cartera..ca_dividendo,
      cob_cartera..ca_amortizacion
where op_naturaleza  = 'A'  --Para procesar solo operaciones activas
and   op_estado      in (@w_est_vigente, @w_est_vencido, @w_est_suspenso)
and   di_operacion   = op_operacion
and   di_fecha_ven  >= @i_fecha_ini
and   di_fecha_ven  <= @i_fecha_fin
and   am_operacion   = di_operacion
and   am_dividendo   = di_dividendo
group by op_oficina, op_oficial, am_concepto,  di_fecha_ven
order by op_oficina, op_oficial, am_concepto,  di_fecha_ven



-- INSERTA EN TABLA TEMPORAL VALORES DE CAPITAL
insert into rep_prorecpag
select operaciones, oficina, of_nombre, oficial, fu_nombre, fecha_fin, cap = saldo, int = 0, imo = 0, mipymes = 0, ivamipymes = 0, otros = 0, total = 0
 from #tmp_oper, cobis..cl_oficina, cobis..cl_funcionario, cobis..cc_oficial
 where oficina       = of_oficina 
  and oficial        = oc_oficial
  and oc_funcionario = fu_funcionario
  and rubro          = @w_par_cap
 
  
-- SINO EXISTE INSERTA REGISTRO PARA INTERES  
insert into rep_prorecpag
select operaciones, oficina, of_nombre, oficial, fu_nombre, fecha_fin, cap = 0, int = saldo, imo = 0, mipymes = 0, ivamipymes = 0, otros = 0, total = 0
 from #tmp_oper a, cobis..cl_oficina, cobis..cl_funcionario, cobis..cc_oficial
 where oficina       = of_oficina 
  and oficial        = oc_oficial
  and oc_funcionario = fu_funcionario
  and rubro          = @w_par_int
  and not exists (select 1 from rep_prorecpag where tmp_cod_ofi = a.oficina and tmp_cod_funcionario = a.oficial and tmp_fecha_ven = a.fecha_fin)

-- ACTUALIZA SALDO INTERES
update rep_prorecpag
   set tmp_int = saldo
  from #tmp_oper
 where tmp_cod_ofi         = oficina
   and tmp_cod_funcionario = oficial
   and tmp_fecha_ven       = fecha_fin
   and rubro               = @w_par_int


   
-- SINO EXISTE INSERTA REGISTRO PARA MORA
insert into rep_prorecpag
select operaciones, oficina, of_nombre, oficial, fu_nombre, fecha_fin, cap = 0, int = 0, imo = saldo, mipymes = 0, ivamipymes = 0, otros = 0, total = 0
 from #tmp_oper a, cobis..cl_oficina, cobis..cl_funcionario, cobis..cc_oficial
 where oficina       = of_oficina 
  and oficial        = oc_oficial
  and oc_funcionario = fu_funcionario
  and rubro          = @w_par_imo
  and not exists (select 1 from rep_prorecpag where tmp_cod_ofi = a.oficina and tmp_cod_funcionario = a.oficial and tmp_fecha_ven = a.fecha_fin)

-- ACTUALIZA SALDO MORA
update rep_prorecpag
   set tmp_imo     = saldo
  from #tmp_oper
 where tmp_cod_ofi         = oficina
   and tmp_cod_funcionario = oficial
   and tmp_fecha_ven       = fecha_fin
   and rubro               = @w_par_imo

   

-- SINO EXISTE INSERTA REGISTRO PARA MIPYMES
insert into rep_prorecpag
select operaciones, oficina, of_nombre, oficial, fu_nombre, fecha_fin, cap = 0, int = 0, imo = 0, mipymes = saldo, ivamipymes = 0, otros = 0, total = 0
 from #tmp_oper a, cobis..cl_oficina, cobis..cl_funcionario, cobis..cc_oficial
 where oficina       = of_oficina 
  and oficial        = oc_oficial
  and oc_funcionario = fu_funcionario
  and rubro          = @w_par_mip
  and not exists (select 1 from rep_prorecpag where tmp_cod_ofi = a.oficina and tmp_cod_funcionario = a.oficial and tmp_fecha_ven = a.fecha_fin)

  
-- ACTUALIZA SALDO MIPYMES  
update rep_prorecpag
   set tmp_mipymes = saldo
  from #tmp_oper
 where tmp_cod_ofi         = oficina
   and tmp_cod_funcionario = oficial
   and tmp_fecha_ven       = fecha_fin
   and rubro               = @w_par_mip

   

-- SINO EXISTE INSERTA REGISTRO PARA IVAMIPYMES
insert into rep_prorecpag
select operaciones, oficina, of_nombre, oficial, fu_nombre, fecha_fin, cap = 0, int = 0, imo = 0, mipymes = 0, ivamipymes = saldo, otros = 0, total = 0
 from #tmp_oper a, cobis..cl_oficina, cobis..cl_funcionario, cobis..cc_oficial
 where oficina       = of_oficina 
  and oficial        = oc_oficial
  and oc_funcionario = fu_funcionario
  and rubro          = @w_par_iva
  and not exists (select 1 from rep_prorecpag where tmp_cod_ofi = a.oficina and tmp_cod_funcionario = a.oficial and tmp_fecha_ven = a.fecha_fin)


-- ACTUALIZA SALDO IVAMIPYMES    
update rep_prorecpag
   set tmp_ivamipymes = saldo
  from #tmp_oper
 where tmp_cod_ofi         = oficina
   and tmp_cod_funcionario = oficial
   and tmp_fecha_ven       = fecha_fin
   and rubro               = @w_par_iva

   
-- SINO EXISTE INSERTA REGISTRO PARA OTROS    
insert into rep_prorecpag
select operaciones, oficina, of_nombre, oficial, fu_nombre, fecha_fin, cap = 0, int = 0, imo = 0, mipymes = 0, ivamipymes = 0, otros = sum(saldo), total = 0
 from #tmp_oper a, cobis..cl_oficina, cobis..cl_funcionario, cobis..cc_oficial
 where oficina       = of_oficina 
  and oficial        = oc_oficial
  and oc_funcionario = fu_funcionario
  and rubro          not in (@w_par_cap, @w_par_int, @w_par_imo, @w_par_mip, @w_par_iva)
  and not exists (select 1 from rep_prorecpag where tmp_cod_ofi = a.oficina and tmp_cod_funcionario = a.oficial and tmp_fecha_ven = a.fecha_fin)
group by operaciones, oficina, of_nombre, oficial, fu_nombre, fecha_fin


-- ACTUALIZA SALDO OTROS
select oficina, oficial, fecha_fin, otros = sum(saldo)
 into #tmp_oper1
 from #tmp_oper
 where rubro not in (@w_par_cap, @w_par_int, @w_par_imo, @w_par_mip, @w_par_iva)
group by oficina, oficial, fecha_fin

update rep_prorecpag
   set tmp_otros = otros
  from #tmp_oper1
 where tmp_cod_ofi         = oficina
   and tmp_cod_funcionario = oficial
   and tmp_fecha_ven       = fecha_fin

   
-- ACTUALIZA SALDO TOTAL   
update rep_prorecpag
   set tmp_valor_total = tmp_cap + tmp_int + tmp_imo + tmp_mipymes + tmp_ivamipymes + tmp_otros 
where tmp_nro_oper >= 0

     
return 0
go
