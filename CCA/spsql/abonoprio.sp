
/************************************************************************/
/*      Archivo:                abonoprio.sp                          */
/*      Stored procedure:       sp_abono_prioridad                      */
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
/*     Aplicar pagos por prioridad.                                     */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abono_prioridad')
   drop proc sp_abono_prioridad
go

                                                                                                                                                                                                                                                    
create proc sp_abono_prioridad (
                                                                                                                                                                                                                              
       @s_culture           varchar(10)  = 'NEUTRAL',
                                                                                                                                                                                                         
       @t_show_version      bit          = 0, -- Mostrar la version del programa
                                                                                                                                                                              
       @s_sesn              int          = null,
                                                                                                                                                                                                              
       @s_ssn               int          = null,
                                                                                                                                                                                                              
       @s_user              login        = null,
                                                                                                                                                                                                              
       @s_term              varchar (30) = null,
                                                                                                                                                                                                              
       @s_date              datetime     = null,
                                                                                                                                                                                                              
       @s_ofi               smallint     = null,
                                                                                                                                                                                                              
       @s_srv               varchar(30)  = null,
                                                                                                                                                                                                              
       @i_operacionca       int          = null,
                                                                                                                                                                                                              
       @i_operacionca_orig  int          = null,
                                                                                                                                                                                                              
       @i_prioridades       varchar(255) = null,
                                                                                                                                                                                                              
       @i_secuencial_ing    int          = null,
                                                                                                                                                                                                              
       @i_secuencial_orig   int          = null,
                                                                                                                                                                                                              
       @i_en_linea          char(1)      = 'N'
                                                                                                                                                                                                                
)
                                                                                                                                                                                                                                                             
as
                                                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
declare @w_sp_name       descripcion,
                                                                                                                                                                                                                         
        @w_return        int,
                                                                                                                                                                                                                                 
        @w_num_dec_mn    int,
                                                                                                                                                                                                                                 
        @w_concepto_aux  catalogo,
                                                                                                                                                                                                                            
        @w_i             int,
                                                                                                                                                                                                                                 
        @w_j             int,
                                                                                                                                                                                                                                 
        @w_k             int,
                                                                                                                                                                                                                                 
        @w_valor         varchar(20),
                                                                                                                                                                                                                         
        @w_error         int,
                                                                                                                                                                                                                                 
        @w_est_vigente   tinyint
                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
/** CARGADO DE LOS PARAMETROS DE CARTERA **/
                                                                                                                                                                                                                  
select @w_sp_name         = 'sp_abono_prioridades',
                                                                                                                                                                                                           
       @w_concepto_aux    = '',
                                                                                                                                                                                                                               
       @w_est_vigente     = 1
                                                                                                                                                                                                                                 
       
                                                                                                                                                                                                                                                       
  ---- JOCH Dic 15 2012 - Integracion cambios IB
                                                                                                                                                                                                              
  ---- VERSIONAMIENTO DEL PROGRAMA ----
                                                                                                                                                                                                                       
  if @t_show_version = 1
                                                                                                                                                                                                                                      
   begin
                                                                                                                                                                                                                                                      
       print 'Stored procedure Version 4.0.0.1'
                                                                                                                                                                                                               
       return 0
                                                                                                                                                                                                                                               
   end
                                                                                                                                                                                                                                                        
  ---- INTERNACIONALIZACION ----
                                                                                                                                                                                                                              
  EXEC cobis..sp_ad_establece_cultura
                                                                                                                                                                                                                         
      @o_culture = @s_culture OUT
                                                                                                                                                                                                                             
  ------------------------------
                                                                                                                                                                                                                              
   if @i_secuencial_orig is not null and @i_operacionca_orig is not null
                                                                                                                                                                                      
   begin 
                                                                                                                                                                                                                                                     
        -- INSERCION DE LAS PRIORIDADES DE PAGO, EN BASE A OPERACION ORIGINAL (VTA.CARTERA)
                                                                                                                                                                   
        insert into ca_abono_prioridad
                                                                                                                                                                                                                        
              (ap_operacion,   ap_secuencial_ing, ap_concepto, ap_prioridad)
                                                                                                                                                                                  
        select @i_operacionca, @i_secuencial_ing, ap_concepto, ap_prioridad
                                                                                                                                                                                   
          from ca_abono_prioridad
                                                                                                                                                                                                                             
         where ap_operacion = @i_operacionca_orig
                                                                                                                                                                                                             
           and ap_secuencial_ing = @i_secuencial_orig
                                                                                                                                                                                                         
        if @@error != 0  begin
                                                                                                                                                                                                                                
           select @w_error = 710030
                                                                                                                                                                                                                           
           goto ERROR
                                                                                                                                                                                                                                         
        end
                                                                                                                                                                                                                                                   
   end
                                                                                                                                                                                                                                                        
   else
                                                                                                                                                                                                                                                       
   if @i_prioridades is not null
                                                                                                                                                                                                                              
   begin 
                                                                                                                                                                                                                                                     
      -- INSERCION DE LAS PRIORIDADES DE PAGO, QUE VIENEN EN UN STRING
                                                                                                                                                                                        
      while @i_prioridades != ''
                                                                                                                                                                                                                              
      begin
                                                                                                                                                                                                                                                   
         set rowcount 1
                                                                                                                                                                                                                                       
         select @w_concepto_aux = ro_concepto
                                                                                                                                                                                                                 
         from   ca_rubro_op
                                                                                                                                                                                                                                   
         where  ro_operacion = @i_operacionca
                                                                                                                                                                                                                 
         and    ro_concepto  > @w_concepto_aux
                                                                                                                                                                                                                
         and    ro_fpago     not in ('L', 'B')
                                                                                                                                                                                                                
         and    ro_concepto_asociado is null
                                                                                                                                                                                                                  
         order by ro_concepto
                                                                                                                                                                                                                                 
         set rowcount 0
                                                                                                                                                                                                                                       
   
                                                                                                                                                                                                                                                           
         select @w_k = charindex(';',@i_prioridades)
                                                                                                                                                                                                          
         if @w_k = 0 begin
                                                                                                                                                                                                                                    
            select @w_k = charindex('#',@i_prioridades)
                                                                                                                                                                                                       
            if @w_k = 0
                                                                                                                                                                                                                                       
               select @w_valor = substring(@i_prioridades, 1, datalength(@w_valor))
                                                                                                                                                                           
            else
                                                                                                                                                                                                                                              
               select @w_valor = substring(@i_prioridades, 1, @w_k-1)
                                                                                                                                                                                         
   
                                                                                                                                                                                                                                                           
            delete ca_abono_prioridad
                                                                                                                                                                                                                         
            where ap_operacion = @i_operacionca
                                                                                                                                                                                                               
            and ap_secuencial_ing = @i_secuencial_ing
                                                                                                                                                                                                         
            and ap_concepto = @w_concepto_aux
                                                                                                                                                                                                                 
   
                                                                                                                                                                                                                                                           
            insert into ca_abono_prioridad
                                                                                                                                                                                                                    
            values (@i_operacionca,@i_secuencial_ing,@w_concepto_aux,convert(int,@w_valor))
                                                                                                                                                                   
            if @@error != 0 begin
                                                                                                                                                                                                                             
               select @w_error = 710030
                                                                                                                                                                                                                       
               goto ERROR
                                                                                                                                                                                                                                     
            end
                                                                                                                                                                                                                                               
          /*update ca_rubro_op
                                                                                                                                                                                                                                
            set ro_prioridad = convert(int,@w_valor)
                                                                                                                                                                                                          
            where ro_operacion = @i_operacionca
                                                                                                                                                                                                               
            and ro_concepto = @w_concepto_aux*/
                                                                                                                                                                                                               
   
                                                                                                                                                                                                                                                           
            select @w_i = @w_i + 1,
                                                                                                                                                                                                                           
                   @w_j = 1
                                                                                                                                                                                                                                   
            break
                                                                                                                                                                                                                                             
         end else begin
                                                                                                                                                                                                                                       
            select @w_valor = substring (@i_prioridades, 1, @w_k-1)
                                                                                                                                                                                           
   
                                                                                                                                                                                                                                                           
            delete ca_abono_prioridad
                                                                                                                                                                                                                         
            where ap_operacion = @i_operacionca
                                                                                                                                                                                                               
            and ap_secuencial_ing = @i_secuencial_ing
                                                                                                                                                                                                         
            and ap_concepto = @w_concepto_aux
                                                                                                                                                                                                                 
   
                                                                                                                                                                                                                                                           
            insert into ca_abono_prioridad
                                                                                                                                                                                                                    
            values (@i_operacionca,@i_secuencial_ing,@w_concepto_aux,convert(int,@w_valor))
                                                                                                                                                                   
            if @@error != 0 begin
                                                                                                                                                                                                                             
               select @w_error = 710001
                                                                                                                                                                                                                       
               goto ERROR
                                                                                                                                                                                                                                     
            end
                                                                                                                                                                                                                                               
            /**** MANTENER LAS PRIORIDADES DEFAULT ***
                                                                                                                                                                                                        
            update ca_rubro_op
                                                                                                                                                                                                                                
            set ro_prioridad = convert(int,@w_valor)
                                                                                                                                                                                                          
            where ro_operacion = @i_operacionca
                                                                                                                                                                                                               
            and ro_concepto = @w_concepto_aux
                                                                                                                                                                                                                 
            *******************************************/
                                                                                                                                                                                                      
            select @w_j = @w_j + 1
                                                                                                                                                                                                                            
            select @i_prioridades = substring(@i_prioridades, @w_k +1,
                                                                                                                                                                                        
                   datalength(@i_prioridades) - @w_k)
                                                                                                                                                                                                         
         end
                                                                                                                                                                                                                                                  
      end --while
                                                                                                                                                                                                                                             
   end --if
                                                                                                                                                                                                                                                   
   else
                                                                                                                                                                                                                                                       
   begin 
                                                                                                                                                                                                                                                     
      -- INSERTAR PRIORIDADES DEFAULT
                                                                                                                                                                                                                         
      while 1=1
                                                                                                                                                                                                                                               
      begin
                                                                                                                                                                                                                                                   
         set rowcount 1
                                                                                                                                                                                                                                       
         select @w_concepto_aux = ro_concepto,
                                                                                                                                                                                                                
                @w_j            = ro_prioridad
                                                                                                                                                                                                                
           from ca_rubro_op
                                                                                                                                                                                                                                   
          where ro_operacion = @i_operacionca
                                                                                                                                                                                                                 
            and ro_concepto  > @w_concepto_aux
                                                                                                                                                                                                                
            and ro_fpago     not in ('L', 'B')
                                                                                                                                                                                                                
            and ro_concepto_asociado is null
                                                                                                                                                                                                                  
   
                                                                                                                                                                                                                                                           
         if @@rowcount = 0 break --Salir del lazo
                                                                                                                                                                                                             
   
                                                                                                                                                                                                                                                           
         set rowcount 0
                                                                                                                                                                                                                                       
   
                                                                                                                                                                                                                                                           
         if not exists (select 1 from ca_abono_prioridad
                                                                                                                                                                                                      
                         where ap_operacion = @i_operacionca
                                                                                                                                                                                                  
                           and ap_secuencial_ing = @i_secuencial_ing
                                                                                                                                                                                          
                           and ap_concepto  = @w_concepto_aux)
                                                                                                                                                                                                
         begin
                                                                                                                                                                                                                                                
            insert into ca_abono_prioridad
                                                                                                                                                                                                                    
                   (ap_operacion,   ap_secuencial_ing, ap_concepto, ap_prioridad)
                                                                                                                                                                             
            values (@i_operacionca, @i_secuencial_ing, @w_concepto_aux, @w_j)
                                                                                                                                                                                 
            if @@error != 0  begin
                                                                                                                                                                                                                            
               select @w_error = 710030
                                                                                                                                                                                                                       
               goto ERROR
                                                                                                                                                                                                                                     
            end
                                                                                                                                                                                                                                               
         end
                                                                                                                                                                                                                                                  
      end --del While
                                                                                                                                                                                                                                         
   end
                                                                                                                                                                                                                                                        
   --CONTROLAR QUE LA PRIORIDAD DEL INTERES SEA IGUAL A LA PRIORIDAD DEL FECI
                                                                                                                                                                                 
 
                                                                                                                                                                                                                                                             
select @w_j = ap_prioridad
                                                                                                                                                                                                                                    
  from ca_abono_prioridad, ca_rubro_op
                                                                                                                                                                                                                        
 where ap_operacion      = @i_operacionca
                                                                                                                                                                                                                     
   and ap_secuencial_ing = @i_secuencial_ing
                                                                                                                                                                                                                  
   and ro_operacion      = ap_operacion
                                                                                                                                                                                                                       
   and ap_concepto       = ro_concepto
                                                                                                                                                                                                                        
   and ro_tipo_rubro     = 'F' --Feci
                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
if @@rowcount > 0
                                                                                                                                                                                                                                             
begin
                                                                                                                                                                                                                                                         
   select @w_i = ap_prioridad
                                                                                                                                                                                                                                 
     from ca_abono_prioridad, ca_rubro_op
                                                                                                                                                                                                                     
    where ap_operacion      = @i_operacionca
                                                                                                                                                                                                                  
      and ap_secuencial_ing = @i_secuencial_ing
                                                                                                                                                                                                               
      and ro_operacion      = ap_operacion
                                                                                                                                                                                                                    
      and ap_concepto       = ro_concepto
                                                                                                                                                                                                                     
      and ro_tipo_rubro     = 'I' --Interes
                                                                                                                                                                                                                   

                                                                                                                                                                                                                                                              
    if @w_j != @w_i
                                                                                                                                                                                                                                           
    begin
                                                                                                                                                                                                                                                     
       select @w_error = 710230
                                                                                                                                                                                                                               
       goto ERROR
                                                                                                                                                                                                                                             
    end
                                                                                                                                                                                                                                                       
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
ERROR:
                                                                                                                                                                                                                                                        
if @i_en_linea ='S'
                                                                                                                                                                                                                                           
begin
                                                                                                                                                                                                                                                         
   exec cobis..sp_cerror
                                                                                                                                                                                                                                      
   @t_debug='N',    @t_file=null,
                                                                                                                                                                                                                             
   @t_from=@w_sp_name,   @i_num = @w_error,
                                                                                                                                                                                                                   
   @s_culture = @s_culture
                                                                                                                                                                                                                                    
   return @w_error
                                                                                                                                                                                                                                            
end
                                                                                                                                                                                                                                                           
else
                                                                                                                                                                                                                                                          
   return @w_error
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
go 

