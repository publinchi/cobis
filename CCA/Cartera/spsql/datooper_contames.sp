
use cob_conta_super
go
 
if exists (select 1 from sysobjects where name = 'sp_datos_operacion_mes')
   drop proc sp_datos_operacion_mes
go                                            
                                                                                                                                                                                                                  
create proc [dbo].[sp_datos_operacion_mes]
                                                                                                                                                                                                                    
(
                                                                                                                                                                                                                                                             
   @i_param1         smalldatetime,
                                                                                                                                                                                                                           
   @i_param2         varchar(2) 
                                                                                                                                                                                                                              
)
                                                                                                                                                                                                                                                             
as DECLARE
                                                                                                                                                                                                                                                    
   --variables de entrada
                                                                                                                                                                                                                                     
   @i_fecha_proceso  smalldatetime,
                                                                                                                                                                                                                           
   @i_toperacion     varchar(2) ,  
                                                                                                                                                                                                                           
   @w_error          varchar(255),
                                                                                                                                                                                                                            
   @w_sp_name        varchar(30),
                                                                                                                                                                                                                             
   @w_retorno        tinyint, 
                                                                                                                                                                                                                                
   @w_banco          int,
                                                                                                                                                                                                                                     
   @w_fuente         descripcion,
                                                                                                                                                                                                                             
   @w_fecha_proc     datetime,
                                                                                                                                                                                                                                
   @w_fecha_aux      datetime,
                                                                                                                                                                                                                                
   @w_return         int
                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
SELECT  
                                                                                                                                                                                                                                                      
@i_fecha_proceso  = @i_param1,
                                                                                                                                                                                                                                
@i_toperacion     = @i_param2,
                                                                                                                                                                                                                                
@w_retorno        = 0,
                                                                                                                                                                                                                                        
@w_sp_name        = 'sp_datos_operacion_mes'
                                                                                                                                                                                                                  

                                                                                                                                                                                                                                                              
create table #aplicativo(dc_aplicativo tinyint null,
                                                                                                                                                                                                          
                         dg_aplicativo tinyint null,
                                                                                                                                                                                                          
                         dt_aplicativo tinyint null)
                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
-- Limpia Log x sp
                                                                                                                                                                                                                                            
delete sb_errorlog
                                                                                                                                                                                                                                            
where er_fuente = @w_sp_name
                                                                                                                                                                                                                                  

                                                                                                                                                                                                                                                              
--codigo de ente asignado al Banco 
                                                                                                                                                                                                                           
select 
                                                                                                                                                                                                                                                       
@w_banco = en_ente 
                                                                                                                                                                                                                                           
from cobis..cl_ente 
                                                                                                                                                                                                                                          
where en_ced_ruc = '9002150711'
                                                                                                                                                                                                                               
and en_tipo_ced = 'N'
                                                                                                                                                                                                                                         

                                                                                                                                                                                                                                                              
if @@rowcount = 0 Begin
                                                                                                                                                                                                                                       
   exec cob_conta_super..sp_errorlog
                                                                                                                                                                                                                          
   @i_operacion     = 'I',
                                                                                                                                                                                                                                    
   @i_fecha_fin     = @i_fecha_proceso,
                                                                                                                                                                                                                       
   @i_fuente        = @w_sp_name,
                                                                                                                                                                                                                             
   @i_origen_error  = '28001',
                                                                                                                                                                                                                                
   @i_descrp_error  = 'NO EXISTE CODIGO DE ENTE ASIGNADO A LA ENTIDAD BANCARIA'
                                                                                                                                                                               
   Goto ERROR
                                                                                                                                                                                                                                                 
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
if @i_toperacion = 'HV' or @i_toperacion = 'TO'
                                                                                                                                                                                                               
Begin
                                                                                                                                                                                                                                                         
    /*** ELIMINA DATOS EN SB_DATO_HECHOS_VIOLENTOS***/
                                                                                                                                                                                                        
    delete cob_conta_super..sb_dato_hechos_violentos
                                                                                                                                                                                                          
    from cob_externos..ex_dato_hechos_violentos devx,
                                                                                                                                                                                                         
         cob_conta_super..sb_dato_hechos_violentos devs
                                                                                                                                                                                                       
    where devx.dh_fecha = @i_fecha_proceso
                                                                                                                                                                                                                    
    and devs.dh_fecha   = devx.dh_fecha
                                                                                                                                                                                                                       
    and devs.dh_tramite = devx.dh_tramite
                                                                                                                                                                                                                     
    
                                                                                                                                                                                                                                                          
    /*** INSERTA DATOS EN SB_DATO_HECHOS_VIOLENTOS ***/
                                                                                                                                                                                                       
    insert into cob_conta_super..sb_dato_hechos_violentos
                                                                                                                                                                                                     
       (dh_fecha,           dh_cliente,         dh_tramite,                     dh_fecha_radicacion,
                                                                                                                                                          
        dh_toperacion,      dh_rechazado,       dh_causa_rechazo,               dh_evento,
                                                                                                                                                                    
        dh_fecha_evento,    dh_ciudad_evento,   dh_municipio_evento,            dh_corregimiento_evento,
                                                                                                                                                      
        dh_inspeccion,      dh_vereda,          dh_sitio,                       dh_destino)
                                                                                                                                                                   
     select 
                                                                                                                                                                                                                                                  
        dh_fecha,           dh_cliente,         dh_tramite,                     dh_fecha_radicacion,
                                                                                                                                                          
        dh_toperacion,      dh_rechazado,       isnull(dh_causa_rechazo,''),    dh_evento,
                                                                                                                                                                    
        dh_fecha_evento,    dh_ciudad_evento,   dh_municipio_evento,            dh_corregimiento_evento,
                                                                                                                                                      
        dh_inspeccion,      dh_vereda,          dh_sitio,                       dh_destino
                                                                                                                                                                    
      from cob_externos..ex_dato_hechos_violentos
                                                                                                                                                                                                             
      where dh_fecha = @i_fecha_proceso
                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
    if @@error <> 0 Begin
                                                                                                                                                                                                                                     
       exec cob_conta_super..sp_errorlog
                                                                                                                                                                                                                      
       @i_operacion     = 'I',
                                                                                                                                                                                                                                
       @i_fecha_fin     = @i_fecha_proceso,
                                                                                                                                                                                                                   
       @i_fuente        = @w_sp_name,
                                                                                                                                                                                                                         
       @i_origen_error  = '28002',
                                                                                                                                                                                                                            
       @i_descrp_error  = 'ERROR INSERTANDO DATOS EN SB_DATO_HECHOS_VIOLENTOS'
                                                                                                                                                                                
    end
                                                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
    /*** ACTUALIZANDO CODIGO DE CLIENTE BANCAMIA PARA AQUELLOS QUE NO EXISTEN EN COBIS ***/
                                                                                                                                                                   
    update cob_conta_super..sb_dato_hechos_violentos Set
                                                                                                                                                                                                      
      dh_cliente = @w_banco
                                                                                                                                                                                                                                   
      where dh_cliente = 0
                                                                                                                                                                                                                                    
      and   dh_fecha   = @i_fecha_proceso   
                                                                                                                                                                                                                  

                                                                                                                                                                                                                                                              
    /*** INSERTANDO LOG DE ERRORES ***/
                                                                                                                                                                                                                       
    insert into sb_errorlog
                                                                                                                                                                                                                                   
      (er_fecha,            er_fecha_proc,      er_fuente,      er_origen_error,
                                                                                                                                                                              
       er_descrp_error) 
                                                                                                                                                                                                                                      
    select 
                                                                                                                                                                                                                                                   
       @i_fecha_proceso,    getdate(),          @w_sp_name,     (dh_tramite + dh_toperacion), 
                                                                                                                                                                
       'ERROR CLIENTE NO EXISTE'
                                                                                                                                                                                                                              
      from cob_externos..ex_dato_hechos_violentos 
                                                                                                                                                                                                            
      where dh_cliente = 0   
                                                                                                                                                                                                                                 
      and dh_fecha = @i_fecha_proceso
                                                                                                                                                                                                                         
End
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
if @i_toperacion = 'CG' or @i_toperacion = 'TO'
                                                                                                                                                                                                               
Begin
                                                                                                                                                                                                                                                         
    /*** ELIMINA DATOS EN SB_DATO_CUSTODIA ***/
                                                                                                                                                                                                               
   if exists (select 1
                                                                                                                                                                                                                                        
                from cob_externos..ex_dato_custodia dacx,
                                                                                                                                                                                                     
                     cob_conta_super..sb_dato_custodia dacs
                                                                                                                                                                                                   
                where dacx.dc_fecha    = @i_fecha_proceso
                                                                                                                                                                                                     
                and dacs.dc_fecha      = dacx.dc_fecha
                                                                                                                                                                                                        
                and dacs.dc_aplicativo = dacx.dc_aplicativo)
                                                                                                                                                                                                  
    Begin
                                                                                                                                                                                                                                                     
        insert into #aplicativo (dc_aplicativo)
                                                                                                                                                                                                               
        select distinct(dc_aplicativo)
                                                                                                                                                                                                                        
        from cob_externos..ex_dato_custodia
                                                                                                                                                                                                                   
        where dc_fecha = @i_fecha_proceso
                                                                                                                                                                                                                     
       
                                                                                                                                                                                                                                                       
        delete cob_conta_super..sb_dato_custodia
                                                                                                                                                                                                              
          from #aplicativo tma,
                                                                                                                                                                                                                               
               cob_conta_super..sb_dato_custodia dac
                                                                                                                                                                                                          
          where tma.dc_aplicativo = dac.dc_aplicativo
                                                                                                                                                                                                         
          and dac.dc_fecha = @i_fecha_proceso 
                                                                                                                                                                                                                
    End
                                                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
    /*** INSERTA DATOS EN SB_DATO_CUSTODIA ***/
                                                                                                                                                                                                               
    insert into cob_conta_super..sb_dato_custodia
                                                                                                                                                                                                             
       (dc_fecha,           dc_aplicativo,      dc_garantia,        dc_oficina,
                                                                                                                                                                               
        dc_cliente,         dc_categoria,       dc_tipo,            dc_idonea,
                                                                                                                                                                                
        dc_fecha_avaluo,    dc_moneda,          dc_valor_avaluo,    dc_valor_actual,
                                                                                                                                                                          
        dc_estado,          dc_abierta,         dc_num_reserva,     dc_calidad_gar,                           -- REQ 184 - dc_num_reserva - COMPLEMENTO REPOSITORIO - 10/DIC/2010 
                                                                            
        dc_valor_uti_opera)
                                                                                                                                                                                                                                   
     select 
                                                                                                                                                                                                                                                  
        dc_fecha,           dc_aplicativo,      dc_garantia,        dc_oficina,
                                                                                                                                                                               
        dc_cliente,         dc_categoria,       dc_tipo,            dc_idonea,
                                                                                                                                                                                
        dc_fecha_avaluo,    dc_moneda,          dc_valor_avaluo,    dc_valor_actual,
                                                                                                                                                                          
        dc_estado,          dc_abierta,         dc_num_reserva,     dc_calidad_gar,                            -- REQ 184 - dc_num_reserva - COMPLEMENTO REPOSITORIO - 10/DIC/2010
                                                                            
        dc_valor_uti_opera
                                                                                                                                                                                                                                    
      from cob_externos..ex_dato_custodia
                                                                                                                                                                                                                     
      where dc_fecha = @i_fecha_proceso
                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
      if @@error <> 0 Begin
                                                                                                                                                                                                                                   
        exec cob_conta_super..sp_errorlog
                                                                                                                                                                                                                     
        @i_operacion     = 'I',
                                                                                                                                                                                                                               
        @i_fecha_fin     = @i_fecha_proceso,
                                                                                                                                                                                                                  
        @i_fuente        = @w_sp_name,
                                                                                                                                                                                                                        
        @i_origen_error  = '28003',
                                                                                                                                                                                                                           
        @i_descrp_error  = 'ERROR INSERTANDO DATOS EN SB_DATO_CUSTODIA'
                                                                                                                                                                                       
      end
                                                                                                                                                                                                                                                     

                                                                                                                                                                                                                                                              
    /*** ACTUALIZANDO CODIGO DE CLIENTE ***/
                                                                                                                                                                                                                  
    update cob_conta_super..sb_dato_custodia 
                                                                                                                                                                                                                 
      set dc_cliente = en_ente
                                                                                                                                                                                                                                
      from cob_externos..ex_dato_custodia dacx,
                                                                                                                                                                                                               
             cobis..cl_ente  
                                                                                                                                                                                                                                 
        where dacx.dc_cliente = 0
                                                                                                                                                                                                                             
        and dacx.dc_fecha  = @i_fecha_proceso
                                                                                                                                                                                                                 
        and dacx.dc_documento_tipo = en_ced_ruc
                                                                                                                                                                                                               
        and dacx.dc_documento_numero = en_ced_ruc
                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              
    /*** ACTUALIZANDO CODIGO DE CLIENTE BANCAMIA PARA AQUELLOS QUE NO EXISTEN EN COBIS ***/
                                                                                                                                                                   
    update cob_conta_super..sb_dato_custodia 
                                                                                                                                                                                                                 
      set dc_cliente = @w_banco
                                                                                                                                                                                                                               
      where dc_cliente = 0
                                                                                                                                                                                                                                    
      and dc_fecha = @i_fecha_proceso   
                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
    /*** INSERTANDO LOG DE ERRORES ***/
                                                                                                                                                                                                                       
    insert into sb_errorlog
                                                                                                                                                                                                                                   
      (er_fecha,            er_fecha_proc,      er_fuente,      er_origen_error,
                                                                                                                                                                              
       er_descrp_error) 
                                                                                                                                                                                                                                      
    select 
                                                                                                                                                                                                                                                   
       @i_fecha_proceso,    getdate(),          @w_sp_name,     (dc_garantia + dc_documento_tipo + dc_documento_numero), 
                                                                                                                                     
       'ERROR CLIENTE NO EXISTE'
                                                                                                                                                                                                                              
      from cob_externos..ex_dato_custodia 
                                                                                                                                                                                                                    
      where dc_cliente = 0   
                                                                                                                                                                                                                                 
      and dc_fecha = @i_fecha_proceso
                                                                                                                                                                                                                         
    
                                                                                                                                                                                                                                                          
    /*** ELIMINA DATOS EN SB_DATO_GARANTIA ***/
                                                                                                                                                                                                               
    if exists (select 1
                                                                                                                                                                                                                                       
                from cob_externos..ex_dato_garantia dagx,
                                                                                                                                                                                                     
                     cob_conta_super..sb_dato_garantia dags
                                                                                                                                                                                                   
                where dagx.dg_fecha    = @i_fecha_proceso
                                                                                                                                                                                                     
                and dags.dg_fecha      = dagx.dg_fecha
                                                                                                                                                                                                        
                and dags.dg_aplicativo = dagx.dg_aplicativo)
                                                                                                                                                                                                  
    Begin
                                                                                                                                                                                                                                                     
        insert into #aplicativo (dg_aplicativo)
                                                                                                                                                                                                               
         select distinct(dg_aplicativo)
                                                                                                                                                                                                                       
           from cob_externos..ex_dato_garantia
                                                                                                                                                                                                                
           where dg_fecha = @i_fecha_proceso
                                                                                                                                                                                                                  
       
                                                                                                                                                                                                                                                       
        delete cob_conta_super..sb_dato_garantia
                                                                                                                                                                                                              
          from #aplicativo tma,
                                                                                                                                                                                                                               
               cob_conta_super..sb_dato_garantia dac
                                                                                                                                                                                                          
          where tma.dg_aplicativo = dac.dg_aplicativo
                                                                                                                                                                                                         
          and dac.dg_fecha = @i_fecha_proceso 
                                                                                                                                                                                                                
    End
                                                                                                                                                                                                                                                       
    
                                                                                                                                                                                                                                                          
/*** INSERTA DATOS EN SB_DATO_GARANTIA ***/
                                                                                                                                                                                                                   
    insert into cob_conta_super..sb_dato_garantia
                                                                                                                                                                                                             
       (dg_fecha,       dg_banco,       dg_toperacion,      dg_aplicativo,
                                                                                                                                                                                    
        dg_garantia,    dg_cobertura)
                                                                                                                                                                                                                         
     select 
                                                                                                                                                                                                                                                  
        dg_fecha,       dg_banco,       dg_toperacion,      dg_aplicativo,
                                                                                                                                                                                    
        dg_garantia,    0
                                                                                                                                                                                                                                     
      from cob_externos..ex_dato_garantia
                                                                                                                                                                                                                     
      where dg_fecha = @i_fecha_proceso 
                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
      if @@error <> 0 Begin
                                                                                                                                                                                                                                   
        exec cob_conta_super..sp_errorlog
                                                                                                                                                                                                                     
        @i_operacion     = 'I',
                                                                                                                                                                                                                               
        @i_fecha_fin     = @i_fecha_proceso,
                                                                                                                                                                                                                  
        @i_fuente        = @w_sp_name,
                                                                                                                                                                                                                        
        @i_origen_error  = '28004',
                                                                                                                                                                                                                           
        @i_descrp_error  = 'ERROR INSERTANDO DATOS EN SB_DATO_GARANTIA'
                                                                                                                                                                                       
      end
                                                                                                                                                                                                                                                     
      
                                                                                                                                                                                                                                                        
End
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
-- Tarifas Servc. Financieros
                                                                                                                                                                                                                                 
If @i_toperacion = 'TF' or @i_toperacion = 'TO' Begin
                                                                                                                                                                                                         
   /*** ELIMINA DATOS EN SB_PARAM_TARIFAS - SB_DATOS_TARIFAS  ***/
                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
   --Fecha de Proceso
                                                                                                                                                                                                                                         
   select @w_fecha_proc = fp_fecha
                                                                                                                                                                                                                            
   from  cobis..ba_fecha_proceso
                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
   if @@rowcount = 0 Begin
                                                                                                                                                                                                                                    
        exec cob_conta_super..sp_errorlog
                                                                                                                                                                                                                     
        @i_operacion     = 'I',
                                                                                                                                                                                                                               
        @i_fecha_fin     = @i_fecha_proceso,
                                                                                                                                                                                                                  
        @i_fuente        = @w_sp_name,
                                                                                                                                                                                                                        
        @i_origen_error  = '2902764',
                                                                                                                                                                                                                         
        @i_descrp_error  = 'No es Posible Obtener la Fecha de Proceso'
                                                                                                                                                                                        
   end
                                                                                                                                                                                                                                                        
      
                                                                                                                                                                                                                                                        
   --Se modifica parametro  @i_finsemana a 'S'  para no tener el cuenta el sabado como dia habil CCA 389
                                                                                                                                                      
	select @w_return = 0
                                                                                                                                                                                                                                         
	exec @w_return = cob_remesas..sp_fecha_habil
                                                                                                                                                                                                                 
	@i_fecha     = @w_fecha_proc,
                                                                                                                                                                                                                                
	@i_oficina   = 1,
                                                                                                                                                                                                                                            
	@i_efec_dia  = 'S',
                                                                                                                                                                                                                                          
	@i_finsemana = 'S',
                                                                                                                                                                                                                                          
	@w_dias_ret  = 1,
                                                                                                                                                                                                                                            
	@o_fecha_sig = @w_fecha_aux out
                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
	If @w_return <> 0
                                                                                                                                                                                                                                            
	Begin
                                                                                                                                                                                                                                                        
        exec cob_conta_super..sp_errorlog
                                                                                                                                                                                                                     
        @i_operacion     = 'I',
                                                                                                                                                                                                                               
        @i_fecha_fin     = @i_fecha_proceso,
                                                                                                                                                                                                                  
        @i_fuente        = @w_sp_name,
                                                                                                                                                                                                                        
        @i_origen_error  = '708208',
                                                                                                                                                                                                                          
        @i_descrp_error  = 'Error al ejecutar sp_fecha_habil'
                                                                                                                                                                                                 
	End
                                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
   	If convert(tinyint,datepart(mm,@w_fecha_aux)) = convert(tinyint,datepart(mm,@w_fecha_proc)) 
                                                                                                                                                              
	Begin
                                                                                                                                                                                                                                                        
	   Print 'No se pasará información de tarifas  por validacion de fecha'
                                                                                                                                                                                      
   end
                                                                                                                                                                                                                                                        
   else
                                                                                                                                                                                                                                                       
   begin
                                                                                                                                                                                                                                                      
    -- Elimina en sb_param_tarifas 
                                                                                                                                                                                                                           
    if exists (select 1
                                                                                                                                                                                                                                       
                from cob_externos..ex_param_tarifas tarx,
                                                                                                                                                                                                     
                     cob_conta_super..sb_param_tarifas tars
                                                                                                                                                                                                   
                where tarx.pt_fecha      = @w_fecha_proc
                                                                                                                                                                                                      
                and   tars.pt_fecha      = tarx.pt_fecha
                                                                                                                                                                                                      
                and   tars.pt_aplicativo = tarx.pt_aplicativo)
                                                                                                                                                                                                
    Begin
                                                                                                                                                                                                                                                     
        insert into #aplicativo (dt_aplicativo)
                                                                                                                                                                                                               
        select distinct(pt_aplicativo)
                                                                                                                                                                                                                        
        from cob_externos..ex_param_tarifas
                                                                                                                                                                                                                   
        where pt_fecha =  @w_fecha_proc
                                                                                                                                                                                                                       
       
                                                                                                                                                                                                                                                       
        delete cob_conta_super..sb_param_tarifas
                                                                                                                                                                                                              
          from #aplicativo apl,
                                                                                                                                                                                                                               
               cob_conta_super..sb_param_tarifas pta
                                                                                                                                                                                                          
          where apl.dt_aplicativo = pta.pt_aplicativo
                                                                                                                                                                                                         
          and   pta.pt_fecha      = @w_fecha_proc 
                                                                                                                                                                                                            
    End
                                                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
    Insert Into sb_param_tarifas
                                                                                                                                                                                                                              
    (pt_fecha,  pt_aplicativo, pt_nemonico, pt_concepto, pt_campo1, pt_campo2,  pt_campo3,        pt_campo4, 
                                                                                                                                                 
     pt_campo5, pt_campo6,     pt_campo7,   pt_campo8,   pt_campo9, pt_campo10, pt_forma_calculo, pt_estado)    
                                                                                                                                              
    Select
                                                                                                                                                                                                                                                    
     pt_fecha,  pt_aplicativo, pt_nemonico, pt_concepto, pt_campo1, pt_campo2,  pt_campo3,        pt_campo4, 
                                                                                                                                                 
     pt_campo5, pt_campo6,     pt_campo7,   pt_campo8,   pt_campo9, pt_campo10, pt_forma_calculo, pt_estado
                                                                                                                                                   
    From cob_externos..ex_param_tarifas
                                                                                                                                                                                                                       
    Where pt_fecha =  @w_fecha_proc 
                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
    if @@error <> 0 Begin
                                                                                                                                                                                                                                     
       exec cob_conta_super..sp_errorlog
                                                                                                                                                                                                                      
       @i_operacion     = 'I',
                                                                                                                                                                                                                                
       @i_fecha_fin     = @i_fecha_proceso,
                                                                                                                                                                                                                   
       @i_fuente        = @w_sp_name,
                                                                                                                                                                                                                         
       @i_origen_error  = '28005',
                                                                                                                                                                                                                            
       @i_descrp_error  = 'ERROR INSERTANDO DATOS EN SB_PARAM_TARIFAS'
                                                                                                                                                                                        
       Goto ERROR
                                                                                                                                                                                                                                             
    end
                                                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
   -- Elimina en sb_datos_tarifas 
                                                                                                                                                                                                                            
   if exists (select 1
                                                                                                                                                                                                                                        
                from cob_externos..ex_datos_tarifas tarx,
                                                                                                                                                                                                     
                     cob_conta_super..sb_datos_tarifas tars
                                                                                                                                                                                                   
                where tarx.dt_fecha      =  @w_fecha_proc
                                                                                                                                                                                                     
                and   tars.dt_fecha      = tarx.dt_fecha
                                                                                                                                                                                                      
                and   tars.dt_aplicativo = tarx.dt_aplicativo)
                                                                                                                                                                                                
    Begin
                                                                                                                                                                                                                                                     
        insert into #aplicativo (dt_aplicativo)
                                                                                                                                                                                                               
        select distinct(dt_aplicativo)
                                                                                                                                                                                                                        
        from cob_externos..ex_datos_tarifas
                                                                                                                                                                                                                   
        where dt_fecha =  @w_fecha_proc
                                                                                                                                                                                                                       
       
                                                                                                                                                                                                                                                       
        delete cob_conta_super..sb_datos_tarifas
                                                                                                                                                                                                              
          from #aplicativo apl,
                                                                                                                                                                                                                               
               cob_conta_super..sb_datos_tarifas dta
                                                                                                                                                                                                          
          where apl.dt_aplicativo = dta.dt_aplicativo
                                                                                                                                                                                                         
          and   dta.dt_fecha      =  @w_fecha_proc 
                                                                                                                                                                                                           
    End
                                                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
    Insert Into sb_datos_tarifas
                                                                                                                                                                                                                              
    (dt_fecha,  dt_aplicativo, dt_nemonico, dt_campo1, dt_campo2,  dt_campo3,       dt_campo4, dt_campo5,
                                                                                                                                                     
     dt_campo6, dt_campo7,     dt_campo8,   dt_campo9, dt_campo10, dt_base_calculo, dt_valor,  dt_estado)
                                                                                                                                                     
    Select
                                                                                                                                                                                                                                                    
     dt_fecha,  dt_aplicativo, dt_nemonico, dt_campo1, dt_campo2,  dt_campo3,       dt_campo4, dt_campo5,
                                                                                                                                                     
     dt_campo6, dt_campo7,     dt_campo8,   dt_campo9, dt_campo10, dt_base_calculo, dt_valor,  dt_estado    
                                                                                                                                                  
    From cob_externos..ex_datos_tarifas
                                                                                                                                                                                                                       
    Where dt_fecha = @w_fecha_proc 
                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
    if @@error <> 0 Begin
                                                                                                                                                                                                                                     
       exec cob_conta_super..sp_errorlog
                                                                                                                                                                                                                      
       @i_operacion     = 'I',
                                                                                                                                                                                                                                
       @i_fecha_fin     = @i_fecha_proceso,
                                                                                                                                                                                                                   
       @i_fuente        = @w_sp_name,
                                                                                                                                                                                                                         
       @i_origen_error  = '28006',
                                                                                                                                                                                                                            
       @i_descrp_error  = 'ERROR INSERTANDO DATOS EN SB_DATOS_TARIFAS'
                                                                                                                                                                                        
       Goto ERROR
                                                                                                                                                                                                                                             
    end
                                                                                                                                                                                                                                                       
   end --fechas
                                                                                                                                                                                                                                               
End
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
ERROR:
                                                                                                                                                                                                                                                        
exec cob_conta_super..sp_errorlog
                                                                                                                                                                                                                             
     @i_fuente = @w_sp_name
                                                                                                                                                                                                                                   

                                                                                                                                                                                                                                                              
Return 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
