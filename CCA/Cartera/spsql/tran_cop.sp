/************************************************************************/
/*	Nombre Fisico: 			tran_cop.sp									*/
/*	Nombre Logico: 			sp_transaccion_copia    					*/
/*	Base de datos:  		cob_cartera									*/
/*	Producto: 				Cartera										*/
/*	Disenado por:  			Epelaezb			    					*/
/*	Fecha de escritura: 	Enero 2002									*/
/************************************************************************/
/*				IMPORTANTE												*/
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
/*				PROPOSITO												*/
/*	Reversa las transacciones y los montos les pone por (-1)        	*/
/*      estipuladas en la tabla ca_sobrecausacion_mex					*/
/************************************************************************/
/*                              MODIFICACIONES                          */
/*	FEB-14-2002		RRB	      Agregar campos al insert					*/
/*					      en ca_transaccion								*/
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/     

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_sobrecausacion_mex')
   DROP TABLE ca_sobrecausacion_mex
go

CREATE TABLE ca_sobrecausacion_mex (scme_operacion           int    not null,
                                    scme_secuencial_prv      int    not null,
                                    scme_dividendo           int    not null,
                                    scme_valor_prv           money  null,
                                    scme_estado              catalogo)
go


if exists (select 1 from sysobjects where name = 'sp_transaccion_copia')
	drop proc sp_transaccion_copia
go

create proc sp_transaccion_copia (
   @s_user              login,
   @s_term              descripcion,
   @s_ofi               smallint,
   @s_date              datetime,
   @i_fecha_proceso     datetime
)

as declare 

@w_return	     int,
@w_sp_name	     varchar(30),
@w_operacion         int,
@w_dividendo         int,
@w_valor_diff        money,
@w_secuencial        int,
@w_estado            catalogo,
@w_valor_prv         money,
@w_banco             cuenta,
@w_error             int,
@w_tipo_op           char(1),
@w_gar_admisible	 char(1), ---RRB:feb-14-2002 para circular 50
@w_reestructuracion	 char(1), ---RRB:feb-14-2002 para circular 50
@w_calificacion		 catalogo  ---RRB:feb-14-2002 para circular 50

/* Captura del nombre del Stored Procedure */
select @w_sp_name    = 'sp_transaccion_copia'




/* CARGAR INFORMACION TABLA DE TRABAJO */


insert into ca_sobrecausacion_mex
select dtr_operacion,dtr_secuencial,dtr_dividendo,dtr_monto,tr_estado
from ca_transaccion,ca_det_trn,ca_abono_det
where tr_operacion = dtr_operacion
and tr_operacion = abd_operacion
and dtr_operacion = abd_operacion
and tr_tran = 'PRV'
and abd_beneficiario = 'DEBITO AUTOMATICO MEXT'
and   tr_secuencial = dtr_secuencial
and   tr_fecha_mov  = tr_fecha_ref
and tr_fecha_mov = '12/28/2001'
and dtr_concepto = 'INT'
and  tr_secuencial_ref <> -999
and tr_dias_calc = 3


/* CURSOR PARA LEER TABLA ca_sobrecausacion_mex  */
declare cursor_operacion cursor for
select 
scme_operacion,
scme_dividendo,
am_acumulado - scme_valor_prv,
scme_secuencial_prv,
scme_estado,
scme_valor_prv
from ca_sobrecausacion_mex,
      ca_dividendo,
      ca_amortizacion
where di_operacion = scme_operacion
and   di_dividendo = scme_dividendo
and   am_operacion = scme_operacion
and   am_operacion = di_operacion
and   am_dividendo  = di_dividendo
and   am_dividendo  = scme_dividendo 
and   am_concepto = 'INT'
and   di_estado <> 3
for read only

open  cursor_operacion

fetch cursor_operacion into 
@w_operacion,
@w_dividendo,
@w_valor_diff,
@w_secuencial,
@w_estado,
@w_valor_prv
while @@fetch_status = 0 begin   

   if @@fetch_status = -1 begin    
      PRINT '(tran_cop.sp)  ERROR!!! en lectura del cursor (cursor_operacion)'
       return 0
   end   

	select @w_tipo_op   = isnull(op_tipo,'N'),
	@w_gar_admisible    = op_gar_admisible, 	---RRB:feb-14-2002 para circular 50
	@w_reestructuracion = op_reestructuracion,	---RRB:feb-14-2002 para circular 50
	@w_calificacion	    = op_calificacion 		---RRB:feb-14-2002 para circular 50
	from ca_operacion
	where op_operacion = @w_operacion

	insert into ca_transaccion (
	tr_secuencial,     tr_fecha_mov,   tr_toperacion,  
	tr_moneda,         tr_operacion,   tr_tran,       
	tr_en_linea,       tr_banco,       tr_dias_calc,
	tr_ofi_oper,       tr_ofi_usu,     tr_usuario,
	tr_terminal,       tr_fecha_ref,   tr_secuencial_ref, 
	tr_estado,         tr_observacion, tr_gerente , 	  
	tr_gar_admisible,  tr_reestructuracion ,		---RRB:feb-14-2002 para circular 50
	tr_calificacion,   tr_fecha_cont,  tr_comprobante)	---RRB:feb-14-2002 para circular 50
	select 
	-1 * tr_secuencial,  @s_date,        tr_toperacion,  
	tr_moneda,           tr_operacion,   'REV', 
	tr_en_linea,         tr_banco,       tr_dias_calc,
	tr_ofi_oper,         @s_ofi,         @s_user,
	@s_term,             tr_fecha_ref,   tr_secuencial, 
	'ING',               tr_observacion, tr_gerente,	      
	isnull(@w_gar_admisible,''),  isnull(@w_reestructuracion,''),			---RRB:feb-14-2002 para circular 50
	isnull(@w_calificacion,''),   @s_date,	    0				---RRB:feb-14-2002 para circular 50
	from   ca_transaccion
	where  tr_operacion = @w_operacion
	and    tr_secuencial = @w_secuencial
	and    tr_estado     = 'CON'
	and    tr_tran      = 'PRV'

	if @@error <> 0 begin
           select @w_error = 710001
           goto ERROR  
        end 

	insert into ca_det_trn (
	dtr_secuencial,     dtr_operacion,    dtr_dividendo,
	dtr_concepto,
	dtr_estado,         dtr_periodo,      dtr_codvalor,
	dtr_monto,          dtr_monto_mn,     dtr_moneda,
	dtr_cotizacion,     dtr_tcotizacion,  dtr_afectacion,
	dtr_cuenta,         dtr_beneficiario, dtr_monto_cont )
	select  
	-1*dtr_secuencial,   dtr_operacion, dtr_dividendo,
	dtr_concepto,
	dtr_estado,          dtr_periodo,                     dtr_codvalor,     
	dtr_monto_cont,      dtr_monto_mn,   dtr_moneda,
	dtr_cotizacion,      isnull(dtr_tcotizacion,""),      dtr_afectacion,
	dtr_cuenta,          dtr_beneficiario,                  0
	from   ca_transaccion, ca_det_trn 
	where  tr_operacion = @w_operacion
	and    tr_secuencial = @w_secuencial
	and    tr_estado     = 'CON'
	and    tr_tran      = 'PRV'
	and    tr_secuencial = dtr_secuencial
	and    tr_operacion  = dtr_operacion

	if @@error <> 0 
           select @w_error =  710001

	/* ACTUALIZAR LAS TRANSACCIONES COMO REVERSADAS */
	update ca_transaccion set 
	tr_estado = 'RV',
	tr_observacion = 'REVERSO TRANSACCION PRV MOEX DIC-28-2001'
	where tr_operacion       = @w_operacion
	and   tr_secuencial = @w_secuencial
	and   tr_tran       = 'PRV'
	and   tr_estado     in ('CON','ING')
	
	if @@error != 0 begin
           select @w_error = 710002
           goto ERROR
        end

	/* ACTUALIZAR EL ACUMULADO de ca_amortizacion*/
        if @w_valor_diff >= 0 begin
	   update ca_amortizacion set 
	   am_acumulado = am_acumulado - @w_valor_prv
	   where am_operacion = @w_operacion
	   and   am_dividendo = @w_dividendo
           and   am_concepto = 'INT'

	   if @@error != 0  begin
             select @w_error = 710002
             goto ERROR
           end
        end



   /* ELIMINAR HISTORICOS SI EXISTEN */

        PRINT 'inicio eliminar Historico' + cast(@w_operacion as varchar)  

	delete from ca_operacion_his
	where  oph_secuencial = @w_secuencial
	and    oph_operacion  =  @w_operacion
	if @@error != 0 begin
           select @w_error = 710003
           goto ERROR
        end


	delete from ca_valores_his
	where  vah_secuencial = @w_secuencial
	and    vah_operacion  =  @w_operacion
	if @@error != 0 begin
        select @w_error = 710003
           goto ERROR
        end



	delete from ca_acciones_his
	where  ach_secuencial_his = @w_secuencial
	and    ach_operacion  =  @w_operacion
	if @@error != 0 begin
        select @w_error = 710003
           goto ERROR
        end


                    
	delete from ca_amortizacion_his
	where  amh_secuencial = @w_secuencial
	and    amh_operacion  =  @w_operacion
	if @@error != 0 begin
        select @w_error = 710003
           goto ERROR
        end

	delete from ca_dividendo_his
	where dih_secuencial = @w_secuencial
	and   dih_operacion   = @w_operacion
	if @@error != 0 begin
        select @w_error = 710003
           goto ERROR
        end

	delete from ca_rubro_op_his
	where  roh_secuencial = @w_secuencial
	and    roh_operacion   = @w_operacion
	if @@error != 0 begin
        select @w_error = 710003
           goto ERROR
        end

	delete from ca_cuota_adicional_his
	where  cah_secuencial = @w_secuencial
	and    cah_operacion   = @w_operacion
	if @@error != 0 begin
        select @w_error = 710003
           goto ERROR
        end

	delete ca_amortizacion_ant_his
	where  anh_secuencial = @w_secuencial 
	and    anh_operacion = @w_operacion
	if @@error != 0 begin
        select @w_error = 710003
           goto ERROR
        end

	select @w_tipo_op = isnull(op_tipo,'N')
	from ca_operacion
	where op_operacion = @w_operacion


	if @w_tipo_op != 'R' begin

	    delete from ca_relacion_ptmo_his
	    where  hpt_secuencial = @w_secuencial
	     and  hpt_activa     = @w_operacion
   	     if @@error != 0 begin
                select @w_error = 710003
                goto ERROR
             end

	end
	else begin

	    delete from ca_relacion_ptmo_his
	    where  hpt_secuencial = @w_secuencial
	    and  hpt_pasiva     = @w_operacion
   	     if @@error != 0 begin
                select @w_error = 710003
                goto ERROR
             end
	end


   /* FIN ELIMINAR HISTORICOS  */


   goto SIGUIENTE

   ERROR:  
                                                    
   exec sp_errorlog                                             
   @i_fecha     = @i_fecha_proceso,
   @i_error     = @w_error,
   @i_usuario   = @s_user,
   @i_tran      = 7000, 
   @i_tran_name = @w_sp_name,
   @i_rollback  = 'N',  
   @i_cuenta= @w_banco,
   @i_descripcion = 'REVERSO TRANSACCION PRV MOEX DIC-28-2001'
   goto SIGUIENTE


 SIGUIENTE:
 fetch cursor_operacion into 
 @w_operacion,
 @w_dividendo,
 @w_valor_diff,
 @w_secuencial,
 @w_estado,
 @w_valor_prv

end /* cursor_operacion */
close cursor_operacion
deallocate cursor_operacion

PRINT 'tran_cop.sp ------> Fin del Proceso'

select * from ca_sobrecausacion_mex

return 0

go
