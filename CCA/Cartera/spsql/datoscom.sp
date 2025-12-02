/************************************************************************/
/*	Archivo:		datoscom.sp				*/
/*	Stored procedure:	sp_datos_compensacion                   */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera	                  		*/
/*	Disenado por:  		Elcira Pelaez                           */
/*	Fecha de escritura:	sep 2001. 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA"							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	Procedimiento que realiza la llamada al sp_act_compensacion     */
/*  									*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_datos_compensacion')
   drop proc sp_datos_compensacion
go

create proc sp_datos_compensacion
@s_user              login,
@s_date              datetime,
@i_modo              char(1)   = null,
@i_banco             cuenta    = null,
@i_operacion         int       = null,
@i_toperacion        catalogo  = null,          
@i_moneda            smallint  = null,
@i_oficina           smallint  = null,
@i_fecha_ult_proceso datetime  = null,   
@i_estado            tinyint   = null,
@i_cliente           int       = null,
@i_fecha_ini         datetime  = null,           
@i_monto             money     = null,
@i_fecha_fin         datetime  = null,
@i_num_renovacion    int       = null,
@i_destino           catalogo  = null,
@i_clase             catalogo  = null,
@i_ciudad            int       = null,
@i_tramite           int       = null,
@i_calificacion      char(1)   = null,
@i_renovacion        char(1)   = null,
@i_gar_admisible     char(1)   = null,
@i_edad              int       = null,
@i_base_calculo      char(1)   = null,
@i_oficial           smallint  = null,
@i_plazo             smallint  = null,
@i_tplazo            catalogo  = null,
@i_num_reest         int       = null

as 
declare 
@w_error                int,          
@w_return               int,    
       
@w_sp_name              descripcion,  
@w_fecha_prox_pago      datetime,  
@w_estado_con           tinyint,      
@w_est_vigente          tinyint,      
@w_est_vencido          tinyint,      
@w_est_novigente        tinyint,      
@w_est_cancelado        tinyint,      
@w_est_anulado          tinyint,
@w_est_credito          tinyint,
@w_est_suspenso         int,
@w_est_castigado        int,
@w_est_condonado        int,
@w_est_recompra         int,
@w_est_precancelado     int,
@w_est_judicial         int,
@w_producto             tinyint,
@w_periodicidad         char(1),
@w_num_periodicidad     smallint,
@w_tasa                 float,
@w_modalidad            char(1),
@w_fecha_ven            datetime,
@w_fecha_ven_cap        datetime,
@w_fecha_pago_cap       datetime,
@w_dias_vencido         int,
@w_dias_vencido_cap     int,
@w_fecha_prxvto         datetime,
@w_valor_cuota          money,
@w_cuota_cap            money,
@w_saldo_cap            money,
@w_saldo_cap_ven        money,
@w_saldo_int            money,
@w_saldo_otro           money,
@w_saldo_int_sus        money,
@w_numero_renovaciones  int,
@w_renovacion           char(1),
@w_div_cancelado        int,
@w_div_vigente          int,
@w_reestructuracion	char(1),
@w_tipo_garantia	char(1),
@w_base_calculo		char(1),
@w_fecha_ult_reest	datetime,
@w_num_cuot_pag		smallint,
@w_num_cuot_pagadas	smallint,
@w_monto_cubierto_gar   money,
@w_monto                money,
@w_fecha_const_gar	datetime,
@w_est_comext           tinyint,
@w_linea_credito        varchar(24),  
@w_periodicidad_cap     int,
@w_divid_ven_cap        int,
@w_divid_cap            int,
@w_suspenso             char(1),
@w_dias_plazo           int,
@w_tipo_cambio          float,
@w_monto_resultado      money,
@w_monto_pesos          money,
@w_saldo_vencido	money,
@w_num_div_vencidos	smallint,
@w_saldo_int_ven	money,
@w_saldo_mor_ven	money,
@w_saldo_otr_ven	money,
@w_num_cuotas           smallint,
@w_periodicidad_cuota   smallint,
@w_secuencial_max       int,
@w_valor_ult_pago       money, 
@w_fecha_castigo        datetime,
@w_fecha                datetime,
@w_fecha1               datetime,
@w_ru_cre               char(10),
@w_mes                  smallint,
@w_mes1                 smallint,
@w_saldo_concepto       money,
@w_modo                 char(1),
@w_saldo                money,
@w_op_divcap_original   int


select   @w_sp_name        = 'sp_datos_compensacion' 


select @w_est_novigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

select @w_est_vigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CANCELADO'

select @w_est_judicial  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'JUDICIAL'

select @w_est_precancelado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'PRECANCELADO'

select @w_est_castigado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CASTIGADO'

select @w_est_credito  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CREDITO'

select @w_est_suspenso   = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'SUSPENSO'

select @w_est_anulado = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'ANULADO'

select @w_est_condonado = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CONDONADO'

select @w_est_recompra = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'RECOMPRA'

select @w_est_comext = isnull(es_codigo, 255)
from ca_estado
where  rtrim(ltrim(es_descripcion)) = 'COMEXT'


---PRINT 'datoscom.sp llega con fecha %1!', @i_fecha_ult_proceso

/*INICIALIZACION DE VARIABLES */

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
	  @w_saldo_mor_ven       = 0,
	  @w_saldo_otro          = 0,
	  @w_saldo_otr_ven       = 0, 
	  @w_saldo_otr_ven       = 0,
	  @w_saldo_vencido       = 0, 
	  @w_monto               = 0, 
	  @w_tipo_cambio         = 0,
	  @i_num_reest           = 0,
	  @w_linea_credito       = null,
	  @w_fecha_pago_cap      = null,
	  @w_secuencial_max      = 0,
	  @w_valor_ult_pago      = 0,
	  @w_divid_cap           = 0,
	  @w_cuota_cap           = 0,
	  @w_num_cuot_pagadas    = 0



   /*NUMERO DE DIVIDENDOS VENCIDOS*/
   /*******************************/
   
   select @w_num_div_vencidos = count(*)
   from   ca_dividendo
   where  di_operacion = @i_operacion 
   and    di_estado    = @w_est_vencido


   /*NUMERO DE CUOTAS DE LAS OPERACION*/
   /***********************************/
   select @w_num_cuotas = count(*)
   from   ca_dividendo
   where  di_operacion = @i_operacion


   /*ESTADO CONTABILIZADO*/
   /**********************/
   select @w_estado_con = 0
   if @i_estado=@w_est_vigente and @i_edad in (1,2)
      select @w_estado_con = 1
   
   if (@i_estado = @w_est_vigente and @i_edad > 1)
      or (@i_estado=@w_est_suspenso)
      or (@i_estado = @w_est_vencido)
      select @w_estado_con = 2
   
   if @i_estado = @w_est_castigado
      select @w_estado_con = 3
   
   if @i_estado in (@w_est_cancelado, @w_est_precancelado, @w_est_condonado)
      select @w_estado_con = 4

   if @i_estado = @w_est_suspenso
      select @w_suspenso = 'S'


   /*CODIGO DEL PRODUCTO DE CARTERA*/
   /********************************/
   select @w_producto = pd_producto
   from cobis..cl_producto
   where pd_abreviatura = 'CCA'
   set transaction isolation level read uncommitted

   /* TASA DE LA OPERACION*/
   /***********************/
   select @w_tasa = isnull(sum(ro_porcentaje_efa),0)
   from ca_rubro_op
   where ro_operacion = @i_operacion
   and ro_fpago in ('P','A')
   and ro_tipo_rubro  = 'I'


   /*PERIODICIDAD DE LA OPERACION*/
   /******************************/ 
   select @w_num_periodicidad = td_factor
   from ca_tdividendo
   where td_tdividendo = @i_tplazo

   select @w_periodicidad_cuota = @i_plazo * @w_num_periodicidad


   /*MODALIDAD DE LA OPERACION*/
   /***************************/
   select @w_modalidad = ro_fpago
   from ca_rubro_op
   where ro_operacion = @i_operacion
   and ro_tipo_rubro  = 'I'
   and ro_provisiona  = 'S'

   if @w_modalidad = 'P'	
      select @w_modalidad = 'V'
   else 
      select @w_modalidad = 'A'


   /*DIAS SOBREGIRO, CARTERIZACION*/
   /*******************************/
   select @w_op_divcap_original = op_divcap_original
   from ca_operacion
   where op_operacion  = @i_operacion


   /*NUMERO DIAS DE VENCIDO*/
   /************************/
   select @w_fecha_ven = min(di_fecha_ven)
   from ca_dividendo
   where di_operacion = @i_operacion
      and di_estado = @w_est_vencido

   if @w_fecha_ven is not null
      if @w_base_calculo = 'R'
         select @w_dias_vencido = isnull(datediff(dd,@w_fecha_ven,@i_fecha_ult_proceso), 0)
         else begin
         exec @w_return  = sp_dias_base_comercial
         @i_fecha_ini = @w_fecha_ven,
         @i_fecha_ven = @i_fecha_ult_proceso,
         @i_opcion    = 'D',
         @o_dias_int  = @w_dias_vencido out
         select @w_dias_vencido = isnull(@w_dias_vencido, 0)
   end
   else
      select @w_dias_vencido = 0


   select @w_dias_vencido = @w_dias_vencido +  isnull(@w_op_divcap_original, 0)      ---XMA CARTERIZACION SOBREGIROS


   /*EDAD DE MORA*/
   /**************/

   select @w_divid_ven_cap = isnull(min(di_dividendo), 0)
     from ca_dividendo
    where di_operacion  = @i_operacion
      and di_estado     = @w_est_vencido
      and di_de_capital = 'S'

   select @w_fecha_ven_cap = di_fecha_ven
     from ca_dividendo
    where di_operacion  = @i_operacion
      and di_dividendo  = @w_divid_ven_cap

   if @w_fecha_ven_cap is not null
      if @w_base_calculo = 'R'
         select @w_dias_vencido_cap = isnull(datediff(dd,@w_fecha_ven_cap,@i_fecha_ult_proceso), 0)
      else begin
         exec @w_return = sp_dias_base_comercial
         @i_fecha_ini = @w_fecha_ven_cap,
         @i_fecha_ven = @i_fecha_ult_proceso,
         @i_opcion    = 'D',
         @o_dias_int  = @w_dias_vencido_cap out

         select @w_dias_vencido_cap = isnull(@w_dias_vencido_cap, 0)
      end
   else
      select @w_dias_vencido_cap = 0



   select @w_dias_vencido_cap = @w_dias_vencido_cap +  isnull(@w_op_divcap_original, 0)      ---XMA CARTERIZACION SOBREGIROS



   /*NUMERO DE RENOVACIONES*/
   /************************/
   select @w_numero_renovaciones = isnull(@i_num_reest,0) + isnull(@i_num_renovacion,0)


   /*CONVERSION DE MONEDA*/
   /**********************/
   exec @w_return = cob_cartera..sp_conversion_moneda
   @s_date                 = @s_date,
   @i_opcion               = 'L',
   @i_moneda_monto         = @i_moneda,
   @i_moneda_resultado     = 0,
   @i_monto                = 1.0,
   @o_monto_resultado      = @w_monto_resultado out,
   @o_tipo_cambio          = @w_tipo_cambio out

   if @w_return != 0 
      select @w_error = @w_return
       

   /* FECHA PROXIMO VENCIMIENTO */
   /* NULO EN CASO QUE LA OPERACION HAYA VENCIDO */
   /**********************************************/
   select 
   @w_fecha_prxvto = di_fecha_ven,
   @w_div_vigente  = di_dividendo
   from   ca_dividendo  
   where  di_operacion   = @i_operacion
   and    di_estado      = @w_est_vigente

   if @@rowcount <> 0 begin
      select @w_valor_cuota = sum(am_cuota)
      from ca_amortizacion
      where am_operacion = @i_operacion
      and   am_dividendo = @w_div_vigente

      select @w_valor_cuota = isnull(@w_valor_cuota,0)

   end


   /*SALDO DE CAPITAL*/
  /******************/
   select @w_div_cancelado = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @i_operacion
   and    di_estado    = @w_est_cancelado

   select @w_div_cancelado = isnull(@w_div_cancelado,0)
     
   select @w_saldo_cap = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from   ca_amortizacion, ca_rubro_op                            
   where  ro_operacion  = @i_operacion                                        
   and    ro_operacion  = am_operacion
   and    ro_concepto   = am_concepto                                        
   and    ro_tipo_rubro = 'C'   -- (C)apital
   and    am_dividendo  > @w_div_cancelado


   /*SALDO DE CAPITAL VENCIDO*/
  /***************************/

   select @w_saldo_cap_ven = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from   ca_rubro_op, ca_dividendo, ca_amortizacion
   where  ro_operacion  = @i_operacion
   and    ro_tipo_rubro = 'C' 
   and    di_operacion  = ro_operacion
   and    di_estado     = @w_est_vencido  --ESTADO VENCIDO
   and    am_operacion  = di_operacion
   and    am_dividendo  = di_dividendo
   and    am_concepto   = ro_concepto

    
   /*SALDO DE INTERES EN ESTADO SUSPENSO */
   /**************************************/
   select @w_saldo_int_sus = 
   isnull(sum(( abs(am_acumulado + am_gracia - am_pagado) + 
   am_acumulado + am_gracia - am_pagado) / 2.0),0)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion  = @i_operacion
   and    ro_operacion  = am_operacion
   and    ro_concepto   = am_concepto
   and    am_estado     = @w_est_suspenso  --ESTADO SUSPENSO
   and    ro_tipo_rubro = 'I'              --INTERES
   and    am_dividendo  > @w_div_cancelado

   if @w_saldo_int_sus <= 0 and @w_modalidad = 'A'
      select @w_saldo_int = 0


   /*SALDO DE INTERES */
  /*******************/
   select @w_saldo_int = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion  =  @i_operacion
   and    ro_operacion  =  am_operacion
   and    ro_concepto   =  am_concepto
   and    am_estado     <> @w_est_suspenso
   and    ro_tipo_rubro =  'I'  --intereses
   and    am_dividendo  >  @w_div_cancelado

   if @w_saldo_int <= 0 and @w_modalidad = 'A'
      select @w_saldo_int = 0


   /*SALDO DE INTERES EN ESTADO VENCIDO */
  /*************************************/
   select @w_saldo_int_ven = 
   isnull(sum(( abs(am_acumulado + am_gracia - am_pagado) + 
   am_acumulado + am_gracia - am_pagado) / 2.0),0)
   from   ca_rubro_op, ca_dividendo, ca_amortizacion
   where  ro_operacion  = @i_operacion
   and    ro_tipo_rubro = 'I'   -- (I)nteres
   and    di_operacion  = ro_operacion
   and    di_estado     = @w_est_vencido
   and    am_operacion  = di_operacion
   and    am_dividendo  = di_dividendo
   and    am_concepto   = ro_concepto

   if @w_saldo_int_ven <= 0 and @w_modalidad = 'A'
      select @w_saldo_int_ven = 0


   /*SALDO DE MORA */
   /****************/
   select @w_saldo_mor_ven = 
   isnull(sum(( abs(am_acumulado + am_gracia - am_pagado) + 
   am_acumulado + am_gracia - am_pagado) / 2.0),0)
   from   ca_rubro_op, ca_dividendo, ca_amortizacion
   where  ro_operacion  = @i_operacion
   and    ro_tipo_rubro = 'M'   -- (M)ora
   and    di_operacion  = ro_operacion
   and    di_estado     = @w_est_vencido
   and    am_operacion  = di_operacion 
   and    am_dividendo  = di_dividendo
   and    am_concepto   = ro_concepto

   if @w_saldo_mor_ven <= 0 and @w_modalidad = 'A'
      select @w_saldo_mor_ven = 0


   /*SALDO DE OTROS RUBROS */
   /************************/
   select @w_saldo_otro = 
   isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion  =  @i_operacion
   and    ro_operacion  =  am_operacion
   and    ro_concepto   =  am_concepto
   and    ro_tipo_rubro not in ('C','I','M') 
   and    am_dividendo  >  @w_div_cancelado

   if @w_saldo_otro <= 0 and @w_modalidad = 'A'
      select @w_saldo_mor_ven = 0



   /*SALDO DE OTROS RUBROS EN ESTADO VENCIDO */
   /******************************************/

   select @w_saldo_otr_ven = 
   isnull(sum(( abs(am_acumulado + am_gracia - am_pagado) + 
   am_acumulado + am_gracia - am_pagado) / 2.0),0)
   from   ca_rubro_op, ca_dividendo, ca_amortizacion
   where  ro_operacion  = @i_operacion
   and    ro_tipo_rubro not in ('C','I','M')   
   and    di_operacion  = ro_operacion 
   and    di_estado     = @w_est_vencido
   and    am_operacion  = di_operacion
   and    am_dividendo  = di_dividendo
   and    am_concepto   = ro_concepto

   select @w_saldo_otr_ven = @w_saldo_otr_ven * @w_tipo_cambio  


  /*TOTAL VENCIDO */
   /****************/

   select @w_saldo_vencido = isnull((@w_saldo_cap_ven + @w_saldo_int_ven + @w_saldo_mor_ven + @w_saldo_otr_ven),0)


  /* SALDO INTERES */
  /*****************/
  select @w_saldo_int = isnull(@w_saldo_int,0) + isnull(@w_saldo_mor_ven,0)


   /*MONTO INICIAL DE LA OPERACION */
   /********************************/

   select @w_monto = @i_monto * @w_tipo_cambio



   /*FECHA DE ULTIMA REESTRUCTURACION */
   /***********************************/

   select @i_num_reest = isnull(@i_num_reest, 0),
          @w_fecha_ult_reest = null,
          @w_reestructuracion = 'N',
          @w_num_cuot_pag = 0

   if @i_num_reest > 0
      begin
	select @w_reestructuracion = 'S'
	
	select w_fecha_ult_reest = tr_fecha_ref
	from ca_transaccion
	where tr_operacion = @i_operacion
	and   tr_tran = 'RES'
    group by tr_operacion, tr_fecha_ref, tr_secuencial
	having tr_secuencial = max(tr_secuencial)

	select @w_num_cuot_pag = count(*)
	from ca_dividendo
	where di_operacion = @i_operacion
        and   di_estado = @w_est_cancelado
	and   di_fecha_ven > @w_fecha_ult_reest
      end



   /*NUMERO DE LINEA DE CREDITO */
   /*****************************/

   select @w_linea_credito  = li_num_banco
   from cob_credito..cr_linea, cob_credito..cr_tramite
   where tr_tramite = @i_tramite
   and   tr_linea_credito = li_numero 


   /*FECHA DE PAGO DE CAPITAL */
   /**************************/

   if @i_calificacion in ('B', 'C', 'D', 'E') begin
      select @w_fecha_pago_cap = max(ab_fecha_pag),
             @w_secuencial_max = max(ab_secuencial_pag)
        from ca_abono, ca_rubro_op, ca_det_trn
       where ab_operacion = @i_operacion
         and ab_estado    = 'A'
         and ab_tipo      = 'PAG'
         and ro_operacion = ab_operacion
         and ro_operacion = dtr_operacion
         and ro_tipo_rubro = 'C'
         and dtr_secuencial = ab_secuencial_pag
     
     and dtr_operacion  = ab_operacion
         and dtr_concepto   = ro_concepto
      
      select @w_valor_ult_pago =  sum(dtr_monto)
      from ca_det_trn
      where dtr_operacion = @i_operacion
      and dtr_secuencial  = @w_secuencial_max

   end
   else
      select @w_fecha_pago_cap = null


   /*VALOR DE LA CUOTA */
   /********************/

   if @w_divid_ven_cap <= 0
      select @w_divid_cap = isnull(min(di_dividendo), 0)
        from ca_dividendo
       where di_operacion = @i_operacion
         and di_dividendo >= @w_div_vigente
   else
      select @w_divid_cap = @w_divid_ven_cap

   select @w_cuota_cap =isnull(sum(am_cuota+am_gracia-am_pagado), 0)
     from ca_rubro_op, ca_amortizacion
    where ro_operacion = @i_operacion
      and am_operacion = ro_operacion
      and am_dividendo = @w_divid_cap
      and am_concepto  = ro_concepto


   /*CUOTAS PAGADAS */
   /*****************/

   select @w_num_cuot_pagadas = count(*)
     from ca_dividendo
    where di_operacion = @i_operacion
      and di_estado    = @w_est_cancelado

   select @w_dias_plazo = isnull(sum(di_dias_cuota), 0)
   from ca_dividendo
   where di_operacion = @i_operacion


   /*SALTO TOTAL  */
   /***************/

   select @w_saldo = isnull(sum(@w_saldo_cap + @w_saldo_int + @w_saldo_otro + @w_saldo_int_sus),0)


    /*   ojooooo  exec @w_return = sp_act_compensacion
         @i_fecha			= @i_fecha_ult_proceso,	
         @i_numero_operacion		= @i_operacion,
         @i_tasa            		= @w_tasa,
         @i_saldo_cap			= @w_saldo_cap,
         @i_saldo_int			= @w_saldo_int,
         @i_saldo_otros			= @w_saldo_otro,
         @i_saldo_int_contingente	= @w_saldo_int_sus,
         @i_saldo			= @w_saldo, 
         @i_estado_contable		= @w_estado_con,
         @i_periodicidad_cuota		= @w_periodicidad_cuota,
         @i_edad_mora           	= @w_dias_vencido_cap,
         @i_valor_mora			= @w_saldo_cap_ven,
         @i_valor_cuota         	= @w_cuota_cap,
         @i_cuotas_pag			= @w_num_cuot_pagadas,
         @i_cuotas_ven          	= @w_num_div_vencidos,
         @i_num_cuotas          	= @w_num_cuotas,
         @i_fecha_pago			= @w_fecha_pago_cap,
         @i_fecha_fin			= @i_fecha_fin,
         @i_estado_cartera		= @i_estado,
         @i_reestructuracion		= @w_reestructuracion,
         @i_fecha_ult_reest		= @w_fecha_ult_reest,
         @i_plazo_dias			= @w_dias_plazo

         if @w_return != 0 begin 
            PRINT 'datoscom.sp  salio por error al ejecutar sp_act_compensacion @w_return %1!',@w_return
            select @w_error = @w_return                                 
         end*/
                                                              

return 0

go
