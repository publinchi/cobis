use cob_remesas
go
if exists (select 1 from sysobjects where name = 'sp_act_est_branch')
   drop proc sp_act_est_branch
 
go


create proc sp_act_est_branch
                                                                                                                                                                                                                                 
@s_user         login    = null,
                                                                                                                                                                                                                              
@s_date         datetime = null,
                                                                                                                                                                                                                              
@i_cliente      int      = null,
                                                                                                                                                                                                                              
@i_accion       char(1)  = null,
                                                                                                                                                                                                                              
@i_cuenta       int      = null,
                                                                                                                                                                                                                              
@i_descripcion  varchar(50) = null
                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
as 
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
declare @w_estado_caja   char(1),
                                                                                                                                                                                                                             
        @w_estado_his    char(1),
                                                                                                                                                                                                                             
        @w_cuenta        int,
                                                                                                                                                                                                                                 
        @w_num_orden     int
                                                                                                                                                                                                                                  

                                                                                                                                                                                                                                                              
/* VALIDA LAS ACCIONES PERMITIDAS */
                                                                                                                                                                                                                          
if @i_accion not in ('I','P')
                                                                                                                                                                                                                                 
   return 722503
                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
/* ASIGNA LOS ESTADOS DE CAJA PARA LA ACCION ES INGRESO */
                                                                                                                                                                                                    
if @i_accion = 'I'
                                                                                                                                                                                                                                            
   select @w_estado_caja = 'I',
                                                                                                                                                                                                                               
          @w_estado_his  = 'C'
                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
/* ASIGNA LOS ESTADOS DE CAJA PARA LA ACCION ES PAGO */
                                                                                                                                                                                                       
if @i_accion = 'P'
                                                                                                                                                                                                                                            
   select @w_estado_caja = 'A',
                                                                                                                                                                                                                               
          @w_estado_his  = 'P'
                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
/* OBTIENE EL NUMERO DE ORDEN DEL PAGO */
                                                                                                                                                                                                                     
select @w_num_orden = hc_sec_ord_pago
                                                                                                                                                                                                                         
from cob_ahorros..ah_his_cierre with (nolock)
                                                                                                                                                                                                                 
where hc_cuenta = @i_cuenta
                                                                                                                                                                                                                                   

                                                                                                                                                                                                                                                              
if @@rowcount = 0 return 722504
                                                                                                                                                                                                                               

                                                                                                                                                                                                                                                              
/* ACTUALIZA LA ORDEN DE CAJA */
                                                                                                                                                                                                                              
update cob_remesas..re_orden_caja
                                                                                                                                                                                                                             
set oc_estado = @w_estado_caja,
                                                                                                                                                                                                                               
oc_fecha_cambio = @s_date,
                                                                                                                                                                                                                                    
oc_usuar_cambio = @s_user
                                                                                                                                                                                                                                     
where oc_cliente = @i_cliente
                                                                                                                                                                                                                                 
and   oc_idorden = @w_num_orden
                                                                                                                                                                                                                               

                                                                                                                                                                                                                                                              
if @@error <> 0 return 722505
                                                                                                                                                                                                                                 

                                                                                                                                                                                                                                                              
/* ACTUALIZA LA TABLA AH_HIS_CIERRE */
                                                                                                                                                                                                                        
update cob_ahorros..ah_his_cierre
                                                                                                                                                                                                                             
set hc_estado = @w_estado_his,
                                                                                                                                                                                                                                
hc_usuario_pg = @s_user,
                                                                                                                                                                                                                                      
hc_observacion1 = isnull(@i_descripcion,'')
                                                                                                                                                                                                                   
where hc_cuenta = @i_cuenta
                                                                                                                                                                                                                                   

                                                                                                                                                                                                                                                              
if @@error <> 0 return 722506
                                                                                                                                                                                                                                 

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      
go

