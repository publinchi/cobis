/************************************************************************/
/*      Archivo:                ca_PlanoOinvernal.sp                    */
/*      Stored procedure:       sp_PlanoOinvernal                       */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez Burbano                   */
/*      Fecha de escritura:     Abr 2012                                */
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
/*    Genera un plano de Las obligaciones que tiene una Reestructuraciom*/
/*    conesta Observacion 'REESTRUCTURACION-BACTH-MARCA-MANUAL-Pro7123' */
/*    solicitud ORS 000403                                              */
/************************************************************************/

use cob_cartera
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'sp_PlanoOinvernal')
   drop proc sp_PlanoOinvernal
go

---JUL.31.2012 Plano poner titulos

create proc sp_PlanoOinvernal
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
@w_ors_403            int,
@w_campo1             varchar(11),
@w_campo2             varchar(2),
@w_campo3             varchar(10),
@w_gar_fng            catalogo,
@w_cabe1              varchar(200)


select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


truncate table  ca_Oper_RES_olaInver_tmp
	
--PARAMETRO  DE ENTRADA
select 	
@w_fecha_desde = @i_param1, ----fecha parametro1
@w_fecha_hasta  = @i_param2 ----fecha parametro2

---sacar Informacion para el plano

select @w_cabe1 = 'FECHA_PROCESO;FECHA_DESEMBOLSO;FECHa_REESTRUC;NRO_CREDITO;SALDO_CAPITAL;NRO_REESTRUC;OFICINA'

insert into ca_Oper_RES_olaInver_tmp
select convert(varchar(12),fc_fecha_cierre,103),
       convert(varchar(12),op_fecha_liq,103),
       convert(varchar(12),tr_fecha_mov,103),
       op_banco,
       op_monto,
       op_numero_reest,
       op_oficina
 from ca_transaccion with (nolock),
      ca_operacion with (nolock),
      cobis..ba_fecha_cierre with (nolock)
where tr_tran = 'RES'
and tr_fecha_mov between @w_fecha_desde and @w_fecha_hasta
and tr_estado <> 'RV'
and tr_secuencial >= 0
and tr_operacion = op_operacion
and tr_observacion like '%MARCA-MANUAL%'
and fc_producto = 7


select @w_ors_403 = count(1)
from  ca_Oper_RES_olaInver_tmp

if @w_ors_403 = 0
begin
 PRINT 'ATENCION!!! no hay operaciones para las fechas digitadas inicio ' + cast(@w_fecha_desde as varchar) + 'Hasta: ' + cast (@w_fecha_hasta as varchar)
 goto ERROR
end

---Poner el saldo de capital


select op_banco, 'montotmp' = sum(am_acumulado - am_pagado) 
into #saldoCAP
from ca_Oper_RES_olaInver_tmp,
     ca_amortizacion with (nolock), 
     ca_operacion with (nolock)
where NRO_CREDITO = op_banco
and  op_operacion = am_operacion
and  am_concepto = 'CAP'
group by op_banco

update ca_Oper_RES_olaInver_tmp
set SALDO_CAPITAL = montotmp
from #saldoCAP,
     ca_Oper_RES_olaInver_tmp
where op_banco = NRO_CREDITO
     

---select * from ca_Oper_RES_olaInver_tmp


--- GENERAR LOS ARCHIVOS PLANOS POR BCP
select @w_dia  = convert(varchar(2), datepart (dd, @w_fecha_cca))
select @w_mes  = convert(varchar(2), datepart (mm, @w_fecha_cca))
select @w_anio = convert(varchar(4), datepart (yy, @w_fecha_cca))

--select @w_dia = CASE WHEN convert(int, @w_dia) < 10 then '0' + @w_dia else @w_dia end
if convert(int, @w_dia) < 10
   select @w_dia = '0' + @w_dia
else
   select @w_dia = @w_dia
   
--select @w_mes = CASE WHEN convert(int, @w_mes) < 10 then '0' + @w_mes else @w_mes end
if convert(int, @w_mes) < 10
   select @w_mes = '0' + @w_mes
else
   select @w_mes = @w_mes
   
select @w_fecha_plano = convert(varchar(2), @w_dia) + convert(varchar(2), @w_mes)+ convert(varchar(4), @w_anio)


select @w_path = ba_path_destino 
from cobis..ba_batch 
where ba_arch_fuente = 'cob_cartera..sp_PlanoOinvernal'

if @@rowcount = 0 begin
   print  'ERROR no se encuentra el sp en la tabla ba_batch'
   goto ERROR
end

select @w_s_app = pa_char 
from cobis..cl_parametro 
where pa_producto = 'ADM' 
and pa_nemonico = 'S_APP'


---INICIO---Borrar archivo del directorio
select @w_comando  = 'ERASE ' + @w_path + 'TITULOMZ.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'TITULOMZ.TXT'
    print @w_comando
end

select @w_comando  = 'ERASE ' +   @w_path + 'ca_Oper_RES_olaInver_tmp' + '_' + @w_fecha_plano + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: generado anteriormente'
    print @w_comando
end

PRINT 'Inicio plano ...'
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_Oper_RES_olaInver_tmp out '
select @w_destino  = @w_path + 'ca_RES_OlaInvernal' + '_' + @w_fecha_plano + '.txt',
       @w_errores  = @w_path + 'ca_fng_16' + '_' + @w_fecha_plano + '.err'
select @w_comando = @w_cmd + @w_path + 'TITULOMZ.TXT' + ' -b5000 -c -e ' + @w_errores + ' -t";" ' + '-config '+ @w_s_app + 's_app.ini'
exec   @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error Generando archivo plano de  ca_Oper_RES_olaInver_tmp'
   print @w_comando 
   return 1
end

---Generar cabeceras
select @w_comando = 'echo ' + ''' +  @w_cabe1 + ''' + ' >> ' +  @w_path + 'ca_Oper_RES_olaInver_tmp' + '_' + @w_fecha_plano + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo cabecera'
    print @w_comando
    PRINT @w_error
end


select @w_comando = 'TYPE ' + @w_path + 'TITULOMZ.TXT >> ' + @w_path + 'ca_Oper_RES_olaInver_tmp' + '_' + @w_fecha_plano + '.txt'
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



