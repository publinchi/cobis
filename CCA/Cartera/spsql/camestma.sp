/************************************************************************/
/*   Nombre Fisico:        camestma.sp                                  */
/*   Nombre Logico:        sp_cambio_estado_manual                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   31/08/1999                                   */
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
/*                               PROPOSITO                              */
/*   Maneja los cambios de estado manuales definidos en las operaciones */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA          AUTOR            CAMBIO                          */
/*      DIC-07-2016    Raul Altamirano  Emision Inicial - Version MX    */
/*  DIC/21/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*  DIC/28/2021   G. Fernandez          Proceso para cambios de estado  */
/*                                      en general                      */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*  21-Ago-2024   Kevin Rodríguez     R240260 Cambio estado anulado     */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_manual')
   drop proc sp_cambio_estado_manual
go

create proc sp_cambio_estado_manual
(  @s_user           login,
   @s_term           varchar(30),
   @s_date           datetime,
   @s_ofi            smallint,
   @i_toperacion     catalogo,
   @i_oficina        smallint,
   @i_banco          cuenta,
   @i_operacionca    int,
   @i_moneda         tinyint,
   @i_fecha_proceso  datetime,
   @i_en_linea       char(1),
   @i_gerente        smallint,
   @i_estado_ini     tinyint,
   @i_estado_fin     tinyint,
   @i_moneda_nac     smallint,
   @i_cotizacion     float,
   @i_tcotizacion    char(1) = 'N',
   @i_num_dec        tinyint,
   @o_msg            varchar(100) = null out

)  

as 
declare
   @w_return            int,
   @w_secuencial        int,
   @w_error             int,
   @w_estado_fin        tinyint,
   @w_est_castigo       tinyint,
   @w_trn               catalogo,
   @w_gar_admisible     char(1), 
   @w_reestructuracion  char(1), 
   @w_calificacion      catalogo, 
   @w_tr_observacion    descripcion,
   @w_op_moneda         tinyint,
   @w_est_anulado       smallint,
   @w_est_judicial      tinyint,
   @w_est_vencido_cobro_admin tinyint, --GFP 28/12/2021 Aumento de nuevas variables
   @w_base_calculo          char(1),
   @w_estado_ope        tinyint,
   @w_est_vencido       tinyint,
   @w_di_fecha_ven       date,
   @w_num_dias           int

-- CARGAR VARIABLES DE TRABAJO
select @w_trn           = 'ETM', --ETM (CAMBIO DE ESTADO MANUAL) --CAS (CASTIGOS) 
       @w_secuencial    = 0,
       @w_tr_observacion = 'CAMBIO DE ESTADO MANUAL'


--CARGAR ESTADOS POSIBLES ESTADOS MANUALES: SOLO CASTIGADO Y ANULADO
exec @w_error = sp_estados_cca
@o_est_castigado            = @w_est_castigo   out,
@o_est_anulado              = @w_est_anulado   out,
@o_est_judicial             = @w_est_judicial  out,
@o_est_vencido              = @w_est_vencido   out, --GFP 28/12/2021
@o_est_vencido_cobro_admin  = @w_est_vencido_cobro_admin out

-- DATOS DE LA OPERACION
select @w_gar_admisible     = op_gar_admisible,    
       @w_reestructuracion  = op_reestructuracion, 
       @w_calificacion      = op_calificacion,     
       @w_op_moneda         = op_moneda,
	   @w_base_calculo       = op_base_calculo         --GFP 28/12/2021  
from   ca_operacion
where  op_operacion = @i_operacionca

--GFP 28/12/2021 SE OBTIENE LA FECHA DEL DIVIDENDO MAS VENCIDO 
select @w_di_fecha_ven = di_fecha_ven
from   ca_dividendo
where  di_operacion    = @i_operacionca
and    di_dividendo    = (select isnull(min(di_dividendo), 0)
                            from   ca_dividendo
                            where  di_operacion  = @i_operacionca
                            and    di_estado     = @w_est_vencido)

--GFP 28/12/2021 Se calcula el número de dias con base de calculo comercial
if @w_base_calculo = 'E' 
begin
   exec @w_return = sp_dias_cuota_360
   @i_fecha_ini   = @w_di_fecha_ven,
   @i_fecha_fin   = @i_fecha_proceso,
   @o_dias        = @w_num_dias out

   if @w_return <> 0 return @w_return

   select @w_num_dias = isnull(@w_num_dias,0) + 1
  
end
else --base de calculo real
   select @w_num_dias = isnull(datediff(dd,@w_di_fecha_ven, @i_fecha_proceso),0) + 1

--GFP 28/12/2021 SELECCIONAR EL NUEVO ESTADO DE LA OPERACION DE ACUERDO AL NUMERO DE DIAS
select @w_estado_ope  = max(em_estado_fin)
from   ca_estados_man
where  em_toperacion  = @i_toperacion
and    em_tipo_cambio = 'M'
and    em_estado_ini  = @i_estado_ini
and    em_dias_cont  <= @w_num_dias
and    em_dias_fin   >= @w_num_dias   

if @@rowcount = 0
   return 0

-- CONDICION DE SALIDA
if @i_estado_fin is null 
   return 0

if @i_estado_ini = @i_estado_fin
   return 0
--GFP 28/12/2021 Se valida que el nuevo estado de la operación coincida con el obtenido de la parametrización de acuerdo al número de días
if (@w_estado_ope = @i_estado_fin )
	select @w_estado_fin = @i_estado_fin   
else 
	return 725134 --'El número de días no coincide con la parametrización'

if (@w_estado_fin = @w_est_castigo or @w_estado_fin = @w_est_judicial or @w_estado_fin = @w_est_vencido_cobro_admin) --GFP 28/12/2021 Validación de cambios de estados manuales
begin
   exec @w_error   = sp_cambio_estado_manual_general
   @s_user         = @s_user,
   @s_term         = @s_term,
   @i_operacionca  = @i_operacionca,
   @i_cotizacion   = @i_cotizacion,
   @i_tcotizacion  = @i_tcotizacion,
   @i_num_dec      = @i_num_dec,
   @i_estado_fin   = @w_estado_fin,
   @o_msg          = @o_msg out

   if @w_error <> 0 return @w_error

end

if @w_estado_fin = @w_est_anulado
begin
  
   exec @w_error   = sp_cambio_estado_anulado
   @s_user         = @s_user,
   @s_term         = @s_term,
   @i_operacionca  = @i_operacionca

   if @w_error <> 0 
      return @w_error

end

return 0

go
