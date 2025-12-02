/************************************************************************/
/*   Archivo:              avisovenccuotas.sp                           */
/*   Stored procedure:     sp_vencimientos_cuotas                       */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         DFu                                          */
/*   Fecha de escritura:   Julio 2017                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Genera archivo xml con informacion de vencimiento de cuotas para   */
/*   envio de correo de aviso de vencimiento a deudores                 */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA        AUTOR             RAZON                                */
/*  12/Dic/2017  DFU               Emision inicial                      */
/*  21/Nov/2018  SRO               Referencias Numericas                */
/*  11/Oct/2019  AAMD              Generacion Reporte en TXT            */
/*  07/Nov/2019  AMG               Reestructura de sp                   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_vencimientos_cuotas')
   drop proc sp_vencimientos_cuotas
go

create proc sp_vencimientos_cuotas
(
    @i_param1        datetime = null, --fecha
    @i_param2        cuenta   = null, --banco
    @o_msg           varchar(255) = null out
)
as 

declare
@w_error                int,
@w_valida_error         char(1),
@w_return               int,
@w_fecha_proceso        datetime,
@w_fecha_vencimiento    datetime,
@w_banco                cuenta,
@w_est_vigente          tinyint,
@w_est_vencida          tinyint,
@w_est_diferido         tinyint,
@w_est_castigado        tinyint,
@w_lon_operacion        tinyint,
@w_format_fecha         varchar(30),
@w_param_ISSUER         varchar(30),
@w_sp_name              varchar(30),
@w_msg                  varchar(255),
@w_param_convpre        varchar(30),
@w_fecha_venci          datetime, 
@w_ciudad_nacional      int,
@w_fecha_ini            datetime


select @w_sp_name = 'sp_vencimientos_cuotas', @w_valida_error = 'S'

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'


/*DETERMINAR FECHA DE PROCESO*/
if (@i_param1 is null)
begin
    select @w_fecha_proceso     = fc_fecha_cierre,
           @w_fecha_vencimiento = dateadd(dd, -1, fc_fecha_cierre)
    from cobis..ba_fecha_cierre 
    where  fc_producto = 7
end
else
begin
    select @w_fecha_proceso     = @i_param1,
           @w_fecha_vencimiento = dateadd(dd, -1, @i_param1)
end


--CONDICION DE SALIDA EN CASO DE DOBLE CIERRE POR FIN DE MES NO SE DEBE EJECUTAR
if exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_proceso )
          return 0 

--HASTA ENCONTRAR EL HABIL ANTERIOR
select  @w_fecha_ini  = dateadd(dd,-1,@w_fecha_proceso)

while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_ini ) 
   select @w_fecha_ini = dateadd(dd,-1,@w_fecha_ini)
   

exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencida   out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_castigado  = @w_est_castigado out

select @w_param_ISSUER = pa_char
    from cobis..cl_parametro 
    where pa_nemonico = 'ISSUER' 
    and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724629
   goto ERROR_PROCESO
end

select @w_lon_operacion = pa_tinyint
    from cobis..cl_parametro 
    where pa_nemonico = 'LOOPA' 
    and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724653
   goto ERROR_PROCESO
end

select @w_format_fecha = pa_char
    from cobis..cl_parametro 
    where pa_nemonico = 'FFOPA' 
    and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724654
   goto ERROR_PROCESO
end

if not exists(select pa_tinyint
    from cobis..cl_parametro 
    where pa_nemonico = 'LMOPA' 
    and pa_producto = 'CCA')
begin
   select @w_error = 724655
   goto ERROR_PROCESO
end

select @w_param_convpre = pa_char
	from cobis..cl_parametro 
	where pa_nemonico = 'CNVPRE' 
	and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 70188
	goto ERROR_PROCESO
end

truncate table ca_vencimiento_cuotas
truncate table ca_vencimiento_cuotas_det

select cliente = op_cliente
	, operacion = op_operacion
	, banco = op_banco
	, tipo_operacion = op_toperacion
	, tramite = op_tramite
	, ope_banco = op_banco 
	, dividendo = di_dividendo
	, fecha_ven = di_fecha_ven 
	, fecha_ult_pro = op_fecha_ult_proceso
	, fecha_liquida = op_fecha_liq
	, moneda = op_moneda
	, oficina = op_oficina
	, cuota = sum(am_cuota + am_gracia - am_pagado)
into #InfoPresGrupal
from ca_operacion with(NOLOCK) inner join ca_dividendo with(NOLOCK)
	on di_operacion = op_operacion inner join ca_amortizacion with(NOLOCK)
	on am_operacion = di_operacion and am_dividendo = di_dividendo
where op_banco = isnull(@i_param2, op_banco)
	and op_estado in (@w_est_vigente, @w_est_vencida, @w_est_diferido, @w_est_castigado)
	and op_fecha_ult_proceso = @w_fecha_proceso
	and di_estado in (@w_est_vigente, @w_est_vencida)
	and di_fecha_ven between @w_fecha_ini and @w_fecha_vencimiento
group by op_cliente, op_operacion, op_toperacion, op_tramite
	, op_banco , di_dividendo, di_fecha_ven, op_fecha_ult_proceso
	, op_fecha_liq, op_moneda, op_oficina

if (@@rowcount) > 0
begin
	insert into ca_vencimiento_cuotas 
		(vc_operacion, vc_cliente, vc_fecha_proceso, vc_tipo_operacion,
		vc_op_fecha_liq, vc_op_moneda, vc_op_oficina, vc_di_fecha_vig, 
		vc_di_dividendo, vc_di_monto, vc_banco, vc_cliente_name, 
		vc_email)
	select operacion, cliente, @w_fecha_proceso, tipo_operacion
		, fecha_liquida, moneda, oficina, fecha_ven
		, dividendo, cuota, banco, replace(replace(replace(replace(replace(replace(replace(
		(isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'') + ' ' + en_nombre)
		, 'Á','A'), 'É','E'), 'Í','I'), 'Ó','O'), 'Ú','U'), 'Ñ','N'), 'Ü','U') AS vc_cliente_name
		, (select top 1 di_descripcion from cobis..cl_direccion where di_ente = cliente 
		and di_tipo = 'CE' order by di_direccion ) as mail
	from #InfoPresGrupal inner join cobis..cl_ente
		on en_ente = cliente

	if (@@error != 0)
	begin
		select @w_error = 708154
		goto ERROR_PROCESO
	end

	-- Generacion del reporte vencimiento cuotas
	exec @w_return = cob_cartera..sp_vencimientos_cuotas_txt

	if @w_return != 0 
	begin
	   select @w_error = @w_return
	   goto ERROR_PROCESO
	end
end

return 0
   
ERROR_PROCESO:
    select @w_msg = mensaje
        from cobis..cl_errores with (nolock)
        where numero = @w_error
        set transaction isolation level read uncommitted
      
   select 
   @w_banco      = isnull(@i_param2, ''), 
   @w_msg        = isnull(@w_msg,    '')
      
   select @w_msg = @w_msg + ' cuenta: ' + @w_banco
      
   select @o_msg = ltrim(rtrim(@w_msg))
      
   exec sp_errorlog 
      @i_fecha     = @i_param1,
      @i_error     = @w_error, 
      @i_usuario   = 'sa', 
      @i_tran      = 7076,
      @i_tran_name = @w_sp_name,
      @i_cuenta    = @i_param2,
      @i_anexo     = @w_msg,
      @i_rollback  = 'N'
   
   if (@w_valida_error = 'S')
   begin
      return @w_error
   end
   else
   begin
      return 0
   end
go