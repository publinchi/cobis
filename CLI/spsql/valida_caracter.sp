/************************************************************************/
/*  Archivo:                valida_caracter.sp                          */
/*  Function:               fn_valida_caracter                          */
/*  Producto:               Clientes                                    */
/*  Disenado por:           Bruno Duenas                                */
/*  Fecha de escritura:     17-09-2021                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es una funcion para manejo de caracteres especiales  */
/************************************************************************/
/*                        MODIFICACIonES                                */
/*  FECHA       AUTOR           RAZon                                   */
/*  17-09-2021  BDU             Emision inicial                         */
/************************************************************************/
use cob_interface

go
set ANSI_NULLS on
go
set QUOTED_IDENTIFIER on
go

if exists (select 1 from sysobjects where name = 'fn_valida_caracter')
   drop function fn_valida_caracter
go

create function [dbo].[fn_valida_caracter](
   @i_cadena                 varchar(264),
   @i_caracteres_permitidos  varchar(100)
)
returns varchar(3)
as
begin
   declare @w_position       int,
           @w_caracter       varchar(3) = null
        
   select @w_position = patindex('%[^' + @i_caracteres_permitidos + ' ]%', @i_cadena )  
   if(@w_position <> 0)
   begin
      set @w_caracter = (select substring(@i_cadena, @w_position, 1))
	  set @w_caracter = '(' + @w_caracter + ')'
   end
   
   return @w_caracter
   
      
end

go
