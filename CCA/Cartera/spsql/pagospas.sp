/************************************************************************/
/*	Archivo:		pagospas.sp				*/
/*	Stored procedure:	sp_genera_pago_pasiva			*/
/*	Disenado por:  		Elcira Pelaez				*/
/*	Fecha de escritura:	Feb-2003 				*/
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
/*	Procedimiento que realiza  la generacion de los pagos           */
/*	automaticamente para las operaciones pasivas.                   */
/*      Si hay feriados estos pagos se haran el proximo dia h bil       */
/*      para garantizar esto se leeran los vencimientos de la tabla     */
/*      ca_conciliacion_diaria 						*/
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*  	Mar 2003	M¢nica Mari¤o	    Compilaci¢n		        */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = "sp_genera_pago_pasiva")
   drop proc sp_genera_pago_pasiva
go

create proc sp_genera_pago_pasiva
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
@w_moneda_nacional      tinyint,
@w_toperacion 		catalogo,
@w_naturaleza           char(1),
@w_commit               char(1),
@w_banco                cuenta,
@w_operacionca          int,
@w_moneda_pag           smallint,
@w_div_vencidos         int,
@w_op_tipo_linea	catalogo,
@w_cd_dividendo		int,
@w_forma_pago_bsp    	catalogo,
@w_forma_bsp    	catalogo,
@w_cotizacion           float,
@w_codigo_agrario       catalogo,
@w_codigo_ifi           catalogo,
@w_codigo_bcodex        catalogo,
@w_codigo_findeter      catalogo,
@w_codigo_finagro       catalogo,
@w_codigo_republica     catalogo,
@w_cd_abono_capital     money,
@w_cd_abono_interes     money,
@w_rowcount             int




--- CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name       = "sp_genera_pago_pasiva",
@s_user          = isnull(@s_user, suser_name()),
@s_term          = isnull(@s_term, "CONSOLA"),
@s_date          = isnull(@s_date, getdate()),
@s_ofi           = isnull(@s_ofi , 900)


--- PARAMETROS GENERALES 
select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


select @w_forma_bsp = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'FPBSP'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 710436  

--ESTOS CODIGO SON TOMADO DE LA TABLA DE CATALOGO ca_tipo_linea
select @w_codigo_agrario   = '143'   ---AGRARIO
select @w_codigo_ifi       = '215'   ---IFI
select @w_codigo_bcodex    = '221'   ---BANCOLDEX
select @w_codigo_findeter  = '222'   ---FINDETER
select @w_codigo_finagro   = '224'   ---FINAGRO
select @w_codigo_republica = '301'   ---REPUBLICA


--ANTES DE PROCESAR, SE BORRAN LOS PAGOS ING QUE TENGAN LAS OPERACIONES DE FORMA AUTOMATICA

if exists (select 1  from  ca_abono,ca_abono_det,ca_conciliacion_diaria
            where ab_operacion = cd_operacion
            and ab_estado = 'ING'
            and   abd_operacion = ab_operacion
            and   abd_secuencial_ing = ab_secuencial_ing
            and   abd_beneficiario = 'PAGO AUTOMATICO PASIVAS'
            and   abd_concepto   like 'FPBSP%'
            and   abd_operacion = cd_operacion)
begin
   --Marcarlos
   update ca_abono
   set ab_estado = 'BOR'
   from 
     ca_abono,
     ca_abono_det,
     ca_conciliacion_diaria
   where ab_operacion = cd_operacion
   and   ab_estado = 'ING'
   and   abd_operacion = ab_operacion
   and   abd_secuencial_ing = ab_secuencial_ing
   and   abd_beneficiario = 'PAGO AUTOMATICO PASIVAS'
   and   abd_concepto   like 'FPBSP%'
   and   abd_operacion = cd_operacion
   
   --Eliminarlos por que ya se insertaran nuevamente

  --Borrar pagos Marcados
  delete ca_abono_prioridad
  from  ca_abono,
        ca_abono_prioridad
  where ab_estado = 'BOR'
  and   ap_operacion    =  ab_operacion
  and   ap_secuencial_ing = ab_secuencial_ing

  delete ca_abono_det
  from  ca_abono_det,
        ca_abono
  where abd_operacion    = ab_operacion
  and   abd_secuencial_ing = ab_secuencial_ing
  and   ab_estado = 'BOR'

  delete ca_abono
  where  ab_estado = 'BOR'
     
end



--- CURSOR PARA LEER  LAS OPERACIONES A PROCESAR 
declare cursor_pagos_pasivas cursor for
select
op_operacion,	
op_aceptar_anticipos,	
op_tipo_reduccion,
op_tipo_cobro,	
op_tipo_aplicacion,	
op_oficina,
op_moneda,	
op_toperacion,
op_banco,
op_tipo_linea,
cd_dividendo,
cd_cotizacion,
cd_abono_capital,
cd_abono_interes
from   cob_cartera..ca_operacion,
       cob_cartera..ca_conciliacion_diaria,
       cob_cartera..ca_estado
where   op_operacion        = cd_operacion 
and    op_tipo              = 'R' ---Todas las pasivas
and    cd_estado            in ('N','A') --Las actualizadas por front-end
and    op_estado            = es_codigo
and    es_procesa           = 'S'
group by op_operacion,	
op_aceptar_anticipos,	
op_tipo_reduccion,
op_tipo_cobro,	
op_tipo_aplicacion,	
op_oficina,
op_moneda,	
op_toperacion,
op_banco,
op_tipo_linea,
cd_dividendo,
cd_cotizacion,
cd_abono_capital,
cd_abono_interes
order by op_operacion,	
op_aceptar_anticipos,	
op_tipo_reduccion,
op_tipo_cobro,	
op_tipo_aplicacion,	
op_oficina,
op_moneda,	
op_toperacion,
op_banco,
op_tipo_linea,
cd_dividendo,
cd_cotizacion,
cd_abono_capital,
cd_abono_interes

for read only

open  cursor_pagos_pasivas

fetch cursor_pagos_pasivas 
into 
   @w_operacionca,	
   @w_aceptar_anticipos,	
   @w_tipo_reduccion,
   @w_tipo_cobro,	
   @w_tipo_aplicacion,	
   @w_oficina,
   @w_moneda_pag,	
   @w_toperacion,		
   @w_banco,
   @w_op_tipo_linea,
   @w_cd_dividendo,
   @w_cotizacion,
   @w_cd_abono_capital,
   @w_cd_abono_interes


while @@fetch_status = 0 
begin   

   if @@fetch_status = -1 
   begin    
       select @w_error = 70899
       goto  ERROR
   end   



   -- POR SOLICITUD DEL BAC, LAS OPERACIONES IFI, SON PARAMETRIZADAS CON BANCOLDEX 
   if ltrim(rtrim(@w_op_tipo_linea)) =  ltrim(rtrim(@w_codigo_ifi))
      select @w_op_tipo_linea = @w_codigo_bcodex

 

   ---SE ARMA LA FORMA DE PAGO DEPENDIENDO EL BANCO DE SEGUNDO PISO
  select @w_forma_pago_bsp = ltrim(rtrim(@w_forma_bsp)) + ltrim(rtrim(@w_op_tipo_linea))

  
    --VALIDAR LA EXISTENCIA DE LA FORMA DE PAGO YA ARMADA

   if not exists (select 1 from ca_producto
      where cp_producto = @w_forma_pago_bsp)
   begin
      select @w_error = 710437   
      goto  ERROR
   end


   --- VALIDAR SI ES MONEDA EXTRANJERA 
   if @w_moneda_pag <> @w_moneda_nacional
      select @w_moneda_pag = @w_moneda_nacional
      
   --LAS PASIVAS SIEMPRE PAGAN TODO PROYECTADO
   if @w_tipo_cobro != 'P'
      select @w_tipo_cobro = 'P'   

   begin tran --atomicidad por registro
   select @w_commit = 'S'
      
	   exec @w_return = sp_genera_pago_pasiva_int
	   @s_user		          = @s_user,
	   @s_term		          = @s_term,
	   @s_ofi		          = @s_ofi,
	   @s_date               = @s_date,
	   @i_operacionca 	    = @w_operacionca,
	   @i_aceptar_anticipos  = @w_aceptar_anticipos,
	   @i_tipo_reduccion     = @w_tipo_reduccion,
	   @i_tipo_cobro         = @w_tipo_cobro,
	   @i_tipo_aplicacion    = @w_tipo_aplicacion,
	   @i_oficina            = @w_oficina,
	   @i_forma_pago         = @w_forma_pago_bsp,
	   @i_cuenta             = '',
	   @i_retencion          = 0,
	   @i_moneda_pag         = @w_moneda_pag,
	   @i_banco              = @w_banco,
      @i_cd_dividendo       = @w_cd_dividendo,
	   @i_fecha_proceso 	    = @i_fecha_proceso,
	   @i_cotizacion         = @w_cotizacion,
      @i_cd_abono_capital   = @w_cd_abono_capital,
      @i_cd_abono_interes   = @w_cd_abono_interes


      if @w_return != 0 
      begin
         select  @w_error  = @w_return
         
         update ca_conciliacion_diaria 
         set cd_estado = 'E'
         where cd_operacion = @w_operacionca
         and   cd_dividendo = @w_cd_dividendo
         
         goto ERROR
         
      end

   update ca_conciliacion_diaria 
   set cd_estado = 'P'
   where cd_operacion = @w_operacionca
   and   cd_dividendo = @w_cd_dividendo

   commit tran     ---Fin de la transaccion 
   select @w_commit = 'N'

   goto SIGUIENTE

   ERROR:  
                                                    
   exec sp_errorlog                                             
   @i_fecha     = @i_fecha_proceso,
   @i_error     = @w_error,
   @i_usuario   = @s_user,
   @i_tran      = 7000, 
   @i_tran_name = @w_sp_name,
   @i_rollback  = 'N',  
   @i_cuenta    = @w_banco,
   @i_descripcion = 'GENERANDO PAGOS CARTERA PASIVA'

   if @w_commit = 'S' 
      commit tran

   goto SIGUIENTE


   SIGUIENTE: 
   fetch cursor_pagos_pasivas 
   into 
   @w_operacionca,	
   @w_aceptar_anticipos,	
   @w_tipo_reduccion,
   @w_tipo_cobro,	
   @w_tipo_aplicacion,	
   @w_oficina,
   @w_moneda_pag,	
   @w_toperacion,		
   @w_banco,
   @w_op_tipo_linea,
   @w_cd_dividendo,
   @w_cotizacion,
   @w_cd_abono_capital,
   @w_cd_abono_interes


end -- cursor_pagos_pasivas 
close cursor_pagos_pasivas
deallocate cursor_pagos_pasivas


set rowcount 0

return 0
go


