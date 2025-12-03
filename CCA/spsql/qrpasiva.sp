/************************************************************************/
/*	Archivo: 		qrpasiva.sp				*/
/*	Stored procedure: 	sp_qr_pasivas      		        */
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		X.Maldonado 	  		        */
/*	Fecha de escritura: 	23/Dic/2003				*/
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
/*	Consulta las Operaciones Pasivas Vencidas.  Todas las operacio 	*/
/*      nes pasivas, cancelan su cuota automaticamente en la fecha de   */
/*      vencimiento.                                                    */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'ca_op_pasivas_ven')
   drop table ca_op_pasivas_ven
go


CREATE TABLE ca_op_pasivas_ven
(banco              cuenta         NULL,
 tramite            int            NULL,
 moneda             smallint       NULL,
 estado             tinyint        NULL,
 codigo_externo     cuenta         NULL,
 margen_redescuento float          NULL,
 cliente            int            NULL,
 monto              money          NULL
)
go

if exists (select 1 from sysobjects where name = 'sp_qr_pasivas')
   	   drop proc sp_qr_pasivas
go

create proc sp_qr_pasivas (
@t_trn                  int         = null,
@s_lsrv                 cuenta      = null,
@s_srv                  cuenta      = null,
@s_sesn	                int         = null,
@s_user			login       = null,
@s_date			datetime    = null,
@s_ofi			smallint    = null,
@s_term			varchar(30) = null,
@s_ssn                  int         = null,
@i_operacion            cuenta      = null,   ---char(1)	  = null,
@i_banco                cuenta      = null,
@i_banco_segundo        cuenta      = null,
@i_llave_redes          cuenta      = '0',
@i_modo                 tinyint     = null,
@i_cuota                smallint    = null,
@i_valor_cap            money       = null,
@i_valor_int            money       = null,
@i_estado_div           varchar(30) = null,
@i_formato_fecha        int         = null,
@i_fecha_consulta       datetime    = null,
@i_siguiente            cuenta      = '0'
)        
as

declare 
@w_sp_name		varchar (32),
@w_formula_tasa		varchar(20),
@w_return		int,
@w_error		int,
@w_secuencial		int,
@w_operacionca		int,
@w_tamanio              int,
@w_tramite		int,
@w_dividendo		int,
@w_dias_interes		int,
@w_moneda_nacional      smallint,
@w_op_oficina		smallint,
@w_op_moneda		smallint,
@w_fecha_prox           datetime,
@w_fecha_liq            datetime,
@w_fecha_proceso  	datetime,
@w_fecha_vencimiento	datetime,
@w_op_fecha_ult_proceso datetime,

@w_cot_mpg		float,
@w_cot_mop		float,
@w_tasa_nominal		float,
@w_cotizacion_hoy	float,
@w_llave_redesc		cuenta,
@w_banco		cuenta,
@w_monto_op		money,
@w_monto_mn		money,
@w_monto		money,
@w_saldo_redescuento	money,
@w_abono_capital	money,
@w_abono_interes	money,
@w_forma_bsp		catalogo,
@w_op_tipo_linea	catalogo,
@w_forma_pago_bsp	catalogo,
@w_concepto             catalogo,
@w_op_toperacion	catalogo,
@w_op_aceptar_anticipos char(1),
@w_op_tipo_reduccion	char(1),
@w_op_tipo_cobro	char(1),
@w_op_tipo_aplicacion	char(1),
@w_tcotizacion_mpg	char(1),
@w_modalidad_pago	char(1),
@w_estado		char(1),
@w_prioridad		tinyint,
@w_llave_redescuento    cuenta,
@w_capital              money,
@w_interes              money,
@w_fecha_pago_s         datetime,
@w_fecha_vencimiento_s  datetime,
@w_llave_redescuento_s  cuenta,
@w_capital_s            money,
@w_interes_s            money,
@w_monto_s              money,
@w_dividendo_s          int,
@w_diferencia           money,
@w_max_banco            int

	
select	@w_sp_name   = 'sp_qr_pasivas'


/*PARAMETROS GENERALES */
/***********************/
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'


select @w_forma_bsp = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FPBSP'
if @@rowcount = 0 
   return 710436  


select @w_fecha_proceso =  @s_date




if @i_operacion = 'Q0'    --OPERACIONES CON DIFERENCIA
begin

   set rowcount 25

   select 'VENCIMIENTO'       = convert(varchar(10),cd_fecha_ven_cuota,101),
          'OPERACION       '  = cd_banco,
          'LLAVE REDESCUENTO' = cd_llave_redescuento,
          'CAPITAL'           = cd_abono_capital,
          'INTERES'           = cd_abono_interes,
          'MONTO TOTAL'       = sum(cd_abono_capital + cd_abono_interes),
          'DIAS INTERES'      = cd_dias_interes,
          'TASA'              = cd_tasa_nominal,
          'FORMULA'           = cd_formula_tasa,
          'ESTADO'            = cd_estado
   from ca_conciliacion_diaria
   where cd_w = 'S'
   and   cd_banco_sdo_piso = @i_banco_segundo
   and   cd_llave_redescuento > @i_siguiente
   and   cd_estado  = 'N'
   group by cd_banco,cd_llave_redescuento,cd_abono_capital, cd_abono_interes, cd_fecha_ven_cuota,cd_dias_interes,cd_tasa_nominal,
            cd_formula_tasa, cd_estado     
   order by cd_banco


   select 25

   set rowcount 0
  
end

if @i_operacion = 'Q6'    --OPERACIONES CON DIFERENCIAS
begin

   set rowcount 25

   select 'VENCIMIENTO'       = convert(varchar(10),cd_fecha_ven_cuota,101),
          'OPERACION       '  = cd_banco,
          'LLAVE REDESCUENTO' = cd_llave_redescuento,
          'CAPITAL'           = cd_abono_capital,
          'INTERES'           = cd_abono_interes,
          'MONTO TOTAL'       = cd_saldo_redescuento,
          'DIAS INTERES'      = cd_dias_interes,
          'TASA'              = cd_tasa_nominal,
          'FORMULA'           = cd_formula_tasa,
          'ESTADO'            = cd_estado
   from ca_conciliacion_diaria
   where cd_banco_sdo_piso = @i_banco_segundo
   ---and   cd_fecha_proceso = @w_fecha_proceso
   and   cd_llave_redescuento > @i_siguiente
   and   cd_estado  = 'A'
   order by cd_banco


   select 25

   set rowcount 0
  
end




if @i_operacion = 'Q1'  --"OK" 
begin
   set rowcount 25

   select 'VENCIMIENTO'       = convert(varchar(10),cd_fecha_ven_cuota,101),
          'OPERACION       '  = cd_banco,
          'LLAVE REDESCUENTO' = cd_llave_redescuento,
          'CAPITAL'           = cd_abono_capital,
          'INTERES'           = cd_abono_interes,
          'MONTO TOTAL'       = cd_saldo_redescuento,
          'DIAS INTERES'      = cd_dias_interes,
          'TASA'              = cd_tasa_nominal,
          'FORMULA'           = cd_formula_tasa,
          'ESTADO'            = cd_estado
   from ca_conciliacion_diaria
   where cd_z1 in (null,'')
   and   cd_w  in (null,'')
   and   cd_banco_sdo_piso = @i_banco_segundo
   and   cd_llave_redescuento > @i_siguiente
   and   cd_estado  = 'N'
   order by cd_banco

   select 25

   set rowcount 0
end






if @i_operacion = 'Q2'   ---"COBIS"   --ESTA EN COBIS Y NO EN FINAGRO
begin

   set rowcount 25

   select 'VENCIMIENTO'       = convert(varchar(10),cd_fecha_ven_cuota,101),
          'OPERACION       '  = cd_banco,
          'LLAVE REDESCUENTO' = cd_llave_redescuento,
          'CAPITAL'           = cd_abono_capital,
          'INTERES'           = cd_abono_interes,
          'MONTO TOTAL'       = cd_saldo_redescuento,
          'DIAS INTERES'      = cd_dias_interes,
          'TASA'              = cd_tasa_nominal,
          'FORMULA'           = cd_formula_tasa,
          'ESTADO'            = cd_estado
   from ca_conciliacion_diaria
   where cd_z1 = 'S'  
   and   cd_banco_sdo_piso = @i_banco_segundo
   and   cd_llave_redescuento > @i_siguiente
   and   cd_estado  = 'N'
   order by cd_banco


   select 25

   set rowcount 0
end




if @i_operacion = 'Q3'   ---"FINAGRO" --ESTA EN FINAGRO Y NO EN COBIS
begin

   set rowcount 25

   select 'FECHA DE PAGO'     = bs_fecha_pago,
          'FECHA VENCIMIENTO' = bs_fecha_vencimiento,
          'LLAVE REDESCUENTO' = bs_oper_llave_redes,
          'CAPITAL'           = bs_abono_capital, 
          'INTERES'           = bs_valor_int,               
          'MONTO TOTAL'       = bs_valor_pagar,
          'DIAS INTERES'      = bs_dias_int,
          'TASA'              = bs_tasa_nom,
          'FORMULA'           = bs_formula_tasa,
          'MODALIDAD PAGO'    = bs_modalidad
   from ca_plano_banco_segundo_piso
   where bs_z2 = 'S'  
   and   bs_oper_llave_redes > @i_siguiente  
   order by bs_oper_llave_redes

   select 25

   set rowcount 0      
end




if @i_operacion = 'Q4'      ---===> OK" --CORRECCION
begin
   if @i_modo = 0
   begin
      update ca_plano_banco_segundo_piso
      set bs_z2 =  null
      where bs_oper_llave_redes = @i_llave_redes
   end

   if @i_modo = 1
   begin
      update ca_conciliacion_diaria
      set cd_w  = null,
          cd_z1 = null
      where cd_llave_redescuento = @i_llave_redes
      and   cd_estado            = 'N'
      and   cd_banco             = @i_banco
   end
end





if @i_operacion = 'Q5'   ---CONSULTA DE OPERACIONES CON DIFERENCIAS
begin


   select @w_fecha_vencimiento = convert(varchar(10),cd_fecha_ven_cuota,101),
          @w_llave_redescuento = cd_llave_redescuento,
          @w_capital           = cd_abono_capital,
          @w_interes           = cd_abono_interes,
          @w_monto             = cd_saldo_redescuento,
          @w_dividendo         = cd_dividendo
   from ca_conciliacion_diaria
   where cd_banco = @i_banco
   and   cd_estado  = 'N'


   select  @w_fecha_pago_s         = bs_fecha_pago,
           @w_fecha_vencimiento_s  = bs_fecha_vencimiento,
           @w_llave_redescuento_s  = bs_oper_llave_redes,
           @w_capital_s            = bs_abono_capital, 
           @w_interes_s            = bs_valor_int,               
           @w_monto_s              = bs_valor_pagar,
           @w_dividendo_s          = bs_dias_int
   from ca_plano_banco_segundo_piso
   where bs_oper_llave_redes = @i_llave_redes
   order by bs_oper_llave_redes


   select @w_diferencia = round(sum(@w_monto_s - @w_monto),2)


   if @w_diferencia < 0
      select @w_diferencia = @w_diferencia*(-1)


   select @w_fecha_vencimiento,
          @w_llave_redescuento,
          @w_capital,
          @w_interes,
          @w_monto,
          @w_dividendo,
          @w_fecha_pago_s,
          @w_fecha_vencimiento_s,
          @w_llave_redescuento_s,
          @w_capital_s,
          @w_interes_s,
          @w_monto_s,
          @w_dividendo_s,
          @w_diferencia
end






if @i_operacion = 'Q7'    --OPERACIONES DEL HISTORICO A UNA FECHA DADA
begin


   set rowcount 25

   select 'VENCIMIENTO'       = convert(varchar(10),cd_fecha_ven_cuota,101),
          'OPERACION       '  = cd_banco,
          'LLAVE REDESCUENTO' = cd_llave_redescuento,
          'CAPITAL'           = cd_abono_capital,
          'INTERES'           = cd_abono_interes,
          'MONTO TOTAL'       = cd_saldo_redescuento,
          'DIAS INTERES'      = cd_dias_interes,
          'TASA'              = cd_tasa_nominal,
          'FORMULA'           = cd_formula_tasa,
          'ESTADO'            = cd_estado
   from ca_conciliacion_diaria
   where cd_fecha_proceso = @i_fecha_consulta
   and   cd_llave_redescuento > @i_siguiente
   order by cd_llave_redescuento  ----cd_banco


   select 25

   set rowcount 0


end





if @i_operacion = 'I'  ----"REG.PAGO" 
begin

   declare cursor_operacion cursor
   for select cd_fecha_proceso, 	cd_operacion,		cd_banco,  	      		cd_dividendo,		
	      cd_estado,		op_tipo_linea,		op_moneda, 	       	 	op_fecha_ult_proceso,   
	      op_aceptar_anticipos,	op_tipo_reduccion,      op_tipo_cobro,	        	op_tipo_aplicacion,	
	      op_oficina,		op_toperacion
   from ca_conciliacion_diaria, ca_operacion
   where cd_z1     is  null
   and   cd_w      is  null
   and   cd_estado = 'N'
   and   cd_operacion = op_operacion
   order by cd_banco
   for read only

   open  cursor_operacion
   fetch cursor_operacion
   into       @w_fecha_proceso,         @w_operacionca,		  @w_banco,                  	@w_dividendo,		
	      @w_estado,		@w_op_tipo_linea,	  @w_op_moneda,             	@w_op_fecha_ult_proceso,  
	      @w_op_aceptar_anticipos,	@w_op_tipo_reduccion,     @w_op_tipo_cobro,	        @w_op_tipo_aplicacion,	  
	      @w_op_oficina,		@w_op_toperacion

   while @@fetch_status = 0 
   begin   
      if @@fetch_status = -1 
      begin    
         select @w_error = 70899
      end   

      select @w_monto = 0


      /*FORMA DE PAGO*/
      /***************/
      select @w_forma_pago_bsp = ltrim(rtrim(@w_forma_bsp)) + ltrim(rtrim(@w_op_tipo_linea))



      /*VALIDAR LA EXISTENCIA DE LA FORMA DE PAGO YA ARMADA*/
      /*****************************************************/
      if not exists (select 1 from ca_producto
         where cp_producto = @w_forma_pago_bsp)
         return 710437


      /*SECUENCIAL DE PAGO */
      /*********************/
      exec @w_secuencial = sp_gen_sec 
      @i_operacion  = @w_operacionca



      /** CONSULTAR LA CUOTA A PAGAR **/
      /********************************/
      select @w_monto = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from  ca_amortizacion
      where am_operacion  = @w_operacionca
      and   am_dividendo  = @w_dividendo



      if @w_op_moneda = @w_moneda_nacional 
      begin
         select @w_cot_mpg          = 1.0,
                @w_cot_mop          = 1.0,
                @w_tcotizacion_mpg  = 'N',
                @w_monto_mn         = @w_monto,
                @w_monto_op         = @w_monto
      end
      else 
      begin
         exec sp_buscar_cotizacion
         @i_moneda     = @w_op_moneda,
         @i_fecha      = @w_op_fecha_ult_proceso,
         @o_cotizacion = @w_cotizacion_hoy output

         select @w_monto_op         = @w_monto,
                @w_monto_mn         = isnull((@w_monto * @w_cotizacion_hoy),0),
                @w_cot_mpg          = @w_cotizacion_hoy,
                @w_cot_mop          = 1.0,
                @w_tcotizacion_mpg  = 'C'
      end


      if @w_monto > 0 
      begin  
         insert ca_abono ( 
         ab_secuencial_ing, 	ab_secuencial_rpa,     	ab_secuencial_pag, 
         ab_operacion,      	ab_fecha_ing,          	ab_fecha_pag,  
         ab_cuota_completa, 	ab_aceptar_anticipos,  	ab_tipo_reduccion, 
         ab_tipo_cobro,     	ab_dias_retencion_ini, 	ab_dias_retencion, 
         ab_estado,         	ab_usuario,            	ab_oficina,
         ab_terminal,       	ab_tipo,               	ab_tipo_aplicacion,
         ab_nro_recibo )
         values (
         @w_secuencial,     	0,                     	  0,
         @w_operacionca,    	@w_op_fecha_ult_proceso,  @s_date,
         'S',               	@w_op_aceptar_anticipos,  @w_op_tipo_reduccion,
         @w_op_tipo_cobro,     	0,                        0,
         'ING',             	@s_user,                  @s_ofi,
         @s_term,           	'PAG',                    @w_op_tipo_aplicacion,
         0)

         if @@error != 0  
            return 710294

    
         insert into ca_abono_det (
         abd_secuencial_ing,    abd_operacion,         abd_tipo,
         abd_concepto,          abd_cuenta,            abd_beneficiario,    
         abd_moneda,            abd_monto_mpg,         abd_monto_mop,       
         abd_monto_mn,          abd_cotizacion_mpg,    abd_cotizacion_mop,  
         abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,          
         abd_cod_banco)
         values (
         @w_secuencial,         @w_operacionca,        'PAG',
         @w_forma_pago_bsp,     '',      	       'PAGO AUTOMATICO PASIVAS', 
         @w_moneda_nacional,    @w_monto_mn,           @w_monto_op,             
         @w_monto_mn,           @w_cot_mpg,            @w_cot_mop,        
         @w_tcotizacion_mpg,    @w_tcotizacion_mpg,    0,           
         '') 

         if @@error != 0 
            return 710295

         select @w_concepto = ' '
	
      end  --2


 
         while 1=1 
         begin --3
	     set rowcount 1
	     select
	     @w_concepto  = ro_concepto,
	     @w_prioridad = ro_prioridad
	     from ca_rubro_op
	     where ro_operacion = @w_operacionca
	     and   ro_fpago not in ('L')
	     and   ro_concepto > @w_concepto
	     order by ro_concepto
  
	     if @@rowcount = 0 begin
	       set rowcount 0
	       break
	    end
     
	    set rowcount 0

	    insert into ca_abono_prioridad (
	    ap_secuencial_ing, ap_operacion,     ap_concepto, 
            ap_prioridad) 
	    values (
	    @w_secuencial,     @w_operacionca,   @w_concepto,
            @w_prioridad)
	    
            if @@error != 0 return 710225

   	  end --3

 

   fetch cursor_operacion
   into       @w_fecha_proceso,         @w_operacionca,		  @w_banco,                  	@w_dividendo,		
	      @w_estado,		@w_op_tipo_linea,	  @w_op_moneda,             	@w_op_fecha_ult_proceso,  
	      @w_op_aceptar_anticipos,	@w_op_tipo_reduccion,     @w_op_tipo_cobro,	        @w_op_tipo_aplicacion,	  
	      @w_op_oficina,		@w_op_toperacion

   end -- CURSOR DE OBLIGACIONES

   close cursor_operacion
   deallocate cursor_operacion
end






if @i_operacion in ('R','A')
begin
   exec  @w_return      = sp_act_amortiza
   @s_sesn	        = @s_sesn,
   @s_user            	= @s_user,
   @s_term		= @s_term,
   @s_date		= @s_date,
   @s_ofi		= @s_ofi,
   @s_ssn               = @s_ssn,
   @s_srv               = @s_srv,
   @s_lsrv              = @s_lsrv,
   @t_trn               = @t_trn,
   @i_operacion         = @i_operacion,
   @i_dividendo         = @i_cuota,
   @i_valor_cap         = @i_valor_cap,
   @i_valor_int         = @i_valor_int,
   @i_banco             = @i_banco,
   @i_estado_div        = @i_estado_div,
   @i_formato_fecha     = @i_formato_fecha 

   if @w_return != 0 
      return @w_return 
end





return 0

go

