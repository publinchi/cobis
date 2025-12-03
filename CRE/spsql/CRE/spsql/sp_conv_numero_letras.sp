/************************************************************************/
/*  Archivo:                conv_numero_letras.sp                       */
/*  Stored procedure:       sp_conv_numero_letras                       */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  CONVERTIR A LETRAS DIFERENTES FORMATOS DE INFORMACION               */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/*  28/12/22          BDU              Agregar opcion 5 y 6             */
/*  24/10/23          BDU              Coreccion Ortografía             */
/*  10/07/24          DMO              R240096:Se corrige para que tome */
/*                                     más de dos decimales             */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_conv_numero_letras')
    drop proc sp_conv_numero_letras
go

create proc sp_conv_numero_letras (                                                                                                                                                                                    
        @t_trn              smallint     = null,                                                                                                                                                                      
        @t_debug            char(1)      = 'N',                                                                                                                                                                        
        @t_file             varchar(14)  = null,                                                                                                                                                                
        @t_from             varchar(30)  = null,                                                                                                                                                                
        @i_dinero           money        = null,                                                                                                                                                                             
        @i_moneda           tinyint      = null,
        @i_fecha            varchar(10)  = null,        
        -- @i_mdesc         char(1) = 'S', /* S - Incluir Descripcion de la moneda */                                                                                    
        @i_opcion           tinyint = 0, /* 0 con descr. moneda */                                                                                                       
                            /* 1 sin unidades */                                                                                                                                            
                            /* 2 con descr. dias */                                                                                                                                                        
        @o_letras           varchar(255) out                                                                                                                                                               
) as                                                                                                                                                                                                              
declare
        @w_sp_name          varchar(30),                                                                                                                                                                              
        @centavos           varchar(6),                                                                                       
        @entero             varchar(30),                                                                                                                                                                             
        @indice             tinyint,                                                                                                                                                                                  
        @txt                varchar(250),                                                                                                                                                                           
        @valor              varchar(30),                                                                                                                                                                            
        @w_nconv            varchar(30),                                                                                                                                                                             
        @length             tinyint,                                                                                                                                                                                 
        @ceros              tinyint,                                                                                                                                                                                     
        @w_pos              tinyint,                                                                                                                                                                                     
        @tmp                varchar(30),                                                                                                                                                                             
        @numero             tinyint,
        @unidad             varchar(30),
        @w_desc_unidades    descripcion,
        @w_unidades         varchar(255),
        @w_unidades1        varchar(255),
        @w_decenas          varchar(255),
        @w_centenas         varchar(255),
        @w_dolar            tinyint,
        @num1               int,
        @num2               int,
		@num1_str           varchar(255),
		@num2_str           varchar(255),
		@w_ceros_prefix     varchar(255),
		@w_resto_numero     int,
		@num2_length        int,
		@w_index            int,
        @aux                varchar(50)

  /*  Captura nombre del Stored Procedure  */
  select @w_sp_name = 'sp_conv_numero_letras'
/*** Inicializar unidades, decenas, centenas ***/
select @w_unidades = '@0@1UN@2DOS@3TRES@4CUATRO@5CINCO@6SEIS@7SIETE@8OCHO'
select @w_unidades = @w_unidades + '@9NUEVE@10DIEZ@11ONCE@12DOCE@13TRECE' 
select @w_unidades = @w_unidades + '@14CATORCE@15QUINCE@16DIECISEIS@17DIECISIETE'
select @w_unidades = @w_unidades + '@18DIECIOCHO@19DIECINUEVE@'
select @w_unidades1 = '@20VEINTE@21VEINTIUNO@22VEINTIDOS@23VEINTITRES'
select @w_unidades1 = @w_unidades1 + '@24VEINTICUATRO@25VEINTICINCO@26VEINTISEIS'
select @w_unidades1 = @w_unidades1 + '@27VEINTISIETE@28VEINTIOCHO@29VEINTINUEVE@'
select @w_decenas = '@1DIEZ@2VEINTE@3TREINTA@4CUARENTA@5CINCUENTA'
select @w_decenas = @w_decenas + '@6SESENTA@7SETENTA@8OCHENTA@9NOVENTA@'
select @w_centenas = '@1CIENTO@2DOSCIENTOS@3TRESCIENTOS@4CUATROCIENTOS'
select @w_centenas = @w_centenas + '@5QUINIENTOS@6SEISCIENTOS@7SETECIENTOS'
select @w_centenas = @w_centenas + '@8OCHOCIENTOS@9NOVECIENTOS@'
/*  Transforma la cantidad en letras  */
select @valor = convert(varchar, @i_dinero)
select @indice = charindex('.', @valor) + 1
select @centavos = substring(@valor, @indice, datalength(@valor)-@indice+1)
select @entero = substring(@valor, 1, @indice - 2)
select @length = datalength(@entero)
select @indice = 1
select @txt = ''
if(@i_opcion < 5)
begin
   while ( @indice <= @length )
   begin
           select @numero = convert(tinyint, substring(@entero, @indice, 1))
           select @ceros = @length - @indice
           if ( @ceros + 1 in (15, 14, 13) )
           begin
               if (@ceros+1) = 13 and @numero = 1  
                   select @unidad = ' BILLON'
               else
                   select @unidad = ' BILLONES'
           end
           else
               if ( @ceros + 1 in (18,17,16,12,11,10,6,5,4) ) 
               select @unidad = ' MIL'
               else
                   if ( @ceros + 1 in (9, 8, 7) )
                   begin
                       if (@ceros+1) = @length and (@ceros+1) = 7 and @numero = 1
                           select @unidad = ' MILLON'
                       else
                           select @unidad = ' MILLONES'
                   end
                   else
                       if ( @ceros + 1 in (3, 2, 1) )
                       begin
                     if (@ceros+1) = 1 and @numero = 1
                               select @unidad = ' UNO'
                           else
                               select @unidad = ''
                       end
       if @numero <> 0
           begin
               if ( @ceros in (17, 14, 11, 8, 5, 2) )
               begin
                   /*** TRANSFORMAR A LETRAS LAS CENTENAS ***/
                   select @w_pos= charindex(('@'+convert(varchar,@numero)),@w_centenas)
                        + datalength(@numero)
                   --DGO if @w_pos > 0 select @w_nconv = stuff(@w_centenas,1,@w_pos,null)
                   if @w_pos > 0 
                       select @w_nconv = substring(@w_centenas,@w_pos+1,
                                             len(@w_centenas))
                   select @w_pos = charindex('@',@w_nconv) - 1
                   if @w_pos > 0 
                   select @w_nconv = substring(@w_nconv,1,@w_pos)
                   if @numero = 1 and substring(@entero,@indice+1,2) = '00'
                   begin
                           select @w_pos = charindex('TO',@w_nconv)
                           --select @w_nconv = stuff(@w_nconv,@w_pos,@w_pos+1,null)
                           select @w_nconv = substring(@w_nconv,1,@w_pos-1) +
                                                     substring(@w_nconv,@w_pos+2,
                                                 len(@w_nconv))
                   end
                   if substring(@entero,@indice+1,2) <> '00'
                         select @unidad = ''
                   if @ceros in (8) and substring(@entero,@indice+1,2) = '00'
                               select @unidad = ''
                       select @tmp = @w_nconv
               end
               if ( @ceros in (16, 13, 10, 7, 4, 1) )
               begin
               -- print '@w_decenas %1! @numero %2!', @w_decenas, @numero
                   if ( @numero in (0, 1,2) )
                   begin
                   -- print '@w_decenas %1! @numero %2!', @w_decenas, @numero
                   select @numero = convert(tinyint, substring(@entero, @indice, 2))
                       /*** TRANSFORMAR A LETRAS LAS UNIDADES ***/
                   -- print '@numero %1!', @numero
                   if @numero >= 20 and @numero <= 29
                   begin
                           select @w_pos = charindex(('@'+convert(varchar(2),@numero)),@w_unidades1)
                                     + datalength(@numero)+1 
                           if @w_pos > 0 
                                   --select @w_nconv = stuff(@w_unidades1,1,@w_pos,null)
                                   select @w_nconv = substring(@w_unidades1,@w_pos+1,
                                                      len(@w_unidades1))
                           select @w_pos = charindex('@',@w_nconv) - 1
                           if @w_pos > 0 
                           select @w_nconv = substring(@w_nconv,1,@w_pos)
                           select @tmp = @w_nconv 
                       select @indice = @indice + 1
                   end
                   else
                   begin
                           select @w_pos = charindex(('@'+convert(varchar(2),@numero)),@w_unidades)
                                     + datalength(@numero)+1 
                           if @w_pos > 0 
                                   --select @w_nconv = stuff(@w_unidades,1,@w_pos,null)
                                   select @w_nconv = substring(@w_unidades,@w_pos+1,
                                                      len(@w_unidades))
                           select @w_pos = charindex('@',@w_nconv) - 1
                           if @w_pos > 0 
                           select @w_nconv = substring(@w_nconv,1,@w_pos)
                           select @tmp = @w_nconv 
                       select @indice = @indice + 1
                   end
               end
                   else
                   begin
                       /*** TRANSFORMAR A LETRAS LAS DECENAS ***/
                       select @w_pos= charindex(('@'+convert(varchar(2),@numero)),@w_decenas)
                            + datalength(@numero)
                       --DGO if @w_pos > 0 select @w_nconv = stuff(@w_decenas,1,@w_pos,null)
           if @w_pos > 0 
                               select @w_nconv = substring(@w_decenas,@w_pos+1,
                                                 len(@w_decenas))
                       select @w_pos = charindex('@',@w_nconv) - 1
                       if @w_pos > 0 
         select @w_nconv = substring(@w_nconv,1,@w_pos)
                       select @tmp = @w_nconv
                   if ( substring(@entero, @indice + 1, 1) <> '0' )
                           select @tmp = @tmp + ' Y',
                                  @unidad = ''
                       if @ceros in (8,7) and substring(@entero,@indice,1) <> '1'
                               select @unidad = ''
                      print '@w_nconv ' + @w_nconv
               END
               END
               if ( @ceros in (18,15,12,9, 6,3,0) )
               begin
                   /*** TRANSFORMAR A LETRAS LAS UNIDADES ***/
                   select @w_pos= charindex(('@'+convert(varchar,@numero)),@w_unidades)
                        + datalength(@numero)
                   --DGO if @w_pos > 0 select @w_nconv = stuff(@w_unidades,1,@w_pos,null)
                   if @w_pos > 0 
                       select @w_nconv = substring(@w_unidades,@w_pos+1, 
                                             len(@w_unidades))
                   select @w_pos = charindex('@',@w_nconv) - 1
     if @w_pos > 0 
                   select @w_nconv = substring(@w_nconv,1,@w_pos)
                   if @ceros = 0 and @numero = 1
                       select @w_nconv = '' 
               /* consideracion para el caso de que el numero sea 1.000 */
               /*if @ceros = 3 and @numero = 1
                   select @tmp = ''
               else*/
                   select @tmp = @w_nconv
               end
               select @tmp = @tmp + @unidad
           end
       else
               if @ceros in (6)
                   select @tmp = @tmp + @unidad
           if @tmp IS NOT null 
              select @txt = @txt + ' ' + rtrim(ltrim(@tmp))
           select @tmp = '',
                  @unidad = ''
           select @indice = @indice + 1
   end
end
if @i_opcion = 0
begin
  /*  Determina Moneda  */
  select  @w_desc_unidades = mo_descripcion
    from  cobis..cl_moneda
   where  mo_moneda = @i_moneda
   if @@rowcount <> 1
   begin
    /*  Codigo de Moneda no Existe  */
    exec cobis..sp_cerror
        @t_debug= @t_debug,
        @t_file   = @t_file,
        @t_from   = @w_sp_name,
        @i_num    = 701069
    return 1
   end
   if (select(substring(ltrim(rtrim(@w_desc_unidades)),
  len(ltrim(rtrim(@w_desc_unidades))), 1)))
  in ('A','E','I','O','U')
  select @w_desc_unidades = (@w_desc_unidades + 'S')
   else
  if (select(substring(ltrim(rtrim(@w_desc_unidades)),
      len(ltrim(rtrim(@w_desc_unidades)))-1, 2)))
      in ('AS','ES','IS','OS','US')
     select @w_desc_unidades = @w_desc_unidades
  else
     select @w_desc_unidades = (@w_desc_unidades + 'ES')
  select  @w_desc_unidades = ' ' + @centavos + '/100 ' +
          rtrim(@w_desc_unidades)
end
else
if @i_opcion = 1
  begin
    -- select @w_desc_unidades = ''
    select  @w_desc_unidades = ' ' + @centavos + '/100 ' 
  end
else
if @i_opcion = 2
  begin
    select @w_desc_unidades = ' DIAS'
  end
if @i_opcion = 3
  begin
    select @w_desc_unidades = ' '
  end
else
if @i_opcion = 4
  begin
     SELECT @w_dolar = pa_tinyint 
     FROM cobis.dbo.cl_parametro cp 
     where pa_nemonico = 'CDOLAR' 
     and pa_producto = 'CRE'
    /*  Determina Moneda  */
    select  @w_desc_unidades = mo_descripcion
      from  cobis..cl_moneda
     where  mo_moneda = @i_moneda
     if @@rowcount <> 1
     begin
      /*  Codigo de Moneda no Existe  */
      exec cobis..sp_cerror
          @t_debug= @t_debug,
          @t_file   = @t_file,
          @t_from   = @w_sp_name,
          @i_num = 701069
      return 1
     end
     if (select(substring(ltrim(rtrim(@w_desc_unidades)),
    len(ltrim(rtrim(@w_desc_unidades))), 1)))
    in ('A','E','I','O','U')
    select @w_desc_unidades 
     else
    if (select(substring(ltrim(rtrim(@w_desc_unidades)),
        len(ltrim(rtrim(@w_desc_unidades)))-1, 2)))
        in ('AS','ES','IS','OS','US')
       select @w_desc_unidades = @w_desc_unidades
    else
       select @w_desc_unidades = (@w_desc_unidades + 'ES')
    if @w_dolar = @i_moneda
       select  @w_desc_unidades = '' + rtrim(@w_desc_unidades) + ' DE LOS ESTADOS UNIDOS DE AMÉRICA '+ @centavos + '/100 ' 
    ELSE
       select  @w_desc_unidades = ' ' + rtrim(@w_desc_unidades) + ' '+ @centavos + '/100 ' 
  end
  if(@i_opcion < 5)
  begin
     select  @o_letras = ltrim(@txt) + @w_desc_unidades
     select  @o_letras =  UPPER(LEFT(@o_letras, 1)) + UPPER(SUBSTRING(@o_letras, 2, LEN(@o_letras)))
  end
if(@i_opcion = 5) --Porcentaje a letras
begin

   SET @num1_str = LEFT(@i_dinero, ISNULL(NULLIF(CHARINDEX('.', @i_dinero) - 1, -1), LEN(@i_dinero)))
   SET @num2_str = RIGHT(@i_dinero, LEN(@i_dinero) - CHARINDEX('.', @i_dinero))
   
   -- Inicializar @o_letras
   select @o_letras = ''
   
   -- Convertir parte entera a letras
   if (@num1_str = '0')
   begin
      select @o_letras = 'CERO'
   end
   else if (@num1_str = '1')
   begin
      select @o_letras = 'UNO'
   end
   else if (CAST(@num1_str AS INT) > 1)
   begin
      exec cob_credito..sp_conv_numero_letras
           @t_trn   = 9490,
           @i_opcion  = 3,
           @i_dinero  = @num1_str,
           @i_moneda  = 1,
           @o_letras  = @aux out
      select @o_letras = @aux
   end
   
   -- Añadir "punto"
   select @o_letras = @o_letras + ' punto '
   
   -- Convertir parte decimal a letras, preservando ceros a la izquierda
   SET @num2_length = LEN(@num2_str)
   set @w_index = 1
   set @w_ceros_prefix  = ''
   WHILE @w_index <= @num2_length AND SUBSTRING(@num2_str, @w_index, 1) = '0'
   BEGIN
      SET @w_ceros_prefix = @w_ceros_prefix + 'CERO '
      SET @w_index = @w_index + 1
   END
   

   IF @w_index <= @num2_length
   begin
      SET @w_resto_numero = SUBSTRING(@num2_str, @w_index, @num2_length - @w_index + 1)
	  
	  if (@w_resto_numero = '0')
      begin
         select @aux = 'CERO'
      end
      else if (@w_resto_numero = '1')
      begin
         select @aux = 'UNO'
      end
      else if (CAST(@w_resto_numero AS INT) > 1)
      begin
         exec cob_credito..sp_conv_numero_letras
              @t_trn   = 9490,
              @i_opcion  = 3,
              @i_dinero  = @w_resto_numero,
              @i_moneda  = 1,
              @o_letras  = @aux out
      end
	  
      set @o_letras = @o_letras + @w_ceros_prefix + @aux
   END
   ELSE
   BEGIN
      set @o_letras = @o_letras + @w_ceros_prefix
   END
end
if(@i_opcion = 6) --Fecha a letras
begin
   SET LANGUAGE Spanish
   SELECT @o_letras = DATENAME(dw, @i_fecha) + ', ' 
                    + DATENAME(day, @i_fecha) + ' de '
                    + DATENAME(month, @i_fecha) + ' de ' + DATENAME(year, @i_fecha) 
   select  @o_letras =  LOWER(@o_letras)
end
if(@i_opcion = 7) --Fecha a letras sin dia
begin
   SET LANGUAGE Spanish
   SELECT @o_letras = DATENAME(day, @i_fecha) + ' de '
                    + DATENAME(month, @i_fecha) + ' de ' + DATENAME(year, @i_fecha) 
   select  @o_letras =  LOWER(@o_letras)
end
GO
