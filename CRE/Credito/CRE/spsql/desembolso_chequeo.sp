/************************************************************************/
/*  Archivo:                desembolso_chequeo.sp                       */
/*  Stored procedure:       sp_desembolso_chequeo                       */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
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
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_desembolso_chequeo')
    drop proc sp_desembolso_chequeo
go

create proc sp_desembolso_chequeo(
 @s_ssn          			int = null,
 @s_sesn         			int = null,
 @s_user         			login = null,
 @s_term         			varchar(30) = null,
 @s_date         			datetime = null,
 @s_srv          			varchar(30) = null,
 @s_lsrv         			varchar(30) = null,
 @s_ofi          			smallint = null,
 @s_rol          			smallint = null,
 @s_org_err      			char(1) = null,
 @s_error        			int = null,
 @s_sev          			tinyint = null,
 @s_msg          			descripcion = null,
 @s_org          			char(1) = null,
 @s_culture					varchar(30) = null,
 @t_debug        			char(1) = 'N',
 @t_file         			varchar(10) = null,
 @t_from         			varchar(32) = null,
 @t_trn          			smallint = null,
 @t_show_version 			bit = 0,
 @i_nombre_documento 		char(28) = null,
 @i_tipo_registro 			char(2) = null,
 @i_num_secuencia			char(7) = null,
 @i_cod_operacion			char(2) = null,
 @i_num_banco				char(3) = null,
 @i_sentido					char(1) = null,
 @i_servicio				char(2) = null,
 @i_num_bloque				char(7) = null,
 @i_fecha_presentacion		char(8) = null,
 @i_cod_divisa				char(2) = null,
 @i_causa_rechazo			char(2) = null,
 @i_modalidad				char(1) = null,
 @i_operacion				char(1) = null,
 @o_causa_rechazo			char(2) = '00' OUTPUT
 )
 as
 
 if @i_operacion = 'Q'
 begin
	select @o_causa_rechazo = dc_causa_rechazo from cob_credito..cr_desembolso_chequeo where dc_nombre_documento = @i_nombre_documento
 end
 
 if @i_operacion = 'I'
 begin
	 if not exists (select 1 from cob_credito..cr_desembolso_chequeo where dc_nombre_documento = @i_nombre_documento)
	 begin
		insert into cob_credito..cr_desembolso_chequeo (dc_nombre_documento,dc_tipo_registro,dc_num_secuencia,dc_cod_operacion,dc_num_banco,dc_sentido,dc_servicio,dc_num_bloque,dc_fecha_presentacion,dc_cod_divisa,dc_causa_rechazo,dc_modalidad)
		values (@i_nombre_documento,@i_tipo_registro,@i_num_secuencia,@i_cod_operacion,@i_num_banco,@i_sentido,@i_servicio,@i_num_bloque,@i_fecha_presentacion,@i_cod_divisa,@i_causa_rechazo,@i_modalidad)

		IF @@ERROR <> 0
		BEGIN
			EXEC cobis..sp_cerror 
				@t_from = 'sp_desembolso_chequeo',
				@i_num = 2110318 --'Error al registrar el resultado del chequeo de archivo de Desembolso'
			RETURN 2110318
		END
	 end
end 

RETURN 0


GO

