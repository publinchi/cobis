/*************************************************************************/
/*   Archivo:              externo.sp                                    */
/*   Stored procedure:     sp_externo                                    */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA           AUTOR RAZON                                        */
/*    Marzo/2019            emision inicial                              */
/*    25-06-2021      PQU   ajustes por integracion de version base XSELL*/
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_externo') IS NOT NULL
    DROP PROCEDURE dbo.sp_externo
go
create proc dbo.sp_externo    (
   @i_filial             tinyint = null,
   @i_sucursal           smallint = null,
   @i_tipo               varchar(64) = null,
   @i_custodia           int = null,
   @o_compuesto          varchar(64) out 
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_parte              tinyint,
   @w_inicio             tinyint,
   @w_contador           tinyint,
   @w_longitud           tinyint,
   @w_caracter           char(1),
   @w_compuesto          varchar(64) ,
   @w_ceros              varchar(10)

select @w_compuesto = '' 

if @i_sucursal < 10
   select @w_compuesto = '000'+convert(varchar(4),@i_sucursal)+@i_tipo  --se añadió 2 ceros 
ELSE --PQU
   if @i_sucursal < 100 AND @i_sucursal >= 10
       select @w_compuesto = '00'+convert(varchar(4),@i_sucursal)+@i_tipo   
   ELSE   
       if @i_sucursal < 1000 AND @i_sucursal >= 100
   select @w_compuesto = '0'+convert(varchar(4),@i_sucursal)+@i_tipo
       else  --fin PQU    
   select @w_compuesto = convert(varchar(4),@i_sucursal)+@i_tipo

--select @w_ceros = '000000'
select @w_ceros = '0000000000'

--select @w_longitud = datalength (convert(varchar(6),@i_custodia))
select @w_longitud = datalength (convert(varchar(10),@i_custodia))

--select @w_compuesto = @w_compuesto +                
--                      substring(@w_ceros,1,6-@w_longitud) +
--                      convert(varchar(6),@i_custodia)
select @w_compuesto = @w_compuesto +                
                      substring(@w_ceros,1,10-@w_longitud) +
                      convert(varchar(10),@i_custodia)

select @o_compuesto = @w_compuesto
go