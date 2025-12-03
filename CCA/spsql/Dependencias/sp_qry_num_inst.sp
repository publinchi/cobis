use cob_sbancarios
go 

drop proc sp_qry_num_inst

go
                                                                                                                                                                                                                                           
create proc sp_qry_num_inst(
                                                                                                                                                                                                                                  
   @i_sec        int     = null,
                                                                                                                                                                                                                              
   @i_interfaz   char(1) = 'N',
                                                                                                                                                                                                                               
   @o_numero     int     = null out
                                                                                                                                                                                                                           
)
                                                                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              
as
                                                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
declare 
                                                                                                                                                                                                                                                      
@w_sp_name        varchar(20),
                                                                                                                                                                                                                                
@w_secuencial     int, 
                                                                                                                                                                                                                                       
@w_instrumento    smallint,
                                                                                                                                                                                                                                   
@w_subtipo        int,  
                                                                                                                                                                                                                                      
@w_serie_ini      varchar(20), 
                                                                                                                                                                                                                               
@w_serie_ini_rep  varchar(20), 
                                                                                                                                                                                                                               
@w_serie_org      int, 
                                                                                                                                                                                                                                       
@w_return         int
                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
select @w_sp_name = 'sp_qry_num_inst'
                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
if @i_sec is null
                                                                                                                                                                                                                                             
begin
                                                                                                                                                                                                                                                         
   --NO SE PUDO OBTENER EL SECUENCIAL DE LA OPERACION
                                                                                                                                                                                                         
   select @w_return = 2902990
                                                                                                                                                                                                                                 
   goto ERROR
                                                                                                                                                                                                                                                 
end
                                                                                                                                                                                                                                                           
 
                                                                                                                                                                                                                                                             
select 
                                                                                                                                                                                                                                                       
@w_secuencial  = isnull(il_sec_origen,il_secuencial), 
                                                                                                                                                                                                        
@w_instrumento = il_instrumento, 
                                                                                                                                                                                                                             
@w_subtipo     = il_subtipo, 
                                                                                                                                                                                                                                 
@w_serie_ini   = SUBSTRING(convert(varchar(20),il_serie_numerica),1,(charindex('.',(convert (varchar(20),il_serie_numerica))))-1)
                                                                                                                             
from   sb_impresion_lotes
                                                                                                                                                                                                                                     
where  il_secuencial = @i_sec
                                                                                                                                                                                                                                 

                                                                                                                                                                                                                                                              
if @w_secuencial is null
                                                                                                                                                                                                                                      
begin
                                                                                                                                                                                                                                                         
   --NO SE ENCUENTRAN REGISTROS CON LOS PARAMETROS ESPECIFICADOS
                                                                                                                                                                                              
   select @w_return = 2902502
                                                                                                                                                                                                                                 
   goto ERROR
                                                                                                                                                                                                                                                 
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
select 
                                                                                                                                                                                                                                                       
@w_serie_ini_rep = SUBSTRING(convert (varchar(20),sn_serie_desde),1,(charindex('.',(convert (varchar(20),sn_serie_desde))))-1), 
                                                                                                                              
@w_serie_org     = pn_num_cheque
                                                                                                                                                                                                                              
from   sb_productos_neg , sb_series_neg   
                                                                                                                                                                                                                    
where  pn_cod_operacion = sn_cod_operacion
                                                                                                                                                                                                                    
and    (pn_sec_producto +1) = sn_sec_producto
                                                                                                                                                                                                                 
and   pn_producto = 14 
                                                                                                                                                                                                                                       
and   pn_pais_origen      = @w_secuencial
                                                                                                                                                                                                                     
and   pn_instrumento      = @w_instrumento
                                                                                                                                                                                                                    
and   pn_sub_tipo         = @w_subtipo
                                                                                                                                                                                                                        
and   sn_estado           <> 'A'      
                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
if @w_serie_ini_rep is null
                                                                                                                                                                                                                                   
   select @o_numero  = convert(int,@w_serie_ini)
                                                                                                                                                                                                              
else
                                                                                                                                                                                                                                                          
   select @o_numero  = convert(int,@w_serie_ini_rep)
                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
ERROR:
                                                                                                                                                                                                                                                        
   if @i_interfaz = 'N'
                                                                                                                                                                                                                                       
   begin
                                                                                                                                                                                                                                                      
      exec cobis..sp_cerror
                                                                                                                                                                                                                                   
      @t_from = @w_sp_name,
                                                                                                                                                                                                                                   
      @i_num  = @w_return
                                                                                                                                                                                                                                     
   end
                                                                                                                                                                                                                                                        
   return @w_return
                                                                                                                                                                                                                                           
go

