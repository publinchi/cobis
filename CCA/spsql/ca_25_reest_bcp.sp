/************************************************************************/
/*   Archivo:             ca_25_reest_bcp.sp                               */
/*   Stored procedure:    ca_25_reest_bcp				*/
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Y. Martinez                                   */
/*   Fecha de escritura:  10/08/2010                                    */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                           PROPOSITO                                  */  
/*   Este programa genera BCP segun informacion de 25_reest.		*/
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR             RAZON                          */
/* 08/Oct/2010         Yecid Martinez    Generar archivo plano de       */
/*                                       25_reest			*/
/************************************************************************/  
/*

exec ca_25_reest_bcp
@i_param1  		= '10/31/2009',
@i_param2  		= 7067
--'F:\VBatch\Cartera\Listados\'

*/
use cob_cartera
go


set ANSI_NULLS ON
go

set ANSI_WARNINGS  ON
go


if exists (select 1 from sysobjects where name = 'ca_25_reest_bcp')
   drop proc ca_25_reest_bcp
go
create proc ca_25_reest_bcp (
@i_param1  		varchar(10), 	-- fecha
@i_param2  		varchar(10) 	-- batch
)
as
declare   
   @w_sp_name                     varchar(32),
   @w_producto                    tinyint,
   @w_fecha                       datetime,
   @w_error                       int,
   @w_fecha_ini                   datetime,                                                                                                          
   @w_fecha_fin                   datetime,
   @w_est_condonado               int,
   @w_vlr_cancelar                money,     
   @w_s_app                       varchar(255),
   @w_path                        varchar(255),
   @w_destino                     varchar(255),
   @w_errores                     varchar(255),
   @w_cmd                         varchar(500),
   @w_comando                     varchar(5000),
   @w_batch                       int,
   @w_servidor_his                varchar(20),
   @w_hora_arch                   varchar(4)


   truncate table bcp_25_reest

   create table #hi_reest(
   sec_hi            int        null,
   operacion_hi      int        null,
   fecha_fin_hi      datetime   null,
   tasa_hi           float      null)

select 
@w_fecha         = @i_param1,
@w_batch         = convert(int,@i_param2),
@w_est_condonado = 7                                                                                                 

select   @w_sp_name = 'ca_25_reest_bcp'

select @w_producto = pd_producto
from cobis..cl_producto
where pd_abreviatura = 'CCA'

set transaction isolation level read uncommitted

-- servidor de historicos

select @w_servidor_his = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'SRVHIS'

-- Restructuraciones

print 'reestructuracion getdate ' + convert (varchar(20), getdate() ,109)

select tr_secuencial, tr_operacion, tr_banco, tr_fecha_ref
into #transacciones
from cob_cartera..ca_transaccion with (nolock)
where tr_fecha_mov <= @w_fecha
and   tr_tran       = 'RES'
and   tr_estado     <> 'RV'

create index idx1 on #transacciones(tr_secuencial, tr_operacion)

select 
sec       = tr_secuencial, 
operacion = tr_operacion, 
banco     = tr_banco, 
fecha_res = tr_fecha_ref, 
monto_res = dtr_monto
into #reest
from #transacciones with (nolock), cob_cartera..ca_det_trn with (nolock)
where tr_operacion  = dtr_operacion
and   tr_secuencial = dtr_secuencial
order by dtr_monto DESC
set rowcount 0

print 'operacion getdate ' + convert (varchar(20), getdate() ,109)


-- Operacion

select 
operacion_op = operacion,
cliente      = op_cliente, 
monto_ini    = op_monto, 
nombre       = op_nombre,  
fecha_ini    = op_fecha_ini,
fecha_fin    = op_fecha_fin,
gracia       = 0,
tasa         = ro_porcentaje,
clase        = op_clase,
tramite      = op_tramite,
identifica   = en_ced_ruc
into #op_reest
from #reest, cob_cartera..ca_operacion with (nolock), cob_cartera..ca_rubro_op with (nolock), cobis..cl_ente with (nolock)
where operacion   = op_operacion
and   operacion   = ro_operacion
and   ro_concepto = 'INT'
and   op_cliente  = en_ente


print ' historicos getdate ' + convert (varchar(20), getdate() ,109)

-- Historicos

print '@w_servidor_his ' + @w_servidor_his 

if @w_servidor_his <> 'NOHIST' begin


   SET  @w_comando = 'insert into #hi_reest
   select 
   sec_hi = sec,
   operacion_hi = operacion,
   fecha_fin_hi = oph_fecha_fin,
   tasa_hi      = roh_porcentaje
   from #reest, cob_cartera..ca_operacion_his with (nolock), ' + @w_servidor_his +
   '.cob_cartera.dbo.ca_rubro_op_his
   where operacion    = oph_operacion
   and   operacion    = roh_operacion
   and   roh_concepto = ''INT''
   and   sec          = oph_secuencial
   and   sec          = roh_secuencial'

   EXEC (@w_comando)

end


print 'provisones getdate ' + convert (varchar(20), getdate() ,109)

-- Provisiones
select 
operacion_fe  = operacion,
fecha_prov_fe = max(do_fecha)
into #fe_reest
from #reest, cob_conta_super..sb_dato_operacion
where do_banco      = banco
and   do_aplicativo = @w_producto 
group by operacion

select 
operacion_pr  = operacion,
calificacion  = do_calificacion,
dias_mora     = do_edad_mora,
provision     = sum(do_prov_cap + do_prov_int),
provision_con = sum(do_prov_con_cap + do_prov_con_int),
vlr_garantia  = sum(do_valor_garantias)
into #pr_reest
from #reest, #fe_reest, cob_conta_super..sb_dato_operacion with (index = idx1)
where banco         = do_banco
and   operacion     = operacion_fe
and   do_fecha      = fecha_prov_fe 
and   do_aplicativo = @w_producto 
group by operacion, do_calificacion, do_edad_mora


print 'garantias getdate ' + convert (varchar(20), getdate() ,109)


-- Garantias

select 
operacion_gafe  = operacion,
fecha_prov_gafe = max(dg_fecha)
into #gafe_reest
from #reest, cob_conta_super..sb_dato_garantia
where dg_banco = banco
--and   dg_aplicativo = @w_producto 
group by operacion

select 
operacion_ga  = operacion,
tipo_ga       = dg_garantia,
descripcion   = tc_descripcion,
banco_ga      = banco
into #ga_reest
from #reest, #gafe_reest, cob_conta_super..sb_dato_garantia, cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia
where banco             = dg_banco
and   cu_codigo_externo = dg_garantia
and   cu_tipo           = tc_tipo
and   operacion_gafe    = operacion
and   fecha_prov_gafe   = dg_fecha



print 'insert bcp_25_rees getdate ' + convert (varchar(20), getdate() ,109)


truncate table bcp_25_reest

insert into bcp_25_reest
select distinct 
banco          = banco, 
identifica     = identifica, 
nombre         = nombre, 
fecha_ini      = convert(varchar(10),fecha_ini,101), 
fecha_ifin     = convert(varchar(10),fecha_fin_hi,101), 
gracia         = gracia, 
tasa_hi        = tasa_hi, 
monto_ini      = monto_ini, 
monto_res      = monto_res, 
fecha_res      = convert(varchar(10),fecha_res,101), 
tasa           = tasa, 
vlr_garantia   = vlr_garantia,
calificacion   = calificacion, 
dias_mora      = dias_mora, 
provision      = provision, 
provision_con  = provision_con,
tipo 			     ='CREDITO ORDINARIO', 
clase 			   = clase, 
descripcion    = descripcion
from #reest
left outer join #ga_reest
on    operacion = operacion_ga
inner join #hi_reest on
   operacion = operacion_hi
inner join #pr_reest on
   operacion = operacion_pr
inner join #op_reest on
   operacion = operacion_op



--  GENRAMOS BCP

print 'BCP getdate ' + convert (varchar(20), getdate() ,109)

----------------------------------------
--Generar Archivo Plano
----------------------------------------
select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = @w_batch

select @w_hora_arch     = substring(convert(varchar,GetDate(),108),1,2) + substring(convert(varchar,GetDate(),108),4,2)



select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..bcp_25_reest out '

select @w_destino  = @w_path + 'ca_25_reest_bcp_' + replace(convert(varchar, @w_fecha, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.txt',
       @w_errores  = @w_path + 'ca_25_reest_bcp_' + replace(convert(varchar, @w_fecha, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.err'

select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"!" ' + '-config '+ @w_s_app + 's_app.ini'


print 'bcp_25_reest @w_comando ' + cast(@w_comando as varchar)

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error generando Archivo ca_25_reest_bcp'
   print @w_comando
   return 1
end

print 'FIN  getdate ' + convert (varchar(20), getdate() ,109)

return 0


ERROR:
   exec cobis..sp_cerror
   @t_debug = 'N',    
   @t_file  = null,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error

   return @w_error

go