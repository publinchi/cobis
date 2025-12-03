/************************************************************************/
/*  Nombre Fisico:        marca_reestructura.sp                         */
/*  Nombre Logico:        sp_marca_reestructura                         */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         Guisela Fernández                             */
/*  Fecha de escritura:   01/Ago/2022                                   */
/************************************************************************/
/*             IMPORTANTE                                               */
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
/*                        PROPOSITO                                     */
/*  Se marca la restructuración para los diferentes flujos que puede    */
/*  tener un préstamo                                                   */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  01/Ago/2022   G. Fernandez    Emision Inicial                       */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_marca_reestructura')
   drop proc sp_marca_reestructura
go

create proc sp_marca_reestructura (
   @s_date           DATETIME, 
   @i_banco          cuenta,     -- Número de operación
   @i_tipo           char(1)     -- Tipo de tramite
)
as
declare
@w_sp_name           varchar(30),
@w_return            INT,
@w_calificacion      catalogo,
@w_tramite           int

-- Proceso de refinanciamineto
if @i_tipo = 'F'
begin
   select @w_tramite = op_tramite from ca_operacion
   where op_banco = @i_banco
   
   select @w_calificacion = max(op_calificacion)
   from ca_operacion
   where op_banco     in   (select or_num_operacion
                           from cob_credito..cr_op_renovar
                           where or_tramite   = @w_tramite)

   
   update ca_operacion
   set op_calificacion     = @w_calificacion,
       op_reestructuracion = 'S',
       op_fecha_reest      = @s_date,
	   op_numero_reest     = isnull(op_numero_reest,0) + 1  
   where  op_banco         = @i_banco
   
   if @@error != 0 begin
   select @w_return = 725169 
   return @w_return
   end
end

-- Proceso para cambio de garantía
if @i_tipo = 'G'
begin
   
   update ca_operacion
   set op_reestructuracion  = 'S',
       op_fecha_reest       = @s_date,
	   op_numero_reest      = isnull(op_numero_reest,0) + 1  
   where  op_banco          = @i_banco
   
   if @@error != 0 begin
   select @w_return = 725170
   return @w_return
   end
end
return 0

go
