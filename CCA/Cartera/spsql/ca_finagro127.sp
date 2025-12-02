/************************************************************************/
/*   Stored procedure:     sp_finagro127                                */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*				         PROPOSITO				                        */
/*	  GENERACION ARCHIVOS PLANOS CON Y SIN ENCABEZADOS PARA LA FORMA127 */
/*    NOVEDADES FINAGRO                                                 */
/************************************************************************/
/*                         ACTUALIZACIONES                              */
/*    FECHA              AUTOR                     CAMBIO               */
/*    ENERO/2015         Acelis      REQ 479 FINAGRO (Emision Inicial)  */
/************************************************************************/
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_finagro127')
   drop proc sp_finagro127
go
 
create proc sp_finagro127(
   @i_param1          datetime      -- Fecha novedad
)
as                         

declare   
   @w_fecha_nov       datetime,
   @w_fecha_proceso   datetime,
   @w_anio            varchar(4),
   @w_mes             varchar(2),
   @w_dia             varchar(2),
   @w_anio_pag        varchar(4),
   @w_mes_pag         varchar(2),
   @w_dia_pag         varchar(2),
   @w_path_destino    varchar(255),
   @w_msg             varchar(255),
   @w_s_app           varchar(255),
   @w_cmd             varchar(1500),
   @w_comando         varchar(1500),
   @w_error           int,
   @w_nombre_archivo  varchar(255),
   @w_fecha_corte     varchar(10),
   @w_cant_reg_sus    int,
   @w_cant_reg_agr    int,
   @w_tot_pag_sus     numeric,
   @w_tot_pag_agr     numeric,
   @w_encabeza        varchar(2000),
   @w_detalle         varchar(2000),
   @w_fecha_habil     datetime,
   @w_fecha_sig       datetime,
   @w_ciudad_nal      int,
   @w_monto_num       numeric,
   @w_hora            varchar(25)

select @w_fecha_nov = @i_param1

select @w_cant_reg_sus = 0,
       @w_cant_reg_agr = 0,
       @w_tot_pag_sus  = 0,
       @w_tot_pag_agr  = 0

--CONSULTA FECHA DE PROCESO
select @w_hora = CONVERT(varchar, GETDATE(), 108)

select @w_hora = REPLACE(@w_hora, ':', '_')

select @w_fecha_proceso = fp_fecha 
from   cobis..ba_fecha_proceso
if @@rowcount = 0
begin
   select @w_msg = 'Error - Fecha de Proceso Nula',
          @w_error = 700002
   Goto ERROR 
end

select @w_ciudad_nal = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
if @@rowcount = 0
begin
   select @w_msg = 'Error - Consultando Parametro CIUN',
          @w_error = 700002
   Goto ERROR 
end

--VALIDAR QUE LA FECHA DE NOVEDAD SEA MAYOR A LA FECHA DE PAGO
if @w_fecha_nov > @w_fecha_proceso begin
   select  @w_msg    = 'Fecha de Novedad es Superior a la Fecha de Proceso del Sistema'
   select  @w_msg
   select  @w_error      = 700002
   goto ERROR
end

if exists(select 1 from sysobjects where name = 'tmp_plano127')
   drop table tmp_plano127

if exists(select 1 from sysobjects where name = 'tmp_reporte127')
   drop table tmp_reporte127

-- PROCESO PRINCIPAL
-- INSERCION DE LOS ABONOS APLICADOS EN LA FECHA DE NOVEDAD

select 
tipo_finagro= of_lincre,
operacion   = ab_operacion,
secuencial  = ab_secuencial_pag,
dividendo   = dtr_dividendo,
estado      = dtr_estado,
monto       = convert(numeric,dtr_monto),
estado_op   = op_estado,
tipo_red    = ab_tipo_reduccion,
cliente     = of_iden_cli,
llave       = isnull((select vo_oper_finagro from cob_cartera..ca_val_oper_finagro    where op_banco= vo_operacion),of_pagare),
monto_cuota = convert(numeric,0),
monto_pagado = convert(numeric,0)
into #abonos
from	 	cob_cartera..ca_abono 
			,cob_cartera..ca_transaccion
			,cob_cartera..ca_det_trn
			,cob_cartera..ca_opera_finagro
			,cob_cartera..ca_operacion
where op_banco           = of_pagare
and   op_operacion       = ab_operacion
and   ab_operacion       = tr_operacion
and   of_procesado       <> 'L'        --EXCLUYENDO LINEAS DE CREDITO QUE SE REALIZO CAMBIO DE LINEA
and   ab_secuencial_pag  = tr_secuencial
and   ab_estado          = 'A'
and   ab_fecha_pag       = @w_fecha_nov
and   tr_estado          in ( 'CON')
and   tr_tran            = 'PAG'
and   tr_toperacion      <> 'HIJA_FNG'
and   ab_fecha_pag       in (tr_fecha_mov,tr_fecha_ref)  --Los abonos se reportan al dia no se tienen en cuenta ajustes
and   dtr_operacion      = tr_operacion
and   dtr_estado         = 1
and   dtr_secuencial     = tr_secuencial
and   dtr_concepto       = 'CAP'
order by ab_operacion,ab_secuencial_pag,dtr_dividendo
if @@rowcount = 0 
begin 
   print 'NO HAY ABONOS APLICADOS A LA FECHA '
   return 0
end   


--calcula el vr de la cuota por dividendo


select cuota_op = am_operacion , cuota_div= am_dividendo, cuota_valor = SUM(am_cuota)  
into #cuotas
from cob_cartera..ca_amortizacion , #abonos
where   am_operacion =operacion
and     am_dividendo = dividendo 
group by am_operacion,am_dividendo

update #abonos
set monto_cuota  = cuota_valor
from #cuotas
where operacion = cuota_op
and dividendo = cuota_div

--calcula  el valor del pago 

select pago_op = dtr_operacion , pago_sec= dtr_secuencial, pago_valor = SUM(dtr_monto)  
into #pago
from cob_cartera..ca_det_trn , #abonos
where dtr_operacion = operacion
and dtr_secuencial = secuencial
and dtr_concepto <> 'VAC0' 
group by dtr_operacion,dtr_secuencial

update #abonos
set monto_pagado  = pago_valor
from #pago
where operacion = pago_op
and secuencial = pago_sec


--TOTALIZA LOS PAGOS REALIZADOS ANTICIPADAMENTE CON CANCELACION DE DEUDA
select
tipo_finagro,   operacion_can=operacion, monto= isnull(sum(monto),0), cliente,llave
into #cancelaciones
from #abonos
where  estado_op = 3
group by tipo_finagro,operacion,cliente, llave

--TOTALIZA EL VALOR PAGADO A CAPITAL POR DIVIDENDO Y POR SECUENCIAL DE PAGO NORMALES
select 
tipo_finagro, operacion,dividendo, 
secuencial,   estado,   monto=sum(monto), 
fecha_ven = convert(varchar(10),'0000/00/00',111),estado_op,cliente, llave,monto_div = convert(numeric, 0),monto_cuota,monto_pagado
into #tot_abonos_ant
from #abonos
where tipo_red = 'N'  -- Pagos Normales
group by tipo_finagro,operacion,dividendo,secuencial,estado,estado_op, cliente, llave,monto_cuota,monto_pagado

delete #tot_abonos_ant
from #cancelaciones
where operacion_can = operacion

--TOTALIZA EL VALOR PAGADO A CAPITAL POR DIVIDENDO Y POR SECUENCIAL DE PAGO EXTRAORDINARIO
select 
tipo_finagro, operacion, secuencial,cliente, llave,estado_op,
monto=sum(monto)
into #tot_abonos_ext
from #abonos
where tipo_red in  ('C','T')
group by tipo_finagro,operacion,secuencial, cliente, llave,estado_op

delete #tot_abonos_ext
from #cancelaciones
where operacion_can = operacion

--OBTIENE LAS FECHAS DE VENCIMIENTO DE LOS DIVIDENDOS
update #tot_abonos_ant
set    fecha_ven =  convert(varchar(10),di_fecha_ven,111)
from cob_cartera..ca_dividendo
where di_operacion = operacion
and   di_dividendo = dividendo

--OBTIENE LOS MONTOS A CUBRIR 
update #tot_abonos_ant
set    monto_div =  am_cuota
from  cob_cartera..ca_amortizacion
where am_operacion = operacion
and   am_dividendo = dividendo
and   am_concepto = 'CAP'

--TOTALIZA LOS PAGOS ANTICIPADOS 
select
tipo_finagro,       operacion_ant= operacion , cliente, llave, monto_ant = SUM(monto) 
into #pag_ant
from #tot_abonos_ant
where @w_fecha_nov < fecha_ven
or (@w_fecha_nov = fecha_ven and monto_cuota < monto_pagado)
group by tipo_finagro,operacion, cliente, llave

--> Generar el archivo plano 127 plano127AAAAMMDD.txt,  separado por punto y coma ';'

create table tmp_reporte127 (cadena varchar(2000) not null)
create table tmp_plano127   (cadena varchar(2000) not null)

select @w_anio_pag = convert(varchar(4),datepart(yyyy,@w_fecha_nov)),
       @w_mes_pag = right('00' + convert(varchar(2),datepart(mm,@w_fecha_nov)),2), 
       @w_dia_pag = right('00' + convert(varchar(2),datepart(dd,@w_fecha_nov)),2) 

select @w_anio = convert(varchar(4),datepart(yyyy,@w_fecha_proceso)),
       @w_mes = right('00' + convert(varchar(2),datepart(mm,@w_fecha_proceso)),2), 
       @w_dia = right('00' + convert(varchar(2),datepart(dd,@w_fecha_proceso)),2) 

select @w_fecha_corte = (@w_anio + right('00' + @w_mes,2) + right('00'+ @w_dia,2))

--CONSULTA RUTA  REPORTE  PARA CARTERA
select @w_path_destino = pp_path_destino
from   cobis..ba_path_pro
where  pp_producto = 7

if @@rowcount = 0 Begin
   select @w_msg = 'NO EXISTE RUTA DE LISTADOS PARA CARTERA'
   GOTO ERROR
End 

--CONSULTA RUTA PARA EJECUCION BCP
select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'
if @@rowcount = 0 Begin
   select @w_msg = 'NO EXISTE RUTA S_APP',
          @w_error = 700008
   GOTO ERROR
End 

-- INICIA PROCESO DE GENERACION DE INFORMACION

select @w_detalle = 'GENERAL;SUCURSAL;LINEA;NRO DE OPERACION;VR ABONO;FECHA DE PAGO DDMMAAAA;CEDULA;%DE PAGO;FORMA DE AMORTIZAR;MOTIVO'

select @w_cant_reg_sus = @w_cant_reg_sus + isnull((select COUNT(1) from #tot_abonos_ext
                         where   tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'S')),0)
select @w_cant_reg_sus = @w_cant_reg_sus + isnull( (select COUNT(1) from #pag_ant
                         where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'S')),0)
select @w_cant_reg_sus = @w_cant_reg_sus + isnull( (select COUNT(1) from #cancelaciones
                         where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'S')),0)


select @w_cant_reg_agr = @w_cant_reg_agr + isnull((select COUNT(1) from #tot_abonos_ext
                         where   tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'A')),0)
select @w_cant_reg_agr = @w_cant_reg_agr + isnull((select COUNT(1) from #pag_ant
                         where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'A')),0)
select @w_cant_reg_agr = @w_cant_reg_agr + isnull((select COUNT(1) from #cancelaciones
                         where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'A')),0)


select @w_tot_pag_sus    = @w_tot_pag_sus + isnull((select sum(monto) from #tot_abonos_ext
                           where   tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'S')),0)

select @w_tot_pag_sus    = @w_tot_pag_sus +  isnull((select sum(monto_ant) from #pag_ant
                           where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'S')),0)

select @w_tot_pag_sus    = @w_tot_pag_sus + isnull((select sum(monto) from #cancelaciones
                           where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'S')),0)
                           

select @w_tot_pag_agr    = @w_tot_pag_agr + isnull((select sum(monto) from #tot_abonos_ext
                           where    tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'A')),0)
select @w_tot_pag_agr    = @w_tot_pag_agr  + isnull((select sum(monto_ant) from #pag_ant
                           where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'A')),0)
select @w_tot_pag_agr    = @w_tot_pag_agr  + isnull((select sum(monto) from #cancelaciones
                           where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'A')),0)


--> ***REPORTE SUSTITUTIVAS ***
truncate  table tmp_plano127

-- Aplicacion a todas las cuotas 
insert into tmp_plano127 (cadena)
select '1;752;' +  convert(varchar,tipo_finagro) + ';' +  convert(varchar,llave) + ';' +  convert(varchar,monto) + ';'  + CONVERT(varchar,@w_dia_pag)+  CONVERT(varchar,@w_mes_pag) + CONVERT(varchar,@w_anio_pag)   + ';' + convert(varchar,cliente)  + ';100.00;1;11;0.00'
from #tot_abonos_ext  
where   tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'S')
if @@error <> 0  begin
   select @w_msg = 'ERROR INSERTA Todas las Ctas'
   goto ERROR
end


-- Aplicacion a primeras cuotas
insert into tmp_plano127 (cadena)
select '1;752;' +  convert(varchar,tipo_finagro) + ';' +  convert(varchar,llave) + ';' +  convert(varchar,monto_ant) + ';'  + CONVERT(varchar,@w_dia_pag)+  CONVERT(varchar,@w_mes_pag) + CONVERT(varchar,@w_anio_pag) + ';' + convert(varchar,cliente) + ';100.00;2;11;0.00'
from #pag_ant  
where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'S')
if @@error <> 0  begin
   select @w_msg = 'ERROR INSERTA Primeras Ctas'
   goto ERROR
end


--Cancelaciones
insert into tmp_plano127 (cadena)
select '1;752;' +  convert(varchar,tipo_finagro) + ';' +  convert(varchar,llave) + ';' +  convert(varchar,monto) + ';'  + CONVERT(varchar,@w_dia_pag) + CONVERT(varchar,@w_mes_pag) +  CONVERT(varchar,@w_anio_pag) + ';' + convert(varchar,cliente) + ';100.00;0;21;0.00'
from #cancelaciones  
where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'S')
if @@error <> 0  begin
   select @w_msg = 'ERROR INSERTA Cancelaciones'
   goto ERROR
end


select @w_nombre_archivo = @w_path_destino + 'rep127Sustitutivas_' + @w_fecha_corte + '_' + @w_hora + '.txt' 

truncate table tmp_reporte127 --encabezado para sustitutivas
select @w_encabeza = '(*);PCXSUC;FECHA PROCESO DDMMAAAA;CANTIDAD REGISTROS;TOTAL PAGOS;'
insert into tmp_reporte127 (cadena) values (@w_encabeza)
if @@error <> 0  begin
   select @w_msg = 'ERROR Encabezado Sust.'
   goto ERROR
end

select @w_encabeza = '*;752;'  + CONVERT(varchar,@w_dia)+  CONVERT(varchar,@w_mes) + CONVERT(varchar,@w_anio) + ';' + CONVERT(varchar,@w_cant_reg_sus) + ';' + CONVERT(varchar,@w_tot_pag_sus) + ';'
insert into tmp_reporte127 (cadena)  values (@w_encabeza)
if @@error <> 0  begin
   select @w_msg = 'ERROR Encabezado Rep Sust.'
   goto ERROR
end

insert into tmp_reporte127 (cadena) values (@w_detalle)
if @@error <> 0  begin
   select @w_msg = 'ERROR Detalle Encab. Sust.'
   goto ERROR
end


insert into tmp_reporte127 (cadena) select * from tmp_plano127
if @@error <> 0  begin
   select @w_msg = 'ERROR Datos Detalle Sust'
   goto ERROR
end

select @w_cmd     =  'bcp "select cadena from cob_cartera..tmp_reporte127  " queryout ' 
select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t";" -T -S'+ @@servername + ' -ePLANO127.err' 

print  @w_comando

exec @w_error = xp_cmdshell @w_comando

If @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP Reporte Sustitutivas ' + @w_comando
   Goto ERROR 
End                            

--> ***PLANO SUSTITUTIVAS ***       

select @w_nombre_archivo = @w_path_destino + 'pla127Sustitutivas_' + @w_fecha_corte + '_' + @w_hora + '.txt' 

truncate table tmp_reporte127 ----encabezado para sustitutivas en el plano
select @w_encabeza = '*;752;'  + CONVERT(varchar,@w_dia)+  CONVERT(varchar,@w_mes) + CONVERT(varchar,@w_anio) +  ';'+ CONVERT(varchar,@w_cant_reg_sus) + ';' + CONVERT(varchar,@w_tot_pag_sus) + ';'
insert into tmp_reporte127 (cadena)  values (@w_encabeza)
if @@error <> 0  begin
   select @w_msg = 'ERROR Encab Plano. Sust.'
   goto ERROR
end


insert into tmp_reporte127 (cadena) select * from tmp_plano127
if @@error <> 0  begin
   select @w_msg = 'ERROR Detalle Plano. Sust.'
   goto ERROR
end

select @w_cmd     =  'bcp "select cadena from cob_cartera..tmp_reporte127  " queryout ' 
select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t";" -T -S'+ @@servername + ' -ePLANO127.err' 


exec @w_error = xp_cmdshell @w_comando

If @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP Plano Sustitutivas ' + @w_comando
   Goto ERROR 
End                            
                                   
--> *** REPORTE AGROPECUARIAS  ***

-- Consulta siguiente dia habil

select @w_fecha_sig  = dateadd(day,1,@w_fecha_nov)
exec   sp_dia_habil
       @i_fecha    = @w_fecha_sig,
       @i_ciudad   = @w_ciudad_nal,
       @o_fecha    = @w_fecha_habil out

select @w_anio_pag = convert(varchar(4),datepart(yyyy,@w_fecha_habil)),
       @w_mes_pag = right('00' + convert(varchar(2),datepart(mm,@w_fecha_habil)),2), 
       @w_dia_pag = right('00' + convert(varchar(2),datepart(dd,@w_fecha_habil)),2) 

truncate  table tmp_plano127
-- Aplicacion a todas las cuotas 
insert into tmp_plano127 (cadena)
select '1;752;' +  convert(varchar,tipo_finagro) + ';' +  convert(varchar,llave) + ';' +  convert(varchar,monto) + ';'  + CONVERT(varchar,@w_dia_pag)+  CONVERT(varchar,@w_mes_pag) + CONVERT(varchar,@w_anio_pag) + ';' + convert(varchar,cliente) + ';100.00;1;11;0.00'
from #tot_abonos_ext  
where    tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'A')
if @@error <> 0  begin
   select @w_msg = 'ERROR Plano Todas las Ctas'
   goto ERROR
end


-- Aplicacion a Primeras cuotas 
insert into tmp_plano127 (cadena)
select '1;752;' +  convert(varchar,tipo_finagro) + ';' +  convert(varchar,llave) + ';' +  convert(varchar,monto_ant) + ';'  + CONVERT(varchar,@w_dia_pag)+  CONVERT(varchar,@w_mes_pag) + CONVERT(varchar,@w_anio_pag) + ';' + convert(varchar,cliente) + ';100.00;2;11;0.00'
from #pag_ant  
where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'A')
if @@error <> 0  begin
   select @w_msg = 'ERROR Plano Primeras Ctas'
   goto ERROR
end

--Cancelaciones
insert into tmp_plano127 (cadena)
select '1;752;' +  convert(varchar,tipo_finagro) + ';' +  convert(varchar,llave ) + ';' +  convert(varchar,monto) + ';'  + CONVERT(varchar,@w_dia_pag)+ CONVERT(varchar,@w_mes_pag) + CONVERT(varchar,@w_anio_pag) + ';' + convert(varchar,cliente) + ';100.00;0;21;0.00'
from #cancelaciones  
where  tipo_finagro in  (select  codigo  from cob_credito..cr_corresp_sib where tabla = 'T301' and codigo_sib = 'A')
if @@error <> 0  begin
   select @w_msg = 'ERROR Plano Cancelaciones'
   goto ERROR
end

select @w_nombre_archivo = @w_path_destino + 'rep127Agropecuarias_' + @w_fecha_corte + '_' + @w_hora + '.txt' 

truncate table tmp_reporte127  -- encabezado agropecuarias
select @w_encabeza = '(*);PCXSUC;FECHA PROCESO DDMMAAAA;CANTIDAD REGISTROS;TOTAL PAGOS;'
insert into tmp_reporte127 (cadena) values (@w_encabeza)
if @@error <> 0  begin
   select @w_msg = 'ERROR Reporte Enc Agropec.'
   goto ERROR
end

select @w_encabeza = '*;752;'  + CONVERT(varchar,@w_dia) + CONVERT(varchar,@w_mes) +  CONVERT(varchar,@w_anio) + ';' + CONVERT(varchar,@w_cant_reg_agr) + ';' + CONVERT(varchar,@w_tot_pag_agr) + ';'

insert into tmp_reporte127 (cadena)  values (@w_encabeza)
if @@error <> 0  begin
   select @w_msg = 'ERROR Reporte Datos Enc Agropec.'
   goto ERROR
end

insert into tmp_reporte127 (cadena) values (@w_detalle)
if @@error <> 0  begin
   select @w_msg = 'ERROR Reporte Detalle Enc Agropec.'
   goto ERROR
end


insert into tmp_reporte127 (cadena) select * from tmp_plano127
if @@error <> 0  begin
   select @w_msg = 'ERROR Reporte Datos Detalle Agropec.'
   goto ERROR
end

select @w_cmd     =  'bcp "select cadena from cob_cartera..tmp_reporte127  " queryout ' 
select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t";" -T -S'+ @@servername + ' -ePLANO127.err' 


exec @w_error = xp_cmdshell @w_comando

If @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP Agropecuarias ' + @w_comando
   Goto ERROR 
End                                   

--> ***PLANO AGROPECUARIAS ***       

select @w_nombre_archivo = @w_path_destino + 'pla127Agropecuarias_' + @w_fecha_corte + '_' + @w_hora + '.txt' 

truncate table tmp_reporte127  --  encabezado agropecuarias
select @w_encabeza = '*;752;'  + CONVERT(varchar,@w_dia)+  CONVERT(varchar,@w_mes) + CONVERT(varchar,@w_anio) + ';' + CONVERT(varchar,@w_cant_reg_agr) + ';' + CONVERT(varchar,@w_tot_pag_agr) + ';'

insert into tmp_reporte127 (cadena)  values (@w_encabeza)
if @@error <> 0  begin
   select @w_msg = 'ERROR Plano Enc Agropec.'
   goto ERROR
end


insert into tmp_reporte127 (cadena) select * from tmp_plano127
if @@error <> 0  begin
   select @w_msg = 'ERROR Reporte Detalle Agropec.'
   goto ERROR
end


select @w_cmd     =  'bcp "select cadena from cob_cartera..tmp_reporte127  " queryout ' 
select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t";" -T -S'+ @@servername + ' -ePLANO127.err' 

exec @w_error = xp_cmdshell @w_comando

If @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP Plano Agropecuarias ' + @w_comando
   Goto ERROR 
End                            


return 0

ERROR:
   print @w_msg 
   select @w_msg = 'sp_finagro127 ' + @w_msg
   exec @w_error = sp_errorlog
        @i_fecha      = @w_fecha_proceso,
        @i_error      = @w_error,
        @i_usuario    = 'sa',
        @i_tran       = 7086,
        @i_tran_name  = @w_msg,
        @i_rollback   = 'N'
   return @w_error

go

