/************************************************************************/
/*      Archivo:                ca_venta_inh.sp                         */
/*      Stored procedure:       sp_venta_inh                            */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Fecha de escritura:     Noviembre 2013                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/* Listas Inhibitorias                                                  */ 
/************************************************************************/
/*                              CAMBIOS                                 */
/*  FECHA     AUTOR             RAZON                                   */
/*  21-11-13  L.Guzman          Emisión Inicial - Req: Venta Cartera    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_venta_inh')
   drop proc sp_venta_inh
go

create proc sp_venta_inh

as
declare @w_consecutivo   int,
        @w_max           int,
        @w_fecha_proceso datetime,
        @w_msg           varchar(255),
        @w_error         int,
        @w_sp_name       varchar(32)

set nocount on

select @w_sp_name = 'sp_venta_inh'

select @w_consecutivo = 0

select @w_consecutivo = isnull(siguiente,0)
from cobis..cl_seqnos 
where tabla = 'cl_refinh'

if @@rowcount = 0
begin
   select @w_msg = 'Error al leer consecutivo en cl_seqnos de cl_refinh',
          @w_error = 801085
   goto ERROR
end

-- OBTIENE FECHA DE PROCESO
select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

if @@rowcount = 0
begin
   select @w_msg = 'Error al leer fecha de proceso de cartera',
          @w_error = 801085
   goto ERROR
end

select distinct
'secuencial'                     = 0, 
'documento'                      = null,      
'identificacion'                 = en_ced_ruc,
'nombre'                         = en_nombre,                             
'fecha_ref'                      = @w_fecha_proceso, 
'origen'                         = '004',
'observacion'                    = 'VENTA CARTERA CASTIGADA',             
'fecha_mod'                      = GETDATE(),        
'subtipo'                        = en_subtipo,
'p_apellido'                     = p_p_apellido,                          
's_apellido'                     = p_s_apellido,     
'tipo_ced'                       = en_tipo_ced,
'nom_lar'                        = en_nomlar,                             
'estado'                         = '007',            
'sexo'                           = p_sexo,
'operador'                       = 'Operador',
'aka'                            = null,            
'categoria'                      = null,
'subcategoria'                   = null,                        
'fuente'                         = null,         
'otroid'                         = null,
'pasaporte'                      = null,                           
'concepto'                       = null,       
'entid'                          = null
into #clientes_inh
from cobis..cl_ente, cob_cartera..ca_venta_universo
where Id_cliente = en_ced_ruc

if @@rowcount = 0
begin
   select @w_msg = 'Error al insertar clientes inhibitorios',
          @w_error = 708154
   goto ERROR
end

delete #clientes_inh
from cobis..cl_refinh
where in_origen  = '004'
and   in_estado  = '007'
and   in_ced_ruc = identificacion

if @@error <> 0
begin
   select @w_msg   = 'Error al eliminar clientes inhibitorios en tmp',
          @w_error = 708155
   goto ERROR
end

update #clientes_inh set 
secuencial     = @w_consecutivo,
@w_consecutivo = @w_consecutivo + 1

insert into cobis..cl_refinh(
in_codigo,       in_documento,      in_ced_ruc,
in_nombre,       in_fecha_ref,      in_origen,
in_observacion,  in_fecha_mod,      in_subtipo,
in_p_p_apellido, in_p_s_apellido,   in_tipo_ced,
in_nomlar,       in_estado,         in_sexo,
in_usuario,      in_aka,            in_categoria,
in_subcategoria, in_fuente,         in_otroid,
in_pasaporte,    in_concepto,       in_entid)
select 
secuencial,      documento,     identificacion,
nombre,          fecha_ref,     origen,
observacion,     fecha_mod,     subtipo,
p_apellido,      s_apellido,    tipo_ced,
nom_lar,         estado,        sexo,
operador,        aka,           categoria,
subcategoria,    fuente,        otroid,
pasaporte,       concepto,      entid
from #clientes_inh

if @@error <> 0
begin
   select @w_msg = 'Error al insertar en cl_refinh ',
          @w_error = 708154
   goto ERROR
end

select @w_max = MAX(in_codigo) from cobis..cl_refinh

update cobis..cl_seqnos set
siguiente = @w_max 
where tabla = 'cl_refinh'

if @@error <> 0
begin
   select @w_msg = 'Error al actualizar consecutivo de cl_seqnos.cl_refinh',
          @w_error = 708152
   goto ERROR
end

return 0

ERROR:

exec cob_cartera..sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = @w_error, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return @w_error
go
