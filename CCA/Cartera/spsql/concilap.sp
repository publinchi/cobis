/************************************************************************/
/*      Archivo:                conciliap.sp                            */
/*      Stored procedure:       sp_conciliacion_activa_pasiva           */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */      
/*      Fecha de escritura:     Feb  2003                               */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/************************************************************************/  
/*                              PROPOSITO                               */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      21/Feb/2003     m. Mari¤o      Emision Inicial		            */
/*      01/Dic/2006     E. Pelaez      defecto -7536 BAC		        */
/*      03/Sep/2007     John Jairo Rendon OPT_233                       */
/*      19/Abr/2022     K. Rodríguez   Cambio catálogo destino finan. op*/
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_conciliacion_activa_pasiva')
	drop proc sp_conciliacion_activa_pasiva
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_conciliacion_activa_pasiva
				(@i_fecha_proceso	datetime)

as
declare 
	@w_error			                 int,
	@w_sp_name			              descripcion,
	@w_hay_valor			           catalogo,
	@w_cu_operacion			        int,
	@w_operacion_activa		        int,
	@w_operacion_pasiva		        int,	
	@w_cu_banco			              cuenta,
	@w_banco_activa			        cuenta,
	@w_banco_pasiva			        cuenta,
	@w_cu_tramite			           int, 
	@w_cu_cliente			           int,
	@w_cu_codigo_externo		        cuenta,
	@w_cu_nombre			           descripcion,
	@w_cu_tipo_linea		           catalogo,
	@w_cu_margen_redescuento 	     float,
	@w_cu_toperacion		           catalogo,
	@w_cu_edad			              int,
	@w_cu_destino			           catalogo,
	@w_cu_oficina			           smallint,
	@w_cu_monto			              money,
	@w_cu_fecha_ini			        datetime,
	@w_cu_moneda			           tinyint,
	@w_cu_sector			           catalogo,
	@w_cu_tdividendo		           catalogo,
	@w_num_dec_op            	     int,
	@w_mon_mn	                    smallint,
	@w_num_dec_n			           smallint,
	@w_return			              int,
	@w_cap_pas_sin_act		        varchar(1),
	@w_cap_pas_salmayor_act		     varchar(1),
   	@w_cotizacion_om                money,
	@w_cap_nomora_saldodiff		     varchar(1),
	@w_cap_pas_tasamayo_act 	     varchar(1),
	@w_cap_act_sin_pas		        varchar(1),
	@w_saldo_cap_pasiva		        money,
	@w_saldo_cap_activa		        money,
	@w_tasa_nom_pasiva		        float,
	@w_tasa_nom_activa		        float,
	@w_signo			                 char,
	@w_factor			              money,
	@w_fpago			                 char(1),
	@w_referencial			           catalogo,
	@w_tasa_referencial 		        varchar(10),
	@w_dias_vencidos_op		        int,
	@w_modalidad			           char(1),
	@w_puntos_c			              varchar(10),
	@w_formula_tasa_pasiva		     varchar(30),
	@w_formula_tasa_activa		     varchar(30),
	@w_fecha_fin_min_div_ven	     datetime,
	@w_cod_tipo_productor		     varchar(30),
	@w_desc_tipo_productor		     descripcion,
	@w_numero_identificacion	     numero,
	@w_desc_destino			        descripcion,
	@w_desc_tipo_linea		        descripcion,
	@w_numero_pagare 		           varchar(64),
	@w_norma_legal			           varchar(255),
	@w_regional			              int,
   @w_producto           		     tinyint,
   @w_ie_fecha_proceso             datetime,	  
   @w_moneda_nacional              tinyint,
   @w_pago                         money,
	@w_cap_valor_desembolso         money,
   @w_moneda_activa                smallint,
   @w_ms                           datetime,
   @w_date                         datetime,
   @w_op_fecha_ini                 datetime,
   @w_op_tipo			              char(1),
   @w_tramite_activa               int,
   @w_fecha_fin_min_div_ven_act    datetime,
   @w_dias_vencidos_op_act         int

  
---  NOMBRE DEL SP  
select  @w_sp_name = 'sp_conciliacion_activa_pasiva', 
        @w_date    = getdate()

if exists ( select 1 from ca_conciliacion_act_pas where cap_fecha_proceso = @i_fecha_proceso)
	print 'Reproceso de fecha' + cast(@i_fecha_proceso as varchar)
else
	truncate table  ca_conciliacion_act_pas


select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


--- RECORRE PASIVAS BUSCANDO ACTIVAS
create table #oper
(
	op_operacion                   int,
	op_banco                       cuenta
)

insert into #oper
select 
op_operacion,op_banco
from cob_cartera..ca_operacion
where op_estado not in (0,99,6,3)
and op_tipo in('C','R') 

delete #oper
from cob_cartera..ca_conciliacion_act_pas
where cap_obligacion_activa = op_banco

delete #oper
from cob_cartera..ca_conciliacion_act_pas
where cap_obligacion_pasiva = op_banco


declare cursor_operacion cursor for
select 
op_operacion,	op_banco
from #oper
for read only

open cursor_operacion

fetch cursor_operacion into
@w_cu_operacion,@w_cu_banco

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin

select 
@w_cu_tramite=op_tramite,		  
@w_cu_cliente=op_cliente,   
@w_cu_codigo_externo=op_codigo_externo,
@w_cu_nombre=op_nombre,	
@w_cu_tipo_linea=op_tipo_linea,
@w_cu_margen_redescuento=op_margen_redescuento,
@w_cu_toperacion=op_toperacion,
@w_cu_edad=op_edad,
@w_cu_destino=op_destino,	
@w_cu_oficina=op_oficina,   
@w_cu_monto=op_monto,	  	  
@w_cu_fecha_ini=op_fecha_liq, 
@w_cu_moneda=op_moneda,
@w_cu_sector=op_sector,	
@w_cu_tdividendo=op_tdividendo,
@w_ie_fecha_proceso=op_fecha_ult_proceso,	  
@w_op_fecha_ini=op_fecha_ini, 
@w_op_tipo=op_tipo	
from ca_operacion
where op_operacion = @w_cu_operacion


   select @w_num_dec_n             = 0,		@w_num_dec_op           = 0,          	@w_mon_mn     		= 0,
          @w_regional              = null,    	@w_cap_pas_sin_act      = '', 		@w_operacion_activa 	= -1,
   	  @w_banco_activa          = '',     	@w_moneda_activa        = null, 	@w_cap_pas_salmayor_act = '',
          @w_saldo_cap_pasiva      = null,   	@w_saldo_cap_activa     = null,     	@w_pago 		= 0,
          @w_cotizacion_om         = 1,         @w_cap_pas_tasamayo_act = '',   	@w_tasa_nom_activa 	= null,
          @w_tasa_nom_pasiva       = null,    	@w_cap_nomora_saldodiff = '',   	@w_dias_vencidos_op 	= null,
          @w_fecha_fin_min_div_ven = '',        @w_cap_act_sin_pas      = ''


   --- FORMULA TASA ACTIVA
   select @w_formula_tasa_activa = '',		@w_tasa_referencial = null,		@w_signo = null,
      	  @w_factor = 0.00,			@w_referencial = null

  -- FORMULA TASA PASIVA
   select @w_tasa_referencial = null,      	@w_signo = null,			@w_factor = 0.00,
    	  @w_fpago            = '',      	@w_puntos_c = '',             		@w_formula_tasa_pasiva = ''
             

  --- NUMERO DE DECIMALES
   exec @w_return = sp_decimales
   @i_moneda       = @w_cu_moneda,
   @o_decimales    = @w_num_dec_op out,
   @o_mon_nacional = @w_mon_mn out,
   @o_dec_nacional = @w_num_dec_n out	


   --- CODIGO DE LA REGIONAL

   select @w_regional = null

   select @w_regional = of_regional
   from   cobis..cl_oficina
   where  of_oficina = @w_cu_oficina
   set transaction isolation level read uncommitted

 


   --- DATOS PARA LAS OBLIGACIONES PASIVAS
   /*************************************/
   if @w_op_tipo = 'R'
   begin


      /*VALIDACIONES No 1 --> PASIVAS QUE NO TIENEN ACTIVAS RELACIONADAS*/
      select @w_operacion_activa = rp_activa
      from  ca_relacion_ptmo
      where rp_pasiva = @w_cu_operacion
      if @@rowcount = 0
         select @w_cap_pas_sin_act = 'S' 
      else 
      begin
         select @w_banco_activa  = op_banco,
                @w_moneda_activa = op_moneda,
                @w_tramite_activa = op_tramite
         from ca_operacion		
         where op_operacion = @w_operacion_activa
      end


      --- VALIDACION No 2 --> PASIVAS DONDE SALDO DE CAPITAL MAYOR QUE EL DE LA ACTIVA
      --- SALDO CAPITAL PASIVA
      select @w_saldo_cap_pasiva = isnull(sum(am_cuota+am_gracia-am_pagado),0)
      from ca_amortizacion,ca_rubro_op
      where am_operacion = @w_cu_operacion --pasiva
      and ro_operacion   = @w_cu_operacion
      and am_concepto    = ro_concepto
      and ro_tipo_rubro  = 'C' -- Capitales

      select @w_saldo_cap_pasiva = isnull(round(@w_saldo_cap_pasiva,@w_num_dec_n),0)




      -- SALDO CAPITAL ACTIVA 
      if @w_cap_pas_sin_act <> 'S'
      begin
         select @w_saldo_cap_activa = isnull(sum(am_cuota+am_gracia-am_pagado),0)
         from ca_amortizacion,ca_rubro_op
         where am_operacion = @w_operacion_activa 
         and ro_operacion   = @w_operacion_activa 
         and am_concepto    = ro_concepto
         and ro_tipo_rubro  = 'C' -- Capitales

         if @w_moneda_activa <> @w_moneda_nacional 
         begin
            exec sp_buscar_cotizacion
            @i_moneda     = @w_moneda_activa,
            @i_fecha      = @i_fecha_proceso,
            @o_cotizacion = @w_cotizacion_om output
          
            select  @w_pago             = @w_saldo_cap_activa * @w_cotizacion_om
            select  @w_saldo_cap_activa = round(@w_pago,0)
         end
       

         --- VALIDACION --> REPORTE DE PASIVAS CON SALDOS MAYOR QUE LA ACTIVA
         if isnull(@w_saldo_cap_pasiva,0) <> 0 and isnull(@w_saldo_cap_activa,0) <> 0
         begin
            if @w_saldo_cap_pasiva > @w_saldo_cap_activa
	       select @w_cap_pas_salmayor_act = 'S'
         end 

      end 


      --- VALIDACION No.4 --> REPORTE DE PASIVAS Y ACTIVAS CON CERO DIAS DE MORA Y CON SALDOS DIFERENTES

      select @w_fecha_fin_min_div_ven = min(di_fecha_ven) 
      from ca_dividendo
      where di_operacion = @w_cu_operacion
      and   di_estado = 2 
      if @@rowcount <> 0
         select @w_dias_vencidos_op = isnull(datediff(dd,@w_fecha_fin_min_div_ven,@i_fecha_proceso),0)
      else
         select @w_dias_vencidos_op = 0



      --- DIAS MORA ACTIVA
      select @w_fecha_fin_min_div_ven_act = min(di_fecha_ven) 
      from ca_dividendo
      where di_operacion = @w_operacion_activa
      and   di_estado = 2 
      if @@rowcount <> 0
         select @w_dias_vencidos_op_act = isnull(datediff(dd,@w_fecha_fin_min_div_ven_act,@i_fecha_proceso),0)
      else
         select @w_dias_vencidos_op_act = 0




      if @w_saldo_cap_pasiva >= 0 and @w_saldo_cap_activa > 0
      begin
         if @w_dias_vencidos_op = 0 and  @w_dias_vencidos_op_act = 0 and @w_saldo_cap_pasiva <> @w_saldo_cap_activa and @w_cap_pas_sin_act <> 'S' 
            select @w_cap_nomora_saldodiff = 'S'

      end
      --- VALIDACION No. 5 --> REPORTE DE OPERACIONES PASIVAS DONDE LA TASA ES MAYOR A LA TASA DE LA OPERACION ACTIVA
      --TASA NOMINAL DE O. PASIVA
      select @w_tasa_nom_pasiva = round(ro_porcentaje,4)
      from ca_rubro_op
      where ro_operacion = @w_cu_operacion
      and ro_tipo_rubro = 'I'--Interes
   
      --TASA NOMINAL DE O. ACTIVA
      if @w_cap_pas_sin_act <> 'S'
      begin
         select @w_tasa_nom_activa = round(ro_porcentaje,4)
         from ca_rubro_op
         where ro_operacion = @w_operacion_activa
         and ro_tipo_rubro = 'I'--Interes
      end 
   
      if isnull(@w_tasa_nom_pasiva,0) <> 0 and isnull(@w_tasa_nom_activa,0) <> 0
      begin
    	 if @w_tasa_nom_pasiva > @w_tasa_nom_activa
   	    select @w_cap_pas_tasamayo_act =  'S'
      end
      select @w_signo = ro_signo,
   	       @w_factor = convert(money,ro_factor),
             @w_fpago = ro_fpago,
             @w_referencial = ro_referencial
      from ca_rubro_op
      where ro_operacion = @w_cu_operacion
      and ro_tipo_rubro = 'I'

      select @w_tasa_referencial = vd_referencia
      from ca_valor_det
      where vd_tipo = @w_referencial
      and vd_sector = @w_cu_sector
   
      if @w_tasa_referencial = '' or @w_tasa_referencial is null
         select @w_tasa_referencial = @w_referencial
	
      /*MODALIDAD TASA*/
      select @w_modalidad = 'V' --por defecto

      if @w_fpago = 'P'
         select @w_modalidad = 'V'

      if @w_fpago = 'A'
         select @w_modalidad = 'A'

      select @w_puntos_c = convert(varchar(10),@w_factor)

      select @w_formula_tasa_pasiva = @w_tasa_referencial+@w_signo+@w_puntos_c+'('+rtrim(ltrim(@w_cu_tdividendo))+rtrim(ltrim(@w_modalidad))+')'
      select @w_formula_tasa_pasiva = rtrim(ltrim(@w_formula_tasa_pasiva))
   
      if @w_cap_pas_sin_act <> 'S'
      begin		
         select @w_signo = ro_signo,
  	        @w_factor = convert(money,ro_factor),
	        @w_fpago = ro_fpago,
  	        @w_referencial = ro_referencial
         from ca_rubro_op
         where ro_operacion = @w_operacion_activa
         and ro_tipo_rubro = 'I'

         select @w_tasa_referencial = vd_referencia
         from ca_valor_det
         where vd_tipo = @w_referencial
         and vd_sector = @w_cu_sector
		
         if @w_tasa_referencial = '' or @w_tasa_referencial is null
            select @w_tasa_referencial = @w_referencial

         --- MODALIDAD TASA
         select @w_modalidad = 'V' --por defecto

         if @w_fpago = 'P'
	    select @w_modalidad = 'V'

         if @w_fpago = 'A'
	    select @w_modalidad = 'A'

         select @w_puntos_c = convert(varchar(10),@w_factor)

         select @w_formula_tasa_activa = @w_tasa_referencial+@w_signo+@w_puntos_c+'('+rtrim(ltrim(@w_cu_tdividendo))+rtrim(ltrim(@w_modalidad))+')'
	
         select @w_formula_tasa_activa = rtrim(ltrim(@w_formula_tasa_activa))

      end -- if @w_cap_pas_sin_act <> 'S'
	

      --- TIPO PRODUCTOR
      select @w_cod_tipo_productor = ''

      select @w_cod_tipo_productor = isnull(tr_tipo_productor,'01')
      from cob_credito..cr_tramite
      where tr_tramite = @w_cu_tramite

      select @w_desc_tipo_productor = ''

      select @w_desc_tipo_productor = valor
      from cobis..cl_catalogo
      where tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_tipo_productor')
      and codigo = @w_cod_tipo_productor
      set transaction isolation level read uncommitted


      --- NUMERO IDENTIFICACION
      select @w_numero_identificacion = null
   
      select @w_numero_identificacion = en_ced_ruc
      from cobis..cl_ente
      where en_ente = @w_cu_cliente
      set transaction isolation level read uncommitted
  
      select @w_desc_destino = null
	
      select @w_desc_destino = valor
      from cobis..cl_catalogo
      where tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_objeto')
      and codigo = @w_cu_destino
      set transaction isolation level read uncommitted

      select @w_desc_tipo_linea = null

      select @w_desc_tipo_linea = valor
      from cobis..cl_catalogo
      where tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_tipo_linea')
      and codigo = @w_cu_tipo_linea
      set transaction isolation level read uncommitted

      select @w_numero_pagare = ''

      select @w_numero_pagare = gp_garantia
      from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia
      where gp_tramite = @w_tramite_activa   ---@w_cu_tramite
      and gp_garantia  = cu_codigo_externo
      and cu_tipo      = '6100'


      select @w_norma_legal = ''

      select @w_norma_legal = dt_valor
      from cob_credito..cr_datos_tramites
      where dt_dato = 'NL'
      and dt_tramite = @w_cu_tramite
   end 
   --- DATOS PARA LAS OBLIGACIONES ACTIVAS

   if @w_op_tipo = 'C'
   begin
      select @w_banco_pasiva          = null 
      select @w_saldo_cap_pasiva      = 0
      select @w_formula_tasa_pasiva   = null
      select @w_tasa_nom_pasiva       = null
      select @w_cap_pas_sin_act       = ''
      select @w_cap_pas_salmayor_act  = ''
      select @w_cap_nomora_saldodiff  = ''
      select @w_cap_pas_tasamayo_act  = ''
      select @w_ie_fecha_proceso      = null
      select @w_cap_act_sin_pas       = ''
      select @w_operacion_pasiva      = 0


      --- VALIDACIONES No 1 --> ACTIVAS QUE NO TIENEN PASIVAS RELACIONADAS

      select @w_operacion_pasiva = isnull(rp_pasiva,0)
      from ca_relacion_ptmo
      where rp_activa = @w_cu_operacion

      if @w_operacion_pasiva = 0
	 select @w_cap_act_sin_pas = 'S' -- no tiene pasiva relacionada
      else
      begin
         select @w_banco_pasiva = op_banco
	 from ca_operacion		
	 where op_operacion = @w_operacion_pasiva
      end

      if @w_cap_act_sin_pas <> ''
      begin
	 select @w_saldo_cap_activa = null

 	 --- SALDO CAPITAL ACTIVA
	 select @w_saldo_cap_activa = isnull(sum(am_cuota+am_gracia-am_pagado),0)
	 from ca_amortizacion,ca_rubro_op
	 where am_operacion = @w_cu_operacion 
	 and ro_operacion   = @w_cu_operacion 
	 and am_concepto    = ro_concepto
	 and ro_tipo_rubro  = 'C' -- Capitales

	 select @w_saldo_cap_activa = round(@w_saldo_cap_activa,@w_num_dec_op)

         if @w_cu_moneda <> @w_moneda_nacional 
         begin
            exec sp_buscar_cotizacion
            @i_moneda     = @w_cu_moneda,
            @i_fecha      = @i_fecha_proceso,
            @o_cotizacion = @w_cotizacion_om output
         
            select  @w_pago             = @w_saldo_cap_activa * @w_cotizacion_om
            select  @w_saldo_cap_activa = round(@w_pago,0)
         end

  	 select @w_dias_vencidos_op = null
 	 select @w_fecha_fin_min_div_ven = ''

         select @w_fecha_fin_min_div_ven = min(di_fecha_ven) 
         from ca_dividendo
         where di_operacion = @w_cu_operacion
    	 and di_estado = 2 
    	
         if @@rowcount <> 0
	    select @w_dias_vencidos_op = isnull(datediff(dd,@w_fecha_fin_min_div_ven,@i_fecha_proceso),0)
         else
      	    select @w_dias_vencidos_op = 0

  	 select @w_tasa_nom_activa = null
	
	 --- TASA NOMINAL DE O. ACTIVA
	 select @w_tasa_nom_activa = round(ro_porcentaje,4)
	 from ca_rubro_op
	 where ro_operacion = @w_cu_operacion
	 and ro_tipo_rubro = 'I'--Interes

	 --- FORMULA TASA ACTIVA
	 select @w_formula_tasa_activa = '' 
	 select @w_tasa_referencial = null
	 select @w_signo = null
	 select @w_factor = 0.00
	 select @w_referencial = null
         select @w_fpago = ''

	 select @w_signo  = ro_signo,
	        @w_factor = convert(money,ro_factor),
		@w_fpago  = ro_fpago,
		@w_referencial = ro_referencial
	 from ca_rubro_op
	 where ro_operacion = @w_cu_operacion
	 and ro_tipo_rubro = 'I'

	 select @w_tasa_referencial = vd_referencia
	 from ca_valor_det
	 where vd_tipo = @w_referencial
	 and vd_sector = @w_cu_sector
	  	
         if @w_tasa_referencial = '' or @w_tasa_referencial is null
            select @w_tasa_referencial = @w_referencial

  	 --- MODALIDAD TASA
	 select @w_modalidad = 'V' --por defecto

	 if @w_fpago = 'P'
	    select @w_modalidad = 'V'

  	 if @w_fpago = 'A'
	    select @w_modalidad = 'A'

    	 select @w_puntos_c = convert(varchar(10),@w_factor)
	 select @w_formula_tasa_activa = @w_tasa_referencial+@w_signo+@w_puntos_c+'('+rtrim(ltrim(@w_cu_tdividendo))+rtrim(ltrim(@w_modalidad))+')'
	 select @w_formula_tasa_activa = rtrim(ltrim(@w_formula_tasa_activa))
	
	 --- TIPO PRODUCTOR
	 select @w_cod_tipo_productor = ''
	 select @w_cod_tipo_productor = en_casilla_def
	 from cobis..cl_ente
	 where en_ente = @w_cu_cliente
	 set transaction isolation level read uncommitted

	 select @w_desc_tipo_productor = ''
	 select @w_desc_tipo_productor = valor
	 from cobis..cl_catalogo
	 where tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_tipo_productor')
 	 and codigo = @w_cod_tipo_productor
	 set transaction isolation level read uncommitted

	 --- NUMERO IDENTIFICACION
	 select @w_numero_identificacion = null
	 select @w_numero_identificacion = en_ced_ruc
	 from cobis..cl_ente
	 where en_ente = @w_cu_cliente
	 set transaction isolation level read uncommitted

 	 select @w_desc_destino = null
	 select @w_desc_destino = valor
	 from cobis..cl_catalogo
	 where tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_objeto')
 	 and codigo = @w_cu_destino
	 set transaction isolation level read uncommitted

	 select @w_desc_tipo_linea = null
	 select @w_desc_tipo_linea = valor
	 from cobis..cl_catalogo
 	 where tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_tipo_linea')
	 and codigo = @w_cu_tipo_linea
	 set transaction isolation level read uncommitted

	 select @w_numero_pagare = ''
	 select @w_numero_pagare = gp_garantia
	 from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia
	 where gp_tramite = @w_cu_tramite
	 and gp_garantia = cu_codigo_externo
	 and cu_tipo = '6100'

	 select @w_norma_legal = ''
	 select @w_norma_legal = dt_valor
	 from cob_credito..cr_datos_tramites
	 where dt_dato = 'NL'
	 and dt_tramite = @w_cu_tramite

         --- VALOR DESEMBOLSO 
         select @w_cap_valor_desembolso = 0

         select @w_cap_valor_desembolso =  isnull(sum(dm_monto_mn),0) 
         from ca_desembolso
         where dm_operacion = @w_cu_operacion
         and dm_estado = 'A'
      end
   end

   if @w_cap_pas_sin_act <> '' or @w_cap_pas_salmayor_act <> '' or @w_cap_nomora_saldodiff <> '' or @w_cap_pas_tasamayo_act <> '' or @w_cap_act_sin_pas <> ''
   begin
      if @w_op_tipo = 'R'
      begin
         insert into ca_conciliacion_act_pas 
         values(
                @i_fecha_proceso,	                @w_cu_oficina,		            @w_regional,		           @w_cu_codigo_externo,
 	             @w_banco_activa,	                   @w_cu_banco,		               @w_cu_nombre,		           @w_numero_identificacion,
   	          isnull(@w_saldo_cap_activa,0),      isnull(@w_saldo_cap_pasiva,0),  @w_formula_tasa_activa,	     @w_formula_tasa_pasiva,
   	          @w_tasa_nom_activa,                 @w_tasa_nom_pasiva,	            @w_dias_vencidos_op,	        @w_desc_tipo_productor,
	             @w_desc_destino,	                   @w_norma_legal,		            @w_cu_margen_redescuento,    @w_cu_monto,
        	       @w_cu_fecha_ini,	                   @w_numero_pagare,	            @w_desc_tipo_linea,	        @w_cap_pas_sin_act,
	             @w_cap_pas_salmayor_act,            @w_cap_act_sin_pas,	            @w_cap_nomora_saldodiff,     @w_cap_pas_tasamayo_act
               )
      end
      if @w_op_tipo = 'C'
      begin
         insert into ca_conciliacion_act_pas 
   	   values(@i_fecha_proceso,	   	             @w_cu_oficina,	            	@w_regional,		           @w_cu_codigo_externo,
	             @w_cu_banco,		   	                @w_banco_pasiva,		            @w_cu_nombre,		           @w_numero_identificacion,
   		       isnull(@w_saldo_cap_activa,0),         isnull(@w_saldo_cap_pasiva,0),	@w_formula_tasa_activa,	     @w_formula_tasa_pasiva,
	             @w_tasa_nom_activa,                    @w_tasa_nom_pasiva,		         @w_dias_vencidos_op,	        @w_desc_tipo_productor,
		          @w_desc_destino,		                   @w_norma_legal,			         @w_cu_margen_redescuento,    @w_cu_monto,              ---MARTHA/LUCIA @w_cap_valor_desembolso,
		          @w_cu_fecha_ini,		                   @w_numero_pagare,		         @w_desc_tipo_linea,	        @w_cap_pas_sin_act,
		          @w_cap_pas_salmayor_act,	             @w_cap_act_sin_pas,		         @w_cap_nomora_saldodiff,     @w_cap_pas_tasamayo_act
                 )
      end
   end --if @w_cap_pas_sin_act = 'S'

   select @w_banco_activa = null
   select @w_banco_pasiva = null
   select @w_cu_banco = null
   
   fetch cursor_operacion into
   @w_cu_operacion,        @w_cu_banco

end --while @@fetch_status = 0 cursor: cursor_operacion

close cursor_operacion
deallocate cursor_operacion

return 0

ERROR:
begin
   exec sp_errorlog 
        @i_fecha     = @w_date,
        @i_error     = @w_error, 
        @i_usuario   = 'operador', 
        @i_tran      = 7999,
        @i_tran_name = @w_sp_name,
        @i_cuenta    = @w_cu_banco,
        @i_rollback  = 'N'

   return @w_error
end

go



