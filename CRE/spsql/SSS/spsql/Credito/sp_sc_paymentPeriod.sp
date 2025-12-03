USE cob_workflow
GO 

IF OBJECT_ID ('dbo.sp_sc_paymentPeriod') IS NOT NULL
    DROP PROCEDURE dbo.sp_sc_paymentPeriod
GO

create procedure sp_sc_paymentPeriod
(
/************************************************************/
/*  ARCHIVO:            sp_sc_paymentPeriod                 */
/*  NOMBRE LOGICO:      sp_sc_paymentPeriod                 */
/*  PRODUCTO:           APF                                 */
/************************************************************/
/*                      IMPORTANTE                          */
/*  Esta aplicacion es parte de los  paquetes bancarios     */
/*  propiedad de COBISCORP                                  */
/*  Su uso no autorizado queda  expresamente  prohibido     */
/*  asi como cualquier alteracion o agregado hecho  por     */
/*  alguno de sus usuarios sin el debido consentimiento     */
/*  por escrito de COBISCORP.                               */
/*  Este programa esta protegido por la ley de derechos     */
/*  de autor y por las convenciones  internacionales de     */
/*  propiedad intelectual.  Su uso  no  autorizado dara     */
/*  derecho   a  COBISCORP  para  obtener  ordenes   de     */
/*  secuestro o retencion y  para perseguir  penalmente     */
/*  a  los autores de cualquier infraccion.                 */
/************************************************************/
/*                      PROPOSITO                           */
/*  Procedimiento que genera un pseudocatalogo con los      */
/*  periodos para pago de intereses o dividendos.           */
/************************************************************/
/*                      MODIFICACIONES                      */
/*  FECHA           AUTOR               RAZON               */
/*  24/01/2018      Freddy Feria        Emision Inicial     */
/************************************************************/

    @s_ssn              int,
    @s_user             varchar(30),
    @s_sesn             int,
    @s_term             varchar(30),
    @s_date             datetime,
    @s_srv              varchar(30),
    @s_lsrv             varchar(30),
    @s_ofi              smallint,
    @t_debug            char(1)         = 'N',
    @t_file             varchar(14)     = null,
    @t_from             varchar(30)     = null,
    @s_rol              smallint        = null,
    @s_org_err          char(1)         = null,
    @s_error            int             = null,
    @s_sev              tinyint         = null,
    @s_msg              descripcion     = null,
    @s_org              char(1)         = null,
    @t_rty              char(1)         = null,
    @t_show_version     BIT             = 0,
    @i_tipo             char(1)         = null,
    @i_tabla            varchar(30)     = null,
    @i_codigo           varchar(150)    = null,
    @i_oficina          int             = 1,
    @i_filas            int             = 80,
    @i_descripcion      varchar(150)    = ''
)as
declare @w_sp_name    varchar(32),
        @w_error      INT,
        @w_mensaje    VARCHAR(256)

select @w_sp_name = 'sp_sc_paymentPeriod'
---- VERSIONAMIENTO DEL PROGRAMA ----
if @t_show_version = 1
begin
   print 'stored procedure !, version 1.0.0.0'
   return 0
end
-------------------------------------
if @i_tipo = 'B' begin --consulta los registros sin filtro
    set rowcount @i_filas

    select  "Codigo" = ltrim(rtrim(td_tdividendo)),
            "Descripcion" = ltrim(rtrim(td_descripcion))
    from    cob_cartera..ca_tdividendo
    where   td_estado = 'V'
    order by td_tdividendo

    set rowcount 0
end

if @i_tipo = 'V'
begin
    select  "Descripcion" = ltrim(rtrim(td_descripcion))
    from    cob_cartera..ca_tdividendo
    where   td_estado = 'V'
    AND td_tdividendo = @i_codigo
    order by td_tdividendo
   
    if @@rowcount =  0
    begin
        select  @w_error    = 101001,
                @w_mensaje    = 'No existe dato solicitado'
        goto ERROR
    end
end

return 0

ERROR:
      exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
      return @w_error

GO

