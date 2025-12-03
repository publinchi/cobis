use cob_conta_super
go
if exists (select 1 from sysobjects where name = 'fn_formatea_texto')
   drop function [dbo].[fn_formatea_texto]
go

CREATE FUNCTION [dbo].[fn_formatea_texto](  @w_tamanio          int,
                                    @w_valor_string     varchar(255),
                                    @w_valor_int        int,
                                    @w_isright          char(1),
                                    @w_esfija           char(1),
				    @w_conlen           char(1))
returns varchar(255)
begin
    declare @w_cadena    varchar(255),
            @w_tamanio_s varchar(5),
            @w_str_rtrn varchar(255),
            @w_cant_cero int
select @w_cant_cero = 2

    if(@w_valor_string is not null)
    begin
        select @w_cadena    =   upper(@w_valor_string)
    end

    if(@w_valor_int is not null)
    begin
        select @w_cadena    =   convert(varchar(10),@w_valor_int)
    end

    if(@w_cadena is null)
    begin
        select @w_cadena=''
    end


    if(@w_esfija = 'S')
    begin
	
        select @w_tamanio_s = right(replicate('0',@w_cant_cero) + convert(varchar,@w_tamanio),@w_cant_cero)

        if(@w_isright = 'S')
        begin
            select @w_str_rtrn = @w_tamanio_s + @w_cadena + space(@w_tamanio - len(@w_cadena))
        end
        else
        begin
            select @w_str_rtrn = @w_tamanio_s + space(@w_tamanio - len(@w_cadena)) + @w_cadena
        end
    end
    else
    begin
        select @w_tamanio_s = right(replicate('0',@w_cant_cero) + convert(varchar,len(@w_cadena)),@w_cant_cero)
        select @w_str_rtrn = @w_tamanio_s + @w_cadena
    end

    if(@w_conlen = 'N')
    begin
	return substring(@w_str_rtrn,@w_cant_cero + 1,len(@w_str_rtrn))
    end

    return @w_str_rtrn
end

GO
