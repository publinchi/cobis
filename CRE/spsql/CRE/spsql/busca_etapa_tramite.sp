/************************************************************************/
/*  Archivo:                busca_etapa_tramite.sp                      */
/*  Stored procedure:       sp_busca_etapa_tramite                      */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_busca_etapa_tramite' and type = 'P')
   drop proc sp_busca_etapa_tramite
go

create proc sp_busca_etapa_tramite (
                                                                                                                                                                                                                          
   @i_tramite              int         = null, 
                                                                                                                                                                                                               
   @o_paso_actual          int         = null   out, 
                                                                                                                                                                                                         
   @o_codigo_actividad     int         = null   out,
                                                                                                                                                                                                          
   @o_desc_actividad       varchar(255)= null   out
                                                                                                                                                                                                           
)
                                                                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              
as
                                                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
declare
                                                                                                                                                                                                                                                       
   @w_error             int,
                                                                                                                                                                                                                                  
   @w_sp_name           varchar(32),   /* NOMBRE STORED PROCEDURE */
                                                                                                                                                                                          
   @w_id_inst_proc      int,
                                                                                                                                                                                                                                  
   @w_id_inst_act       int,
                                                                                                                                                                                                                                  
   @w_id_asig_act       int,
                                                                                                                                                                                                                                  
   @w_id_paso           int,
                                                                                                                                                                                                                                  
   @w_id_actividad      int,
                                                                                                                                                                                                                                  
   @w_des_actividad     varchar(50)
                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
   /* INICIAR VARIABLES DE TRABAJO */
                                                                                                                                                                                                                         
   select @w_sp_name = 'sp_busca_etapa_tramite'
                                                                                                                                                                                                               
   
                                                                                                                                                                                                                                                           
   select @w_id_inst_proc =  io_id_inst_proc
                                                                                                                                                                                                                  
   from cob_workflow..wf_inst_proceso 
                                                                                                                                                                                                                        
   where io_campo_3 = @i_tramite 
                                                                                                                                                                                                                             
    
                                                                                                                                                                                                                                                          
   print 'CODIGO PROCESO: ' + convert(varchar,@w_id_inst_proc)
                                                                                                                                                                                                
     
                                                                                                                                                                                                                                                         
   select @w_id_inst_act = ia_id_inst_act, 
                                                                                                                                                                                                                   
          @w_id_paso     = ia_id_paso 
                                                                                                                                                                                                                        
   from cob_workflow..wf_inst_actividad 
                                                                                                                                                                                                                      
   where ia_id_inst_proc = @w_id_inst_proc
                                                                                                                                                                                                                    
   
                                                                                                                                                                                                                                                           
   print 'CODIGO INSTANCIA ACTIVIDAD:' + convert(varchar,@w_id_inst_act)
                                                                                                                                                                                      
   print 'CODIGO PASO:' + convert(varchar,@w_id_paso)
                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
   select @w_id_actividad = pa_codigo_actividad 
                                                                                                                                                                                                              
   from cob_workflow..wf_paso 
                                                                                                                                                                                                                                
   where pa_id_paso       = @w_id_paso
                                                                                                                                                                                                                        
    
                                                                                                                                                                                                                                                          
   
                                                                                                                                                                                                                                                           
   select @w_des_actividad = ac_nombre_actividad
                                                                                                                                                                                                              
   from cob_workflow..wf_actividad
                                                                                                                                                                                                                            
   where ac_codigo_actividad = @w_id_actividad
                                                                                                                                                                                                                
   
                                                                                                                                                                                                                                                           
   print 'PASO: ' + convert(varchar, @w_id_paso)
                                                                                                                                                                                                              
   print 'CODIGO ACT: ' + convert(varchar, @w_id_actividad)
                                                                                                                                                                                                   
   print 'DESC   ACT: ' + @w_des_actividad
                                                                                                                                                                                                                    
   
                                                                                                                                                                                                                                                           
   select  @o_paso_actual      = @w_id_paso      ,
                                                                                                                                                                                                            
           @o_codigo_actividad = @w_id_actividad ,
                                                                                                                                                                                                            
           @o_desc_actividad   = @w_des_actividad
                                                                                                                                                                                                             
   
                                                                                                                                                                                                                                                           
return 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              

GO
