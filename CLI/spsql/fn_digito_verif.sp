/* **********************************************************************/
/*   Archivo:                fn_digito_verif.sp                         */
/*   Stored procedure:       fn_digito_verif                            */
/*   Base de datos:          COBIS                                      */
/*   Producto:               CLIENTES                                   */
/*   Disenado por:           RIGG   				                    */
/*   Fecha de escritura:     30-Abr-2019                                */
/* **********************************************************************/
/*                            IMPORTANTE                                */
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
/* **********************************************************************/
/*                             PROPOSITO                                */
/* **********************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA       	AUTOR                RAZON                          */
/*   30/Abr/2019   	RIGG	             Versión Inicial Te Creemos     */
/* **********************************************************************/
use cobis
go

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select * from sysobjects where name = 'fn_digito_verif')
    drop function fn_digito_verif
go

create function fn_digito_verif (@w_nit char(9)) returns char(10)
begin
   declare 
      @w_vtnit          char(9),
      @w_vgtabdigito    char(30),
      @w_vtsuma         smallint,
      @w_modulo         smallint,
      @w_i              smallint,
      @w_vtnumero       smallint,
      @w_vtn            smallint,
      @w_vtconstante    smallint,
      @w_vtdig          smallint

   select 
      @w_vtnit       = @w_nit,
      @w_vgtabdigito = '716759534743413729231917130703',
      @w_vtsuma      = 0,
      @w_modulo      = 11

   select @w_i = datalength(@w_vtnit)

   while @w_i > 0
   begin
      select @w_vtnumero    = convert(int, substring(@w_vtnit, @w_i, 1))
      select @w_vtn         = @w_i + 15 - datalength(@w_vtnit)
      select @w_vtconstante = convert(int, substring(@w_vgtabdigito, (2 * @w_vtn), 1)) + 10 * convert(int, substring( @w_vgtabdigito, (2 *  @w_vtn - 1), 1))
      select @w_vtsuma      = @w_vtsuma + @w_vtnumero * @w_vtconstante
      select @w_i           = @w_i - 1
   end --while
 
   select @w_vtdig = @w_vtsuma % @w_modulo

   if @w_vtdig > 1
      select @w_vtdig = 11 - @w_vtdig

   return convert(char(10), convert(numeric(9, 0), @w_nit) * 10 + @w_vtdig)
end

go

