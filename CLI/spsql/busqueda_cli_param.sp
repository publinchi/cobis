/************************************************************/
/*   ARCHIVO:         sp_busqueda_cli_param.sp              */
/*   NOMBRE LOGICO:   sp_busqueda_cli_param                 */
/*   PRODUCTO:        COBIS COMMONS CORE                    */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de COBIS.                                    */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de COBIS.                                  */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a COBIS  para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*   Descripcion de un parametro COBIS.                     */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA        AUTOR               RAZON                 */
/*   29/01/2019   DFL       Emision Inicial                 */
/*   29/07/20     MBA       Estandarizacion sp y seguridades*/
/************************************************************/

use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO


if exists (select * 
             from sysobjects
            where type = 'P'
              and name = 'sp_busqueda_cli_param')
  drop proc sp_busqueda_cli_param
go

create procedure sp_busqueda_cli_param
(
  @s_ssn                int,
  @s_user               varchar(30),
  @s_sesn               int,
  @s_term               varchar(30),
  @s_date               datetime,
  @s_srv                varchar(30),
  @s_lsrv               varchar(30),
  @s_ofi                smallint,
  @t_trn                int,
  @t_debug              char(1)     = 'N',
  @t_file               varchar(14) = null,
  @t_from               varchar(30) = null,
  @s_culture            varchar(10) = null,
  @s_rol                smallint    = null,
  @s_org_err            char(1)     = null,
  @s_error              int         = null,
  @s_sev                tinyint     = null,
  @s_msg                descripcion = null,
  @s_org                char(1)     = null,
  @t_rty                char(1)     = null,
  @t_show_version       bit         = 0,
  @i_parametro          char(6),
  @i_producto           char(3),
  @i_operacion          char(1)     = 'Q',
  @o_tipo               char(1)     = null out,
  @o_int                int         = null out,
  @o_tinyint            tinyint     = null out,
  @o_smallint           smallint    = null out,
  @o_datetime           datetime    = null out,
  @o_money              money       = null out,
  @o_float              float       = null out,
  @o_char               varchar(30) = null out,
  @o_varchar            varchar(30) = null out
)
As declare
  @w_sp_name varchar(64),
  @w_sp_msg  varchar(132)

/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_busqueda_cli_param'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/ 


if not exists (select 1 from cobis..cl_parametro
                where pa_nemonico = @i_parametro
                  and pa_producto = @i_producto)
begin -- No existe tal parametro.
  exec cobis..sp_cerror
       @t_from  = @w_sp_name,
       @i_num   = 1729000
  return 1
end

-- VALIDACION DE TRANSACCIONES
if (@t_trn <> 172902)
begin
   exec sp_cerror
    @t_debug  = @t_debug,
    @t_file   = @t_file,
    @t_from   = @w_sp_name,
    @i_num    = 1720075                  
    --NO CORRESPONDE CODIGO DE TRANSACCION
   return 1720075
end

if @i_operacion = 'Q'
begin
   select @o_tipo     = pa_tipo,
          @o_int      = pa_int,
          @o_tinyint  = pa_tinyint,
          @o_smallint = pa_smallint,
          @o_char     = pa_char,
          @o_varchar  = pa_char,
          @o_float    = pa_float,
          @o_money    = pa_money,
          @o_datetime = pa_datetime
     from cobis..cl_parametro
    where pa_nemonico = @i_parametro
      and pa_producto = @i_producto
end

set rowcount 0
return 0

go
