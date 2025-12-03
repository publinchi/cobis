/*************************************************************************/
/*   ARCHIVO:            validar_catalogo.sp                             */
/*   NOMBRE LOGICO:      sp_validar_catalogo                             */
/*   Base de datos:      cob_conta_super                                 */
/*   PRODUCTO:           REC                                             */
/*   Fecha de escritura: May 2020                                        */
/*************************************************************************/
/*                           IMPORTANTE                                  */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante legal.            */
/*************************************************************************/
/*                           PROPOSITO                                   */
/*  Valida la existenda de un dato en los catalogos.                     */
/*************************************************************************/
/*                        MODIFICADO POR                                 */
/*  07/07/2020     FSAP      Estandarizacion de clientes                 */
/*  15/10/20       MBA       Uso de la variable @s_culture               */ 
/*************************************************************************/

use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go


if exists (select * from sysobjects where name = 'sp_validar_catalogo')
   drop proc sp_validar_catalogo
go
create procedure sp_validar_catalogo(
@s_culture       varchar(10)  = 'NEUTRAL',
@i_tabla         varchar(100),
@i_valor         varchar(100) = null,
@t_show_version  bit  = 0     -- mostrar la version del programa
)

as

declare
@w_error     int,
@w_tabla     int,
@w_catalogo  varchar(100),
@w_sp_name   descripcion,
@w_sp_msg    varchar(132)

/* INICIAR VARIABLES DE TRABAJO  */
select 
@w_sp_name           = 'sp_validar_catalogo',
@w_sp_msg            = ''
            
/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
		

if isnull(@i_valor,'') = '' return 0  --los valores nulos se ignoran

if @i_tabla = 'cl_actividad_ec' begin
   if not exists(select 1 from cobis..cl_actividad_ec where ac_codigo = @i_valor) goto ERROR_FIN
   return 0
end

if @i_tabla = 'cl_pais' begin
   if not exists(select 1 from cobis..cl_pais where pa_pais = @i_valor) goto ERROR_FIN
   return 0
end

if @i_tabla = 'cc_oficial' begin
   if not exists(select 1 from cc_oficial where oc_oficial = convert(int,@i_valor)) goto ERROR_FIN
   return 0
end



-- SI NO ENTRO EN NINGUNA DE LAS TABLAS ANTERIORES, ENTONCES ES UN CATALOGO

select @w_tabla = codigo 
from cobis..cl_tabla 
where tabla = @i_tabla

if @@rowcount <> 1 begin
   select @w_error = 1720018
   goto ERROR_FIN
end

if not exists (select 1
from 	cobis..cl_catalogo
where codigo = @i_valor
and   tabla  = @w_tabla)
begin
   goto ERROR_FIN
end

return 0

ERROR_FIN:

if @w_error is null begin

   select 
   @w_error    = 1720018,
   @w_catalogo = '%'+upper(@i_tabla)+'%'
   
   select @w_error = numero
   from cl_errores
   where upper(mensaje) like @w_catalogo
   and   upper(mensaje) like '%CATALOGO%'
   and   upper(mensaje) like '%NO EXISTE%'

   if @i_tabla = 'cl_nivel_egresos'     select @w_error = 1720373
   if @i_tabla = 'cl_ingresos'          select @w_error = 1720374
   if @i_tabla = 'cl_referencia_tiempo' select @w_error = 1720375
   if @i_tabla = 'cl_fuente_ingreso'    select @w_error = 1720296
   if @i_tabla = 'cl_categoria_AML'     select @w_error = 1720377
   if @i_tabla = 'cl_provincia'         select @w_error = 1720378
   if @i_tabla = 'cl_discapacidad'      select @w_error = 1720020
   if @i_tabla = 'cl_tcifras'           select @w_error = 1720490
   if @i_tabla = 'cl_posicion'          select @w_error = 1720489
   if @i_tabla = 'cl_sexo'              select @w_error = 1720025
   if @i_tabla = 'cl_profesion'         select @w_error = 1720026
   if @i_tabla = 'cl_pais'              select @w_error = 1720027
   if @i_tabla = 'cl_ciudad'            select @w_error = 1720028   
   if @i_tabla = 'cl_nivel_estudio'     select @w_error = 1720029
   if @i_tabla = 'cl_tipo_vivienda'     select @w_error = 1720030
   if @i_tabla = 'cl_relacion_banco'    select @w_error = 1720037
   if @i_tabla = 'cl_profesion'         select @w_error = 1720041   
   if @i_tabla = 'cl_sector_economico'  select @w_error = 1720042
   if @i_tabla = 'cc_oficial'           select @w_error = 1720051
   if @i_tabla = 'cl_ecivil'            select @w_error = 1720057
   if @i_tabla = 'cl_ptipo'             select @w_error = 1720058
   if @i_tabla = 'cl_actividad_ec'      select @w_error = 1720059
   if @i_tabla = 'cl_promotor'          select @w_error = 1720060
   if @i_tabla = 'cl_tip_soc'           select @w_error = 1720137
   if @i_tabla = 'cl_genero'            select @w_error = 1720380   
   if @i_tabla = 'cl_nivel_cuenta'      select @w_error = 1720381
   if @i_tabla = 'cl_num_trn_mes_n1'    select @w_error = 1720382
   if @i_tabla = 'cl_mto_trn_mes_n1'    select @w_error = 1720383
   if @i_tabla = 'cl_sdo_prom_mes_n1'   select @w_error = 1720384
   if @i_tabla = 'cl_num_trn_mes_n2'    select @w_error = 1720385
   if @i_tabla = 'cl_mto_trn_mes_n2'    select @w_error = 1720386
   if @i_tabla = 'cl_sdo_prom_mes_n2'   select @w_error = 1720387
   if @i_tabla = 'cl_num_trn_mes_n3'    select @w_error = 1720388
   if @i_tabla = 'cl_mto_trn_mes_n3'    select @w_error = 1720389
   if @i_tabla = 'cl_sdo_prom_mes_n3'   select @w_error = 1720390
   if @i_tabla = 'cl_gpo_matriz_riesgo' select @w_error = 1720391
   
   

end

return @w_error

go

/*  ejemplo de ejecucion

declare @w_error int

exec @w_error = sp_validar_catalogo 'cl_pais','11'

select @w_error

select * from cobis..cl_errores where upper(mensaje) like '%CATALOGO%'

*/