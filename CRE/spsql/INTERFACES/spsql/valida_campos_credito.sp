/************************************************************************/
/*  Archivo:                valida_campos_credito.sp                    */
/*  Stored procedure:       sp_valida_campos_credito                    */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Mieles                                 */
/*  Fecha de Documentacion: 31/08/2021                                  */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_interface               */ 
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  31/08/2021       jmieles        Emision Inicial                     */
/*  24/03/2022       pmoreno        Validacion fecha proceso,ciudad     */
/*  29/06/2022       bduenas        Se agrega nuevo campo @i_pplazo     */
/*  19/07/2022       bduenas        Se corrige validacion del oficial   */
/*  14/08/2023     D. Morales       Se cambia catalogo cc_sector a      */
/*                                  cl_sector_neg                       */
/* **********************************************************************/

use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_valida_campos_credito')
   drop procedure sp_valida_campos_credito
go


CREATE proc sp_valida_campos_credito 
            @s_ssn                     int              = null,
            @s_user                    login            = null,
            @s_sesn                    int              = null,
            @s_term                    descripcion      = null,
            @s_date                    datetime         = null,
            @s_srv                     varchar(30)      = null,
            @s_lsrv                    varchar(30)      = null,
            @s_rol                     smallint         = null,
            @s_ofi                     smallint         = null,
            @s_org_err                 char(1)          = null,
            @s_error                   int              = null,
            @s_sev                     tinyint          = null,
            @s_msg                     descripcion      = null,
            @s_org                     char(1)          = null,
            @t_rty                     char(1)          = null,
            @t_trn                     int              = null,
            @t_debug                   char(1)          = 'N',
            @t_file                    varchar(14)      = null,
            @t_from                    varchar(30)      = null,
            @t_show_version            bit              = 0,      
            @s_culture                 varchar(10)      = 'NEUTRAL',
            @i_oficina                 smallint         = null,--
            @i_linea_credito           cuenta           = null,--
            @i_sector                  catalogo         = null,--
            @i_destino_financiero      varchar(25)      = null,
            @i_destino_econimico       varchar(25)      = null,
            @i_origen_fondos           varchar(255)     = null,--
            @i_oficial                 smallint         = null,--
            @i_moneda                  tinyint          = null,--
            @i_enterado                catalogo         = null,--
            @i_provincia               int              = null,--
            @i_ciudad                  int              = null,--
            @i_deudor                  int              = null,--
            @i_fecha_inicio            datetime         = null,--
            @i_pplazo                  smallint         = null,--
            @i_tplazo                  catalogo         = null,--
            @i_toperacion              catalogo         = null,
            @i_canal                   tinyint          = 0,
            @i_ciudad_destino          int              = null,
            @i_fecha_crea              datetime         = null
         
as
declare
         @w_error                  int,                          
         @w_sp_name                varchar(32),
         @w_msg                    varchar(255),
         @w_fecha                  datetime,
         @w_fecha_calc             datetime,
         @w_factor                 smallint

select @w_sp_name = 'sp_valida_campos_credito'

select @w_error = 0

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_oficina')and codigo = @i_oficina)
begin
   select
      @w_error = 2110151
        --@w_msg    = 'No existe Oficina.'
        goto SALIR
end   

if not exists( select 1 from  cobis..cc_oficial where oc_oficial = @i_oficial)
begin
   select
      @w_error = 2110144
        --@w_msg    = 'No existe Oficial.'
        goto SALIR
end   

if not exists(select 1
                from cobis..cl_funcionario, cobis..cc_oficial, cobis..ad_usuario
               where fu_funcionario = oc_funcionario
                 and oc_oficial = @i_oficial
                 and us_oficina = @i_oficina
                 and us_login = fu_login)
begin
   select
      @w_error = 2110145
       -- @w_msg    = 'El Oficial no pertenece a la Oficina.'
        goto SALIR
end   

 if (@i_linea_credito is not null and @i_linea_credito <> '')
 begin
   select @w_factor = td_factor from cob_cartera..ca_tdividendo where td_tdividendo = @i_tplazo
   select @w_fecha_calc = dateadd(day, @i_pplazo * @w_factor, @i_fecha_inicio)
   if not exists( select  1
        from  cob_credito..cr_linea
        where li_num_banco = @i_linea_credito
      and li_estado = 'V'
      and li_fecha_vto >= @w_fecha_calc)
   begin
      select
         @w_error = 2110140
         --@w_msg    = 'La línea de Crédito no existe o no está vigente o la fecha no está en el rango.'
         goto SALIR
   end
   
end   

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_sector_neg')and codigo = @i_sector) 
begin
   select
      @w_error = 2110126
        --@w_msg    = 'Codigo de sector no existe.'
        goto SALIR
end   

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cr_origen_fondo')and codigo = @i_origen_fondos)
begin
   select
      @w_error = 2110143
        --@w_msg    = 'Origen de Fondos no existe.'
      goto SALIR
end   

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_moneda')and codigo = @i_moneda)
begin
   select
      @w_error = 2110155
        --@w_msg    = 'Moneda no existe.'
        goto SALIR
end   

if not exists( select 1 from   cob_cartera..ca_default_toperacion where dt_toperacion = @i_toperacion and dt_moneda = @i_moneda)
begin
   select
      @w_error = 2110147
        --@w_msg    = 'La moneda no está parametrizada para el tipo de producto.'
        goto SALIR
end   

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_enterado')and codigo = @i_enterado)
begin
   select
      @w_error = 2110148
        --@w_msg    = 'No existe el como se enteró.'
        goto SALIR
end   

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_provincia')and codigo = @i_provincia)
begin
   select
      @w_error = 2110149
        --@w_msg    = 'No existe Provincia.'
        goto SALIR
end   

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_ciudad')and codigo = @i_ciudad)
begin
   select
      @w_error = 2110150
        --@w_msg    = 'No existe Ciudad.'
        goto SALIR
end   

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_ciudad')and codigo = @i_ciudad_destino)
begin
   select
      @w_error = 2110150
        --@w_msg    = 'No existe Ciudad Destino.'
        goto SALIR
end   

if not exists( select 1 from cobis..cl_ciudad where ci_ciudad = @i_ciudad and ci_provincia = @i_provincia)
begin
   select
      @w_error = 2110150
        --@w_msg    = 'No existe ciudad asociada a la provincia.'
        goto SALIR
end   

-- Fecha
select @w_fecha = fp_fecha
from   cobis..ba_fecha_proceso

if @i_fecha_inicio = null
begin
   select @i_fecha_inicio = @w_fecha
end

if (@i_fecha_inicio  < @w_fecha) or (@i_fecha_crea < @w_fecha)
begin
   select @w_error = 708142
   --@w_msg    = Fecha Incorrecta.Debe ser Mayor o Igual a la Fecha de Proceso.
    goto SALIR
end

if not exists( select 1 from cobis..cl_ente where en_ente = @i_deudor)
begin
   select
      @w_error = 2110172
        --@w_msg    = 'No existe el deudor.'
        goto SALIR
end   

--cr_plazo_ind      
if not exists( select 1 from cob_cartera..ca_tdividendo where td_tdividendo = @i_tplazo)  
begin
   select
      @w_error = 2110146
        --@w_msg    = 'EL Plazo no existe.'
        goto SALIR
end   

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cr_objeto')and codigo = @i_destino_financiero)
begin
   select
      @w_error = 2110141
        --@w_msg    = 'No existe el destino financiero.'
        goto SALIR
end   

if not exists(select 1 from   cobis..cl_subactividad_ec where  se_estado =    'V' and    se_codigo =  @i_destino_econimico)
begin
   select
      @w_error = 2110142
        --@w_msg    = 'No existe el destino economico.'
        goto SALIR
end   


SALIR:
   print 'SALIO'     
   return @w_error


ERROR:
   --Devolver mensaje de Error
print 'ENTRO ERROR dd: ' + @w_msg
   if @i_canal in (0,1) --Frontend o batch
     begin
      exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
       @i_msg   = @w_msg,
         @i_num   = @w_error
      return @w_error
     end
    else
      return @w_error
go
