/************************************************************/
/*   ARCHIVO:         sp_feriados_tamortizacion.sp           */
/*   NOMBRE LOGICO:   sp_feriados_tamortizacion              */
/*   PRODUCTO:        COBIS WORKFLOW                        */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*   Consulta las actividades para la administración de un  */
/*   supervisor  					    */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA        AUTOR               RAZON                 */
/*   10-Jun-2011  Santiago Gavilanes  Emision Inicial.      */
/************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_feriados_tamortizacion')
    drop proc sp_feriados_tamortizacion
go

CREATE PROCEDURE sp_feriados_tamortizacion(

	@s_ssn			int = NULL,
	@s_user			login = NULL,
	@s_sesn			int = NULL,
	@s_term			varchar(32) = NULL,
	@s_date			datetime = NULL,
	@s_srv			varchar(30) = NULL,
	@s_lsrv			varchar(30) = NULL, 
	@s_rol			smallint = NULL,
	@s_ofi			smallint = NULL,
	@s_org_err		char(1) = NULL,
	@s_error		int = NULL,
	@s_sev			tinyint = NULL,
	@s_msg			descripcion = NULL,
	@s_org			char(1) = NULL,
	@t_debug		char(1) = 'N',
	@t_file			varchar(14) = null,
	@t_from			varchar(32) = null,
	@t_trn			smallint =NULL,
	@i_operacion    varchar(1) = null,
	@i_oficina		int = null
	
)as declare 
	@w_ciudad			int,
	@w_fecha_proceso 	datetime
	

	
	if @i_operacion = 'Q'
	begin
	
		--Ciudad 
		select @w_ciudad = of_ciudad   
		from cobis..cl_oficina
		where of_oficina = isnull(@i_oficina,@s_ofi)
		
		--Fecha de Proceso
		select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
		
		
		--Feriados mayores a la fecha actual
		select df_fecha
		from cobis..cl_dias_feriados
		where convert(datetime, df_fecha, 103) >= convert(datetime, @w_fecha_proceso, 103)
		and df_ciudad = @w_ciudad
		
		
		
	end
	
return 0
go
