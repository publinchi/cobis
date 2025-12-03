/*calif_int.sp***********************************************************/
/*      Archivo:                calif_int.sp                            */
/*      Stored procedure:       sp_califica_interna                     */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabi n de la Torre                      */
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
/*      Realiza la calificacion interna de las operaciones de 1 a 5     */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_califica_interna')
   drop proc sp_califica_interna
go

create proc sp_califica_interna
@s_user     login   = 'OPERADOR',
@i_en_linea char(1) = 'N'

as

declare 
@w_error             int,
@w_estado            int,
@w_est_vigente       int,
@w_msg               varchar(100),
@w_commit            char(1),
@w_sp_name           varchar(30),
@w_est_vencido       tinyint,
@w_est_cancelado     tinyint,
@w_tipo_calif        catalogo,
@w_tipo_calif_ant    catalogo,
@w_desde             int,
@w_hasta             int,
@w_nota              smallint,
@w_fecha_proceso     datetime,
@w_max_dias_mora     tinyint


/* INICIAR VARIABLES DE TRABAJO */
select
@w_commit        = 'N',
@w_sp_name       = 'sp_califica_interna',
@w_est_vencido   = 2,
@w_est_cancelado = 3

/* DETERMINA LA FECHA DE PROCESO */
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

/* CANTIDAD MAXIMA DE DIAS MORA POR CUOTA */ 
select @w_max_dias_mora = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'MAXDMO'
and   pa_producto = 'CRE'

/* GENERAR RANGOS DE CALIFICACION DESDE LA PARAMETRIA BASE EN CREDITO */
select 
@w_nota           = 0, 
@w_desde          = 0,
@w_tipo_calif     = '',
@w_tipo_calif_ant = ''

create table #calificaciones(
tipo_calif  varchar(10) not null,
desde       int         not null,
hasta       int         not null,
nota        smallint    not null)

while 1=1 begin

   set rowcount 1

   select 
      @w_tipo_calif = ci_tipo_calif,
      @w_hasta      = ci_dias_hasta,
      @w_nota       = ci_nota
   from cob_credito..cr_califica_interna
   where ci_estado     = 'V'
   and  (ci_tipo_calif > @w_tipo_calif or (ci_tipo_calif = @w_tipo_calif and ci_nota < @w_nota))
   order by ci_tipo_calif, ci_nota desc

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   if @w_tipo_calif <> @w_tipo_calif_ant begin
      select 
      @w_desde          = 0,
      @w_tipo_calif_ant = @w_tipo_calif
   end

   insert into #calificaciones values(
   @w_tipo_calif, @w_desde, @w_hasta, @w_nota)      

   select @w_desde = @w_hasta -- + 1

end


/* DETERMINAR EL UNIVERSO DE OPERACIONES A CALIFICAR */
select
toperacion = op_toperacion,
moneda     = op_moneda,
cliente    = op_cliente,
banco      = op_banco,
operacion  = op_operacion,
fecha      = op_fecha_ult_proceso,
tipo_calif = convert(char(10), 'U'),       -- GAL 01MAY2009 - EF-CRE-024 - TIPO DE CALIFICACION DEFAULT
tramite    = op_tramite,                   -- GAL 01MAY2009 - EF-CRE-024 - TRAMITE REQUERIDO PARA ACTUALIZAR TIPO DE CALIFICACION
reestruct  = op_numero_reest               -- GAL 31JUL2009 - INTERV-CASO-284
into #oper_paso1
from ca_operacion, ca_estado
where op_estado  = es_codigo
and   es_procesa = 'S'

if @@error <> 0 begin
   select 
   @w_error = 710001,
   @w_msg   = 'ERROR AL DETERMINAR EL UNIVERSO DE OPERACIONES A CALIFICAR'
   goto ERROR
end

--create index #oper_paso1_1 on #oper_paso1(banco)
--create index #oper_paso1_2 on #oper_paso1(reestruct) include (operacion)
create index oper_paso1_1 on #oper_paso1(banco)
create index oper_paso1_2 on #oper_paso1(reestruct) include (operacion)


/* LIMPIEZA DE OPERACIONES ACTIVAS DE LA TABLA DE CALIFICACION INTERNA */
delete cob_credito..cr_califica_int_mod
from #oper_paso1
where ci_banco = banco

if @@error <> 0 begin
   select 
   @w_error = 710003,
   @w_msg   = 'ERROR AL LIMPIAR LA CALIFICACION INTERNA DE OPERACIONES ACTIVAS'
   goto ERROR
end


update #oper_paso1 set                    -- GAL 01MAY2009 - EF-CRE-024 - TIPO DE CALIFICACION SE DETERMINA EN EL TRAMITE
   tipo_calif = tr_mercado
from cob_credito..cr_tramite
where tr_tramite  = tramite
and   tr_mercado in (select distinct ci_tipo_calif 
                     from cob_credito..cr_califica_interna
                     where ci_tipo_calif <> 'U'           )

if @@error <> 0 begin
   select 
   @w_error = 710002,
   @w_msg   = 'ERROR AL DETERMINAR EL TIPO DE CALIFICACION INTERNA'
   goto ERROR
end


/* DETERMINACION DEL DIVIDENDO DESDE EL CUAL SE REALIZO LA ULTIMA REESTRUCTURACION 
select operacion, div_reestr = max(di_dividendo)
into #reest
from #oper_paso1, ca_transaccion, ca_dividendo
where reestruct         >= 1
and   tr_operacion       = operacion
and   tr_tran            = 'RES'
and   tr_estado         <> 'RV' 
and   di_operacion       = tr_operacion
and   tr_fecha_ref between di_fecha_ini and di_fecha_ven
group by operacion

if @@error <> 0 begin
   select 
   @w_error = 710001,
   @w_msg   = 'ERROR AL CREAR TABLA TEMPORAL DE REESTRUCTURADOS'
   goto ERROR
end

create index #reest_1 on #reest(operacion) include (div_reestr)
*/

/* DETERMINAR LOS DIAS DE VENCIMIENTO DE LAS CUOTAS */

--Temporal para los Dividendos y calificacion manual
select ca_dividendo.*
into #dividendo
from ca_dividendo, #oper_paso1
where di_operacion = operacion

create index div1 on #dividendo(di_operacion, di_estado, di_dividendo)

update #dividendo set
di_fecha_can = di_fecha_ven
from ca_operacion, cob_credito..cr_califica_int_manual
where op_banco     = cim_banco
and   op_operacion = di_operacion
and   di_estado    in (@w_est_vencido, @w_est_cancelado)
and   di_fecha_ven between '10/01/2008' and '11/30/2008'


update #dividendo set
   di_fecha_can = fecha
from #dividendo, #oper_paso1
where di_operacion = operacion
and di_fecha_can = '01/01/1900'
and   di_estado in (@w_est_vencido, @w_est_cancelado)


select
toperacion,  moneda,  cliente,
banco,       fecha,   tipo_calif,
dias_mora_cuota_prom = sum(case when datediff(dd, di_fecha_ven, isnull(di_fecha_can, fecha)) > 0  then datediff(dd, di_fecha_ven, isnull(di_fecha_can, fecha)) else 0 end) / convert(float,count(1)),
dias_mora_cuota_max  = max(case when datediff(dd, di_fecha_ven, isnull(di_fecha_can, fecha)) > 0  then datediff(dd, di_fecha_ven, isnull(di_fecha_can, fecha)) else 0 end)
into #oper_paso2
from #oper_paso1 O, #dividendo
where di_operacion  = operacion
and   di_estado    in (@w_est_vencido, @w_est_cancelado)
and   di_dividendo >= 1 --isnull((select div_reestr from #reest where operacion = O.operacion), 1)
group by toperacion, moneda, cliente, banco, fecha, tipo_calif

if @@error <> 0 begin
   select 
   @w_error = 710001,
   @w_msg   = 'ERROR AL DETERMINAR LOS DIAS PROMERDIO DE VENCIMIENTO DE LAS CUOTAS ANTES DE SER CANCELADAS'
   goto ERROR
end


/* CALIFICAR Y REPORTAR LAS CALIFICACIONES OBTENIDAS EN CREDITO */
insert into cob_credito..cr_califica_int_mod(
ci_producto,   ci_toperacion, ci_moneda,     
ci_cliente,    ci_banco,      ci_fecha,      
ci_nota)
select
7,             toperacion,    moneda,
cliente,       banco,         fecha,
case                                                            
   when dias_mora_cuota_max >= @w_max_dias_mora then       -- SI LA CANTIDAD DE DIAS MORA DE ALGUNA CUOTA 
      1                                                    -- SUPERA O IGUALA EL VALOR DEL PARAMETRO LA NOTA ES 1 (EF-CRE-024)
   else 
      nota
end
from #oper_paso2 a, #calificaciones b
where a.tipo_calif               = b.tipo_calif
--and   dias_mora_cuota_prom between desde and hasta
and   dias_mora_cuota_prom > desde and dias_mora_cuota_prom <= hasta

if @@error <> 0 begin
   select 
   @w_error = 710001,
   @w_msg   = 'ERROR AL REGISTRAR LAS CALIFICACIONES OBTENIDAS EN CREDITO'
   goto ERROR
end

/* OPERACIONES ACTIVAS SIN DIVIDENDOS VENCIDOS NI CANCELADOS */
/* TIENEN POR DEFAULT UNA CALIFICACION DE 5 */

insert into cob_credito..cr_califica_int_mod(
ci_producto,   ci_toperacion, ci_moneda,     
ci_cliente,    ci_banco,      ci_fecha,      
ci_nota)
select
7,             toperacion,    moneda,
cliente,       banco,         fecha,
5
from #oper_paso1 O
where not exists (select 1 from cob_credito..cr_califica_int_mod
                  where ci_banco = O.banco)

if @@error <> 0 begin
   select 
   @w_error = 710001,
   @w_msg   = 'ERROR AL REGISTRAR LAS CALIFICACIONES DEFAULT'
   goto ERROR
end


return 0

ERROR:

if @w_commit = 'S' rollback tran

if @w_msg is null begin
   select @w_msg = mensaje
   from cobis..cl_errores
   where numero = @w_error
end

if @i_en_linea = 'S' 
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg
else
   exec sp_errorlog 
   @i_fecha       = @w_fecha_proceso,
   @i_error       = @w_error, 
   @i_usuario     = @s_user, 
   @i_tran        = 7999,
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = '',
   @i_descripcion = @w_msg,
   @i_rollback    = 'S'

   
return @w_error

go
