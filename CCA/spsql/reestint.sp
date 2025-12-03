/************************************************************************/
/*   NOMBRE LOGICO:      reestint.sp                                    */
/*   NOMBRE FISICO:      sp_reestructuracion_int                        */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:                                                      */
/*   FECHA DE ESCRITURA: Agosto 99                                      */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                        PROPOSITO                                     */
/*	Realiza la reestructuracion de una operacion a partir de su         */
/*	respectiva temporal                                                 */
/************************************************************************/
/*		                      MODIFICACIONES 		                	*/
/*      	FECHA		AUTOR			RAZON		                    */
/*    30/Nov/06     	Viviana Arias	 Actualiza estado de la opera.  */
/*    31/May/2007       Tania Suarez     Eliminar am_sector_contable    */
/*                                       tr_plazo_contable              */
/*                                       dtr_sector_contable            */
/*    17/Jul/2007       Sandra Robayo    elimine correctamente el F     */
/*    30/Jul/2007       Clotilde Vargas  I.4515 Actualizar Medio Repago */
/*    02/Ago/2007	Ricardo Reyes    Cambio estado T.Rubro F,Q          */
/*    03/Ago/2007       Ricardo Reyes    Eliminacion de FECI            */
/*    15/Ago/2007       Clotilde Vargas  I.4545                         */
/*    21/Ago/2007       P. Coello      Implementar cambios por manejo de*/
/*                                       promociones                    */
/*    05/Sep/2007       Clotilde Vargas  Correccion de plazo para       */
/*                                       reestructuracion               */
/*    23/Sep/2007       Pedro C. Coello  Cambiar forma de actualizar    */
/*                                       medios de repago               */
/*    31/Ago/2007       Clotilde Vargas  Libor                          */ 
/*    05/Sep/2007       Clotilde Vargas  Correccion de plazo para       */
/*                                       reestructuracion               */
/*    05/Nov/2020       P.Narvaez        Version CoreBase               */
/*    05/Ene/2021       P.Narvaez   Tipo Reestructuracion/TipoRenovacion*/
/*    02/Sep/2021       K.Rodriguez Registro de reajuste, detalle reajus*/
/*                                  te, y detalle transacción reestruc  */
/*    25/Abr/2023       K.Rodriguez S809859 Traslado contable por REESTR*/
/*    06/Jun/2023	    M. Cordova	  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*    03/Oct-2023       K. Rodiguez   R216451 Ajsute base calculo       */
/*    14/Mar/2024       K. Rodiguez   R2228975 Correc. valor rubros calc*/
/************************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_reestructuracion_int')
   drop proc sp_reestructuracion_int
go
create proc sp_reestructuracion_int (
   @s_user		   login        = null,
   @s_term	       varchar(30)  = null,
   @s_sesn         int          = null,
   @s_date         datetime     = null,
   @s_ofi          smallint     = null,
   @i_banco        cuenta       = null,
   @i_op_plant     int          = null, -- KDR Oper que se uso como plantilla para la reestruc
   @i_op_tipo_reest char(1)     = 'N',  -- KDR Criterio para obtener monto. N: Solo CAP, S: CAP e INT, T: TODO
   @i_upd_clientes char(1)      = null,
   @i_saldo_reest  money        = 0,
   @i_debug        char(1)      = 'N', --SVA
   @t_show_version bit  = 0, -- Mostrar la version del programa
   @o_secuencial   int  = 0 out
)
as declare	
   @w_sp_name		varchar(30),
   @w_return      	int,
   @w_operacionca       int,
   @w_pagado            money,
   @w_acumulado         money,
   @w_dividendo_ini     smallint,
   @w_concepto          catalogo,
   @w_tipo_rubro        char(1),
   @w_secuencial        int,
   @w_toperacion        catalogo,
   @w_moneda            tinyint,
   @w_moneda_old        tinyint,
   @w_oficina           int,
   @w_fecha_ini         datetime,
   @w_dividendo_ch      smallint,
   @w_monto_ch          money,
   @w_div_actualizar    smallint,
   @w_fecha_ult_proceso datetime,
   @w_estado             tinyint,
   @w_ult_div            smallint,	
   @w_am_estado          tinyint,
   @w_am_monto           money,
   @w_fecha_ini_old      datetime,
   @w_fecha_new          datetime ,
   @w_num_reest          smallint,
   @w_op_sector          catalogo,
   @w_gerente            smallint,
   @w_gar_admisible      char(1),
   @w_reestructuracion   char(1),
   @w_calificacion       catalogo, 
   @w_base_calculo       char(1),
   @w_dias_anio          smallint,
   @w_nuevo_monto        money,
   @w_est_vigente        tinyint,
   @w_tran               varchar(10),
   @w_fecha_reest        datetime,
   @w_fecha_reest_noestandar datetime,
   @w_est_cancelado          tinyint,
   @w_tipo_reest             char(1),
   @w_monto                  money,
   @w_concepto_rubro       catalogo,
   @w_estado_rubro         tinyint,
   @w_saldo_rubro          money,
   @w_codval_rubro         int, 
   @w_dividen_rubro        smallint,
   @w_secuencia_rub        tinyint,
   @w_periodo_rubro        tinyint,
   @w_cont                 int,
   @w_cod_val_cap          int,
   
   @w_secuencial_tcr       int,
   @w_count_res            smallint
   
-- VARIABLES INICIALES 
select @w_sp_name    = 'sp_reestructuracion_int',
       @w_div_actualizar = 0,
       @w_nuevo_monto    = 0

if @t_show_version = 1
begin
    print 'Stored procedure sp_reestructuracion_int, Version 4.0.0.0'
    return 0
end


-- ESTADOS DE CARTERA
exec @w_return = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_cancelado  = @w_est_cancelado out

if @w_return != 0 
   goto ERROR

-- OBTENGO EL PLAZO CONTABLE ANTES DE HACER LA REESTRUCTURACION
select @w_fecha_ini_old = op_fecha_ini, --CVA Sep-05-07
       @w_num_reest     = op_numero_reest,        --NUMERO DE VECES REESTRUCTURADO
       @w_op_sector     = op_sector,
       @w_estado        = op_estado,
       @w_monto         = op_monto,
	   @w_moneda_old    = op_moneda
from   ca_operacion
where  op_banco = @i_banco


/*DATOS DE LA OPERACION REESTRUCTURADA */
select @w_operacionca = opt_operacion,
       @w_toperacion  = opt_toperacion,
       @w_moneda      = opt_moneda,
       @w_oficina     = opt_oficina,
       @w_fecha_ini   = opt_fecha_ini,
       @w_fecha_ult_proceso = opt_fecha_ult_proceso,
       @w_fecha_new     = opt_fecha_fin,
	   @w_base_calculo  = opt_base_calculo,
	   @w_dias_anio     = opt_dias_anio,
       @w_gerente       = opt_oficial,
       @w_gar_admisible = opt_gar_admisible,
       @w_reestructuracion = isnull(opt_reestructuracion, ''),
       @w_calificacion     = isnull(opt_calificacion, 'A'),
       @w_tipo_reest       = isnull(opt_tipo_reest, 'E')
from ca_operacion_tmp
where opt_banco   = @i_banco

if @w_tipo_reest ='E'  --Reestructuracion
   select @w_tran = 'RES',
          @w_num_reest = isnull(@w_num_reest,0) + 1,
          @w_fecha_reest = @w_fecha_ult_proceso

if @w_tipo_reest ='D'  --Diferimiento u otro
   select @w_tran = 'DIF',
          @w_fecha_reest_noestandar = @w_fecha_ult_proceso

-- ACTUALIZACION DE CLIENTES
if @i_upd_clientes = 'S' 
begin
   exec @w_return = sp_cliente
        @t_debug        = 'N',
        @t_file         = '',
        @t_from         = @w_sp_name,
        @s_date         = @s_date,
        @i_usuario      = @s_user,
        @i_sesion       = @s_sesn,
        @i_banco        = @i_banco,
        @i_operacion    = 'U'

   if @w_return != 0 goto ERROR

end

-- ACTUALIZACION DE LA OPERACION
update ca_operacion_tmp 
   set opt_fecha_ini       = op_fecha_ini,
       opt_monto           = op_monto,
       opt_numero_reest    = @w_num_reest,       --NUMERO DE VECES REESTRUCTURADO
       opt_fecha_reest     = isnull(@w_fecha_reest,opt_fecha_reest),
       opt_fecha_reest_noestandar = isnull(@w_fecha_reest_noestandar,opt_fecha_reest_noestandar)
from ca_operacion 
where opt_operacion = @w_operacionca
and   op_operacion  = @w_operacionca
and   opt_operacion = op_operacion

exec @w_secuencial = sp_gen_sec
     @i_operacion = @w_operacionca

-- OBTENER RESPALDO ANTES DE LA REESTRUCTURACION
exec @w_return = sp_historial
     @i_operacionca    = @w_operacionca,
     @i_secuencial     = @w_secuencial

if @w_return != 0 goto ERROR

exec @w_return = sp_pasodef
     @i_banco       = @i_banco, 
     @i_operacionca = 'S' 

if @w_return != 0 goto ERROR

-- SI NO EXISTEN DIVIDENDOS TEMPORALES ENTONCES 
-- LA REESTRUCTURACION SOLO INVOLUCRO CAMBIO DE DEUDORES
if not exists (select 1 from ca_dividendo_tmp
               where dit_operacion = @w_operacionca) 
   return 0

select @w_dividendo_ini = 0

select @w_dividendo_ini = isnull(max(di_dividendo),0)
  from ca_dividendo
 where di_operacion = @w_operacionca
   and di_estado in (1,2) 

-- ACTUALIZACION DEL DIVIDENDO VIGENTE 
if exists (select 1
        from   ca_dividendo
        where  di_operacion = @w_operacionca
        and    di_dividendo = @w_dividendo_ini
        and    di_fecha_ini = @w_fecha_ini
        and    @i_saldo_reest > 0)  --Reestructura sin saldo, lo hace desde el primer no vigente
   select @w_dividendo_ini = @w_dividendo_ini - 1
else
   update ca_dividendo
     set di_fecha_ven = @w_fecha_ini
   where di_operacion = @w_operacionca
     and di_dividendo = @w_dividendo_ini 

if @@error != 0
begin
  select @w_return = 710002
  goto ERROR
end

-- Total Trans. Reestructuraciones antes de la Reestructura actual
select @w_count_res = isnull(count(1), 0)
from ca_transaccion with (nolock)
where tr_operacion = @w_operacionca 
and tr_tran = 'RES' 
and tr_estado <> 'RV'

/* TRANSACCION CONTABLE */
select @o_secuencial = @w_secuencial

insert into ca_transaccion (
tr_secuencial,       tr_fecha_mov,     tr_toperacion,
tr_moneda,           tr_operacion,     tr_tran,
tr_en_linea,         tr_banco,         tr_dias_calc,
tr_ofi_oper,         tr_ofi_usu,       tr_usuario,
tr_terminal,         tr_fecha_ref,     tr_secuencial_ref,
tr_estado,           tr_gerente,       tr_gar_admisible,
tr_reestructuracion, tr_calificacion,  tr_observacion,
tr_fecha_cont,       tr_comprobante)
values (
@w_secuencial,       @s_date,                @w_toperacion,
@w_moneda,           @w_operacionca,         @w_tran,
'S',                 @i_banco,               0,
@w_oficina,          @s_ofi,                 @s_user,
@s_term,             @w_fecha_ult_proceso,   0,
'ING',               @w_gerente,             isnull(@w_gar_admisible,''),
@w_reestructuracion, @w_calificacion,        'DESDE CARTERA',
@s_date,             0)

if @@error != 0 begin
   select @w_return = 708165
   goto   ERROR
end

-- KDR 2/Sep/2021 DET TRANSACCION DE LOS DIVIDENDOS VENCIDOS Y VIGENTE HASTA LA FECHA REEST 
select * into #rubros_reest FROM ca_amortizacion where 1=2 
        
if @i_op_tipo_reest = 'N'
   insert into #rubros_reest
   select ca_amortizacion.* FROM ca_amortizacion, ca_rubro_op
   WHERE am_operacion = @w_operacionca
   and   ro_operacion = am_operacion
   and   am_concepto  = ro_concepto
   and   ro_tipo_rubro in ('C')

if @i_op_tipo_reest = 'S'
   insert into #rubros_reest
   select ca_amortizacion.* FROM ca_amortizacion, ca_rubro_op 
   WHERE am_operacion = @w_operacionca
   and   ro_operacion = am_operacion
   and   am_concepto  = ro_concepto
   and   ro_tipo_rubro in ('C', 'I')

if @i_op_tipo_reest = 'T'
   insert into #rubros_reest
   select ca_amortizacion.* FROM ca_amortizacion, ca_rubro_op 
   WHERE am_operacion = @w_operacionca
   and   ro_operacion = am_operacion
   and   am_concepto  = ro_concepto

select @w_cont = count(1) from #rubros_reest

while  @w_cont > 0
begin
   SELECT TOP 1
       @w_concepto_rubro = am_concepto,
	   @w_estado_rubro   = am_estado,
       @w_saldo_rubro    = am_acumulado + am_gracia - am_pagado,
       @w_codval_rubro   = ((select co_codigo from ca_concepto where co_concepto = am_concepto)*1000+am_estado*10+am_periodo), 
       @w_dividen_rubro  = am_dividendo,
	   @w_secuencia_rub  = am_secuencia,
	   @w_periodo_rubro  = am_periodo
   from #rubros_reest

   if @w_saldo_rubro > 0
   begin
      -- Detalle de transacción
	  insert into ca_det_trn
            (dtr_secuencial,     dtr_operacion,       dtr_dividendo,
             dtr_concepto,       dtr_estado,          dtr_periodo,
             dtr_codvalor,       dtr_monto,           dtr_monto_mn,
             dtr_moneda,         dtr_cotizacion,      dtr_tcotizacion,
             dtr_afectacion,     dtr_cuenta,          dtr_beneficiario,
             dtr_monto_cont)
      values(@w_secuencial,      @w_operacionca,      @w_dividen_rubro,
             @w_concepto_rubro,  @w_estado_rubro,     @w_periodo_rubro,
             @w_codval_rubro,    -@w_saldo_rubro,     -@w_saldo_rubro, 
             @w_moneda_old,      1,                   'N',
             'C',                '',                  '',
             0)
			  
	  if @@error <> 0 
      begin
	     select @w_return = 710031          
         goto ERROR
      end
   end

   delete #rubros_reest 
      where am_operacion = @w_operacionca 
	  and am_dividendo   = @w_dividen_rubro 
	  and am_concepto    = @w_concepto_rubro
	  and am_secuencia   = @w_secuencia_rub
   set @w_cont = (select count(1) from #rubros_reest)

end

DROP TABLE #rubros_reest

-- KDR TRASLADO CONTABLE POR REESTRUCTURACION (TCR)
if @w_estado = @w_est_vigente
begin

   -- Genera TCR solo si es la primera Reestructuración
   if @w_count_res = 0
   begin
   
      exec @w_secuencial_tcr = sp_gen_sec
           @i_operacion = @w_operacionca
      
      -- RESPALDO ANTES DE LA TRANSACCIÓN DE TRASLADO CONTABLE POR REESTRUCTURACION
      exec @w_return = sp_historial
           @i_operacionca    = @w_operacionca,
           @i_secuencial     = @w_secuencial_tcr
      
      if @w_return != 0 goto ERROR
      
      insert into ca_transaccion (
      tr_secuencial,       tr_fecha_mov,     tr_toperacion,
      tr_moneda,           tr_operacion,     tr_tran,
      tr_en_linea,         tr_banco,         tr_dias_calc,
      tr_ofi_oper,         tr_ofi_usu,       tr_usuario,
      tr_terminal,         tr_fecha_ref,     tr_secuencial_ref,
      tr_estado,           tr_gerente,       tr_gar_admisible,
      tr_reestructuracion, tr_calificacion,  tr_observacion,
      tr_fecha_cont,       tr_comprobante)
      values (
      @w_secuencial_tcr,   @s_date,                @w_toperacion,
      @w_moneda,           @w_operacionca,         'TCR',
      'S',                 @i_banco,               0,
      @w_oficina,          @s_ofi,                 @s_user,
      @s_term,             @w_fecha_ult_proceso,   0,
      'ING',               @w_gerente,             isnull(@w_gar_admisible,''),
      'S',                 @w_calificacion,        'DESDE CARTERA',
      @s_date,             0)
      
      if @@error != 0 
	  begin
         select @w_return = 708165 -- No se pudo crear registro en ca_transaccion
         goto   ERROR
      end
	  
	  -- Detalle de Transacción TRASLADO CONTABLE POR REESTRUCTURACION
      insert into ca_det_trn(
	  dtr_secuencial,     dtr_operacion,       dtr_dividendo,
      dtr_concepto,       dtr_estado,          dtr_periodo,
      dtr_codvalor,       
	  dtr_monto,          dtr_monto_mn,
      dtr_moneda,         dtr_cotizacion,      dtr_tcotizacion,
      dtr_afectacion,     dtr_cuenta,          dtr_beneficiario,
      dtr_monto_cont)
      select 
	  @w_secuencial_tcr, @w_operacionca,                        0, 
      am_concepto,       am_estado,                             am_periodo, 
      ((select co_codigo from ca_concepto where co_concepto = am_concepto)*1000+am_estado*10+am_periodo),                 
	  sum(am_acumulado+am_gracia-am_pagado), sum(am_acumulado+am_gracia-am_pagado),
      @w_moneda_old,     1,                                     'N',
      'C',               '',                                    '',
      0
	  from ca_amortizacion, ca_concepto
	  where am_operacion = @w_operacionca
	  and am_concepto = co_concepto
	  and am_estado <> @w_est_cancelado
	  and co_categoria in ('C', 'I')
	  group by am_concepto, am_estado, am_periodo
	  having sum(am_acumulado + am_gracia-am_pagado) > 0
	  
      if @@error != 0 
      begin
	     select @w_return = 710031 -- Error al insertar informacion de detalle de la transaccion         
         goto ERROR
      end
	
   end
end

/* MANEJO DE DIVIDENDOS */
delete ca_dividendo
where  di_operacion = @w_operacionca
and    di_dividendo > @w_dividendo_ini

if @@error != 0 begin
   select @w_return = 707054 --Error en eliminacion de Dividendo
   goto   ERROR
end

insert into ca_dividendo 
select 
dit_operacion,   dit_dividendo+ @w_dividendo_ini ,      dit_fecha_ini,
dit_fecha_ven,   dit_de_capital,                        dit_de_interes,
dit_gracia,      dit_gracia_disp,                       dit_estado,
dit_dias_cuota,  dit_intento,                           dit_prorroga,
dit_fecha_can
from ca_dividendo_tmp
where dit_operacion = @w_operacionca

if @@error != 0 begin
   select @w_return = 703090 --Error en creacion de Dividendo
   goto   ERROR
end


--SI HUBO MODIFICACION DE SALDOS, IGUALAR AL PAGADO EL LOS RUBROS QUE SI CONTABILIZAN DE LOS DIVIDENDOS 
--ANTERIORES AL DIVIDENDO VIGENTE o VENCIDO
if @i_saldo_reest > 0
begin
   -- KDR 2/Sep/2021 Igualar cuota y acumulado, con el pagado
   update ca_amortizacion 
   set am_cuota = am_pagado,
       am_acumulado = am_pagado	
   from  ca_rubro_op
   where am_operacion  = @w_operacionca
     and am_dividendo <= @w_dividendo_ini
     and ro_operacion  = @w_operacionca
     and ro_concepto   = am_concepto
     and ro_tipo_rubro = 'C'
   
   if @@error != 0 begin
      select @w_return = 705050 --Error en actualizacion Amortizacion
      goto   ERROR
   end 
	 
   if @i_op_tipo_reest = 'S'
   begin
      update ca_amortizacion 
      set am_cuota = am_pagado,		
          am_acumulado = am_pagado	
      from  ca_rubro_op
      where am_operacion  = @w_operacionca
        and am_dividendo <= @w_dividendo_ini
        and ro_operacion  = @w_operacionca
        and ro_concepto   = am_concepto
        and ro_tipo_rubro in ('I')
      
      if @@error != 0 begin
         select @w_return = 705050 --Error en actualizacion Amortizacion
         goto   ERROR
      end
   end
   
   if @i_op_tipo_reest = 'T'
   begin
      update ca_amortizacion 
      set am_cuota = am_pagado,		
          am_acumulado = am_pagado	
      from  ca_rubro_op
      where am_operacion  = @w_operacionca
        and am_dividendo <= @w_dividendo_ini
        and ro_operacion  = @w_operacionca
        and ro_concepto   = am_concepto
		and ro_tipo_rubro != 'C'
      
      if @@error != 0 begin
         select @w_return = 705050 --Error en actualizacion Amortizacion
         goto   ERROR
      end
   end

   -- ACTUALIZAR LOS VALORES PROYECTADOS CON LO ACUMULADO A LA FECHA
   update ca_amortizacion 
   set am_cuota  = am_acumulado
       --am_pagado = am_acumulado
   from ca_rubro_op
   where am_operacion = @w_operacionca
   and am_dividendo <= @w_dividendo_ini
   and ro_operacion = @w_operacionca
   and ro_concepto  = am_concepto
   and ro_tipo_rubro != 'C'

   if @@error != 0 begin
      select @w_return = 705050 --Error en actualizacion Amortizacion
      goto   ERROR
   end
end

/* CURSOR PARA ACTUALIZAR LOS DIVIDENDOS ANTERIORES DE SER NECESARIO */
declare cur_dividendos cursor for
 select am_dividendo, sum(am_cuota+am_gracia-am_pagado)
   from   ca_amortizacion
  where  am_operacion = @w_operacionca
    and    am_dividendo <= @w_dividendo_ini
  group by am_dividendo 

open cur_dividendos

fetch cur_dividendos into @w_dividendo_ch, @w_monto_ch

while @@fetch_status = 0
begin
   if @@fetch_status = -1 
   begin
      select @w_return = 710004
      goto ERROR 
   end   
   if @i_debug='S'  print 'Monto chequeo:' + convert(varchar,@w_monto_ch)

   if @w_monto_ch <= 0.0099
   begin
      update ca_dividendo
      set    di_estado = @w_est_cancelado
      where  di_operacion = @w_operacionca
      and    di_dividendo = @w_dividendo_ch 

      update ca_amortizacion
      set    am_estado = @w_est_cancelado
      where  am_operacion = @w_operacionca
      and    am_dividendo = @w_dividendo_ch 
   end

   fetch cur_dividendos into @w_dividendo_ch, @w_monto_ch
end
close cur_dividendos
deallocate cur_dividendos


-- DE NO EXISTIR UN DIVIDENDO VIGENTE SE PONE EL DIVIDENDO INICIAL VIGENTE
if not exists (select 1 from ca_dividendo 
            where di_operacion = @w_operacionca
              and di_estado = 1)
begin
   select @w_div_actualizar = @w_dividendo_ini +1

   update ca_dividendo
      set di_estado = 1
    where di_operacion = @w_operacionca
      and di_dividendo = @w_dividendo_ini + 1

   if @@error != 0 begin
     select @w_return = 705043 --Error en actualizacion de Dividendo
     goto   ERROR
   end 
end

-- KDR 2/Sep/2021 Actualización días cuota.
update ca_dividendo
   set di_dias_cuota = datediff(dd, di_fecha_ini, di_fecha_ven)
   where di_operacion = @w_operacionca

if @@error != 0 begin
   select @w_return = 705043 --Error en actualizacion de Dividendo
   goto   ERROR
end 

-- MANEJO DE CUOTAS ADICIONALES
if exists (select 1 from ca_cuota_adicional
           where ca_operacion = @w_operacionca)
begin
   delete ca_cuota_adicional
   where ca_operacion = @w_operacionca
   and ca_dividendo > @w_dividendo_ini

   insert ca_cuota_adicional
   select cat_operacion, cat_dividendo + @w_dividendo_ini , cat_cuota
   from ca_cuota_adicional_tmp
   where cat_operacion = @w_operacionca
end

-- MANEJO DE VALORES PAGADOS POR ANTICIPADO (OPERACIONES AL VENCIMIENTO Y ANTICIPADO PARCIAL)
declare rubros cursor for
 select ro_concepto, ro_tipo_rubro, am_estado, sum(am_acumulado), sum(am_pagado)
   from ca_rubro_op, ca_amortizacion
  where ro_operacion  = @w_operacionca
    and ro_fpago      in ('P','A')
    and ro_tipo_rubro in ('C','I','F')  
    and am_operacion  = @w_operacionca
    and am_concepto   = ro_concepto
    and am_dividendo  > @w_dividendo_ini
  group by ro_concepto, ro_tipo_rubro, am_estado

open rubros
fetch rubros into @w_concepto, @w_tipo_rubro, @w_am_estado,  @w_acumulado, @w_pagado

while @@fetch_status = 0
begin
   if @@fetch_status = -1 
   begin
      select @w_return = 710004
      goto ERROR 
   end

   if @w_tipo_rubro = 'C'   --ACUMULAR EN LA PRIMERA CUOTA CREADA PARA LAS PENDIENTES EL VALOR PAGADO
   begin
      update ca_amortizacion_tmp 
         set amt_cuota     = amt_cuota     + @w_pagado,
             amt_acumulado = amt_acumulado + @w_pagado,
             amt_pagado    = amt_pagado    + @w_pagado
       where amt_operacion = @w_operacionca
         and amt_dividendo = 1
         and amt_concepto  = @w_concepto
         and amt_estado    = @w_am_estado

      if @@error != 0 
      begin
         select @w_return = 705022
         goto   ERROR
      end
   end 
   else
   if @w_tipo_rubro in ('I','F')
   begin
      update ca_amortizacion_tmp 
         set amt_pagado = isnull(@w_pagado, 0),
             amt_acumulado = isnull(@w_acumulado, 0)
       where amt_operacion = @w_operacionca
         and amt_dividendo = 1
         and amt_estado    = @w_am_estado
         and amt_concepto  = @w_concepto

      if @@error != 0 
      begin
         select @w_return = 705022
         goto   ERROR
      end
   end   

   fetch rubros into @w_concepto, @w_tipo_rubro, @w_am_estado,  @w_acumulado, @w_pagado
end --del while cursor rubros

close rubros
deallocate rubros


delete ca_amortizacion
where am_operacion = @w_operacionca
and   am_dividendo > @w_dividendo_ini

if @@error != 0 begin
   select @w_return = 71003
   goto   ERROR
end

-- ACTUALIZAR LOS RUBROS DE LA OPERACION

if @w_estado <> @w_est_vigente and @i_saldo_reest <= 0
begin
   update ca_amortizacion_tmp
      set amt_estado = @w_estado
     from ca_rubro_op
    where amt_operacion = @w_operacionca
      and ro_operacion  = @w_operacionca
      and ro_concepto   = amt_concepto
      and ro_tipo_rubro <> 'M' -- Solo la mora no cambia de estado contable

   if @@error != 0 begin
      select @w_return = 705050 --Error en actualizacion Amortizacion
      goto   ERROR
   end      
   
end


insert into ca_amortizacion (
am_operacion,       am_dividendo,  am_concepto,
am_estado,          am_periodo,    am_cuota,
am_gracia,          am_pagado,     am_acumulado,
am_secuencia) 
select 
amt_operacion,       amt_dividendo + @w_dividendo_ini,  amt_concepto,
amt_estado,          amt_periodo,    amt_cuota,
amt_gracia,          amt_pagado,     amt_acumulado,
amt_secuencia
from  ca_amortizacion_tmp
where amt_operacion = @w_operacionca

if @@error != 0 begin
   select @w_return = 71001
   goto   ERROR
end


--CONTROL PARA RUBROS AGREGADOS EN LA REESTRUCTURACION (MSU)
declare otros_rubros cursor for
select am_concepto, max(am_cuota)
  from ca_amortizacion, ca_operacion, ca_rubro, ca_rubro_op_tmp
 where am_operacion  = @w_operacionca
   and op_operacion  = @w_operacionca
   and op_toperacion = ru_toperacion
   and am_dividendo  > @w_dividendo_ini
   and op_moneda     = ru_moneda
   and am_concepto   = ru_concepto
   and ru_tipo_rubro = 'Q'
   and rot_operacion  = am_operacion
   and rot_concepto   = am_concepto
  group by am_concepto
  order by am_concepto

open otros_rubros

fetch otros_rubros into @w_concepto, @w_am_monto

while @@fetch_status = 0
begin
   if @@fetch_status = -1 
   begin
      select @w_return = 710004
      goto ERROR 
   end

   update ca_rubro_op
      set ro_valor = @w_am_monto
    where ro_operacion = @w_operacionca
      and ro_concepto  = @w_concepto

   if @@rowcount = 0 --El rubro no existe insertarlo
   begin
      insert  into ca_rubro_op
             (ro_operacion,            ro_concepto,           ro_tipo_rubro,
              ro_fpago,                ro_prioridad,          ro_paga_mora,
              ro_provisiona,           ro_signo,              ro_factor,
              ro_referencial,          ro_signo_reajuste,     ro_factor_reajuste,
              ro_referencial_reajuste, ro_valor,              ro_porcentaje,
              ro_porcentaje_aux,       ro_gracia,             ro_concepto_asociado,
			  ro_principal,            ro_garantia)
      select  @w_operacionca,          @w_concepto,           ru_tipo_rubro,
              ru_fpago,                ru_prioridad,          ru_paga_mora,
              ru_provisiona,           '+',                   0,
              ru_referencial,          '+',                   0.0,
              ru_referencial,          isnull(@w_am_monto,0), 0,
              0,                       0,                     ru_concepto_asociado,
			  ru_principal,            0
         from ca_rubro, ca_operacion
        where op_operacion  = @w_operacionca
          and op_toperacion = ru_toperacion
          and op_moneda     = ru_moneda
          and ru_concepto   = @w_concepto
      if @@error != 0
      begin
         select @w_return = 710001
         goto ERROR
      end
   end

   fetch otros_rubros into @w_concepto, @w_am_monto
end --Del while
close otros_rubros
deallocate otros_rubros
--FIN CONTROL RUBROS AÑADIDOS

--Si se cambió el capital, se actualiza el rubro tipo capital
select @w_nuevo_monto = sum(am_acumulado)
from  ca_amortizacion, ca_rubro_op
where am_operacion  = @w_operacionca
and ro_operacion  = am_operacion
and ro_concepto   = am_concepto
and ro_tipo_rubro = 'C'

if @w_nuevo_monto < @w_monto
begin
   select @w_return = 711078--'El valor total de la reestructura no cubre las operaciones'
   goto ERROR
end
   
update ca_rubro_op 
set ro_valor = case when @w_nuevo_monto > ro_valor then @w_nuevo_monto else ro_valor end
where ro_operacion = @w_operacionca
and ro_tipo_rubro = 'C'

if @@error <> 0 begin
   select @w_return = 710002
   goto ERROR
end

--Si se reestructuró saldos de la op final o base, la op pasa a Vigente
if @i_saldo_reest > 0
   select @w_estado = @w_est_vigente


--ACTUALIZAR LA TASA DE INTERES CON LA ESPECIFICADA EN LA REESTRUCTURACION (MSU)
update ca_rubro_op
   set ro_porcentaje       = rot_porcentaje,
       ro_porcentaje_aux   = rot_porcentaje_aux,
       ro_porcentaje_efa   = rot_porcentaje_efa,
       ro_factor           = rot_factor,
       ro_signo            = rot_signo,
       ro_referencial      = rot_referencial,
       ro_factor_reajuste  = rot_factor_reajuste,
       ro_signo_reajuste   = rot_signo_reajuste,
       ro_referencial_reajuste = rot_referencial_reajuste
  from ca_rubro_op_tmp
 where ro_operacion = @w_operacionca
   and rot_operacion = ro_operacion
   and ro_concepto   = rot_concepto
   and ro_tipo_rubro in ( 'I', 'M')  

if @@error <> 0 begin
   select @w_return = 710002
   goto ERROR
end

delete ca_tasas
  from ca_rubro_op
 where ts_operacion  = @w_operacionca
   and ro_operacion  = @w_operacionca
   and ts_concepto   = ro_concepto
   and ro_tipo_rubro in ( 'I' )   -- SYR 07/17/2007 
   and ts_fecha      >= @w_fecha_ult_proceso

insert  into ca_tasas 
      (ts_operacion,      ts_dividendo,           ts_fecha,
       ts_concepto,       ts_porcentaje,          ts_secuencial,
       ts_porcentaje_efa, ts_referencial,         ts_signo, 
       ts_factor,         ts_valor_referencial,   ts_fecha_referencial,
       ts_tasa_ref) 
select @w_operacionca,    @w_dividendo_ini,       @w_fecha_ult_proceso,
       ro_concepto,       ro_porcentaje,          @w_secuencial,
       ro_porcentaje_efa, ro_referencial,         ro_signo,
       ro_factor,         vr_valor,               vr_fecha_vig, 
       vd_referencia
  from ca_rubro_op, ca_valor_det, ca_valor_referencial
 where ro_operacion   = @w_operacionca
   and ro_tipo_rubro in ( 'I')  -- SYR 07/17/2007 
   and ro_referencial = vd_tipo
   and vd_sector      = @w_op_sector
   and vd_referencia  = vr_tipo 
   and vr_secuencial  = (select max(vr_secuencial)
                         from ca_valor_referencial
                         where vr_tipo       =  vd_referencia
                         and   vr_fecha_vig  <= @w_fecha_ult_proceso)

if @@error <> 0 begin
   select @w_return = 703118 
   goto ERROR
end

-- KDR 2/Sep/2021 DET TRANSACCION DEL NUEVO CAPITAL VIGENTE PARA LA REESTRUCTURACIÓN

SELECT @w_cod_val_cap = co_codigo*1000+1*10+0
FROM  ca_concepto
WHERE co_concepto = 'CAP'

insert into ca_det_trn
select @w_secuencial,  @w_operacionca,                     am_dividendo, 
       am_concepto,    am_estado,                          am_periodo,
       @w_cod_val_cap, (am_acumulado+am_gracia-am_pagado), (am_acumulado+am_gracia-am_pagado),
       @w_moneda,      1,                                  'N',
       'D',            '',                                 '',
       0
FROM ca_dividendo, ca_amortizacion, ca_rubro_op
WHERE di_operacion = @w_operacionca
AND   am_operacion = di_operacion
AND   am_operacion = ro_operacion
AND   am_dividendo = di_dividendo
AND   di_dividendo >= @w_dividendo_ini + 1
and   am_concepto  = ro_concepto
and   ro_tipo_rubro in ('C')
		  
if @@error <> 0 
begin
   select @w_return = 710031          
   goto ERROR
end


-- KDR 2/Sep/2021 Ingreso de reajuste y detalle de reajuste
if @i_op_plant is not null and exists (select 1 from ca_operacion where op_operacion = @i_op_plant)
begin
  
    delete cob_cartera..ca_reajuste_det
    where  red_operacion   = @w_operacionca         
    and    red_secuencial in (select re_secuencial
                              from   cob_cartera..ca_reajuste
                              where  re_operacion = @w_operacionca			 
                              and    re_fecha    >= @w_fecha_ini)
    
    if @@error != 0
    begin
       select @w_return = 710003
       goto   ERROR
    end
    
    delete cob_cartera..ca_reajuste
    where  re_operacion = @w_operacionca
    and    re_fecha    >= @w_fecha_ini
    
    if @@error != 0
    begin
       select @w_return = 710003
       goto   ERROR
    end
    
    select @w_secuencial = isnull(max(re_secuencial), 0)
    from   cob_cartera..ca_reajuste   
    where  re_operacion = @w_operacionca
    
    insert into cob_cartera..ca_reajuste
    select re_secuencial + @w_secuencial, @w_operacionca, re_fecha,
           re_reajuste_especial, re_desagio,  re_sec_aviso
    from   cob_cartera..ca_reajuste
    where  re_operacion = @i_op_plant                              
    
    if @@error != 0
    begin
       select @w_return = 710045
       goto   ERROR
    end
    
    insert into cob_cartera..ca_reajuste_det
    select red_secuencial + @w_secuencial, @w_operacionca,  
           red_concepto,   red_referencial, red_signo,	
           red_factor,     red_porcentaje
    from   cob_cartera..ca_reajuste_det
    where  red_operacion = @i_op_plant                                
    
    if @@error != 0
    begin
       select @w_return = 708154
       goto   ERROR
    end
	
end
-- Fin Ingreso de reajuste y detalle de reajuste


if @w_div_actualizar > 0 
begin
   update ca_amortizacion
   set    am_estado = 1
   where  am_operacion = @w_operacionca
   and    am_dividendo = @w_div_actualizar
   and    am_estado = 0 

   if @@error != 0 begin
      select @w_return = 705050 --Error en actualizacion Amortizacion
      goto   ERROR
   end
end


select @w_ult_div = max(di_dividendo)
from ca_dividendo
where di_operacion = @w_operacionca


update ca_operacion
   set op_plazo            = @w_ult_div,
       --op_estado           = isnull(@w_estado, op_estado),
       op_monto            = case when @w_nuevo_monto > op_monto then @w_nuevo_monto else op_monto end, 
       op_monto_aprobado   = case when @w_nuevo_monto > op_monto_aprobado then @w_nuevo_monto else op_monto_aprobado end,
       op_reestructuracion = 'S',
	   op_calificacion     = @w_calificacion,
	   op_tipo_reest       = @w_tipo_reest,
	   op_base_calculo     = @w_base_calculo,
	   op_dias_anio        = @w_dias_anio   
 where op_operacion = @w_operacionca 

return 0          

ERROR:

IF OBJECT_ID ('dbo.#rubros_reest') IS NOT NULL
	DROP TABLE dbo.#rubros_reest
	
if @i_debug = 'S' print 'Error No. ' + convert(varchar,@w_return)
return @w_return
go

