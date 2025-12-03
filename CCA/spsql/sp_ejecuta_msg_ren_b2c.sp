/************************************************************/
/*   ARCHIVO:         sp_ejecuta_msg_ren_b2c.sp             */
/*   NOMBRE LOGICO:   sp_ejecuta_msg_ren_b2c                */
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
/*   Envia la ejecución del mensaje de renovación desde la  */
/*   b2c. Respuesta S/N ejecuta este sp                     */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/* 29/ENE/2019     VBR                 Emision Inicial      */
/************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_ejecuta_msg_ren_b2c')
   drop proc sp_ejecuta_msg_ren_b2c
go
create proc sp_ejecuta_msg_ren_b2c
        (@s_ssn        int         = null,
         @s_ofi        smallint,
         @s_user       login,
         @s_date       datetime,
         @s_srv        varchar(30) = null,
         @s_term       descripcion = null,
         @s_rol        smallint    = null,
         @s_lsrv       varchar(30) = null,
         @s_sesn       int         = null,
         @s_org        char(1)     = NULL,
         @s_org_err    int         = null,
         @s_error      int         = null,
         @s_sev        tinyint     = null,
         @s_msg        descripcion = null,
         @t_rty        char(1)     = null,
         @t_trn        int         = null,
         @t_debug      char(1)     = 'N',
         @t_file       varchar(14) = null,
         @t_from       varchar(30) = null,
         --variables
         @i_cliente    INT,
         @i_banco      VARCHAR(64)  = NULL,
		 @i_msg_id     int          = null,
         @o_msg		   VARCHAR(200) = NULL
)as
declare
@w_return          int,
@w_tramite         INT,
@w_actividad       CHAR(6),
@w_flujo           INT


SELECT @w_flujo = pa_tinyint FROM cobis..cl_parametro
WHERE pa_nemonico = 'FLIREV' 
AND pa_producto = 'CCA'

/* Obtengo el numero de prestamo*/
select @w_tramite      = io_campo_3
from   cob_workflow..wf_inst_proceso 
where  io_campo_1 = @i_cliente
AND io_estado = 'EJE'
AND io_codigo_proc = @w_flujo -- Individual Revolvente


exec @w_return = cob_cartera..sp_ruteo_actividad_wf
     @s_ssn             =  @s_ssn, 
     @s_user            =  @s_user,
     @s_sesn            =  @s_sesn,
     @s_term            =  @s_term,
     @s_date            =  @s_date,
     @s_srv             =  @s_srv,
     @s_lsrv            =  @s_lsrv,
     @s_ofi             =  @s_ofi,
     @i_tramite         =  @w_tramite,
     @i_param_etapa     =  'ERESCL' 

     IF @w_return <> 0 
        RETURN 1

return 0

go





