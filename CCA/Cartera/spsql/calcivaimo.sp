
/************************************************************************/
/*      Nombre Fisico:          calcivaimo.sp                           */
/*      Nombre Logico:       	sp_calculo_iva_imo                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Ene. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/  
/*                              PROPOSITO                               */
/*     Calculo IVA IMO                                                  */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calculo_iva_imo')
   drop proc sp_calculo_iva_imo
go

                                                                                                                                                                                                                                                    
CREATE PROCEDURE sp_calculo_iva_imo (
                                                                                                                                                                                                                 
   @s_date              datetime    = null,
                                                                                                                                                                                                                   
   @s_ssn               int         = null,
                                                                                                                                                                                                                   
   @s_srv               varchar(30) = null,
                                                                                                                                                                                                                   
   @s_user              login       = null,
                                                                                                                                                                                                                   
   @s_term              descripcion = null,
                                                                                                                                                                                                                   
   @s_ofi               smallint    = null,
                                                                                                                                                                                                                   
   @i_banco             cuenta      = null,
                                                                                                                                                                                                                   
   @i_operacion         char(1)     = NULL,
                                                                                                                                                                                                                   
   @i_concepto          varchar(10) = NULL,
                                                                                                                                                                                                                   
   @i_en_linea          char(1)     = 'S'
                                                                                                                                                                                                                     
)
                                                                                                                                                                                                                                                             
AS
                                                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
/*@i_formato_fecha     int         = null,
                                                                                                                                                                                                                    
   @i_toperacion        varchar(10) = null,
                                                                                                                                                                                                                   
   @i_moneda            int         = null,
                                                                                                                                                                                                                   
   @i_concepto          varchar(10) = null,
                                                                                                                                                                                                                   
   @i_monto             money       = null,
                                                                                                                                                                                                                   
   @i_comentario        varchar(64) = null,
                                                                                                                                                                                                                   
   @i_tipo_rubro        char(1)     = null,
                                                                                                                                                                                                                   
   @i_base_calculo      money       = 0,
                                                                                                                                                                                                                      
   @i_div_desde         smallint    = 0,
                                                                                                                                                                                                                      
   @i_div_hasta         smallint    = 0,
                                                                                                                                                                                                                      
   @i_saldo_op          char(1)     = 'N',
                                                                                                                                                                                                                    
   @i_saldo_por_desem   char(1)     = 'N',
                                                                                                                                                                                                                    
   @i_tasa              float       = 0,
                                                                                                                                                                                                                      
   @i_num_dec_tapl      tinyint     = null,
                                                                                                                                                                                                                   
   @i_credito           char(1)     = 'N',
                                                                                                                                                                                                                    
   @i_sec_act           int         = null,
                                                                                                                                                                                                                   
   @i_forma_cabio_fecha char(1)     = null,
                                                                                                                                                                                                                   
   @i_secuencial        int         = null,
                                                                                                                                                                                                                   
   @i_en_linea          char(1)     = 'S',
                                                                                                                                                                                                                    
   @i_desde_batch       char(1)     = 'N',
                                                                                                                                                                                                                    
   @i_secuencial_ioc    int         = null,
                                                                                                                                                                                                                   
   @o_sec_tran          int         = 0 output*/
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
DECLARE
                                                                                                                                                                                                                                                       
   @w_sp_name              varchar(32),
                                                                                                                                                                                                                       
   @w_error                int,
                                                                                                                                                                                                                               
   @w_sector               catalogo,
                                                                                                                                                                                                                          
   @w_commit               char(1),
                                                                                                                                                                                                                           
   @w_operacion            int,
                                                                                                                                                                                                                               
   @w_oficina              smallint,
                                                                                                                                                                                                                          
   @w_fecha_ult_proceso    datetime,
                                                                                                                                                                                                                          
   @w_cliente              INT,
                                                                                                                                                                                                                               
   @w_gerente              smallint,
                                                                                                                                                                                                                          
   @w_gar_admisible        char(1), 
                                                                                                                                                                                                                          
   @w_reestructuracion     char(1),
                                                                                                                                                                                                                           
   @w_calificacion         catalogo,
                                                                                                                                                                                                                           
   @w_moneda               int,
                                                                                                                                                                                                                               
   @w_toperacion           catalogo,
                                                                                                                                                                                                                          
   @w_ru_tipo_rubro        catalogo,
                                                                                                                                                                                                                          
   @w_ru_limite            char(1),
                                                                                                                                                                                                                           
   @w_rubro_iva            catalogo,
                                                                                                                                                                                                                          
   @w_tasa_ref_iva         catalogo,
                                                                                                                                                                                                                          
   @w_tasa_iva             float
                                                                                                                                                                                                                              
   
                                                                                                                                                                                                                                                           
select @w_sp_name = 'sp_calculo_iva_imo' 
                                                                                                                                                                                                                     

                                                                                                                                                                                                                                                              
if @i_operacion = 'I' begin
                                                                                                                                                                                                                                   

                                                                                                                                                                                                                                                              
   select
                                                                                                                                                                                                                                                     
   @w_operacion         = op_operacion,
                                                                                                                                                                                                                       
   @w_oficina           = op_oficina,
                                                                                                                                                                                                                         
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
                                                                                                                                                                                                               
   @w_cliente           = op_cliente,
                                                                                                                                                                                                                         
   @w_gerente           = op_oficial,
                                                                                                                                                                                                                         
   @w_gar_admisible     = op_gar_admisible,
                                                                                                                                                                                                                   
   @w_reestructuracion  = op_reestructuracion,
                                                                                                                                                                                                                
   @w_calificacion      = isnull(op_calificacion,'A'),
                                                                                                                                                                                                        
   @w_moneda            = op_moneda,
                                                                                                                                                                                                                          
   @w_toperacion        = op_toperacion,
                                                                                                                                                                                                                      
   @w_sector            = op_sector
                                                                                                                                                                                                                           
   from   ca_operacion
                                                                                                                                                                                                                                        
   where  op_banco = @i_banco
                                                                                                                                                                                                                                 
   
                                                                                                                                                                                                                                                           
   select
                                                                                                                                                                                                                                                     
   @w_operacion,
                                                                                                                                                                                                                                              
   @w_oficina,
                                                                                                                                                                                                                                                
   @w_fecha_ult_proceso,
                                                                                                                                                                                                                                      
   @w_cliente,
                                                                                                                                                                                                                                                
   @w_gerente,
                                                                                                                                                                                                                                                
   @w_gar_admisible,
                                                                                                                                                                                                                                          
   @w_reestructuracion,
                                                                                                                                                                                                                                       
   @w_calificacion,
                                                                                                                                                                                                                                           
   @w_moneda,
                                                                                                                                                                                                                                                 
   @w_toperacion -->
                                                                                                                                                                                                                                          
   
                                                                                                                                                                                                                                                           
   SELECT
                                                                                                                                                                                                                                                     
   @w_ru_tipo_rubro = ru_tipo_rubro,
                                                                                                                                                                                                                          
   @w_ru_limite     = ru_limite
                                                                                                                                                                                                                               
   from   ca_rubro
                                                                                                                                                                                                                                            
   where  ru_toperacion = @w_toperacion
                                                                                                                                                                                                                       
   and    ru_moneda     = @w_moneda
                                                                                                                                                                                                                           
   and    ru_concepto   = @i_concepto
                                                                                                                                                                                                                         
   
                                                                                                                                                                                                                                                           
   SELECT @w_ru_tipo_rubro, @w_ru_limite -->
                                                                                                                                                                                                                  
   
                                                                                                                                                                                                                                                           
   select
                                                                                                                                                                                                                                                     
   @w_ru_tipo_rubro = ru_tipo_rubro,
                                                                                                                                                                                                                          
   @w_ru_limite     = ru_limite
                                                                                                                                                                                                                               
   from   ca_rubro
                                                                                                                                                                                                                                            
   where  ru_toperacion = @w_toperacion
                                                                                                                                                                                                                       
   and    ru_moneda     = @w_moneda
                                                                                                                                                                                                                           
   and    ru_concepto   = @i_concepto
                                                                                                                                                                                                                         
  
                                                                                                                                                                                                                                                            
   SELECT @w_ru_tipo_rubro,@w_ru_limite -->
                                                                                                                                                                                                                   

                                                                                                                                                                                                                                                              
   select
                                                                                                                                                                                                                                                     
   @w_rubro_iva       = ru_concepto,
                                                                                                                                                                                                                          
   @w_tasa_ref_iva    = ru_referencial
                                                                                                                                                                                                                        
   from   ca_rubro
                                                                                                                                                                                                                                            
   where  ru_toperacion          = @w_toperacion
                                                                                                                                                                                                              
   and    ru_moneda              = @w_moneda
                                                                                                                                                                                                                  
   and    ru_concepto_asociado   = @i_concepto
                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
   select @w_rubro_iva, @w_tasa_ref_iva -->
                                                                                                                                                                                                                   
   
                                                                                                                                                                                                                                                           
   if @@rowcount <> 0 begin
                                                                                                                                                                                                                                   

                                                                                                                                                                                                                                                              
      select @w_tasa_iva = vd_valor_default
                                                                                                                                                                                                                   
      from   ca_valor, ca_valor_det
                                                                                                                                                                                                                           
      where  va_tipo   = @w_tasa_ref_iva
                                                                                                                                                                                                                      
      and    vd_tipo   = @w_tasa_ref_iva
                                                                                                                                                                                                                      
      and    vd_sector = @w_sector
                                                                                                                                                                                                                            
      
                                                                                                                                                                                                                                                        
      SELECT TOP 10  * FROM ca_valor_det
                                                                                                                                                                                                                      
      
                                                                                                                                                                                                                                                        
      
                                                                                                                                                                                                                                                        
      if @@rowcount = 0
                                                                                                                                                                                                                                       
      begin
                                                                                                                                                                                                                                                   
          select @w_error = 710076
                                                                                                                                                                                                                            
          goto ERROR
                                                                                                                                                                                                                                          
      END
                                                                                                                                                                                                                                                     
      
                                                                                                                                                                                                                                                        
      select @w_tasa_iva
                                                                                                                                                                                                                                      
      
                                                                                                                                                                                                                                                        
   end
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
end 
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
RETURN 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
ERROR:
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
if @w_commit = 'S' begin
                                                                                                                                                                                                                                      
   select @w_commit = 'N'
                                                                                                                                                                                                                                     
   rollback tran
                                                                                                                                                                                                                                              
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
if @i_en_linea = 'S'
                                                                                                                                                                                                                                          
begin
                                                                                                                                                                                                                                                         
   exec cobis..sp_cerror
                                                                                                                                                                                                                                      
   @t_debug = 'N',
                                                                                                                                                                                                                                            
   @t_from  = @w_sp_name,
                                                                                                                                                                                                                                     
   @i_num   = @w_error
                                                                                                                                                                                                                                        
end
                                                                                                                                                                                                                                                              
return @w_error                                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
go 

