/************************************************************************/
/*      Archivo:                maestext.sp                             */
/*      Stored procedure:       sp_maestro_ach_ext                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez Burbano		        */
/*      Fecha de escritura:     Feb. 2001                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA", representantes exclusivos para el Ecuador de la       */
/*      "NCR CORPORATION".                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Ejecutar sp_maestro_ach                                         */
/* 									*/
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*                                                                      */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_maestro_ach_ext')
	drop proc sp_maestro_ach_ext
go
create proc sp_maestro_ach_ext
   @s_user		login       = null,
   @s_ofi 		smallint    = null,
   @s_date              datetime    = null,
   @i_nom_producto      char(3)     = null,  ---Abreviatura
   @i_valor             money       = null,
   @i_codigo_banco	int         = null,
   @i_cliente   	int         = null,
   @i_categoria_fpago   char(1)     = null,
   @i_cuenta    	cuenta      = null,
   @i_des_transaccion  	descripcion = null,
   @i_referencia        int         = null,---Secuencial Transaccion
   @i_camara    	char(1)     = null,---'A' ACH - 'S' Swift -  'C' Cenit
   @i_operacion_ach     char(1)     = null,---E - evaluar existencia P prenotificar C cargar
   @o_respuesta         char(1)     = null out
	  
as	
declare 
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_pa_char		catalogo,
   @w_direccion         tinyint,
   @w_respuesta         char(1),
   @w_producto_cuenta   tinyint
	

/* CARGAR VALORES INICIALES */
select @w_sp_name = 'sp_maestro_ach_ext'
   

if @i_categoria_fpago = 'A'
   select  @w_producto_cuenta = 4


if @i_categoria_fpago = 'O'
   select  @w_producto_cuenta = 3

/** PARCHADO HASTA CUANDO SE DECIDA UTILIZAR -- JCQ -- 10/10/2002 **/
/**

begin tran

     exec @w_return = cob_compensacion..sp_maestro_ach
     @s_user            = @s_user,              
     @s_date            = @s_date,              
     @s_ofi             = @s_ofi,  
     @i_producto_cobis  = @i_nom_producto,
     @i_cliente         = @i_cliente,
     @i_valor           = @i_valor,
     @i_codigo_banco    = @i_codigo_banco,
     @i_producto_cuenta = @w_producto_cuenta,
     @i_cuenta          = @i_cuenta,
     @i_des_transaccion = @i_des_transaccion,
     @i_camara          = 'A', 
     @i_operacion       = @i_operacion_ach, 
     @i_referencia      = @i_referencia,
     @o_respuesta       = @w_respuesta out

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end


   select  @o_respuesta = @w_respuesta
   select @o_respuesta

**/

commit tran

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go

