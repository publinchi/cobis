/************************************************************************/
/*  Archivo:                sp_cons_productos_linea.sp                  */
/*  Stored procedure:       sp_cons_productos_linea                     */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_cons_productos_linea' and type = 'P')
   drop proc sp_cons_productos_linea
go

create proc sp_cons_productos_linea (
        @s_sesn            	int,
        @s_user            	login,
        @s_date            	datetime,
        @s_term            	varchar(30),
        @s_ofi             	int,	
        @i_toperacion      	varchar(25) = null
)
as 
	declare @w_sp_name varchar(32)

select @w_sp_name = 'sp_cons_productos_linea'

	if @i_toperacion is not null
	begin
		SELECT pl_producto, pl_descripcion, pl_riesgo
		FROM cob_credito..cr_productos_linea
		where pl_toperacion = @i_toperacion
	end
	
	if @@rowcount = 0
	begin
	exec cobis..sp_cerror
        @t_from  = @w_sp_name,
        @i_num   = 2110101
	end

return 0


GO
