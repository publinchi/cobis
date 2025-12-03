/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sonia Rojas                             */
/*      Fecha de escritura:     Noviembre 2017                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Rutina para paso de actividades en el WorkFlow                  */
/*      de estacion en espera.                                          */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_salir_espera_can')
   drop proc sp_salir_espera_can
go

create proc sp_salir_espera_can 
   @s_sesn                    int          = NULL,
   @s_ssn                     int          = null,
   @s_user                    login        = NULL,
   @s_date                    datetime     = NULL,
   @s_ofi                     smallint     = NULL,
   @s_term                    varchar (30) = NULL,
   @s_srv                     varchar (30) = '',
   @s_lsrv                    varchar (30) = null,
   @i_operacionca             int          
as
declare 
@w_id_inst_proc		int,
@w_id_inst_act		int,
@w_id_asig_act		int,
@w_id_paso			int,
@w_codigo_res		int,
@w_id_empresa		int,
@w_codigo_act		int,
@w_nombre_act		varchar(30),
@w_actividad		varchar(30),
@w_error			int,
@w_grupo            int,
@w_tramite_actual   int,
@w_tramite_ren      int,
@w_param_etapa      cuenta,
@w_ciclo            int,
@w_cliente          int ,
@w_est_cancelado    int		 


/* ESTADOS DE CARTERA */
exec  sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out

		
select @w_ciclo = dc_ciclo_grupo 
from  ca_det_ciclo		
where  dc_operacion = @i_operacionca -- 9176
--GRUPAL
if @@rowcount <> 0  begin 
   select  @w_param_etapa		= 	'CANCRA'
   
   select 
   @w_grupo          = tg_grupo,
   @w_tramite_actual = tg_tramite   
   from cob_credito..cr_tramite_grupal
   where tg_operacion = @i_operacionca

  -- CONTROL AVANZAR EL TRAMITE SOLO SI TODOS LOS PRESTAMOS DEL GRUPO ESTAN CANCELADOS
   if exists ( select 1 from ca_operacion,ca_det_ciclo 
                        where op_operacion = dc_operacion 
						and   op_estado not in (3,6,0,99)
						and   dc_grupo = @w_grupo
						and   dc_ciclo = @w_ciclo) return 0 
                                         

end  
else begin 
   select  @w_param_etapa		= 	'CANCRI'
   select
   @w_tramite_actual = tr_tramite,
   @w_cliente        = tr_cliente   
   from cob_credito..cr_tramite 
   where tr_numero_op = @i_operacionca
end    		

select @w_codigo_res = 1 --OK
select @w_id_empresa = 1 

select @w_actividad = pa_char 
from cobis..cl_parametro 
where pa_nemonico = @w_param_etapa
and pa_producto = 'CCA'
      
if @@rowcount = 0 return 101254


select @w_id_inst_proc = io_id_inst_proc
from cob_workflow..wf_inst_proceso
where io_campo_5 =  @w_tramite_actual   --CAMPO 5 GRABA TRAMITE ANTERIOR
and io_estado = 'EJE'

if @@rowcount = 0 return 0

	
--Instancia de la actividad
select @w_id_inst_act = ia_id_inst_act,
       @w_id_paso	  = ia_id_paso,
	   @w_nombre_act  = ia_nombre_act
  from cob_workflow..wf_inst_actividad
 where ia_id_inst_proc = @w_id_inst_proc
   and ia_estado 	= 'ACT'
   and ia_tipo_dest is null
   
--Asignación actividad
select @w_id_asig_act = aa_id_asig_act
  from cob_workflow..wf_asig_actividad
 where aa_id_inst_act = @w_id_inst_act

 
if @w_nombre_act = @w_actividad
begin
	exec cob_workflow..sp_resp_actividad_wf 
		@s_ssn  			= 	@s_ssn, 
		@s_user             = 	@s_user,
		@s_sesn             = 	@s_sesn,
		@s_term             = 	@s_term,
		@s_date             = 	@s_date,
		@s_srv              = 	@s_srv,
		@s_lsrv             = 	@s_lsrv,
		@s_ofi              = 	@s_ofi,		
		@t_trn 				= 	73505,
		@i_operacion 		= 	'C',
		@i_actualiza_var 	= 	'N',
		@i_asig_manual 		= 	0,
		@i_id_inst_proc 	= 	@w_id_inst_proc,
		@i_id_inst_act 		= 	@w_id_inst_act,
		@i_id_asig_act 		= 	@w_id_asig_act,
		@i_id_paso 			= 	@w_id_paso,
		@i_codigo_res 		= 	@w_codigo_res,
		@i_id_empresa 		= 	@w_id_empresa
end

return 0

go


