/*************************************************************************/
/*   Archivo:              consult2.sp                                   */
/*   Stored procedure:     sp_consult2                                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
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
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_consult2') IS NOT NULL
    DROP PROCEDURE dbo.sp_consult2
go

create proc dbo.sp_consult2  (
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
   @i_operacion          char(1)     = null,
   @i_modo               smallint    = null,
   @i_filial             tinyint     = null,
   @i_sucursal           smallint    = null,
   @i_tipo_cust          varchar(64) = null,
   @i_custodia           int         = null,
   @i_secuencial         smallint    = null,
   @i_item               tinyint     = null,
   @i_codigo_compuesto	 varchar(64) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_consult2'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19465 and @i_operacion = 'Q') 
     
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

if @i_operacion = 'Q'
begin
        if @i_codigo_compuesto <> null
        begin
           exec sp_compuesto
           @t_trn = 19245,
           @i_operacion = 'Q',
           @i_compuesto = @i_codigo_compuesto,
           @o_filial    = @i_filial out,
           @o_sucursal  = @i_sucursal out,
           @o_tipo      = @i_tipo_cust out,
           @o_custodia  = @i_custodia out
       end

   set rowcount 20

   select isnull(ic_secuencial,1),it_nombre,ic_valor_item
     from cu_item,cu_item_custodia
    where ic_filial    = @i_filial
      and ic_sucursal  = @i_sucursal
      and ic_tipo_cust = @i_tipo_cust
      and ic_custodia  = @i_custodia
      and ic_tipo_cust = it_tipo_custodia
      and ic_item      = it_item
      and ((ic_secuencial > @i_secuencial or 
          (ic_secuencial = @i_secuencial and it_item > @i_item)) or
           @i_secuencial is null)
    order by ic_secuencial,ic_item
      
    if @@rowcount = 0
       return 1
    else
       return 0 
end
go