/************************************************************************/
/*   Nombre Fisico:        camestsu.sp                                  */
/*   Nombre Logico:        sp_cambio_estado_suspenso                    */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   31/08/1999                                   */
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
/*                               PROPOSITO                              */
/*   Maneja los cambios de estado de las operaciones                    */
/*                              CAMBIOS                                 */
/*   FECHA            AUTOR         CAMBIO                              */
/*   JUN-09-2010      EPB           Quitar Codigo Causacion Pasivas     */
/*  DIC/23/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_suspenso')
   drop proc sp_cambio_estado_suspenso
go

---INC. 55584  ABR.10.2012

create proc sp_cambio_estado_suspenso
   @s_user           login,
   @s_term           varchar(30),
   @s_date           datetime,
   @i_toperacion     catalogo,
   @i_banco          cuenta,
   @i_operacionca    int,
   @i_en_linea       char(1)  = 'N',  --En CoreBase solo se llama desde batch
   @i_gerente        smallint,
   @i_estado_ini     tinyint,
   @i_estado_fin     tinyint,
   @i_cotizacion     float   = null,
   @i_tcotizacion    char(1) = 'N',
   @i_num_dec        tinyint = null

as 
declare
   @w_error             int,
   @w_secuencial        int,
   @w_di_dividendo      smallint,
   @w_di_vigente        smallint,
   @w_est_vigente       tinyint,
   @w_est_vencido       tinyint,
   @w_est_cancelado     tinyint,
   @w_est_novigente     tinyint,
   @w_est_suspenso      tinyint,
   @w_ro_concepto       catalogo,
   @w_secuencia         int,
   @w_trn               catalogo,
   @w_di_estado         tinyint,
   @w_tipo_rubro        char(1),
   @w_am_estado         tinyint,
   @w_am_cuota          money,
   @w_am_acumulado      money,
   @w_am_pagado         money,
   @w_am_gracia         money,
   @w_am_secuencia      tinyint,
   @w_am_cuota2         money,
   @w_am_pagado2        money,
   @w_am_gracia2        money,
   @w_am_concepto       catalogo,
   @w_gar_admisible     char(1),
   @w_reestructuracion  char(1),
   @w_calificacion      catalogo,
   @w_observacion       varchar(255),
   @w_fecha_ult_proceso datetime,
   @w_op_moneda         tinyint,
   @w_di_fecha_ini      datetime,
   @w_op_oficina        smallint,
   @w_rowcount          int                           -- REQ 175: PEQUEÑA EMPRESA

-- CONDICION DE SALIDA
if @i_estado_fin is null         return 0
if @i_estado_ini = @i_estado_fin return 0

-- CARGAR VARIABLES DE TRABAJO
select 
@w_secuencial    = 0,
@w_di_dividendo  = 0,
@w_di_vigente    = 0

-- IDENTIFICAR SI LA TRANSACCION ES EN LINea O EN BATCH
select 
@w_trn         = 'EST', --'SUA',--En CoreBase solo se llama desde batch
@w_observacion = 'CAMBIO ESTADO A SUSPENSO'
  

--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso  out  

-- DATOS DE LA OPERACION
select 
@w_gar_admisible     = op_gar_admisible,
@w_reestructuracion  = op_reestructuracion,
@w_calificacion      = op_calificacion,
@w_op_moneda         = op_moneda,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_op_oficina        = op_oficina
from   ca_operacion
where  op_operacion = @i_operacionca


-- OBTENER RESPALDO ANTES DEL CAMBIO DE ESTADO
exec @w_secuencial = sp_gen_sec
@i_operacion = @i_operacionca

exec @w_error = sp_historial
@i_operacionca = @i_operacionca,
@i_secuencial  = @w_secuencial

if @w_error <> 0  return @w_error

insert into ca_transaccion(
tr_secuencial,                  tr_fecha_mov,                    tr_toperacion,
tr_moneda,                      tr_operacion,                    tr_tran,
tr_en_linea,                    tr_banco,                        tr_dias_calc,
tr_ofi_oper,                    tr_ofi_usu,                      tr_usuario,
tr_terminal,                    tr_fecha_ref,                    tr_secuencial_ref,
tr_estado,                      tr_observacion,                  tr_gerente,
tr_gar_admisible,               tr_reestructuracion,             tr_calificacion,            
tr_fecha_cont,                  tr_comprobante)                    
values(                                                          
@w_secuencial,                  @s_date,                         @i_toperacion,
@w_op_moneda,                   @i_operacionca,                  @w_trn,
@i_en_linea,                    @i_banco,                        0,
@w_op_oficina,                  @w_op_oficina,                   @s_user,
@s_term,                        @w_fecha_ult_proceso,            0,
'ING',                          @w_observacion,                  @i_gerente,
isnull(@w_gar_admisible,''),    isnull(@w_reestructuracion,''),  isnull(@w_calificacion,''), 
@s_date,                        0)
   
if @@error <> 0  return 708165


if @i_estado_fin <> @w_est_vigente begin

   update ca_operacion set    
   op_estado         = @i_estado_fin,
   op_suspendio      = 'S',
   op_fecha_suspenso = @w_fecha_ult_proceso
   where  op_operacion = @i_operacionca
   
   if @@error <> 0  return 710003
   
   -- BUSCAR EL MENOR DIVIDENDO NO CANCELADO
   select @w_di_dividendo = isnull(min(di_dividendo),-999)
   from   ca_dividendo
   where  di_operacion  = @i_operacionca
   and    di_estado    in (@w_est_vencido, @w_est_vigente)
   
   while 1=1 begin  -- cursor de dividendos
   
      select 
      @w_di_estado    = di_estado,
      @w_di_fecha_ini = di_fecha_ini
      from ca_dividendo
      where di_operacion = @i_operacionca
      and   di_dividendo = @w_di_dividendo
      and   di_estado   in (@w_est_vencido, @w_est_vigente)
      
      if @@rowcount = 0 break

/*      
      if @w_di_estado = @w_est_vencido begin
      
         declare  dividir cursor for select 
         ro_concepto,   ro_tipo_rubro
         from   ca_rubro_op
         where  ro_operacion   = @i_operacionca
         and    ro_provisiona  = 'S'
         and    ro_tipo_rubro  = 'M'
         for read only
         
      end else begin
*/
         declare dividir cursor for select 
         ro_concepto,  ro_tipo_rubro
         from   ca_rubro_op
         where  ro_operacion   = @i_operacionca
         and    ro_provisiona  = 'S'
         and    ro_tipo_rubro  in('I','F')
         for read only
         
--      end
   
      open dividir
   
      fetch dividir into  @w_ro_concepto, @w_tipo_rubro
   
      while  @@fetch_status = 0  begin
      
         select @w_secuencia = isnull(max(am_secuencia), 0)
         from   ca_amortizacion
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_di_dividendo
         and    am_concepto  = @w_ro_concepto
         
         if @w_tipo_rubro in ('I','F')  begin
         
            select 
            @w_am_cuota     = am_cuota,
            @w_am_acumulado = am_acumulado
            from   ca_amortizacion
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_ro_concepto
            
            if @w_am_cuota =  @w_am_acumulado goto SIGUIENTE
         end
         
         if @w_secuencia = 0 goto SIGUIENTE
         
/*         
         if @w_tipo_rubro = 'M' and @i_estado_fin = @w_est_suspenso begin
         
            insert into ca_amortizacion(
            am_operacion,       am_dividendo,      am_concepto,
            am_estado,          am_periodo,        am_cuota,
            am_gracia,          am_pagado,         am_acumulado,
            am_secuencia )
            values(
            @i_operacionca,     @w_di_dividendo,   @w_ro_concepto,
            @i_estado_fin,      0,                 0,
            0,                  0,                 0,
            @w_secuencia + 1)
               
            if @@error <> 0  return 710001
               
            goto SIGUIENTE
         end
*/         
         select 
         @w_am_estado    = am_estado,
         @w_am_acumulado = am_acumulado,
         @w_am_pagado    = am_pagado
         from   ca_amortizacion
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_di_dividendo
         and    am_concepto  = @w_ro_concepto
         and    am_secuencia = @w_secuencia
         
         if @w_am_acumulado = 0 begin
         
            update ca_amortizacion
            set    am_estado = @i_estado_fin
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_ro_concepto
            and    am_secuencia = @w_secuencia
            
            goto SIGUIENTE
            
         end
         
         select 
         @w_am_cuota2 = 0,
         @w_am_pagado2 = 0,
         @w_am_gracia2 = 0
         
         if @w_am_cuota > @w_am_acumulado
            select @w_am_cuota2 = @w_am_cuota - @w_am_acumulado
         else
            select @w_am_cuota2 = @w_am_cuota
         
         if @w_am_pagado > @w_am_acumulado
            select @w_am_pagado2 = @w_am_pagado - @w_am_acumulado
         else
            select @w_am_pagado2 = @w_am_pagado
         
         if @w_am_gracia > @w_am_acumulado
            select @w_am_gracia2 = @w_am_gracia - @w_am_acumulado
         else
            select @w_am_gracia2 = @w_am_gracia
         
         select @w_am_cuota  = @w_am_cuota       - @w_am_cuota2
         select @w_am_pagado = @w_am_pagado      - @w_am_pagado2
         select @w_am_gracia = @w_am_gracia      - @w_am_gracia2
         
         if @w_am_cuota >= 0 begin
         
            update ca_amortizacion
            set    am_cuota = @w_am_cuota
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_ro_concepto
            and    am_secuencia = @w_secuencia
            
            if @@error <> 0 return 710002
            
         end else begin
            select @w_am_cuota  = @w_am_cuota2
            select @w_am_cuota2 = 0
         end

         if @w_am_pagado >= 0 begin
            update ca_amortizacion
            set    am_pagado = @w_am_pagado2
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_ro_concepto
            and    am_secuencia = @w_secuencia
            
            if @@error <> 0 return 710002
         end else begin
            select @w_am_pagado = @w_am_pagado2
            select @w_am_pagado2 = 0
         end
         
         
         if @w_am_gracia >= 0  begin
         
            update ca_amortizacion
            set    am_gracia = @w_am_gracia
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_ro_concepto
            and    am_secuencia = @w_secuencia
            
            if @@error <> 0 return 710002
            
         end else begin
            select @w_am_gracia = @w_am_gracia2
            select @w_am_gracia2 = 0
         end
         
         if (@w_am_cuota >= 0 and @w_am_cuota2 > 0) begin
         
            insert into ca_amortizacion (
            am_operacion,       am_dividendo,      am_concepto,
            am_estado,          am_periodo,        am_cuota,
            am_gracia,          am_pagado,         am_acumulado,
            am_secuencia)
            values(
            @i_operacionca,     @w_di_dividendo,   @w_ro_concepto,
            @i_estado_fin,      0,                 @w_am_cuota2,
            @w_am_gracia2,      @w_am_pagado,      0,  
            @w_secuencia +1)
            
            if @@error <> 0 return 710001
         end
         
         SIGUIENTE:
         fetch dividir into  @w_ro_concepto, @w_tipo_rubro

      end -- WHILE CURSOR DIVIDIR
      
      close dividir
      deallocate dividir
 
      --- REVERSAR LA CAUSACION DE LOS RUBROS QUE CAUSAN AL INICIO DE LA CUOTA 
      if  datediff(dd, @w_di_fecha_ini, @w_fecha_ult_proceso) <= 1
      and @w_di_estado = @w_est_vigente begin
      
         insert into ca_det_trn
         select
         dtr_secuencial   = @w_secuencial,
         dtr_operacion    = @i_operacionca, 
         dtr_dividendo    = am_dividendo,
         dtr_concepto     = am_concepto,
         dtr_estado       = am_estado,
         dtr_periodo      = 0,
         dtr_codvalor     = (co_codigo * 1000) + (am_estado * 10),
         dtr_monto        = (am_acumulado - am_pagado) * -1,
         dtr_monto_mn     = round(((am_acumulado - am_pagado) * -1)*@i_cotizacion,@i_num_dec),
         dtr_moneda       = @w_op_moneda,
         dtr_cotizacion   = @i_cotizacion,
         dtr_tcotizacion  = @i_tcotizacion,
         dtr_afectacion   = 'D',
         dtr_cuenta       = '',
         dtr_beneficiario = '',
         dtr_monto_cont   = 0
         from ca_amortizacion, ca_rubro_op, ca_concepto
         where am_operacion = ro_operacion
         and   am_concepto  = ro_concepto
         and   am_concepto  = co_concepto 
         and   ro_provisiona = 'N'
         and   ro_tipo_rubro <> 'C'
         and   co_categoria <> 'R'
         and   ro_operacion  = @i_operacionca
         and   am_dividendo  = @w_di_dividendo
         and  (am_acumulado - am_pagado)  >= 0.01
          
         if @@error <>0 return 710001

         update ca_amortizacion with (rowlock) set   
         am_estado    = @i_estado_fin
         from ca_rubro_op,ca_concepto
         where am_operacion  = ro_operacion
         and   am_concepto   = ro_concepto
         and   ro_provisiona = 'N'
         and   ro_tipo_rubro <> 'C'
         and   ro_operacion  = @i_operacionca
         and   am_dividendo  = @w_di_dividendo 
         and   co_concepto   = ro_concepto
         and   co_categoria  <> 'R'
         and   co_concepto   = am_concepto
 
         if @@error <>0 return 710002
         
         insert into ca_det_trn
         select
         dtr_secuencial   = @w_secuencial,
         dtr_operacion    = @i_operacionca, 
         dtr_dividendo    = am_dividendo,
         dtr_concepto     = am_concepto,
         dtr_estado       = am_estado,
         dtr_periodo      = 0,
         dtr_codvalor     = (co_codigo * 1000) + (am_estado * 10),
         dtr_monto        = (am_acumulado - am_pagado),
         dtr_monto_mn     = round((am_acumulado - am_pagado)*@i_cotizacion,@i_num_dec),
         dtr_moneda       = @w_op_moneda,
         dtr_cotizacion   = @i_cotizacion,
         dtr_tcotizacion  = @i_tcotizacion,
         dtr_afectacion   = 'D',
         dtr_cuenta       = '',
         dtr_beneficiario = '',
         dtr_monto_cont   = 0
         from ca_amortizacion, ca_rubro_op, ca_concepto
         where am_operacion = ro_operacion
         and   am_concepto  = ro_concepto
         and   am_concepto  = co_concepto 
         and   ro_provisiona = 'N'
         and   ro_tipo_rubro <> 'C'
         and   co_categoria <> 'R' ---Otros cargos
         and   ro_operacion  = @i_operacionca
         and   am_dividendo  = @w_di_dividendo
         and   (am_acumulado - am_pagado)  >= 0.01
          
         if @@error <>0 return 710001
         
      end
      
      select @w_di_dividendo = @w_di_dividendo + 1
      
   end -- lazo de cuotas
      
   -- INI - REQ 175: PEQUEÑA EMPRESA - SE MANTIENE EL ESTADO VIGENTE DE LOS INTERESES DE GRACIA
   insert ca_amortizacion(
   am_operacion,     am_dividendo,        am_concepto,
   am_estado,        am_periodo,          am_cuota,
   am_gracia,        am_pagado,           am_acumulado,
   am_secuencia                                        )
   select
   am_operacion,     am_dividendo,        am_concepto,
   am_estado,        am_periodo,          0,
   am_gracia,        0,                   0,
   am_secuencia - 1
   from ca_amortizacion, ca_rubro_op
   where am_operacion  = @i_operacionca
   and   am_dividendo >= @w_di_dividendo
   and   am_gracia     > 0
   and   ro_operacion  = am_operacion
   and   ro_concepto   = am_concepto
   and   ro_tipo_rubro = 'I'
   
   select 
   @w_error    = @@error,
   @w_rowcount = @@rowcount
   
   if @w_error <> 0
      return 721305
      
   if @w_rowcount > 0
   begin
      -- MARCAR ESTADO DE PROVISION PARA EL RESTO DE DIVIDENDOS
      update ca_amortizacion set
      am_estado    = case when am_cuota > 0 then @i_estado_fin else @w_est_vigente end,
      am_gracia    = case when am_cuota > 0 then 0             else am_gracia      end,
      am_secuencia = am_secuencia + 1
      from   ca_rubro_op, ca_amortizacion
      where  am_operacion  = @i_operacionca
      and    am_dividendo >= @w_di_dividendo
      and    ro_operacion  = @i_operacionca
      and    am_operacion  = ro_operacion
      and    ro_concepto   = am_concepto
      and    ro_provisiona = 'S'
      and    ro_tipo_rubro in ('I','M','F')
      
      if @@error <> 0 return 710002
   end
   else
   begin
      -- MARCAR ESTADO DE PROVISION PARA EL RESTO DE DIVIDENDOS
      update ca_amortizacion
      set    am_estado = @i_estado_fin
      from   ca_rubro_op, ca_amortizacion
      where  am_operacion  = @i_operacionca
      and    am_dividendo >= @w_di_dividendo
      and    ro_operacion  = @i_operacionca
      and    am_operacion  = ro_operacion
      and    ro_concepto   = am_concepto
      and    ro_provisiona = 'S'
      and    ro_tipo_rubro in ('I','M','F')
      
      if @@error <> 0 return 710002
   end   
   -- FIN - REQ 175: PEQUEÑA EMPRESA
end

-- SALIR DEL ESTADO DE SUSPENSO
if @i_estado_fin <> @w_est_suspenso begin

   update ca_operacion set    
   op_estado = @w_est_vigente
   where  op_operacion = @i_operacionca
   
   if @@error <> 0  return 710003

   -- BUSCAR EL MENOR DIVIDENDO NO CANCELADO
   select @w_di_dividendo = isnull(min(di_dividendo),-999)
   from   ca_dividendo
   where  di_operacion  = @i_operacionca
   and    di_estado    in (@w_est_vencido, @w_est_vigente)
   
   while 1=1 begin  -- cursor de dividendos
   
      select 
      @w_di_estado    = di_estado,
      @w_di_fecha_ini = di_fecha_ini
      from ca_dividendo
      where  di_operacion = @i_operacionca
      and    di_dividendo = @w_di_dividendo
      
      if @@rowcount = 0 break
      
      insert into ca_det_trn
      select
      dtr_secuencial   = @w_secuencial,
      dtr_operacion    = @i_operacionca, 
      dtr_dividendo    = am_dividendo,
      dtr_concepto     = am_concepto,
      dtr_estado       = am_estado,
      dtr_periodo      = 0,
      dtr_codvalor     = (co_codigo * 1000) + (am_estado * 10),
      dtr_monto        = sum(am_acumulado - am_pagado) * -1,
      dtr_monto_mn     = round((sum(am_acumulado - am_pagado) * -1)*@i_cotizacion,@i_num_dec),
      dtr_moneda       = @w_op_moneda,
      dtr_cotizacion   = @i_cotizacion,
      dtr_tcotizacion  = @i_tcotizacion,
      dtr_afectacion   = 'D',
      dtr_cuenta       = '',
      dtr_beneficiario = '',
      dtr_monto_cont   = 0
      from ca_amortizacion, ca_concepto
      where am_operacion  = @i_operacionca
      and   am_concepto   = co_concepto 
      and   am_dividendo  = @w_di_dividendo
      and   am_estado     = @w_est_suspenso
      and   co_categoria <> 'R'
      group by am_dividendo, am_concepto, am_estado, co_codigo
      having  sum(am_acumulado - am_pagado) >= 0.01
       
      if @@error <>0 return 710001

      insert into ca_det_trn
      select
      dtr_secuencial   = @w_secuencial,
      dtr_operacion    = @i_operacionca, 
      dtr_dividendo    = am_dividendo,
      dtr_concepto     = am_concepto,
      dtr_estado       = @w_di_estado,
      dtr_periodo      = 0,
      dtr_codvalor     = (co_codigo * 1000) + (@w_di_estado * 10),
      dtr_monto        = sum(am_acumulado - am_pagado),
      dtr_monto_mn     = round(sum(am_acumulado - am_pagado)*@i_cotizacion,@i_num_dec),
      dtr_moneda       = @w_op_moneda,
      dtr_cotizacion   = @i_cotizacion,
      dtr_tcotizacion  = @i_tcotizacion,
      dtr_afectacion   = 'D',
      dtr_cuenta       = '',
      dtr_beneficiario = '',
      dtr_monto_cont   = 0
      from ca_amortizacion, ca_concepto
      where am_operacion  = @i_operacionca
      and   am_concepto   = co_concepto 
      and   am_dividendo  = @w_di_dividendo
      and   am_estado     = @w_est_suspenso
      and   co_categoria <> 'R'
      group by am_dividendo, am_concepto, am_estado, co_codigo
      having  sum(am_acumulado - am_pagado) >= 0.01
       
      if @@error <>0 return 710001
      
      update ca_amortizacion
      set    am_estado = @w_di_estado
      where  am_operacion  = @i_operacionca
      and    am_dividendo  = @w_di_dividendo
      and    am_estado     = @w_est_suspenso
      
      if @@error <> 0  return 710002

      select @w_di_dividendo = @w_di_dividendo + 1
      
   end

   
   --UNIFICAR LOS SECUENCIALES
   
   delete ca_amortizacion_unif
   where amu_spid = @@spid
   
   insert into ca_amortizacion_unif
   select @@spid, *
   from   ca_amortizacion
   where  am_operacion = @i_operacionca
   and    am_secuencia = 2
   and    am_estado   <> 3
   
   update ca_amortizacion set
   am_cuota     = am_cuota     + amu_cuota,
   am_gracia    = am_gracia    + amu_gracia,
   am_acumulado = am_acumulado + amu_acumulado,
   am_pagado    = am_pagado    + amu_pagado,
   am_estado    = amu_estado
   from   ca_amortizacion, ca_amortizacion_unif
   where  am_operacion = amu_operacion
   and    am_dividendo = amu_dividendo
   and    am_concepto  = amu_concepto
   and    am_secuencia = 1
   and    amu_spid = @@spid
   
   delete ca_amortizacion
   from   ca_amortizacion_unif
   where  am_operacion = amu_operacion
   and    am_dividendo = amu_dividendo
   and    am_concepto  = amu_concepto
   and    am_secuencia = amu_secuencia
   and    amu_spid = @@spid
   
   delete ca_amortizacion_unif 
   where amu_spid = @@spid
   
end


return 0

go
