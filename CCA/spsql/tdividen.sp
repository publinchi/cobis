/************************************************************************/
/*	Archivo:		tdividen.sp				*/
/*	Stored procedure:	sp_tdividendo				*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Sandra Ortiz				*/
/*	Fecha de escritura:	07/05/1994				*/
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
/*	Este stored procedure procesa todo sobre tipos de dividendos.	*/
/*	I: Insercion de tipos de dividendo				*/
/*	U: Actualizacion de tipos de dividendo				*/
/*	S: Busqueda de tipos de dividendo				*/
/*	H: Ayuda de tipos de dividendo		   			*/
/************************************************************************/
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*      07/26/1994	Peter Espinosa	Emision Inicial			*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tdividendo')
	drop proc sp_tdividendo
go


create proc sp_tdividendo (
@i_operacion	char(2),
@i_tipo		char(1) = null,
@i_modo		tinyint = null,
@i_codigo	catalogo = null,
@i_descripcion	descripcion = null,
@i_estado	estado = null,
@i_factor	smallint = null,
@i_toperacion   catalogo = null
)
as
declare 
@w_sp_name	descripcion,
@w_error	int,
@w_dt_tdividendo   catalogo,
@w_tdividendo      catalogo,
@w_des             varchar(30)


/*  INICIALIZAR VARIABLES  */
select	@w_sp_name = 'sp_tdividendo'


/*  INSERT */
if @i_operacion = 'I' begin
   begin tran
   /* INSERTAR LOS PARAMAETROS INGRESADOS */
   insert into ca_tdividendo 
   (td_tdividendo, td_descripcion, td_estado, td_factor)
   values
   (@i_codigo, @i_descripcion, 'V', @i_factor)
	
   if @@error != 0 begin
      select @w_error = 708168
      goto ERROR
   end
   commit tran
end


/* UPDATE */
if @i_operacion = 'U' begin
   begin tran
   /* MODIFICAR LA INFORMACION  */
   update ca_tdividendo
   set td_descripcion= @i_descripcion,
   td_estado = @i_estado,
   td_factor = @i_factor
   where td_tdividendo = @i_codigo

   if @@error != 0 begin
      select @w_error = 705023
      goto ERROR
   end
   commit tran
end

/* SEARCH */
if @i_operacion = 'S' begin
   set rowcount 20
   /* TRAER LOS VEINTE PRIMEROS */
   if @i_modo = 0 begin
      select
      'Código'            = td_tdividendo,
      'Tipo de dividendo' =substring( td_descripcion,1,30),
      'Valor/Puntos'      = td_factor, 
      'Estado'            = td_estado
      from    ca_tdividendo
      order by td_tdividendo
   end

   /* TRAER LOS VEINTE SIGUIENTES */
   if @i_modo = 1 begin
      select
      'Código'            = td_tdividendo,
      'Tipo de dividendo' =substring( td_descripcion,1,30),
      'Valor/Puntos'      = td_factor,
      'Estado'            = td_estado
      from ca_tdividendo
      where  td_tdividendo > @i_codigo
      order by td_tdividendo
   end
   set rowcount 0
end

/* QUERY */
if @i_operacion = 'Q' begin
   select 'Dias' = td_factor
   from	ca_tdividendo
   where td_tdividendo = @i_codigo
   and td_estado = 'V'
	
   if @@rowcount != 1 begin
      select @w_error = 701083
      goto ERROR
   end
end

/* HELP */
if @i_operacion = 'H' begin
   /* CODIGO Y DESCRIPCION */
   if @i_tipo = 'A' begin
      /* TRAER 20 PRIMEROS */
      set rowcount 20
      if @i_modo = 0
         select 'Codigo' = td_tdividendo,
         'Descripcion'   = td_descripcion,
         'Valor/Puntos'  = td_factor
         from ca_tdividendo
         where td_estado = 'V'
         order by td_tdividendo

      /* TRAER 20 SIGUIENTES */
      if @i_modo = 1
         select 'Codigo' = td_tdividendo,
         'Descripcion'   = td_descripcion,
         'Valor/Puntos'  = td_factor
         from ca_tdividendo
         where   td_estado = 'V'
         and td_tdividendo > @i_codigo
         order by td_tdividendo

      if @i_modo = 3  begin
      
         select @w_dt_tdividendo = dt_tdividendo
         from ca_default_toperacion
         where dt_toperacion = @i_toperacion

         select 'Codigo' = td_tdividendo,
         'Descripcion'   = td_descripcion,
         'Valor/Dias'  = td_factor
         from ca_tdividendo
         where   td_estado = 'V'
         and     td_tdividendo = @w_dt_tdividendo ---'M'
         order by td_tdividendo
      end


      if @i_modo = 4  begin
      
         select @w_dt_tdividendo = dt_tdividendo
         from ca_default_toperacion
         where dt_toperacion = @i_toperacion

         select 
         @w_tdividendo = td_tdividendo,
         @w_des        = td_descripcion
         from ca_tdividendo
         where   td_estado = 'V'
         and td_tdividendo = @w_dt_tdividendo ---'M'

         select 
         '1-PERIODO -'  + @w_tdividendo,
         @w_des 

      end



      set rowcount 0
   end
   else begin
      if @i_tipo = 'V' begin
         select  'Descripcion'= td_descripcion,
         'Valor/Puntos'       = td_factor
         from ca_tdividendo
         where td_estado = 'V'
         and td_tdividendo = @i_codigo

	 if @@rowcount = 0 begin
            select @w_error = 701000
            goto ERROR
         end
      end
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
