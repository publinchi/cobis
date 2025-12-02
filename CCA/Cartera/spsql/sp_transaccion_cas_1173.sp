
use cob_cartera
go

set ansi_warnings off
go


if exists (select 1 from sysobjects where name = 'sp_transaccion_cas_1173')
   drop proc sp_transaccion_cas_1173
go

---INC. 114955 MAR.04.2014

create proc sp_transaccion_cas_1173(
   @s_date              datetime = null,
   @s_user              login,
   @s_term              varchar(30),
   @i_operacionca       int,
   @o_msg               varchar(100) = null out) 

as 
declare
   @w_return               int,
   @w_secuencial           int,
   @w_error                int,
   @w_estado               int,
   @w_est_cancelado        tinyint,
   @w_est_novigente        tinyint,
   @w_est_castigado        tinyint,
   @w_est_vigente          tinyint,
   @w_est_vencido          tinyint,
   @w_est_suspenso         tinyint,   
   @w_fecha_proceso        datetime,
   @w_fecha_ult_proceso    datetime,
   @w_moneda               tinyint,
   @w_tramite              int,
   @w_toperacion           catalogo,
   @w_banco                cuenta,
   @w_oficina              int,
   @w_oficial              int,
   @w_est_diferido         int,
   @w_saldo_dif            money,
   @w_concepto_cap         catalogo,
   @w_ciudad               int,
   @w_ant_habil            datetime,
   @w_prov_cap_cc          money,
   @w_prov_int_cc          money,
   @w_prov_otr_cc          money,
   @w_estado_prejuridico   varchar(5),
   @w_estado_cobr          varchar(5),
   @w_concepto_prov        char(1),
   @w_concepto_cod         int,
   @w_saldo_ant            money,
   @w_saldo_act            money,
   @w_vlr_tot              money,
   @w_vlt_pag              money,
   @w_orden                smallint,
   @w_concepto             catalogo,
   @w_sld_cpto             money,
   @w_commit               char(1)

-- CARGAR VARIABLES DE TRABAJO
select @w_secuencial    = 0,
       @w_saldo_dif     = 0,
       @w_commit        = 'N'

--- Parametros del estado de la operacion en Cobranzas 
select @w_estado_prejuridico = pa_char
from  cobis..cl_parametro
where pa_nemonico = 'ESTCPR'
and pa_producto = 'CRE'  

--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_vencido    = @w_est_vencido   out

select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

select 
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_toperacion        = op_toperacion,
@w_moneda            = op_moneda,
@w_banco             = op_banco,
@w_oficina           = op_oficina,
@w_oficial           = op_oficial,
@w_tramite           = op_tramite,
@w_estado            = op_estado
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount = 0                
   return 0
   
if @w_estado  in (  @w_est_castigado ,@w_est_cancelado,@w_est_novigente)
   return 0

--- NO CASTIGAR OPERACIONES EN ESTADO QUE NO PROCESA 
if exists(select 1 from ca_estado
where es_codigo = @w_estado
and   es_procesa = 'N')
begin
   return 0
end

select @w_fecha_proceso = @w_fecha_ult_proceso

if @w_fecha_proceso <> @w_fecha_ult_proceso
begin
   select @w_error = 724510, @o_msg = 'ERROR FECHA DE PROCESO <> A LA DEL SISTEMA' 
   goto ERROR_FIN
end
	
	
--- GENERAR LA TRANSACCION DE CASTIGO 
exec @w_secuencial =  sp_gen_sec
@i_operacion       = @i_operacionca

if @@trancount = 0 begin
   begin tran --atomicidad por castigo
   select @w_commit = 'S'
end
---VALIDAR HONORARIOS QUE NO SE PAGARON
---POR DEFINICON DE PRIORIDADES CON ERROR
---Y MUY COMPLICADO CORREGIR HISTORIAS DE TABLA DE AMORTIZACION
---POR LO GRANDES
if exists (select 1 from ca_amortizacion
	where am_operacion = @i_operacionca
	and am_concepto in ('IVAHONOABO','HONABO')
	and am_cuota <> am_pagado
	and am_gracia = 0)
begin
	update  ca_amortizacion
	set am_cuota     = am_pagado, 
	    am_acumulado = am_pagado
	where am_operacion = @i_operacionca
	and am_concepto in ('IVAHONOABO','HONABO')
	and am_cuota <> am_pagado
	and am_gracia = 0
	if @@error <> 0 begin
	   select @w_error = 708165, @o_msg = 'ERROR EN ACTUALIZACION DE CA_AMORTIZACION ' 
	   goto ERROR_FIN
	end
end
	


insert into ca_transaccion(
tr_secuencial,          tr_fecha_mov,                   tr_toperacion,
tr_moneda,              tr_operacion,                   tr_tran,
tr_en_linea,            tr_banco,                       tr_dias_calc,
tr_ofi_oper,            tr_ofi_usu,                     tr_usuario,
tr_terminal,            tr_fecha_ref,                   tr_secuencial_ref,
tr_estado,              tr_observacion,                 tr_gerente,
tr_gar_admisible,       tr_reestructuracion,            tr_calificacion,
tr_fecha_cont,          tr_comprobante)  
values(
@w_secuencial,          @w_fecha_proceso,               @w_toperacion,
@w_moneda,              @i_operacionca,                 'CAS',
'N',                    @w_banco,                       0,
@w_oficina,             @w_oficina,                     @s_user,
@s_term,                @w_fecha_proceso,               0,
'ING',                  'CASTIGO DE OPERACIONES',       @w_oficial,
'',                     '',                             'E',
@w_fecha_proceso,       0)

if @@error <> 0 begin
   select @w_error = 708165, @o_msg = 'ERROR AL REGISTRAR LA TRANSACCION DE CASTIGO ' 
   goto ERROR_FIN
end


--- REGISTRAR VALORES QUE SALEN DE LOS ESTADOS INICIALES 
insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = am_dividendo,
dtr_concepto     = am_concepto,
dtr_estado       = case am_estado when @w_est_novigente then @w_estado else am_estado end,
dtr_periodo      = 0,
dtr_codvalor     = co_codigo * 1000 + case am_estado when @w_est_novigente then @w_estado else am_estado end * 10,
dtr_monto        = sum(am_acumulado - am_pagado),  
dtr_monto_mn     = 0,
dtr_moneda       = @w_moneda,
dtr_cotizacion   = 1,
dtr_tcotizacion  = 'N',
dtr_afectacion   = 'D',
dtr_cuenta       = '',
dtr_beneficiario = '',
dtr_monto_cont   = 0
from ca_amortizacion, ca_concepto
where am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado
and   co_concepto  = am_concepto
group by am_dividendo, am_concepto, case am_estado when @w_est_novigente then @w_estado else am_estado end,
         co_codigo * 1000 + case am_estado when @w_est_novigente then @w_estado else am_estado end * 10
having sum(am_acumulado - am_pagado) > 0

if @@error <> 0  begin
   select @w_error = 708165, @o_msg = 'ERROR AL REGISTRAR DETALLES DE SALIDA'
   goto ERROR_FIN
end

-- SUMARIZAR CONCEPTOS CAP, INT, OTR POR OPERACION
select
concepto    = case when dtr_concepto = 'CAP'                                  then 'CAP' 
                   when dtr_concepto in ('INT', 'IMO', 'INTTRAS')             then 'INT' 
                   when dtr_concepto not in ('CAP', 'INT', 'IMO', 'INTTRAS')  then 'MIPYMES' 
              end,
monto       = sum(dtr_monto),
monto_cc    = convert(money,0)
into #sumariza
from ca_det_trn
where dtr_operacion   = @i_operacionca
and   dtr_secuencial  = @w_secuencial
and   dtr_estado      in (@w_est_vencido, @w_est_vigente, @w_est_novigente)
group by case when dtr_concepto = 'CAP'                                 then 'CAP' 
              when dtr_concepto in ('INT', 'IMO', 'INTTRAS')            then 'INT' 
              when dtr_concepto not in ('CAP', 'INT', 'IMO', 'INTTRAS') then 'MIPYMES' 
         end

-- RUBROS EN SUSPENSO 
if @w_estado not in (@w_est_vigente, @w_est_vencido) begin
   select 
   concepto    = case when am_concepto = 'CAP'                                 then 'CAP' 
                      when am_concepto in ('INT', 'IMO', 'INTTRAS')            then 'INT' 
                      when am_concepto not in ('CAP', 'INT', 'IMO', 'INTTRAS') then 'MIPYMES' 
                 end,
   monto    = sum(am_acumulado - am_pagado),
   monto_cc = convert(money,0)
   into #sumariza1
   from cob_cartera..ca_amortizacion
   where am_operacion  = @i_operacionca
   and   am_concepto  in ('CAP')
   and   am_estado     in (@w_est_suspenso, @w_est_novigente)
   group by case when am_concepto = 'CAP'                                 then 'CAP' 
                 when am_concepto in ('INT', 'IMO', 'INTTRAS')            then 'INT' 
                 when am_concepto not in ('CAP', 'INT', 'IMO', 'INTTRAS') then 'MIPYMES' 
      end
      
   insert into #sumariza1
   select 
   concepto    = case when am_concepto = 'CAP'                                 then 'CAP' 
                      when am_concepto in ('INT', 'IMO', 'INTTRAS')            then 'INT' 
                      when am_concepto not in ('CAP', 'INT', 'IMO', 'INTTRAS') then 'MIPYMES' 
                 end,
   monto    = sum(am_acumulado - am_pagado),
   monto_cc = convert(money,0)
   from cob_cartera..ca_amortizacion
   where am_operacion  = @i_operacionca
   and   am_concepto  not in ('CAP','MIPYMES', 'IVAMIPYMES', 'INT', 'IMO', 'INTTRAS')
   and   am_estado     in (@w_est_suspenso)
   group by case when am_concepto = 'CAP'                                 then 'CAP' 
                 when am_concepto in ('INT', 'IMO', 'INTTRAS')            then 'INT' 
                 when am_concepto not in ('CAP', 'INT', 'IMO', 'INTTRAS') then 'MIPYMES' 
      end
end

--- BUSCAR EL DIA ANTERIOR HABIL 

select @w_ciudad = pa_int
from cobis..cl_parametro
where pa_nemonico = 'CIUN'
and   pa_producto = 'ADM'

select @w_ant_habil = dateadd(dd, -1, @w_fecha_proceso)

while exists (select 1
              from cobis..cl_dias_feriados
              where df_fecha   = @w_ant_habil
              and   df_ciudad  = @w_ciudad)
begin
   select @w_ant_habil = dateadd(dd, -1, @w_ant_habil)
end

--- BUSCAR VALORES PROVISIONES CONTRACICLICAS EN LA sb_dato_operacion 

select 
@w_prov_cap_cc = do_prov_con_cap,
@w_prov_int_cc = do_prov_con_int,
@w_prov_otr_cc = do_prov_con_cxc
from cob_conta_super..sb_dato_operacion
where do_fecha = @w_ant_habil
and   do_banco = @w_banco

if @@rowcount = 0 select @w_prov_cap_cc = 0, @w_prov_int_cc = 0, @w_prov_otr_cc = 0 

update #sumariza set
monto_cc = case when @w_prov_cap_cc > monto then monto else @w_prov_cap_cc end
where concepto = 'CAP'

update #sumariza set
monto_cc = case when @w_prov_int_cc > monto then monto else @w_prov_int_cc end
where concepto = 'INT'

update #sumariza set
monto_cc = case when @w_prov_otr_cc > monto then monto else @w_prov_otr_cc end
where concepto = 'MIPYMES'

--- INSERTAR EN LA ca_det_trn <ContraCiclica> 

insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = 0,
dtr_concepto     = concepto,
dtr_estado       = 1,
dtr_periodo      = 0,
dtr_codvalor     = co_codigo * 1000 + 19,
dtr_monto        = monto_cc,
dtr_monto_mn     = 0,
dtr_moneda       = @w_moneda,
dtr_cotizacion   = 1,
dtr_tcotizacion  = 'N',
dtr_afectacion   = 'C',
dtr_cuenta       = '',
dtr_beneficiario = '',
dtr_monto_cont   = 0
from #sumariza, ca_concepto
where monto_cc > 0
and   concepto = co_concepto

if @@error <> 0  begin
   select @w_error = 710001, @o_msg = 'ERROR AL INSERTAR ca_det_trn <ContraCiclica> '
   goto ERROR_FIN
end

--- INSERTAR EN LA ca_det_trn <ProCiclica> 

insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = 0,
dtr_concepto     = concepto,
dtr_estado       = 1,
dtr_periodo      = 0,
dtr_codvalor     = co_codigo * 1000 + 18,
dtr_monto        = monto - monto_cc,
dtr_monto_mn     = 0,
dtr_moneda       = @w_moneda,
dtr_cotizacion   = 1,
dtr_tcotizacion  = 'N',
dtr_afectacion   = 'C',
dtr_cuenta       = '',
dtr_beneficiario = '',
dtr_monto_cont   = 0
from #sumariza, ca_concepto
--where monto_cc > 0
where concepto = co_concepto

if @@error <> 0  begin
   select @w_error = 710001, @o_msg = 'ERROR AL INSERTAR ca_det_trn <Prociclica> '
   goto ERROR_FIN
end

--- PRUEBA
if @w_estado not in (@w_est_vigente, @w_est_vencido) begin

insert into ca_det_trn
   select 
   dtr_secuencial   = @w_secuencial,
   dtr_operacion    = @i_operacionca,
   dtr_dividendo    = 0,
   dtr_concepto     = concepto,
   dtr_estado       = 1,
   dtr_periodo      = 0,
   dtr_codvalor     = co_codigo * 1000 + 18,
   dtr_monto        = monto - monto_cc,
   dtr_monto_mn     = 0,
   dtr_moneda       = @w_moneda,
   dtr_cotizacion   = 1,
   dtr_tcotizacion  = 'N',
   dtr_afectacion   = 'C',
   dtr_cuenta       = '',
   dtr_beneficiario = '',
   dtr_monto_cont   = 0
   from #sumariza1, ca_concepto
   --where monto_cc > 0
   where concepto = co_concepto
   
   if @@error <> 0  begin
      select @w_error = 710001, @o_msg = 'ERROR AL INSERTAR ca_det_trn <Prociclica> '
      goto ERROR_FIN
   end
end

---INSERTAR EN EL TRASLADO DEL DIFERIDO 
select @w_saldo_dif = isnull(( dif_valor_total - dif_valor_pagado), 0)
from ca_diferidos
where dif_operacion = @i_operacionca
and (dif_valor_total - dif_valor_pagado) > 0

if @w_saldo_dif > 0
begin
   -- REGISTRAR VALORES DIFERIDOS QUE SALEN DE LA OFICINA ORIGEN 

   select 
   'orden'     = row_number() over (order by dif_concepto asc),
   'concepto'  = dif_concepto,
   'vlr_tot'   = dif_valor_total,
   'vlr_pag'   = dif_valor_pagado
   into #diferidos
   from ca_diferidos
   where dif_operacion = @i_operacionca

   select @w_orden = 0
   while 1=1
   begin
   
      select top 1
      @w_orden    = orden,
      @w_concepto = concepto,
      @w_sld_cpto = vlr_tot - vlr_pag
      from #diferidos
      order by orden asc
      if @@rowcount = 0
         break      
         
      if @w_concepto = 'CAP' 
         select @w_concepto_prov = '1' , @w_saldo_act = @w_prov_cap_cc
      if @w_concepto = 'INT' 
         select @w_concepto_prov = '2' , @w_saldo_act = @w_prov_int_cc
      if @w_concepto in ('IVAMIPYME', 'MIPYMES') 
         select @w_concepto_prov = '5' , @w_saldo_act = @w_prov_otr_cc
	 
      select @w_saldo_ant = isnull(sum(ppa_provcc),0)
      from   cob_credito..cr_provision_periodo_anterior
      where  ppa_banco    = @w_banco
      and    ppa_concepto = @w_concepto_prov
      
      -- Validacion saldos periodos actual y anterior.
      
      -- Valor Periodo anterior
      if @w_saldo_ant > 0 and @w_sld_cpto > 0 begin
         if @w_saldo_ant > @w_sld_cpto begin         -- Si saldo periodo anterior es mayor al saldo concepto
            select @w_saldo_ant = @w_sld_cpto        -- Periodo anterior es igual a saldo concepto
            select @w_saldo_act = 0                  -- No se genera saldo para Periodo Actual
            select @w_sld_cpto  = 0                  -- No queda saldo para el concepto
         end
         else
            select @w_sld_cpto = @w_sld_cpto - @w_saldo_ant -- Nuevo Saldo concepto 
      end
         
      -- Valor Periodo actual
      if @w_saldo_act > 0 and @w_sld_cpto > 0 begin
         if @w_saldo_act > @w_sld_cpto begin         -- Si saldo periodo actual es mayor al saldo concepto
            select @w_saldo_act = @w_sld_cpto        -- Periodo actual es igual a saldo concepto
            select @w_sld_cpto  = 0                  -- No queda saldo para el concepto
         end
         else
            select @w_sld_cpto = @w_sld_cpto - @w_saldo_act -- Nuevo Saldo concepto          
      end 
      
      if @w_sld_cpto > 0 begin-- Si aun queda saldo concepto sin afectar por el castigo se envia contra Periodo Anterior
         select @w_saldo_ant = @w_saldo_ant + @w_sld_cpto
      end
            
      if @w_saldo_ant > 0 begin
         insert into ca_det_trn
         select 
         dtr_secuencial   = @w_secuencial,
         dtr_operacion    = @i_operacionca,
         dtr_dividendo    = 1,
         dtr_concepto     = @w_concepto,
         dtr_estado       = @w_est_diferido,
         dtr_periodo      = 0,
         dtr_codvalor     = (co_codigo * 1000 +  @w_est_diferido * 10) + 5,
         dtr_monto        = @w_saldo_ant,  -- Saldo Provision Periodo Anterior
         dtr_monto_mn     = 0,
         dtr_moneda       = @w_moneda,
         dtr_cotizacion   = 1,
         dtr_tcotizacion  = 'N',
         dtr_afectacion   = 'C',
         dtr_cuenta       = '',
         dtr_beneficiario = '',
         dtr_monto_cont   = 0
         from  ca_concepto
         where co_concepto  = @w_concepto
         
         if @@error <> 0  begin
            select @w_error = 722205, @o_msg = 'ERROR AL REGISTRAR DETALLES DE SALIDA: ' + @w_banco
            goto ERROR_FIN
         end

         insert into ca_det_trn
         select 
         dtr_secuencial   = @w_secuencial,
         dtr_operacion    = @i_operacionca,
         dtr_dividendo    = 1,
         dtr_concepto     = @w_concepto,
         dtr_estado       = @w_est_diferido,
         dtr_periodo      = 0,
         dtr_codvalor     = (co_codigo * 1000 +  @w_est_diferido * 10) ,
         dtr_monto        = @w_saldo_ant,  -- Saldo Provision Periodo Anterior
         dtr_monto_mn     = 0,
         dtr_moneda       = @w_moneda,
         dtr_cotizacion   = 1,
         dtr_tcotizacion  = 'N',
         dtr_afectacion   = 'D',
         dtr_cuenta       = '',
         dtr_beneficiario = '',
         dtr_monto_cont   = 0
         from  ca_concepto
         where co_concepto  = @w_concepto
         
         if @@error <> 0  begin
            select @w_error = 722205, @o_msg = 'ERROR AL REGISTRAR DETALLES DE SALIDA: ' + @w_banco
            goto ERROR_FIN
         end         
      end
      
      if @w_saldo_act > 0 begin
         insert into ca_det_trn
         select 
         dtr_secuencial   = @w_secuencial,
         dtr_operacion    = @i_operacionca,
         dtr_dividendo    = 1,
         dtr_concepto     = @w_concepto,
         dtr_estado       = @w_est_diferido,
         dtr_periodo      = 0,
         dtr_codvalor     = (co_codigo * 1000 +  @w_est_diferido * 10) + 6,
         dtr_monto        = @w_saldo_act,  -- Saldo Provision Periodo Actual
         dtr_monto_mn     = 0,
         dtr_moneda       = @w_moneda,
         dtr_cotizacion   = 1,
         dtr_tcotizacion  = 'N',
         dtr_afectacion   = 'C',
         dtr_cuenta       = '',
         dtr_beneficiario = '',
         dtr_monto_cont   = 0
         from  ca_concepto
         where co_concepto  = @w_concepto
         
         if @@error <> 0  begin
            select @w_error = 722205, @o_msg = 'ERROR AL REGISTRAR DETALLES DE SALIDA: ' + @w_banco
            goto ERROR_FIN
         end

         insert into ca_det_trn
         select 
         dtr_secuencial   = @w_secuencial,
         dtr_operacion    = @i_operacionca,
         dtr_dividendo    = 1,
         dtr_concepto     = @w_concepto,
         dtr_estado       = @w_est_diferido,
         dtr_periodo      = 0,
         dtr_codvalor     = (co_codigo * 1000 +  @w_est_diferido * 10),
         dtr_monto        = @w_saldo_act,  -- Saldo Provision Periodo Actual
         dtr_monto_mn     = 0,
         dtr_moneda       = @w_moneda,
         dtr_cotizacion   = 1,
         dtr_tcotizacion  = 'N',
         dtr_afectacion   = 'D',
         dtr_cuenta       = '',
         dtr_beneficiario = '',
         dtr_monto_cont   = 0
         from  ca_concepto
         where co_concepto  = @w_concepto
         
         if @@error <> 0  begin
            select @w_error = 722205, @o_msg = 'ERROR AL REGISTRAR DETALLES DE SALIDA: ' + @w_banco
            goto ERROR_FIN
         end

      end
      
      update ca_diferidos
      set dif_valor_pagado = dif_valor_total
      where dif_operacion  = @i_operacionca
      and   dif_concepto   = @w_concepto
         
	  delete from #diferidos where orden = @w_orden
     
    end -- end while          

end -- Diferido               

--- CAMBIAR DE ESTADO AL RUBRO DE LA OPERACION 
update ca_amortizacion set
am_estado = @w_est_castigado
where am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado

if @@error <> 0  begin
   select @w_error = 710003, @o_msg = 'ERROR AL ACTUALIZAR EL ESTADO DE LOS RUBROS DE LA OPERACION '
   goto ERROR_FIN
end

--- UNIFICAR RUBROS INNECESARIAMENTE SEPARADOS 
select 
operacion = am_operacion, 
dividendo = am_dividendo, 
concepto  = am_concepto,
secuencia = min(am_secuencia),
cuota     = isnull(sum(am_cuota),     0.00),
gracia    = isnull(sum(am_gracia),    0.00),
acumulado = isnull(sum(am_acumulado), 0.00),
pagado    = isnull(sum(am_pagado),    0.00)
into #para_juntar
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_estado   <> @w_est_cancelado
group by am_operacion, am_dividendo, am_concepto, am_estado

if @@error <> 0  begin
   select @w_error = 710001, @o_msg = 'ERROR AL GENERAR TABLA DE TRABAJO para_juntar '
   goto ERROR_FIN
end
   
update ca_amortizacion set
am_cuota     = cuota,
am_gracia    = gracia,
am_acumulado = acumulado,
am_pagado    = pagado
from   #para_juntar
where  am_operacion = operacion
and    am_dividendo = dividendo
and    am_concepto  = concepto
and    am_secuencia = secuencia

if @@error <> 0  begin
   select @w_error = 708165, @o_msg = 'AL ACUALIZAR LOS SALDOS DE LOS RUBROS UNIFICADOS ' 
   goto ERROR_FIN
end
   
delete ca_amortizacion
from   #para_juntar
where  am_operacion  = operacion
and    am_dividendo  = dividendo
and    am_concepto   = concepto
and    am_secuencia  > secuencia
and    am_estado    <> @w_est_cancelado

if @@error <> 0  begin
   select @w_error = 710003, @o_msg = 'ERROR AL ELIMINAR REGISTROS UNIFICADOS' 
   goto ERROR_FIN
end

-- NYMR 

--- NYMR el estado de la operacion en la cobranza

select @w_estado_cobr = co_estado
from cob_cartera..ca_operacion,
     cob_credito..cr_operacion_cobranza,
     cob_credito..cr_cobranza
where op_operacion     = @i_operacionca
and   oc_num_operacion = op_banco
and   co_cobranza      = oc_cobranza

if @w_estado_cobr = @w_estado_prejuridico 
begin 

   --- CAMBIAR EL ESTADO DE LA OPERACION A CASTIGO 
   -- NYMR
   select 
   cc_cobranza   = oc_cobranza,
   cc_banco      = cj_banco,
   cc_estado_ant = convert(varchar(10), null),
   cc_estado     = cj_estado_cb,
   cc_codigo_ab  = cj_codigo_ab
   into  #cambios_cobranza
   from  cob_credito..cr_operacion_cobranza, ca_op_cobranza_jud
   where cj_banco    = oc_num_operacion
   and   cj_banco    = @w_banco
   
   
   update #cambios_cobranza set
   cc_estado_ant = co_estado
   from   cob_credito..cr_cobranza
   where  co_cobranza = cc_cobranza
   
   
   --- INGRESO EL CAMBIO DE ESTADO A CA
   insert into cob_credito..cr_cambio_estados(
   ce_cobranza,    ce_secuencial,  ce_estado_ant,  
   ce_estado_act,  ce_funcionario, ce_fecha)
   select
   cc_cobranza,    isnull(max(ce_secuencial) + 1, 1), isnull(cc_estado_ant, 'NO'), 
   cc_estado,      'script',               (select convert(varchar,(select fp_fecha from cobis..ba_fecha_proceso),101))
   from  #cambios_cobranza left outer join cob_credito..cr_cambio_estados on cc_cobranza = ce_cobranza
   group  by cc_cobranza, cc_estado_ant, cc_estado
   

   --- ACTUALIZO A CP LAS COBRANZAS SOLICITADAS 
   update cob_credito..cr_cobranza set
   co_estado        = cc_estado,
   co_observa       = 'CAMBIO COBRO ADMINISTRATIVO POR CASTIGO', 
   co_abogado       = cc_codigo_ab
   from  #cambios_cobranza
   where co_cobranza = cc_cobranza

   update ca_operacion set
   op_estado_cobranza = 'CA'
   where  op_operacion = @i_operacionca


end   

--- CAMBIAR EL ESTADO DE LA OPERACION A CASTIGO 

--GENERACION DE LA COMISION DIFERIDA
exec @w_error     = sp_comision_diferida
@s_date           = @s_date,
@i_operacion      = 'A',
@i_operacionca    = @i_operacionca,
@i_secuencial_ref = @w_secuencial 

if @w_error <> 0  begin 
   select @w_error = 724589, @o_msg = 'ERROR EN EL sp_comision_diferida CON OPCION A'  
   goto ERROR_FIN
end

update ca_operacion set
op_estado = @w_est_castigado
where  op_operacion = @i_operacionca

if @@error <> 0  begin
   select @w_error = 710002, @o_msg = 'ERROR AL CAMBIAR EL ESTADO DE LA OPERACION ' 
   goto ERROR_FIN
end

-- ACTUALIZAR ESTADO DE LA GARANTIA
update cob_custodia..cu_custodia
set    cu_estado = 'K'
from   cob_credito..cr_gar_propuesta 
where  gp_tramite = @w_tramite
and    gp_garantia = cu_codigo_externo 
and    cu_valor_actual > 0

if @@error <> 0  begin
   select @w_error = 710003, @o_msg = 'ERROR AL CAMBIAR EL ESTADO DE LA GARANTIA ' 
   goto ERROR_FIN
end

if @w_commit = 'S' begin 
   commit tran
   select @w_commit = 'N'
end

return 0

ERROR_FIN:

if @w_commit = 'S'
   rollback tran

return @w_error

go

