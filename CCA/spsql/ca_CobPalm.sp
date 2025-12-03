/************************************************************************/
/*      Archivo:                ca_CobPalm.sp                           */
/*      Stored procedure:       sp_gestion_cobranza_palm                */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez Burbano                   */
/*      Fecha de escritura:     May 2012                                */
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
/*    Genera un plano de la gestion de cobranza Realizada enlapalm por  */
/*    los oficiles de Oficina      ORS     418   batch 7955             */
/************************************************************************/

use cob_cartera
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'sp_gestion_cobranza_palm')
   drop proc sp_gestion_cobranza_palm
go

---JUNIO.15.2012 Plano

create proc sp_gestion_cobranza_palm
   @i_param1  varchar(10),  --fecha desde
   @i_param2  varchar(10)  --fecha hasta

as

declare 
@w_sp_name            varchar(32),
@w_error              int,
@w_s_app              varchar(250),
@w_cmd                varchar(250),
@w_path               varchar(250),
@w_comando            varchar(500),
@w_batch              int,
@w_errores            varchar(255),
@w_destino            varchar(255),
@w_dia                varchar(2),
@w_mes                varchar(2),
@w_anio               varchar(4),
@w_fecha_plano        varchar(8),
@w_fecha_cca          datetime,
@w_fecha_desde        datetime,
@w_fecha_hasta        datetime,
@w_ors_418             int,
@w_campo1             varchar(11),
@w_campo2             varchar(2),
@w_campo3             varchar(10),
@w_gar_fng            catalogo,
@w_cabe1              varchar(200)


select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


truncate table  ca_gestion_cobranza_palm_tmp
	
--PARAMETRO  DE ENTRADA
select 	
@w_fecha_desde = @i_param1, ----fecha parametro1
@w_fecha_hasta  = @i_param2 ----fecha parametro2

---sacar Informacion para el plano

select * 
into #aux2
from cob_credito..cr_gestion_cobro with (nolock)
where gc_tipo_gestor = 'E'
and  gc_id_gestor is not null
and     ascii(substring(gc_id_gestor,1,1)) between 48 and 58
and gc_fecha_ges between  @w_fecha_desde and @w_fecha_hasta

select 
   'Ofi'            =  op_oficina,
   'NomOFi'         = (select of_nombre from cobis..cl_oficina 
                      where of_oficina = P.op_oficina),
   'IDEjecutivo'    =  gc_id_gestor,  
   'nombreEjecutivo'=  (select fu_nombre from cobis..cl_funcionario 
                        where fu_funcionario = O.oc_funcionario ),
   'banco'          =  gc_op_banco ,
   'NomCliente'     =  gc_nombre,
   'ESTOperativo'   =  op_estado,
   'EStCobranza'    =  op_estado_cobranza,

   'IndGestion'     =  (select  b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                       where a.codigo = b.tabla
                       and  a.tabla = 'cr_tipo_cobro'
                       and  b.codigo = A.gc_tipo_cobro),
   'Gestion'        =    isnull(gc_comentario,'NO TIENE')
into #seleccion   
from #aux2 A, 
      cobis..cc_oficial O,
      cob_cartera..ca_operacion P with (nolock)
where  ltrim(rtrim(gc_id_gestor)) = convert(varchar(30), oc_oficial)
and    gc_op_banco = op_banco

insert into ca_gestion_cobranza_palm_tmp
select  Ofi, NomOFi,IDEjecutivo, nombreEjecutivo,banco,NomCliente,0,0,0,0,0,ESTOperativo,EStCobranza,IndGestion, Gestion        
from #seleccion

select @w_ors_418 = count(1)
from  ca_gestion_cobranza_palm_tmp

if @w_ors_418 = 0
begin
 PRINT 'ATENCION!!! no hay operaciones para las fechas digitadas inicio ' + cast(@w_fecha_desde as varchar) + 'Hasta: ' + cast (@w_fecha_hasta as varchar)
 goto ERROR
end


select @w_cabe1 = 'COD_OFICINA;NOM_OFICINA;EJECUTIVO;NOM_EJECUTIVO;BANCO;NOM_CLIENTE;DIAS_IMO;SALDO_CAP;SALDO_VENCIDO;SALDO_CANCELACION;VALOR_CUOTA;ESTADO_OPERATIVO;ESTADO_COBRANZA;INDICADOR_GESTION;GESTION'

---poner Dias deIMO

select op_operacion,nro_banco= op_banco,'div_vencido'=isnull(min(di_dividendo),0)
into #divVen
from ca_gestion_cobranza_palm_tmp,
     ca_dividendo with (nolock), 
     ca_operacion with (nolock)
where banco = op_banco
and  op_operacion = di_operacion
and  di_estado  = 2
group by op_operacion,op_banco

update ca_gestion_cobranza_palm_tmp
set dias_imo = datediff(dd,di_fecha_ven,@w_fecha_cca)
from #divVen,
     ca_gestion_cobranza_palm_tmp,
     ca_dividendo with(nolock)
where banco     = nro_banco
and   op_operacion = di_operacion
and   di_dividendo = div_vencido
and   div_vencido > 0

---poner el saldo de capital

select op_banco, 'montotmp' = sum(am_acumulado - am_pagado) 
into #saldoCAP
from ca_gestion_cobranza_palm_tmp,
     ca_amortizacion with (nolock), 
     ca_operacion with (nolock)
where banco = op_banco
and  op_operacion = am_operacion
and  am_concepto = 'CAP'
group by op_banco



update ca_gestion_cobranza_palm_tmp
set saldo_cap = montotmp
from #saldoCAP,
     ca_gestion_cobranza_palm_tmp
where op_banco = banco

---poner el saldo total

select op_banco, 'montoCAN' = sum(am_acumulado - am_pagado) 
into #saldoTOT
from ca_gestion_cobranza_palm_tmp,
     ca_amortizacion with (nolock), 
     ca_operacion with (nolock)
where banco = op_banco
and  op_operacion = am_operacion
group by op_banco


update ca_gestion_cobranza_palm_tmp
set saldo_cancelacion = montoCAN
from #saldoTOT,
     ca_gestion_cobranza_palm_tmp
where op_banco = banco

---poner el saldo  VEncido

select op_banco, 'montoVEN' = isnull(sum(am_acumulado - am_pagado) ,0)
into #saldoVEN
from ca_gestion_cobranza_palm_tmp,
     ca_amortizacion with (nolock), 
     ca_operacion with (nolock),
     ca_dividendo with (nolock)
where banco = op_banco
and  op_operacion = am_operacion
and  op_operacion = di_operacion
and  am_operacion = di_operacion
and  di_dividendo = am_dividendo
and di_estado = 2
group by op_banco

update ca_gestion_cobranza_palm_tmp
set saldo_vencido = montoVEN
from #saldoVEN,
     ca_gestion_cobranza_palm_tmp
where op_banco = banco

---poner valor CUOTA

select op_operacion,nro_banco= op_banco,'div_ult'=isnull(max(di_dividendo),0)
into #divultimo
from ca_gestion_cobranza_palm_tmp,
     ca_dividendo with (nolock), 
     ca_operacion with (nolock)
where banco = op_banco
and  op_operacion = di_operacion
and  di_estado  in (1,2)
group by op_operacion,op_banco

select nro_banco,oper = di_operacion,div_ult,'valCuota'=isnull(sum(am_cuota),0)
into #valCuota
from #divultimo,
     ca_gestion_cobranza_palm_tmp,
     ca_dividendo with(nolock),
     ca_amortizacion with(nolock)
where banco     = nro_banco
and   op_operacion = di_operacion
and   di_dividendo = div_ult
and   am_operacion = di_operacion
and   di_dividendo = am_dividendo
group by nro_banco,di_operacion,div_ult


update ca_gestion_cobranza_palm_tmp
set valor_cuota =  valCuota
from #valCuota,
     ca_gestion_cobranza_palm_tmp,
     ca_dividendo with(nolock),
     ca_amortizacion with(nolock)
where banco     = nro_banco
and   oper         = di_operacion
and   di_dividendo = div_ult
and   am_operacion = di_operacion
and   di_dividendo = am_dividendo


--- GENERAR LOS ARCHIVOS PLANOS POR BCP
select @w_dia  = convert(varchar(2), datepart (dd, @w_fecha_cca))
select @w_mes  = convert(varchar(2), datepart (mm, @w_fecha_cca))
select @w_anio = convert(varchar(4), datepart (yy, @w_fecha_cca))

--select @w_dia = CASE WHEN convert(int, @w_dia) < 10 then '0' + @w_dia else @w_dia end
if convert(int, @w_dia) < 10
   select @w_dia = '0' + @w_dia 
else
   select  @w_dia = @w_dia

--select @w_mes = CASE WHEN convert(int, @w_mes) < 10 then '0' + @w_mes else @w_mes end
if convert(int, @w_mes) < 10
   select @w_mes = '0' + @w_mes 
else
   select  @w_mes = @w_mes

select @w_fecha_plano = convert(varchar(2), @w_dia) + convert(varchar(2), @w_mes)+ convert(varchar(4), @w_anio)

select @w_path = ba_path_destino 
from cobis..ba_batch 
where ba_arch_fuente = 'cob_cartera..sp_gestion_cobranza_palm'

if @@rowcount = 0 begin
   print  'ERROR no se encuentra el sp en la tabla ba_batch'
   goto ERROR
end
---PRINT 'ba_path_destino : ' + cast(@w_path as varchar)
select @w_s_app = pa_char 
from cobis..cl_parametro 
where pa_producto = 'ADM' 
and pa_nemonico = 'S_APP'

---Borrar archivo del directorio
select @w_comando  = 'ERASE ' + @w_path + 'TITULOMZ.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'TITULOMZ.TXT'
    print @w_comando
end

select @w_comando  = 'ERASE ' +   @w_path + 'ca_plaGestion_palm' + '_' + @w_fecha_plano + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: generado anteriormente'
    print @w_comando
end

---PRINT 'Inicio plano ...'
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_gestion_cobranza_palm_tmp out '
select @w_destino  = @w_path + 'ca_plaGestion_palm' + '_' + @w_fecha_plano + '.txt',
       @w_errores  = @w_path + 'ca_plaGestion_palm' + '_' + @w_fecha_plano + '.err'
select @w_comando = @w_cmd + @w_path + 'TITULOMZ.TXT' + ' -b5000 -c -e ' + @w_errores + ' -t";" ' + '-config '+ @w_s_app + 's_app.ini'

exec   @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error Generando archivo plano de  ca_gestion_cobranza_palm_tmp'
   print @w_comando 
   return 1
end

---Generar cabeceras
select @w_comando = 'echo ' + ''' +  @w_cabe1 + ''' + ' >> ' +  @w_path + 'ca_plaGestion_palm' + '_' + @w_fecha_plano + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo cabecera'
    print @w_comando
    PRINT @w_error
end

select @w_comando = 'TYPE ' + @w_path + 'TITULOMZ.TXT >> ' + @w_path + 'ca_plaGestion_palm' + '_' + @w_fecha_plano + '.txt'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error uniendo archivos'
    print @w_comando
    PRINT @w_error
end

select @w_comando  = 'ERASE ' + @w_path + 'TITULOMZ.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'TITULOMZ.TXT'
    print @w_comando
end

---Fingenerar cabecera



ERROR:

return 0
   
go



