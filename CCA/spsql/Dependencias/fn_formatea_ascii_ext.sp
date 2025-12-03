use cob_conta_super
go
if exists (select 1 from sysobjects where name = 'fn_formatea_ascii_ext')
   drop function [dbo].[fn_formatea_ascii_ext]
go


CREATE FUNCTION [dbo].[fn_formatea_ascii_ext](
   @w_valor_str varchar(255),
   @w_tipo char(2)
)
returns varchar(255)
begin
declare
   @w_cadena   varchar(255),
   @w_cad_ant  varchar(255),
   @w_cont     int

   if @w_valor_str is not null
   begin
      select @w_cont = 1, @w_cadena = ltrim(rtrim(@w_valor_str))
   end

   while len(@w_cadena) >= @w_cont
   begin
      select @w_cad_ant = @w_cadena
      if exists(select eq_valor_cat
                  from cob_conta_super..sb_equivalencias
                 where eq_catalogo  = 'CHAR_ASCII' 
                   and eq_valor_cat = substring(@w_cadena,@w_cont,1)
                   and eq_estado    = 'V')
      begin
         select @w_cadena = replace(@w_cadena, eq_valor_cat, (case @w_tipo when 'A' then eq_valor_arch when 'AN' then eq_descripcion end))
           from cob_conta_super..sb_equivalencias 
          where eq_catalogo = 'CHAR_ASCII' 
            and eq_valor_cat = substring(@w_cadena,@w_cont,1)
            and eq_estado = 'V'
      end
      else
      begin
         select @w_cadena = replace(@w_cadena,substring(@w_cadena,@w_cont,1),'')
      end
      if len(@w_cad_ant) = len(@w_cadena)
      begin
         select @w_cont = @w_cont + 1
      end
   end

   return @w_cadena
end

GO
