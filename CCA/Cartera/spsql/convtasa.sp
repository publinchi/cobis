/************************************************************************/
/*      Archivo:                convtasa.sp                             */
/*      Stored procedure:       sp_conversion_tasas                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Christian De la Cruz 	                */
/*      Fecha de escritura:     Mar. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Conversion de la tasa de interes de una operacion de Cartera    */
/*      entre sus diferentes periodicidades y modalidades, sp externo   */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_conversion_tasas')
	drop proc sp_conversion_tasas
go
create proc sp_conversion_tasas
   @i_dias_anio		smallint,
   @i_periodo_o		char(1) ,
   @i_modalidad_o	char(1) ,
   @i_periodo_d		char(1) ,
   @i_tasa_o		float ,
   @i_modalidad_d	char(1) ,
   @i_num_periodo_o	smallint = 1,
   @i_num_periodo_d	smallint = 1,
   @o_tasa_d            float = null output

as
declare 
@w_sp_name		descripcion,
@w_error		int,
@w_return               int


/* CARGAR VALORES INICIALES */
select @w_sp_name = 'sp_conversion_tasas'

exec @w_return = sp_conversion_tasas_int
@i_dias_anio    = @i_dias_anio,
@i_periodo_o	= @i_periodo_o,
@i_modalidad_o	= @i_modalidad_o,
@i_periodo_d	= @i_periodo_d,
@i_tasa_o	= @i_tasa_o,
@i_modalidad_d	= @i_modalidad_d,
@i_num_periodo_o= @i_num_periodo_o,
@i_num_periodo_d= @i_num_periodo_d,
@o_tasa_d       = @o_tasa_d output

if @w_return != 0 begin         
   select @w_error = @w_return
   goto ERROR                   
end                             


return 0

ERROR:                                    
exec cobis..sp_cerror                     
@t_debug='N',         
@t_file   = null,     
@t_from   = @w_sp_name,   
@i_num    = @w_error
--@i_cuenta = ' '                            
                                          
return @w_error                           
                                          
go

