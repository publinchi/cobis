
/************************************************************************/
/*      Archivo:                qamortmp_sim.sp                        */
/*      Stored procedure:       sp_qamortmp_sim                        */
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

if exists (select 1 from sysobjects where name = 'sp_qamortmp_sim')
   drop proc sp_qamortmp_sim
go

create proc sp_qamortmp_sim
                                                                                                                                                                                                                                   
    @i_banco                cuenta,
                                                                                                                                                                                                                           
    @i_dividendo            smallint,
                                                                                                                                                                                                                         
    @i_formato_fecha        int  = null,
                                                                                                                                                                                                                      
    @i_concepto             catalogo = '',
                                                                                                                                                                                                                    
    @i_opcion               tinyint  = null,
                                                                                                                                                                                                                  
    @i_tipo_rubro           char(1)  = null
                                                                                                                                                                                                                   
as
                                                                                                                                                                                                                                                            
declare @w_error                 int, 
                                                                                                                                                                                                                        
        @w_return                 int, 
                                                                                                                                                                                                                       
        @w_operacionca             int, 
                                                                                                                                                                                                                      
        @w_sp_name                descripcion, 
                                                                                                                                                                                                               
        @w_count                 int, 
                                                                                                                                                                                                                        
        @w_filas                 int, 
                                                                                                                                                                                                                        
        @w_tipo_amortizacion     catalogo, 
                                                                                                                                                                                                                   
        @w_filas_rubros         int, 
                                                                                                                                                                                                                         
        @w_est_vigente            tinyint, 
                                                                                                                                                                                                                   
        @w_primer_des             int
                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
/* VARIABLES INICIALES */
                                                                                                                                                                                                                                     
select @w_sp_name = 'sp_qamortmp_sim'
                                                                                                                                                                                                                         
select @w_est_vigente = 1
                                                                                                                                                                                                                                     
/* DATOS GENERALES DEL PRESTAMO */
                                                                                                                                                                                                                            
select @w_operacionca = opt_operacion, @w_tipo_amortizacion = opt_tipo_amortizacion from   ca_operacion_tmp where  opt_banco = @i_banco 
                                                                                                                      
----print '@i_tipo_rubro %1! @w_operacionca %2!', @i_tipo_rubro, @w_operacionca
                                                                                                                                                                               
   /* RUBROS QUE PARTICIPAN EN LA TABLA */
                                                                                                                                                                                                                    
   select b.rot_concepto, co_descripcion, b.rot_tipo_rubro, b.rot_porcentaje 
                                                                                                                                                                                 
     from ca_rubro_op_tmp a, ca_rubro_op_tmp b, ca_concepto
                                                                                                                                                                                                   
    where a.rot_operacion = @w_operacionca
                                                                                                                                                                                                                    
      and a.rot_fpago in ('P','A','T')
                                                                                                                                                                                                                        
      and a.rot_tipo_rubro != @i_tipo_rubro 
                                                                                                                                                                                                                  
      and b.rot_operacion = @w_operacionca
                                                                                                                                                                                                                    
      and b.rot_concepto_asociado = a.rot_concepto
                                                                                                                                                                                                            
      and b.rot_concepto  = co_concepto
                                                                                                                                                                                                                       
   UNION                                --   INICIO LRO CA0009 RUBROS ASOCIADOS 
                                                                                                                                                                              
   select rot_concepto, co_descripcion, rot_tipo_rubro,rot_porcentaje
                                                                                                                                                                                         
     from ca_rubro_op_tmp, ca_concepto
                                                                                                                                                                                                                        
    where rot_operacion  = @w_operacionca
                                                                                                                                                                                                                     
      and rot_concepto   = co_concepto
                                                                                                                                                                                                                        
      and rot_tipo_rubro != @i_tipo_rubro 
                                                                                                                                                                                                                    
      and rot_fpago in ('P','A','T')                    --   FIN LRO CA0009 RUBROS ASOCIADOS 
                                                                                                                                                                 
    order by rot_tipo_rubro,rot_concepto
                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
    /*if @i_opcion = 0 begin
                                                                                                                                                                                                                                  
   if @i_dividendo = 0
                                                                                                                                                                                                                                        
      select @w_count = (3000 - (@w_filas_rubros * 93) - 4) / 30
                                                                                                                                                                                              
   else select @w_count  = 3000 / 10
                                                                                                                                                                                                                          
   set rowcount @w_count
                                                                                                                                                                                                                                      
   FECHAS DE VENCIMIENTOS DE DIVIDENDOS */
                                                                                                                                                                                                                    
   select dit_fecha_ven
                                                                                                                                                                                                                                       
   from ca_dividendo_tmp
                                                                                                                                                                                                                                      
   where dit_operacion = @w_operacionca
                                                                                                                                                                                                                       
   and   dit_dividendo > @i_dividendo 
                                                                                                                                                                                                                        
   order by dit_dividendo
                                                                                                                                                                                                                                     
/*end
                                                                                                                                                                                                                                                         
else select @w_filas = 0,
                                                                                                                                                                                                                                     
            @w_count = 1
                                                                                                                                                                                                                                      
if @w_filas < @w_count
                                                                                                                                                                                                                                        
begin
                                                                                                                                                                                                                                                         
   select @w_count = (3000 - (@w_filas * 10) - 4) / 30TAMANIO EN BYTES PARA MAPEAR EL BUFFER
                                                                                                                                                                  
   if @i_dividendo > 0 and @i_opcion = 0
                                                                                                                                                                                                                      
      select @i_dividendo = 0
                                                                                                                                                                                                                                 
   
                                                                                                                                                                                                                                                           
   set rowcount 0
                                                                                                                                                                                                                                             
 */
                                                                                                                                                                                                                                                           
select dit_dividendo,                             --   INICIO LRO CA0009 RUBROS ASOCIADOS 
                                                                                                                                                                    
          b.rot_concepto, 
                                                                                                                                                                                                                                    
          ISNULL(sum(amt_cuota+amt_gracia),0),
                                                                                                                                                                                                                
          b.rot_tipo_rubro
                                                                                                                                                                                                                                    
     from ca_amortizacion_tmp, ca_rubro_op_tmp a, ca_dividendo_tmp,
                                                                                                                                                                                           
      ca_rubro_op_tmp b
                                                                                                                                                                                                                                       
    where amt_operacion   = @w_operacionca
                                                                                                                                                                                                                    
      and a.rot_operacion = @w_operacionca
                                                                                                                                                                                                                    
      and a.rot_tipo_rubro  != @i_tipo_rubro 
                                                                                                                                                                                                                 
      and dit_operacion   = @w_operacionca
                                                                                                                                                                                                                    
      and (dit_dividendo  > @i_dividendo or dit_dividendo = @i_dividendo) 
                                                                                                                                                                                    
      and b.rot_concepto = amt_concepto
                                                                                                                                                                                                                       
      and a.rot_fpago    in ('P','A','T')
                                                                                                                                                                                                                     
      and dit_dividendo  = amt_dividendo
                                                                                                                                                                                                                      
      and b.rot_operacion = @w_operacionca
                                                                                                                                                                                                                    
      and b.rot_concepto_asociado = a.rot_concepto
                                                                                                                                                                                                            
    group by dit_dividendo,b.rot_tipo_rubro,b.rot_concepto
                                                                                                                                                                                                    
   UNION                                --   FIN LRO CA0009 RUBROS ASOCIADOS 
                                                                                                                                                                                 
   select dit_dividendo,
                                                                                                                                                                                                                                      
          rot_concepto,
                                                                                                                                                                                                                                       
          ISNULL(sum(amt_cuota+amt_gracia),0),
                                                                                                                                                                                                                
          rot_tipo_rubro
                                                                                                                                                                                                                                      
     from ca_amortizacion_tmp, ca_rubro_op_tmp, ca_dividendo_tmp
                                                                                                                                                                                              
    where amt_operacion   =  @w_operacionca
                                                                                                                                                                                                                   
      and rot_operacion   =  @w_operacionca
                                                                                                                                                                                                                   
      and rot_concepto    =  amt_concepto
                                                                                                                                                                                                                     
      and rot_tipo_rubro  != @i_tipo_rubro 
                                                                                                                                                                                                                   
      and dit_operacion   =  @w_operacionca
                                                                                                                                                                                                                   
      and dit_dividendo   =  amt_dividendo
                                                                                                                                                                                                                    
      and amt_operacion   = rot_operacion
                                                                                                                                                                                                                     
      and rot_operacion   = dit_operacion
                                                                                                                                                                                                                     
      and rot_fpago in ('P','A','T')
                                                                                                                                                                                                                          
      and (dit_dividendo >  @i_dividendo or dit_dividendo =  @i_dividendo) 
                                                                                                                                                                                   
    group by dit_dividendo, rot_tipo_rubro, rot_concepto 
                                                                                                                                                                                                     
    order by dit_dividendo, rot_tipo_rubro, rot_concepto 
                                                                                                                                                                                                     

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      
ERROR:
                                                                                                                                                                                                                                                        
exec cobis..sp_cerror
                                                                                                                                                                                                                                         
@t_debug='N',         @t_file = null,
                                                                                                                                                                                                                         
@t_from =@w_sp_name,   @i_num = @w_error
                                                                                                                                                                                                                      
return @w_error
                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
go 

