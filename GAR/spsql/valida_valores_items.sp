/****************************************************************/
/* ARCHIVO:              valida_valores_items.sp                */
/* Stored procedure:	 sp_valida_valores_items	          	*/
/* BASE DE DATOS:        cob_custodia 					        */
/* PRODUCTO:             GARANTIAS              	            */
/****************************************************************/
/*                         IMPORTANTE                           */
/* Esta aplicacion es parte de los paquetes bancarios propiedad */
/* de MACOSA S.A.						                        */
/* Su uso no  autorizado queda  expresamente prohibido asi como */
/* cualquier  alteracion  o agregado  hecho por  alguno  de sus */
/* usuarios sin el debido consentimiento por escrito de MACOSA. */
/* Este programa esta protegido por la ley de derechos de autor */
/* y por las  convenciones  internacionales de  propiedad inte- */
/* lectual.  Su uso no  autorizado dara  derecho a  MACOSA para */
/* obtener  ordenes de  secuestro o retencion y  para perseguir */
/* penalmente a los autores de cualquier infraccion.            */
/****************************************************************/
/*                      MODIFICACIONES                          */
/* FECHA               AUTOR                         RAZON      */
/* 28/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/****************************************************************/


USE cob_custodia
go
IF OBJECT_ID('dbo.sp_valida_valores_items') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_valida_valores_items
    IF OBJECT_ID('dbo.sp_valida_valores_items') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_valida_valores_items >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_valida_valores_items >>>'
END
go
create proc dbo.sp_valida_valores_items
(
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_tipo_cust          descripcion  = null,
   @i_valor_item         descripcion  = null,   
   @i_nombre             descripcion = null,
   @o_error              int = null out, --PSE 02/26/2009, se modifica el tipo de dato de bit a int
   @o_msg                varchar(100) = null out
)
as

declare @w_return             int,          
        @w_msg                varchar(100),
        @w_longitud           int,
        @w_i                  int,  
        @w_error              int,
        @w_valor              varchar(2),
        @w_anio               int

    --REF:LRC ene.28.2008 Inicio
    if @i_tipo_cust in (select b.codigo
                       from cobis..cl_tabla a, cobis..cl_catalogo b
                      where a.tabla = 'ca_tgarantia_soat'
                        and b.tabla = a.codigo
                        and b.codigo = @i_tipo_cust)
    begin
      select @w_error = 0
      if not exists (select 1 
                       from cobis..cl_tabla a, cobis..cl_catalogo b
                      where a.tabla = 'ca_clase_transporte'
                        and b.tabla = a.codigo
                        and b.codigo = @i_valor_item) and @i_nombre = 'TVEHICULO'
      begin
        select @w_msg = 'Valor invalido para item TVEHICULO'
        select @w_error = 1
      end
		--print 'valor item: %1!',@i_valor_item
		--print 'nombre item: %1!',@i_nombre
      if not exists (select 1 
                       from cobis..cl_tabla a, cobis..cl_catalogo b
                      where a.tabla = 'ca_uso_transporte'
                        and b.tabla = a.codigo
                        and b.codigo = @i_valor_item) and @i_nombre = 'USO'
      begin
        select @w_msg = 'Valor invalido para item USO'
        select @w_error = 1
      end
     
      if @i_nombre = 'ANIO' 
      begin
        if LEN(@i_valor_item) != 4 
        begin
           select @w_msg = 'Longitud invalida, para aĂ±o deben ingresarse 4 caracteres'
           select @w_error = 1
        end
      
	select @w_longitud = LEN(@i_valor_item)

	select @w_i = 1
	while @w_i <= @w_longitud
	begin
	  select @w_valor = substring(@i_valor_item, @w_i,1)
	  if @w_valor not in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
	  begin
	     select @w_msg = 'Valor invalido, el aĂ±o debe ser numerico'		--PSE 10/02/2009
	     select @w_error = 1
	     break
	  end
	  select @w_i = @w_i + 1
	end

	select @w_anio =  datepart(yy, getdate())
	if convert(int,@i_valor_item) > @w_anio
	begin
	   if convert(int,@i_valor_item) > @w_anio + 1
	   begin
             select @w_msg = 'El valor ingresado no puede ser mayor a dos aĂ±os'
             select @w_error = 1	     
	   end
	end	
      end	

      if @i_nombre = 'CILINDRAJE' 
      begin      
	select @w_longitud = LEN(@i_valor_item)

	select @w_i = 1
	while @w_i <= @w_longitud
	begin
	  select @w_valor = substring(@i_valor_item, @w_i,1)
	  if @w_valor not in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
	  begin
	     select @w_msg = 'Valor invalido, el cilindraje debe ser numerico'  --PSE 10/02/2009
	     select @w_error = 1
	     break
	  end
	  select @w_i = @w_i + 1
	end
      end	
      
      if @i_nombre = 'CAPACIDAD' 
      begin      
	select @w_longitud = LEN(@i_valor_item)

	select @w_i = 1
	while @w_i <= @w_longitud
	begin
	  select @w_valor = substring(@i_valor_item, @w_i,1)
	  if @w_valor not in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
	  begin
	     select @w_msg = 'Valor invalido, la capacidad debe ser numerico'	--PSE 10/02/2009
	     select @w_error = 1
	     break
	  end
	  select @w_i = @w_i + 1
	end
      end	
	
      if @i_nombre = 'TONELAJE' 
      begin      
	select @w_longitud = LEN(@i_valor_item)

	select @w_i = 1
	while @w_i <= @w_longitud
	begin
	  select @w_valor = substring(@i_valor_item, @w_i,1)
	  if @w_valor not in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.')
	  begin
	     select @w_msg = 'Valor invalido, el tonelaje debe ser numerico'	--PSE 10/02/2009
	     select @w_error = 1
	     break
	  end
	  select @w_i = @w_i + 1
	end
      end	      
    end
    --REF:LRC ene.28.2008 Fin

select @o_error = @w_error
select @o_msg = @w_msg

return 0
go
--EXEC sp_procxmode 'dbo.sp_valida_valores_items', 'unchained'
go
IF OBJECT_ID('dbo.sp_valida_valores_items') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.sp_valida_valores_items >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.sp_valida_valores_items >>>'
go
