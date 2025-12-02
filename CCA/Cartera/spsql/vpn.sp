/************************************************************************/
/*   NOMBRE LOGICO:      vpn.sp                                         */
/*   NOMBRE FISICO:      sp_vpn                                         */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Luis Castellanos                               */
/*   FECHA DE ESCRITURA: 19/JUL/2007                                    */
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
/*      Calculo del Valor Presente Neto (VPN)                           */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/*    19/Jul/07             LCA                   Revision indices      */
/*    14/May/21             LBP                   Calculos TIR TEA      */
/*    16/May/22             GFP     Actualizacion de proceso para tablas*/
/*                                  temporales                          */
/*    14/May/21             KDR     R192772 Instrucción No lock a tablas*/
/*    06/Mar/25             KDR     R256950(235424) Read onlye a cursor */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_vpn')
   drop proc sp_vpn
go

create proc sp_vpn
   @i_operacionca         int,
   @i_monto               money,
   @i_tdivi               smallint,
   @i_tasa                decimal(18,10),
   @i_des_seg             char(1),
   @i_deuda               money,
   @i_periodica           char(1) = 'S',
   @i_fecha_desde         datetime,
   @i_seguro              money  = 0,
   @i_temporales		  char(1) = 'N',
   @o_vpn                 decimal(18,10) out
as

declare
   @w_intentos             int,
   @w_vp                   decimal(20,10),
   @w_vpn                  decimal(20,10),
   @w_monto                money,
   @w_dividendo            smallint,
   @w_cuota                money,
   @w_tdivi                smallint,
   @w_tasa                 decimal(18,10),
   @w_proporcion           money,
   @w_aux                  float,
   @w_int_proporcion       float,
   @w_cap_proporcion       float,
   @w_pagado               money,
   @w_int                  money,
   @w_int_pag              money,
   @w_pdias                int,
   @w_fecha_ven            datetime

select @w_proporcion = 0, @w_aux = 0, @w_int_proporcion = 0, @w_cap_proporcion = 0

CREATE TABLE #ca_dividendo_concepto_tmp (
dc_dividendo			SMALLINT,
dc_fecha_vencimiento	SMALLDATETIME,
dc_concepto				VARCHAR(10),
dc_cuota				MONEY,
dc_gracia				MONEY,
dc_pagado				MONEY,
dc_operacion			INT)

IF @i_temporales = 'N'
  insert into #ca_dividendo_concepto_tmp
  select 
  di_dividendo, 
  di_fecha_ven, 
  am_concepto, 
  sum(am_cuota), 
  sum(am_gracia), 
  sum(am_pagado), 
  di_operacion    
  from  ca_amortizacion, ca_dividendo
  where am_operacion = di_operacion
  and   am_dividendo = di_dividendo 
  and   am_operacion = @i_operacionca 
  group by di_dividendo, di_fecha_ven, am_concepto,di_operacion
ELSE
  insert into #ca_dividendo_concepto_tmp
  select 
  dit_dividendo, 
  dit_fecha_ven, 
  amt_concepto, 
  sum(amt_cuota), 
  sum(amt_gracia), 
  sum(amt_pagado), 
  dit_operacion    
  from  ca_amortizacion_tmp with (nolock), ca_dividendo_tmp with (nolock) -- KDR 19/09/2022 No bloquear tablas
  where amt_operacion = dit_operacion
  and   amt_dividendo = dit_dividendo 
  and   amt_operacion = @i_operacionca 
  group by dit_dividendo, dit_fecha_ven, amt_concepto,dit_operacion
  
-- KDR Verifica si existen rubros en el préstamo aptos para ser tomados en cuenta para el cálculo de vpn
if not exists (select 1
  from #ca_dividendo_concepto_tmp, cobis..cl_tabla a, cobis..cl_catalogo b
  where dc_operacion = @i_operacionca
  and   a.tabla = 'ca_rubros_cat'
  and   a.codigo = b.tabla
  and   dc_concepto = b.codigo
  and   b.estado   = 'V'
 group by  dc_dividendo, dc_fecha_vencimiento)
begin
    return 725138
end

declare vpn cursor for
select dc_dividendo, dc_fecha_vencimiento, sum(dc_cuota + dc_gracia), sum(dc_pagado)
  from #ca_dividendo_concepto_tmp, cobis..cl_tabla a, cobis..cl_catalogo b
  --where dc_concepto in ('CAP','INT')
  where dc_operacion = @i_operacionca
  and   a.tabla = 'ca_rubros_cat'
  and   a.codigo = b.tabla
  and   dc_concepto = b.codigo
  and   b.estado   = 'V'
  group by  dc_dividendo, dc_fecha_vencimiento
  for read only

select @w_vpn = -1 * @i_monto

open vpn fetch vpn into @w_dividendo, @w_fecha_ven, @w_cuota, @w_pagado

while  @@fetch_status = 0 /*WHILE CURSOR PRINCIPAL*/
begin


   if @i_des_seg = 'S' begin
      select @w_proporcion = sum(dc_cuota)
        from #ca_dividendo_concepto_tmp
       where dc_operacion  = @i_operacionca
         and dc_dividendo  = @w_dividendo
         and dc_concepto  != 'INT'

      select @w_cap_proporcion = (@w_proporcion / @i_deuda*1.00)*@i_seguro
      select @w_int = sum(dc_cuota+dc_gracia),
             @w_int_pag =  sum(dc_cuota)
        from #ca_dividendo_concepto_tmp
       where dc_operacion = @i_operacionca
         and dc_dividendo = @w_dividendo
         and dc_concepto  = 'INT'

      if @w_proporcion = 0 select @w_int_proporcion = 0
      else select @w_int_proporcion = @w_cap_proporcion * @w_int/@w_proporcion

      if @i_des_seg = 'A'
         select @w_cuota = @w_cuota - @w_int_pag
   end

   select @w_cap_proporcion = 0, @w_int_proporcion = 0
   if @i_periodica = 'S'
   BEGIN
    
      select @w_vp  = convert(decimal(18,10),@w_cuota-@w_cap_proporcion-@w_int_proporcion)*power(1+@i_tasa*1.00,-1*(@w_dividendo))
   end
   else 
   begin
      select @w_pdias = datediff(dd,@i_fecha_desde, @w_fecha_ven)
      select @w_vp  = convert(decimal(18,10),@w_cuota-@w_cap_proporcion-@w_int_proporcion)*power(1+@i_tasa*1.00,-1*(@w_pdias))
   end
   select @w_vpn = @w_vpn + @w_vp
   --print 'div: %1! cuota: %2! proporcion: %3! QUOTA: %4! vp: %5!  vpn: %6! PROPOR_INT: %7! PROPORC_CAP: %8!',@w_dividendo,@w_cuota,@w_proporcion,@w_aux,@w_vp,@w_vpn,@w_int_proporcion,@w_cap_proporcion
   select @w_aux = @w_aux + @w_cap_proporcion + @w_int_proporcion

   SIGUIENTE:
   fetch vpn into @w_dividendo, @w_fecha_ven, @w_cuota, @w_pagado
end

close vpn
deallocate  vpn
select @o_vpn = @w_vpn
return 0



GO
