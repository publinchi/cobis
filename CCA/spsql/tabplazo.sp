/************************************************************************/
/*	Archivo:		tabplazo.sp				*/
/*	Stored procedure:	sp_tipo_plazo				*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Ramiro Buitron 				*/
/*	Fecha de escritura:	05/06/1999				*/
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
/*	Este stored procedure procesa todo sobre tipos de plazos.	*/
/*	I: Insercion de tipos de plazos  				*/
/*	U: Actualizacion de tipos de plazos				*/
/*	S: Busqueda de tipos de plazos 					*/
/*	H: Ayuda de tipos de plazos		   			*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tipo_plazo')
	drop proc sp_tipo_plazo
go


create proc sp_tipo_plazo (
@i_operacion	char(2),
@i_tipo		char(1) = null,
@i_modo		tinyint = null,
@i_codigo	catalogo = null,
@i_descripcion	descripcion = null,
@i_estado	estado = null,
@i_rango	smallint = null
)
as
declare 
@w_sp_name	descripcion,
@w_error	int


/*  INICIALIZAR VARIABLES  */
select	@w_sp_name = 'sp_tipo_plazo'


/*  INSERT */
if @i_operacion = 'I' begin
   begin tran
   /* INSERTAR LOS PARAMAETROS INGRESADOS */
   insert into ca_tipo_plazo 
   (tp_codigo, tp_descripcion, tp_estado, tp_rango)
   values
   (@i_codigo, @i_descripcion, 'V', @i_rango)
	
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
   update ca_tipo_plazo
   set tp_descripcion= @i_descripcion,
   tp_estado = @i_estado,
   tp_rango = @i_rango
   where tp_codigo = @i_codigo

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
      'Código'        = tp_codigo,
      'Tipo de plazo' =substring( tp_descripcion,1,30),
      'Rango'         = tp_rango, 
      'Estado'        = tp_estado
      from ca_tipo_plazo
      order by tp_codigo
   end

   /* TRAER LOS VEINTE SIGUIENTES */
   if @i_modo = 1 begin
      select
      'Código'        = tp_codigo,
      'Tipo de plazo' = substring( tp_descripcion,1,30),
      'Rango'         = tp_rango,
      'Estado'        = tp_estado
      from ca_tipo_plazo
      where  tp_codigo > @i_codigo
      order by tp_codigo
   end
   set rowcount 0
end

/* QUERY */
if @i_operacion = 'Q' begin
   select 'Dias' = tp_rango
   from	ca_tipo_plazo
   where tp_codigo = @i_codigo
   and tp_estado = 'V'
	
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
         select 
         'Codigo' = tp_codigo,
         'Descripcion'   = tp_descripcion,
         'Rango'         = tp_rango
         from ca_tipo_plazo
         where tp_estado = 'V'
         order by tp_codigo

      /* TRAER 20 SIGUIENTES */
      if @i_modo = 1
         select 'Codigo' = tp_codigo,
         'Descripcion'   = tp_descripcion,
         'Rango'         = tp_rango
         from ca_tipo_plazo
         where tp_estado = 'V'
         and tp_codigo > @i_codigo
         order by tp_codigo

      set rowcount 0
   end
   else begin
      if @i_tipo = 'V' begin
         select 'Descripcion' = tp_descripcion,
         'Rango'              = tp_rango
         from ca_tipo_plazo
         where tp_estado = 'V'
         and tp_codigo = @i_codigo

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
