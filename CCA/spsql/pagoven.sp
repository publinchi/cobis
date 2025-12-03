
/************************************************************************/
/*  archivo:                abonoven.sp                                 */
/*  stored procedure:       sp_pagos_ven_garliq_ej                      */
/*  base de datos:          cob_cartera                                 */
/*  producto:               credito                                     */
/*  disenado por:           Andy Gonzalez                               */
/*  fecha de documentacion: 28/ago/2018                                 */
/************************************************************************/
/*          importante                                                  */
/*  este programa es parte de los paquetes bancarios propiedad de       */
/*  "macosa",representantes exclusivos para el ecuador de la            */
/*  at&t                                                                */
/*  su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  presidencia ejecutiva de macosa o su representante                  */
/************************************************************************/
/*          proposito                                                   */
/*               Aplicacion de Pagos con Garantia                       */
/*            a prestamos vencidos                                      */
/************************************************************************/

use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_pagos_ven_garliq_ej')
	drop proc sp_pagos_ven_garliq_ej
go

create proc sp_pagos_ven_garliq_ej
as
declare
@w_sp_name       	varchar(32),
@w_tramite_grupal   int,
@w_return        	int,
@w_error            int,
@w_msg              varchar(255),
@w_fecha_proceso    datetime, 
@w_op_fecha_fin     datetime,
@w_monto_garantia   money,
@w_secuencial_ing   int,
@w_fpago            descripcion,
@w_fecha_control    datetime,
@s_ssn              int,
@s_ofi              int, 
@s_user             descripcion,
@s_srv              descripcion,
@s_term             descripcion,
@s_rol              int,
@s_lsrv             descripcion,
@w_ciudad_nacional  int,
@w_beneficiario     varchar(255),
@w_banco            varchar(255),
@w_moneda           int,
@w_commit           char(1),
@w_cuotas_vencidas  int,
@w_cuota_aplicacion int,
@w_operacion_gr     varchar(255),
@w_op_cliente       int,
@w_op_cuenta        varchar(255),
@w_cod_externo      varchar(255),
@w_op_tramite       int,
@w_grupo            int,
@w_aplica_gar_liquida  char(1),
@w_monto            int,
@w_toperacion       catalogo,
@w_operiodo         int, 
@w_operacionca      int,
@w_est_vencido      int,
@w_debug            char(1),
@w_est_cancelado    int,
@w_bandera          int,
@w_oficina          int 


select @w_fecha_proceso= fp_fecha 
from cobis..ba_fecha_proceso

--INICIALIZACION DE VARIABLES--
exec @s_ssn  = ADMIN...rp_ssn
select 
@s_user             ='usrbatch',
@s_srv              ='CTSSRV',
@s_term             ='batch-pag-ven',
@s_rol              =3,
@s_lsrv             ='CTSSRV',
@w_fpago            ='GAR_DEB',
@w_debug            = 'N'

create table #grupos_vencidos(
gv_grupo           int      null, 
gv_operacion       int      null,
gv_toperacion      catalogo null,  
gv_periodo         int      null,
gv_vencidos        money    null,
gv_saldo_vencido   money    null,
gv_total_garantia  money    null,
gv_ciclo_grupo     int      null,
gv_cuotas_vencidas int      null,
gv_oficina         int      null
)

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @@rowcount = 0 begin
   select @w_error = 101024
   goto ERROR
end


exec @w_error   = sp_estados_cca
@o_est_vencido  = @w_est_vencido   OUT,
@o_est_cancelado = @w_est_cancelado out 
if @w_error <> 0
begin 
   SELECT
   @w_error = 701103,
   @w_msg = 'Error !:No exite estado vencido'
   goto ERROR
end



if exists (select 1 from cobis..cl_dias_feriados where df_fecha = @w_fecha_proceso and df_ciudad = @w_ciudad_nacional)
and datepart(dd,@w_fecha_proceso) <> 1 
   return 0
			
--MANEJO DE LOS DIAS HABILES

select @w_fecha_control = @w_fecha_proceso

insert into #grupos_vencidos  
        (gv_grupo  ,gv_operacion       ,gv_toperacion      ,gv_periodo                      ,gv_vencidos                  ,gv_cuotas_vencidas ,gv_oficina )
select   dc_grupo  ,max(dc_operacion)  ,max(op_toperacion) ,max(op_periodo_int*td_factor)   ,count(distinct di_dividendo) ,0                  ,op_oficina                  
from  ca_dividendo, ca_det_ciclo, ca_operacion , ca_tdividendo
where di_operacion  = dc_operacion
and   dc_operacion  = op_operacion
and   td_tdividendo = op_tdividendo
and   di_operacion  = di_operacion 
and   di_fecha_ven  <  @w_fecha_control 
and   di_estado     <> @w_est_cancelado
and   op_estado     <> @w_est_cancelado
group by dc_grupo,op_oficina



select 
toperacion = gv_toperacion, 
periodo    = gv_periodo, 
prestamo   = max(gv_operacion)
into  #periodicidad
from  #grupos_vencidos
group by gv_toperacion, gv_periodo

--cursor periodicidad
declare cur_periodicidad cursor
for select toperacion , periodo, prestamo
from  #periodicidad  
open  cur_periodicidad
fetch cur_periodicidad
into  @w_toperacion, @w_operiodo,@w_operacionca

while @@fetch_status = 0
begin

   
   --EJECUCION DE LA REGLA DE NEGOCIO
   exec @w_error       = sp_ejecutar_regla
   @s_ssn              = @s_ssn,
   @s_ofi              = @s_ofi,
   @s_user             = @s_user,
   @s_date             = @w_fecha_proceso,
   @s_srv              = @s_srv,
   @s_term             = @s_term,
   @s_rol              = @s_rol,
   @s_lsrv             = @s_lsrv,
   @s_sesn             = 1,
   @i_operacionca      = @w_operacionca,
   @i_regla            ='APLGAR',                --nemonico de la regla
   @o_resultado1       =  @w_cuota_aplicacion out, --cuotas aplicacion    15
   @o_resultado2       =  @w_cuotas_vencidas out  --cuota  vencidas       3
   
   if @w_error <> 0 return @w_error 
   
   if @w_cuotas_vencidas is null 
   begin
      select 
      @w_error = 710002,
      @w_msg = 'ERROR: NO SE PUDO DETERMINAR LOS VALORES PARA LA REGLA APLGAR'
      goto ERROR
   end   
   
   update #grupos_vencidos set 
   gv_cuotas_vencidas  =  @w_cuotas_vencidas
   where gv_toperacion =  @w_toperacion     
   and gv_periodo      =  @w_operiodo 


fetch cur_periodicidad
into  @w_toperacion, @w_operiodo,@w_operacionca
end
close cur_periodicidad
deallocate cur_periodicidad


--CURSOS DE PRESTAMOS CON VENCIMIENTOS DE ACUERDO A LA REGLA DE NEGOCIO
declare cur_pagos_gl cursor for
select gv_grupo, gv_oficina 
from #grupos_vencidos 
where gv_vencidos >=gv_cuotas_vencidas for read only
open  cur_pagos_gl fetch cur_pagos_gl into  @w_grupo , @w_oficina 

while @@fetch_status = 0 begin

   if @w_debug = 'S' print 'PROCESANDO GRUPO: ' +convert(varchar, @w_grupo) +' CON FECHA CONTROL: '+convert(varchar,@w_fecha_control)
       
	
   exec @w_error = sp_pago_grupal
   @s_user       = @s_user,
   @s_term       = @s_term,
   @s_date       = @w_fecha_proceso,
   @s_sesn       = 1,
   @s_ofi        = @w_oficina,
   @s_ssn        = @s_ssn,
   @s_srv        = @s_srv,
   @i_grupo      = @w_grupo,   --
   @i_operacion  ='I',
   @i_monto      = null,
   @i_fecha_control = @w_fecha_control,
   @i_batch      = 'S'
   if @w_error <> 0  begin
      select 
      @w_msg = 'ERROR EN APLICACION DE PAGO (sp_pago_cartera)'
      goto SIGUIENTE_GRP
   end
   
   SIGUIENTE_GRP:
   exec cob_cartera..sp_errorlog 
   @i_fecha       = @w_fecha_proceso,
   @i_error       = @w_error,
   @i_usuario     = 'usrbatch',
   @i_tran        = 7999,
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = '',
   @i_descripcion = @w_msg,
   @i_rollback    = 'N'
   
   fetch cur_pagos_gl into  @w_grupo, @w_oficina 
end 
close cur_pagos_gl
deallocate cur_pagos_gl


return 0

ERROR:

exec cob_cartera..sp_errorlog 
    @i_fecha       = @w_fecha_proceso,
    @i_error       = @w_error,
    @i_usuario     = 'usrbatch',
    @i_tran        = 7999,
    @i_tran_name   = @w_sp_name,
    @i_cuenta      = '',
    @i_descripcion = @w_msg,
    @i_rollback    = 'N'
	

return @w_error 
go
