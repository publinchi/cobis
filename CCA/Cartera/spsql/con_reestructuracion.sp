/************************************************************************/
/*      Archivo:                con_reajustes.sp                        */
/*      Stored procedure:       sp_consulta_reestructuracion            */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Mayo 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Presenta la relacion de pagos y su afectacion por cuotas        */
/************************************************************************/
/*                     MODIFICACIONES                                   */ 
/*   FECHA            AUTOR                 RAZON                       */ 
/*   22/FEB/2010    Karina Zhamungui      Fecha de reestructuracion     */ 
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_reestructuracion')
   drop proc sp_consulta_reestructuracion
go

create proc sp_consulta_reestructuracion
    @s_user       login     = null,
    @t_trn        smallint  = null,
    @i_fecha      datetime  = null

as
--
--sp_consulta_reestructuracion
--    @i_fecha      = '08/06/2008'



declare @w_sp_name            varchar(32),
        @w_return             int,
        @w_error              int,
        @w_operacionca        int,
        @w_op_banco           cuenta,
        @w_op_migrada         cuenta,
        @w_op_estado          tinyint,
        @w_es_descripcion     descripcion,
        @w_op_nombre          descripcion,
        @w_dtr_monto_mn       money,
        @w_tr_usuario         char(14),
        @w_op_oficial         smallint,
        @w_fu_nombre          descripcion,
        @w_est_vigente        tinyint,
        @w_est_vencido        tinyint,
        @w_est_cancelado      tinyint,
        @w_est_castigado      tinyint,
        @w_est_suspenso       tinyint

/*CREACION DE TABLA TEMPORAL DEFINITIVA */
create table #reestructuraciones
   (
   tmp_op_banco           varchar(24),
   tmp_op_migrada         varchar(24),
   tmp_es_descripcion     varchar(64),
   tmp_estado_despues     varchar(24),
   tmp_op_nombre          varchar(64),
   tmp_dtr_monto_mn       money,
   tmp_tr_usuario         char(14),
   tmp_op_oficial         smallint,
   tmp_fu_nombre          varchar(64),
   tmp_dias_mora          smallint,
   tmp_fec_reestruc       varchar(10) --REQ 00024 KZH 
   )   
        
/* ESTADO DEL DIVIDENDO */
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

/* SELECCION DE LAS OPERACIONES REESTRUCTURADAS */
insert into #reestructuraciones
(tmp_op_banco,     tmp_op_migrada,   tmp_es_descripcion, tmp_estado_despues,
 tmp_op_nombre,    tmp_dtr_monto_mn, tmp_tr_usuario,     tmp_op_oficial,
 tmp_fu_nombre,    tmp_dias_mora,    tmp_fec_reestruc)
select 
    op_banco,
    op_migrada,
    es_descripcion,
    'VIGENTE',
    op_nombre,
    dtr_monto_mn,
    tr_usuario,
    op_oficial,
    '',
     0, --- dias de mora
    convert(varchar(10), tr_fecha_mov, 101)--REQ 00024 KZH 
from ca_operacion,
     ca_estado,
     ca_transaccion,
     ca_det_trn
where op_naturaleza = 'A'
and   op_estado       in (@w_est_vigente,@w_est_vencido,@w_est_cancelado,@w_est_castigado,@w_est_suspenso)
and   op_numero_reest > 0
and   es_codigo       = op_estado
and   tr_operacion    = op_operacion
and   tr_tran         =  'RES'
and   dtr_operacion   = tr_operacion
and   dtr_secuencial  = tr_secuencial
and   tr_fecha_mov   <= @i_fecha

update #reestructuraciones
set tmp_fu_nombre = fu_nombre 
from cobis..cl_funcionario, #reestructuraciones
     where  fu_funcionario = tmp_op_oficial

update #reestructuraciones
set    tmp_dias_mora = dd_total_dias_mora
from #reestructuraciones, cob_palm..ca_detalle_dividendos_pda2
where dd_banco = tmp_op_banco

--if @@rowcount = 0
--begin
--   select @w_error = 601138 --710022
--   goto ERROR
--end

/* LECTURA DE LAS VARIABLES DEL REPORTE Y DEL PLANO */
select 
    tmp_op_banco,
    tmp_op_migrada,
    tmp_es_descripcion,
    tmp_estado_despues,
    tmp_op_nombre,
    tmp_dtr_monto_mn,
    tmp_dias_mora,
    tmp_tr_usuario,
    tmp_op_oficial,
    tmp_fu_nombre,
    tmp_fec_reestruc --REQ 00024 KZH
from #reestructuraciones


-- select * from ca_datos_operaciones
--




return 0
----        
----ERROR:  
----        
----exec cobis..sp_cerror
----   @t_debug = 'N',
----   @t_from  = @w_sp_name,
----   @i_num   = @w_error
        
--return @w_error
        
go
