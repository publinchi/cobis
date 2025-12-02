/************************************************************************/
/*	Archivo:		tasaval.sp				*/
/*	Stored procedure:	sp_tasa_valor 				*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cobis CARTERA         			*/
/*	Disenado por:  Christian De la Cruz.				*/
/*	Fecha de escritura: 07-ABR-1998					*/
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
/*	Este programa procesa las siguientes operaciones de             */
/*      ca_valor_referencial						*/
/*	I: Creacion de la Tasa  					*/
/*	U: Actualizacion del registro de Tasas Referenciales		*/
/*	D: Eliminacion del registro de Tasas Referenciales		*/
/*	S: Busqueda del registro de Tasas Referenciales			*/
/*	Q: Consulta del registro de Tasas Referenciales			*/
/*	H: Ayuda en el registro de Tasas Referenciales			*/
/************************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_tasa_valor')
   drop proc sp_tasa_valor

go
create proc sp_tasa_valor (
@i_operacion		char(2),
@i_modo			tinyint 	= null,
@i_tipo			char(1) 	= null,
@i_nombre_tasa		catalogo	= null,
@i_descripcion		descripcion	= null,
@i_modalidad		char(1)		= null,
@i_tipo_tasa		char(1)		= null,
@i_periodicidad		char(1)		= null,
@i_estado		char(1)		= null
)
as
declare 
@w_sp_name		varchar(32),
@w_return		int,
@w_error		int,
@w_codigo               int


/** INICIALIZACION DE VARIABLES **/
select @w_sp_name = 'sp_tasa_valor'


/** INSERT **/

if @i_operacion = 'I' begin

   begin tran
   /* VERIFICAR LA NO EXISTENCIA DE LA TASA */
   if exists (select 1 from cob_cartera..ca_tasa_valor
   where tv_nombre_tasa = @i_nombre_tasa) begin
      select @w_error = 701176
      goto ERROR
   end
   



   
   /* INSERT A ca_tasa_valor */
   insert into ca_tasa_valor (
   tv_nombre_tasa,tv_descripcion,tv_modalidad,tv_periodicidad,
   tv_estado,tv_tipo_tasa)
   values (@i_nombre_tasa,@i_descripcion,@i_modalidad,@i_periodicidad,
   @i_estado,@i_tipo_tasa)

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

   /* UPDATE DATOS DE LA TASA */
   update   cob_cartera..ca_tasa_valor set
   tv_descripcion    = @i_descripcion,
   tv_modalidad      = @i_modalidad,
   tv_tipo_tasa      = @i_tipo_tasa,
   tv_periodicidad   = @i_periodicidad,
   tv_estado	     = @i_estado
   where tv_nombre_tasa = @i_nombre_tasa 
  

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
      'Codigo Tasa'  = tv_nombre_tasa,
      'Descripcion'  = substring(tv_descripcion,1,64),
      'Tipo Tasa'    = tv_tipo_tasa,
      'Modalidad'    = tv_modalidad,
      'Periodicidad' = td_descripcion,
      'Estado'	     = y.valor--tv_estado
      from  
      cob_cartera..ca_tasa_valor,
      cob_cartera..ca_tdividendo,
      cobis..cl_tabla x,
      cobis..cl_catalogo y
      where tv_periodicidad = td_tdividendo  
      and x.tabla  = 'cl_estado_ser'
      and x.codigo = y.tabla
      and y.codigo = tv_estado
      order by tv_nombre_tasa
      
   if @i_modo = 1
      select 
      'Codigo Tasa'  = tv_nombre_tasa,
      'Descripcion'  = substring(tv_descripcion,1,64),
      'Tipo Tasa'    = tv_tipo_tasa,
      'Modalidad'    = tv_modalidad,                      
      'Periodicidad' = td_descripcion, --tv_periodicidad,
      'Estado'	     = y.valor --tv_estado
      from   cob_cartera..ca_tasa_valor,
      cob_cartera..ca_tdividendo,
      cobis..cl_tabla x,
      cobis..cl_catalogo y
      where tv_nombre_tasa  > @i_nombre_tasa
      and tv_periodicidad = td_tdividendo
      and x.tabla  = 'cl_estado_ser'
      and x.codigo = y.tabla
      and y.codigo = tv_estado
      order by tv_nombre_tasa

   set rowcount 0

end

/** QUERY **/        

if @i_operacion = 'Q' begin

   select  tv_descripcion,tv_nombre_tasa,
   tv_periodicidad,tv_modalidad
   from	cob_cartera..ca_tasa_valor
   where   tv_nombre_tasa  = @i_nombre_tasa

   if @@rowcount = 0 begin
      select @w_error = 701177
      goto ERROR
   end

end

/** HELP **/

if @i_operacion = 'H' begin
   /** CONSULTA DE LAS TASAS **/ 
   if @i_tipo = 'A' begin
      set rowcount 20
      if @i_modo = 0
         select 
         'Codigo Tasa'  = tv_nombre_tasa,
  	     'Descripcion'  = substring(tv_descripcion,1,64),
         'Tipo Tasa'    = tv_tipo_tasa,
         'Modalidad'    = tv_modalidad,
         'Periodicidad' = tv_periodicidad,
         'Desc. Period.'= td_descripcion
         from
         ca_tasa_valor,
         ca_tdividendo
         where tv_periodicidad = td_tdividendo
         and   tv_estado = 'V'
	 order by tv_nombre_tasa
        
      if @i_modo = 1
       	 select
         'Codigo Tasa'  = tv_nombre_tasa,
  	     'Descripcion'  = substring(tv_descripcion,1,64),
         'Tipo Tasa'    = tv_tipo_tasa,
         'Modalidad'    = tv_modalidad,
         'Periodicidad' = tv_periodicidad,
         'Desc. Period.'= td_descripcion
         from	
         ca_tasa_valor,
         ca_tdividendo
	 where tv_nombre_tasa > @i_nombre_tasa
         and   tv_periodicidad = td_tdividendo
         and   tv_estado = 'V'
	 order by tv_nombre_tasa
        
     set rowcount 0 
     return 0
   end

   if @i_tipo = 'V' begin
      select
      substring(tv_descripcion,1,64), 
      tv_tipo_tasa,
      tv_modalidad,
      tv_periodicidad,
      td_descripcion
      from
      ca_tasa_valor,
      ca_tdividendo
      where tv_nombre_tasa = @i_nombre_tasa
      and tv_estado = 'V'
      and tv_periodicidad  = td_tdividendo

      if @@rowcount = 0 begin
         select @w_error = 701178 
         goto ERROR
      end
   end
end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',
@t_file = null,
@t_from =@w_sp_name,
@i_num = @w_error
--@i_cuenta= ' '

return @w_error

go

