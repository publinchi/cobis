use cob_workflow
go

if exists (select 1 from sysobjects where name = 'sp_valida_montos_wf')
  drop procedure sp_valida_montos_wf
go

/****************************************************************/
/*   ARCHIVO:           valida_mon.sp                           */
/*   NOMBRE LOGICO:     sp_valida_montos_wf                     */
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
/*   Este procedimiento permite obtener la el numero de ciclo   */
/*   de un cliente                                              */
/****************************************************************/
/*                     MODIFICACIONES                           */
/*   FECHA         AUTOR               RAZON                    */
/*   28-Mar-2017   Tania Baidal        Emision Inicial.         */
/****************************************************************/

CREATE PROCEDURE sp_valida_montos_wf
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
@w_grupo                    int,
@w_cliente                  INT,
@w_sp_name                  VARCHAR(30),
@w_tramite                  int,
@w_mon_min                  varchar(255),
@w_mon_max                  varchar(255),
@w_monto                    float,
@w_ciclo                    int,
@w_rule                     int,
@w_rule_version             int,
@w_error_msj                varchar,
@w_valor_nuevo              varchar(255),
@w_num_ciclo                int,
@w_var_code                 int,
@w_msg                      varchar(100)

select @w_sp_name = 'sp_valida_montos_wf'
select @w_var_code = vb_codigo_variable from wf_variable where vb_abrev_variable = 'NUMCLGR'
if not exists(select 1
          from cob_workflow..wf_variable_actual
          where va_codigo_var   = @w_var_code
            and va_id_inst_proc = @i_id_inst_proc)
begin
	SELECT @w_grupo = convert(int, io_campo_1)
	FROM cob_workflow..wf_inst_proceso
	where io_id_inst_proc = @i_id_inst_proc


	select @w_num_ciclo= gr_num_ciclo
	from cobis..cl_grupo
	where gr_grupo = @w_grupo

	select @w_valor_nuevo = convert(varchar(10),@w_num_ciclo,0)
	insert into wf_variable_actual
	values (@i_id_inst_proc,@w_var_code,@w_valor_nuevo)

end


SELECT @w_tramite = convert(int,io_campo_3),
@w_grupo = convert(int, io_campo_1)
FROM cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

IF @w_tramite is null or @w_grupo is null
BEGIN
   SELECT @o_id_resultado = 3, -- Error
   @w_error = 9999
   GOTO ERROR
END

select @w_ciclo = gr_num_ciclo
from cobis..cl_grupo
where gr_grupo = @w_grupo

select @w_mon_min = '-1'
select @w_mon_max = '-1'

IF @w_ciclo is null
BEGIN
   SELECT @o_id_resultado = 3, -- Error
   @w_error = 9999
   GOTO ERROR
END

select @w_rule         	= bpl_rule.rl_id,
	   @w_rule_version 	= rv_id
from cob_pac..bpl_rule
inner join cob_pac..bpl_rule_version on bpl_rule.rl_id = bpl_rule_version.rl_id
where bpl_rule.rl_acronym = 'MONMAXGR'
	and rv_status in ('PRO')
	and getdate() >= rv_date_start
	and getdate() <= rv_date_finish

exec @w_error 			= cob_pac..sp_rules_run
     @t_trn             = 73506,
	 @i_status          = 'V',
     @i_id_inst_proceso = @i_id_inst_proc,
     @i_code_rule       = @w_rule,
     @i_version         = @w_rule_version,
     @o_return_value    = @w_mon_max   out,
     @o_return_code     = 0,
     @i_mode            = 'WFL',
     @i_simulator       = 'N',
     @i_nivel           =  0,
     @i_modo            = 'S'

print '@w_mon_max: ' + convert(varchar,@w_mon_max)

IF @w_error <> 0
BEGIN
    SELECT @o_id_resultado = 3 -- Error
    GOTO ERROR
END


select @w_rule         	= bpl_rule.rl_id,
	   @w_rule_version 	= rv_id
from cob_pac..bpl_rule
inner join cob_pac..bpl_rule_version on bpl_rule.rl_id = bpl_rule_version.rl_id
where bpl_rule.rl_acronym = 'MONMING'
	and rv_status in ('PRO')
	and getdate() >= rv_date_start
	and getdate() <= rv_date_finish

exec @w_error 			= cob_pac..sp_rules_run
     @t_trn             = 73506,
	 @i_status          = 'V',
     @i_id_inst_proceso = @i_id_inst_proc,
     @i_code_rule       = @w_rule,
     @i_version         = @w_rule_version,
     @o_return_value    = @w_mon_min   out,
     @o_return_code     = 0,
     @i_mode            = 'WFL',
     @i_abreviature	    = null,
     @i_simulator       = 'N',
     @i_nivel           =  0,
     @i_modo            = 'S'


IF @w_error <> 0
BEGIN
   SELECT @o_id_resultado = 3 -- Error
   GOTO ERROR
END

--CURSOR QUE CONSULTA MONTOS
declare cursor_montos cursor for
select tg_monto from cob_credito..cr_tramite_grupal
where tg_tramite =@w_tramite

open  cursor_montos
fetch cursor_montos
into @w_monto

while @@fetch_status = 0
BEGIN

    if @w_monto < @w_mon_min or @w_monto > @w_mon_max
    begin

        close cursor_montos
        deallocate cursor_montos

        SELECT @o_id_resultado = 3, -- Error
         @w_error = 6902003,
		 @w_msg   = 'Monto: '+ convert(varchar,@w_monto)+' no se encuentra dentro del rango. Mínimo: '+ convert(varchar, @w_mon_min) + ' Máximo: '+ convert(varchar, @w_mon_max)
         GOTO ERROR

    end

    fetch cursor_montos
    into  @w_monto
end

close cursor_montos
deallocate cursor_montos

select @o_id_resultado = 1 --OK

return 0
ERROR:
    exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error, @i_msg = @w_msg
    return @w_error
go

