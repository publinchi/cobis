/************************************************************************/
/*	Nombre Fisico: 		    geneppas.sp		                            */
/*	Nombre Logico: 			sp_genera_abono_ppasivas	                */
/*	Base de datos:  	   	cob_cartera			                        */
/*	Producto: 		      	Cartera			                            */
/*	Disenado por:  			Elcira Pelaez Burbano 		                */
/*	Fecha de escritura: 	DIC -2002                                   */
/************************************************************************/
/*				                    IMPORTANTE                          */
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
/*				                   PROPOSITO	                        */
/*	     Genera los abonos en ING  para las pasivas a partir            */
/*      del visto bueno dado por pantalla de prepagos_pasivas	        */
/*      Genera un registro por interse y otro por capital               */
/*                           MODIFICACION 		                        */
/*  FEB/14/2005     Elcira Pelaez    Nuevo Req. 200                     */
/*  MAY-25-2006     Elcira Pelaez    Def. 6247 Todo valor en pesos      */
/*  JUL-01-2006     Ivan Jimenez     Def. 6789 Correccion Cotizacion en */
/*                                   valor NULL                         */
/*  20/10/2021      G. Fernandez     Ingreso de nuevo campo de          */
/*                                       solidario en ca_abono_det      */
/*    06/06/2023	 M. Cordova		 Cambio variable @w_op_calificacion */
/*									 de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_genera_abono_ppasivas')
   drop proc sp_genera_abono_ppasivas
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_genera_abono_ppasivas (
   @s_date                  datetime    = null,
   @s_user                  login       = null,
   @s_term                  descripcion = null,
   @s_ofi                   smallint    = null,
   @i_fecha_proceso         datetime    = null

)
as
declare	@w_sp_name			varchar(32),
       	@w_return			int,
        @w_error        		int,
        @w_secuencial                   int,
      	@w_moneda_nacional		tinyint,
      	@w_operacionca			int,			
      	@w_pp_cliente			int,
      	@w_numero_recibo		int,
      	@w_concepto			catalogo,
      	@w_moneda_op			tinyint,
       	@w_pp_saldo_intereses		money,
      	@w_pp_moneda			smallint,
      	@w_cuota_completa		char(1),
      	@w_prioridad			tinyint,
      	@w_monto_mn			money,
      	@w_cot_moneda			float,
        @w_aceptar_anticipos		char(1), 
        @w_pp_tipo_reduccion    	char(1),
      	@w_tipo_cobro        		char(1),
      	@w_tipo_aplicacion   		char(1),
      	@w_monto_mop			money,
      	@w_cotizacion_mop		float,
      	@w_parametro_ppas		varchar(30),
      	@w_pp_banco			cuenta,
      	@w_commit			char(1),
      	@w_pp_valor_prepago 		money,
      	@w_valor 			money,
        @w_pp_fecha_aplicar             datetime,
      	@w_est_vigente                  smallint,
      	@w_div_vigente                  smallint,
        @w_int                          catalogo,
        @w_op_calificacion		catalogo,
      	@w_cot_mn            		money,
      	@w_num_dec           		smallint,
      	@w_moneda_nac        		smallint,
      	@w_gar_admisible		char(1),
      	@w_num_dec_mn        		smallint,
        @w_am_acumulado			money,
        @w_reestructuracion             char(1),
        @w_genera_PRV                   char(1),
        @w_valor_prv			money,
        @w_op_oficina			int,
      	@w_codvalor			int,
      	@w_op_toperacion		catalogo,
      	@w_op_oficial			int,
      	@w_secuencial_prv		int,
        @w_fecha_proceso                datetime,
        @w_op_tipo_linea                catalogo,
        @w_forma_pago_bsp               catalogo,
        @w_fpago_bsp                    catalogo,
        @w_prepago_desde_lavigente      char(1),
        @w_pp_tipo_novedad              char(1),
        @w_abono_extraordinario         char(1),
        @w_pp_secuencial                int,
        @w_op_tipo_cobro                char(1),
        @w_tipo				char(1),
	     @w_causacion			char(1),		
	     @w_tipo_tabla                   varchar(10),
	     @w_dias_div			smallint,
	     @w_fecha_a_causar		datetime,
	     @w_dias_anio			smallint,
        @w_sector			catalogo,
        @w_tdividendo			catalogo,
        @w_fecha_liq			datetime,
        @w_fecha_ini			datetime,
        @w_clausula                     char(1),
	     @w_base_calculo 		char(1),
	     @w_pp_sec_pagoactiva int,
	     @w_oper_activa       int,
	     @w_llave_redescuento  cuenta,
	     @w_rowcount           int


-- Captura nombre de Stored Procedure  
select	@w_sp_name = 'sp_genera_abono_ppasivas',
	@w_secuencial     = 0,
	@w_est_vigente    = 1,
	@w_div_vigente    = 0,
	@w_valor_prv      = 0


select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 708174 
   goto ERROR1
end  


-- FORMA DE PAGO POR DEFAULT 
select @w_fpago_bsp = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'FPBSP'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 710436 
   goto ERROR1
end  


select @w_int = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 710428
   goto ERROR1
end  



select @w_tipo_cobro = 'A'  

declare cursor_prepagos_juridico cursor for 
	select pp_banco,
	       pp_cliente,
	       pp_valor_prepago,
	       pp_saldo_intereses,
	       pp_moneda,
          pp_fecha_aplicar,
          pp_tipo_reduccion,
          pp_tipo_novedad,
          pp_abono_extraordinario,
          pp_secuencial,
          pp_sec_pagoactiva,
          pp_cotizacion

        from  ca_prepagos_pasivas
        where pp_fecha_aplicar <=  @i_fecha_proceso
        and   pp_estado_aplicar = 'S'
        and   pp_estado_registro = 'I'
        for read only

open cursor_prepagos_juridico 
fetch cursor_prepagos_juridico into
	     @w_pp_banco,
	     @w_pp_cliente,
	     @w_pp_valor_prepago,  
	     @w_pp_saldo_intereses,
	     @w_pp_moneda,
        @w_pp_fecha_aplicar,
        @w_pp_tipo_reduccion,
        @w_pp_tipo_novedad,
        @w_abono_extraordinario,
        @w_pp_secuencial,
        @w_pp_sec_pagoactiva,
        @w_cotizacion_mop
      

while (@@fetch_status = 0)
begin
   if (@@fetch_status = -1) begin
      print 'Error en Cursor prepagos juridicos' 
      select @w_error = 710379 -- Crear error
      goto ERROR
   end 

   begin tran --atomicidad por registro
      select @w_commit = 'S'

      select @w_tipo_aplicacion         = op_tipo_aplicacion,
             @w_operacionca             = op_operacion,
             @w_cuota_completa          = op_cuota_completa,
             @w_aceptar_anticipos       = op_aceptar_anticipos,
             @w_moneda_op               = op_moneda,
             @w_op_calificacion         = op_calificacion,
             @w_gar_admisible           = op_gar_admisible,
             @w_reestructuracion        = op_reestructuracion,
             @w_op_oficina              = op_oficina,
             @w_op_oficial              = op_oficial,
             @w_fecha_proceso           = op_fecha_ult_proceso,
             @w_op_tipo_linea           = op_tipo_linea,
             @w_prepago_desde_lavigente = op_prepago_desde_lavigente,
             @w_op_tipo_cobro           = op_tipo_cobro,
             @w_tipo                    = op_tipo,
             @w_causacion               = op_causacion,
             @w_op_toperacion           = op_toperacion,
             @w_dias_anio               = op_dias_anio,
             @w_sector                  = op_sector,
             @w_fecha_liq               = op_fecha_liq,
             @w_fecha_ini               = op_fecha_ini,
             @w_tdividendo              = op_tdividendo,
             @w_clausula                = op_clausula_aplicada,
             @w_base_calculo            = op_base_calculo,
             @w_dias_div                = op_periodo_int,
             @w_tipo_tabla              = op_tipo_amortizacion,
             @w_llave_redescuento          = op_codigo_externo
      from  ca_operacion
      where op_banco = @w_pp_banco
 


     -- Inicio Ivan Jimenez Def. 6789 Correccion de Cotizacion En NULL
      if @w_cotizacion_mop is null
      begin
         if @w_pp_moneda = 0
            select @w_cotizacion_mop = 1
         else
         begin         
            exec sp_buscar_cotizacion
            @i_moneda      = @w_pp_moneda,
            @i_fecha       = @w_pp_fecha_aplicar,
            @o_cotizacion  = @w_cotizacion_mop out
         end
      end
      -- Fin Ivan Jimenez Def. 6789
      
 
      ---SE ARMA LA FORMA DE PAGO DEPENDIENDO EL BANCO DE SEGUNDO PISO
      
      
         select @w_oper_activa = op_operacion
         from ca_operacion
         where op_cliente = @w_pp_cliente
         and   op_codigo_externo = @w_llave_redescuento
         and   op_tipo = 'C'
            

     if @w_pp_tipo_novedad = 'I'
        select @w_forma_pago_bsp = 'ICR'
     else
        select @w_forma_pago_bsp = ltrim(rtrim(@w_fpago_bsp)) + ltrim(rtrim(@w_op_tipo_linea))



     select @w_valor  =  @w_pp_valor_prepago + @w_pp_saldo_intereses



     --VALIDAR LA EXISTENCIA DE LA FORMA DE PAGO YA ARMADA
     if not exists (select 1 from ca_producto
                    where cp_producto = @w_forma_pago_bsp)
     begin
        select @w_error = 710437
        goto ERROR
     end  


     --- MANEJO DE DECIMALES PARA LA MONEDA DE LA OPERACION 
     exec @w_return  = sp_decimales
     @i_moneda       = @w_moneda_op,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_nac out,
     @o_dec_nacional = @w_num_dec_mn out


     exec @w_secuencial = sp_gen_sec 
     @i_operacion  = @w_operacionca
  

     --- GENERACION DEL NUMERO DE RECIBO 
     exec @w_return = sp_numero_recibo
     @i_tipo    = 'P',
     @i_oficina = @s_ofi,
     @o_numero  = @w_numero_recibo out

     if @w_return != 0 begin
        select @w_error = @w_return
        goto ERROR
     end
 

      if @w_tipo_tabla != 'MANUAL'
     begin
        select @w_dias_div = @w_dias_div * td_factor
        from   ca_tdividendo
        where  td_tdividendo = @w_tdividendo
     end
     else
        select @w_dias_div = max(di_dias_cuota)
        from   ca_dividendo
        where  di_operacion = @w_operacionca
        and    di_estado = 1

   
     select @w_return = 0,
            @w_fecha_a_causar = dateadd(dd, -1, @w_fecha_proceso)

     exec @w_return = sp_calculo_diario_int
     @s_user              = @s_user,
     @s_term              = @s_term,
     @s_date              = @s_date,
     @s_ofi               = @s_ofi,
     @i_en_linea          = 'N',
     @i_toperacion        = @w_op_toperacion,
     @i_banco             = @w_pp_banco,
     @i_operacionca       = @w_operacionca,
     @i_moneda            = @w_moneda_op,
     @i_dias_anio         = @w_dias_anio,
     @i_sector            = @w_sector,
     @i_oficina           = @s_ofi,
     @i_fecha_liq         = @w_fecha_liq,
     @i_fecha_ini         = @w_fecha_ini,
     @i_fecha_proceso     = @w_fecha_a_causar,
     @i_tdividendo        = @w_tdividendo,
     @i_clausula_aplicada = @w_clausula,
     @i_base_calculo      = @w_base_calculo,
     @i_dias_interes      = @w_dias_div,
     @i_causacion         = @w_causacion,
     @i_tipo              = @w_tipo,
     @i_gerente           = @w_op_oficial,
     @i_cotizacion        = @w_cotizacion_mop

     if @w_return != 0
        return @w_return
 
     -- INSERCION EN CA_ABONO 
     insert into ca_abono (
     ab_operacion,      ab_fecha_ing,          ab_fecha_pag,
     ab_cuota_completa, ab_aceptar_anticipos,  ab_tipo_reduccion,
     ab_tipo_cobro,     ab_dias_retencion_ini, ab_dias_retencion,
     ab_estado,         ab_secuencial_ing,     ab_secuencial_rpa,
     ab_secuencial_pag, ab_usuario,            ab_terminal,
     ab_tipo,           ab_oficina,            ab_tipo_aplicacion,
     ab_nro_recibo,     ab_tasa_prepago,       ab_dividendo,
     ab_calcula_devolucion,                    ab_prepago_desde_lavigente)

     values (
     @w_operacionca,    @i_fecha_proceso,     @w_pp_fecha_aplicar,
     @w_cuota_completa, @w_aceptar_anticipos, @w_pp_tipo_reduccion,
     @w_tipo_cobro,     0,                    0,
     'ING',             @w_secuencial,        0,
     0,                 @s_user,              @s_term,
     'PAG',             @s_ofi,               @w_tipo_aplicacion,
     @w_numero_recibo,  0.00,                 0,
     'N',                                     @w_prepago_desde_lavigente)
  
     if @@error != 0 
     begin
         select @w_error = 710294
         goto ERROR
     end   

     select @w_concepto = ' '
     while 1=1 
     begin
        set rowcount 1
        select
        @w_concepto  = ro_concepto,
        @w_prioridad = ro_prioridad
        from ca_rubro_op
        where ro_operacion = @w_operacionca
        and   ro_fpago    not in ('L','B')
        and   ro_concepto > @w_concepto
        order by ro_concepto  
        if @@rowcount = 0 begin
           set rowcount 0
           break
        end
    
        set rowcount 0
        insert into ca_abono_prioridad (
        ap_secuencial_ing, ap_operacion,ap_concepto, ap_prioridad) 
        values (
        @w_secuencial,@w_operacionca,@w_concepto,@w_prioridad)
        if @@error != 0 
        begin
            select @w_error = 710001
            goto ERROR
        end  
     end


    if @w_moneda_op <> @w_moneda_nacional
     begin
        select @w_monto_mop =  round(@w_valor / @w_cotizacion_mop,@w_num_dec),
               @w_monto_mn  = @w_valor 
     end
     else
        select @w_monto_mop = @w_valor,
               @w_monto_mn  = @w_valor


     --INSERCION DE CA_ABONO_DET 
     insert into ca_abono_det (
     abd_secuencial_ing,  abd_operacion,    abd_tipo,
     abd_concepto,
     abd_cuenta,          abd_beneficiario, abd_monto_mpg,
     abd_monto_mop,       abd_monto_mn,     abd_cotizacion_mpg,
     abd_cotizacion_mop,  abd_moneda,       abd_tcotizacion_mpg,
     abd_tcotizacion_mop, abd_cheque,       abd_cod_banco,
	 abd_solidario)                                             --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
     values (
     @w_secuencial,     	@w_operacionca,      'PAG',
     @w_forma_pago_bsp,
     '0',     		          'PREPAS',       @w_monto_mn,
     @w_monto_mop,       	@w_monto_mn,     1,
     @w_cotizacion_mop,  	0,             'N',
     'N',   	       	   0,             '0',
	 'N')

     if @@error != 0 begin
        select @w_error = 710295
        goto ERROR
     end  

     update ca_prepagos_pasivas
     set pp_secuencial_ing = @w_secuencial,
         pp_estado_registro = 'P'
     where  pp_banco = @w_pp_banco
     and    pp_secuencial = @w_pp_secuencial
     and    pp_estado_aplicar = 'S'

     if @@error != 0 begin
        select @w_error = 710380
        goto ERROR
     end  

     update ca_abonos_voluntarios
     set av_estado_registro = 'S'  -- Con Estado APlicar Definido en PREPAGOS
     where av_operacion_activa =  @w_oper_activa
     and   av_secuencial_pag =  @w_pp_sec_pagoactiva
     and av_estado_registro = 'P'

   commit tran     ---Fin de la transaccion 
   select @w_commit = 'N'

   goto SIGUIENTE1

   ERROR:  
                                                     
   exec sp_errorlog                                             
   @i_fecha       = @i_fecha_proceso,
   @i_error       = @w_error,
   @i_usuario     = @s_user,
   @i_tran        = 7000, 
   @i_tran_name   = @w_sp_name,
   @i_rollback    = 'N',  
   @i_cuenta      = @w_pp_banco,
   @i_anexo       = 'REGISTRO DE ABONO PREPAGO PASIVA'

   if @w_commit = 'S' 
      commit tran
   
   goto SIGUIENTE1

   SIGUIENTE1: 
   fetch cursor_prepagos_juridico into
		@w_pp_banco,
		@w_pp_cliente,
		@w_pp_valor_prepago,
		@w_pp_saldo_intereses,
		@w_pp_moneda,
      @w_pp_fecha_aplicar,
      @w_pp_tipo_reduccion,
      @w_pp_tipo_novedad,
      @w_abono_extraordinario,
      @w_pp_secuencial,
      @w_pp_sec_pagoactiva,
      @w_cotizacion_mop



end  ---Cursor  cursor_prepagos_juridico
close cursor_prepagos_juridico
deallocate cursor_prepagos_juridico
return	 0


ERROR1:
   exec sp_errorlog 
   @i_fecha     = @i_fecha_proceso,                      
   @i_error     = @w_error, 
   @i_usuario   = @s_user, 
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = @w_pp_banco,
   @i_rollback  = 'N'


go



