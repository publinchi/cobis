/*************************************************************************/
/*   Archivo:              cambio_valor.sp                               */
/*   Stored procedure:     sp_cambio_valor                               */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
go
if exists (select 1 from sysobjects where name = 'sp_cambio_valor')
    drop proc sp_cambio_valor
go

create proc sp_cambio_valor (
                                                                                                                                                                                                                                 
   @s_ssn                int      = null,
                                                                                                                                                                                                                     
   @s_date               datetime = null,
                                                                                                                                                                                                                     
   @s_user               login    = null,
                                                                                                                                                                                                                     
   @s_term               descripcion = null,
                                                                                                                                                                                                                  
   @s_ofi                smallint  = null,
                                                                                                                                                                                                                    
   @t_trn                smallint = null,
                                                                                                                                                                                                                     
   @i_operacion          char(1)  = null,
                                                                                                                                                                                                                     
   @i_filial             tinyint = null,
                                                                                                                                                                                                                      
   @i_sucursal           smallint = null,
                                                                                                                                                                                                                     
   @i_tipo_cust          varchar(64) = null,
                                                                                                                                                                                                                  
   @i_custodia           int = null,
                                                                                                                                                                                                                          
   @i_fecha_tran         datetime,
                                                                                                                                                                                                                            
   @i_debcred            char(1) = null,
                                                                                                                                                                                                                      
   @i_valor              float = 0,  	--NVR money por float "acciones"
                                                                                                                                                                                        
   @i_num_acciones       float = 0,		--NVR int por float "ACCIONES"
                                                                                                                                                                                           
   @i_valor_accion       money = 0,
                                                                                                                                                                                                                           
   @i_valor_cobertura    float = 0,	--NVR money por float
                                                                                                                                                                                                     
   @i_descripcion        varchar(64) = null,
                                                                                                                                                                                                                  
   @i_autoriza           varchar(25) = null,   --NVR1
                                                                                                                                                                                                         
   @i_nuevo_comercial    money = 0,
                                                                                                                                                                                                                           
   @i_tipo_superior	     varchar(64) = null,
                                                                                                                                                                                                                  
   @i_codigo_externo     varchar(64) = null,
                                                                                                                                                                                                                  
   @i_afecta_prod        char(1) = 'N'
                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
)
                                                                                                                                                                                                                                                             
as
                                                                                                                                                                                                                                                            
   declare
                                                                                                                                                                                                                                                    
   @w_return int,
                                                                                                                                                                                                                                             
   @w_today              datetime,
                                                                                                                                                                                                                            
   @w_sp_name            varchar(32),  /* nombre stored proc          */
                                                                                                                                                                                      
   @w_secuencial  int,  --PGA 8mar2001
                                                                                                                                                                                                                        
   @w_estado      char(1),  --PGA 11jul2001
                                                                                                                                                                                                                   
   @w_agotada     char(1), --PGA 11jul2001
                                                                                                                                                                                                                    
   @w_valor_actual money --emg
                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
select @w_sp_name = 'sp_cambio_valor'
                                                                                                                                                                                                                         
select @w_today = convert(varchar(10),@s_date,101)
                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
                                                                                                                                                                                                                                                           
return 0
                                                                                                                                                                                                                                                      
ERROR:
                                                                                                                                                                                                                                                        
   exec cobis..sp_cerror
                                                                                                                                                                                                                                      
   @t_from  = @w_sp_name,
                                                                                                                                                                                                                                     
   @i_num   = @w_return
                                                                                                                                                                                                                                       
   return 1
                                                                                                                                                                                                                                                   
go
