/*************************************************************************/
/*   Archivo:              intcre05.sp                                   */
/*   Stored procedure:     sp_intcre05                                   */
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
IF OBJECT_ID('dbo.sp_intcre05') IS NOT NULL
    DROP PROCEDURE dbo.sp_intcre05
go
create proc dbo.sp_intcre05  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_producto           char(64) = null,
   @i_modo               smallint = null,
   @i_cliente            int = null,
   @i_ente               int = null,
   @i_filial 		 tinyint = null,
   @i_sucursal		 smallint = null,
   @i_tipo_cust		 varchar(64) = null,
   @i_custodia 		 int = null,
   @i_garante  		 int = null,
   @i_opcion             tinyint = null,
   @i_codigo_compuesto   varchar(64) = null


)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_contador           tinyint,
   @w_gar                varchar(64)

select @w_today = getdate()
select @w_sp_name = 'sp_intcre05'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19534 and @i_operacion = 'S') 
     
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
   select @w_gar = pa_char + '%' -- TIPOS GARANTIA
     from cobis..cl_parametro
    where pa_producto = 'GAR'
      and pa_nemonico = 'GAR'

   if @i_opcion = 1   -- GARANTES DE UN CLIENTE
   begin
      select cu_garante,p_p_apellido + ' '+p_s_apellido+ ' '+en_nombre
        from cu_custodia,cu_cliente_garantia,cobis..cl_ente
       where cg_ente        = @i_cliente
         and cu_filial      = cg_filial 
         and cu_sucursal    = cg_sucursal
         and cu_tipo        = cg_tipo_cust
         and cu_custodia    = cg_custodia
         and cu_garante    <> null      -- POSEA GARANTE
         and cu_estado     not in ('A','C') -- NO CANCELADAS
         and cu_garante     = en_ente
         and (cu_garante > @i_ente or @i_ente is null)
       order by cu_garante
   end

   if @i_opcion = 2   -- CLIENTES DE UN GARANTE 
   begin
      set rowcount 20
      select cg_ente,cg_nombre
        from cu_custodia,cu_cliente_garantia
       where cu_garante     = @i_garante
         and cu_filial      = cg_filial 
         and cu_sucursal    = cg_sucursal
         and cu_tipo        = cg_tipo_cust
         and cu_custodia    = cg_custodia
         and cu_garante    <> null      -- POSEA GARANTE
         and cu_estado     not in ('A','C') -- NO CANCELADAS
         and (cg_ente > @i_ente or @i_ente is null)
       order by cg_ente
   end
end
go