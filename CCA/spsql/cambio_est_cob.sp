/************************************************************************/
/*   Archivo:              cambio_est_cob.sp                            */
/*   Stored procedure:     sp_cambio_est_cob                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Fecha de escritura:   Mayo.2010                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Realiza el cambio de esado de la cobranza mediante carguemasivo    */
/*   de de un plano                                                     */
/************************************************************************/
/*                               CAMBIOS                                */
/*   FECHA     AUTOR          CAMBIO                                    */
/*   Ene-2015  Elcira Pelaez  NR-0439 Cambio est.Cobranza por parametro */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_est_cob') 
drop proc sp_cambio_est_cob
go

SET ANSI_NULLS ON
go

---NR 439 Manejo de la cobranza por parametro 
create proc sp_cambio_est_cob
as declare 
   @w_path       varchar(250),
   @w_cmd        varchar(250),
   @w_s_app      varchar(250),
   @w_destino    varchar(250),
   @w_errores    varchar(250),
   @w_comando    varchar(250),
   @w_error      int,
   @w_err_up     varchar(250),
   @w_fecha_hoy   datetime,
   @w_descripcion varchar(50)
   
   
-- CARGA DEL ARCHIVO ENTREGADO POR BANCA MIA

select @w_fecha_hoy = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

---VALIDAR PARAMETRO CAMBIO DE ESTADO DE LA COBRANZA ANTES DE CARGAR PLANO
select 1
from cobis..cl_catalogo c,
     cobis..ba_batch
where c.tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_habilita_camestcobranza')
and c.codigo = ba_batch
and ba_arch_fuente like '%sp_cambio_est_cob%'
and c.estado ='V'
if @@rowcount = 0
begin
      select @w_error = 5
      goto ERROR_PARAMETRO
end
ELSE
begin
   PRINT 'PROCESO ESTA HABILITADO EN CATALOGO ca_habilita_camestcobranza'
end
---FIN VALIDAR CAMBIO ESTADO COBRANZA PARAMETRO

truncate table ca_op_cobranza_jud
truncate table ca_cobranza_castigada_tmp

select @w_err_up = ''
PRINT 'Inicio carga de plano cambio_est_cob.txt'
select @w_s_app   = pa_char from cobis..cl_parametro where pa_producto = 'ADM' and   pa_nemonico = 'S_APP'
select @w_path    = 'F:\VBatch\Cartera\Listados\'
select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_op_cobranza_jud in '
select @w_destino = @w_path + 'cambio_est_cob' + '.txt', @w_errores  = @w_path + 'cambio_est_cob' + '.err'
select @w_comando = @w_cmd + @w_path + 'cambio_est_cob.txt -b5000 -c -e' + @w_errores + ' -t";" ' + '-config '+ @w_s_app + 's_app.ini'

exec   @w_error   = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error Carga Archivo Revisar Estructura y Ubicacion'
   print @w_comando 
   return 1
end
PRINT 'FIN carga de plano cambio_est_cob.txt'
-- VALIDACION TIPO DE CAMBIO SOLICTADO

select tipo      = cj_estado_cb, 
       registros = count(1)
into #validacion
from ca_op_cobranza_jud
group by cj_estado_cb

if @@rowcount = 0
begin
   PRINT 'No hay registros validos para procesar en la tabla ca_op_cobranza_jud'
   return 1
end

select * from #validacion

---- DEFINIR TIPO DE ACTUALIZACION

if exists (select 1 from #validacion
           where tipo = 'CP')
begin -- CAMBIO A COBRO PREJURIDICO

   PRINT 'Encontro estaos CP'
   begin tran  --INICIO ATOMICIDAD
    
   --- CARTERA
   update ca_operacion                      
   set op_estado_cobranza = 'CP'            
   from ca_op_cobranza_jud                 
   where op_banco      = cj_banco       
   and   cj_estado_cb  = 'CP'
              
   if @@error <> 0 begin
      select @w_error = 724531
      goto ERROR
   end   
   
   update cob_cartera..ca_valor_atx         
   set vx_estado_cobranza = 'CP'            
   from ca_op_cobranza_jud                    
   where vx_banco = cj_banco 
   and   cj_estado_cb  = 'CP'                  
                  
   if @@error <> 0  begin
      select @w_error = 724532
      goto ERROR
   end                              
                                
   --- CREDITO 
   --- OBTENGO EL NUMERO DE COBRANZA 
   select 
   cc_cobranza = oc_cobranza,
   cc_banco    = cj_banco,
   cc_abogado  = cj_codigo_ab,
   cc_login_ab = convert(varchar(14), null)
   into  #cp_cambios_cobranza
   from  cob_credito..cr_operacion_cobranza, 
         ca_op_cobranza_jud
   where cj_banco    = oc_num_operacion
   
   --- OBTENGO EL LOGIN DEL ABOGADO 
   update #cp_cambios_cobranza set
   cc_login_ab = ab_login
   from  cob_credito..cr_abogado
   where ab_abogado  = cc_abogado
   
   if @@error <> 0  begin
      select @w_error = 724533
      goto ERROR
   end    
   
   --- INGRESO EL CAMBIO DE ESTADO A CP 
   insert into cob_credito..cr_cambio_estados(
   ce_cobranza,    ce_secuencial,  ce_estado_ant,  
   ce_estado_act,  ce_funcionario, ce_fecha)
   select
   cc_cobranza,    max(ce_secuencial) + 1, 'CA',
   'CP',           'script',               (select convert(varchar,(select fp_fecha from cobis..ba_fecha_proceso),101))
   from  cob_credito..cr_cambio_estados, #cp_cambios_cobranza
   where cc_cobranza = ce_cobranza
   group  by cc_cobranza
   
   if @@error <> 0  begin
      select @w_error = 724534
      goto ERROR
   end       
   
   --- ACTUALIZO A CP LAS COBRANZAS SOLICITADAS 
   update cob_credito..cr_cobranza set
   co_estado        = 'CP',
   co_abogado       = cc_abogado,
   co_fecha_abogado = (select convert(varchar,(select fp_fecha from cobis..ba_fecha_proceso),101)),
   co_observa       = 'SCRIPT POR PETICION BANCAMIA  - Cambio a Cobro Prejuridico'
   from  #cp_cambios_cobranza
   where co_cobranza = cc_cobranza
   
   if @@error <> 0  begin
      select @w_error = 724535
      goto ERROR
   end      
   
   commit tran   

end

if exists (select 1 from #validacion
           where tipo = 'CJ')
begin -- CAMBIO A COBRO JURIDICO
   PRINT 'Encontro estaos CJ'
   begin tran  --INICIO ATOMICIDAD
   
   --- CARTERA
     
   update ca_operacion                      
   set   op_estado_cobranza = 'CJ'            
   from  ca_op_cobranza_jud                 
   where op_banco = cj_banco 
   and   cj_estado_cb  = 'CJ'               
              
   if @@error <> 0  begin
      select @w_error = 724531
      goto ERROR
   end      
 
   
   update cob_cartera..ca_valor_atx         
   set vx_estado_cobranza = 'CJ'            
   from ca_op_cobranza_jud                    
   where vx_banco = cj_banco                
   and   cj_estado_cb  = 'CJ'
                               
   if @@error <> 0  begin
      select @w_error = 724532
      goto ERROR
   end              
              
   ---  CREDITO 
   ---  OBTENGO EL NUMERO DE COBRANZA 
   select 
   cc_cobranza = oc_cobranza,
   cc_banco    = cj_banco,
   cc_abogado  = cj_codigo_ab,
   cc_login_ab = convert(varchar(14), null)
   into  #cj_cambios_cobranza
   from  cob_credito..cr_operacion_cobranza, ca_op_cobranza_jud
   where cj_banco    = oc_num_operacion
   
   
   --- OBTENGO EL LOGIN DEL ABOGADO 
   update #cj_cambios_cobranza set
   cc_login_ab = ab_login
   from  cob_credito..cr_abogado
   where ab_abogado  = cc_abogado

   if @@error <> 0  begin
      select @w_error = 724533
      goto ERROR
   end      
   
   
   --- INGRESO EL CAMBIO DE ESTADO A CJ 
   insert into cob_credito..cr_cambio_estados(
   ce_cobranza,    ce_secuencial,  ce_estado_ant,  
   ce_estado_act,  ce_funcionario, ce_fecha)
   select
   cc_cobranza,    max(ce_secuencial) + 1, 'CA',
   'CJ',           'script',               (select convert(varchar,(select fp_fecha from cobis..ba_fecha_proceso),101))
   from  cob_credito..cr_cambio_estados, #cj_cambios_cobranza
   where cc_cobranza = ce_cobranza
   group  by cc_cobranza
   
   if @@error <> 0  begin
      select @w_error = 724534
      goto ERROR
   end   
   
   --- ACTUALIZO A CP LAS COBRANZAS SOLICITADAS 
   update cob_credito..cr_cobranza set
   co_estado        = 'CJ',
   co_abogado       = cc_abogado,
   co_fecha_abogado = (select convert(varchar,(select fp_fecha from cobis..ba_fecha_proceso),101)),
   co_observa       = 'SCRIPT POR PETICION BANCAMIA  - Cambio a Cobro Juridico'
   from  #cj_cambios_cobranza
   where co_cobranza = cc_cobranza
   
   if @@error <> 0  begin
      select @w_error = 724535
      goto ERROR
   end    
   
   commit tran
   
end

---ORS 000457
if exists (select 1 from #validacion
           where tipo = 'CC')
begin -- CAMBIO A CARTERA CASTIGADA

   PRINT 'Encontro estaos CC'
   begin tran  --INICIO ATOMICIDAD

   if exists (select 1 
           from cob_cartera..ca_op_cobranza_jud,
                ca_operacion with(nolock)
           where op_banco = cj_banco
           and cj_estado_cb  = 'CC'
           and op_estado <> 4 
          )
	begin
          insert into ca_cobranza_castigada_tmp
	      select cj_banco ,op_estado, cj_estado_cb
	           from cob_cartera..ca_op_cobranza_jud,
	           ca_operacion with(nolock)
           where op_banco = cj_banco
           and cj_estado_cb  = 'CC'
           and op_estado <> 4 

           ---Eliminar las que vienen malas para queno se actualicen
           delete cob_cartera..ca_op_cobranza_jud
           from cob_cartera..ca_op_cobranza_jud,
                      ca_cobranza_castigada_tmp
           where cj_banco = banco
	end 
   
   update ca_operacion                      
   set   op_estado_cobranza = 'CC'            
   from  ca_op_cobranza_jud                 
   where op_banco = cj_banco                
   and   cj_estado_cb  = 'CC'   
   and   op_estado     = 4

   if @@error <> 0  begin
      select @w_error = 724531
      goto ERROR
   end      
 
   update cob_cartera..ca_valor_atx         
   set vx_estado_cobranza = 'CC'            
   from ca_op_cobranza_jud                    
   where vx_banco      = cj_banco   
   and   cj_estado_cb  = 'CC'      
                               
   if @@error <> 0  begin
      select @w_error = 724532
      goto ERROR
   end              
              
   ---  CREDITO 
   ---  OBTENGO EL NUMERO DE COBRANZA 
   select 
   cc_cobranza = oc_cobranza,
   cc_banco    = cj_banco,
   cc_abogado  = cj_codigo_ab,
   cc_login_ab = convert(varchar(14), null)
   into  #cj_cambios_cobranzaCC
   from  cob_credito..cr_operacion_cobranza, ca_op_cobranza_jud
   where cj_banco    = oc_num_operacion
   
   
   --- OBTENGO EL LOGIN DEL ABOGADO 
   update #cj_cambios_cobranzaCC set
   cc_login_ab = ab_login
   from  cob_credito..cr_abogado
   where ab_abogado  = cc_abogado

   if @@error <> 0  begin
      select @w_error = 724533
      goto ERROR
   end      
   
   
   --- INGRESO EL CAMBIO DE ESTADO A CC
   insert into cob_credito..cr_cambio_estados(
   ce_cobranza,    ce_secuencial,  ce_estado_ant,  
   ce_estado_act,  ce_funcionario, ce_fecha)
   select
   cc_cobranza,    max(ce_secuencial) + 1, 'CJ o CP',
   'CC',           'script',               (select convert(varchar,(select fp_fecha from cobis..ba_fecha_proceso),101))
   from  cob_credito..cr_cambio_estados, #cj_cambios_cobranzaCC
   where cc_cobranza = ce_cobranza
   group  by cc_cobranza
   
   if @@error <> 0  begin
      select @w_error = 724534
      goto ERROR
   end   
   
   --- ACTUALIZO A CP LAS COBRANZAS SOLICITADAS 
   update cob_credito..cr_cobranza set
   co_estado        = 'CC',
   co_abogado       = cc_abogado,
   co_fecha_abogado = (select convert(varchar,(select fp_fecha from cobis..ba_fecha_proceso),101)),
   co_observa       = 'SCRIPT POR PETICION BANCAMIA  - Cambio a Cobro Castigado'
   from  #cj_cambios_cobranzaCC
   where co_cobranza = cc_cobranza
   
   if @@error <> 0  begin
      select @w_error = 724535
      goto ERROR
   end    
   
   commit tran
   
end

---ORS 000457

goto FIN

ERROR:
    PRINT 'llego a ERROR con este codigo' + cast ( @w_error as varchar)
    rollback
	if @w_error > 0 
	begin
	   select @w_descripcion = mensaje
	   from cobis..cl_errores
	   where numero = @w_error  
   
	   insert into ca_errorlog
	         (er_fecha_proc,      er_error,   er_usuario,
	          er_tran,            er_cuenta,  er_descripcion,
	          er_anexo)
	   values(@w_fecha_hoy ,         @w_error, 'sa',
	          7269,              '',            @w_descripcion,
	          'Error en SP --> cambio_est_cobranza'
	          ) 
	end       


FIN:

if exists (select 1 from ca_cobranza_castigada_tmp)
begin
 ---generar plano de erroers si los hay
    PRINT 'Encontro estados CC con estado operativo diferentes de CASTIGADO'
    
    select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_cobranza_castigada_tmp out '
	select @w_destino = @w_path + 'Err_cambio_est_cob.txt', @w_errores  = @w_path + 'Err_cambio_est_cob' + '.err'
	select @w_comando = @w_cmd + @w_path + 'Err_cambio_est_cob.txt -b5000 -c -e' + @w_errores + ' -t";" ' + '-config '+ @w_s_app + 's_app.ini'
	
	exec   @w_error   = xp_cmdshell @w_comando
	if @w_error <> 0 begin
	   select @w_error = 724529
	   goto ERROR
	end 

end

ERROR_PARAMETRO:
if @w_error = 5
begin
   PRINT ''
   PRINT ''
   PRINT 'ATENCION !!!!!'
   PRINT 'NO SE HACE EL CARGUE POR QUE EL PROGRAMA ESTA BLOQUEADO  POR CATALOGO '
   return 0
end        
   
return 0
go



