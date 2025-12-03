/************************************************************************/
/*   Archivo:              carggescob_aut.sp                            */
/*   Stored procedure:     sp_cargos_gestion_cobranza_automatico      	*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Kevin Rodríguez                              */
/*   Fecha de escritura:   12/Octubre/2021                              */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Realiza el registro del cálculo del valor total en mora  (sin      */
/*   incluir los rubros de cargos por gestión de cobranza) y la can-    */
/*   dad de días en mora(en base a la cuota más vencida) de un préstamo */
/*                                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/************************************************************************/
/*   FECHA        AUTOR                    RAZON                        */
/* 12/Oct/2021   Kevin Rodríguez     Version inicial					*/
/* 25/Jul/2022   Kevin Rodríguez     Días mora en base a Inicio de Día. */
/* 18/Ago/2022   Kevin Rodríguez     R191968 Valor proyec para calc mora*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cargos_gestion_cobranza_automatico')
   drop proc sp_cargos_gestion_cobranza_automatico
go

create proc sp_cargos_gestion_cobranza_automatico (
@s_ofi                  SMALLINT     = null,
@s_user                 login,
@s_date                 DATETIME,
@s_term                 descripcion  = null,
@s_sesn                 int          = null,
@i_banco                cuenta       = null,
@i_operacionca          int          = null,
@i_en_linea             char(1)      = 'N'
)

as declare
@w_sp_name              varchar(30),
@w_error                int,
@w_banco                cuenta,
@w_operacionca          int,
@w_fecha_ult_proceso    datetime,
@w_fecha_proceso        datetime,
@w_tipo_operacion       catalogo,
@w_monto                money, 
@w_moneda_op            tinyint, 
@w_rubgescob            catalogo,  
@w_est_novigente        tinyint,
@w_est_vencido          tinyint,
@w_cont_cat_rub         smallint,
@w_dias_mora            smallint,
@w_monto_mora           money,
@w_valor_cobranza       money,
@w_div_mas_venc         smallint,
@w_secuencial_ioc       int,
@w_monto_ioc            money,
@w_monto_abonado        money,
@w_descripcionErr       varchar(255),
@w_commit               char(1)


---  VARIABLES DE TRABAJO  
select  
@w_sp_name       = 'sp_cargos_gestion_cobranza_automatico'

select @w_commit = 'N'

-- OBTENER ESTADOS DE CARTERA
exec @w_error = sp_estados_cca 
@o_est_novigente  = @w_est_novigente out,
@o_est_vencido    = @w_est_vencido out

if @w_error <> 0 GOTO ERROR

-- Datos de la operación
if @i_operacionca is null
   select 
     @w_banco              = op_banco,
     @w_operacionca        = op_operacion,
     @w_fecha_ult_proceso  = op_fecha_ult_proceso,
     @w_tipo_operacion     = op_toperacion,
     @w_moneda_op          = op_moneda
   from  ca_operacion
   where op_banco = @i_banco
else
   select
     @w_banco              = op_banco,   
     @w_operacionca        = op_operacion,
     @w_fecha_ult_proceso  = op_fecha_ult_proceso,
     @w_tipo_operacion     = op_toperacion,
     @w_moneda_op          = op_moneda
   from  ca_operacion
   where op_operacion = @i_operacionca

if @@rowcount = 0 begin
   select @w_error = 701013 -- No existe operación activa de cartera
   goto ERROR
end

select @w_fecha_proceso = @w_fecha_ult_proceso

-- Validación que el tipo de préstamo no tenga más de un rubro de cargos por gestión de cobranza
SELECT @w_rubgescob = ru_concepto FROM ca_rubro, cobis..cl_tabla t, cobis..cl_catalogo c
   WHERE t.tabla = 'ca_cargos_gestion_cobranza'
   AND   t.codigo      = c.tabla
   AND   c.estado      = 'V'
   AND   c.codigo      = ru_concepto
   AND   ru_toperacion = @w_tipo_operacion
   and   ru_moneda     = @w_moneda_op
   --AND   ru_fpago = 'M'

IF @@ROWCOUNT <> 1
begin 
   select @w_descripcionErr = 'No existe, o existe más de un rubro de cargos por gestión de cobranza asociado al préstamo: '+ @w_banco
   GOTO ERROR_BATCH
end


-- Total días de mora, monto total en mora y dividendo más vencido del préstamo (Hasta fecha proceso)
select @w_monto_mora   = isnull(sum(am_cuota + am_gracia - am_pagado),0),                             -- KDR Se toma el valor proyectado para el monto en mora (am_cuota)
       @w_dias_mora    = isnull(datediff(dd, min(di_fecha_ven), dateadd(dd, 1, @w_fecha_proceso)),0), -- KDR Se toma la cantidad de días mora en base al INI día
	   @w_div_mas_venc = isnull(min(di_dividendo),0)
from ca_amortizacion, ca_dividendo
where di_operacion = @w_operacionca
and   di_operacion = am_operacion
and   di_dividendo = am_dividendo
and   di_estado    = @w_est_vencido
and   am_concepto <> @w_rubgescob
--and   co_concepto  = am_concepto
--and   co_categoria = 'M' 

if @w_monto_mora = 0 or @w_dias_mora = 0 or @w_div_mas_venc = 0
begin 
   select @w_descripcionErr = 'No existe valores de mora en el préstamo: '+ @w_banco
   GOTO ERROR_BATCH
end

-- Valor de cobranza que se obtiene de tabla de parametrización
select @w_valor_cobranza = cgc_valor_cargo
from  ca_param_cargos_gestion_cobranza
where cgc_dias_mora_desde  <= @w_dias_mora
and   cgc_dias_mora_hasta  >= @w_dias_mora
and   cgc_monto_mora_desde <= @w_monto_mora
and   cgc_monto_mora_hasta >= @w_monto_mora

if @w_valor_cobranza = 0 OR @w_valor_cobranza is null
begin 
   select @w_descripcionErr = 'No existe parametrización para cargos de gestión de cobranza. Préstamo: '+ @w_banco
   GOTO ERROR_BATCH
end

if exists (select 1 from ca_otro_cargo 
                    where oc_operacion = @w_operacionca 
					and   oc_concepto  = @w_rubgescob
					and   oc_div_desde = isnull(@w_div_mas_venc, 0)
					and   oc_div_hasta = isnull(@w_div_mas_venc, 0))
begin

   -- Si ya existe un registro de otro cargo con el concepto de cobranza para el dividendo más vencido
   -- y si el valor de cobranza es diferente al cargado actualmente, se agrega un nuevo cargo con el nuevo valor.
   
   select @w_monto_ioc = sum(oc_monto)
   from ca_otro_cargo 
   where oc_operacion = @w_operacionca 
   and   oc_concepto  = @w_rubgescob
   and   oc_div_desde = isnull(@w_div_mas_venc, 0)
   and   oc_div_hasta = isnull(@w_div_mas_venc, 0)

   if @w_valor_cobranza <> isnull(@w_monto_ioc, 0) AND
      exists (select 1 from ca_rubro_op where ro_operacion = @w_operacionca and ro_concepto = @w_rubgescob)
   begin
      if @w_valor_cobranza > @w_monto_ioc
         select @w_valor_cobranza = @w_valor_cobranza - isnull(@w_monto_ioc,0)
	  ELSE
	     GOTO SALIR
   end
   else GOTO SALIR   

end

begin tran 
   
exec @w_error     = sp_otros_cargos
@s_date           = @s_date,
@s_user           = @s_user,
@s_term           = @s_term,
@s_ofi            = @s_ofi,
@i_banco          = @w_banco,
@i_moneda         = @w_moneda_op,
@i_operacion      = 'I',
@i_en_linea       = @i_en_linea,
@i_desde_batch    = 'N',  
@i_concepto       = @w_rubgescob ,
@i_monto          = @w_valor_cobranza, 
@i_div_desde      = @w_div_mas_venc ,      
@i_div_hasta      = @w_div_mas_venc ,
@i_comentario     = 'GENERADO POR: sp_batch1' 
       
if @w_error != 0 
BEGIN
   SELECT @w_commit = 'S'
   GOTO ERROR
END
   
commit tran


SALIR:
return 0

ERROR_BATCH: 
IF @i_en_linea <> 'S'
insert into ca_errorlog (er_fecha_proc, er_error,  er_usuario, er_tran, er_cuenta, er_descripcion )
                 values (@s_date,       999999,    @s_user,    0,       @w_banco,  isnull(@w_descripcionErr,''))
				 
return 0

ERROR:

if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end

return @w_error

GO


