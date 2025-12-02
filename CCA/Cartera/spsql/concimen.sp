/************************************************************************/
/*	Archivo:		         concimen.sp			*/
/*	Stored procedure:	   sp_conciliacion_mensual		*/
/*	Base de datos:		   cob_cartera				*/
/*	Producto: 		      Credito y Cartera			*/	
/*	Disenado por:  		Elcira Pelaez				*/
/*	Fecha de escritura:	Feb.2003 			  	*/
/************************************************************************/
/*				                   IMPORTANTE           */
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.                                                       */
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				                   PROPOSITO            */
/*	Procedimiento que saca la informacion de los saldos a fin de mes*/
/*	de los bancos de segundo piso					*/
/* para insertcarlos en la estructura ca_conciliacion_mensual           */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre      	Proposito			*/
/*      03/Mar/2003	   Luis Mayorga  Dar funcionalidad procedimiento*/
/*      01/Dic/2006     E. Pelaez       defecto -7537 BAC		*/
/*      03/Sep/2007     John Jairo Rendon OPT_232                       */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_conciliacion_mensual')
   drop proc sp_conciliacion_mensual
go

create proc sp_conciliacion_mensual
@i_fecha_proceso     	datetime

as

declare 
@w_error          	      int,
@w_return         	      int,
@w_sp_name        	      descripcion,
@w_est_vigente    	      tinyint,
@w_op_banco		            cuenta,
@w_op_tramite		         int,
@w_op_oficina		         int,
@w_op_codigo_externo	      cuenta,
@w_op_fecha_ini		      datetime,
@w_op_nombre		         varchar(15),
@w_op_sector		         char(1),
@w_op_tdividendo	         char(1),
@w_op_tipo_linea	         catalogo,
@w_op_cliente		         int,
@w_op_moneda		         tinyint,
@w_op_margen_redescuento   float,
@w_op_opcion_cap	         char(1),
@w_op_operacion		      int,
@w_dividendo_vigente 	   smallint,
@w_prox_pago_int	         datetime,
@w_num_dec_op 		         tinyint,
@w_moneda_mn  		         tinyint,
@w_num_dec_n  		         tinyint,
@w_saldo_capital	         float,
@w_tasa_mercado		      varchar(10),
@w_saldo_redescuento	      float,
@w_referencial		         catalogo,
@w_signo 		            char(1),
@w_puntos       	         money,
@w_fpago 		            char(1),
@w_tasa_nominal		      float,
@w_tipo_tasa		         char(1),
@w_modalidad		         char(1),
@w_puntos_c 		         varchar(10),
@w_tasa_pactada		      varchar(25),
@w_norma_legal		         varchar(255),
@w_abono_interes 	         float,
@w_valor_capitalizar	      float,
@w_porcentaje_capitalizar  float,
@w_identificacion	         varchar(15),
@w_llaver		            char(24),
@w_ciudad_nacional         int,
@w_moneda_nacional         smallint,
@w_tipo_identificacion     char(2),
@w_cotizacion              float,
@w_abono_capital           money,
@w_op_fecha_ult_proceso	   datetime,
@w_finagro                 catalogo

-- CARGADO DE VARIABLES DE TRABAJO 
select @w_sp_name = 'sp_conciliacion_mensual'

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted


-- ESTADOS PARA OPERACIONES


select @w_est_vigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

select @w_finagro = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FINAG'
set transaction isolation level read uncommitted


if exists (select 1 from ca_conciliacion_mensual where cm_fecha_proceso  = @i_fecha_proceso)
	print 'Reproceso de fecha' + cast(@i_fecha_proceso as varchar)
else
        truncate table ca_conciliacion_mensual

create table #oper
(
	op_operacion                   int,
	op_banco                       cuenta
)

insert into #oper
select 
op_operacion,op_banco
from cob_cartera..ca_operacion
where op_tipo = 'R'  
and   op_tipo_linea = @w_finagro
and   op_estado not in (0,99,6,3)

delete #oper
from cob_cartera..ca_conciliacion_mensual
where cm_operacion = op_operacion

-- CURSOR PARA LEER LOS VENCIMIENTOS DE LA FECHA 
declare cursor_saldos_pasivas_men cursor for
select 
op_operacion,	op_banco
from #oper
for read only

open  cursor_saldos_pasivas_men

fetch cursor_saldos_pasivas_men into
@w_op_operacion,@w_op_banco

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin

--while @@fetch_status = 0 begin   
--   if @@fetch_status = -1 begin    
--      select @w_error = 710427 -- Crear error
--      return @w_error
--   end   

select 
@w_op_cliente=op_cliente,		
@w_op_moneda=op_moneda,		
@w_op_margen_redescuento=op_margen_redescuento,
@w_op_tramite=isnull(op_tramite,0),		
@w_op_oficina=op_oficina,
@w_op_codigo_externo=isnull(op_codigo_externo,'0'),	
@w_op_fecha_ini=op_fecha_ini,	
@w_op_nombre=substring(op_nombre,1,15),
@w_op_sector=op_sector,		
@w_op_tdividendo=op_tdividendo,	
@w_op_tipo_linea=op_tipo_linea,
@w_op_opcion_cap=op_opcion_cap,	
@w_op_fecha_ult_proceso=op_fecha_ult_proceso
from  ca_operacion                                     
where op_operacion = @w_op_operacion

   -- LECTURA DE DECIMALES 
   exec @w_return  = sp_decimales
   @i_moneda       = @w_op_moneda,
   @o_decimales    = @w_num_dec_op out,
   @o_mon_nacional = @w_moneda_mn  out,
   @o_dec_nacional = @w_num_dec_n  out

   -- DIVIDENDO VIGENTE y PROXIMO PAGO INT 
   select @w_dividendo_vigente  = di_dividendo
   from ca_dividendo 
   where di_operacion = @w_op_operacion
   and   di_estado    = @w_est_vigente

   -- SALDO_CAPITAL 
   select @w_saldo_capital = 0

   select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from  ca_dividendo, ca_amortizacion
   where am_operacion  = @w_op_operacion
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
   and   am_estado     <> 3  -- Cancelado
   and   am_concepto   = 'CAP'

   select @w_saldo_redescuento = isnull(@w_saldo_capital,0)

   -- FORMULA TASA 
   select 
   @w_referencial  = ro_referencial,
   @w_signo        = ro_signo,
   @w_puntos       = convert(money,ro_factor),
   @w_fpago        = ro_fpago,
   @w_tasa_nominal = ro_porcentaje
   from  ca_rubro_op
   where ro_operacion = @w_op_operacion
   and   ro_concepto  = 'INT'

   select @w_tasa_mercado = vd_referencia
   from  ca_valor_det
   where vd_tipo = @w_referencial  
   and   vd_sector = @w_op_sector  

   -- TIPO TASA 
   select @w_tipo_tasa = null

   select @w_tipo_tasa = tv_tipo_tasa
   from ca_tasa_valor
   where tv_nombre_tasa = @w_referencial

   -- MODALIDAD TASA 
   select @w_modalidad = 'V'  ---Por defecto

   if @w_fpago = 'P'
      select @w_modalidad = 'V'

   if @w_fpago = 'A'
      select @w_modalidad = 'A'
   
   select @w_puntos_c  = convert(varchar(10),@w_puntos)

   select @w_tasa_mercado = rtrim(ltrim(@w_tasa_mercado))
   select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c 

   -- NORMA LEGAL 
   select @w_norma_legal = substring(dt_valor,1,4) 
   from cob_credito..cr_datos_tramites
   where dt_dato = 'NL'
   and   dt_tramite = @w_op_tramite
  
   if @@rowcount = 0 
      select @w_norma_legal = 'No'

   -- ABONO INTERES
   select @w_abono_interes = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_rubro_op, ca_amortizacion, ca_concepto
   where  ro_operacion = @w_op_operacion
   and    ro_tipo_rubro in ('I', 'M')
   and    co_concepto = ro_concepto
   and    am_operacion = ro_operacion
   and    am_concepto  = ro_concepto
   and    am_estado in (1, 2, 4, 44)
   group by co_codigo*1000 + am_estado * 10, am_concepto, am_estado
   having sum(am_acumulado - am_pagado)!= 0

   select @w_prox_pago_int = di_fecha_ven
   from  ca_dividendo
   where di_operacion = @w_op_operacion 
   and   di_dividendo = @w_dividendo_vigente + 1

   -- VALOR A CAPITALIZAR
   select 
   @w_valor_capitalizar = 0,
   @w_porcentaje_capitalizar = 0

   if @w_op_opcion_cap = 'S' begin

      if exists (select 1 from ca_acciones
                 where  ac_operacion = @w_op_operacion
                 and    @w_dividendo_vigente between ac_div_ini and ac_div_fin)  begin

         select @w_porcentaje_capitalizar = ac_porcentaje
         from ca_acciones
	 where  ac_operacion = @w_op_operacion
         and  @w_dividendo_vigente between ac_div_ini and ac_div_fin
                        
         select @w_valor_capitalizar = (@w_abono_interes * @w_porcentaje_capitalizar )/100
         select @w_abono_interes = round(@w_abono_interes - @w_valor_capitalizar,@w_num_dec_op)
      end       
   end

   -- IDENTIFICACION
   select 
   @w_tipo_identificacion = en_tipo_ced,
   @w_identificacion      = en_ced_ruc
   from cobis..cl_ente
   where en_ente = @w_op_cliente
   set transaction isolation level read uncommitted

   if ltrim(rtrim(@w_tipo_identificacion)) = 'N'   ---solo para tipo de identificacion NIT, NO SE TOMA EN CUENTA EL DIGITO VERIFICADOR
      select @w_identificacion = substring (@w_identificacion,1,9) 

   select @w_cotizacion = 0          

   if @w_op_moneda <> @w_moneda_nacional begin

      exec sp_buscar_cotizacion
      @i_moneda     = @w_op_moneda,
      @i_fecha      = @w_op_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion output

      select @w_abono_capital     = round((@w_abono_capital * @w_cotizacion),0)
      select @w_abono_interes     = round((@w_abono_interes * @w_cotizacion),0)
      select @w_saldo_redescuento = round((@w_saldo_redescuento * @w_cotizacion),0)

   end else      

      select @w_cotizacion = 1

   insert into ca_conciliacion_mensual(
   cm_fecha_proceso,		cm_operacion,   	cm_banco,
   cm_tramite,			cm_oficina,             cm_llave_redescuento,	
   cm_fecha_redescuento,	cm_nombre,	        cm_tasa_nominal,
   cm_formula_tasa,             cm_saldo_redescuento,   cm_valor_interes,
   cm_modalidad_pago,       	cm_norma_legal,	        cm_prox_interes,         	
   cm_valor_capitalizar,        cm_banco_sdo_piso,   	cm_identificacion,
   cm_diferencia,		cm_estado,              cm_my,	
   cm_mw,			cm_llave_red,		cm_ident)
   values (
   @i_fecha_proceso,     @w_op_operacion,      @w_op_banco,
   @w_op_tramite,        @w_op_oficina,        @w_op_codigo_externo,
   @w_op_fecha_ini,      @w_op_nombre,         isnull(@w_tasa_nominal,	0),
   @w_tasa_pactada,      @w_saldo_redescuento, @w_abono_interes,
   @w_modalidad,         @w_norma_legal,       @w_prox_pago_int,
   @w_valor_capitalizar, @w_op_tipo_linea,     isnull(@w_identificacion, ''),
   0,                    'N',                  '',
   '',                   convert(float,substring(@w_op_codigo_externo, datalength(rtrim(ltrim(@w_op_codigo_externo))) - 4, 5)),
   convert(float,isnull(@w_identificacion, null))
   )

   fetch cursor_saldos_pasivas_men into
   @w_op_operacion,@w_op_banco

end -- CURSOR

close cursor_saldos_pasivas_men
deallocate cursor_saldos_pasivas_men

return 0

go