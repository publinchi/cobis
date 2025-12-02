/************************************************************************/
/*      Nombre Fisico:          iocbatch.sp                             */
/*      Nombre Logico:          sp_aplicacion_ioc_batch                 */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira PElaez                           */
/*      Fecha de escritura:     dic. 2005                               */
/************************************************************************/
/*                              IMPORTANTE                              */
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
/*                         PROPOSITO                                    */
/*      Este sp tiene como propósito la aplicación en batch de los IOC  */
/*      que por efecto de Fecha valor se han quedado NA                 */
/************************************************************************/  
/*			                  MODIFICACIONES		                    */
/*	FECHA	     AUTOR	      RAZON		                                */
/*	mayo-2006    Elcira Pelaez    def 6515 BAC              	        */
/*	Enero-2007   Elcira Pelaez    def 7722 BAC              	        */
/*	Mayo-2007    Elcira Pelaez    def 8297 BAC el estado del            */
/*                                    IOC es el del div VIGENTE 	    */
/*                                    o estado VENCIDO          	    */
/*  Ago-22/07    John Jairo Rendon Optimizacion                     	*/
/*  06/06/2023	 M. Cordova		  Cambio variable @i_calificacion,   	*/
/* 								  de char(1)  a catalogo				*/
/*																		*/
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_aplicacion_ioc_batch')
   drop proc sp_aplicacion_ioc_batch
go


---INC. 56187 BAR.16.2012

create proc sp_aplicacion_ioc_batch
   @s_date                 datetime    = null,
   @s_user                 login       = null,
   @s_term                 descripcion = null,
   @s_ofi                  smallint    = null,
   @i_banco                cuenta      = null,
   @i_operacionca          int         = null,
   @i_toperacion           catalogo    = null,
   @i_fecha_ult_proceso    datetime    = null,
   @i_reestructuracion     char(1)     = null,
   @i_calificacion         catalogo     = null,
   @i_oficina              int         = null,
   @i_gar_admisible        char(1)     = null,
   @i_moneda               smallint    = 0,
   @i_moneda_nacional      smallint    = 0,
   @i_sector                catalogo    = null,
   @i_num_dec              float       = 0,
   @i_gerente              smallint    = null,
   @i_desde_batch          char(1)     = 'S',
   @i_en_linea             char(1)     = 'N'

as
declare
@w_sp_name		     varchar(30),
@w_oc_monto         money,
@w_oc_concepto      catalogo,
@w_oc_div_desde     smallint,
@w_oc_div_hasta     smallint,
@w_oc_base_calculo  money,
@w_oc_secuencial    int,
@w_estado_ioc       int,
@w_div_actual       smallint,
@w_secuencial       int,
@w_error            int,
@w_valor_tot        money,
@w_monto_uvr        money,
@w_codvalor         int,
@w_tasa             float,
@w_ru_referencial   catalogo,
@w_monto_mn         money,
@w_cotizacion       float,
@w_oc_referencia    descripcion,
@w_estado_op        int,   
@w_min_div          smallint ,
@w_di_desde         smallint  

SET ANSI_WARNINGS OFF

--- INICIALIZACION VARIABLES 
select @w_sp_name = 'sp_aplicacion_ioc_batch'


       
declare cursor_aplicacion_ioc cursor for 
select
oc_monto,
oc_concepto,
oc_div_desde,
oc_div_hasta,
oc_base_calculo,
oc_secuencial,
oc_referencia
from   ca_otro_cargo
where oc_operacion = @i_operacionca          
and oc_fecha <=  @i_fecha_ult_proceso    
and   oc_estado = 'NA'

for read only

open   cursor_aplicacion_ioc

fetch cursor_aplicacion_ioc into

@w_oc_monto,
@w_oc_concepto,
@w_oc_div_desde,
@w_oc_div_hasta,
@w_oc_base_calculo,
@w_oc_secuencial,
@w_oc_referencia

while @@fetch_status = 0
begin

   exec @w_error     = sp_otros_cargos
   @s_date           = @s_date,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_ofi			 = @s_ofi,
   @i_banco          = @i_banco,
   @i_operacion      = 'I',
   @i_desde_batch    = @i_desde_batch,   
   @i_en_linea       = @i_en_linea,
   @i_secuencial     = @w_oc_secuencial,
   @i_concepto       = @w_oc_concepto,
   @i_monto          = @w_oc_monto,      
   @i_base_calculo   = @w_oc_base_calculo,      
   @i_div_desde      = @w_oc_div_desde,      
   @i_div_hasta      = @w_oc_div_hasta,
   @i_comentario     = @w_oc_referencia      
         
   if @w_error <> 0 
   begin
      close cursor_aplicacion_ioc
      deallocate cursor_aplicacion_ioc
      goto ERROR
   end    
   
   fetch  cursor_aplicacion_ioc into
   @w_oc_monto,
   @w_oc_concepto,
   @w_oc_div_desde,
   @w_oc_div_hasta,
   @w_oc_base_calculo,
   @w_oc_secuencial,
   @w_oc_referencia
   
end --WHILE CURSOR RUBROS

close cursor_aplicacion_ioc
deallocate cursor_aplicacion_ioc

return 0

ERROR:

return @w_error

go
