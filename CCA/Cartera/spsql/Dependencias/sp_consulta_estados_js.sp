use cob_conta_super
go 

drop proc sp_consulta_estados_js
go

create proc sp_consulta_estados_js
                                                                                                                                                                                                                            
   @i_operacion   char(1),
                                                                                                                                                                                                                                    
   @i_fecha       datetime,
                                                                                                                                                                                                                                   
   @i_banco       varchar(60) = null,
                                                                                                                                                                                                                         
   @i_cliente     int         = null
                                                                                                                                                                                                                          
   
                                                                                                                                                                                                                                                           
as declare @w_error     int,
                                                                                                                                                                                                                                  
           @w_fecha_ini datetime,
                                                                                                                                                                                                                             
           @w_sp_name   varchar(64),
                                                                                                                                                                                                                          
           @w_msg       varchar(100)
                                                                                                                                                                                                                          
           
                                                                                                                                                                                                                                                   
select @w_sp_name = 'sp_consulta_estados_js'           
                                                                                                                                                                                                       
select @w_fecha_ini = dateadd(mm,-(1 - 1),@i_fecha)
                                                                                                                                                                                                           
select @w_fecha_ini = dateadd(dd,-(datepart(day,@w_fecha_ini)) + 1, @w_fecha_ini)           
                                                                                                                                                                  

                                                                                                                                                                                                                                                              
if @i_operacion = 'I' --Insercion en tabla temporal
                                                                                                                                                                                                           
begin
                                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
   truncate table sb_estados_cuenta
                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
   insert into sb_estados_cuenta
                                                                                                                                                                                                                              
   select 
                                                                                                                                                                                                                                                    
   do_fecha,
                                                                                                                                                                                                                                                  
   null,
                                                                                                                                                                                                                                                      
   do_banco, 
                                                                                                                                                                                                                                                 
   do_codigo_cliente,
                                                                                                                                                                                                                                         
   null,
                                                                                                                                                                                                                                                      
   null,
                                                                                                                                                                                                                                                      
   do_fecha_prox_vto,
                                                                                                                                                                                                                                         
   null,
                                                                                                                                                                                                                                                      
   do_saldo,
                                                                                                                                                                                                                                                  
   (do_valor_proxima_cuota + do_saldo_total_Vencido), 
                                                                                                                                                                                                        
   do_clase_cartera,
                                                                                                                                                                                                                                          
   do_codigo_destino,
                                                                                                                                                                                                                                         
   do_monto,
                                                                                                                                                                                                                                                  
   do_monto,
                                                                                                                                                                                                                                                  
   do_fecha_concesion,
                                                                                                                                                                                                                                        
   null,
                                                                                                                                                                                                                                                      
   do_plazo_dias,
                                                                                                                                                                                                                                             
   do_tipo_operacion,
                                                                                                                                                                                                                                         
   do_fecha_vencimiento,
                                                                                                                                                                                                                                      
   do_valor_proxima_cuota,
                                                                                                                                                                                                                                    
   do_tasa,
                                                                                                                                                                                                                                                   
   do_tasa_mora,
                                                                                                                                                                                                                                              
   do_tasa,
                                                                                                                                                                                                                                                   
   do_tasa_mora,
                                                                                                                                                                                                                                              
   do_tasa_com,
                                                                                                                                                                                                                                               
   null, --cat
                                                                                                                                                                                                                                                
   null,
                                                                                                                                                                                                                                                      
   null,
                                                                                                                                                                                                                                                      
   do_saldo_cap,
                                                                                                                                                                                                                                              
   do_tasa,
                                                                                                                                                                                                                                                   
   do_tasa_mora,
                                                                                                                                                                                                                                              
   do_tasa_com,
                                                                                                                                                                                                                                               
   null,
                                                                                                                                                                                                                                                      
   null,
                                                                                                                                                                                                                                                      
   null,
                                                                                                                                                                                                                                                      
   null,
                                                                                                                                                                                                                                                      
   null,
                                                                                                                                                                                                                                                      
   null,
                                                                                                                                                                                                                                                      
   null
                                                                                                                                                                                                                                                       
   FROM sb_dato_operacion x
                                                                                                                                                                                                                                   
   WHERE x.do_banco = isnull(@i_banco,x.do_banco)
                                                                                                                                                                                                             
   AND   x.do_codigo_cliente = isnull(@i_cliente,x.do_codigo_cliente)
                                                                                                                                                                                         
   and   x.do_fecha BETWEEN @w_fecha_ini AND @i_fecha
                                                                                                                                                                                                         
   AND x.do_fecha = (SELECT max(y.do_fecha) FROM sb_dato_operacion y WHERE y.do_banco = x.do_banco AND y.do_fecha BETWEEN @w_fecha_ini AND @i_fecha)
                                                                                                          

                                                                                                                                                                                                                                                              
   if @@error <> 0
                                                                                                                                                                                                                                            
   begin
                                                                                                                                                                                                                                                      
      select @w_error = @@error,
                                                                                                                                                                                                                              
             @w_msg   = 'ERROR AL INSERTAR REGISTROS A LA TABLA TEMPORAL'   
                                                                                                                                                                                  
      goto ERROR
                                                                                                                                                                                                                                              
   end
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
   update sb_estados_cuenta  set ec_ced_ruc   = (select isnull(dc_ced_ruc,dc_nit) from sb_dato_cliente x where dc_cliente = ec_codigo_cliente 
                                                                                                                
                                                   AND dc_fecha BETWEEN @w_fecha_ini AND @i_fecha
                                                                                                                                                             
                                                   AND dc_fecha = (SELECT max(dc_fecha) FROM sb_dato_cliente y 
                                                                                                                                               
                                                                     WHERE x.dc_cliente = y.dc_cliente 
                                                                                                                                                       
                                                                     AND y.dc_fecha BETWEEN @w_fecha_ini AND @i_fecha)),
                                                                                                                                      
                                 ec_nombres   = (select concat(isnull(dc_nombre,''),' ' ,isnull(dc_p_apellido,'') ,' ' , isnull(dc_s_apellido,'')) 
                                                                                                           
                                                from sb_dato_cliente x where dc_cliente = ec_codigo_cliente 
                                                                                                                                                  
                                                   AND dc_fecha BETWEEN @w_fecha_ini AND @i_fecha
                                                                                                                                                             
                                                   AND dc_fecha = (SELECT max(dc_fecha) FROM sb_dato_cliente y 
                                                                                                                                               
                                                                     WHERE x.dc_cliente = y.dc_cliente 
                                                                                                                                                       
                                                                     AND y.dc_fecha BETWEEN @w_fecha_ini AND @i_fecha)),
                                                                                                                                      
                                 ec_direccion = (select TOP 1 dd_descripcion from sb_dato_direccion x 
                                                                                                                                                        
                                                 where dd_cliente = ec_codigo_cliente
                                                                                                                                                                         
                                                 AND dd_fecha BETWEEN @w_fecha_ini AND @i_fecha
                                                                                                                                                               
                                                 AND dd_fecha = (SELECT max(dd_fecha) FROM sb_dato_direccion y 
                                                                                                                                               
                                                                     WHERE x.dd_cliente = y.dd_cliente 
                                                                                                                                                       
                                                                     AND y.dd_fecha BETWEEN @w_fecha_ini AND @i_fecha)),
                                                                                                                                      
                                 ec_clase_cartera = (select eq_descripcion from sb_equivalencias where eq_catalogo = 'CLASECA' and eq_valor_arch = ec_clase_cartera),
                                                                                         
                                 ec_codigo_destino = (select eq_descripcion from sb_equivalencias where eq_catalogo = 'CRDESTINO' and eq_valor_arch = ec_codigo_destino),
                                                                                     
                                 ec_tipo_operacion = (select eq_descripcion from sb_equivalencias where eq_catalogo = 'CATOPER' and eq_valor_arch = ec_tipo_operacion)
   WHERE ec_codigo_cliente >= 0                              
                                                                                        
   if @@error <> 0
                                                                                                                                                                                                                                            
   begin
                                                                                                                                                                                                                                                      
      select @w_error = @@error,
                                                                                                                                                                                                                              
             @w_msg   = 'ERROR AL ACTUALIZAR REGISTROS A LA TABLA TEMPORAL'   
                                                                                                                                                                                
      goto ERROR
                                                                                                                                                                                                                                              
   end
                                                                                                                                                                                                                                                        
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
if @i_operacion = 'Q'
                                                                                                                                                                                                                                         
begin
                                                                                                                                                                                                                                                         
   select
                                                                                                                                                                                                                                                     
   'Fecha'                 = ec_fecha,                
                                                                                                                                                                                                        
   'RFC'                   = ec_ced_ruc,              
                                                                                                                                                                                                        
   'Cuenta'                = ec_banco,                
                                                                                                                                                                                                        
   'Cliente'               = ec_codigo_cliente,       
                                                                                                                                                                                                        
   'Nombres'               = ec_nombres,              
                                                                                                                                                                                                        
   'Direccion'             = ec_direccion,            
                                                                                                                                                                                                        
   'FechaLimitePago'       = ec_fecha_prox_vto,       
                                                                                                                                                                                                        
   'PagoMinimo'            = ec_pago_minimo,          
                                                                                                                                                                                                        
   'DeudaTotal'            = ec_saldo,                
                                                                                                                                                                                                        
   'SaldoFecha'            = ec_saldo_fecha,          
                                                                                                                                                                                                        
   'Producto'              = ec_clase_cartera,        
                                                                                                                                                                                                        
   'Finalidad'             = ec_codigo_destino,       
                                                                                                                                                                                                        
   'ImporteAutorizado'     = ec_monto_imp,                
                                                                                                                                                                                                    
   'CreditoOtorgado'       = ec_monto,
                                                                                                                                                                                                                        
   'FechaDisposicion'      = ec_fecha_concesion,      
                                                                                                                                                                                                        
   'Plazo'                 = ec_plazo,                
                                                                                                                                                                                                        
   'DiasPlazo'             = ec_plazo_dias,           
                                                                                                                                                                                                        
   'TipoPrestamo'          = ec_tipo_operacion,   --validar    
                                                                                                                                                                                               
   'FechaVencimiento'      = ec_fecha_vencimiento,    
                                                                                                                                                                                                        
   'ProximoAbono'          = ec_valor_proxima_cuota,  
                                                                                                                                                                                                        
   'TasaOrdinaria'         = ec_tasa,                 
                                                                                                                                                                                                        
   'TasaMoratorio'         = ec_tasa_mora,            
                                                                                                                                                                                                        
   'TasaOrdinariaConcep'   = ec_tasa_concep,          
                                                                                                                                                                                                        
   'TasaMoratorioConcep'   = ec_tasa_mora_concep,     
                                                                                                                                                                                                        
   'TasaComisionesConcep'  = ec_tasa_com_concep,      
                                                                                                                                                                                                        
   'TasaIvaConcep'         = ec_iva_concep, 
                                                                                                                                                                                                                  
   'CAT'                   = ec_cat,          
                                                                                                                                                                                                                
   'PorcentajeCubierto'    = ec_porcentaje_cubierto,  
                                                                                                                                                                                                        
   'AbonoCapital'          = ec_saldo_cap,           
                                                                                                                                                                                                         
   'TasaOrdinarioDet'      = ec_tasa_det,             
                                                                                                                                                                                                        
   'TasaMoratorioDet'      = ec_tasa_mora_det,        
                                                                                                                                                                                                        
   'TasaComisionDet'       = ec_tasa_com_det,         
                                                                                                                                                                                                        
   'TasaIvaDet'            = ec_iva_det,              
                                                                                                                                                                                                        
   'MontoPagado'           = ec_monto_pagado,         
                                                                                                                                                                                                        
   'FechaPago'             = ec_fecha_pago,           
                                                                                                                                                                                                        
   'Capital'               = ec_capital,              
                                                                                                                                                                                                        
   'InteresOrdinario'      = ec_int_ord,              
                                                                                                                                                                                                        
   'InteresMoratorio'      = ec_int_mor,              
                                                                                                                                                                                                        
   'IVA'                   = ec_iva_pag             
                                                                                                                                                                                                          
   from sb_estados_cuenta
                                                                                                                                                                                                                                     
end
                                                                                                                                                                                                                                                           
                            
                                                                                                                                                                                                                                  
return 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
ERROR:
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
exec cobis..sp_errorlog
                                                                                                                                                                                                                                       
@i_fecha        = @i_fecha,
                                                                                                                                                                                                                                   
@i_error        = @w_error,
                                                                                                                                                                                                                                   
@i_usuario      = 'batch',
                                                                                                                                                                                                                                    
@i_tran         = 123456789,
                                                                                                                                                                                                                                  
@i_descripcion  = @w_msg,
                                                                                                                                                                                                                                     
@i_programa     = @w_sp_name
                                                                                                                                                                                                                                  

                                                                                                                                                                                                                                                              
return @w_error
                                                                                                                                                                                                                                               
go 

