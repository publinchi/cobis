/************************************************************************/
/*   Archivo:             ca_condonaciones.sp                           */
/*   Stored procedure:    ca_condonaciones_bcp				            */
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
/*   Este programa ejecuta el query de operaciones de cartera           */
/*   llamado por el SP sp_operacion_qry.                                */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR             RAZON                          */
/* 08/Oct/2010         Yecid Martinez    Generar archivo plano de       */
/*                                       Condonaciones			*/
/************************************************************************/  
/*

exec ca_condonaciones_bcp
@i_param1  		= '06/11/2009',
@i_param2  		= 7067
--'F:\VBatch\Cartera\Listados\'

*/
use cob_cartera
go

If exists (select 1 from sysobjects where name = 'ca_condonaciones_bcp')
   drop proc ca_condonaciones_bcp
go
create proc ca_condonaciones_bcp (
@i_param1  		varchar(10), 	-- fecha
@i_param2  		varchar(10) 	-- path destino
)
as
declare   
   @w_sp_name                      varchar(32),
   @w_producto                     tinyint,
   @w_fecha                        datetime,
   @w_error			   int,
   @w_fecha_ini     		   datetime,                                                                                                          
   @w_fecha_fin                    datetime,
   @w_est_condonado                int,
   @w_vlr_cancelar                 money,     
   @w_s_app                        varchar(255),
   @w_path                         varchar(255),
   @w_destino                      varchar(255),
   @w_errores                      varchar(255),
   @w_cmd                          varchar(500),
   @w_comando                      varchar(5000),
   @w_batch                        int

set ansi_warnings off
truncate table bcp_condonaciones_def

select 
@w_fecha = @i_param1,
@w_batch = convert(int,@i_param2)
   
select @w_fecha_ini 	= dateadd(dd,1-datepart(dd,@w_fecha), @w_fecha)                                                                           
select @w_fecha_fin 	= @w_fecha   
select @w_est_condonado = 7                                                                                                 

   
/*  Captura nombre de Stored Procedure  */
select   @w_sp_name = 'ca_condonaciones_bcp'

select @w_producto = pd_producto
from cobis..cl_producto
where pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted


select @w_fecha = convert(varchar(10),fc_fecha_cierre,101)
from cobis..ba_fecha_cierre
where fc_producto = @w_producto
   


--CARGUE DE DATOS                                                                                                                   

select 
cn_fecha        = convert(varchar(10),ab_fecha_pag,111),
cn_cargo        = (select isnull(valor , 'NO EXISTE DESCRIPCION') from cobis..cl_catalogo with (nolock), cobis..cl_funcionario where tabla = 2 and codigo = fu_cargo and fu_login = A.ab_usuario), 
cn_usuario      = ab_usuario, 
cn_rubro        = abd_concepto, 
cn_monto        = abd_monto_mpg, 
cn_porcentaje   = isnull(abd_porcentaje_con,0),
vn_vlr_cancelar = 0,
cn_secuencial   = ab_secuencial_pag, 
cn_operacion    = ab_operacion, 
cn_cosecha      = case when op_estado = 4 then '2008' else null end,
cn_capital      = 0,
cn_banco        = op_banco,
cn_nombre       = op_nombre,
cn_ced_ruc      = (select en_ced_ruc from cobis..cl_ente with (nolock) where en_ente = O.op_cliente),
cn_estado       = es_descripcion,
cn_pago         = 0,
cn_saldo_actual = 0, 
cn_ente         = op_cliente,
cn_tipo         = abd_tipo
into #cr_condonaciones_des
from  cob_cartera..ca_abono A with (index = ca_abono_1, nolock), 
      cob_cartera..ca_abono_det with (nolock), 
      cob_cartera..ca_operacion O with (index=ca_operacion_1, nolock) , 
      cob_cartera..ca_estado with (nolock)
where ab_operacion = abd_operacion
and   ab_secuencial_ing = abd_secuencial_ing
and   ab_estado = 'A'
and   ab_fecha_pag >= @w_fecha_ini
and   ab_fecha_pag <= @w_fecha_fin
and   ab_operacion = op_operacion
and   op_estado    = es_codigo

delete  #cr_condonaciones_des
where   cn_tipo <> 'CON'

select 
dif_concepto       = dtr_concepto,
dif_operacion      = dtr_operacion, 
dif_vlr_cancelar   = isnull(sum(dtr_monto),0)
into  #Dif_condonados
from  cob_cartera..ca_det_trn with (index = ca_det_trn_1, nolock), 
      #cr_condonaciones_des
where cn_operacion    = dtr_operacion
and   cn_secuencial   = dtr_secuencial
and   cn_rubro        = dtr_concepto
and   dtr_estado      <> @w_est_condonado
group by dtr_concepto, dtr_operacion


select con_concepto = dtr_concepto, con_operacion  = dtr_operacion , con_vlr_cancelar = isnull(sum(dtr_monto),0)
into #Son_condonados
from cob_cartera..ca_det_trn with (index = ca_det_trn_1, nolock), #cr_condonaciones_des
where cn_operacion = dtr_operacion
and cn_secuencial = dtr_secuencial
and cn_rubro = dtr_concepto
and dtr_estado = @w_est_condonado
group by dtr_concepto, dtr_operacion

update #cr_condonaciones_des
set vn_vlr_cancelar = dif_vlr_cancelar - con_vlr_cancelar
from cob_cartera..ca_det_trn  with (index = ca_det_trn_1, nolock), #Dif_condonados, #Son_condonados
where cn_operacion = dtr_operacion
and cn_secuencial = dtr_secuencial
and cn_rubro = dtr_concepto
and cn_operacion = con_operacion
and con_operacion = dif_operacion
and con_concepto = dtr_concepto
and dif_concepto = dtr_concepto


/* DETERMINAR A¢O DE CASTIGO (COSECHAS)*/
update #cr_condonaciones_des set
cn_cosecha = datepart(yy,tr_fecha_ref)
from cob_cartera..ca_transaccion with (nolock)
where tr_operacion = cn_operacion
and   tr_tran      = 'CAS'
and   tr_estado   != 'RV'

/* SALDO DE CAPITAL */
select banco = do_banco, fecha = max(do_fecha)
into #fechas
from cob_conta_super..sb_dato_operacion with (nolock), #cr_condonaciones_des 
where cn_banco = do_banco
and   do_fecha < @w_fecha_ini
and   do_aplicativo = 7
and   do_saldo_cap > 0
group by do_banco


update #cr_condonaciones_des set
cn_capital = do_saldo_cap
from cob_conta_super..sb_dato_operacion with (nolock), #fechas
where cn_banco = banco
and   do_banco = banco
and   do_fecha = fecha
and   do_aplicativo = 7

update #cr_condonaciones_des set
cn_saldo_actual = do_saldo_cap
from cob_conta_super..sb_dato_operacion with (nolock)
where do_banco = cn_banco
and   do_fecha = @w_fecha_fin
and   do_aplicativo = 7

select concepto = cn_rubro, banco = cn_banco , pag_operacion = cn_operacion , monto=sum(cn_pago) 
into #pago_det 
from #cr_condonaciones_des
group by cn_rubro, cn_banco, cn_operacion

select distinct operacion = pag_operacion , secuencial_pag = ab_secuencial_pag
into #abonos
from cob_cartera..ca_abono with (index = ca_abono_1, nolock), cob_cartera..ca_abono_det with (index = ca_abono_det_1, nolock), #pago_det 
where ab_operacion = pag_operacion
and   abd_operacion  = ab_operacion
and   abd_secuencial_ing  = ab_secuencial_ing
and   (abd_tipo != 'CON' and  abd_concepto not in ( 'RENOVACION', 'SALDOSMINI' , 'SOBRANTE' ) )
and   ab_fecha_pag between @w_fecha_ini and @w_fecha_fin
and   ab_estado = 'A'

select dtr_estado , concepto = dtr_concepto, banco = tr_banco, pagos = sum(dtr_monto)
into #pagos
from cob_cartera..ca_det_trn with (index = ca_det_trn_1, nolock), #abonos,
      #pago_det ,  cob_cartera..ca_transaccion with (nolock)
where banco = tr_banco
and   operacion      = pag_operacion 
and   tr_operacion   = pag_operacion 
and   tr_secuencial  = secuencial_pag
and   dtr_operacion  = tr_operacion
and   dtr_secuencial = tr_secuencial
and   dtr_concepto   = concepto 
and   dtr_estado != 7
and   tr_estado != 'RV'
group by dtr_estado , dtr_concepto, tr_banco

update #cr_condonaciones_des set
cn_pago = pagos
from #pagos
where cn_banco = banco
and cn_rubro = concepto 

--insert into cr_condonaciones_tmp
--(cn_fecha, cn_cargo, cn_usuario, cn_rubro, cn_monto, cn_porcentaje, vn_vlr_cancelar, cn_cosecha, cn_capital, cn_banco, cn_nombre, cn_ced_ruc, cn_estado )

select 
OBLIGACION        = cn_banco,
FECHA             = cn_fecha, 
NOMBRE            = cn_nombre,
CEDULA            = cn_ced_ruc,
USUARIO           = cn_usuario, 
ITEM              = cn_rubro, 
VALOR_CONDONACION = cn_monto,
PORCENTAJE        = cn_porcentaje,
CAPITAL_INI_PER   = convert(varchar,round(cn_capital     ,2)),
ESTADO            = cn_estado,
CARGO             = cn_cargo,
PAGOS             = cn_pago ,
SALDO_DESP_CON    = case when abs(cn_monto + cn_pago - cn_capital) <= 2 then 0 
                         --when cn_pago = 0                               then 0 
                         else cn_saldo_actual end
into #resumen
from #cr_condonaciones_des

insert into bcp_condonaciones_def
select
OBLIGACION        ,
FECHA             , 
NOMBRE            ,
CEDULA            ,
USUARIO           , 
ITEM              , 
VALOR_CONDONACION = convert(varchar,round(sum(VALOR_CONDONACION),2)), 
PORCENTAJE = convert(varchar,round(sum(PORCENTAJE),0)) + '%', 
CAPITAL_INI_PER   ,
ESTADO            ,
CARGO             ,
PAGOS             ,
SALDO_DESP_CON    
from #resumen
group by OBLIGACION , FECHA , NOMBRE , CEDULA , USUARIO , ITEM , CAPITAL_INI_PER  , ESTADO , CARGO , PAGOS , SALDO_DESP_CON


--  GENRAMOS BCP

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

select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..bcp_condonaciones_def out '

select @w_destino  = @w_path + 'ca_condonaciones_bcp_' + replace(convert(varchar, @w_fecha, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.txt',
       @w_errores  = @w_path + 'ca_condonaciones_bcp_' + replace(convert(varchar, @w_fecha, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.err'

select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"!" ' + '-config '+ @w_s_app + 's_app.ini'


print 'CONDOANCIONES @w_comando ' + cast(@w_comando as varchar)


exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando Archivo ca_condonaciones_bcp'
   print @w_comando
   return 1
end


return 0


ERROR:
   exec cobis..sp_cerror
   @t_debug = 'N',    
   @t_file  = null,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error

   return @w_error

go