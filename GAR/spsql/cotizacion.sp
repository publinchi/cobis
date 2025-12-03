/*************************************************************************/
/*   Archivo:              cotizacion.sp                                 */
/*   Stored procedure:     sp_cotizacion                                 */
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
IF OBJECT_ID('dbo.sp_cotizacion') IS NOT NULL
    DROP PROCEDURE dbo.sp_cotizacion
go
create proc dbo.sp_cotizacion (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
--   @s_term               descripcion = null,
   @s_term              varchar(30)   = null,
   @s_ofi                smallint  = null,
   @s_srv		 varchar(30) = null,
   @s_lsrv	  	 varchar(30) = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_moneda 		 money,
   @i_monto		 money    = null,
   @i_fecha              datetime = null,
   @o_cotiz 		 money out
)
as
declare
   @w_today		datetime,     /* fecha del dia */ 
   @w_return            int,          /* valor que retorna */
   @w_sp_name           varchar(32),  /* nombre stored proc*/
   @w_cotizacion	money


select @w_today = getdate()
select @w_sp_name = 'sp_cotizacion'

if 1 = 1
begin
     /**** ENCONTRAR LA COTIZACION DE LA MONEDA */
	select @w_cotizacion = ct_compra
	from   cob_conta..cb_cotizacion
        where  ct_moneda = @i_moneda
	and    ct_fecha in (select max(ct_fecha)
			    from cob_conta..cb_cotizacion
			    where ct_fecha <= @i_fecha
                              and ct_moneda = @i_moneda)
       
        select @o_cotiz = isnull(@w_cotizacion,1)
	return 0
end
go