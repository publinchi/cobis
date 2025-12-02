/************************************************************************/
/*	Archivo: 		cartrnmc.sp				*/
/*	Stored procedure: 	sp_cargar_trn_mesa_cambio	        */
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Marcelo Poveda A. 			*/
/*	Fecha de escritura: 	02/14/2002				*/
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
/*	Consulta y carga en tabla temporal las transacciones necesarias */
/*      para Mesa de Cambio						*/
/************************************************************************/

-- MPO Ref. 017 02/14/2002
use cob_cartera
go



if exists(select 1 from sysobjects where name = 'sp_carga_trn_mesa_cambio')
   drop proc sp_carga_trn_mesa_cambio
go


create proc sp_carga_trn_mesa_cambio
@i_fecha_ini		datetime,
@i_fecha_fin		datetime
as
declare
@w_op_banco		cuenta,
@w_op_operacion		int,
@w_op_moneda		smallint,
@w_op_toperacion	catalogo,
@w_tr_secuencial	int,
@w_tr_tran		catalogo,
@w_tr_fecha_mov		datetime,
@w_tr_estado		catalogo,
@w_tr_comprobante	int,
@w_tr_fecha_cont	datetime,
@w_reversado		int,
@w_dtr_moneda		smallint,
@w_moneda_legal		smallint,
@w_dtr_monto		money,
@w_dtr_cotizacion	money,
@w_dtr_monto_mn		money,
@w_naturaleza		char(1)

/** INICIALIZACION DE VARIABLES **/
-- seleccion moneda legal
select @w_moneda_legal = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

-- limpiar tabla temporal
delete ca_mesacambio_temp WHERE mt_comprobante >= 0


/** CURSOR DE OPERACIONES **/
declare cursor_operacion cursor for
select op_banco,	op_operacion,		op_moneda,
       op_toperacion
from   ca_operacion
where  op_moneda != 0
and    op_estado not in (0,98,99)
for read only

open cursor_operacion

fetch cursor_operacion into
@w_op_banco,	@w_op_operacion,	@w_op_moneda,
@w_op_toperacion

while @@fetch_status = 0 begin

   /** SELECCIONAR NATURALEZA DE OPERACION **/
   select @w_naturaleza = dt_naturaleza
   from   ca_default_toperacion
   where  dt_toperacion = @w_op_toperacion
 
   /** CURSOR DE TRANSACCIONES **/
   declare cursor_transacciones cursor for
   select 
   tr_secuencial,	tr_tran,		tr_fecha_mov, 
   tr_estado,		tr_comprobante,		tr_fecha_cont
   from  ca_transaccion
   where tr_operacion = @w_op_operacion
   and   tr_tran   in ('PRV', 'AMO', 'RPA')
   and   tr_estado in ('ING', 'CON', 'RV') 
   and   tr_fecha_mov >= @i_fecha_ini
   and   tr_fecha_mov <= @i_fecha_fin
   for read only

   open cursor_transacciones

   fetch cursor_transacciones into
   @w_tr_secuencial,	@w_tr_tran,		@w_tr_fecha_mov,
   @w_tr_estado,	@w_tr_comprobante,	@w_tr_fecha_cont

   while @@fetch_status = 0 begin

      -- Inicializacion de variables
      select @w_reversado = 1

      -- Transaccion Pago
      if @w_tr_tran = 'RPA' and @w_naturaleza = 'A' begin
         -- Validar moneda de pago
         select @w_dtr_moneda = dtr_moneda
         from   ca_det_trn
         where  dtr_operacion  = @w_op_operacion
         and    dtr_secuencial = @w_tr_secuencial
         and    dtr_concepto   not like 'VAC%'

         if @w_dtr_moneda != @w_moneda_legal
             goto SIGUIENTE

         -- Determinar si la reversa fue contabilizada
         if @w_tr_estado = 'RV' begin
            if exists (select 1 from ca_transaccion
            where  tr_operacion = @w_op_operacion
            and    tr_secuencial = @w_tr_secuencial * -1)
               select @w_reversado = -1
            else begin
               select @w_reversado = 1
               goto SIGUIENTE
            end
         end

         -- Insertar la informaci¢n 
         select @w_dtr_monto = dtr_monto * @w_reversado,
         @w_dtr_cotizacion   = dtr_cotizacion,
         @w_dtr_monto_mn     = dtr_monto_mn * @w_reversado
         from   ca_det_trn
         where  dtr_operacion  = @w_op_operacion
         and    dtr_secuencial = @w_tr_secuencial 
         and    dtr_concepto   like 'VAC%'

         if @@rowcount != 0
            insert ca_mesacambio_temp(
            mt_fecha,	mt_tran,	mt_moneda,
            mt_monto,	mt_cotizacion,	mt_monto_mn,
            mt_en_linea,mt_banco,	mt_comprobante,
	    mt_fecha_cont
            )
            values  
            (
            @w_tr_fecha_mov,	'PAG',	   	   @w_op_moneda,
            @w_dtr_monto,	@w_dtr_cotizacion, @w_dtr_monto_mn,
            'N',		@w_op_banco,	   @w_tr_comprobante,
	    @w_tr_fecha_cont
            )     
      end


      -- Transaccion Causacion
      if @w_tr_tran in ('PRV', 'AMO') begin
         -- Determinar si la reversa fue contabilizada
         if @w_tr_estado = 'RV' begin
            if exists (select 1 from ca_transaccion
            where  tr_operacion  = @w_op_operacion
            and    tr_secuencial = @w_tr_secuencial * -1)
               select @w_reversado = -1
            else begin
               select @w_reversado = 1
               goto SIGUIENTE
            end
         end

         -- Insertar la informacion 
         select @w_dtr_monto = dtr_monto * @w_reversado,
         @w_dtr_cotizacion   = dtr_cotizacion,
         @w_dtr_monto_mn     = dtr_monto_mn * @w_reversado
         from   ca_det_trn
         where  dtr_operacion  = @w_op_operacion
         and    dtr_secuencial = @w_tr_secuencial 
         
         if @@rowcount != 0
            insert ca_mesacambio_temp(
            mt_fecha,	mt_tran,	mt_moneda,
            mt_monto,	mt_cotizacion,	mt_monto_mn,
            mt_en_linea,mt_banco,	mt_comprobante,
	    mt_fecha_cont
            )
            values  
            (
            @w_tr_fecha_mov,	@w_tr_tran,	   @w_op_moneda,
            @w_dtr_monto,	@w_dtr_cotizacion, @w_dtr_monto_mn,
            'N',		@w_op_banco,	   @w_tr_comprobante,
	    @w_tr_fecha_cont
            )     
      end            

      goto SIGUIENTE

      SIGUIENTE:
      fetch cursor_transacciones into
      @w_tr_secuencial,	@w_tr_tran,		@w_tr_fecha_mov,
      @w_tr_estado,	@w_tr_comprobante,	@w_tr_fecha_cont   
      
   end
   close cursor_transacciones
   deallocate cursor_transacciones
      
   fetch cursor_operacion into
   @w_op_banco,		@w_op_operacion,	@w_op_moneda,
   @w_op_toperacion
end
close cursor_operacion
deallocate cursor_operacion

-- MPO Ref. 017 02/14/2002

return 0
go


