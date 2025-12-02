/************************************************************************/
/*   NOMBRE LOGICO:      tir.sp                                         */
/*   NOMBRE FISICO:      sp_tir                                         */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Luis Castellanos                               */
/*   FECHA DE ESCRITURA: 21/JUL/2007                                    */
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
/*      Calculo de la Tasa Interna de Retorno (TIR)                     */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/*    21/Jul/07             LCA                   Emision Inicial       */
/*    08/Mar/19             SRO                   Mejoras y Cr�dito Rev */
/*    13/May/21             LBP                   Calculos TIR TEA      */
/*    29/Jun/21            KDR                   Limitar calculos vpn   */
/*    16/May/22            GFP      Actualizacion de proceso para tablas*/
/*                                  temporales                          */
/*    17/Jun/22            GFP      Se cambia en calculo TIR el valor de*/
/*                                  perido por el calculo directo de 360*/
/*                                  dividido para tdivi                 */
/*    08/Sep/22            GFP      R192940 Se actualiza proceso para   */
/*                               recisión de decimales en calculo de TIR*/
/*    13/10/2022           KDR      R194789 No bloq. tabla with nolock  */
/*    22/03/2024           KDR      R221689 Anualizar TIR               */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tir')
	drop proc sp_tir
go

create proc sp_tir
   @i_operacionca         int         = null,
   @i_banco               varchar(32) = null,
   @i_desacumula          char(1)     = null,
   @i_id_inst_proc        int         = null,
   @i_considerar_iva      char(1)     = 'S',
   @i_temporales		  char(1)	  = 'N',
   @o_cat                 float out,
   @o_tir                 float out,
   @o_tea                 float       = null out

as
declare
@w_sp_name              varchar(30),
@w_error		        int ,
@w_tir                  float,
@w_tir1                 float,
@w_tir2                 float,
@w_tir3                 float,
@w_saldo_desde          float,
@w_saldo_hasta          float,
@w_cap                  catalogo,
@w_tipo_rubro           char(1),
@w_monto                money,
@w_dividendo            smallint,
@w_cuota                money,
@w_tdivi                smallint,
@w_tasa                 float,
@w_sdg                  varchar(10),
@w_sho                  varchar(10),
@w_sag                  varchar(10),
@w_aad                  varchar(10),
@w_vpn1                 float,
@w_vpn2                 float,
@w_sumar                float,
@w_flag                 tinyint,
@w_intentos             int,
@w_seguro               money,
@w_seguro2              money,
@w_seguro3              money,
@w_solca                money,
@w_operacionca          int,
@w_desacumula_seg       char(1),
@w_deuda                money,
@w_tea                  float,
@w_monto_op             money,
@w_monto_sol            money,
@w_anticipados          money,
@w_financiados          money,
@w_int_anticipados      money,
@w_tplazo               money,
@w_valor_aad            money,
@w_sector               varchar(10),
@w_plazo_total          int, 
@w_periodica            char(1),
@w_pprom                int,
@w_fecha_desde          datetime,
@w_gracia_cap           smallint,
@w_gracia_int           smallint,
@w_var                  money ,
@w_periodo              INT,
@w_toperacion           varchar(25),
@w_comisiones           money,
@w_fecha_proceso        datetime,
@w_plazo                int,
@w_tipo_plazo           char(4),
@w_tdividendo           char(4),
@w_periodo_cap          int,
@w_periodo_int          int,
@w_dia_pago             int,
@w_resultado_monto      varchar(255),
@w_tasa_int             varchar(255),
@w_tasa_com             varchar(255),
@w_periodicidad         char(4),
@w_msg                  varchar(255),
@w_valor_variable_regla varchar(255),
@w_flag_2               int,
@w_vpn2_aux             float,
@w_tir2_aux             float,
@w_anualiza_tir         char(1),
@w_base_calculo         smallint


select 
@w_sp_name        = 'sp_tir',
@w_intentos       = 0,
@w_tir           = 0,
@w_tir1           = 0,
@w_tir2           = 1,
@w_tipo_rubro     = null,
@w_desacumula_seg = isnull(@i_desacumula,'S'),
@w_periodica      = 'S',
@w_var            = 1.0,
@w_comisiones     = 0,
@w_flag_2         = 0,
@w_vpn2_aux       = 0,
@w_tir2_aux       = 0


select @w_fecha_proceso  = fp_fecha
from cobis..ba_fecha_proceso

-- Parámetro para calcular la TEA de forma similar a la TIR
select @w_anualiza_tir = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'ANUTIR'
and    pa_producto = 'CCA'

select @w_anualiza_tir = isnull(@w_anualiza_tir, 'N')

if @i_temporales = 'N'
  if @i_banco is null 
    begin  
      select 
      @w_monto_op    = op_monto, 
      @w_monto_sol   = op_monto, 
      @w_tdivi       = op_periodo_int * a.td_factor, 
      @w_operacionca = op_operacion, 
      @w_deuda       = op_monto, 
      @w_tplazo      = op_plazo * b.td_factor, 
      @w_sector      = op_sector, 
      @w_plazo_total = datediff(dd,op_fecha_ini,op_fecha_fin), 
      @w_fecha_desde = op_fecha_ini, 
      @w_gracia_cap  = op_gracia_cap, 
      @w_gracia_int  = op_gracia_int, 
      @w_toperacion  = op_toperacion,
      @w_base_calculo = op_dias_anio
      from ca_operacion, ca_tdividendo a, ca_tdividendo b
      where a.td_tdividendo = op_tdividendo
      and   b.td_tdividendo = op_tplazo
      and   op_operacion    = @i_operacionca 
    end
  else 
    begin
      select 
      @w_monto_op  = op_monto,
      @w_monto_sol = op_monto,
      @w_tdivi     = op_periodo_int * a.td_factor,
      @w_operacionca = op_operacion,
      @w_deuda       = op_monto,
      @w_tplazo      = op_plazo * b.td_factor,
      @w_sector      = op_sector,
      @w_plazo_total = datediff(dd,op_fecha_ini,op_fecha_fin),
      @w_fecha_desde = op_fecha_ini,
      @w_gracia_cap  = op_gracia_cap,
      @w_gracia_int  = op_gracia_int,
      @w_toperacion  = op_toperacion,
      @w_base_calculo = op_dias_anio
      from ca_operacion, ca_tdividendo a, ca_tdividendo b
      where a.td_tdividendo = op_tdividendo
      and   b.td_tdividendo = op_tplazo
      and   op_banco        = @i_banco
    end
else
  if @i_banco is null 
    begin  
      select 
      @w_monto_op    = opt_monto, 
      @w_monto_sol   = opt_monto, 
      @w_tdivi       = opt_periodo_int * a.td_factor, 
      @w_operacionca = opt_operacion, 
      @w_deuda       = opt_monto, 
      @w_tplazo      = opt_plazo * b.td_factor, 
      @w_sector      = opt_sector, 
      @w_plazo_total = datediff(dd,opt_fecha_ini,opt_fecha_fin), 
      @w_fecha_desde = opt_fecha_ini, 
      @w_gracia_cap  = opt_gracia_cap, 
      @w_gracia_int  = opt_gracia_int, 
      @w_toperacion  = opt_toperacion,
      @w_base_calculo = opt_dias_anio	  
      from ca_operacion_tmp with (nolock), ca_tdividendo a with (nolock), ca_tdividendo b with (nolock)
      where a.td_tdividendo = opt_tdividendo
      and   b.td_tdividendo = opt_tplazo
      and   opt_operacion    = @i_operacionca 
    end
  else 
    begin
      select 
      @w_monto_op  = opt_monto,
      @w_monto_sol = opt_monto,
      @w_tdivi     = opt_periodo_int * a.td_factor,
      @w_operacionca = opt_operacion,
      @w_deuda       = opt_monto,
      @w_tplazo      = opt_plazo * b.td_factor,
      @w_sector      = opt_sector,
      @w_plazo_total = datediff(dd,opt_fecha_ini,opt_fecha_fin),
      @w_fecha_desde = opt_fecha_ini,
      @w_gracia_cap  = opt_gracia_cap,
      @w_gracia_int  = opt_gracia_int,
      @w_toperacion  = opt_toperacion,
      @w_base_calculo = opt_dias_anio
      from ca_operacion_tmp with (nolock), ca_tdividendo a with (nolock), ca_tdividendo b with (nolock)
      where a.td_tdividendo = opt_tdividendo
      and   b.td_tdividendo = opt_tplazo
      and   opt_banco        = @i_banco
    end

if @w_operacionca is null 
  return 0

select @w_periodo = periodo  
from ca_tasas_periodos 
where tdivi = @w_tdivi 

if @i_temporales = 'N'
  if (select count(1) from ca_dividendo where di_operacion = @w_operacionca) = 1   
    select @w_tplazo = @w_plazo_total, @w_tdivi = @w_plazo_total
  else 
    begin
      if exists (select 1 from ca_dividendo where di_operacion = @w_operacionca 
                 and datediff(dd,di_fecha_ini,di_fecha_ven) <> @w_tdivi) 
         OR    (@w_gracia_cap > 0 or @w_gracia_int > 0) 
      select @w_periodica = 'N', @w_var = 0.01 
    end
else
  if (select count(1) from ca_dividendo_tmp with (nolock) where dit_operacion = @w_operacionca) = 1   
    select @w_tplazo = @w_plazo_total, @w_tdivi = @w_plazo_total
  else 
    begin
      if exists (select 1 from ca_dividendo_tmp with (nolock) where dit_operacion = @w_operacionca 
                 and datediff(dd,dit_fecha_ini,dit_fecha_ven) <> @w_tdivi) 
         OR    (@w_gracia_cap > 0 or @w_gracia_int > 0) 
      select @w_periodica = 'N', @w_var = 0.01 
    end

if @w_anualiza_tir = 'S' -- No se consideran las variaciones de días de las cuotas con el factor de la periodicidad.
   select @w_periodica = 'S'

if @i_temporales = 'N'
  begin
    /* BUSCAR RUBRO CAPITAL */
    select @w_cap = ro_concepto
    from ca_rubro_op with (nolock) 
    where ro_operacion  = @w_operacionca 
    and   ro_fpago      = 'P'
    and   ro_tipo_rubro = 'C' 

    /* BUSCAR TASA INTERES */
    select @w_tasa = ro_porcentaje
    from ca_rubro_op with (nolock) 
    where ro_operacion  = @w_operacionca 
    and   ro_concepto   = 'INT' 

    select @w_seguro = isnull(@w_seguro,0)+isnull(@w_seguro2,0)+isnull(@w_seguro3,0)

    select @w_solca = ro_valor
    from ca_rubro_op with (nolock) 
    where ro_operacion = @w_operacionca
    and ro_concepto    = 'SOLCA' 
    and ro_fpago       = 'F'

    select 
    @w_seguro = isnull(@w_seguro,0),
    @w_solca  = isnull(@w_solca,0)

    select @w_financiados = isnull(sum(ro_valor),0)
    from ca_rubro_op with (nolock) 
    where ro_operacion = @w_operacionca
    and   ro_fpago     = 'L'
    AND   ro_limite    = 'S'

    select @w_anticipados = isnull(sum(ro_valor) ,0)
    from ca_rubro_op with (nolock) 
    where ro_operacion = @w_operacionca 
    and  ro_fpago      = 'L' 
    AND  ro_limite     = 'N'     
    and  ro_concepto   <> 'SOLCA'

    select @w_int_anticipados = isnull(sum(am_cuota),0) 
    from ca_amortizacion with (nolock) , ca_rubro_op with (nolock) 
    where am_operacion =  @w_operacionca 
    and ro_operacion   =  am_operacion
    and ro_concepto    =  am_concepto 
    and ro_concepto    =  'INT'
    and ro_fpago       in ('T')
  end
else
  begin
    /* BUSCAR RUBRO CAPITAL */
    select @w_cap = rot_concepto
    from ca_rubro_op_tmp with (nolock)
    where rot_operacion  = @w_operacionca 
    and   rot_fpago      = 'P'
    and   rot_tipo_rubro = 'C' 

    /* BUSCAR TASA INTERES */
    select @w_tasa = rot_porcentaje
    from ca_rubro_op_tmp with (nolock)
    where rot_operacion  = @w_operacionca 
    and   rot_concepto   = 'INT' 

    select @w_seguro = isnull(@w_seguro,0)+isnull(@w_seguro2,0)+isnull(@w_seguro3,0)

    select @w_solca = rot_valor
    from ca_rubro_op_tmp with (nolock)
    where rot_operacion = @w_operacionca
    and rot_concepto    = 'SOLCA' 
    and rot_fpago       = 'F'

    select 
    @w_seguro = isnull(@w_seguro,0),
    @w_solca  = isnull(@w_solca,0)

    select @w_financiados = isnull(sum(rot_valor),0)
    from ca_rubro_op_tmp with (nolock)
    where rot_operacion = @w_operacionca
    and   rot_fpago     = 'L'
    AND   rot_limite    = 'S'

    select @w_anticipados = isnull(sum(rot_valor) ,0)
    from ca_rubro_op_tmp with (nolock)
    where rot_operacion = @w_operacionca 
    and  rot_fpago      = 'L'
    AND  rot_limite     = 'N' 
    and  rot_concepto   <> 'SOLCA'

    select @w_int_anticipados = isnull(sum(amt_cuota),0) 
    from ca_amortizacion_tmp with (nolock), ca_rubro_op_tmp with (nolock)
    where amt_operacion =  @w_operacionca 
    and rot_operacion   =  amt_operacion
    and rot_concepto    =  amt_concepto 
    and rot_concepto    =  'INT'
    and rot_fpago       in ('T')
  end

if @w_int_anticipados > 0 
	select @w_desacumula_seg = 'A'
	
select @w_monto = @w_monto_op - isnull(@w_anticipados,0) - isnull(@w_int_anticipados,0) - @w_financiados + isnull(@w_valor_aad,0) - @w_comisiones

if @w_tplazo = @w_tdivi and @w_tdivi <= 360 
BEGIN
	select @w_tir1 = convert(float,@w_tasa / (360/@w_tdivi*100.00))
END	
else
	if @w_periodica = 'S' 
	BEGIN
	  	select @w_tir1 = convert(float,@w_tasa / ((360/@w_tdivi)*100.00))
	END
	else 
	BEGIN 
		select @w_tir1 = convert(float,@w_tasa / (360*100.00)) 
	END

select @w_seguro = @w_financiados + isnull(@w_anticipados,0) - isnull(@w_valor_aad,0)

/* SE OBTIENE EL VALOR PRESENTE NETO CON LA PRIMERA APROXIMACION */
exec @w_error = sp_vpn
@i_operacionca = @w_operacionca,
@i_monto       = @w_monto,
@i_tdivi       = @w_tdivi,
@i_tasa        = @w_tir1,
@i_deuda       = @w_deuda,
@i_des_seg     = @w_desacumula_seg,
@i_seguro      = @w_seguro,
@i_periodica   = @w_periodica,
@i_fecha_desde = @w_fecha_desde,
@i_temporales  = @i_temporales,
@o_vpn         = @w_vpn1 out

if @w_error <> 0 
   goto ERROR_FIN 

if @w_vpn1 = 0 begin
   select @o_tir = @w_tasa
   goto SALIR
end

if @w_vpn1 > 0
   select @w_sumar =  0.0001*@w_var -- SUBIR LA TASA POR VPN1 POSITIVO
else
   select @w_sumar = -0.0001*@w_var -- BAJAR LA TASA POR VPN1 NEGATIVO

select @w_tir2 = @w_tir1

select @w_flag = 1

while @w_flag = 1  
begin
  
   -- KDR 28Jun2021 Limitar intentos de calculo vpn.
   IF @w_intentos >= 2000
   BEGIN
      --SELECT  @o_tir = 0,
	  --	      @o_tea = 0,
	  --	      @o_cat = 0
	  --SELECT @w_error = 711099 --- HACER MENSAJE DE ERROR
	  --GOTO ERROR_FIN  
	  break
   end
   
   select
   @w_intentos = @w_intentos + 1,  
   @w_tir2     = @w_tir2 + @w_sumar

   exec @w_error = sp_vpn
   @i_operacionca = @w_operacionca,
   @i_monto       = @w_monto,
   @i_tdivi       = @w_tdivi,
   @i_tasa        = @w_tir2,
   @i_des_seg     = @w_desacumula_seg,
   @i_deuda       = @w_deuda,
   @i_seguro      = @w_seguro,
   @i_periodica   = @w_periodica,
   @i_fecha_desde = @w_fecha_desde,
   @i_temporales  = @i_temporales,
   @o_vpn         = @w_vpn2 out
   
   if @w_error <> 0 
   begin
      break
      goto ERROR_FIN 
   end
   
   --GFP 08/Sep/22 Se invierte la variación de la TIR con más decimales de precisión 
   if @w_vpn1 > 0
   begin
      if @w_vpn2 < 0 and @w_flag_2 = 0
         select @w_sumar   =  -0.00001*@w_var, 
                @w_flag_2  = 1
      else   
         if @w_vpn2 > 0 and @w_flag_2 = 1 
		 begin
		    select @w_tir2    = @w_tir2_aux,
			       @w_vpn2    = @w_vpn2_aux
		    break
		 end
   end
   else
   begin
      if @w_vpn2 > 0 and @w_flag_2 = 0 
         select @w_sumar  =  0.00001*@w_var, 
                @w_flag_2 = 1
      else   
         if @w_vpn2 < 0 and @w_flag_2 = 1 
		 begin
		    select @w_tir2    = @w_tir2_aux,
			       @w_vpn2    = @w_vpn2_aux
		    break
		 end
   end
   
   -- Los valores de la TIR y VPN se almacenan en variables auxiliares para mas precisión
   select @w_tir2_aux    = @w_tir2,
          @w_vpn2_aux    = @w_vpn2 
   
   if abs(@w_tir2) = 1  break 
END

select @w_tir = @w_tir1 + (@w_tir2 - @w_tir1) * (@w_vpn1/(@w_vpn1-@w_vpn2)) 

if @w_tplazo = @w_tdivi
BEGIN
select @o_tir  = @w_tir *100*@w_base_calculo*1.0/@w_tplazo,
       @w_tir1 = @w_tir1*100*@w_base_calculo*1.0/@w_tplazo, 
       @w_tir2 = @w_tir2*100*@w_base_calculo*1.0/@w_tplazo
END
else if @w_periodica = 'S'   
select @o_tir  = @w_tir *100*@w_base_calculo/@w_tdivi,
       @w_tir1 = @w_tir1*100*periodo, 
       @w_tir2 = @w_tir2*100*periodo
  from ca_tasas_periodos
 where tdivi = @w_tdivi
else begin
select @o_tir   = @w_tir *100*@w_base_calculo*1.0,
       @w_tir1  = @w_tir1*100*@w_base_calculo*1.0, 
       @w_tir2  = @w_tir2*100*@w_base_calculo*1.0
select @w_pprom = avg(datediff(dd,di_fecha_ini,di_fecha_ven))
          from ca_dividendo
        where di_operacion = @w_operacionca
end


SALIR:

if @w_anualiza_tir = 'N'
begin 
   exec sp_tea
      @i_tir        = @o_tir,
      @i_tdivi      = @w_tdivi,
      @i_tplazo     = @w_tplazo,
      @i_pprom      = @w_pprom,
      @i_periodica  = @w_periodica,
      @o_tasa       = @o_tea out
end
else
begin

   if @w_tplazo = @w_tdivi
      select @o_tea  = @w_tir *100*@w_base_calculo*1.0/@w_tplazo
   else if @w_periodica = 'S'   
      select @o_tea = @w_tir*100*periodo 
      from ca_tasas_periodos
      where tdivi = @w_tdivi
   else begin
      select @o_tea = @w_tir *100*@w_base_calculo*1.0
   end
   
   if @o_tir is null
      select  @o_tir = @w_tir *100*@w_base_calculo*1.0/@w_tdivi,
	          @o_tea = @w_tir *100*@w_base_calculo*1.0/@w_tdivi
 
end

		
select @o_cat = (power(1+@o_tir/100/@w_periodo, @w_periodo) - 1)*100

if @o_tea is null 
  SELECT @o_tea = 0

return 0

ERROR_FIN:
return @w_error

GO

