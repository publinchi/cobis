/************************************************************************/
/*   Stored procedure:     sp_fng_devoluciones                          */
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
/*                            PROPOSITO                                 */
/*   Generar reportes de operaciones con Devolución de FNG.             */
/*   Reporetes que son enciados al Fondo Nacional de garantias para     */
/*   aprobación y posterior aplicación de pagos en forma masiva         */

/*   Dic 12: Correccion lectura del parametro w_pfngdes con nemonico    */
/*   COFNGD																*/
/*   Dic 12: La comision de la Anualidad debe leerse con base en el     */
/*   parametro  w_pfnganu y no en el parametro w_pfngdes                */
/*   Enero 2012: Alcance: Porcentaje minimo de devolucion sobre comision */
/*   Febrero 2 2012: Modifica el calculo de meses no cubiertos           */
/************************************************************************/

use cob_cartera
go

 
if exists (select 1 from sysobjects where name = 'sp_fng_devoluciones')
   drop proc sp_fng_devoluciones
go
 
create proc sp_fng_devoluciones(
   @i_param1          datetime,      -- Fecha Inicial
   @i_param2          datetime       -- Fecha Final
)
as                         
declare   
   @i_fecha_ini       datetime,
   @i_fecha_fin       datetime, 
   @w_smv_porcen      money,
   @w_fecha_proceso   datetime,
   @w_anio            varchar(4),
   @w_mes             varchar(2),
   @w_dia             varchar(2),
   @w_path_destino    varchar(255),
   @w_msg             varchar(255),
   @w_s_app           varchar(255),
   @w_cmd             varchar(1500),
   @w_comando         varchar(1500),
   @w_error           int,
   @w_nombre_archivo  varchar(255),
   @w_fecha_corte     varchar(10),
   @w_fecha_rep       varchar(10),
   @w_pfngdes         varchar(10),
   @w_pfngiva         varchar(10),
   @w_pfnganu         varchar(10),
   @w_pfngivad        varchar(10),
   @w_cod_gar_fng     varchar(10),
   @w_psmcfng         float,
   @w_pmcfng         float,
   @w_smdfng          smallint,
   @w_pacsa           float,
   @w_mmpdf           smallint,
   @w_perfng          smallint

--Version 3 Alcance al NR227

select @i_fecha_ini = @i_param1,
       @i_fecha_fin = @i_param2

/****VALIDAR QUE LA FECHA INICIO DE PAGO SEA MAYOR A LA FECHA FIN DE PAGO***/
if @i_fecha_ini > @i_fecha_fin begin
   select  @w_msg    = 'Fecha Inicio es Superior a la Fecha Fin'
   select  @w_msg
   select  @w_error      = 700009
   goto ERROR
end


select @w_fecha_proceso = fp_fecha 
from cobis..ba_fecha_proceso
if @@rowcount = 0
begin
   select @w_msg = 'Error - Fecha de Proceso Nula',
          @w_error = 700002
   Goto ERROR 
end

print 'La fecha de proceso es    :' + cast(@w_fecha_proceso  as varchar)

--PARAMETRO COMISIÓN FNG PERIODICA

select @w_pfnganu = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro COMISION FNG PERIODICA',
          @w_error = 700002
   Goto ERROR 
end

-- PARAMETROS GENERALES DE CALCULO

-- Porcentaje minimo de comision a devolver 
select @w_pmcfng = pa_float
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'PMCFNG'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro PORCENTAJE MINIMO COMISION FNG - DEVOLUCION',
          @w_error = 700002
   Goto ERROR 
end

-- Porcentaje sobre el monto de la Comision
select @w_psmcfng = pa_float
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'PSMCFD'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro PORCENTAJE SOBRE COMISION FNG - DEVOLUCION',
          @w_error = 700002
   Goto ERROR 
end



-- Numero de salarios minimos legales vigentes
select @w_smdfng = pa_smallint
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'SMDFNG'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro SALARIOS MINIMOS PARA DEVOLUCION FNG',
          @w_error = 700002
   Goto ERROR 
end

-- Porcentaje sobre lo que va a cobrar de la anualidad
select @w_pacsa = pa_float
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'PACSA'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro PORCENTAJE A COBRAR SOBRE LA ANUALIDAD',
          @w_error = 700002
   Goto ERROR 
end

-- Numero minimo de meses de haberse liquidado la unualidad
select @w_mmpdf = pa_smallint
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'MMPDF'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro MESES MINIMOS PARA DEVOLUCION DE FNG',
          @w_error = 700002
   Goto ERROR 
end

--PARAMETRO COMISIÓN FNG DESEMBOLO
select @w_pfngdes = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'COFNGD' -- acelis 12122011 'COMFNG'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro COMISION FNG DESEMBOLSO',
          @w_error = 700002
   Goto ERROR 
end

--PARAMETRO IVA FNG
select @w_pfngiva = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'IVAFNG'
and pa_producto = 'CCA'  --acelis 12122011  se agrego esta linea
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro IVA COMISION FNG PERIODICA ',
          @w_error = 700002
   Goto ERROR 
end

--PARAMETRO IVA FNG DESEMBOLSO
select @w_pfngivad = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'IVFNGD'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro IVA COMISION FNG DESEMBOLSO ',
          @w_error = 700002
   Goto ERROR 
end

--PARAMETRO CODIGO GARANTIA PADRE FNG
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro CODIGO PADRE FNG TIPO GARANTIA',
          @w_error = 700002
   Goto ERROR 
end

--PARAMETRO SALARIO MINIMO
select @w_smv_porcen = ((pa_money * @w_pacsa/100) * @w_smdfng)  --acelis 12162011  faltaba dividir en 100
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'SMV'
if @@rowcount = 0
begin
   select @w_msg = 'No existe parametro SMV',
          @w_error = 700001
   Goto ERROR 
end

--PARAMETRO PERIODICIDAD COBRO COMISION FNG
select @w_perfng = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'PERFNG'
if @@rowcount = 0
begin
   select @w_msg = 'Error - No existe parametro PERIODICIDAD COBRO COMISION FNG',
          @w_error = 700002
   Goto ERROR 
end

-- Obtener colaterales FNG
select tc_tipo as tipo into #calfng
from cob_custodia..cu_tipo_custodia
where  tc_tipo_superior  = @w_cod_gar_fng


if exists(select 1 from sysobjects where name = 'tmp_fng')
   drop table tmp_fng

--> Insertar en la tabla ca_fng_devoluviones, las obligaciones resultado del siguiente query :
select 'num_operacion'     = op_operacion,
       'tramite'           = op_tramite,
       'banco'             = op_banco,
       'banco_renova'      = op_anterior,
       'op_reestructurada' = 'N',
       'cliente'           = op_cliente,
       'fecha_liq'         = op_fecha_liq,
       'oficina'           = op_oficina,
       'monto_aprobado'    = round(op_monto_aprobado,2),
       'fecha_liq_renova'  = convert(datetime, null),
       'fecha_renova'      = convert(datetime, null),
       'oper_renovada'     = convert(int, 0),       
       'fech_cuota_tres'   = convert(datetime, null),
       'tramite_renova'    = convert(int, 0),
       'tipo_periodo'      = convert(int, 0)
into #op_renovadas
from  cob_cartera..ca_operacion with (nolock),
      cob_credito..cr_gar_propuesta with (nolock),
      cob_custodia..cu_custodia with (nolock), 
      #calfng
where op_anterior is not null
and   op_fecha_liq >= @i_fecha_ini 
and   op_fecha_liq <= @i_fecha_fin 
and   op_estado in (1,2,4,9)
and   gp_tramite   =  op_tramite 
and   gp_garantia  = cu_codigo_externo
and   cu_tipo      = tipo

if @@rowcount = 0
begin
   select @w_msg = 'No existen operaciones para procesar',
          @w_error = 700003
   Goto ERROR 
end

--ACTUALIZAR NUMERO DE OPERACION CANCELADA
update #op_renovadas
set   fecha_liq_renova  = op_fecha_liq,
      fecha_renova      = op_fecha_ult_proceso,
      oper_renovada     = op_operacion,
      tramite_renova    = op_tramite,
      tipo_periodo      = (td_factor / 30)
from  cob_cartera..ca_operacion with (nolock),
      cob_credito..cr_gar_propuesta with (nolock),
      cob_custodia..cu_custodia with (nolock), 
      cob_cartera..ca_tdividendo with (nolock), 
      #calfng
where banco_renova =  op_banco 
and   gp_tramite   =  op_tramite 
and   gp_garantia  = cu_codigo_externo
and   cu_tipo      = tipo
and   op_tplazo    = td_tdividendo

if @@error <> 0
begin
   select @w_msg = 'Error Actualizando Operaciones Renovadas',  
          @w_error = 700003
   Goto ERROR 
end

/*****ELIMINAR OPERACIONES QUE TIENE GARANTIA FNG  ***/
delete #op_renovadas 
where oper_renovada = 0

--ACTUALIZAR LA TERCERA CUOTA DE LA OPERACION CANCELADA
update #op_renovadas
set  fech_cuota_tres  = dateadd(mm, @w_mmpdf, fecha_liq_renova)



if @@error <> 0
begin
   select @w_msg = 'Error Actualizando Operaciones Renovadas',  
          @w_error = 700003
   Goto ERROR 
end


/**** INSERTANDO DATOS EN LA TABLA DEFINITIVA CA_FNG_DEVOLIUCIONES ***/
delete ca_fng_devoluciones WHERE ro_codigo_cliente >= 0

insert into ca_fng_devoluciones
(ro_codigo_cliente, 
 ro_nombre_cliente, 
 ro_banco_ren, 
 ro_banco_reest,
 ro_fecha_liq_ren, 
 ro_oficina, 
 ro_monto_ren, 
 ro_comision_fng_ren,
 ro_iva_fng_ren, 
 ro_comision_fng_reest, 
 ro_iva_fng_reest, 
 ro_valor_reintegro_fng,
 ro_aplica_pago_fng)
select
 cliente, 
 (select en_nomlar from cobis..cl_ente where en_ente = cliente), 
 rtrim(ltrim(banco)),   
 rtrim(ltrim(banco_renova)),
 convert(varchar,fecha_liq,111), 
 oficina, 
 round(monto_aprobado,2), 
 0, 
 0, 
 0, 
 0,
 0, 
 'N'
from #op_renovadas
if @@rowcount = 0
begin
   select @w_msg = 'No existen Datos para Procesar fecha fin : ' + convert(varchar(10),@i_fecha_fin,101),
          @w_error = 700005
   Goto ERROR 
end

/*** ULTIMA ANUALIDAD COBRADA DE LA OPE. ANTERIOR ****/
select 
banco,
'num_op'          = di_operacion, 
'fecha_ult_anual' = max(di_fecha_ven),
'div_ult_anual'   = max(di_dividendo),
'fecha_ren'         = fecha_renova,
't_dividendo'     = tipo_periodo
into #ult_anualidad_cobrada
from ca_amortizacion, ca_dividendo, #op_renovadas
where am_operacion = di_operacion
and   am_operacion = oper_renovada
and   am_dividendo = di_dividendo
and   am_concepto  in (@w_pfnganu,@w_pfngiva)
and   am_cuota > 0
and   di_fecha_ven <= fecha_renova
group by banco,di_operacion,fecha_renova,tipo_periodo
order by banco,di_operacion,fecha_renova,tipo_periodo

if @@rowcount > 0 begin

   update ca_fng_devoluciones set
   ro_comision_fng_reest = round(isnull(am_cuota,0),2)
   from ca_amortizacion, #ult_anualidad_cobrada 
   where am_operacion = num_op
   and   am_concepto  = @w_pfnganu --acelis 12122011 @w_pfngdes
   and   am_dividendo = div_ult_anual
   and   ro_banco_ren = banco
   if @@error <> 0
   begin
      select @w_msg = 'Error actualizando comision fng ren  ',
             @w_error = 700006
      Goto ERROR 
   end

   update ca_fng_devoluciones set
   ro_iva_fng_reest = round(isnull(am_cuota,0),2)
   from ca_amortizacion, #ult_anualidad_cobrada 
   where am_operacion = num_op
   and   am_concepto  = @w_pfngiva
   and   am_dividendo = div_ult_anual
   and   ro_banco_ren = banco
   if @@error <> 0
   begin
      select @w_msg = 'Error actualizando iva fng ren  ',
             @w_error = 700006
      Goto ERROR 
   end
end

--VALIDAR LA COMISIÓN FNG EN EL DESEMBOLSO
select
banco ,
'num_op'           = tr_operacion, 
'div_ult_anual'    = 1, 
'fecha_ult_anual'  = tr_fecha_ref,
'concepto'         = dtr_concepto,
'valor'            = round(dtr_monto,2),
'fecha_ren'        = fecha_renova,
'tipo_periodo'     = tipo_periodo
into #ult_anualidad_cobrada_des
from ca_transaccion,ca_det_trn, #op_renovadas
where oper_renovada = tr_operacion
and   tr_tran       = 'DES'
and   tr_secuencial = dtr_secuencial
and   tr_operacion  = dtr_operacion
and   dtr_concepto in (@w_pfngdes ,@w_pfngivad) --acelis 12122011 se cambia el parametro w_pfngiva por w_pfngivad
and   tr_secuencial > 0
and   tr_estado <> 'RV'
and   banco not in (select banco from #ult_anualidad_cobrada )

if @@rowcount > 0 begin
   update ca_fng_devoluciones set
   ro_comision_fng_reest = round(isnull(valor,0),2)
   from #ult_anualidad_cobrada_des 
   where concepto  = @w_pfngdes
   and   ro_banco_ren = banco
   if @@error <> 0 begin
     select @w_msg = 'Error actualizando comision fng ren  ',
            @w_error = 700006
     Goto ERROR 
   end

   update ca_fng_devoluciones set
   ro_iva_fng_reest = round(isnull(valor,0),2)
   from #ult_anualidad_cobrada_des 
   where concepto  = @w_pfngivad
   and   ro_banco_ren = banco
   if @@error <> 0 begin
      select @w_msg = 'Error actualizando comision fng ren  ',
             @w_error = 700006
      Goto ERROR 
   end

   insert into #ult_anualidad_cobrada
   select distinct banco,num_op,fecha_ult_anual,1,fecha_ren,tipo_periodo
   from #ult_anualidad_cobrada_des
end

/*** ANUALIDAD COBRADA EN EL DESEMBOLSO DE LA OPE. NUEVA ***/
select
banco ,
'operacion'        = tr_operacion, 
'div_pri_anual'    = 1, 
'fecha_pri_anual'  = tr_fecha_ref,
'concepto'         = dtr_concepto,
'valor'            = round(dtr_monto,2)
into #pri_anualidad_cobrada
from ca_transaccion,ca_det_trn, #op_renovadas
where num_operacion = tr_operacion
and   tr_tran       = 'DES'
and   tr_secuencial = dtr_secuencial
and   tr_operacion  = dtr_operacion
and   dtr_concepto in (@w_pfngdes ,@w_pfngivad)
and   tr_secuencial > 0
and   tr_estado <> 'RV'
if @@rowcount = 0
begin
   select @w_msg = 'No Existen Anualidad de Desembolso para las Operaciones',
          @w_error = 700006
   Goto ERROR 
end

update ca_fng_devoluciones set
ro_comision_fng_ren = round(isnull(valor,0),2)
from #pri_anualidad_cobrada 
where concepto  = @w_pfngdes
and   ro_banco_ren = banco
if @@error <> 0
begin
   select @w_msg = 'Error actualizando comision fng ren  ',
          @w_error = 700006
   Goto ERROR 
end

update ca_fng_devoluciones set
ro_iva_fng_ren = round(isnull(valor,0),2)
from #pri_anualidad_cobrada 
where concepto  = @w_pfngivad
and   ro_banco_ren = banco
if @@error <> 0
begin
   select @w_msg = 'Error actualizando iva fng ren  ',
          @w_error = 700006
   Goto ERROR 
end

/*** VALOR REINTEGRO COMISIÓN FNG E IVA **/

/* CREAR TABLA DE TRABAJO */
create table #reintegro_fng 
(num_oper         int null,
 banco            varchar(30) null, 
 saldo_cap        money null, 
 tasa_fng         float null, 
 tasa_fng_iva     float null, 
 meses_liquidados smallint null, 
 meses_no_gar     smallint null, 
 vlr_reintegro_fng money null)

insert into #reintegro_fng
(num_oper,banco)
select oper_renovada,banco
from #op_renovadas

select
'operacion' = num_op ,
'capital' = round(sum(am_cuota),2)
into #capital
from ca_amortizacion, #ult_anualidad_cobrada
where am_operacion = num_op
and   am_dividendo >= div_ult_anual
and   am_concepto = 'CAP'
group by num_op

update #reintegro_fng set
saldo_cap = capital
from #capital, #reintegro_fng
where operacion = num_oper
if @@error <> 0
begin
   select @w_msg = 'Error actualizando saldo capital',
          @w_error = 700006
   Goto ERROR 
end

update #reintegro_fng set
tasa_fng = isnull(ro_porcentaje,0)
from ca_rubro_op, #ult_anualidad_cobrada, #reintegro_fng
where ro_operacion = num_op
and   num_op = num_oper
and   ro_concepto in (@w_pfnganu,@w_pfngdes)
if @@error <> 0
begin
   select @w_msg = 'Error actualizando tasa fng  ',
          @w_error = 700006
   Goto ERROR 
end

update #reintegro_fng set
tasa_fng_iva = isnull(ro_porcentaje,0)
from ca_rubro_op, #ult_anualidad_cobrada, #reintegro_fng
where ro_operacion = num_op
and   num_op = num_oper
and   ro_concepto in (@w_pfngiva,@w_pfngivad)
if @@error <> 0
begin
   select @w_msg = 'Error actualizando tasa fng iva ',
          @w_error = 700006
   Goto ERROR 
end

/* CALCULA LOS DIAS QUE HAN TRANSCURRIDO DESDE EL COBRO DE LA ULTIMA ANUALIDAD Y LA FECHA DE RENOVACION */
update #reintegro_fng set
meses_no_gar = abs(datediff(dd,fecha_ult_anual,ua.fecha_ren)) --acelis 12152011
from  #ult_anualidad_cobrada ua,#reintegro_fng re
where ua.banco     = re.banco
if @@error <> 0
begin
   select @w_msg = 'Error actualizando meses no garantiza fng ',
          @w_error = 700006
   Goto ERROR 
end

/* SE CALCULA EL NUMERO DE MESES NO GARANTIZADOS */
update #reintegro_fng set
meses_no_gar = case when meses_no_gar % 30 > 0 then @w_perfng - ((meses_no_gar/30) + 1) else @w_perfng - (meses_no_gar/30) end
if @@error <> 0
begin
   select @w_msg = 'Error actualizando meses no garantiza fng ',
          @w_error = 700006
   Goto ERROR 
end

update #reintegro_fng set
vlr_reintegro_fng = round(ro_comision_fng_reest*(@w_psmcfng/100.0)/12*meses_no_gar,2) --acelis 12152011 faltaba div por 100
from #reintegro_fng,cob_cartera..ca_fng_devoluciones
where ro_banco_ren = banco
if @@error <> 0
begin
   select @w_msg = 'Error actualizando valor reintegro fng  ',
          @w_error = 700006
   Goto ERROR 
end

/* VALOR REINTEGRO + IVA */

update #reintegro_fng set
vlr_reintegro_fng = round(vlr_reintegro_fng + (vlr_reintegro_fng*(tasa_fng_iva/100.0)),2)  --acelis 12152010
from #reintegro_fng
if @@error <> 0
begin
   select @w_msg = 'Error actualizando valor reintegro fng + iva ',
          @w_error = 700006
   Goto ERROR 
end


update ca_fng_devoluciones set
ro_valor_reintegro_fng = round(isnull(vlr_reintegro_fng,0),2),
--ro_aplica_pago_fng     = case when vlr_reintegro_fng >= @w_smv_porcen and a.fecha_liq   > fech_cuota_tres then 'S'  --acelis 12152011
ro_aplica_pago_fng     = case when vlr_reintegro_fng >= @w_smv_porcen and  vlr_reintegro_fng > ro_comision_fng_reest*@w_pmcfng/100.0 and a.fecha_liq > fech_cuota_tres then 'S'  --alcance 01192012
                          else 'N' end
from #reintegro_fng b, ca_fng_devoluciones,#op_renovadas a
where ro_banco_ren = b.banco
and   b.banco      = a.banco
if @@error <> 0
begin
   select @w_msg = 'Error actualizando ro_aplica_pago_fng ',
          @w_error = 700006
   Goto ERROR 
end

--> Generar el archivo plano renovacionesfng_AAAAMMDD.txt,  separado por pipes '|', Todas las obligaciones que se encuentran en la tabla ca_fng_devoluciones

create table tmp_fng (orden int not null, cadena varchar(2000) not null)

select @w_anio = convert(varchar(4),datepart(yyyy,@w_fecha_proceso)),
       @w_mes = convert(varchar(2),datepart(mm,@w_fecha_proceso)), 
       @w_dia = convert(varchar(2),datepart(dd,@w_fecha_proceso)) 
 
select @w_fecha_corte = (@w_anio + right('00' + @w_mes,2) + right('00'+ @w_dia,2))
select @w_fecha_rep   = (right('00'+ @w_dia,2) + right('00' + @w_mes,2) + @w_anio)

Select @w_path_destino = ba_path_destino
from cobis..ba_batch
where ba_batch = 7111
if @@rowcount = 0 Begin
   select @w_msg = 'NO EXISTE RUTA DE LISTADOS PARA EL BATCH 7111'
   GOTO ERROR
End 

select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'
if @@rowcount = 0 Begin
   select @w_msg = 'NO EXISTE RUTA S_APP',
          @w_error = 700008
   GOTO ERROR
End 

select @w_nombre_archivo = @w_path_destino + 'renovacionesfng_' + @w_fecha_corte + '.txt' 
Print  'Generando Archivo x BCP'
Print @w_nombre_archivo

select @w_cmd     =  'bcp "select ro_nombre_cliente,ro_banco_ren,ro_banco_reest,convert(varchar,ro_fecha_liq_ren,111),'+ 
                     'ro_oficina,ro_monto_ren,ro_comision_fng_ren,ro_iva_fng_ren,ro_comision_fng_reest,'+ 
                     'ro_iva_fng_reest,ro_valor_reintegro_fng,ro_aplica_pago_fng from cob_cartera..ca_fng_devoluciones " queryout ' 
select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t"|" -T -S'+ @@servername + ' -eOLAINVR.err' 
PRINT @w_comando
exec @w_error = xp_cmdshell @w_comando

If @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP' + @w_comando
   Goto ERROR 
End

--> Generar el archivo plano reintegrocomFNG_AAAAMMDD.txt, con encabezado y separadas por pipes '|', El archivo plano debe tener todas aquellas 
--  obligaciones que  se encuentren en la tabla  ca_fng_devoluciones y que el campo ro_aplica_pago_fng = ''S

 print 'Generar el archivo plano FNG_AAAAMMDD.txt !!!!!  PRIMERO  '                 

insert into tmp_fng (orden, cadena) values (0,'Nidentificacion|Nobligacion|Fecdesembolso|Vr_a_Aplicar')

insert into tmp_fng (orden, cadena)
select 
row_number() over (order by ro_banco_ren),
(select en_ced_ruc from cobis..cl_ente where en_ente = ro_codigo_cliente) +
'|' + convert(varchar, ro_banco_ren) +
'|' + convert(varchar,ro_fecha_liq_ren,112) +
'|' + convert(varchar,convert(numeric,ro_valor_reintegro_fng)) +
'|' + '0' +
'|' + '0' +
'|' + '0'
from cob_cartera..ca_fng_devoluciones
where ro_aplica_pago_fng = 'S'
order by ro_banco_ren

select @w_nombre_archivo = @w_path_destino + 'reintegrocomFNG_' + @w_fecha_corte + '.txt' 
Print  'Generando Archivo x BCP'
Print  @w_nombre_archivo

print 'datos de la tabla '
print ''
print ''
print ''
print ''

select @w_cmd     =  'bcp "select cadena from cob_cartera..tmp_fng order by orden " queryout ' 
select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t"|" -T -S'+ @@servername + ' -eREINFNG.err' 
PRINT @w_comando
exec @w_error = xp_cmdshell @w_comando

If @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP' + @w_comando
   Goto ERROR 
End                                   
                                   

--> Generar el archivo plano FNG_AAAAMMDD.txt,  separado por pipes '|', El archivo plano debe tener todas aquellas obligaciones que  se encuentren en la tabla  ca_fng_devoluciones y que el campo ro_aplica_pago_fng = ''S

print 'Generar el archivo plano FNG_AAAAMMDD.txt !!!!!  SEGUNDO '                 
delete tmp_fng WHERE orden >= 0

insert into tmp_fng (orden, cadena) values (0,'REFERENCIA_DEL_ARCHIVO|NIT_INTERMEDIARIO|TIPO_DE_PROCESO|NUMERO_DE_RESERVA|IDENTIFICA_DEUDOR|REF_CREDITO|FECHA_DE_RADICACION')

insert into tmp_fng (orden, cadena)
select
row_number() over (order by ro_banco_reest),
'DC'+@w_fecha_rep+
'|' + (select replace(fi_ruc,'-','') from cobis..cl_filial where fi_filial = 1) +
'|' + 'D' +
'|' + convert(varchar,cu_num_dcto) + 
'|' + (select en_ced_ruc from cobis..cl_ente where en_ente = ro_codigo_cliente) +
'|' + convert(varchar,ro_banco_reest) +
'|' + @w_fecha_rep
from cob_credito..cr_gar_propuesta,
     cob_custodia..cu_custodia,
     #op_renovadas,
     ca_fng_devoluciones, 
     #calfng
where gp_tramite = tramite_renova
and   ro_banco_reest = banco_renova
and   gp_garantia = cu_codigo_externo
and   ro_aplica_pago_fng = 'S'
and   cu_tipo = tipo
order by ro_banco_reest

select @w_nombre_archivo = @w_path_destino + 'FNG_' + @w_fecha_corte + '.txt' 


print 'Generar el archivo plano FNG_AAAAMMDD.txt !!!!!  TERCERO   '                 

Print  'Generando Archivo x BCP'
Print @w_nombre_archivo

select @w_cmd     =  'bcp "select cadena from cob_cartera..tmp_fng order by orden " queryout ' 
select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t"|" -T -S'+ @@servername + ' -eFNG.err' 
PRINT @w_comando
exec @w_error = xp_cmdshell @w_comando

If @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP' + @w_comando
   Goto ERROR 
End                  

return 0

ERROR:
   print @w_msg 
   select @w_msg = 'sp_fng_devoluciones ' + @w_msg
   exec @w_error = sp_errorlog
        @i_fecha      = @w_fecha_proceso,
        @i_error      = @w_error,
        @i_usuario    = 'sa',
        @i_tran       = 7086,
        @i_tran_name  = @w_msg,
        @i_rollback   = 'N'

go
/*
exec cob_cartera..sp_fng_devoluciones
@i_param1 = '20110101',
@i_param2 = '20111231'
*/
