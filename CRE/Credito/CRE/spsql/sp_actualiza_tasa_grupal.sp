/********************************************************************/
/*   NOMBRE LOGICO:         sp_actualiza_tasa_grupal                */
/*   NOMBRE FISICO:         sp_actualiza_tasa_grupal.sp             */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          P. Jarrin                               */
/*   FECHA DE ESCRITURA:    23-Oct-2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Texto descriptivo                                              */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA           AUTOR           RAZON                          */
/*   23-Oct-2023     P. Jarrin.      Emision Inicial S923938-R214406*/
/*   13-Feb-2025     G. Romero       Req 251290 Tasa de interes mora*/
/********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_tasa_grupal')
   drop proc sp_actualiza_tasa_grupal
go

create proc sp_actualiza_tasa_grupal(
        @s_ssn                      int         = null,
        @s_user                     login       = null,
        @s_sesn                     int         = null,
        @s_term                     descripcion = null,
        @s_date                     datetime    = null,
        @s_srv                      varchar(30) = null,
        @s_lsrv                     varchar(30) = null,
        @s_rol                      smallint    = null,
        @s_ofi                      smallint    = null,
        @s_org_err                  char(1)     = null,
        @s_culture                  varchar(10) = 'NEUTRAL',
        @s_error                    int         = null,
        @s_sev                      tinyint     = null,
        @s_msg                      descripcion = null,
        @s_org                      char(1)     = null,
        @t_rty                      char(1)     = null,
        @t_trn                      int         = null,
        @t_debug                    char(1)     = 'N',
        @t_file                     varchar(14) = null,
        @t_from                     varchar(30) = null,
        @t_show_version             bit         = 0,
        @i_tramite                  int,
        @i_operacion                char(1) = null,
        @i_num_integrantes          int     = null,
        @o_tasa                     float   = null out,
		@o_tasa_mora                float   = null out  --Req 251290
)
as

declare 
        @w_sp_name                varchar(32),
        @w_sp_msg                 varchar(100),
        @w_return                 int,
        @w_error                  int,
        @w_variables              varchar(64),
        @w_return_variable        varchar(25),
        @w_return_results         varchar(25),
        @w_last_condition_parent  varchar(10),
        @w_tasa                   float,
        @w_tasa_aux               float,
		@w_tasa_mora              float,       --Req 251290
        @w_tasa_aux_mora          float,       --Req 251290
        @w_toperacion             varchar(10),
        @w_count                  int,
        @w_operacion              int,         --Req 251290
		@w_banco_aux              varchar(24),
        @w_monto_aux              money,
        @w_op_monto_hija          varchar(24),
        @w_num_integrantes        int

select @w_sp_name = 'sp_actualiza_tasa_grupal'

if @t_show_version = 1    --Req 251290
begin
    print 'Stored procedure %1!, Version 1.1.1'  
    print @w_sp_name
    return 0
end


if not exists( select 1
                 from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
                where rl_acronym = 'TCRGR' 
                  and rv_status = 'PRO'
                  and BPL.rl_id = RV.rl_id)
begin
    select @w_return  = 725109
    goto ERROR_FIN  
end

if not exists( select 1
                 from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
                where rl_acronym = 'TAINMOG' 
                  and rv_status = 'PRO'
                  and BPL.rl_id = RV.rl_id)
begin
    select @w_return  = 725109
    goto ERROR_FIN  
end


if (@i_operacion = 'V')
begin
    select @w_toperacion = trim(op_toperacion)
      from cob_cartera..ca_operacion 
     where op_tramite = @i_tramite
     
    select @w_num_integrantes = count(1) 
     from cob_credito..cr_tramite_grupal
    where tg_tramite   = @i_tramite
      and tg_participa_ciclo = 'S'  

    select @w_variables =  @w_toperacion + '|' + convert(varchar(10),@w_num_integrantes - 1)

    exec @w_return                = cob_pac..sp_rules_param_run
         @s_rol                   = @s_rol,
         @i_rule_mnemonic         = 'TCRGR',
         @i_var_values            = @w_variables,
         @i_var_separator         = '|',
         @o_return_variable       = @w_return_variable  out,
         @o_return_results        = @w_return_results   out,
         @o_last_condition_parent = @w_last_condition_parent out
         
     
    if @w_return != 0
    begin
        select @w_return  = @w_return
        goto ERROR_FIN
    end

    if (@w_return_results is null)
    begin
        return 0
    end

    select @w_tasa_aux = replace(@w_return_results,'|','')  
    select @w_tasa =  isnull(ro_porcentaje,0) from cob_cartera..ca_rubro_op, cob_cartera..ca_operacion where ro_tipo_rubro = 'I' and ro_operacion = op_operacion and op_tramite = @i_tramite
    
	/*Req 251290**/	
	exec @w_return                = cob_pac..sp_rules_param_run
         @s_rol                   = @s_rol,
         @i_rule_mnemonic         = 'TAINMOG',
         @i_var_values            = @w_variables,
         @i_var_separator         = '|',
         @o_return_variable       = @w_return_variable  out,
         @o_return_results        = @w_return_results   out,
         @o_last_condition_parent = @w_last_condition_parent out
	
	if @w_return != 0
    begin
        select @w_return  = @w_return
        goto ERROR_FIN
    end

    if (@w_return_results is null)
    begin
        return 0
    end

    select @w_tasa_aux_mora = replace(@w_return_results,'|','') 
    
	select @w_tasa_mora =  isnull(ro_porcentaje,0) 
	from cob_cartera..ca_rubro_op, cob_cartera..ca_operacion 
	where ro_tipo_rubro = 'M' 
	and ro_operacion = op_operacion 
	and op_tramite = @i_tramite
    /*Req 251290**/	
	
    if (@w_tasa <> @w_tasa_aux) or (@w_tasa_mora <> @w_tasa_aux_mora)  --or Req 251290
    begin
        select @w_return  = 2110437 -- El integrante no se puede eliminar, ya que hay una variación de tasa. Revisar regla Tasa Crédito Grupal.
        goto ERROR_FIN
    end   

end

if (@i_operacion = 'U')
begin

    select @w_toperacion = trim(op_toperacion)
      from cob_cartera..ca_operacion 
     where op_tramite = @i_tramite

    if (OBJECT_ID('tempdb.dbo.#tmp_integrantes','U')) is not null
    begin
      drop table #tmp_integrantes
    end
    create table #tmp_integrantes
    (
        id          int    identity (1,1),
        operacion   int    not null,
        banco       cuenta not null,
        monto       money  not null 
    )

    insert into #tmp_integrantes (operacion, banco, monto)
    select tg_operacion, op_banco, op_monto
      from cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion 
     where tg_operacion = op_operacion 
       and tg_tramite   = @i_tramite
       and tg_participa_ciclo = 'S'

    select @w_num_integrantes = count(1) from #tmp_integrantes  

    select @w_variables =  @w_toperacion + '|' + convert(varchar(10),@w_num_integrantes)

    exec @w_return                = cob_pac..sp_rules_param_run
         @s_rol                   = @s_rol,
         @i_rule_mnemonic         = 'TCRGR',
         @i_var_values            = @w_variables,
         @i_var_separator         = '|',
         @o_return_variable       = @w_return_variable  out,
         @o_return_results        = @w_return_results   out,
         @o_last_condition_parent = @w_last_condition_parent out
         
         
    if @w_return != 0
    begin
        select @w_return  = @w_return
        goto ERROR_FIN
    end

    if (@w_return_results is null)
    begin
        return 0
    end

    select @w_tasa = replace(@w_return_results,'|','')
    /*Req 251290**/
    exec @w_return                = cob_pac..sp_rules_param_run
         @s_rol                   = @s_rol,
         @i_rule_mnemonic         = 'TAINMOG',
         @i_var_values            = @w_variables,
         @i_var_separator         = '|',
         @o_return_variable       = @w_return_variable  out,
         @o_return_results        = @w_return_results   out,
         @o_last_condition_parent = @w_last_condition_parent out
         
         
    if @w_return != 0
    begin
        select @w_return  = @w_return
        goto ERROR_FIN
    end

    if (@w_return_results is null)
    begin
        return 0
    end

    select @w_tasa_mora = replace(@w_return_results,'|','')
	
	update cob_cartera..ca_rubro_op    --op padre
	set ro_porcentaje=@w_tasa_mora
	where ro_concepto='IMO'
	and ro_operacion IN (select op_operacion from cob_cartera..ca_operacion where op_tramite = @i_tramite)
	
    /*Req fin 251290**/
    select @w_count = 1
    while @w_count <= @w_num_integrantes 
    begin
	        select 
			   @w_operacion = operacion, --Req 251290
			   @w_banco_aux = banco, 
               @w_monto_aux = monto 
          from #tmp_integrantes
         where id = @w_count
		   
             update cob_cartera..ca_rubro_op    --op hijas
	         set ro_porcentaje=@w_tasa_mora
	         where ro_concepto='IMO' 
			 AND ro_operacion= @w_operacion
		     		 
            exec @w_return = cob_cartera..sp_xsell_actualiza_monto_op
               @i_banco           = @w_banco_aux,
               @s_user            = @s_user,
               @s_term            = @s_term,
               @s_ofi             = @s_ofi,
               @s_date            = @s_date,
               @i_monto_nuevo     = @w_monto_aux,
               @i_grupal          = 'S',
               @i_tasa            = @w_tasa,
               @o_monto_calculado = @w_op_monto_hija out

            if @w_return != 0
            begin
             select @w_error = @w_return
             goto ERROR_FIN
            end 	
        
            select @w_count = @w_count + 1
    end
end  

if (@i_operacion = 'Q')
begin

    select @w_toperacion = trim(op_toperacion)
      from cob_cartera..ca_operacion 
     where op_tramite = @i_tramite
     
    select @w_variables =  @w_toperacion + '|' + convert(varchar(10),@i_num_integrantes)

    exec @w_return                = cob_pac..sp_rules_param_run
         @s_rol                   = @s_rol,
         @i_rule_mnemonic         = 'TCRGR',
         @i_var_values            = @w_variables,
         @i_var_separator         = '|',
         @o_return_variable       = @w_return_variable  out,
         @o_return_results        = @w_return_results   out,
         @o_last_condition_parent = @w_last_condition_parent out
         
     
    if @w_return != 0
    begin
        select @w_return  = @w_return
        goto ERROR_FIN
    end

    if (@w_return_results is null)
    begin
        select @o_tasa = null
        return 0
    end
    
    select @o_tasa = replace(@w_return_results,'|','')	

end      

if (@i_operacion = 'M')
begin

    select @w_toperacion = trim(op_toperacion)
      from cob_cartera..ca_operacion 
     where op_tramite = @i_tramite
     
    select @w_variables =  @w_toperacion + '|' + convert(varchar(10),@i_num_integrantes)

	/*Req 251290**/	
	exec @w_return                = cob_pac..sp_rules_param_run
         @s_rol                   = @s_rol,
         @i_rule_mnemonic         = 'TAINMOG',
         @i_var_values            = @w_variables,
         @i_var_separator         = '|',
         @o_return_variable       = @w_return_variable  out,
         @o_return_results        = @w_return_results   out,
         @o_last_condition_parent = @w_last_condition_parent out
	 
	 if @w_return != 0
    begin
        select @w_return  = @w_return
        goto ERROR_FIN
    end

    if (@w_return_results is null)
    begin
        select @o_tasa_mora = null
        return 0
    end	
    select @o_tasa_mora = replace(@w_return_results,'|','')
    /*Req 251290**/	
	
end      

return 0

ERROR_FIN:
exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_return
return @w_return

go
