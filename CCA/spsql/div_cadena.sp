/************************************************************************/
/*  Archivo:            div_cadena.sp                                      */
/*  Stored procedure:   sp_division_cadena                              */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:                                                       */
/*  Fecha de escritura:                                                 */
/************************************************************************/
/*                             IMPORTANTE                               */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "Cobiscorp".                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de Cobiscorp o su representante.              */
/************************************************************************/  
/*                              PROPOSITO                               */
/* Este programa divide una cadena de text que concatena valores        */
/************************************************************************/  
/* Julio 2017       S. Rojas            Emision Inicial                 */
/************************************************************************/  

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_division_cadena')
drop proc sp_division_cadena
go


create proc sp_division_cadena
(
@i_cadena           varchar(8000),
@i_delimiter_item   varchar(1)    = '|',
@i_delimiter_string varchar(1)    = ';',
@o_secuencial       int           = 0 output
) 

as

declare 
@w_delimIndex       int,
@w_delimIndex_item  int,
@w_item             varchar(255),
@w_counter          INT,
@w_valor1           VARCHAR(30),
@w_valor2           VARCHAR(30),
@w_secuencial       int,
@w_error            int,
@w_sp_name          varchar(50)


select @w_sp_name = 'sp_division_cadena'

IF OBJECT_ID('tempdb..#cadena') IS NULL
   create table #cadena(
   secuencial int, 
   valor1     varchar(100),
   valor2     varchar(100))


select @w_secuencial = isnull(max(secuencial),0)+1
from #cadena

SELECT @i_cadena = replace(@i_cadena, '[', '')
SELECT @i_cadena = replace(@i_cadena, ']', '')

if @i_cadena = '' or @i_cadena is null
begin
   select @w_error = 70124 --CADENA DE TEXTO ESTÁ VACIA
   goto ERROR
end

select @w_delimIndex = charindex(@i_delimiter_string, @i_cadena, 0)
SELECT @w_counter     = 0

if @w_delimIndex = 0
begin
   select @w_error = 70123 --Caracter no encontrado en la cadena de texto
   goto ERROR
end

while @w_delimIndex != 0
begin 
    IF @w_counter = 0
    select @w_item = SUBSTRING(@i_cadena, 0, @w_delimIndex)
    ELSE
    select @w_item = SUBSTRING(@i_cadena, 0, @w_delimIndex + 1)
	
    SELECT @w_delimIndex_item = charindex(@i_delimiter_item,@w_item, 0)
	
	if @w_delimIndex_item = 0
    begin
       select @w_error = 70123 --Caracter no encontrado en la cadena de texto
       goto ERROR
    end
	
    SELECT @w_valor1 = SUBSTRING(@w_item, 0, @w_delimIndex_item)
    SELECT @w_valor2 = SUBSTRING(@w_item, @w_delimIndex_item + 1, LEN(@w_item) - LEN(@w_valor1))
    
    --Cambiar a estructura definida con Andy
    INSERT INTO #cadena(secuencial, valor1, valor2)
    SELECT @w_secuencial, @w_valor1, @w_valor2
    
    select @i_cadena = SUBSTRING(@i_cadena, @w_delimIndex + 1, LEN(@i_cadena)-@w_delimIndex)
    
    select @w_delimIndex = CHARINDEX(@i_delimiter_string, @i_cadena, 0)
    
    IF @w_delimIndex = 0 AND @w_counter = 0
    begin
        select @w_delimIndex = LEN(@i_cadena)
        SELECT @w_counter = @w_counter + 1
    END
end 

select @o_secuencial = @w_secuencial

RETURN 0


ERROR:

exec cobis..sp_cerror
@t_debug = 'N',    
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error

GO
