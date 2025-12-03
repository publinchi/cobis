/* ********************************************************************** */
/*       Archivo:                ca09_pf.sp                               */
/*       Stored procedure:       sp_ca09_pf                               */
/*       Base de datos:          cobis                                    */
/*       Producto:               Cartera                                  */
/*       Disenado por:           Guisela Fernandez                        */
/*       Fecha de escritura:     08/Feb/2022                              */
/* ********************************************************************** */
/*                           IMPORTANTE                                   */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad          */
/*  de COBISCorp.                                                         */
/*  Su uso no autorizado queda expresamente prohibido asi como            */
/*  cualquier alteracion o agregado hecho por alguno de sus               */
/*  usuarios sin el debido consentimiento por escrito de COBISCorp.       */
/*  Este programa esta protegido por la ley de derechos de autor          */
/*  y por las convenciones internacionales de propiedad inte-             */
/*  lectual. Su uso no autorizado dara derecho a COBISCorp para           */
/*  obtener ordenes de secuestro o retencion y para perseguir             */
/*  penalmente a los autores de cualquier infraccion.                     */
/* ********************************************************************** */
/*                               PROPOSITO                                */
/*  Clave de combinación de catálogos de clase de cartrea con grupo       */
/*  contable de garantias para la asignacion de parámetros                */
/* ********************************************************************** */
/*                               MODIFICACIONES                           */
/*  FECHA        AUTOR              RAZON                                 */
/*  08/02/2022   G. Fernandez      Version base                           */
/* ********************************************************************** */
use cobis
go

if exists(select 1 from sysobjects where name = 'sp_ca09_pf')
   drop procedure sp_ca09_pf
go

create procedure sp_ca09_pf(
   @t_trn   int = null
)
as declare
@w_num_clase_cartera          int,
@w_num_grupo_garantia         int,
@w_contador_clase             int,
@w_contador_garantia          int,
@w_cod_clase_cartera          varchar (10),
@w_des_clase_cartera          descripcion,
@w_cod_grupo_garantia         varchar (10),
@w_des_grupo_garantia         descripcion,
@w_cg_codigo                  varchar (10),
@w_cg_descripcion             descripcion

create table ##cartera_grupo_gar_tmp (
 cg_codigo          varchar(10),
 cg_descripcion     descripcion
)

--Catálogo de clase de cartera
SELECT  @w_num_clase_cartera =  count(1)
FROM  cl_tabla t, cl_catalogo c
where c.tabla = t.codigo AND
t.tabla = 'cr_clase_cartera'

set @w_contador_clase = 1

while @w_contador_clase <= @w_num_clase_cartera
begin

	SELECT  @w_cod_clase_cartera = c.codigo,
			@w_des_clase_cartera = c.valor
	FROM  cl_tabla t, cl_catalogo c
	where c.tabla = t.codigo AND
	t.tabla = 'cr_clase_cartera' 
	and c.codigo = convert(char(10),@w_contador_clase)
	
	--Catálogo de grupo de garantias
	SELECT  @w_num_grupo_garantia =  count(1)
    FROM  cl_tabla t, cl_catalogo c
    where c.tabla = t.codigo AND
    t.tabla = 'cr_combinacion_gar'
	
	set @w_contador_garantia = 1
	
	while @w_contador_garantia < @w_num_grupo_garantia
	begin
	
		SELECT  @w_cod_grupo_garantia = c.codigo,
				@w_des_grupo_garantia = c.valor
		FROM  cl_tabla t, cl_catalogo c
		where c.tabla = t.codigo AND
		t.tabla = 'cr_combinacion_gar' 
		and c.codigo = convert(char(10),@w_contador_garantia)
		
		set @w_cg_codigo      = right('0'+rtrim(ltrim(isnull(@w_cod_clase_cartera,''))),2) +'.'+ right('0'+rtrim(ltrim(isnull(@w_cod_grupo_garantia, ''))),2)
		set @w_cg_descripcion = rtrim(ltrim(isnull(@w_des_clase_cartera,''))) +'-'+ rtrim(ltrim(isnull(@w_des_grupo_garantia, '')))
		insert into ##cartera_grupo_gar_tmp values (@w_cg_codigo,@w_cg_descripcion)
	
		set @w_contador_garantia = @w_contador_garantia +1
	end

	set @w_contador_clase = @w_contador_clase +1
end

-- Retorna datos
select   "CODIGO"      = cg_codigo, 
         "DESCRIPCION" = cg_descripcion
from     ##cartera_grupo_gar_tmp

drop table ##cartera_grupo_gar_tmp
return 0
go