/*************************************************************************/
/*   Archivo:              sp_rees_control_rubro.sp                      */
/*   Stored procedure:     sp_rees_control_rubro                         */
/*   Base de datos:        cob_credito                                   */
/*   Producto:             Credito                                       */
/*   Disenado por:         Paul Moreno                                   */
/*   Fecha de escritura:   22/Dic/2021                                   */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las convenciones  internacionales de propiedad intectual      */
/*   Su uso no autorizado dara derecho a COBIS para                      */
/*   obtener ordenes de secuestro o retencion y para perseguir           */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Control de obtención de rubros iguales en una reestructuración     */
/*************************************************************************/
/*                           MODIFICACIONES                              */
/*     FECHA              AUTOR                     RAZON                */
/*     22/12/2021         pmoreno                   Emisión inicial      */
/*************************************************************************/

USE cob_credito
go

if exists(select 1 from sysobjects where name ='sp_rees_control_rubro' and type = 'P' )
    drop proc sp_rees_control_rubro
go

create PROCEDURE sp_rees_control_rubro
(           
    @s_ssn            int         = NULL,
    @s_user           login       = NULL,
    @s_sesn           int         = NULL,
    @s_term           varchar(30) = NULL,
    @s_date           datetime    = NULL,
    @s_srv            varchar(30) = NULL,
    @s_lsrv           varchar(30) = NULL, 
    @s_rol            smallint    = NULL,
    @s_ofi            smallint    = NULL,
    @s_org_err        char(1)     = NULL,
    @s_error          int         = NULL,
    @s_sev            tinyint     = NULL,
    @s_msg            descripcion = NULL,
    @s_org            char(1)     = NULL,
    @t_rty            char(1)     = NULL,
    @t_trn            int         = NULL,
    @t_debug          char(1)     = 'N',
    @t_file           varchar(14) = NULL,
    @t_from           varchar(32) = NULL,
    @t_show_version   bit         = 0,
    @i_id_inst_proc   int,
    @i_id_inst_act    int,
    @i_id_empresa     int         = NULL,
    @o_id_resultado   smallint    out      
)
as
declare @w_sp_name                varchar(32),
        @w_tramite                int,
        @w_return                 int,
        @w_nro_operacion_oo       int,  --operacion original
		@w_nro_operacion_on       int,  --operacion nueva de reestr
	@w_tipo                   char(1),
	@w_grupo                  int,
	@w_op_definitiva          cuenta,
	@w_op_tipo_reest          CHAR(1),
	@w_banco                  cuenta,
	@w_tipo_saldo             CHAR(1),
	@w_saldo_total            MONEY,
	@w_saldo                  MONEY,
	@w_id_asig_act            int,
	@w_act_ant                int,
	@w_max_observa            int,
	@w_fecha_hoy              DATETIME,
	@w_ejec_nombre			  varchar(30),
	@w_ol_observacion         SMALLINT,
	@w_ol_linea       		  int,
	@w_mjs                    varchar(255)

select @w_sp_name='sp_rees_control_rubro'

select @o_id_resultado = 1 --OK

select @w_fecha_hoy = convert(date,getdate(),101)

select @w_return = 0

--Encontrar numero de tramite
select @w_tramite = io_campo_3
from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

if @@rowcount = 0
begin
   select @o_id_resultado = 2 --Devolver
   goto SALIR
end

select @w_nro_operacion_on = op_operacion from cob_cartera..ca_operacion where op_tramite = @w_tramite
if @@rowcount = 0
begin
   select @o_id_resultado = 2 --Devolver
   goto SALIR
end

--Encontrar el tipo de tramite
select @w_tipo   = tr_tipo,
       @w_grupo  = tr_grupo
from   cob_credito..cr_tramite
where  tr_tramite = @w_tramite	  

--Validación de rubros
if (@w_tipo ='E') and exists (select 1 from cob_credito..cr_op_renovar where or_tramite = @w_tramite and or_base = 'S')
begin 
   select @w_nro_operacion_oo = op_operacion from cob_cartera..ca_operacion, cob_credito..cr_op_renovar   
   where  or_tramite = @w_tramite and or_num_operacion = op_banco
   if exists (select 1
		from cob_cartera..ca_dividendo,
		cob_cartera..ca_amortizacion
		where di_operacion = am_operacion 
		and di_dividendo = am_dividendo 
		and di_estado != 3 
		and di_operacion = @w_nro_operacion_oo 
		and (am_cuota - am_pagado  + am_gracia ) != 0
		and am_concepto not in (select oc_concepto from cob_cartera..ca_otro_cargo where oc_operacion = @w_nro_operacion_oo )
		and am_concepto not in (select am_concepto from cob_cartera..ca_amortizacion where am_operacion = @w_nro_operacion_on))
		begin
		   select @o_id_resultado = 2 --Devolver
		end
	else
		begin
			select @o_id_resultado = 1 --Ok
			GOTO SALIR
		end
end
else if (@w_tipo ='E') and (select count(1) from cob_credito..cr_op_renovar where or_tramite = @w_tramite and or_base = 'N') > 1
begin
	select @o_id_resultado = 1 --Ok
	GOTO SALIR
end
else 
begin
    select @o_id_resultado = 2 --Devolver
end --fin reestructuracion E

if (@o_id_resultado = 2)
begin
	--obtener la actividad anterior a la automatica para dejar la observacion
	select @w_act_ant = id_inst_act_parent
	from   cob_workflow..wf_inst_actividad
	where  ia_id_inst_proc = @i_id_inst_proc
	and    ia_id_inst_act  = @i_id_inst_act
	if @@rowcount = 0
	begin
		  select @o_id_resultado = 2 --Devolver
		  goto SALIR
	end
		
	--actividad para observacion
	select @w_id_asig_act = aa_id_asig_act
	from   cob_workflow..wf_asig_actividad
	where  aa_id_inst_act = @w_act_ant
	if @@rowcount = 0
	begin
		  select @o_id_resultado = 2 --Devolver
		  goto SALIR
	end
		
	select @w_max_observa = isnull (max (ob_numero), 0) + 1
	from   cob_workflow..wf_observaciones
	where  ob_id_asig_act = @w_id_asig_act
	if @@rowcount = 0
	begin
		  select @o_id_resultado = 2 --Devolver
		  goto SALIR
	end
		
	if not exists(select 1 from   cob_workflow..wf_observaciones where  ob_id_asig_act = @w_id_asig_act)
	begin
		select @w_ejec_nombre = fu_nombre
		from   cobis..cl_funcionario
		where  fu_login = @s_user
		
		insert into cob_workflow..wf_observaciones(
		           ob_id_asig_act, ob_numero,          ob_fecha,
		           ob_categoria,   ob_lineas,          ob_oficial, ob_ejecutivo
		           )
		values (@w_id_asig_act, @w_max_observa,     @w_fecha_hoy,
		           '',             1,                  '',         @w_ejec_nombre)
		if @@error > 0
		begin
		    select @o_id_resultado = 2 --Devolver
		    goto SALIR
		end
	end
		
	--numero de observacion
	select @w_ol_observacion  = ob_numero
	from   cob_workflow..wf_observaciones
	where  ob_id_asig_act = @w_id_asig_act            
	--linea de observacion
	select @w_ol_linea  = 1
	select @w_ol_linea = isnull(ol_linea,0) + 1
	from   cob_workflow..wf_ob_lineas 
	where  ol_id_asig_act = @w_id_asig_act
		             
	select @w_mjs = mensaje from cobis..cl_errores where numero = 70011005
		               
	insert into cob_workflow..wf_ob_lineas(
		          ol_id_asig_act, ol_observacion,    ol_linea,    ol_texto
		          )
	values(@w_id_asig_act, @w_ol_observacion, @w_ol_linea, @w_mjs)          
	if @@error > 0
	begin
		 select @o_id_resultado = 2 --Devolver
		 goto SALIR
	end
	select @o_id_resultado = 2
end
 
SALIR:

return 0

go