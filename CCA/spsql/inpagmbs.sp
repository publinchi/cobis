/************************************************************************/
/*	Archivo: 		inpagmbs.sp		 		*/
/*	Stored procedure: 	sp_ing_pago_mbs  			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Marcelo Poveda       			*/
/*	Fecha de escritura: 	Junio 2001				*/
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
/*	Sp que ingresa el pago generado por MBS para ser aplicado por   */
/*      Cartera								*/
/*                                                                      */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ing_pago_mbs')
	drop proc sp_ing_pago_mbs
go

create proc sp_ing_pago_mbs (
	@s_ssn                int		=null,
        @s_user               varchar(30)	=null,
	@s_sesn               int		=null,
	@s_term               varchar(10)	=null,
	@s_date               datetime		=null,
        @s_ofi                smallint		=null,
	@i_archivo	      varchar(30)	=null,    
	@i_cuenta_cliente     cuenta  		=null
)
as
declare	@w_sp_name                      descripcion,
       	@w_return 	                int,
	@w_cliente                      int,
	@w_toperacion                   catalogo,
	@w_moneda                       tinyint,
        @w_producto                     tinyint,          
        @w_estado                       char(1),
        @w_error                        int,
        @w_op_operacionca               int,            
        @w_op_banco                     cuenta,
        @w_op_nombre                    descripcion,
	@w_op_moneda                    tinyint,
	@w_op_cuota_completa            char(1),
	@w_op_tipo_cobro                char(1), 
	@w_op_tipo_reduccion            char(1),
        @w_op_tipo_aplicacion           char(1),
	@w_op_aceptar_anticipos         char(1),
	@w_op_precancelacion            char(1),
	@w_prioridad                    tinyint,
        @w_contador                     tinyint,
        @w_prioridad_arreglo            varchar(20),
        @w_prioridad_arreglo2           varchar(20),
        @w_cotizacion                   float,
        @w_tasa_prepago                 float,
        @w_concepto                     varchar(10),
        @w_cantidad_pri                 smallint,
        @w_count                        smallint,
	@w_secuencial			int,
	@w_forma_pago			catalogo,
	/***************************************/
	@w_pc_banco			cuenta,
	@w_pc_monto			money,
	@w_pc_forma			char(1),
	@w_pc_ofipag			smallint,
	@w_sec_ing			int,
	@w_pc_archivo			varchar(30),
	@w_pc_fecha_ing			datetime
	/***************************************/ --MPO23Oct2001

/*  Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_ing_pago_mbs'

if @s_date is null
   select @s_date = fc_fecha_cierre
   from cobis..ba_fecha_cierre
   where fc_producto = 7

select @s_user = 'sa',
       @s_term = 'CONSOLA',
       @s_ofi  = 900



/** CURSOR DE PAGOS INGRESADOS POR MBS **/
declare cursor_caja_mbs cursor for
select 
pc_archivo,	pc_fecha_ing,	pc_banco,
pc_monto,	pc_forma,	pc_ofipag
from ca_pagos_caja_mbs
where pc_fecha_ing = @s_date
and   pc_archivo   = @i_archivo
and   pc_sec_ing   = 0
order by pc_banco
for read only

open cursor_caja_mbs

fetch cursor_caja_mbs into
@w_pc_archivo,	@w_pc_fecha_ing,	@w_pc_banco,	
@w_pc_monto,	@w_pc_forma,		@w_pc_ofipag

while @@fetch_status = 0 begin


  
   /* SELECCION FORMA DE PAGO */
   if @w_pc_forma = 'E' begin --Efectivo
      select @w_forma_pago = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'EFEMBS'
      set transaction isolation level read uncommitted
   end

   if @w_pc_forma = 'C' begin --Cheque
      select @w_forma_pago = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'CHQMBS'
      set transaction isolation level read uncommitted
   end

   
   /*GENERACION REGISTRO DE PAGO*/
   /*****************************/
   select @w_op_operacionca  = op_operacion,
   @w_op_banco               = op_banco,
   @w_op_nombre              = op_nombre,
   @w_op_moneda              = op_moneda,
   @w_op_cuota_completa      = op_cuota_completa,
   @w_op_tipo_cobro          = op_tipo_cobro,
   @w_op_tipo_reduccion      = op_tipo_reduccion,
   @w_op_tipo_aplicacion     = op_tipo_aplicacion,
   @w_op_aceptar_anticipos   = op_aceptar_anticipos,
   @w_op_precancelacion      = op_precancelacion
   from  ca_operacion, ca_estado, ca_default_toperacion
   where op_banco          = @w_pc_banco
---op_migrada        = @w_pc_banco  ---EPB:dic-06-2001
   and   op_estado         = es_codigo
   and   es_acepta_pago    = 'S'                
   and   op_toperacion = dt_toperacion          -- RRB Oct 31 2.001
   and   dt_naturaleza = 'A' -- Solo para Activas, se descartan Pasivas - RRB Oct 31 2.001

   if @@rowcount = 0 begin
      select @w_error = 710307  ---EPB:oct-11-2001
      goto ERROR
   end


   select @w_count  = 0,
   @w_cantidad_pri  = 0,
   @w_prioridad_arreglo = '',
   @w_prioridad_arreglo2 = ''                    
                 
   select @w_cantidad_pri = count(*)
   from   ca_rubro_op 
   where  ro_operacion    = @w_op_operacionca
   and    ro_fpago <> 'L'  --MPO Ref. 022 02/19/2002
               
   declare prioridad cursor for
   select ro_concepto,ro_prioridad
   from ca_rubro_op
   where ro_operacion    = @w_op_operacionca
   and   ro_fpago <> 'L' --MPO Ref. 022 02/19/2002
   order by ro_concepto 
   for read only
   
   open prioridad

   fetch prioridad into  @w_concepto,@w_prioridad

   if (@@fetch_status != 0) begin
      close prioridad
      return 710124
   end

   while (@@fetch_status = 0 ) begin 
      select @w_count = @w_count + 1  
      select @w_prioridad_arreglo = convert(varchar(10),@w_prioridad)  

      if @w_cantidad_pri <> @w_count 
         select @w_prioridad_arreglo2 = @w_prioridad_arreglo2 + convert(varchar(10),@w_prioridad_arreglo) + ';'     
      else
         select @w_prioridad_arreglo2 = @w_prioridad_arreglo2 + convert(varchar(10),@w_prioridad_arreglo) + '#'             

      fetch prioridad into @w_concepto,@w_prioridad
   end
   
   close prioridad
   deallocate prioridad

   /* COTIZACION*/
   /*************/
   select @w_cotizacion = 1

   /*TASA APLICADA */
   /****************/
   select @w_tasa_prepago = ro_porcentaje
   from ca_rubro_op
   where ro_operacion = @w_op_operacionca
   and ro_concepto    = 'INT'

   --begin tran

   /*INSERCION DEL REGISTRO*/
   /************************/
   exec @w_return = sp_ing_detabono
   @s_user	       = @s_user,
   @s_date	       = @s_date,
   @s_sesn	       = @s_sesn,
   @t_trn              = 7059,
   @i_accion 	       = 'I',
   @i_encerar          = 'S',
   @i_tipo	       = 'PAG',
   @i_concepto         = @w_forma_pago,
   @i_cuenta 	       = @i_cuenta_cliente,
   @i_moneda 	       = @w_op_moneda,     
   @i_beneficiario     = @w_op_nombre,     
   @i_monto_mpg        = @w_pc_monto,    
   @i_monto_mop        = @w_pc_monto,    
   @i_monto_mn         = @w_pc_monto, 
   @i_cotizacion_mpg   = @w_cotizacion,
   @i_cotizacion_mop   = @w_cotizacion,  
   @i_tcotizacion_mpg  = 'N',    
   @i_tcotizacion_mop  = 'N'  

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end    

      
   exec @w_return = sp_ing_abono 
   @s_user		= @s_user,
   @s_term		= @s_term,
   @s_date		= @s_date,
   @s_sesn		= @s_sesn,
   @s_ssn		= @s_ssn,
   @s_ofi 		= @s_ofi,
   @t_trn              	= 7058,
   @i_accion		= 'I',
   @i_banco		= @w_op_banco,
   @i_tipo 		= 'PAG',
   @i_fecha_vig		= @s_date, 
   @i_ejecutar		= 'N',     
   @i_retencion    	= 0,        
   @i_cuota_completa 	= @w_op_cuota_completa,   
   @i_anticipado    	= @w_op_aceptar_anticipos,   
   @i_tipo_reduccion	= @w_op_tipo_reduccion,   
   @i_proyectado     	= @w_op_tipo_cobro,       
   @i_tipo_aplicacion 	= @w_op_tipo_aplicacion,  
   @i_prioridades  	= @w_prioridad_arreglo2,
   @i_en_linea		= 'S',
   @i_tasa_prepago     	= @w_tasa_prepago,
   @i_verifica_tasas   	= 'S',
   @o_secuencial_ing	= @w_sec_ing out

     
   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

   
   /** ACTUALIZAR EL REGISTRO DEL PAGO EN TABLA DE CAJA **/
   update ca_pagos_caja_mbs
   set   pc_sec_ing   = @w_sec_ing
   where pc_fecha_ing = @s_date
   and   pc_archivo   = @i_archivo
   and   pc_banco     = @w_pc_banco
   and   pc_sec_ing   = 0 

   if @@error != 0 begin
      select @w_error = 710002
      goto ERROR
   end


   --commit tran

   goto SIGUIENTE

   ERROR:
   exec sp_errorlog 
   @i_fecha     = @s_date,                      
   @i_error     = @w_error, 
   @i_usuario   = @s_user, 
   @i_tran      = 7999,
   @i_tran_name = 'sp_ing_pago_mbs',
   @i_cuenta    = @w_pc_banco,
   @i_rollback  = 'S'
   while @@trancount > 0 rollback tran
   goto SIGUIENTE 

   
   SIGUIENTE:
   
   fetch cursor_caja_mbs into
   @w_pc_archivo,	@w_pc_fecha_ing,	@w_pc_banco,	
   @w_pc_monto,		@w_pc_forma,		@w_pc_ofipag
end

close cursor_caja_mbs
deallocate cursor_caja_mbs 

return 0
go


