/*************************************************************************/
/*   Archivo:              sp_insurace_names.sp                          */
/*   Stored procedure:     sp_insurace_names                             */
/*   Base de datos:        cob_credito                                   */
/*   Producto:             Credito                                       */
/*   Disenado por:         Jose Mieles      							 */
/*   Fecha de escritura:   4/Aug/2021                                    */
/*************************************************************************/
/*                          IMPORTANTE                                   */
/*    Este programa es parte de los paquetes bancarios propiedad de      */
/*    COBISCORP.                                                         */
/*    Su uso no autorizado queda expresamente prohibido asi como         */
/*    cualquier autorizacion o agregado hecho por alguno de sus          */
/*    usuario sin el debido consentimiento por escrito de la             */
/*    Presidencia Ejecutiva de COBISCORP o su representante.             */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Crea operacion hija de una operacion padre en grupales             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                   RAZON                	 */
/*    4/Aug/2021    	  Jose Mieles             Emision Inicial        */
/*                                                                       */
/*************************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_insurace_names')
			drop proc sp_insurace_names
go

CREATE PROCEDURE sp_insurace_names
	@t_show_version bit = 0, 
    @s_ssn int = NULL, 
    @s_srv varchar(30) = NULL, 
    @s_lsrv varchar(30) = NULL, 
    @s_date datetime = NULL, 
    @s_user login = NULL, 
    @s_term descripcion = NULL, 
    @s_corr char(1) = NULL, 
    @s_ssn_corr int = NULL, 
    @s_ofi smallint = NULL, 
    @t_rty char(1) = NULL, 
    @t_trn int = NULL, 
    @t_debug char(1) = 'N', 
    @t_file varchar(14) = NULL, 
    @t_from varchar(30) = NULL,
	@i_tramite 		int
AS 
	declare	
	@w_operacion	int,
	@w_sp_name varchar(32),
	@w_mensaje varchar(80),
	@w_names		catalogo
	
	SELECT @w_sp_name = 'sp_insurace_names'
	
	 IF (@t_show_version = 1)
    BEGIN
        SELECT @w_mensaje = 'Stored procedure sp_insurace_names, Version 1.0.0'
        
        PRINT CONVERT(VARCHAR, @w_mensaje)
        
        RETURN 0
    END
	
	select @w_operacion = op_operacion from cob_cartera..ca_operacion where op_tramite = @i_tramite

	select  co_descripcion, ro_concepto
	from cob_cartera..ca_rubro_op INNER JOIN cob_cartera..ca_concepto 
	ON ro_concepto =co_concepto 
	where ro_operacion = @w_operacion and ro_concepto in(select b.valor
	from cobis..cl_tabla a,
	cobis..cl_catalogo b
	where a.codigo = b.tabla and a.tabla = 'cr_tipos_seguro')
	
return 0

GO