/************************************************************************/
/*      NOMBRE LOGICO:          sp_cambio_estado_anulado.sp             */
/*      NOMBRE FISICO:          sp_cambio_estado_anulado                */
/*      BasE DE DATOS:          cob_cartera                             */
/*      PRODUCTO:               Cartera                                 */
/*      DISENADO POR:           Kevin Rodríguez                         */
/*      FECHA DE ESCRITURA:     Agosto 2024                             */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Realiza el cambio de estado a Anulado (No genera transacción)      */
/*                                                                      */
/************************************************************************/
/*                               CAMBIOS                                */
/*  FECHA         AUTOR             CAMBIO                              */
/*  21-Ago-2024   Kevin Rodríguez   R240260 Emisión inicial             */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_anulado')
   drop proc sp_cambio_estado_anulado
go

create proc sp_cambio_estado_anulado(
   @s_user          login,
   @s_term          varchar(30),
   @i_operacionca   int
)as 

declare
@w_sp_name           varchar(64),
@w_error             int,   
@w_estado            tinyint,
@w_est_novigente     tinyint,   
@w_est_anulado       tinyint,
@w_fecha_proceso     datetime,
@w_banco             cuenta,
@w_grupal            char(1),
@w_ref_grupal        cuenta,
@w_tipo_grupal       char(1),
@w_completo          char(1),
@w_tot_no_vigente    smallint,
@w_tot_anuladas      smallint,
@w_tot_otro_estado   smallint

declare 
@operaciones table (operacion int, estado tinyint)

select 
@w_sp_name  = 'sp_cambio_estado_anulado',
@w_completo = 'S'

--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_anulado    = @w_est_anulado   out

if @w_error <> 0                
begin
	select @w_error = 710217 -- ERROR No existe estado
	goto ERROR
end

--FECHA DE PROCESO
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7
 
-- Datos de la operacion
select 
@w_banco      = op_banco,
@w_estado     = op_estado,
@w_grupal     = op_grupal,
@w_ref_grupal = op_ref_grupal
from ca_operacion  with (nolock)
where op_operacion = @i_operacionca

if @@rowcount = 0                
begin
	select @w_error = 701025 -- Operación no existe o Estado No acepta pagos
	goto ERROR
end 

-- Tipo Grupal (Padre o Hija)
if @w_grupal = 'S'
begin 
   if @w_ref_grupal is null
      select @w_tipo_grupal = 'G'
   else 
      select @w_tipo_grupal = 'H'
end
else
   select @w_tipo_grupal = 'N'

-- Validación de Estado No vigente operación base
if @w_estado not in (@w_est_novigente)
begin
   select @w_error = 725317 -- Error, la operación debe tener estado No Vigente
   goto ERROR
end

-- Validación de restricción de cambio de estado de OP hija
if @w_tipo_grupal = 'H'
begin
   select @w_error = 725321 -- Error, no se puede realizar esta acción a una operación grupal hija
   goto ERROR   
end

-- Ingreso Operaciónes para cambio de estado
insert into @operaciones (operacion, estado) values (@i_operacionca, @w_estado)

if @w_tipo_grupal = 'N'
   select @w_completo = 'S'


if @w_tipo_grupal = 'G' 
begin

   insert into @operaciones
   select op_operacion, op_estado
   from ca_operacion with (nolock) 
   where op_ref_grupal = @w_banco

   select @w_tot_no_vigente = count(1) from @operaciones where estado = @w_est_novigente
   select @w_tot_anuladas = count(1) from @operaciones where estado = @w_est_anulado
   select @w_tot_otro_estado = count(1) from @operaciones where estado not in (@w_est_novigente, @w_est_anulado)

   if isnull(@w_tot_otro_estado, 0) > 0
   begin
      select @w_error = 725318 -- Error, existen operaciones grupales hijas con estado distinto de No vigente o Anulado
	  goto ERROR
   end 

   if isnull(@w_tot_no_vigente, 0) = 0
   begin
      select @w_error = 725319 -- Error, no existen operaciones grupales hijas con estado No vigente
	  goto ERROR
   end 
   
   -- Elimina OPs hijas que no realizarán la anulación (Si fueron anuladas desde otro proceso)
   delete @operaciones where estado <> @w_est_novigente

   -- Establece si la anulación afectó a todas las OPs hijas o si ya existian anuladas
   if isnull(@w_tot_anuladas, 0) = 0
       select @w_completo = 'S'
   else
      select @w_completo = 'N'     
   
end

-- Cambio de Estado a Anulado
update ca_operacion with (rowlock)
set op_estado = @w_est_anulado
from @operaciones
where op_operacion = operacion

if @@error <> 0 
begin
   select @w_error = 705036 -- Error en actualizacion de Estado
   goto ERROR
end

-- Registro del cambio de la anulación.
insert into ca_op_anulacion 
(oa_user,      oa_fecha_proceso, oa_fecha_real, 
 oa_operacion, oa_completo)
select 
 @s_user,      @w_fecha_proceso, getdate(), 
 operacion,    @w_completo
from @operaciones

if @@error <> 0
begin
   select @w_error = 725320 -- Error al registrar el cambio de estado
   goto ERROR
end
    
return 0

ERROR:
   
return @w_error

go
