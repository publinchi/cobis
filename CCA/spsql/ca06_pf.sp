/************************************************************************/  
/*    Archivo:                ca06_pf.sp                                */  
/*    Stored procedure:       sp_ca06_pf                                */  
/*    Base de datos:          cob_cartera                               */  
/*    Producto:               Cartera                                   */  
/************************************************************************/  
/*                             IMPORTANTE                               */  
/*    Este programa es parte de los paquetes bancarios propiedad de     */  
/*    'COBISCORP'.                                                      */  
/*    Su uso no autorizado  queda  expresamente  prohibido asi como     */  
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus     */  
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la     */  
/*    Presidencia Ejecutiva de COBISCORP o su representante.            */  
/************************************************************************/  
/*                              PROPOSITO                               */  
/*    Despliega para las pantallas de perfiles contables en el modulo   */  
/*    de Contabilidad COBIS los valores que pueden tomar los criterios  */  
/*    contables de CTA BANCO                                            */  
/************************************************************************/  
/*                             MODIFICACION                             */  
/*    FECHA                 AUTOR                 RAZON                 */  
/************************************************************************/  
                                                                            
use cob_cartera                                                             
go                                                                          
                                                                            
if exists (select 1 from sysobjects where name = 'sp_ca06_pf')              
   drop proc sp_ca06_pf                                                     
go                                                                          
                                                                            
                                                                            
create proc sp_ca06_pf(                                                     
@i_criterio tinyint     = null,                                             
@i_codigo   varchar(30) = null)                                             
                                                                            
as                                                                          
                                                                            
declare                                                                     
@w_return         int,                                                      
@w_sp_name        varchar(32),                                              
@w_tabla          smallint,                                                 
@w_codigo         varchar(30),                                              
@w_criterio       tinyint,
@w_categoria      catalogo                                                   
                                                                            
select @w_sp_name = 'sp_ca06_pf'  

-- Categoria Archivos Planos
select @w_categoria = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'PLANO'                                                 
                                                                            
/* LA 1A VEZ ENVIA LAS ETIQUETAS QUE APARECERAN EN LOS CAMPOS DE LA FORMA */
if @i_criterio is null begin                                                
   select                                                                   
   'Cuenta Banco'                                                                 
end                                                                         
                                                                            
select @w_codigo   = isnull(@i_codigo, '')                                  
select @w_criterio = isnull(@i_criterio, 0)                                 
                                                                            
/* TABLA TEMPORAL PARA LLENAR LOS DATOS DE TODOS LOS DATOS DEL F5 AL CARGAR LA PANTALLA */
create table #ca_catalogo(                                                  
ca_tabla       tinyint,                                                     
ca_codigo      varchar(20),                                                 
ca_descripcion varchar(50))                                                 
                                                                            
/* Tipo Operacion */                                                                
if @w_criterio <= 1 begin                                                   
   if exists(select 1 from cobis..cl_producto where pd_abreviatura = 'REM')
   begin
   insert into #ca_catalogo
   select 1, pcc_cuenta, (select ba_descripcion from cob_remesas..re_banco where ba_banco = x.pcc_banco)
   from   cob_sbancarios..sb_ctas_comercl x
   where  pcc_secuencial > 0
   union
   select
   1, cp_producto, substring(cp_descripcion,1,30)
   from  ca_producto
   where cp_categoria = @w_categoria                                     
   end                                                                        
   if @@error <> 0 return 710001                                            
end                                                                         
                                                                            
                                                                            
                                                                            
/* RETORNA LOS DATOS AL FRONT-END */                                        
select ca_tabla, ca_codigo, ca_descripcion                                  
from   #ca_catalogo                                                         
where  ca_tabla   > @w_criterio                                             
or    (ca_tabla  = @w_criterio and ca_codigo > @w_codigo)                   
order by ca_tabla, ca_codigo                                                
                                                                            
return 0                                                                    
                                                                            
go                                                                          
                                                                            