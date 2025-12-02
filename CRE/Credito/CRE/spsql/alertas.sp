/************************************************************************/
/*  Archivo:                alertas.sp                                  */
/*  Stored procedure:       sp_alertas                                  */
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

if exists (select 1 from sysobjects where name = 'sp_alertas' and type = 'P')
   drop proc sp_alertas
go
                                                                                                                                                                                                                                                              
   create proc sp_alertas (
                                                                                                                                                                                                                                   
   @i_cliente       int     = null,
                                                                                                                                                                                                                           
   @i_num_banco     cuenta  = null,
                                                                                                                                                                                                                           
   @i_pago_ext      char(1) = 'N',       --pagos desde CNB   
                                                                                                                                                                                                 
   @i_crea_ext      char(1) = null       -- cca 353 alianzas bancamia 
                                                                                                                                                                                        
   )
                                                                                                                                                                                                                                                          
   as
                                                                                                                                                                                                                                                         
   declare
                                                                                                                                                                                                                                                    
   
                                                                                                                                                                                                                                                           
   @w_porc_saldo   float,
                                                                                                                                                                                                                                     
   @w_monto        money,
                                                                                                                                                                                                                                     
   @w_disponible   money,
                                                                                                                                                                                                                                     
   @w_smmlv        money,
                                                                                                                                                                                                                                     
   @w_meses        int,
                                                                                                                                                                                                                                       
   @w_fecha_vto    datetime,
                                                                                                                                                                                                                                  
   @w_mensaje      varchar(255),
                                                                                                                                                                                                                              
   @w_banca        catalogo,
                                                                                                                                                                                                                                  
   @w_fecha_pro    datetime,
                                                                                                                                                                                                                                  
   @w_dias_pol     smallint   -- JAR REQ 266
                                                                                                                                                                                                                  

                                                                                                                                                                                                                                                              
   select 
                                                                                                                                                                                                                                                    
   @w_fecha_pro = fp_fecha
                                                                                                                                                                                                                                    
   from cobis..ba_fecha_proceso
                                                                                                                                                                                                                               
   
                                                                                                                                                                                                                                                           
   -- PORCENTAJE SALDO DISPONIBLE CUPO
                                                                                                                                                                                                                        
   select 
                                                                                                                                                                                                                                                    
   @w_porc_saldo = pa_float / 100.00
                                                                                                                                                                                                                          
   from   cobis..cl_parametro
                                                                                                                                                                                                                                 
   where  pa_producto = 'CRE'
                                                                                                                                                                                                                                 
   and    pa_nemonico = 'PRSCUP'
                                                                                                                                                                                                                              
      
                                                                                                                                                                                                                                                        
   -- SALARIO MINIMO MENSUAL LEGAL VIGENTE
                                                                                                                                                                                                                    
   select 
                                                                                                                                                                                                                                                    
   @w_smmlv = pa_money
                                                                                                                                                                                                                                        
   from   cobis..cl_parametro
                                                                                                                                                                                                                                 
   where  pa_producto = 'ADM'
                                                                                                                                                                                                                                 
   and    pa_nemonico = 'SMV'
                                                                                                                                                                                                                                 
        
                                                                                                                                                                                                                                                      
   -- DIAS PARA MENSAJE VENCIMIENTO POLIZAS -- JAR REQ 266
                                                                                                                                                                                                    
   select 
                                                                                                                                                                                                                                                    
   @w_dias_pol = pa_smallint
                                                                                                                                                                                                                                  
   from   cobis..cl_parametro
                                                                                                                                                                                                                                 
   where  pa_producto = 'GAR'
                                                                                                                                                                                                                                 
   and    pa_nemonico = 'DIAPOL'
                                                                                                                                                                                                                              
   
                                                                                                                                                                                                                                                           
   if @i_cliente is not null
                                                                                                                                                                                                                                  
   begin
                                                                                                                                                                                                                                                      
      select 
                                                                                                                                                                                                                                                 
      @w_banca = en_banca,
                                                                                                                                                                                                                                    
      @w_disponible = li_monto - isnull(li_utilizado,0) - isnull(li_reservado,0),
                                                                                                                                                                             
      @w_fecha_vto  = li_fecha_vto
                                                                                                                                                                                                                            
      from cr_linea, cobis..cl_ente
                                                                                                                                                                                                                           
      where en_ente      = @i_cliente
                                                                                                                                                                                                                         
      and   li_cliente   = en_ente
                                                                                                                                                                                                                            
      and   li_estado    = 'V'
                                                                                                                                                                                                                                
   end
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
   if @i_num_banco is not null
                                                                                                                                                                                                                                
   begin
                                                                                                                                                                                                                                                      
      select @w_banca = en_banca,
                                                                                                                                                                                                                             
      @w_disponible   = li_monto - isnull(li_utilizado,0) - isnull(li_reservado,0),
                                                                                                                                                                           
      @w_fecha_vto    = li_fecha_vto
                                                                                                                                                                                                                          
      from cr_linea, cobis..cl_ente
                                                                                                                                                                                                                           
      where li_cliente   = en_ente
                                                                                                                                                                                                                            
      and li_num_banco   = @i_num_banco
                                                                                                                                                                                                                       
      and li_estado      = 'V'
                                                                                                                                                                                                                                
   end
                                                                                                                                                                                                                                                        
   
                                                                                                                                                                                                                                                           
   -- CLIENTES POTENCIALES DE CUPO
                                                                                                                                                                                                                            
   if exists (select 1 from cr_reporte064
                                                                                                                                                                                                                     
   where re_cliente    = @i_cliente
                                                                                                                                                                                                                           
   and re_tipo_cliente = 'P')
                                                                                                                                                                                                                                 
   begin
                                                                                                                                                                                                                                                      
      if (@i_pago_ext = 'N' and @i_crea_ext is null)
                                                                                                                                                                                                          
         PRINT 'CLIENTE POTENCIAL DE CUPO'
                                                                                                                                                                                                                    
   end
                                                                                                                                                                                                                                                        
   
                                                                                                                                                                                                                                                           
   -- CUPO CON SALDO DISPONIBLE
                                                                                                                                                                                                                               
   if @w_disponible >= @w_smmlv * @w_porc_saldo
                                                                                                                                                                                                               
   begin
                                                                                                                                                                                                                                                      
      if (@i_pago_ext = 'N' and @i_crea_ext is null)
                                                                                                                                                                                                          
         PRINT 'CLIENTE CON SALDO DISPONIBLE EN CUPO'
                                                                                                                                                                                                         
   end
                                                                                                                                                                                                                                                        
   
                                                                                                                                                                                                                                                           
   -- CUPO DE CREDITO PROXIMO A VENCERSE
                                                                                                                                                                                                                      
   select @w_meses = round(datediff(dd, @w_fecha_pro, @w_fecha_vto) / 30,0)
                                                                                                                                                                                   
   
                                                                                                                                                                                                                                                           
   select 
                                                                                                                                                                                                                                                    
   @w_mensaje = pm_mensaje
                                                                                                                                                                                                                                    
   from  cr_param_mensajes
                                                                                                                                                                                                                                    
   where pm_tipo   = '2'
                                                                                                                                                                                                                                      
   and   pm_cuotas = @w_meses
                                                                                                                                                                                                                                 
   and   pm_banca  = @w_banca
                                                                                                                                                                                                                                 
      
                                                                                                                                                                                                                                                        
   if @w_mensaje is not null
                                                                                                                                                                                                                                  
   begin
                                                                                                                                                                                                                                                      
      if (@i_pago_ext = 'N' and @i_crea_ext is null)
                                                                                                                                                                                                          
         PRINT @w_mensaje  
                                                                                                                                                                                                                                   
   end
                                                                                                                                                                                                                                                        
   
                                                                                                                                                                                                                                                           
   -- UTILIZACIONES DE CREDITO PROXIMO A VENCERSE
                                                                                                                                                                                                             
   select op_operacion as operacion, count(di_dividendo) as no_cuotas
                                                                                                                                                                                         
   into #op_util
                                                                                                                                                                                                                                              
   from cob_cartera..ca_dividendo, cob_cartera..ca_operacion, cr_tramite
                                                                                                                                                                                      
   where tr_cliente    =  @i_cliente
                                                                                                                                                                                                                          
   and tr_tipo         =  'T'
                                                                                                                                                                                                                                 
   and tr_estado       =  'A'
                                                                                                                                                                                                                                 
   and op_estado       <> 3
                                                                                                                                                                                                                                   
   and di_estado       <> 3
                                                                                                                                                                                                                                   
   and di_fecha_ven    <= op_fecha_fin
                                                                                                                                                                                                                        
   and tr_tramite      =  op_tramite
                                                                                                                                                                                                                          
   and op_operacion    =  di_operacion
                                                                                                                                                                                                                        
   group by op_operacion
                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
   select @w_mensaje = null
                                                                                                                                                                                                                                   
   
                                                                                                                                                                                                                                                           
   select 
                                                                                                                                                                                                                                                    
   @w_mensaje = pm_mensaje
                                                                                                                                                                                                                                    
   from   cr_param_mensajes, #op_util
                                                                                                                                                                                                                         
   where  pm_tipo   = '1'
                                                                                                                                                                                                                                     
   and    pm_cuotas = no_cuotas
                                                                                                                                                                                                                               
   and    pm_banca  = @w_banca
                                                                                                                                                                                                                                
   
                                                                                                                                                                                                                                                           
   if @w_mensaje is not null
                                                                                                                                                                                                                                  
   begin
                                                                                                                                                                                                                                                      
      if (@i_pago_ext = 'N' and @i_crea_ext is null)
                                                                                                                                                                                                          
         PRINT @w_mensaje   
                                                                                                                                                                                                                                  
   end
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
-- VENCIMIENTO DE POLIZAS
                                                                                                                                                                                                                                     
   select tr_tramite, gp_garantia
                                                                                                                                                                                                                             
   into #tramites
                                                                                                                                                                                                                                             
   from cr_tramite with (nolock), cr_gar_propuesta with (nolock), 
                                                                                                                                                                                            
   cob_cartera..ca_operacion with (nolock),  cob_custodia..cu_custodia with (nolock)
                                                                                                                                                                          
   where tr_cliente     =        @i_cliente
                                                                                                                                                                                                                   
   and tr_tipo          not in   ( 'E', 'C')
                                                                                                                                                                                                                  
   and tr_estado        <>       'Z'
                                                                                                                                                                                                                          
   and op_estado        not in   (3,6)
                                                                                                                                                                                                                        
   and cu_estado        not in   ('C', 'E', 'Z')
                                                                                                                                                                                                              
   and tr_tramite       =        op_tramite
                                                                                                                                                                                                                   
   and tr_tramite       =        gp_tramite
                                                                                                                                                                                                                   
   and gp_garantia      =        cu_codigo_externo
                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
   if exists (select 1 from #tramites, cob_custodia..cu_poliza with (nolock)
                                                                                                                                                                                  
   where po_estado_poliza  = 'V' 
                                                                                                                                                                                                                             
   and gp_garantia       = po_codigo_externo
                                                                                                                                                                                                                  
   and datediff(dd, @w_fecha_pro, po_fvigencia_fin) <= @w_dias_pol)
                                                                                                                                                                                           
   begin
                                                                                                                                                                                                                                                      
      if (@i_pago_ext = 'N' and @i_crea_ext is null)
                                                                                                                                                                                                          
         PRINT 'POLIZA DE LA GARANTIA PROXIMA A VENCER, POR FAVOR INFORMAR AL GESTOR RESPECTIVO'   
                                                                                                                                                           
   end
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
   return 0
                                                                                                                                                                                                                                                   

                                                                                                                                                                                                                                                              

GO
