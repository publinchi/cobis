/********************************************************************/
/*   NOMBRE LOGICO:         fn_digito_verif_dui                     */
/*   NOMBRE FISICO:         fn_digito_verif_dui                     */
/*   BASE DE DATOS:         cobis                                   */
/*   PRODUCTO:              Clientes                                */
/*   DISENADO POR:          P. Jarrin.                              */
/*   FECHA DE ESCRITURA:    25-Abr-2023                             */
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
/*   Funcion de validacion del digito verificador del DUI           */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   25-Abr-2023        P. Jarrin.      Emision Inicial             */
/*   19-Jul-2023        P. Jarrin.      Se ajusta validacion-R211476*/
/********************************************************************/

use cobis
go

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select * from sysobjects where name = 'fn_digito_verif_dui')
    drop function fn_digito_verif_dui
go

create function fn_digito_verif_dui (@w_dui varchar(10)) returns int
begin
   declare 
      @w_vtdui          varchar(9),
      @w_vgdigito       int,
      @w_vtsuma         int,
      @w_vtresta        int,      
      @w_modulo         int,
      @w_posicion       int,
      @w_vti            int,      
      @w_vtnumero       int,
      @w_vtn            int,
      @w_vtconstante    int,
      @w_vtdig          int,
      @w_return         int

   select 
      @w_vtdui       = '',
      @w_vtsuma      = 0,
      @w_vtresta     = 0,
      @w_modulo      = 10,
      @w_vti         = 1,
      @w_return      = 0

   select @w_dui      = replicate ('0',(10 - len(@w_dui))) + convert(varchar, @w_dui)
   select @w_vtdui    = ltrim(rtrim(replace(@w_dui,'-', '')))
   select @w_posicion = datalength(@w_vtdui)
   
   if (datalength(@w_vtdui) = 9)
   begin
       select @w_vgdigito = convert(int, substring(@w_vtdui, @w_posicion, 1))
       
       while @w_posicion > 1
       begin
          select @w_vtnumero = convert(int, substring(@w_vtdui, @w_vti, 1))
          select @w_vtsuma   = @w_vtsuma + @w_posicion * @w_vtnumero
          select @w_posicion = @w_posicion - 1
          select @w_vti      = @w_vti + 1
       end
 
       select @w_vtdig = @w_vtsuma % @w_modulo
       if(@w_vtdig = 0)
       begin
            select @w_vtresta = 0
       end
       else
       begin
            select @w_vtresta = 10 - @w_vtdig
       end

       if ((@w_vtsuma = 0) or (@w_vgdigito != @w_vtresta))
       begin
            select @w_return = 1
       end
       else
       begin
            select @w_return = 0
       end
   end
   else
   begin
         select @w_return = 1
   end   
   return @w_return
end
go
