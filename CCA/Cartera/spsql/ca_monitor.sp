/************************************************************************/                                                             
/*      Archivo:                ca_monitor.sp                           */                                                             
/*      Stored procedure:       sp_plano_condonacion                    */                                                             
/*      Base de datos:          cob_credito                             */                                                             
/*      Producto:               Credito                                 */                                                             
/*      Disenado por:           RRB                                     */                                                             
/*      Fecha de escritura:     Agosto - 2009                           */                                                             
/************************************************************************/                                                             
/*                              IMPORTANTE                              */                                                             
/*      Este programa es parte de los paquetes bancarios propiedad de   */                                                             
/*      'MACOSA', representantes exclusivos para el Ecuador de la       */                                                             
/*      'NCR CORPORATION'.                                              */                                                             
/*      Su uso no autorizado queda expresamente prohibido asi como      */                                                             
/*      cualquier alteracion o agregado hecho por alguno de sus         */                                                             
/*      usuarios sin el debido consentimiento por escrito de la         */                                                             
/*      Presidencia Ejecutiva de MACOSA o su representante.             */                                                             
/************************************************************************/                                                             
/*                              PROPOSITO                               */                                                             
/*      Monitor                                                         */                                                             
/************************************************************************/                                                             
/*                              MODIFICACIONES                          */                                                             
/* FECHA           AUTOR                RAZON                           */                                                             
/*                                                                      */                                                             
/************************************************************************/                                                             
use cob_cartera                                                                                                                        
go                                                                                                                                                                                                                           
                                                                                                                                
if exists (SELECT 1 FROM sysobjects WHERE name = 'sp_cartera_monitor')                                                              
   drop proc sp_cartera_monitor
go                


---Inc. 31742 partiendo de la version 10  OCt-07-2011
                                                                                                            
create proc sp_cartera_monitor                                                                                                   
   @i_param1       datetime,
   @i_param2       datetime      
                                                                                                                                   
as declare     
   @w_fecha_proc      datetime,
   @w_fecha_archivo   varchar(10),
   @w_error           int,
   @w_msg             varchar(255),
   @w_otros           money,
   @w_apercred        smallint,
   @w_montoaper       money,
   @w_parametro_apecr catalogo,
   @w_s_app           varchar(250),
   @w_cmd             varchar(250),
   @w_path            varchar(250),
   @w_comando         varchar(500),
   @w_batch           int,
   @w_errores         varchar(255),
   @w_destino         varchar(255),
   @w_destino_dat     varchar(255),
   @w_destino_cab     varchar(255),
   @w_col_id          int,
   @w_columna         varchar(50),
   @w_cabecera        varchar(400),
   @w_nombre_plano    varchar(200)
    

select @w_path = ba_path_destino 
from cobis..ba_batch 
where ba_arch_fuente = 'cob_cartera..sp_justificacion_finan'


select @w_s_app = pa_char 
from cobis..cl_parametro 
where pa_producto = 'ADM' 
and pa_nemonico = 'S_APP'
            
select @w_fecha_proc = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7 

select @w_parametro_apecr = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'APECR'   

select @w_fecha_archivo = convert(varchar(10),getdate(),112)

truncate table  ca_monitor_1

create table #ca_monitor_1 (
mot_fecha_gen      varchar(10) null,
mot_oficina        int         null,
mot_desc_oficina   varchar(64) null,
mot_ced_ruc        cuenta      null,
mot_nombre         varchar(64) null,
mot_fecha_liq      varchar(10) null,
mot_banco          cuenta      null,
mot_monto          money       null,
mot_monto_concepto money       null,
mot_saldo          money       null,
mot_clase          smallint    null,
mot_dias_plazo     int         null,
mot_tasa           float       null,
mot_tasa_nom       float       null,
mot_operacion      int         null,
mot_secuencial     int         null,
mot_desembolso     smallint    null,
mot_tipo_pres      char(1)     null,
mot_tipo_dese      catalogo    null,
mot_tramite        int         null,
mot_destino        char(100)   null,
mot_ced_benef      cuenta      null,
mot_nombre_benef   varchar(64) null 
)

-- MONITOR 1                                                                                                                    

insert into #ca_monitor_1
select distinct
convert(varchar(10),@w_fecha_proc,112),
op_oficina,
of_nombre,
en_ced_ruc,
op_nombre,
convert(varchar(10),op_fecha_liq,112),
op_banco,
op_monto,
ro_valor,
0,
op_clase,
(select td_factor * op_plazo from ca_tdividendo where td_tdividendo =  op_tplazo),
ro_porcentaje_efa,
ro_porcentaje,
op_operacion,
tr_secuencial,
dm_desembolso,
case when op_anterior is null then 'N' 
     when op_anterior = 'PRE' then 'N'
     else 'R' end,
ro_concepto,
op_tramite,
case when dm_destino_economico is null then ''
else dm_destino_economico + '-' + valor end,
(select en_ced_ruc from cobis..cl_ente where en_ente=dm_ente_benef),
(select p_p_apellido + ' ' + p_s_apellido + ' ' +en_nombre   from cobis..cl_ente where en_ente=dm_ente_benef)
from ca_operacion inner join ca_rubro_op on op_operacion = ro_operacion
inner join cobis..cl_ente on op_cliente   = en_ente
inner join cobis..cl_oficina on op_oficina = of_oficina
inner join ca_transaccion on tr_operacion = op_operacion
inner join ca_desembolso on  op_operacion = dm_operacion
inner join cobis..cl_catalogo on dm_destino_economico = cobis..cl_catalogo.codigo
inner join cobis..cl_tabla	on  cobis..cl_tabla.codigo = cobis..cl_catalogo.tabla
where op_estado not in (0,99,6)
and   op_fecha_liq >= @i_param1
and   op_fecha_liq <= @i_param2
and   tr_tran = 'DES'
and   tr_estado <> 'RV'
and   tr_secuencial > 0
and   cobis..cl_tabla.tabla = 'ca_destino_economico'
and   ro_concepto = 'GMF'

union

select distinct
convert(varchar(10),@w_fecha_proc,112),
op_oficina,
of_nombre,
en_ced_ruc,
op_nombre,
convert(varchar(10),op_fecha_liq,112),
op_banco,
op_monto,
dm_monto_mn,
0,
op_clase,
(select td_factor * op_plazo from ca_tdividendo where td_tdividendo =  op_tplazo),
ro_porcentaje_efa,
ro_porcentaje,
op_operacion,
tr_secuencial,
dm_desembolso,
case when op_anterior is null then 'N' 
     when op_anterior = 'PRE' then 'N'
     else 'R' end,
dm_producto,
op_tramite,
'',
'',
''
from ca_operacion inner join ca_rubro_op on op_operacion = ro_operacion
inner join cobis..cl_ente on op_cliente   = en_ente
inner join cobis..cl_oficina on op_oficina = of_oficina
inner join ca_transaccion on tr_operacion = op_operacion
inner join ca_desembolso on  op_operacion = dm_operacion
where ro_concepto  = 'INT'
and   op_estado not in (0,99,6)
and   op_fecha_liq >= @i_param1
and   op_fecha_liq <= @i_param2
and   tr_tran = 'DES'
and   tr_estado <> 'RV'
and   tr_secuencial > 0

-- Saldo Operacion
select 
operacion = am_operacion,
saldo = sum(am_acumulado + am_gracia - am_pagado)
into #saldo
from ca_amortizacion, #ca_monitor_1
where am_operacion = mot_operacion
and am_concepto = 'CAP'
group by am_operacion

update #ca_monitor_1
set mot_saldo = saldo
from #saldo
where mot_operacion = operacion

-- Desgloce Otros Conceptos Desembolso

-- Copia registro Plantilla
select * into #otros from #ca_monitor_1
where mot_desembolso = 1 and mot_tipo_dese <> 'GMF'

-- Actualiza a OTROS registro plantilla
update #otros set 
mot_tipo_dese = 'OTROS',
mot_monto_concepto = 0

-- Inserta en tabla de trabajo
insert into #ca_monitor_1
select * from #otros

select distinct operacion_s=mot_operacion, secuencial_s=mot_secuencial
into #secuenciales
from #ca_monitor_1

-- Selecciona valores OTROS por operacion
select operacion_o=dtr_operacion , otros_o = sum(dtr_monto_mn)
into #otros_sal
from ca_det_trn, #secuenciales
where dtr_operacion  = operacion_s
and   dtr_secuencial = secuencial_s
and   dtr_concepto  not in (select mot_tipo_dese from #ca_monitor_1 where mot_operacion = dtr_operacion)
and   dtr_concepto not in ('CAP')
and   dtr_estado <> 3
group by dtr_operacion

-- Calculo Apercred (saber si aplica en el desembolso)
select operacion_a=mot_operacion , porcentaje=ro_porcentaje, monto_a = count(1) * ro_porcentaje
into #apercred
from #ca_monitor_1, cob_credito..cr_deudores, cob_cartera..ca_rubro_op
where mot_tramite   = de_tramite
and   mot_operacion = ro_operacion
and   ro_concepto   = @w_parametro_apecr
and   mot_tipo_dese = 'OTROS'
and   de_cobro_cen  = 'N'
group by mot_operacion, ro_porcentaje

/*-- Resta apercred ya pagado antes del desembolso
update #otros_sal set 
otros_o = otros_o - monto_a
from #apercred
where operacion_o = operacion_a
and   otros_o > 0*/

-- Inserta en tabla de trabajo
update #ca_monitor_1 set
mot_monto_concepto = otros_o
from #otros_sal
where operacion_o   = mot_operacion
and   mot_tipo_dese = 'OTROS'

-- Elimina conceptos con valor CERO
delete #ca_monitor_1
where mot_monto_concepto = 0

-- Tabla definitiva

insert into ca_monitor_1

select 
mot_fecha_gen,
mot_oficina,
mot_desc_oficina,
mot_ced_ruc,
mot_nombre,
mot_fecha_liq,
mot_banco,
mot_monto,
mot_monto_concepto,
mot_clase,
mot_dias_plazo,
mot_tasa, 
mot_tasa_nom, 
mot_tipo_pres,
mot_tipo_dese,
mot_destino,
mot_ced_benef,
mot_nombre_benef 

from #ca_monitor_1 




---------------------------------------------------------------------------------
--Generar Archivo Plano req 00264 ceh Desembolsos GMF
---------------------------------------------------------------------------------
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_monitor_1 out '
select @w_destino  = @w_path + 'ca_monitor_88' + '_' + @w_fecha_archivo + '.txt'
select @w_destino_cab = @w_path + 'ca_monitor_cabecera.txt' 
select @w_comando = @w_cmd + @w_path + 'ca_monitor_88.txt -c -e ' + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec   @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error Generando archivo'
   print @w_comando 
   return 1
end


--Generar Archivo de Cabeceras  
   select @w_col_id   = 0,
          @w_columna  = '',
          @w_cabecera = ''
   while 1 = 1 begin
      set rowcount 1
      select @w_columna = c.name,
             @w_col_id  = c.colid
      from sysobjects o, syscolumns c
      where o.id    = c.id
      and   o.name  = 'ca_monitor_1'
      and   c.colid > @w_col_id
      order by c.colid
      if @@rowcount = 0 begin
         set rowcount 0
         break
      end
      select @w_cabecera = @w_cabecera + @w_columna + '^|'
   end

--Escribir Cabecera
   select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_destino_cab
   exec @w_error = xp_cmdshell @w_comando
   
   if @w_error <> 0 begin
   print 'Error Generando archivo de Cabecera'
   print @w_comando 
   return 1
   end

   select @w_destino_dat = @w_path + 'ca_monitor_88.txt' 
   
   select @w_comando = 'type ' + @w_destino_cab + ' ' + @w_destino_dat + '>' + @w_destino
   exec @w_error = xp_cmdshell @w_comando
   
   if @w_error <> 0 begin
   print 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   print @w_comando 
   return 1
   end   

/*** ELIMINACION DE ARCHIVO DE CABECERA Y DATOS  ***/

select
@w_comando = 'rm ' + @w_destino_cab 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando archivo final'
   print @w_comando 
   return 1
   end
   

select
@w_comando = 'rm ' + @w_destino_dat 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando archivo final'
   print @w_comando 
   return 1
   end

-- FIN CEH REQ264         
return 0
go                                                                                                                   