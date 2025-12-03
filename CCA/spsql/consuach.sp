/************************************************************************/
/*	Archivo: 		consuach.sp			        */
/*	Stored procedure: 	sp_consultar_envios_ach		        */
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		ELCIRA PELAEZ BURBANO           	*/
/*	Fecha de escritura: 	02-FEB-2001				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA"							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Consulta la informacion de cob_compensacion..ach_maestro      	*/
/*      Operaciones:							*/
/*                   'Q' @i_estado <> 'T' envia a front-end los registro*/
/*			 de ach_maestro  que cumplan con la condicon de */
/*			 estado, fecha_ingreso y cedula                 */
/*                   'Q' @i_estado = 'T' envia a front-end los registro */
/*			 de ach_maestro  que cumplan con la condicon de */
/*			 fecha_ingreso y cedula  sin importar estado    */
/*                   'C' envia a front-end los registro  de ach_maestro */
/*			 que cumplan con la condicon de cedula          */
/*                   'F' envia a front-end los registro  de ach_maestro */
/*			 que cumplan con la condicon de fecha de ingreso*/
/************************************************************************/
/*	 								*/
/*	      		                        			*/
/************************************************************************/
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_consultar_envios_ach')
   drop proc sp_consultar_envios_ach
go

create proc sp_consultar_envios_ach (
   @i_operacion		char(1)     = null,
   @i_formato_fecha	int         = null,
   @i_fecha_ingreso     datetime    = null,
   @i_nit	        cuenta      = null,
   @i_estado            varchar(10) = null,
   @i_nom_producto      char(3)     = null

)

as
declare	@w_sp_name			varchar(32),
       	@w_return			int,
	@w_error        		int,
        @w_opcion			int



/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_consultar_envios_ach'

/** PARCHADO HASTA CUANDO SE DECIDA UTILIZAR -- JCQ -- 10/10/2002 **/
/**

if @i_operacion='Q'  and @i_estado <> 'T' begin

  select 
    'Cedula_Nit'    = ma_nit,
    'Valor'	      = ma_monto,
    'Cod. Banco'      = ma_codigo_banco,
    'Transaccion'     = ma_descripcion,
    'Fecha Ingreso'   = convert(varchar,ma_fecha_ing,@i_formato_fecha),
    'Fecha Proceso'   = convert(varchar,ma_fecha_pro,@i_formato_fecha),
    'Estado'          = ma_estado,
    'Codigo Sec. Prod' = ma_codigo,
    'Tipo de Cuenta' = ma_tipo_cuenta
   from cob_compensacion..ach_maestro
   where ma_fecha_ing  = @i_fecha_ingreso 
     and ma_nit        = @i_nit
     and ma_estado     = @i_estado
     and substring(ma_codigo,1,3) = @i_nom_producto
 if @@rowcount = 0   
  select '0'
 else
  select '1'

end  /*Fin Todos */
else
if @i_operacion='Q'  and @i_estado = 'T' begin
  select 
    'Cedula_Nit'    = ma_nit,
    'Valor'	      = ma_monto,
    'Cod. Banco'      = ma_codigo_banco,
    'Transaccion'     = ma_descripcion,
    'Fecha Ingreso'   = convert(varchar,ma_fecha_ing,@i_formato_fecha),
    'Fecha Proceso'   = convert(varchar,ma_fecha_pro,@i_formato_fecha),
    'Estado'          = ma_estado,
    'Codigo Sec. Prod' = ma_codigo,
    'Tipo de Cuenta' = ma_tipo_cuenta
   from cob_compensacion..ach_maestro
   where ma_fecha_ing  = @i_fecha_ingreso 
     and ma_nit        = @i_nit
     and substring(ma_codigo,1,3) = @i_nom_producto
 if @@rowcount = 0   
  select '0'
 else
  select '1'

end

if @i_operacion='C' begin
  select 
    'Cedula_Nit'    = ma_nit,
    'Valor'	      = ma_monto,
    'Cod. Banco'      = ma_codigo_banco,
    'Transaccion'     = ma_descripcion,
    'Fecha Ingreso'   = convert(varchar,ma_fecha_ing,@i_formato_fecha),
    'Fecha Proceso'   = convert(varchar,ma_fecha_pro,@i_formato_fecha),
    'Estado'          = ma_estado,
    'Codigo Sec. Prod' = ma_codigo,
    'Tipo de Cuenta' = ma_tipo_cuenta
   from cob_compensacion..ach_maestro
   where ma_nit        = @i_nit
     and substring(ma_codigo,1,3) = @i_nom_producto
 if @@rowcount = 0   
  select '0'
 else
  select '1'

end /*Fin Cedula*/

if @i_operacion='F'  begin
  select 
    'Cedula_Nit'    = ma_nit,
    'Valor'	      = ma_monto,
    'Cod. Banco'      = ma_codigo_banco,
    'Transaccion'     = ma_descripcion,
    'Fecha Ingreso'   = convert(varchar,ma_fecha_ing,@i_formato_fecha),
    'Fecha Proceso'   = convert(varchar,ma_fecha_pro,@i_formato_fecha),
    'Estado'          = ma_estado,
    'Codigo Sec. Prod' = ma_codigo,
    'Tipo de Cuenta' = ma_tipo_cuenta
   from cob_compensacion..ach_maestro
   where ma_fecha_ing  = @i_fecha_ingreso 
     and substring(ma_codigo,1,3) = @i_nom_producto
 if @@rowcount = 0   
  select '0'
 else
  select '1'

end  /*Fin Fecha Ing*/


if @i_operacion='E' begin
  select 
    'Cedula_Nit'    = ma_nit,
    'Valor'	      = ma_monto,
    'Cod. Banco'      = ma_codigo_banco,
    'Transaccion'     = ma_descripcion,
    'Fecha Ingreso'   = convert(varchar,ma_fecha_ing,@i_formato_fecha),
    'Fecha Proceso'   = convert(varchar,ma_fecha_pro,@i_formato_fecha),
    'Estado'          = ma_estado,
    'Codigo Sec. Prod' = ma_codigo,
    'Tipo de Cuenta' = ma_tipo_cuenta
   from cob_compensacion..ach_maestro
  where ma_estado     = @i_estado
    and substring(ma_codigo,1,3) = @i_nom_producto

 if @@rowcount = 0   
   select '0'
 else
  select '1'

end  /*Estado */


set rowcount 0

**/

return 0


go


