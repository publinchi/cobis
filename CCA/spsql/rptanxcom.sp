/************************************************************************/
/*   Archivo:             rptanxcom.sp                                  */
/*   Stored procedure:    sp_reporte_anexo_comisiones                   */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Walther Toledo Qu.                            */
/*   Fecha de escritura:  05/Sept/2019                                */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta para los Reportes Anexo de Comisiones BC SI y BC 52 Plus  */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*   FECHA           AUTOR          RAZON                               */
/*   05/Sept/2019  WTO            Emision Inicial                     */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reporte_anexo_comisiones ')
   drop proc sp_reporte_anexo_comisiones 
go

create proc sp_reporte_anexo_comisiones  (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              varchar(14)       = null,
   @s_term              varchar(64) = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_show_version      bit         = 0,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               int    = null,
   @i_operacion         char(1)     = null,
   @i_banco             varchar(24)      = null,
   @i_nemonico          varchar(10)     = null,
   @i_nombre_rpt        varchar(128) = null,
   @i_formato_fecha     int         = null
)as
declare
   @w_sp_name           varchar(24),
   @w_nombre_rpt        varchar(128),
   @w_gas_cob_sem       money,
   @w_gas_cob_cat       money,
   @w_mnc_gas_apert     varchar(32),
   @w_mnc_pag_tardio    varchar(32),
   @w_gas_apert         money,
   @w_pag_tardio        money,
   @w_num_reca          varchar(64),
   --
   @w_operacion         int,
   @w_tdividendo        varchar(10),
   @w_tipo_oper         varchar(10),
   @w_error             int,
   @w_return            int,
   @w_msg               varchar(1000)

   
select @w_sp_name = 'sp_reporte_anexo_comisiones'

--Versionamiento del Programa
if @t_show_version = 1
begin
  print 'Stored Procedure=' + @w_sp_name + ' Version=' + '1.0.0.0'
  return 0
end

if @t_trn <> 77536
begin        
   select @w_error = 151023
   goto ERROR
end

select @w_operacion  = op_operacion,
       @w_tdividendo = op_tdividendo,
       @w_tipo_oper  = op_toperacion
from ca_operacion
where op_banco = @i_banco
   
if @i_operacion = 'C'
begin
   
   select @w_nombre_rpt = valor 
   from cobis..cl_catalogo 
   where tabla in (
      select codigo 
      from cobis..cl_tabla 
      where tabla = 'ca_toperacion')
   and codigo = @w_tipo_oper
   
   select @w_gas_cob_sem = pa_money from cobis..cl_parametro 
   where pa_producto = 'CCA' and pa_nemonico = 'GASCOS'
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero GASCOS'
      goto ERROR
   end
   
   select @w_gas_cob_cat = pa_money from  cobis..cl_parametro 
   where pa_producto = 'CCA' and pa_nemonico = 'GASCOC'
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero GASCOC'
      goto ERROR
   end
    
    select @w_gas_cob_sem = isnull(@w_gas_cob_sem, 0), @w_gas_cob_cat = isnull(@w_gas_cob_cat, 0)
   
   select @w_mnc_gas_apert   = pa_char from cobis..cl_parametro 
   where pa_producto = 'CCA' and pa_nemonico = 'RUCGCO'
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero RUCGCO'
      goto ERROR
   end
   
   select @w_mnc_pag_tardio  = pa_char from cobis..cl_parametro 
   where pa_producto = 'CCA' and pa_nemonico = 'RUCPTA'
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero RUCPTA'
      goto ERROR
   end
    
   select top 1 @w_num_reca = id_dato
   from cob_credito..cr_imp_documento 
   WHERE id_toperacion LIKE @w_tipo_oper
   AND id_mnemonico IN ('ANXCOMBCSI', 'ANXCOMBC52')

   select @w_gas_apert = ro_porcentaje
   from ca_rubro_op
   where ro_concepto    = @w_mnc_gas_apert
   and ro_operacion   = @w_operacion
   
   select @w_pag_tardio = ro_porcentaje
   from ca_rubro_op
   where ro_concepto    = @w_mnc_pag_tardio
   and ro_operacion   = @w_operacion

   select 
      @w_gas_apert = isnull(@w_gas_apert, 0),
      @w_pag_tardio = isnull(@w_pag_tardio, 0)

   select
      @w_nombre_rpt  ,  @w_gas_cob_sem ,  @w_gas_cob_cat ,  @w_gas_apert ,  
      @w_pag_tardio  ,  @w_num_reca ,     @w_tdividendo
end

return 0

ERROR:
exec @w_return = cobis..sp_cerror
@t_debug  = @t_debug,
@t_file   = @t_file,
@t_from   = @w_sp_name,
@i_num    = @w_error,
@i_msg    = @w_msg

return @w_error


go