/* ********************************************************************** */
/*       Nombre Fisico:          ca10_pf.sp                               */
/*       Nombre Logico:          sp_ca10_pf                               */
/*       Base de datos:          cob_cartera                              */
/*       Producto:               Cartera                                  */
/*       Disenado por:           Guisela Fernandez                        */
/*       Fecha de escritura:     10/Abr/2023                              */
/* ********************************************************************** */
/*                           IMPORTANTE                                   */
/*	 Este programa es parte de los paquetes bancarios que son       	  */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	  */
/*   representantes exclusivos para comercializar los productos y   	  */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	  */
/*   y regida por las Leyes de la República de España y las         	  */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	  */
/*   alteración en cualquier sentido, ingeniería reversa,           	  */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	  */
/*   de los usuarios o personas que hayan accedido al presente      	  */
/*   sitio, queda expresamente prohibido; sin el debido             	  */
/*   consentimiento por escrito, de parte de los representantes de  	  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	  */
/*   en el presente texto, causará violaciones relacionadas con la  	  */
/*   propiedad intelectual y la confidencialidad de la información  	  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	  */
/*   y penales en contra del infractor según corresponda. 				  */
/* ********************************************************************** */
/*                               PROPOSITO                                */
/*  Clave de combinación de catálogos de clase de cartrea con grupo       */
/*  contable de garantias para la asignacion de parámetros                */
/* ********************************************************************** */
/*                               MODIFICACIONES                           */
/*  FECHA        AUTOR              RAZON                                 */
/*  10/Abr/2023   G. Fernandez      Version base                          */
/*  13/Jul/2023   G. Fernandez      Cambio de tipo dato para clase cartera*/
/* ********************************************************************** */
use cobis
go

if exists(select 1 from sysobjects where name = 'sp_ca10_pf')
   drop procedure sp_ca10_pf
go

create procedure sp_ca10_pf(
   @t_trn   int = null
)
as declare
@w_num_clase_cartera          int,
@w_categoria_plazo            char(1),
@w_contador_clase             int,
@w_cod_clase_cartera          varchar (10),
@w_des_clase_cartera          descripcion,
@w_cod_categoria_plazo        varchar (10),
@w_des_categoria_plazo        descripcion,
@w_cpc_codigo                 varchar (24),
@w_cpc_descripcion            descripcion,
@w_cod_estado                 tinyint,
@w_des_estado                 descripcion,
@w_clase_cartera              varchar (10)

create table #cartera_parametro_contable (
 cpc_codigo          varchar(24),
 cpc_descripcion     descripcion
)

--Catálogo de clase de cartera

select @w_clase_cartera = min(c.codigo)
from  cl_tabla t, cl_catalogo c
where c.tabla = t.codigo and
t.tabla = 'cr_clase_cartera'

while @w_clase_cartera is not null
begin

	select  @w_cod_clase_cartera = c.codigo,
			@w_des_clase_cartera = c.valor
	from  cl_tabla t, cl_catalogo c
	where c.tabla = t.codigo and
	t.tabla = 'cr_clase_cartera' 
	and c.codigo = convert(char(10),@w_clase_cartera)
	
	--Catálogo de grupo de garantias
	select  @w_categoria_plazo =  min(c.codigo)
    from  cl_tabla t, cl_catalogo c
    where c.tabla = t.codigo and
    t.tabla = 'ca_categoria_plazo'
	
	while @w_categoria_plazo is not null
	begin
	
		select  @w_cod_categoria_plazo = c.codigo,
				@w_des_categoria_plazo = c.valor
		from  cl_tabla t, cl_catalogo c
		where c.tabla = t.codigo and
		t.tabla = 'ca_categoria_plazo' 
		and c.codigo = convert(char(10),@w_categoria_plazo)
		
		--Estado de un prestamo
	    select  @w_cod_estado =  min(es_codigo)
        from  cob_cartera..ca_estado
		where es_codigo in (1,2,3,4)
		
		while @w_cod_estado is not null
		begin
		
		   select  @w_des_estado =  es_descripcion
           from  cob_cartera..ca_estado
		   where es_codigo = @w_cod_estado

		   set @w_cpc_codigo      = rtrim(ltrim(@w_cod_clase_cartera)) +'.'+ rtrim(ltrim(@w_cod_categoria_plazo))+'.'+ rtrim(ltrim(@w_cod_estado))+'.'+'E'
		   set @w_cpc_descripcion = rtrim(ltrim(@w_des_clase_cartera)) +'-'+ rtrim(ltrim(@w_des_categoria_plazo))+'-'+ rtrim(ltrim(@w_des_estado))+'-'+'E'
		   insert into #cartera_parametro_contable values (@w_cpc_codigo,@w_cpc_descripcion)
		   
		   set @w_cpc_codigo      = rtrim(ltrim(@w_cod_clase_cartera)) +'.'+ rtrim(ltrim(@w_cod_categoria_plazo))+'.'+ rtrim(ltrim(@w_cod_estado))+'.'+'O'
		   set @w_cpc_descripcion = rtrim(ltrim(@w_des_clase_cartera)) +'-'+ rtrim(ltrim(@w_des_categoria_plazo))+'-'+ rtrim(ltrim(@w_des_estado))+'-'+'O'
		   insert into #cartera_parametro_contable values (@w_cpc_codigo,@w_cpc_descripcion)
		   
		   set @w_cpc_codigo      = rtrim(ltrim(@w_cod_clase_cartera)) +'.'+ rtrim(ltrim(@w_cod_categoria_plazo))+'.'+ rtrim(ltrim(@w_cod_estado))+'.'+'R-F'
		   set @w_cpc_descripcion = rtrim(ltrim(@w_des_clase_cartera)) +'-'+ rtrim(ltrim(@w_des_categoria_plazo))+'-'+ rtrim(ltrim(@w_des_estado))+'-'+'R-F'
		   insert into #cartera_parametro_contable values (@w_cpc_codigo,@w_cpc_descripcion)
		   
		   select  @w_cod_estado =  min(es_codigo)
           from  cob_cartera..ca_estado 
		   where es_codigo in (1,2,3,4)
		   and es_codigo  > @w_cod_estado
		
		end
	
	   select  @w_categoria_plazo =  min(c.codigo)
       from  cl_tabla t, cl_catalogo c
       where c.tabla = t.codigo and
       t.tabla = 'ca_categoria_plazo'
	   and c.codigo > @w_categoria_plazo
	end
	
	select @w_clase_cartera = min(c.codigo)
    from  cl_tabla t, cl_catalogo c
    where c.tabla = t.codigo and
    t.tabla = 'cr_clase_cartera'
	and c.codigo > @w_clase_cartera

end

-- Retorna datos
select   "CODIGO"      = cpc_codigo, 
         "DESCRIPCION" = UPPER(cpc_descripcion)
from     #cartera_parametro_contable

drop table #cartera_parametro_contable
return 0
go