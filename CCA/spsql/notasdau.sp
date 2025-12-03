/************************************************************************/
/*	Archivo:		         notasdau.sp		                                 */
/*	Stored procedure:	   sp_ndaut_batch		                              */
/*	Disenado por:  		Elcira Pelaez		                              */
/*	Fecha de escritura:	Oct-19-2001 		                              */
/************************************************************************/
/*                         IMPORTANTE                                   */
/*	Este programa es parte de los paquetes bancarios propiedad de	      */
/*	'MACOSA'.                                                            */
/*	Su uso no autorizado queda expresamente prohibido asi como	         */
/*	cualquier alteracion o agregado hecho por alguno de sus		         */
/*	usuarios sin el debido consentimiento por escrito de la 	            */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/
/*                          PROPOSITO	                                 */
/*	Procedimiento que realiza  la generacion de notas debito             */
/*	automaticas a las operaciones con esta forma de pago                 */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*   JUL 17 2006      Elcira Pelaez   DEF-6753  BAC                     */
/*   OCT 12 2006      Elcira Pelaez   DEF-7226  BAC                     */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_ndaut_batch')
   drop proc sp_ndaut_batch
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_ndaut_batch
@s_user		     	login,
@s_term		     	varchar(30),
@s_date		     	datetime,
@s_ofi		     	smallint,
@i_fecha_proceso        datetime



as

declare 
@w_error          	int,
@w_return         	int,
@w_sp_name        	descripcion,
@w_aceptar_anticipos    char(1),
@w_tipo_reduccion       char(1),
@w_tipo_cobro           char(1),
@w_tipo_aplicacion      char(1),
@w_oficina              smallint,
@w_forma_pago           catalogo,
@w_cuenta               cuenta,
@w_est_novedades        tinyint,
@w_moneda_nacional      tinyint,
@w_toperacion 		catalogo,
@w_naturaleza           char(1),
@w_commit               char(1),
@w_banco                cuenta,
@w_operacionca          int,
@w_retencion            smallint,
@w_moneda_pag           smallint,
@w_dividendo_vigente    smallint,
@w_estado_dividendo     smallint,
@w_dividendo_procesar   smallint,
@w_dividendo_vencido    smallint,
@w_op_fecha_ult_proceso   datetime,
@w_di_fecha_ven           datetime



/** CARGADO DE VARIABLES DE TRABAJO **/
select 
@w_sp_name       = 'sp_ndaut_batch',
@s_user          = isnull(@s_user, suser_name()),
@s_term          = isnull(@s_term, 'CONSOLA'),
@s_date          = isnull(@s_date, getdate()),
@s_ofi           = isnull(@s_ofi , 900)



--PARAMETROS GENERALES 

select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


--cargar tabla de control

delete ca_opercaion_ndaut
where ona_fecha_proceso = @i_fecha_proceso

insert into ca_opercaion_ndaut
select @i_fecha_proceso,op_operacion,0,null
from   ca_operacion,
       ca_producto,
       ca_estado
where  op_forma_pago = cp_producto
and   cp_pago_aut   = 'S'
and   op_cuenta     is not null
and  ((cp_pcobis = 3 or cp_pcobis = 4) )
and   op_naturaleza = 'A'
and   op_estado = es_codigo
and    es_procesa = 'S'
and  isnull(op_estado_cobranza, '') != 'CJ'  -- DEF-7226


--- CURSOR PARA LEER  LAS OPERACIONES A PROCESAR 

declare cursor_operacion cursor for
select
op_operacion,	op_aceptar_anticipos,	op_tipo_reduccion,
op_tipo_cobro,	op_tipo_aplicacion,	op_oficina,
op_forma_pago,	op_cuenta,		cp_retencion,
cp_moneda,	op_toperacion,	  	op_banco,
op_fecha_ult_proceso
from   ca_operacion,
       ca_producto,
       ca_estado,
       ca_opercaion_ndaut
where  op_operacion = ona_operacion
and    ona_fecha_proceso = @i_fecha_proceso
and    op_forma_pago = cp_producto
and   cp_pago_aut   = 'S'
and   op_cuenta     is not null
and  ((cp_pcobis = 3 or cp_pcobis = 4) )
and   op_naturaleza = 'A'
and   op_estado = es_codigo
and    es_procesa = 'S'
and  isnull(op_estado_cobranza, '') != 'CJ'  -- DEF-7226
for read only

open  cursor_operacion

fetch cursor_operacion into 
@w_operacionca,	@w_aceptar_anticipos,	@w_tipo_reduccion,
@w_tipo_cobro,	@w_tipo_aplicacion,	@w_oficina,
@w_forma_pago,	@w_cuenta,		@w_retencion,
@w_moneda_pag,	@w_toperacion,		@w_banco,
@w_op_fecha_ult_proceso

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
 begin   

      --- VALIDAR SI ES MONEDA EXTRANJERA 
      
      if @w_moneda_pag <> @w_moneda_nacional
      select @w_moneda_pag = @w_moneda_nacional

     select @w_dividendo_vigente = isnull(max(di_dividendo),0)
      from   ca_dividendo
      where  di_estado = 1
      and    di_operacion = @w_operacionca
      
      select @w_dividendo_vencido = isnull(max(di_dividendo),0)
      from   ca_dividendo
      where  di_estado = 2
      and    di_operacion = @w_operacionca
      
      select @w_di_fecha_ven = di_fecha_ven
      from   ca_dividendo
      where   di_dividendo = @w_dividendo_vigente
      and    di_operacion = @w_operacionca

    
      if @w_di_fecha_ven = @i_fecha_proceso and @w_dividendo_vigente > 0
         begin
           select @w_estado_dividendo = 1
           select @w_dividendo_procesar = @w_dividendo_vigente
         end   
      else
         if @w_dividendo_vencido > 0
         begin
            select @w_estado_dividendo = 2,
                   @w_dividendo_procesar = @w_dividendo_vencido
         end   
                      

      begin tran --atomicidad por registro
      select @w_commit = 'S'
              
        
         if (@w_di_fecha_ven = @i_fecha_proceso and @w_dividendo_vigente > 0) or (@w_dividendo_vencido) > 0
         begin
            ---PRINT 'notasdau.sp  va para sp_genera_afect_productos %1!',@w_banco
            
      	   exec @w_return = sp_genera_afect_productos
      	   @s_user		         = @s_user,
      	   @s_term		         = @s_term,
      	   @s_ofi		         = @w_oficina,
      	   @s_date              = @s_date,
      	   @i_operacionca 	   = @w_operacionca,
      	   @i_aceptar_anticipos = @w_aceptar_anticipos,
      	   @i_tipo_reduccion    = @w_tipo_reduccion,
      	   @i_tipo_cobro        = @w_tipo_cobro,
      	   @i_tipo_aplicacion   = @w_tipo_aplicacion,
      	   @i_oficina           = @w_oficina,
      	   @i_forma_pago        = @w_forma_pago,
      	   @i_cuenta            = @w_cuenta,
      	   @i_retencion         = @w_retencion,
      	   @i_moneda_pag        = @w_moneda_pag,
      	   @i_banco             = @w_banco,
      	   @i_fecha_proceso    	= @i_fecha_proceso,
      	   @i_estado_dividendo  = @w_estado_dividendo,
      	   @i_dividendo_procesar = @w_dividendo_procesar
      
            if @w_return != 0 
            begin
                select  @w_error  = @w_return
                goto ERROR
            end
            else
            begin
               --cargadas paso numero 1 roceso notasdau.sp
               update ca_opercaion_ndaut
               set ona_proceso = 'notasdau.sp',
                   ona_numero_indicador  = 1     
               where ona_operacion = @w_operacionca
               and   ona_fecha_proceso = @i_fecha_proceso
              
            end
        end
        
      commit tran     ---Fin de la transaccion 
      select @w_commit = 'N'

   goto SIGUIENTE

   ERROR:  
                                                    
   exec sp_errorlog                                             
   @i_fecha       = @i_fecha_proceso,
   @i_error       = @w_error,
   @i_usuario     = @s_user,
   @i_tran        = 7000, 
   @i_tran_name   = @w_sp_name,
   @i_rollback    = 'N',  
   @i_cuenta      = @w_banco,
   @i_descripcion = 'GENERANDO NOTA DEBITO AUTOMATICA POR BATCH'

   if @w_commit = 'S' commit tran
   goto SIGUIENTE


   SIGUIENTE: 
   fetch cursor_operacion into 
   @w_operacionca,	@w_aceptar_anticipos,	@w_tipo_reduccion,
   @w_tipo_cobro,	   @w_tipo_aplicacion,	   @w_oficina,
   @w_forma_pago,   	@w_cuenta,		         @w_retencion,
   @w_moneda_pag,	   @w_toperacion,		      @w_banco,
   @w_op_fecha_ult_proceso
end --- cursor_operacion 
close cursor_operacion
deallocate cursor_operacion

set rowcount 0

return 0
go


