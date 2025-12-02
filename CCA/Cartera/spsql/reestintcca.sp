/************************************************************************/
/*	Nobre Fisico:         reestintcca.sp                                 */
/*	Nombre Logico:        sp_reestructuracion_int_cca                    */
/*	Base de datos:        cob_cartera                                    */
/*	Producto:             Cartera                                        */
/*	Disenado por:                                                        */
/*	Fecha de escritura:   Agosto 99                                      */
/************************************************************************/
/* IMPORTANTE                                                           */
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
/*                        PROPOSITO                                      */
/*	Realiza la reestructuracion de una operacion a partir de su          */
/*	respectiva temporal                                                  */
/************************************************************************/
/*		                      MODIFICACIONES 			                 */
/*      	FECHA		AUTOR			RAZON		                     */
/*    30/Nov/06     	Viviana Arias	 Actualiza estado de la opera.  */
/*    31/May/2007       Tania Suarez     Eliminar am_sector_contable    */
/*                                       tr_plazo_contable              */
/*                                       dtr_sector_contable            */
/*    17/Jul/2007       Sandra Robayo    elimine correctamente el F     */
/*    30/Jul/2007       Clotilde Vargas  I.4515 Actualizar Medio Repago */
/*    02/Ago/2007	Ricardo Reyes    Cambio estado T.Rubro F,Q      */
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
/*    17/Nov/2021       K.Rodriguez Ajustes lógica de diferimiento      */
/*    12/Oct/2022       K.Rodriguez R195663 Ajuste fecha ult proceso def*/
/*    06/Jun/2023	    M. Cordova	  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_reestructuracion_int_cca')
   drop proc sp_reestructuracion_int_cca
go
create proc sp_reestructuracion_int_cca (
   @s_user		   login        = null,
   @s_term	       varchar(30)  = null,
   @s_sesn         int          = null,
   @s_date         datetime     = null,
   @s_ofi          smallint     = null,
   @i_banco        cuenta       = null,
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
   @w_nuevo_monto        money,
   @w_est_vigente        tinyint,
   @w_tran               varchar(10),
   @w_fecha_reest        datetime,
   @w_fecha_reest_noestandar datetime,
   @w_est_cancelado          tinyint,
   @w_tipo_reest             char(1),
   @w_monto                  money,
   @w_capitalNoVigentes      money,
   @w_capitalTmp             money,
   @w_cont                   smallint,
   @w_div_tmp                smallint,
   @w_fecha_ven_tmp          datetime,
   @w_fecha_ven_tmp_aux      datetime,
   @w_fecha_ini_primerNV     datetime,
   @w_fecha_ven_primerNV     datetime,
   @w_fecha_ult_proceso_def  datetime   -- KDR Fecha ult proceso de tabla definitiva
   

-- VARIABLES INICIALES 
select @w_sp_name    = 'sp_reestructuracion_int_cca',
       @w_div_actualizar = 0,
       @w_est_vigente    = 1,
       @w_est_cancelado  = 3,
       @w_nuevo_monto    = 0,
	   @w_dividendo_ini  = 0

if @t_show_version = 1
begin
    print 'Stored procedure sp_reestructuracion_int_cca, Version 4.0.0.0'
    return 0
end

-- OBTENGO EL PLAZO CONTABLE ANTES DE HACER LA REESTRUCTURACION
select @w_fecha_ini_old = op_fecha_ini, --CVA Sep-05-07
       @w_num_reest     = op_numero_reest,        --NUMERO DE VECES REESTRUCTURADO
       @w_op_sector     = op_sector,
       @w_estado        = op_estado,
       @w_monto         = op_monto,
	   @w_fecha_ult_proceso_def = op_fecha_ult_proceso
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
       @w_gerente       = opt_oficial,
       @w_gar_admisible = opt_gar_admisible,
       @w_reestructuracion = isnull(opt_reestructuracion, ''),
       @w_calificacion     = isnull(opt_calificacion, 'A'),
       @w_tipo_reest       = opt_tipo_reest
from ca_operacion_tmp
where opt_banco   = @i_banco


-- Validar que el saldo capital No vigente sea el mismo que con la nueva distribución de cuotas
select @w_capitalNoVigentes = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
from   ca_amortizacion, ca_rubro_op, ca_dividendo
where  am_operacion  = @w_operacionca
and    ro_operacion  = am_operacion
and    am_operacion  = di_operacion
and    ro_operacion  = di_operacion
and    di_dividendo  = am_dividendo
and    ro_concepto   = am_concepto
and    di_estado     = 0
and    ro_tipo_rubro = 'C'

select @w_capitalTmp = isnull(sum(amt_acumulado + amt_gracia - amt_pagado),0)
from   ca_amortizacion_tmp, ca_rubro_op_tmp, ca_dividendo_tmp
where  amt_operacion   = @w_operacionca
and    rot_operacion   = amt_operacion
and    amt_operacion   = dit_operacion
and    rot_operacion   = dit_operacion
and    dit_dividendo   = amt_dividendo
and    rot_concepto    = amt_concepto
and    rot_tipo_rubro  = 'C'

if(@w_capitalNoVigentes <> @w_capitalTmp)
begin
   select @w_return = 725125 -- El monto de saldo no vigente de la operación no coincide con el monto del diferimiento
   goto ERROR
end


/* Validar que las fechas de la tabla con las cuotas diferidas sean consecutivas, crecientes y no repetidas.
   y que la fecha inicio del primer div de la op dif. sea igual a la fecha inicio del primer div no vigente (op original)*/

-- Fecha inicio y vencimiento del primer dividendo No Vigente
select @w_fecha_ini_primerNV = min(di_fecha_ini),
       @w_fecha_ven_primerNV = min(di_fecha_ven)
from ca_dividendo
where di_operacion = @w_operacionca
and di_estado = 0

if @w_fecha_ini_primerNV <> @w_fecha_ini or @w_fecha_ven_primerNV <= @w_fecha_ini
begin
   select @w_return = 725127 -- La fecha de inicio o vencimiento del primer dividendo no es consistente
   goto ERROR	
end

create table #divs_diferidos (
   div         smallint,
   fecha_ven   datetime
)

insert into #divs_diferidos
select dit_dividendo, dit_fecha_ven
from ca_dividendo_tmp
where dit_operacion = @w_operacionca
order by dit_dividendo ASC

select @w_cont = count(1) from #divs_diferidos

select @w_fecha_ven_tmp_aux = '01/01/1900'

while  @w_cont > 0
begin

   SELECT TOP 1
       @w_div_tmp        = div,
	   @w_fecha_ven_tmp  = fecha_ven
   from #divs_diferidos order by div ASC
   
   if @w_fecha_ven_tmp = @w_fecha_ven_tmp_aux 
      or @w_fecha_ven_tmp < @w_fecha_ven_tmp_aux
   begin
      select @w_return = 725126 -- Las fechas de las cuotas de la operación deben ser consecutivas crecientes y no repetidas
      goto ERROR	
   end
   
   select @w_fecha_ven_tmp_aux = @w_fecha_ven_tmp
   
   delete #divs_diferidos 
      where div = @w_div_tmp 

   set @w_cont = (select count(1) from #divs_diferidos )
   
end


if @w_tipo_reest ='E'  --Reestructuracion
   select @w_tran = 'RES',
          @w_num_reest = isnull(@w_num_reest,0) + 1,
          @w_fecha_reest = @w_fecha_ult_proceso_def

if @w_tipo_reest ='D'  --Diferimiento u otro
   select @w_tran = 'DIF',
          @w_fecha_reest_noestandar = @w_fecha_ult_proceso_def

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

if @@error != 0 begin
   select @w_return = 705018 -- Error en actualizacion de Operacion Temporal
   goto   ERROR
end

exec @w_secuencial = sp_gen_sec
     @i_operacion = @w_operacionca

   if @w_return != 0 goto ERROR

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

select @w_dividendo_ini = max(di_dividendo)
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
     select @w_return = 705043  --Error en actualizacion de Dividendo     
     goto ERROR
   end

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
@s_term,             @w_fecha_ult_proceso_def,0,
'ING',               @w_gerente,             isnull(@w_gar_admisible,''),
@w_reestructuracion, @w_calificacion,        'DESDE CARTERA',
@s_date,             0)

if @@error != 0 begin
   select @w_return = 708165
   goto   ERROR
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

   -- ACTUALIZAR LOS VALORES PROYECTADOS CON LO ACUMULADO A LA FECHA
   update ca_amortizacion 
   set am_cuota  = am_acumulado,
       am_pagado = am_acumulado
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
	  
	  if @@error != 0 begin
		  select @w_return = 705043 -- Error en actualizacion de Dividendo
		  goto   ERROR
	   end

      update ca_amortizacion
      set    am_estado = @w_est_cancelado
      where  am_operacion = @w_operacionca
      and    am_dividendo = @w_dividendo_ch 
	  
	  if @@error != 0 begin
		  select @w_return = 705050 -- Error en actualizacion Amortizacion 
		  goto   ERROR
	   end
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
         select @w_return = 705022 -- Error en actualizacion de Amortizacion temporal
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
         select @w_return = 705022 -- Error en actualizacion de Amortizacion temporal
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
      select @w_return = 705022 -- Error en actualizacion de Amortizacion temporal
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
select am_concepto, sum(am_cuota)
  from ca_amortizacion, ca_operacion, ca_rubro, ca_rubro_op
 where am_operacion  = @w_operacionca
   and op_operacion  = @w_operacionca
   and op_toperacion = ru_toperacion
   and am_dividendo  > @w_dividendo_ini
   and op_moneda     = ru_moneda
   and am_concepto   = ru_concepto
   and ru_tipo_rubro = 'Q'
   and ro_operacion  = am_operacion
   and ro_concepto   = am_concepto
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
              ro_porcentaje_aux,       ro_gracia,             ro_concepto_asociado)
      select  @w_operacionca,          @w_concepto,           ru_tipo_rubro,
              ru_fpago,                ru_prioridad,          ru_paga_mora,
              ru_provisiona,           '+',                   0,
              ru_referencial,          '+',                   0.0,
              ru_referencial,          isnull(@w_am_monto,0), 0,
              0,                       0,                     ru_concepto_asociado
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
   
update ca_rubro_op set ro_valor = case when @w_nuevo_monto > ro_valor then @w_nuevo_monto else ro_valor end
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
   and ro_tipo_rubro in ( 'I')  

if @@error <> 0 begin
   select @w_return = 710002
   goto ERROR
end

-- KDR En diferimiento no se afectan los registros de las tasas ya que solo se modifican cuotas futuras.
/*delete ca_tasas
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
end*/

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
       op_estado           = isnull(@w_estado, op_estado),
	   op_fecha_ult_proceso = @w_fecha_ult_proceso_def,
       op_monto            = case when @w_nuevo_monto > op_monto then @w_nuevo_monto else op_monto end, 
       op_monto_aprobado   = case when @w_nuevo_monto > op_monto_aprobado then @w_nuevo_monto else op_monto_aprobado end
 where op_operacion = @w_operacionca       

return 0          

ERROR:
if @i_debug = 'S' print 'Error No. ' + convert(varchar,@w_return)
return @w_return
go
