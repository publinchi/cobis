/************************************************************************/
/*   NOMBRE LOGICO:      interfaz_pago.sp                               */
/*   NOMBRE FISICO:      sp_interfaz_pago                               */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Johan Hernandez                                */
/*   FECHA DE ESCRITURA: Septiembre 2021                                */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*  Procedimiento fachada encargado del llamado de los programas        */
/*  de pagos                                                            */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 18/05/2021    J. Hernandez	 Versión Inicial                        */
/* 22/10/2021    G. Fernandez	 Validación de fechas de pago menor a   */
/*                            fecha de proceso para aplicar fecha_valor */
/* 18/07/2022    G. Fernandez	 Cambio de parametro id_referencia_int  */
/*                               de int a varchar                       */
/* 05/09/2022    G. Fernandez	 Se comenta validación de saldo  a      */
/*                               precancelar                            */
/* 03/10/2022    K. Rodriguez    R194612 Valida fecha venc. y fecha pago*/
/* 12/12/2022    K. Rodríguez    S737197 Sec. pago como parámetro salida*/
/* 21/12/2022    K. Rodriguez    S749257 Habilita Pago por WS con f. val*/
/* 21/12/2022    K. Rodriguez    S717212 Saldo segun fecha pagos de 7*24*/
/* 29*03/2023    K. Rodriguez    Ajuste consulta saldo en fuera de línea*/
/* 28/07/2023    G. Fernandez     S857741 Parametros de licitud         */
/* 09/08/2023    G. Fernandez    Se incluye parametros de facturación   */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_interfaz_pago')
   drop proc sp_interfaz_pago
go
create proc sp_interfaz_pago
@s_srv                  varchar(30)   = null,
@s_rol                  smallint      = null,      
@s_ssn                  int           = null,
@s_lsrv                 varchar(30)   = null,            
@s_user                 login         = null,
@s_date                 datetime      = null,
@s_sesn                 int           = null,
@s_term                 descripcion   = null,
@t_trn                  INT           = null,
@s_ofi                  smallint      = null,  
@s_ssn_branch           int           = null,             
@i_operacion            char(1)       = null,
@i_banco                varchar(30)   ,
@i_monto                money         ,
@i_moneda               int           ,
@i_canal                catalogo      ,
@i_aplica_en_linea      char(1)       ,
@i_fecha_pago           datetime      ,
@i_forma_pago           catalogo      ,             
@i_banco_pago           int           ,
@i_cta_banco_pago       varchar(20)   ,
@i_formato_fecha        int           ,
@i_id_referencia_inter  varchar(30)   ,   --GFP 18/07/2022
@i_referencia_pago      varchar(50)   ,
@i_debug                char(1)       = 'N',
@i_observacion          varchar(30)   = null,
@i_sp_cerror            char(1)       = 'N',
@i_fuera_linea          char(1)       = 'N',
@i_reg_pago_grupal_hijo char(1)       = 'N',
@o_secuencial_ing       int           = null out,
@o_error                int           = null out,
@o_msg_error            varchar (220) = null,
@o_secuencial_pag       int           = null, 
@o_factor               float         = null,
@o_total_pago           money         = null out,
-- Parámetros factura electrónica
@o_guid               varchar(36)    = null out,
@o_fecha_registro     varchar(10)    = null out,
@o_ssn                int            = null out,
@o_orquestador_fact   char(1)        = null out

         
as declare
@w_return           int,
@w_op_operacion     int,
@w_error		    int,
@w_msg			    varchar(64),
@w_sp_name          varchar(64),
@w_fecha_proceso    datetime,
@w_moneda_local     int,
@w_codusd           int,
@w_cotizacion       float ,
@w_valor_convertido money,
@w_tipo_op          char,
@w_cot_usd          float,
@w_codigo_cat       int,
@w_factor           float,
@w_secuencial_ing   int,
@w_operacionca      int,
@w_aplica_en_linea  char(1) = 'S',
@w_saldo_cap        money,       
@w_cuota_completa   char(1), 
@w_tipo_aplicacion  char(1),
@w_calcula_devolucion char(1),
@w_retencion        int,
@w_secuencial_pag   int,
@w_op_tipo_cobro    char(1),
@w_monto_total      money,
@w_en_linea         char(1),
@w_fecha_ult_proc   datetime

--Parametros 

select @w_sp_name = 'sp_interfaz_pago'

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

/*CONSULTA CODIGO DE MONEDA LOCAL */
SELECT  @w_moneda_local = pa_tinyint
FROM cobis..cl_parametro
WHERE pa_nemonico = 'MLO'
AND pa_producto = 'ADM'
set transaction isolation level read uncommitted
                                                                                                                                                                                                              
-- Codigo de moneda DOLAR 
select @w_codusd = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and pa_nemonico = 'CDOLAR'



if @i_canal <> 2 and @i_moneda <> @w_moneda_local -- Validación que permite al canal Batch procesar en monedas distintas a la local  	
begin 
	    select @w_error = 725090 
	    goto ERROR
end

if @i_fecha_pago > @w_fecha_proceso -- Validación que indica que no permite ningún con fecha superior a la del sistema  
begin 
	select @w_error = 725095  
	goto ERROR
end

if @i_canal not in (2, 3) and @i_fecha_pago <> @w_fecha_proceso -- Canales Batch y WS permite fechas menores a la del sistema
begin 
	select @w_error = 725091 
	goto ERROR
end

if @i_canal <> 2 and @i_aplica_en_linea = 'N' -- Para todos los canales solo permite el pago en línea a excepción del canal batch que puede tener S o N
begin
	select @w_error = 725096 
	goto ERROR
end

select @w_operacionca    = op_operacion,
       @w_op_tipo_cobro  = op_tipo_cobro,
       @w_fecha_ult_proc = op_fecha_ult_proceso 
from ca_operacion
where op_banco = @i_banco

-- KDR Pagos solo en la fecha ultimo proceso de la operación [Para canales diferentes a canal batch y WS]
if @i_canal not in (2, 3) and @i_fecha_pago <> @w_fecha_ult_proc
begin 
	select @w_error = 725189 -- Error, la fecha de último proceso del préstamo es diferente a la fecha de pago
	goto ERROR
end

--- CONSULTA SALDO DE CANCELACION
if @i_canal = 2
    select @w_en_linea = 'N'

--GFP se comenta para aplicar el pago sin restrinción
/*   
exec @w_return = sp_calcula_saldo
@i_operacion = @w_operacionca,
@i_tipo_pago = 'A',
@i_en_linea  = @w_en_linea,  
@o_saldo = @w_saldo_cap out

if @w_return <> 0
begin
	select @w_error = 725097 
	goto ERROR
end

if @i_monto > @w_saldo_cap -- Validación que indica que el monto ingresado no debe superar al saldo de precancelación
begin
	select @w_error = 725098 
	goto ERROR
end
*/

if @i_operacion = 'Q'
begin

    if @i_fuera_linea = 'S'
    begin
	   select @o_total_pago = sp_saldo_a_pagar
       from ca_7x24_saldos_prestamos
       where sp_num_banco = @i_banco
       and sp_fecha_proceso = @i_fecha_pago
    end
	else
	begin
	    exec @w_return = cob_cartera..sp_qr_pagos
        @i_banco          = @i_banco,
        @i_formato_fecha  = @i_formato_fecha,
        @i_tipo_pago      = @w_op_tipo_cobro,
        @i_tipo_pago_can  = 'A',
        @i_cancela        = 'N',
		@i_resulset       = 'N', --No devulve resulset
        @t_trn            = 7144,
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_ofi            = @s_ofi,
        @s_date           = @s_date,
        @s_sesn           = @s_sesn,
		@o_total_pago     = @w_monto_total out
		
		select @o_total_pago = @w_monto_total 
	    
	    if @w_return <> 0
        begin
           select @w_error = @w_return
           goto ERROR
        end
		
	end
end --fin operacion Q


if @i_operacion = 'P'
begin 

	select @w_cuota_completa     = op_cuota_completa,
		   @w_tipo_aplicacion    = op_tipo_aplicacion,
		   @w_calcula_devolucion = op_calcula_devolucion
    from ca_operacion
    where op_banco = @i_banco
	
    --Valicación si acepta pagos
    if exists (select 1 from ca_operacion_datos_adicionales where oda_operacion = @w_operacionca and oda_aceptar_pagos = 'N')
    begin
    	select @w_error = 725094
        goto ERROR
    end	
	
	
	--Retencion
	select @w_retencion= cp_retencion from cob_cartera..ca_producto
	where cp_producto = @i_forma_pago
	if @@rowcount <> 1
	begin
		select @w_error = 725100 
       goto ERROR
	end
		
	
	
	exec @w_return = cob_cartera..sp_consulta_divisas
    @t_trn               = 77541,
    @i_banco             = @i_banco,
    @i_modulo            = 'CCA',
    @i_concepto          = 'PAG',
    @i_operacion         = 'C',
    @i_cot_contable      = 'S',
    @i_moneda_origen     = @i_moneda,
    @i_moneda_destino    = @w_moneda_local,
    @o_cotizacion        = @w_cotizacion out,
    @o_valor_convertido  = @w_valor_convertido out,
    @o_tipo_op           = @w_tipo_op out,
    @o_cot_usd           = @w_cot_usd out,
    @o_factor            = @w_factor out
       
    if @w_return <> 0
    begin
        select @w_error = @w_return
        goto ERROR
    end
	
	if @i_fecha_pago < @w_fecha_proceso and @i_canal = 2
	begin
        exec @w_return = sp_fecha_valor
		@s_ssn               = @s_ssn, 
		@s_date              = @s_date,
		@s_user              = @s_user,
		@s_term              = @s_term,
		@i_fecha_valor       = @i_fecha_pago,
		@i_banco             = @i_banco,
		@i_operacion         = 'F',
		@i_en_linea          = 'N'
		
		if  @w_return <> 0
		begin
			select @w_error = @w_return
				goto ERROR
		end	
	end

	exec @w_return = cob_cartera..sp_ing_detabono 
    @i_accion             = 'I',
    @i_encerar            = 'S', 
    @i_tipo               = 'PAG',
    @i_concepto           = @i_forma_pago, 
    @i_cuenta             = @i_cta_banco_pago, 
    @i_moneda             = @i_moneda, 
    @i_beneficiario       = @i_referencia_pago,
    @i_monto_mpg          = @i_monto,
    @i_monto_mop          = @i_monto ,
    @i_monto_mn           = @i_monto ,
    @i_cotizacion_mpg     = @w_cotizacion,
    @i_cotizacion_mop     = @w_cotizacion,
    @i_tcotizacion_mpg    = @w_tipo_op,
    @i_tcotizacion_mop    = @w_tipo_op,
    @i_no_cheque          = 0,
    @i_cod_banco          = @i_banco_pago,
    @i_inscripcion        = 0,
    @i_carga              = 0,
    @i_porcentaje         = 0.0,
    @t_trn                = 7059,
    @s_user               = @s_user,
    @s_term               = @s_term,
    @s_date               = @s_date,
    @s_sesn               = @s_sesn
          
	if  @w_return <> 0
	begin
        select @w_error = @w_return
             goto ERROR
    end
	
	if @i_debug = 'S'
	begin
	    print '@i_fecha_pago: ' + convert(varchar(30), @i_fecha_pago)
        print '@w_fecha_proceso: ' + convert(varchar(30), @w_fecha_proceso)
        print '@i_banco: ' + convert(varchar(30), @i_banco)
        print '@i_aplica_en_linea: ' + convert(varchar(30), @i_aplica_en_linea)
        print '@w_retencion: ' + convert(varchar(30), @w_retencion)
        print '@w_cuota_completa: ' + convert(varchar(30), @w_cuota_completa)
        print '@w_tipo_aplicacion: ' + convert(varchar(30), @w_tipo_aplicacion)
        print '@w_calcula_devolucion: ' + convert(varchar(30), @w_calcula_devolucion)
        print '@i_id_referencia_inter: ' + convert(varchar(30), @i_id_referencia_inter)
        print '@i_canal: ' + convert(varchar(30), @i_canal)
        print '@i_forma_pago: ' + convert(varchar(30), @i_forma_pago)
        print '@i_cta_banco_pago: ' + convert(varchar(30), @i_cta_banco_pago)
        print '@i_banco_pago: ' + convert(varchar(30), @i_banco_pago)
	end

	exec @w_return = cob_cartera..sp_ing_abono
    @i_accion              = 'I',
    @i_banco               = @i_banco,
    @i_tipo                = 'PAG',
    @i_fecha_vig           = @i_fecha_pago,
    @i_ejecutar            = @i_aplica_en_linea,
    @i_retencion           = @w_retencion, 
    @i_cuota_completa      = @w_cuota_completa,
    @i_anticipado          = 'S',
    @i_tipo_reduccion      = 'N',
    @i_proyectado          = 'P',
    @i_tipo_aplicacion     = @w_tipo_aplicacion, 
    @i_prioridades         = '', --Cuando se envía en nulo o vacio el sistema respeta las prioridades actuales
    @i_tasa_prepago        = '', 
    @i_verifica_tasas      = 'S', 
    @i_calcula_devolucion  = @w_calcula_devolucion,
    @i_cancela             = 'N',
    @i_solo_capital        = 'N',
	@i_pago_interfaz       = 'S',
	@i_id_referencia_inter = @i_id_referencia_inter,
	@i_canal_inter         = @i_canal,
	@i_forma_pago          = @i_forma_pago,
	@i_cuenta              = @i_cta_banco_pago,
	@i_cod_banco           = @i_banco_pago,
	@i_reg_pago_grupal_hijo = @i_reg_pago_grupal_hijo, 
	--@i_debug               = 'S',
	@i_aplica_licitud      = 'S',
    @o_secuencial_ing      = @w_secuencial_ing out, 
    @t_trn                 = 7058,
    @s_srv                 = @s_srv, 
    @s_user                = @s_user,
    @s_term                = @s_term,
    @s_ofi                 = @s_ofi, 
    @s_rol                 = @s_rol, 
    @s_ssn                 = @s_ssn, 
    @s_date                = @s_date,
    @s_sesn                = @s_sesn,
	@s_ssn_branch          = @s_ssn_branch,
	@o_error               = @w_error,
	--Parametros facturacion
	@o_guid                = @o_guid             out,
    @o_fecha_registro      = @o_fecha_registro   out,
    @o_ssn                 = @o_ssn              out,
	@o_orquestador_fact    = @o_orquestador_fact out
	   
	if @w_return <> 0
    begin
       select @w_error = @w_return
       goto ERROR
    end
	
	select @o_secuencial_ing = isnull(@w_secuencial_ing, 0)
	
	if @i_fecha_pago < @w_fecha_proceso and @i_canal = 2
	begin
		exec @w_return = sp_fecha_valor  
		@s_ssn               = @s_ssn, 
		@s_date              = @s_date,
		@s_user              = @s_user,
		@s_term              = @s_term,
		@i_fecha_valor       = @w_fecha_proceso,
		@i_banco             = @i_banco,
		@i_operacion         = 'F',
		@i_en_linea          = 'N'
		
		if  @w_return <> 0
		begin
			select @w_error = @w_return
			goto ERROR
		end
	
	end

end --fin operación P
		
		
if @i_operacion = 'R'
begin 

	select  @w_secuencial_ing = ip_sec_ing_cartera
	from cob_cartera..ca_intefaz_pago 
	where ip_id_referencia_origen = @i_id_referencia_inter
	and ip_operacionca = @w_operacionca
	and ip_fecha_pago = @w_fecha_proceso
	and ip_estado  = 'N'
	
	if @@rowcount <> 1
	BEGIN
		select @w_error = 725089
       goto ERROR
	end
   
   select @w_secuencial_pag = ab_secuencial_pag 
   from ca_abono
   where ab_secuencial_ing = @w_secuencial_ing
   and ab_operacion = @w_operacionca
   
   if @@rowcount <> 1
	begin
		select @w_error = 725101 
       goto ERROR
	end
   
   
	if @w_secuencial_pag <> 0 
	begin
		exec  @w_return = cob_cartera..sp_fecha_valor
             @s_srv         	    = @s_srv,
             @s_user        	    = @s_user,
             @s_term        	    = @s_term,
             @s_ofi         	    = @s_ofi,
             @s_rol         	    = @s_rol,
             @s_ssn         	    = @s_ssn,
             @s_lsrv        	    = @s_lsrv,
             @s_date        	    = @s_date,
             @s_sesn        	    = @s_sesn,
             @t_trn         	    = 7049,
             @i_banco    	       = @i_banco,
             @i_secuencial         = @w_secuencial_pag, --Secuencial pago
			 @i_secuencial_rv_int  = @w_secuencial_ing, --Secuencial ingreso pago
			 @i_id_referencia      = @i_id_referencia_inter, -- Referencia de pago del banco
             @i_operacion          = 'R',	
             @i_observacion 	   = @i_observacion,
             @i_es_atx             = 'S',	
             @i_en_linea           = 'S',
			 @i_pago_interfaz      = 'S'
                                 	
             if @@error != 0 or  @w_return <> 0	
             begin                                    	
                select @w_error =725102
                goto ERROR
             end	
	end
	else
	begin
	    exec @w_error = sp_eliminar_pagos
        @t_trn             = 7036,
        @i_banco           = @i_banco,
        @i_operacion       = 'D',
        @i_secuencial_ing  = @w_secuencial_ing, --Secuencial ingreso pago	
        @i_en_linea        = 'S',
        @i_id_referencia   = @i_id_referencia_inter,   -- Referencia de pago del banco	 
		@i_pago_interfaz   = 'S'  
        
        if @@error != 0 or @w_error <> 0
        goto ERROR
	end
	
end --fin operación R	

return 0

ERROR:

select @o_error = @w_error
if @i_canal <> 2
begin
    exec cobis..sp_cerror
    @t_debug='N',    
    @t_file=null,
    @t_from=@w_sp_name,   
    @i_num = @w_error
end

return @w_error    

go
