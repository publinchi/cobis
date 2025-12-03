
/************************************************************************/
/*      Archivo:                tcca_segcred.sp                         */
/*      Stored procedure:       sp_tcca_segcred                         */
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

if exists (select 1 from sysobjects where name = 'sp_tcca_segcred')
   drop proc sp_tcca_segcred
go

create proc sp_tcca_segcred (
                                                                                                                                                                                                                                 
   @i_operacion          char(1)  = null,  -- PROCESO A REALIZARSE
                                                                                                                                                                                            
   @i_tipo_car           catalogo = null,  -- TIPO DE CARTERA
                                                                                                                                                                                                 
   @i_seg_cred           catalogo = null,  -- Segmento de credito
                                                                                                                                                                                             
   @i_val_min            money    = null,
                                                                                                                                                                                                                     
   @i_val_max            money    = null,
                                                                                                                                                                                                                     
   @i_programa           varchar(40) = null,
                                                                                                                                                                                                                  
   @i_modo               tinyint  = 0,      -- SIGUIENTE
                                                                                                                                                                                                      
   @i_valor_maximo_sis_fin money  = 0,
                                                                                                                                                                                                                        
   @i_valor_max_m2       money    = null,   --JZU Mejora Reporte de Tasas
                                                                                                                                                                                     
   @i_valor_max_viv      money    = null    --JZU Mejora Reporte de Tasas
                                                                                                                                                                                     
)
                                                                                                                                                                                                                                                             
as
                                                                                                                                                                                                                                                            
declare 
                                                                                                                                                                                                                                                      
   @w_sp_name            varchar(32),      -- NOMBRE STORED PROC
                                                                                                                                                                                              
   @w_return             int,              -- VALOR QUE RETORNA
                                                                                                                                                                                               
   @w_error              int,              -- CODIGO DE ERROR
                                                                                                                                                                                                 
   @w_existe             tinyint,          -- EXisTE EL REGisTRO
                                                                                                                                                                                              
   @w_seg_cred           catalogo,         -- TIPO DE OPERACION
                                                                                                                                                                                               
   @w_tipo_car           catalogo,         -- TIPO DE CARTERA
                                                                                                                                                                                                 
   @w_des_segcred        varchar(64),      -- DETALLE DEL TIPO DE OPERACION
                                                                                                                                                                                   
   @w_det_tipocar        varchar(64),       -- DETALLE TIPO DE CARTERA
                                                                                                                                                                                        
   @w_val_min            money,
                                                                                                                                                                                                                               
   @w_val_max            money,
                                                                                                                                                                                                                               
   @w_programa           varchar(40),
                                                                                                                                                                                                                         
   @w_valor_maximo_sis_fin money,
                                                                                                                                                                                                                             
   @w_valor_max_m2       money,           --JZU Mejora Reporte de Tasas
                                                                                                                                                                                       
   @w_valor_max_viv      money            --JZU Mejora Reporte de Tasas
                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
select @w_sp_name = 'sp_tcca_segcred'
                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
if @i_operacion = 'I'
                                                                                                                                                                                                                                         
begin
                                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
   if @i_seg_cred is null or  @i_tipo_car is null
                                                                                                                                                                                                             
   begin
                                                                                                                                                                                                                                                      
      select @w_error = 708150
                                                                                                                                                                                                                                
      goto ERROR
                                                                                                                                                                                                                                              
   end
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
   if exists (select 1 from cob_cartera..ca_segcred_tipocca
                                                                                                                                                                                                   
              where  st_seg_cred = @i_seg_cred 
                                                                                                                                                                                                               
              and    st_tipo_cca = @i_tipo_car)
                                                                                                                                                                                                               
   begin
                                                                                                                                                                                                                                                      
      select @w_error = 708151
                                                                                                                                                                                                                                
      goto ERROR
                                                                                                                                                                                                                                              
   end
                                                                                                                                                                                                                                                        
   else 
                                                                                                                                                                                                                                                      
   begin
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
      insert into ca_segcred_tipocca(st_seg_cred,     st_tipo_cca,        st_valor_minimo,    st_valor_maximo,
                                                                                                                                                
                     st_programa,     st_valor_maximo_sis_fin,st_valor_max_m2,    st_valor_max_viv)
                                                                                                                                                           
                       values (@i_seg_cred,    @i_tipo_car,         @i_val_min,         @i_val_max, 
                                                                                                                                                          
                     @i_programa,     @i_valor_maximo_sis_fin,@i_valor_max_m2,    @i_valor_max_viv)--JZU Mejora Reporte de Tasas
                                                                                                                              

                                                                                                                                                                                                                                                              
      if @@error != 0
                                                                                                                                                                                                                                         
      begin
                                                                                                                                                                                                                                                   
         select @w_error = 708154
                                                                                                                                                                                                                             
         goto ERROR
                                                                                                                                                                                                                                           
      end
                                                                                                                                                                                                                                                     
   end
                                                                                                                                                                                                                                                        
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
if @i_operacion = 'U'
                                                                                                                                                                                                                                         
begin
                                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
   if @i_seg_cred is null or  @i_tipo_car is null
                                                                                                                                                                                                             
   begin
                                                                                                                                                                                                                                                      
      select @w_error = 708150
                                                                                                                                                                                                                                
      goto ERROR
                                                                                                                                                                                                                                              
   end
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
   if exists (select 1 from cob_cartera..ca_segcred_tipocca
                                                                                                                                                                                                   
              where  st_seg_cred = @i_seg_cred 
                                                                                                                                                                                                               
              and    st_tipo_cca = @i_tipo_car)
                                                                                                                                                                                                               
   begin
                                                                                                                                                                                                                                                      
      update ca_segcred_tipocca
                                                                                                                                                                                                                               
      set    st_valor_minimo = @i_val_min,
                                                                                                                                                                                                                    
             st_valor_maximo = @i_val_max,
                                                                                                                                                                                                                    
             st_programa     = @i_programa,
                                                                                                                                                                                                                   
             st_valor_maximo_sis_fin = @i_valor_maximo_sis_fin,
                                                                                                                                                                                               
             st_valor_max_m2 = @i_valor_max_m2,   --JZU Mejora Reporte de Tasas
                                                                                                                                                                               
             st_valor_max_viv= @i_valor_max_viv   --JZU Mejora Reporte de Tasas
                                                                                                                                                                               
      where  st_seg_cred = @i_seg_cred 
                                                                                                                                                                                                                       
      and    st_tipo_cca = @i_tipo_car
                                                                                                                                                                                                                        
     
                                                                                                                                                                                                                                                         
      if @@error != 0
                                                                                                                                                                                                                                         
      begin
                                                                                                                                                                                                                                                   
        select @w_error = 708152
                                                                                                                                                                                                                              
        goto ERROR
                                                                                                                                                                                                                                            
      end
                                                                                                                                                                                                                                                     

                                                                                                                                                                                                                                                              
   end
                                                                                                                                                                                                                                                        
   else
                                                                                                                                                                                                                                                       
   begin
                                                                                                                                                                                                                                                      
      select @w_error = 708154
                                                                                                                                                                                                                                
      goto ERROR
                                                                                                                                                                                                                                              
   end
                                                                                                                                                                                                                                                        
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
if @i_operacion = 'D'
                                                                                                                                                                                                                                         
begin
                                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
   if exists (select 1 from cob_cartera..ca_segcred_tipocca
                                                                                                                                                                                                   
              where  st_seg_cred = @i_seg_cred 
                                                                                                                                                                                                               
              and    st_tipo_cca = @i_tipo_car)
                                                                                                                                                                                                               
   begin
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
      delete cob_cartera..ca_segcred_tipocca
                                                                                                                                                                                                                  
      where  st_seg_cred = @i_seg_cred 
                                                                                                                                                                                                                       
      and    st_tipo_cca = @i_tipo_car
                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
      if @@error != 0 begin
                                                                                                                                                                                                                                   
         select @w_error = 708155
                                                                                                                                                                                                                             
         goto ERROR
                                                                                                                                                                                                                                           
      end
                                                                                                                                                                                                                                                     
   end
                                                                                                                                                                                                                                                        
   else begin
                                                                                                                                                                                                                                                 
      select @w_error = 708150
                                                                                                                                                                                                                                
      goto ERROR
                                                                                                                                                                                                                                              
   end
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
-- BUSQUEDA DE REGisTRO 
                                                                                                                                                                                                                                      
if @i_operacion = 'S' 
                                                                                                                                                                                                                                        
begin
                                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
   if @i_modo = 0 
                                                                                                                                                                                                                                            
   begin
                                                                                                                                                                                                                                                      
      /*CONSULTA DATOS SOLO DEL PARAMETRO INGRESADO*/   
                                                                                                                                                                                                      
      set rowcount 20
                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
      select 'Tipo Cartera'    = st_tipo_cca,
                                                                                                                                                                                                                 
             'Des.Cartera' = (select valor
                                                                                                                                                                                                                    
                          from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                                                                                                                                                      
                          where  t.tabla  = 'ca_tipo_cartera'
                                                                                                                                                                                                 
                          and    y.tabla  = t.codigo
                                                                                                                                                                                                          
                          and    y.codigo = a.st_tipo_cca),
                                                                                                                                                                                                   
             'Seg.Credito'= st_seg_cred,
                                                                                                                                                                                                                      
             'Des.Segmento' = (select valor
                                                                                                                                                                                                                   
                          from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                                                                                                                                                      
                          where  t.tabla  = 'ca_segmento_credito'
                                                                                                                                                                                             
                          and    y.tabla  = t.codigo
                                                                                                                                                                                                          
                          and    y.codigo = a.st_seg_cred),
                                                                                                                                                                                                   
             'Valor Minimo' = st_valor_minimo,
                                                                                                                                                                                                                
             'Valor Maximo' = st_valor_maximo,
                                                                                                                                                                                                                
             'Programa' = st_programa,
                                                                                                                                                                                                                        
             'Valor Maximo Sis Financiero' = st_valor_maximo_sis_fin,
                                                                                                                                                                                         
             'Valor Max m2'       = st_valor_max_m2,     --JZU Mejora Reporte de Tasas
                                                                                                                                                                        
             'Valor Max Vivienda' = st_valor_max_viv     --JZU Mejora Reporte de Tasas
                                                                                                                                                                        
      from   ca_segcred_tipocca a
                                                                                                                                                                                                                             
      where  (st_tipo_cca = @i_tipo_car or @i_tipo_car is null)
                                                                                                                                                                                               
      order by st_tipo_cca, st_seg_cred
                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
      select 20
                                                                                                                                                                                                                                               
   end
                                                                                                                                                                                                                                                        
   else 
                                                                                                                                                                                                                                                      
   begin
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
      select @i_seg_cred = isnull(@i_seg_cred,'')
                                                                                                                                                                                                             
      select @i_tipo_car = isnull(@i_tipo_car,'')
                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              
      set rowcount 20
                                                                                                                                                                                                                                         
      select 'Tipo Cartera' = st_tipo_cca,
                                                                                                                                                                                                                    
             'Des.Cartera'  = (select valor
                                                                                                                                                                                                                   
                          from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                                                                                                                                                      
                          where  t.tabla  = 'ca_tipo_cartera'
                                                                                                                                                                                                 
                          and    y.tabla  = t.codigo
                                                                                                                                                                                                          
                          and    y.codigo = a.st_tipo_cca),
                                                                                                                                                                                                   
             'Seg.Credito'  =  st_seg_cred,
                                                                                                                                                                                                                   
             'Des.Segmento' = (select valor
                                                                                                                                                                                                                   
                          from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                                                                                                                                                      
                          where  t.tabla  = 'ca_segmento_credito'
                                                                                                                                                                                             
                          and    y.tabla  = t.codigo
                                                                                                                                                                                                          
                          and    y.codigo = a.st_seg_cred),
                                                                                                                                                                                                   
             'Valor Minimo' = st_valor_minimo,
                                                                                                                                                                                                                
         'Valor Maximo' = st_valor_maximo,
                                                                                                                                                                                                                    
         'Programa' = st_programa,
                                                                                                                                                                                                                            
             'Valor Maximo Sis Financiero' = st_valor_maximo_sis_fin,
                                                                                                                                                                                         
             'Valor Max m2'       = st_valor_max_m2,     --JZU Mejora Reporte de Tasas
                                                                                                                                                                        
             'Valor Max Vivienda' = st_valor_max_viv     --JZU Mejora Reporte de Tasas
                                                                                                                                                                        
      from   ca_segcred_tipocca a
                                                                                                                                                                                                                             
      where  (st_tipo_cca > @i_tipo_car or
                                                                                                                                                                                                                    
              (st_tipo_cca = @i_tipo_car and st_seg_cred > @i_seg_cred))
                                                                                                                                                                                      
      order by st_tipo_cca, st_seg_cred
                                                                                                                                                                                                                       
      select 20
                                                                                                                                                                                                                                               
 
                                                                                                                                                                                                                                                             
   end 
                                                                                                                                                                                                                                                       
   set rowcount 0
                                                                                                                                                                                                                                             
end 
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
--  CONSULTA DE UN REGisTRO ESPECifICO 
                                                                                                                                                                                                                       
if @i_operacion = 'Q'
                                                                                                                                                                                                                                         
begin
                                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
   select @w_tipo_car    = st_tipo_cca,
                                                                                                                                                                                                                       
          @w_det_tipocar = (select valor
                                                                                                                                                                                                                      
                            from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                                                                                                                                                    
                            where  t.tabla  = 'ca_tipo_cartera'
                                                                                                                                                                                               
                            and    y.tabla  = t.codigo
                                                                                                                                                                                                        
                            and    y.codigo = a.st_tipo_cca),
                                                                                                                                                                                                 
          @w_seg_cred   = st_seg_cred,
                                                                                                                                                                                                                        
          @w_des_segcred = (select valor
                                                                                                                                                                                                                      
                          from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                                                                                                                                                      
                          where  t.tabla  = 'ca_segmento_credito'
                                                                                                                                                                                             
                          and    y.tabla  = t.codigo
                                                                                                                                                                                                          
                          and    y.codigo = a.st_seg_cred),
                                                                                                                                                                                                   
          @w_val_min  = st_valor_minimo,
                                                                                                                                                                                                                      
          @w_val_max  = st_valor_maximo,
                                                                                                                                                                                                                      
          @w_programa = st_programa,
                                                                                                                                                                                                                          
          @w_valor_maximo_sis_fin = st_valor_maximo_sis_fin,
                                                                                                                                                                                                  
          @w_valor_max_m2    = st_valor_max_m2,     --JZU Mejora Reporte de Tasas
                                                                                                                                                                             
          @w_valor_max_viv   = st_valor_max_viv     --JZU Mejora Reporte de Tasas
                                                                                                                                                                             
   from   ca_segcred_tipocca a
                                                                                                                                                                                                                                
   where  st_tipo_cca = @i_tipo_car
                                                                                                                                                                                                                           
   and    st_seg_cred = @i_seg_cred
                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
   select @w_tipo_car,
                                                                                                                                                                                                                                        
          @w_det_tipocar,
                                                                                                                                                                                                                                     
          @w_seg_cred,
                                                                                                                                                                                                                                        
          @w_des_segcred,
                                                                                                                                                                                                                                     
          @w_val_min,
                                                                                                                                                                                                                                         
          @w_val_max,
                                                                                                                                                                                                                                         
          @w_programa,
                                                                                                                                                                                                                                        
          @w_valor_maximo_sis_fin,
                                                                                                                                                                                                                            
          @w_valor_max_m2,          --JZU Mejora Reporte de Tasas
                                                                                                                                                                                             
          @w_valor_max_viv          --JZU Mejora Reporte de Tasas
                                                                                                                                                                                             
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
-- AYUDA (F5)
                                                                                                                                                                                                                                                 
if @i_operacion = 'H' 
                                                                                                                                                                                                                                        
begin
                                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
  if exists (select 1 from ca_segcred_tipocca
                                                                                                                                                                                                                 
             where  st_tipo_cca = @i_tipo_car)
                                                                                                                                                                                                                
  begin
                                                                                                                                                                                                                                                       
     select 'Seg.Credito' = st_seg_cred,
                                                                                                                                                                                                                      
            'Des.Segmento'= (select valor
                                                                                                                                                                                                                     
                                from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                                                                                                                                                
                                where  t.tabla  = 'ca_segmento_credito'
                                                                                                                                                                                       
                                and    y.tabla  = t.codigo
                                                                                                                                                                                                    
                                and    y.codigo = a.st_seg_cred)
                                                                                                                                                                                              
     from   ca_segcred_tipocca a
                                                                                                                                                                                                                              
     where  st_tipo_cca = @i_tipo_car
                                                                                                                                                                                                                         
  end
                                                                                                                                                                                                                                                         
  else 
                                                                                                                                                                                                                                                       
     select 'Seg.Credito'   = b.codigo,
                                                                                                                                                                                                                       
            'Des.Segmento'    = b.valor
                                                                                                                                                                                                                       
     from   cobis..cl_tabla a, 
                                                                                                                                                                                                                               
            cobis..cl_catalogo b
                                                                                                                                                                                                                              
     where  a.tabla = 'ca_segmento_credito'
                                                                                                                                                                                                                   
     and    b.tabla = a.codigo
                                                                                                                                                                                                                                
end 
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
-- VALORES (F5)
                                                                                                                                                                                                                                               
if @i_operacion = 'V' 
                                                                                                                                                                                                                                        
begin
                                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
   if exists (select 1 from ca_segcred_tipocca
                                                                                                                                                                                                                
              where st_tipo_cca = @i_tipo_car)
                                                                                                                                                                                                                
   begin
                                                                                                                                                                                                                                                      
      select 'Des.Segmento'  = (select valor
                                                                                                                                                                                                                  
                                 from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                                                                                                                                               
                                 where  t.tabla  = 'ca_segmento_credito'
                                                                                                                                                                                      
                                 and    y.tabla  = t.codigo
                                                                                                                                                                                                   
                                 and    y.codigo = a.st_seg_cred)
                                                                                                                                                                                             
      from   ca_segcred_tipocca a
                                                                                                                                                                                                                             
      where  st_tipo_cca = @i_tipo_car
                                                                                                                                                                                                                        
      and    st_seg_cred = @i_seg_cred
                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
      if @@rowcount = 0 begin
                                                                                                                                                                                                                                 
         select @w_error = 708153
                                                                                                                                                                                                                             
         goto ERROR
                                                                                                                                                                                                                                           
      end
                                                                                                                                                                                                                                                     
   end
                                                                                                                                                                                                                                                        
   else 
                                                                                                                                                                                                                                                      
   begin
                                                                                                                                                                                                                                                      
     select  'Des.Segmento'    = b.valor
                                                                                                                                                                                                                      
     from   cobis..cl_tabla a, 
                                                                                                                                                                                                                               
            cobis..cl_catalogo b
                                                                                                                                                                                                                              
     where  a.tabla  =  'ca_segmento_credito'
                                                                                                                                                                                                                 
     and    b.tabla  = a.codigo
                                                                                                                                                                                                                               
     and    b.codigo = @i_seg_cred
                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
      if @@rowcount = 0 begin
                                                                                                                                                                                                                                 
         select @w_error = 708153
                                                                                                                                                                                                                             
         goto ERROR
                                                                                                                                                                                                                                           
      end
                                                                                                                                                                                                                                                     
   end
                                                                                                                                                                                                                                                        
end 
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
ERROR:
                                                                                                                                                                                                                                                        
exec cobis..sp_cerror
                                                                                                                                                                                                                                         
     @t_debug = 'N',
                                                                                                                                                                                                                                          
     @t_file  = null,
                                                                                                                                                                                                                                         
     @t_from  = @w_sp_name,
                                                                                                                                                                                                                                   
     @i_num   = @w_error
                                                                                                                                                                                                                                      
return @w_error
                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                    

go