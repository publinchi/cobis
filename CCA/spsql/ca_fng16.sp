/************************************************************************/
/*      Archivo:                ca_fng16.sp                             */
/*      Stored procedure:       sp_fng_16_cca                           */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez Burbano                   */
/*      Fecha de escritura:     Abr 2012                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera un plano de Las obligaciones que en un rango de fechas   */
/*      hasn tenido RES o CAmbio de fecha y tiene garantia              */
/************************************************************************/

use cob_cartera
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'sp_fng_16_cca')
   drop proc sp_fng_16_cca
go

---MAY.28.2012 INC. 62448

create proc sp_fng_16_cca
   @i_param1  varchar(10),  --fecha desde
   @i_param2  varchar(10)  --fecha hasta

as

declare 
@w_sp_name            varchar(32),
@w_error              int,
@w_s_app              varchar(250),
@w_cmd                varchar(250),
@w_path               varchar(250),
@w_comando            varchar(500),
@w_batch              int,
@w_errores            varchar(255),
@w_destino            varchar(255),
@w_dia                varchar(2),
@w_mes                varchar(2),
@w_anio               varchar(4),
@w_fecha_plano        varchar(8),
@w_fecha_cca          datetime,
@w_fecha_desde        datetime,
@w_fecha_hasta        datetime,
@w_reg_fng16          int,
@w_campo1             varchar(11),
@w_campo2             varchar(2),
@w_campo3             varchar(10),
@w_gar_fng            catalogo,
@w_dias               int


--Parametros generales
select @w_gar_fng  = pa_char
from   cobis..cl_parametro
where  pa_producto = 'GAR'
and    pa_nemonico = 'CODFNG'
set transaction isolation level read uncommitted

select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


truncate table  ca_fng_16_tmp
	
--PARAMETRO  DE ENTRADA
select 
@w_fecha_desde = @i_param1, ----fecha parametro1
@w_fecha_hasta  = @i_param2 ----fecha parametro2

---Segun el usuario solicita que del rango digitado se saque el ultimo cambio
---para esto es necesario que elrango de fechas sea unocamente  un mes para no 
---dejar de sacar cambiosque si son validos por estar en diference mes.
---Cometario del usuario Ipuesto en la INC. 62448

select @w_dias = datediff(dd,@w_fecha_desde,@w_fecha_hasta)

if @w_dias > 35
begin
 PRINT 'ATENCION!!! Digitar un rango de fechas no superior a 35 dias ' + cast(@w_fecha_desde as varchar) + 'Hasta: ' + cast (@w_fecha_hasta as varchar)
 goto ERROR
end

---sacar Informacion para el plano
select tr_operacion,tr_secuencial,tr_tran,op_oficina,op_plazo,op_tramite,tr_banco
into #oper_fng_16
 from ca_transaccion with (nolock),ca_operacion with (nolock), ca_estado
where tr_tran = 'RES'
and tr_fecha_mov between @w_fecha_desde and @w_fecha_hasta
and tr_estado <> 'RV'
and tr_secuencial >= 0
and tr_operacion = op_operacion
and op_estado = es_codigo
and es_procesa = 'S'
union
select tr_operacion,tr_secuencial,tr_tran,op_oficina,op_plazo,op_tramite,tr_banco
from ca_transaccion with (nolock),ca_operacion with (nolock),ca_estado
where tr_tran = 'MAN'
and tr_fecha_mov between @w_fecha_desde and @w_fecha_hasta
and tr_estado <> 'RV'
and tr_secuencial >= 0
and tr_observacion like '%CAMBIO FECHA%'
and tr_operacion = op_operacion
and op_estado = es_codigo
and es_procesa = 'S'

select @w_reg_fng16 = count(1) 
from  #oper_fng_16

if @w_reg_fng16 = 0
begin
 PRINT 'ATENCION!!! no hay operaciones para las fechas digitadas inicio ' + cast(@w_fecha_desde as varchar) + 'Hasta: ' + cast (@w_fecha_hasta as varchar)
 goto ERROR
end

---seleccionar  las Duplicadas
select tr_oper = tr_operacion,'total'=count(1)
into #repetidas
 from  #oper_fng_16
group by tr_operacion
having count(1) > 1

----select * from #repetidas

select 'oper'  = tr_operacion,
       'sec'   = max(tr_secuencial)
into #maximoSec
 from ca_transaccion,
      #repetidas
where tr_oper = tr_operacion
and tr_tran  = 'MAN'
and tr_fecha_mov between @w_fecha_desde and @w_fecha_hasta
and tr_estado <> 'RV'
and tr_secuencial >= 0
and tr_observacion like '%CAMBIO FECHA%'
group by tr_operacion

---select * from #maximoSec

delete #oper_fng_16
from #oper_fng_16,
     #maximoSec
where tr_operacion = oper
and tr_secuencial <> sec

---poner la oficina que hizo el desembolso
---segun loindicado por Adrian CASTRO el 28.mayo.correo

select ofi_desembolso = T.tr_ofi_usu,
       oper           = T.tr_operacion
into #operDes
from ca_transaccion T with (nolock),
     #oper_fng_16 F
where  T.tr_operacion = F.tr_operacion
and    T.tr_tran = 'DES'
and    T.tr_estado <> 'RV'
and    T.tr_secuencial > =0

update #oper_fng_16
set op_oficina = ofi_desembolso
from #operDes,#oper_fng_16
where oper = tr_operacion

---poner la garantia

select tr_operacion,tr_secuencial,tr_tran,op_oficina,op_plazo,op_tramite,tr_banco,cu_num_dcto
into #con_FNG
from #oper_fng_16,
     cob_credito..cr_gar_propuesta,
     cob_custodia..cu_custodia,
     cob_custodia..cu_tipo_custodia
where gp_tramite = op_tramite
and  gp_garantia = cu_codigo_externo
and   cu_tipo           = tc_tipo
and   tc_tipo_superior  = @w_gar_fng  

--- GENERAR LOS ARCHIVOS PLANOS POR BCP
select @w_dia  = convert(varchar(2), datepart (dd, @w_fecha_cca))
select @w_mes  = convert(varchar(2), datepart (mm, @w_fecha_cca))
select @w_anio = convert(varchar(4), datepart (yy, @w_fecha_cca))

--select @w_dia = CASE WHEN convert(int, @w_dia) < 10 then '0' + @w_dia else @w_dia end
if convert(int, @w_dia) < 10
   select @w_dia = '0' + @w_dia
else
   select @w_dia = @w_dia

--select @w_mes = CASE WHEN convert(int, @w_mes) < 10 then '0' + @w_mes else @w_mes end
if convert(int, @w_mes) < 10
   select @w_mes = '0' + @w_mes
else
   select @w_mes = @w_mes
   
select @w_fecha_plano = convert(varchar(2), @w_dia) + convert(varchar(2), @w_mes)+ convert(varchar(4), @w_anio)

select @w_campo1 = 'PRO' + @w_fecha_plano,
       @w_campo2 = '31',
       @w_campo3 = '9002150711'

       
---select * from #con_FNG
       
insert into ca_fng_16_tmp
select @w_campo1,@w_campo2,@w_campo3,'SBA52'+convert(varchar(5),op_oficina),cu_num_dcto,'','','','',op_plazo,'3','','','','','','','','','','','','','','','','','','','','','','','',''
from #con_FNG

---select * from ca_fng_16_tmp

select @w_path = ba_path_destino 
from cobis..ba_batch 
where ba_arch_fuente = 'cob_cartera..sp_fng_16_cca'

if @@rowcount = 0 begin
   print  'ERROR no se encuentra el sp en la tabla ba_batch'
   goto ERROR
end
PRINT 'ba_path_destino : ' + cast(@w_path as varchar)
select @w_s_app = pa_char 
from cobis..cl_parametro 
where pa_producto = 'ADM' 
and pa_nemonico = 'S_APP'

PRINT 'Inicio plano ca_fng_16_tmp'
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_fng_16_tmp out '
select @w_destino  = @w_path + 'ca_fng_16' + '_' + @w_fecha_plano + '.txt',
       @w_errores  = @w_path + 'ca_fng_16' + '_' + @w_fecha_plano + '.err'
select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e ' + @w_errores + ' -t";" ' + '-config '+ @w_s_app + 's_app.ini'

exec   @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error Generando archivo plano de  ca_fng_16_tmp'
   print @w_comando 
   return 1
end


ERROR:

return 0
   
go



