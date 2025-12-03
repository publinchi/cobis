/************************************************************************/
/*    Archivo:                  sp_ca_endeudamiento.sp                  */
/*    Stored procedure:         sp_ca_endeudamiento                     */
/*    Base de datos:            cob_cartera                             */
/*    Producto:                 Cartera                                 */
/*    Disenado por:             Jorge Escobar                           */
/*    Fecha de escritura:       13/Nov/2019                             */
/************************************************************************/
/*                             IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    "MACOSA",  representantes  exclusivos  para  el Ecuador de la     */
/*    "NCR CORPORATION".                                                */
/*    Su uso no autorizado  queda  expresamente  prohibido asi como     */
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus     */
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la     */
/*    Presidencia Ejecutiva de MACOSA o su representante.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*    Proceso que devuelve el valor de la variable de endeudamiento     */
/*    de un cliente en el producto de Lineas Revolventes                */
/************************************************************************/
/*				MODIFICACIONES				*/
/*    FECHA		AUTOR			RAZON			*/
/*  22/11/2019         EMP-JJEC                Creaciòn                 */
/************************************************************************/
use cob_cartera
go
 
if exists (select * from sysobjects where name = "sp_ca_endeudamiento")
  drop proc sp_ca_endeudamiento
go

create proc sp_ca_endeudamiento 
@s_user          login        = NULL,
@s_term          descripcion  = NULL,
@s_ofi           smallint     = NULL,
@s_date          datetime     = NULL,
@i_cliente       int          = NULL,   --Cliente
@o_id_resultado  money        output
as

declare
@w_est_cancelado                tinyint,
@w_est_credito                  tinyint,
@w_est_anulado                  tinyint,
@w_est_novigente                tinyint,
@w_est_vigente                  tinyint,
@w_est_vencido                  tinyint,
@w_monto_usado_ml               money,
@w_monto_usado_me               money,
@w_moneda_nacional              tinyint,
@w_op_moneda_ext                tinyint,
@w_cotizacion_hoy               float,
@w_monto_usado_total            money,
@w_linea                        int

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

if @@rowcount = 0
   return 708174

select @w_op_moneda_ext = 1
select @w_monto_usado_total = 0

-- OPCION 1 Leer cupo utilizado de la linea del producto 
if exists(select 1 from cob_credito..cr_linea where li_cliente = @i_cliente and li_estado = 'V' and li_rotativa = 'S' and li_fecha_vto > @s_date)
begin
   select @w_linea = li_numero 
     from cob_credito..cr_linea 
    where li_cliente = @i_cliente 
      and li_estado = 'V' 
      and li_rotativa = 'S' 
      and li_fecha_vto > @s_date
	
   if exists(select 1 from cob_credito..cr_lin_ope_moneda where om_linea = @w_linea and om_toperacion = 'VIVTCASA')
     select @w_monto_usado_total = om_utilizado 
       from cob_credito..cr_lin_ope_moneda 
      where om_linea = @w_linea
        and om_toperacion = 'VIVTCASA'
end

-- OPCION 2 Leer cupo utilizado de los prestamos
/*
select @w_monto_usado_ml = isnull(sum(op_monto),0)
  from ca_operacion 
 where op_cliente = @i_cliente
   and op_estado not in (@w_est_cancelado, @w_est_novigente, @w_est_credito, @w_est_anulado)
   and op_toperacion = 'VIVTCASA' -- Cambiar al Producto Lineas Revolventes
   and op_moneda = @w_moneda_nacional

select @w_monto_usado_me = isnull(sum(op_monto),0)
  from ca_operacion 
 where op_cliente = @i_cliente
   and op_estado not in (@w_est_cancelado, @w_est_novigente, @w_est_credito, @w_est_anulado)
   and op_toperacion = 'VIVTCASA' -- Cambiar al Producto Lineas Revolventes
   and op_moneda <> @w_moneda_nacional

-- DETERMINAR EL VALOR DE COTIZACION DEL DIA
   exec sp_buscar_cotizacion
   @i_moneda     = @w_op_moneda_ext,
   @i_fecha      = @s_date,
   @o_cotizacion = @w_cotizacion_hoy output

select @w_monto_usado_total = @w_monto_usado_ml + (@w_monto_usado_me*isnull(@w_cotizacion_hoy,1))
*/
           
select @o_id_resultado = @w_monto_usado_total

return 0

go

