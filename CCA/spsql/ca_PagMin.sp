/******************************************************************/
/*  Archivo:            ca_PagMin.sp                              */
/*  Stored procedure:   sp_pagosMinimosVEn                        */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Elcira Pelaez                             */
/*  Fecha de escritura:  AGO.2012                                 */
/******************************************************************/
/*                          IMPORTANTE                            */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'MACOSA'                                                      */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                          PROPOSITO                             */
/*  Con la fecha del sistema busca las transacciones que se       */
/*  ejecutaronen el batch                                         */
/******************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_pagos_saldos_minimos_tmp')
      drop table ca_pagos_saldos_minimos_tmp
go

CREATE TABLE ca_pagos_saldos_minimos_tmp (
banco      cuenta null,
operacion  int null,
dividendo  smallint null,
fecha_ven  datetime null,
debe       money null
)
go


if object_id('sp_pagosMinimosVEn') is not null
   drop proc sp_pagosMinimosVEn
go


create proc sp_pagosMinimosVEn
   @i_param1   datetime,
   @i_param2   datetime
as

declare 
	@w_s_app              varchar(250),
	@w_cmd                varchar(250),
	@w_path               varchar(250),
	@w_comando            varchar(500),
	@w_batch              int,
	@w_errores            varchar(255),
	@w_destino            varchar(255),
	@w_error              int,
	@w_dia                varchar(2),
	@w_mes                varchar(2),
	@w_anio               varchar(4),
	@w_fecha_plano        varchar(8),
	@w_fcha_cca           datetime,
	@w_valor_saldo_minimo   money,
	@w_fcha_ini            datetime,
	@w_fcha_fin            datetime,
	@w_beneficiario        varchar(50),
	@w_ofi                 int,
	@w_operacion            int,
	@w_debe               money,
	@w_secuencial_ing   int
	

  
select @w_fcha_cca  = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_operacion = 0

---MONTO SALDO MINIMO
select @w_valor_saldo_minimo = pa_money
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'SALMIN'
   
select @w_fcha_ini = @i_param1
select @w_fcha_fin = @i_param2

select @w_fcha_cca = convert(varchar(12),@w_fcha_cca,101)

--- GENERAR LOS ARCHIVOS PLANOS POR BCP
select @w_dia  = convert(varchar(2), datepart (dd, @w_fcha_cca))
select @w_mes  = convert(varchar(2), datepart (mm, @w_fcha_cca))
select @w_anio = convert(varchar(4), datepart (yy, @w_fcha_cca))

--select @w_dia = CASE WHEN convert(int, @w_dia) < 10 then '0' + @w_dia else @w_dia end
if convert(int, @w_dia) < 10
   select @w_dia = '0' + @w_dia
else
   select @w_dia = @w_dia

--select @w_mes = CASE WHEN convert(int, @w_mes) < 10 then '0' + @w_mes else @w_mes end
if convert(int, @w_mes) < 10
   select @w_mes = '0' + @w_mes
else
   select @w_mes = @w_mes
   
select @w_fecha_plano = convert(varchar(2), @w_dia) + convert(varchar(2), @w_mes)+ convert(varchar(4), @w_anio)

truncate table ca_pagos_saldos_minimos_tmp

insert into ca_pagos_saldos_minimos_tmp
select op_banco,op_operacion,di_dividendo,di_fecha_ven,'debe'=sum(am_acumulado - am_pagado) 
from ca_operacion with (nolock),
     ca_dividendo with (nolock),
     ca_amortizacion with (nolock)
where op_operacion = di_operacion
and   op_operacion = am_operacion
and  di_estado = 2
and am_operacion = di_operacion
and am_dividendo = di_dividendo
and di_fecha_ven between @w_fcha_ini and  @w_fcha_fin 
and op_estado in (1,2,4,9)
group by op_banco,op_operacion,di_dividendo,di_fecha_ven


delete ca_pagos_saldos_minimos_tmp
where debe > @w_valor_saldo_minimo

---PROCESO PARA REGISTRAR EL SALDO MINIMO
  

   while 1 = 1
    begin

      set rowcount 1

      select @w_operacion = operacion,
             @w_debe      = debe
      from ca_pagos_saldos_minimos_tmp
      where operacion > @w_operacion
      order by operacion

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0
      
	      select @w_secuencial_ing = 0

	      exec @w_secuencial_ing = sp_gen_sec
	      @i_operacion  = @w_operacion

          select @w_ofi           = op_oficina
          from ca_operacion
          where op_operacion = @w_operacion
          
	      insert into ca_abono
	      (ab_secuencial_ing,     ab_secuencial_rpa,           ab_secuencial_pag,            
	       ab_operacion,          ab_fecha_ing,                ab_fecha_pag,           
	       ab_cuota_completa,     ab_aceptar_anticipos,        ab_tipo_reduccion,  
	       ab_tipo_cobro,         ab_dias_retencion_ini,       ab_dias_retencion,
	       ab_estado,             ab_usuario,                  ab_oficina,                   
	       ab_terminal,           ab_tipo,                     ab_tipo_aplicacion,     
	       ab_nro_recibo,         ab_tasa_prepago,             ab_dividendo,       
	       ab_calcula_devolucion, ab_prepago_desde_lavigente)
	      values(
	       @w_secuencial_ing,     0,                           0,                            
	       @w_operacion,        @w_fcha_cca,               @w_fcha_cca,              
	       'N',     'S',        'N',      
	       'A',                  0,                             0,
	       'ING',                 'sa',                     @w_ofi,                   
	       'CONSOLA',               'PAG',                       'D',         
	       @w_secuencial_ing,      0.00,                        0,                      
	       'N',                   'N')
	
	      if @@error <> 0
	       begin
	         print 'ATENCION!!! error Insertando en ca_abono'
	      end
     
	      insert into ca_abono_det
	      (abd_secuencial_ing,    abd_operacion,         abd_tipo,            
	       abd_concepto ,         abd_cuenta,            abd_beneficiario,    
	       abd_moneda,            abd_monto_mpg,         abd_monto_mop,         
	       abd_monto_mn,          abd_cotizacion_mpg,    abd_cotizacion_mop,
	       abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,          
	       abd_cod_banco,         abd_inscripcion,       abd_carga)
	      values(                                        
	       @w_secuencial_ing,     @w_operacion,        'PAG',               
	       'SALDOSMINI',         '0',                  'Pago por ORS. 490 sep292012',     
	       0,                     @w_debe,              @w_debe,          
	       @w_debe,           1,     1,
	       'C',                    'C',                  null,                
	       null,                  null,                  null)
	
	      if @@error <> 0
	       begin
	         PRint 'ATENCION!!! error Insertando en ca_abono_det'
	      end
	
	     insert into ca_abono_prioridad
	     select @w_secuencial_ing, @w_operacion, ro_concepto, ro_prioridad
	     from   ca_rubro_op
	     where  ro_operacion = @w_operacion
	     and    ro_fpago not in ('L','B')
	     
	     if @@error <> 0
	     begin
	        PRint 'ATENCION!!! error Insertando en ca_abono_prioridad'
	     end
        
      end

select @w_path = ba_path_destino 
from cobis..ba_batch 
where ba_arch_fuente = 'cob_cartera..sp_pagosMinimosVEn'

if @w_path is null
begin
select @w_path = 'F:\VBatch\Cartera\Listados\'
end

print  @w_path

select @w_s_app = pa_char 
from cobis..cl_parametro 
where pa_producto = 'ADM' 
and pa_nemonico = 'S_APP'

----------------------------------------
--Generar Archivo Plano
----------------------------------------
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_pagos_saldos_minimos_tmp out '
select @w_destino  = @w_path + 'PAG_SALDOSMINIMOS' + '_' + @w_fecha_plano + '.txt',
       @w_errores  = @w_path + 'PAG_SALDOSMINIMOS' + '_' + @w_fecha_plano + '.err'
select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e ' + @w_errores + ' -t'' ' + '-config '+ @w_s_app + 's_app.ini'

exec   @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error Generando archivo de PAG_SALDOSMINIMOS'
   print @w_comando 
end
   

return 0
   
go
