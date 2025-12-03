/*************************************************************************/
/*   Archivo:              moneda.sp                                     */
/*   Stored procedure:     sp_moneda                                     */
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
IF OBJECT_ID('dbo.sp_moneda') IS NOT NULL
    DROP PROCEDURE dbo.sp_moneda
go
create proc dbo.sp_moneda (
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
   @i_moneda             tinyint = null,
   @i_param1             descripcion = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint      /* existe el registro*/

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_moneda'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19150 and @i_operacion = 'A') or
   (@t_trn <> 19151 and @i_operacion = 'V')
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,

    @i_num   = 1901006
    return 1 
end

 /* Todos los datos de la tabla */
 /*******************************/
if @i_operacion = 'A'
begin
      set rowcount 20
      if @i_modo = 0 
      begin
         if @i_moneda is null
         select @i_moneda =convert(tinyint,@i_param1) 
         select "CODIGO" = mo_moneda, 
                "DESCRIPCION" = substring(mo_descripcion,1,20),
                "SIMBOLO" = mo_simbolo 
           from cobis..cl_moneda  
         order by mo_moneda
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1 
         end
      end
      else 
      begin
         select "CODIGO" = mo_moneda, 
                "DESCRIPCION" = substring(mo_descripcion,1,20),
                "SIMBOLO" = mo_simbolo 
           from cobis..cl_moneda  
         where mo_moneda > convert(tinyint,@i_param1) 
         order by mo_moneda
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1 
         end
      end
end

if @i_operacion = 'V'
begin
      set rowcount 0
      select mo_descripcion
        from cobis..cl_moneda
       where mo_moneda = @i_moneda
      if @@rowcount = 0
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901005
         return 1 
      end 
end
go