/************************************************************************/
/*  Archivo:            clconxml.sp                                     */
/*  Function:           fn_concatena                                    */
/*  Base de datos:      cobis                                           */
/*  Producto:           CLIENTES                                        */
/*  Disenado por:       RIGG   				                            */
/*  Fecha de escritura: 30-Abr-2019                                     */
/************************************************************************/
/*                           IMPORTANTE                                 */
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
/************************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA       	AUTOR                RAZON                          */
/*   30/Abr/2019   	RIGG	             Versión Inicial Te Creemos     */
/*   07/Jul/2020    FSAP                 Estandarizacion Clientes       */
/************************************************************************/
use cobis
go

SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go

if exists (select * from sysobjects where name = 'fn_concatena')
    drop function fn_concatena
go

create function fn_concatena
(
  @w_tabla  char(30),
  @w_codigo varchar(10)
)
returns varchar(255)
as
begin
  declare @w_valor varchar(255)

  select
    @w_valor = ''

  select
    @w_valor = @w_valor + valor
  from   cobis..cl_tabla T,
         cobis..cl_catalogo C
  where  T.tabla   = @w_tabla
     and C.tabla   = T.codigo
     and @w_codigo = case
                       when charindex('-',
                                      C.codigo) > 0 then substring(C.codigo,
                                                                   1,
                                                                   charindex(
                                                                   '-',
     C.codigo)
     - 1)
     else C.codigo
     end
  order  by substring(C.codigo,
                      charindex('-', C.codigo) + 1,
                      len(C.codigo))

  return @w_valor
end

go

