/************************************************************************/
/*   Archivo           : fn_valida_telefono.sp                          */
/*   Stored procedure  : fn_valida_telefono                             */
/*   Base de datos     : cobis                                          */
/*   Producto          : CLIENTES                                       */
/*   Disenado por      : ACA    				                        */
/*   Fecha de escritura: 04-Ago-2021                                    */
/* **********************************************************************/
/*                          IMPORTANTE                                  */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de 'COBISCorp'.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Validar los digítos repetidos en un número de teléfono              */
/* **********************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA       	AUTOR                RAZON                          */
/*   04/Ago/2021   	ACA	             Versión Inicial                    */
/************************************************************************/


use cobis
go

SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go

if exists(select 1 from sysobjects where name = 'fn_valida_telefono')
   drop function fn_valida_telefono
go
create function fn_valida_telefono(
   @i_telefono varchar(16)
)
returns tinyint
as
begin
   declare 
   @w_parametro tinyint, 
   @w_numero0 varchar(16), 
   @w_validacion tinyint, 
   @w_cont tinyint
    
   select @w_cont = 0 --Se inicia el contador
   select @w_parametro = pa_tinyint from cobis..cl_parametro where pa_nemonico = 'DCTEL' and pa_producto = 'CLI'
   
   /*Contador que va desde 0 hasta 9*/
   while @w_cont <= 9
   begin
      select @w_numero0 = REPLICATE (@w_cont, @w_parametro+1)
      select @w_validacion = CHARINDEX(@w_numero0, @i_telefono)

      if @w_validacion > 0
      begin
         return 1
      end
      select @w_cont = @w_cont + 1
   end
   return 0
end
go
