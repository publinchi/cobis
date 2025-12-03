/************************************************************************/
/*Archivo            :     imptabvr.sp                                  */
/*Stored procedure   :     sp_imp_tabla_amort_var                       */
/*Base de datos      :     cob_cartera                                  */
/*Producto           :     Cartera                                      */
/*Disenado por       :     Ramiro Buitron (GrupoCONTEXT)                */
/*Fecha de escritura :    08/Jun/1999                                   */
/************************************************************************/
/*                IMPORTANTE                                            */
/*Este programa es parte de los paquetes bancarios propiedad de         */
/*"MACOSA".                                                             */
/*Su uso no autorizado queda expresamente prohibido asi como            */
/*cualquier alteracion o agregado hecho por alguno de sus               */
/*usuarios sin el debido consentimiento por escrito de la               */
/*Presidencia Ejecutiva de MACOSA o su representante.                   */
/************************************************************************/  
/*                 PROPOSITO                                            */
/*Consulta para imprimir la tabla de amortizacion con interes           */
/*acumulado                                                             */
/************************************************************************/
/*                MODIFICACIONES                                        */
/*       FECHA           AUTOR                 MODIFICACION             */
/*       Ene-2005        ElciraPelaez         Actualizacion para el BAC */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_imp_tabla_amort_var')
   drop proc sp_imp_tabla_amort_var
go

create proc sp_imp_tabla_amort_var (
   @s_ssn                 int         = null,
   @s_date                datetime    = null,
   @s_user                login       = null,
   @s_term                descripcion = null,
   @s_corr                char(1)     = null,
   @s_ssn_corr            int         = null,
   @s_ofi                 smallint    = null,
   @t_rty                 char(1)     = null,
   @t_debug               char(1)     = 'N',
   @t_file                varchar(14) = null,
   @t_trn                 smallint    = null,  
   @i_operacion           char(1)     = null,
   @i_banco               cuenta      = null,
   @i_formato_fecha       int         = null,
   @i_dividendo           int         = null,
   @i_cliente             int         = null,-- LAM
   @i_ext_enlinea         char(1)     = 'N'  -- JAR REQ 175
)
as
declare @w_sp_name                      varchar(32),
        @w_return                       int,
        @w_error                        int,
        @w_operacionca                  int,
        @w_tamanio                      int,
        @w_tipo                         char(1),
        @w_det_producto                 int,
        @w_cliente                      int,
        @w_nombre                       varchar(60),
        @w_direccion                    varchar(100),
        @w_ced_ruc                      varchar(15),
        @w_telefono                     varchar(15),  
        @w_toperacion_desc              varchar(100),
        @w_moneda                       tinyint,
        @w_moneda_desc                  varchar(30),
        @w_monto                        money,
        @w_plazo                        smallint,
        @w_tplazo                       varchar(30),
        @w_tipo_amortizacion            varchar(10),
        @w_tdividendo                   varchar(30),
        @w_periodo_cap                  smallint,
        @w_periodo_int                  smallint,
        @w_gracia                       smallint,
        @w_gracia_cap                   smallint,
        @w_gracia_int                   smallint,
        @w_cuota                        money,
        @w_tasa                         float,
        @w_mes_gracia                   tinyint,
        @w_rejustable                   char(1),
        @w_existe_interes               char(1),
        @w_periodo_reaj                 int,
        @w_primer_des                   int,
        @w_tasa_ef_anual                float,
        @w_periodicidad_o               char(1),
        @w_modalidad_o                  char(1),
        @w_fecha_fin                    varchar(10), 
        @w_dias_anio                    int,
        @w_base_calculo                 char(1),
        @w_tasa_referencial             varchar(12), 
        @w_signo_spread                 char(1),
        @w_valor_spread                 float,
        @w_modalidad                    char(1),
        @w_valor_referencial            float,
        @w_sector                       char(1),
        @w_dividendos                   tinyint,
        @w_num_cuotas                   smallint,
        @w_fecha_liq                    varchar(10),
        @w_dia_fijo                     int,
        @w_fecha_pri_cuot               varchar(10),
        @w_recalcular_plazo             char(1),
        @w_evitar_feriados              char(1),
        @w_ult_dia_habil                char(1),
        @w_tasa_equivalente             char(1),
        @w_tipo_puntos                  char(1),
        @w_ref_exterior                 cuenta,
        @w_fec_embarque                 varchar(15),
        @w_fec_dex                      varchar(15),
        @w_num_deuda_ext                cuenta,
        @w_num_comex                    cuenta,
        @w_descripcion_actividad        descripcion,--LAM
        @w_en_concurso_acreedores       catalogo,--LAM
        @w_lugar_doc                    int,--LAM
        @w_ciudad_doc                   descripcion,--LAM
        @w_en_actividad                 catalogo,
        @w_ciudad                       int,
        @w_oficina                      smallint,
        @w_en_situacion_cliente         catalogo,
        @w_en_activo                    money,
        @w_nom_ciudad                   varchar(100),  -- JAR REQ 175
        @w_nom_oficina                  descripcion,
        @w_op_direccion                 tinyint,
        @w_cod_ciudad                   int,
        @w_rowcount                     int,
        @w_dir                          int,           -- JAR REQ 175
        @w_dir_super_bancaria           varchar(100)   -- JAR REQ 175

-- Captura nombre de Stored Procedure  
select @w_sp_name = 'sp_imp_tabla_amort_var'

-- CABECERA DE LA IMPRESION  EN TABLAS DEFINITIVAS
if @i_operacion = 'C'
begin
   select 
   @w_operacionca       = op_operacion ,
   @w_cliente           = op_cliente, 
   @w_toperacion_desc   = A.valor,
   @w_moneda            = op_moneda,
   @w_moneda_desc       = mo_descripcion,
   @w_monto             = op_monto,
   @w_plazo             = op_plazo,
   @w_tplazo            = op_tplazo,
   @w_tipo_amortizacion = op_tipo_amortizacion,
   @w_tdividendo        = op_tdividendo,
   @w_periodo_cap       = op_periodo_cap,
   @w_periodo_int       = op_periodo_int,
   @w_gracia            = isnull(di_gracia,0),
   @w_gracia_cap        = op_gracia_cap,
   @w_gracia_int        = op_gracia_int,
   @w_cuota             = op_cuota,
   @w_mes_gracia        = op_mes_gracia,
   @w_rejustable        = op_reajustable,
   @w_periodo_reaj      = isnull(op_periodo_reajuste,0),
   @w_fecha_fin         = convert(varchar(10),op_fecha_liq,@i_formato_fecha),
   @w_dias_anio         = op_dias_anio,
   @w_base_calculo      = op_base_calculo,
   @w_sector            = op_sector,
   @w_fecha_liq = convert(varchar(10),op_fecha_liq,@i_formato_fecha),
   @w_dia_fijo          = op_dia_fijo,
   @w_fecha_pri_cuot    = convert(varchar(10),op_fecha_pri_cuot,@i_formato_fecha),
   @w_recalcular_plazo  = op_recalcular_plazo,
   @w_evitar_feriados   = op_evitar_feriados,
   @w_ult_dia_habil     = op_dia_habil,
   @w_tasa_equivalente  = op_usar_tequivalente,
   @w_ref_exterior      = op_ref_exterior,
   @w_fec_embarque      = substring(convert(varchar,op_fecha_embarque,@i_formato_fecha),1,15),
   @w_fec_dex           = substring(convert(varchar,op_fecha_dex,@i_formato_fecha),1,15),
   @w_num_deuda_ext     = op_num_deuda_ext,
   @w_num_comex         = op_num_comex,
   @w_op_direccion      = op_direccion

   from ca_operacion
               inner join cobis..cl_catalogo A on
               op_banco    = @i_banco
               and op_toperacion = A.codigo
                    inner join cobis..cl_moneda on
                        op_moneda     = mo_moneda
                       left outer join ca_dividendo on  
                        op_operacion = di_operacion 
                        and di_estado = 1

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end  

   select @w_tplazo   = td_descripcion 
   from ca_tdividendo
   where td_tdividendo = @w_tplazo

   select @w_tdividendo= td_descripcion 
   from ca_tdividendo
   where td_tdividendo = @w_tdividendo

   select @w_tasa = isnull(sum(ro_porcentaje),0)
   from ca_rubro_op
   where ro_operacion  =  @w_operacionca
   and   ro_tipo_rubro =  'I'
   and   ro_fpago      in ('P','A')

   select @w_tasa_referencial = ro_referencial,  
   @w_signo_spread = ro_signo,       
   @w_valor_spread = ro_factor,              
   @w_modalidad    = ro_fpago,       
   @w_valor_referencial = ro_porcentaje_aux, 
   @w_tipo_puntos = ro_tipo_puntos
   from ca_rubro_op
   where ro_operacion  =  @w_operacionca
   and   ro_tipo_rubro =  'I'
   and   ro_fpago      in ('P','A')

   select @w_tasa_referencial = vd_referencia from ca_valor_det
   where vd_tipo = @w_tasa_referencial
     and vd_sector = @w_sector

   if exists ( select ro_operacion from ca_rubro_op 
      where ro_operacion = @w_operacionca
      and ro_tipo_rubro  = 'I' )  Begin
      select @w_existe_interes = 'S'
   end
   else 
      Begin
        select @w_existe_interes = 'N'      
      end
   
   --DEUDOR
   --  Encuentra el Producto  
       
   select @w_tipo = pd_tipo
   from cobis..cl_producto
   where pd_producto = 7
   set transaction isolation level read uncommitted

   --  Encuentra el Detalle de Producto  

   select 
   @w_det_producto = dp_det_producto
   from cobis..cl_det_producto
   where dp_producto = 7
   and dp_tipo   = @w_tipo
   and dp_moneda = @w_moneda
   and dp_cuenta = @i_banco
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 
   begin
      select @w_error = 710023
      goto ERROR
   end

   -- Realizar la consulta de Informacion General de Cliente

   select 
   @w_ced_ruc  = isnull(cl_ced_ruc,p_pasaporte), 
   @w_nombre   = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' 
                 + rtrim(en_nombre),1,60)),
   @w_telefono  = isnull(te_valor,''),
   @w_direccion = isnull(di_descripcion,'')
   from  cobis..cl_cliente
            inner join cobis..cl_ente on 
                cl_det_producto   = @w_det_producto
                and cl_rol        = 'D'
                and en_ente       = cl_cliente                                         
                and cl_cliente    = @w_cliente
                left outer join cobis..cl_telefono on 
                     te_ente = en_ente
                     left outer join cobis..cl_direccion on
                         di_ente = cl_cliente
                         where te_direccion  = @w_op_direccion
                         and di_direccion  = @w_op_direccion 
                 set transaction isolation level read uncommitted

   exec @w_return = sp_control_tasa
   @i_operacionca = @w_operacionca,
   @i_temporales  = 'N',
   @i_ibc         = 'N',
   @o_tasa_total_efe = @w_tasa_ef_anual  output

   if @w_return != 0 return @w_return

   ---  RBU Fecha de desembolso de la operacion 
   select @w_fecha_liq = convert(varchar(10),op_fecha_liq,@i_formato_fecha) 
   from ca_operacion where op_operacion = @w_operacionca


   select
   @w_cliente,    @w_nombre ,           @w_ced_ruc,
   @w_direccion,  @w_telefono,          @w_toperacion_desc, 
   @w_monto,      @w_moneda_desc,       @w_plazo, 
   @w_tplazo,     @w_tipo_amortizacion, @w_tdividendo,
   @w_tasa,       @w_periodo_cap,       @w_periodo_int, 
   @w_mes_gracia, @w_gracia,            @w_gracia_cap, 
   @w_gracia_int,   @w_tasa_ef_anual,     @w_fecha_fin,
   @w_dias_anio , @w_base_calculo,      @w_tasa_referencial,
   @w_valor_referencial,@w_valor_spread,      @w_signo_spread,
   @w_modalidad, @w_rejustable,       @w_existe_interes,
   @w_fecha_liq,        @w_dia_fijo,      @w_fecha_pri_cuot,
   @w_recalcular_plazo, @w_evitar_feriados,   @w_ult_dia_habil,
   @w_tasa_equivalente, @w_tipo_puntos,       @w_ref_exterior,
   @w_fec_embarque,     @w_fec_dex,           @w_num_deuda_ext,
   @w_num_comex

end

-- DETALLE DE LA TABLA DE AMORTIZACION EN TABLAS DEFINITIVAS 

if @i_operacion = 'D' 
begin 
   --- CHEQUEO QUE EXISTA LA OPERACION 

   select 
   @w_operacionca  = op_operacion,
   @w_rejustable   = op_reajustable,
   @w_periodo_reaj = op_periodo_reajuste,
   @w_periodo_int  = op_periodo_int

   from ca_operacion
   where op_banco = @i_banco

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end  

   if @w_periodo_reaj = 0 Begin
      select @w_num_cuotas = 1
   end
   else Begin
      if @w_periodo_int = 0 Begin
         select @w_num_cuotas = 0
      end
      else Begin
         select @w_num_cuotas = floor(@w_periodo_reaj/@w_periodo_int)
      end
   end
             
   select @w_tamanio = round(2500/(6 + 6 + 6 + 6 +10+10+20),0) -1

   select @w_dividendos = count(*)
   from   ca_dividendo
   where  di_operacion  = @w_operacionca

   -- TABLA DE AMORTIZACION 
   -- CAPITAL 

   set rowcount @w_tamanio
   
   select am_dividendo,convert(float,sum(am_cuota + am_gracia))
   from ca_amortizacion,ca_rubro_op 
   where 
   ro_operacion      = @w_operacionca
   and am_operacion  = ro_operacion
   and am_concepto   = ro_concepto
   and ro_tipo_rubro = 'C'
 and am_dividendo  < @i_dividendo
   group by am_dividendo
   order by am_dividendo desc 

   -- INTERES 

   set rowcount @w_tamanio

   if exists ( select ro_operacion from ca_rubro_op
      where ro_operacion = @w_operacionca
      and ro_tipo_rubro  = 'I' ) Begin
      if @w_rejustable = 'S' Begin /* operacion reajustable */  --LALG 25/09/2001 se agrego am_concepto
         if @w_periodo_reaj = 0 Begin /* periodo de reajuste indefinido */
            if (@w_dividendos <= @w_tamanio) or (@i_dividendo  <= @w_tamanio) Begin
               select am_dividendo,0,convert(float,sum(am_cuota + am_gracia)),am_concepto 
          from ca_amortizacion,ca_rubro_op 
       where ro_operacion = @w_operacionca
       and am_operacion   = ro_operacion
       and am_concepto    = ro_concepto
       and ro_tipo_rubro  = 'I'
       and am_dividendo   > 1
       and am_dividendo   < @i_dividendo
       group by am_dividendo,am_concepto 
               union
               select am_dividendo,convert(float,sum(am_cuota + am_gracia)),
               convert(float,sum(am_cuota + am_gracia)),am_concepto
               from ca_amortizacion,ca_rubro_op 
       where ro_operacion = @w_operacionca
       and am_operacion   = ro_operacion
       and am_concepto    = ro_concepto
       and ro_tipo_rubro  = 'I'
               and am_dividendo   = 1
       group by am_dividendo, am_concepto
       order by am_dividendo desc
            end    
            else Begin
               select am_dividendo,0,convert(float,sum(am_cuota + am_gracia)), am_concepto
          from ca_amortizacion,ca_rubro_op 
       where ro_operacion = @w_operacionca
       and am_operacion   = ro_operacion
       and am_concepto    = ro_concepto
       and ro_tipo_rubro  = 'I'
       and am_dividendo   > 1
       and am_dividendo   < @i_dividendo
       group by am_dividendo,am_concepto
               order by am_dividendo desc
            end
         end
         else Begin /* periodo de reajuste definido */   
            if (@w_dividendos <= @w_tamanio) or (@i_dividendo <= @w_tamanio) Begin
               select am_dividendo,0,convert(float,sum(am_cuota + am_gracia)), am_concepto
       from ca_amortizacion,ca_rubro_op 
               where ro_operacion = @w_operacionca
       and am_operacion   = ro_operacion
       and am_concepto    = ro_concepto
               and ro_tipo_rubro  = 'I'
       and am_dividendo   > @w_num_cuotas
       and am_dividendo   < @i_dividendo
               group by am_dividendo, am_concepto
       union
               select am_dividendo,convert(float,sum(am_cuota + am_gracia)),
               convert(float,sum(am_cuota + am_gracia)), am_concepto
       from ca_amortizacion,ca_rubro_op 
          where ro_operacion = @w_operacionca
       and am_operacion   = ro_operacion
       and am_concepto    = ro_concepto
       and ro_tipo_rubro  = 'I'
       and am_dividendo   >= 1
       and am_dividendo   <= @w_num_cuotas
       group by am_dividendo, am_concepto
       order by am_dividendo desc
            end
            else Begin
            select am_dividendo,0,convert(float,sum(am_cuota + am_gracia)),am_concepto
       from ca_amortizacion,ca_rubro_op 
               where ro_operacion = @w_operacionca
       and am_operacion   = ro_operacion
       and am_concepto    = ro_concepto
       and ro_tipo_rubro  = 'I'
       and am_dividendo   > @w_num_cuotas
       and am_dividendo   < @i_dividendo
       group by am_dividendo, am_concepto
       order by am_dividendo desc
            end
         end
      end
      else Begin   /* operacion no reajustable */
         select am_dividendo,convert(float,sum(am_cuota + am_gracia)),
         convert(float,sum(am_cuota + am_gracia)),am_concepto
         from ca_amortizacion,ca_rubro_op 
         where ro_operacion = @w_operacionca
 and am_operacion   = ro_operacion
         and am_concepto    = ro_concepto
 and ro_tipo_rubro  = 'I'
 and am_dividendo   < @i_dividendo
 group by am_dividendo, am_concepto
 order by am_dividendo desc
      end
   end
   else Begin /* no existe rubro tipo interes */
      select am_dividendo,0,0,am_concepto  --Serß CAP
      from ca_amortizacion,ca_rubro_op 
      where ro_operacion = @w_operacionca
      and am_operacion   = ro_operacion
      and am_concepto    = ro_concepto
      and ro_tipo_rubro  = 'C'
      and am_dividendo   < @i_dividendo
      group by am_dividendo, am_concepto
      order by am_dividendo desc
   end

   /* OTROS */

   set rowcount @w_tamanio

   select am_dividendo,convert(float,sum(am_cuota + am_gracia))
   from ca_amortizacion,ca_rubro_op 
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   < @i_dividendo
   group by am_dividendo
   order by am_dividendo desc

   -- ABONO 

   set rowcount @w_tamanio

   select  am_dividendo,convert(float,sum(am_pagado))
   from ca_amortizacion,ca_rubro_op 
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and am_dividendo   < @i_dividendo
   group by am_dividendo
   order by am_dividendo desc

   -- DESEMBOLSOS Y REESTRUCTURACIONES 

   set rowcount @w_tamanio

   select @w_primer_des = min(dm_secuencial)
   from   ca_desembolso
   where  dm_operacion  = @w_operacionca

   select dtr_dividendo, convert(float,sum(dtr_monto))
   from   ca_det_trn, ca_transaccion, ca_rubro_op
   where  tr_banco        =  @i_banco
   and    tr_secuencial   =  dtr_secuencial
   and    tr_operacion   =  dtr_operacion
   and    dtr_secuencial  <> @w_primer_des
   and    ro_operacion    =  tr_operacion
   and    ro_operacion    =  dtr_operacion
   and    ro_tipo_rubro   =  'C'
   and    tr_tran         in ('DES', 'RES')
   and    tr_estado       in ('ING','CON')
   and    ro_concepto     =  dtr_concepto 
   and    dtr_dividendo   <  @i_dividendo
   group by dtr_dividendo
   order by dtr_dividendo desc
      

   -- FECHAS DE PAGO Y ESTADO 
   set rowcount @w_tamanio

   select 
   convert(varchar(10),di_fecha_ven,@i_formato_fecha),
   es_descripcion,
   di_dias_cuota         
   from ca_dividendo,ca_estado
   where 
   di_operacion     = @w_operacionca
   and di_estado    = es_codigo
   and di_dividendo < @i_dividendo
   --order by di_fecha_ven desc
   order by di_dividendo desc
   
   select @w_return = @@rowcount

   if @w_return = 0
   begin
      select 9999 
      select @w_error = 710026
      goto ERROR
   end
   else
   begin
      select @w_tamanio - @w_return     
   end

end


-- CABECERA DE LA IMPRESION  EN TABLAS TEMPORALES EN SIMULACIONS
if @i_operacion = 'Z'
begin
   select 
   @w_operacionca       = opt_operacion ,
   @w_cliente           = opt_cliente, 
   @w_toperacion_desc   = A.valor,
   @w_moneda            = opt_moneda,
   @w_moneda_desc       = mo_descripcion,
   @w_monto             = opt_monto,
   @w_plazo             = opt_plazo,
   @w_tplazo            = opt_tplazo,
   @w_tipo_amortizacion = opt_tipo_amortizacion,
   @w_tdividendo        = opt_tdividendo,
   @w_periodo_cap       = opt_periodo_cap,
   @w_periodo_int       = opt_periodo_int,
   @w_gracia            = isnull(dit_gracia,0),
   @w_gracia_cap        = opt_gracia_cap,
   @w_gracia_int        = opt_gracia_int,
   @w_cuota             = opt_cuota,
   @w_mes_gracia        = opt_mes_gracia,
   @w_rejustable        = opt_reajustable,
   @w_periodo_reaj      = isnull(opt_periodo_reajuste,0),
   @w_fecha_fin         = convert(varchar(10),opt_fecha_fin,@i_formato_fecha),
   @w_dias_anio         = opt_dias_anio,
   @w_base_calculo      = opt_base_calculo,
   @w_sector            = opt_sector,
   @w_fecha_liq = convert(varchar(10),opt_fecha_liq,@i_formato_fecha),
   @w_dia_fijo       = opt_dia_fijo,
   @w_fecha_pri_cuot    = convert(varchar(10),opt_fecha_pri_cuot,@i_formato_fecha),
   @w_recalcular_plazo  = opt_recalcular_plazo,
   @w_evitar_feriados   = opt_evitar_feriados,
   @w_ult_dia_habil     = opt_dia_habil,
   @w_tasa_equivalente  = opt_usar_tequivalente
   from ca_operacion_tmp
             inner join cobis..cl_catalogo A on
               opt_banco    = @i_banco
               and opt_toperacion = A.codigo
                    inner join cobis..cl_moneda on
                    opt_moneda     = mo_moneda
                        left outer join ca_dividendo_tmp on
                        opt_operacion = dit_operacion  
                           and dit_estado = 1   

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end  

   select @w_tplazo   = td_descripcion 
   from ca_tdividendo
   where td_tdividendo = @w_tplazo

   select @w_tdividendo= td_descripcion 
   from ca_tdividendo
   where td_tdividendo = @w_tdividendo

   select @w_tasa_referencial = rot_referencial,
          @w_signo_spread = rot_signo,
          @w_valor_spread = rot_factor,
          @w_modalidad    = rot_fpago,
          @w_valor_referencial = rot_porcentaje_aux,
          @w_tasa              = rot_porcentaje 
   from ca_rubro_op_tmp
   where rot_operacion  = @w_operacionca
   and   rot_tipo_rubro = 'I'
   and   rot_fpago in ('P','A')

   select @w_tasa_referencial = vd_referencia from ca_valor_det
   where vd_tipo = @w_tasa_referencial
   and vd_sector = @w_sector

   if exists ( select rot_operacion from ca_rubro_op_tmp
      where rot_operacion = @w_operacionca
      and rot_tipo_rubro  = 'I' )  Begin
      select @w_existe_interes = 'S'
   end
   else Begin
      select @w_existe_interes = 'N'      
   end


   exec @w_return = sp_control_tasa
   @i_operacionca = @w_operacionca,
   @i_temporales  = 'S',
   @i_ibc         = 'N',
   @o_tasa_total_efe = @w_tasa_ef_anual  output

   if @w_return != 0 return @w_return

   select
   @w_cliente,    @w_nombre ,           @w_ced_ruc,
   @w_direccion,  @w_telefono,          @w_toperacion_desc, 
   @w_monto,      @w_moneda_desc,       @w_plazo, 
   @w_tplazo,     @w_tipo_amortizacion, @w_tdividendo,
   @w_tasa,       @w_periodo_cap,       @w_periodo_int, 
   @w_mes_gracia, @w_gracia,            @w_gracia_cap, 
   @w_gracia_int, @w_tasa_ef_anual,     @w_fecha_fin,
   @w_dias_anio , @w_base_calculo,      @w_tasa_referencial,
   @w_valor_referencial, @w_valor_spread,@w_signo_spread,
   @w_modalidad, @w_rejustable, @w_existe_interes     ,
   @w_dia_fijo,
   @w_fecha_pri_cuot, @w_recalcular_plazo, @w_evitar_feriados,
   @w_ult_dia_habil, @w_tasa_equivalente

end


-- SIMULACION DE LA TABLA DE AMORTIZACION 
if @i_operacion = 'S' 
begin 
   -- CHEQUE DE EXISTA LA OPERACION 
   select 
   @w_operacionca  = opt_operacion,
   @w_rejustable   = opt_reajustable,
   @w_periodo_reaj = opt_periodo_reajuste,
   @w_periodo_int  = opt_periodo_int,
   @w_op_direccion = opt_direccion
   from ca_operacion_tmp
   where opt_banco = @i_banco

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end  

   if @w_periodo_reaj = 0 Begin
      select @w_num_cuotas = 1
   end
   else Begin
      if @w_periodo_int = 0 Begin
         select @w_num_cuotas = 0
      end
      else Begin
         select @w_num_cuotas = floor(@w_periodo_reaj/@w_periodo_int)
      end
   end
             
   select @w_tamanio = round(2500/(6 + 6 + 6 + 6 +10+20),0) -1

   select @w_dividendos = count(*)
   from   ca_dividendo_tmp
   where  dit_operacion  = @w_operacionca

   -- TABLA DE AMORTIZACION 
   -- CAPITAL 

   set rowcount @w_tamanio

   select amt_dividendo,convert(float,sum(amt_cuota + amt_gracia))
   from ca_amortizacion_tmp,ca_rubro_op_tmp 
   where 
   rot_operacion      = @w_operacionca
   and amt_operacion  = rot_operacion
   and amt_concepto   = rot_concepto
   and rot_tipo_rubro = 'C'
   and amt_dividendo  < @i_dividendo
   group by amt_dividendo
   order by amt_dividendo desc 
 
   -- INTERES 

   set rowcount @w_tamanio

   if @w_rejustable = 'S' Begin /* operacion reajustable */
      if @w_periodo_reaj = 0 Begin /* periodo de reajuste indefinido */
         if (@w_dividendos <= @w_tamanio) or (@i_dividendo  <= @w_tamanio) Begin
            select amt_dividendo,0,convert(float,sum(amt_cuota + amt_gracia))
            from ca_amortizacion_tmp,ca_rubro_op_tmp 
    where rot_operacion = @w_operacionca
    and amt_operacion   = rot_operacion
            and amt_concepto    = rot_concepto
            and rot_tipo_rubro  = 'I'
    and amt_dividendo   > 1
    and amt_dividendo   < @i_dividendo
    group by amt_dividendo
            union
            select amt_dividendo,convert(float,sum(amt_cuota + amt_gracia)),
    convert(float,sum(amt_cuota + amt_gracia))
            from ca_amortizacion_tmp,ca_rubro_op_tmp 
    where rot_operacion = @w_operacionca
    and amt_operacion   = rot_operacion
    and amt_concepto    = rot_concepto
    and rot_tipo_rubro  = 'I'
            and amt_dividendo   = 1
    group by amt_dividendo
            order by amt_dividendo desc 
         end    
         else Begin
            select amt_dividendo,0,convert(float,sum(amt_cuota + amt_gracia))
       from ca_amortizacion_tmp,ca_rubro_op_tmp 
    where rot_operacion = @w_operacionca
    and amt_operacion   = rot_operacion
    and amt_concepto    = rot_concepto
    and rot_tipo_rubro  = 'I'
    and amt_dividendo   > 1
    and amt_dividendo   < @i_dividendo
    group by amt_dividendo
            order by amt_dividendo desc 
         end
      end
      else Begin /* periodo de reajuste definido */   
         if (@w_dividendos <= @w_tamanio) or (@i_dividendo  <= @w_tamanio) Begin
            select amt_dividendo,0,convert(float,sum(amt_cuota + amt_gracia))
            from ca_amortizacion_tmp,ca_rubro_op_tmp 
            where rot_operacion = @w_operacionca
    and amt_operacion   = rot_operacion
    and amt_concepto    = rot_concepto
            and rot_tipo_rubro  = 'I'
    and amt_dividendo   > @w_num_cuotas
    and amt_dividendo   < @i_dividendo
    group by amt_dividendo
            union
            select amt_dividendo,convert(float,sum(amt_cuota + amt_gracia)),
    convert(float,sum(amt_cuota + amt_gracia))
    from ca_amortizacion_tmp,ca_rubro_op_tmp 
       where rot_operacion = @w_operacionca
    and amt_operacion   = rot_operacion
    and amt_concepto    = rot_concepto
    and rot_tipo_rubro  = 'I'
    and amt_dividendo   >= 1
    and amt_dividendo   <= @w_num_cuotas
    group by amt_dividendo
            order by amt_dividendo desc 
         end
         else Begin
         select amt_dividendo,0,convert(float,sum(amt_cuota + amt_gracia))
    from ca_amortizacion_tmp,ca_rubro_op_tmp 
            where rot_operacion = @w_operacionca
    and amt_operacion   = rot_operacion
    and amt_concepto    = rot_concepto
    and rot_tipo_rubro  = 'I'
    and amt_dividendo   > @w_num_cuotas
    and amt_dividendo   < @i_dividendo
            group by amt_dividendo
            order by amt_dividendo desc 
         end
      end
   end
   else Begin  -- operacion no reajustable 

   select amt_dividendo,convert(float,sum(amt_cuota + amt_gracia)),
   convert(float,sum(amt_cuota + amt_gracia))
   from ca_amortizacion_tmp,ca_rubro_op_tmp 
   where rot_operacion = @w_operacionca
   and amt_operacion   = rot_operacion
   and amt_concepto    = rot_concepto
   and rot_tipo_rubro  = 'I'
   and amt_dividendo   < @i_dividendo
   group by amt_dividendo
   order by amt_dividendo desc 
   end

   -- OTROS 

   set rowcount @w_tamanio

   select amt_dividendo,convert(float,sum(amt_cuota + amt_gracia))
   from ca_amortizacion_tmp,ca_rubro_op_tmp 
   where rot_operacion = @w_operacionca
   and amt_operacion   = rot_operacion
   and amt_concepto    = rot_concepto
   and rot_tipo_rubro  not in ('C', 'I')
   and amt_dividendo   < @i_dividendo
   group by amt_dividendo
   order by amt_dividendo desc 

   -- ABONO 

   set rowcount @w_tamanio

   select  amt_dividendo,convert(float,sum(amt_pagado))
   from ca_amortizacion_tmp,ca_rubro_op_tmp
   where rot_operacion = @w_operacionca
   and amt_operacion   = rot_operacion
   and amt_concepto    = rot_concepto
   and amt_dividendo   < @i_dividendo
   group by amt_dividendo
   order by amt_dividendo desc 

   --- FECHAS DE PAGO Y ESTADO 
   set rowcount @w_tamanio

   select  
   convert(varchar(10),dit_fecha_ven,@i_formato_fecha),
   es_descripcion,
   dit_dias_cuota
   from ca_dividendo_tmp,ca_estado
   where 
   dit_operacion     = @w_operacionca
   and dit_estado    = es_codigo
   and dit_dividendo < @i_dividendo
   --order by dit_fecha_ven desc 
   order by dit_dividendo desc

   select @w_return = @@rowcount
   if @w_return = 0
   begin
      select 9999 
      select @w_error = 710026
      goto ERROR
   end
   else
   begin
      select @w_tamanio - @w_return     
   end
end



if @i_operacion = 'E' 
begin
   --La direccion se busca en cartera
   set rowcount 1
   select @w_op_direccion = op_direccion,
          @w_oficina      = op_oficina
   from cob_cartera..ca_operacion
   where op_cliente = @i_cliente
   set rowcount 0
   
   if @w_op_direccion is null  or @w_op_direccion <= 0
   begin
      select @w_op_direccion = en_direccion
      from  cobis..cl_ente
      where en_ente = @i_cliente
      set transaction isolation level read uncommitted
   end

   if @w_oficina is null
   begin
      select @w_oficina = en_oficina
      from  cobis..cl_ente
      where en_ente = @i_cliente
      set transaction isolation level read uncommitted
   end

   select @w_ciudad = of_ciudad, 
          @w_nom_oficina = of_nombre
   from  cobis..cl_oficina
   where of_oficina = @w_oficina
   set transaction isolation level read uncommitted
   
   set rowcount 1
   select @w_ced_ruc   = isnull(cl_ced_ruc,p_pasaporte), 
          @w_nombre    = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre),1,60)),
          @w_telefono  = isnull(te_valor,''),
          @w_direccion = isnull(di_descripcion,''),
          @w_en_concurso_acreedores = en_concurso_acreedores,
          @w_en_actividad = en_actividad,
          @w_lugar_doc = p_lugar_doc,
          @w_en_activo = c_activo,
          @w_en_situacion_cliente = en_situacion_cliente,
          @w_cod_ciudad  = di_ciudad
   from  cobis..cl_cliente
            inner join cobis..cl_ente on
                  en_ente          = cl_cliente                                         
                  and   cl_cliente       = @i_cliente
                  inner join cobis..cl_det_producto on                  
                    cl_det_producto  = dp_det_producto
                    left outer join cobis..cl_telefono on
                         te_ente = en_ente
                         left outer join cobis..cl_direccion on
                              di_ente = cl_cliente    
                              where te_direccion = @w_op_direccion
                              and di_direccion = @w_op_direccion
      set transaction isolation level read uncommitted
   set rowcount 0


   select @w_nom_ciudad = ci_descripcion
   from  cobis..cl_ciudad 
   where ci_ciudad = @w_cod_ciudad
   set transaction isolation level read uncommitted
  
    
  if  @w_ced_ruc is null
  begin
      select @w_ced_ruc =  en_ced_ruc,
             @w_nombre  =  ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre),1,60)),
             @w_en_concurso_acreedores = en_concurso_acreedores,
             @w_en_actividad = en_actividad,
             @w_lugar_doc = p_lugar_doc,
             @w_en_activo = c_activo,
             @w_en_situacion_cliente = en_situacion_cliente
      from cobis..cl_ente
      where en_ente =   @i_cliente     
      
      select @w_direccion = isnull(di_descripcion,'')
      from cobis..cl_direccion
      where di_ente =  @i_cliente
      and   di_direccion = 1

      select  @w_telefono  = isnull(te_valor,'')
      from cobis..cl_telefono
      where te_ente =  @i_cliente
      and te_direccion = 1
            
  end
  
   select @w_ciudad_doc = ci_descripcion
   from  cobis..cl_ciudad
   where ci_ciudad =  @w_lugar_doc
   set transaction isolation level read uncommitted


   select @w_descripcion_actividad =  ''
   select @w_descripcion_actividad = valor 
   from cobis..cl_catalogo
   where tabla  = (select codigo from cobis..cl_tabla where tabla = 'cl_actividad')
   and   codigo = @w_en_actividad
   set transaction isolation level read uncommitted

   if @w_en_concurso_acreedores is Null
      select @w_en_concurso_acreedores = 'No'
      
   -- INI JAR REQ 175 
   if @i_ext_enlinea = 'S'
   begin
      select top 1
             @w_dir       = di_direccion,
             @w_direccion = di_descripcion,
             @w_ciudad    = di_ciudad
        from cobis..cl_direccion
       where di_ente      = @i_cliente
         and di_principal = 'S'       
      set transaction isolation level read uncommitted
      
      select @w_nom_ciudad = ltrim(rtrim(ci_descripcion)) + ' ' + ltrim(rtrim(pv_descripcion))
        from cobis..cl_ciudad, cobis..cl_provincia
       where ci_ciudad    = @w_ciudad
         and ci_provincia = pv_provincia
         
      select @w_telefono  = isnull(te_valor,'')
        from cobis..cl_telefono
       where te_ente      =  @i_cliente
         and te_direccion = @w_dir
         
      select @w_dir_super_bancaria = pa_char
        from cobis..cl_parametro
       where pa_nemonico = 'DIRSBA'
         and pa_producto = 'CCA'
   end
   
   ---Envio datos al Front-end
   if @i_ext_enlinea <> 'S'
   begin
      select 
      @w_ciudad,
      @w_oficina,
      @w_nombre,
      @w_ced_ruc,
      @w_direccion,
      @w_telefono,
      @w_en_activo,
      @w_en_concurso_acreedores,
      @w_en_actividad,
      @w_descripcion_actividad,  --10
      @w_en_situacion_cliente,
      @w_ciudad_doc,
      @w_nom_ciudad,
      @w_nom_oficina
   end
   else
   begin
      select 
      @w_ciudad,
      @w_oficina,
      @w_nombre,
      @w_ced_ruc,
      @w_direccion,
      @w_telefono,
      @w_en_activo,
      @w_en_concurso_acreedores,
      @w_en_actividad,
      @w_descripcion_actividad,  --10
      @w_en_situacion_cliente,
      @w_ciudad_doc,
      @w_nom_ciudad,
      @w_nom_oficina,
      @w_dir_super_bancaria
   end
   
   -- FIN JAR REQ 175
end 


return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error
go






