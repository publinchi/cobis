/* ********************************************************************* */
/*   ARCHIVO:         lcr_msg_inc.sp                                     */
/*   NOMBRE LOGICO:   sp_lcr_gen_msg_incremento                          */
/*   Base de datos:   cob_cartera                                        */
/*   PRODUCTO:        Cartera                                            */
/*   Fecha de escritura:   Diciembre 2018                                */
/* ********************************************************************* */
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante legal.            */
/* ********************************************************************* */
/*                     PROPOSITO                                         */
/*  Determina las lineas de Credito que son acreedoras a un incremento   */
/*  de cupo y genera para todos ellos el mensaje solicitando al cliente  */
/*  su aprobacion a traves del centro de mensajes de la B2C.             */
/*  Este proceso esta diseñado para ejecutarse en la sarta 22            */
/* ********************************************************************* */
/*                             MODIFICACION                              */
/*    FECHA                 AUTOR                 RAZON                  */
/*    27/Dic/2018           TBA                   Emisión Inicial        */
/* ********************************************************************* */

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_lcr_gen_msg_incremento')
    drop proc sp_lcr_gen_msg_incremento
go
create proc sp_lcr_gen_msg_incremento (
    @i_param1           datetime   = null --FECHA PROCESO
)as
declare
@w_sp_name            varchar(20),
@w_fecha_corte        datetime,
@w_banco              cuenta,
@w_cliente            int,
@w_cupo               money,
@w_error              int,
@s_ssn                int,
@s_user               login,
@s_srv                varchar(24),
@s_term               varchar(24),
@s_rol                int,
@s_lsrv               varchar(24),
@s_sesn               int,
@s_ofi                int,
@s_date               datetime,
@w_incremento         money,
@w_id_inst_proceso    int,
@w_limite_inc         money,
@w_diferencia         money,
@w_commit             char(1),
@w_msg                varchar(200),
@w_fecha_proceso      datetime,
@w_num_cortes_evaluar int, 
@w_ultimo_div         int,
@w_cumple             char(1),
@w_ciudad_nacional    int,
@w_dividendo          int,
@w_fecha_ini          datetime,
@w_fecha_fin          datetime,
@w_operacionca        int,
@w_procede            varchar(10),
@w_monto              money,
@w_fecha              datetime,
@w_cortes_evaluar     int

select @w_sp_name = 'sp_lcr_gen_msg_incremento'

--INICIALIZACION DE VARIABLES
select
@s_ssn      = convert(int,rand()*10000),
@s_user     = 'usrbatch',
@s_srv      = 'CTSSRV',
@s_term     = 'batch-lcr',
@s_rol      = 3,
@s_lsrv     = 'CTSSRV',
@w_sp_name  = 'sp_lcr_gen_msg_incremento',
@s_sesn     = @s_ssn

select @s_ofi = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'OFICEN'

select @w_fecha_proceso = @i_param1

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select @w_cortes_evaluar = pa_int 
from cobis..cl_parametro 
where pa_nemonico = 'NCEIC'
and pa_producto = 'CCA'

--HASTA ENCONTRAR EL HABIL ANTERIOR
select  @w_fecha_corte  = dateadd(dd,-1,@w_fecha_proceso)

while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_corte ) 
   select @w_fecha_corte = dateadd(dd,-1,@w_fecha_corte)

select @w_num_cortes_evaluar = pa_int 
from cobis..cl_parametro 
where pa_nemonico = 'NCEIC'
and   pa_producto = 'CCA'


if object_id('tempdb..#prestamos_dividendos') is not null
   drop table #prestamos_dividendos

create table #prestamos_dividendos(
secuencial      int IDENTITY(1,1),
operacion       int, 
banco           cuenta,
cliente         int,
monto_aprobado  money,
id_inst_proceso int,
fecha_ini       datetime,
fecha_fin       datetime,
fecha_des       datetime,
utilizacion     money,
pagos           money,
diferencia      money
)

exec cob_cartera..sp_lcr_gen_dividendos 
@i_cortes = @w_num_cortes_evaluar, 
@i_fecha  = @w_fecha_corte


--Eliminación de registros que tienen saldos de Deudas
delete from #prestamos_dividendos
where operacion in (select distinct(operacion)  from #prestamos_dividendos where diferencia <> 0)

--Eliminación de prestamos que tienen utilizacion menor a 50%
delete from #prestamos_dividendos 
where operacion in (select operacion  from #prestamos_dividendos where utilizacion / monto_aprobado < 0.5)

--Eliminacion de operaciones que se les otorgo un incremento recientemente
delete #prestamos_dividendos
from ca_incremento_cupo
where operacion        = ic_operacion
and   ic_fecha_proceso >= fecha_fin

--Eliminación de operaciones que tienen menos n cortes a evaluar
delete from #prestamos_dividendos 
where operacion in (select operacion  from #prestamos_dividendos group by operacion having count(1) < @w_cortes_evaluar)


select @w_operacionca = 0

--borrar utilizaciones menores a 50%

while (1=1) begin
   select top 1
   @w_operacionca     = operacion, 
   @w_banco           = banco,
   @w_cliente         = cliente,
   @w_cupo            = monto_aprobado,
   @w_id_inst_proceso = id_inst_proceso,
   @w_cumple          = 'N'
   from #prestamos_dividendos
   where operacion > @w_operacionca
   order by operacion
      
   if @@rowcount = 0 break
   
   if @w_id_inst_proceso = 0 or @w_id_inst_proceso  is null continue
   
   --1. Regla de Porcentaje de utilizacion
   
   exec @w_error   = cob_cartera..sp_ejecutar_regla
   @s_ssn          = @s_ssn,
   @s_ofi          = @s_ofi,
   @s_user         = @s_user,
   @s_date         = @s_date,
   @s_srv          = @s_srv,
   @s_term         = @s_term,
   @s_rol          = @s_rol,
   @s_lsrv         = @s_lsrv,
   @s_sesn         = @s_ssn,
   @i_regla        = 'LCRPROINC',  
   @i_id_inst_proc = @w_id_inst_proceso,
   @o_resultado1   = @w_procede out
   
   print 'Resultado 1 procede: ' +convert(varchar, isnull(@w_procede,'')) + ' @w_operacionca '+convert(varchar, @w_operacionca) + ' @w_id_inst_proceso '+convert(varchar, @w_id_inst_proceso) --BORRAR
   if @w_procede = 'SI' begin -- Si es cliente totalero
	  
	  exec @w_error   = cob_cartera..sp_ejecutar_regla
      @s_ssn          = @s_ssn,
      @s_ofi          = @s_ofi,
      @s_user         = @s_user,
      @s_date         = @s_date,
      @s_srv          = @s_srv,
      @s_term         = @s_term,
      @s_rol          = @s_rol,
      @s_lsrv         = @s_lsrv,
      @s_sesn         = @s_ssn,
      @i_regla        = 'LCRVALINC',  
      @i_id_inst_proc = @w_id_inst_proceso,
      @o_resultado1   = @w_incremento out,
      @o_resultado2   = @w_limite_inc out
      
      if @w_error <> 0   select @w_limite_inc = 10000, @w_incremento = 300
	  
      select @w_diferencia = @w_limite_inc - @w_cupo --Si el crédito supero el tiempo límite no puede tener un incremento
	        
      if @w_diferencia < 0 continue --Si el crédito supero el tiempo límite no puede tener un incremento
      
      if @w_diferencia < @w_incremento select @w_incremento = @w_diferencia

--INI AGI. 22ABR19.  Se comenta porque no se encuentra cob_bvirtual..sp_b2c_msg_ingresar 
/*      
      exec @w_error = cob_bvirtual..sp_b2c_msg_ingresar 
      @i_cliente  = @w_cliente,
      @i_banco    = @w_banco,
      @i_tipo_msg = 'INCRE_LCR', 
      @i_var1     = @w_incremento
      
      if @w_error != 0
      begin
         exec cobis..sp_errorlog 
         @i_fecha        = @w_fecha_proceso,
         @i_error        = @w_error,
         @i_usuario      = 'usrbatch',
         @i_tran         = 1,
         @i_descripcion  = 'ERROR AL GENERAR MENSAJE DE AUMENTO DE CUPO DE CREDITO',
         @i_tran_name    = null,
         @i_rollback     = 'S'
      end
*/      --FIN AGI
   end
end

return 0

ERROR_FIN:

if @w_commit = 'S'begin 
   select @w_commit = 'N'
   rollback tran    
end

select @w_msg = isnull(@w_msg, 'ERROR GENERAL DEL PROCESO')

exec cobis..sp_errorlog 
@i_fecha        = @w_fecha_proceso,
@i_error        = @w_error,
@i_usuario      = 'usrbatch',
@i_tran         = 1,
@i_descripcion  = @w_msg,
@i_tran_name    = null,
@i_rollback     = 'S'
return @w_error

go
