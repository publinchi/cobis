use cob_ccontable
go

drop proc sp_ing_opera_det 

go                                                                                                                                                                                                                            
create proc sp_ing_opera_det (
                                                                                                                                                                                                                                
	@s_ssn			int		= null,
                                                                                                                                                                                                                                        
	@s_date			datetime	= null,
                                                                                                                                                                                                                                   
	@s_user			login		= null,
                                                                                                                                                                                                                                     
	@s_term			descripcion	= null,
                                                                                                                                                                                                                                
	@s_corr			char(1)		= null,
                                                                                                                                                                                                                                   
	@s_ssn_corr		int		= null,
                                                                                                                                                                                                                                    
        @s_ofi			smallint	= null,
                                                                                                                                                                                                                             
	@t_rty			char(1)		= null,
                                                                                                                                                                                                                                    
        @t_trn			int		= null,
                                                                                                                                                                                                                                 
	@t_debug		char(1)		= 'N',
                                                                                                                                                                                                                                    
	@t_file			varchar(14)	= null,
                                                                                                                                                                                                                                
	@t_from			varchar(30)	= null,
                                                                                                                                                                                                                                
	@i_empresa		tinyint		= null,
                                                                                                                                                                                                                                 
	@i_operacion		char(1)		= null,
                                                                                                                                                                                                                               
	@i_producto		tinyint		= null,
                                                                                                                                                                                                                                
	@i_fecha 		datetime	= null,
                                                                                                                                                                                                                                  
	@i_cuenta       	cuenta		= null,
                                                                                                                                                                                                                             
	@i_oficina		smallint	= null,
                                                                                                                                                                                                                                 
	@i_area			smallint	= null,
                                                                                                                                                                                                                                   
	@i_moneda		tinyint		= null,
                                                                                                                                                                                                                                  
	@i_val_opera_mn		money		= 0,
                                                                                                                                                                                                                                 
	@i_val_opera_me		money		= 0,
                                                                                                                                                                                                                                 
	@i_val_conta_mn		money		= 0,
                                                                                                                                                                                                                                 
	@i_val_conta_me		money		= 0,
                                                                                                                                                                                                                                 
	@i_diferencia_mn	money		= 0,
                                                                                                                                                                                                                                 
	@i_diferencia_me	money		= 0,
                                                                                                                                                                                                                                 
	@i_tipo  		char(1)		= null,
                                                                                                                                                                                                                                  
	@i_operacion_mod	cuenta		= null,
                                                                                                                                                                                                                             
	@i_adicional		descripcion	= null
                                                                                                                                                                                                                             
)
                                                                                                                                                                                                                                                             
as
                                                                                                                                                                                                                                                            
declare @w_today 	datetime,
                                                                                                                                                                                                                                   
	@w_sp_name	varchar(32),
                                                                                                                                                                                                                                      
	@w_cuenta       cuenta,
                                                                                                                                                                                                                                      
	@w_moneda       tinyint,
                                                                                                                                                                                                                                     
	@w_oficina	smallint,
                                                                                                                                                                                                                                         
	@w_categoria    char(1)
                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
select @w_sp_name = 'sp_ing_opera'
                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
if (@t_trn <> 60032 and @i_operacion = 'I')  or
                                                                                                                                                                                                               
   (@t_trn <> 60033 and @i_operacion = 'D')
                                                                                                                                                                                                                   
begin	/* 'Tipo de transaccion no corresponde' */
                                                                                                                                                                                                              
/*
                                                                                                                                                                                                                                                            
	exec cobis..sp_cerror
                                                                                                                                                                                                                                        
	@t_debug = @t_debug,
                                                                                                                                                                                                                                         
	@t_file	 = @t_file,
                                                                                                                                                                                                                                          
	@t_from	 = @w_sp_name,
                                                                                                                                                                                                                                       
	@i_num	 = 6000009
                                                                                                                                                                                                                                            
*/
                                                                                                                                                                                                                                                            
	return 6000009
                                                                                                                                                                                                                                               
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
if @i_operacion = 'I'
                                                                                                                                                                                                                                         
begin
                                                                                                                                                                                                                                                         
	select 	@w_oficina = of_oficina
                                                                                                                                                                                                                              
	from 	cob_conta..cb_oficina
                                                                                                                                                                                                                                  
	where 	of_empresa = @i_empresa
                                                                                                                                                                                                                               
	and     of_oficina  = @i_oficina
                                                                                                                                                                                                                             
        and     of_movimiento = 'S'
                                                                                                                                                                                                                           
        and     of_estado = 'V'
                                                                                                                                                                                                                               
	if @@rowcount = 0
                                                                                                                                                                                                                                            
	begin	/*'Oficina consultada no existe o no es de movimiento'*/
                                                                                                                                                                                               
/*
                                                                                                                                                                                                                                                            
		exec cobis..sp_cerror
                                                                                                                                                                                                                                       
		@t_debug = @t_debug,
                                                                                                                                                                                                                                        
		@t_file	 = @t_file,
                                                                                                                                                                                                                                         
		@t_from	 = @w_sp_name,
                                                                                                                                                                                                                                      
		@i_num	 = 6000017
                                                                                                                                                                                                                                           
*/
                                                                                                                                                                                                                                                            
		return 6000017
                                                                                                                                                                                                                                              
	end
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
	select 	@w_moneda = cu_moneda,
                                                                                                                                                                                                                               
		@w_categoria = cu_categoria
                                                                                                                                                                                                                                 
	from 	cob_conta..cb_cuenta
                                                                                                                                                                                                                                   
	where 	cu_empresa = @i_empresa
                                                                                                                                                                                                                               
	and     cu_cuenta  = @i_cuenta
                                                                                                                                                                                                                               
        and     cu_movimiento = 'S'
                                                                                                                                                                                                                           
        and     cu_estado = 'V'
                                                                                                                                                                                                                               
	if @@rowcount = 0
                                                                                                                                                                                                                                            
	begin	/*'Cuenta no es válida, no existe o no es de movimiento'*/
                                                                                                                                                                                             
/*
                                                                                                                                                                                                                                                            
		exec cobis..sp_cerror
                                                                                                                                                                                                                                       
		@t_debug = @t_debug,
                                                                                                                                                                                                                                        
		@t_file	 = @t_file,
                                                                                                                                                                                                                                         
		@t_from	 = @w_sp_name,
                                                                                                                                                                                                                                      
		@i_num	 = 6000011
                                                                                                                                                                                                                                           
*/
                                                                                                                                                                                                                                                            
		return 6000011
                                                                                                                                                                                                                                              
	end
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
	if @w_categoria = 'C' and @i_tipo <> 'P'
                                                                                                                                                                                                                     
	begin
                                                                                                                                                                                                                                                        
		select @i_val_opera_mn = @i_val_opera_mn  * (-1)
                                                                                                                                                                                                            
		select @i_val_opera_me = @i_val_opera_me  * (-1)
                                                                                                                                                                                                            
	end
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
	if @w_moneda <> @i_moneda
                                                                                                                                                                                                                                    
	begin	/* 'C=digo de Moneda no es válida o no corresponde' */
                                                                                                                                                                                                 
/*
                                                                                                                                                                                                                                                            
		exec cobis..sp_cerror
                                                                                                                                                                                                                                       
		@t_debug = @t_debug,
                                                                                                                                                                                                                                        
		@t_file	 = @t_file,
                                                                                                                                                                                                                                         
		@t_from	 = @w_sp_name,
                                                                                                                                                                                                                                      
		@i_num	 = 6000018
                                                                                                                                                                                                                                           
*/
                                                                                                                                                                                                                                                            
		return 6000018
                                                                                                                                                                                                                                              
	end
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
	if exists(select 1 from cob_ccontable..cco_boc_det
                                                                                                                                                                                                           
			where bo_empresa = @i_empresa
                                                                                                                                                                                                                              
			and   bo_fecha    = @i_fecha
                                                                                                                                                                                                                               
			and   bo_producto = @i_producto
                                                                                                                                                                                                                            
			and   bo_cuenta   = @i_cuenta
                                                                                                                                                                                                                              
			and   bo_oficina  = @i_oficina
                                                                                                                                                                                                                             
			and   bo_area     = @i_area
                                                                                                                                                                                                                                
			and   bo_operacion = @i_operacion_mod
                                                                                                                                                                                                                      
			and   bo_tipo     = @i_tipo)
                                                                                                                                                                                                                               
	begin
                                                                                                                                                                                                                                                        
		update cob_ccontable..cco_boc_det
                                                                                                                                                                                                                           
		set   bo_val_opera_mn = bo_val_opera_mn + @i_val_opera_mn,
                                                                                                                                                                                                  
              	      bo_val_opera_me = bo_val_opera_me + @i_val_opera_me,
                                                                                                                                                                                     
              	      bo_val_conta_mn = bo_val_conta_mn + @i_val_conta_mn,
                                                                                                                                                                                     
              	      bo_val_conta_me = bo_val_conta_me + @i_val_conta_me,
                                                                                                                                                                                     
              	      bo_diferencia_mn = bo_diferencia_mn + @i_diferencia_mn,
                                                                                                                                                                                  
              	      bo_diferencia_me = bo_diferencia_me + @i_diferencia_me
                                                                                                                                                                                   
		where bo_empresa = @i_empresa
                                                                                                                                                                                                                               
		and   bo_fecha    = @i_fecha
                                                                                                                                                                                                                                
		and   bo_producto = @i_producto
                                                                                                                                                                                                                             
		and   bo_cuenta   = @i_cuenta
                                                                                                                                                                                                                               
		and   bo_oficina  = @i_oficina
                                                                                                                                                                                                                              
		and   bo_area     = @i_area
                                                                                                                                                                                                                                 
		and   bo_operacion = @i_operacion_mod
                                                                                                                                                                                                                       
		and   bo_tipo     = @i_tipo
                                                                                                                                                                                                                                 
		if @@error <> 0
                                                                                                                                                                                                                                             
		begin	/* 'Error en actualizacion de registro' */
                                                                                                                                                                                                            
/*
                                                                                                                                                                                                                                                            
			exec cobis..sp_cerror
                                                                                                                                                                                                                                      
			@t_debug = @t_debug,
                                                                                                                                                                                                                                       
			@t_file  = @t_file,
                                                                                                                                                                                                                                        
			@t_from  = @w_sp_name,
                                                                                                                                                                                                                                     
			@i_num   = 6000015
                                                                                                                                                                                                                                         
*/
                                                                                                                                                                                                                                                            
			return 6000015
                                                                                                                                                                                                                                             
		end
                                                                                                                                                                                                                                                         
	end
                                                                                                                                                                                                                                                          
	else
                                                                                                                                                                                                                                                         
	begin
                                                                                                                                                                                                                                                        
		insert into cob_ccontable..cco_boc_det (
                                                                                                                                                                                                                    
			bo_empresa,bo_producto,bo_fecha,bo_cuenta,bo_oficina,
                                                                                                                                                                                                      
			bo_area,bo_moneda,bo_val_opera_mn,bo_val_opera_me,
                                                                                                                                                                                                         
			bo_val_conta_mn,bo_val_conta_me,bo_diferencia_mn,bo_diferencia_me,
                                                                                                                                                                                         
			bo_operacion,bo_adicional,bo_tipo)
                                                                                                                                                                                                                         
		values (@i_empresa,@i_producto,@i_fecha,@i_cuenta,@i_oficina,
                                                                                                                                                                                               
			@i_area,@i_moneda,@i_val_opera_mn,@i_val_opera_me,
                                                                                                                                                                                                         
			@i_val_conta_mn,@i_val_conta_me,@i_diferencia_mn,@i_diferencia_me,
                                                                                                                                                                                         
			@i_operacion_mod,@i_adicional,@i_tipo)
                                                                                                                                                                                                                     
		if @@error <> 0
                                                                                                                                                                                                                                             
		begin	/*'Error en insercion de registro'*/
                                                                                                                                                                                                                  
/*
                                                                                                                                                                                                                                                            
			exec cobis..sp_cerror
                                                                                                                                                                                                                                      
			@t_debug = @t_debug,
                                                                                                                                                                                                                                       
			@t_file	 = @t_file,
                                                                                                                                                                                                                                        
			@t_from	 = @w_sp_name,
                                                                                                                                                                                                                                     
			@i_num	 = 6000014
                                                                                                                                                                                                                                          
*/
                                                                                                                                                                                                                                                            
			return 6000014
                                                                                                                                                                                                                                             
		end
                                                                                                                                                                                                                                                         
	end
                                                                                                                                                                                                                                                          
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
if @i_operacion = 'D'
                                                                                                                                                                                                                                         
begin
                                                                                                                                                                                                                                                         
	delete cob_ccontable..cco_boc_det
                                                                                                                                                                                                                            
	where bo_empresa  = @i_empresa
                                                                                                                                                                                                                               
	and   bo_fecha    = @i_fecha
                                                                                                                                                                                                                                 
	and   bo_producto = @i_producto
                                                                                                                                                                                                                              
	and   bo_operacion = @i_operacion_mod
                                                                                                                                                                                                                        
        and   bo_tipo in ('S','M')
                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
	if @@error <> 0 
                                                                                                                                                                                                                                             
	begin	/* 'Error en eliminacion de registro' */
                                                                                                                                                                                                               
/*
                                                                                                                                                                                                                                                            
		exec cobis..sp_cerror
                                                                                                                                                                                                                                       
		@t_debug = @t_debug,
                                                                                                                                                                                                                                        
		@t_file	 = @t_file,
                                                                                                                                                                                                                                         
		@t_from	 = @w_sp_name,
                                                                                                                                                                                                                                      
		@i_num	 = 6000013
                                                                                                                                                                                                                                           
*/
                                                                                                                                                                                                                                                            
		return 6000013
                                                                                                                                                                                                                                              
	end
                                                                                                                                                                                                                                                          
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
