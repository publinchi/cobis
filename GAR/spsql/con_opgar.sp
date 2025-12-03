/*************************************************************************/
/*   Archivo:              con_opgar.sp                                  */
/*   Stored procedure:     sp_con_opgar                                  */
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

IF OBJECT_ID('dbo.sp_con_opgar') IS NOT NULL
    DROP PROCEDURE dbo.sp_con_opgar
go

create proc dbo.sp_con_opgar      
(
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @s_rol		 tinyint   = null,	--II CMI 02Dic2006
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_producto		 catalogo = null,
   @i_operac             descripcion = null,
   @i_tipo_cust          descripcion = null,
   @i_custodia           int = null,
   @i_filial             tinyint = null,
   @i_sucursal           smallint = null,
   @i_codigo_compuesto   varchar(64) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_abreviatura        descripcion,
   @w_codigo_custodia    descripcion,
   @w_contador           tinyint

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_con_opgar'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19204 and @i_operacion = 'S') 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

    if @i_codigo_compuesto is not null 
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
   
if @i_operacion = 'S'
begin
    exec sp_consult3
    @t_trn = 19475,
    @i_operacion = 'Q',
    @i_filial    = @i_filial,
    @i_sucursal  = @i_sucursal,
    @i_tipo_cust = @i_tipo_cust,
    @i_codigo_externo  = @i_codigo_compuesto,
    @s_date      = @s_date
end

--Guarda log auditoria
--II CMI 02Dic2006

	/*exec @w_return = cob_cartera..sp_trnlog_auditoria_activas
	@s_ssn 		= @s_ssn,                   
   	@i_cod_alterno	= 0,
   	@t_trn		= @t_trn,
	@i_producto	= '19',      
   	@s_date		= @s_date,
   	@s_user		= @s_user,
   	@s_term		= @s_term,
   	@s_rol		= @s_rol,
   	@s_ofi		= @s_ofi,
   	@i_tipo_trn	= @i_operacion,
   	@i_num_banco	= @i_codigo_compuesto

        if @w_return <> 0 
             begin
             /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1903003
                return 1 
        end*/


--FI CMI 02Dic2006
go