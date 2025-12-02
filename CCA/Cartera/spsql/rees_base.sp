
/************************************************************************/
/*      Archivo:                rees_base.sp                            */
/*      Stored procedure:       sp_rees_base                            */
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

if exists (select 1 from sysobjects where name = 'sp_rees_base')
   drop proc sp_rees_base
go

create proc sp_rees_base
                                                                                                                                                                                                                                      
@s_user            varchar(30)     = null,
                                                                                                                                                                                                                    
@s_sesn         int             = null,
                                                                                                                                                                                                                       
@s_term            varchar(30)     = null,
                                                                                                                                                                                                                    
@s_date            datetime        = null,
                                                                                                                                                                                                                    
@i_cadena       varchar(250)    = null,
                                                                                                                                                                                                                       
@i_tmonto       char(1)         = 'N',
                                                                                                                                                                                                                        
@i_tramite        INT                = null
                                                                                                                                                                                                                   
    
                                                                                                                                                                                                                                                          
as 
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
/* Declaraciones de variables de operacion */
                                                                                                                                                                                                                 
declare @w_sp_name        varchar(30),
                                                                                                                                                                                                                        
    @w_msg                varchar(50),
                                                                                                                                                                                                                        
    @w_error            int,
                                                                                                                                                                                                                                  
    @w_base             char(1),
                                                                                                                                                                                                                              
    @w_posicion         int,
                                                                                                                                                                                                                                  
    @w_banco            cuenta,
                                                                                                                                                                                                                               
    @w_cadena           varchar(250),
                                                                                                                                                                                                                         
    @w_fecha            datetime,
                                                                                                                                                                                                                             
    @w_fecha_op         datetime,
                                                                                                                                                                                                                             
    @w_num_op           int,
                                                                                                                                                                                                                                  
    @w_banco_rees       cuenta,
                                                                                                                                                                                                                               
    @w_band             char,
                                                                                                                                                                                                                                 
    @w_saldo_op         money,         -- saldo por operacion
                                                                                                                                                                                                 
    @w_saldo_mayor      money         -- saldo de operacion a reestructurar
                                                                                                                                                                                   
    
                                                                                                                                                                                                                                                          
/*-- setear variables de operacion */
                                                                                                                                                                                                                         
select @w_sp_name = 'sp_rees_base'
                                                                                                                                                                                                                            
select @w_fecha = fp_fecha from cobis..ba_fecha_proceso
                                                                                                                                                                                                       
select @w_cadena = @i_cadena, @w_saldo_mayor = 0
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
/*-- VALIDAR LOS PARAMETROS */
                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
/*-- Valido existencia de dato en el catalogo*/
                                                                                                                                                                                                               
if not exists(select 1 from cobis..cl_tabla a, cobis..cl_catalogo b
                                                                                                                                                                                           
               where a.tabla = 'cr_monto_rees'
                                                                                                                                                                                                                
                 and a.codigo = b.tabla
                                                                                                                                                                                                                       
                 and b.codigo = @i_tmonto)
                                                                                                                                                                                                                    
begin
                                                                                                                                                                                                                                                         
      exec cobis..sp_cerror
                                                                                                                                                                                                                                   
        @t_debug = 'N',
                                                                                                                                                                                                                                       
        @t_file  = ' ', 
                                                                                                                                                                                                                                      
        @t_from  = @w_sp_name,
                                                                                                                                                                                                                                
        @i_num   = 101000
                                                                                                                                                                                                                                     
      return 101000
                                                                                                                                                                                                                                           
end
                                                                                                                                                                                                                                                           
select @w_base =  pa_char 
                                                                                                                                                                                                                                    
  from cobis..cl_parametro
                                                                                                                                                                                                                                    
 where pa_nemonico = 'PRIRES'
                                                                                                                                                                                                                                 
   and pa_producto = 'CRE'
                                                                                                                                                                                                                                    
   
                                                                                                                                                                                                                                                           
/*-- IDENTIFICA OPERACIONES A REESTRUCTURAR*/
                                                                                                                                                                                                                 
select @w_posicion = charindex (',', @i_cadena), @w_band = 'S'
                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
if @w_posicion <= 0 and  @i_cadena is not null
                                                                                                                                                                                                                
   select @w_banco_rees = @i_cadena, @w_band = 'N'
                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
-- 
                                                                                                                                                                                                                                                           
if @i_tramite IS not null AND @i_tramite != 0
                                                                                                                                                                                                                 
begin
                                                                                                                                                                                                                                                         
    if not exists (select 1 FROM cob_credito..cr_op_renovar WHERE or_tramite = @i_tramite AND or_base = 'S')
                                                                                                                                                  
    begin
                                                                                                                                                                                                                                                     
        exec cobis..sp_cerror
                                                                                                                                                                                                                                 
            @t_debug = 'N',
                                                                                                                                                                                                                                   
            @t_file  = ' ', 
                                                                                                                                                                                                                                  
            @t_from  = @w_sp_name,
                                                                                                                                                                                                                            
            @i_num   = 101001
                                                                                                                                                                                                                                 
          return 101001
                                                                                                                                                                                                                                       
    end
                                                                                                                                                                                                                                                       
    select @w_banco_rees = or_num_operacion FROM cob_credito..cr_op_renovar WHERE or_tramite = @i_tramite AND or_base = 'S'
                                                                                                                                   
    -- Retornamos operacion base almacenada en la base de datos
                                                                                                                                                                                               
    select 'op_base' = @w_banco_rees
                                                                                                                                                                                                                          
    RETURN 0
                                                                                                                                                                                                                                                  
end
                                                                                                                                                                                                                                                           
ELSE
                                                                                                                                                                                                                                                          
begin
                                                                                                                                                                                                                                                         
    while @w_band = 'S'
                                                                                                                                                                                                                                       
    begin
                                                                                                                                                                                                                                                     
       if @w_posicion = 0 -- PARA INGRESAR LA ULTIMA OCASION
                                                                                                                                                                                                  
          select @w_banco = ltrim(rtrim(@w_cadena))
                                                                                                                                                                                                           
       else
                                                                                                                                                                                                                                                   
          select @w_banco = substring(@w_cadena, 1, @w_posicion - 1)
                                                                                                                                                                                          
          
                                                                                                                                                                                                                                                    
       select @w_cadena = substring(@w_cadena, @w_posicion + 1, len(@w_cadena))
                                                                                                                                                                               
       
                                                                                                                                                                                                                                                       
       select @w_fecha_op = op_fecha_ini, @w_num_op = op_operacion 
                                                                                                                                                                                           
         from cob_cartera..ca_operacion 
                                                                                                                                                                                                                      
        where op_banco = @w_banco
                                                                                                                                                                                                                             
    
                                                                                                                                                                                                                                                          
       if @w_base = 'F' -- OPERACION BASE POR FECHA
                                                                                                                                                                                                           
          if @w_fecha > @w_fecha_op 
                                                                                                                                                                                                                          
             select @w_fecha = @w_fecha_op, @w_banco_rees = @w_banco  -- TOMA FECHA MAS ANTIGUA
                                                                                                                                                               
       if @w_base = 'M' -- OPERACION BASE POR MONTO
                                                                                                                                                                                                           
       begin
                                                                                                                                                                                                                                                  
          /*-- VALIDACION DEL MONTO*/
                                                                                                                                                                                                                         
          if @i_tmonto = 'N'
                                                                                                                                                                                                                                  
          begin
                                                                                                                                                                                                                                               
              select @w_saldo_op = 0
                                                                                                                                                                                                                          
              
                                                                                                                                                                                                                                                
              select @w_saldo_op = sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)) 
                                                                                                                                                   
              from cob_cartera..ca_amortizacion
                                                                                                                                                                                                               
              where am_operacion = @w_num_op and am_concepto = 'CAP'
                                                                                                                                                                                          
              
                                                                                                                                                                                                                                                
              /*
                                                                                                                                                                                                                                              
              select @w_saldo_op = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0))
                                                                                                                             
                from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
                                                                                                                                                                                 
               where  ro_operacion = @w_num_op
                                                                                                                                                                                                                
                 and  ro_tipo_rubro in ('C')  -- tipo de rubro capital
                                                                                                                                                                                        
                 and  am_operacion = ro_operacion
                                                                                                                                                                                                             
                 and  am_concepto  = ro_concepto
                                                                                                                                                                                                              
              */ -- DFL Cod: Anterior 
                                                                                                                                                                                                                        
          end
                                                                                                                                                                                                                                                 
          if @i_tmonto = 'S'
                                                                                                                                                                                                                                  
          begin
                                                                                                                                                                                                                                               
          
                                                                                                                                                                                                                                                    
                select @w_saldo_op = sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)) 
                                                                                                                                                 
              from cob_cartera..ca_amortizacion
                                                                                                                                                                                                               
              where am_operacion = @w_num_op and am_concepto IN ('CAP','INT')
                                                                                                                                                                                 
              
                                                                                                                                                                                                                                                
                /*
                                                                                                                                                                                                                                            
              select @w_saldo_op = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0))
                                                                                                                             
                from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
                                                                                                                                                                                 
               where  ro_operacion = @w_num_op
                                                                                                                                                                                                                
                 and  ro_tipo_rubro in ('C', 'I')    -- tipo de rubro capital + interes
                                                                                                                                                                       
                 and  am_operacion = ro_operacion
                                                                                                                                                                                                             
                 and  am_concepto  = ro_concepto
                                                                                                                                                                                                              
              */ -- DFL Cod: Anterior  
                                                                                                                                                                                                                       
          end
                                                                                                                                                                                                                                                 
          if @i_tmonto = 'T'
                                                                                                                                                                                                                                  
          begin
                                                                                                                                                                                                                                               
          
                                                                                                                                                                                                                                                    
                select @w_saldo_op = sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)) 
                                                                                                                                                 
              from cob_cartera..ca_amortizacion
                                                                                                                                                                                                               
              where am_operacion = @w_num_op
                                                                                                                                                                                                                  
                /*
                                                                                                                                                                                                                                            
              select @w_saldo_op = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0))
                                                                                                                             
                from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
                                                                                                                                                                                 
               where  ro_operacion = @w_num_op
                                                                                                                                                                                                                
                 and  am_operacion = ro_operacion
                                                                                                                                                                                                             
                 and  am_concepto  = ro_concepto
                                                                                                                                                                                                              
              */ -- DFL Cod: Anterior   
                                                                                                                                                                                                                      
          end
                                                                                                                                                                                                                                                 
          
                                                                                                                                                                                                                                                    
          if @w_saldo_op > @w_saldo_mayor
                                                                                                                                                                                                                     
             select @w_saldo_mayor = @w_saldo_op, @w_banco_rees = @w_banco
                                                                                                                                                                                    
       end
                                                                                                                                                                                                                                                    
       
                                                                                                                                                                                                                                                       
       select @w_posicion = charindex (',', @w_cadena) 
                                                                                                                                                                                                       
       if @w_posicion = 0 and @w_banco = @w_cadena
                                                                                                                                                                                                            
          select @w_band = 'N'
                                                                                                                                                                                                                                
    end
                                                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
    if @w_base = 'M' or @w_base = 'F'
                                                                                                                                                                                                                         
    select 'op_base' = @w_banco_rees
                                                                                                                                                                                                                          
    else
                                                                                                                                                                                                                                                      
    select 'op_base' = ''
                                                                                                                                                                                                                                     
    
                                                                                                                                                                                                                                                          
    return 0  
                                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
end                                 
                                                                                                                                                                                                                          

go