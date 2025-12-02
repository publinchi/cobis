/*************************************************************************/
/*   Archivo:              intcre07.sp                                   */
/*   Stored procedure:     sp_intcre07                                   */
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
IF OBJECT_ID('dbo.sp_intcre07') IS NOT NULL
    DROP PROCEDURE dbo.sp_intcre07
go
create proc dbo.sp_intcre07  (
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
   @i_codigo_externo     varchar(64) = null,
   @i_operacion          cuenta      = null


)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_contador           tinyint,
   @w_gar                varchar(64),
   @w_gac                varchar(64),
   @w_vcu                varchar(64)

select @w_today = getdate()
select @w_sp_name = 'sp_intcre07'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19554 and @i_operacion = 'S') 
     
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

   select @w_gac = pa_char + '%' -- TIPOS GARANTIAS AL COBRO
     from cobis..cl_parametro
    where pa_producto = 'GAR'
      and pa_nemonico = 'GAC'

   select @w_vcu = pa_char + '%' -- TIPOS VALORES EN CUSTODIA
     from cobis..cl_parametro
    where pa_producto = 'GAR'
      and pa_nemonico = 'VCU'

      select cu_codigo_externo,cu_tipo,cu_descripcion,cu_valor_actual,
             cu_moneda
        from cu_custodia,cob_credito..cr_gar_propuesta,cob_credito..cr_tramite
       where tr_numero_op_banco = @i_operacion
         and tr_tramite         = gp_tramite
         and gp_garantia        = cu_codigo_externo
         and cu_abierta_cerrada = 'C'      
         and cu_garante         <> null      -- POSEA GARANTE
         and cu_estado         not in ('A','C')  -- NO CANCELADAS
         and cu_tipo      not like @w_vcu
         and (cu_codigo_externo>@i_codigo_externo or @i_codigo_externo is NULL)
       order by cu_codigo_externo
end
go