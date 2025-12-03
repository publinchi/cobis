/************************************************************************/
/*	Archivo:		otrtasas.sp				*/
/*	Stored procedure:	sp_otras_tasas_rubros			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto:               Cobis CARTERA         			*/
/*	Disenado por:           Elcira Pelaez  .       		        */
/*	Fecha de escritura:     Ene. 2003 				*/
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
/*	Este programa procesa las siguientes operaciones de             */
/*      ca_otras_tasas 						        */
/*	I: Insercion de los diferentes Subtipos 		        */
/*	U: Actualizacion del registro de Subtipos de Lineas 		*/
/*	D: Eliminacion del registro de Subtipos de Lineas 	        */
/*	S: Busqueda de los registros de Subtipos de Lineas 		*/
/*	Q: Consulta del registro de Subtipos de Lineas 			*/
/*	H: Ayuda en el registro de Subtipos de Lineas 			*/
/************************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_otras_tasas_rubros')
   drop proc sp_otras_tasas_rubros

go
create proc sp_otras_tasas_rubros (
@t_trn                  int,
@s_date			datetime	= null, 
@s_user			login           = null,
@s_term                 varchar(30)     = null,
@s_org                  char(1)         = null,
@s_ofi                  smallint        = null,
@i_operacion		char(1),
@i_modo			tinyint 	= null,
@i_codigo		char(10)        = null,
@i_valor		float           = null,
@i_descripcion		descripcion	= null,
@i_categoria_rubro		char(1)		= null,
@i_tipo 		char(4)	        = null
)
as
declare 
@w_sp_name		varchar(32),
@w_return		int,
@w_error		int,
@w_codigo               int,
@w_ot_codigo		char(10), 
@w_ot_descripcion	descripcion, 
@w_ot_valor		float, 
@w_ot_categoria_rubro	char(1)


/** INICIALIZACION DE VARIABLES **/
select @w_sp_name = 'sp_otras_tasas_rubros'




/** INSERT **/

if @i_operacion = 'I' begin

   begin tran
   /* VERIFICAR LA NO EXISTENCIA DEL SUBTIPO DE LINEA */
   if exists (select 1 from cob_cartera..ca_otras_tasas
   where ot_codigo  = @i_codigo) begin
      select @w_error = 701176
      goto ERROR
   end
   
   
   /* INSERT A ca_otras_tasas */
   insert into ca_otras_tasas (
	ot_codigo ,
	ot_descripcion,
	ot_valor,      
	ot_categoria_rubro )
   values (@i_codigo,
           @i_descripcion,
           @i_valor,
           @i_categoria_rubro)

   if @@error != 0 begin
      select @w_error = 703121 
      goto ERROR
   end

      ---Transaccion de servicio - Inserción de Otras Tasas
   insert into cob_cartera..ca_otras_tasas_ts (ots_fecha_proceso_ts, ots_fecha_ts, ots_usuario_ts, ots_oficina_ts,	
					       ots_terminal_ts, ots_tipo_transaccion_ts, ots_origen_ts, ots_clase_ts,
					       ots_codigo, ots_descripcion, ots_valor, ots_categoria_rubro
 					      )
                                       values (@s_date, getdate(), @s_user, @s_ofi, 
                                               @s_term, @t_trn, @s_org, 'N', 
                                               @i_codigo, @i_descripcion, @i_valor, @i_categoria_rubro
                                               )
     if @@error != 0
     begin
        exec cobis..sp_cerror
                @t_from         = @w_sp_name,
                @i_num          = 710047
        return 1
     end          


   commit tran

   return 0
end


/** UPDATE **/
if @i_operacion = 'U' begin

   begin tran

   ---Seleccionar los nuevos datos    
       select @w_ot_codigo          = ot_codigo,
	      @w_ot_descripcion     = ot_descripcion,
	      @w_ot_valor           = ot_valor,   
	      @w_ot_categoria_rubro = ot_categoria_rubro
   	 from cob_cartera..ca_otras_tasas
        where ot_codigo = @i_codigo

   /* UPDATE DATOS DEL SUBTIPO DE LINEA DE CREDITO */
   update cob_cartera..ca_otras_tasas set
   ot_codigo         = @i_codigo,
   ot_descripcion    = @i_descripcion,
   ot_valor          = @i_valor,
   ot_categoria_rubro     = @i_categoria_rubro
   where ot_codigo = @i_codigo 
  
   if @@error != 0 begin
      select @w_error = 705077 
      goto ERROR
   end

      ---Transaccion de servicio - Actualizacion de Otras Tasas
   insert into cob_cartera..ca_otras_tasas_ts (ots_fecha_proceso_ts, ots_fecha_ts, ots_usuario_ts, ots_oficina_ts,	
					       ots_terminal_ts, ots_tipo_transaccion_ts, ots_origen_ts, ots_clase_ts,
					       ots_codigo, ots_descripcion, ots_valor, ots_categoria_rubro
 					      )
                                       values (@s_date, getdate(), @s_user, @s_ofi, 
                                               @s_term, @t_trn, @s_org, 'P', 
                                               @w_ot_codigo, @w_ot_descripcion, @w_ot_valor, @w_ot_categoria_rubro
                                               )
     if @@error != 0
     begin
        exec cobis..sp_cerror
                @t_from         = @w_sp_name,
                @i_num          = 710047
        return 1
     end          

      ---Transaccion de servicio - Actualizacion de Otras Tasas
   insert into cob_cartera..ca_otras_tasas_ts (ots_fecha_proceso_ts, ots_fecha_ts, ots_usuario_ts, ots_oficina_ts,	
					       ots_terminal_ts, ots_tipo_transaccion_ts, ots_origen_ts, ots_clase_ts,
					       ots_codigo, ots_descripcion, ots_valor, ots_categoria_rubro
 					      )
                                       values (@s_date, getdate(), @s_user, @s_ofi, 
                                               @s_term, @t_trn, @s_org, 'A', 
                                               @i_codigo, @i_descripcion, @i_valor, @i_categoria_rubro
                                               )
     if @@error != 0
     begin
        exec cobis..sp_cerror
                @t_from         = @w_sp_name,
                @i_num          = 710047
        return 1
     end          

   commit tran
end


/** SEARCH **/
if @i_operacion = 'S' begin
   set rowcount 20
 
   if @i_modo = 0
      select 
      'Codigo '          = ot_codigo,
      'Descripci¢n'      = substring(ot_descripcion,1,64),
      'Valor Tasa'	 = ot_valor,
      'Categoria Rubro'  = ot_categoria_rubro,
      'Descripcion Categoria' = cr_descripcion
      from cob_cartera..ca_otras_tasas,
           cob_cartera..ca_categoria_rubro
      where ot_categoria_rubro = cr_codigo
      order by ot_codigo

      
   if @i_modo = 1
      select
      'Codigo '          = ot_codigo,
      'Descripci¢n'      = substring(ot_descripcion,1,64),
      'Valor Tasa'	 = ot_valor,
      'Categoria Rubro'  = ot_categoria_rubro,
      'Descripcion Categoria' = cr_descripcion
      from cob_cartera..ca_otras_tasas,
           cob_cartera..ca_categoria_rubro
      where ot_categoria_rubro = cr_codigo
      and   ot_codigo > @i_codigo
      order by ot_codigo

   set rowcount 0

end

/** QUERY **/        

if @i_operacion = 'Q' begin

   select  ot_codigo,ot_descripcion,ot_valor,
   ot_categoria_rubro
   from	cob_cartera..ca_otras_tasas
   where ot_codigo  = @i_codigo

   if @@rowcount = 0 begin
      select @w_error = 701177
      goto ERROR
   end

end

if @i_operacion = 'V' begin

      select
      ot_codigo,
      substring(ot_descripcion,1,64),
      ot_valor,
      ot_categoria_rubro
      from
      ca_otras_tasas
      where ot_codigo = @i_codigo

      if @@rowcount = 0 begin
         select @w_error = 701178
         goto ERROR
      end                             
end 


if @i_operacion = 'T' begin

   
select 'Codigo'     =  cv_clase,
       'Descripcion'=  cv_descripcion 
from cob_custodia..cu_clase_vehiculo
      if @@rowcount = 0 begin
         select @w_error = 710244
         goto ERROR
      end            


end 



return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go

