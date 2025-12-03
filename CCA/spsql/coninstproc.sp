/************************************************************************/
/*   Archivo:              coninstproc.sp                               */
/*   Stored procedure:     sp_cons_proc_info                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Tania B.                                     */
/*   Fecha de escritura:   Agosto 2017                                  */
/************************************************************************/
/*                            IMPORTANTE                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Programa consulta datos del proceso de workflow                    */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA        AUTOR             RAZON                                */
/*  16/Ago/2017  Tania B.          Emision inicial                      */
/************************************************************************/

use cob_workflow
go

if exists (select 1 from sysobjects where name = 'sp_cons_instancia')
   drop proc sp_cons_instancia
go

create proc sp_cons_instancia 
@i_ente          int           = null,
@i_operacion     char(1),  
@i_nom_proceso   varchar(150) = null,
@o_inst_proc     int           = null output,
@o_tramite       int           = null output, 
@o_fecha_ini_act datetime      = null output,
@o_nombre_act    varchar(100)  = null output,
@o_id_act        int           = null output
as 
declare
@w_sp_name        varchar(64),
@w_error          int,
@w_inst_proc      int,
@w_tramite        int,
@w_fecha_ini_act  datetime,
@w_fecha_ult_inst datetime,
@w_nombre_act     varchar(64),
@w_actividad      varchar(100),
@w_id_act         int,
@w_cod_proceso    int,
@w_num_procesos   int


select @w_sp_name = 'sp_cons_instancia'


if @i_operacion = 'Q'
begin

   select top 1
   @w_inst_proc     = io_id_inst_proc
   from wf_inst_proceso
   where io_estado             = 'EJE'
   and io_campo_1              = @i_ente
   order by io_campo_3 desc   


   select top 1
   @w_tramite       = io_campo_3,
   @w_fecha_ini_act = ia_fecha_inicio,
   @w_nombre_act    = ac_nombre_actividad,
   @w_id_act        = ia_codigo_act
   from wf_inst_proceso,  wf_inst_actividad, wf_actividad
   where io_estado             = 'EJE'
   and io_id_inst_proc         = @w_inst_proc
   and io_id_inst_proc         = ia_id_inst_proc
   and io_campo_1              = @i_ente
   and ia_estado             in ('ACT')
   and ia_codigo_act           = ac_codigo_actividad
   order by io_campo_3, ia_secuencia desc   
   
   if @@rowcount = 0
   begin
      select @w_error = 724604 -- ERROR AL CONSULTAR DATOS DEL PROCESO EN EL FLUJO
      return @w_error
   end
   
   select
   @o_inst_proc     = @w_inst_proc,
   @o_tramite       = @w_tramite, 
   @o_fecha_ini_act = @w_fecha_ini_act,
   @o_nombre_act    = @w_nombre_act,
   @o_id_act        = @w_id_act
end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error

go

