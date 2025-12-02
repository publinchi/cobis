/************************************************************************/
/*  Archivo:                calif_interna_cliente.sp                    */
/*  Stored procedure:       sp_calif_interna_cliente                    */
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

if exists (select 1 from sysobjects where name = 'sp_calif_interna_cliente' and type = 'P')
   drop proc sp_calif_interna_cliente
go

create proc sp_calif_interna_cliente
                                                                                                                                                                                                                          
@i_cliente       int,
                                                                                                                                                                                                                                         
@o_calificacion  int out ,
                                                                                                                                                                                                                                    
@o_msg           descripcion out
                                                                                                                                                                                                                              
as 
                                                                                                                                                                                                                                                           
declare
                                                                                                                                                                                                                                                       
@w_est_novigente              tinyint     ,
                                                                                                                                                                                                                   
@w_est_vigente                tinyint     ,
                                                                                                                                                                                                                   
@w_est_vencido                tinyint     ,
                                                                                                                                                                                                                   
@w_est_cancelado              tinyint     ,
                                                                                                                                                                                                                   
@w_est_castigado              tinyint     ,
                                                                                                                                                                                                                   
@w_est_anulado                tinyint     ,
                                                                                                                                                                                                                   
@w_est_credito                tinyint     ,
                                                                                                                                                                                                                   
@w_error                      int         ,
                                                                                                                                                                                                                   
@w_msg                        descripcion ,
                                                                                                                                                                                                                   
@w_commit                     char(1)     ,
                                                                                                                                                                                                                   
@w_sp_name                    varchar(30) 
                                                                                                                                                                                                                    

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
exec @w_error = cob_cartera..sp_estados_cca
                                                                                                                                                                                                                   
@o_est_novigente  = @w_est_novigente out,
                                                                                                                                                                                                                     
@o_est_vigente    = @w_est_vigente   out,
                                                                                                                                                                                                                     
@o_est_vencido    = @w_est_vencido   out,
                                                                                                                                                                                                                     
@o_est_cancelado  = @w_est_cancelado out,
                                                                                                                                                                                                                     
@o_est_castigado  = @w_est_castigado out,
                                                                                                                                                                                                                     
@o_est_anulado    = @w_est_anulado   out,
                                                                                                                                                                                                                     
@o_est_credito    = @w_est_credito  out
                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
if @w_error <> 0 begin
                                                                                                                                                                                                                                        
   select @o_msg = 'ERROR AL EJECUTAR EL sp_estados_cca'
                                                                                                                                                                                                      
   return @w_error
                                                                                                                                                                                                                                            
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
/*Inicio de variables */
                                                                                                                                                                                                                                      
select 
                                                                                                                                                                                                                                                       
@w_sp_name = 'sp_calif_interna_cliente',
                                                                                                                                                                                                                      
@w_commit = 'N'
                                                                                                                                                                                                                                               

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
/*Retorna la calificacion minima del cliente*/
                                                                                                                                                                                                                
select @o_calificacion = isnull ( MIN(ci_nota),0) 
                                                                                                                                                                                                            
from cr_califica_int_mod, cob_cartera..ca_operacion 
                                                                                                                                                                                                          
where ci_banco = op_banco 
                                                                                                                                                                                                                                    
and ci_cliente = @i_cliente 
                                                                                                                                                                                                                                  
and op_estado <> @w_est_novigente 
                                                                                                                                                                                                                            
and op_estado <> @w_est_cancelado 
                                                                                                                                                                                                                            
and op_estado <> @w_est_castigado 
                                                                                                                                                                                                                            
and op_estado <> @w_est_anulado 
                                                                                                                                                                                                                              
and op_estado <> @w_est_credito
                                                                                                                                                                                                                               

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      

GO
