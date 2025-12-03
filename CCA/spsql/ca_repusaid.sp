/*ca_repusaid.sp*********************************************************/
/*  Archivo:                         ca_repusaid.sp                     */
/*  Stored procedure:                sp_reporte_usaid_sem               */
/*  Base de datos:                   cob_cartera                        */
/*  Producto:                        Credito                            */
/*  Disenado por:                    Johan Ardila                       */
/*  Fecha de escritura:              02-02-2011                         */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA', representantes exclusivos para el Ecuador de NCR          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Generar REPORTE USAID                                               */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR                    RAZON                          */
/*  02/02/2011  Alfredo Zuluaga          Emision Inicial                */
/************************************************************************/

use cob_cartera
go

if exists (SELECT 1 from sysobjects WHERE name = 'sp_reporte_usaid_sem')
   drop proc sp_reporte_usaid_sem
go

---INC. 57201 ABR.20.2012

create proc sp_reporte_usaid_sem(
@i_param1            varchar(255),     --Fecha Inicio consulta
@i_param2            varchar(255)      --Fecha Final  consulta debe ser la fecha de fin de mes

)
as
declare
@i_fecha_ini         datetime,
@i_fecha_fin         datetime,
@w_fecha             datetime,
@w_fecha_fm          datetime,
@w_sp_name           varchar(20),
@w_s_app             varchar(50),
@w_path              varchar(60),
@w_nombre            varchar(26),
@w_nombre_cab        varchar(26),
@w_cmd               varchar(2000),
@w_destino           varchar(2000),
@w_errores           varchar(1000),
@w_error             int,
@w_comando           varchar(2000),
@w_nombre_plano      varchar(1000),
@w_mensaje           varchar(255),
@w_msg               varchar(255),
@w_col_id            int,
@w_columna           varchar(200),
@w_cabecera          varchar(1000),
@w_fecha_ultimo_cierre datetime

select 
@i_fecha_ini     = convert(datetime, @i_param1),
@i_fecha_fin     = convert(datetime, @i_param2),
@w_sp_name       = 'sp_reporte_usaid_sem'

truncate table ca_rep_usaid

---LA fecha final de parametro 2 debe ser la fecha de fin de mes
---para poder seleccionar los saldos correctamente del consolidador

set rowcount 1
select @w_fecha_ultimo_cierre = do_fecha
from cob_credito..cr_dato_operacion with (nolock)
where  do_tipo_reg = 'M'
and    do_codigo_producto = 7
set rowcount 0


if @i_fecha_fin <> @w_fecha_ultimo_cierre
begin
    select @w_error = 2902797, @w_msg = 'PARAMETRO FECHA FIN DIDIGATO NO ES LA FECHA DEL ULTIMO CIERRE REVISAR'
    PRINT 'ERROR FECHA ULTIMO CIERRE:  ' + cast (@w_fecha_ultimo_cierre as varchar) + 'DIFERENTE DE FECHA FIN DIGITADA: ' + cast (@i_fecha_fin as varchar)
    goto ERRORFIN
end

---Es la fecha de inicio del reporte 
select @w_fecha_fm = @i_fecha_ini


select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = 7067

select @w_fecha = fp_fecha
from cobis..ba_fecha_proceso

select @w_nombre = 'ClientesExistentesUSAID_'

select tipo = cg_tipo_garantia, moneda = cg_moneda
into #convenio
from cob_custodia..cu_convenios_garantia 
where cg_estado = 'V'

select *
into #temporal
from ca_rep_usaid

--Cargue Grupo1 (Desembolsados en el rango de fechas dado)
insert into #temporal (
ru_clasificar,     ru_id_unico,       ru_banco,
ru_nom_cliente,    ru_fecha_ini,      ru_fecha_ven,
ru_fecha_gar,      ru_monto_apr,      ru_fecha_cob,
ru_dias_mora,      ru_saldo_inicial,  ru_desembolso,
ru_pago,           ru_saldo
)
select 
'',                
'',
op_banco,
convert(varchar(100),(en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido)),
convert(varchar(10),op_fecha_liq,101),
convert(varchar(10),op_fecha_fin,101),
convert(varchar(10),op_fecha_liq,101),
op_monto_aprobado,
'',
0,
null,
op_monto_aprobado,
null,
0
from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta, cob_credito..cr_tramite, cob_cartera..ca_operacion, cobis..cl_ente, #convenio
where cu_tipo           = tipo
and   cu_estado         not in ('A')
and   cu_codigo_externo = gp_garantia
and   gp_tramite        = tr_tramite
and   tr_tramite        = op_tramite
and   op_cliente        = en_ente
and   op_estado         not in (0,6,99)
and   op_fecha_liq      >= @i_fecha_ini
and   op_fecha_liq      <= @i_fecha_fin

--Cargue Grupo2 (No importa la fecha de desembolso pero aun tienen saldo de deuda)
insert into #temporal (
ru_clasificar,     ru_id_unico,       ru_banco,
ru_nom_cliente,    ru_fecha_ini,      ru_fecha_ven,
ru_fecha_gar,      ru_monto_apr,      ru_fecha_cob,
ru_dias_mora,      ru_saldo_inicial,  ru_desembolso,
ru_pago,           ru_saldo
)
select 
'',                
'',
op_banco,
convert(varchar(100),(en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido)),
convert(varchar(10),op_fecha_liq,101),
convert(varchar(10),op_fecha_fin,101),
convert(varchar(10),op_fecha_liq,101),
op_monto_aprobado,
'',
do_edad_mora,
null,
op_monto_aprobado,
null,
do_saldo
from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta, cob_credito..cr_tramite, cob_cartera..ca_operacion, cobis..cl_ente, #convenio,
     cob_conta_super..sb_dato_operacion
where cu_tipo           = tipo
and   cu_estado         not in ('A')
and   cu_codigo_externo = gp_garantia
and   gp_tramite        = tr_tramite
and   tr_tramite        = op_tramite
and   op_cliente        = en_ente
and   op_estado         not in (0,6,99)
and   op_banco          = do_banco
and   do_fecha          = @i_fecha_fin
and   do_saldo          > 0
and   do_banco          not in (select ru_banco from #temporal)

--Actualizacion Edad Mora y Saldo Final
select banco = do_banco, saldo = do_saldo, edad_mora = do_edad_mora
into #saldo_final
from cob_conta_super..sb_dato_operacion, #temporal
where ru_banco = do_banco
and   do_fecha = @i_fecha_fin

update #temporal set
ru_dias_mora  = edad_mora,
ru_saldo      = saldo
from #saldo_final
where ru_banco = banco

--Actualizacion Saldo Inicial
select banco = do_banco, saldo = do_saldo
into #saldo_inicial
from cob_conta_super..sb_dato_operacion, #temporal
where ru_banco = do_banco
and   do_fecha = ru_fecha_ini ---@w_fecha_fm  Por que es un rango de fechas, por tanto sacar de unasola fechano aplica

update #temporal set
   ru_saldo_inicial = saldo
  from #saldo_inicial
 where ru_banco = banco

--Actualizacion Monto Pagado
select banco = op_banco, monto = sum(ar_monto_mn)
into #pagado
from #temporal, 
	cob_cartera..ca_operacion, 
	cob_cartera..ca_rubro_op, 
	cob_cartera..ca_abono_rubro, 
	cob_cartera..ca_transaccion
where op_operacion  = ar_operacion
and   tr_fecha_ref >= @i_fecha_ini
and   tr_fecha_ref <= @i_fecha_fin
and   tr_secuencial = ar_secuencial
and   tr_operacion  = ar_operacion 
and   ro_operacion  = ar_operacion
and   ro_concepto   = ar_concepto
and   ro_tipo_rubro = 'C'
and   op_banco = ru_banco
and   tr_estado <> 'RV'
and   tr_secuencial >= 0
group by op_banco

update #temporal set
ru_pago = monto
from #pagado
where ru_banco = banco

update #temporal set
   ru_saldo = isnull(ru_desembolso,0) - isnull(ru_pago,0)

insert into ca_rep_usaid
select * from #temporal

----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select 
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = '',
@w_nombre_cab   = @w_nombre

select 
@w_nombre_plano = @w_path + @w_nombre_cab + convert(varchar(2), datepart(dd,@w_fecha)) + '_' + convert(varchar(2), datepart(mm,@w_fecha)) + '_' + convert(varchar(4), datepart(yyyy, @w_fecha)) + '.txt'

select @w_cabecera = 'Clasificar' + '^|' + 'ID Unico USAID'    + '^|' + 'ID Unico Bancamia' + '^|' + 'Nombre Cliente' + '^|' + 'Fecha Inicio'
select @w_cabecera = @w_cabecera  + '^|' + 'Fecha Vencimiento' + '^|' + 'Fecha Garantia'    + '^|' + 'Monto Credito'  + '^|' + 'Fecha Final Cobertura'
select @w_cabecera = @w_cabecera  + '^|' + 'Dias Mora'         + '^|' + 'Saldo Inicial'  + '^|' + 'Desembolso'        + '^|' + 'Pago'
select @w_cabecera = @w_cabecera  + '^|' + 'Saldo Principal Final'

--Escribir Cabecera
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
    goto ERRORFIN
end

--Ejecucion para Generar Archivo Datos

select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_rep_usaid out '

select 
@w_destino  = @w_path + 'ca_rep_usaid.txt',
@w_errores  = @w_path + 'ca_rep_usaid.err'

select
@w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin

    select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS (2).'
    goto ERRORFIN
end


----------------------------------------
--Uni«n de archivo @w_nombre_plano con archivo ca_rep_usaid.txt
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'ca_rep_usaid.txt' + ' ' + @w_nombre_plano

select @w_comando

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin

    select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
    goto ERRORFIN
end



return 0

ERRORFIN: 

   select @w_mensaje = @w_sp_name + ' --> ' + @w_mensaje
   print @w_mensaje
   
   return 1

go



/*

exec cob_cartera..sp_reporte_usaid_sem
@i_param1 = '01/01/2011',
@i_param2 = '12/31/2011'

*/