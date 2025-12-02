/************************************************************************/
/*   Nombre Fisico:        cambprest.sp                                 */
/*   Nombre Logico:        sp_cambio_prestamista                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Ivan Jimenez                                 */
/*   Fecha de escritura:   Dic. 2006                                    */
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
/************************************************************************/
/*                            MODIFICACIONES                            */
/*      18/Dic/2006    Ivan Jimenez       Emision Inicial               */
/*    06/06/2023	 M. Cordova		 Cambio variable @w_op_calificacion */
/*									 de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_cambio_prestamista')
   drop proc sp_cambio_prestamista 
go

create procedure sp_cambio_prestamista(
   @s_user                 login,
   @s_term                 varchar(30),
   @s_date                 datetime,
   @s_ofi                  smallint,
   @i_fecha_proceso        datetime,
   @i_moneda_nac           smallint,
   @i_operacionca          int,
   @i_entidad_prestamista  catalogo
)
as 
declare
   @w_sp_name               varchar(32),
   @w_error                 int,
   @w_trn                   catalogo,
   @w_secuencial            int,
   @w_op_estado             int,
   @w_op_toperacion         catalogo,
   @w_op_oficina            smallint,
   @w_op_banco              cuenta,
   @w_op_moneda             tinyint,
   @w_op_gerente            smallint,
   @w_op_garantia           char(1),
   @w_op_reestructuracion   char(1),
   @w_op_calificacion       catalogo,
   @w_op_tipo_linea         catalogo


-- CARGAR VARIABLES DE TRABAJO
select @w_sp_name = 'sp_cambio_prestamista'
select @w_trn     = 'CPR'

-- EJECUTAR SP TRASLADADOR
select @w_op_estado           = op_estado,
       @w_op_tipo_linea       = op_tipo_linea,
       @w_op_toperacion       = op_toperacion,
       @w_op_oficina          = op_oficina,
       @w_op_banco            = op_banco,
       @w_op_moneda           = op_moneda,
       @w_op_gerente          = op_oficial,
       @w_op_garantia         = isnull(op_gar_admisible, 'N'),
       @w_op_reestructuracion = op_reestructuracion,
       @w_op_calificacion     = isnull(op_calificacion, 'A')
from   ca_operacion
where  op_operacion = @i_operacionca

-- ACTUALIZACION DE LA OBLIGACION CON TODA SU HISTORIA 
-- ACTUALIZAR LA ENTIDAD PRESTAMISTA
update ca_operacion 
set    op_tipo_linea = @i_entidad_prestamista
where  op_operacion = @i_operacionca

if @@error <> 0 
   return 705076

update ca_operacion_his
set    oph_tipo_linea = @i_entidad_prestamista
where  oph_operacion = @i_operacionca

if @@error <> 0 
    return  705076

update cob_cartera_his..ca_operacion_his
set    oph_tipo_linea = @i_entidad_prestamista
where  oph_operacion = @i_operacionca

if @@error <> 0 
    return  710002

update cob_cartera_depuracion..ca_operacion_his
set    oph_tipo_linea = @i_entidad_prestamista
where  oph_operacion = @i_operacionca

if @@error <> 0 
    return  710002

-- ANULAR LAS TRANSACCIONES ANTERIORES PARA EVITAR  CONTABILIZACION DE REVERSOS
update ca_transaccion
set    tr_estado = 'ANU',
       tr_observacion = 'ANULADA POR EFECTO DE ULTIMO CAMBIO DE PRESTAMISTA'
where  tr_operacion = @i_operacionca
and    tr_tran      = @w_trn
and    tr_fecha_mov < @i_fecha_proceso

if @@error <> 0 
   return 710510

exec @w_secuencial  =  sp_gen_sec
     @i_operacion   = @i_operacionca

exec @w_error = sp_trasladador
     @s_user               = @s_user,
     @s_term               = @s_term,
     @s_date               = @s_date,
     @s_ofi                = @s_ofi,
     @i_trn                = @w_trn,
     @i_toperacion         = @w_op_toperacion,
     @i_oficina            = @w_op_oficina,
     @i_banco              = @w_op_banco,
     @i_operacionca        = @i_operacionca,
     @i_moneda             = @w_op_moneda,
     @i_fecha_proceso      = @i_fecha_proceso,
     @i_gerente            = @w_op_gerente,
     @i_moneda_nac         = @i_moneda_nac,
     @i_garantia           = @w_op_garantia,
     @i_reestructuracion   = @w_op_reestructuracion,
     @i_cuenta_final       = @i_entidad_prestamista,
     @i_cuenta_antes       = @w_op_tipo_linea,
     @i_calificacion       = @w_op_calificacion,
     @i_estado_actual      = @w_op_estado,
     @i_secuencial         = @w_secuencial

if @@error <> 0 
   return   708152
   
if @w_error != 0 
   return @w_error

return 0

go
