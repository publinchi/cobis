/**************************************************************************/
/*   Archivo:             ca_numeros_letras.sp                            */
/*   Stored procedure:    sp_numeros_letras                               */
/*   Base de datos:       cob_cartera                                     */
/*   Producto:            Cartera                                         */
/*   Disenado por:                                                        */
/*   Fecha de escritura:  ENE/2015                                        */
/**************************************************************************/
/*                              IMPORTANTE                                */
/*   Este programa es parte de los paquetes bancarios propiedad de        */
/*   'MACOSA'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como           */
/*   cualquier alteracion o agregado hecho por alguno de sus              */
/*   usuarios sin el debido consentimiento por escrito de la              */
/*   Presidencia Ejecutiva de MACOSA o su representante.                  */
/**************************************************************************/
/*                              PROPOSITO                                 */
/*   Obtiene los datos necesarios para la impresión del Pagaré            */
/*   y solicitud de servicio                                              */
/**************************************************************************/
/*                               MODIFICACIONES                           */
/*  FECHA              AUTOR          CAMBIO                              */
/**************************************************************************/ 

use
cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_numeros_letras')
   drop proc sp_numeros_letras 
go

create proc sp_numeros_letras 
	@s_ssn          int          = null,
    @s_date         datetime     = null,
    @s_user         login        = null,
    @s_term         descripcion  = null,
    @s_corr         char(1)      = null,
    @s_ssn_corr     int          = null,
    @s_ofi          smallint      = null,
    @t_rty          char(1)      = null,
    @t_trn          smallint     = null,
    @t_debug        char(1)      = 'N',
    @t_file         varchar(14)  = null,
    @t_from         varchar(30)  = null,

    @i_dinero	money,
	@i_moneda	smallint,
	@i_idioma	estado,
	@o_texto	varchar(250) = null out

as
declare 
    @w_return   int,
    @w_sp_name  varchar(32),    /* nombre del stored procedure */
	@w_centavos	varchar(6), 
	@w_entero	varchar(30), 
	@w_punto	tinyint,
  	@w_txt		varchar(250), 
	@w_valor	varchar(30), 
	@w_length	tinyint,
  	@w_aux		tinyint, 
	@w_tmp 		varchar(20), 
	@w_numero 	varchar(10), 
	@w_unidad 	varchar(20),
	@w_milesp	varchar(20),
	@w_milotro	varchar(20),
	@w_millonesp	varchar(20),
	@w_millonotro	varchar(20),
	@w_cent 	varchar(50),
	@w_dec 		varchar(50),
	@w_unid		varchar(50),
	@w_cifra_w_aux	tinyint,
	@w_cifras	tinyint,
	@w_bandera 	tinyint,
	@w_desc_moneda	descripcion,
	@w_texto	varchar(255),
        @w_cont_centdec tinyint,
        @w_cont         smallint,
        @w_long_tot     smallint


select @w_sp_name = 'sp_numeros_letras'


if @t_trn <> 29322
begin
  /* Tipo de transaccion no corresponde */
     exec cobis..sp_cerror @t_debug = @t_debug,
                           @t_file  = @t_file,
                           @t_from  = @w_sp_name,
                           @i_num   = 2902500
     return 1
end

/* Consulta de descripciones de monedas en sb_numlet */
/*ESTA PARTE SE COMENTA PUES TODOS LOS CHEQUES YA TIENEN PRE IMPRESO EL NOMBRE DE LA MONEDA*/
/*********************************************************************************************/
if @i_idioma = 'E'	-- Desc. de la moneda en español 
	select  @w_desc_moneda = nl_letras_esp
	from  cob_sbancarios..sb_numlet
	where nl_tipo = 'O'		-- Tipo Moneda
	and nl_numero = @i_moneda	-- Cod. Moneda
else			-- Desc. de la moneda en otro idioma 
	select  @w_desc_moneda = nl_letras_otro
	from  cob_sbancarios..sb_numlet
	where nl_tipo = 'O'		-- Tipo Moneda
	and nl_numero = @i_moneda	-- Cod. Moneda

if @@rowcount <> 1
begin
	-- Codigo de Moneda no Existe  
	exec cobis..sp_cerror
		@t_debug= @t_debug,
		@t_file	= @t_file,
		@t_from	= @w_sp_name,
		@i_num	= 2902608
	return 1
end

/*  Transforma la cantidad en letras  */
select @w_valor = convert(varchar, @i_dinero)
select @w_punto = charindex('.', @w_valor) 
select @w_bandera = 0
select @w_txt = ''
select @w_centavos = substring(@w_valor, @w_punto + 1, datalength(@w_valor) - @w_punto)
select @w_entero = substring(@w_valor, 1, @w_punto - 1)
select @w_length = datalength(@w_entero)
select @w_long_tot = @w_length 
select @w_cont_centdec = 0
select @w_cont   = 0

while @w_length > 0 
begin
	select @w_cent = ''
	select @w_dec = ''
	select @w_unid = ''

	/* billones */
	if ( @w_length in (15, 14, 13) ) 
	begin
	    if @i_idioma = 'E'
		select @w_unidad = ' ' + nl_letras_esp
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'B'
		and nl_numero <> 1

	    if @i_idioma = 'O' or @i_idioma = 'I'
		select @w_unidad = ' ' + nl_letras_otro
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'B'
		and nl_numero <> 1
	end

	/* un billon */
	if ( @w_length = 13 and convert(smallint, substring(@w_entero,1,1)) = 1 ) 
	begin
	    if @i_idioma = 'E'
		select @w_unidad = ' ' + nl_letras_esp
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'B'
		and   nl_numero = 1

	    if @i_idioma = 'O' or @i_idioma = 'I'
		select @w_unidad = ' ' + nl_letras_otro
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'B'
		and   nl_numero = 1
	end

	/* miles */
	if ( @w_length in (18,17,16,12,11,10,6,5,4) ) 
	begin
	    if @i_idioma = 'E'
		select @w_unidad = ' ' + nl_letras_esp
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'M'

	    if @i_idioma = 'O' or @i_idioma = 'I'
		select @w_unidad = ' ' + nl_letras_otro
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'M'
	end

	/* millones */
	if ( @w_length in (9, 8, 7) ) 
	begin
	    if @i_idioma = 'E'
		select @w_unidad = ' ' + nl_letras_esp
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'L'
		and nl_numero <> 1

	    if @i_idioma = 'O' or @i_idioma = 'I'
		select @w_unidad = ' ' + nl_letras_otro
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'L'
		and nl_numero <> 1
	end

	/* un millon */
	if ( @w_length = 7 and convert(smallint, substring(@w_entero,1,1)) = 1 ) 
	begin
	    if @i_idioma = 'E'
		select @w_unidad = ' ' + nl_letras_esp
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'L'
		and   nl_numero = 1

	    if @i_idioma = 'O' or @i_idioma = 'I'
		select @w_unidad = ' ' + nl_letras_otro
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'L'
		and   nl_numero = 1
	end

	/* cientos, decenas y unidades */
	if ( @w_length in (3, 2, 1) ) 
		select @w_unidad = ''

	/*Obtengo hasta los 3 primeros w_numeros del w_entero*/
	select @w_cifras = @w_length % 3
	if @w_cifras = 0 select @w_cifras = 3
	select @w_cifra_w_aux = @w_cifras

	select @w_numero = substring(@w_entero, 1, @w_cifras)	
	if @i_idioma = 'E'
	begin
		select @w_milesp =  ' ' + nl_letras_esp
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'M'

	   	if convert(smallint, @w_numero) = 0 and @w_unidad = @w_milesp
		select @w_unidad = ''
	end
	if @i_idioma = 'O' or @i_idioma = 'I'
	begin
		select @w_milotro =  ' ' + nl_letras_otro
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'M'

	   	if convert(smallint, @w_numero) = 0 and @w_unidad = @w_milotro
		select @w_unidad = ''
	end

	if (@w_length in (12, 11, 10))and convert(smallint, @w_numero) > 0 
		select @w_bandera = 1

	if @i_idioma = 'E'
	begin
		select @w_millonesp = ' ' + nl_letras_esp
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'L'

	       	if convert(smallint, @w_numero) = 0 and @w_unidad = @w_millonesp and  @w_bandera = 0 
		select @w_unidad = ''
	end
	if @i_idioma = 'O' or @i_idioma = 'I'
	begin
		select @w_millonotro = ' ' + nl_letras_otro
		from cob_sbancarios..sb_numlet
		where nl_tipo = 'L'

	       	if convert(smallint, @w_numero) = 0 and @w_unidad = @w_millonotro and  @w_bandera = 0 
		select @w_unidad = ''
	end

	if convert(smallint, @w_numero) <> 0
	begin
		/*Analizo las centenas*/
		if @w_cifras = 3 
        	 begin
		  select @w_aux = convert(tinyint, substring(@w_numero, 1, 1))
		  if @i_idioma = 'E'	
       	    	    if @w_aux = 1 and substring(@w_numero, 2, 1) = '0' and substring(@w_numero, 3, 1) = '0'		   		
        	      select @w_cent = ' CIEN'
		    else
	            begin
			if @w_aux <> 0			
			  select @w_cent = ' ' + nl_letras_esp from cob_sbancarios..sb_numlet
			  where  nl_numero = @w_aux and
		          nl_tipo = 'C'
		   end
	          else
		    if @w_aux <> 0
                      select @w_cent = ' ' + nl_letras_otro from cob_sbancarios..sb_numlet
		      where  nl_numero = @w_aux and
		      nl_tipo = 'C'
		  select @w_numero = substring(@w_numero, 2,2)
        	  select @w_cifras = 2
		 end 

		/*Analizo las decenas*/
		if @w_cifras = 2 
		 begin
		  select @w_aux = convert(tinyint, substring(@w_numero, 1, 1))
		  if @w_aux = 1 
		   begin
    			   if @i_idioma = 'E'	
				select @w_dec = ' ' + nl_letras_esp from cob_sbancarios..sb_numlet
				where  nl_numero = convert(tinyint, @w_numero)
				and    nl_tipo = 'U'
			   if @i_idioma = 'O' or @i_idioma = 'I'
				select @w_dec = ' ' + nl_letras_otro from cob_sbancarios..sb_numlet
				where  nl_numero = convert(tinyint, @w_numero)
				and    nl_tipo = 'U'

			select @w_numero = substring(@w_numero, 2,1)
		        select @w_cifras = 0
		   end
		  else
		   begin	
			if @w_aux <> 0 
			  begin
	    			   if @i_idioma = 'E'	
				   begin	
 					select @w_dec = ' ' + nl_letras_esp from cob_sbancarios..sb_numlet
					where  nl_numero = @w_aux
					and	nl_tipo = 'D'
					if substring(@w_numero, 2, 1) <> '0'
			   begin 
				   if @w_aux = 2
				   begin
				      select @w_dec = SUBSTRING(@w_dec, 1, LEN(@w_dec) - 1)
				      select @w_dec = @w_dec + 'I' 
				      select @w_numero = substring(@w_numero, 2,1)
		              select @w_cifras = 2
		              select @w_aux = convert(tinyint, @w_numero)
		              if @i_idioma = 'E'	
						select @w_unid = nl_letras_esp from cob_sbancarios..sb_numlet
						where  nl_numero = @w_aux
						and nl_tipo = 'U'
				   end
				   else
				      select @w_dec = @w_dec + ' Y' 
				end
				   end
				   if @i_idioma = 'O' or @i_idioma = 'I'
 					select @w_dec = ' ' + nl_letras_otro from cob_sbancarios..sb_numlet
					where  nl_numero = @w_aux
					and	nl_tipo = 'D'
			  end
			select @w_numero = substring(@w_numero, 2,1)
		        select @w_cifras = 1
		   end
		 end 

		/*Analizo las unidades*/
		if @w_cifras = 1 
		 begin
		  select @w_aux = convert(tinyint, @w_numero)
		  if @w_aux <> 0 
    	 	     if @i_idioma = 'E'	
			  select @w_unid = ' ' + nl_letras_esp from cob_sbancarios..sb_numlet
		          where  nl_numero = @w_aux
			  and nl_tipo = 'U'
    	 	     if @i_idioma = 'O'	or @i_idioma = 'I'
			  select @w_unid = ' ' + nl_letras_otro from cob_sbancarios..sb_numlet
		          where  nl_numero = @w_aux
			  and nl_tipo = 'U'
		 end 
	end	

                if (@w_cent <> '' or @w_dec <> ''or  @w_unid <> '') and @w_cont > 0
                    select @w_cont_centdec = @w_cont_centdec + 1

		select @w_txt = @w_txt +  @w_cent +  @w_dec +  @w_unid + @w_unidad
		select @w_entero = substring(@w_entero, @w_cifra_w_aux + 1, datalength(@w_entero)- @w_cifra_w_aux)
		select @w_length = datalength(@w_entero)
                select @w_cont = @w_cont + 1
end 


/*select @w_texto = '   '+ rtrim(ltrim(@w_txt)) + ' ' + rtrim(ltrim(@w_centavos)) + '/100************' */


if @i_idioma = 'E'
begin
    if @w_cont_centdec = 0 and @w_long_tot > 6
       select @w_txt = @w_txt + ' DE '

    select @w_texto = rtrim(ltrim(@w_txt)) + ' ' + rtrim(ltrim(@w_desc_moneda)) --+ ' CON ' + rtrim(ltrim(@w_centavos)) + '/100 '
    -- + rtrim(ltrim(@w_desc_moneda))
end
else
select @w_texto = rtrim(ltrim(@w_txt)) + ' ' + rtrim(ltrim(@w_desc_moneda)) --+ ' AND ' + rtrim(ltrim(@w_centavos)) + '/100******' 
--+  rtrim(ltrim(@w_desc_moneda))
  

--retornar a frontend el string del monto en letras

select @o_texto = @w_texto   

return 0


