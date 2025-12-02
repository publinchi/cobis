/************************************************************************/
/*   Nombre Fisico:        datcast.sp                                   */
/*   Nombre Logico:        sp_datcast                                   */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   Mar 1999.                                    */
/************************************************************************/
/*                                  IMPORTANTE                          */
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
/*                                      CAMBIOS                         */
/*      EPB:feb-13-2002                                                 */
/*      EPB:MAY-23-2002  actualizar el select para que no genere el     */
/*                       concepto de seguros en estado 1                */
/*      EPB:MAY-28-2002  en concepto INTDES deve ser enviado como CAP   */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_procesos_consolidador_tmp')
   drop table ca_procesos_consolidador_tmp
go

create table ca_procesos_consolidador_tmp
(proceso        int,
 estado         char(1),
 operacion_ini  int,
 operacion_fin  int)
go


if exists (select 1 from sysobjects where name = 'sp_datcast')
   drop proc sp_datcast
go


create proc sp_datcast
@s_user        login,
@s_date        datetime, ---Fecha de proceso digitada por operador
@i_modo        char(1)  = null,
@i_banco       cuenta   = null,
@i_siguiente   cuenta   = null,
@i_en_linea    char(1)  = 'N',
@i_siempre     char(1)  = 'N',
@i_proceso     int      = null
as 
declare
@w_error                   int,          
@w_return                  int,    
@w_sp_name                 descripcion,  
@w_fecha_liq               datetime,
@w_fecha_ult_proceso       datetime,     
@w_operacionca             int,          
@w_op_cliente              int,          
@w_moneda                  smallint,     
@w_oficina                 smallint,     
@w_banco                   varchar(24),       
@w_toperacion              catalogo,     
@w_dias_anio               smallint,     
@w_estado                  tinyint,      
@w_estado_con              tinyint,      
@w_edad                    tinyint,      
@w_sector                  catalogo,     
@w_fecha_prox_pago         datetime,     
@w_est_vigente             tinyint,      
@w_est_vencido             tinyint,      
@w_est_novigente           tinyint,      
@w_est_cancelado           tinyint,      
@w_est_anulado             tinyint,
@w_est_credito             tinyint,
@w_est_suspenso            int,
@w_est_castigado           int,
@w_est_condonado           int,
@w_est_recompra            int,
@w_est_precancelado        int,
@w_est_judicial            int,
@w_est_novedades           int,
@w_est_ley550              int,
@w_est_cja                 int,
@w_producto                tinyint,
@w_monto                   money,
@w_fecha_fin               datetime,
@w_fecha_ini               datetime,
@w_periodicidad            char(1),
@w_num_periodicidad        smallint,
@w_num_reest               int,
@w_num_renova              tinyint,
@w_destino                 catalogo,
@w_ciudad                  int,
@w_clase                   catalogo,
@w_tramite                 int,
@w_tasa                    float,
@w_modalidad               char(1),
@w_fecha_ven               datetime,
@w_dias_venc               int,
@w_fecha_ven_cap           datetime,
@w_fecha_pago_cap          datetime,
@w_dias_vencido            int,
@w_dias_vencido_cap        int,
@w_fecha_prxvto            datetime,
@w_valor_cuota             money,
@w_cuota_cap               money,
@w_saldo_cap               money,
@w_saldo_cap_ven           money,
@w_saldo_int               money,
@w_saldo_otro              money,
@w_saldo_int_sus           money,
@w_calificacion            catalogo,
@w_numero_renovaciones     int,
@w_dias_clausula           int,
@w_renovacion              char(1),
@w_div_cancelado           int,
@w_div_vigente             int,
@w_reestructuracion        char(1),
@w_gar_admisible           char(1),
@w_tipo_garantia           char(1),
@w_tipo                    char(1),
@w_base_calculo            char(1),
@w_fecha_ult_reest         datetime,
@w_num_cuot_pag            smallint,
@w_num_cuot_pagadas        smallint,
@w_monto_cubierto_gar      money,
@w_fecha_const_gar         datetime,
@w_est_comext              tinyint,
@w_periodo_cap             smallint,
@w_periodicidad_cap        int,
@w_divid_ven_cap           int,
@w_divid_cap               int,
@w_suspenso                char(1),
@w_dias_plazo              int,
@w_monto_resultado         money,
@w_monto_pesos             money,
@w_saldo_vencido           money,
@w_num_div_vencidos        smallint,
@w_saldo_int_ven           money,
@w_saldo_otr_ven           money,
@w_oficial                 smallint,
@w_plazo                   smallint,          
@w_tplazo                  catalogo,
@w_num_cuotas              smallint,
@w_periodicidad_cuota      smallint,
@w_secuencial_max          int,
@w_valor_ult_pago          money, 
@w_fecha_castigo           datetime,
@w_fecha                   datetime,
@w_fecha1     datetime,
@w_ru_cre                  char(10),
@w_mes                     smallint,
@w_mes1                    smallint,
@w_saldo_concepto          money,   
@w_saldo_concepto_a        money,   
@w_modo                    char(1), 
@w_saldo                   money,   
@w_siguiente_dia           datetime,
@w_commit                  char(1), 
@w_concepto_cap            catalogo,
@w_op_reestructuracion     char(1), 
@w_op_lin_credito          cuenta,  
@w_op_num_renovacion       int,     
@w_estado_desembolso       char(1), 
@w_op_migrada              cuenta,  
@w_fin_mes                 char(1), 
@w_saldo_mora              money,    
@w_otros_total             money,   
@w_concepto_intdes         catalogo,
@w_saldo_intdes_ven        money,   
@w_saldo_intdes            money,   
@w_op_tipo_cambio          char(1), 
@w_probabilidad_default    float,   
@w_rct_fpago               char(1), 
@w_saldo_otr_ant           money,   
@w_min_div_vencido         smallint,
@w_max_div_vencido         smallint,
@w_max_div_vigente         smallint,
@w_saldo_seg_vig           money,   
@w_saldo_seg_ven           money,   
@w_rubro_seg_vida          catalogo,
@w_saldo_concepto_int      money,   
@w_saldo_concepto_intant   money,
@w_saldo_concepto_imo      money,
@w_cap_contingente         money,
@w_int_contingente         money,
@w_imo_contingente         money,
@w_correc_cap_vig          money,
@w_correc_int_vig          money,
@w_correc_imo_vig          money,
@w_moneda_uvr              smallint,
@total_int                 money,
@total_int_ant             money,
@w_int_imo_uvr             money,
@w_ms                      datetime,
@w_mc                      datetime,
@w_temporal                int,
@w_max                     int,
@w_contador                int,
@w_ccon 		   varchar(30),
@w_sit_castigo 		   varchar(30)

select @w_max = 0, @w_contador = 0
   
select @w_sp_name        = 'sp_consolidador' ,
       @w_fin_mes        = 'N'

PRINT 'datconso.sp PROCESO ' + cast (@i_proceso as varchar)

select @w_concepto_cap = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'CAP'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_ccon = pa_char
from cobis..cl_parametro 
where pa_nemonico = 'CCON' 
and pa_producto = 'CRE'
set transaction isolation level read uncommitted

--Situacion de castigo
select @w_sit_castigo = pa_char
from cobis..cl_parametro 
where pa_nemonico = 'SITCS' 
and pa_producto = 'CRE'
set transaction isolation level read uncommitted

-- CODIGO DE LA MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
set transaction isolation level read uncommitted

select @w_est_novigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

select @w_est_vigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CANCELADO'

select @w_est_judicial  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'JUDICIAL'

select @w_est_precancelado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'PRECANCELADO'

select @w_est_castigado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CASTIGADO'

select @w_est_credito  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CREDITO'

select @w_est_suspenso   = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'SUSPENSO'

select @w_est_anulado = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'ANULADO'

select @w_est_condonado = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CONDONADO'

select @w_est_recompra = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'RECOMPRA'

select @w_est_comext = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'COMEXT'

select @w_est_novedades = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'NOVEDADES'

select @w_est_cja = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'COBRO JURIDICO ACTIVAS'

select @w_est_ley550 = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'LEY 550'


select @w_siguiente_dia = @s_date,
       @w_probabilidad_default = 0.0

select @w_concepto_intdes = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INTFAC'
set transaction isolation level read uncommitted

-- CODIGO DEL PRODUCTO DE CARTERA
select @w_producto = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted

-- CODIGO DEL RUBRO SEGURO DE VIDA
select @w_rubro_seg_vida = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'SEGURO'
set transaction isolation level read uncommitted

select @w_siguiente_dia = dateadd(dd,1,@w_siguiente_dia)

if @i_en_linea = 'S' 
begin

   select @w_fecha  = convert(varchar(10),@s_date,101)
   select @w_mes    = datepart(mm,@w_fecha)

   select @w_fecha1 = convert(varchar(10),@w_siguiente_dia,101)
   select @w_mes1   = datepart(mm,@w_fecha1)

   if @w_mes1 <> @w_mes 
      select @w_fin_mes = 'S'
   else
      select @w_fin_mes = 'N'
      
end

if @i_en_linea = 'N' 
begin

   exec @w_return = sp_dia_habil 
        @i_fecha  = @w_siguiente_dia,
        @i_ciudad = 11001,  ---BOGOTA
        @o_fecha  = @w_siguiente_dia out
   
   if @w_return !=0
   begin
      select @w_error = @w_return
      goto ERROR1
   end
   
   select @w_fecha  = convert(varchar(10),@s_date,101)
   select @w_mes    = datepart(mm,@w_fecha)
   
   select @w_fecha1 = convert(varchar(10),@w_siguiente_dia,101)
   select @w_mes1   = datepart(mm,@w_fecha1)
   
   if @w_mes1 <> @w_mes 
      select @w_fin_mes = 'S'
   else
      select @w_fin_mes = 'N'
      
end

-- EJECUCION DEL PROCESO
-- CURSOR PARA LEER TODAS LAS OPERACIONES A PROCESAR
if @i_modo =  'F' 
begin    
   declare
   cursor_operacion_nuevo cursor
   for select op_operacion,        op_banco,          op_toperacion,          
   op_moneda,           op_oficina,        op_fecha_ult_proceso,   
   op_dias_anio,        op_estado,         op_banca,              
   op_cliente,          op_fecha_liq,      op_fecha_ini,           
   op_dias_clausula,    op_monto,          op_fecha_fin,
   op_tdividendo,       op_numero_reest,   op_num_renovacion,
   op_destino,          op_clase,          op_ciudad,
   op_tramite,          op_calificacion,   op_renovacion,
   op_gar_admisible,    op_tipo,      op_edad,
   op_base_calculo,     op_periodo_cap,    op_oficial,
   op_plazo,            op_tplazo,         op_gar_admisible,
   op_reestructuracion, op_lin_credito,    op_num_renovacion,
   op_tipo_cambio
   from   ca_operacion,  ca_default_toperacion 
   where  op_estado not in (@w_est_novigente, @w_est_credito, @w_est_comext) 
   and   (op_banco = @i_banco or @i_banco is null)
   and   (op_banco > @i_siguiente or @i_siguiente is null)
   and   (op_fecha_ult_proceso > @s_date  or (op_estado in (@w_est_cancelado, @w_est_castigado, @w_est_anulado, @w_est_suspenso, @w_est_novedades))) 
   and    op_toperacion = dt_toperacion
   and    op_tramite is not null      --- Consideracion para la migracion.
   and    dt_naturaleza = 'A'
   order  by op_banco
end   
ELSE
begin
   declare
   cursor_operacion_nuevo cursor
   for select op_operacion,   op_banco,        op_toperacion,          
   op_moneda,           op_oficina,      op_fecha_ult_proceso,   
   op_dias_anio,        op_estado,       op_banca,              
   op_cliente,          op_fecha_liq,    op_fecha_ini,           
   op_dias_clausula,    op_monto,        op_fecha_fin,
   op_tdividendo,       op_numero_reest, op_num_renovacion,
   op_destino,          op_clase,        op_ciudad,
   op_tramite,          op_calificacion, op_renovacion,
   op_gar_admisible,    op_tipo,         op_edad,
   op_base_calculo,     op_periodo_cap,  op_oficial,
   op_plazo,            op_tplazo,       op_gar_admisible,
   op_reestructuracion, op_lin_credito,  op_num_renovacion,
   op_tipo_cambio
   from   ca_operacion, ca_default_toperacion, ca_procesos_consolidador_tmp
   where  op_estado not in (@w_est_novigente, @w_est_credito, @w_est_comext) 
   and   (op_banco = @i_banco or @i_banco is null)
   and   (op_banco > @i_siguiente or @i_siguiente is null)
   --and   (op_fecha_ult_proceso > @s_date  or (op_estado in (@w_est_cancelado, @w_est_castigado, @w_est_anulado) and (datepart(mm,op_fecha_ult_mov) = datepart(mm,@s_date))) or (op_estado in (@w_est_suspenso,@w_est_novedades))) ----FECHA PROCESO DE OPERACIONES DESPUES DEL BATCH   ,@w_est_ley550
   and   (op_fecha_ult_proceso > @s_date  or (op_estado in (@w_est_cancelado, @w_est_castigado, @w_est_anulado, @w_est_suspenso, @w_est_novedades))) 
   and    op_toperacion = dt_toperacion
   and    op_tramite is not null --- Consideracion para la migracion.
   and    dt_naturaleza = 'A'
   and    proceso       = @i_proceso
   and    op_operacion between operacion_ini and operacion_fin
   order by op_banco
end  



open  cursor_operacion_nuevo                                        
    
fetch cursor_operacion_nuevo
into  @w_operacionca,         @w_banco,            @w_toperacion,          
      @w_moneda,              @w_oficina,          @w_fecha_ult_proceso,   
      @w_dias_anio,           @w_estado,           @w_sector,    
      @w_op_cliente,          @w_fecha_liq,        @w_fecha_ini,           
      @w_dias_clausula,       @w_monto,            @w_fecha_fin,
      @w_periodicidad,        @w_num_reest,        @w_num_renova,
      @w_destino,             @w_clase,            @w_ciudad,
      @w_tramite,             @w_calificacion,     @w_renovacion,
      @w_gar_admisible,       @w_tipo,             @w_edad,
      @w_base_calculo,        @w_periodo_cap,      @w_oficial,
      @w_plazo,               @w_tplazo,           @w_gar_admisible,
      @w_op_reestructuracion, @w_op_lin_credito,   @w_op_num_renovacion,
      @w_op_tipo_cambio
       
while @@fetch_status = 0
begin
   if @@fetch_status = -1 return  70899 -- error en la base

   --exec sp_reloj 1, @w_ms, @w_ms out, @w_max
   
   --if @w_contador % 500 = 0
   --   exec sp_reloj @w_contador, @w_mc, @w_mc out, @w_max   

   select @w_contador = @w_contador + 1
   
   select @w_commit = 'S'
   
   select @w_banco = rtrim(@w_banco)
   
   select @w_divid_ven_cap       = 0,
          @w_fecha_ven_cap       = null,
          @w_fecha_ven           = null,
          @w_dias_vencido        = 0,
          @w_dias_vencido_cap    = 0,
          @w_suspenso            = null,
          @w_num_div_vencidos    = 0,
          @w_num_div_vencidos    = 0,
          @w_num_cuotas          = 0,
          @w_tasa                = 0,
          @w_num_periodicidad    = 0,
          @w_modalidad           = null,
          @w_fecha_ven           = null,
          @w_divid_ven_cap       = 0,
          @w_fecha_ven_cap       = null,
          @w_numero_renovaciones = 0,
          @w_div_cancelado       = 0,
          @w_saldo_cap           = 0,
          @w_saldo_cap_ven       = 0,
          @w_saldo_int_sus       = 0,
          @w_saldo_int           = 0,
          @w_saldo_int_ven       = 0,
          @w_saldo_otro          = 0,
          @w_saldo_otr_ven       = 0, 
          @w_saldo_vencido       = 0, 
          @w_fecha_pago_cap      = null,
          @w_secuencial_max      = 0,
          @w_valor_ult_pago      = 0,
          @w_divid_cap           = 0,
          @w_cuota_cap           = 0,
          @w_num_cuot_pagadas    = 0,
          @w_otros_total         = 0,
          @w_op_migrada          = 'NOMIGRADA',
          @w_saldo_intdes_ven    = 0,
          @w_saldo_intdes        = 0,
          @w_saldo_otr_ant       = 0,
          @w_saldo_concepto_a    = 0,
          @w_saldo_mora          = 0
   
   if @w_estado = @w_est_novedades 
      select @w_fecha_ult_proceso = @s_date

   -- NUMERO DE CUOTAS DE LAS OPERACION
   select @w_num_cuotas = count(1)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
      
   -- NUMERO DE DIVIDENDOS VENCIDOS
   select @w_num_div_vencidos = count(1)
   from   ca_dividendo
   where  di_operacion = @w_operacionca 
   and    di_estado    = @w_est_vencido
   
   if @w_op_num_renovacion > 0
      select @w_estado_desembolso = 'R'
   else
      select @w_estado_desembolso = 'N'
      
   --exec sp_reloj 1.1, @w_ms, @w_ms out, @w_max   
   
   -- ESTADO CONTABILIZADO
   select @w_estado_con = 0
   
   if (@w_estado=@w_est_vigente or @w_estado = @w_est_novedades or @w_estado = @w_est_cja) and @w_edad in (1, 7, 12, 17)
      select @w_estado_con = 1
   
   if ((@w_estado=@w_est_vigente or @w_estado = @w_est_novedades or @w_estado = @w_est_cja) and @w_edad not in (1, 7, 12, 17))
      or (@w_estado=@w_est_suspenso)
      or (@w_estado = @w_est_vencido)
      select @w_estado_con = 2
   
   if @w_estado = @w_est_castigado
      select @w_estado_con = 3
   
   if @w_estado in (@w_est_cancelado, @w_est_precancelado, @w_est_condonado)
      select @w_estado_con = 4
   
   if @w_estado = @w_est_anulado
      select @w_estado_con = 5
   
   if @w_estado = @w_est_suspenso
      select @w_suspenso = 'S'
   
   -- TASA DE LA OPERACION
   select @w_tasa = sum(ro_porcentaje_efa)
   from   ca_rubro_op
   where  ro_operacion   = @w_operacionca
   and    ro_fpago      in ('P','A')
   and    ro_tipo_rubro  = 'I'

   select @w_tasa = isnull(@w_tasa,0)
   
   --exec sp_reloj 1.2, @w_ms, @w_ms out, @w_max      
   
   -- PERIODICIDAD DE LA OPERACION
   select @w_num_periodicidad = td_factor
   from   ca_tdividendo
   where  td_tdividendo = @w_tplazo
   
   select @w_periodicidad_cuota = @w_plazo * @w_num_periodicidad
   
   -- MODALIDAD DE LA OPERACION
   select @w_modalidad = ro_fpago
   from   ca_rubro_op
   where  ro_operacion  = @w_operacionca
   and    ro_tipo_rubro = 'I'
   and    ro_provisiona = 'S'
   
   --exec sp_reloj 1.3, @w_ms, @w_ms out, @w_max      
   
   if @w_modalidad = 'P'
      select @w_modalidad = 'V'
   else 
      select @w_modalidad = 'A'
   
   --- DIAS DE VENCIMIENTO
   select @w_dias_vencido = 0
   select @w_fecha_ven = min(di_fecha_ven)
   from   ca_dividendo 
   where  di_operacion = @w_operacionca
   and    di_estado    = 2
   if @@rowcount <> 0
   begin
     --exec sp_reloj 1.4, @w_ms, @w_ms out, @w_max      
     if @w_base_calculo = 'R' 
        begin 
           select @w_dias_vencido = datediff(day,min(di_fecha_ven), @w_fecha_ult_proceso )
           from   ca_dividendo 
           where  di_operacion = @w_operacionca
           and    di_estado = 2

           select @w_dias_vencido = isnull(@w_dias_vencido,0) 
        end
        else
          begin
            exec @w_return = sp_dias_base_comercial
            @i_fecha_ini = @w_fecha_ven,
            @i_fecha_ven = @w_fecha_ult_proceso,
            @i_opcion    = 'D',
            @o_dias_int  = @w_dias_vencido out
          end
   end --si hay dividendo vencido

   --exec sp_reloj 1.45, @w_ms, @w_ms out, @w_max      
   
   -- EDAD DE MORA
   select @w_divid_ven_cap = min(di_dividendo)
   from   ca_dividendo
   where  di_operacion  = @w_operacionca
   and    di_estado     = @w_est_vencido
   and    di_de_capital = 'S'

   --exec sp_reloj 1.46, @w_ms, @w_ms out, @w_max      

   select @w_divid_ven_cap = isnull(@w_divid_ven_cap,0)
   
   select @w_fecha_ven_cap = di_fecha_ven
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_dividendo = @w_divid_ven_cap

   --exec sp_reloj 1.5, @w_ms, @w_ms out, @w_max      

   if @w_fecha_ven_cap is not null
   begin
      if @w_base_calculo = 'R'
         select @w_dias_vencido_cap = isnull(datediff(dd,@w_fecha_ven_cap,@w_fecha_ult_proceso), 0)
      else 
      begin
         exec @w_return = sp_dias_base_comercial
         @i_fecha_ini = @w_fecha_ven_cap,
         @i_fecha_ven = @w_fecha_ult_proceso,
         @i_opcion    = 'D',
         @o_dias_int  = @w_dias_vencido_cap out
         if @w_return != 0
         begin
            select @w_error = @w_return
            goto ERROR1
         end  
         
         select @w_dias_vencido_cap = isnull(@w_dias_vencido_cap, 0)
      end
   end
   else
      select @w_dias_vencido_cap = 0

       
   -- NUMERO DE RENOVACIONES
   select @w_numero_renovaciones = isnull(@w_num_reest,0) + isnull(@w_num_renova,0)
   
   -- FECHA PROXIMO VENCIMIENTO
   -- NULO EN CASO QUE LA OPERACION HAYA VENCIDO
   select @w_fecha_prxvto = di_fecha_ven,
          @w_div_vigente  = di_dividendo
   from   ca_dividendo  
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vigente
   
   if @@rowcount <> 0
   begin
      select @w_valor_cuota = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_amortizacion
      where  am_operacion = @w_operacionca
      and    am_dividendo = @w_div_vigente
      
      select @w_valor_cuota = isnull(@w_valor_cuota,0)
      
      if @w_valor_cuota < 0
      begin
         select @w_error = 710288
         goto ERROR1
      end      
   end
   
   --exec sp_reloj 1.6, @w_ms, @w_ms out, @w_max      
   
   -- MAXIMO DIVIDENDO CANCELADO
   select @w_div_cancelado = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_cancelado
   
   select @w_div_cancelado = isnull(@w_div_cancelado, 0)
   
   -- MINIMO DIVIDENDO VENCIDO
   select @w_min_div_vencido = min(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vencido

   select @w_min_div_vencido = isnull(@w_min_div_vencido, 0)
   
   -- MAXIMO DIVIDENDO VENCIDO
   select @w_max_div_vencido = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vencido

   select @w_max_div_vencido = isnull(@w_max_div_vencido, 0)
   
   -- MAXIMO DIVIDENDO VIGENTE
   select @w_max_div_vigente = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vigente

   select @w_max_div_vigente = isnull(@w_max_div_vigente, 0)
   
   --exec sp_reloj 1.7, @w_ms, @w_ms out, @w_max      
   
   if @w_max_div_vigente = 0
      select @w_max_div_vigente = @w_max_div_vencido
   
   -- OPERACION UVR DATOS EN CONTINGENTE
   /*if @w_moneda = @w_moneda_uvr and @w_estado =  @w_est_suspenso
   begin
      exec @w_return = sp_consolidador_uvr
      @i_fecha           = @w_fecha_ult_proceso,
      @i_operacionca     = @w_operacionca,
      @i_div_cancelado   = @w_div_cancelado,
      @o_cap_contingente = @w_cap_contingente  out,
      @o_correc_cap_vig  = @w_correc_cap_vig   out,
      @o_int_contingente = @w_int_contingente  out,
      @o_correc_int_vig  = @w_correc_int_vig   out,
      @o_imo_contingente = @w_imo_contingente  out,
      @o_correc_imo_vig  = @w_correc_imo_vig   out
      
      if @w_return != 0 
      begin
         select @w_error = @w_return
         goto ERROR1
      end
      
      select @w_int_imo_uvr = isnull(sum(@w_int_contingente + @w_imo_contingente),0)
   end
   */
   --exec sp_reloj 1.8, @w_ms, @w_ms out, @w_max      
   
   -- SALDO DE CAPITAL
   select @w_saldo_cap = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_amortizacion                          
   where  am_operacion  = @w_operacionca                                        
   and    am_concepto   = 'CAP'
   and    am_estado    <> @w_est_cancelado

   select @w_saldo_cap = isnull(@w_saldo_cap, 0)
   
   if @w_saldo_cap < 0
   begin
      select @w_error = 710289
      goto ERROR1
   end      

   --exec sp_reloj 1.85, @w_ms, @w_ms out, @w_max     
   
   -- SALDO DE CAPITAL VENCIDO
   select @w_saldo_cap_ven = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_amortizacion
   where  am_operacion  = @w_operacionca
   and    am_estado     = @w_est_vencido
   and    am_dividendo  >= @w_min_div_vencido
   and    am_dividendo  <= @w_max_div_vencido
   and    am_concepto   = 'CAP'

   select @w_saldo_cap_ven = isnull(@w_saldo_cap_ven, 0)
   
   if @w_saldo_cap_ven < 0
   begin
      select @w_error = 710290
      goto ERROR1
   end      
   
   --exec sp_reloj 1.9, @w_ms, @w_ms out, @w_max      
   
   -- SALDO DE INTERES
   if @w_modalidad = 'V'
   begin
      select @w_saldo_int = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion
      where  am_operacion  =  @w_operacionca
      and    am_dividendo  >= @w_min_div_vencido    -- min vencido
      and    am_dividendo  <= @w_max_div_vigente    -- max vigente
      and    am_estado     <> @w_est_suspenso
      and    am_estado     <> @w_est_cancelado
      and    am_concepto   = 'INT'

      select @w_saldo_int = isnull(@w_saldo_int, 0)
      
      if @w_saldo_int <= 0 
         select @w_saldo_int = 0
   end
   else
   begin   --INTERES ANTICIPADO
      select @w_saldo_int = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  ro_operacion  =  @w_operacionca
      and    ro_operacion  =  am_operacion
      and    ro_concepto   =  am_concepto
      and    am_dividendo  >= @w_min_div_vencido       -- min vencido
      and    am_dividendo  <= @w_max_div_vigente + 1   -- max vigente
      and    ro_tipo_rubro =  'I'  --intereses
      and    am_estado     <> @w_est_suspenso
      and    am_estado     <> @w_est_cancelado

      select @w_saldo_int = isnull(@w_saldo_int, 0)
      
      if @w_saldo_int <= 0 
         select @w_saldo_int = 0
   end
   
   -- SALDO DE INTERES EN ESTADO SUSPENSO  IMO e INT
   select @w_saldo_int_sus = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion  = @w_operacionca
   and    ro_operacion  = am_operacion
   and    ro_concepto   = am_concepto
   and    am_estado     = @w_est_suspenso        
   and    ro_tipo_rubro in ('I','M')       

   select @w_saldo_int_sus = isnull(@w_saldo_int_sus, 0)
   
   if @w_saldo_int_sus <= 0 
      select @w_saldo_int_sus = 0
   
   -- SALDO DE INTERES  DOCUMENTOS DESCONTADOS
   if (@w_tipo = 'D'  and  @w_tipo = 'F')
   begin
      select @w_saldo_intdes = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  ro_operacion  =  @w_operacionca
      and    ro_operacion  =  am_operacion
      and    ro_concepto   =  am_concepto
      and    am_estado     <> @w_est_suspenso
      and    am_estado     <> @w_est_cancelado
      and    am_estado     <> @w_est_novigente
      and    am_concepto   =  @w_concepto_intdes    
      and    ro_tipo_rubro =  'I'  --intereses

      select @w_saldo_intdes = isnull(@w_saldo_intdes , 0)
      
      if @w_saldo_intdes <= 0 
         select @w_saldo_intdes = 0
      
      -- SALDO DE INTERES EN ESTADO VENCIDO  DE DOCUMENTOS DESCONTADOS
      select @w_saldo_intdes_ven = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_rubro_op, ca_dividendo, ca_amortizacion
      where  ro_operacion  = @w_operacionca
      and    ro_tipo_rubro = 'I'   -- (I)nteres
      and    di_operacion  = ro_operacion
      and    di_estado     = @w_est_vencido
      and    am_operacion  = di_operacion
      and    am_dividendo  = di_dividendo
      and    am_concepto   = ro_concepto
      and    am_estado     <> @w_est_suspenso
      and    am_estado     <> @w_est_cancelado
      and    am_concepto   =  @w_concepto_intdes   
 
      select @w_saldo_intdes_ven = isnull(@w_saldo_intdes_ven, 0) 
      
      if @w_saldo_intdes_ven < 0 
         select @w_saldo_intdes_ven = 0
   end
   
   -- SALDO DE MORA
   select @w_saldo_mora =  isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_amortizacion
   where  am_operacion  = @w_operacionca
   and    am_concepto   = 'IMO'
   and    am_estado     <> @w_est_suspenso
   and    am_estado     <> @w_est_cancelado

   select @w_saldo_mora = isnull(@w_saldo_mora, 0)
   
   if @w_saldo_mora < 0
      select @w_saldo_mora = 0

   
   -- OPERACION EN ESTADO CASTIGADO
   if @w_estado = @w_est_castigado   ---en la ca_amortizacion esta con estado = 4
   begin
      select @w_saldo_otro =  isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  ro_operacion  =  @w_operacionca
      and    ro_operacion  =  am_operacion
      and    ro_concepto   =  am_concepto
      and    am_dividendo  <= @w_max_div_vigente
      and    am_estado     =  @w_est_castigado
      and    ro_tipo_rubro not in ('C','I','M')

      select @w_saldo_otro = isnull(@w_saldo_otro, 0) 
      
      if @w_saldo_otro < 0 select @w_saldo_otro = 0
         select @w_saldo_otr_ven = 0,
                @w_saldo_otr_ant = 0
   end

   -- A PESAR DE EXISTIR SALDOS POR CONCEPTOS ANTICIPADOS NO SE TOMAN PARA EFECTO DE CONSOLIDADOR   
   if @w_estado <> @w_est_castigado  
   begin
      select @w_saldo_otr_ven = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op  
      where  am_operacion  = @w_operacionca
      and    am_dividendo  <= @w_max_div_vigente 
      and    am_estado     <> @w_est_cancelado
      and    am_estado     <> @w_est_suspenso
      and    am_operacion  =  ro_operacion
      and    am_concepto   =  ro_concepto
      and    ro_tipo_rubro not in ('C','I','M')
   end
   
   if @w_saldo_otr_ven < 0 
      select @w_saldo_otr_ven = 0
   
   select @w_saldo_otro = isnull(@w_saldo_otro ,0)
   
   if @w_saldo_otro < 0 
      select @w_saldo_otro = 0
   

   select @w_otros_total = isnull(@w_saldo_otro,0)  + isnull(@w_saldo_otr_ven,0) + isnull(@w_saldo_seg_vig,0) + isnull(@w_saldo_seg_ven,0)
   


   -- AJUSTE AL DECIMAL - CAMBIO TEMPORAL ELIMINAR
   if @w_otros_total > -1 and @w_otros_total < 1  select @w_otros_total = 0
   
   -- TOTAL VENCIDO
   select @w_saldo_cap_ven = @w_saldo_cap_ven + @w_saldo_intdes_ven
   select @w_saldo_vencido = isnull((@w_saldo_cap_ven + @w_saldo_int_ven + @w_saldo_mora + @w_saldo_otr_ven + @w_saldo_seg_ven),0)
   
   -- SALDO INTERES INT + IMO <> SUSPENSA
   select @w_saldo_int = isnull(@w_saldo_int,0) + isnull(@w_saldo_mora,0)
   
   -- FECHA DE ULTIMA REESTRUCTURACION
   select @w_fecha_ult_reest = null
   select @w_op_reestructuracion = isnull(@w_op_reestructuracion, 'N')
   select @w_num_cuot_pag = 0,
          @w_reestructuracion = 'N'
   
   if @w_op_reestructuracion = 'S'
   begin
      select @w_reestructuracion = 'S'
      
      select @w_op_migrada = op_migrada
      from   ca_operacion 
      where  op_operacion  = @w_operacionca
      
      if @w_op_migrada != 'NOMIGRADA'
         select @w_fecha_ult_reest = '11/30/2001'
      else
         select @w_fecha_ult_reest = @w_fecha_ini
      
      
      select @w_fecha_ult_reest = tr_fecha_ref
      from   ca_transaccion
      where  tr_operacion = @w_operacionca
      and    tr_tran = 'RES'
      and    tr_secuencial = (select  max(tr_secuencial)
                              from ca_transaccion
                              where  tr_operacion = @w_operacionca
                              and    tr_tran = 'RES')
          
      
      select @w_num_cuot_pag = count(1)
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      and    di_estado = @w_est_cancelado
      and    di_fecha_ven > @w_fecha_ult_reest
   end
   
   -- FECHA DE PAGO DE CAPITAL
   if @w_calificacion in ('B', 'C', 'D', 'E') 
   begin
      select @w_secuencial_max = isnull(max(dtr_secuencial),0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion  = @w_operacionca
      and    dtr_operacion = @w_operacionca
      and    tr_operacion  = dtr_operacion
      and    tr_secuencial = dtr_secuencial
      and    tr_tran       = 'PAG'
      and    tr_estado    != 'RV'
      and    tr_fecha_mov  = @s_date    ---valor recaudado por dia. 
    --and    dtr_concepto  = @w_concepto_cap
      
      select @w_fecha_pago_cap = tr_fecha_mov
      from   ca_transaccion
      where  tr_operacion = @w_operacionca
      and    tr_secuencial = @w_secuencial_max
      
      select @w_valor_ult_pago =  isnull(sum(dtr_monto),0)
      from ca_det_trn
      where dtr_operacion  = @w_operacionca
      and   dtr_secuencial = @w_secuencial_max
      and   dtr_concepto   = @w_concepto_cap
      
      if @w_valor_ult_pago < 0 
         select @w_valor_ult_pago = 0
   end
   else
      select @w_fecha_pago_cap = null,
             @w_valor_ult_pago = 0
   
   -- VALOR DE LA CUOTA
   if @w_divid_ven_cap <= 0 begin
      select @w_divid_cap = min(di_dividendo)
      from ca_dividendo
      where di_operacion = @w_operacionca
      and di_dividendo >= @w_div_vigente

      select @w_divid_cap = isnull(@w_divid_cap, 0)
   end else
      select @w_divid_cap = @w_divid_ven_cap
   
   select @w_cuota_cap = isnull(sum(am_cuota+am_gracia-am_pagado),0)
   from   ca_amortizacion
   where  am_operacion = @w_operacionca
   and    am_dividendo = @w_divid_cap
   and    am_concepto  = 'CAP'

   select @w_cuota_cap = isnull(@w_cuota_cap, 0)
   
   if @w_cuota_cap < 0 
       select @w_cuota_cap = 0
   
   -- CUOTAS PAGADAS
   select @w_num_cuot_pagadas = count(1)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_cancelado
   
   select @w_dias_plazo = sum(di_dias_cuota)
   from   ca_dividendo
   where  di_operacion = @w_operacionca

   select @w_dias_plazo = isnull(@w_dias_plazo,0)
   
   -- SALTO TOTAL
   select @w_saldo_cap = @w_saldo_cap + @w_saldo_intdes
   select @w_saldo = isnull(sum(@w_saldo_cap + @w_saldo_int + @w_otros_total + @w_saldo_int_sus),0)
   
   if @w_estado in (@w_est_anulado, @w_est_cancelado)
   begin
      select @w_saldo_int   = 0,
             @w_otros_total = 0,
             @w_saldo_cap   = 0
   end
   

   -- JCQ 01/27/2004 VALORES EN EL RANGO DE -1 a 1 SE CONVIERTEN EN CERO
   if @w_saldo_cap   > -1 and @w_saldo_cap   < 1 select @w_saldo_cap   = 0
   if @w_saldo_int   > -1 and @w_saldo_int   < 1 select @w_saldo_int   = 0
   if @w_otros_total > -1 and @w_otros_total < 1 select @w_otros_total = 0

   
   --BEGIN TRAN --atomicidad por registro La atomicidad se hace en credito
   
   if @i_modo =  'F' --PARA FIN DE MES Y EJECUTADO DESDE FECHA VALOR
   begin
      if @w_fin_mes = 'S'
      begin 
	 exec @w_return = cob_credito..sp_act_datooper
	 @i_fecha             = @w_fecha_ult_proceso,   
	 @i_numero_operacion         = @w_operacionca,
	 @i_numero_operacion_banco   = @w_banco,
	 @i_codigo_producto          = 7,
	 @i_tasa                     = @w_tasa,          
	 @i_periodicidad             = @w_num_periodicidad,       
	 @i_fecha_vencimiento        = @w_fecha_fin,       
	 @i_dias_vto_div             = @w_dias_vencido,            
	 @i_fecha_vto_div            = @w_fecha_ven,       
	 @i_reestructuracion         = @w_reestructuracion,
	 @i_fecha_reest              = @w_fecha_ult_reest,   
	 @i_num_cuota_reest          = @w_num_cuot_pag,
	 @i_no_renovacion            = @w_numero_renovaciones,
	 @i_fecha_prox_vto           = @w_fecha_prxvto,       
	 @i_saldo_prox_vto           = @w_valor_cuota,          
	 @i_saldo_cap                = @w_saldo_cap,          
	 @i_saldo_int                = @w_saldo_int,  --INT + IMO        
	 @i_saldo_otros              = @w_otros_total,          
	 @i_saldo_int_contingente    = @w_saldo_int_sus,
	 @i_estado_contable          = @w_estado_con,        
	 @i_estado_terminos          = 'N',
	 @i_calificacion             = @w_calificacion,
	 @i_periodicidad_cuota       = @w_periodicidad_cuota, 
	 -- REC
	 @i_edad_mora                = @w_dias_vencido_cap,
	 @i_valor_mora               = @w_saldo_cap_ven,   
	 @i_fecha_pago               = @w_fecha_pago_cap,  
	 @i_valor_cuota              = @w_cuota_cap,       
	 @i_cuotas_pag               = @w_num_cuot_pagadas,
	 @i_estado_cartera           = @w_estado,
	 @i_dias_plazo               = @w_dias_plazo,
	 @i_num_cuotaven             = @w_num_div_vencidos,
	 @i_saldo_cuotaven           = @w_saldo_vencido,
	 @i_admisible                = @w_gar_admisible,  
	 @i_num_cuotas               = @w_num_cuotas,
	 @i_tipo_bloqueo             = null,
	 @i_fecha_bloqueo            = null,
	 @i_valor_ult_pago           = @w_valor_ult_pago,
	 -- PARA CREACION DE OBLIGACIONES CON FECHA VALOR
	 @i_tipo_operacion           = @w_toperacion,   
	 @i_codigo_cliente           = @w_op_cliente,
	 @i_oficina                  = @w_oficina,
	 @i_moneda                   = @w_moneda,
	 @i_monto                    = @w_monto,
	 @i_modalidad                = @w_modalidad,
	 @i_fecha_concesion          = @w_fecha_liq,
	 @i_codigo_destino           = @w_destino,
	 @i_clase_cartera            = @w_clase,  
	 @i_codigo_geografico        = @w_ciudad,
	 @i_estado_desembolso        = @w_estado_desembolso,
	 @i_linea_credito            = @w_op_lin_credito,   
	 @i_gerente                  = @w_oficial,
	 @i_tipo_cambio              = @w_op_tipo_cambio,
	 @i_num_reest                = @w_num_reest,
	 @i_probabilidad_default     = @w_probabilidad_default,
	 @i_capsusxcor               = @w_cap_contingente,
	 @i_intsusxcor               = @w_int_imo_uvr

         if @w_return != 0
         begin
            select @w_error = @w_return
            goto ERROR1
         end
         
         exec @w_return = cob_credito..sp_tmp_concepto 
         @t_debug                    = 'N',
         @t_file                     = null,
         @t_from                     = null,
         @i_fecha                    = @s_date,
         @i_codigo_producto          = 7,
         @i_numero_operacion         = @w_operacionca,
         @i_numero_operacion_banco   = @w_banco,
         @i_operacion                = 'D' 
         
         if @w_return != 0
         begin
            select @w_error = @w_return
            goto ERROR1
         end
      end
      
      exec @w_return = sp_act_compensacion
           @i_fecha                 = @w_fecha_ult_proceso,   
           @i_numero_operacion      = @w_operacionca,
           @i_tasa                  = @w_tasa,
           @i_saldo_cap             = @w_saldo_cap,
           @i_saldo_int             = @w_saldo_int,
           @i_saldo_otros           = @w_otros_total,
           @i_saldo_int_contingente = @w_saldo_int_sus,
           @i_saldo                 = @w_saldo, 
           @i_estado_contable       = @w_estado_con,
           @i_periodicidad_cuota    = @w_periodicidad_cuota,
           @i_edad_mora             = @w_dias_vencido_cap,
           @i_valor_mora            = @w_saldo_cap_ven,
           @i_valor_cuota           = @w_cuota_cap,
           @i_cuotas_pag            = @w_num_cuot_pagadas,
           @i_cuotas_ven            = @w_num_div_vencidos,
           @i_num_cuotas            = @w_num_cuotas,
           @i_fecha_pago            = @w_fecha_pago_cap,
           @i_fecha_fin             = @w_fecha_fin,
           @i_estado_cartera        = @w_estado,
           @i_reestructuracion      = @w_reestructuracion,
           @i_fecha_ult_reest       = @w_fecha_ult_reest,
           @i_plazo_dias            = @w_dias_plazo
      
      if @w_return != 0
      begin
         select @w_error = @w_return
         goto ERROR1
      end
   end
   else
   begin
   
      if @w_estado = @w_est_castigado
         select @w_fecha_castigo = @w_fecha_ult_proceso
      else
         select @w_fecha_castigo = null
      
      exec @w_return = cob_credito..sp_tmp_datooper
           @s_date                     = @s_date,
           @i_numero_operacion         = @w_operacionca,            
           @i_numero_operacion_banco   = @w_banco,       
           @i_tipo_operacion           = @w_toperacion,       
           @i_codigo_producto          = @w_producto,        
           @i_codigo_cliente           = @w_op_cliente,            
           @i_oficina                  = @w_oficina,       
           @i_moneda                   = @w_moneda,        
           @i_monto                    = @w_monto,          
           @i_tasa                     = @w_tasa,          
           @i_periodicidad             = @w_num_periodicidad,       
           @i_modalidad                = @w_modalidad,        
           @i_fecha_concesion          = @w_fecha_liq,       
           @i_fecha_vencimiento        = @w_fecha_fin,       
           @i_dias_vto_div             = @w_dias_vencido,            
           @i_fecha_vto_div            = @w_fecha_ven,       
           @i_reestructuracion         = @w_reestructuracion,
           @i_fecha_reest              = @w_fecha_ult_reest,   
           @i_num_cuota_reest          = @w_num_cuot_pag,
           @i_no_renovacion            = @w_numero_renovaciones,
           @i_codigo_destino           = @w_destino,       
           @i_clase_cartera            = @w_clase,
           @i_codigo_geografico        = @w_ciudad,            
           @i_fecha_prox_vto           = @w_fecha_prxvto,       
           @i_saldo_prox_vto           = @w_valor_cuota,          
           @i_saldo_cap                = @w_saldo_cap,          
           @i_saldo_int                = @w_saldo_int,          
           @i_saldo_otros              = @w_otros_total,          
           @i_saldo_int_contingente    = @w_saldo_int_sus,
           @i_estado_contable          = @w_estado_con,        
           @i_estado_desembolso        = 'N',
           @i_estado_terminos          = 'N',
           @i_calificacion             = @w_calificacion,
           @i_saldo_orden              = null,
           @i_saldo_deuda              = null,
           @i_linea_credito            = @w_op_lin_credito,
           @i_periodicidad_cuota       = @w_periodicidad_cuota, 
           @i_edad_mora                = @w_dias_vencido_cap,
           @i_valor_mora               = @w_saldo_vencido,   ----@w_saldo_cap_ven,   
           @i_fecha_pago               = @w_fecha_pago_cap,  
           @i_valor_cuota              = @w_valor_cuota,   ---@w_cuota_cap,       
           @i_cuotas_pag               = @w_num_cuot_pagadas,
           @i_estado_cartera           = @w_estado,
           @i_dias_plazo               = @w_dias_plazo,
           @i_gerente                  = @w_oficial,
           @i_num_cuotaven             = @w_num_div_vencidos,
           @i_saldo_cuotaven           = @w_saldo_vencido,
           @i_admisible                = @w_gar_admisible,  
           @i_num_cuotas               = @w_num_cuotas,
           @i_valor_ult_pago           = @w_valor_ult_pago,
           @i_fecha_castigo            = @w_fecha_castigo,
           @i_tipo_cambio              = @w_op_tipo_cambio,
           @i_num_reest                = @w_num_reest,
           @i_probabilidad_default     = @w_probabilidad_default,
           @i_capsusxcor               = @w_cap_contingente,
           @i_intsusxcor               = @w_int_imo_uvr,
           @i_ccon                     = @w_ccon,
           @i_sit_castigo	       = @w_sit_castigo,
           @i_fecha                    = @s_date
      
      if @w_return != 0
      begin
         select @w_error = @w_return
         --PRINT 'datconso.sp error retornado por sp_tmp_datooper %1! --> ' + cast (@w_return as varchar)
         goto ERROR1
      end
   end
   
   --exec sp_reloj 3, @w_ms, @w_ms out, @w_max   
   
   -- CONDICION PARA FIN DE MES
   if (@w_fin_mes = 'S') or (@i_siempre = 'S')
   begin
      exec @w_return = cob_credito..sp_tmp_concepto 
      @t_debug                    = 'N',
      @t_file                     = null,
      @t_from                     = null,
      @i_fecha                    = @s_date,
      @i_codigo_producto          = 7,
      @i_numero_operacion         = @w_operacionca,
      @i_numero_operacion_banco   = @w_banco,
      @i_operacion                = 'D' 
      
      if @w_return != 0
      begin
         select @w_error = @w_return
         goto ERROR1
      end
      
      delete ca_rubro_calculado_tmp
      where rct_operacion = @w_operacionca
      
      insert ca_rubro_calculado_tmp
      select @w_operacionca, ro_concepto,ro_tipo_rubro,ru_cca,ru_cre,ro_fpago
      from   ca_rubro_op,ca_rubro_cca_cre
      where  ro_operacion = @w_operacionca
      and    ro_concepto  = ru_cca
      
      if @w_return != 0
      begin
         select @w_error = 710292
         goto ERROR1
      end
      
      -- CURSOR...
      declare
      cursor_concepto cursor
      for select distinct rct_rubro_cre
      from ca_rubro_calculado_tmp
      where rct_operacion = @w_operacionca
      
      open  cursor_concepto
      
      fetch cursor_concepto
      into  @w_ru_cre
      
      while @@fetch_status = 0
      begin
         if @@fetch_status = -1
            return  70899
         
         select @w_saldo_concepto         = 0,
                @w_saldo_concepto_int     = 0,
                @w_saldo_concepto_intant  = 0,
                @w_saldo_concepto_imo     = 0,
                @w_saldo_concepto_a       = 0
         
         if @w_ru_cre in ('1') 
         begin 
            select @w_saldo_concepto = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
            from   ca_amortizacion 
            where  am_operacion  = @w_operacionca
            and    am_concepto   = @w_concepto_cap
            and    am_estado     <> @w_est_cancelado
            
            if @w_saldo_concepto < 0
               select @w_saldo_concepto = 0
         end
         
         if @w_ru_cre in ('2')
         begin
            select @w_saldo_concepto_int = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
            from   ca_amortizacion 
            where  am_operacion  = @w_operacionca
            and    am_concepto   = 'INT'
            and    am_dividendo  >= @w_min_div_vencido    
            and    am_dividendo  <= @w_max_div_vigente    
            and    am_estado     <> @w_est_suspenso
            and    am_estado     <> @w_est_cancelado
            
            if @w_saldo_concepto_int < 0
               select @w_saldo_concepto_int = 0
            
            if @w_modalidad = 'A'
            begin
               select @w_saldo_concepto_intant = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
               from   ca_amortizacion 
               where  am_operacion  = @w_operacionca
               and    am_concepto   = 'INTANT'
               and    am_dividendo  >= @w_min_div_vencido     
               and    am_dividendo  <= @w_max_div_vigente + 1 
               and    am_estado     <> @w_est_suspenso
               and    am_estado     <> @w_est_cancelado
               
               if @w_saldo_concepto_intant < 0
                  select @w_saldo_concepto_intant = 0
            end
            
            select @w_saldo_concepto_imo =  isnull(sum(am_acumulado + am_gracia - am_pagado),0)
            from   ca_rubro_op, ca_amortizacion
            where  ro_operacion  = @w_operacionca
            and    ro_tipo_rubro = 'M'   -- (M)ora
            and    am_operacion  = ro_operacion
            and    am_concepto   = ro_concepto
            and    am_estado     <> @w_est_suspenso
            and    am_estado     <> @w_est_cancelado
            
            if @w_saldo_concepto_imo < 0
               select @w_saldo_concepto_imo = 0
            
            select @w_saldo_concepto = isnull(@w_saldo_concepto_int,0) + isnull(@w_saldo_concepto_intant,0) + isnull(@w_saldo_concepto_imo,0) 
            
            select @total_int = sum(@w_saldo_concepto_int + @w_saldo_concepto_imo)
            select @total_int_ant = sum(@w_saldo_concepto_intant + @w_saldo_concepto_imo)
         end 
         
         if @w_ru_cre not in ('1','2')
         begin


            select @w_saldo_concepto = 0 

            -- A PESAR DE EXISTIR SALDOS POR CONCEPTOS ANTICIPADOS NO SE TOMAN PARA EFECTO DE CONSOLIDADOR            
            select @w_saldo_concepto = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
            from   ca_amortizacion 
            where  am_operacion  = @w_operacionca
            and    am_concepto   in (select rct_rubro_cca from ca_rubro_calculado_tmp
                                     where  rct_operacion = @w_operacionca
                                     and    rct_rubro_cre = @w_ru_cre)
            and    am_dividendo  <= @w_max_div_vigente 
            and    am_estado     <> @w_est_cancelado
            and    am_estado     <> @w_est_suspenso
            
            if @w_saldo_concepto < 0
               select @w_saldo_concepto = 0
            
            select @w_saldo_concepto_a = 0
            
            select @w_saldo_concepto = @w_saldo_concepto + @w_saldo_concepto_a
         end
         
         if @w_saldo_concepto > -1 and @w_saldo_concepto < 1 select @w_saldo_concepto = 0
         
         if @w_estado in (@w_est_anulado,@w_est_cancelado)   ---por perdio de CREDIDO,pablo gaibor
         begin
            select @w_saldo_concepto = 0
         end
         
         exec @w_return = cob_credito..sp_tmp_concepto 
         @t_debug                    = 'N',
         @t_file                     = null,
         @t_from                     = null,
         @i_fecha                    = @s_date,
         @i_codigo_producto          = 7,
         @i_numero_operacion         = @w_operacionca,
         @i_numero_operacion_banco   = @w_banco,
         @i_concepto                 = @w_ru_cre,
         @i_saldo                    = @w_saldo_concepto,
         @i_operacion                = 'I' 
         
         if @w_return != 0
         begin                                     
            PRINT 'datconso.sp error retornado por sp_tm_concepto ' + cast (@w_return as varchar)
            select @w_error = @w_return
            close cursor_concepto
            deallocate cursor_concepto
            goto ERROR1
         end
         
         fetch cursor_concepto
         into  @w_ru_cre
      end -- cursor_concepto
      
      close cursor_concepto
      deallocate cursor_concepto
   end

   --exec sp_reloj 9, @w_ms, @w_ms out, @w_max

   select @w_commit = 'N'

   --exec sp_reloj 10, @w_ms, @w_ms out, @w_max
   
   if @w_estado in (@w_est_cancelado, @w_est_castigado,@w_est_anulado)
   begin
      update ca_operacion
      set op_validacion    = 'C'
      where op_operacion   = @w_operacionca
      and   op_validacion <> 'C'
   end

   --exec sp_reloj 11, @w_ms, @w_ms out, @w_max
   
   goto SIGUIENTE
   
   ERROR1:  
  
   if @i_en_linea = 'S'
      return @w_error
   ELSE
   begin
      exec sp_errorlog                                             
      @i_fecha       = @s_date,
      @i_error       = @w_error,
      @i_usuario     = @s_user,
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name,
      @i_rollback    = 'S',  
      @i_cuenta      = @w_banco,
      @i_descripcion = ''
      
      if @w_commit = 'S'
         commit tran
      
      goto SIGUIENTE
   end
   
   SIGUIENTE:
   fetch cursor_operacion_nuevo
   into  @w_operacionca,         @w_banco,          @w_toperacion,          
         @w_moneda,              @w_oficina,        @w_fecha_ult_proceso,   
         @w_dias_anio,           @w_estado,         @w_sector,              
         @w_op_cliente,          @w_fecha_liq,      @w_fecha_ini,           
         @w_dias_clausula,       @w_monto,          @w_fecha_fin,
         @w_periodicidad,        @w_num_reest,      @w_num_renova,
         @w_destino,             @w_clase,          @w_ciudad,
         @w_tramite,             @w_calificacion,   @w_renovacion ,
         @w_gar_admisible,       @w_tipo,           @w_edad,
         @w_base_calculo,        @w_periodo_cap,    @w_oficial,
         @w_plazo,               @w_tplazo,         @w_gar_admisible,
         @w_op_reestructuracion, @w_op_lin_credito, @w_op_num_renovacion,
         @w_op_tipo_cambio
end -- cursor_operacion_nuevo

close cursor_operacion_nuevo                                           
deallocate cursor_operacion_nuevo                               

if @i_proceso is not null
begin
  begin tran
    update ca_procesos_consolidador_tmp
    set    estado = 'T'
    where  proceso = @i_proceso
  commit tran
end

return 0

go

