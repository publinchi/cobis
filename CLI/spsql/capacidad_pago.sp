/********************************************************************/
/*   NOMBRE LOGICO:         sp_capacidad_pago                       */
/*   NOMBRE FISICO:         capacidad_pago.sp                       */
/*   BASE DE DATOS:         cobis                                   */
/*   PRODUCTO:              Cliente                                 */
/*   DISENADO POR:          P. Jarrin.                              */
/*   FECHA DE ESCRITURA:    05-May-2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Se realizan todas las operaciones relacionadas a la capacidad  */
/*   de pago                                                        */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   05-May-2023        P. Jarrin       Emision Inicial             */
/*   25-Jul-2023        P. Jarrin       Ajuste Gastos Familiares    */
/*   22/Sep/2023        P. Jarrín       Ajuste signo B903813-R215336*/
/*   07/Dec/2023        B. Duenas       Ajuste deadlock R221171     */
/********************************************************************/

use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_capacidad_pago')
   drop proc sp_capacidad_pago 
go

create procedure sp_capacidad_pago(
   @s_ssn               int,
   @s_sesn              int           = null,
   @s_user              login         = null,
   @s_term              varchar(32)   = null,
   @s_date              datetime,
   @s_srv               varchar(30)   = null,
   @s_lsrv              varchar(30)   = null,
   @s_ofi               smallint      = null,
   @s_rol               smallint      = null,
   @s_org_err           char(1)       = null,
   @s_error             int           = null,
   @s_sev               tinyint       = null,
   @s_msg               descripcion   = null,
   @s_org               char(1)       = null,
   @s_culture           varchar(10)   = 'NEUTRAL',
   @t_debug             char(1)       = 'N',
   @t_file              varchar(10)   = null, 
   @t_from              varchar(32)   = null,
   @t_trn               int           = 172249,
   @t_show_version      bit           = 0, 
   @i_operacion         char(1), 
   @i_cliente           int           = null,
   @o_ventas            money         = null out,
   @o_compras           money         = null out,
   @o_gastos            money         = null out,
   @o_otro_ing          money         = null out,
   @o_gtos_fami         money         = null out,
   @o_capacidad_pago    money         = null out
        
)
as 
declare 
    @w_sp_name           varchar(32),
    @w_sp_msg            varchar(132),
    @w_existe_cliente    bit,   
    @w_porcentaje_uti    float,
    @w_nc_codigo         int,   
    @w_pago              money,
    @w_ventas            money,
    @w_compras           money,
    @w_utilidad_bruta    money, 
    @w_gastos            money,
    @w_utilidad_neg      money,
    @w_otro_ing          money,
    @w_gtos_fami         money,
    @w_utilidad_fam      money,
    @w_capacidad_pago    money,
    @w_gtos_fami_neg     money

select @w_sp_name = 'sp_capacidad_pago' 

if @i_operacion = 'S'
begin 
    select @w_existe_cliente = 1 
    from cobis..cl_ente with (nolock)
    where en_ente = @i_cliente 

    if @w_existe_cliente is null 
    begin 
        exec cobis..sp_cerror 
          @t_debug = @t_debug, 
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 1720079
        return 
    end

    select @w_porcentaje_uti = pa_float
    from cobis..cl_parametro with (nolock)
    where pa_producto = 'CLI'
    and pa_nemonico = 'PORUTI'

    select @w_nc_codigo = an_negocio_codigo
    from cobis.dbo.ts_analisis_negocio with (nolock) 
    where an_cliente_id = @i_cliente
    and an_clase not in ('P')
    order by an_secuencial asc

    select @w_pago           = (isnull(an_cuota_pago_buro,0)  + isnull(an_cuota_pago_enlace,0) + isnull(an_cuota_pago,0)),
           @w_gtos_fami_neg  = (isnull(an_gastos_alimentos,0) + isnull(an_gastos_renta_viv,0)  + isnull(an_gastos_energia_elect,0) +
                                isnull(an_gastos_agua,0)      + isnull(an_gastos_telefono,0)   + isnull(an_gastos_tv,0)   +
                                isnull(an_gastos_salud,0)     + isnull(an_gastos_transp,0)     + isnull(an_gastos_educ,0) +
                                isnull(an_gastos_gas,0)       + isnull(an_gastos_vestido,0)    + isnull(an_gastos_otros,0))
     from cobis..cl_analisis_negocio with (nolock), 
          cobis..cl_negocio_cliente with (nolock)
     where an_cliente_id     = @i_cliente
     and an_negocio_codigo = nc_codigo
     and an_negocio_codigo = @w_nc_codigo
     and nc_estado_reg = 'V'

    select 
        @w_ventas         = sum(isnull(an_ventas_prom_mes,0)),
        @w_compras        = sum(isnull(an_compras_prom_mes,0)),
        @w_utilidad_bruta = @w_ventas - @w_compras,
        
        @w_gastos         = (sum(isnull(an_renta_neg,0))    + sum(isnull(an_transporte_neg,0)) + sum(isnull(an_personal_neg,0)) +
                            sum(isnull(an_impuestos_neg,0)) + sum(isnull(an_electrica_neg,0))  + sum(isnull(an_agua_neg,0)) + 
                            sum(isnull(an_telefono_neg,0))  + sum(isnull(an_otros_neg,0))      + isnull(@w_pago,0)),

        @w_utilidad_neg   = @w_utilidad_bruta - @w_gastos,
        
        @w_otro_ing       = sum(isnull(an_monto_extra,0)),
        @w_gtos_fami      = @w_gtos_fami_neg,
                            
        @w_utilidad_fam   = @w_utilidad_neg + @w_otro_ing - @w_gtos_fami,
        
        @w_capacidad_pago = isnull((@w_utilidad_fam * @w_porcentaje_uti) / 100 , 0)
        
    from cobis..cl_analisis_negocio with (nolock), 
         cobis..cl_negocio_cliente  with (nolock)
    where an_cliente_id = @i_cliente
    and an_negocio_codigo = nc_codigo
    and nc_estado_reg = 'V'

    select
        @o_ventas         = isnull(@w_ventas , 0),
        @o_compras        = isnull(@w_compras, 0),
        @o_gastos         = isnull(@w_gastos, 0),
        @o_otro_ing       = isnull(@w_otro_ing, 0),
        @o_gtos_fami      = isnull(@w_gtos_fami , 0),
        @o_capacidad_pago = isnull(@w_capacidad_pago , 0)
end

return 0
go
