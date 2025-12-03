/************************************************************************/
/*   Archivo:            ca_seguros.sp                                  */
/*   Stored procedure:   sp_seguros                                     */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       Ricardo Reyes                                  */
/*   Fecha de escritura: Jul. 2013                                      */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                          PROPOSITO                                   */
/*      Procedimiento  que distribuye el valor de la cuota del seguro   */
/*      en el sistema frances                                           */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA           AUTOR      RAZON                                    */
/*  julio-10-2013   Luis Guzman  Emision Inicial                        */
/*  Ene-07-2014     Luis Guzman   CCA 409 Interes de Mora               */
/*  Jun-22-2015     Elcira Pelaez Homologacion 397-406-409-2-424 con    */
/*                  PRODUCCION                                          */
/*  Sep-22-2015     Elcira Pelaez Optimizacion                          */
/*  Jun-01-2022     Guisela Fernandez    Se comenta prints              */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_seguros')
   drop proc sp_seguros
go
--- NR.397-406-409-424
create proc sp_seguros
   @s_ssn                   int         = null,
   @s_sesn                  int         = null,
   @s_date                  datetime    = null,
   @s_ofi                   smallint    = null,
   @s_user                  login       = null,
   @s_rol                   smallint    = null,
   @s_term                  varchar(30) = null,
   @s_srv                   varchar(30) = null,
   @s_lsrv                  varchar(30) = null,
   @i_tramite               int         = null,
   @i_banco                 cuenta      = null,   -- Se envia desde la pantalla datos operacion de CCA
   @i_opcion                char(1)           ,
   @i_sec_seguro            int         = null,
   @i_sec_renovacion        int         = null,
   @i_secuencial_pago       int         = null,
   @i_secuencial_ing        int         = null,
   @i_liquida               char(1)     = 'N',    -- Solo llega en S cuando se le da transmitir al desembolso de lo contrario todo se hace en TMP
   @i_extraordinario        char(1)     = 'N',    -- Se utiliza para los pagos extraordinarios o cancelacion anticipada de seguros
   @i_concepto              catalogo    = '',     -- CCA 409
   @i_dividendo             smallint    = 0,      -- CCA 409
   @i_monto_mora            money       = 0,      -- CCA 409
   @i_operacion             int         = null    -- CCA 409
   
as 
declare
   @w_error                 int,
   @w_sp_name               varchar(64),
   @w_commit                char(1), 
   @w_trancount             int,
   @w_rowcount              int,
   @w_operacion             int,
   @w_tramite               int,
   @w_pagos                 smallint,
   @w_est_vigente           tinyint,
   @w_est_novigente         tinyint,
   @w_est_vencido           tinyint,
   @w_est_cancelado         tinyint,
   @w_est_castigado         tinyint,
   @w_gen_desde             smallint,
   @w_desde_ext             int,
   @w_gen_hasta             smallint,
   @w_pagos_poliza          smallint,
   @w_vlr_cuota             money,
   @w_monto_poliza          money,
   @w_sec_seguro            int,
   @w_sec_renovacion        int,
   @w_porcentaje_int        float,   
   @w_valor_cuota_int       float,
   @w_valor_cuota_cap       float,
   @w_int                   float,
   @w_ro_fpago              char(1),
   @w_ro_num_dec            tinyint,
   @w_di_dias_cuota         int,
   @w_tasa_efa              float,
   @w_dias_calculo          int,
   @w_op_toperacion         catalogo,
   @w_concepto_seg          varchar(10),
   @w_sum_cap               money,
   @w_dtr_dividendo         int,
   @w_dtr_concepto          varchar(10),
   @w_dtr_monto             money,
   @w_dtr_secuencial        int,
   @w_estado_di             int,   
   @w_porc_pago             float,
   @w_pago                  money,
   @w_am_pagado             money,
   @w_am_cuota              money,
   @w_amh_pagado            money,
   @w_amh_cuota             money,
   @w_vlr_tot               money,
   @w_cuota_obligacion      money,
   @w_porc_obligacion       float,
   @w_pago_obligacion       money,
   @w_valor_pagado_seg      money,
   @w_plazo                 int,   
   @w_plazo_seguro          int,
   @w_saldo_capital         money,
   @w_tipo_seguro           int,
   @w_capital_inicial       money,
   @w_tipo_asegurado        int,
   @w_factor                float,
   @w_cuota_fija            money,
   @w_banco_renovado        varchar(24),
   @w_tramite_renovado      int,
   @w_fpago                 varchar(10),
   @w_cod_seg               int,
   @w_ro_porcentaje         float,
   @w_ro_porcentaje_efa     float,
   @w_tasa_ponderada        float,
   @w_tasa_ponderada_efa    float,
   @w_vlr_int               money,
   @w_monto                 money,
   @w_am_cuota_ini          money,
   @w_monto_seguros         money,
   @w_nro_seg               int,
   @w_dividendo_can         int,
   @w_porcenta_extra        float,
   @w_cuo_ant               money,
   @w_cuo_act               money,
   @w_monto_nuevo           money,
   --@w_int_cartera           float,        -- CCA 391 Cambio Politica - Tasa seguro Vs Tasa Microcrédito
   @w_plazo_cobertura_cre   int,
   @w_num_dias              int,
   @w_periodo_d             varchar(10),
   @w_porc_max              float,
   @w_valor_seguros         money,
   @w_monto_cre             money,
   @w_valor_cuota_cap_tot   money,
   @w_valor_cuota_cap_ex    money,
   @w_porcentaje_int_his    float,
   @w_sec_asegurado         int,
   @w_cedula                varchar(30),      
   @w_tipo_cedula           catalogo,
   @w_fecha_fin_op_nueva    datetime,
   @w_fecha_ini_op_nueva    datetime,
   @w_plan                  int,
   @w_saldo_seguro          money,
   @w_am_pag_seg            money,
   @w_concepto_pag          varchar(10),
   @w_gen_desde_original    int,
   @w_dtr_dividendo_pag     int,
   @w_valor_pagado_cap      money,
   @w_saldo_seguro_extra    money,
   @w_total_seguro_extra    money,
   @w_tasa_seg              float,
   @w_ro_porcentaje_aux     float,
   @w_valtotal              money, 
   @w_por_seg               float, 
   @w_val_seg               money, 
   @w_tipo_seg              varchar(10),
   @w_op_estado             smallint,
   @w_num_periodo_d         smallint,   
   @w_cod_seg_mora          int,                -- CCA 409
   @w_suma_cap              money,              -- CCA 409
   @w_tipo_seg_mora         int,                -- CCA 409
   @w_suma_mora             money,              -- CCA 409
   @w_mora_dividendo_ant    money,              -- CCA 409
   @w_mora_dividendo_desp   money,              -- CCA 409
   @w_diff                  money               -- CCA 409

   
      
set nocount on

-- INICIALIZA VARIABLES
Select @w_gen_hasta           = 0,
       @w_gen_desde           = 0,
       @w_tasa_ponderada      = 0,
       @w_saldo_capital       = 0,
       @w_valor_cuota_cap_tot = 0,
       @w_cuo_ant             = 0,
       @w_cuo_act             = 0,
       @w_tasa_efa            = 0,
       @w_cod_seg_mora        = 0,                -- CCA 409
       @w_suma_cap            = 0                 -- CCA 409
   
-- ESTADOS DE CARTERA
exec @w_error    = sp_estados_cca
@o_est_vigente   = @w_est_vigente   out,
@o_est_vencido   = @w_est_vencido   out,
@o_est_cancelado = @w_est_cancelado out,
@o_est_novigente = @w_est_novigente out

if @w_error <> 0
   return @w_error

if @w_est_vigente is null
begin
   --print 'ERROR EN LA BUSQUEDA DE ESTADOS EN sp_estados_cca'
   return  710217
end

if @i_operacion is null
begin   

	-- OBTENER DATOS DEL TRAMITE Y/O BANCO RECIBIDO
	select @w_operacion     = op_operacion,
		   @w_tramite       = op_tramite,
		   @w_op_toperacion = op_toperacion,
			@w_plazo         = isnull(op_plazo,0),
			@w_monto         = op_monto,
			@w_op_estado     = op_estado,
			@w_periodo_d     = op_tdividendo,
			@w_num_periodo_d = op_periodo_int
	from cob_cartera..ca_operacion
	where (op_tramite = isnull(@i_tramite,0)
	or op_banco = isnull(@i_banco,''))
	and op_tramite > 0

	if @@rowcount = 0
	begin
	   --print 'NO SE ENCUENTRAN DATOS DEL TRAMITE'
	   return 710022
	end
end

if @i_opcion = 'M'   --> INTERES DE MORA CCA 409
begin
	---NUMERO DE DECIMALES
	select  @w_ro_num_dec  = ro_num_dec
	from cob_cartera..ca_rubro_op
	where ro_operacion = @i_operacion
	and ro_concepto in ('INT')

   -- SELECCIONA EL CODIGO DEL SEGURO DE ACUERDO AL CONCEPTO DE MORA QUE LLEGA DESDE calcdimo.sp
   select @w_cod_seg_mora = codigo
   from   cob_credito..cr_corresp_sib
   where  tabla = 'T156'
   and    codigo_sib = @i_concepto            

   if @w_cod_seg_mora = 1
   begin
	   -- LLENA TABLA TEMPORAL CON LOS SALDOS CORESPONDIENTES A CADA ASEGURADO DEL TIPO DE SEGURO SELECCIONADO
	   select sed_sec_asegurado asegurado, sum(sed_cuota_cap) - sum(sed_pago_cap) monto, porcentaje = convert(float,0)
	   into #seguros_cap
	   from cob_cartera..ca_seguros_det
	   where sed_operacion   = @i_operacion
	   and   sed_tipo_seguro = @w_cod_seg_mora	   	    
	   group by sed_sec_asegurado 

	   if @@rowcount = 0
	   begin
		  --print 'No es posible sumar valores de mora para la operacion'
		  return 1
	   end
       
	   -- SALDO TOTAL DEL SEGURO
	   select @w_suma_cap = sum(monto)
	   from #seguros_cap      
   
	   -- PORCENTAJE DE MORA DE CADA ASEGURADO DE ACUERDO AL SALDO
	   update #seguros_cap
	   set porcentaje = ISNULL(ROUND(monto * 100 / @w_suma_cap,@w_ro_num_dec),0)
      
	   if @@error <> 0 begin
		  --print 'Error actualizando #seguros_cap peso para la mora de los seguros'
		  return 708152  
	   end                
   
	   -- SALDO DE MORA + LA CUOTA ENTRANTE (POR TIPO DE SEGURO Y DIVIDENDO)
	   select @w_mora_dividendo_ant = ISNULL(sum(sed_cuota_mora) + @i_monto_mora,0)
	   from ca_seguros_det
	   where sed_operacion      = @i_operacion
	   and   sed_tipo_seguro    = @w_cod_seg_mora      
	   and   sed_dividendo      = @i_dividendo       
   
	   -- ACTUALIZA LA CUOTA DE LA MORA (POR TIPO DE SEGURO, ASEGURADO Y DIVIDENDO)
	   update ca_seguros_det
	   set sed_cuota_mora = ISNULL(round(sed_cuota_mora + round((@i_monto_mora * porcentaje/100),0),0),0)
	   from #seguros_cap
	   where sed_operacion      = @i_operacion
	   and   sed_tipo_seguro    = @w_cod_seg_mora
	   and   sed_sec_asegurado  = asegurado
	   and   sed_dividendo      = @i_dividendo   
   
	   if @@error <> 0 
	   begin
		  --print 'Error actualizando #ca_seguros_det monto de mora'
		  return 708152  
	   end               
   
	   -- SALDO DE MORA + CUOTA ENTRANTE DESPUES DE LA ACTUALIZACION POR PORCENTAJES (POR TIPO DE SEGURO Y DIVIDENDO)
	   select @w_mora_dividendo_desp = ISNULL(sum(sed_cuota_mora) ,0)
	   from ca_seguros_det
	   where sed_operacion      = @i_operacion
	   and   sed_tipo_seguro    = @w_cod_seg_mora       
	   and   sed_dividendo      = @i_dividendo             
  
	   -- VALIDA SI EXISTE DIFERENCIA ENTRE EL SALDO ANTERIOR Y EL NUEVO (ESTO DEBIDO A QUE POR LOS PORCENTAJES EL VALOR TIENDE A CAMBIAR)
	   if @w_mora_dividendo_ant <> @w_mora_dividendo_desp 
	   begin
   
		  select @w_diff = ISNULL(abs(@w_mora_dividendo_desp - @w_mora_dividendo_ant),0)
      
		  set rowcount 1
      
		  update ca_seguros_det
		  set sed_cuota_mora = case when @w_mora_dividendo_ant > @w_mora_dividendo_desp 
							   then sed_cuota_mora + @w_diff else sed_cuota_mora - @w_diff end
		  from #seguros_cap
		  where sed_operacion      = @i_operacion
		  and   sed_tipo_seguro    = @w_cod_seg_mora      
		  and   sed_dividendo      = @i_dividendo       

		  if @@error <> 0 
		  begin
			 --print 'Error actualizando en ca_seguros_det el sed_cuota_mora'
			 return 708152  
		  end               
      
		  set rowcount 0
   
	   end
   end
   ELSE
   begin
	   -- ACTUALIZA LA CUOTA DE LA MORA (POR TIPO DE SEGURO, ASEGURADO Y DIVIDENDO) 100%
	   update ca_seguros_det
	   set sed_cuota_mora = round(sed_cuota_mora + @i_monto_mora,0)
	   where sed_operacion      = @i_operacion
	   and   sed_tipo_seguro    = @w_cod_seg_mora
	   and   sed_dividendo      = @i_dividendo   
   
	   if @@error <> 0 
	   begin
		  --print 'Error actualizando #ca_seguros_det monto de mora 100 %'
		  return 708152  
	   end             
   end
   return 0   
end ---M


-- OBTENER NUMERO DE PAGOS PARA LA POLIZA
select @w_pagos = count(1) 
from ca_dividendo 
where di_operacion = @w_operacion
and   di_estado   <> @w_est_cancelado        

-- OBTENER CUOTA HASTA DONDE GENERAR
select @w_gen_hasta = isnull(max(di_dividendo) ,0)
from ca_dividendo 
where di_operacion = @w_operacion
and   di_estado   <> @w_est_cancelado        

select @w_gen_desde = @w_gen_hasta

-- OBTENER CUOTA DESDE DONDE GENERAR
select @w_gen_desde = isnull(min(di_dividendo) ,0)
from ca_dividendo 
where di_operacion = @w_operacion
and   di_estado   <> @w_est_cancelado      

select @w_gen_desde_original = @w_gen_desde

-- Buscar Tasa de la Obligacion
select @w_ro_porcentaje     = 0,
       @w_ro_porcentaje_efa = 0
if @w_op_estado = 0 
begin
   select @w_ro_porcentaje     = isnull(rot_porcentaje,0),
          @w_ro_porcentaje_efa = isnull(rot_porcentaje_efa,0),
          @w_ro_porcentaje_aux = isnull(rot_porcentaje_aux,0)
   from cob_cartera..ca_rubro_op_tmp
   where rot_operacion = @w_operacion
   and rot_tipo_rubro = 'I'
   if @@rowcount = 0
   begin
      --print 'NO SE ENCUENTRAN DATOS DEL TASA en ca_rubro_op_tmp'
      return 710022
   end   
end
ELSE
begin
   select @w_ro_porcentaje     = isnull(ro_porcentaje,0),
          @w_ro_porcentaje_efa = isnull(ro_porcentaje_efa,0),
          @w_ro_porcentaje_aux = isnull(ro_porcentaje_aux,0)
   from cob_cartera..ca_rubro_op
   where ro_operacion = @w_operacion
   and ro_tipo_rubro = 'I'
   if @@rowcount = 0
   begin
      --print 'NO SE ENCUENTRAN DATOS DEL TASA en ca_rubro_op'
      return 710022
   end      
end

select @w_am_cuota_ini = isnull(SUM(am_cuota),0)
from cob_cartera..ca_amortizacion
where am_operacion = @w_operacion		
and am_concepto  = 'INT'

/*NUMERO DE DECIMALES*/
select  @w_ro_num_dec  = ro_num_dec
from cob_cartera..ca_rubro_op
where ro_operacion = @w_operacion
and ro_concepto in ('INT')

--Validacion 4  --> 12.4.	validar que la sumatoria de las Primas de Seguros a Financiar no sea mayor a este porcentaje sobre el valor del monto del cr‚dito solicitado.
select @w_porc_max = isnull(pa_float,0)
from cobis..cl_parametro with (nolock)
where pa_nemonico = 'PMFPS'

select @w_monto_cre = 0
select @w_monto_cre = isnull(tr_monto_solicitado,0)  --tr_monto contiene el valor con seguros
from cob_credito..cr_tramite with (nolock)
where tr_tramite = @i_tramite

select @w_valor_seguros = 0
                          
-- Calcula el valor total del seguro, incluyendo tipos de seguros antiguos o totalmente nuevos
select @w_valor_seguros = isnull(sum(isnull(ps_valor_mensual,0) * isnull(datediff(mm,as_fecha_ini_cobertura,as_fecha_fin_cobertura),0)),0)
from cob_credito..cr_seguros_tramite with (nolock),
     cob_credito..cr_asegurados      with (nolock),
     cob_credito..cr_plan_seguros_vs
where st_tramite           = @i_tramite
and   st_secuencial_seguro = as_secuencial_seguro
and   as_plan              = ps_codigo_plan
and   st_tipo_seguro       = ps_tipo_seguro
and   ps_estado            = 'V'      
and   as_tipo_aseg         = (case when ps_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)                                                     

--GFP se suprime print
/*
if @w_valor_seguros > (@w_monto_cre * (@w_porc_max/100))
begin
   print 'Mensaje Informativo: Importante - Valor de Primas de Seguros excede al porcentaje maximo de financiacion'
end     
*/
-- CREAR TABLAS TEMPORALES DE TRABAJO

create table #seguros(
se_sec_seguro        int         null,
se_tipo_seguro       int         null,
se_sec_renovacion    int         null,
se_tipo_asegurado    int         null,
se_plan              int         null,
se_tramite           int         null,
se_operacion         int         null,
se_monto             money       null,
se_tasa              float       null,
se_fec_devolucion    datetime    null,
se_mto_devolucion    money       null,
se_estado            char(1)     null,
se_sec_asegurado     int         null,
se_plazo_seguro      int         null,
se_cedula            varchar(30) null
)

select * into #seguros_det from cob_cartera..ca_seguros_det  where 1 = 2

if @i_opcion = 'G'   --> Generar detalles de seguros
begin
   -- Extractar Valores de las polizas solictadas por el cliente desde el DMO   
   
   insert into #seguros
   select 
   se_sec_seguro          = st_secuencial_seguro,
   se_tipo_seguro         = st_tipo_seguro        ,   
   se_sec_renovacion      = 0                     ,
   se_tipo_asegurado      = as_tipo_aseg          ,
   se_plan                = as_plan               ,
   se_tramite             = @i_tramite            ,
   se_operacion           = @w_operacion          ,
   se_monto               = 0                     ,
   se_tasa                = 0                     ,
   se_fec_devolucion      = null                  ,
   se_mto_devolucion      = null                  ,
   se_estado              = 'I'                   ,
   se_sec_asegurado       = as_sec_asegurado      ,
   se_plazo_seguro        = datediff(mm,as_fecha_ini_cobertura,as_fecha_fin_cobertura),
   se_cedula              = as_ced_ruc 
   from cob_credito..cr_seguros_tramite, cob_credito..cr_asegurados
   where st_tramite = @i_tramite         
   and st_secuencial_seguro = as_secuencial_seguro
   and as_tipo_aseg = (case when st_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)         
   
   if @@error <> 0
   begin
      --print 'No se pudo insertar a #seguros desde cr_seguros_tramite'
	  return 708154
   end		 		 	   
   
   delete from #seguros
   where se_tipo_seguro in (select sec_tipo_seguro 
                            from ca_seguros_can,#seguros 
                            where sec_tramite     = se_tramite 
                            and   sec_tipo_seguro = se_tipo_seguro)
   
   if @@error <> 0
   begin 
      --print 'No Se Pudo Eliminar Tramites Cancelados'
      return 708155
   end		       
   
   -- ACTUALIZA EL MONTO Y LA TASA DE ACUERDO AL PLAN OBTENIDO
   update a set
   a.se_monto = isnull(b.ps_valor_mensual,0),
   a.se_tasa  = isnull(b.ps_tasa_efa,0)
   from #seguros a, cob_credito..cr_plan_seguros_vs b
   where b.ps_codigo_plan = a.se_plan
   and b.ps_tipo_seguro   = a.se_tipo_seguro
   and ps_estado = 'V'

   if @@error <> 0
   begin
      --print 'No se pudo actualizar valor mensual de tipo de seguro'
	  return 708152
   end	  
	 		
   delete from #seguros
   where se_monto = 0
   
   if @@error <> 0
   begin 
      --print 'No Se Pudo Eliminar Tramites con Monto Iguales a Cero'
      return 708155
   end		       
      
   if exists (select 1 from ca_seguros where se_tramite = @i_tramite)
   begin
      
      delete from ca_seguros_det 
      from ca_seguros
      where sed_sec_seguro = se_sec_seguro
      and se_tramite       = @i_tramite
      and sed_pago_cap     = 0 
      and sed_pago_int     = 0 
      and sed_pago_mora    = 0                -- CCA 409
   
      if @@error <> 0 
      begin 
        --print 'No se pudo eliminar los registros relacionados al tramite, ca_seguros_det'
	     return 708155
      end		 
                  
      select @w_gen_desde = isnull(MAX(sed_dividendo),0) + 1 
      from ca_seguros_det 
      where sed_operacion = @w_operacion
      and   sed_tipo_seguro not in (select sec_tipo_seguro from ca_seguros_can where sec_tramite = @i_tramite) 
                        
	  select @w_gen_desde_original = @w_gen_desde
	  
	  delete from ca_seguros 
	  where se_tramite = @i_tramite
	  and se_estado <> 'C'	  

	  if @@error <> 0
	  begin
         --print 'No se pudo eliminar los registros relacionados al tramite, ca_seguros'
	     return 708155
      end
   end	  
   
   -- PASO DE DATOS A TABLA DEFINITIVA
   insert into ca_seguros (
   se_sec_seguro    , se_tipo_seguro   , se_sec_renovacion, 
   se_tramite       , se_operacion     , se_fec_devolucion, 
   se_mto_devolucion, se_estado
   )
   select distinct
   se_sec_seguro    , se_tipo_seguro   , se_sec_renovacion, 
   se_tramite       , se_operacion     , se_fec_devolucion, 
   se_mto_devolucion, se_estado 
   from  #seguros
   
   if @@error <> 0
   begin 
      --print 'No se pudo insertar en ca_seguros desde #seguros'
	  return 708154
   end	  
   
   while 1 = 1
   begin
      set rowcount 1
      select @w_monto_poliza   = se_monto,
	         @w_tasa_efa       = se_tasa,
	         @w_plan           = se_plan,
             @w_sec_seguro     = se_sec_seguro,
			 @w_tipo_seguro    = se_tipo_seguro,
             @w_sec_renovacion = se_sec_renovacion, 
			 @w_tipo_asegurado = se_tipo_asegurado,
			 @w_sec_asegurado  = se_sec_asegurado,
			 @w_plazo_seguro   = se_plazo_seguro,
			 @w_cedula         = se_cedula
      from #seguros
      where se_estado = 'I'
      order by se_tipo_asegurado
     
      if @@rowcount = 0 break
   
      set rowcount 0        
      
      select @w_plazo_cobertura_cre = isnull(ps_plazo_cobertura_cre,0)
      from cob_credito..cr_plan_seguros_vs with (nolock)
      where ps_codigo_plan       = @w_plan
      and   ps_estado            = 'V'
      and   ps_tipo_seguro       = @w_tipo_seguro
      
      if @w_plazo_seguro <= 0
      begin
         --print 'El Asegurado con Documento de Identidad ' + @w_cedula  + ' ya tiene asociada una poliza vigente del tipo ' + cast(@w_tipo_seguro as varchar) + ', no es posible asociar el mismo tipo de poliza con fecha de vigencia menor a la fecha fin de la poliza vigente '         
         return 708154
      end      
      
      if @w_plazo_seguro < @w_plazo_cobertura_cre  and @i_extraordinario <> 'S'
      begin         
         --print 'Plazo del Tipo de Seguro ' + cast(@w_tipo_seguro as varchar) + ' del Asegurado con Documento de Identidad ' + @w_cedula  + ', menor al permitido. Debe ser mayor a ' + cast(@w_plazo_cobertura_cre as varchar) + ' meses '  + 'Plazo Actual : ' + cast (@w_plazo_seguro as varchar)       
         return 708154
      end   -- Fin Validacion coberturas por plazo de los tipos de seguros                           
      
      
      select 
	  @w_pagos_poliza  = (@w_gen_hasta + 1 ) - @w_gen_desde ,               --> Pagos de la poliza basados en el plazo pendiente de la obligacion
      @w_vlr_cuota     = round(@w_monto_poliza,0),                        --> Valor de la cuota (K) basada en el plazo pendiente del asegurado      
	  @w_valor_cuota_cap = @w_vlr_cuota,
      @w_valor_cuota_int = 0	                                          --> Valor de la cuota (I) basada en el plazo pendiente del asegurado	  
         	     	  
   	  if @i_liquida <> 'S' and @i_extraordinario = 'N'
   	  begin
	  
	     -- BUSCA FORMA DE PAGO DE LA OPERACION EN LA TEMPORAL
	     select 
	     @w_ro_fpago    = rot_fpago,
	     @w_ro_num_dec  = rot_num_dec
	     from cob_cartera..ca_rubro_op_tmp 
	     where rot_operacion = @w_operacion 
	     and rot_concepto in ('INT')
	     and rot_fpago    in ('P','A','T')
         
	     if @w_ro_fpago in ('P', 'T')
            select @w_ro_fpago = 'V'		
			     			
		 -- BUSCA DIAS DE LA CUOTA EN AL TAMPORAL
         select @w_di_dias_cuota = dit_dias_cuota
	     from cob_cartera..ca_dividendo_tmp 
	     where dit_operacion = @w_operacion
	     and   dit_dividendo >= 1			 
		 
      end
   	  else
   	  begin
	     -- BUSCA FORMA DE PAGO DE LA OPERACION EN LAS DEFINITIVAS
	     select 
	     @w_ro_fpago    = ro_fpago,
	     @w_ro_num_dec  = ro_num_dec
	     from cob_cartera..ca_rubro_op
	     where ro_operacion = @w_operacion 
	     and ro_concepto in ('INT')
	     and ro_fpago    in ('P','A','T')
         
	     if @w_ro_fpago in ('P', 'T')
            select @w_ro_fpago = 'V'	   	     
	     
	   	 -- BUSCA DIAS DE LA CUOTA EN LA DEFINITIVA
		 select @w_di_dias_cuota = di_dias_cuota
		 from cob_cartera..ca_dividendo 
		 where di_operacion = @w_operacion
		 and   di_dividendo >= 1
   	  end	   	  	  	 

   	  
      -- CALCULAR LA TASA EQUIVALENTE

     
      exec @w_error = sp_conversion_tasas_int
      @i_periodo_o       = 'A',
      @i_modalidad_o     = 'V',
      @i_num_periodo_o   = 1,
      @i_tasa_o          = @w_tasa_efa,
      @i_periodo_d       = 'D',
      @i_modalidad_d     = @w_ro_fpago,
      @i_num_periodo_d   = @w_di_dias_cuota,
      @i_dias_anio       = 360,
      @i_num_dec         = @w_ro_num_dec,
      @o_tasa_d          = @w_porcentaje_int output
      
      if @w_error <> 0
      begin
         --print 'Error en conversion de tasa'
		 return @w_error
      end		 

      	  
	  select @w_porcentaje_int_his = @w_porcentaje_int
	  	  
	  if @i_extraordinario = 'S'   -- Si existe un pago extraordinario se debe volver a generar la tabla de amortizacion de seguros con los nuevos valores
	  begin
		 	 
		 select @w_valor_cuota_cap = isnull(sum(sedh_cuota_cap),0)
	     from ca_seguros_det_his
	     where sedh_operacion    = @w_operacion	     
	     and sedh_sec_seguro     = @w_sec_seguro	    
	     and sedh_tipo_seguro    = @w_tipo_seguro
        and sedh_sec_renovacion = @w_sec_renovacion
		  and sedh_tipo_asegurado = @w_tipo_asegurado
		  and sedh_sec_asegurado  = @w_sec_asegurado    -- CCA 409 
		  and sedh_secuencial     = @i_secuencial_pago

         select @w_valor_cuota_cap = @w_valor_cuota_cap - isnull(sum(sed_pago_cap),0)
         from ca_seguros_det
         where sed_operacion    = @w_operacion	     
         and sed_sec_seguro     = @w_sec_seguro	    
         and sed_tipo_seguro    = @w_tipo_seguro
         and sed_sec_renovacion = @w_sec_renovacion
         and sed_tipo_asegurado = @w_tipo_asegurado
         and sed_sec_asegurado  = @w_sec_asegurado     -- CCA 409 
	     		 		 		 		 		 
		 select @w_valor_cuota_cap_ex = @w_valor_cuota_cap		 
		 
	  end	  	  	  	  
	  	  
	  select @w_porcentaje_int = isnull((round(@w_porcentaje_int/12,2) / 100),0)	  -- Devuelve el Interes Nominal Mensual
	  select @w_factor = isnull(power(1 + @w_porcentaje_int,@w_pagos_poliza),0)       -- Ayuda a determinar la cuota fija de acuerdo INT Vs Plazo

	  if @i_extraordinario <> 'S'
	     select @w_capital_inicial = (@w_vlr_cuota * @w_plazo_seguro)	     
	  else
	     select @w_capital_inicial = (@w_valor_cuota_cap)	  	     	  	  	 	  	 	
	  
	  -- cuota fija mensual que pagara el asegurado por cada poliza
	  if @w_porcentaje_int = 0
	  begin
	     select @w_cuota_fija = @w_capital_inicial
	  end
	  else
	  begin
	     if @w_porcentaje_int = 0 or @w_factor = 1
	     begin 
	        select @w_cuota_fija  = @w_valor_cuota_cap
	     end
	     else
	     begin
	        select @w_cuota_fija = (@w_porcentaje_int*@w_factor*@w_capital_inicial)/(@w_factor-1)
	        select @w_cuota_fija = round(@w_cuota_fija,0)
	     end
	  end	  	  	  
	  
      if @w_valor_cuota_cap < 0 
	     select @w_valor_cuota_cap = 0 
	     
	  if @w_vlr_cuota < 0 
	     select @w_vlr_cuota = 0 
	  
      while @w_gen_desde <= @w_gen_hasta    --> Generacion Tabla de Amortizacion de Seguros ca_seguros_Det
      begin   
	                                 
         select @w_valor_cuota_int = round((@w_capital_inicial * @w_porcentaje_int),0)

	     if @w_gen_desde = @w_gen_hasta 
	     begin
	        
	        if @i_extraordinario <> 'S' 
	        begin	        	        
	           select @w_monto_poliza = round(@w_monto_poliza * @w_plazo_seguro,0)
	           select @w_valor_cuota_cap = round(@w_monto_poliza - @w_valor_cuota_cap_tot,0)	           
	        end 
	        else
	        begin
	           select @w_valor_cuota_cap = round(@w_valor_cuota_cap_ex - @w_valor_cuota_cap_tot,0)
	        end	        	        	        
	        
	     end
	     else 
	     begin
	        select @w_valor_cuota_cap = round((@w_cuota_fija - @w_valor_cuota_int),0)		 		 
	        select @w_saldo_capital  = round(@w_capital_inicial - @w_valor_cuota_cap,0)
	     end

         insert into #seguros_det(
         sed_operacion,      sed_sec_seguro,     sed_tipo_seguro, 
         sed_sec_renovacion, sed_tipo_asegurado, sed_estado,
         sed_dividendo,      sed_cuota_cap,      sed_pago_cap,
         sed_cuota_int,      sed_pago_int,       sed_cuota_mora,
         sed_pago_mora,      sed_sec_asegurado                          -- CCA 409
         )		 
         values (
         @w_operacion,       @w_sec_seguro,      @w_tipo_seguro, 
         @w_sec_renovacion,  @w_tipo_asegurado,  1, 
         @w_gen_desde,       @w_valor_cuota_cap, 0, 
         @w_valor_cuota_int, 0,                  0, 
         0,                  @w_sec_asegurado                           -- CCA 409
         )
         
		 select @w_capital_inicial = @w_saldo_capital		 		 
		 select @w_valor_cuota_cap_tot = @w_valor_cuota_cap_tot + @w_valor_cuota_cap
		 
		 select @w_gen_desde = @w_gen_desde + 1
		 
      end    --> Fin Generacion Tabla de Amortizacion de Seguros ca_seguros_Det
      
      select @w_gen_desde = @w_gen_desde_original
      
      select @w_valor_cuota_cap_tot = 0                   -- Inicializa nuevamente en cero para los siguientes seguros
	  
	  -- PASO DETALLE A DEFINITIVAS
      insert into ca_seguros_det 
      select * from #seguros_det

      if @@error <> 0
      begin
	     --print 'Error en paso detalle de definitivas - ca_seguros_det'
		 return 708154
      end		 
                
      update #seguros set se_estado = 'P' 
      where se_sec_seguro   = @w_sec_seguro
      and se_tipo_seguro    = @w_tipo_seguro
      and se_sec_renovacion = @w_sec_renovacion
      and se_tipo_asegurado = @w_tipo_asegurado
      and se_sec_asegurado  = @w_sec_asegurado
      and se_estado         = 'I'
      
	  if @@error <> 0
	  begin 
	     --print 'Error actualizando estado #seguros'
		 return 708152
      end
	  
      select dividendo = sed_dividendo,
             capital   = isnull(SUM(sed_cuota_cap),0),
             interes   = isnull(SUM(sed_cuota_int),0),
             mora      = isnull(SUM(sed_cuota_mora),0)             
      into #dividendos
      from #seguros_det, ca_seguros
      where se_tramite       = @i_tramite
      and se_operacion       = @w_operacion
      and se_sec_seguro      = sed_sec_seguro
      and se_sec_renovacion  = sed_sec_renovacion
      and sed_tipo_seguro    = @w_tipo_seguro
	   and sed_tipo_asegurado = @w_tipo_asegurado
	   and sed_sec_asegurado  = @w_sec_asegurado                    -- CCA 409 
      group by sed_dividendo 
      	  
	  if @@error <> 0
	  begin 
	     --print 'Error al insertar en #dividendos'
         return 708154
      end		 

      delete #seguros_det
      
	  if @@error <> 0
	  begin 
         --print 'No se pudo eliminar tabla temporal #seguros_det'
	     return 708155
      end		       
	  	  
	  if @i_extraordinario = 'N'
	  begin 	  
	    	  	  
         if @i_liquida <> 'S'
         begin	      --> Temporales (esto pasa cuando se abre la pantalla del desembolso)
      
	        select * into #amortizacion 
            from ca_amortizacion_tmp
            where amt_operacion = @w_operacion
	  
	        if @@error <> 0
	        begin
	           --print 'Error al insertar en #amortizacion'
               return 708154
            end		 
      
            select * into #rubros 
            from ca_rubro_op_tmp
            where rot_operacion = @w_operacion      

	        if @@error <> 0
	        begin
	           --print 'Error al insertar en #rubros'
               return 708154
            end		 
      
            update #amortizacion 
            set amt_cuota     = amt_cuota + capital,
                amt_acumulado = amt_acumulado + capital
            from #dividendos, #rubros 
            where amt_operacion  = @w_operacion  
            and   amt_dividendo  = dividendo
            and   amt_operacion  = rot_operacion
            and   amt_concepto   = rot_concepto
            and   rot_tipo_rubro = 'C'

	        if @@error <> 0
	        begin 
	           --print 'Error actualizando cuota capital en #amortizacion'
		       return 708152
            end
      
            update #amortizacion 
            set amt_cuota = amt_cuota + interes
            from #dividendos, #rubros 
            where amt_operacion  = @w_operacion  
            and   amt_dividendo  = dividendo
            and   amt_operacion  = rot_operacion
            and   amt_concepto   = rot_concepto
            and   rot_tipo_rubro = 'I'

	        if @@error <> 0
	        begin 
	           --print 'Error actualizando cuota interes en #amortizacion'
		       return 708152
            end
           
            update #amortizacion 
            set amt_cuota = amt_cuota + mora
            from #dividendos, #rubros, cob_credito..cr_corresp_sib
            where amt_operacion  = @w_operacion  
            and   amt_dividendo  = dividendo
            and   amt_operacion  = rot_operacion
            and   amt_concepto   = rot_concepto
            and   rot_tipo_rubro = 'M'
            and   rot_concepto   = codigo_sib
            and   codigo         = @w_tipo_seguro
            and   tabla          = 'T156'

	        if @@error <> 0
	        begin 
	           --print 'Error actualizando mora en #amortizacion'
		       return 708152
            end
      
            update #amortizacion 
            set amt_acumulado = amt_acumulado + mora
            from #dividendos, #rubros, cob_credito..cr_corresp_sib 
            where amt_operacion  = @w_operacion  
            and   amt_dividendo  = dividendo
            and   amt_operacion  = rot_operacion
            and   amt_concepto   = rot_concepto
            and   rot_tipo_rubro = 'M'
            and   rot_concepto   = codigo_sib
            and   codigo         = @w_tipo_seguro
            and   tabla          = 'T156'
      
	        if @@error <> 0
	        begin 
	           --print 'Error actualizando acumulado de interes en #amortizacion'
		       return 708152
            end		 
      
            update a 
            set a.amt_cuota     = b.amt_cuota,
                a.amt_acumulado = b.amt_acumulado
            from ca_amortizacion_tmp a, #amortizacion b, #rubros c
            where a.amt_operacion = b.amt_operacion
            and   a.amt_dividendo = b.amt_dividendo
            and   a.amt_concepto  = b.amt_concepto
            and   a.amt_operacion = c.rot_operacion            
            and   a.amt_concepto  = c.rot_concepto 
            and   (c.rot_tipo_rubro in ('C','I')
            or    (c.rot_tipo_rubro = 'M'
                   and c.rot_concepto in (select codigo_sib from cob_credito..cr_corresp_sib where tabla = 'T156'))) 
          
	        if @@error <> 0
	        begin 
	           --print 'Error actualizando ca_amortizacion'
		       return 708152
            end
      
	        -- BUSCA EL CONCEPTO A APLICAR PARA EL SEGURO RESPECTIVO
      
            select @w_concepto_seg = codigo_sib
            from cob_credito..cr_corresp_sib
            where tabla = 'T155'
            and codigo  = @w_tipo_seguro --> Corresponde a un tipo de seguro     
      
            if @@rowcount = 0
            begin
	           --print 'No existe parametria para cob_credito..cr_corresp_sib'
	           return 708152
	        end	     
	     
	        -- ACTIVA LOS CONCEPTOS RESPECTIVOS EN LA TABLA ca _rubro_op - Desembolsos Seguros Asociados (Contabilidad)
       
            if not exists(select 1 from cob_cartera..ca_rubro_op_tmp
                         where rot_operacion = @w_operacion
                         and rot_concepto    = @w_concepto_seg)

            begin     -- Solo inserta si el concepto no existe para la operacion
	   
				insert into ca_rubro_op_tmp(
				rot_operacion           , rot_concepto            , rot_tipo_rubro       ,
				rot_fpago               , rot_prioridad           , rot_paga_mora        ,
				rot_provisiona          , rot_signo               , rot_factor           ,
				rot_referencial         , rot_signo_reajuste      , rot_factor_reajuste  ,
				rot_referencial_reajuste, rot_valor               , rot_porcentaje       ,
				rot_porcentaje_aux      , rot_gracia              , rot_concepto_asociado,
				rot_redescuento         , rot_intermediacion      , rot_principal        ,
				rot_porcentaje_efa      , rot_garantia            , rot_tipo_puntos      ,
				rot_saldo_op            , rot_saldo_por_desem     , rot_base_calculo     ,
				rot_num_dec             , rot_limite              , rot_iva_siempre      ,
				rot_monto_aprobado      , rot_porcentaje_cobrar   , rot_tipo_garantia    ,
				rot_nro_garantia        , rot_porcentaje_cobertura, rot_valor_garantia   ,
				rot_tperiodo            , rot_periodo             , rot_tabla            ,
				rot_saldo_insoluto      , rot_calcular_devolucion)
				select
				@w_operacion     , ru_concepto            , ru_tipo_rubro       ,
				ru_fpago         , ru_prioridad           , 'N'                 ,
				ru_provisiona    , null                   , null                ,
				ru_referencial   , null                   , null                ,
				null             , 0                      , @w_tasa_efa         ,
				@w_tasa_efa      , null    , ru_concepto_asociado,
				ru_redescuento   , ru_intermediacion      , ru_principal        ,
				@w_tasa_efa      , 0                      , null                ,
				ru_saldo_op      , ru_saldo_por_desem     , null                ,
				null             , ru_limite              , ru_iva_siempre      ,
				ru_monto_aprobado, ru_porcentaje_cobrar   , ru_tipo_garantia    ,
				null             , ru_porcentaje_cobertura, ru_valor_garantia   ,
				ru_tperiodo      , ru_periodo             , ru_tabla            ,
				ru_saldo_insoluto, ru_calcular_devolucion
				from ca_rubro
				where ru_toperacion = @w_op_toperacion
				and   ru_concepto   = @w_concepto_seg
		 
				if @@error <> 0
				begin 
				   --print 'Error insertando ca_rubro_op'
				   return 708154		  		  
				end
						            			
            end   -- Fin insert ca_rubro_op
         
			 select @w_sum_cap = isnull(round(SUM(sed_cuota_cap),0),0)
			 from ca_seguros_det, ca_seguros
			 where se_sec_seguro   = sed_sec_seguro
			 and se_tramite        = @i_tramite
			 and se_operacion      = @w_operacion     
			 and sed_tipo_seguro   = @w_tipo_seguro		    			
						
			 update ca_rubro_op_tmp set 
			 rot_valor = @w_sum_cap                     --(sumatoria de K de la tabla detalle del seguro respectivo)     
			 where rot_operacion = @w_operacion
			 and rot_concepto    = @w_concepto_seg
	            
			 if @@error <> 0
			 begin 
				--print 'Error actualizando valor ca_rubro_op'
				return 708152
			 end		

	         
			 drop table #amortizacion
			 drop table #rubros               
          		 
		  end --> fin Temporales
		  else
		  begin -- ACTUALIZA TABLAS DEFINITIVAS

			 select * into #amortizacion2 
			 from ca_amortizacion
			 where am_operacion = @w_operacion
		  
			 if @@error <> 0
			 begin
				--print 'Error al insertar en #amortizacion'
				return 708154
			 end		 
	      
			 select * into #rubros2 
			 from ca_rubro_op
			 where ro_operacion = @w_operacion      

			 if @@error <> 0
			 begin
				--print 'Error al insertar en #rubros'
				return 708154
			 end		 
	      
			 update #amortizacion2 
			 set am_cuota     = am_cuota + capital,
				 am_acumulado = am_acumulado + capital
			 from #dividendos, #rubros2 
			 where am_operacion  = @w_operacion  
			 and   am_dividendo  = dividendo
			 and   am_operacion  = ro_operacion
			 and   am_concepto   = ro_concepto
			 and   ro_tipo_rubro = 'C'

			 if @@error <> 0
			 begin 
				--print 'Error actualizando cuota capital en #amortizacion'
				return 708152
			 end
	      
			 update #amortizacion2 
			 set am_cuota = am_cuota + interes
			 from #dividendos, #rubros2 
			 where am_operacion  = @w_operacion  
			 and   am_dividendo  = dividendo
			 and   am_operacion  = ro_operacion
			 and   am_concepto   = ro_concepto
			 and   ro_tipo_rubro = 'I'

			 if @@error <> 0
			 begin 
				--print 'Error actualizando cuota interes en #amortizacion'
				return 708152
			 end
	      	      
			 update #amortizacion2 
			 set am_cuota = am_cuota + mora
			 from #dividendos, #rubros2, cob_credito..cr_corresp_sib
			 where am_operacion  = @w_operacion  
			 and   am_dividendo  = dividendo
			 and   am_operacion  = ro_operacion
			 and   am_concepto   = ro_concepto
			 and   ro_tipo_rubro = 'M'         
			 and   ro_concepto   = codigo_sib
          and   codigo        = @w_tipo_seguro
          and   tabla         = 'T156'

			 if @@error <> 0
			 begin 
				--print 'Error actualizando mora en #amortizacion'
				return 708152
			 end
	      
			 update #amortizacion2 
			 set am_acumulado = am_acumulado + mora
			 from #dividendos, #rubros2, cob_credito..cr_corresp_sib 
			 where am_operacion  = @w_operacion  
			 and   am_dividendo  = dividendo
			 and   am_operacion  = ro_operacion
			 and   am_concepto   = ro_concepto
			 and   ro_tipo_rubro = 'M'         
			 and   ro_concepto   = codigo_sib
          and   codigo        = @w_tipo_seguro
          and   tabla         = 'T156'
	      
			 if @@error <> 0
			 begin 
				--print 'Error actualizando acumulado de interes en #amortizacion'
				return 708152
			 end		 
	      
			 update a 
			 set a.am_cuota     = b.am_cuota,
				 a.am_acumulado = b.am_acumulado
			 from ca_amortizacion a, #amortizacion2 b, #rubros2 c
			 where a.am_operacion = b.am_operacion
			 and   a.am_dividendo = b.am_dividendo
			 and   a.am_concepto  = b.am_concepto
			             and   a.am_operacion = c.ro_operacion            
            and   a.am_concepto  = c.ro_concepto
            and   (c.ro_tipo_rubro in ('C','I')
            or    (c.ro_tipo_rubro = 'M'
                   and c.ro_concepto in (select codigo_sib from cob_credito..cr_corresp_sib where tabla = 'T156')))
            	          
            if @@error <> 0 
            begin 
               --print 'Error actualizando ca_amortizacion def'
               return 708152
            end		 
            	      
            update a 
            set a.amt_cuota     = b.am_cuota,
            a.amt_acumulado = b.am_acumulado
            from ca_amortizacion_tmp a, #amortizacion2 b, #rubros2 c
            where a.amt_operacion = b.am_operacion
            and   a.amt_dividendo = b.am_dividendo
            and   a.amt_concepto  = b.am_concepto
            and   a.amt_operacion = c.ro_operacion            
            and   a.amt_concepto  = c.ro_concepto
            and   (c.ro_tipo_rubro in ('C','I')
            or    (c.ro_tipo_rubro = 'M'
                   and c.ro_concepto in (select codigo_sib from cob_credito..cr_corresp_sib where tabla = 'T156')))
	          
			 if @@error <> 0
			 begin 
				--print 'Error actualizando ca_amortizacion'
				return 708152
			 end		 

			 -- BUSCA EL CONCEPTO A APLICAR PARA EL SEGURO RESPECTIVO
	      
			 select @w_concepto_seg = codigo_sib
			 from cob_credito..cr_corresp_sib
			 where tabla = 'T155'
			 and codigo  = @w_tipo_seguro --> Corresponde a un tipo de seguro     
	      
			 if @@rowcount = 0
			 begin
				--print 'No existe parametria para cob_credito..cr_corresp_sib'		 
				return 708152
			end
		     
			 -- ACTIVA LOS CONCEPTOS RESPECTIVOS EN LA TABLA ca _rubro_op - Desembolsos Seguros Asociados (Contabilidad)
	       
			 if not exists(select 1 from cob_cartera..ca_rubro_op
						  where ro_operacion = @w_operacion
						  and ro_concepto    = @w_concepto_seg)

			 begin     -- Solo inserta si el concepto no existe para la operacion
		   
				insert into ca_rubro_op(
				ro_operacion           , ro_concepto            , ro_tipo_rubro       ,
				ro_fpago               , ro_prioridad           , ro_paga_mora        ,
				ro_provisiona          , ro_signo               , ro_factor           ,
				ro_referencial         , ro_signo_reajuste      , ro_factor_reajuste  ,
				ro_referencial_reajuste, ro_valor               , ro_porcentaje       ,
				ro_porcentaje_aux      , ro_gracia              , ro_concepto_asociado,
				ro_redescuento         , ro_intermediacion      , ro_principal        ,
				ro_porcentaje_efa      , ro_garantia            , ro_tipo_puntos      ,
				ro_saldo_op            , ro_saldo_por_desem     , ro_base_calculo     ,
				ro_num_dec             , ro_limite              , ro_iva_siempre      ,
				ro_monto_aprobado      , ro_porcentaje_cobrar   , ro_tipo_garantia    ,
				ro_nro_garantia        , ro_porcentaje_cobertura, ro_valor_garantia   ,
				ro_tperiodo            , ro_periodo             , ro_tabla            ,
				ro_saldo_insoluto      , ro_calcular_devolucion)
				select
				@w_operacion     , ru_concepto            , ru_tipo_rubro       ,
				ru_fpago         , ru_prioridad           , 'N'                 ,
				ru_provisiona    , null                   , null                ,
				ru_referencial   , null                   , null                ,
				null             , 0                      , @w_tasa_efa         ,
				@w_tasa_efa      , null                   , ru_concepto_asociado,
				ru_redescuento   , ru_intermediacion      , ru_principal        ,
				@w_tasa_efa      , 0                      , null                ,
				ru_saldo_op      , ru_saldo_por_desem     , null                ,
				null             , ru_limite              , ru_iva_siempre      ,
				ru_monto_aprobado, ru_porcentaje_cobrar   , ru_tipo_garantia    ,
				null             , ru_porcentaje_cobertura, ru_valor_garantia   ,
				ru_tperiodo      , ru_periodo             , ru_tabla            ,
				ru_saldo_insoluto, ru_calcular_devolucion
				from ca_rubro
				where ru_toperacion = @w_op_toperacion
				and   ru_concepto   = @w_concepto_seg
			 
				if @@error <> 0
				begin 
				   --print 'Error insertando ca_rubro_op'
				   return 708154		  		  
				end
			                						
			 end   -- Fin insert ca_rubro_op		 		 
			 
			 select @w_sum_cap = isnull(round(SUM(sed_cuota_cap),0),0)
			 from ca_seguros_det, ca_seguros
			 where se_sec_seguro   = sed_sec_seguro
			 and se_tramite        = @i_tramite
			 and se_operacion      = @w_operacion     
			 and sed_tipo_seguro   = @w_tipo_seguro
			    
			 update ca_rubro_op
			 set ro_valor = @w_sum_cap                     --(sumatoria de K de la tabla detalle del seguro respectivo)     
			 where ro_operacion = @w_operacion
			 and ro_concepto    = @w_concepto_seg
	            
			 if @@error <> 0
			 begin 
				--print 'Error actualizando valor ca_rubro_op'
				return 708152
			 end				 			 		 			 
		  			 		 			 		  	     		 
			 drop table #amortizacion2
			 drop table #rubros2
	     		 
		  end	  -- FIN ACTUALIZA TABLAS DEFINITIVAS
	  end   -- FIN EXTRAORDINARIO
	  drop table #dividendos	  	       	 
   end  -- Fin While General, --> realiza el proceso de cada seguro por cada tipo y asegurado
   
   set rowcount 0
   
end  --> Fin Opcion G

if @i_liquida = 'S'
begin 	        -- Actualiza definitivas si se realiza el desembolso
      
   -- CALCULO PONDERADO TASA
   select @w_valtotal = 0
   
   select 'Porcentaje' = isnull(ro_porcentaje,0), 
          'Valor' = sum(isnull(ro_valor,0)),
          'Tipo' = ro_concepto
   into #porsegur
   from cob_cartera..ca_rubro_op
  where ro_operacion =  @w_operacion
   and ro_concepto like 'SEG%'
   and   ro_concepto not in ( 'SEGDEUVEN' ,'SEGDEUANT', 'SEGDEUEM') 
   group by ro_concepto, ro_porcentaje
      
   while 1 = 1
   begin
   set rowcount 1
   select @w_por_seg  = Porcentaje,
          @w_val_seg   = Valor,
          @w_tipo_seg  = Tipo
    from  #porsegur
    
    if @@rowcount = 0
       break
  
   select @w_valtotal =  @w_valtotal + (@w_val_seg * @w_por_seg)
      
    delete #porsegur where Tipo = @w_tipo_seg 
   end
   set rowcount 0

   
   select @w_porc_pago = @w_valor_seguros / (@w_valor_seguros + @w_monto_cre)		    -- PORCENTAJE DE PAGO PARA EL SEGURO              			
   select @w_porc_obligacion = @w_monto_cre / (@w_valor_seguros + @w_monto_cre)			-- PORCENTAJE DE PAGO PARA LA OBLIGACION	                				

   select @w_tasa_ponderada_efa =round((((@w_monto_cre * @w_ro_porcentaje_aux ) + (@w_valtotal)) /(@w_monto_cre +@w_valor_seguros)) , @w_ro_num_dec)                                                                                      


   ---TASA NOMINAL MENSUAL PONDERADA PARA EL CALCULO DE INTERSESE
   ---EN EL NUEVO PROGRAMA sp_recalc_int_Tasa_Ponderada
   
   select 
   @w_ro_fpago    = ro_fpago,
   @w_ro_num_dec  = ro_num_dec
   from cob_cartera..ca_rubro_op
   where ro_operacion = @w_operacion 
   and ro_concepto in ('INT')
   and ro_fpago    in ('P','A','T')
   
   if @w_ro_fpago in ('P', 'T')
      select @w_ro_fpago = 'V'	 
	    
   exec @w_error = sp_conversion_tasas_int
   @i_periodo_o       = 'A',
   @i_modalidad_o     = 'V',
   @i_num_periodo_o   = 1,
   @i_tasa_o          = @w_tasa_ponderada_efa,
   @i_periodo_d       = @w_periodo_d,
   @i_modalidad_d     = @w_ro_fpago,
   @i_num_periodo_d   = @w_num_periodo_d,
   @i_dias_anio       = 360,
   @i_num_dec         = @w_ro_num_dec,
   @o_tasa_d          = @w_tasa_ponderada output
   
   if @w_error <> 0
   begin
      --print 'Error en conversion de tasa'
	 return @w_error
   end
      
   update ca_rubro_op set
   ro_porcentaje     = @w_tasa_ponderada,
   ro_porcentaje_efa = @w_tasa_ponderada_efa    
   where ro_operacion = @w_operacion
   and ro_tipo_rubro  = 'I'
        
   if @@error <> 0
   begin
      --print 'Error actualizando ca_rubro_op para el pocentaje'
       return 708152
   end	   
        
   update ca_rubro_op_tmp set
   rot_porcentaje      = @w_tasa_ponderada,
   rot_porcentaje_efa  = @w_tasa_ponderada_efa    
   where rot_operacion = @w_operacion
   and rot_tipo_rubro  = 'I'
        
   if @@error <> 0
   begin
      --print 'Error actualizando ca_rubro_op_tmp para el pocentaje'
       return 708152
   end	   

   -- Obtine el monto por seguros
   select @w_monto_seguros = @w_valor_seguros

   update ca_operacion set
   op_monto = @w_monto + @w_monto_seguros,
   op_monto_aprobado = @w_monto + @w_monto_seguros
   where op_operacion = @w_operacion
   and op_tramite = @i_tramite

   if @@error <> 0 begin
      --print 'Error actualizando op_monto en ca_operacion'
	  return 708152
   end	         
       
   update ca_rubro_op set
   ro_valor = @w_monto + @w_monto_seguros
   where ro_operacion = @w_operacion
   and ro_tipo_rubro  = 'C'
        
   if @@error <> 0 begin
      --print 'Error actualizando ca_rubro_op para el ro_valor'
	  return 708152
   end
                
end

if @i_opcion = 'P' begin   -- DISTRIBUCION DE PAGOS RECIBIDOS            

   select @w_fpago = null
   select @w_fpago = abd_concepto          
   from   ca_abono_det,  ca_abono
   where  abd_secuencial_ing = @i_secuencial_ing 
   and    abd_operacion      = @w_operacion
   and    abd_tipo = 'PAG'            
   and    abd_secuencial_ing = ab_secuencial_ing    
   and    abd_operacion      = ab_operacion
   and    ab_estado          not in ('E', 'RV')
   
   if @w_fpago is null return 0
    
   --Tabla temporal que guarda los seguros del tramite por cada tipo y asegurado que exista
   create table #seguros_pag(
   se_sec_seguro     int,
   se_tipo_seguro    int,
   se_sec_renovacion int,
   se_sec_asegurado  int,       -- CCA 409
   se_tipo_asegurado int,      
   se_monto_cap      money,
   se_monto_int      money,
   se_monto_imo      money,     -- CCA 409
   se_tramite        int,
   se_estado         char(1)         
   )
   
   select codigo,codigo_sib concepto into #concepto_mora_seg     -- CCA 409
   from cob_credito..cr_corresp_sib
   where tabla = 'T156'
        
   -- Inserta el detalle de la transaccion
   
   select
   dtr_secuencial,
   dtr_operacion,
   dtr_dividendo,
   dtr_concepto,
   dtr_monto_mn,
   dtr_estado,
   dtr_estado_pro = 'I'
   into #detalle_trn
   from cob_cartera..ca_det_trn
   where (dtr_concepto in ('CAP', 'INT') or dtr_concepto in (select concepto from #concepto_mora_seg))   -- CCA 409
   and dtr_operacion  = @w_operacion
   and dtr_secuencial = @i_secuencial_pago
   order by dtr_dividendo, dtr_concepto DESC
   
   if @@error <> 0 begin
      --PRINT 'No se encuentra el detalle del pago en cob_cartera..ca_det_trn'
      return 710029
   end
   
   update #detalle_trn set
   dtr_estado = am_estado
   from #detalle_trn, cob_cartera..ca_amortizacion
   where am_operacion   = dtr_operacion
   and am_dividendo     = dtr_dividendo
   and am_concepto      = dtr_concepto      
   
   if @@error <> 0 Begin
      --print 'Error actualizando #detalle_trn'
      return 708152                        
   end
   
   while 1 = 1 -- While Principal (RECORRE DETALLE DE LA TRANSACCION)
   begin
   
      set rowcount 1
   
      select 
      @w_dtr_secuencial = dtr_secuencial,
      @w_dtr_dividendo  = dtr_dividendo,
      @w_dtr_concepto   = dtr_concepto,
      @w_dtr_monto      = dtr_monto_mn,
      @w_estado_di      = dtr_estado
      from #detalle_trn   
      where dtr_estado_pro = 'I'
      order by dtr_dividendo, dtr_concepto DESC
      
      if @@rowcount = 0 break

      set rowcount 0
             
      select @w_cod_seg = null 
	  select @w_cod_seg = codigo,
	         @w_concepto_pag = codigo_sib
      from cob_credito..cr_corresp_sib
      where tabla = 'T155'
      and descripcion_sib  = @w_fpago            
            
      if @w_cod_seg  is not null      -- si la forma de pago es para cancelacion total de seguro
      begin         
                        
	     if not exists (select 1 from ca_seguros,ca_rubro_op
	                    where ro_operacion = @w_operacion
	                    and   ro_concepto  = @w_concepto_pag
	                    and ro_operacion   = se_operacion	                    
	                    and se_tipo_seguro = @w_cod_seg
	                    and se_estado      <> 'C')
	     begin
	        --print 'sp_seguros: LA OBLIGACION NO TIENE UN SEGURO VIGENTE ASOCIADO PARA CANCELAR CON ESTA FORMA DE PAGO'
	        return 708152
	     end
	     
	     select @w_saldo_seguro = isnull(sum(sed_cuota_cap - sed_pago_cap),0)
	     from ca_seguros_det
	     where sed_operacion    = @w_operacion	     	     
	     and sed_tipo_seguro    = @w_cod_seg		          
         
         select @w_am_pag_seg = isnull(abd_monto_mop,0)
         from cob_cartera..ca_abono,cob_cartera..ca_abono_det
         where ab_operacion = @w_operacion
         and ab_operacion = abd_operacion
         and ab_secuencial_ing = abd_secuencial_ing
         and ab_secuencial_pag = @i_secuencial_pago
			 		 		 
		 if @w_am_pag_seg < @w_saldo_seguro
		 begin
		    --print 'sp_seguros: EL VALOR INGRESADO NO ALCANZA A CUBRIR EL VALOR DEL SALDO DEL SEGURO - '+ @w_fpago
		    return 708152
		 end
		 
		 select @w_dtr_dividendo_pag = MIN(sed_dividendo) from ca_seguros_det 
		 where sed_operacion = @w_operacion	     	     
	     and sed_tipo_seguro = @w_cod_seg
	     and sed_estado      = @w_est_vigente
		 		 		 
		 update ca_seguros_det set
         sed_pago_cap  = isnull(sed_cuota_cap,0)
         from cob_cartera..ca_seguros
         where sed_sec_seguro = se_sec_seguro         
         and se_operacion  = @w_operacion
         and se_tramite    = @i_tramite
		 and sed_tipo_seguro = @w_cod_seg		 

		 if @@error <> 0
		 begin
	        --print 'Error actualizando sed_pago_cap para cancelacion de seguro'
	        return 708152
         end         

		 update ca_seguros_det set         
		 sed_cuota_int = 0,
		 sed_pago_int  = 0,
		 sed_cuota_mora = 0,      -- CCA 409
       sed_pago_mora  = 0       -- CCA 409
       from cob_cartera..ca_seguros
       where sed_sec_seguro = se_sec_seguro         
       and se_operacion     = @w_operacion
       and se_tramite       = @i_tramite
		 and sed_tipo_seguro  = @w_cod_seg		 
       and sed_pago_int     = 0
       and sed_pago_mora    = 0 -- CCA 409

		 if @@error <> 0
		 begin
	        --print 'Error actualizando sed_pago_cap para cancelacion de seguro'
	        return 708152
         end         
         
         insert into ca_seguros_can
         select
         se_sec_seguro, se_tipo_seguro,se_sec_renovacion,
         se_tramite   , se_operacion  ,GETDATE()        , 
         @i_secuencial_pago         
         from ca_seguros
         where se_tramite = @i_tramite
         and se_tipo_seguro = @w_cod_seg
         
         if @@error <> 0
         begin
            --print 'No se pudo insertar Seguros Cancelados, ca_seguros_can'
	        return 708154
         end		 		 	                  
         
         update ca_seguros set
         se_estado = 'C'
         where se_tramite = @i_tramite
         and se_tipo_seguro = @w_cod_seg

         if @@error <> 0
         begin
            --print 'No se pudo Actualizar el estado al Seguro Cancelado, ca_seguros'
	        return 708152
         end		 		 	                  
         
         break   -- Sale del While Principal
                                                                  			
	  end      -- FIN si la forma de pago es para cancelacion total de seguro
	  else     -- FORMA DE PAGO DIFERENTE A CANCELACION TOTAL DEL SEGURO 
	  begin

		  if @w_estado_di = 3 and @i_extraordinario <> 'S'  -- SI EL DIVIDENDO ESTA EN ESTADO CANCELADO      
		  begin 		  
              
			 if @w_dtr_concepto = 'CAP'
			 begin
				update ca_seguros_det set
				sed_pago_cap = sed_cuota_cap
				from cob_cartera..ca_seguros
				where sed_sec_seguro = se_sec_seguro
				and sed_dividendo = @w_dtr_dividendo
				and se_operacion  = @w_operacion
				and se_tramite    = @i_tramite

				if @@error <> 0
				begin
				   --print 'Error actualizando sed_pago_cap'
				   return 708152
				end                                                     
			 end
	         
			 if @w_dtr_concepto = 'INT'
			 begin
				update ca_seguros_det set
				sed_pago_int = sed_cuota_int
				from cob_cartera..ca_seguros
				where sed_sec_seguro = se_sec_seguro
				and sed_dividendo = @w_dtr_dividendo     
				and se_operacion  = @w_operacion
				and se_tramite    = @i_tramite 

				if @@error <> 0
				begin 
				   --print 'Error actualizando sed_pago_int'
				   return 708152
				end                                                          
			 end
			 
			 if @w_dtr_concepto in (select concepto from #concepto_mora_seg) -- CCA 409
          begin
               
             update ca_seguros_det set
             sed_pago_mora = sed_cuota_mora
             from cob_cartera..ca_seguros
             where sed_sec_seguro = se_sec_seguro
             and sed_dividendo = @w_dtr_dividendo     
             and se_operacion  = @w_operacion
             and se_tramite    = @i_tramite 	
               
             if @@error <> 0 
             begin 
                --print 'Error actualizando conceptos de mora'
                return 708152
             end                                                                                      		 
          end
	            
		  end -- Fin Dividendo Estado = 3 and @i_extraordinario <> 'S'   (PAGO COMPLETO CUOTA)
		  else
		  begin        
	         
			 -- CALCULO PONDERADO SEGUROS 
	        
			 --Busca el valor del pago y la cuota como esta actualmente

			 select @w_am_pagado = isnull(am_pagado,0),
					@w_am_cuota  = isnull(am_cuota,0)
			 from cob_cartera..ca_amortizacion
			 where am_operacion = @w_operacion
			 and am_dividendo = @w_dtr_dividendo
			 and am_concepto  = @w_dtr_concepto
	         
	       --Busca el valor del pago y la cuota que realmente correspondia
			 select @w_amh_pagado = isnull(amh_pagado,0),
					@w_amh_cuota  = isnull(amh_cuota,0)
			 from cob_cartera..ca_amortizacion_his
			 where amh_operacion = @w_operacion
			 and amh_dividendo   = @w_dtr_dividendo
			 and amh_concepto    = @w_dtr_concepto
			 and amh_secuencial  = @i_secuencial_pago
	         	         			 
	       -- Identifica si se hizo un pago extra
			 if (@w_am_cuota > @w_amh_cuota ) and (@w_amh_cuota > 0 ) 
			    select @w_porcenta_extra = (@w_am_cuota - @w_amh_cuota) / @w_amh_cuota
			 else
			    select @w_porcenta_extra = 0	         	         	         
	         	         
			 --Busca valor de la cuota total de todos los seguros del tramite
			 if @w_dtr_concepto = 'CAP'
			 begin
				select @w_vlr_tot = isnull(SUM(sed_cuota_cap),0)
				from cob_cartera..ca_seguros,cob_cartera..ca_seguros_det
				where se_sec_seguro = sed_sec_seguro
				and sed_dividendo = @w_dtr_dividendo
				and se_tramite    = @i_tramite
				and se_estado     <> 'C'
			 end 

			 if @w_dtr_concepto = 'INT'             
			 begin
				select @w_vlr_tot = isnull(SUM(sed_cuota_int),0)
				from cob_cartera..ca_seguros,cob_cartera..ca_seguros_det
				where se_sec_seguro = sed_sec_seguro
				and sed_dividendo = @w_dtr_dividendo
				and se_tramite    = @i_tramite
				and se_estado     <> 'C'
			 end    
			 if @w_dtr_concepto in (select concepto from #concepto_mora_seg)  -- CCA 409
          begin
             select @w_vlr_tot = isnull(SUM(sed_cuota_mora),0)
             from cob_cartera..ca_seguros,cob_cartera..ca_seguros_det
             where se_sec_seguro = sed_sec_seguro
             and sed_dividendo = @w_dtr_dividendo
             and se_tramite    = @i_tramite
             and se_estado     <> 'C'
          end                        
	         
			 -- Al valor total de la am_cuota se resta el valor de los seguros para obtener el valor de la obligacion
			 select @w_cuota_obligacion = isnull((@w_am_cuota - @w_vlr_tot),0)

			 -- Encontrar el valor aplicado a la obligacion
			 if @w_am_cuota > 0
			 begin
	            
				select @w_porc_obligacion = @w_cuota_obligacion / @w_am_cuota
				select @w_pago_obligacion = @w_porc_obligacion * @w_am_pagado            
	         
				 -- Valor que corresponde a pago de seguros y se debe distribuir entre los diferentes tipos que tenga el tramite
				 select @w_valor_pagado_seg = @w_am_pagado - @w_pago_obligacion
		                        
				 -- inserta en la temporal los el codigo de cada seguro del tramite en un estado Ingresado
				 insert into #seguros_pag
				 select 
				 se_sec_seguro     = st_secuencial_seguro,
				 se_tipo_seguro    = st_tipo_seguro      ,   
				 se_sec_renovacion = 0                   ,
				 se_sec_asegurado  = as_sec_asegurado    ,   -- CCA 409
				 se_tipo_asegurado = as_tipo_aseg        ,
				 se_monto_cap      = 0                   ,
				 se_monto_int      = 0                   ,
				 se_monto_imo      = 0                   ,
				 se_tramite        = @i_tramite          ,
				 se_estado         = 'I'                    
				 from cob_credito..cr_seguros_tramite, cob_credito..cr_asegurados
				 where st_tramite = @i_tramite         
				 and st_secuencial_seguro = as_secuencial_seguro
                 and as_tipo_aseg = (case when st_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)         				 

				 if @@error <> 0
				 begin
					--print 'No se pudo insertar en #seguros_pag'
					return 708154
				 end
		         		            
				 delete from #seguros_pag
				 where se_tipo_seguro in (select sec_tipo_seguro from ca_seguros_can,#seguros_pag 
										where sec_tramite = se_tramite and sec_tipo_seguro = se_tipo_seguro)
				   
				 if @@error <> 0
				 begin 
				    --print 'No Se Pudo Eliminar Tramites Cancelados al Pagar'
					return 708155
				 end		       
		         		            
				 -- Actualiza los montos o cuotas a pagar de cada seguro
				 update #seguros_pag set
				 se_monto_cap = sed_cuota_cap,
				 se_monto_int = sed_cuota_int,
				 se_monto_imo = sed_cuota_mora                 -- CCA 409    
				 from cob_cartera..ca_seguros_det
				 where sed_sec_seguro   = se_sec_seguro
				 and sed_tipo_seguro    = se_tipo_seguro
				 and sed_sec_renovacion = se_sec_renovacion
				 and sed_sec_asegurado  = se_sec_asegurado     -- CCA 409
				 and sed_tipo_asegurado = se_tipo_asegurado
				 and sed_dividendo      = @w_dtr_dividendo
				 and se_tramite         = @i_tramite         

				 if @@error <> 0
				 begin
					--print 'No se pudo actualizar montos en #seguros_pag'
					return 708152
				 end
		            
				 -- Recorre cada seguro por asegurado para pagar el porcentaje correspondiente
				 while 1 = 1
				 begin
		            
					set rowcount 1
		            
					if @w_dtr_concepto = 'CAP'
					begin         
					   select @w_monto_poliza   = isnull(se_monto_cap,0),
							  @w_sec_seguro     = se_sec_seguro,                            
							  @w_tipo_seguro    = se_tipo_seguro,
							  @w_sec_renovacion = se_sec_renovacion, 
							  @w_sec_asegurado  = se_sec_asegurado,       -- CCA 409
							  @w_tipo_asegurado = se_tipo_asegurado
					   from #seguros_pag
					   where se_estado = 'I'
					   order by se_sec_seguro
		            
					   if @@rowcount = 0 break
		                 
					end
					if @w_dtr_concepto = 'INT'
					begin
					   select @w_monto_poliza   = isnull(se_monto_int,0),
							  @w_sec_seguro     = se_sec_seguro,                            
							  @w_tipo_seguro    = se_tipo_seguro,
							  @w_sec_renovacion = se_sec_renovacion, 
							  @w_sec_asegurado  = se_sec_asegurado,         -- CCA 409
							  @w_tipo_asegurado = se_tipo_asegurado
					   from #seguros_pag
					   where se_estado = 'I'
					   order by se_sec_seguro
		            
					   if @@rowcount = 0 break               
					end
					
					if @w_dtr_concepto in (select concepto from #concepto_mora_seg)   -- CCA 409
               begin
                  select @w_monto_poliza   = isnull(se_monto_imo,0),
                         @w_sec_seguro     = se_sec_seguro,                            
                         @w_tipo_seguro    = se_tipo_seguro,
                         @w_sec_renovacion = se_sec_renovacion,
                         @w_sec_asegurado  = se_sec_asegurado,
                         @w_tipo_asegurado = se_tipo_asegurado
                  from #seguros_pag
                  where se_estado = 'I'
                  order by se_sec_seguro
                     		            
                  if @@rowcount = 0 break               
               end
		                  
					set rowcount 0
		            
		            if @w_vlr_tot <> 0
		            begin
		            
					   select @w_porc_pago = @w_monto_poliza / @w_vlr_tot
					   select @w_pago = round((@w_porc_pago + @w_porcenta_extra) * @w_valor_pagado_seg,0) 
					   
					   select @w_saldo_seguro_extra = SUM(sed_cuota_cap-sed_pago_cap)
					   from cob_cartera..ca_seguros_det, cob_cartera..ca_seguros
					   where sed_tipo_seguro = @w_tipo_seguro
					   and   se_tramite      = @i_tramite
					   and   se_operacion    = sed_operacion 
					   and   se_tipo_seguro  = sed_tipo_seguro 
					   
					   select @w_total_seguro_extra = SUM(sed_cuota_cap-sed_pago_cap)
					   from cob_cartera..ca_seguros_det, cob_cartera..ca_seguros
					   where sed_tipo_seguro = @w_tipo_seguro
					   and   se_tramite      = @i_tramite
					   and   se_operacion    = sed_operacion 
					   and   se_tipo_seguro  = sed_tipo_seguro 
					   and   sed_dividendo   = @w_dtr_dividendo
                       					   					  
					   if @w_pago >= @w_saldo_seguro_extra
					   begin

						   if @w_dtr_concepto = 'CAP'
						   begin
							  update ca_seguros_det set
							  sed_pago_cap = case when @w_total_seguro_extra > 0 then isnull(round(@w_saldo_seguro_extra,0),0) else sed_pago_cap + isnull(round(@w_saldo_seguro_extra,0),0) end, 
							  sed_cuota_cap = case when @w_total_seguro_extra > 0 then  isnull(round(@w_saldo_seguro_extra,0),0) else sed_cuota_cap + isnull(round(@w_saldo_seguro_extra,0),0) end, 
							  sed_estado    = @w_est_cancelado 
							  from cob_cartera..ca_seguros
							  where sed_sec_seguro   = @w_sec_seguro
							  and sed_tipo_seguro    = @w_tipo_seguro
							  and sed_sec_renovacion = @w_sec_renovacion
							  and sed_sec_asegurado  = @w_sec_asegurado       -- CCA 409
							  and sed_tipo_asegurado = @w_tipo_asegurado                                  
							  and sed_dividendo      = @w_dtr_dividendo
							  and sed_sec_seguro     = se_sec_seguro
							  and se_tramite         = @i_tramite

							  if @@error <> 0
							  begin
								 --print 'Error actualizando sed_pago_cap'
								 return 708152        
							  end                                                
						      
							  update ca_seguros_det set
							  sed_pago_cap = 0, 
							  sed_cuota_cap = 0,
							  sed_estado    = @w_est_cancelado 
							  from cob_cartera..ca_seguros
							  where sed_sec_seguro   = @w_sec_seguro
							  and sed_tipo_seguro    = @w_tipo_seguro
							  and sed_sec_renovacion = @w_sec_renovacion
							  and sed_sec_asegurado  = @w_sec_asegurado      -- CCA 409
							  and sed_tipo_asegurado = @w_tipo_asegurado                                  
							  and sed_dividendo      > @w_dtr_dividendo
							  and sed_sec_seguro     = se_sec_seguro
							  and se_tramite         = @i_tramite

							  if @@error <> 0
							  begin
								 --print 'Error actualizando sed_pago_cap'
								 return 708152        
							  end                                                
						   end
						   if @w_dtr_concepto = 'INT'
						   begin
							  update ca_seguros_det set
							  sed_cuota_int = 0,
							  sed_pago_int = 0
							  from cob_cartera..ca_seguros
							  where sed_sec_seguro   = @w_sec_seguro
							  and sed_tipo_seguro    = @w_tipo_seguro
							  and sed_sec_renovacion = @w_sec_renovacion
							  and sed_sec_asegurado  = @w_sec_asegurado     -- CCA 409
							  and sed_tipo_asegurado = @w_tipo_asegurado                                  
							  and sed_dividendo      > @w_dtr_dividendo
							  and sed_sec_seguro     = se_sec_seguro
							  and se_tramite         = @i_tramite
							  and sed_pago_int       = 0
			                    
							  if @@error <> 0
							  begin
								 --print 'Error actualizando sed_pago_int'
								 return 708152  
							  end
						   end
						   
						   if @w_dtr_concepto in (select concepto from #concepto_mora_seg)   -- CCA 409
                     begin
                        update ca_seguros_det set
                        sed_cuota_mora = 0,
                        sed_pago_mora  = 0
                        from cob_cartera..ca_seguros
                        where sed_sec_seguro   = @w_sec_seguro
                        and   sed_tipo_seguro    = @w_tipo_seguro
                        and   sed_sec_renovacion = @w_sec_renovacion
                        and   sed_sec_asegurado  = @w_sec_asegurado
                        and   sed_tipo_asegurado = @w_tipo_asegurado                                  
                        and   sed_dividendo      > @w_dtr_dividendo
                        and   sed_sec_seguro     = se_sec_seguro
                        and   se_tramite         = @i_tramite
                        and   sed_pago_mora      = 0
                        			                    
                        if @@error <> 0 
                        begin
                           --print 'Error actualizando sed_pago_mora'
                           return 708152  
                        end
                     end
						   
                     update ca_seguros set
                     se_estado = 'C'
                     where se_tramite   = @i_tramite
                     and se_tipo_seguro = @w_tipo_seguro

                     if @@error <> 0
                     begin
                        --print 'Error actualizando ca_seguro para cancelar el seguro'
                        return 708152  
                     end
                           
						  insert into ca_seguros_can
						  select
						  se_sec_seguro, se_tipo_seguro,se_sec_renovacion,
						  se_tramite   , se_operacion  ,GETDATE()        , 
						  @i_secuencial_pago         
						  from ca_seguros
						  where se_tramite = @i_tramite
						  and se_estado = 'C'
						  and se_tipo_seguro = @w_tipo_seguro
					         
						  if @@error <> 0
						  begin
							 --print 'No se pudo insertar Seguros Cancelados, ca_seguros_can'
						  return 708154
						  end		 		 	                                                                                                                                                         
                                  
					   end   -- FIN @w_pago >= @w_saldo_seguro_extra
				      else
				      begin				                  
					      if @w_dtr_concepto = 'CAP' begin
					      update ca_seguros_det set
					      sed_pago_cap = isnull(round(@w_pago,0),0), 
					      sed_cuota_cap = case when @w_porcenta_extra > 0 then isnull(@w_pago,0) else isnull(sed_cuota_cap,0) end
					      from cob_cartera..ca_seguros
					      where sed_sec_seguro   = @w_sec_seguro
					      and sed_tipo_seguro    = @w_tipo_seguro
					      and sed_sec_renovacion = @w_sec_renovacion
					      and sed_sec_asegurado  = @w_sec_asegurado    -- CCA 409
					      and sed_tipo_asegurado = @w_tipo_asegurado                                  
					      and sed_dividendo      = @w_dtr_dividendo
					      and sed_sec_seguro     = se_sec_seguro
					      and se_tramite         = @i_tramite

					      if @@error <> 0
					      begin
						     --print 'Error actualizando sed_pago_cap'
						     return 708152        
					      end                                                
					      end
		         
					      if @w_dtr_concepto = 'INT'
					      begin
					         update ca_seguros_det set
					         sed_pago_int = case when @i_extraordinario <> 'S' then isnull(round(@w_pago,0),0) else isnull(sed_cuota_int,0) end 			   
					         from cob_cartera..ca_seguros
					         where sed_sec_seguro   = @w_sec_seguro
					         and sed_tipo_seguro    = @w_tipo_seguro
					         and sed_sec_renovacion = @w_sec_renovacion
					         and sed_sec_asegurado  = @w_sec_asegurado      -- CCA 409
					         and sed_tipo_asegurado = @w_tipo_asegurado                                  
					         and sed_dividendo      = @w_dtr_dividendo
					         and sed_sec_seguro     = se_sec_seguro
					         and se_tramite         = @i_tramite
   		                    
					         if @@error <> 0
					         begin
						        --print 'Error actualizando sed_pago_int'
						        return 708152  
					         end
					      end                                                                                      

                     if @w_dtr_concepto in (select concepto from #concepto_mora_seg)   -- CCA 409
                     begin
                        update ca_seguros_det set
                        sed_pago_mora = case when @i_extraordinario <> 'S' then isnull(round(@w_pago,0),0) else isnull(sed_cuota_mora,0) end 			   
                        from cob_cartera..ca_seguros
                        where sed_sec_seguro     = @w_sec_seguro
                        and   sed_tipo_seguro    = @w_tipo_seguro
                        and   sed_sec_renovacion = @w_sec_renovacion
                        and   sed_sec_asegurado  = @w_sec_asegurado
                        and   sed_tipo_asegurado = @w_tipo_asegurado                                  
                        and   sed_dividendo      = @w_dtr_dividendo
                        and   sed_sec_seguro     = se_sec_seguro
                        and   se_tramite         = @i_tramite
		  		       					       					       					       		                    
                        if @@error <> 0 
                        begin
                           --print 'Error actualizando sed_pago_mora'
                           return 708152  
                        end
                     end                                                                                                              
					   end   -- FIN  NO SE CUMPLE @w_pago >= @w_saldo_seguro_extra
					end      -- FIN @w_vlr_tot <> 0 

					update #seguros_pag set 
					se_estado = 'P'
					where se_sec_seguro   = @w_sec_seguro              
					and se_tipo_seguro    = @w_tipo_seguro
					and se_sec_renovacion = @w_sec_renovacion
					and se_sec_asegurado  = @w_sec_asegurado         -- CCA 409
					and se_tipo_asegurado = @w_tipo_asegurado                                                      
					and se_estado = 'I'     
					
					--if @w_porcenta_extra > 0 and @i_extraordinario = 'S' break
		                             
				 end -- FIN Recorre cada seguro para pagar el porcentaje correspondiente
			 end	  -- FIN @w_am_cuota > 0	  
		  end       -- CALCULO PONDERADO SEGUROS
	      
		  update #detalle_trn 
		  set dtr_estado_pro = 'P'
		  where dtr_secuencial = @w_dtr_secuencial
		  and dtr_dividendo = @w_dtr_dividendo
		  and dtr_concepto  = @w_dtr_concepto        
		  and dtr_monto_mn  = @w_dtr_monto
		  and dtr_estado    = @w_estado_di
		  and dtr_estado_pro = 'I'
	       
		  if @@error <> 0
		  begin 
			 --print 'Error actualizando #detalle_trn'
			 return 708152  
		  end
		                                                                                            
		  delete #seguros_pag  
		  
		  if @w_porcenta_extra > 0 break
		  
      end   -- FIN FORMA DE PAGO DIFERENTE A CANCELACION TOTAL DEL SEGURO 
   end  -- Fin del While Principal (RECORRE DETALLE DE LA TRANSACCION)
   
   set rowcount 0
   
   -- Actualza el estados de los dividendos que se encuentren cancelados tanto capital como interes
   update ca_seguros_det with (rowlock) set
   sed_estado = @w_est_cancelado,
   sed_pago_cap = sed_cuota_cap,
   sed_pago_int = sed_cuota_int,
   sed_pago_mora = sed_cuota_mora
   from ca_dividendo 
   where sed_operacion =  @w_operacion 
   and sed_pago_cap >= sed_cuota_cap 
   and sed_operacion = di_operacion 
   and sed_dividendo = di_dividendo 
   and di_estado = @w_est_cancelado
   
   
   if @@error <> 0
   begin
      --print 'Error actualizando ca_seguros_det para cancelacion de cuotas'
      return 708152  
   end   
   
   -- Valida que todos los dividendos se encuentren cancelados
   if not exists (select 1 from cob_cartera..ca_seguros_det, ca_seguros
                 where sed_sec_seguro = se_sec_seguro
                 and sed_estado <> @w_est_cancelado
                 and se_tramite = @i_tramite)
   begin   
      -- Si todos los dividendos estan cancelados actualiza el estado a Cancelado en la ca_seguros
      update ca_seguros set
      se_estado = 'C'
      where se_tramite = @i_tramite

      if @@error <> 0 begin
         --print 'Error actualizando ca_seguro para cancelar el seguro'
         return 708152  
      end         

      insert into ca_seguros_can
      select
      se_sec_seguro, se_tipo_seguro,se_sec_renovacion,
      se_tramite   , se_operacion  ,GETDATE()        , 
      @i_secuencial_pago         
      from ca_seguros
      where se_tramite = @i_tramite
      and se_estado = 'C'
         
      if @@error <> 0 begin
         --print 'No se pudo insertar Seguros Cancelados, ca_seguros_can'
      return 708154
      end		 		 	                  
               
   end  -- Fin Valida que todos los dividendos se encuentren cancelados
   
end  -- fin opcion P

if @i_opcion = 'A'
begin --> Desgloce para consultas en línea
   
   create table #seguros_desgloce(
   des_sec_seguro       int,
   des_tipo_seguro      int,
   des_desc_seguro      catalogo,
   des_tipo_asegurado   int,
   des_tramite          int,
   des_capital          money,
   des_capital_pag      money,
   des_interes          money,
   des_interes_pag      money,
   des_interes_mora     money,      -- CCA 409
   des_interes_mora_pag money       -- CCA 409
   )
   
   insert into #seguros_desgloce
   select 
   des_sec_seguro      = se_sec_seguro ,
   des_tipo_seguro     = sed_tipo_seguro      ,
   des_desc_seguro     = ''                   ,   
   des_tipo_asegurado  = sed_tipo_asegurado   ,
   des_tramite         = se_tramite           ,
   des_capital         = isnull(sed_cuota_cap,0),              
   des_capital_pag     = isnull(sed_pago_cap,0) ,
   des_interes         = isnull(sed_cuota_int,0),
   des_interes_pag     = isnull(sed_pago_int,0),
   des_interes_mora     = isnull(sed_cuota_mora,0),
   des_interes_mora_pag = isnull(sed_pago_mora,0)
   from cob_cartera..ca_seguros, cob_cartera..ca_seguros_det
   where se_sec_seguro = sed_sec_seguro   
   and se_tramite = @w_tramite 
   
   if @@error <> 0
   begin
      --print 'No se encuentran tramites #seguros_desgloce'
      return 710029
   end
      
   update #seguros_desgloce set 
   des_desc_seguro = codigo_sib
   from cob_credito..cr_corresp_sib
   where codigo = des_tipo_seguro
   and tabla = 'T155'
   
   if @@error <> 0
   begin
      --print 'Error actualizando ##seguros_desgloce'
      return 708152                        
   end   
   
   select 
   'Seguro'     = des_desc_seguro               ,
   'Capital'    = isnull(sum(des_capital),0)    ,
   'Cap Pagado' = isnull(sum(des_capital_pag),0),
   'Interes'    = isnull(sum(des_interes),0)    ,
   'Int Pagado' = isnull(sum(des_interes_pag),0),
   'Int Mora'     = isnull(sum(des_interes_mora),0),    -- CCA 409
   'Int Pag Mora' = isnull(sum(des_interes_mora_pag),0) -- CCA 409
   from #seguros_desgloce
   group by des_tipo_seguro,des_desc_seguro
   order by des_tipo_seguro
   
end

if @i_opcion = 'R' begin --> RENOVACION    detalles de seguros     
  
   -- Selecciona datos de la operacion nueva
   select @w_banco_renovado     = op_anterior,
          @w_monto_nuevo        = op_monto,
          @w_fecha_fin_op_nueva = op_fecha_fin,
          @w_fecha_ini_op_nueva = op_fecha_ini
   from ca_operacion with (nolock)
   where op_tramite = @i_tramite
   
   -- selecciona los datos de la operacion renovada
   select @w_tramite_renovado = op_tramite   
   from cob_cartera..ca_operacion with (nolock)
   where op_banco = @w_banco_renovado
   
   -- actualiza el secuencial de renovacion poniendole el tramite nuevo y deja el tramite en estado Renovado
   update ca_seguros set
   se_sec_renovacion = @i_tramite,
   se_estado         = 'R'
   where se_tramite = @w_tramite_renovado
   
   if @@error <> 0
   begin
      --print 'Error actualizando ca_seguros para Renovaciones'
      return 708152  
   end   
   
   -- actualiza el secuencial de renovacion poniendole el tramite nuevo
   update ca_seguros_det set   
   sed_sec_renovacion = @i_tramite
   from ca_seguros
   where se_sec_seguro = sed_sec_seguro
   and se_tramite = @w_tramite_renovado

   if @@error <> 0 begin
      --print 'Error actualizando ca_seguros_det para Renovaciones'
      return 708152  
   end   
         
end


return 0
go
