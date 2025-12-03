/************************************************************************/
/*	Archivo:		casubtil.sp				*/
/*	Stored procedure:	sp_subtipo_linea			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto:               Cobis CARTERA         			*/
/*	Disenado por:           Xavier Maldonado.       		*/
/*	Fecha de escritura:     Nov. 2000 				*/
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
/*      ca_subtipo_linea						*/
/*	I: Insercion de los diferentes Subtipos 		        */
/*	U: Actualizacion del registro de Subtipos de Lineas 		*/
/*	D: Eliminacion del registro de Subtipos de Lineas 	        */
/*	S: Busqueda de los registros de Subtipos de Lineas 		*/
/*	Q: Consulta del registro de Subtipos de Lineas 			*/
/*	H: Ayuda en el registro de Subtipos de Lineas 			*/
/************************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_subtipo_linea')
   drop proc sp_subtipo_linea

go
create proc sp_subtipo_linea (
@t_trn                  int,
@i_operacion		char(1),
@i_modo			tinyint 	= null,
@i_codigo		char(10)        = null,
@i_codigo_tipo		char(10)        = null,
@i_descripcion		descripcion	= null,
@i_estado		char(1)		= null,
@i_tipo 		char(4)	= null
)
as
declare 
@w_sp_name		varchar(32),
@w_return		int,
@w_error		int,
@w_codigo               int


/** INICIALIZACION DE VARIABLES **/
select @w_sp_name = 'sp_subtipo_linea'


/** INSERT **/

if @i_operacion = 'I' begin

   begin tran
   /* VERIFICAR LA NO EXISTENCIA DEL SUBTIPO DE LINEA */
   if exists (select 1 from cob_cartera..ca_subtipo_linea
   where si_codigo = @i_codigo) begin
      select @w_error = 701176
      goto ERROR
   end
   
   
   /* INSERT A ca_subtipo_linea */
   insert into ca_subtipo_linea (
   si_codigo, si_descripcion,si_tipo_linea,si_estado)
   values (@i_codigo,@i_descripcion,@i_tipo,@i_estado)

   if @@error != 0 begin
      select @w_error = 703121 
      goto ERROR
   end

   commit tran

   return 0
end


/** UPDATE **/
if @i_operacion = 'U' begin

   begin tran

   /* UPDATE DATOS DEL SUBTIPO DE LINEA DE CREDITO */
   update cob_cartera..ca_subtipo_linea set
   si_codigo         = @i_codigo,
   si_descripcion    = @i_descripcion,
   si_tipo_linea     = @i_tipo,
   si_estado	     = @i_estado
   where si_codigo = @i_codigo 
  
   if @@error != 0 begin
      select @w_error = 705077 
      goto ERROR
   end


   commit tran
end


/** SEARCH **/
if @i_operacion = 'S' begin
   set rowcount 20
 
   if @i_modo = 0
      select 
      'Codigo Subtipo'   = si_codigo,
      'Descripci¢n'      = substring(si_descripcion,1,64),
      'Estado'	         = si_estado,
      'Tipo de Linea'   = si_tipo_linea
      from cob_cartera..ca_subtipo_linea
      order by si_codigo
      
   if @i_modo = 1
      select
      'Codigo Subtipo'  = si_codigo,
      'Descripci¢n'      = substring(si_descripcion,1,64),
      'Estado'           = si_estado,
      'Tipo de Linea'   = si_tipo_linea
      from cob_cartera..ca_subtipo_linea
      where si_codigo > @i_codigo
      order by si_codigo

   set rowcount 0

end

/** QUERY **/        

if @i_operacion = 'Q' begin

   select  si_codigo,si_descripcion,si_estado,
   si_tipo_linea
   from	cob_cartera..ca_subtipo_linea
   where si_codigo  = @i_codigo

   if @@rowcount = 0 begin
      select @w_error = 701177
      goto ERROR
   end

end

if @i_operacion = 'V' begin
      select
      si_codigo,
      substring(si_descripcion,1,64),
      si_tipo_linea,
      si_estado
      from
      ca_subtipo_linea
      where si_codigo = @i_codigo

      if @@rowcount = 0 begin
         select @w_error = 701178
         goto ERROR
      end                             
end 


if @i_operacion = 'H' begin
   set rowcount 20

   if @i_modo = 0
      select
      'Codigo Subtipo'  = si_codigo,
      'Descripci¢n'      = substring(si_descripcion,1,64),
      'Estado'           = si_estado,
      'Tipo de Linea'   = si_tipo_linea
      from cob_cartera..ca_subtipo_linea
     where si_tipo_linea = @i_tipo
       and si_estado = 'V'
      order by si_codigo

   if @i_modo = 1
      select
      'Codigo Subtipo'  = si_codigo,
      'Descripci¢n'      = substring(si_descripcion,1,64),
      'Estado'           = si_estado,
      'Tipo de Linea'   = si_tipo_linea
      from cob_cartera..ca_subtipo_linea
      where si_codigo > @i_codigo
        and si_tipo_linea = @i_tipo
        and si_estado = 'V'
      order by si_codigo

   set rowcount 0              
end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go

