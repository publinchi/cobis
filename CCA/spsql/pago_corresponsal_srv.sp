/************************************************************************/
/*   Archivo:              PagoCorresponsalSrv.sp                       */
/*   Stored procedure:     sp_pago_corresponsal_srv      				*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raúl Altamirano Mendez                       */
/*   Fecha de escritura:   Junio 2017                                   */
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

if exists (select 1 from sysobjects where name = 'sp_pago_corresponsal_srv')
   drop proc sp_pago_corresponsal_srv
go

create proc sp_pago_corresponsal_srv
(
	@s_user          login       = null,
	@s_ofi           smallint    = null,
	@s_date          datetime    = null,
	@s_term          varchar(30) = null,

	@i_banco         cuenta		 = null,
	@i_fecha         datetime	 = null,

    @o_valida_error  char(1)      = 'S' out,
	@o_msg           varchar(255) = null out
)
as 

declare
	@w_error				   int,
	@w_return				int,
	@w_fecha_proceso		datetime,
	@w_fecha_vencimiento	datetime,
	@w_banco				cuenta,
	@w_est_vigente			tinyint,
	@w_est_vencida			tinyint,
	@w_lon_operacion        tinyint,
	@w_format_fecha         varchar(30),
	@w_toperacion			varchar(30),
	@w_param_ISSUER         varchar(30),
	@w_sp_name				varchar(30),
	@w_msg					varchar(255),
	@w_par_fp_co_pag_ref    varchar(10),
	@w_param_convgar		varchar(30),
	@w_param_convpre		varchar(30),
	@w_institucion1         varchar(20),
	@w_institucion2         varchar(20),
	@w_grupo                int, 
	@w_fecha                datetime, 
	@w_corresponsal         varchar(20), 
	@w_fecha_venci          datetime, 
	@w_monto_pago           money, 
	@w_referencia           varchar(40),
	@w_ref_santander        varchar(40),
	@w_fecha_ini            datetime ,
	@w_ciudad_nacional      int 
	

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
		
	
	
select @w_sp_name = 'sp_pago_cartera_srv'

select @w_toperacion = 'GRUPAL'

declare @TablaRefGrupos as table 
(
	grupo		   int, 
	correo		varchar(255), 
	rol			varchar(30), 
	ente		   int, 
	nombre		varchar(60), 
	cargo		   varchar(100)
)

declare @TablaInfoPresGroup as table 
(
	grupo			   int, 
	cliente			int, 
	operacion		int, 
	tramite			int,
	ope_grupal		cuenta, 
	dividendo		int, 
	fecha_ven		datetime, 
	fecha_ult_pro	datetime
)



/*DETERMINAR FECHA DE PROCESO*/
if (@i_fecha is null)
begin
	select @w_fecha_proceso     = fc_fecha_cierre,
		   @w_fecha_vencimiento  = dateadd(dd, -1, fc_fecha_cierre)
	from cobis..ba_fecha_cierre 
	where  fc_producto = 7
end
else
begin
	select @w_fecha_proceso    = @i_fecha,
		   @w_fecha_vencimiento = dateadd(dd, -1, @i_fecha)
end

--CONDICION DE SALIDA EN CASO DE DOBLE CIERRE POR FIN DE MES NO SE DEBE EJECUTAR
if exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_proceso )
          return 0 
		  
--HASTA ENCONTRAR EL HABIL ANTERIOR
select  @w_fecha_ini  = dateadd(dd,-1,@w_fecha_proceso)

while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_ini ) 
   select @w_fecha_ini = dateadd(dd,-1,@w_fecha_ini)



exec @w_error = sp_estados_cca
@o_est_vigente  = @w_est_vigente out,
@o_est_vencido  = @w_est_vencida out

select @w_param_ISSUER = pa_char
	from cobis..cl_parametro 
	where pa_nemonico = 'ISSUER' 
	and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724629
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

select @w_par_fp_co_pag_ref = pa_char
from  cobis..cl_parametro 
where pa_nemonico = 'FPCOPR' 
and   pa_producto = 'CCA'

select @w_par_fp_co_pag_ref = isnull(@w_par_fp_co_pag_ref, 'TODAS')


delete from ca_pago_en_corresponsal 
where pc_fecha_proceso = @w_fecha_proceso

if (@@error != 0)
begin
   select @w_error = 724630
	goto ERROR_PROCESO
end

insert into @TablaInfoPresGroup (grupo, cliente, operacion, tramite, ope_grupal, dividendo, fecha_ven, fecha_ult_pro)
	select tg_grupo, tg_cliente, tg_operacion, tg_tramite, tg_referencia_grupal, di_dividendo, di_fecha_ven, op_fecha_ult_proceso
		from cob_credito..cr_tramite_grupal, ca_operacion, ca_dividendo (nolock)
		where tg_cliente	= op_cliente
		and op_operacion	= tg_operacion
		and	op_operacion	= di_operacion 
		and di_estado		= @w_est_vencida
		and op_estado		in (@w_est_vigente, @w_est_vencida)
		and op_toperacion	= @w_toperacion
		and di_fecha_ven	between @w_fecha_ini and @w_fecha_vencimiento
		and op_fecha_ult_proceso = @w_fecha_proceso
		and tg_referencia_grupal = isnull(@i_banco, tg_referencia_grupal)

if (@@error != 0)
begin
	select @w_error = 724631
	goto ERROR_PROCESO
end

insert into ca_pago_en_corresponsal 
		(pc_grupo_id, pc_fecha_proceso, pc_grupo_name, pc_op_fecha_liq, pc_op_moneda, 
		pc_op_oficina, pc_di_fecha_vig, pc_di_dividendo, pc_di_monto, pc_institucion1,
		pc_referencia1, pc_convenio)
select	grupo, 
		@w_fecha_proceso, 
		gr_nombre, 
		opg.op_fecha_liq, 
		opg.op_moneda, 
		opg.op_oficina, 
		fecha_ven, 
		dividendo, 
		sum(am_cuota + am_gracia - am_pagado),
		case 
		  when @w_par_fp_co_pag_ref in ('TODAS', 'OPEN_PAY', 'SANTANDER') then 
		       cob_cartera.dbo.LlenarI('X', 'X', 15)
		  else NULL 
	    end as institucion1, 
		case 
		  when @w_par_fp_co_pag_ref in ('TODAS', 'OPEN_PAY', 'SANTANDER') then 
		       cob_cartera.dbo.CalcularDigitoVerificadorOpenPay(@w_param_ISSUER + 
			   cob_cartera.dbo.LlenarI(opg.op_operacion, '0', @w_lon_operacion) +
			   'P' + cob_cartera.dbo.ConvertFechaString(fecha_ven, @w_format_fecha) + 
			   cob_cartera.dbo.ConvertMontoString(sum(am_cuota + am_gracia - am_pagado)))
		  else NULL
		end,
		@w_param_convpre
	from @TablaInfoPresGroup, ca_dividendo (nolock), ca_amortizacion (nolock), cobis..cl_grupo, ca_operacion opg
	where grupo			= gr_grupo
	and	operacion		= di_operacion 

	and di_operacion	= am_operacion
	and di_dividendo	= am_dividendo
	and di_estado		= @w_est_vencida

	and opg.op_banco	= ope_grupal 
	group by grupo, tramite, ope_grupal, gr_nombre, fecha_ven, dividendo, opg.op_fecha_liq, opg.op_moneda, opg.op_oficina, opg.op_operacion
	order by grupo, tramite, ope_grupal, gr_nombre, fecha_ven, dividendo, opg.op_fecha_liq, opg.op_moneda, opg.op_oficina, opg.op_operacion

if (@@error != 0)
begin
	select @w_error = 724632
	goto ERROR_PROCESO
end


if @w_par_fp_co_pag_ref in ('TODAS', 'OPEN_PAY', 'SANTANDER')
begin
   select @w_institucion1 = NULL,
          @w_institucion2 = NULL
		  
   if @w_par_fp_co_pag_ref = 'TODAS'
      select @w_institucion1 = 'OPEN PAY',
	         @w_institucion2 = 'BANCO SANTANDER'
   else if @w_par_fp_co_pag_ref = 'OPEN_PAY'
      select @w_institucion1 = 'OPEN PAY',
	         @w_institucion2 = NULL
   else if @w_par_fp_co_pag_ref = 'SANTANDER'
      select @w_institucion1 = 'BANCO SANTANDER',
	         @w_institucion2 = NULL
	  
   update ca_pago_en_corresponsal
   set pc_institucion1 = @w_institucion1,
       pc_referencia1  = (case when @w_institucion1 is not null then pc_referencia1 else NULL end),
	   pc_institucion2 = @w_institucion2,
	   pc_referencia2  = (case when @w_institucion2 is not null then pc_referencia1 else NULL end)
   where pc_grupo_id	> 0
   and pc_fecha_proceso = @w_fecha_proceso
   and pc_institucion1 is not null
   and pc_referencia1  is not null

   if (@@error != 0)
   begin
	  select @w_error = 724632
	  goto ERROR_PROCESO
   end
   
   --Digito Verificador nueva referencia para corresponsal SANTANDER
   select 
   grupo         = pc_grupo_id,
   fecha_proceso = pc_fecha_proceso,
   corresponsal  = pc_institucion1,
   fecha_venci   = pc_di_fecha_vig,
   monto_pago    = pc_di_monto,
   referencia_o  = pc_referencia1,     --Referencia inicial de 29 caracteres 
   referencia_s  = pc_referencia2      --Referencia actual de 40 caracteres
   into #tmp_data_santander
   from ca_pago_en_corresponsal
   where 1=2
   
   insert into #tmp_data_santander
   select pc_grupo_id,
          pc_fecha_proceso,
		  'SANTANDER',
		  pc_di_fecha_vig,
		  pc_di_monto,
		  pc_referencia1,
		  pc_referencia1
   from ca_pago_en_corresponsal
   where pc_grupo_id	> 0
   and pc_fecha_proceso = @w_fecha_proceso
   and pc_institucion1 is not null
   and pc_referencia1  is not null
   and @w_par_fp_co_pag_ref = 'SANTANDER'
   
   insert into #tmp_data_santander
   select pc_grupo_id,
          pc_fecha_proceso,
		  'SANTANDER',
		  pc_di_fecha_vig,
		  pc_di_monto,
		  pc_referencia2,
		  pc_referencia2
   from ca_pago_en_corresponsal
   where pc_grupo_id	> 0
   and pc_fecha_proceso = @w_fecha_proceso
   and pc_institucion2 is not null
   and pc_referencia2  is not null   
   and @w_par_fp_co_pag_ref = 'TODAS'
   
   declare cur_referencias cursor for
   select grupo, 
          fecha_proceso,
          corresponsal, 
		  fecha_venci,
		  monto_pago,
          referencia_o
   from #tmp_data_santander
   
   open  cur_referencias
   fetch cur_referencias into @w_grupo, @w_fecha, @w_corresponsal, @w_fecha_venci, @w_monto_pago, @w_referencia

   while @@fetch_status = 0
   begin
	  select @w_ref_santander = null
	  
      exec @w_error = sp_gen_ref_santander 
		   @i_tipo  = 'PG',                 --Tipo: GL(Garantia Liquida), PR(Precancelacion), PI(Prestamo Individual), PG(Prestamo Grupal)
           @i_referencia = @w_grupo,        --Referencia: PG/GL (Numero - Codigo de Grupo), PI/PR(Numero de Operacion - Prestamo)
           @i_fecha = @w_fecha_venci,       --Fecha de Vencimiento
           @i_monto = @w_monto_pago,        --Importe del Pago
           @o_referencia = @w_ref_santander out
	 
	  if @w_error != 0 
	  begin
		goto SIGTE_REGISTRO
	  end	
	  
	  select @w_ref_santander = isnull(@w_ref_santander, @w_referencia)	  
	  
	  if @w_ref_santander != @w_referencia
	  begin
	     update #tmp_data_santander
	     set   referencia_s = @w_ref_santander
	     where grupo = @w_grupo 
	     and   fecha_proceso = @w_fecha
         and   corresponsal  = @w_corresponsal 
	     and   referencia_o  = @w_referencia 
	     and   referencia_s  = @w_referencia 
	  
	     if @@error != 0 
	     begin
		    goto SIGTE_REGISTRO
	     end
      end	  
	  
   SIGTE_REGISTRO:
   
      fetch cur_referencias into @w_grupo, @w_fecha, @w_corresponsal, @w_fecha_venci, @w_monto_pago, @w_referencia
   end

   close cur_referencias
   deallocate cur_referencias 

   select @w_error = 0
   
   if @w_par_fp_co_pag_ref = 'TODAS'
   begin
      select @w_institucion1 = 'OPEN PAY',
	         @w_institucion2 = 'BANCO SANTANDER'
			 
      update ca_pago_en_corresponsal
      set pc_referencia1  = referencia_o,
	      pc_referencia2  = referencia_s
	  from  #tmp_data_santander	  
      where pc_grupo_id > 0
	  and pc_fecha_proceso = @w_fecha_proceso
	  and pc_grupo_id	   = grupo
      and pc_fecha_proceso = fecha_proceso
      and pc_institucion1  = @w_institucion1
      and pc_referencia1   is not null	  
	  and pc_institucion2  = @w_institucion2
	  and pc_referencia2   is not null
	  
	  select @w_error = @@error
   end			 
   else if @w_par_fp_co_pag_ref = 'OPEN_PAY'
   begin
      select @w_institucion1 = 'OPEN PAY'

      update ca_pago_en_corresponsal
      set pc_referencia1  = referencia_o,
	      pc_referencia2  = referencia_o
	  from  #tmp_data_santander	  
      where pc_grupo_id > 0
	  and pc_fecha_proceso = @w_fecha_proceso
	  and pc_grupo_id	   = grupo
      and pc_fecha_proceso = fecha_proceso
      and pc_institucion1  = @w_institucion1
      and pc_referencia1   is not null	  
	  and pc_institucion2  is null 
	  and pc_referencia2   is null 
	  
	  select @w_error = @@error			 
   end
   else if @w_par_fp_co_pag_ref = 'SANTANDER'
   begin
      select @w_institucion1 = 'BANCO SANTANDER'
			 
      update ca_pago_en_corresponsal
      set pc_referencia1  = referencia_s,
	      pc_referencia2  = referencia_s
	  from  #tmp_data_santander	  
      where pc_grupo_id > 0
	  and pc_fecha_proceso = @w_fecha_proceso
	  and pc_grupo_id	   = grupo
      and pc_fecha_proceso = fecha_proceso
      and pc_institucion1  = @w_institucion1
	  and pc_referencia1   is not null
	  and pc_institucion2  is null 
	  and pc_referencia2   is null
	  
	  select @w_error = @@error			 
   end	  
   
   if (@w_error != 0)
   begin
	  select @w_error = 724632
	  goto ERROR_PROCESO
   end   
   --Digito Verificador nueva referencia para SANTANDER
end


insert into @TablaRefGrupos (grupo, correo, rol, ente, nombre, cargo)
	select cg_grupo, di_descripcion, cg_rol, di_ente, en_nomlar, b.valor
	from cobis..cl_direccion, cobis..cl_cliente_grupo, cobis..cl_ente,
		cobis..cl_tabla a, cobis..cl_catalogo b
	where di_ente = cg_ente
	and di_ente = en_ente
	and cg_grupo in (select pc_grupo_id from ca_pago_en_corresponsal where pc_fecha_proceso = @w_fecha_proceso)
	and di_tipo in ('CE')
	and cg_rol in ('P', 'T', 'S')
	and cg_rol = b.codigo
	and a.codigo = b.tabla
	and a.tabla = 'cl_rol_grupo'

if (@@error != 0)
begin
	select @w_error = 724631
	goto ERROR_PROCESO
end
 
update ca_pago_en_corresponsal
	set pc_dest_nombre1 = b.nombre, 
		pc_dest_cargo1	= b.cargo, 
		pc_dest_email1	= b.correo 
	from @TablaRefGrupos b 
	where pc_grupo_id	= b.grupo
	and b.rol			= 'P'
	and pc_fecha_proceso= @w_fecha_proceso

if (@@error != 0)
begin
	select @w_error = 724633
	goto ERROR_PROCESO
end

update ca_pago_en_corresponsal 
	set pc_dest_nombre2 = b.nombre, 
		pc_dest_cargo2	= b.cargo, 
		pc_dest_email2	= b.correo
	from @TablaRefGrupos b 
	where pc_grupo_id	= b.grupo
	and b.rol			= 'T'
	and pc_fecha_proceso= @w_fecha_proceso
	
if (@@error != 0)
begin
	select @w_error = 724633
	goto ERROR_PROCESO
end

update ca_pago_en_corresponsal 
	set pc_dest_nombre3 = b.nombre, 
		pc_dest_cargo3	= b.cargo, 
		pc_dest_email3	= b.correo
	from @TablaRefGrupos b 
	where pc_grupo_id	= b.grupo
	and b.rol			= 'S'
	and pc_fecha_proceso= @w_fecha_proceso

if (@@error != 0)
begin
	select @w_error = 724633
	goto ERROR_PROCESO
end

exec @w_return = cob_cartera..sp_pago_corresponsal_xml 
	@i_fecha = @w_fecha_proceso,
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


