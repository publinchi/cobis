/************************************************************************/
/*      Nombre Fisico:          cambfech.sp                             */
/*      Nombre Logico:       	sp_cambiar_fecha                        */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Jul. 2008                               */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Permite el cambio del dia del pago en el mes del prestamo       */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*      FECHA               AUTOR      CAMBIO                           */
/*      Dic.2014            E.Pelaez   se hace el cambio de fecha       */
/*                          unicamente moviendo en rubro INT y se regene*/
/*                          ra la tabla pero solo se utiliza la tabla   */    
/*                          ca_dividendo_tmp >= a la cuota VIGENTE      */       
/*                          y se recalculan los Intereses a estas cuotas*/
/*                           MODIFICACIONES                             */
/*  17/abr/2023   Guisela Fernandez     S807925 Ingreso de campo de     */
/*                                      reestructuracion                */
/*    06/06/2023	 M. Cordova		 Cambio variable @w_op_calificacion */
/*									 de char(1) a catalogo				*/
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambiar_fecha')
   drop proc sp_cambiar_fecha
go

---Inc. 117803

create proc sp_cambiar_fecha
@s_user        login        = 'operador',
@s_term        varchar(30)  = 'consola',
@s_sesn        int          = 1,
@s_date        datetime     = null,
@s_ofi         int          = null,
@i_banco       cuenta,
@i_fecha       datetime,
@i_fecha_def   datetime     = null

as declare 
@w_return            int,
@w_operacionca       int,
@w_error             int,
@w_op_estado         int,
@w_est_vigente       tinyint,
@w_div_vigente       int,
@w_msg               varchar(100),
@w_commit            char(1),
@w_sp_name           varchar(30),
@w_pa_ncfe           tinyint,
@w_pa_ndcfe          tinyint,
@w_di_fecha_ven      datetime,
@w_fecha_ult_proc    datetime,
@w_tipo_amortizacion catalogo,
@w_periodo_int       int,
@w_tdividendo        catalogo,
@w_dia_fijo          int,
@w_pa_dimave         tinyint,
@w_fecha_ini         datetime,
@w_plazo             int,
@w_secuencial        int,
@w_moneda            tinyint,
@w_toperacion        catalogo,
@w_oficina           int,
@w_op_calificacion   catalogo,
@w_op_gar_admisible  char(1),
@w_gerente           smallint,
@w_saldo_cap         money,
@w_cap_pag_novig     money,
@w_primer_ven        datetime,
@w_fecha_fin         datetime,
@w_capital_antes     money,
@w_capital_despues   money,
@w_dias_min_cuota    int,
@w_dias_max_cuota    int,
@w_est_vencido       tinyint,
@w_min_di_fecha_ven  datetime,
@w_dias_venc         int,
@w_dias_div_vigente  int,
@w_base_calculo      char(1),
@w_divini_reg        smallint,                     -- REQ 175: PEQUEÑA EMPRESA
@w_periodo_cap       smallint,                     -- REQ 175: PEQUEÑA EMPRESA
@w_gracia_cap        smallint,                     -- REQ 175: PEQUEÑA EMPRESA
@w_gracia_int        smallint,                     -- REQ 175: PEQUEÑA EMPRESA
@w_div_mod           smallint,                     -- REQ 175: PEQUEÑA EMPRESA
@w_ciudad_nacional   int,                          -- REQ 175: PEQUEÑA EMPRESA
@w_cambio_fecha      char(1),
@w_est_novigente     tinyint,
@w_di_fecha_ini      datetime,
@w_primer_NO_viente  smallint,
@w_vence_novigente   datetime,
@w_tasa_nom          float,
@w_valor_calc        money,
@w_num_dec           smallint,
@w_moneda_nac        smallint,
@w_num_dec_mn        smallint,
@w_concepto_int      catalogo,
@w_fpago             char(1),
@w_ro_porcentaje_efa float,
@w_num_dec_tapl      tinyint,
@w_op_monto          money,
@w_dias_anio         smallint,
@w_dividendo         smallint,
@w_di_num_dias       smallint,
@w_tasa_equivalente  float,
@w_int               money,
@w_otros_int         money,
@w_cap               money,
@w_reestructuracion  char(1)


--- VARIABLES DE TRABAJO 
select
@w_sp_name     = 'sp_cambiar_fecha',
@w_commit      = 'N',
@w_dia_fijo    = datepart(dd, @i_fecha),
@w_primer_ven  = dateadd(mm,1,@i_fecha)

if @s_date is null begin
   select @s_date = fc_fecha_cierre
   from cobis..ba_fecha_cierre
   where fc_producto = 7
end

exec @w_error = sp_estados_cca
@o_est_vigente   = @w_est_vigente out,
@o_est_vencido   = @w_est_vencido out,
@o_est_novigente = @w_est_novigente out

if @w_error <> 0 goto ERROR

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @@rowcount = 0 begin
   select @w_error = 101024
   goto ERROR
end


--- VALIDAR QUE PARAMETROS DE ENTRADA NO SEAN NULOS --
if @i_banco is null or @i_fecha is null begin
   select 
   @w_error = 1875041,
   @w_msg   = 'ALGUNO DE LOS PARAMETROS DE ENTRADA OBLIGATORIOS LLEGO EN NULO'
   goto ERROR
end

--- DATOS DE LA OPERACION --
select 
@w_operacionca       = op_operacion,
@w_op_estado         = op_estado,
@w_fecha_ult_proc    = op_fecha_ult_proceso,
@w_tipo_amortizacion = op_tipo_amortizacion,
@w_periodo_int       = op_periodo_int,
@w_tdividendo        = op_tdividendo,
@w_plazo             = op_plazo,
@w_moneda            = op_moneda,
@w_toperacion        = op_toperacion,
@w_oficina           = op_oficina,
@w_op_calificacion   = op_calificacion,
@w_op_gar_admisible  = op_gar_admisible,
@w_gerente           = op_oficial,
@w_base_calculo      = op_base_calculo,
@w_periodo_cap       = op_periodo_cap,                -- REQ 175: PEQUEÑA EMPRESA
@w_gracia_cap        = op_gracia_cap,                  -- REQ 175: PEQUEÑA EMPRESA
@w_gracia_int        = op_gracia_int,                  -- REQ 175: PEQUEÑA EMPRESA
@w_op_monto          = op_monto,
@w_dias_anio         = op_dias_anio,
@w_reestructuracion  = isnull(op_reestructuracion, 'N')
from ca_operacion
where op_banco = @i_banco

if @@rowcount = 0 begin
   select 
   @w_error = 701049,
   @w_msg   = 'NO EXISTE EL PRESTAMO A CAMBIAR DE FECHA'
   goto ERROR
end

if @s_ofi is null select @s_ofi = @w_oficina

/*** CCA 509 CARTERA FINAGRO - CAMBIO FECHA DE PAGO ***/
-- SI ES LINEA DE CREDITO FINAGRO NO ES POSIBLE CAMBIAR FECHAS DE PAGO 
if exists (select 1 from cob_credito..cr_corresp_sib s, cobis..cl_tabla t, cobis..cl_catalogo c  
                    where s.descripcion_sib = t.tabla
                    and   t.codigo            = c.tabla
                    and   s.tabla             = 'T301'
                    and   c.codigo            = @w_toperacion
                    and   c.estado            = 'V')
begin
   --OBLIGACION PERTENECE A LINEAS FINAGRO, NO ES POSIBLE MODIFICAR LA FECHA DE PAGO
   select 
   @w_error = 724566
   goto ERROR
end

exec  sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec out,
@o_mon_nacional = @w_moneda_nac out,
@o_dec_nacional = @w_num_dec_mn out

---*****************************************
select @i_fecha_def = @i_fecha

-- INI - REQ 175: PEQUEÑA EMPRESA
if exists(
select 1 from cobis..cl_dias_feriados
where df_ciudad = @w_ciudad_nacional
and   df_fecha  = @i_fecha            )
begin
    select @w_error = 708144,
    @w_msg   = 'LA FECHA DIGITADA ES UN FESTIVO; POR FAVOR SELECCIONAR OTRA'
    goto ERROR
end
-- FIN - REQ 175: PEQUEÑA EMPRESA


---REVISAR SI LA FECHA  CAMBIO POR SER FESTIVO SE DEBE AJUSTAR EL 
---INICIO DE LA SIGUEINTE CUOTA NO VIEGENTE
select @w_cambio_fecha = 'N'
if @i_fecha <> @i_fecha_def
begin
  --- PRINT 'cambfech.sp cambio de fecha para cuota VIGENTE por festivo'
  select @w_cambio_fecha = 'S'
end
---*****************************************

select @w_min_di_fecha_ven = min(di_fecha_ven)
from   ca_dividendo  with (nolock)
where  di_operacion =  @w_operacionca
and    di_estado = @w_est_vencido

-- EPB_09NOV2004 SALIR DE SUSPENSO POR QUE TIENE YA UNA CALIFICACION MENOR Y 0 DIAS DE MORA
select @w_dias_venc = 0

select @w_dias_venc = datediff(dd, @w_min_di_fecha_ven, @s_date)

--- SOLO SE PERMITE CAMBIAR LA FECHA DE OPERACIONES CON CERO DIAS DE MORA 
if (@w_dias_venc > 0) begin
   select 
   @w_error = 710563,
   @w_msg   = 'SE PERMITE EL CAMBIO DE FECHA SOLO EN OPERACIONES QUE NO TENGAN MORA'
   goto ERROR
end

--- SOLO SE PERMITE CAMBIAR LA FECHA DE OPERACIONES VIGENTES 
if @i_fecha < @w_fecha_ult_proc  begin
   select 
   @w_error = 710563,
   @w_msg   = 'LA NUEVA FECHA DE VENCIMIENTO ES MENOR A LA FECHA DE ULTIMO PROCESO DE LA OPERACION'
   goto ERROR
end

if @w_tipo_amortizacion not in ('ALEMANA','FRANCESA') begin
   select 
   @w_error = 701185,
   @w_msg   = 'ESTA HERRAMIENTA APLICA SOLO SOBRE OPERACIONES CON TABLAS ALEMANAS O FRANCESAS'
   goto ERROR
end

--- VALIDA QUE NO TENGA DIVIDENDOS VENCIDOS 
if exists(select 1 from  ca_dividendo
where di_operacion = @w_operacionca
and   di_estado = 2) begin
   select 
   @w_error = 710563,
   @w_msg   = 'NO SE PERMITE EL CAMBIO DE FECHA EN OPERACIONES CON CUOTAS VENCIDAS'
   goto ERROR
end


--- OBTENER LOS DATOS DE LA CUOTA VIGENTE DE LA OPERACION 
select
@w_div_vigente      = di_dividendo,
@w_di_fecha_ven     = di_fecha_ven,
@w_fecha_ini        = di_fecha_ini,
@w_dias_div_vigente = di_dias_cuota
from ca_dividendo
where di_operacion = @w_operacionca
and   di_estado    = @w_est_vigente

if @@rowcount = 0 begin
   select 
   @w_error = 701179,
   @w_msg   = 'NO EXISTE CUOTA VIGENTE'
   goto ERROR
end

--- CONTROLAR QUE EL NUEVO VENCIMIENTO SEA MAYOR AL INICIO DE LA CUOTA VIGENTE 
if @i_fecha <= @w_fecha_ini begin
   select 
   @w_error = 701182,
   @w_msg   = 'LA NUEVA FECHA DE VENCIMIENTO DEBE SER MAYOR O IGUAL AL INICIO DE LA CUOTA VIGENTE'
   goto ERROR
end

--- LA OPERACION ADMITE SOLO UN CAMBIO DE FECHA POR CUOTA 
if exists(select 1 from ca_cambio_fecha
where cf_operacion = @w_operacionca
and   cf_dividendo = @w_div_vigente) begin
   select 
   @w_error = 701182,
   @w_msg   = 'SOLO SE PERMITE UN CAMBIO DE FECHA DE VENCIMIENTO POR CUOTA'
   goto ERROR
end


--- CONTROLAR NO SUPERAR EL LIMITE DE CAMBIOS DE FECHA POR OPERACION 
select @w_pa_ncfe = pa_tinyint  --numero de cambios permitidos de fechas de vencimiento
from cobis..cl_parametro
where pa_nemonico = 'NCFE'
and   pa_producto = 'CCA'

if @w_pa_ncfe < (select count(*) from ca_cambio_fecha where cf_operacion = @w_operacionca)
begin
   select 
   @w_error = 701183,
   @w_msg   = 'SE SUPERO EL LIMITE DE CAMBIOS DE FECHA POR OPERACION'
   goto ERROR
end


--- CONTROLAR EL NUMERO DE DIAS PERMITIDOS DE CORRIMIENTO DE LA FECHA DE VENCIMIENTO 
select @w_pa_ndcfe = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'NDCFE'
and   pa_producto = 'CCA'

if @@rowcount = 0 begin
   select 
   @w_error = 101077,
   @w_msg   = 'NO SE ENCUENTRA PARAMETRO GENERAL -NDCFE- DE CARTERA'
   goto ERROR
end

if @w_pa_ndcfe < abs(datediff(dd, @i_fecha, @w_di_fecha_ven)) begin
   select 
   @w_error = 701184,
   @w_msg   = 'SE SUPERO EL LIMITE DE DIAS PERMITIDOS DE CORRIMIENTO DE LA FECHA DE VENCIMIENTO'
   goto ERROR
end

select @w_dias_min_cuota = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'DMINC'
and   pa_producto = 'CCA'

if @@rowcount = 0 begin
   select 
   @w_error = 101077,
   @w_msg   = 'NO SE ENCUENTRA PARAMETRO GENERAL -DMINC- DE CARTERA'
   goto ERROR
end

if datediff(dd, @w_fecha_ini, @i_fecha) < @w_dias_min_cuota begin
   select 
   @w_error = 701184,
   @w_msg   = 'ERROR: NO SE PERMITEN CUOTAS MENORES A ' + convert(varchar,@w_dias_min_cuota) + ' DIAS'
   goto ERROR
end


select @w_dias_max_cuota = pa_tinyint + 30
from cobis..cl_parametro
where pa_nemonico = 'DMAXC'
and   pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select 
   @w_error = 101077,
   @w_msg   = 'NO SE ENCUENTRA PARAMETRO GENERAL -DMAXC- DE CARTERA'
   goto ERROR
end


if @w_base_calculo = 'E' 
begin
   exec @w_error = sp_dias_cuota_360
   @i_fecha_ini  = @w_fecha_ini,
   @i_fecha_fin  = @i_fecha,
   @o_dias       = @w_dias_venc OUTPUT
   if @@error <> 0 begin
      select 
      @w_error = 700002,
      @w_msg   = 'ERROR AL CALCULAR BASE'
      goto ERROR
   end
end 
else             
begin
  select @w_dias_venc = datediff(dd,@w_fecha_ini,@i_fecha)
end
   
if @w_dias_venc > @w_dias_max_cuota
 begin
   select 
   @w_error = 701184,
   @w_msg   = 'ERROR: NO SE PERMITEN CUOTAS MAYORES A ' + convert(varchar,@w_dias_max_cuota) + ' DIAS'
   print @w_msg
   goto ERROR
end

--- AQUI TERMINAN LAS VALIDACIONES E INICIA EL PROCESO 
---****************************************************

exec @w_secuencial = sp_gen_sec
@i_operacion       = @w_operacionca

select @w_capital_antes = sum(am_cuota)
from ca_amortizacion
where am_operacion = @w_operacionca
and   am_concepto  = 'CAP'

if @@trancount = 0 begin
   begin tran
   select @w_commit = 'S'
end

-- OBTENER RESPALDO ANTES DE LA REESTRUCTURACION
exec @w_error = sp_historial
@i_operacionca = @w_operacionca,
@i_secuencial  = @w_secuencial

if @w_error <> 0 goto ERROR


--- TRANSACCION NO CONTABLE 
insert into ca_transaccion (
tr_secuencial,      tr_fecha_mov,         tr_toperacion,
tr_moneda,          tr_operacion,         tr_tran,
tr_en_linea,        tr_banco,             tr_dias_calc,
tr_ofi_oper,        tr_ofi_usu,           tr_usuario,
tr_terminal,        tr_fecha_ref,         tr_secuencial_ref,
tr_estado,          tr_gerente,             tr_calificacion,
tr_gar_admisible,   tr_observacion,       tr_comprobante,
tr_fecha_cont,      tr_reestructuracion)
values (
@w_secuencial,      @s_date,              @w_toperacion,
@w_moneda,          @w_operacionca,       'MAN',
'S',                @i_banco,             0,
@w_oficina,         @s_ofi,               @s_user,
@s_term,            @w_fecha_ult_proc,    0,
'NCO',              @w_gerente,           isnull(@w_op_calificacion,'A'),
isnull(@w_op_gar_admisible,'A'),'CAMBIO FECHA',       0,
'',                 @w_reestructuracion)

if @@error <> 0 begin
   select @w_error = 708165
   goto ERROR
end

--LGAR
--- Calcular dias del dividendo acorde a base de calculo                                    
if @w_base_calculo = 'E' begin
   exec @w_error = sp_dias_cuota_360
   @i_fecha_ini  = @w_fecha_ini,
   @i_fecha_fin  = @i_fecha,
   @o_dias       = @w_dias_venc OUTPUT
   if @@error <> 0 begin
      select 
      @w_error = 700002,
      @w_msg   = 'ERROR AL CALCULAR BASE'
      goto ERROR
   end
end 
else             
begin
 select @w_dias_venc = datediff(dd,@w_fecha_ini,@i_fecha)
end
 
update ca_dividendo set 
di_fecha_ven  = @i_fecha,
di_dias_cuota = @w_dias_venc --datediff(dd,di_fecha_ini, @i_fecha)
where di_operacion = @w_operacionca
and   di_dividendo = @w_div_vigente
if @@error <> 0 begin
   select 
   @w_error = 700002,
   @w_msg   = 'ERROR AL ACTUALIZAR FECHA DE VENCIMIENTO DE LA CUOTA VIGENTE'
   goto ERROR
end

if not exists(select 1 from ca_dividendo
where di_operacion = @w_operacionca
and   di_dividendo = @w_div_vigente + 1) begin

   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
   
   return 0  -- terminar el programa solo ajustando los intereses de la cuota vigente

end


--- BORRAR LOS TEMPORALES 
exec @w_error = sp_borrar_tmp
@s_user   = @s_user,
@s_term   = @s_term,
@s_sesn   = @s_sesn,
@i_banco  = @i_banco

if @@error <> 0 begin
   select @w_msg = 'ERROR BORRAR TABLAS TEMPORALES (sp_borrar_tmp)'
   goto ERROR
end


-- PASO DE LA OPERACION A TEMPORALES
exec @w_error = sp_pasotmp
@s_user            = @s_user,
@s_term            = @s_term,
@i_banco           = @i_banco,
@i_operacionca     = 'S',
@i_dividendo       = 'N',
@i_amortizacion    = 'N',
@i_cuota_adicional = 'S',
@i_rubro_op        = 'S',
@i_valores         = 'S',
@i_acciones        = 'N'

if @@error <> 0 begin
   select @w_msg = 'ERROR AL PASAR OPERACION A TABLAS TEMPORALES (sp_paso_tmp)'
   goto ERROR
end

----- DE aca para abajo con @i_fecha_def  *********************


--- AJUSTAR LOS DATOS DEL PRESTAMO EN TEMPORALES 
update ca_operacion_tmp set
opt_cuota          = 0.00,
opt_fecha_pri_cuot = null,
opt_monto          = @w_op_monto,
opt_dia_fijo       = @w_dia_fijo
where opt_operacion = @w_operacionca

if @@error <> 0 begin
   select    @w_error = 710002,
             @w_msg   = 'ERROR AL AJUSTAR LA FECHA DEL SIGUIENTE VENCIMIENTO DE LA OPERACION'
             
   print 'ERROR AL AJUSTAR LA FECHA DEL SIGUIENTE VENCIMIENTO DE LA OPERACION'
   
   goto ERROR
end

update ca_rubro_op_tmp
set rot_valor = @w_op_monto
where  rot_operacion = @w_operacionca
and    rot_fpago     = 'P'
and    rot_tipo_rubro= 'C'

if @@error <> 0 begin
   select 
   @w_error = 710002,
   @w_msg   = 'ERROR AL AJUSTAR EL MONTO DE CAPITAL EN LA TABLA DE RUBROS'
   
   print 'ERROR AL AJUSTAR EL MONTO DE CAPITAL EN LA TABLA DE RUBROS'
         
   goto ERROR
end


-- INI - REQ 175: PEQUEÑA EMPRESA - DETERMINACION DE GRACIA BASE
select 
concepto = am_concepto,
gracia   = case when sum(am_gracia) < 0 then -sum(am_gracia) else 0 end
into #gracia
from ca_rubro_op, ca_amortizacion
where ro_operacion   = @w_operacionca
and   ro_tipo_rubro <> 'C'
and   am_operacion   = ro_operacion
and   am_dividendo  <= @w_div_vigente
and   am_concepto    = ro_concepto      
group by am_concepto

update ca_rubro_op_tmp
set rot_gracia = gracia
from #gracia
where rot_operacion   = @w_operacionca
and   rot_tipo_rubro <> 'C'
and   rot_concepto    = concepto

select @w_divini_reg =  1
-- FIN - REQ 175: PEQUEÑA EMPRESA

exec @w_error = sp_gentabla
@i_operacionca        = @w_operacionca,
@i_operacion_activa   = @w_operacionca,
@i_tabla_nueva        = 'N',
@i_reajusta_cuota_uno = 'N',
@i_reajuste           = 'S',
@i_cuota_reajuste     = @w_divini_reg,
@i_cuota_desde_cap    = null,
@i_cambio_fecha       = 'S',
@o_fecha_fin          = @w_fecha_fin out

if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR LA NUEVA TABLA DE AMORTIZACION (sp_gentabla)'
   goto ERROR
end

delete ca_dividendo
where di_operacion = @w_operacionca
and   di_dividendo > @w_div_vigente
 
if @@error <> 0 begin
   select @w_error = 705043
   goto ERROR
end

insert into ca_dividendo
select * from ca_dividendo_tmp
where dit_operacion = @w_operacionca
and   dit_dividendo > @w_div_vigente

if @@error <> 0 begin
   select @w_error = 705043
   goto ERROR
end

update ca_operacion set
op_dia_fijo        = @w_dia_fijo,
op_evitar_feriados = 'N',
op_fecha_fin       = @w_fecha_fin
where op_operacion = @w_operacionca

if @@error <> 0 begin
   select @w_error = 710001
   goto ERROR
end


---Recalcular el Interes de todas las cuotas que cambiaron
---mayoes a a VIGENTE
select @w_ro_porcentaje_efa = ro_porcentaje_efa,
       @w_tasa_equivalente  = ro_porcentaje,
       @w_fpago             = ro_fpago,
       @w_num_dec_tapl      = ro_num_dec
from   ca_rubro_op
where  ro_operacion = @w_operacionca
and    ro_tipo_rubro = 'I'

if @w_ro_porcentaje_efa < 0
begin
   PRINT 'cambfech.sp Error tasa con valor no valido @w_ro_porcentaje_efa ' +   cast ( @w_ro_porcentaje_efa as varchar)
  select @w_error = 710004
  goto ERROR         
end

if @w_fpago = 'P' 
   select @w_fpago = 'V'

declare cursor_divi_Canbfech cursor for select 
di_dividendo,
di_dias_cuota
from   ca_dividendo
where  di_operacion   = @w_operacionca
and    di_dividendo >= @w_div_vigente
order  by di_dividendo
for read only

open cursor_divi_Canbfech
fetch cursor_divi_Canbfech 
into  @w_dividendo,
      @w_di_num_dias

while   @@fetch_status = 0  
begin 
   if (@@fetch_status = -1) 
   return 710004

      select @w_cap = 0
      select @w_cap = sum(am_cuota)
      from ca_amortizacion
      where am_operacion = @w_operacionca
      and am_dividendo >= @w_dividendo
      and am_concepto  = 'CAP'

      --exec @w_error =  sp_conversion_tasas_int
      --@i_dias_anio      = @w_dias_anio,
      --@i_periodo_o      = 'A',
      --@i_modalidad_o    = 'V',
      --@i_num_periodo_o  = 1,
      --@i_tasa_o         = @w_ro_porcentaje_efa,
      --@i_periodo_d      = 'D',
      --@i_modalidad_d    = @w_fpago, 
      --@i_num_periodo_d  = @w_di_num_dias,
      --@i_num_dec        = @w_num_dec_tapl,
      --@o_tasa_d         = @w_tasa_equivalente output
      
      select @w_int = (@w_tasa_equivalente * @w_cap) / (100 * 360) * @w_di_num_dias
      select @w_int = round(@w_int,@w_num_dec)
      
      select @w_otros_int  = isnull(sum(am_cuota),0)
      from   ca_amortizacion, ca_dividendo
      where  am_operacion  = @w_operacionca
      and    am_operacion  = di_operacion
      and    am_dividendo  = di_dividendo
	  and    am_dividendo  = @w_dividendo
	  and    am_estado    <> @w_op_estado
      and    am_concepto   = 'INT'
	  and    di_de_interes = 'S'     
	  
	  if @w_otros_int > 0
	     select @w_int = @w_int - @w_otros_int

      update ca_amortizacion
	  set    am_cuota      = @w_int
      from   ca_amortizacion, ca_dividendo
      where  am_operacion  = @w_operacionca
      and    am_operacion  = di_operacion
      and    am_dividendo  = di_dividendo
	  and    am_dividendo  = @w_dividendo
	  and    am_estado     = @w_op_estado
      and    am_concepto   = 'INT'
	  and    di_de_interes = 'S'
      
	  if @@error <> 0 begin
        PRINT 'cambfech.sp  Error actualizando INT despues de cambio de la fecha'
        select @w_error =  724401
        goto ERROR
      end    
      
      fetch cursor_divi_Canbfech 
      into  @w_dividendo,
            @w_di_num_dias
   
end  ---while cursor

close cursor_divi_Canbfech
deallocate cursor_divi_Canbfech   
---FIN ACT INT despues de cambio de FECHA   

select @w_capital_despues = sum(am_cuota)
from ca_amortizacion
where am_operacion = @w_operacionca
and   am_concepto  = 'CAP'

if @w_capital_antes <> @w_capital_despues 
begin
   select @w_error = 705043, @w_msg = 'ERROR EN EL PROCESO, CAP.ANTES:' + convert(varchar, @w_capital_antes) + ' CAP.DESPUES:' + convert(varchar, @w_capital_despues)
   goto ERROR
end

if @w_commit = 'S' 
begin
   commit tran
   select @w_commit = 'N'
end

PRINT '!!!  CAMBIO DE FECHA EXITOSO..!!!'

return 0

ERROR:

if @w_commit = 'S' 
begin
   rollback tran
   select @w_commit = 'N'
end

exec sp_borrar_tmp
@s_user   = @s_user,
@s_term   = @s_term,
@s_sesn   = @s_sesn,
@i_banco  = @i_banco

if @w_msg is null 
begin
   select @w_msg = mensaje
   from cobis..cl_errores
   where numero = @w_error
end

exec cobis..sp_cerror
@t_debug = 'N',
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg
   
return @w_error
go

