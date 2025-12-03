/************************************************************************/
/*  Archivo:                sync_solicitudes.sp                         */
/*  Stored procedure:       sp_sync_solicitudes                         */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_sync_solicitudes')
    drop proc sp_sync_solicitudes
go

CREATE proc sp_sync_solicitudes (
    @i_oficial 	INT
)

AS
DECLARE
@w_sp_name             VARCHAR(32),
@w_accion              VARCHAR(255),
@w_observacion         VARCHAR(255),
@w_num_det			   INT,
@w_cod_entidad		   SMALLINT,
@w_des_entidad         VARCHAR(64),
@w_fecha_proceso       DATETIME,
@w_actividad		   INT,
@w_user				   login,
@w_subalterno 		   INT,
@w_max_si_sincroniza   INT,
@w_grupo 			   INT,
@w_inst_proceso 	   INT,
@w_tramite             INT,
@w_cliente      	   INT,
@w_act_actual 		   INT,
@w_nombre_cl           varchar(64),
@w_error               INT,
@w_msg                 VARCHAR(100),
@w_filas               INT


SET @w_sp_name='sp_sync_solicitudes'
SET @w_accion='COMPLETAR SOLICITUD'
SET @w_observacion='POR SINCRONIZACION DE DISPOSITIVO'
SET @w_cod_entidad = 3 --SOLICITUD GRUPAL
SET @w_num_det = 0

SELECT @w_des_entidad = valor
FROM cobis..cl_catalogo
WHERE tabla = ( SELECT codigo  FROM cobis..cl_tabla
                WHERE tabla = 'si_sincroniza') AND codigo = @w_cod_entidad

SELECT @w_fecha_proceso = fp_fecha FROM cobis..ba_fecha_proceso
SELECT @w_actividad=ac_codigo_actividad FROM cob_workflow..wf_actividad WHERE ac_nombre_actividad='INGRESAR SOLICITUD'

select @w_user = fu_login
from  cobis..cl_funcionario, cobis..cc_oficial
where oc_oficial = @i_oficial 
and oc_funcionario = fu_funcionario

SELECT @w_max_si_sincroniza = isnull(max(si_secuencial),0) + 1
FROM   cob_sincroniza..si_sincroniza
-- Insert en si_sincroniza
INSERT INTO cob_sincroniza..si_sincroniza (si_secuencial,si_cod_entidad,si_des_entidad,
                                         si_usuario,si_estado,si_fecha_ing,
                                          si_fecha_sin,si_num_reg)
       						VALUES (@w_max_si_sincroniza,@w_cod_entidad,@w_des_entidad,
                   			@w_user,'P',@w_fecha_proceso,
                               NULL,1)
if @@error <> 0
	begin
    	select @w_error = 150000 -- ERROR EN INSERCION
    	select @w_msg = 'Insertar en si_sincroniza'
    	goto ERROR
	end
   
SELECT @w_grupo=0
WHILE 1=1 --while para cada grupo del oficial
BEGIN
 	SELECT @w_inst_proceso=NULL
 	SELECT @w_tramite=NULL
 			
	SELECT TOP 1 @w_grupo=gr_grupo 
	FROM cobis..cl_grupo 
	WHERE 
	gr_oficial = @i_oficial
	AND gr_grupo>@w_grupo
	ORDER BY gr_grupo
				
	IF @@ROWCOUNT = 0
		BREAK
			
	PRINT 'oficial>>'+convert(VARCHAR(10),@i_oficial)+' grupo >>'+convert(VARCHAR(10),@w_grupo)
		
    SELECT TOP 1 
	@w_inst_proceso=io_id_inst_proc,
	@w_tramite = io_campo_3
	FROM cob_workflow..wf_inst_proceso 
	WHERE io_campo_1=@w_grupo 
	AND io_estado='EJE' 
	ORDER BY io_id_inst_proc DESC
				
   --	PRINT '@w_inst_proceso>>'+isnull(convert(VARCHAR(10),@w_inst_proceso),'no existe')
   --	PRINT '@w_tramite>>'+isnull(convert(VARCHAR(10),@w_tramite),'no existe')
		  		
   	IF @w_inst_proceso IS NOT NULL 
	BEGIN
		SELECT 
       	@w_cliente    = op_cliente,
       	@w_nombre_cl  = op_nombre
		FROM cob_cartera..ca_operacion OP 
		WHERE op_tramite = @w_tramite
		   
		SELECT TOP 1 @w_act_actual = ia_codigo_act FROM cob_workflow..wf_inst_actividad WHERE ia_id_inst_proc=@w_inst_proceso ORDER BY ia_id_inst_act DESC
		PRINT '@w_act_actual>>'+convert(VARCHAR(10),@w_act_actual)
				
	 	IF @w_act_actual = @w_actividad
		BEGIN --si el proceso está en la actividad INGRESAR SOLICITUD
		   /*	PRINT 'Sincronizar SOLICITUD'	
			PRINT 'Sincronizar solicitud>>>@w_tramite'+convert(VARCHAR(10),@w_tramite)
			PRINT 'Sincronizar solicitud>>>@w_inst_proceso'+convert(VARCHAR(10),@w_inst_proceso)
			PRINT 'Sincronizar solicitud>>>@w_max_si_sincroniza_sol'+convert(VARCHAR(10),@w_max_si_sincroniza)*/
						
			IF @w_tramite<>0 
			  EXEC cob_credito..sp_grupal_xml_det
			   @i_inst_proc = @w_inst_proceso,
    				@i_secuencial = @w_max_si_sincroniza,
    				@i_tramite =@w_tramite
    					
				   
			END	--END si el proceso está en la actividad cuestionario grupal
	END
END --end while para barrerse los oficiales
	
	SELECT @w_num_det= count (sid_secuencial) FROM cob_sincroniza..si_sincroniza_det
	WHERE sid_secuencial=@w_max_si_sincroniza
	
	IF @w_num_det >0		
		update cob_sincroniza..si_sincroniza set
		   si_num_reg = @w_num_det
		   where si_secuencial = @w_max_si_sincroniza
	ELSE
		DELETE FROM  cob_sincroniza..si_sincroniza
		WHERE si_secuencial = @w_max_si_sincroniza
	RETURN 0


ERROR:
begin 
	exec cobis..sp_cerror
  		@t_debug = 'N',
   		@t_file  = 'S',
   		@t_from  = @w_sp_name,
   		@i_num   = @w_error,
      	@i_msg   = @w_msg
    return @w_error
END

GO
