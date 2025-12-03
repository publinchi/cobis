/************************************************************************/
/*	Archivo            :       reajuant.sp                          */
/*	Stored procedure   :	   sp_reajuste_oper_intant              */
/*	Base de datos      :	   cob_cartera                          */
/*	Producto           : 	   Cartera                              */
/*	Disenado por       :  	   Elcira Pelaez Burbano                */
/*	Fecha de escritura :	   Agosto-21-2001                       */
/************************************************************************/
/*	                            IMPORTANTE                          */
/*	Este programa es parte de los paquetes bancarios propiedad de   */
/*	'MACOSA'.                                                       */
/*	Su uso no autorizado queda expresamente prohibido asi como      */
/*	cualquier alteracion o agregado hecho por alguno de sus         */
/*	usuarios sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante.             */
/*	                              PROPOSITO                         */
/************************************************************************/
/*	Procedimiento que realiza los reajustes a las operaciones       */
/*	INTANT                                                          */
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*      marzo-2004        Elcira             Personalizacion para el BAC*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reajuste_oper_intant')
   drop proc sp_reajuste_oper_intant
go

create proc sp_reajuste_oper_intant
@s_user		     	login,
@s_term		     	varchar(30),
@s_date		     	datetime,
@s_ofi		     	smallint,
@i_fecha_proceso    datetime

as

declare 
   @w_error          	 int,
   @w_return         	 int,
   @w_sp_name        	 descripcion,
   @w_int_ant            catalogo,
   @w_modalidad          catalogo,
   @w_operacionca        int,
   @w_fecha_ult_proceso  datetime,
   @w_commit             char(1),
   @w_banco              cuenta,
   @w_moneda_uvr         tinyint,
   @w_moneda_nacional    tinyint,
   @w_cotizacion_hoy     float,
   @w_concepto_int       catalogo,
   @w_concepto_cap       catalogo,
   @w_op_moneda          smallint,
   @w_num_dec            int,
   @w_aux1               smallint,
   @w_decimales_nacional int,
   @w_rowcount           int

-- CARGADO DE VARIABLES DE TRABAJO 

select 
@w_sp_name       = 'sp_reajuste_oper_intant',
@s_user          = isnull(@s_user, suser_name()),
@s_term          = isnull(@s_term, 'BATCH_CARTERA'),
@s_date          = isnull(@s_date, getdate()),
@s_ofi           = isnull(@s_ofi , 1),
@w_commit        = 'N'

select @w_int_ant = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and pa_nemonico = 'INTANT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 710256
   goto ERROR
end

select @w_concepto_int = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and pa_nemonico = 'INT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 710256
   goto ERROR
end

select @w_concepto_cap = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and pa_nemonico = 'CAP'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 710256
   goto ERROR
end

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 708174
   goto ERROR
end

-- CODIGO DE LA MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
begin
   select @w_error = 710256
   goto ERROR
end

--PRINT 'reajunat.sp INICIO DE REAJUSTE INTANT con FECHA' + cast(@i_fecha_proceso as varchar)

select ro_operacion
into #intant
from ca_rubro_op 
where ro_concepto = @w_int_ant

--- CURSO PARA LEER TODAS LAS OPERACIONES A PROCESAR
declare cursor_operacion cursor for
select op_operacion, op_fecha_ult_proceso, op_banco, op_moneda
from cob_cartera..ca_operacion,
     cob_cartera..ca_dividendo,
     cob_cartera..ca_reajuste,
     #intant
where op_operacion = di_operacion
and   op_operacion = re_operacion
and   di_operacion = re_operacion
and   op_operacion = ro_operacion
and   di_operacion = ro_operacion
and   di_fecha_ini = re_fecha
and   re_fecha     = @i_fecha_proceso  
and   op_estado in (1,5,8,9,10)
for read only

open  cursor_operacion

fetch cursor_operacion into 
        @w_operacionca,	@w_fecha_ult_proceso,	@w_banco,	@w_op_moneda

while @@fetch_status = 0 
begin   

   if @@fetch_status = -1 
    begin    
       select @w_error = 70899
       goto  ERROR
   end   

   exec @w_return = sp_buscar_cotizacion
        @i_moneda     = @w_op_moneda,
        @i_fecha      = @w_fecha_ult_proceso,
        @o_cotizacion = @w_cotizacion_hoy output

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

   exec @w_return       = sp_decimales
        @i_moneda       = @w_op_moneda,
        @o_decimales    = @w_num_dec out,
        @o_mon_nacional = @w_aux1    out,
        @o_dec_nacional = @w_decimales_nacional out

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

   begin tran --atomicidad por registro
   select @w_commit = 'S'

   select @w_modalidad = ro_fpago
   from ca_rubro_op
   where ro_operacion  = @w_operacionca
   and ro_tipo_rubro   = 'I'
   and ro_provisiona   = 'S'

   exec @w_return = sp_reajuste
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_date            = @s_date,
   @s_ofi             = @s_ofi,
   @i_en_linea        = 'N',
   @i_fecha_proceso   = @i_fecha_proceso,
   @i_operacionca     = @w_operacionca,
   @i_monto_capit     = 0,
   @i_modalidad       = @w_modalidad,
   @i_moneda_local    = @w_moneda_nacional,
   @i_moneda_uvr      = @w_moneda_uvr,
   @i_cotizacion      = @w_cotizacion_hoy,
   @i_num_dec         = @w_num_dec,
   @i_concepto_int    = @w_concepto_int,
   @i_concepto_cap    = @w_concepto_cap

   if @w_return != 0 
    begin
      --PRINT 'reajuant.sp salio con error de sp_reajuste'
      select @w_error = @w_return
      goto ERROR
   end

   commit tran     ---Fin de la transaccion
   select @w_commit = 'N'
   goto SALIR 

   ERROR:
   exec sp_errorlog 
   @i_fecha      = @s_date,                      
   @i_error      = @w_error, 
   @i_usuario    = @s_user, 
   @i_tran       = 7999,
   @i_tran_name  = @w_sp_name,
   @i_cuenta     = @w_banco,
   @i_descripcion = 'ERROR REAJUSTANDO OPERACIONES DE INTERES INTANT',
   @i_rollback = 'S'
   if @w_commit = 'S' commit tran
   goto SALIR 

 SALIR:
 fetch cursor_operacion into 
 @w_operacionca,	@w_fecha_ult_proceso,	@w_banco,  	@w_op_moneda
end -- cursor_operacion 

close cursor_operacion
deallocate cursor_operacion

--PRINT 'reajunat.sp FIN  DE REAJUSTE INTANT con FECHA' + cast(@i_fecha_proceso as varchar)

return 0

go


