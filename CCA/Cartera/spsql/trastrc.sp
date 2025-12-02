 /***********************************************************************/
/*   Nombre Fisico:        trastrc.sp                                   */
/*   Nombre Logico:        sp_transaccion_trc                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez Burbano                        */
/*   Fecha de escritura:   31/08/1999                                   */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                                PROPOSITO                             */
/*   Traslada los saldos generando una transaccion TRC                  */
/*   Actualiza la Obligacion con la nueva calificacion                  */
/*   Saca un nuevo HFM con las nuevas calificaciones                    */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*   FECHA       AUTOR      RAZON                                       */
/*   FEB-2006    ElciraP.   actualizacion de la calif. en la his        */
/*    06/06/2023	 M. Cordova		  Cambio variable @i_calificacion_final*/
/*									  @i_calificacion_antes				*/			
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_transaccion_trc')
   drop proc sp_transaccion_trc
go

create proc sp_transaccion_trc(
   @s_user                 login,
   @s_term                 varchar(30),
   @s_date                 datetime,
   @s_ofi                  smallint,
   @i_toperacion           catalogo,
   @i_oficina              smallint,
   @i_banco                cuenta,
   @i_operacionca          int,
   @i_moneda               tinyint,
   @i_fecha_proceso        datetime,
   @i_gerente              smallint,
   @i_moneda_nac           smallint,
   @i_garantia             char(1) = '',
   @i_reestructuracion     char(1) = '',
   @i_calificacion_final   catalogo = '',
   @i_calificacion_antes   catalogo = '',
   @i_reproceso            char(1) = 'N'
) 

as 
declare
   @w_sp_name           descripcion,
   @w_return            int,
   @w_trn               catalogo,
   @w_estado_op         int,
   @w_cotizacion_hoy    money,
   @w_fecha_ult_proceso datetime,
   @w_concepto_cap      catalogo,
   @w_parametro_int     catalogo,
   @w_num_dec_op        int,
   @w_moneda_mn         smallint,
   @w_num_dec_n         smallint,
   @w_causacion         char(1),
   @w_secuencial        int

-- CARGAR VARIABLES DE TRABAJO
select @w_sp_name       = 'sp_transaccion_trc',
       @w_trn           = 'TRC'

-- OBTENER EL CONCEPTO CAP
select @w_concepto_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
set transaction isolation level read uncommitted

-- OBTENER EL CONCEPTO INT
select @w_parametro_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
set transaction isolation level read uncommitted

-- EJECUTAR SP TRASLADADOR
select @w_estado_op          = op_estado,
       @w_fecha_ult_proceso  = op_fecha_ult_proceso,
       @w_causacion          = op_causacion
from   ca_operacion
where  op_operacion = @i_operacionca
      
-- LECTURA DE DECIMALES
exec @w_return = sp_decimales
     @i_moneda       = @i_moneda,
     @o_decimales    = @w_num_dec_op out,
     @o_mon_nacional = @w_moneda_mn  out,
     @o_dec_nacional = @w_num_dec_n  out

if @w_return != 0 
   return  @w_return

-----------------  ACTUALIZACION DE LA OBLIGACION CON TODA SU HISTORIA 
-- ACTUALIZAR LA CALIFICACION y MARCAR LAS OPERACIONES QUE GENERARON TRASLADO
 
update ca_operacion 
set    op_calificacion     = @i_calificacion_final,
       op_calificacion_ant = @i_calificacion_antes
where  op_operacion = @i_operacionca

if @@error <> 0 
   return 705076

if @i_reproceso <> 'S'
begin
   update ca_transaccion
   set    tr_estado = 'ANU', tr_observacion = 'ANULADA POR QUE NO SE PRESENTO REPROCESO'
   where  tr_operacion = @i_operacionca
   and    tr_tran = 'HFM'
   and    tr_fecha_mov >=  @i_fecha_proceso  --Fecha de Fin de mes
   
   if @@error <> 0 
      return 710510
end
-- ACTUALIZAR LA CALIFICACION EN HISTORICOS

update ca_operacion_his
set    oph_calificacion     = @i_calificacion_final,
       oph_calificacion_ant = @i_calificacion_antes
where  oph_operacion        = @i_operacionca

if @@error <> 0 
    return  705076


update cob_cartera_his..ca_operacion_his
set    oph_calificacion     = @i_calificacion_final,
       oph_calificacion_ant = @i_calificacion_antes
where  oph_operacion        = @i_operacionca

if @@error <> 0 
    return  710002


update cob_cartera_depuracion..ca_operacion_his
set    oph_calificacion     = @i_calificacion_final,
       oph_calificacion_ant = @i_calificacion_antes
where  oph_operacion        = @i_operacionca

if @@error <> 0 
    return  710002
    
    
-- ANULAR LAS TRANSACCIONES ANTERIORES PARA EVITAR  CONTABILIZACION DE REVERSOS
update ca_transaccion
set    tr_estado = 'ANU',
       tr_observacion = 'ANULADA POR EFECTO DE ULTIMO CAMBIO DE CALIFICACION'
where  tr_operacion = @i_operacionca
and    tr_tran = 'TRC'
and    tr_fecha_mov < @i_fecha_proceso

if @@error <> 0 
   return 710510


-- ACTUALIZAR LAS CALIFICACIONES DE LA TRANSACCION POR LA FINAL
update ca_transaccion
set    tr_calificacion  = @i_calificacion_final,
       tr_observacion = 'NUEVA CALIFICACION POR TRC'
where  tr_operacion = @i_operacionca
and    tr_estado    = 'CON'

if @@error <> 0 
   return 710510

----------------------------------       

exec @w_secuencial  =  sp_gen_sec
     @i_operacion   = @i_operacionca

exec @w_return = sp_trasladador
     @s_user               = @s_user,
     @s_term               = @s_term,
     @s_date               = @s_date,
     @s_ofi                = @s_ofi,
     @i_trn                = 'TRC',
     @i_toperacion         = @i_toperacion,
     @i_oficina            = @i_oficina,
     @i_banco              = @i_banco,
     @i_operacionca        = @i_operacionca,
     @i_moneda             = @i_moneda,
     @i_fecha_proceso      = @i_fecha_proceso,
     @i_gerente            = @i_gerente,
     @i_moneda_nac         = @i_moneda_nac,
     @i_garantia           = @i_garantia,
     @i_reestructuracion   = @i_reestructuracion,
     @i_cuenta_final       = @i_calificacion_final,
     @i_cuenta_antes       = @i_calificacion_antes,
     @i_calificacion       = @i_calificacion_antes,
     @i_estado_actual      = @w_estado_op,
     @i_secuencial         = @w_secuencial

         if @@error <> 0 
            return   708152
          
         if @w_return != 0 
         begin
            PRINT 'trastrc.sp Error Ejecutando sp_trasladador'
            return @w_return
         end

if @i_moneda = @i_moneda_nac
   select @w_cotizacion_hoy = 1.0
else
begin
  exec sp_buscar_cotizacion
       @i_moneda     = @i_moneda,
       @i_fecha      = @w_fecha_ult_proceso,
       @o_cotizacion = @w_cotizacion_hoy output
end

exec @w_return = sp_historicos_fin_mes
     @s_user             = @s_user,
     @s_date             = @s_date,
     @s_ofi              = @s_ofi,
     @s_term             = @s_term,
     @i_operacionca      = @i_operacionca,
     @i_fecha_proceso    = @i_fecha_proceso,
     @i_moneda_nacional  = @i_moneda_nac,  
     @i_parametro_int    = @w_parametro_int,
     @i_cotizacion       = @w_cotizacion_hoy,
     @i_concepto_cap     = @w_concepto_cap, 
     @i_causacion        = @w_causacion,    
     @i_fecultpro        = @w_fecha_ult_proceso,
     @i_gar_admisible    = @i_garantia,
     @i_reestructuracion = @i_reestructuracion,
     @i_calificacion     = @i_calificacion_final,
     @i_num_dec          = @w_num_dec_op

      if @@error <> 0   
         return 708152
         
      if @w_return != 0 
         return @w_return



return 0

go
