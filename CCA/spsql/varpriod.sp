
/************************************************************************/
/*      Archivo:                varpriod.sp                             */
/*      Stored procedure:       sp_var_periodicidad                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Ene. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*     Calculo IVA IMO                                                  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_var_periodicidad')
   drop proc sp_var_periodicidad
go

                                                                                                                                                                                                                                            
create proc sp_var_periodicidad(
                                                                                                                                                                                                                      
	@t_debug       		char(1)     = 'N',
                                                                                                                                                                                                                          
	@t_from        		varchar(30) = null,
                                                                                                                                                                                                                         
	@s_ssn              int,
                                                                                                                                                                                                                                     
	@s_user             varchar(30),
                                                                                                                                                                                                                             
	@s_sesn             int,
                                                                                                                                                                                                                                     
	@s_term             varchar(30),
                                                                                                                                                                                                                             
	@s_date             datetime,
                                                                                                                                                                                                                                
	@s_srv              varchar(30),
                                                                                                                                                                                                                             
	@s_lsrv             varchar(30),
                                                                                                                                                                                                                             
	@s_ofi              smallint,
                                                                                                                                                                                                                                
	@t_file             varchar(14) = null,
                                                                                                                                                                                                                      
	@s_rol              smallint    = null,
                                                                                                                                                                                                                      
	@s_org_err          char(1)     = null,
                                                                                                                                                                                                                      
	@s_error            int         = null,
                                                                                                                                                                                                                      
	@s_sev              tinyint     = null,
                                                                                                                                                                                                                      
	@s_msg              descripcion = null,
                                                                                                                                                                                                                      
	@s_org              char(1)     = null,
                                                                                                                                                                                                                      
	@s_culture         	varchar(10) = 'NEUTRAL',
                                                                                                                                                                                                                 
	@t_rty              char(1)     = null,
                                                                                                                                                                                                                      
	@t_trn				int = null,
                                                                                                                                                                                                                                        
	@t_show_version     BIT = 0,
                                                                                                                                                                                                                                 
    @i_id_inst_proc    	int,    --codigo de instancia del proceso
                                                                                                                                                                                             
    @i_id_inst_act     	int,    
                                                                                                                                                                                                                              
    @i_id_asig_act     	int,
                                                                                                                                                                                                                                  
    @i_id_empresa      	int, 
                                                                                                                                                                                                                                 
    @i_id_variable     	smallint
                                                                                                                                                                                                                              
)
                                                                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              
as
                                                                                                                                                                                                                                                            
declare 
                                                                                                                                                                                                                                                      
@w_sp_name       	varchar(32),
                                                                                                                                                                                                                                
@w_error            int,
                                                                                                                                                                                                                                      
@w_msg              descripcion,
                                                                                                                                                                                                                              
@w_valor_ant        varchar(255),
                                                                                                                                                                                                                             
@w_valor_nuevo      varchar(255),
                                                                                                                                                                                                                             
@w_tramite          int,
                                                                                                                                                                                                                                      
@w_dias             int,
                                                                                                                                                                                                                                      
@w_operacionca      int 
                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
select  @w_tramite     = io_campo_3
                                                                                                                                                                                                                           
from cob_workflow..wf_inst_proceso
                                                                                                                                                                                                                            
where io_id_inst_proc = @i_id_inst_proc
                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
select  top 1 @w_operacionca =tg_operacion 
                                                                                                                                                                                                                   
from cob_credito..cr_tramite_grupal
                                                                                                                                                                                                                           
where  tg_tramite = @w_tramite
                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
if @@rowcount = 0 begin 
                                                                                                                                                                                                                                      
	
                                                                                                                                                                                                                                                             
   select @w_operacionca =op_operacion 
                                                                                                                                                                                                                       
   from ca_operacion 
                                                                                                                                                                                                                                         
   where  op_tramite = @w_tramite	
                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
end 
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
select 
                                                                                                                                                                                                                                                       
@w_dias  =  op_periodo_int * (select td_factor from ca_tdividendo where td_tdividendo = op_tdividendo),
                                                                                                                                                       
@w_sp_name    ='sp_var_periodicidad'
                                                                                                                                                                                                                          
from   ca_operacion 
                                                                                                                                                                                                                                          
where  op_operacion = @w_operacionca
                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
if @@rowcount = 0 begin     
                                                                                                                                                                                                                                  
   select
                                                                                                                                                                                                                                                     
   @w_error = 70001,
                                                                                                                                                                                                                                          
   @w_msg   = 'NO SE PUDO DETERMINAR PERIODICIDAD DEL PRESTAMO'
                                                                                                                                                                                               
   goto ERROR 
                                                                                                                                                                                                                                                
end 
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
select @w_valor_nuevo = convert(varchar, @w_dias) 
                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
print 'RESULTADO DE LA VARIABLE:'+convert(varchar, @w_dias)
                                                                                                                                                                                                   
if @i_id_asig_act is null select @i_id_asig_act = 0
                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
-- valor anterior de variable tipo en la tabla cob_workflow..wf_variable
                                                                                                                                                                                      
select @w_valor_ant    = isnull(va_valor_actual, '')
                                                                                                                                                                                                          
from cob_workflow..wf_variable_actual
                                                                                                                                                                                                                         
where va_id_inst_proc = @i_id_inst_proc
                                                                                                                                                                                                                       
and va_codigo_var     = @i_id_variable
                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
if @@rowcount > 0  --ya existe
                                                                                                                                                                                                                                
begin
                                                                                                                                                                                                                                                         
   --print '@i_id_inst_proc %1! @w_asig_actividad %2! @w_valor_ant %3!',@i_id_inst_proc, @w_asig_actividad, @w_valor_ant
                                                                                                                                      
   update cob_workflow..wf_variable_actual set
                                                                                                                                                                                                                
   va_valor_actual         = @w_valor_nuevo 
                                                                                                                                                                                                                  
   where va_id_inst_proc   = @i_id_inst_proc
                                                                                                                                                                                                                  
   and   va_codigo_var     = @i_id_variable    
                                                                                                                                                                                                               
end
                                                                                                                                                                                                                                                           
else
                                                                                                                                                                                                                                                          
begin
                                                                                                                                                                                                                                                         
   insert into cob_workflow..wf_variable_actual
                                                                                                                                                                                                               
   (va_id_inst_proc, va_codigo_var, va_valor_actual) values
                                                                                                                                                                                                   
   (@i_id_inst_proc, @i_id_variable, @w_valor_nuevo)
                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
end
                                                                                                                                                                                                                                                           
--print '@i_id_inst_proc %1! @w_asig_actividad %2! @w_valor_ant %3!',@i_id_inst_proc, @w_asig_actividad, @w_valor_ant
                                                                                                                                         
if not exists(select 1 from cob_workflow..wf_mod_variable
                                                                                                                                                                                                     
              where mv_id_inst_proc = @i_id_inst_proc and
                                                                                                                                                                                                     
              mv_codigo_var         = @i_id_variable  and
                                                                                                                                                                                                     
              mv_id_asig_act        = @i_id_asig_act)
                                                                                                                                                                                                         
begin
                                                                                                                                                                                                                                                         
   insert into cob_workflow..wf_mod_variable
                                                                                                                                                                                                                  
   (mv_id_inst_proc  ,mv_codigo_var  ,mv_id_asig_act ,mv_valor_anterior,mv_valor_nuevo ,mv_fecha_mod) values
                                                                                                                                                  
   (@i_id_inst_proc  ,@i_id_variable ,@i_id_asig_act ,@w_valor_ant     ,@w_valor_nuevo , getdate())
                                                                                                                                                           
			
                                                                                                                                                                                                                                                           
if @@error > 0
                                                                                                                                                                                                                                                
   begin
                                                                                                                                                                                                                                                      
      exec cobis..sp_cerror
                                                                                                                                                                                                                                   
      @t_debug = @t_debug,
                                                                                                                                                                                                                                    
      @t_file = @t_file, 
                                                                                                                                                                                                                                     
      @t_from = @t_from,
                                                                                                                                                                                                                                      
      @i_num = 2101002
                                                                                                                                                                                                                                        
   return 1
                                                                                                                                                                                                                                                   
end 
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
ERROR:
                                                                                                                                                                                                                                                        
exec cobis..sp_cerror
                                                                                                                                                                                                                                         
@t_debug = 'N',
                                                                                                                                                                                                                                               
@t_from  = @w_sp_name,
                                                                                                                                                                                                                                        
@i_num   = @w_error,
                                                                                                                                                                                                                                          
@i_msg   = @w_msg
                                                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              
return @w_error
                                                                                                                                                                                                                                               

                                                                                                                                                                                                                                                              

go