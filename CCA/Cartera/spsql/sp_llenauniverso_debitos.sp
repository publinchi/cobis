/************************************************************************/
/*      Archivo:                sp_llenauniverso_debitos.sp             */
/*      Stored procedure:       sp_llenauniverso_debitos                */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sandro Vallejo                          */
/*      Fecha de escritura:     Ago. 2018                               */
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
/*      Llena la tabla de operaciones a procesar batch en paralelo.     */
/*      operaciones con debito automatico a la fecha de pago            */
/*      Se consideran todas las operaciones que procesan                */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*   01/Dec/2020  P.Narvaez    Tomar la fecha de cierre de Cartera      */
/************************************************************************/

use cob_cartera
go

/* INICIO SP */
if exists (select 1 from sysobjects where name = 'sp_llenauniverso_debito')
   drop proc sp_llenauniverso_debito
go

create procedure sp_llenauniverso_debito (
        @i_tipo              char(1)  = 'F', -- 'I=Intento en Linea  F=En Batch
        @i_sarta             int      = null,
        @i_batch             int      = null
        )
as
declare 
@w_sp_name         descripcion,
@w_fecha           datetime,
@w_est_vigente     tinyint,
@w_est_vencido     tinyint 

/* INICIALIZACION DE VARIABLES */
select 
@w_sp_name     = 'sp_llenauniverso_debito',
@w_est_vigente = 1,
@w_est_vencido = 2

/* SELECCIONAR LA FECHA DE PROCESO */
select @w_fecha = fc_fecha_cierre from cobis..ba_fecha_cierre
where fc_producto = 7


/* INICIALIZAR UNIVERSO DE DEBITOS */
truncate table ca_universo_debitos

/* CREAR TABLAS DE TRABAJO */
CREATE TABLE #universo (
op_operacion int,
op_banco     varchar(24))

BEGIN TRAN

-- SELECCIONAR UNIVERSO DE LAS OPERACIONES CON DEBITOS A PROCESAR ()
if @i_tipo = 'I'
begin
   insert into #universo
   select op_operacion,
          op_banco
   from   ca_operacion, ca_estado, ca_producto, ca_dividendo
   where  op_operacion         > 0
   and    op_estado            = es_codigo
   and    es_procesa           = 'S'
   and    op_operacion         = di_operacion
   and    op_fecha_ult_proceso = @w_fecha
   and    op_naturaleza        = 'A'
   and    op_forma_pago IS NOT NULL
   and    op_forma_pago        = cp_producto
   and    cp_pcobis           in (3,4)
   and    cp_pago_aut          = 'S'
   and   (di_estado            = @w_est_vencido or (di_estado = @w_est_vigente and di_fecha_ven = op_fecha_ult_proceso))
   group by op_operacion, op_banco
end   
else
begin
   insert into #universo
   select op_operacion,
          op_banco
   from   ca_operacion, ca_estado, ca_producto, ca_dividendo
   where  op_operacion          > 0
   and    op_estado             = es_codigo
   and    es_procesa            = 'S'
   and    op_operacion          = di_operacion
   and    op_fecha_ult_proceso <= @w_fecha
   and    op_naturaleza        = 'A'
   and    op_forma_pago IS NOT NULL
   and    op_forma_pago         = cp_producto
   and    cp_pcobis            in (3,4)
   and    cp_pago_aut           = 'S'
   and   (di_estado             = @w_est_vencido or (di_estado = @w_est_vigente and di_fecha_ven = op_fecha_ult_proceso))
   group by op_operacion, op_banco
end

-- SELECCIONAR LAS OPERACIONES DE INTERCICLOS
select op_operacion,
       op_banco
into   #interciclo
from   ca_operacion, ca_det_ciclo
where  op_operacion       = dc_operacion
and   (op_grupal          = 'N' or op_grupal is null)
and    op_ref_grupal IS NOT NULL
and    dc_tciclo          = 'I'

-- ELIMINAR DEL UNIVERSO LAS OPERACIONES DE INTERCICLOS
delete #universo
where  op_operacion in (select op_operacion from #interciclo)
   
-- INSERTAR EL UNIVERSO DE LAS OPERACIONES A PROCESAR 
insert into ca_universo_debitos (operacion, banco, intentos, hilo)
select op_operacion,
       op_banco,   
       0,   -- empezamos con intentos 0
       0    -- empezamos con hilo 0
from   #universo
order by op_operacion

COMMIT TRAN        
                             
return 0
go
