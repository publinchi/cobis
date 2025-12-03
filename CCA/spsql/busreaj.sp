/***********************************************************************/
/*	Archivo:			           busopera.sp                    */
/*	Stored procedure:		     sp_buscar_op_reajuste          */
/*	Base de Datos:			     cob_cartera                    */
/*	Producto:			        Cartera	                       */
/*	Disenado por:			      P. Narvaez 		                */
/*	Fecha de Documentacion: 	21 de Julio/98                 */
/***********************************************************************/
/*			                    IMPORTANTE		       		         */
/*	Este programa es parte de los paquetes bancarios propiedad de  */ 	
/*	'MACOSA'.						                                    */
/*	Su uso no autorizado queda expresamente prohibido asi como     */
/*	cualquier autorizacion o agregado hecho por alguno de sus      */
/*	usuario sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante	            */
/***********************************************************************/  
/*			                     PROPOSITO				               */
/*	Similar al sp_buscar_operaciones pero para operaciones que po- */	
/*      sean el rubro a reajustarse                                    */
/***********************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_buscar_op_reajuste')
	drop proc sp_buscar_op_reajuste
go
---TIKET 167070 Mayo 2015
create proc sp_buscar_op_reajuste (
   @t_trn                  int		= NULL,
   @s_org                  char(1)      = NULL,
   @s_sesn                 int          = NULL,
   @s_user                 login        = NULL,
   @s_term                 varchar (30) = NULL,
   @s_date                 datetime     = NULL,
   @s_ofi                  smallint     = NULL,
   @s_ssn                  int          = null,
   @s_srv                  varchar (30) = null,
   @s_lsrv                 varchar (30) = null,
	@i_banco		cuenta = null,
	@i_tramite		int = null,
	@i_cliente		int = null,
	@i_oficina		int = null,
	@i_moneda		tinyint = null,
	@i_oficial		smallint = null,
	@i_fecha_ini		datetime = null,
	@i_toperacion		catalogo = null,
	@i_lin_credito		cuenta = null,
	@i_estado		descripcion = null,
        @i_migrada              cuenta  = null,
        @i_fecha_ini_hasta      datetime= null,
	@i_siguiente		int     = 0,
        @i_formato_fecha        int = null,
        @i_condicion_est        tinyint = null,
        @i_fecha_a_reajustar    datetime= null, --USADO PARA REAJUSTE MASIVO
        @i_concepto             catalogo,
        @i_referencial          catalogo = null,
        @i_signo                varchar(1)  = null,
        @i_factor               float    = null,
        @i_porcentaje           float    = null,
        @i_deseconomico	        catalogo = null,
        @i_tipo_puntos          varchar(1)  = null
)
as
declare
 	@w_sp_name	varchar(32),	
	@w_opcion	int,
        @w_error        int,
        @w_estado       int,
        @w_tasa_referencial     catalogo,
        @w_fecha_cartera        datetime,
        @w_fecha_tr             datetime,
        @w_valor_tasa_ref       float,
        @w_estado_op            smallint

	
/*  Captura nombre de Stored Procedure  */
select @w_sp_name = 'sp_buscar_op_reajuste'

   
/* BUSCAR OPCION DE BUSQUEDA */
select @w_opcion = 1000

if @i_deseconomico    is not null select @w_opcion = 13
if @i_fecha_ini_hasta is not null select @w_opcion = 12
if @i_moneda          is not null select @w_opcion = 11
if @i_fecha_ini       is not null select @w_opcion = 10
if @i_tramite         is not null select @w_opcion = 9
if @i_estado          is not null select @w_opcion = 8 
if @i_migrada         is not null select @w_opcion = 7
if @i_toperacion      is not null select @w_opcion = 6
if @i_oficina         is not null select @w_opcion = 5
if @i_oficial         is not null select @w_opcion = 4
if @i_cliente         is not null select @w_opcion = 3
if @i_toperacion      is not null select @w_opcion = 2   ---EPB:feb-27-2002 cambio tramite por linea para busqueda
if @i_banco           is not null select @w_opcion = 1

if @w_opcion > 5 begin
   select @w_error  = 708199
   goto ERROR
end

if @i_banco is not null
begin

   select @w_estado_op = op_estado
   from ca_operacion
   where op_banco = @i_banco
   
   if @w_estado_op = 4
   begin
      select @w_error  = 701010
      goto ERROR  
   end
  
end


/* CONVERTIR EL ESTADO DESCRIPCION A ESTADO NUMERO */
if @i_estado is not null
   select @w_estado = es_codigo
   from ca_estado
   where es_descripcion = @i_estado

/* CREAR TABLA TEMPORAL */
select
op_operacion,   op_moneda,  op_fecha_ini,
op_lin_credito, op_estado,  op_migrada,
op_toperacion , op_oficina, op_oficial,
op_cliente    , op_tramite, op_banco, 
op_fecha_reajuste, op_tipo, op_reajuste_especial,
op_reajustable, op_monto,   op_monto_aprobado,
op_anterior,    op_fecha_ult_proceso, op_destino
into #operaciones
from ca_operacion
where 1 = 2


/* BUSQUEDAS DE NUMERO DE OPERACIONES */

if @w_opcion = 1 

   insert into #operaciones
   select 
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste, op_tipo, isnull(op_reajuste_especial,'N'),
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_destino
   from ca_operacion 
   where op_banco = @i_banco

if @w_opcion = 2 

   insert into #operaciones
   select
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste, op_tipo, isnull(op_reajuste_especial,'N'),
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_destino
   from ca_operacion
   where op_toperacion = @i_toperacion  

if @w_opcion = 3 

   insert into #operaciones
   select
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste, op_tipo, isnull(op_reajuste_especial,'N'),
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_destino
   from ca_operacion
   where op_cliente = @i_cliente


if @w_opcion = 4

   insert into #operaciones
   select
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste,op_tipo,  isnull(op_reajuste_especial,'N'),
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_destino
   from ca_operacion
   where op_oficial = @i_oficial


if @w_opcion = 5

   insert into #operaciones
   select
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste,op_tipo,  isnull(op_reajuste_especial,'N'),
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_destino
   from ca_operacion
   where op_oficina = @i_oficina


/* RETORNAR DATOS A FRONT END */
select 
'Lin.Credito'  = substring(B.op_toperacion,1,5),
Moneda         = B.op_moneda,
'No.Operacion' = substring(B.op_banco,1,20),
Monto          = B.op_monto,
Cliente        = substring(B.op_nombre,1,30),
Concesion      = convert(varchar(10),B.op_fecha_ini, @i_formato_fecha),
Vencimiento    = convert(varchar(10),B.op_fecha_fin, @i_formato_fecha),
Oficial        = B.op_oficial,
Oficina        = B.op_oficina,
'Cup.Credito'  = B.op_lin_credito,
'Op.Migrada'   = substring(B.op_migrada,1,20),
'Op.Anterior'  = substring(B.op_anterior,1,20),
Estado         = substring(es_descripcion,1,20), 
Tramite        = convert(varchar(13),B.op_tramite),
'Cod.Cli'      = B.op_cliente,
Secuencial     = B.op_operacion,
'Reaj.Especial' = isnull(B.op_reajuste_especial,'N'),
'Destino Econo' = B.op_destino

from ca_operacion B , ca_estado, #operaciones A, ca_rubro_op
where B.op_operacion = A.op_operacion
and  A.op_operacion    = ro_operacion
and  (A.op_moneda      = @i_moneda      or @i_moneda      is null)
and  ((A.op_fecha_ini   >= @i_fecha_ini and  A.op_fecha_ini <= @i_fecha_ini_hasta)  or (@i_fecha_ini is null and @i_fecha_ini_hasta is null)) ---EPB:feb-27-2002  Quitar esta linea
and  (A.op_toperacion = @i_toperacion or @i_toperacion is null)
and  (A.op_estado      = @w_estado      or @w_estado      is null)
and  (A.op_migrada     = @i_migrada     or @i_migrada     is null)
and  (A.op_oficina     = @i_oficina     or @i_oficina     is null)
and  (A.op_oficial     = @i_oficial     or @i_oficial     is null)
and  (A.op_cliente     = @i_cliente     or @i_cliente     is null)
and  (A.op_tramite     = @i_tramite     or @i_tramite     is null)
and  (A.op_banco       = @i_banco       or @i_banco       is null) 
and  (A.op_estado      = 0              or @i_condicion_est <> 1  ) 
and  (A.op_estado      <> 0             or @i_condicion_est <> 2  ) 
and  (A.op_tipo        <> 'R'           or @i_condicion_est <> 3  )
and ((A.op_estado      <> 0  and
      @i_fecha_a_reajustar>=A.op_fecha_ult_proceso and 
      ro_concepto      = @i_concepto)
      or @i_condicion_est <> 4) 
and ((A.op_monto < A.op_monto_aprobado and A.op_estado <> 0 and 
      A.op_estado <> 2 and A.op_estado <> 3) or @i_condicion_est <> 5) 
and ((A.op_anterior is not null and A.op_estado = 0) or @i_condicion_est <> 6)
and   B.op_estado = es_codigo
and   es_codigo not in (98,99,3,6,4,0,2) -- Menos Operaciones no aptas para reajuste  EPB:mar-05-2002
and  (A.op_destino  = @i_deseconomico or @i_deseconomico is null)
and   B.op_operacion > @i_siguiente
order by B.op_operacion

if @@rowcount = 0 begin
   select @w_error = 1
   goto ERROR
end

return 0

ERROR:
if @w_error = 1 print '  ---> Final de La Consulta '
else 
begin
   if @w_error = 701010
     PRINT 'ATENCION Operacion en estado CASTIGADO no permite cambio de tasa'
   else  
    print 'Ingrese al menos un criterio de busqueda principal'
end
return 1 

go

