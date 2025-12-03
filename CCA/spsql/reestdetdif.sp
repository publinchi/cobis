/************************************************************************/
/*      Archivo:                reestdetdif.sp                   	    */
/*      Stored procedure:       sp_plano_reestruct_det_diff             */
/*      Base de datos:          cob_ahorros                             */
/*      Producto:               cartera                                 */
/*      Disenado por:           Yecid Martinez                      	*/
/*      Fecha de documentacion: 02/24/2011                              */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera archivo plano de reestructuracion en un rango de fechas  */
/*      con detalle diferidos.                			                */
/*                                                                      */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA      AUTOR              RAZON                             */
/*      02/28/2011 Y.Martinez         Version Inicial.                  */
/************************************************************************/

use cob_cartera
go

if exists ( select 1 from sysobjects where
            name = 'sp_plano_reestruct_det_diff' and type = 'P')
	drop proc sp_plano_reestruct_det_diff
go

---INC 98543

create proc sp_plano_reestruct_det_diff
	@i_param1       	varchar(255) 	= NULL,
   	@i_param2       	varchar(255) 	= NULL
as
declare 
  	@w_sp_name              varchar(300),
	@w_error  		        int,
	@w_fecha_proceso	    datetime,
	@w_mensaje		        varchar(300),
	@w_cod_error		    int,
	@w_dias 		        int,
	@w_fecha_ini		    datetime, 
	@w_fecha_fin		    datetime,
	@w_servidor		        varchar(10),
    @w_operacion  		    int, 
    @w_secuencial 		    int,
    @w_s_app                varchar(255),
   	@w_path                 varchar(255),
   	@w_destino              varchar(255),
   	@w_errores              varchar(255),
   	@w_cmd                  varchar(500),
   	@w_comando              varchar(5000),
   	@w_batch                int,
   	@w_dia			        varchar(2),
   	@w_mes			        varchar(2),
   	@w_ano		        	varchar(4),
    @w_col_id   	    	int,
    @w_columna  	    	varchar(100),
    @w_cabecera 	    	varchar(1000),
    @w_nombre_plano         varchar(500),
    @w_debug 		        varchar(1), 
   	@w_numdatos		        int,
   	@w_nombre_plano_aux     varchar(200)

 
--- DEBUG 

select  @w_sp_name 			= 'sp_plano_reestruct_det_diff',
	    @w_error  			= 0,
	    @w_fecha_ini		= @i_param1, 
	    @w_fecha_fin		= @i_param2,
	    @w_servidor         = 'NOHIST',
        @w_comando 			= '',
        @w_debug 		    = 'N',
        @w_batch            = 7112


-- fecha de proceso
select   @w_fecha_proceso = fp_fecha
from     cobis..ba_fecha_proceso

select @w_mes 			= datepart(dd,@w_fecha_proceso)
select @w_dia 			= datepart(mm,@w_fecha_proceso)
select @w_ano 			= datepart(yy,@w_fecha_proceso)
select @w_nombre_plano 		= 'REESTRUCTURACIONES_' + @w_mes + @w_dia + @w_ano 


-- El reango entre fecha inicial y fecha final no debe duperar un mes
select @w_dias = datediff(dd, @w_fecha_ini, @w_fecha_fin)

-- PARAMETRO DE LINK 
select 	@w_servidor = pa_char
from 	cobis..cl_parametro
where 	pa_producto = 'CCA'
and   	pa_nemonico = 'SRVHIS'

If @@rowcount = 0  Begin

   select @w_mensaje = 'No Existe Parámetro para el LINK SERVER'
   exec cob_conta_super..sp_errorlog
      @i_operacion     = 'I',
      @i_fecha_fin     = @w_fecha_proceso,
      @i_fuente        = @w_sp_name,
      @i_origen_error  = '28001',
      @i_descrp_error  = @w_mensaje   
   Goto ERROR

End

if @w_debug = 'S' print '@w_servidor' + cast(@w_servidor as varchar)

if @w_fecha_ini > @w_fecha_fin begin
   select  @w_mensaje    = 'Fecha de Inicio es Mayor a la Fecha Fin'
   select  @w_mensaje
   select  @w_error  = 101
   goto ERROR
end

if @w_dias > 31 begin
   select  @w_mensaje         = 'Error: Número de días a consultar supera los 30 dias'
   select  @w_mensaje
   select  @w_cod_error       = 100
   goto ERROR

end

create table #sec_retro(
operacion    int,
sec          int,
estado       char(1))


truncate table ca_reporte_reest 

-- cargamos informacion reestructuraciones aplicadas 

select 
tr_secuencial,
tr_fecha_ref,
op_operacion,
tr_banco,
op_cliente,
op_toperacion,
op_oficina,
'FNG' = isnull((select 'S' 
                 from cob_credito..cr_gar_propuesta (nolock) 
                 where gp_tramite = op_tramite 
                 and   gp_est_garantia = 'V'
                 and gp_porcentaje = 50),'N')
into #oper_reest
from cob_cartera..ca_transaccion (nolock),
     cob_cartera..ca_operacion (nolock)       
where tr_tran       =  'RES'
and   tr_estado     <>  'RV'
and   tr_fecha_mov >= @w_fecha_ini
and   tr_fecha_mov <= @w_fecha_fin
and   tr_operacion  = op_operacion


if @w_debug = 'S' select @w_numdatos = count(1) from #oper_reest
if @w_debug = 'S' print ' #op_reest ' + cast(@w_numdatos as varchar)

---XTRAER EL NÚMERO DE TRAMITE CUANDO LA FECHA DE APROBACIÓN SEA <= A LA FECHA DE TRANSACCION 
select 'fecha_tramite' = max(tr_fecha_apr) ,'banco'= tr_numero_op_banco
into #tramites
from cob_credito..cr_tramite,
     #oper_reest 
where tr_tipo 	          = 'E'
and   tr_estado           = 'A'
and   tr_numero_op_banco  = tr_banco
and   tr_fecha_apr        < dateadd(dd,1,tr_fecha_ref)
group by tr_numero_op_banco


if @w_debug = 'S' select  @w_numdatos = count(1) from #tramites
if @w_debug = 'S' print ' #tramites ' + cast(@w_numdatos as varchar)

-- cargamos informacion general de amortizacion de las reestructuraciones encontradas segun ultima fecha de tramite

select 	t.tr_motivo,
       	t.tr_tramite,
       	'tr_monto' = convert(money, 0), --t.tr_monto,
       	t.tr_plazo,
	o.tr_secuencial,
	o.tr_fecha_ref,
	o.op_operacion,
	o.tr_banco,
	o.op_cliente,
	o.op_toperacion,
	o.op_oficina,
	o.FNG 
into 	#rees
from 	#oper_reest o,
     	cob_credito..cr_tramite t (nolock),
     	#tramites tr
where 	t.tr_numero_op_banco = tr_banco
and     banco = tr_banco
AND     tr_fecha_apr = tr.fecha_tramite
and     tr_tipo = 'E'
and     tr_estado = 'A'

if @w_debug = 'S' select  @w_numdatos = count(1) from #rees
if @w_debug = 'S' print ' #rees ' + cast(@w_numdatos as varchar)

-- cargamos informacion general de reestructuraciones que se encuentran en historicos para traerlas a produccion

insert into #sec_retro
select 	op_operacion, 
	tr_secuencial, 
	'N'
from  	#rees RE
where 	exists (select 	1 
		from 	cob_cartera..ca_operacion_his 
		where 	oph_operacion  = RE.op_operacion  
		and 	oph_secuencial = RE.tr_secuencial)
and   	@w_servidor <> 'NOHIST'


if @w_debug = 'S' select @w_numdatos = count(1) from #sec_retro
if @w_debug = 'S' print ' #sec_retro ' + cast(@w_numdatos as varchar)


if exists( select 1 from #sec_retro) Begin
   while 1 = 1 begin
      
      select top 1 
      @w_operacion  = operacion,
      @w_secuencial = sec
      from    #sec_retro     
      where   estado = 'N'
 
      if @@rowcount = 0 
         break;  

      begin tran

      exec @w_error = cob_cartera..sp_cpy_historico_lnk  
      @i_operacion   = @w_operacion,
      @i_secuencial  = @w_secuencial
      
      if @w_error  <> 0 begin       

          select @w_mensaje = 'ERROR EJECUTANDO BCP DE HISTORICOS OP:' + cast(@w_operacion as varchar) + ' SEC:' + cast(@w_secuencial as varchar) 

          exec cob_conta_super..sp_errorlog
          @i_operacion     = 'I',
          @i_fecha_fin     = @w_fecha_proceso,
          @i_fuente        = @w_sp_name,
          @i_origen_error  = '28003',
          @i_descrp_error  = @w_mensaje   
          commit tran    
          Goto ERROR

       End 
      
       select @w_comando = 'exec '+ @w_servidor +'.cob_cartera.dbo.sp_bor_historico_lnk'
       select @w_comando = @w_comando + '  @i_operacion   = ' + convert(varchar(25),@w_operacion)
       select @w_comando = @w_comando + ', @i_secuencial  = ' + convert(varchar(25),@w_secuencial)
       exec @w_error = sp_sqlexec @w_comando   
      
       if @w_error  <> 0 begin       

          select @w_mensaje = 'ERROR CARGANDO BCP EN EL CENTRAL OP:' + cast(@w_operacion as varchar) + ' SEC:' + cast(@w_secuencial as varchar) 

          exec cob_conta_super..sp_errorlog
          @i_operacion     = 'I',
          @i_fecha_fin     = @w_fecha_proceso,
          @i_fuente        = @w_sp_name,
          @i_origen_error  = '28003',
          @i_descrp_error  = @w_mensaje   
          commit tran    
          Goto ERROR

       End 

       update #sec_retro set
       estado = 'P'
       where estado    = 'N'
       and   operacion = @w_operacion  
       and   sec       = @w_secuencial 

       commit tran    

  End       

End


---GENERAR EL MONTO DE LA REESTRUCTURACION
select 'fecha_ref' = tr_fecha_ref,       
       'banco'     = tr_banco,
       'monto'     = sum(amh_acumulado + amh_gracia - amh_pagado)
into    #total_rees
from  #rees RES,
     ca_amortizacion_his
where  tr_secuencial = amh_secuencial
and    op_operacion  = amh_operacion
group   by tr_fecha_ref, tr_banco

-- cargamos en tabla temporal datos definitivos agrupados

select 	tr_fecha_ref,
	op_cliente,
	tr_banco,
       	op_toperacion, 
       	op_oficina, 
       	FNG, 
	tr_monto,
	tr_plazo,
	tr_motivo,
       	amh_concepto,
       	amh_estado,
	'valor' = sum(amh_acumulado + amh_gracia - amh_pagado)
into     #definitiva
from 	#rees RES,
	ca_amortizacion_his
where 	tr_secuencial = amh_secuencial
and   	op_operacion  = amh_operacion
and     amh_estado <> 3
and    (amh_acumulado + amh_gracia - amh_pagado) > 0
group   by tr_fecha_ref, op_cliente, tr_banco, op_toperacion, op_oficina, FNG, tr_monto, tr_plazo, tr_motivo, amh_concepto, amh_estado


if @w_debug = 'S' select @w_numdatos = count(1) from #definitiva
if @w_debug = 'S' print ' #definitiva ' + cast(@w_numdatos as varchar)


---ACTUALIZA MONTO REESTRUCTURACION 
update #definitiva  set
tr_monto  = monto
from  #total_rees 
where banco      = tr_banco
and   fecha_ref  = tr_fecha_ref



-- Generar Archivo de Cabeceras

select @w_col_id   = 0,
       @w_columna  = '',
       @w_cabecera = '',
       @w_comando  = ''

select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

if @@rowcount = 0 Begin
   select  @w_mensaje    = 'NO EXISTE RUTA DEL S_APP'
   select  @w_error  = 106
   goto ERROR
End 


select @w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = @w_batch


---**********GENERANDO ARCHIVO PLANO 
if exists (select 1 from sysobjects where name = 'tmp_archivo')
   drop table tmp_archivo

create table tmp_archivo(
registro     varchar(700))

select @w_cabecera = 'Fecha_Reest|Nombre_cliente|Tipo_IDE|Numero_IDE|Obligacion|Tipo_producto|Oficina|FNG|Monto|Plazo|Motivo|Concepto|Estado_concepto|Valor_concepto'


---********* INSERTANDO DETALLE DEL ARCHIVO 
insert into tmp_archivo(registro)
values (@w_cabecera)

-- realizamos cargue en tabla definitiva

insert into ca_reporte_reest 
select
tr_fecha_ref,
(select (select case when en_subtipo = 'P' then rtrim(ltrim(en_nombre)) + ' ' + rtrim(ltrim(p_p_apellido)) + ' ' +  rtrim(ltrim(p_s_apellido)) else en_nomlar end ) from cobis..cl_ente where en_ente = D.op_cliente),
(select rtrim(ltrim(en_tipo_ced)) from cobis..cl_ente where en_ente = D.op_cliente) ,
(select en_ced_ruc from cobis..cl_ente where en_ente = D.op_cliente),
tr_banco,
ltrim(rtrim(op_toperacion)), 
op_oficina, 
FNG, 
tr_monto,
tr_plazo,
(select c.valor from cobis..cl_tabla t, cobis..cl_catalogo c where t.codigo = c.tabla and t.tabla = 'cr_motivo_reestruct' and c.codigo = D.tr_motivo),
amh_concepto,
(select es_descripcion from ca_estado where es_codigo = D.amh_estado),
valor
from #definitiva D

insert into tmp_archivo(registro)
select convert(varchar(10),rr_fecha_tran,103) + '|' + rr_nombre_cli + '|' + rr_tipo_ide + '|' + rr_numero_ide + '|' + 
       rr_olbigacion + '|' + rr_toperacion + '|' + cast(rr_oficina as varchar) + '|' + rr_gar_FNG + '|' + cast(rr_monto_reest  as varchar)  + '|' + 
       cast(rr_plazo_reest  as varchar) + '|' + rr_motivo_reest + '|' + rr_conceptos + '|' + rr_estado_concepto + '|' + cast(rr_valor_concepto as varchar)
from   ca_reporte_reest
order  by rr_fecha_tran, rr_olbigacion

if @w_debug = 'S' select  @w_numdatos = count(1)  from ca_reporte_reest
if @w_debug = 'S' print ' ca_reporte_reest ' + cast(@w_numdatos as varchar)

--Escribir Cabecera

select @w_destino  = @w_path + @w_nombre_plano + '.txt',
       @w_errores  = @w_path + @w_nombre_plano + '.err'

select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..tmp_archivo out ' 
select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e' + @w_errores + ' -config '+ @w_s_app + 's_app.ini'

if @w_debug = 'S' print ' w_comando ' + cast(@w_comando as varchar(1000))

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    select @w_error = 2902797, @w_mensaje = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
    goto ERROR
end



return 0

ERROR:

exec sp_errorlog
@i_fecha     = @w_fecha_proceso,
@i_error     = @w_error, 
@i_usuario   = 'sa', 
@i_tran      = 7999,
@i_tran_name = @w_sp_name,
@i_cuenta    = 'PAGOSREES',
@i_anexo     = @w_mensaje,
@i_rollback  = 'S'


return 1

go
