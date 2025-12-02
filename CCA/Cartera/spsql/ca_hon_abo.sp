/***********************************************************************/
/*     Archivo:                         ca_hon_abo.sp                  */
/*     Stored procedure:                sp_hon_abo                     */
/*     Base de Datos:                   cob_cardtera                   */
/*     Producto:                        Cartera                        */
/*     Disenado por:                    J. Ardila                      */
/*     Fecha de Documentacion:          21/Jul/2011                    */
/***********************************************************************/
/*               IMPORTANTE                                            */
/*     Este programa es parte de los paquetes bancarios propiedad de   */
/*     'MACOSA',representantes exclusivos para el Ecuador de la        */
/*     AT&T                                                            */
/*     Su uso no autorizado queda expresamente prohibido asi como      */
/*     cualquier autorizacion o agregado hecho por alguno de sus       */
/*     usuario sin el debido consentimiento por escrito de la          */
/*     Presidencia Ejecutiva de MACOSA o su representante              */
/***********************************************************************/
/*                            PROPOSITO                                */
/*     Procedimiento que basado en el numero de la operacion y el      */
/*     código del abogado obtiene el porcentaje a cobrar al cliente    */
/*     por concepto de honorarios                                      */
/***********************************************************************/
/*               MODIFICACIONES                                        */
/*     FECHA          AUTOR                  RAZON                     */
/*  21/Jul/2011      J. Ardila            Emision Inicial - REQ 230    */
/***********************************************************************/
use cob_cartera
go

if object_id ('sp_hon_abo') is not null
begin
   drop proc sp_hon_abo
end
go

create proc sp_hon_abo (
   @s_ssn         int         = null,
   @s_date        datetime    = null,
   @s_user        login       = null,
   @s_term        descripcion = null,
   @s_ofi         smallint    = null,
   @s_srv         varchar(30) = null,
   @s_lsrv        varchar(30) = null,
   @i_banco       cuenta,
   @i_abogado     catalogo    = null,
   @i_estado_cob  catalogo    = null,
   @o_porcentaje  float       = null out,
   @o_tarifa      money       = null out
)
as
declare
   @w_sp_name     varchar(32),
   @w_codhon      int,
   @w_porcentaje  float,
   @w_tarifa      money,
   @w_debug       char(1)

select @w_sp_name = 'sp_hon_abo', @w_debug = 'N'

if not exists (select 1 from cob_credito..cr_altura_mora
                where am_banco = @i_banco)
begin
   -- RETORNO DE DATOS
   select @o_porcentaje = 0.00, @o_tarifa = 0.00
   return 0
end

-- ALTURA DE MORA
select @w_codhon = am_codigo_honorario
  from cob_credito..cr_altura_mora
 where am_banco           = @i_banco
   and am_estado_cobranza = @i_estado_cob

if @w_debug = 'S'
   print '@w_codhon: ' + isnull(cast(@w_codhon as varchar), 'NULL')

-- HONORARIOS ABOGADO
select @w_porcentaje = ha_tasa_cobrar,
       @w_tarifa     = ha_tarifa_unica
  from cob_credito..cr_hono_abogado
 where ha_id_abogado       = @i_abogado
   and ha_codigo_honorario = @w_codhon

if @w_debug = 'S'
begin
   print 'HONORARIOS ABOGADO'
   print '@w_porcentaje: ' + isnull(cast(@w_porcentaje as varchar), 'NULL')
   print '@w_tarifa: ' + isnull(cast(@w_tarifa as varchar), 'NULL')
end

if @w_porcentaje is null and @w_tarifa is null
begin
   -- HONORARIOS X MORA
   select @w_porcentaje = hm_tasa_cobrar,
          @w_tarifa     = hm_tarifa_unica
     from cob_credito..cr_hono_mora
    where hm_codigo          = @w_codhon
      and hm_estado_cobranza = @i_estado_cob

   if @w_debug = 'S'
   begin
      print 'HONORARIOS X MORA'
      print '@w_porcentaje: ' + isnull(cast(@w_porcentaje as varchar), 'NULL')
      print '@w_tarifa: ' + isnull(cast(@w_tarifa as varchar), 'NULL')
   end
end

-- No existe Tarifa de Honorarios para ese Rango y Estado de Cobranza
if @w_porcentaje is null and @w_tarifa is null return 721326

-- RETORNO DE DATOS
select 
   @o_porcentaje = @w_porcentaje,
   @o_tarifa     = @w_tarifa

return 0
go
