/************************************************************************/
/*  Archivo:                mdebaut.sp                                  */
/*  Stored procedure:       sp_marca_debaut                             */
/*  Base de datos:          cobis                                       */
/*  Producto:               Credito y Cartera                           */
/*  Disenado por:           Johan Ardila                                */
/*  Fecha de escritura:     03-Dic-2010                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Este programa presenta la lista de productos del credito.           */
/*    FECHA                AUTOR                  RAZON                 */
/*  03/Dic/2010        Johan Ardila         REQ 205. Debito Automatico  */
/************************************************************************/
use cob_cartera
go

if object_id ('sp_marca_debaut') is not null
begin
   drop proc sp_marca_debaut
end
go

create proc sp_marca_debaut (
   @s_user           login,
   @s_term           varchar(30),
   @t_trn            smallint,
   @i_operacion      char(1),
   @i_banco          cuenta,
   @i_forma_pago     catalogo     = null,
   @i_cuenta         varchar(24)  = null,
   @s_date           datetime     = null   
)
as
declare
   @w_error    int,
   @w_return   int,
   @w_sp_name  varchar(20)

select @w_sp_name = 'sp_marca_debaut'

-- Codigo de transaccion errada
if @t_trn <> 7708
begin   
   select @w_error = 701014
   goto ERROR
end

-----------------------
-- Paso a Temporales --
-----------------------
if @i_operacion = 'P'
begin
   exec @w_return = sp_pasotmp
      @s_user        = @s_user,
      @s_term        = @s_term,
      @i_banco       = @i_banco,
      @i_operacionca = 'S',
      @i_rubro_op    = 'S'

   if @w_return <> 0 
   begin
      select @w_error = @w_return
      goto ERROR
   end
   
   -- Envio a Front-end
   select op_toperacion,
          (select C.valor from cobis..cl_tabla T, cobis..cl_catalogo C
            where T.tabla  = 'ca_toperacion'
              and T.codigo = C.tabla
              and C.codigo = O.op_toperacion),
          op_moneda,
          (select mo_descripcion from cobis..cl_moneda
            where mo_moneda = O.op_moneda),
          op_nombre,     op_cliente,
          op_forma_pago, op_cuenta
     from ca_operacion O
    where op_banco = @i_banco
          
end  -- if @i_operacion = 'P'

------------------------------------
-- Actualizacion en Temporales y  --
-- Transferencia a definitivas    --
------------------------------------
if @i_operacion = 'T'
begin
   update ca_operacion_tmp set
      opt_forma_pago = @i_forma_pago,
      opt_cuenta     = @i_cuenta
    where opt_banco = @i_banco

   if @@error <> 0
   begin
      select @w_error = 705018 
      goto ERROR
   end

   insert into ca_operacion_ts
   (   ops_fecha_proceso_ts, ops_fecha_ts,            ops_usuario_ts,          ops_oficina_ts,        ops_terminal_ts, 
       ops_operacion,        ops_banco,               ops_sector,              ops_toperacion,        ops_oficina,
       ops_moneda,           ops_oficial,             ops_fecha_ini,           ops_fecha_fin,         ops_fecha_ult_proceso,
       ops_monto,            ops_monto_aprobado,      ops_destino,             ops_ciudad,            ops_estado,
       ops_tipo,             ops_dias_anio,           ops_tipo_amortizacion,   ops_cuota_completa,    ops_tipo_cobro,
       ops_tipo_reduccion,   ops_aceptar_anticipos,   ops_precancelacion,      ops_tipo_aplicacion,   ops_mes_gracia,
       ops_reajustable,      ops_dias_clausula,       ops_clase,               ops_numero_reest,      ops_fondos_propios,
       ops_tipo_linea,       ops_bvirtual,            ops_extracto,            ops_cuenta,            ops_cliente,
       ops_valor_cat
   )
   select 
       @s_date,              @s_date,                 @s_user,                 opt_oficina,           @s_term, 
       opt_operacion,        opt_banco,               opt_sector,              opt_toperacion,        opt_oficina,
       opt_moneda,           opt_oficial,             opt_fecha_ini,           opt_fecha_fin,         opt_fecha_ult_proceso,
       opt_monto,            opt_monto_aprobado,      opt_destino,             opt_ciudad,            opt_estado,
       opt_tipo,             opt_dias_anio,           opt_tipo_amortizacion,   opt_cuota_completa,    opt_tipo_cobro,
       opt_tipo_reduccion,   opt_aceptar_anticipos,   opt_precancelacion,      opt_tipo_aplicacion,   opt_mes_gracia,
       opt_reajustable,      opt_dias_clausula,       opt_clase,               opt_numero_reest,      opt_fondos_propios,
       opt_tipo_linea,       opt_bvirtual,            opt_extracto,            @i_cuenta,             opt_cliente,
       opt_valor_cat
       from ca_operacion_tmp where opt_banco = @i_banco

   if @@error <> 0
   begin
      select @w_error = 710001 
      goto ERROR
   end
   
   exec @w_return = sp_pasodef
      @i_banco       = @i_banco,
      @i_operacionca = 'S'

   if @w_return <> 0 
   begin
      select @w_error = @w_return
      goto ERROR
   end
end  -- if @i_operacion = 'T'

----------------------------------
-- Actualizacion en definitivas --
----------------------------------
if @i_operacion = 'U'
begin
   update ca_operacion set
      op_forma_pago = @i_forma_pago,
      op_cuenta     = @i_cuenta
    where op_banco = @i_banco

   if @@error <> 0
   begin
      select @w_error = 705007
      goto ERROR
   end
end  -- if @i_operacion = 'U'

return 0

ERROR:

   exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_num   = @w_error

   return @w_error

go
