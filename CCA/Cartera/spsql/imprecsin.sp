/************************************************************************/
/*   Archivo:             imprecsin.sp                                  */
/*   Stored procedure:    sp_imp_reclam_sin                             */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            cartera						               	*/
/*   Disenado por:        Luis Carlos Moreno C.			                */
/*   Fecha de escritura:  Diciembre/2011                                */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios	                */
/*	propiedad de "MACOSA", representantes exclusivos para	            */
/*  el Ecuador de "NCR".                      			                */
/*  Su uso no autorizado queda expresamente prohibido asi como  		*/
/*  cualquier alteracion o agregado hecho por alguno de sus    			*/
/*  usuarios sin el debido consentimiento por escrito de la    			*/
/*  Presidencia Ejecutiva de MACOSA o su representante.    			    */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Genera información para la generación del reporte de reclamaciones  */
/*  de garantia para una fecha dada                                     */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA     AUTOR             RAZON                                   */
/*  30-12-11  L.Moreno  Emisión Inicial - Req 293 - Rep. Recl. Siniest. */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_imp_reclam_sin')
   drop proc sp_imp_reclam_sin
go

create procedure sp_imp_reclam_sin(
	   @s_user               login        = null,
	   @s_term               varchar(30)  = null,
	   @s_date               datetime     = null,
	   @s_ssn                int          = null,
	   @s_srv                varchar(30)  = null, 
	   @s_sesn               int          = null,
	   @s_ofi                smallint     = null,
	   @s_rol		         smallint     = null,
       @i_operacion          char(1)      = null,
       @i_fec_rec            datetime     = null,
       @i_secuencial         int          = 0
)

as

declare @w_sp_name           varchar(32),
        @w_nom_ent           varchar(30),
        @w_num_usa           varchar(30),
        @w_cod_gar_usaid     varchar(30),
        @w_porc_cobert       money,
        @w_fec_ult_rec       datetime,
        @w_num_rec           int,
        @w_tot_pago          money,
        @w_error             int,
        @w_dias_mora         int
        
select @w_sp_name = 'sp_imp_reclam_sin'
--Institucion Financiera
select @w_nom_ent = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CRE'
and   pa_nemonico = 'BANCO'

--Numero Garantia
select @w_num_usa = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'NUMUSA'

--Porcentaje Garantia
select @w_cod_gar_usaid = pa_char
      from cobis..cl_parametro with (nolock)
      where pa_producto = 'GAR'
      and   pa_nemonico = 'CODUSA'

--INI AGI.  Se comenta porque campo tc_porcen_cobertura en la tabla cu_tipo_custodia   
/*
select @w_porc_cobert = tc_porcen_cobertura
from   cob_custodia..cu_tipo_custodia
where  tc_tipo = @w_cod_gar_usaid
*/
--FIN AGI

select @w_fec_ult_rec = pa_datetime
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'FECUSA'

select @w_dias_mora = pa_tinyint
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'DIAREC'

/* Si el secuencial es nulo se asigna el valor de cero para la busqueda */
if @i_secuencial is null
   select @i_secuencial = 0

/* Leer catalogo de formas de pago por reconocimiento */
select c.codigo
into #formas_rec
from
cobis..cl_tabla t with (nolock),
cobis..cl_catalogo c with (nolock)
where t.tabla = 'ca_fpago_reconocimiento'
and   c.tabla = t.codigo

select banco       = do_banco,
      id_unico    = cu_codigo_externo,
      nom_cliente = op_nombre,
      fec_inicio  = convert(varchar(10),op_fecha_liq,103),
      fec_cober   = convert(varchar(10),op_fecha_liq,103),
      fec_ult_dem = '',
      fec_reclamo = '',
      ult_fec_rec = convert(varchar(10),@w_fec_ult_rec,103),
      sld_ult_rep = convert(money,0),
      sld_cap     = op_monto_aprobado,
      monto_rec   = round(isnull(op_monto_aprobado,0) * @w_porc_cobert / 100,0),
      operacion   = op_operacion,
      desembolso  = op_monto_aprobado
into #reporte
from cob_conta_super..sb_dato_operacion with (nolock),
    cob_cartera..ca_operacion with (nolock),
    cob_credito..cr_gar_propuesta with (nolock),
    cob_custodia..cu_custodia with (nolock),
    cob_custodia..cu_tipo_custodia with (nolock)
where op_banco          = do_banco
and   gp_tramite        = op_tramite
and   cu_codigo_externo = gp_garantia
and   tc_tipo           = cu_tipo
and   do_fecha          = @i_fec_rec
and   cu_estado         not in ('A')
and   tc_tipo_superior  = @w_cod_gar_usaid
and   do_edad_mora      >= @w_dias_mora
and   op_operacion not in (select ab_operacion
                         from
                         cob_cartera..ca_abono with (nolock),
                         cob_cartera..ca_abono_det with (nolock),
                         #formas_rec
                         where ab_operacion = op_operacion
                         and   abd_operacion = ab_operacion
                         and   abd_secuencial_ing = ab_secuencial_ing
                         and   abd_concepto = codigo
                         and   ab_estado in ('A','ING','NA'))--No tener en cuenta las obligaciones con reconocimiento
order by op_operacion 

select @w_num_rec = @@rowcount

if @w_num_rec = 0
begin
  select @w_error = 721331
  goto ERROR
end

--ACTUALIZA LA TABLA CON EL ULTIMO SALDO DE LA OBLIGACION INFORMADO EN EL REPORTE SEMESTRAL
update #reporte
set sld_ult_rep = ru_saldo
from cob_cartera..ca_rep_usaid with (nolock)
where ru_banco = banco

--Actualizacion Monto Pagado
select banco = op_banco, monto = sum(ar_monto_mn)
into #pagado
from #reporte, 
cob_cartera..ca_operacion, 
cob_cartera..ca_rubro_op, 
cob_cartera..ca_abono_rubro, 
cob_cartera..ca_transaccion
where op_operacion  = ar_operacion
and   tr_secuencial = ar_secuencial
and   tr_operacion  = ar_operacion 
and   ro_operacion  = ar_operacion
and   ro_concepto   = ar_concepto
and   ro_tipo_rubro = 'C'
and   op_banco = banco
and   tr_estado <> 'RV'
and   tr_secuencial >= 0
group by op_banco

update #reporte
set 
sld_cap = isnull(r.desembolso,0) - isnull(p.monto,0),
monto_rec = round((isnull(r.desembolso,0) - isnull(p.monto,0)) * @w_porc_cobert / 100,0)
from #reporte r, #pagado p
where r.banco = p.banco

select @w_tot_pago = sum(monto_rec)
from #reporte

--ENCABEZADO REPORTE
if @i_operacion = 'C'
   select institucion = @w_nom_ent,
          num_gar     = @w_num_usa,
          porc_gar    = @w_porc_cobert,
          fec_rec     = convert(varchar(10),@i_fec_rec,103),
          num_rec     = @w_num_rec,
          vlr_rec     = @w_tot_pago

--DETALLE REPORTE
set rowcount 20
select id_unico, nom_cliente, fec_inicio, fec_cober,
      fec_ult_dem, fec_reclamo, ult_fec_rec, sld_ult_rep,
      sld_cap, monto_rec, operacion
from #reporte 
where operacion      > @i_secuencial
order by operacion
set rowcount 0

return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go