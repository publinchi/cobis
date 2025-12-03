/************************************************************************/
/*   Nombre Fisico:      corrmon.sp                                     */
/*   Nombre Logico:   	 sp_correccion_monetaria                        */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Credito y Cartera                              */
/*   Disenado por:       Xavier Maldonado                               */
/*   Fecha de escritura: Oct. 2001.                                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                            MODIFICACIONES                            */
/*   FECHA                  AUTOR                  RAZON                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_op_calificacion*/
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_rubros_correccion_tmp')
   drop table ca_rubros_correccion_tmp
go

CREATE TABLE ca_rubros_correccion_tmp
(spid               int,
 dividendo          smallint,
 concepto           catalogo,
 monto_hoy          money,
 monto_siguiente    money,
 estado             tinyint,
 secuencia          tinyint,
 periodo            tinyint,
 tipo_rubro         char
)
go

--alter table ca_rubros_correccion_tmp partition 200
go

--alter table ca_rubros_correccion_tmp lock datarows
go

if exists (select * from sysobjects where name = 'sp_correccion_monetaria')
   drop proc sp_correccion_monetaria
go

create proc sp_correccion_monetaria
@s_user                 login,
@s_term                 varchar (30),
@s_date                 datetime,
@s_ofi                  smallint,
@i_en_linea             char (1),
@i_toperacion           catalogo,
@i_banco                cuenta,
@i_operacionca          int,
@i_estado_op            tinyint,
@i_oficina              smallint,
@i_gerente              smallint,
@i_moneda               smallint,
@i_fecha_proceso        datetime,
@i_cotizacion_hoy       float,
@i_cotizacion_siguiente float,
@i_aplicar_fecha_valor  char(1)

as

declare 
   @w_sp_name           descripcion,
   @w_secuencial        int,
   @w_est_suspenso      tinyint,
   @w_est_castigado     tinyint,
   @w_est_cancelado     tinyint,
   @w_moneda_nac        tinyint,
   @w_dividendo         smallint,
   @w_concepto          catalogo,
   @w_secuencia         tinyint,
   @w_estado            tinyint,
   @w_periodo           tinyint,
   @w_tr_estado         catalogo,
   @w_codvalor          int,
   @w_monto_hoy         money,
   @w_monto_siguiente   money,
   @w_correccion        money,
   @w_transaccion_nueva char (1),
   @w_act_transacc      char (1),
   @w_dtr_monto         money,
   @w_op_calificacion   catalogo,
   @w_op_gar_admisible  char(1),
   @w_tipo_rubro        char,
   @w_ro_concepto       catalogo,
   @w_ro_fpago          char(1),
   @w_am_dividendo      int,
   @w_am_acumulado      float,
   @w_am_pagado         float,
   @w_cotizacion_seg    float,
   @w_nuevo_monto       float,
   @w_saldo_pesos       float,
   @w_error             int,
   @w_num_reest         int,
   @w_reestructuracion  char(1),
   @w_op_estado         int,
   @w_am_secuencial     int,
   @w_inserta           char(1),
   @w_rowcount          int
   

-- CARGA DE VARIABLES DE TRABAJO
select @w_sp_name       = 'sp_correccion_monetaria',
       @w_act_transacc  = 'N',
       @w_transaccion_nueva = 'N'


select @w_dtr_monto = 0
-- DETERMINAR FECHA DEL MOVIMIENTO DEPENDIENDO SI ES O NO FECHA VALOR


select @w_op_calificacion  = isnull(op_calificacion,''),
       @w_op_gar_admisible = isnull(op_gar_admisible,''),
       @w_num_reest        = isnull(op_numero_reest, 0),
       @w_op_estado        = op_estado
from   ca_operacion 
where  op_operacion = @i_operacionca

if @w_num_reest > 0
   select @w_reestructuracion = 'S'
else
   select @w_reestructuracion = 'N'

-- SELECCION DE ESTADOS DE CARTERA
select @w_est_cancelado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CANCELADO'

select @w_est_suspenso  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'SUSPENSO'

select @w_est_castigado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CASTIGADO'

-- CODIGO DE RUBRO MONEDA NACIONAL
select @w_moneda_nac = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   delete ca_rubros_correccion_tmp where spid = @@spid
   return 710076
end

-- PARA CONTABILIDAD
-- VERIFICAR NECESIDAD DE CREAR NUEVA TRANSACCION
select @w_secuencial = null

-- SE BUSCA LA ULTIMA TRANSACCION VALIDA
exec @w_error = sp_valida_existencia_prv
     @s_user              = @s_user,
     @s_term              = @s_term,
     @s_date              = @s_date,
     @s_ofi               = @s_ofi,
     @i_en_linea          = 'N',
     @i_operacionca       = @i_operacionca,
     @i_fecha_proceso     = @i_fecha_proceso,
     @i_tr_observacion    = 'CORRECCION MONETARIA',
     @i_gar_admisible     = @w_op_gar_admisible,
     @i_reestructuracion  = @w_reestructuracion,
     @i_calificacion      = @w_op_calificacion,
     @i_toperacion        = @i_toperacion,
     @i_moneda            = @i_moneda,
     @i_oficina           = @i_oficina,
     @i_banco             = @i_banco,
     @i_gerente           = @i_gerente,
     @i_moneda_uvr        = @i_moneda,
     @o_secuencial        = @w_secuencial  out

if @w_error != 0
begin
   delete ca_rubros_correccion_tmp where spid = @@spid
   return @w_error
end
select @w_secuencial = @w_secuencial + 1

-- BORRAR DATOS DE LA TEMPORAL PARA LOS RUBROS
delete ca_rubros_correccion_tmp where spid = @@spid

if @@error != 0
begin
   delete ca_rubros_correccion_tmp where spid = @@spid
   return 710003
end
-- SELECCIONAR LOS RUBROS A CALCULAR CORRECCION MONETARIA EN TEMPORAL
insert into ca_rubros_correccion_tmp
select spid            = @@spid,
       dividendo       = am_dividendo,
       concepto        = am_concepto,
       monto_hoy       = (case when am_acumulado - am_pagado < 0 then 0 else am_acumulado - am_pagado end) * @i_cotizacion_hoy,              -- REQ 175: PEQUEÑA EMPRESA
       monto_siguiente = (case when am_acumulado - am_pagado < 0 then 0 else am_acumulado - am_pagado end) * @i_cotizacion_siguiente,        -- REQ 175: PEQUEÑA EMPRESA
       estado          = am_estado,
       secuencia       = am_secuencia,
       periodo         = am_periodo,
       tipo_rubro      = ro_tipo_rubro
from   ca_rubro_op, ca_amortizacion
where  ro_operacion   = am_operacion
and    ro_operacion   = @i_operacionca
and    am_operacion   = @i_operacionca
and    ro_concepto    = am_concepto
and    am_estado     <> @w_est_cancelado
and    ro_tipo_rubro in ('C', 'I', 'M')     -- CAPITAL o INTERESES o INTERES DE MORA


if @@error != 0
begin
   delete ca_rubros_correccion_tmp where spid = @@spid
   return 710001
end
-- CURSOR PARA SELECCIONAR LOS RUBROS A CALCULAR CORRECCION MONETARIA
declare
   cursor_rubros cursor
   for select dividendo,       concepto,  monto_hoy,
              monto_siguiente, estado,    secuencia,
              periodo,         tipo_rubro
       from   ca_rubros_correccion_tmp
       where spid = @@spid
open  cursor_rubros

fetch cursor_rubros
into  @w_dividendo,       @w_concepto,   @w_monto_hoy,
      @w_monto_siguiente, @w_estado,     @w_secuencia,
      @w_periodo,         @w_tipo_rubro

while @@fetch_status = 0 
begin
   if @@fetch_status = -1
   begin
      delete ca_rubros_correccion_tmp where spid = @@spid
      return 70899
   end
   -- INICIALIZAR VARIABLES
   select @w_correccion = 0,
          @w_dtr_monto  = 0,
          @w_codvalor   = 0

   
   -- CALCULAR VALOR DE CORRECCION
   select @w_correccion = @w_monto_siguiente - @w_monto_hoy
   
   -- SI NO EXISTE VALOR DE CORRECCION MONETARIA VA AL SIGUIENTE REGISTRO
   if @w_correccion = 0
      goto SIGUIENTE
   
   -- ACTUALIZAR EL VALOR DE LA CORRECCION MONETARIA EN CA_AMORTIZACION
   if @i_estado_op in (@w_est_suspenso, @w_est_castigado)
   begin
     -- cambio de los campos am_correccion_xxx a la nueva tabla ca_correccion
     if exists (select am_operacion
                from   ca_amortizacion
                where  am_operacion = @i_operacionca
                and    am_dividendo = @w_dividendo
                and    am_concepto  = @w_concepto
                and    am_estado    = @w_estado
                and    am_secuencia = @w_secuencia
                and    am_periodo   = @w_periodo)
      begin
         update ca_correccion
         set    co_correccion_sus_mn = isnull(co_correccion_sus_mn,0) + @w_correccion
         where  co_operacion = @i_operacionca
         and    co_dividendo = @w_dividendo
         and    co_concepto  = @w_concepto
         
         if @@error<> 0 
         begin
            close cursor_rubros
            deallocate cursor_rubros
            delete ca_rubros_correccion_tmp where spid = @@spid
            return 705050
         end
      end --if exists (select ....
   end -- if @i_estado_op in (@w_est_suspenso, @w_est_castigado)
   ELSE
   begin
      if exists (select am_operacion from ca_amortizacion
                 where  am_operacion = @i_operacionca
                 and    am_dividendo = @w_dividendo
                 and    am_concepto  = @w_concepto
                 and    am_estado    = @w_estado
                 and    am_secuencia = @w_secuencia
                 and    am_periodo   = @w_periodo)
      begin
         update ca_correccion
         set    co_correccion_mn = isnull(co_correccion_mn,0) + @w_correccion
         where  co_operacion = @i_operacionca
         and    co_dividendo = @w_dividendo
         and    co_concepto  = @w_concepto
         
         if @@error<> 0 
         begin
           close cursor_rubros
           deallocate cursor_rubros
           delete ca_rubros_correccion_tmp where spid = @@spid
           return 705050
         end
      end -- if exists (select....
   end -- else
   
   -- ACTUALIZAR TRANSACCION CONTABLE
   if @w_tipo_rubro != 'M' or @i_estado_op = @w_est_suspenso -- INTERES Y CAPITAL U OBLIGACION EN SUSPENSO
   begin
      select @w_codvalor = (co_codigo * 1000) + (@i_estado_op * 10) + 0
      from   ca_concepto
      where  co_concepto = @w_concepto
   end
   ELSE
   begin -- MORA EN OBLIGACION VIGENTE
      select @w_codvalor = (co_codigo * 1000) + (20) + 0
      from   ca_concepto
      where  co_concepto = @w_concepto
   end
   
   if @w_tipo_rubro = 'C' and @i_estado_op = @w_est_suspenso
      select @w_estado = @i_estado_op
   


   select @w_inserta = ''

   if exists (select 1 from ca_amortizacion 
              where am_operacion = @i_operacionca
              and am_concepto    = @w_concepto )
      select @w_inserta = 'S'
   else
      select @w_inserta = 'N'



   if @w_inserta = 'S'
   begin

   select @w_dtr_monto = dtr_monto
   from   ca_det_trn
   where  dtr_secuencial = @w_secuencial
   and    dtr_operacion  = @i_operacionca
   and    dtr_dividendo  = 0
   and    dtr_concepto   = @w_concepto
   and    dtr_codvalor   = @w_codvalor
   and    dtr_estado     = @w_estado
   
   if @@rowcount = 0 -- NO EXISTE
   begin
      insert into ca_det_trn
            (dtr_secuencial, dtr_operacion,  dtr_dividendo,
             dtr_concepto,   dtr_estado,     dtr_periodo,
             dtr_codvalor,   dtr_monto,      dtr_monto_mn,
             dtr_moneda,     dtr_cotizacion, dtr_tcotizacion,
             dtr_afectacion, dtr_cuenta,     dtr_beneficiario,
             dtr_monto_cont)
      values(@w_secuencial,  @i_operacionca, 0,
             @w_concepto,    @w_estado,      0,
             @w_codvalor,    @w_correccion,  @w_correccion,
             @w_moneda_nac,  1.00,           'N',
             'D',            '',             '',
             0)
      
      if @@error != 0 
      begin
         close cursor_rubros
         deallocate cursor_rubros
         delete ca_rubros_correccion_tmp where spid = @@spid
         return 708166
      end 
   end
   ELSE -- YA EXISTE
   begin
      select @w_dtr_monto = isnull(sum(@w_dtr_monto + @w_correccion),0)    ---XMA el CACONTA.SP se encarga de contabilizar solo la <>
      
      update ca_det_trn
      set    dtr_monto      = @w_dtr_monto,
             dtr_cotizacion = 1.0,
             dtr_monto_mn   = @w_dtr_monto
      where  dtr_secuencial = @w_secuencial
      and    dtr_operacion  = @i_operacionca
      and    dtr_codvalor   = @w_codvalor
      and    dtr_dividendo  = 0
      and    dtr_estado     = @w_estado
      and    dtr_periodo    = 0
      and    dtr_concepto   = @w_concepto
      
      if @@error != 0 
      begin
         close cursor_rubros
         deallocate cursor_rubros
         delete ca_rubros_correccion_tmp where spid = @@spid
         return 708165
      end
   end
   end   

   select @w_act_transacc = 'S'
   
SIGUIENTE:
   fetch cursor_rubros
   into  @w_dividendo,       @w_concepto, @w_monto_hoy,
         @w_monto_siguiente, @w_estado,   @w_secuencia,
         @w_periodo, @w_tipo_rubro
end -- while cursor_rubros

close cursor_rubros
deallocate cursor_rubros

if @w_act_transacc = 'S'
begin
   if @w_transaccion_nueva = 'N' 
   begin
      update ca_transaccion
      set    tr_dias_calc        = tr_dias_calc + 1,
             tr_estado           = 'ING',
             tr_fecha_mov        = @s_date,
             tr_calificacion     = isnull(@w_op_calificacion,''),
             tr_gar_admisible    = isnull(@w_op_gar_admisible,'')
      where  tr_secuencial = @w_secuencial
      and    tr_operacion    = @i_operacionca 
      
      if @@error != 0
      begin
         delete ca_rubros_correccion_tmp where spid = @@spid
         return 710492
      end
        
   end 
end

-- ACTUALIZACION DE LOS VALORES DE SEGUROS VENCIDOS
declare  cSeg cursor
  for select ro_concepto, ro_fpago
      from   ca_rubro_op, ca_concepto
      where  ro_operacion = @i_operacionca
      and    ro_tipo_rubro = 'Q'
      and    ro_provisiona = 'N'
      and    ro_fpago     <> 'L'
      and    co_concepto = ro_concepto
      and    co_categoria in ('O', 'S')
      union -- UNIR LOS CONCEPTOS DE IVA ASOACIADOS A ESTOS CONCEPTOS
      select ro_concepto, ro_fpago
      from   ca_rubro_op, ca_concepto
      where  ro_operacion = @i_operacionca
      and    ro_fpago     <> 'L'
      and    ro_concepto_asociado in (select ro_concepto
                                      from   ca_rubro_op, ca_concepto
                                      where  ro_operacion = @i_operacionca
                                      and    ro_tipo_rubro = 'Q'
                                      and    ro_provisiona = 'N'
                                      and    ro_fpago     <> 'L'
                                      and    co_concepto = ro_concepto
                                      and    co_categoria in ('O', 'S')
                                     )

open cSeg

fetch cSeg
into  @w_ro_concepto, @w_ro_fpago

while @@fetch_status = 0
begin
   
   declare
      cMonto cursor
      for select am_dividendo, am_acumulado, am_pagado, ct_valor, am_secuencia
          from   ca_dividendo, ca_amortizacion, cob_conta..cb_cotizacion, ca_concepto
          where  di_operacion = @i_operacionca
          and    di_estado = 2
          and    am_operacion = di_operacion
          and    am_concepto  = @w_ro_concepto
          and    ct_moneda = 2
          and    ct_fecha  = di_fecha_ven
          and    co_concepto  = am_concepto
          and    (    (am_dividendo = di_dividendo + charindex('A', @w_ro_fpago)
                       and not(co_categoria in ('S','A') and am_secuencia > 1)
                      )
                   or (am_dividendo = di_dividendo and co_categoria in ('S','A') and am_secuencia > 1)
                 )
      for read only
   
   open cMonto
   
   fetch cMonto
   into  @w_am_dividendo, @w_am_acumulado, @w_am_pagado, @w_cotizacion_seg, @w_am_secuencial
   
--   while (@@fetch_status not in (-1,0) )
   while (@@fetch_status = 0)
   begin
      select @w_nuevo_monto = round((@w_am_acumulado - @w_am_pagado) * @i_cotizacion_hoy, 2)
      select @w_nuevo_monto = round(@w_nuevo_monto / @i_cotizacion_siguiente, 4)
      
      update ca_amortizacion
      set    am_acumulado = @w_am_pagado + @w_nuevo_monto,
             am_cuota     = @w_am_pagado + @w_nuevo_monto
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_am_dividendo
      and    am_concepto  = @w_ro_concepto
      and    am_secuencia = @w_am_secuencial
      
      ---
      fetch cMonto
      into  @w_am_dividendo, @w_am_acumulado, @w_am_pagado, @w_cotizacion_seg, @w_am_secuencial
   end
   
   close cMonto
   deallocate cMonto
   ---
   fetch cSeg
   into  @w_ro_concepto, @w_ro_fpago
end

close cSeg
deallocate cSeg



/* ACTUALIZACION DE LOS VALORES QUE SON TIPO MULTA/OTRO CARGO */
declare  rubro_multa cursor
  for select ro_concepto, ro_fpago
      from   ca_rubro_op
      where  ro_operacion = @i_operacionca
      and    ro_tipo_rubro = 'V'
      and    ro_provisiona = 'N'
      and    ro_fpago      = 'M'
open rubro_multa

fetch rubro_multa
into  @w_ro_concepto, @w_ro_fpago

while @@fetch_status = 0
begin
   declare
      monto_rubro_multa cursor
      for select am_dividendo, am_acumulado, am_pagado, ct_valor, am_secuencia
          from   ca_dividendo, ca_amortizacion, cob_conta..cb_cotizacion, ca_concepto
          where  di_operacion = @i_operacionca
          and    am_operacion = di_operacion
          and    am_concepto  = @w_ro_concepto
          and    ct_moneda = 2
          and    ct_fecha  = di_fecha_ven
          and    di_estado != 3
          and    co_concepto  = am_concepto
          and    (    (am_dividendo = di_dividendo + charindex('A', @w_ro_fpago)
                       and not(co_categoria in ('S','A') and am_secuencia > 1)
                      )
                   or (am_dividendo = di_dividendo and co_categoria in ('S','A') and am_secuencia > 1)
                 )
      for read only
   
   open monto_rubro_multa
   
   fetch monto_rubro_multa
   into  @w_am_dividendo, @w_am_acumulado, @w_am_pagado, @w_cotizacion_seg, @w_am_secuencial
   
--   while (@@fetch_status not in (-1,0) )
   while (@@fetch_status = 0)
   begin
      select @w_nuevo_monto = round((@w_am_acumulado - @w_am_pagado) * @i_cotizacion_hoy, 2)
      select @w_nuevo_monto = round(@w_nuevo_monto / @i_cotizacion_siguiente, 4)
      
      
      update ca_amortizacion
      set    am_acumulado = @w_am_pagado + @w_nuevo_monto,
             am_cuota     = @w_am_pagado + @w_nuevo_monto
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_am_dividendo
      and    am_concepto  = @w_ro_concepto
      and    am_secuencia = @w_am_secuencial
      
      ---
      fetch monto_rubro_multa
      into  @w_am_dividendo, @w_am_acumulado, @w_am_pagado, @w_cotizacion_seg, @w_am_secuencial
   end
   
   close monto_rubro_multa
   deallocate monto_rubro_multa
   ---
   fetch rubro_multa
   into  @w_ro_concepto, @w_ro_fpago
end

close rubro_multa
deallocate rubro_multa

delete ca_rubros_correccion_tmp where spid = @@spid
return 0
go
 
