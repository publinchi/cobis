/************************************************************************/
/*      Archivo:                calcenrie.sp                            */
/*      Stored procedure:       sp_calculo_cenrie                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Marzo 2008                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calculo Consulta Central de Riesgo                              */
/************************************************************************/  
/*                           MODIFICACIONES                             */
/*      FECHA           AUTOR             RAZON                         */
/*      May-2008        MRoa              Validación deudores para cobro*/
/*                                        Central de riesgo             */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_calculo_cenrie')
   drop proc sp_calculo_cenrie
go

create proc sp_calculo_cenrie
@i_operacion    int,
@i_porcentaje   float,
@o_valor_rubro  money       = 0 out

as
declare 
@w_sp_name              varchar(30),
@w_return               int,
@w_est_vigente          tinyint,
@w_est_novigente        tinyint,
@w_parametro_apecr     catalogo,
@w_op_toperacion        catalogo,
@w_op_sector            catalogo,
@w_referencial          catalogo,
@w_tipo_val             catalogo,
@w_num_dec              smallint,
@w_op_moneda            smallint,
@w_vr_valor             float,
@w_signo                char(1),
@w_clase                char(1),
@w_op_tramite           int,
@w_fecha_liq            datetime,
@w_op_monto             money,
@w_di_dividendo         int,
@w_di_fecha_ven         datetime,
@w_di_estado            int,
@w_fecha_anual          datetime,
@w_valor                money,
@w_factor               float,
@w_asociado             catalogo,
@w_porcentaje           float,
@w_valor_asociado       money,
@w_can_deu              int

/* INICIALIZACION VARIABLES */
select 
@w_sp_name        = 'sp_calculo_cenrie',
@w_est_vigente    = 1,
@w_est_novigente  = 0,
@w_valor          = 0,
@w_porcentaje     = 0,
@w_valor_asociado = 0,
@w_asociado       = ''


--LECTURA DEL PARAMETRO CODIGO APERTURA DE CREDITO
select @w_parametro_apecr = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'APECR'
set transaction isolation level read uncommitted



/*OBTENER DATOS DE LA OPERACION */
select @w_op_tramite    = op_tramite,
       @w_op_toperacion = op_toperacion,
       @w_op_moneda     = op_moneda,
       @w_op_sector     = op_sector
from   ca_operacion
where  op_operacion = @i_operacion

/* NUMERO DE DECIMALES */
exec @w_return = sp_decimales
     @i_moneda      = @w_op_moneda,
     @o_decimales   = @w_num_dec out

if @w_return != 0 return  @w_return

/*OBTENER CANTIDAD DE DEUDORES PARA COBRO CENTRAL DE RIESGO- VERSION FABIAN DE LA TORRE
select @w_can_deu = count(*)
from   ca_deu_segvida
where  dt_operacion      = @i_operacion
and    dt_central_riesgo = 'S'
*/

/*MROA: OBTENER VALOR INDIVIDUAL A COBRAR POR CONSULTA CENTRAL DE RIESGO */
select @w_referencial = ru_referencial
from ca_rubro
where ru_toperacion  = @w_op_toperacion
and   ru_moneda      = @w_op_moneda
and   ru_estado      = 'V'
and   ru_concepto    = @w_parametro_apecr

print 'REFERENCIAL....' + cast(@w_referencial as varchar(20))

/*MROA: DETERMINACION DE LA TASA A APLICAR */
select @w_signo     = isnull(vd_signo_default, ''),
       @w_factor    = isnull(vd_valor_default, 0),
       @w_tipo_val  = vd_referencia,
       @w_clase     = va_clase
from ca_valor, ca_valor_det
where va_tipo   = @w_parametro_apecr
and   vd_tipo   = @w_parametro_apecr
and   vd_sector = @w_op_sector


print 'FACTOR....' + cast(@w_factor as varchar(20))
print 'CLASE.....' + cast(@w_clase as varchar(20))
print 'PORCENTAJE.....' + cast(@i_porcentaje as varchar(20))

if @w_clase = 'V'  
   select @i_porcentaje = @w_factor,
          @w_factor = 0
else
begin
    print '@w_vr_valor.....' + cast(@w_vr_valor as varchar(20))
    
    select @w_vr_valor = 0
    
    if @w_signo = '+'
       select @i_porcentaje = @w_vr_valor + @w_factor
    if @w_signo = '-'
       select @i_porcentaje = @w_vr_valor - @w_factor
    if @w_signo = '/'
       select @i_porcentaje = @w_vr_valor / @w_factor
    if @w_signo = '*'
       select @i_porcentaje = @w_vr_valor * @w_factor
end 

/*MROA: OBTENER CANTIDAD DE DEUDORES UTILIZANDO TABLA CR_DEUDORES*/
select @w_can_deu = isnull(count(*),0)
from   cob_credito..cr_deudores
where  de_tramite     = @w_op_tramite
and    de_cobro_cen   = 'S'


/* VALOR DE COBCENRIE */
select @o_valor_rubro = round((@w_can_deu * @i_porcentaje), @w_num_dec)


print '@o_valor_rubro.....' + cast(@o_valor_rubro as varchar(20))

/* VERIFICAR SI EL RUBRO COBCENRIE TIENE RUBRO ASOCIADO */
if exists (select 1
           from   ca_rubro_op_tmp
           where  rot_operacion         = @i_operacion
           and    rot_concepto_asociado = @w_parametro_apecr)
begin
   select 
   @w_asociado   = rot_concepto,
   @w_porcentaje = rot_porcentaje
   from   ca_rubro_op_tmp
   where  rot_operacion         = @i_operacion
   and    rot_concepto_asociado = @w_parametro_apecr
end

return 0

go