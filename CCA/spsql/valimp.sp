
/************************************************************************/
/*      Archivo:                valimp.sp                               */
/*      Stored procedure:       sp_val_imp                              */
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

if exists (select 1 from sysobjects where name = 'sp_val_imp')
   drop proc sp_val_imp
go

                                                                                                                                                                                                                                            
create proc sp_val_imp (
                                                                                                                                                                                                                                      
@i_tramite          int,
                                                                                                                                                                                                                                      
@s_srv            varchar(30) = null,
                                                                                                                                                                                                                         
@s_user            varchar(14) = null,
                                                                                                                                                                                                                        
@s_term            varchar(30) = null,
                                                                                                                                                                                                                        
@s_ofi            smallint     = null, 
                                                                                                                                                                                                                       
@s_rol            smallint    = null,
                                                                                                                                                                                                                         
@s_ssn            int         = null,
                                                                                                                                                                                                                         
@s_lsrv            varchar(30) = null,
                                                                                                                                                                                                                        
@s_date            datetime    = null,
                                                                                                                                                                                                                        
@s_sesn             int         = null,
                                                                                                                                                                                                                       
@s_org            char(1)     = null,
                                                                                                                                                                                                                         
@s_culture        varchar(10) = null,
                                                                                                                                                                                                                         
@t_trn              int         = null
                                                                                                                                                                                                                        
)
                                                                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              
as
                                                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
declare
                                                                                                                                                                                                                                                       
@w_max_impresiones         tinyint,
                                                                                                                                                                                                                           
@w_op_estado        tinyint = 0,
                                                                                                                                                                                                                              
@w_des_estado         varchar(64)     
                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
   select @w_max_impresiones = pa_tinyint
                                                                                                                                                                                                                     
     from cobis..cl_parametro
                                                                                                                                                                                                                                 
    where pa_producto = 'CRE' 
                                                                                                                                                                                                                                
      and pa_nemonico = 'MIPD'--MAXIMO DE IMPRESIONES PERMITIDAS
                                                                                                                                                                                              

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
   select @w_op_estado = op_estado
                                                                                                                                                                                                                            
     from cob_cartera..ca_operacion
                                                                                                                                                                                                                           
    where op_tramite = @i_tramite
                                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
   select @w_des_estado = es_descripcion 
                                                                                                                                                                                                                     
     from cob_cartera..ca_estado
                                                                                                                                                                                                                              
    where es_codigo = @w_op_estado
                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
select 
                                                                                                                                                                                                                                                       
    'maxImpresiones'=    @w_max_impresiones,                
                                                                                                                                                                                                  
    'Des_estado'=        convert(varchar(64),@w_op_estado)
                                                                                                                                                                                                    

                                                                                                                                                                                                                                            
return 0
                                                                                                                                                                                                                                                      
                                                                                                                                                                                              
                                                                

go