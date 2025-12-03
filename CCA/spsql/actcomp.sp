/************************************************************************/
/*  Archivo:            actcomp.sp                                      */
/*  Stored procedure:   sp_act_compensacion                             */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:                                                       */
/*  Fecha de escritura:                                                 */
/************************************************************************/
/*                             IMPORTANTE                               */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "Cobiscorp".                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de Cobiscorp o su representante.              */
/************************************************************************/  
/*                              PROPOSITO                               */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_act_compensacion')
	drop proc sp_act_compensacion
go

create proc sp_act_compensacion
(
   @i_fecha			 datetime,	
   @i_numero_operacion           int,
   @i_tasa                       float = 0, 	
   @i_saldo_cap			 money,
   @i_saldo_int			 money,
   @i_saldo_otros		 money,
   @i_saldo_int_contingente	 money,
   @i_saldo			 money,
   @i_estado_contable		 tinyint,
   @i_periodicidad_cuota	 smallint,
   @i_edad_mora                  int,
   @i_valor_mora		 money,
   @i_valor_cuota                money,
   @i_cuotas_pag		 smallint,
   @i_cuotas_ven                 smallint,
   @i_num_cuotas             	 smallint,
   @i_fecha_pago		 datetime,
   @i_fecha_fin			 datetime,
   @i_estado_cartera		 tinyint,
   @i_reestructuracion		 char(1),
   @i_fecha_ult_reest		 datetime,
   @i_plazo_dias		 int
)
as

declare 
   @w_sp_name       	varchar(15),
   @w_error         	int,
   @w_tipo_reg		char(1),
   @w_numero_operacion_banco cuenta,
   @w_tipo_operacion	varchar(10),
   @w_codigo_cliente    int,
   @w_oficina           smallint,
   @w_sucursal		smallint,
   @w_regional		varchar(10),
   @w_moneda		tinyint,
   @w_monto		money,
   @w_fecha_ini		datetime,
   @w_codigo_destino	varchar(10),
   @w_clase_cartera	varchar(10),
   @w_codigo_geografico int,
   @w_departamento	smallint,
   @w_tipo_garantias	varchar(10),
   @w_valor_garantias	money,
   @w_admisible		char(1),
   @w_gerente		smallint,
   @w_situacion_cliente catalogo,
   @w_prov_cap		money,
   @w_prov_int		money,
   @w_prov_cxc		money,
   @w_califica          varchar(30),
   @w_do_fecha    datetime

select @w_sp_name = 'sp_act_compensacion'

select @w_tipo_reg = 'D'

select
@w_numero_operacion_banco = do_numero_operacion_banco, 
@w_tipo_operacion    = do_tipo_operacion,
@w_codigo_cliente    = do_codigo_cliente,
@w_oficina           = do_oficina,
@w_sucursal	     = do_sucursal,
@w_regional	     = do_regional,
@w_moneda	     = do_moneda,
@w_monto	     = do_monto,
@w_fecha_ini         = do_fecha_ini,
@w_codigo_destino    = do_codigo_destino,
@w_clase_cartera     = do_clase_cartera,
@w_codigo_geografico = do_codigo_geografico,
@w_departamento	     = do_departamento,
@w_tipo_garantias    = do_tipo_garantias,
@w_valor_garantias   = do_valor_garantias,
@w_admisible	     = do_admisible,
@w_gerente	     = do_gerente,
@w_situacion_cliente = do_situacion_cliente,
@w_prov_cap	     = do_prov_cap,
@w_prov_int          = do_prov_int,
@w_prov_cxc          = do_prov_cxc,
@w_califica	     = do_calificacion
from cob_compensacion..cr_dato_operacion_rep
where  do_fecha = @i_fecha
and    do_tipo_reg = @w_tipo_reg
and    do_numero_operacion = @i_numero_operacion
and    do_codigo_producto = 7 

if @@rowcount = 0 begin

   select @w_do_fecha = max(do_fecha) from cob_compensacion..cr_dato_operacion_rep where do_numero_operacion  = @i_numero_operacion and do_fecha < @i_fecha
   select
   @w_numero_operacion_banco = do_numero_operacion_banco, 
   @w_tipo_operacion    = do_tipo_operacion,
   @w_codigo_cliente    = do_codigo_cliente,
   @w_oficina           = do_oficina,
   @w_sucursal	     = do_sucursal,
   @w_regional	     = do_regional,
   @w_moneda	     = do_moneda,
   @w_monto	     = do_monto,
   @w_fecha_ini         = do_fecha_ini,
   @w_codigo_destino    = do_codigo_destino,
   @w_clase_cartera     = do_clase_cartera,
   @w_codigo_geografico = do_codigo_geografico,
   @w_departamento	     = do_departamento,
   @w_tipo_garantias    = do_tipo_garantias,
   @w_valor_garantias   = do_valor_garantias,
   @w_admisible	     = do_admisible,
   @w_gerente	     = do_gerente,
   @w_situacion_cliente = do_situacion_cliente,
   @w_prov_cap	     = do_prov_cap,
   @w_prov_int          = do_prov_int,
   @w_prov_cxc          = do_prov_cxc,
   @w_califica	     = do_calificacion
   from cob_compensacion..cr_dato_operacion_rep A
   where  do_fecha = @w_do_fecha
   and    do_tipo_reg = @w_tipo_reg
   and    do_numero_operacion = @i_numero_operacion
   and do_codigo_producto = 7 
   --having do_fecha = max(do_fecha)

   if @@rowcount = 0 begin
      select 
      @w_numero_operacion_banco = op_banco,
      @w_tipo_operacion = op_toperacion,
      @w_codigo_cliente = op_cliente,
      @w_oficina = op_oficina,
      @w_moneda = op_moneda,
      @w_monto = op_monto,
      @w_fecha_ini = op_fecha_ini,
      @w_codigo_destino = op_destino,
      @w_clase_cartera = op_clase,
      @w_gerente = op_oficial,
      @w_admisible = op_gar_admisible
      from  ca_operacion
      where op_operacion = @i_numero_operacion

      select @w_sucursal = isnull(of_sucursal,0),
      @w_regional = '1', --ZAPATA por facilidad en la prueba  isnull(of_regional,''),
      @w_codigo_geografico = of_ciudad
      from   cobis..cl_oficina
      where  of_oficina = @w_oficina
      set transaction isolation level read uncommitted

      select @w_departamento = ci_provincia
      from cobis..cl_ciudad
      where ci_ciudad = @w_codigo_geografico
      set transaction isolation level read uncommitted

      select @w_situacion_cliente = '',
      @w_prov_cap = 0,
      @w_prov_int = 0,
      @w_prov_cxc = 0,
      @w_califica = '',
      @w_tipo_garantias = '',
      @w_valor_garantias = 0
            
   end
      

end

if @i_estado_cartera in (3,4) begin 
   delete cob_compensacion..cr_dato_operacion_rep
   where do_fecha >= @i_fecha
   and   do_tipo_reg = @w_tipo_reg
   and   do_numero_operacion = @i_numero_operacion
   and   do_codigo_producto = 7
end else begin
   delete cob_compensacion..cr_dato_operacion_rep
   where do_fecha = @i_fecha
   and   do_tipo_reg = @w_tipo_reg
   and   do_numero_operacion = @i_numero_operacion
   and   do_codigo_producto = 7
end


insert cob_compensacion..cr_dato_operacion_rep(
do_fecha,                  do_tipo_reg,       do_numero_operacion,  
do_numero_operacion_banco, do_tipo_operacion, do_codigo_producto,  
do_codigo_cliente,         do_oficina,        do_sucursal,
do_regional,               do_moneda,         do_monto,
do_tasa,                   do_codigo_destino, do_clase_cartera,  
do_codigo_geografico,      do_departamento,   do_tipo_garantias,
do_valor_garantias,        do_admisible,      do_saldo_cap,
do_saldo_int,              do_saldo_otros,    do_saldo_int_contingente,  
do_saldo,                  do_estado_contable,do_periodicidad_cuota,   
do_edad_mora,              do_valor_mora,     do_valor_cuota,  
do_cuotas_pag,             do_cuotas_ven,     do_num_cuotas,
do_fecha_pago,             do_fecha_ini,      do_fecha_fin,
do_estado_cartera,         do_reestructuracion,do_fecha_ult_reest,
do_plazo_dias,             do_gerente,        do_calificacion,
do_prov_cap,               do_prov_int,       do_prov_cxc,
do_situacion_cliente)
values (
@i_fecha,                  @w_tipo_reg,       @i_numero_operacion,  
@w_numero_operacion_banco, @w_tipo_operacion, 7,
@w_codigo_cliente,         @w_oficina,        @w_sucursal,  
@w_regional,               @w_moneda,         @w_monto,
@i_tasa,                   @w_codigo_destino, @w_clase_cartera,
@w_codigo_geografico,      isnull(@w_departamento,0),   @w_tipo_garantias,
@w_valor_garantias,        @w_admisible,      @i_saldo_cap,
@i_saldo_int,              @i_saldo_otros,    @i_saldo_int_contingente,
@i_saldo,                  @i_estado_contable,@i_periodicidad_cuota,
@i_edad_mora,              @i_valor_mora,     @i_valor_cuota,
@i_cuotas_pag,             @i_cuotas_ven,     @i_num_cuotas,
@i_fecha_pago,             @w_fecha_ini,      @i_fecha_fin,
@i_estado_cartera,         @i_reestructuracion,@i_fecha_ult_reest,
@i_plazo_dias,             @w_gerente,        @w_califica,
@w_prov_cap,               @w_prov_int,       @w_prov_cxc,
@w_situacion_cliente)

if @@error != 0 return 710279
   
return 0
 
go

