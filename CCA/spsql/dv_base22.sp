/************************************************************************/
/*   Archivo:              dv_base22.sp                                 */
/*   Stored procedure:     sp_dv_base22                                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raúl Altamirano Mendez                       */
/*   Fecha de escritura:   Noviembre 2017                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Realiza el calculo de 8 digitos verificadores en base a una referen*/
/*   cia dada                                                           */
/*                              CAMBIOS                                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dv_base22')
   drop proc sp_dv_base22
go

create proc sp_dv_base22(
	@i_input		varchar(32),
	@i_monto        varchar(15) = null,
	@i_fecha        varchar(10) = null,
	@o_output	    varchar(40) out
)
as
declare @w_length 				INT,
		@w_input        		VARCHAR(32),
		@w_count				INT,
		@w_cadena   			VARCHAR(255),
		@w_num_caracteres		int,
		@w_anio_proceso         varchar(4),
		@w_importe_pago         varchar(15),
		@w_fecha_vencimiento    varchar(10),
		@w_dia_vencimiento		varchar(2),
		@w_mes_vencimiento		varchar(2),
		@w_anio_vencimiento		varchar(4),
		@w_factor				varchar(4),
		@w_constante        	int,
		@w_digito_1				INT,
		@w_bandera				INT,
		@w_caracter				int,
		@w_valor				INT,
		@w_suma_calc_importe	INT,
		@w_valid_calc_importe	INT,
		@w_suma_valores_3		INT,
		@w_divisor				INT,
		@w_factor_3				INT,
		@w_dv_1					INT,
		@w_dv_2					INT,
		@w_dv_3					INT,
		@w_dv_3_char			VARCHAR(2)

		
DECLARE  @w_tabla_referencia TABLE (tr_valor		CHAR(1),
								    tr_columna	    int not null)
									
declare @w_tabla_factores table (tf_factor_1		int not null,
								tf_factor_2			int not null,
								tf_factor_3			INT not null,
								tf_factor_4			int not null,
								tf_anio				INT null,
								tf_mes				int null,
								tf_dia				varchar(2) null,
								tf_valido			int  null)
								
declare @w_tabla_importe table (ti_valor			int not NULL, 
								ti_columna			int not null)
								
declare @w_tabla_enteros table (te_valor			int not null,
								te_columna			int not null)
								
declare @w_tabla_calculo_importe table (tci_valor	int,
										tci_columna	int identity not null)
										
declare @w_tabla_valores TABLE (tv_valor		int not null,
						        tv_columna	    int not null)
								
declare @w_tabla_valores_2 TABLE (tv2_valor		int not null,
						          tv2_columna	int not null)

declare @w_tabla_valores_3 TABLE (tv3_valor		int not null,
						          tv3_columna	int not null)
										
declare @w_tabla_busqueda TABLE (tb_columna	    char(1) not null,
								 tb_valor		int not null)
								

select @w_anio_proceso = convert(varchar(4), datepart(year, fp_fecha)) from cobis..ba_fecha_proceso
								
select @w_importe_pago      = isnull(@i_monto, left(right(@i_input,9), 8)),
       @w_fecha_vencimiento = isnull(@i_fecha, substring(@i_input, 15, 6))
	   
   
SELECT @w_count = 1
SELECT @w_input = dbo.LlenarI(@i_input, '0', 32)


print @w_input

select @w_num_caracteres = 40,
	   @w_constante      = 0,
	   @w_divisor		 = 97,
	   @w_factor_3       = 1
	   
select @w_importe_pago = ltrim(rtrim(dbo.LlenarI(substring(@w_importe_pago, 1, len(@w_importe_pago) - 2), '0', 12) + right(@w_importe_pago, 2))),
       @w_fecha_vencimiento = ltrim(rtrim(replace(@w_fecha_vencimiento, '/', '')))

if len(@w_fecha_vencimiento) = 6
   select @w_fecha_vencimiento = substring(@w_fecha_vencimiento, 1, 4) + left(@w_anio_proceso, 2) + right(@w_fecha_vencimiento, 2)
	   
select @w_dia_vencimiento  = substring(@w_fecha_vencimiento, 1, 2), --'02',
       @w_mes_vencimiento  = substring(@w_fecha_vencimiento, 3, 2), --'04',
       @w_anio_vencimiento = substring(@w_fecha_vencimiento, 5, 4)  --'2014'
	   
	   

insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('A',10)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('B',11)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('C',12)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('D',13)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('E',14)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('F',15)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('G',16)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('H',17)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('I',18)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('J',19)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('K',20)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('L',21)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('M',22)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('N',23)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('O',24)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('P',25)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('Q',26)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('R',27)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('S',28)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('T',29)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('U',30)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('V',31)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('W',32)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('X',33)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('Y',34)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('Z',35)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('0',0)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('1',1)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('2',2)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('3',3)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('4',4)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('5',5)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('6',6)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('7',7)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('8',8)
insert into @w_tabla_busqueda(tb_columna, tb_valor) values ('9',9)


set @w_bandera = 1
while @w_bandera <= len(@w_importe_pago)
begin
    select @w_valor = convert(int, substring(@w_importe_pago, @w_bandera, 1))
	insert into @w_tabla_importe (ti_valor, ti_columna) values (@w_valor, @w_bandera)
	select @w_bandera = @w_bandera + 1
end	   


set @w_bandera = @w_num_caracteres
set @w_valor = 17
while @w_bandera >=3
begin
	insert into @w_tabla_valores_2 (tv2_valor, tv2_columna) 
	values (@w_valor, @w_bandera)	
	
	if @w_valor = 11
		select @w_valor = 23
	else if @w_valor = 13
		select @w_valor = 11
	else if @w_valor = 17
		select @w_valor = 13
	else if @w_valor = 19
		select @w_valor = 17
	else if @w_valor = 23
		select @w_valor = 19
	
	select @w_bandera = @w_bandera - 1
end

set @w_bandera = 1
set @w_valor = 3
while @w_bandera <= 14
begin	
	insert into @w_tabla_enteros (te_valor, te_columna)
	values (@w_valor, @w_bandera)
	select @w_bandera = @w_bandera + 1
	if @w_valor = 1
		select @w_valor = 3
	else if @w_valor = 3
		select @w_valor = 7
	else if @w_valor = 7
		select @w_valor = 1
end


insert into @w_tabla_calculo_importe (tci_valor)
select te_valor * ti_valor
  from @w_tabla_enteros, @w_tabla_importe
where te_columna = ti_columna

select @w_bandera = @w_num_caracteres
WHILE @w_count <= LEN(@w_input)
BEGIN 
	SELECT @w_cadena = substring(@w_input, @w_count, 1)
	insert into @w_tabla_referencia (tr_valor, tr_columna) values (@w_cadena, @w_bandera)
	SELECT @w_count = @w_count + 1
	select @w_bandera = @w_bandera - 1
end

insert into @w_tabla_factores(tf_factor_1,tf_factor_2,tf_factor_3,tf_factor_4) values (1,31,2013,372)

update @w_tabla_factores
   set tf_anio = ((convert(int,@w_anio_vencimiento) - tf_factor_3) * tf_factor_4),
       tf_mes  = ((convert(int,@w_mes_vencimiento) - tf_factor_1) * tf_factor_2),
	   tf_dia  = REPLICATE('0', (2 - LEN(convert(VARCHAR,((convert(int,@w_dia_vencimiento) - tf_factor_1)))))) + 
	   		     convert(VARCHAR,((convert(int,@w_dia_vencimiento) - tf_factor_1)))

update @w_tabla_factores
   set tf_valido = tf_anio + tf_mes + tf_dia  
                        
SELECT @w_factor =  convert(VARCHAR,tf_valido) from @w_tabla_factores
select @w_factor = REPLICATE('0', 4 - (SELECT LEN(convert(VARCHAR,@w_factor)))) + @w_factor
select @w_suma_calc_importe = sum(tci_valor)
  FROM @w_tabla_calculo_importe

SELECT @w_valid_calc_importe = @w_suma_calc_importe % 10 

set @w_bandera = 8
SET @w_caracter = 1
WHILE @w_bandera >= 5
begin
	INSERT INTO @w_tabla_referencia (tr_valor,  tr_columna)
    SELECT @w_constante + convert(INT,substring(@w_factor,@w_caracter,1)),
           @w_bandera
           
    select @w_bandera = @w_bandera - 1
    SELECT @w_caracter = @w_caracter + 1

END

INSERT INTO @w_tabla_referencia (tr_valor,  tr_columna)
SELECT @w_valid_calc_importe, 4

INSERT INTO @w_tabla_referencia (tr_valor,  tr_columna)
SELECT 2, 3

set @w_bandera = @w_num_caracteres
while @w_bandera >= 3
begin
	insert into @w_tabla_valores (tv_valor, tv_columna)
	select isnull(tb_valor,0), @w_bandera
      from @w_tabla_busqueda
     where tb_columna = (select tr_valor 
                           from @w_tabla_referencia
					      where tr_columna = @w_bandera)
	select @w_bandera = @w_bandera -1	  
end

set @w_bandera = @w_num_caracteres
while @w_bandera >= 3
begin
	insert @w_tabla_valores_3 (tv3_valor, tv3_columna)
	select tv_valor * tv2_valor, @w_bandera
	  from @w_tabla_valores, @w_tabla_valores_2
	 where tv_columna = tv2_columna
	 AND tv_columna = @w_bandera
	 
	 SELECT @w_bandera = @w_bandera -1
end
	  
SELECT @w_suma_valores_3 = sum(tv3_valor)
  FROM @w_tabla_valores_3
  

SELECT @w_dv_3 = @w_factor_3 + (@w_suma_valores_3 % @w_divisor)

SELECT @w_dv_3_char = REPLICATE('0',(2-len(convert(VARCHAR, @w_dv_3)))) + convert(VARCHAR, @w_dv_3)

SELECT @w_dv_1 = substring(@w_dv_3_char,1,1)
SELECT @w_dv_2 = substring(@w_dv_3_char,2,1)


INSERT INTO @w_tabla_referencia (tr_valor,  tr_columna)
VALUES (@w_dv_1,2)

INSERT INTO @w_tabla_referencia (tr_valor,  tr_columna)
VALUES (@w_dv_2,1)


set @o_output = ''
set @w_bandera = 8
WHILE @w_bandera >= 1
begin
	select @o_output = @o_output + convert(varchar, tr_valor)
	from @w_tabla_referencia
	WHERE tr_columna = @w_bandera
	SELECT @w_bandera = @w_bandera -1
end

select @o_output = @i_input + @o_output

--select * from @w_tabla_calculo_importe
--select * from @w_tabla_factores
--select * from @w_tabla_referencia 
--select * from @w_tabla_valores
--select * from @w_tabla_valores_2
--select * from @w_tabla_valores_3

RETURN 0
go



