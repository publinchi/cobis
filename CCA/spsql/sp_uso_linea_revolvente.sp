/************************************************************************/
/*   Stored procedure:     sp_uso_linea_revolvente.sp                   */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/*  Programa que permite actualizar y desembolsar una operación de      */
/*  Linea Revolvente                                                    */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*				MODIFICACIONES				*/
/*    FECHA		AUTOR			RAZON			*/
/*  22/11/2019         EMP-JJEC                Creaciòn                 */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_uso_linea_revolvente')
   drop proc sp_uso_linea_revolvente
go

create proc sp_uso_linea_revolvente
(  @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_operacion_linea  cuenta,
   @i_monto            money,
   @i_plazo            int,
   @i_fecha_uso        datetime
)
as declare
   @w_return               int,
   @w_sp_name              varchar(32),
   @w_error                int,
   @w_toperacion           catalogo,
   @w_oficina              int,
   @w_moneda               smallint,
   @w_fecha_ini            datetime,
   @w_fecha_fin            datetime,
   @w_moneda_local         tinyint,
   @w_cod_capital          catalogo,
   @w_operacion            int,
   @w_op_monto             money,
   @w_op_monto_aprobado    money,
   @w_tramite              int,
   @w_lin_credito          cuenta, 
   @w_banco_tmp            cuenta,
   @w_operacion_tmp        int,
   @w_op_cuenta            cuenta,
   @w_producto             catalogo,
   @w_num_dec              tinyint,
   @w_num_dec_mn           tinyint,
   @w_moneda_n             tinyint,
   @w_secuencial           int,
   @w_estado               tinyint,
   @w_est_vigente          tinyint,
   @w_est_cancelado        tinyint,
   @w_est_novigente        tinyint,
   @w_est_suspenso         tinyint,
   @w_est_vencido          tinyint,
   @w_est_credito          tinyint,
   @w_est_anulado          tinyint, 
   @w_max_fecha_dividendo  datetime,
   @w_dividendo            int,
   @w_dividendo_act        int,
   @w_dividendo_ven        int,
   @w_nrows                tinyint,
   @w_sec_previo           int,
   @w_dit_operacion        int,
   @w_dit_dividendo        smallint,
   @w_dit_fecha_ini        datetime,
   @w_dit_fecha_ven        datetime,
   @w_dit_de_capital       char(1),
   @w_dit_de_interes       char(1),
   @w_dit_gracia           smallint,
   @w_dit_gracia_disp      smallint,
   @w_dit_estado           tinyint,
   @w_dit_dias_cuota       int,
   @w_dit_intento          tinyint,
   @w_dit_prorroga         char(1),
   @w_dit_fecha_can        datetime,
   @w_cotizacion           float, 
   @w_convertir_valor      char(1),
   @w_monto_mn             money,
   @w_monto_op             money,
   @w_desembolso           int,
   @w_monto_des            money,
   @w_fecha_liq            datetime,
   @w_li_fecha_vto         datetime,
   @w_oficial              smallint,
   @w_dm_producto          catalogo,
   @w_dm_cuenta            cuenta,
   @w_dm_beneficiario      descripcion,
   @w_dm_moneda            tinyint,
   @w_dm_desembolso        int,
   @w_dm_monto_mds         money,
   @w_dm_cotizacion_mds    float,
   @w_dm_tcotizacion_mds   char(1),
   @w_dm_cotizacion_mop    float,
   @w_dm_tcotizacion_mop   char(1),
   @w_dm_monto_mn          money,
   @w_dm_monto_mop         money,
   @w_prod_cobis           int,
   @w_categoria            catalogo,
   @w_codvalor             int,
   @w_tipo_oficina_ifase   char(1),
   @w_oficina_ifase        int,
   @w_num_renovacion       int,
   @w_concepto_cap         catalogo,
   @w_codvalor_cap         int,
   @w_cliente              int,
   @w_rowcount             int,
   @w_num_dec_op           tinyint,
   @w_dividendo_min        int,
   @w_op_tipo              char(1),
   @i_moneda_ds            tinyint

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_credito    = @w_est_credito   out,
@o_est_anulado    = @w_est_anulado   out

if @i_fecha_uso is null or @i_operacion_linea is null or @i_monto is null or @i_plazo is null
begin
   select @w_error = 1801035 -- DATOS OBLIGATORIOS
   goto ERROR
end

if @i_monto <= 0
begin
   select @w_error = 701027
   goto ERROR
end 

-- VARIABLES INICIALES
select @w_sp_name = 'sp_uso_linea_revolvente'

-- CONSULTA CODIGO DE MONEDA LOCAL
select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'MLO'
and    pa_producto = 'ADM'

-- CODIGO DE CAPITAL
select @w_concepto_cap = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'

select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 710429
   goto ERROR
end

select @s_date = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

select @w_fecha_liq = @s_date

if @i_fecha_uso <> @w_fecha_liq
  select @i_fecha_uso = @w_fecha_liq

select @w_operacion              = op_operacion,
       @w_oficina                = op_oficina,
       @w_moneda                 = op_moneda,
       @w_op_monto               = op_monto,
       @w_op_monto_aprobado      = op_monto_aprobado,
       @w_tramite                = op_tramite,
       @w_toperacion             = op_toperacion,
       @w_op_cuenta              = op_cuenta,
       @w_lin_credito            = op_lin_credito,
       @w_estado                 = op_estado,
       @w_oficial                = op_oficial,
       @w_cliente                = op_cliente
from   ca_operacion
where  op_banco = @i_operacion_linea
  and  op_estado not in (@w_est_credito, @w_est_anulado, @w_est_novigente) --, @w_est_cancelado)

if @@rowcount = 0
begin
   select @w_error = 710025
   goto ERROR
end

-- MANEJO DE DECIMALES
exec @w_return = sp_decimales
     @i_moneda       = @w_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_num_dec_op out,
     @o_dec_nacional = @w_num_dec_mn out

if @w_return <> 0 begin
   select @w_error = @w_return
   goto ERROR
end

-- CREAR OPERACION TEMPORAL CON DATOS ENVIADOS
exec @w_return = sp_crear_operacion_int
   @i_ref_revolvente    = @i_operacion_linea,
   @i_monto             = @i_monto,
   @i_monto_aprobado    = @i_monto,
   @i_plazo             = @i_plazo,
   @i_fecha_ini         = @i_fecha_uso,
   @i_es_revolvente     = 'S', 
   @o_banco             = @w_banco_tmp output

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end

-- Obtener numero de operacion int de temporal
select @w_operacion_tmp  = opt_operacion
from   ca_operacion_tmp
where  opt_banco = @w_banco_tmp

--- GERERAR SECUENCIAL
exec @w_secuencial = sp_gen_sec 
     @i_operacion  = @w_operacion

BEGIN TRAN        

-- GENERACION DE RESPALDO PARA REVERSAS
exec @w_return = sp_historial
     @i_operacionca = @w_operacion,
     @i_secuencial  = @w_secuencial

if @w_return <> 0 begin
  select @w_error = @w_return
  goto ERROR
end

-- ACTUALIZAR CA_OPERACION
if @w_estado = @w_est_cancelado
begin
   update ca_operacion
   set op_tipo_amortizacion = 'MANUAL',
       op_monto      = op_monto + @i_monto,
       op_monto_aprobado = op_monto_aprobado + @i_monto,
       op_plazo      = op_plazo + @i_plazo,
       op_estado     = @w_est_vigente
   where op_operacion = @w_operacion
   
   if @@error <> 0 
   begin
      select @w_error = 705076
      goto ERROR
   end
end
else
begin
   update ca_operacion
   set op_tipo_amortizacion = 'MANUAL',
       op_monto = op_monto + @i_monto,
       op_monto_aprobado = op_monto_aprobado + @i_monto,
       op_plazo = op_plazo + @i_plazo
   where op_operacion = @w_operacion
   
   if @@error <> 0 
   begin
      select @w_error = 705076
      goto ERROR
   end
end	
	   
-- ACTUALIZAR CA_RUBRO_OP   
update ca_rubro_op
set ro_valor = ro_valor + isnull(rot_valor,0),
    ro_base_calculo = ro_base_calculo + isnull(rot_base_calculo,0)
from ca_rubro_op_tmp
where rot_operacion = @w_operacion_tmp
  and ro_operacion  = @w_operacion
  and rot_concepto  = ro_concepto
  
if @@error <> 0 
begin
   select @w_error = 705071
   goto ERROR
end

-- ACTUALIZAR CA_DIVIDENDO
select @w_dividendo = max(di_dividendo)
from ca_dividendo
where di_operacion = @w_operacion

-- CURSOR DE DIVIDENDOS TABLA TMP
select @w_nrows = 1, 
       @w_sec_previo = 0

while (@w_nrows > 0) 
begin 
   select top 1
      @w_dit_operacion  = dit_operacion, 
      @w_dit_dividendo  = dit_dividendo, 
      @w_dit_fecha_ini  = dit_fecha_ini,               
      @w_dit_fecha_ven  = dit_fecha_ven,               
      @w_dit_de_capital = dit_de_capital, 
      @w_dit_de_interes = dit_de_interes, 
      @w_dit_gracia     = dit_gracia, 
      @w_dit_gracia_disp= dit_gracia_disp, 
      @w_dit_estado     = dit_estado, 
      @w_dit_dias_cuota = dit_dias_cuota, 
      @w_dit_intento    = dit_intento, 
      @w_dit_prorroga   = dit_prorroga, 
      @w_dit_fecha_can  = dit_fecha_can,
      @w_sec_previo     = dit_dividendo
   from ca_dividendo_tmp
   where dit_operacion = @w_operacion_tmp
     and dit_dividendo > @w_sec_previo
   order by dit_dividendo
        
   if @@rowcount = 0 break 

   if not exists (select 1 from ca_dividendo where di_operacion = @w_operacion and di_fecha_ven = @w_dit_fecha_ven)
   begin
      
      select @w_dividendo = @w_dividendo + 1
      
      insert into ca_dividendo
      select @w_operacion,  
             @w_dividendo,
             @w_dit_fecha_ini, 
             @w_dit_fecha_ven,  
             @w_dit_de_capital, 
             @w_dit_de_interes, 
             @w_dit_gracia,     
             @w_dit_gracia_disp,
             @w_dit_estado,     
             @w_dit_dias_cuota, 
             @w_dit_intento,    
             @w_dit_prorroga,   
             @w_dit_fecha_can
   
      if @@error <> 0 
      begin
         select @w_error = 703090
         goto ERROR
      end
      
      insert into ca_cuota_adicional
      select @w_operacion,  
             @w_dividendo,
             0
      
      if @@error <> 0 
      begin
         select @w_error = 703102
         goto ERROR
      end

      -- INSERTA AMORTIZACION DEL DIVIDDO
      insert into ca_amortizacion
      select @w_operacion, 
             @w_dividendo,
             amt_concepto,
             amt_estado,
             amt_periodo,
             amt_cuota,
             amt_gracia,
             amt_pagado,
             amt_acumulado,
             amt_secuencia
       from ca_amortizacion_tmp
       where amt_operacion = @w_operacion_tmp
         and amt_dividendo = @w_dit_dividendo

      if @@error <> 0 
      begin
         select @w_error = 703113
         goto ERROR
      end
      
   end             
   else
   begin
      -- ACTUALIZAR CA_AMORTIZACION EN REGISTROS EXISTENTES
      select @w_dividendo_act = di_dividendo
      from ca_dividendo
      where di_operacion = @w_operacion
        and di_fecha_ven = @w_dit_fecha_ven

      if isnull(@w_dividendo_act,0) > 0
      begin
         update ca_amortizacion
            set am_cuota = am_cuota + amt_cuota,
                am_acumulado = am_acumulado + amt_acumulado
           from ca_amortizacion_tmp
          where am_operacion  = @w_operacion
            and am_dividendo  = @w_dividendo_act
            and amt_operacion = @w_operacion_tmp
            and amt_dividendo = @w_dit_dividendo
            and am_concepto   = amt_concepto
      
         if @@error <> 0 
         begin
            select @w_error = 705072
            goto ERROR
         end
      end
   end	
end

select @w_max_fecha_dividendo = max(di_fecha_ven)
from ca_dividendo 
where di_operacion = @w_operacion

-- ACTUALIZAR CA_OPERACION
update ca_operacion
   set op_fecha_fin = @w_max_fecha_dividendo
 where op_operacion = @w_operacion

if @@error <> 0 
begin
   select @w_error = 705076
   goto ERROR
end

if @w_estado = @w_est_cancelado
begin
	
   select @w_dividendo_min = min(di_dividendo)
   from ca_dividendo
   where di_operacion = @w_operacion
     and di_estado in (@w_est_vigente,@w_est_novigente)
	
   update ca_dividendo
   set di_estado = @w_est_vigente
    where di_operacion = @w_operacion
      and di_dividendo = @w_dividendo_min
end

-- INSERTAR FORMA DE DESEMBOLSO
select @w_producto = 'NCAH_FINAN'

select @w_dividendo = di_dividendo
from ca_dividendo
where di_operacion = @w_operacion
and di_estado = @w_est_vigente

if @@rowcount = 0
begin
   select @w_error = 701179
   goto ERROR
end

if @w_op_tipo = 'O' and @w_lin_credito is null
begin
  select @w_error = 701065
  goto ERROR 
end 

select @i_moneda_ds = isnull(@i_moneda_ds,@w_moneda)

-- DETERMINAR EL VALOR DE COTIZACION DEL DIA
if @i_moneda_ds = @w_moneda_local
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
        @i_moneda     = @i_moneda_ds,
        @i_fecha      = @i_fecha_uso,
        @o_cotizacion = @w_cotizacion output
end

---CALCULAR MONTO OP Y MONTO MN 
if @i_moneda_ds = @w_moneda
begin
   if @w_moneda = @w_moneda_local
      select @w_convertir_valor = 'N'
   else
      select @w_convertir_valor = 'S'
end
ELSE
begin
   select @w_convertir_valor = 'S'
end

if @w_convertir_valor = 'S'
begin
   select @i_monto  = round(@i_monto,@w_num_dec_mn)
   select @w_monto_mn  = @i_monto * isnull(@w_cotizacion,1)
   select @w_monto_mn  = round(@w_monto_mn,@w_num_dec_mn)
   select @w_monto_op  = round(convert(float,@w_monto_mn) / convert(float,@w_cotizacion), @w_num_dec_op)
end
else
begin
   select @w_monto_mn = round(@i_monto,@w_num_dec_op)
   select @w_monto_op = round(@i_monto,@w_num_dec_op)
end

--- CALCULAR NUMERO DE LINEA 
select @w_desembolso = max(dm_desembolso) + 1
from   ca_desembolso
where  dm_operacion  = @w_operacion
and    dm_estado     in ('A','NA')

if @w_desembolso is null 
begin
  select @w_error = 701121
  goto ERROR 
end 

insert into ca_desembolso
      (dm_secuencial,      dm_operacion,      dm_desembolso,
       dm_producto,        dm_cuenta,         dm_beneficiario,
       dm_oficina_chg,     dm_usuario,        dm_oficina,
       dm_terminal,        dm_dividendo,      dm_moneda,
       dm_monto_mds,       dm_monto_mop,      dm_monto_mn,
       dm_cotizacion_mds,  dm_cotizacion_mop, dm_tcotizacion_mds,
       dm_tcotizacion_mop, dm_estado,         dm_cod_banco,
       dm_cheque,          dm_fecha,          dm_prenotificacion,
       dm_carga,           dm_concepto,       dm_valor,
       dm_fecha_ingreso)
values(@w_secuencial,      @w_operacion,         @w_desembolso,
       @w_producto,        @w_op_cuenta,         convert(varchar(10),@w_cliente), 
       @w_oficina,         @s_user,              @w_oficina,
       @s_term,            @w_dividendo,         @i_moneda_ds,
       @i_monto,           @w_monto_op,          @w_monto_mn,
       @w_cotizacion,      @w_cotizacion,        @w_cotizacion,
       @w_cotizacion,      'NA',                 null,
       null,               @i_fecha_uso,         null,
       null,               '',                   0,
       @i_fecha_uso)

if @@error <> 0
begin
   select @w_error = 710088
   goto ERROR
end

-- LIQUIDAR
---Validacion de los montos  a desembolsar contra el monto aprobado
select @w_monto_des = isnull(sum(dm_monto_mn),0)
from ca_desembolso
where dm_operacion = @w_operacion
and   dm_estado = 'NA'

select @w_li_fecha_vto = li_fecha_vto
from cob_credito..cr_linea
where li_num_banco  = @w_lin_credito

if @w_fecha_liq > @w_li_fecha_vto
begin
   select @w_error = 711055
   goto ERROR
end

---Inicio de la transaccion
---------------------------
insert into ca_transaccion
      (tr_secuencial,        tr_fecha_mov,        tr_toperacion,
       tr_moneda,            tr_operacion,        tr_tran, 
       tr_en_linea,          tr_banco,            tr_dias_calc,
       tr_ofi_oper,          tr_ofi_usu,          tr_usuario,
       tr_terminal,          tr_fecha_ref,        tr_secuencial_ref,
       tr_estado,            tr_gerente,          tr_gar_admisible,
       tr_reestructuracion,  tr_calificacion,
       tr_observacion,       tr_fecha_cont,       tr_comprobante)
values(@w_secuencial,        @s_date,             @w_toperacion,
       @w_moneda,            @w_operacion,        'DES',
       'S',                  @i_operacion_linea,  0,
       @w_oficina,           @s_ofi,              @s_user,
       @s_term,              @w_fecha_liq,        0,
       'ING',                @w_oficial,          'N',
       'N',                   '',
       'DESEMBOLSO PARCIAL', @s_date,             0)

if @@error <>0 
begin
   select @w_error = 710030
   goto ERROR
end
   
-- INSERCION DEL DETALLE CONTABLE PARA LAS FORMAS DE PAGO
declare cursor_desembolso cursor
for select dm_desembolso,    dm_producto,          dm_cuenta,
           dm_beneficiario,  dm_monto_mds,
           dm_moneda,        dm_cotizacion_mds,    dm_tcotizacion_mds,
           dm_monto_mn,      dm_cotizacion_mop,    dm_tcotizacion_mop,
           dm_monto_mop
    from   ca_desembolso
    where  dm_secuencial = @w_secuencial
    and    dm_operacion  = @w_operacion
    order  by dm_desembolso
    for read only

open cursor_desembolso

fetch cursor_desembolso
into  @w_dm_desembolso,   @w_dm_producto,       @w_dm_cuenta,
      @w_dm_beneficiario, @w_dm_monto_mds,
      @w_dm_moneda,       @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
      @w_dm_monto_mn,     @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
      @w_dm_monto_mop
   
--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin
   
   select @w_prod_cobis = isnull(cp_pcobis,0),  
          @w_categoria      = cp_categoria,
          @w_codvalor       = cp_codvalor
   from   ca_producto
   where  cp_producto = @w_dm_producto
   
   if @@rowcount = 0
   begin
      select @w_error = 701150
      goto ERROR
   end
   
   -- INSERCION DEL DETALLE DE LA TRANSACCION
   insert ca_det_trn
         (dtr_secuencial,    dtr_operacion,        dtr_dividendo,
          dtr_concepto,      dtr_estado,           dtr_periodo,
          dtr_codvalor,      dtr_monto,            dtr_monto_mn,
          dtr_moneda,        dtr_cotizacion,       dtr_tcotizacion,
          dtr_afectacion,    dtr_cuenta,           dtr_beneficiario,
          dtr_monto_cont)
   values(@w_secuencial,     @w_operacion,         @w_dm_desembolso,
          @w_dm_producto,    1,                    0, 
          @w_codvalor,       @w_dm_monto_mds,      @w_dm_monto_mn,
          @w_dm_moneda,      @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
          'C',               isnull(@w_dm_cuenta,''),   @w_dm_beneficiario,
          0)
   
      if @@error <>0
      begin
         select @w_error = 710001  
         goto ERROR
      end 

      select @w_codvalor_cap = co_codigo * 1000  + 10  + 0 --@w_tipo_garantia
      from   ca_concepto
      where  co_concepto = @w_concepto_cap

   -- INSERCION DEL DETALLE DE LA TRANSACCION
   insert ca_det_trn
         (dtr_secuencial,    dtr_operacion,        dtr_dividendo,
          dtr_concepto,      dtr_estado,           dtr_periodo,
          dtr_codvalor,      dtr_monto,            dtr_monto_mn,
          dtr_moneda,        dtr_cotizacion,       dtr_tcotizacion,
          dtr_afectacion,    dtr_cuenta,           dtr_beneficiario,
          dtr_monto_cont)
   values(@w_secuencial,     @w_operacion,         @w_dm_desembolso,
          @w_concepto_cap,    1,                   0, 
          @w_codvalor_cap,   @w_dm_monto_mds,      @w_dm_monto_mn,
          @w_dm_moneda,      @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
          'D',               isnull(@w_dm_cuenta,''),   @w_dm_beneficiario,
          0)
   
      if @@error <>0
      begin
         select @w_error = 710001  
         goto ERROR
      end 
      
      if  @w_prod_cobis > 0 
      begin
         select @w_oficina_ifase = @s_ofi
         
         select @w_tipo_oficina_ifase = dp_origen_dest
         from   ca_trn_oper, cob_conta..cb_det_perfil
         where  to_tipo_trn = 'DES'
         and    to_toperacion = @w_toperacion
         and    dp_empresa    = 1
         and    dp_producto   = 7
         and    dp_perfil     = to_perfil
         and    dp_codval     = @w_codvalor
         
         if @@rowcount = 0
         begin
            select @w_error = 710446
            goto ERROR
         end
         
         if @w_tipo_oficina_ifase = 'C'
         begin
            select @w_oficina_ifase = pa_int
            from   cobis..cl_parametro
            where  pa_nemonico = 'OFC'
            and    pa_producto = 'CON'
            set transaction isolation level read uncommitted
         end
         
         if @w_tipo_oficina_ifase = 'D'
         begin
            select @w_oficina_ifase = @w_oficina
         end

         -- AFECTACION A OTROS PRODUCTOS
         exec @w_error = sp_afect_prod_cobis
         @s_user               = @s_user,
         @s_date               = @s_date,
         @s_ssn                = @s_ssn,
         @s_sesn               = @s_sesn,
         @s_term               = @s_term,
         @s_srv                = @s_srv,
         @s_ofi                = @w_oficina_ifase,
         @i_fecha              = @w_fecha_liq,
         @i_cuenta             = @w_dm_cuenta,
         @i_producto           = @w_dm_producto,
         @i_monto              = @w_dm_monto_mn,
         @i_mon                = @w_dm_moneda,  
         @i_beneficiario       = @w_dm_beneficiario,
         @i_monto_mpg          = @w_dm_monto_mds,
         @i_monto_mop          = @w_dm_monto_mop,
         @i_monto_mn           = @w_dm_monto_mn,
         @i_cotizacion_mop     = @w_dm_cotizacion_mop,
         @i_tcotizacion_mop    = @w_dm_tcotizacion_mop,
         @i_cotizacion_mpg     = @w_dm_cotizacion_mds,
         @i_tcotizacion_mpg    = @w_dm_tcotizacion_mds,
         @i_operacion_renovada = 0,
         @i_alt                = @w_operacion,
         @i_sec_tran_cca       = @w_secuencial, -- FCP Interfaz Ahorros
         @o_num_renovacion     = @w_num_renovacion out
         
         if @w_error <> 0
         begin
            select @w_error = @w_error
            goto ERROR
         end
      end
      
   fetch cursor_desembolso
   into  @w_dm_desembolso,   @w_dm_producto,       @w_dm_cuenta,
         @w_dm_beneficiario, @w_dm_monto_mds,
         @w_dm_moneda,       @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
         @w_dm_monto_mn,     @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
         @w_dm_monto_mop
end

close cursor_desembolso
deallocate cursor_desembolso
    
--FIN GENERACION TRANSACCION

-- AFECTACION A LA LINEA EN CREDITO
if @w_lin_credito is not null
begin
   exec @w_error = cob_credito..sp_utilizacion
        @s_ofi         = @s_ofi,
        @s_ssn         = @s_ssn,
        @s_sesn        = @s_sesn,
        @s_user        = @s_user,
        @s_term        = @s_term,
        @s_date        = @s_date,
        @s_srv         = @s_srv,
        @s_lsrv        = @s_lsrv,
        @s_rol         = @s_rol,
        @s_org         = @s_org,
        @t_trn         = 21888,
        @i_linea_banco = @w_lin_credito,
        @i_producto    = 'CCA',
        @i_toperacion  = @w_toperacion,
        @i_tipo        = 'D',
        @i_moneda      = @w_moneda,
        @i_monto       = @w_monto_des,
        @i_cliente     = @w_cliente,
        @i_secuencial  = @w_secuencial,
        @i_tramite     = @w_tramite,
        @i_opcion      = 'A', --Activa
        @i_opecca      = @w_operacion,
        @i_fecha_valor = @i_fecha_uso,
        @i_modo        = 0,
        @i_monto_cex   = 0,
        @i_numoper_cex = ''

   if @@error <> 0 or @@trancount = 0
   begin
      select @w_error = 710522
      goto ERROR
   end
end

---MARCAR EL DESEMBOLSO COMO APLICADO
update ca_desembolso 
set    dm_estado          = 'A'
where  dm_secuencial = @w_secuencial
and    dm_operacion  = @w_operacion

if @@error <> 0
begin
   select @w_error = 710522
   goto ERROR
end


exec @w_return = sp_borrar_tmp_int
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_sesn            = @s_sesn,
   @i_banco           = @w_banco_tmp

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end 

COMMIT TRAN

return 0

ERROR:

exec cobis..sp_cerror
     @t_debug   = 'N',
     @t_file    = null,
     @t_from    = @w_sp_name,
     @i_num     = @w_error
     --@i_cuenta  = @i_operacion_linea
   
   return @w_error

go

