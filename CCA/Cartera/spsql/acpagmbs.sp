/************************************************************************/
/*	Archivo: 		acpagmbs.sp		 		*/
/*	Stored procedure: 	sp_act_pago_mbs  			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Marcelo Poveda       			*/
/*	Fecha de escritura: 	Julio 2001				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Sp que actualiza la informacion del pago MBS contra el pago     */
/*      COBIS								*/
/*                                                                      */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_act_pago_mbs')
	drop proc sp_act_pago_mbs
go

create proc sp_act_pago_mbs 
as
declare	
@w_sp_name                      descripcion,
@w_return 	                int,
@w_error			int,
@w_tran				int,
@w_in_secuencial		int,
@w_in_val_aplicado		money,
@w_in_operacion			int,
@w_in_estado			char(1),
@w_fecha_proceso		datetime,
@w_op_banco			cuenta,
@w_in_val_aplicar		money


/*  Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_act_pago_mbs'
        

/* Fecha de proceso */
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7


PRINT 'ACPAGMBS.SP --> comienza a actualizar PAGOS'


/* Seleccion registros MBS */                 
declare pago_mbs cursor for
   select 
   in_secuencial,
   in_operacion,
   in_val_aplicar,
   in_val_aplicado, 
   in_estado
   from ca_interfaz_mbs
   where in_estado in('A','R')
   and   in_tipo_trn = 'PAG'
   for read only
   
   open pago_mbs

   fetch pago_mbs into  
   @w_in_secuencial, 
   @w_in_operacion, 
   @w_in_val_aplicar,
   @w_in_val_aplicado, 
   @w_in_estado

   if (@@fetch_status != 0) begin
      close pago_mbs
      return 708157
   end

   while (@@fetch_status = 0 ) begin 
	/* Datos de la operacion */
	select @w_op_banco = op_banco
      	from   ca_operacion
      	where  op_operacion = @w_in_operacion

	/* Para pagos (A)ceptados por MBS */
	if (@w_in_estado = 'A') and (@w_in_val_aplicar >= @w_in_val_aplicado) 
     	begin
             if @w_in_val_aplicar > @w_in_val_aplicado begin
      		/* Actualizar el detalle de pago */
      		update ca_abono_det
      		set    abd_monto_mn  = @w_in_val_aplicado,
             	abd_monto_mpg = @w_in_val_aplicado / abd_cotizacion_mpg,
             	abd_monto_mop = @w_in_val_aplicado / abd_cotizacion_mop
      		where  abd_operacion      = @w_in_operacion
      		and    abd_secuencial_ing = @w_in_secuencial
      		and    abd_tipo           = 'PAG'
                      		
      		if @@error != 0 begin
			select @w_tran  = 7999
         		select @w_error = 708152
         		goto ERROR1
      		end
	      end	                

     		/* EPBsep282001 actualizar dias de retencion para que el batch lo aplique*/
 
     		update ca_abono
     		set ab_dias_retencion_ini  = 0,
         	ab_dias_retencion          = 0,
                ab_cuota_completa          = 'N'
     		where  ab_operacion        = @w_in_operacion
     		and    ab_secuencial_ing   = @w_in_secuencial

      		if @@error != 0 begin
			select @w_tran  = 7999
         		select @w_error = 708190
         		goto ERROR1
      		end
	end
	/* Para pagos (R)echazados por MBS */
	else begin
           if (@w_in_estado = 'A') and (@w_in_val_aplicar < @w_in_val_aplicado) 
     	   begin
		/* Coloco el estado en (E)liminado */
		update ca_abono
     		set ab_estado = 'E'
     		where  ab_operacion      = @w_in_operacion
     		and    ab_secuencial_ing = @w_in_secuencial

		select @w_tran  = @w_in_secuencial
        	select @w_error = 710303
        	goto ERROR1
           end
	end

	if @w_in_estado = 'R' begin
 		update ca_abono
     		set ab_estado = 'E'
     		where  ab_operacion      = @w_in_operacion
     		and    ab_secuencial_ing = @w_in_secuencial

		select @w_tran  = @w_in_secuencial
        	select @w_error = 710303
	       	goto ERROR1
	end


   goto SIGUIENTE1

   ERROR1:
   exec sp_errorlog 
   @i_fecha     = @w_fecha_proceso,                      
   @i_error     = @w_error, 
   @i_usuario   = 'cartera', 
   @i_tran      = @w_tran,
   @i_tran_name = 'sp_act_pago_mbs',
   @i_cuenta    = @w_op_banco,
   @i_descripcion = 'PAGO RECHAZADO POR MBS',
   @i_rollback  = 'N'

   SIGUIENTE1:

   fetch pago_mbs into  
   @w_in_secuencial, 
   @w_in_operacion, 
   @w_in_val_aplicar,
   @w_in_val_aplicado, 
   @w_in_estado
 end
close pago_mbs
deallocate pago_mbs


PRINT 'ACPAGMBS.SP --> comienza a actualizar DESMBOLSOS'


/* Seleccion registros MBS */                 
declare desembolso_mbs cursor for
   select 
   in_secuencial, 
   in_operacion, 
   in_estado
   from ca_interfaz_mbs
   where in_estado in('A','R')
   and   in_tipo_trn = 'DES'
   for read only
   
   open desembolso_mbs

   fetch desembolso_mbs into  
   @w_in_secuencial, 
   @w_in_operacion, 
   @w_in_estado

   if (@@fetch_status != 0) begin
      close desembolso_mbs
      return 708157
   end

   while (@@fetch_status = 0 ) begin 



   	/* Datos de la operacion */
      	select @w_op_banco = op_banco
      	from   ca_operacion
      	where  op_operacion = @w_in_operacion

	/* Para desembolso (A)ceptados por MBS */
	if @w_in_estado = 'A' 
     	begin
      		update ca_desembolso
      		set dm_estado = 'A'
      		where dm_secuencial = @w_in_secuencial
      		and   dm_operacion = @w_in_operacion 

      		if @@error != 0 begin
			select @w_tran  = 7999
         		select @w_error = 710305
         		goto ERROR2
      		end

	end
	/* Para desembolsos (R)echazados por MBS */
	else
	begin
		/* Coloco el estado en (E)liminado */
		update ca_desembolso
     		set dm_estado = 'E'
     		where  dm_secuencial = @w_in_secuencial
     		and    dm_operacion =  @w_in_operacion
		
                select @w_tran  = @w_in_secuencial
        	select @w_error = 710304
       		goto ERROR2
	end


   goto SIGUIENTE2

   ERROR2:
   exec sp_errorlog 
   @i_fecha     = @w_fecha_proceso,                      
   @i_error     = @w_error, 
   @i_usuario   = 'cartera', 
   @i_tran      = @w_tran,
   @i_tran_name = 'sp_act_pago_mbs',
   @i_cuenta    = @w_op_banco,
   @i_descripcion = 'DESEMBOLSO RECHAZADO POR MBS',
   @i_rollback  = 'N'


   SIGUIENTE2:

   fetch desembolso_mbs into  
   @w_in_secuencial, 
   @w_in_operacion, 
   @w_in_estado
   end
close desembolso_mbs
deallocate desembolso_mbs
return 0

go


