/************************************************************************/
/*  Archivo:                valida_cuenta_ahorros.sp                    */
/*  Stored procedure:       sp_valida_cuenta_ahorros                    */
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

if exists (select 1 from sysobjects where name = 'sp_valida_cuenta_ahorros' and type = 'P')
   drop proc sp_valida_cuenta_ahorros
go


create proc sp_valida_cuenta_ahorros (
	@s_ssn                int         = null,
	@s_user               varchar(30) = null,
	@s_sesn               int         = null,
	@s_term               varchar(30) = null,
	@s_date               datetime    = null,
	@s_srv                varchar(30) = null,
	@s_lsrv               varchar(30) = null,
	@s_ofi                smallint    = null,
	@t_trn                int         = null,
	@t_debug              char(1)     = 'N',
	@t_file               varchar(14) = null,
	@t_from               varchar(30) = null,
	@s_rol                smallint    = null,
	@s_org_err            char(1)     = null,
	@s_error				int       = null,
	@s_serv               tinyint     = null,
	@s_msg                descripcion = null,
	@s_org                char(1)     = null,
	@t_rty                char(1)     = null,
	@i_version            smallint    = null,
	@i_id_proceso         smallint    = null,
	@i_cliente	  		  int,
	@i_monto_solicitado	  money,
	@o_valida_monto		  smallint out
)
as
declare
	@w_monto_parcial money,
	@w_disponible money,
	@w_porcentaje float,
	@w_grupo int,
	@w_representante int

-- LGU-ini: control para validar o no con cobis-ahorros
if 'S' != (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' -- existe validacion con cobis-ahorros
         and pa_producto = 'CCA')
begin
	select @o_valida_monto = 1
   return 0
end
-- LGU-fin: control para validar o no con cobis-ahorros


	--Porcentaje 50%
	select @w_porcentaje = 50

	--Monto en base al porcentaje definido
	select @w_monto_parcial = @i_monto_solicitado / (100/@w_porcentaje)

	--Se obtiene el grupo
	select @w_grupo = cg_grupo
	from cobis..cl_cliente_grupo
	where cg_ente = @i_cliente

	--Se obtiene representante del grupo
	select @w_representante = gr_representante
	from cobis..cl_grupo
	where gr_grupo = @w_grupo


	if @w_representante = @i_cliente
	begin
		select @w_disponible = isnull(sum(ah_disponible),0)
		from cob_ahorros..ah_cuenta
		where ah_cliente = @i_cliente
		and ah_estado = 'A'
	end
	else
	begin
		select @w_disponible = isnull(sum(ah_disponible),0)
		from cob_ahorros..ah_cuenta
		where ah_cliente in (@i_cliente, @w_representante)
		and ah_estado = 'A'
	end


	if @w_disponible >= @w_monto_parcial
		select @o_valida_monto = 1
	else
		select @o_valida_monto = 0


return 0

GO
