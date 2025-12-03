use cob_workflow
go

if exists (select 1 from sysobjects where name = 'sp_incentivos_ganancias_wf')
  drop procedure sp_incentivos_ganancias_wf
go

/****************************************************************/
/*   ARCHIVO:           incen_gan.sp                           */
/*   NOMBRE LOGICO:     sp_incentivos_ganancias_wf                     */
/*   PRODUCTO:              CARTERA                             */
/****************************************************************/
/*                     IMPORTANTE                               */
/*   Esta aplicacion es parte de los  paquetes bancarios        */
/*   propiedad de MACOSA S.A.                                   */
/*   Su uso no autorizado queda  expresamente  prohibido        */
/*   asi como cualquier alteracion o agregado hecho  por        */
/*   alguno de sus usuarios sin el debido consentimiento        */
/*   por escrito de MACOSA.                                     */
/*   Este programa esta protegido por la ley de derechos        */
/*   de autor y por las convenciones  internacionales de        */
/*   propiedad intelectual.  Su uso  no  autorizado dara        */
/*   derecho a MACOSA para obtener ordenes  de secuestro        */
/*   o  retencion  y  para  perseguir  penalmente a  los        */
/*   autores de cualquier infraccion.                           */
/****************************************************************/
/*                     PROPOSITO                                */
/*                                                              */
/****************************************************************/
/*                     MODIFICACIONES                           */
/*   FECHA         AUTOR               RAZON                    */
/*   29-Mar-2017   Tania Baidal        Emision Inicial.         */
/****************************************************************/

CREATE PROCEDURE sp_incentivos_ganancias_wf
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
         @s_org_err    int         = null,
         @s_error      int         = null,
         @s_sev        tinyint     = null,
         @s_msg        descripcion = null,
         @t_rty        char(1)     = null,
         @t_trn        int         = null,
         @t_debug      char(1)     = 'N',
         @t_file       varchar(14) = null,
         @t_from       varchar(30)  = null,
         --variables        
         @i_id_inst_proc int,    --codigo de instancia del proceso
         @i_id_inst_act  int,    
         @i_id_empresa   int,
         @i_grupal       char(1) = 'N',
         @o_id_resultado  smallint  out
)as
DECLARE
@w_error                    int,
@w_ente                    int,
@w_cliente                  INT,
@w_sp_name                  VARCHAR(30),
@w_tramite                  int,
@w_ciclo                    int,
@w_tipo_prestamo            char(1)

select @w_sp_name = 'sp_incentivos_ganancias_wf'


SELECT 
@w_tramite       = convert(int,io_campo_3),
@w_ente          = convert(int,io_campo_1),
@w_tipo_prestamo = io_campo_7
FROM cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

IF @w_ente is null
BEGIN 
   SELECT @o_id_resultado = 3, -- Error
   @w_error = 724604
   GOTO ERROR
END

exec @w_error = cob_cartera..sp_incentivos_ganancias
@s_ofi           = @s_ofi,
@s_user          = @s_user,
@i_tipo_prestamo = @w_tipo_prestamo,
@i_ente          = @w_ente --secuencial del grupo



IF @w_error <> 0 
BEGIN   
    SELECT @o_id_resultado = 3 -- Error
    GOTO ERROR
END

select @o_id_resultado = 1 --OK

return 0
ERROR:
    exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error
    return @w_error
go

