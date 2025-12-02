/************************************************************************/
/*	Archivo:		carinffi.sp				*/
/*	Stored procedure:	sp_carga_inf_findeter   	        */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Fecha de escritura:	Junio.2005 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Genera informacion para conciliacion FINDETER                   */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_carga_inf_findeter')
   drop proc sp_carga_inf_findeter
go

create proc sp_carga_inf_findeter
@i_fecha_proceso     datetime

as


declare 
   @w_error                   int,
   @w_return                  int,
   @w_sp_name                 descripcion,
   @w_fecha_proceso           datetime,
   @w_contador                int,
   @w_est_vigente             tinyint,
   @w_est_vencido             tinyint,
   @w_est_novigente           tinyint,
   @w_est_cancelado           tinyint,
   @w_est_credito             tinyint,
   @w_est_suspenso            tinyint,
   @w_est_castigado           tinyint,
   @w_est_anulado             tinyint,
   @w_est_novedades           tinyint,
   @w_op_banco                cuenta,
   @w_op_tramite              int,
   @w_op_oficina              int,
   @w_op_codigo_externo       cuenta,
   @w_op_fecha_ini            datetime,
   @w_op_nombre               varchar(15),
   @w_op_sector               char(1),
   @w_op_tdividendo           char(1),
   @w_op_tipo_linea           catalogo,
   @w_op_cliente              int,
   @w_op_moneda               tinyint,
   @w_saldo_capital           money,
   @w_referencial             catalogo,
   @w_tasa_mercado            varchar(10),
   @w_tipo_tasa               char(10),
   @w_modalidad               char(1),
   @w_fpago                   char(1),
   @w_op_operacion            int,
   @w_op_margen_redescuento   float,
   @w_signo                   char(1),
   @w_tasa_referencial        varchar(10),
   @w_puntos                  money,  
   @w_abono_capital           money,
   @w_abono_interes           float,
   @w_op_opcion_cap           char(1),
   @w_num_dec_op              int,
   @w_moneda_mn               smallint,
   @w_saldo_redescuento       money,
   @w_tasa_nominal            float,
   @w_tasa_nominal_unica      float,
   @w_puntos_c                varchar(5),
   @w_norma_legal             varchar(255),
   @w_di_dividendo            smallint,
   @w_prox_pago_int           datetime,
   @w_di_dias_cuota           int,
   @w_tasa_pactada            varchar(30),
   @w_valor_capitalizar       float,
   @w_porcentaje_capitalizar  float,
   @w_identificacion          numero,
   @w_fecha_desembolso        datetime,
   @w_op_fecha_ult_proceso    datetime,
   @w_ciudad_nacional         int,
   @w_di_fecha_ven            datetime,
   @w_di_fecha_ini            datetime,
   @w_cotizacion              float,
   @w_num_dec_n               smallint,
   @w_moneda_nacional         smallint,
   @w_num_dec                 smallint,
   @w_moneda_n                smallint,
   @w_tipo_identificacion     char(2),
   @w_fecha_para_tasa         datetime,
   @w_valor_imo               money,
   @w_findeter                catalogo,
   @w_numero_pagare           descripcion,
   @w_ciudad_ofi              int,
   @w_op_ref_exterior         cuenta,
   @w_valor_neto              money,
   @w_departamento            descripcion,
   @w_di_provincia	      smallint,
   @w_op_direccion            tinyint,
   @w_operacion               int,
   @w_max_div_oper            smallint,
   @w_modalidad_pago          char(5),
   @w_op_tdividendo_aux       catalogo,
   @w_tasa_redes              char(20),
   @w_activa                  int,
   @w_op_tramite_act          int
 

--  CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name          = 'sp_carga_inf_findeter'

select @w_fecha_proceso = @i_fecha_proceso


--PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted


---SACAR PARAMETROS GENERALES
select @w_findeter = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FINDET'
set transaction isolation level read uncommitted
 

select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

           
--SE ELIMINAN LOS REGISTROS EN ESTADO N PORQUE ESTE PROGRAMA LOS VUELVE A CARGAR
 
 
--CURSOR PARA LEER LOS VENCIMIENTOS MENORES O IGUALES A LA FECHA DE PROCESO 
declare cursor_carga_vtos_dia cursor for
select 
   op_cliente,                          op_moneda,           isnull(op_margen_redescuento,100),
   op_banco,                            op_tramite,          op_oficina,
   isnull(op_codigo_externo,op_banco),  op_fecha_ini,        substring(op_nombre,1,15),
   op_sector,                           op_tdividendo,       op_tipo_linea,
   op_opcion_cap,                       op_operacion,        op_fecha_ini,
   di_dividendo,                        di_dias_cuota,       op_fecha_ult_proceso,
   di_fecha_ven,                        di_fecha_ini,	     op_ref_exterior,
   isnull(op_direccion,1)	
from cob_cartera..ca_operacion,
     cob_cartera..ca_dividendo
where op_operacion = di_operacion
and   op_tipo = 'R'                 ---Solo Pasivas REDESCUENTO
and   op_tipo_linea = @w_findeter   ---SOLO LAS PASIVAS DE BANCOLDEX
and   di_fecha_ven <=  @w_fecha_proceso  
and   di_estado in (1,2)
and   op_estado in (1,2,4,5,8,9,10)
      
open  cursor_carga_vtos_dia

fetch cursor_carga_vtos_dia into 
   @w_op_cliente,                       @w_op_moneda,           @w_op_margen_redescuento,
   @w_op_banco,                         @w_op_tramite,          @w_op_oficina,
   @w_op_codigo_externo,                @w_op_fecha_ini,        @w_op_nombre,
   @w_op_sector,                        @w_op_tdividendo,       @w_op_tipo_linea,
   @w_op_opcion_cap,                    @w_op_operacion,        @w_fecha_desembolso,
   @w_di_dividendo,                     @w_di_dias_cuota,       @w_op_fecha_ult_proceso,
   @w_di_fecha_ven,                     @w_di_fecha_ini,	@w_op_ref_exterior,
   @w_op_direccion

while @@fetch_status = 0 
begin   
   if @@fetch_status = -1 
   begin    
     PRINT 'carinfba.sp No hay datos para conciliacion diaria BANCOLDEX'
   end   

   /* CIUDAD DE LA OFICINA EN QUE ESTA RADICADO EL CREDITO */
   /********************************************************/
   select @w_ciudad_ofi        = of_ciudad
   from cobis..cl_oficina noholdlock
   where of_oficina = @w_op_oficina


   /* DEPARTAMENTO DONDE ESTA RADICADO EL CREDITO */
   /***********************************************/
   select @w_ciudad_ofi        = of_ciudad
   from cobis..cl_oficina noholdlock
   where of_oficina = @w_op_oficina


   select @w_di_provincia = di_provincia
   from cobis..cl_direccion
   where di_direccion = @w_op_direccion


   select @w_departamento = pv_descripcion
   from cobis..cl_provincia
   where pv_provincia = @w_di_provincia


   select @w_activa = rp_activa
   from  ca_relacion_ptmo
   where rp_pasiva = @w_op_operacion


   select @w_op_tramite_act = op_tramite
   from ca_operacion
   where op_operacion = @w_activa


   /*NUMERO DE PAGARE */
   /*******************/
   select @w_numero_pagare = gp_garantia
   from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia
   where gp_garantia = cu_codigo_externo
   and cu_tipo = '6100'
   and gp_tramite = @w_op_tramite_act


   /*LECTURA DE DECIMALES */
   /***********************/
   exec @w_return = sp_decimales
   @i_moneda       = @w_op_moneda,
   @o_decimales    = @w_num_dec out,
   @o_mon_nacional = @w_moneda_n out,
   @o_dec_nacional = @w_num_dec_n out

   /*NOMBRE DEL CLIENTE*/
   /********************/
   select 
   @w_op_nombre  = rtrim(p_p_apellido)+' '+rtrim(p_s_apellido)+' '+rtrim(en_nombre)
   from  cobis..cl_ente
   where en_ente = @w_op_cliente
   set transaction isolation level read uncommitted


   /*SALDO_CAPITAL */
   /****************/
   select @w_saldo_capital     = 0,
          @w_saldo_redescuento = 0
      
   select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from  ca_dividendo, ca_amortizacion, ca_rubro_op
   where ro_operacion  = @w_op_operacion
   and   ro_tipo_rubro = 'C'  --Capital
   and   am_operacion  = ro_operacion
   and   am_concepto   = ro_concepto
   and   di_operacion  = ro_operacion
   and   am_dividendo  = di_dividendo
   and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
   and   am_estado     <>  3  -- Cancelado 


   /* FORMULA TASA */
   /****************/
   select @w_referencial  = '',
          @w_signo        = '',
          @w_puntos       = 0,
          @w_fpago        = '',
          @w_tasa_nominal_unica = 0


   select @w_referencial  = ro_referencial,
          @w_signo        = ro_signo,
          @w_puntos       = convert(money,ro_factor),
          @w_fpago        = ro_fpago,
          @w_tasa_nominal_unica = isnull(ro_porcentaje,0)
   from  ca_rubro_op,ca_operacion
   where ro_operacion = @w_op_operacion
   and   ro_concepto  = 'INT'
   and   ro_operacion = op_operacion



   /* TASA REFERENCIAL */
   /********************/
   select @w_tasa_referencial = vd_referencia
   from   ca_valor_det
   where  vd_tipo = @w_referencial
   and    vd_sector = @w_op_sector


   select @w_tasa_redes = @w_tasa_referencial + ' ' + @w_signo + ' ' + convert(varchar(10),@w_puntos)


   /* LA FECHA DE LA TASA DEBE SER LA DEL INICIO DEL DIVIDENDO*/
   /* ES CON LA QUE SE INSERTO EL REAJUSTE */
   /****************************************/
   select @w_fecha_para_tasa = di_fecha_ini
   from ca_dividendo
   where di_operacion = @w_op_operacion
   and   di_dividendo = @w_di_dividendo

   select @w_tasa_nominal = isnull(ts_porcentaje,0)
   from ca_tasas
   where ts_operacion = @w_op_operacion
   and   ts_dividendo = @w_di_dividendo
   and   ts_concepto  in('INT','INTANT')
   and   ts_fecha    = @w_fecha_para_tasa

   if @@rowcount = 0
      select @w_tasa_nominal = @w_tasa_nominal_unica
     


   --ABONO CAPITAL 
   select @w_abono_capital = 0
   select @w_abono_capital = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from  ca_amortizacion, ca_rubro_op
   where ro_operacion  =  @w_op_operacion
   and   ro_tipo_rubro =  'C'  --Capital
   and   am_operacion  =  ro_operacion
   and   am_concepto   =  ro_concepto
   and   am_dividendo  =  @w_di_dividendo

   /*ABONO INTERES*/
   select @w_abono_interes = 0
   select @w_abono_interes = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from  ca_amortizacion, ca_rubro_op
   where ro_operacion  =  @w_op_operacion
   and   ro_tipo_rubro =  'I'  --Interes
   and   am_operacion  =  ro_operacion
   and   am_concepto   =  ro_concepto
   and   am_dividendo  =  @w_di_dividendo


   /*MORA A PAGAR*/
   select @w_valor_imo  = 0
   select @w_valor_imo  = isnull(sum(am_cuota  + am_gracia - am_pagado),0)
   from ca_amortizacion,ca_rubro_op
   where am_operacion = @w_op_operacion
   and ro_operacion = am_operacion
   and am_concepto = ro_concepto
   and am_dividendo = @w_di_dividendo  
   and ro_tipo_rubro = 'M'

   exec sp_dias_cuota_360
   @i_fecha_ini  = @w_di_fecha_ini,
   @i_fecha_fin  = @w_di_fecha_ven,
   @o_dias       = @w_di_dias_cuota out

   --VALOR A CAPITALIZAR 
   select @w_valor_capitalizar = 0,
          @w_porcentaje_capitalizar = 0  

   if @w_op_opcion_cap = 'S'  
   begin
       if exists (select 1 from ca_acciones
         where  ac_operacion = @w_op_operacion
         and    @w_di_dividendo between  ac_div_ini and ac_div_fin)  
          begin
             select @w_porcentaje_capitalizar = ac_porcentaje
             from ca_acciones
             where  ac_operacion = @w_op_operacion
             and  @w_di_dividendo between  ac_div_ini and ac_div_fin
             
             select @w_valor_capitalizar = (@w_abono_interes * @w_porcentaje_capitalizar )/100
             select @w_abono_interes = round(@w_abono_interes - @w_valor_capitalizar,@w_num_dec)
          end       
    end

   select @w_cotizacion = 0          

   if  @w_op_moneda <> @w_moneda_nacional
   begin
      exec sp_buscar_cotizacion
      @i_moneda     = @w_op_moneda,
      @i_fecha      = @w_di_fecha_ven,    
      @o_cotizacion = @w_cotizacion output

      select @w_abono_capital     = round((@w_abono_capital * @w_cotizacion),2)
      select @w_abono_interes     = round((@w_abono_interes * @w_cotizacion),2)
      select @w_saldo_redescuento = round((@w_saldo_redescuento * @w_cotizacion),0)

      if @w_abono_interes  > 0 and @w_abono_interes  <  1
         select  @w_abono_interes = 1
           
      if @w_abono_capital > 0  and @w_abono_capital < 1
         select @w_abono_capital = 1
   end     
   else      
      select @w_cotizacion = 1
   

   /* MODALIDAD PAGO */
   /******************/
   select @w_max_div_oper = max(di_dividendo)
   from ca_dividendo
   where di_operacion = @w_op_operacion
   
   select @w_di_dias_cuota = di_dias_cuota 
   from ca_dividendo
   where di_operacion = @w_operacion
   and di_dividendo = @w_max_div_oper
   
   select @w_op_tdividendo_aux = @w_op_tdividendo

   select @w_op_tdividendo = td_tdividendo 
   from ca_tdividendo
   where td_factor = @w_di_dias_cuota

   if @w_op_tdividendo is null 
      select @w_op_tdividendo = @w_op_tdividendo_aux

   if @w_fpago  = 'P'
      select @w_fpago   = 'V'
   else
      select @w_fpago   = 'A'


   select @w_modalidad_pago =  @w_op_tdividendo + '/' + @w_fpago   


   /*VALOR NETO*/
   /*************/
   select @w_valor_neto = isnull(sum(@w_abono_capital + @w_abono_interes + @w_valor_imo),0)

   if @w_abono_interes > 0.1 or @w_abono_capital > 0.1
   begin
        insert into  ca_conci_dia_findeter(
      	cf_fecha_proceso,		cf_num_oper_cobis,		cf_num_oper_findeter,              
	cf_beneficiario,		cf_departamento,		cf_pagare,              
	cf_saldo_capital,		cf_valor_capital,		cf_fecha_desde,              
	cf_fecha_hasta,			cf_dias,			cf_modalida_pago,              
	cf_tasa_redes,			cf_tasa,			cf_valor_interes,              
	cf_neto_pagar,			cf_marcar_diff,                 cf_no_conciliada
        )                        
	values(
	@w_fecha_proceso,		@w_op_banco,    		@w_op_codigo_externo,
   	@w_op_nombre,   		@w_departamento,   		@w_numero_pagare,
	@w_saldo_capital,		@w_abono_capital,		@w_di_fecha_ven,
   	@w_di_fecha_ini,		@w_di_dias_cuota,		@w_modalidad_pago,
	@w_tasa_redes,			@w_tasa_nominal,		@w_abono_interes, 
        @w_valor_neto,          	null,				null
	)

        if @@error != 0
           PRINT 'error al insertar en ca_conci_dia_findeter ' + @w_op_banco
   end

   ---select * from ca_conci_dia_findeter

   fetch cursor_carga_vtos_dia into 
   @w_op_cliente,          @w_op_moneda,    	@w_op_margen_redescuento,
   @w_op_banco,            @w_op_tramite,   	@w_op_oficina,
   @w_op_codigo_externo,   @w_op_fecha_ini, 	@w_op_nombre,
   @w_op_sector,           @w_op_tdividendo,	@w_op_tipo_linea,
   @w_op_opcion_cap,       @w_op_operacion, 	@w_fecha_desembolso,
   @w_di_dividendo,        @w_di_dias_cuota,	@w_op_fecha_ult_proceso,
   @w_di_fecha_ven,        @w_di_fecha_ini,	@w_op_ref_exterior,
   @w_op_direccion
end -- cursor_carga_vtos_dia 

close cursor_carga_vtos_dia
deallocate cursor_carga_vtos_dia
 
return 0

go
