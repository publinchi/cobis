use cob_pac

go

if object_id('sp_rules_evaluation_condition') is not null
begin
  drop procedure sp_rules_evaluation_condition
  if object_id('sp_rules_evaluation_condition') is not null
    print 'FAILED DROPPING PROCEDURE sp_rules_evaluation_condition'
end

go

CREATE PROCEDURE sp_rules_evaluation_condition
(

/*******************************************************************/
/*   ARCHIVO:         rules_evaluation_condition.sp                */
/*   NOMBRE LOGICO:   sp_rules_evaluation_condition                */
/*   PRODUCTO:        REE                                          */
/*******************************************************************/
/*   IMPORTANTE                                                    */
/*   Esta aplicacion es parte de los  paquetes bancarios           */
/*   propiedad de MACOSA S.A.                                      */
/*   Su uso no autorizado queda  expresamente  prohibido           */
/*   asi como cualquier alteracion o agregado hecho  por           */
/*   alguno de sus usuarios sin el debido consentimiento           */
/*   por escrito de MACOSA.                                        */
/*   Este programa esta protegido por la ley de derechos           */
/*   de autor y por las convenciones  internacionales de           */
/*   propiedad intelectual.  Su uso  no  autorizado dara           */
/*   derecho a MACOSA para obtener ordenes  de secuestro           */
/*   o  retencion  y  para  perseguir  penalmente a  los           */
/*   autores de cualquier infraccion.                              */
/*******************************************************************/
/*                          PROPOSITO                              */
/*  Permite evaluar las condiciones con los siguientes operadores  */
/*  between, >, >=, <>, <, <=, =                                   */
/*******************************************************************/
/*                     MODIFICACIONES                              */
/*   FECHA        AUTOR              RAZON                         */
/*   15/Nov/2011  Francisco Schnabel Emision Inicial               */
/*******************************************************************/
    @i_operator       varchar(15)  = null,
    @i_min_value      varchar(255) = null,
    @i_max_value      varchar(255) = null,
    @i_real_value     varchar(255) = null,
    @i_data_type      varchar(15)  = null,
    @o_return_value   bit          = 0 out      
)
as
begin
    DECLARE @w_valmin         numeric(20,8),
            @w_valmax         numeric(20,8),
            @w_valreal        numeric(20,8),
            @w_retorno        bit
    
    select @w_retorno = 0
    
    if (@i_data_type != 'numeric' and @i_data_type != 'INT' and @i_data_type != 'FLT') and
       (@i_data_type != 'varchar' and @i_data_type != 'CHR' and @i_data_type != 'VCH')
	begin
		return 3107566
	end
		

     if (@i_operator = 'ISNULL' and (@i_real_value is null or @i_real_value = ''))
            begin
                 select @o_return_value = 1
                return 0
            end

            if (@i_operator = 'ANYVALUE')
            begin
                 select @o_return_value = 1
                 return 0
            end
		
    if (@i_data_type = 'numeric' or @i_data_type = 'INT' or @i_data_type = 'FLT')
    begin
		if (@i_real_value is not null and @i_real_value <> '')
		begin
			
           
			
			/*select @i_min_value = case when @i_min_value is null or @i_min_value = '' then '0' else @i_min_value end*/
			if @i_min_value is null or @i_min_value = ''
			begin
				select @i_min_value = '0'
			end
			
			select @w_valmin = convert(float,@i_min_value)
			select @w_valmax = convert(float,@i_max_value)
			select @w_valreal = convert(float,@i_real_value)
        
		
			if (@i_operator = 'BETWEEN' and (@w_valreal between @w_valmin and @w_valmax))
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '>' and @w_valreal > @w_valmax)
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '>=' and @w_valreal >= @w_valmax)
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '<>' and @w_valreal <> @w_valmax)
			begin
				select @w_retorno = 1
			end
			
			
			if (@i_operator = '<' and @w_valreal < @w_valmax)
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '<=' and @w_valreal <= @w_valmax)
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '=' and @w_valreal = @w_valmax)
			begin
				select @w_retorno = 1
			end
		end
		

    end

    if (@i_data_type = 'varchar' or @i_data_type = 'CHR' or @i_data_type = 'VCH')
    begin

		if (@i_operator = 'ISNULL' and (@i_real_value is null or @i_real_value = ''))
        begin
            select @w_retorno = 1
        end
		
		if (@i_operator = 'ANYVALUE')
        begin
            select @w_retorno = 1
        end
		if (@i_real_value is not null and @i_real_value <> '')
		begin
			if (@i_operator = 'BETWEEN' and (@i_real_value between @i_min_value and @i_max_value))
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '>' and @i_real_value > @i_max_value)
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '>=' and @i_real_value >= @i_max_value)
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '<>' and @i_real_value <> @i_max_value)
			begin
				select @w_retorno = 1
			end
			
			
			if (@i_operator = '<' and @i_real_value < @i_max_value)
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '<=' and @i_real_value <= @i_max_value)
			begin
				select @w_retorno = 1
			end
			
			if (@i_operator = '=' and @i_real_value = @i_max_value)
			begin
				select @w_retorno = 1
			end
		end
		
    end
    select @o_return_value = @w_retorno
    return 0
end
go
