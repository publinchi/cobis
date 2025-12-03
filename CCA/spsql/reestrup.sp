/************************************************************************/
/*	Archivo: 	         	reestrup.sp				                              */
/*	Stored procedure: 	sp_reestructuracion_pasiva		                  */
/*	Base de datos:    	cob_cartera				                              */
/*	Producto: 		      Cartera				                                 	*/
/*	Disenado por:  		  Xavier Maldonado                  	            */
/*	Fecha de escritura: Nov 2003				                                */
/************************************************************************/
/*				                    IMPORTANTE				                        */
/*	Este programa es parte de los paquetes bancarios propiedad de	      */
/*	"MACOSA".							                                              */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		          */
/*	usuarios sin el debido consentimiento por escrito de la 	          */
/*	Presidencia Ejecutiva de MACOSA o su representante.		              */
/************************************************************************/  
/*				                    PROPOSITO				                          */
/*	Realiza la reestructuracion de una operacion pasiva a partir 	      */
/*	de la operacion activa                                              */
/*                              MODIFICACIONES                          */
/*  Nov-22-2005  Ivan Jimenez    REQ 379 Traslado de Intereses          */
/*  Jun-09-2010  ELcira PElaez   Quitar codigo causacion Pasivas y      */
/*                               comentados                             */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reestructuracion_pasiva')
   drop proc sp_reestructuracion_pasiva
go


create proc sp_reestructuracion_pasiva (
   @s_user		login        = null,
   @s_term		varchar(30)  = null,
   @s_sesn              int          = null,
   @s_date		datetime     = null,
   @s_ofi		smallint     = null,
   @i_banco_activa      cuenta,
   @i_banco_pasiva      cuenta,
   @i_activa            int,
   @i_pasiva            int,
   @i_num_reest         char(1),
   @i_cotizacion        money,
   @i_fecha_proceso     datetime
)

as declare	
   @w_sp_name		    varchar(30),
   @w_return      	    int,
   @w_activa                int,
   @w_pasiva                int,
   @w_banco_pasiva          cuenta,
   @w_tipo_amortizacion     varchar(10),
   @w_op_fecha_ini          datetime,
   @w_op_fecha_fin          datetime,
   @w_op_tplazo             catalogo,  
   @w_op_plazo              smallint,
   @w_op_tdividendo         catalogo,
   @w_op_periodo_cap        smallint,
   @w_op_periodo_int        smallint,
   @w_op_gracia_cap         smallint,
   @w_op_gracia_int         smallint,
   @w_op_cuota              money,
   @w_op_periodo_reajuste   smallint,
   @w_op_reajuste_especial  char(1),
   @w_op_dias_anio          smallint,
   @w_op_tipo_amortizacion  varchar(10),
   @w_op_tipo_cobro         char(1),
   @w_op_tipo_reduccion     char(1),
   @w_op_tipo_aplicacion    char(1),
   @w_op_dist_gracia        char(1),
   @w_op_dia_fijo           tinyint,
   @w_op_evitar_feriados    char(1),
   @w_op_mes_gracia         tinyint,
   @w_op_base_calculo       char(1),
   @w_op_recalcular_plazo   char(1),
   @w_op_opcion_cap         char(1),
   @w_op_tasa_cap           float,
   @w_op_dividendo_cap      smallint,
   @w_op_fecha_pri_cuot     datetime,
   @w_op_ult_dia_habil      char(1),
   @w_op_tipo_redondeo	    tinyint,
   @w_op_convierte_tasa     char(1),
   @w_tipo_crecimiento      char(1),
   @w_moneda_pas            tinyint,
   @w_dias_anio_pas         smallint,
   @w_sector_pas            catalogo,
   @w_oficina_pas           smallint,
   @w_fecha_proceso_pas     datetime,
   @w_base_calculo_pas      char(1),
   @w_dias_interes_pas      int,
   @w_tipo_pas              char(1),
   @w_gerente_pas           smallint,
   @w_num_div               smallint,  -- Para Traslado de Intereses IFJ REQ 379 25/Nov/2005
   @w_ti_cuota_dest         smallint   -- Para Traslado de Intereses IFJ REQ 379 25/Nov/2005
   
/* VARIABLES INICIALES  */
select @w_sp_name = 'sp_reestructuracion_pasiva'

/* OBTENER DATOS DE LA OPERACION PASIVA */
select
@w_moneda_pas            = op_moneda,
@w_dias_anio_pas         = op_dias_anio,
@w_sector_pas            = op_sector,
@w_oficina_pas           = op_oficina,
@w_base_calculo_pas      = op_base_calculo,
@w_tipo_pas              = op_tipo,
@w_gerente_pas           = op_oficial
from  ca_operacion 
where op_operacion = @i_pasiva

select @w_fecha_proceso_pas = dateadd(dd, -1, @i_fecha_proceso)

select @w_dias_interes_pas = max(di_dias_cuota)
from   ca_dividendo
where  di_operacion = @i_pasiva
and    di_estado    = 1

/** INICIO REQ 379 IFJ 25/Nov/2005 **/
select @w_num_div = max(di_dividendo)
from ca_dividendo
where di_operacion = @i_pasiva

Select @w_ti_cuota_dest = min(ti_cuota_dest)
from  ca_traslado_interes
Where ti_operacion = @i_pasiva
And   ti_estado     = 'P'

if @@rowcount > 0
begin
   if @w_ti_cuota_dest <= @w_num_div
   begin
      return 711007
   end
end

/* CREAR OPERACION TEMPORAL PASIVA */
exec @w_return = sp_crear_tmp
@s_user        = @s_user,
@s_term        = @s_term, 
@i_banco       = @i_banco_pasiva,
@i_accion      = 'R'

if @w_return <> 0 return @w_return

/* OBTENER DATOS DE LA OPERACION ACTIVA */
select
@w_op_fecha_ini           = op_fecha_ini,
@w_op_fecha_fin           = op_fecha_fin,
@w_op_tplazo              = op_tplazo,
@w_op_plazo               = op_plazo,
@w_op_tdividendo          = op_tdividendo,
@w_op_periodo_cap         = op_periodo_cap,
@w_op_periodo_int         = op_periodo_int,
@w_op_gracia_cap          = op_gracia_cap, 
@w_op_gracia_int          = op_gracia_int,
@w_op_cuota               = op_cuota,
@w_op_periodo_reajuste    = op_periodo_reajuste,
@w_op_reajuste_especial   = op_reajuste_especial,
@w_op_dias_anio           = op_dias_anio,
@w_op_tipo_amortizacion   = op_tipo_amortizacion,
@w_op_tipo_cobro          = op_tipo_cobro,
@w_op_tipo_reduccion      = op_tipo_reduccion,
@w_op_tipo_aplicacion     = op_tipo_aplicacion,
@w_op_dist_gracia         = op_dist_gracia,
@w_op_dia_fijo            = op_dia_fijo,
@w_op_evitar_feriados     = op_evitar_feriados,
@w_op_mes_gracia          = op_mes_gracia,
@w_op_base_calculo        = op_base_calculo,
@w_op_recalcular_plazo    = op_recalcular_plazo,
@w_op_opcion_cap          = op_opcion_cap,
@w_op_tasa_cap            = op_tasa_cap,
@w_op_dividendo_cap       = op_dividendo_cap,
@w_op_fecha_pri_cuot      = op_fecha_pri_cuot,   
@w_op_ult_dia_habil       = op_dia_habil,       
@w_op_tipo_redondeo       = op_tipo_redondeo,    
@w_tipo_crecimiento       = op_tipo_crecimiento,           ---REUTILIZACION DEL CAMPO, 'A' PARA CALCULO AUTOMATICO TABLA AMORTIZACION CAPITAL FIJO O CUOTA FIJA, 
                                                           ---Y 'D' DIGITADO UN VALOR DE CAPITAL O CUOTA FIJA 
@w_op_convierte_tasa      = isnull(op_convierte_tasa,'S')
from  cob_cartera..ca_operacion
where op_operacion = @i_activa

if @w_return <> 0 return @w_return

if @w_tipo_crecimiento in ('A','P')
   select @w_op_cuota = 0

/* ACTUALIZAR DATOS DE LA OPERACION TEMPORAL PASIVA */
update ca_operacion_tmp set  
opt_fecha_ini         = @i_fecha_proceso,
opt_fecha_fin         = @w_op_fecha_fin,
opt_plazo             = @w_op_plazo,
opt_tplazo            = @w_op_tplazo,
opt_tdividendo        = @w_op_tdividendo,
opt_periodo_cap       = @w_op_periodo_cap,
opt_periodo_int       = @w_op_periodo_int,
opt_cuota             = 0,
opt_gracia_cap        = @w_op_gracia_cap, 
opt_gracia_int        = @w_op_gracia_int,
opt_periodo_reajuste  = @w_op_periodo_reajuste,
opt_reajuste_especial = @w_op_reajuste_especial,
opt_dias_anio         = @w_op_dias_anio,
opt_tipo_amortizacion = @w_op_tipo_amortizacion,
opt_tipo_cobro        = @w_op_tipo_cobro,
opt_tipo_reduccion    = @w_op_tipo_reduccion,
opt_tipo_aplicacion   = @w_op_tipo_aplicacion,
opt_dist_gracia       = @w_op_dist_gracia,
opt_dia_fijo          = @w_op_dia_fijo,
opt_evitar_feriados   = @w_op_evitar_feriados,
opt_mes_gracia        = @w_op_mes_gracia,
opt_base_calculo      = @w_op_base_calculo,      
opt_recalcular_plazo  = @w_op_recalcular_plazo,
opt_opcion_cap        = @w_op_opcion_cap,         
opt_tasa_cap          = @w_op_tasa_cap,           
opt_dividendo_cap     = @w_op_dividendo_cap,      
opt_fecha_pri_cuot    = @w_op_fecha_pri_cuot,     
opt_dia_habil         = @w_op_ult_dia_habil,      
opt_tipo_redondeo     = @w_op_tipo_redondeo,	
opt_convierte_tasa    = @w_op_convierte_tasa
where opt_operacion = @i_pasiva
      
if @@error != 0 return 710002

/* GENERAR TABLA TEMPORAL DE LA PASIVA */
exec @w_return      = sp_gentabla
@i_operacionca      = @i_pasiva,
@i_reajuste         = 'N',   --@w_op_reajustable, porque el gentabla pone en cero los valores de gracia cuando es reajustable
@i_tabla_nueva      = 'S',
@i_dias_gracia      = 0,
@i_actualiza_rubros = 'S',
@i_crear_op         = 'S',
@i_control_tasa     = 'S'
      
if @w_return != 0 return @w_return

/* GENERAR REESTRUCTURACION DE LA OPERACION */
exec @w_return = sp_reestructuracion_int
@s_user        = @s_user,
@s_term        = @s_term,
@s_sesn        = @s_sesn,
@s_date        = @s_date,
@s_ofi         = @s_ofi,
@i_banco       = @i_banco_pasiva,
@i_num_reest   = @i_num_reest,
@i_cotizacion  = @i_cotizacion

if @w_return != 0 return @w_return

/* BORRAR OPERACION PASIVA TEMPORAL */
exec @w_return = sp_borrar_tmp
@s_user        = @s_user,
@s_term        = @s_term, 
@i_banco       = @i_banco_pasiva

if @w_return <> 0 return @w_return


return 0
go

