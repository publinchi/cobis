USE cob_credito
GO
/************************************************************/
/*   ARCHIVO:         sp_valida_garantia.sp                 */
/*   NOMBRE LOGICO:   sp_valida_garantia                    */
/*   PRODUCTO:        COBIS                                 */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*Validar los datos ingresados para creación de garantías   */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/* 03/SEP/2021     EBA                 Emision Inicial      */
/************************************************************/

if exists (select 1 from sysobjects where name = 'sp_valida_garantia')
   drop proc sp_valida_garantia
go

CREATE PROCEDURE sp_valida_garantia (
		@t_show_version         bit          = 0,
		@t_debug                char(1)      = 'N',
        @t_file                 varchar(14)  = null,
		@t_from                 varchar(30)  = null,
        @i_oficina              smallint     = null,
        @i_tipo                 varchar(64)  = null,
        @i_valor_inicial        money        = null,
        @i_moneda               tinyint      = null,
		@i_abierta_cerrada      char(1)      = null,
		@i_fecha_avaluo         DATETIME     = NULL,
		@i_fecha_const          datetime     = null,
		@i_nemonico_cob         catalogo     = null,
        @i_suficiencia_legal    CHAR(1)      = NULL,
		@i_adecuada_noadec      char(1)      = null,
		@i_cobranza_judicial    char(1)      = null,
		@i_fondo_garantia       VARCHAR(2)   = NULL,
		@i_inspeccionar         char(1)      = null,
		@i_motivo_noinsp        catalogo     = null,
		@i_periodicidad         catalogo     = null,
		@i_pais                 int          = NULL,
		@i_almacenera           smallint     = null
)
as
declare @w_sp_name              varchar(32),
        @w_error                int,
		@w_return               int,
		@w_fecha                datetime,
		@w_tipo_gar             varchar(30)


select @w_sp_name = 'sp_valida_garantia',
       @w_error = 0

select @w_tipo_gar = pa_char
from cobis..cl_parametro
where pa_nemonico = 'GARGPE'
and pa_producto = 'GAR'


--EJECUCION DE VALIDACIONES DE CAMPOS
--***********************************

--Validacion Oficina
IF NOT EXISTS (select 1 from cobis..cl_oficina where of_oficina = @i_oficina) 
begin
    select @w_error = 2110151
    goto ERROR
end


--Validacion de tipo de garantia
if not exists (select 1 from cob_custodia..cu_tipo_custodia
               where tc_tipo = @i_tipo)
begin
	select @w_error = 2110153
    goto ERROR
end

--Validacion del valor inicial
if (@i_tipo <> @w_tipo_gar and @i_valor_inicial = 0)
begin
	select @w_error = 2110154
    goto ERROR
end

--Validacion de moneda
if (@i_tipo <> @w_tipo_gar)
begin
	if not exists (select 1 from cobis..cl_moneda
                   where mo_moneda = @i_moneda)
	begin
		select @w_error = 2110155
		goto ERROR
    end
end

--Validacion de tipo de cobertura
if not exists(select 1 from cobis..cl_catalogo
              where tabla in (select codigo from cobis..cl_tabla where tabla = 'cu_cobertura')
                and codigo = @i_nemonico_cob)
begin
	select @w_error = 2110156
	goto ERROR
end

--Validacion fecha avaluo y fecha constitucion
select @w_fecha   = fp_fecha
from cobis..ba_fecha_proceso
if (@i_fecha_avaluo > @w_fecha or @i_fecha_const > @w_fecha)
begin
	select @w_error = 2110157
	goto ERROR
end

--Validacion de clase
if (@i_abierta_cerrada not in ('A', 'C'))
begin
	select @w_error = 2110158
	goto ERROR
end

--Validacion suficiencia legal
if (@i_suficiencia_legal not in ('S', 'N', 'O'))
begin
	select @w_error = 2110159
	goto ERROR
end

--Validacion adecuada
if (@i_adecuada_noadec not in ('S', 'N', 'O'))
begin
	select @w_error = 2110160
	goto ERROR
end


--Validacion cobranza judicial
if (@i_cobranza_judicial not in ('S', 'N'))
begin
	select @w_error = 2110161
	goto ERROR
end

--Validacion fondo garantia
if (@i_fondo_garantia not in ('S', 'N'))
begin
	select @w_error = 2110162
	goto ERROR
end

--Validacion inspeccionar
if (@i_inspeccionar not in ('S', 'N'))
begin
	select @w_error = 2110163
	goto ERROR
end

if (@i_inspeccionar = 'N')
begin
	if(@i_motivo_noinsp is null)
	begin
		select @w_error = 2110164
		goto ERROR
	end
	else if not exists(select 1 from cobis..cl_catalogo
                       where tabla in (select codigo from cobis..cl_tabla where tabla = 'cu_motivo_noinspeccion')
                         and codigo = @i_motivo_noinsp)
	begin
		select @w_error = 2110165
		goto ERROR
	end
end


if (@i_inspeccionar = 'S')
begin
	if(@i_periodicidad is null)
	begin
		select @w_error = 2110166
		goto ERROR
	end
	else if not exists(select 1 from cobis..cl_catalogo
                       where tabla in (select codigo from cobis..cl_tabla where tabla = 'cu_des_periodicidad')
                         and codigo = @i_periodicidad)
	begin
		select @w_error = 2110167
		goto ERROR
	end
end


--Validacion almacenera
if not exists(select 1 from cob_custodia..cu_almacenera
              where al_almacenera = @i_almacenera)
begin
	select @w_error = 2110168
	goto ERROR
end


return 0

ERROR:    --Rutina que dispara sp_cerror dado el codigo de error
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return @w_error
GO

