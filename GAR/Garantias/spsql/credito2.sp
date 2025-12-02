/*************************************************************************/
/*   Archivo:              credito2.sp                                   */
/*   Stored procedure:     sp_credito2                                   */
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
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_credito2') IS NOT NULL
    DROP PROCEDURE dbo.sp_credito2
go
create proc dbo.sp_credito2  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_codigo_externo     descripcion = null,
   @i_cliente            int = null,
   @i_grupo              int = null

)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int

select @w_today = getdate()
select @w_sp_name = 'sp_credito2'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19424 and @i_operacion = 'S') 
     
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

if @i_operacion = 'S'
begin
   exec sp_credcon2
        @t_trn            = 19425,
        @i_operacion      = 'S',
        @i_cliente        = @i_cliente,
        @i_estado         = 'V',  -- (V)igente
        @i_grupo          = @i_grupo
 
   exec sp_credcon2
        @t_trn            = 19425,
        @i_operacion      = 'S',
        @i_cliente        = @i_cliente,
        @i_estado         = 'P',  -- (P)ropuesta
        @i_grupo          = @i_grupo
 
   exec sp_credcon2
        @t_trn            = 19425,
        @i_operacion      = 'S',
        @i_cliente        = @i_cliente,
        @i_estado         = 'E',  -- (E)xcepcionada
        @i_grupo          = @i_grupo

   exec sp_credcon2
        @t_trn            = 19425,
        @i_operacion      = 'S',
        @i_cliente        = @i_cliente,
        @i_grupo          = @i_grupo
end
go