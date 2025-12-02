/**************************************************************************/
/*   NOMBRE LOGICO:      sp_reestructuracion.sp                           */
/*   NOMBRE FISICO:      sp_reestructuracion                              */
/*   BASE DE DATOS:      cob_cartera                                      */
/*   PRODUCTO:           Cartera                                          */
/*   DISENADO POR:       Kevin Rodríguez                                  */
/*   FECHA DE ESCRITURA: 26/Agosto/2021                                   */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada; y por lo tanto, derivará en acciones legales civiles        */
/*   y penales en contra del infractor según corresponda.”.               */
/**************************************************************************/
/*                                   PROPOSITO                            */
/*   Reestructura una operación nueva sobre una operación base            */
/*                                                                        */
/**************************************************************************/
/*                            CAMBIOS                                     */
/*                                                                        */
/* ECHA         AUTOR             RAZON                                   */
/* 26/Ago/2021  Kevin Rodríguez   Version inicial(Encapsulamiento de rees-*/
/*                                tructuración de operaciones de credito) */
/* 22/04/2022   G. Fernandez  Ingreso de validacion de prestamos migrados */
/*                            y tabla de amortizacion manual              */
/* 25/04/2023   K.Rodriguez   S809859 Cambio estado autom. después de RES */
/* 03/Oct-2023  K. Rodiguez   R216451 Actualizar base calculo y dias anio */
/**************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reestructuracion')
   drop proc sp_reestructuracion
go

create proc sp_reestructuracion (
@s_user              login        = null,
@s_term              descripcion  = null,
@s_ssn               int,
@s_srv               varchar(30),
@s_sesn              int          = null,
@s_date              DATETIME     = null,
@s_ofi               SMALLINT     = null, 
@i_banco             cuenta,                  -- Operación base a reestructurarse
@i_tramite           int,                     -- Numero de tramite de operacion generada con la nueva tabla
@i_fecha_liq         datetime     = null,     -- Fecha en que se realiza la reestructuracion o reprogramacion
@i_op_tipo_reest     char(1)      = 'N',      -- Criterio para obtener monto. N: Solo CAP, S: CAP e INT, T: TODO
@o_secuencial        int          = null out
)

as declare
@w_sp_name              varchar(30),
@w_error                int,
@w_est_vigente          tinyint,
@w_est_vencido          tinyint,
@w_est_cancelado        tinyint,
@w_secuencial           int,
@w_op_original          int,         -- Operacion Original sobre la que se reestructura
@w_tramite_original     int,         -- N£mero de tramite Original sobre la que se reestructura
@w_estado_original      int,         -- Estado de la Operacion Original sobre la que se reestructura
@w_aprobado_original    money,       -- Monto Aprobado de la Operacion Original sobre la que se reestructura
@w_moneda_original      int,
@w_fecha_proc_original  datetime,
@w_op_nueva             int,         -- Operacion con los datos a reestructurar
@w_banco_nueva          cuenta,      -- Operacion Banco con los datos a reestructurar
@w_monto_nueva          money,       -- Monto con los datos a reestructurar
@w_moneda_nueva         int,
@w_aprobado_nueva       money,       -- Monto Aprobado con los datos a reestructurar
@w_gracia_int_nueva     int,
@w_fecha_fin_nueva      datetime,
@w_tplazo_nueva         catalogo,
@w_plazo_nueva          int,
@w_tdividendo_nueva     catalogo,    
@w_periodo_cap_nueva    int,
@w_periodo_int_nueva    int,
@w_cuota_nueva          money,
@w_dia_fijo_nueva       int,
@w_fecha_ini_nueva      datetime,
@w_oficina_nueva        int,
@w_base_calculo_nueva   char(1),
@w_dias_anio_nueva      smallint,
@w_tramite              int,
@w_cat1                 float,
@w_tir                  float,
@w_tea                  float,
@w_estado_despues_res   tinyint

---  VARIABLES DE TRABAJO  
select @w_sp_name = 'sp_reestructuracion'

-- OBTENER ESTADOS DE CARTERA
exec @w_error = sp_estados_cca 
@o_est_vigente   = @w_est_vigente out,
@o_est_vencido   = @w_est_vencido out,
@o_est_cancelado = @w_est_cancelado out

if @w_error <> 0 GOTO ERROR

-- Tramite del crédito de la operación generada como plantilla para la reestructuración
if @i_tramite is not null
   select @w_tramite = @i_tramite
   
if @@rowcount = 0
begin
   select @w_error = 2101011
   goto ERROR
end

--GFP 22/04/2022 Validacion para operaciones migradas y con tabla de amortizacion manual
if exists (select 1 from ca_operacion where op_banco   = @i_banco and op_migrada is not null and op_tipo_amortizacion = 'MANUAL' )
begin
   select @w_error = 725151
   goto ERROR
end


-- OBTENER DATOS DE LA OPERACION BASE-ORIGINAL
select @w_op_original         = op_operacion,
       @w_tramite_original    = op_tramite,
       @w_estado_original     = op_estado,
       @w_aprobado_original   = op_monto_aprobado,
       @w_moneda_original     = op_moneda,
	   @w_fecha_proc_original = op_fecha_ult_proceso
from   cob_cartera..ca_operacion
where  op_banco   = @i_banco

-- OBTENER LA OPERACION QUE SE ARMà PRODUCTO DE LA REESTRUCTURACIàN
select @w_op_nueva           = op_operacion,
       @w_banco_nueva        = op_banco,
       @w_monto_nueva        = op_monto,
       @w_moneda_nueva       = op_moneda,
       @w_aprobado_nueva     = op_monto_aprobado,
       @w_gracia_int_nueva   = op_gracia_int,
       @w_fecha_fin_nueva    = op_fecha_fin,
       @w_tplazo_nueva       = op_tplazo,
       @w_plazo_nueva        = op_plazo,
       @w_tdividendo_nueva   = op_tdividendo,
       @w_periodo_cap_nueva  = op_periodo_cap,
       @w_periodo_int_nueva  = op_periodo_int,
       @w_cuota_nueva        = op_cuota,
       @w_dia_fijo_nueva     = op_dia_fijo,
       @w_fecha_ini_nueva    = op_fecha_ini,
       @w_oficina_nueva      = op_oficina,
	   @w_base_calculo_nueva = op_base_calculo,
	   @w_dias_anio_nueva    = op_dias_anio
from   cob_cartera..ca_operacion
where  op_tramite = @w_tramite                 

-- BORRAR TABLAS TEMPORALES DE LA OPERACION BASE
exec @w_error  = cob_cartera..sp_borrar_tmp
     @s_user        = @s_user,
     @s_sesn        = @s_sesn,
     @s_term        = @s_term,
     @i_banco       = @i_banco 

if @w_error <> 0 goto ERROR


-- BORRAR TABLAS TEMPORALES DE LA OPERACION NUEVA
exec @w_error  = cob_cartera..sp_borrar_tmp
     @s_user        = @s_user,
     @s_sesn        = @s_sesn,
     @s_term        = @s_term,
     @i_banco       = @w_banco_nueva 

if @w_error <> 0 goto ERROR

-- PASAR LOS DATOS DE LA OPERACION ORIGINAL A TABLAS TEMPORALES
exec @w_error        = cob_cartera..sp_pasotmp
     @s_user              = @s_user,
     @s_term              = @s_term,
     @i_banco             = @i_banco, 
     @i_operacionca       = 'S',
	 @i_rubro_op          = 'S'

if @w_error <> 0 goto ERROR

-- PASAR LOS DATOS DE LA OPERACION NUEVA A TABLAS TEMPORALES
exec @w_error        = cob_cartera..sp_pasotmp
   @s_user              = @s_user,
   @s_term              = @s_term,
   @i_banco             = @w_banco_nueva,
   @i_operacionca       = 'S',
   @i_dividendo         = 'S',
   @i_amortizacion      = 'S',
   @i_cuota_adicional   = 'S',
   @i_rubro_op          = 'S'


if @w_error <> 0 goto ERROR

-- ACTUALIZAR LOS DATOS DE LA OPERACION ORIGINAL EN LA TABLA TEMPORAL
if @w_aprobado_original > @w_aprobado_nueva                           
   select @w_aprobado_nueva = @w_aprobado_original                

update cob_cartera..ca_operacion_tmp
set    opt_monto          = @w_monto_nueva,
       opt_monto_aprobado = @w_aprobado_nueva, 
       opt_gracia_int     = @w_gracia_int_nueva,
       opt_fecha_ini      = @w_fecha_ini_nueva,
       opt_fecha_fin      = @w_fecha_fin_nueva,
       opt_tplazo         = @w_tplazo_nueva,
       opt_plazo          = @w_plazo_nueva,
       opt_tdividendo     = @w_tdividendo_nueva,
       opt_periodo_cap    = @w_periodo_cap_nueva,
       opt_periodo_int    = @w_periodo_int_nueva,
       opt_cuota          = @w_cuota_nueva,
       opt_dia_fijo       = @w_dia_fijo_nueva,
	   opt_base_calculo   = @w_base_calculo_nueva,
	   opt_dias_anio      = @w_dias_anio_nueva   
where  opt_operacion      = @w_op_original

if @@error <> 0 
begin
   select @w_error = 705022          
    goto ERROR
end 

-- ACTUALIZAR ESTADO DE LOS REGISTROS DE AMORTIZACION DE LA OPERACION NUEVA
/*update cob_cartera..ca_amortizacion_tmp
set    amt_estado = 1                            
from   cob_cartera..ca_rubro_op
where  amt_operacion = @w_op_nueva
and    ro_operacion  = @w_op_nueva
and    ro_concepto   = amt_concepto
and    ro_tipo_rubro = 'C'

if @@error <> 0 
begin
   select @w_error = 705022
   goto ERROR
end */

-- ACTUALIZAR EL NUMERO DE OPERACION DE LAS TABLAS TEMPORALES DE LA OPERACION NUEVA 
-- COLOCANDO EL NUMERO DE OPERACION DE LA OPERACION ORIGINAL                        
update cob_cartera..ca_dividendo_tmp
set    dit_operacion = @w_op_original      
where  dit_operacion = @w_op_nueva

if @@error <> 0 
begin
   select @w_error = 705022
   goto ERROR
end 

update cob_cartera..ca_amortizacion_tmp
set    amt_operacion = @w_op_original
where  amt_operacion = @w_op_nueva

if @@error <> 0 
begin
   select @w_error = 705022
   goto ERROR
end 

update cob_cartera..ca_cuota_adicional_tmp
set    cat_operacion = @w_op_original
where  cat_operacion = @w_op_nueva

if @@error <> 0 
begin
   select @w_error = 705062
   goto ERROR
end 

-- KDR Se elimina registro para que no se duplique al asignar los registros de los rubros de la op nueva
delete cob_cartera..ca_rubro_op_tmp
where  rot_operacion = @w_op_original

if @@error <> 0 
begin
   select @w_error = 707019 -- Error en eliminacion de Rubro Temporal
   goto ERROR
end 

update cob_cartera..ca_rubro_op_tmp
set    rot_operacion = @w_op_original
where  rot_operacion = @w_op_nueva

if @@error <> 0 
begin
   select @w_error = 705026
   goto ERROR
end 

-- REESTRUCTURAR LA OPERACION ORIGINAL
exec @w_error  = cob_cartera..sp_reestructuracion_int
@s_user        = @s_user,
@s_term        = @s_term,
@s_sesn        = @s_sesn,
@s_date        = @s_date,
@s_ofi         = @s_ofi,
@i_banco       = @i_banco,
@i_op_plant    = @w_op_nueva,
@i_op_tipo_reest  = @i_op_tipo_reest,
@i_saldo_reest = @w_monto_nueva,
--@i_fecha_ini   = @w_fecha_ini_nueva,
@o_secuencial  = @w_secuencial out

if @w_error <> 0 goto ERROR

exec @w_error  = cob_cartera..sp_borrar_tmp
@s_user        = @s_user,
@s_sesn        = @s_sesn,
@s_term        = @s_term,
@i_banco       = @i_banco

if @w_error <> 0 goto ERROR

exec @w_error  = cob_cartera..sp_borrar_tmp
@s_user        = @s_user,
@s_sesn        = @s_sesn,
@s_term        = @s_term,
@i_banco       = @w_banco_nueva

if @w_error <> 0 goto ERROR

-- Cambio de Estado Operación
select @w_estado_despues_res = op_estado
from   ca_operacion
where  op_operacion = @w_op_original

if @w_estado_despues_res <> @w_est_cancelado
begin
   exec @w_error = sp_cambio_estado_op
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_banco          = @i_banco,
   @i_fecha_proceso  = @w_fecha_proc_original,
   @i_tipo_cambio    = 'A',
   @i_en_linea       = 'S'

   if @w_error <> 0 
      goto ERROR
   if @@error <> 0 
      return 708201 -- ERROR. Retorno de ejecucion de Stored Procedure

end

-- Recálculo de la TIR y TEA por reestructuración
EXEC @w_error  = sp_tir 
     @i_banco	= @i_banco, 
	 @o_cat		= @w_cat1 output, 
	 @o_tir		= @w_tir  output, 
	 @o_tea		= @w_tea output 

	 if @w_error != 0 goto ERROR

-- ACTUALIZAR ESTADO DE OPERACION A VIGENTE Y VALOR DE LA TIR Y TEA.
update cob_cartera..ca_operacion
set    --op_estado    = @w_est_vigente,
       op_valor_cat	= @w_tir,
   	   op_tasa_cap	= @w_tea
where  op_operacion = @w_op_original

if @@error <> 0
begin
   select @w_error =  705007
   goto ERROR
end


-- Retorna el numero de secuencial
select @o_secuencial = @w_secuencial 

return 0

ERROR:

exec cobis..sp_cerror
@t_debug   = 'N',
@t_file    = null,
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error

GO
