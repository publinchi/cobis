/*************************************************************************/
/*   Archivo:              consulta_garantia.sp                          */
/*   Stored procedure:     sp_consulta_garantia                          */
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

IF OBJECT_ID('dbo.sp_consulta_garantia') IS NOT NULL
    DROP PROCEDURE dbo.sp_consulta_garantia
go

create proc dbo.sp_consulta_garantia (
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
   @i_filial             tinyint  = null,
   @i_sucursal           smallint = null,
   @i_tipo               descripcion = null,
   @i_custodia           int  = null, 
   @i_cliente            int  = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo               descripcion,
   @w_custodia           int,
   @w_estado             catalogo,
   @w_valor_inicial      money,
   @w_valor_actual       money,
   @w_moneda             tinyint,
   @w_cliente            int,
   @w_descripcion        varchar(255),
   @w_error		 int,
   @w_abier_cerrada      char(1) 

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_consulta_garantia'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19214 and @i_operacion = 'S') 
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
      set rowcount 20
         select "SUCURSAL"=cu_sucursal,
                "GARANTIA" = cu_custodia, "TIPO" = cu_tipo,
                "ESTADO" = cu_estado, "CLASE" = cu_abierta_cerrada,
                "DESCRIPCION" = cu_descripcion, 
		"VALOR ACTUAL" = cu_valor_actual,
                "MONEDA" = cu_moneda
         from cu_custodia with(index(cu_custodia)),cu_cliente_garantia
         where  cu_filial     = @i_filial
           and  cu_filial     = cg_filial
           and  cu_sucursal   = cg_sucursal
           and  cu_tipo       = cg_tipo_cust
           and  cu_custodia   = cg_custodia
           and  cg_ente       = @i_cliente
           and  ((cu_sucursal > @i_sucursal or (cu_sucursal = @i_sucursal
           and cu_tipo > @i_tipo) 
                 or (cu_sucursal = @i_sucursal and cu_tipo = @i_tipo and 
                     cu_custodia > @i_custodia)) 
                         or @i_custodia is null)  
	 order by  cu_sucursal,  cu_custodia, cu_tipo
          if @@rowcount = 0
             print 'NO EXISTEN REGISTROS'
             return 1 
end
go