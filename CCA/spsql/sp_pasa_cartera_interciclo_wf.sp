use cob_workflow
go

if object_id ('sp_pasa_cartera_interciclo_wf') is not null
   drop procedure sp_pasa_cartera_interciclo_wf
go
/*************************************************************************/
/*   Archivo:            sp_pasa_cartera_interciclo_wf.sp                */
/*   Stored procedure:   sp_pasa_cartera_interciclo_wf                   */
/*   Base de datos:      cob_workflow                                    */
/*   Producto:           Originación                                    */
/*   Disenado por:       VBR                                             */
/*   Fecha de escritura: 03/04/2017                                      */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   "MACOSA", representantes exclusivos para el Ecuador de NCR          */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier acion o agregado hecho por alguno de sus                  */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante.                 */
/*************************************************************************/
/*                                  PROPOSITO                            */
/*   Este procedimiento almacenado, cambia el estado del tramite  a A    */
/*   en una actividad automatica                                         */
/*************************************************************************/
/*                                MODIFICACIONES                         */
/*   FECHA               AUTOR                 RAZON                     */
/*   03-04-2017          JSA                   Emision Inicial           */
/*************************************************************************/
create procedure sp_pasa_cartera_interciclo_wf
        (@s_ssn            int         = null,
         @s_ofi            smallint,
         @s_user           login,
         @s_date           datetime,
         @s_srv            varchar(30) = null,
         @s_term           descripcion = null,
         @s_rol            smallint    = null,
         @s_lsrv           varchar(30) = null,
         @s_sesn           int         = null,
         @s_org            char(1)     = NULL,
         @s_org_err        int         = null,
         @s_error          int         = null,
         @s_sev            tinyint     = null,
         @s_msg            descripcion = null,
         @t_rty            char(1)     = null,
         @t_trn            int         = null,
         @t_debug          char(1)     = 'N',
         @t_file           varchar(14) = null,
         @t_from           varchar(30) = null,
--variables
         @i_id_inst_proc   int,    --codigo de instancia del proceso
         @i_id_inst_act    int,
         @i_id_empresa     int,
         @o_id_resultado   smallint  out
)as
declare
@w_error             int,
@w_return            int,
@w_tramite           int,
@w_codigo_proceso    int,
@w_version_proceso   int,
@w_cliente           int,
@w_codigo_tramite    char(50),
@w_sp_name           varchar(30)


select @w_sp_name = 'sp_pasa_cartera_interciclo_wf'

select @w_tramite = convert(int, io_campo_3)
from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

/*** Estado A para el tramite, estado Aprobado ***/

exec @w_error   = cob_cartera..sp_pasa_cartera_interciclo
     @s_ofi     = @s_ofi,
     @s_user    = @s_user,
     @s_date    = @s_date,
     @s_term    = @s_term,
     @i_tramite = @w_tramite
print '@w_error' + convert(varchar,@w_error)
     if @w_error <> 0
     begin 
         select @o_id_resultado = 3, -- Error
         @w_error = @@ERROR
         print '@w_error' + cast(@w_error as varchar)
         goto ERROR
     end
	
select @o_id_resultado = 1 --OK

return 0
ERROR:
    exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error
    return @w_error
go
