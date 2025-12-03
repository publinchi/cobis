
/************************************************************************/
/*      Archivo:                rees_opbase.sp                          */
/*      Stored procedure:       sp_rees_op_base                         */
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

if exists (select 1 from sysobjects where name = 'sp_rees_op_base')
   drop proc sp_rees_op_base
go

create proc sp_rees_op_base
                                                                                                                                                                                                                                   
@s_user        	varchar(30) 	= null,
                                                                                                                                                                                                                          
@s_sesn         int             = null,
                                                                                                                                                                                                                       
@s_term        	varchar(30) 	= null,
                                                                                                                                                                                                                          
@s_date        	datetime        = null,
                                                                                                                                                                                                                       
@i_tope_base    varchar(10)     = null,
                                                                                                                                                                                                                       
@i_moneda       varchar(10)     = null
                                                                                                                                                                                                                        
	
                                                                                                                                                                                                                                                             
as 
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
/* Declaraciones de variables de operacion */
                                                                                                                                                                                                                 
declare @w_sp_name	    varchar(30),
                                                                                                                                                                                                                           
	@w_date		        datetime,
                                                                                                                                                                                                                                   
	@w_msg		        varchar(50),
                                                                                                                                                                                                                                 
	@w_error	        int,
                                                                                                                                                                                                                                        
	@w_tope_rees        varchar(10)
                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
	
                                                                                                                                                                                                                                                             
/*-- setear variables de operacion */
                                                                                                                                                                                                                         
select @w_sp_name = 'sp_rees_op_base'
                                                                                                                                                                                                                         
select @w_date = fp_fecha from cobis..ba_fecha_proceso
                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
if exists(select 1 from cob_cartera..ca_producto_reestructuracion
                                                                                                                                                                                             
           where pr_toperacion = @i_tope_base
                                                                                                                                                                                                                 
              AND pr_moneda = @i_moneda)
                                                                                                                                                                                                                      
   select 'tope_rees' = pr_toperacion_reestructuracion
                                                                                                                                                                                                        
   from cob_cartera..ca_producto_reestructuracion
                                                                                                                                                                                                             
   where pr_toperacion = @i_tope_base
                                                                                                                                                                                                                         
      AND pr_moneda = @i_moneda
                                                                                                                                                                                                                               
else
                                                                                                                                                                                                                                                          
   select 'tope_rees' = @i_tope_base
                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      

go