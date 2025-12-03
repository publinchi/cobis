/********************************************************************/
/*   NOMBRE LOGICO:      cuotadic.sp	                            */
/*   NOMBRE FISICO:      sp_cuotas_adicionales                      */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Fabian de la Torre, Rodrigo Garces         */
/*   FECHA DE ESCRITURA: Ene. 1998                                  */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*	S: Manejo de las cuotas adicionales			                    */
/*	U: Actualizacion del valor de cuotas adicionales a TEMP         */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   18-Ene-1998        A. Ramirez       Emision Inicial            */
/*   27-Ene-2023        G. Fernandez     Actualizaciones para BLIs  */
/*   10-Feb-2023        G. Fernandez     Validación de monto de cuo-*/
/*                                       tas adicionales            */
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cuotas_adicionales')
	drop proc sp_cuotas_adicionales
go

create proc sp_cuotas_adicionales
   @t_trn                   INT     = NULL, --GFP Cambio de Servicios a Blis
   @i_operacion             char(1) = NULL,
   @i_banco                 cuenta  = NULL,
   @i_dividendo             int     = NULL,
   @i_valor			        money   = 0, 
   @i_formato_fecha		    int     = null,
   @i_siguiente             int     = 0  
as

declare @w_sp_name			descripcion,
	    @w_operacionca		int,
	    @w_moneda			smallint,
	    @w_error			int,
        @w_monto_op         money,
        @w_num_dec          tinyint,
        @w_total_cutadic    money


select @w_sp_name = 'sp_cuotas_adicionales'

select 
@w_operacionca    = opt_operacion,
@w_moneda	      = opt_moneda	
from ca_operacion_tmp
where opt_banco   = @i_banco

if @@rowcount = 0 begin
    select @w_error = 701025
    goto ERROR
end

/** MANEJO DE DECIMALES **/
exec sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out


/** BUSQUEDA DE CUOTAS ADICIONALES **/
if @i_operacion = 'S' begin
   set rowcount  20
   
   select 
   cat_dividendo,
   convert(varchar(10),dit_fecha_ven,@i_formato_fecha), 
   cat_cuota,
   dit_de_capital
   from ca_cuota_adicional_tmp, ca_dividendo_tmp
   where cat_operacion = @w_operacionca
   and   dit_operacion = cat_operacion
   and   dit_dividendo = cat_dividendo
   and   cat_dividendo > @i_siguiente
   order by cat_dividendo

   select 20 

   set rowcount 0      
   return 0

end


/**  ACTUALIZACION DEL VALOR DE LA CUOTA  **/
if @i_operacion = 'U' begin

   select @w_monto_op = opt_monto
   from ca_operacion_tmp
   where opt_operacion = @w_operacionca

   select @w_total_cutadic = isnull(sum(cat_cuota),0)
   from ca_cuota_adicional_tmp
   where cat_operacion = @w_operacionca
   and cat_dividendo <> @i_dividendo --GFP sumatoria de cuotas_adicionales diferentes al dividendo ha actualizar
    
   if @w_monto_op < @i_valor + @w_total_cutadic  begin
      select @w_error = 708126
      goto ERROR
   end
    
   update ca_cuota_adicional_tmp set 
   cat_cuota = round(@i_valor, @w_num_dec)
   where cat_operacion = @w_operacionca
   and cat_dividendo = @i_dividendo

   if @@error != 0 begin
      select @w_error = 703102
      goto ERROR
   end

   return 0
end


ERROR:
exec cobis..sp_cerror 
@t_debug  = 'N',    
@t_file   = null,  
@t_from   = @w_sp_name,   
@i_num    = @w_error
return @w_error
go
