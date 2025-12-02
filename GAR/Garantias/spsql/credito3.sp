/*************************************************************************/
/*   Archivo:              credito3.sp                                   */
/*   Stored procedure:     sp_credito3                                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_credito3') IS NOT NULL
    DROP PROCEDURE dbo.sp_credito3
go
create proc dbo.sp_credito3 (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_garantia           descripcion = null,
   @i_tramite            int = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_scu                varchar(64)

select @w_today = getdate()
select @w_sp_name = 'sp_credito3'

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19444 and @i_operacion = 'S') 
begin
   /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end
else
begin
   create table #temporal (moneda money, cotizacion money)
   insert into #temporal (moneda,cotizacion)
  select ct_moneda,ct_compra
   from cob_conta..cb_cotizacion
   where ct_fecha =(SELECT max(ct_fecha) FROM cob_conta..cb_cotizacion)
   GROUP BY ct_moneda,ct_compra
end

if @i_operacion = 'S'
begin
   set rowcount 20
   select tr_tramite,tr_numero_op,((1-floor(power(cos(gp_monto_exceso),2))) * gp_monto_exceso + floor(power(cos(gp_monto_exceso),2)) * tr_monto * isnull(cotizacion,1)),tr_monto * isnull(cotizacion,1)
   from cob_credito..cr_gar_propuesta 
   inner join cob_credito..cr_tramite on gp_tramite = tr_tramite
   left join #temporal on moneda = tr_moneda
   where gp_garantia  =  @i_garantia
   --  and co_fecha     =  dateadd(dd,-1,@s_date)
     and (tr_tramite  >  @i_tramite or @i_tramite is null)
 
   if @@rowcount = 0
      if @i_tramite is null
         print 'No existen tramites para esta garantia'
      else
         print 'No existen mas tramites para esta garantia'
end
go