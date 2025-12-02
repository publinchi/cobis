/************************************************************************/
/*      Archivo:                calfag.sp                               */
/*      Stored procedure:       sp_calculo_fag                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Johan Ardila                            */
/*      Fecha de escritura:     Dic 2010                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Calculo de comision FAG de manera periodica                     */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*  15/Dic/2010      Johan Ardila       Emision Inicial                 */
/*  29/Jul/2015      Andres Muñoz       Cal. Comisión FAG CCA 509 - 500 */
/*  01/Jun/2022      Guisela Fernandez  Se comenta prints               */
/************************************************************************/
use cob_cartera
go

if object_id ('sp_calculo_fag') is not null
begin
   drop proc sp_calculo_fag
end
go
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO
---NR000353

create proc sp_calculo_fag
@i_operacion            int,
@i_desde_abnextra       char(1)      = 'N',
@i_cuota_abnextra       smallint     = null,
@i_crea_ext             char(1)      = null,
@i_parametro_fag        varchar(10)  = null,
@i_parametro_fagd       varchar(10)  = null,
@i_parametro_fag_iva    varchar(10)  = null,
@o_msg_msv              varchar(255) = null out

as
declare
@w_sp_name              varchar(30),
@w_return               int,
@w_est_vigente          tinyint,
@w_est_vencido          tinyint,
@w_est_cancelado        tinyint,
@w_est_novigente        tinyint,
@w_num_dec              smallint,
@w_moneda               smallint,
@w_op_monto             money,
@w_di_dividendo         int,
@w_di_fecha_ini         datetime,
@w_di_fecha_ven         datetime,
@w_di_estado            int,
@w_valor                money,
@w_valor_no_vig         money,
@w_factor               float,
@w_factor_op            float,
@w_asociado             catalogo,
@w_porcentaje           float,
@w_valor_asociado       money,
@w_plazo_restante       int,
@w_fecha_ini            datetime,
@w_fecha_fin            datetime,
@w_mes_anualidad        int,
@w_tramite              int,
@w_periodo_fag          tinyint,
@w_cod_gar_fag          catalogo,
@w_par_fag              catalogo,
@w_par_iva_fag          catalogo,
@w_dividendo_vig        int,
@w_estado_op            int,
@w_cuota                money,
@w_cuota_iva            money,
@w_dividendo            int,
@w_min_dividendo        int,
@w_max_dividendo        int,
@w_control_divid        int,
@w_SMV                  money,
@w_oficina              smallint,
@w_monto_parametro      float,
@w_fecha_ult_proceso    datetime,
@w_error                int,
@w_msg                  descripcion,
@w_par_fag_des          catalogo,
@w_tdividendo           catalogo,
@w_freq_cobro           int,
@w_periodos             int,
@w_est_credito          tinyint,
@w_garantia             varchar(64),
@w_previa               varchar(20),
@w_porcentaje_resp      float,
@w_fecha_col            datetime,
@w_sec                  int,
@w_plazo                int,
@w_tplazo               varchar(10),
@w_seguros              char(1),
@w_mes_oper             int,
@w_fecha_fin_real       datetime,
@w_fecha_fin_habil      datetime,
@w_ciudad_nacional      int,
@w_siguiente_dia        datetime,
@w_es_habil             char(1),
@w_dia_semana           int,
@w_dias_restados        int,
@w_dias_calculo         float,
@w_fecha_liq            datetime,
@w_dia_pago             int,
@w_fecha_aux            datetime,
@w_fecha_aux1           datetime,
@w_fecha_aux2           datetime,
@w_fecha_aux3           datetime,
@w_aux                  int

--- INICIALIZACION VARIABLES 
select 
@w_sp_name           = 'sp_calculo_fag',   
@w_valor             = 0,
@w_porcentaje        = 0,
@w_valor_asociado    = 0,
@w_asociado          = '',
@w_plazo_restante    = 0,
@w_mes_anualidad     = 1,
@w_dividendo_vig     = 0,
@w_estado_op         = 0,
@w_control_divid     = 0,
@i_cuota_abnextra    = isnull(@i_cuota_abnextra,0),
@w_seguros           = 'N',
@w_dias_restados     = 0,
@w_dias_calculo      = 0
 
--- ESTADOS DE CARTERA 

exec @w_error     = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_credito    = @w_est_credito   out

if @w_est_vigente is null begin
   --GFP se suprime print
   /*
   if @i_crea_ext is null
      PRINT 'Error en la busqueds de estados  en sp_estados_cca'
   else
   */
      select @o_msg_msv = 'Error en la busqueds de estados  en sp_estados_cca'
   return  710217
end

--- PARAMETRO PERIODICIDAD COBRO FAG 
select @w_periodo_fag = pa_tinyint
from   cobis..cl_parametro 
where  pa_nemonico    = 'PERFAG'
and    pa_producto    = 'CCA'
 
--- CODIGO PADRE GARANTIA DE FAG 
select @w_cod_gar_fag = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto    = 'GAR'
and    pa_nemonico    = 'CODFAG'
set transaction isolation level read uncommitted

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico        = 'CIUN'
and    pa_producto        = 'ADM'

if @i_parametro_fag is null and @i_parametro_fagd is null and @i_parametro_fag_iva is null
begin
   --- PARAMETRO DE LA GARANTIA DE FAG DESEMBOLSO
   select @w_par_fag_des = pa_char
   from   cobis..cl_parametro 
   where  pa_nemonico    = 'CMFAGD'
   and    pa_producto    = 'CCA'

   --- PARAMETRO DE LA GARANTIA DE FAG PERIODICA 
   select @w_par_fag  = pa_char
   from   cobis..cl_parametro with (nolock)
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'CMFAGP'

   --- IVA DE LA COMISION DE FAG PERIODICA 
   select @w_par_iva_fag = pa_char
   from   cobis..cl_parametro with (nolock)
   where  pa_producto    = 'CCA'
   and    pa_nemonico    = 'ICMFAG'
end
else
begin
   select 
   @w_par_fag_des   = @i_parametro_fag,
   @w_par_fag       = @i_parametro_fagd,
   @w_par_iva_fag   = @i_parametro_fag_iva
end

--- PARAMETRO SALARIO MINIMO VITAL VIGENTE 
select @w_SMV      = pa_money 
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'SMV'

--- DATOS OPERACION 
select 
@w_fecha_ini         = opt_fecha_ini,
@w_fecha_fin         = opt_fecha_fin,
@w_op_monto          = opt_monto,
@w_moneda            = opt_moneda,
@w_tramite           = opt_tramite,
@w_estado_op         = opt_estado,
@w_oficina           = opt_oficina,
@w_fecha_ult_proceso = opt_fecha_ult_proceso,
@w_tdividendo        = opt_tdividendo,
@w_tplazo            = opt_tplazo,
@w_plazo             = opt_plazo,
@w_fecha_liq         = opt_fecha_liq,
@w_dia_pago          = opt_dia_fijo
from  ca_operacion_tmp
where opt_operacion = @i_operacion

if exists (select 1 from cob_credito..cr_seguros_tramite
           where st_tramite = @w_tramite)
           and @w_estado_op in (@w_est_novigente, @w_est_credito)
begin
   select @w_seguros  = 'S'
   select @w_op_monto = tr_monto   -- Otra forma de obtener el monto sin seguros es tomar el @i_monto y restarle el valor total 
   from   cob_credito..cr_tramite with (nolock) -- de los seguros, valor que se obtiene con el select que se realiza en la operacion C
   where  tr_tramite  = @w_tramite              -- del SP cob_credito..sp_seguros_tramite.               	  
end  -- Fin Generar monto base de la operación Req. 366
 
--- FRECUENCIA DE COBRO DEPENDIENDO DEL TIPO DE DIVIDENDO 
select @w_periodos   = td_factor / 30
from   ca_tdividendo
where  td_tdividendo = @w_tdividendo
 
select @w_freq_cobro = td_factor / 30
from   ca_tdividendo
where  td_tdividendo = @w_tdividendo

select @w_freq_cobro = @w_periodo_fag / @w_freq_cobro

--- DIVIDENDO VIGENTE 
if @w_estado_op not in (@w_est_novigente, @w_est_vencido)
begin 
   select @w_dividendo_vig = di_dividendo
   from   ca_dividendo
   where  di_operacion     = @i_operacion
   and    di_estado        = @w_est_vigente
end

--- GARANTIA TIPO FAG 
select tc_tipo as tipo 
into   #calfag
from   cob_custodia..cu_tipo_custodia
where  tc_tipo_superior = @w_cod_gar_fag

--- REQ 0212 Banca Rural
if not exists(
	select 1
	from cob_cartera..ca_rubro_op_tmp
	where rot_operacion = @i_operacion
	and   rot_concepto  = @w_par_fag)
if not exists(
	select 1
	from cob_cartera..ca_rubro_op_tmp
	where rot_operacion = @i_operacion
	and   rot_concepto  = @w_par_fag_des)
begin
	delete cob_cartera..ca_amortizacion
	where am_operacion = @i_operacion
	and   am_concepto  = @w_par_fag
end
else
begin
   --GFP se suprime print
   /*
   if @i_crea_ext is null
	   PRINT 'Se ha eliminado el Concepto FAG en desembolso o Periodicidad'
   else
   */
      select @o_msg_msv = 'Se ha eliminado el Concepto FAG en desembolso o Periodicidad'
   
   return 722206
end

if not exists (select 1 
               from   cob_custodia..cu_custodia, 
                      cob_credito..cr_gar_propuesta, 
                      cob_credito..cr_tramite
               where  gp_tramite  = @w_tramite
               and    gp_garantia = cu_codigo_externo
               and    cu_estado   in ('P','F','V','X','C')
               and    tr_tramite  = gp_tramite
               and    cu_tipo     in (select tipo from #calfag))
begin

   update ca_amortizacion_tmp with (rowlock) set 
   amt_cuota     = case when amt_pagado > 0 then amt_pagado else 0 end,
   amt_acumulado = case when amt_pagado > 0 then amt_pagado else 0 end,
   amt_gracia    = 0                                     -- PAQUETE 2 - REQ 212 BANCA RURAL - GAL 28/JUL/2011
   where amt_operacion = @i_operacion
   and   amt_concepto  in (@w_par_fag, @w_par_iva_fag)
   
   if @@error <> 0
   begin
      return 724401
   end
   else
   begin
      return 0
   end
end

--- OBTENER LA FECHA DE VENCIMIENTO FINAL DESDE ca_dividendo_tmp, POR QUE EN ca_operacion_tmp AUN NO SE TIENE 
select @w_fecha_fin  = max(dit_fecha_ven)
from   ca_dividendo_tmp
where  dit_operacion = @i_operacion

--GARANTIA DEL CREDITO Y TIPO DE GARANTIA (PREVIA-AUTOMATICA)
select
@w_garantia        = cu_codigo_externo, 
@w_previa          = case gp_previa when 'P' then 'PREVIA' else 'AUTOMATICA'  end,
@w_porcentaje_resp = gp_porcentaje
from  cob_custodia..cu_custodia,
      cob_credito..cr_gar_propuesta,
      cob_credito..cr_tramite
where gp_tramite   = @w_tramite
and   gp_garantia  = cu_codigo_externo 
and   cu_estado    in ('P','F','V','X','C')
and   tr_tramite   = gp_tramite
and   cu_tipo      in (select tipo from #calfag) 
      
--- NUMERO DE DECIMALES 
exec @w_return  = sp_decimales
   @i_moneda    = @w_moneda,
   @o_decimales = @w_num_dec out

if @w_return <> 0
begin
   return  @w_return
end

--- CALCULO DEL MONTO EN SMVV 
select @w_monto_parametro = @w_op_monto/@w_SMV

if @w_estado_op in ( @w_est_novigente , @w_est_credito) or @i_cuota_abnextra > 0
begin -- Si la operacion es nueva o proviene de un reajuste consulta la Matriz

   exec @w_error  = sp_matriz_garantias
   @s_date            = @w_fecha_ult_proceso,
   @i_tramite         = @w_tramite,
   --@i_garantia        = @w_garantia, --REQ 477
   @i_tipo_garantia   = @w_previa, 
   @i_porcentaje_resp = @w_porcentaje_resp,      
   @i_plazo           = @w_plazo,
   @i_tplazo          = @w_tplazo,
   @i_crea_ext        = @i_crea_ext,
   @o_valor           = @w_factor  out,
   @o_msg             = @o_msg_msv out
   
   if @w_error <> 0 begin
      return @w_error
   end
   
   if @w_factor = 0 begin
      return 722208
   end
   
   update ca_rubro_op set   
   ro_porcentaje     = @w_factor,
   ro_porcentaje_aux = @w_factor
   where ro_operacion = @i_operacion
   and ro_concepto  = @w_par_fag
   
   if @@error <> 0
   begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         PRINT 'calfag.sp Error Actaulizando ca_rubro_op @w_par_fag'
      else
	  */
         select @o_msg_msv = 'calfag.sp Error Actaulizando ca_rubro_op @w_par_fag'
      return 720002
   end
   
   update ca_rubro_op_tmp set
   rot_porcentaje      = @w_factor,
   rot_porcentaje_aux  = @w_factor
   where rot_operacion = @i_operacion
   and rot_concepto  = @w_par_fag
   
   if @@error <> 0
   begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         PRINT 'calfag.sp Error Actaulizando ca_rubro_op_tmp @w_par_fag'
      else
	  */
         select @o_msg_msv = 'calfag.sp Error Actaulizando ca_rubro_op_tmp @w_par_fag'
      return 720002      
   end      
   
   update ca_rubro_op set
   ro_porcentaje      = @w_factor,
   ro_porcentaje_aux  = @w_factor 
   where ro_operacion = @i_operacion
   and ro_concepto  = @w_par_fag_des
   
   if @@error <> 0
   begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         PRINT 'calfag.sp Error Actualizando ca_rubro_op @w_par_fag_des'
      else 
	  */
         select @o_msg_msv = 'calfag.sp Error Actualizando ca_rubro_op @w_par_fag_des'
      return 720002
   end
            
   update ca_rubro_op_tmp set
   rot_porcentaje      = @w_factor,
   rot_porcentaje_aux  = @w_factor
   where rot_operacion = @i_operacion
   and rot_concepto    = @w_par_fag_des
   
   if @@error <> 0
   begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         PRINT 'calfag.sp Error Actaulizando ca_rubro_op_tmp @w_par_fag_des'
      else
	  */
         select @o_msg_msv = 'calfag.sp Error Actaulizando ca_rubro_op_tmp @w_par_fag_des'
      return 720002
   end
   
   -- Control de tabla para fecha valor    
   if exists (select 1 
              from ca_rubro_col_op 
              where ruc_operacion  = @i_operacion
              and   ruc_concepto   = @w_par_fag
              and   ruc_fec_pro_op = @w_fecha_ult_proceso
              and   ruc_porcentaje = @w_factor)
   begin           
      delete ca_rubro_col_op
      where ruc_operacion  = @i_operacion
      and   ruc_concepto   = @w_par_fag
      and   ruc_fec_pro_op = @w_fecha_ult_proceso
      and   ruc_porcentaje = @w_factor        
   end
   
   exec @w_sec = sp_gen_sec
   @i_operacion  = -1

   insert into ca_rubro_col_op 
   values (@i_operacion, @w_sec, @w_par_fag, @w_fecha_ult_proceso, @w_factor)
   if @@error <> 0
   begin
      --GFP se suprime print
      /*	  
      if @i_crea_ext is null
         PRINT 'calfag.sp Error Insertando Rubro FAG para Control Fecha Valor'
      else
	  */
         select @o_msg_msv = 'calfag.sp Error Insertando Rubro FAG para Control Fecha Valor'
      
      return 720002
   end	
end 	
else
begin
   select @w_fecha_col    = max(ruc_fec_pro_op)
   from   ca_rubro_col_op
   where  ruc_operacion   = @i_operacion
   and    ruc_concepto    = @w_par_fag
   and    ruc_fec_pro_op  <= @w_fecha_ult_proceso
   
   select @w_sec          = max(ruc_secuencial)
   from   ca_rubro_col_op
   where  ruc_operacion   = @i_operacion
   and    ruc_concepto    = @w_par_fag
   and    ruc_fec_pro_op  = @w_fecha_col

   select @w_factor       = ruc_porcentaje
   from   ca_rubro_col_op
   where  ruc_operacion   = @i_operacion
   and    ruc_concepto    = @w_par_fag
   and    ruc_fec_pro_op  = @w_fecha_col
   and    ruc_secuencial  = @w_sec

   if @@rowcount = 0
   begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         PRINT 'calfag.sp Error Actualizando ca_rubro_op_tmp @w_par_fag oper Desembolsada'
      else
	  */
         select @o_msg_msv = 'calfag.sp Error Actualizando ca_rubro_op_tmp @w_par_fag oper Desembolsada'
      
      return 720002
   end
   
end	

--- VALOR DE COMFAGANU 
select @w_valor = round((@w_op_monto * @w_factor / 100.0), @w_num_dec)

---VERIFICAR SI EL RUBRO COMFAGANU TIENE RUBRO ASOCIADO 
if exists (select 1 from ca_rubro_op_tmp
           where rot_operacion         = @i_operacion
           and   rot_concepto_asociado = @w_par_fag)
begin
   select
   @w_asociado   = rot_concepto,
   @w_porcentaje = rot_porcentaje
   from  ca_rubro_op_tmp
   where rot_operacion         = @i_operacion
   and   rot_concepto_asociado = @w_par_fag
end

--- VERIFICA SI VIENE DE ABONO EXTRAORDINARIO
if @i_cuota_abnextra > 0
begin 
   select @w_mes_anualidad = (@w_freq_cobro -(@i_cuota_abnextra % @w_freq_cobro)) + 1
end
   
--- UBICACION DEL FAG 
select @w_min_dividendo = min(amt_dividendo)
from   ca_amortizacion_tmp
where  amt_operacion    = @i_operacion
and    amt_concepto     in (@w_par_fag, @w_par_iva_fag) 
and    amt_cuota        > 0 

select @w_control_divid = count(1)
from   ca_dividendo
where  di_operacion     = @i_operacion
and    di_estado        in (@w_est_vencido, @w_est_cancelado)

select @w_max_dividendo = max(amt_dividendo)
from   ca_amortizacion_tmp
where  amt_operacion    = @i_operacion
and    amt_concepto     in (@w_par_fag, @w_par_iva_fag) 
and    amt_dividendo    <= @w_dividendo_vig 
and    amt_cuota        > 0 

if @w_min_dividendo = @w_freq_cobro + 1
begin
   select
   @w_mes_anualidad = @w_freq_cobro + 1,
   @w_control_divid = @w_control_divid + 1
end   
else
   select @w_mes_anualidad = @w_freq_cobro

if @w_max_dividendo < @w_control_divid
begin
   select @w_mes_anualidad = @w_max_dividendo + @w_freq_cobro
end
   
--- CURSOR DE DIVIDENDOS
declare cursor_dividendos_1 cursor for
select  dit_dividendo,  dit_fecha_ini,   dit_fecha_ven,
        dit_estado
from    ca_dividendo_tmp
where   dit_operacion = @i_operacion
for read only

open    cursor_dividendos_1
fetch   cursor_dividendos_1
into    @w_di_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, 
        @w_di_estado

--- WHILE CURSOR PRINCIPAL 
while @@fetch_status = 0 
begin
   if (@@fetch_status = -1) return 708999

   select @w_valor = 0
   
   --- DETERMINAR CAMBIO DE PERIODO 
   if @w_di_dividendo + @w_control_divid = @w_mes_anualidad 
   begin
      --OBTIENE NUMERO DE DIVIDENDOS
      select @w_plazo      = COUNT(1)
      from   ca_dividendo_tmp
      where  dit_operacion = @i_operacion
      
      --SI ES UN ABONO EXTRAORDINARIO Y PAGO DE PERIODICIDAD COMPLETA
      if (@i_desde_abnextra = 'S') and (@w_di_dividendo = @w_mes_anualidad)
      begin
         --SE LE RESTA UN DIVIDENDO PARA APLICAR EL COBRO COMISION EN EL MES DE LA ANUALIDAD
         select @w_di_dividendo = @w_di_dividendo - 1
         
         --OBTIENE LA FECHA DE VENCIMIENTO DEL ANTERIR DIVIDENDO
         select 
         @w_di_fecha_ven = dit_fecha_ven
         from    ca_dividendo_tmp
         where   dit_operacion = @i_operacion
         and     dit_dividendo = @w_di_dividendo
         
         select @w_mes_oper = @w_plazo + @w_control_divid + 1
      end
      else
         select @w_mes_oper = @w_plazo + @w_control_divid
      
      --OBTIENE EL MONTO BASE PARA EL CALCULO DE COMISION
      select @w_op_monto    = sum(amt_cuota - amt_pagado)
      from   ca_amortizacion_tmp,
             ca_rubro_op_tmp
      where  amt_operacion  = @i_operacion
      and    rot_operacion  = amt_operacion
      and    amt_dividendo  >= @w_di_dividendo + 1
      and    rot_concepto   = amt_concepto 
      and    rot_tipo_rubro = 'C'

      select @w_fecha_fin = null
      
      select @w_fecha_fin = dit_fecha_ven
      from    ca_dividendo_tmp
      where   dit_operacion = @i_operacion
      and     dit_dividendo = @w_mes_anualidad + @w_freq_cobro

      if @w_fecha_fin is null
      begin
         --- OBTENER LA FECHA DE VENCIMIENTO FINAL DESDE ca_dividendo_tmp, POR QUE EN ca_operacion_tmp AUN NO SE TIENE 
         select @w_fecha_fin  = max(dit_fecha_ven)
         from   ca_dividendo_tmp
         where  dit_operacion = @i_operacion

         select  @w_di_fecha_ven = dit_fecha_ven
         from    ca_dividendo_tmp
         where   dit_operacion = @i_operacion
         and     dit_dividendo = @w_di_dividendo
      end

      --OBTIENE EL PLAZO EN MESES RESTANTES A COBRAR PARA LA ANUALIDAD
      select @w_plazo_restante = datediff(mm,@w_di_fecha_ven,@w_fecha_fin)

       --CALCULA MONTO DE COBERTURA DE LA GARANTIA
      select @w_op_monto =  isnull((@w_op_monto * @w_porcentaje_resp)/100,0)
      
      --OBTIENE EL FACTOR DE CALCULO DE LA OPERACION
      select @w_factor_op = td_factor
      from   cob_cartera..ca_operacion,
             cob_cartera..ca_tdividendo
      where  op_tplazo    = td_tdividendo
      and    op_operacion = @i_operacion
      
      --OBTIENE LOS DIAS DE CALCULO DE LA OPERACION   
      select @w_dias_calculo = @w_mes_oper * @w_factor_op
      
      --CALCULA LOS MESES DE LA OPERACION   
      select @w_mes_oper = @w_dias_calculo/30
      
      --SELECCIONE FECHA INICIO CREDITO
      select @w_fecha_liq = @w_fecha_ini
      
      --CALCULA EL MES DE LA SIGUENTE ANUALIDAD A COBRAR
      select @w_mes_anualidad = @w_mes_anualidad + @w_freq_cobro

      select @w_fecha_fin_habil = dateadd(mm, @w_mes_oper, @w_fecha_liq)

      if @i_desde_abnextra = 'S' 
      begin
         select  @w_fecha_liq = @w_fecha_liq

         select  @w_fecha_aux = di_fecha_ven
         from    cob_cartera..ca_dividendo--_tmp
         WHERE   di_operacion = @i_operacion
         and     di_dividendo = 1

         /*** OBTIENE DIFERENCIA DE DIAS ENTRE EL DESEMBOLSO Y LA PRIMERA CUOTA ***/
         select @w_aux = DATEDIFF(dd, @w_fecha_liq, @w_fecha_aux)

         /*** OBTIENE EL ULTIMO DIA DEL MES INMEDIATAMENTE ANTERIOR A LA PRIMERA CUOTA ***/
         select @w_fecha_aux1 = dateadd(dd, -1, convert(varchar, datepart(mm, @w_fecha_aux)) + '/01/' + convert(varchar, datepart(yyyy, @w_fecha_aux)))

         /*** OBTIENE EL ULTIMO DIA DEL MES DE LA FECHA DESEMBOLSO ***/
         select @w_fecha_aux2 = dateadd(dd, -1, convert(varchar, datepart(mm, @w_fecha_aux1)) + '/01/' + convert(varchar, datepart(yyyy, @w_fecha_aux1)))

         /*** VALIDA SI EL MES ANTERIOR AL DE LA PRIMERA CUOTA ES DE 31 DIAS ***/
         if datepart(dd, @w_fecha_aux1) > 30
         begin
             /*** SI EL MES ANTERIOR ES DE 31 DIAS LE RESTA 1 A LA DIFERENCIA ***/
             select @w_aux = @w_aux - 1
             /*** VALIDA SI EL MES DE LA FECHA DESEMBOLSO ES DE 31 DIAS ***/
             if datepart(dd, @w_fecha_aux2) > 30
                /*** SI EL MES DE LA FECHA DESEMBOLSO ES DE 31 DIAS LE RESTA 1 A LA DIFERENCIA ***/
                select @w_aux = @w_aux - 1
         end
         
         select  @w_dias_calculo   = ((@w_mes_oper-1) * 30) + @w_aux
      end
      else
      begin
         select @w_dias_calculo = sum(dit_dias_cuota)
         from   cob_cartera..ca_dividendo_tmp
         where  dit_operacion = @i_operacion
      end

      select 
      @w_es_habil      = 'N', 
      @w_dias_restados = 0
      
      --DETERMINA EL NUMERO DE DIAS FERIADOS AL FINALIZAR EL CREDITO
      while @w_es_habil = 'N'
      begin
         --RESTA LOS DIAS FESTIVOS SI LA FECHA FIN DEL CREDITO ES UN DIA FESTIVO
         while exists(select 1 from cobis..cl_dias_feriados
                      where df_ciudad = @w_ciudad_nacional
                      and   df_fecha  = @w_fecha_fin_habil)
         begin
            select @w_fecha_fin_habil = dateadd(day, 1, @w_fecha_fin_habil)
            select @w_dias_restados   = @w_dias_restados - 1
         end
          
         --OPTIENE EL DIA DE LA SEMANA PARA EL ULTIMO DIA DE PAGO
         select @w_dia_semana = datepart(dw,@w_fecha_fin_habil) 
        
         if @w_dia_semana = 1
            select @w_dia_semana = 7
         else
            select @w_dia_semana = @w_dia_semana - 1

         --RESTA LOS DIAS FESTIVOS SI LA FECHA FIN DEL CREDITO ES UN DIA FESTIVO FINAGRO (SABADO)
         if exists(select 1 from cobis..cl_tabla t,cobis..cl_catalogo c
                   where t.tabla = 'ca_dias_feriados_fag'
                   and   c.tabla = t.codigo
                   and   c.codigo = @w_dia_semana
                   and   c.estado = 'V')
         begin
            select @w_fecha_fin_habil = dateadd(dd, 1, @w_fecha_fin_habil)
            select @w_dias_restados   = @w_dias_restados - 1
         end
         else
         begin
            --RESTA LOS DIAS FESTIVOS SI LA FECHA FIN DEL CREDITO ES UN DIA FESTIVO
            while exists(select 1 from cobis..cl_dias_feriados
                         where df_ciudad = @w_ciudad_nacional
                         and   df_fecha  = @w_fecha_fin_habil)
            begin
               select @w_fecha_fin_habil = dateadd(day, 1, @w_fecha_fin_habil)
               select @w_dias_restados   = @w_dias_restados - 1
            end
         
            select @w_es_habil = 'S'
         end
      end
      
      --DETERMINA EL NUMERO DE DIAS REALES DE CALCULO RESTANDO FERIADOS
      select @w_dias_calculo = @w_dias_calculo + @w_dias_restados
      
      ----DETERMINA EL NUMERO DE MESES REALES DE CALCULO
      select @w_dias_calculo = (@w_dias_calculo / 30)

      -- OBTENIENDO FECHA DEL MAXIMO DIVIDENDO
      select  @w_fecha_aux3 = max(dit_fecha_ven)
      from    cob_cartera..ca_dividendo_tmp
      WHERE   dit_operacion = @i_operacion

      --VALIDA Y AUMENTA MES POR DESFASE
      if @w_dias_calculo > @w_mes_oper
      begin
         if @w_fecha_aux3 = @w_fecha_fin
            select @w_plazo_restante = @w_plazo_restante + 1
      end
      
      select @w_valor = round(((@w_op_monto * @w_factor / 100.0)/@w_periodo_fag) * @w_plazo_restante, @w_num_dec)
   end

   --- SI EL DIVIDENDO ESTA VIGENTE O NO VIGENTE 
   if @w_di_estado in (@w_est_vigente,@w_est_novigente) and @w_valor > 0 
   begin    
      if @w_di_estado = @w_est_vigente
         select @w_valor_no_vig = @w_valor
      else
         select @w_valor_no_vig = 0

      --- CALCULAR RUBRO COMFAGANU 
      if exists (
         select 1 
           from ca_amortizacion_tmp
          where amt_operacion = @i_operacion
            and amt_dividendo = @w_di_dividendo
            and amt_concepto  = @w_par_fag)
      begin
         update ca_amortizacion_tmp with (rowlock) set 
            amt_cuota     = @w_valor,
            amt_acumulado = @w_valor_no_vig,
            amt_gracia    = 0                                     -- PAQUETE 2 - REQ 212 BANCA RURAL - GAL 28/JUL/2011
          where amt_operacion = @i_operacion
            and amt_dividendo = @w_di_dividendo 
            and amt_concepto  = @w_par_fag

         if @@error <> 0
         begin
             close cursor_dividendos_1
             deallocate cursor_dividendos_1
             return 710001
         end         
      end
      else 
      begin
         --- INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP 
         insert into ca_amortizacion_tmp with (rowlock)
               (amt_operacion,   amt_dividendo,   amt_concepto,
                amt_cuota,       amt_gracia,      amt_pagado,
                amt_acumulado,   amt_estado,      amt_periodo,
                amt_secuencia)
         values(@i_operacion,    @w_di_dividendo, @w_par_fag,
                @w_valor,        0,               0,
                @w_valor_no_vig ,@w_di_estado,    0,
                1 )

         if @@error <> 0
         begin
             close cursor_dividendos_1
             deallocate cursor_dividendos_1
             return 710001
         end
      end

       --- SI EL RUBRO COMFAGANU TIENE RUBRO ASOCIADO 
      if @w_asociado is not null and @w_asociado <> '' 
      begin
         select @w_valor_asociado = round((@w_valor * @w_porcentaje / 100.0), @w_num_dec)

         if @w_di_estado = @w_est_vigente
            select @w_valor_no_vig = @w_valor_asociado
         else
            select @w_valor_no_vig = 0         
 
         ----ACTUALIZAR RUBRO ASOCIADO A COMFAGANU 
         if exists (
            select 1 
              from ca_amortizacion_tmp
             where amt_operacion = @i_operacion
               and amt_dividendo = @w_di_dividendo
               and amt_concepto  = @w_asociado)
         begin
            update ca_amortizacion_tmp with (rowlock) set 
               amt_cuota     = @w_valor_asociado,
               amt_acumulado = @w_valor_no_vig,
               amt_gracia    = 0                                     -- PAQUETE 2 - REQ 212 BANCA RURAL - GAL 28/JUL/2011
             where amt_operacion = @i_operacion
               and amt_dividendo = @w_di_dividendo 
               and amt_concepto  = @w_asociado

             if @@error <> 0
             begin
                 close cursor_dividendos_1
                 deallocate cursor_dividendos_1
                 return 710001
             end
         end
         else 
         begin
            --- INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP 
            insert into ca_amortizacion_tmp with (rowlock)
                  (amt_operacion,   amt_dividendo,   amt_concepto,
                   amt_cuota,       amt_gracia,      amt_pagado,
                   amt_acumulado,   amt_estado,      amt_periodo,
                   amt_secuencia)
            values(@i_operacion,     @w_di_dividendo, @w_asociado,
                   @w_valor_asociado,0,               0,
                   @w_valor_no_vig,  @w_di_estado,    0,
                   1 )

             if @@error <> 0
             begin
                 close cursor_dividendos_1
                 deallocate cursor_dividendos_1
                 return 710001
             end
         end---
      end
   end -- if @w_di_estado
   else 
   begin   
      --- Si no es Dividendo de anualidad lo deja en valores cero 
      update ca_amortizacion_tmp with (rowlock) set    
         amt_cuota     = 0,
         amt_acumulado = 0,
         amt_gracia    = 0                                     -- PAQUETE 2 - REQ 212 BANCA RURAL - GAL 28/JUL/2011
       where amt_operacion = @i_operacion
         and amt_dividendo = @w_di_dividendo 
         and amt_concepto in (@w_par_fag, @w_par_iva_fag)
   end

   fetch   cursor_dividendos_1
   into    @w_di_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, @w_di_estado
end --- WHILE CURSOR RUBROS FIJOS 

close cursor_dividendos_1
deallocate cursor_dividendos_1

if @i_desde_abnextra = 'N'
begin
   -- ACTUALIZA ULTIMO DIVIDENDO A CEROS SI ES ANUALIDAD SI CAE EN ANUALIDAD
   update ca_amortizacion_tmp with (rowlock) set    
   amt_cuota     = 0,
   amt_acumulado = 0,
   amt_gracia    = 0                                     -- PAQUETE 2 - REQ 212 BANCA RURAL - GAL 28/JUL/2011
   where amt_operacion = @i_operacion
   and amt_dividendo   = @w_di_dividendo 
   and amt_concepto    in (@w_par_fag, @w_par_iva_fag)
end
  
return 0
go




