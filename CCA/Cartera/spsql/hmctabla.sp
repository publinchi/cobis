/************************************************************************/
/*      Archivo:                hmctabla.sp                             */
/*      Stored procedure:       sp_consulta_tablas                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           P. Narvaez                              */
/*      Fecha de escritura:     17/12/1997                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      MACOSA                                                          */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Consulta de los datos de las tablas de una operacion creada.    */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_tablas')
	drop proc sp_consulta_tablas
go

create proc sp_consulta_tablas(

   @i_tabla                varchar(30),
   @i_num_oper             cuenta,
   @i_tipo_num             char(1),
   @i_siguiente            int = 0,  
   @i_fecha_ini	           datetime  = '04/17/2002',
   @i_fecha_fin	           datetime  = '04/17/2002',
   @i_siguiente1           catalogo = ''    
)as

declare 
   @w_error             int ,
   @w_tramite           int ,
   @w_sp_name           descripcion,
   @w_secuencial        int,
   @w_operacionca       int


/* VARIABLES INICIALES */
select @w_sp_name = 'sp_consulta_tablas'

/*TIPO DE NUMERO DE OPERACION BANCO(B), INTERNO(I) O TRAMITE(T)*/
if @i_tipo_num = 'B' 
   select @w_operacionca = op_operacion
   from ca_operacion
   where op_banco = @i_num_oper
else if @i_tipo_num = 'I'
   select @w_operacionca = convert(int,@i_num_oper)
else if @i_tipo_num = 'T' 
   select @w_operacionca = op_operacion
   from ca_operacion
   where op_tramite =convert(int,@i_num_oper)

/*VERIFICAR QUE EXISTA LA OPERACION*/
if not exists(select 1 from ca_operacion
              where op_operacion = @w_operacionca)
begin   
   select @w_error = 710025 
   goto ERROR
end
      

/*SELECT DE LAS TABLAS DEFINITIVAS*/

if @i_tabla = 'ca_operacion_ts'  begin

select distinct
'Fecha Trn.'        = ltrim(convert(varchar(20),ops_fecha_ts)),
'Usuario'           = ltrim(ops_usuario_ts),
'Oficina Trn.'      = ops_oficina_ts,
'Terminal'          = ltrim(ops_terminal_ts),
'No. Tramite'       = ops_tramite,
'No. Operacion'     = ltrim(op_banco),
'Cliente'           = ops_cliente,
'Oficina Op.'       = ops_oficina,
'Estado'            = ltrim(es_descripcion),
'ACTUALIZACIONES'   = '-->',
'Destino'           = ltrim(ops_destino),
'Destino_F'         = ltrim(op_destino),
'Gerente'           = ops_oficial,
'Gerente-F'         = op_oficial,
'FPago'             = ltrim(ops_forma_pago),
'FPago-F'           = ltrim(op_forma_pago),
'Cuenta'            = ltrim(ops_cuenta),
'Cuenta-F'          = ltrim(op_cuenta),
'C.Complata'        = ltrim(ops_cuota_completa),
'C.Complata-F'      = ltrim(op_cuota_completa),
'Pag. A/P'          = ltrim(ops_tipo_cobro),
'Pag. A/P-F'        = ltrim(op_tipo_cobro),
'Reduccion'         = ltrim(ops_tipo_reduccion),
'Reduccion-F'       = ltrim(op_tipo_reduccion),
'Pag.caja'          = ltrim(ops_pago_caja),
'Pag.caja-F'        = ltrim(op_pago_caja),
'Aplicacion'        = ltrim(ops_tipo_aplicacion),
'Aplicacion-F'      = ltrim(op_tipo_aplicacion),
'TPlazo'            = ltrim(ops_tplazo),
'TPlazo-F'          = ltrim(op_tplazo),
'Plazo'             = ops_plazo,
'Plazo-F'           = op_plazo,
'Renovacion'        = ltrim(ops_renovacion),
'Renovacion-F'      = ltrim(op_renovacion),
'Precan'            = ltrim(ops_precancelacion),
'Precan-F'          = ltrim(op_precancelacion),
'Extracto'          = ltrim(ops_extracto),
'Extracto-F'        = ltrim(op_extracto),
'B.Virtual'         = ltrim(ops_bvirtual),
'Virtual-F'         = ltrim(op_bvirtual)
from  ca_operacion_ts,ca_estado,ca_operacion
where ops_fecha_proceso_ts >= @i_fecha_ini
and   ops_fecha_proceso_ts <= @i_fecha_fin
and   ops_operacion = @w_operacionca 
and   op_estado            = es_codigo
and   ops_operacion         = op_operacion
order by ops_oficina_ts, ltrim(op_banco), ltrim(convert(varchar(20),ops_fecha_ts))


---   select * from ca_operacion_ts
---   where ops_operacion = @w_operacionca 

end

if @i_tabla = 'ca_dividendo' 
   select * from ca_dividendo
   where di_operacion = @w_operacionca 
   and   di_dividendo > @i_siguiente

set rowcount 20 
if @i_tabla = 'ca_amortizacion'
   select * from ca_amortizacion
   where am_operacion = @w_operacionca 
   and (am_dividendo > @i_siguiente or 
       (am_dividendo = @i_siguiente and am_concepto > @i_siguiente1))
   order by am_operacion,am_dividendo,am_concepto
                        
set rowcount 0 

if @i_tabla = 'ca_rubro_op' 
   select * from ca_rubro_op
   where ro_operacion = @w_operacionca 

if @i_tabla = 'ca_cuota_adicional'
   select * from ca_cuota_adicional
   where ca_operacion = @w_operacionca
   and  ca_dividendo > @i_siguiente

if @i_tabla = 'ca_transaccion'
   select * from ca_transaccion
   where tr_operacion = @w_operacionca
   and   tr_secuencial > @i_siguiente

if @i_tabla = 'ca_det_trn' 
   select *
   from  ca_det_trn, ca_transaccion
   where tr_operacion  = @w_operacionca
   and   tr_secuencial = dtr_secuencial
   and   tr_operacion  = dtr_operacion
   and  ( dtr_secuencial > @i_siguiente or 
        (dtr_secuencial = @i_siguiente and dtr_concepto > @i_siguiente1))
   order by dtr_secuencial,dtr_concepto

if @i_tabla = 'ca_tasas'
   select * from ca_tasas
   where ts_operacion = @w_operacionca

/*SELECT DE LAS TABLAS TEMPORALES*/

if @i_tabla = 'ca_operacion_tmp'
   select * from ca_operacion_tmp
   where opt_operacion = @w_operacionca

if @i_tabla = 'ca_dividendo_tmp'
   select * from ca_dividendo_tmp
   where dit_operacion = @w_operacionca
   and   dit_dividendo > @i_siguiente

if @i_tabla = 'ca_amortizacion_tmp'
   select * from ca_amortizacion_tmp
   where amt_operacion = @w_operacionca
   and  ( amt_dividendo > @i_siguiente or 
        (amt_dividendo = @i_siguiente and amt_concepto > @i_siguiente1))

if @i_tabla = 'ca_rubro_op_tmp'
   select * from ca_rubro_op_tmp
   where rot_operacion = @w_operacionca

if @i_tabla = 'ca_cuota_adicional_tmp' 
   select * from ca_cuota_adicional_tmp
   where cat_operacion = @w_operacionca
   and  cat_dividendo > @i_siguiente

return 0


ERROR:

exec cobis..sp_cerror
@t_debug  ='N',           @t_file = null,
@t_from   = @w_sp_name,   @i_num  = @w_error
--@i_cuenta = ' '

return @w_error

go

