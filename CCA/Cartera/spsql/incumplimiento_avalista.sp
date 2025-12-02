/************************************************************************/
/*   Archivo:              incumplimiento_avalista.sp                   */
/*   Stored procedure:     sp_incumplimiento_avalista      				*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Pedro Rafael Montenegro Rosales              */
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
/*   Realiza la Aplicacion de los Pagos a los Prestamos procesados en ar*/
/*   chivo de retiro para banco SANTANDER MX, con respuesta OK.         */
/*                              CAMBIOS                                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_incumplimiento_avalista')
   drop proc sp_incumplimiento_avalista
go

create proc sp_incumplimiento_avalista
(
	@s_user          login       = null,
	@s_ofi           smallint    = null,
	@s_date          datetime    = null,
	@s_term          varchar(30) = null,

	@i_banco         cuenta		 = null,
	@i_fecha         datetime	 = null,
   
   @o_valida_error  char(1)    = 'S' out,
	@o_msg           varchar(255) = null out
)
as 

declare
	@w_error				int,
	@w_return				int,
	@w_fecha_proceso		datetime,
	@w_banco				cuenta,
	@w_est_vigente			tinyint,
	@w_est_vencida			tinyint,
	@w_cant_max_pw			smallint,
	@w_cant_max_pq			smallint,
	@w_cant_max_pm			smallint,
	@w_toperacion			varchar(30),
	@w_param_Garantia		varchar(30),
	@w_sp_name				varchar(30),
	@w_msg					varchar(255),
	@w_cant_ini_pw          int,
	@w_cant_ini_pq          int,
    @w_cant_ini_pm          int,
	@w_ciudad_nacional      int,
	@w_fecha_ini            datetime 
            
		
select @w_sp_name = 'sp_incumplimiento_avalista'

select @w_toperacion = 'INDIVIDUAL'


select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

/*DETERMINAR FECHA DE PROCESO*/
if (@i_fecha is null)
begin
	select @w_fecha_proceso     = fc_fecha_cierre
	from cobis..ba_fecha_cierre 
	where  fc_producto = 7
end
else
begin
	select @w_fecha_proceso     = @i_fecha
end

exec @w_error = sp_estados_cca
@o_est_vigente  = @w_est_vigente out,
@o_est_vencido  = @w_est_vencida out

select @w_param_Garantia = pa_char 
	from cobis..cl_parametro 
	where pa_nemonico = 'GARPER'
	and pa_producto = 'GAR'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724639
	goto ERROR_PROCESO
end

select @w_cant_max_pw = pa_smallint 
	from cobis..cl_parametro 
	where pa_nemonico = 'MDWNA'
	and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724647
	goto ERROR_PROCESO
end

select @w_cant_max_pq = pa_smallint 
	from cobis..cl_parametro 
	where pa_nemonico = 'MDQNA'
	and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724648
	goto ERROR_PROCESO
end

select @w_cant_max_pm = pa_smallint 
	from cobis..cl_parametro 
	where pa_nemonico = 'MDMNA'
	and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724649
	goto ERROR_PROCESO
end

declare @TablaInfoPresGroup as table 
(
	id_key			int identity,
	tramite			int,
	operacion		int, 
	codigo_ope		cuenta, 
	cant_dividendo	int, 
	fecha_ven		datetime, 
	tipo_dividendo	char(1), 
	oficial			int, 
	oficina			int,
	moneda			int,
	estado			char(1)
)

declare @TablaGarantias as table 
(
	id_key			int identity,
	tramite			int,
	garante			int
)

declare @TablaMontoTramite as table 
(
	id_key			int identity,
	operacion		int,
	valor			decimal(18,2)
)

declare @TablaDatosOficial as table 
(
	id_key			int identity,
	oficial			int,
	nombre			varchar(255),
	cargo			varchar(255)
)

declare @TablaDatosOficina as table 
(
	id_key			int identity,
	oficina			int,
	nombre_oficina	varchar(64),
	direcc_oficina	varchar(255),
	ciudad_oficina	varchar(64)
)


--CONDICION DE SALIDA EN CASO DE DOBLE CIERRE POR FIN DE MES NO SE DEBE EJECUTAR
if exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_proceso )
          return 0 

--HASTA ENCONTRAR EL HABIL ANTERIOR
select  
@w_fecha_ini    = dateadd(dd,-1,@w_fecha_proceso),
@w_cant_ini_pw  = @w_cant_max_pw, 
@w_cant_ini_pq  = @w_cant_max_pq,
@w_cant_ini_pm  = @w_cant_max_pm
        

while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_ini ) 
   select  
    @w_fecha_ini = dateadd(dd,-1,@w_fecha_ini),
	@w_cant_max_pw  = @w_cant_max_pw+1, 
    @w_cant_max_pq  = @w_cant_max_pq+1,
    @w_cant_max_pm  = @w_cant_max_pm+1
         


insert into @TablaInfoPresGroup (tramite, operacion, codigo_ope, cant_dividendo, fecha_ven, tipo_dividendo, moneda, oficial, oficina, estado)
select op_tramite, op_operacion, op_banco, count(di_dividendo), min(di_fecha_ven), op_tdividendo, op_moneda, op_oficial, op_oficina, op_estado		
		from ca_operacion, ca_dividendo (nolock)
		where op_operacion	= di_operacion 
		and di_estado		= @w_est_vencida
		and op_estado		in (@w_est_vigente, @w_est_vencida)
		and op_toperacion	= @w_toperacion
		and	op_operacion	not in (select tg_operacion from cob_credito..cr_tramite_grupal where tg_operacion is not null)		
		and op_banco		= isnull(@i_banco, op_banco)		
		and ((datediff(dd,   di_fecha_ven, @w_fecha_proceso)   between @w_cant_ini_pw and  @w_cant_max_pw and op_tdividendo = 'W')
			or (datediff(dd, di_fecha_ven, @w_fecha_proceso)   between @w_cant_ini_pq and  @w_cant_max_pq and op_tdividendo = 'Q')
			or (datediff(dd, di_fecha_ven, @w_fecha_proceso)   between @w_cant_ini_pm and  @w_cant_max_pm and op_tdividendo = 'M'))
		group by op_tramite, op_operacion, op_banco, op_tdividendo, op_moneda, op_oficial, op_oficina, op_estado

if (@@error != 0)
begin
   select @w_error = 724640
	goto ERROR_PROCESO
end


insert into @TablaGarantias (garante, tramite)
select cu_garante, gp_tramite
	from cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia
	where gp_garantia = cu_codigo_externo
	and gp_tramite in (select tramite from @TablaInfoPresGroup)
	and cu_tipo = @w_param_Garantia

if (@@error != 0)
begin
   select @w_error = 724650
	goto ERROR_PROCESO
end

insert into @TablaMontoTramite (operacion, valor)
select	operacion,
		sum(am_cuota + am_gracia - am_pagado)
	from @TablaInfoPresGroup, ca_dividendo (nolock), ca_amortizacion (nolock)
	where operacion = di_operacion 
	and di_operacion	= am_operacion
	and di_dividendo	= am_dividendo
	and di_estado		= @w_est_vencida
group by operacion

if (@@error != 0)
begin
   select @w_error = 724642
	goto ERROR_PROCESO
end

insert @TablaDatosOficial (oficial, nombre, cargo)
select distinct oficial, fu_nombre, b.valor
	from @TablaInfoPresGroup, cobis..cc_oficial, cobis..cl_funcionario
	, cobis..cl_tabla a, cobis..cl_catalogo b
	where  oficial = oc_oficial
	and oc_funcionario = fu_funcionario
	and fu_cargo = b.codigo
	and a.codigo = b.tabla
	and a.tabla = 'cl_cargo'

if (@@error != 0)
begin
   select @w_error = 724643
	goto ERROR_PROCESO
end

insert into @TablaDatosOficina (oficina, nombre_oficina, direcc_oficina, ciudad_oficina)
select distinct oficina, of_nombre, of_direccion, ci_descripcion
from @TablaInfoPresGroup, cobis..cl_oficina, cobis..cl_ciudad
where oficina = of_oficina
and of_ciudad = ci_ciudad

if (@@error != 0)
begin
   select @w_error = 724643
	goto ERROR_PROCESO
end

delete from ca_incumplimiento_aval where ia_fecha_con = @w_fecha_proceso

if (@@error != 0)
begin
   select @w_error = 724644
	goto ERROR_PROCESO
end

insert into ca_incumplimiento_aval 
		(ia_fecha_con, ia_tramite, ia_operacion, ia_banco, ia_dividendo, ia_fecha_ven, ia_tdividendo, 
		ia_oficial, ia_oficina, ia_estado, ia_garante, ia_monto_deuda, ia_nom_oficial, ia_car_oficial, 
		ia_nom_garante, ia_mail_garante, ia_nom_oficina, ia_dir_oficina, ia_ciu_oficina, ia_moneda, ia_simbolo)
select	@w_fecha_proceso, a.tramite, a.operacion, a.codigo_ope, a.cant_dividendo, a.fecha_ven, a.tipo_dividendo, 
		a.oficial, a.oficina, a.estado, b.garante, c.valor, d.nombre, d.cargo, 
		en_nomlar, di_descripcion, nombre_oficina, direcc_oficina, ciudad_oficina, a.moneda, mo_simbolo
from @TablaInfoPresGroup a, @TablaGarantias b, @TablaMontoTramite c, @TablaDatosOficial d, @TablaDatosOficina e,
	cobis..cl_ente, cobis..cl_direccion, cobis..cl_moneda
where a.tramite = b.tramite
and a.operacion = c.operacion
and b.garante	= en_ente
and en_ente		= di_ente
and a.oficina	= e.oficina
and a.oficial	= d.oficial
and a.moneda	= mo_moneda
order by a.tramite

if (@@error != 0)
begin
   select @w_error = 724645
	goto ERROR_PROCESO
end

exec @w_return = cob_cartera..sp_generador_xml 
	@i_fecha = @w_fecha_proceso,
	@i_batch = 7073,
	@i_param = 'PFIAV',
   @o_valida_error = @o_valida_error out

if @w_return != 0 
begin
   select @w_error = @w_return
   goto ERROR_PROCESO
end

return 0
   
ERROR_PROCESO:
	select @w_msg = mensaje
		from cobis..cl_errores with (nolock)
		where numero = @w_error
		set transaction isolation level read uncommitted
	  
   select 
   @w_banco      = isnull(@i_banco, ''), 
   @w_msg        = isnull(@w_msg,    '')
	  
   select @w_msg = @w_msg + ' cuenta: ' + @w_banco
	  
   select @o_msg = ltrim(rtrim(@w_msg))
   
   return @w_error

go
