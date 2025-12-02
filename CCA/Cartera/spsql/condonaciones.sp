/************************************************************************/
/*   Nombre Fisico:       condonaciones.sp                              */
/*   Nombre Logico:       sp_condonacion                                */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Carlos Hernanadez                             */
/*   Fecha de escritura:  Frebrero-2012                                 */
/************************************************************************/
/*                           IMPORTANTE                                 */
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
/*                           PROPOSITO                                  */  
/*   Este programa ejecuta administra y aplica nuevo plantemiento de    */
/*   condonaciones y su respectiva política                             */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR             RAZON                          */
/* 	10/04/2015         Acelis            Req 447 						*/
/*  20/10/2021         G. Fernandez      Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_condonaciones')
   drop proc sp_condonaciones
go
--Inc. 26883 Partiendo de la Ver. 28 Jul-27-2011
create proc sp_condonaciones (
@s_user                  varchar(14),
@s_term                  varchar(30)  = null,
@s_date                  datetime     = null,
@s_ofi                   smallint     = null,
@s_rol                   smallint     = 1,
@s_ssn                   int          = null,
@s_sesn                  int          = null,
@s_srv                   varchar (30) = '',
@i_banco                 cuenta       = null,
@i_formato_fecha         int          = null,
@i_operacion             char(1)      = null,
@i_porcentaje            float        = null,
@i_valor                 money        = null,
@i_concepto              catalogo     = null,
@i_estado_concepto       tinyint      = null,
@i_ente                  int          = null,
@i_rol                   smallint     = null,
@i_oficina               smallint     = null,
@i_fecha_proceso         datetime     = null,
@i_secuencial            int          = null,
@i_opcion                char(1)      = 'T',
@i_crea_pago             char(1)      = 'N',
@i_excepcion             char(1)      = 'N',
@i_porcentaje_par        float        = null,
@o_autoriza              char(1)      = null out,
@o_secuencial            int          = null out
)
as
declare   
   @w_sp_name                      varchar(32),   
   @w_return                       int,
   @w_operacionca                  int,
   @w_banco                        cuenta,
   @w_cliente                      int,
   @w_secuencial                   int,
   @w_secuencial_pag               int,
   @w_toperacion                   catalogo,
   @w_dias_mora                    smallint,
   @w_fecha_ini                    datetime,
   @w_fecha_fin                    datetime,
   @w_saldo_mora                   money,
   @w_tplazo                       catalogo,
   @w_plazo                        smallint,
   @w_ncuotas_pag         		   int,
   @w_nombre                       descripcion,
   @w_banca                        catalogo,  --xma
   @w_desc_banca                   descripcion,
   @w_fecha_liq                    datetime,
   @w_fecha_ult_proceso            datetime,
   @w_fecha_proceso                smalldatetime,
   @w_numero_reest                 int ,
   @w_cobranza                     catalogo,
   @w_saldo_cap                    money,
   @w_saldo_operacion_finan        money,
   @w_des_mercado                  descripcion,
   @w_saldo_operacion              money,
   @w_desc_toperacion              descripcion,
   @w_error                        int,
   @w_est_castigado                tinyint,
   @w_est_cancelado                tinyint,
   @w_est_vencido                  tinyint,
   @w_est_vigente                  tinyint, 
   @w_est_noven                    tinyint, 
   @w_estado                       tinyint,
   @w_param_cap                    varchar(30),
   @w_param_int                    varchar(30),
   @w_param_mora                   varchar(30),
   @w_param_honabo                 varchar(30),
   @w_param_ivahonabo              varchar(30),
   @w_condonar_cap                 money,
   @w_condonar_int                 money,
   @w_condonar_mora                money,
   @w_moneda                       int,
   @w_moneda_nacional              int,
   @w_calificacion                 catalogo,
   @w_fecha_ven                    datetime,
   @w_cap_vig                      money,
   @w_int_vig                      money,
   @w_imo_vig                      money,
   @w_hon_vig                      money,
   @w_ivahon_vig                   money,
   @w_otr_vig                      money,
   @w_cap_ven                      money,
   @w_int_ven                      money,
   @w_imo_ven                      money,
   @w_hon_ven                      money,
   @w_ivahon_ven                   money,
   @w_otr_ven                      money,
   @w_num_dec                      tinyint,
   @w_cotizacion_hoy               float,
   @w_monto_mop                    money,
   @w_monto_mn                     money,
   @w_numero_recibo                int,
   @w_ano_castigo                  int,
   @w_autoriza                     char(1),
   @w_rol_autoriza                 tinyint,
   @w_cond_ant                     tinyint,
   @w_clave1			           varchar(255),
   @w_clave2			           varchar(255),
   @w_saldo_fecha                  money,
   @w_estado_conc_cond             int,
   @w_estado_cond                  char(1),
   @w_concepto                     varchar(10),
   @w_secuencial_cond              int,
   @w_secuencial_ing               int,
   @w_operacion_cond               int,
   @w_rol_especial                 char(1)

set nocount on
set ansi_warnings off
   
/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_castigado  = @w_est_castigado out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_noven     out,
@o_est_vencido    = @w_est_vencido   out

if @w_error <> 0
   goto ERROR
   
/*  Captura nombre de Stored Procedure  */
select   @w_sp_name = 'sp_condonaciones'

-- PARAMETROS DE CONCEPTOS
select @w_param_cap = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'CAP'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701060
   goto ERROR
end

select @w_param_int = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701059
   goto ERROR
end

select @w_param_mora = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'IMO'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701084
   goto ERROR
end

select @w_param_honabo = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'HONABO'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701015
   goto ERROR
end

select @w_param_ivahonabo = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'IVAHOB'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701015
   goto ERROR
end

--MONEDA LEGAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

--LA FECHA DE INGRESO DEL PAGO DEBE SER LA FECHA DEL PRODUCTO DE CARTERA
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

if @i_fecha_proceso is null
   select @i_fecha_proceso = @w_fecha_proceso

-- CONTROL DEL NUMERO DE DECIMALES
exec @w_error = sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec out
   
if @w_error <> 0
   goto ERROR

if @i_banco is not null
begin   
select   
   @w_operacionca         = op_operacion,       
   @w_banco               = op_banco,
   @w_fecha_ult_proceso   = op_fecha_ult_proceso,
   @w_toperacion          = op_toperacion,
   @w_desc_toperacion     = ltrim(rtrim(op_toperacion)) + ' - ' + cx.valor,
   @w_plazo               = op_plazo,
   @w_cliente             = op_cliente, 
   @w_nombre              = op_nombre,
   @w_banca               = op_banca,
   @w_desc_banca          = (select valor from cobis..cl_catalogo where tabla = 2525 and codigo = op_banca),
   @w_fecha_liq           = op_fecha_liq,
   @w_nombre              = op_nombre,
   @w_numero_reest        = op_numero_reest,
   @w_cobranza            = op_estado_cobranza,
   @w_estado              = op_estado,
   @w_calificacion        = op_calificacion,
   @w_moneda              = op_moneda                         
from
   ca_operacion x,
   cobis..cl_catalogo cx      
where x.op_banco  = @i_banco
and   cx.codigo   = op_toperacion

if @@rowcount = 0
begin
   select @w_error = 710238
   goto ERROR
end


   select @w_rol_especial = 'N'
   if exists (select  1
           from    cobis..cl_catalogo c, cobis..cl_tabla t
           where     t.tabla = 'ca_roles_condona'
           and     c.tabla = t.codigo
           and     c.codigo = @s_rol
           and     c.estado = 'V')
   begin
      
      select @w_rol_especial = 'S'
   end           
   
if exists (select 1 from ca_condonacion where co_operacion = @w_operacionca and co_fecha_aplica = @w_fecha_proceso and co_concepto = @i_concepto and co_estado_concepto = @i_estado_concepto and co_estado not in ('R','E'))    and @w_rol_especial = 'N'
begin

         select @w_error = 721907
         goto ERROR   
end  

      if @w_moneda  = @w_moneda_nacional  begin -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
      select @w_cotizacion_hoy = 1.0
      select @w_monto_mop = @i_valor,
             @w_monto_mn  = @i_valor
     end   
     ELSE begin
      exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda,
      @i_fecha      = @w_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion_hoy output

      select @w_monto_mop = ceiling(@i_valor*10000.0 / @w_cotizacion_hoy)/10000.0
end

--SE OBTIENE BUSQUEDA DE CONDONACIONES ANTERIORES
select @w_cond_ant = count(1) from ca_condonacion where co_operacion = @w_operacionca and co_estado = 'A'

if @w_estado = @w_est_castigado
begin

  select @w_ano_castigo = datepart(yyyy,tr_fecha_mov)         
  from ca_operacion, ca_transaccion
  where op_estado = @w_est_castigado
  and  op_operacion = tr_operacion 
  and  op_operacion = @w_operacionca
  and  tr_tran = 'CAS'
  
  if @@rowcount = 0
     select @w_ano_castigo = 2008 --> Default por Fecha de Migración a Cobis
end

--CANTIDAD DE CUOTAS PAGADAS
   select @w_ncuotas_pag = count(di_dividendo)
   from ca_dividendo
   where di_operacion = @w_operacionca
   and di_estado = @w_est_cancelado

   select 
   di_dividendo,
   di_estado,
   di_fecha_ven,
   di_gracia
   into #dividendo
   from cob_cartera..ca_dividendo
   where di_operacion = @w_operacionca
   and   di_estado    <> @w_est_cancelado
   
   
-- CONSULTA DE DIAS MORA
   select @w_dias_mora = max(case when datediff(dd, di_fecha_ven, @w_fecha_ult_proceso) - di_gracia > 0 then datediff(dd, di_fecha_ven, @w_fecha_ult_proceso) else 0 end)
   from #dividendo       
   
/*SALDO DE LA OPERACION. MODIFICADO*/
   select @w_saldo_operacion = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from  ca_amortizacion, ca_rubro_op
   where am_operacion = @w_operacionca
   and   ro_operacion = @w_operacionca
   and   ro_tipo_rubro= 'C'
   and   ro_concepto  = am_concepto


if exists (select 1 from cob_credito..cr_hono_mora   -- INI JAR REQ 230
            where hm_estado_cobranza = @w_cobranza)
begin

   /* INCLUIR CALCULO DE SALDO DE HONORARIOS */
   exec @w_return    = sp_saldo_honorarios
   @i_banco          = @i_banco,
   --@i_num_dec        = @w_num_dec,
   @o_saldo_tot      = @w_saldo_cap out
  
   if @w_return <> 0 
   begin
      select @w_error = @w_return 
      goto ERROR
   end
   
   select @w_saldo_operacion_finan = isnull(@w_saldo_cap, 0)
end 
else
begin

   /* SALDO TOTAL DE LA OPERACION   */
   exec @w_return   = sp_calcula_saldo
   @i_operacion     = @w_operacionca,
   @i_tipo_pago     = 'A', --@w_anticipado_int,
   @o_saldo         = @w_saldo_operacion_finan out
   
   if @w_return <> 0 
   begin
      select @w_error = @w_return 
      goto ERROR
   end
       
   
   select @w_saldo_operacion_finan = isnull(@w_saldo_operacion_finan,0)
end
--- DIAS DE VENCIMIENTO MORA VA REAL 

/*SALDO DE CAPITAL EN MORA (CUOTAS VENCIDAS)*/
Select @w_saldo_mora = sum(am_cuota + am_gracia - am_pagado)
from ca_dividendo,ca_amortizacion
where di_operacion = @w_operacionca
and   di_operacion = am_operacion 
and   di_dividendo = am_dividendo 
and   di_estado    = 2

select @w_saldo_mora = isnull(@w_saldo_mora,0)

end

if @i_operacion = 'Q'
begin

   create table #condonaciones(   
      banco          varchar(64)      not null,
      operacion      int              not null,
      cliente        int              null,
      nomcliente     descripcion      null,
      banca          catalogo         null,
      descbanca      descripcion      null,
      linea          descripcion      null,
      cuotaspag      int              null,
      diasmora       smallint         null,   
      valvencido     money            null,
      valvigente     money            null,  
      valnoven       money            null,  
      condonacion    tinyint          null,
      secuencial     int              null)
   
   insert into #condonaciones   
   select distinct  
      op_banco,
      op_operacion,           
      op_cliente, 
      op_nombre,
      op_banca,
      (select valor from cobis..cl_catalogo where tabla = 2525 and codigo = op_banca),
      ltrim(rtrim(op_toperacion)),
      0,
      0,
      (select sum(co_valor) from ca_condonacion where co_estado_concepto = 2  and co_operacion = op_operacion and co_estado = 'V'),
      (select sum(co_valor) from ca_condonacion where co_estado_concepto = 1  and co_operacion = op_operacion and co_estado = 'V'),
      (select sum(co_valor) from ca_condonacion where co_estado_concepto = 0  and co_operacion = op_operacion and co_estado = 'V'),
      (select count(1) from ca_condonacion where co_operacion = op_operacion and co_estado = 'A'),
      co_secuencial            
   from
      ca_operacion ,
      ca_condonacion     
   where co_operacion   = op_operacion
   and  (op_oficina     = @i_oficina      or @i_oficina     is null)
   and  (op_cliente     = @i_ente         or @i_ente        is null)
   and  (op_banco       = @i_banco        or @i_banco       is null)
   and  (co_rol_condona = @i_rol          or @i_rol         is null)
   and  co_autoriza = @s_rol
   and  co_estado   = 'V'
   
--CANTIDAD DE CUOTAS PAGADAS
   select count(di_dividendo) as cuotas, di_operacion
   into #cuotas
   from ca_dividendo
   where di_operacion in (select distinct operacion from #condonaciones)
   and di_estado = @w_est_cancelado
   group by di_operacion

   update #condonaciones   
   set cuotaspag = cuotas
   from #cuotas, #condonaciones 
   where di_operacion = operacion   

   select 
   di_operacion,
   max(case when datediff(dd, di_fecha_ven, op_fecha_ult_proceso) - di_gracia > 0 then datediff(dd, di_fecha_ven, op_fecha_ult_proceso) else 0 end) as mora
   into #mora
   from cob_cartera..ca_dividendo, ca_operacion
   where di_operacion in (select distinct operacion from #condonaciones)
   and   di_estado    <> @w_est_cancelado
   and   di_operacion  = op_operacion
   group by di_operacion
   
-- CONSULTA DE DIAS MORA
   update #condonaciones
   set  diasmora = mora
   from #mora, #condonaciones
   where operacion = di_operacion   

   select 
   'Operacion'           = operacion,
   'Banco'               = banco,  
   'Cliente'             = cliente,    
   'Nombre del cliente'  = nomcliente, 
   'Tipo de banca'       = banca,      
   'Descripcion Banca'   = descbanca,  
   'Tipo de Linea'       = linea,      
   'Cuotas Pagadas'      = cuotaspag,  
   'Dias en Mora'        = diasmora,   
   'Valor Condonar Vencido' = valvencido, 
   'Valor Condonar Vigente' = valvigente, 
   'Valor Condonar No Vencido' = valnoven, 
   'Condonacion Anterior' = case condonacion when 0 then 'NO' else 'SI' end,
   'Secuencial'           = secuencial
   from #condonaciones  

end

if @i_operacion = 'S'
begin

   
create table #rubrocondonar(   
   descr          descripcion  not null,
   valor          money            null,
   porcentaje     float            null,
   valcond        money            null,
   saldo          money            null,
   estado         tinyint               )     
    
--INSERCION DE RUBROS
   insert into #rubrocondonar
   select am_concepto,
   isnull(sum(am_acumulado + am_gracia - am_pagado), 0),
   0, 
   0,
   isnull(sum(am_acumulado + am_gracia - am_pagado), 0),
   @w_est_vigente
   from ca_dividendo, ca_amortizacion
   where di_operacion = @w_operacionca
   and   di_estado    = @w_est_vigente
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo           
   group by am_concepto
   
   insert into #rubrocondonar
   select am_concepto,
   isnull(sum(am_cuota + am_gracia - am_pagado), 0),
   0, 
   0,
   isnull(sum(am_cuota + am_gracia - am_pagado), 0),
   @w_est_vencido
   from ca_dividendo, ca_amortizacion
   where di_operacion = @w_operacionca
   and   di_estado    = @w_est_vencido
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo           
   group by am_concepto   

--req 447
   insert into #rubrocondonar
   select am_concepto,
   isnull(sum(am_cuota + am_gracia - am_pagado), 0),
   0, 
   0,
   isnull(sum(am_cuota + am_gracia - am_pagado), 0),
   @w_est_noven
   from ca_dividendo, ca_amortizacion
   where di_operacion = @w_operacionca
   and   di_estado    = @w_est_noven
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo           
   group by am_concepto   

   


   /* Obtiene el Saldo a la Fecha de la obligación */
   select   @w_saldo_fecha = vx_monto
   from     ca_valor_atx 
   where    vx_banco = @i_banco

   select @w_saldo_fecha = isnull(@w_saldo_fecha,0)

   if @w_estado = @w_est_castigado
   begin              
      
      select 'pc_porcentaje' = pc_porcentaje_max,
             'pc_rubro'      = pc_rubro,
             'pc_vigentes'   = pc_valores_vigentes,
             'pc_noven'      = pc_valores_noven
             
      into   #porcondona1
      from   ca_param_condona, ca_rol_condona
      where  pc_codigo = rc_condonacion
      and    pc_banca  = @w_banca
      and    pc_ano_castigo = @w_ano_castigo 
      and    rc_rol = @s_rol
   
      update #rubrocondonar
      set    porcentaje = pc_porcentaje
      from   #rubrocondonar, #porcondona1
      where  descr = pc_rubro
      and    valor > 0
   
      update #rubrocondonar
      set    valcond = (valor * porcentaje) / 100          
      from   #rubrocondonar
      where  porcentaje <> 0
   
      update #rubrocondonar
      set    saldo   = valor - valcond
      from   #rubrocondonar
      where  porcentaje <> 0 and valcond > 0
   
      update #rubrocondonar
      set    porcentaje = 0
      from   #rubrocondonar, #porcondona1
      where  descr = pc_rubro
      and    pc_vigentes = 'N'
      and    estado = @w_est_vigente 
      
      --req 447 incidencia
      
      update #rubrocondonar
      set    porcentaje = 0
      from   #rubrocondonar, #porcondona1
      where  descr = pc_rubro
      and    pc_noven = 'N'
      and    estado = @w_est_noven 
   
      update #rubrocondonar
      set    valcond = 0
      from   #rubrocondonar
      where  porcentaje = 0
      and    estado = @w_est_vigente
   
      update #rubrocondonar
      set    saldo = valor
      from   #rubrocondonar
      where  porcentaje = 0
      and    estado = @w_est_vigente       
   end
   else
   begin  
     
      select 'pc_porcentaje' = pc_porcentaje_max,
             'pc_rubro'      = pc_rubro,
             'pc_vigentes'   = pc_valores_vigentes ,
             'pc_noven'      = pc_valores_noven
      into   #porcondona
      from   ca_param_condona, ca_rol_condona
      where  pc_codigo = rc_condonacion
      and    pc_banca  = @w_banca
      and    @w_dias_mora between pc_mora_inicial and pc_mora_final
      and    rc_rol = @s_rol
   
      update #rubrocondonar
      set    porcentaje = pc_porcentaje
      from   #rubrocondonar, #porcondona
      where  descr = pc_rubro
      and    valor > 0
   
      update #rubrocondonar
      set    valcond = (valor * porcentaje) / 100
      from   #rubrocondonar
      where  porcentaje <> 0  
   
      update #rubrocondonar
      set    saldo   = valor - valcond
      from   #rubrocondonar
      where  porcentaje <> 0 and valcond > 0
   
      update #rubrocondonar
      set    porcentaje = 0
      from   #rubrocondonar, #porcondona
      where  descr = pc_rubro
      and    pc_vigentes = 'N'
      and    estado = @w_est_vigente 
   
   --req 447 incidencia
      update #rubrocondonar
      set    porcentaje = 0
      from   #rubrocondonar, #porcondona
      where  descr = pc_rubro
      and    pc_noven = 'N'
      and    estado = @w_est_noven
   
   
      update #rubrocondonar
      set    valcond = 0
      from   #rubrocondonar
      where  porcentaje = 0
      and    estado = @w_est_vigente
   
      update #rubrocondonar
      set    saldo = valor
      from   #rubrocondonar
      where  porcentaje = 0
      and    estado = @w_est_vigente   
   end 

   if @i_opcion = 'T' begin --> Todos los conceptos separados por estado vigente y vencido   
      
      select   
	  @w_operacionca,
	  @w_banco,
	  @w_cliente,
	  @w_toperacion,
	  @w_desc_toperacion,
	  @w_plazo,
	  @w_banca,
	  @w_desc_banca,
	  convert(varchar(10),@w_fecha_liq,@i_formato_fecha), 
	  @w_ncuotas_pag,
	  @w_dias_mora,
	  @w_nombre,
	  @w_saldo_operacion_finan,
	  @w_saldo_mora,
	  @w_nombre,
	  @w_calificacion,
	  @w_ano_castigo,
	  case @w_cond_ant when 0 then 'NO' when null then 'N' else 'SI' end,
      @w_saldo_fecha

      /* DETERMINAR LOS SALDOS DE LOS RUBROS A LA FECHA DE PROCESO */
      
      select 
      'Concepto'     = descr,
      'Valor'        = valor,
      '% Max'        = porcentaje,
      '% Cond'       = 0,
      'Valor a Cond.'    = 0,
      'Saldo a Cancelar' = saldo,
      'Nro Condonaciones ' = (select count(1) from cob_cartera..ca_condonacion
                             where co_operacion =@w_operacionca
                             and   co_concepto = descr
                             and   co_estado_concepto = @w_est_vencido
                             and   co_estado = 'A'),
      'Nro Permitidas   ' = isnull((select limite_sup from cob_credito..cr_corresp_sib 
                              where tabla = 'T162'
                              and codigo_sib =descr
                              and convert(tinyint,monto_inf) = @w_est_vencido ),999),
      'Tiempo Condona   ' = isnull(datediff(dd, (select max(co_fecha_aplica) from cob_cartera..ca_condonacion 
						      where co_operacion =@w_operacionca
						      and   co_concepto = descr
						      and   co_estado_concepto = @w_est_vencido
                              and   co_estado = 'A'),@w_fecha_proceso) ,9999) ,

      'Tiempo Permitido ' = isnull((select limite_inf from cob_credito..cr_corresp_sib 
                              where tabla = 'T162'
                              and codigo_sib =descr
                              and convert(tinyint,monto_inf) = @w_est_vencido ),0),
      'Prioridad '      =  case descr when 'CAP' then '3'
                                      when 'INT' then '2'
                                      when 'IMO' then '1' else null end,
       'Signos'         =  '0'
      
      
      from #rubrocondonar
      where estado = @w_est_vencido
      
      select 
      'Concepto'     = descr,
      'Valor'        = valor,
      '% Max'        = porcentaje,
      '% Cond'       = 0,
      'Valor a Cond.'    = 0,
      'Saldo a Cancelar' = saldo,
      'Nro Condonaciones ' = (select count(1) from cob_cartera..ca_condonacion
                             where co_operacion =@w_operacionca
                             and   co_concepto = descr
                             and   co_estado_concepto = @w_est_vigente
                             and   co_estado = 'A'),
      'Nro Permitidas   ' = isnull((select limite_sup from cob_credito..cr_corresp_sib 
                              where tabla = 'T162'
                              and codigo_sib =descr
                              and convert(tinyint,monto_inf) = @w_est_vigente ),999),
      'Tiempo Condona   ' = isnull(datediff(dd, (select max(co_fecha_aplica) from cob_cartera..ca_condonacion 
						      where co_operacion =@w_operacionca
						      and   co_concepto = descr
						      and   co_estado_concepto = @w_est_vigente
                              and   co_estado = 'A'),@w_fecha_proceso) ,9999) ,

      'Tiempo Permitido ' = isnull((select limite_inf from cob_credito..cr_corresp_sib 
                              where tabla = 'T162'
                              and codigo_sib =descr
                              and convert(tinyint,monto_inf) = @w_est_vigente ),0),
      'Prioridad '      =  case descr when 'CAP' then '3'
                                      when 'INT' then '2'
                                      else null end,
      'Signos'         =  '0'
      
      
      from #rubrocondonar
      where estado = @w_est_vigente
      --req 447
      select 
      'Concepto'     = descr,
      'Valor'        = valor,
      '% Max'        = porcentaje,
      '% Cond'       = 0,
      'Valor a Cond.'    = 0,
      'Saldo a Cancelar' = saldo,
      'Nro Condonaciones ' = (select count(1) from cob_cartera..ca_condonacion
                             where co_operacion =@w_operacionca
                             and   co_concepto = descr
                             and   co_estado_concepto = @w_est_noven
                             and   co_estado = 'A'),
      'Nro Permitidas   ' = isnull((select limite_sup from cob_credito..cr_corresp_sib 
                              where tabla = 'T162'
                              and codigo_sib =descr
                              and convert(tinyint,monto_inf) = @w_est_noven ),999),
      'Tiempo Condona   ' = isnull(datediff(dd, (select max(co_fecha_aplica) from cob_cartera..ca_condonacion 
						      where co_operacion =@w_operacionca
						      and   co_concepto = descr
						      and   co_estado_concepto = @w_est_noven
                              and   co_estado = 'A'),@w_fecha_proceso) ,9999) ,

      'Tiempo Permitido ' = isnull((select limite_inf from cob_credito..cr_corresp_sib 
                              where tabla = 'T162'
                              and codigo_sib =descr
                              and convert(tinyint,monto_inf) = @w_est_noven ),0),
      'Prioridad '      =  case descr when 'CAP' then '3'
                                            else null end,
      
      'Signos'            =  '0'
      
                              
      from #rubrocondonar
      where estado = @w_est_noven

      
   end	
   
   if @i_opcion = 'U' begin --> Conceptos Unificados para grilla de acuerdos de pago
   --print 'condonaciones.sp nueva politica ' + cast(@w_operacionca as varchar) + ' - ' + cast(@w_dias_mora as varchar) + 
   --                               ' banca ' + cast(@w_banca as varchar)       + ' - ' + cast(@s_rol as varchar)
      
      insert into #rubros 
      values ('OTROS',0,0.0)
      insert into #rubros 
      values ('IMO',0,0.0)
      insert into #rubros 
      values ('INT',0,0.0)
      insert into #rubros 
      values ('CAP',0,0.0)

      update #rubros
         set valor      = case descr when 'CAP' then (select sum(valcond) from #rubrocondonar where descr = 'CAP')
                                     when 'INT' then (select sum(valcond) from #rubrocondonar where descr = 'INT')
                                     when 'IMO' then (select sum(valcond) from #rubrocondonar where descr = 'IMO')end,
             porc       = case descr when 'CAP' then (select max(porcentaje) from #rubrocondonar where descr = 'CAP')
                                     when 'INT' then (select max(porcentaje) from #rubrocondonar where descr = 'INT')
                                     when 'IMO' then (select max(porcentaje) from #rubrocondonar where descr = 'IMO')end
      from #rubrocondonar
      where descr = concepto
      
      update #rubros
         set valor      = (select sum(valcond)    from #rubrocondonar where descr not in ( 'CAP', 'INT', 'IMO' )),
             porc       = (select max(porcentaje) from #rubrocondonar where descr not in ( 'CAP', 'INT', 'IMO' ))
      from #rubrocondonar 
      where descr    not in ( 'CAP', 'INT', 'IMO' )
      and   concepto not in ( 'CAP', 'INT', 'IMO' )    
  end
   
   
--Req 447 acelis

select @w_rol_especial = 'N'
if exists (select  1
           from    cobis..cl_catalogo c, cobis..cl_tabla t
           where     t.tabla = 'ca_roles_condona'
           and     c.tabla = t.codigo
           and     c.codigo = @s_rol
           and     c.estado = 'V')
begin
    
    select @w_rol_especial = 'S'
end           
select @w_rol_especial   
return 0
end

if @i_operacion = 'I'
begin

   select @w_operacionca= op_operacion from ca_operacion with (nolock) where op_banco  = @i_banco
   
   
   select @w_rol_especial = 'N'
   if exists (select  1
           from    cobis..cl_catalogo c, cobis..cl_tabla t
           where     t.tabla = 'ca_roles_condona'
           and     c.tabla = t.codigo
           and     c.codigo = @s_rol
           and     c.estado = 'V')
   begin
      
      select @w_rol_especial = 'S'
   end           

   select @w_estado_conc_cond = co_estado_concepto,
          @w_estado_cond = co_estado,
          @w_concepto = co_concepto,
          @w_secuencial_cond = co_secuencial
   from ca_condonacion with (nolock)
   where co_operacion    = @w_operacionca
   and   co_fecha_aplica = @w_fecha_proceso
   and   co_concepto     = @i_concepto
   and   co_estado      not in ('E','R')

   if @w_estado_conc_cond = @i_estado_concepto and @w_rol_especial = 'N'
   begin
   
         select @w_error = 721907
         goto ERROR   
   end  

   if @w_estado = @w_est_castigado
   begin
        select @w_autoriza = pc_control_autorizacion       
        from   ca_param_condona with (nolock), ca_rol_condona with (nolock)
        where  pc_banca  = @w_banca
        and    rc_condonacion = pc_codigo
        and    pc_ano_castigo = @w_ano_castigo 
        and    pc_rubro = @i_concepto 
        and    rc_rol = @s_rol        
   end
   else
   begin
        select @w_autoriza = pc_control_autorizacion
        from   ca_param_condona with (nolock), ca_rol_condona with (nolock)
        where  pc_banca  = @w_banca
        and    rc_condonacion = pc_codigo
        and    @w_dias_mora between pc_mora_inicial and pc_mora_final
        and    pc_rubro = @i_concepto
        and    rc_rol   = @s_rol
   end
   
   if @w_autoriza = 'S'
      select @w_rol_autoriza = rac_rol_autoriza
      from   ca_rol_autoriza_condona with (nolock)
      where  rac_rol_condona = @s_rol        
                   
   BEGIN TRAN              

     select @w_secuencial = ab_secuencial_ing
     from ca_abono with (nolock)
     where ab_operacion = @w_operacionca
     and   ab_fecha_pag = @w_fecha_proceso
     and   ab_estado not in ('RV','E','A','NA')


     -- SI NO ENCUENTRA UN PAGO EN ESTADO ING O SI EL FRONT ESTA FORZANDO A CREAR UN PAGO NUEVO 
     -- SI EL CONCEPTO A CONDONAR YA ESTA CONDONADO PARA LA FECHA CREA UN NUEVO PAGO
     -- EN CASO CONTRARIO ADICIONA UN NUEVO DETALLE AL PAGO
         
     if @w_secuencial is null or @i_crea_pago = 'S' or
       (@w_concepto = @i_concepto and @w_secuencial_cond = @w_secuencial and @w_estado_cond = 'V')

     begin
          select @w_secuencial = 0

          exec @w_secuencial = sp_gen_sec
          @i_operacion  = @w_operacionca
          
          exec @w_secuencial_pag = sp_gen_sec
          @i_operacion      = @w_operacionca
          
          exec @w_return = sp_numero_recibo
          @i_tipo    = 'P',
          @i_oficina = @s_ofi,
          @o_numero  = @w_numero_recibo out
           
          if @w_return <> 0 begin
             select @w_error =  @w_return
             goto ERROR
          end               
                                    
           insert into ca_abono with (rowlock)
           (ab_secuencial_ing,     ab_secuencial_rpa,           ab_secuencial_pag,            
            ab_operacion,          ab_fecha_ing,                ab_fecha_pag,           
            ab_cuota_completa,     ab_aceptar_anticipos,        ab_tipo_reduccion,  
            ab_tipo_cobro,         ab_dias_retencion_ini,       ab_dias_retencion,
            ab_estado,             ab_usuario,                  ab_oficina,                   
            ab_terminal,           ab_tipo,                     ab_tipo_aplicacion,     
            ab_nro_recibo,         ab_tasa_prepago,             ab_dividendo,       
            ab_calcula_devolucion, ab_prepago_desde_lavigente)
           values(
            @w_secuencial,         0,                           @w_secuencial_pag,                            
            @w_operacionca,        @w_fecha_proceso,            @w_fecha_proceso,              
            'N',                   'S',                         'N',      
            'P',                   0,                           0,
            'ING',                 @s_user,                     @s_ofi,                   
            @s_term,               'PAG',                       'D',         
            @w_numero_recibo,      0.00,                        0,                      
            'N',                   'N')
           
           if @@error <> 0 begin              
              select @w_error = 710232
              goto ERROR
           end
                                
           -- Valores de Comisiones por recaudo
           
           if @i_concepto is not null begin
              insert into ca_abono_prioridad with (rowlock)
              (ap_secuencial_ing, ap_operacion, ap_concepto, ap_prioridad)
              select @w_secuencial, @w_operacionca, ro_concepto, ro_prioridad
              from   ca_rubro_op with (nolock)
              where  ro_operacion = @w_operacionca
              and    ro_fpago not in ('L','B')
              
              if @@error <> 0 begin                 
                 select @w_error = 710234
                 goto ERROR
              end                            
              
              update ca_abono_prioridad with (rowlock)
              set ap_prioridad = 0
              where ap_operacion      = @w_operacionca
              and   ap_secuencial_ing = @w_secuencial
              and  (ap_concepto       = @i_concepto or @i_concepto is null)

              if @@error <> 0 begin                 
                 select @w_error = 710234
                 goto ERROR
              end                                          
         
          end
      end

      -- INSERTAR EN ca_abono_det           
          
      select @w_monto_mop = @i_valor, @w_monto_mn = @i_valor

      insert into ca_abono_det with (rowlock)
      (abd_secuencial_ing,    abd_operacion,         abd_tipo,            
       abd_concepto ,         abd_cuenta,            abd_beneficiario,    
       abd_moneda,            abd_monto_mpg,         abd_monto_mop,         
       abd_monto_mn,          abd_cotizacion_mpg,    abd_cotizacion_mop,
       abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,          
       abd_cod_banco,         abd_inscripcion,       abd_carga,
       abd_porcentaje_con,    abd_solidario)                              --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
      values(                                        
       @w_secuencial,         @w_operacionca,        'CON',               
       @i_concepto,           ' '                    ,' ',     
       0,                     @i_valor,              @w_monto_mop,          
       @w_monto_mn,           @w_cotizacion_hoy,     @w_cotizacion_hoy,
       'C',                    'C',                  null,                
       null,                  null,                  null,
       @i_porcentaje,         'N')
      
      if @@error <> 0 begin         
         select @w_error = 710233
         goto ERROR
      end

            
      insert into ca_condonacion with (rowlock)(
      co_secuencial,       co_operacion ,   co_fecha_aplica, 
      co_valor,            co_porcentaje,   co_concepto,
      co_estado_concepto,  co_usuario,      co_rol_condona,
      co_autoriza,         co_estado,       co_excepcion,
      co_porcentaje_par)
	  values
	  (@w_secuencial,      @w_operacionca,  @w_fecha_proceso,
	   @i_valor,	       @i_porcentaje,   @i_concepto,
	   @i_estado_concepto, @s_user,         @s_rol,
	   @w_rol_autoriza,	   'V',             @i_excepcion,
	   @i_porcentaje_par)   	 
	 	   
      if @@error <> 0 begin          
      
          select @w_error = 603059
          goto ERROR
      end                    
      
      select @w_clave1 = convert(varchar(255),@w_operacionca)
      select @w_clave2 = convert(varchar(255),@w_secuencial)    
            
      exec @w_error = sp_tran_servicio
          @s_user    = @s_user, 
          @s_date    = @s_date, 
          @s_ofi     = @s_ofi,  
          @s_term    = @s_term, 
          @i_tabla   = 'ca_condonacion',
          @i_clave1  = @w_clave1,
          @i_clave2  = @w_clave2,
          @i_clave3  = @i_concepto,
          @i_clave4  = @i_operacion
      
      if @w_error <> 0
      begin        
        select @w_error = @w_error        
        goto ERROR
      end            
   
   COMMIT TRAN   
      
   select @o_autoriza = @w_autoriza  
   
   select @o_secuencial = @w_secuencial   
     
end
if @i_operacion = 'A'
begin      
    begin tran          
      
      select @w_secuencial_pag = ab_secuencial_pag
      from ca_abono with (nolock)
      where ab_operacion = @w_operacionca
      and   ab_secuencial_ing = @i_secuencial
      
      if @@rowcount = 0 begin         
         select @w_error = 710238
         goto ERROR
      end            
       
       exec @w_return    = sp_registro_abono
            @s_user           = @s_user,
            @s_term           = @s_term,
            @s_date           = @s_date,
            @s_ofi            = @s_ofi,
            @s_ssn            = @s_ssn,
            @s_sesn           = @s_sesn,
            @s_srv            = @s_srv,            
            @i_secuencial_ing = @i_secuencial,
            @i_secuencial_pag = @w_secuencial_pag,           -- ITO 11/02/2010
            @i_operacionca    = @w_operacionca,
            @i_en_linea       = 'S',
            @i_fecha_proceso  = @w_fecha_proceso,
            @i_mon            = @w_moneda,      
            @i_dividendo      = 0,
            @i_cotizacion     = @w_cotizacion_hoy

       if @@error <> 0 begin          
          select @w_error = @w_return
          goto ERROR
       end                      
       
       
       exec @w_return    = sp_cartera_abono
         @s_user           = @s_user,                
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_ofi            = @s_ofi,
         @s_rol		       = @s_rol,
         @i_secuencial_ing = @i_secuencial,
         @i_operacionca    = @w_operacionca,
         @i_fecha_proceso  = @w_fecha_proceso,
         @i_en_linea       = 'S',
         @i_dividendo      = 0,
         @i_cancela        = 'N',
         @i_renovacion     = 'N',
         @i_cotizacion     = @w_cotizacion_hoy
   
       if @@error <> 0 begin          
          select @w_error = @w_return
          goto ERROR
       end                      
       
         update ca_condonacion
         set    co_estado = 'A'
         where  co_operacion = @w_operacionca
         and    co_fecha_aplica = @i_fecha_proceso
         and    co_secuencial   = @i_secuencial

         if @@error <> 0 begin            
            select @w_error = 705064
            goto ERROR
         end 
      
      select @w_clave1 = convert(varchar(255),@w_operacionca)
      select @w_clave2 = convert(varchar(255),@i_secuencial)
      
      exec @w_error = sp_tran_servicio
          @s_user    = @s_user,
          @s_date    = @s_date,
          @s_ofi     = @s_ofi,
          @s_term    = @s_term,
          @i_tabla   = 'ca_condonacion',
          @i_clave1  = @w_clave1,
          @i_clave2  = @w_clave2,
          @i_clave4  = @i_operacion
      
      if @w_error <> 0
      begin         
        select @w_error = @w_error
        goto ERROR
      end
      
      
      COMMIT TRAN            
end

if @i_operacion = 'R'
begin 

    /* Obtener secuencial de Ingreso del pago*/
    select @w_secuencial_ing = 0
    
    select @w_secuencial_ing = isnull(ab_secuencial_ing,0),
           @w_operacion_cond = co_operacion 
    from ca_abono, ca_condonacion
    where ab_operacion      = @w_operacionca
    and   ab_secuencial_pag = @i_secuencial    
    and   co_operacion      = ab_operacion
    and   co_secuencial     = ab_secuencial_ing
     
    begin tran
           
    if isnull(@w_secuencial_ing,0) <> 0 and isnull(@w_operacion_cond,0) <> 0 begin
       update ca_condonacion
       set    co_estado     = 'R'
       where  co_operacion  = @w_operacionca
       and    co_secuencial = @w_secuencial_ing
       and    co_estado     = 'A'
    
       if @@error <> 0
       begin
          select @w_error = 705064
          goto ERROR
       end

       select @w_clave1 = convert(varchar(255),@w_operacionca)
       select @w_clave2 = convert(varchar(255),@w_secuencial_ing)
    
       exec @w_error = sp_tran_servicio
            @s_user    = @s_user,
            @s_date    = @s_date,
            @s_ofi     = @s_ofi,
            @s_term    = @s_term,
            @i_tabla   = 'ca_condonacion',
            @i_clave1  = @w_clave1,
            @i_clave2  = @w_clave2,
            @i_clave4  = @i_operacion
      
        if @w_error <> 0
        begin
           goto ERROR
        end

    end
    
     
     COMMIT TRAN
end
if @i_operacion = 'E'
begin 
    /* Obtener secuencial de Ingreso del pago*/
    select @w_secuencial_ing = 0
    
    select @w_secuencial_ing = isnull(ab_secuencial_ing,0),
           @w_operacion_cond = co_operacion 
    from ca_abono, ca_condonacion
    where ab_operacion      = @w_operacionca
    and   ab_secuencial_ing = @i_secuencial
    and   co_operacion      = ab_operacion
    and   co_secuencial     = ab_secuencial_ing
    
    begin tran

    exec @w_return = sp_eliminar_pagos
        @s_user           = @s_user,
        @s_term           = @s_term,
        @i_banco          = @i_banco,
        @i_operacion      = 'D',
        @i_secuencial_ing = @i_secuencial
        
     if @w_return <> 0
     begin
        select @w_error = @w_return
        goto ERROR
     end
    
    select @w_clave1 = convert(varchar(255),@w_operacionca)
    select @w_clave2 = convert(varchar(255),@i_secuencial)

    exec @w_error = sp_tran_servicio
        @s_user    = @s_user,
        @s_date    = @s_date,
        @s_ofi     = @s_ofi,
        @s_term    = @s_term,
        @i_tabla   = 'ca_condonacion',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2,
        @i_clave4  = @i_operacion
      
     if @w_error <> 0
     begin
        goto ERROR
     end
     
     COMMIT TRAN
end
return 0
ERROR:
 
   exec cobis..sp_cerror
   @t_debug = 'N',    
   @t_file  = null,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error

   if @@trancount > 0
      rollback 
      
   return @w_error

go

