/************************************************************************/
/*	Archivo:		recupcob				*/
/*	Stored procedure:	sp_recuperacion_cobranza		*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Elcira Pelaez				*/
/*	Fecha de escritura:	Mar. 2001. 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	Procedimiento que realiza la insercion de informacion a la      */
/*	tabla ca_recuperacion_cobranza                                  */
/************************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_recuperacion_cobranza')
   drop proc sp_recuperacion_cobranza
go

create proc sp_recuperacion_cobranza
@s_user		     	login		= null,
@s_term		     	varchar(30)	= null,
@s_date		     	datetime	= null,
@s_ofi		     	smallint	= null,
@i_fecha_proceso  	datetime
 

as

declare 
@w_error          	int,
@w_return         	int,
@w_sp_name        	descripcion,
@w_fecha_asignacion	datetime,
@w_fecha_corte		datetime,
@w_num_obligacion	int,
@w_num_banco		varchar(24),
@w_producto		tinyint,
@w_dias_vcto		smallint,
@w_ofi_gte		smallint,
@w_moneda		tinyint,
@w_saldo_obligacion     money,
@w_valor                money,
@w_monto                money,
@w_secuencial           int,
@w_tran			catalogo,
@w_secuencial_ref       int,
@w_ref			char(1),
@w_mora                 varchar(24),
@w_categoria_fpago      catalogo


/* INICIALIZO VARIABLES */
   select @w_saldo_obligacion = 0


/* CURSO PARA LEER TODAS LAS OPERACIONES A PROCESAR */

declare cursor_recuperacion_cobranza cursor for
select 
ac_fecha_asig,
ac_fecha_corte,
ac_num_obligacion,
ac_num_banco_obl,
ac_producto,
ac_dias_vcto,
ac_ofi_gte,
ac_moneda,
ac_saldo_obligacion
from cob_credito..cr_asignacion_cob
where ac_producto = 7
and ac_fecha_asig = @i_fecha_proceso
for read only

open  cursor_recuperacion_cobranza

fetch cursor_recuperacion_cobranza into 
@w_fecha_asignacion,
@w_fecha_corte,
@w_num_obligacion,
@w_num_banco,
@w_producto,
@w_dias_vcto,
@w_ofi_gte,
@w_moneda,
@w_saldo_obligacion

while @@fetch_status = 0 begin   

   if @@fetch_status = -1 begin    
       select @w_error = 710209
   end   

	/* INICIALIZO VARIABLES */
	   select  @w_monto  = 0

	/* CURSO PARA LEER LAS TRANSACCIONES POSIBLES DE LA OPERACION */
	declare cursor_transacciones_oper cursor for
	select 
	tr_secuencial,
	tr_secuencial_ref,
	tr_tran
	from   ca_transaccion
	where tr_banco = @w_num_banco
        and   tr_fecha_mov = @i_fecha_proceso 
	and   tr_tran  in ('PAG','PRO','RES')
	and   tr_estado  <> 'RV'
        and   tr_estado  <> 'ANU'
        for read only

	open cursor_transacciones_oper

	fetch cursor_transacciones_oper into 
	@w_secuencial,
	@w_secuencial_ref,
	@w_tran

	while @@fetch_status = 0 begin   
	   if @@fetch_status = -1 begin    
	       select @w_error = 710210
	   end  
         
           select @w_valor = 0

	   if @w_tran = 'PAG' begin
           
		select @w_categoria_fpago = cp_categoria,
	               @w_monto           = dtr_monto
		   from ca_det_trn,
		        ca_producto
		where dtr_concepto = cp_producto
		and dtr_secuencial = @w_secuencial_ref
                and dtr_operacion  = @w_num_obligacion
              	
                if @w_categoria_fpago in ('NDAH','NDCC','EFEC','CHLO','CHOT','CHGE')  begin
                   select @w_valor =  @w_monto
                end  /*categoria*/

	        select @w_ref = 'E'

	        /*Falta definir la categoria de fpago
                  para Dacion  en pago               */

           end /*PAGOS*/

	   if @w_tran = 'PRO' begin
               select @w_valor =   @w_saldo_obligacion
	        select @w_ref = 'P'
           end /*PRORROGAS*/

	   if @w_tran = 'RES' begin
               select @w_monto  = dtr_monto
               from ca_det_trn
               where dtr_secuencial = @w_secuencial
                 and dtr_operacion  = @w_num_obligacion

               select @w_valor =  @w_valor + @w_monto

	       select @w_ref = 'R'
           end /*PRORROGAS*/

         if @w_dias_vcto >= 1 and @w_dias_vcto <= 30
            select @w_mora  = 'MORA 30'

         if @w_dias_vcto >= 31 and @w_dias_vcto <= 60
            select @w_mora  = 'MORA 60'

         if @w_dias_vcto >= 61 and @w_dias_vcto <= 90
            select @w_mora  = 'MORA 90'

         if @w_dias_vcto > 90
            select @w_mora  = 'MORA > 90'

       /*INSERTAR LA OPERACION */
         if @w_valor > 0  begin
         
         if not exists (select 1 from ca_recuperacion_cobranza
                        where rc_fecha_proc    = @i_fecha_proceso
			and   rc_num_op        = @w_num_obligacion
                        and   rc_moneda        = @w_moneda
                        and   rc_oficina       = @w_ofi_gte
                        and   rc_tipo_trn      = @w_ref
			and   rc_dias_ven      = @w_mora
			and   rc_producto      = 'CARTERA') begin
         insert into ca_recuperacion_cobranza values (@i_fecha_proceso,		 @w_num_obligacion,	
						     @w_num_banco,		 @w_ofi_gte,
						     @w_moneda,			 @w_ref,
						     @w_valor,			 @w_mora,
						     'CARTERA',			 1) 

           if @@error != 0 
              select @w_error = 710208

         end /*exists e Insert*/
          else  begin
	    update ca_recuperacion_cobranza	
            set rc_monto = rc_monto + @w_valor
            where rc_fecha_proc    = @i_fecha_proceso
	    and   rc_num_op        = @w_num_obligacion
            and   rc_moneda        = @w_moneda
            and   rc_oficina       = @w_ofi_gte
            and   rc_tipo_trn      = @w_ref
	    and   rc_dias_ven      = @w_mora
	    and   rc_producto      = 'CARTERA'

          end /*Update */
         end /*valor > 0 */         


	fetch cursor_transacciones_oper into 
	@w_secuencial,
	@w_secuencial_ref,
	@w_tran

	end /* cursor_transacciones_oper */

	close cursor_transacciones_oper
	deallocate cursor_transacciones_oper

fetch cursor_recuperacion_cobranza into 
@w_fecha_asignacion,
@w_fecha_corte,
@w_num_obligacion,
@w_num_banco,
@w_producto,
@w_dias_vcto,
@w_ofi_gte,
@w_moneda,
@w_saldo_obligacion

end /* cursor_recuperacion_cobranza */

close cursor_recuperacion_cobranza
deallocate cursor_recuperacion_cobranza


set rowcount 0
return 0
go

