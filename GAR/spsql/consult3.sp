/*************************************************************************/
/*   Archivo:              consult3.sp                                   */
/*   Stored procedure:     sp_consult3                                   */
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
/*   lectual. Su uso no autorizado dara  derecho a  MACOSA para          */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_consult3') IS NOT NULL
    DROP PROCEDURE dbo.sp_consult3
go

create proc dbo.sp_consult3  (
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
   @i_tramite            int         = null,
   @i_codigo_externo  	 varchar(64) = null,
   @i_cliente            int         = null,
   @i_producto           varchar(20) = null,
   @i_operac             varchar(15) = null,
   @i_detalle            char(1)     = null 
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_codigo_externo     varchar(64),
   @w_abierta_cerrada    char(1),
   @w_cliente            int       

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_consult3'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19475 and @i_operacion = 'Q') 
     
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
    if @i_codigo_externo <> null
    begin
       exec sp_compuesto
       @t_trn = 19245,
       @i_operacion = 'Q',
       @i_compuesto = @i_codigo_externo,
       @o_filial    = @i_filial out,
       @o_sucursal  = @i_sucursal out,
       @o_tipo      = @i_tipo_cust out,
       @o_custodia  = @i_custodia out
    end

	/*    PGA: 27/May
	-- CODIGO EXTERNO
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
	*/
       exec @w_return = sp_riesgos2
       @i_operacion = 'S',
       @t_trn = 19614,
       @i_garantia = @i_codigo_externo,
       @i_producto = @i_producto,
       @i_operac = @i_operac,
       @s_date   = @s_date 	

       if @w_return <> 0
       begin 
          print 'No pudo retornar datos'
       end
return 0
end
go