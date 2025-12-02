/************************************************************************/
/*   NOMBRE LOGICO:      trasophis.sp                                   */            
/*   NOMBRE FISICO:      sp_traslado_op_historicos                      */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Kevin Rodríguez                                */
/*   FECHA DE ESCRITURA: Marzo 2023                                     */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Programa de depuración de base de datos principal de cartera. La   */
/*   depuración consiste en trasladar las operaciones canceladas a la   */
/*   base de datos histórica de cartera                                 */
/*                                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*   FECHA       AUTOR             RAZON                                */
/* 20/Mar/2023   Kevin Rodríguez   Version inicial                      */
/* 18/Ene/2024   Kevin Rodríguez   R224034 Correccion orden parametros  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_traslado_op_historicos')
   drop proc sp_traslado_op_historicos
go

create proc sp_traslado_op_historicos (
@i_param1   datetime = null, -- Fecha proceso
@i_param2   char(1)          -- Operación (T: Traslado OPs canceladas a históricos)

)

as declare
@w_sp_name              varchar(30),
@w_error                int,
@w_error_index          int,
@w_accion               char(1),
@w_index_delete         char(1),
@w_fecha_proceso        datetime,
@w_est_cancelado        tinyint,
@w_descripcionErr       varchar(255),
@w_descripcionErrIndex  varchar(255),
@w_dias_paso_op_cancel  smallint,
@w_commit               char(1)


declare @exclude_opergrp table (oper_padre VARCHAR(24))

---  VARIABLES DE TRABAJO  
select  
@w_sp_name       = 'sp_traslado_op_historicos',
@w_index_delete  = 'N',
@w_commit        = 'N'

select @w_accion = @i_param2

if @i_param1 is null
   select @w_fecha_proceso = fc_fecha_cierre 
   from cobis..ba_fecha_cierre 
   where fc_producto = 7
else
   select @w_fecha_proceso = @i_param1

-- Estados de Cartera
exec @w_error = sp_estados_cca 
@o_est_cancelado   = @w_est_cancelado  out

if @w_error <> 0
begin 
   select @w_descripcionErr = 'Traslado Operaciones a históricos: Error obteniendo estados de cartera'
   goto ERROR_BATCH
end
   
select @w_dias_paso_op_cancel = pa_smallint 
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA' 
and pa_nemonico in ('DIPAHI')

if @w_dias_paso_op_cancel is null
begin
   select @w_descripcionErr = 'Traslado Operaciones a históricos: Error obteniendo parámetro DIPAHI'
   goto ERROR_BATCH
end


if @w_accion = 'T' -- Traslado de operaciones canceladas a históricos
begin

   IF OBJECT_ID ('dbo.#ops_canceladas') IS NOT NULL
      DROP TABLE dbo.#ops_canceladas
   
   -- 1. Preparación de Tabla temporal con el universo de OPs a ser trasladadas
   
   -- Operaciones canceladas (Individuales y Grupales Hijas)
   select distinct(tr_operacion) as 'operacion',    
          max(tr_secuencial)     as 'secuencial',
          op_grupal              as 'grupal',
          op_ref_grupal          as 'ref_grupal',
          'P'                    as 'estado'       -- (P)Pendiente,(N)No aplica, (T)Traslado con éxito   		  
   into #ops_canceladas
   from ca_operacion with (nolock), ca_transaccion with (nolock) 
   where op_operacion = tr_operacion
   and op_estado = @w_est_cancelado
   and ((op_grupal = 'N' or op_grupal is null) 
       or (op_grupal = 'S' and op_ref_grupal is not null))
   and tr_tran = 'PAG'
   and tr_estado <> 'RV'
   group by tr_operacion, op_grupal, op_ref_grupal
   order by tr_operacion
   
   -- Operaciones grupales que aun tiene OPs hijas activas o que una o más OPs 
   -- hijas no cumple el mínimo de días de cancelación para realizar el traslado 
   insert into @exclude_opergrp
   select op_ref_grupal from ca_operacion with (nolock), #ops_canceladas 
   where op_ref_grupal = ref_grupal 
   and op_estado not in (@w_est_cancelado)
   union                      
   select op_ref_grupal from ca_operacion with (nolock), ca_transaccion with (nolock), #ops_canceladas
   where op_ref_grupal = ref_grupal 
   and op_operacion = operacion 
   and tr_operacion = op_operacion
   and tr_secuencial = secuencial 
   and datediff(dd, tr_fecha_mov, @w_fecha_proceso) < @w_dias_paso_op_cancel
   
   -- Eliminación OPs  que no cumplen requisitos de traslado
   delete #ops_canceladas   
   where ref_grupal in (SELECT oper_padre FROM @exclude_opergrp)
   or not exists (select 1 from ca_transaccion with (nolock) 
                 where tr_operacion = operacion
                 and tr_secuencial = secuencial
                 and datediff(dd, tr_fecha_mov, @w_fecha_proceso) > @w_dias_paso_op_cancel)
				 
   -- Inserción de operaciones Padres
   insert into #ops_canceladas
   select op_operacion, 0, 'S', null, 'P'
   from #ops_canceladas, ca_operacion
   where op_banco = ref_grupal 
   and ref_grupal is not null
   group by op_operacion, ref_grupal
   
 
   -- 2. Prepara tablas destino (base históricos)
     
   -- Eliminación de indices tablas cob_cartera_his
   exec @w_error = cob_cartera_his..sp_crea_elimina_indices
   @i_operacion = 'E'
   
   if @w_error <> 0
   begin
      select @w_descripcionErr = 'Traslado Operaciones a históricos: Error al preparar tablas para históricos (elimina índices)'
      goto ERROR_BATCH
   end	  
   else
      select @w_index_delete = 'S'

   
   -- 3. Traslado de información a históricos.
   
   begin tran
   
   -- Inserción de registros a tablas históricas
   
   -- ca_operacion
   insert into cob_cartera_his..ca_operacion
   select ca_operacion.* 
   from ca_operacion, #ops_canceladas
   where op_operacion = operacion
   
   if @@error != 0 
   begin     
      select @w_commit = 'S'   
      select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_operacion'
      goto ERROR_BATCH
   end
   
   -- ca_rubro_op
   insert into cob_cartera_his..ca_rubro_op
   select ca_rubro_op.* 
   from ca_rubro_op, #ops_canceladas
   where ro_operacion = operacion
   
   if @@error != 0 
   begin
      select @w_commit = 'S'   
      select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_rubro_op'
      goto ERROR_BATCH
   end
   
   -- ca_dividendo
   insert into cob_cartera_his..ca_dividendo
   select ca_dividendo.* 
   from ca_dividendo, #ops_canceladas
   where di_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_dividendo'
      goto ERROR_BATCH
   end
   
   -- ca_amortizacion
   insert into cob_cartera_his..ca_amortizacion
   select ca_amortizacion.* 
   from ca_amortizacion, #ops_canceladas
   where am_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_amortizacion'
      goto ERROR_BATCH
   end
   
   -- ca_cuota_adicional 
   insert into cob_cartera_his..ca_cuota_adicional 
   select ca_cuota_adicional .* 
   from ca_cuota_adicional , #ops_canceladas
   where ca_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_cuota_adicional '
      goto ERROR_BATCH
   end
   
   -- ca_tasas
   insert into cob_cartera_his..ca_tasas
   select ca_tasas.* 
   from ca_tasas, #ops_canceladas
   where ts_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_tasas'
      goto ERROR_BATCH
   end
   
   -- ca_transaccion
   insert into cob_cartera_his..ca_transaccion
   select ca_transaccion.* 
   from ca_transaccion, #ops_canceladas
   where tr_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_transaccion'
      goto ERROR_BATCH
   end
   
   -- ca_det_trn
   insert into cob_cartera_his..ca_det_trn
   select ca_det_trn.* 
   from ca_det_trn, #ops_canceladas
   where dtr_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_det_trn'
      goto ERROR_BATCH
   end
   
   -- ca_transaccion_prv
   insert into cob_cartera_his..ca_transaccion_prv
   select ca_transaccion_prv.* 
   from ca_transaccion_prv, #ops_canceladas
   where tp_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_transaccion_prv'
      goto ERROR_BATCH
   end
   
   -- ca_operacion_datos_adicionales
   insert into cob_cartera_his..ca_operacion_datos_adicionales
   select ca_operacion_datos_adicionales.* 
   from ca_operacion_datos_adicionales, #ops_canceladas
   where oda_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_operacion_datos_adicionales'
      goto ERROR_BATCH
   end
   
   -- ca_abono
   insert into cob_cartera_his..ca_abono
   select ca_abono.* 
   from ca_abono, #ops_canceladas
   where ab_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_abono'
      goto ERROR_BATCH
   end
   
   -- ca_abono_det
   insert into cob_cartera_his..ca_abono_det
   select ca_abono_det.* 
   from ca_abono_det, #ops_canceladas
   where abd_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_abono_det'
      goto ERROR_BATCH
   end
   
   -- ca_otro_cargo
   insert into cob_cartera_his..ca_otro_cargo
   select ca_otro_cargo.* 
   from ca_otro_cargo, #ops_canceladas
   where oc_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_otro_cargo'
      goto ERROR_BATCH
   end
   
   -- ca_operacion_his
   insert into cob_cartera_his..ca_operacion_his
   select ca_operacion_his.* 
   from ca_operacion_his, #ops_canceladas
   where oph_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_operacion_his'
      goto ERROR_BATCH
   end
   
   -- ca_rubro_op_his
   insert into cob_cartera_his..ca_rubro_op_his
   select ca_rubro_op_his.* 
   from ca_rubro_op_his, #ops_canceladas
   where roh_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_rubro_op_his'
      goto ERROR_BATCH
   end
   
   -- ca_amortizacion_his
   insert into cob_cartera_his..ca_amortizacion_his
   select ca_amortizacion_his.* 
   from ca_amortizacion_his, #ops_canceladas
   where amh_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_amortizacion_his'
      goto ERROR_BATCH
   end
   
   -- ca_dividendo_his
   insert into cob_cartera_his..ca_dividendo_his
   select ca_dividendo_his.* 
   from ca_dividendo_his, #ops_canceladas
   where dih_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_dividendo_his'
      goto ERROR_BATCH
   end
   
   -- ca_cuota_adicional_his
   insert into cob_cartera_his..ca_cuota_adicional_his
   select ca_cuota_adicional_his.* 
   from ca_cuota_adicional_his, #ops_canceladas
   where cah_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al insertar registros en ca_cuota_adicional_his'
      goto ERROR_BATCH
   end
   
   
   -- Eliminación de registros de tablas definitivas
      
   -- ca_operacion
   delete ca_operacion from #ops_canceladas where op_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_operacion'
      goto ERROR_BATCH
   end
   
   -- ca_rubro_op
   delete ca_rubro_op from #ops_canceladas where ro_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_rubro_op'
      goto ERROR_BATCH
   end
  
   -- ca_dividendo
   delete ca_dividendo from #ops_canceladas where di_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_dividendo'
      goto ERROR_BATCH
   end
   
   -- ca_amortizacion
   delete ca_amortizacion from #ops_canceladas where am_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_amortizacion'
      goto ERROR_BATCH
   end
   
   -- ca_cuota_adicional
   delete ca_cuota_adicional from #ops_canceladas where ca_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_cuota_adicional'
      goto ERROR_BATCH
   end
   
   -- ca_tasas
   delete ca_tasas from #ops_canceladas where ts_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_tasas'
      goto ERROR_BATCH
   end
   
   -- ca_transaccion
   delete ca_transaccion from #ops_canceladas where tr_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_transaccion'
      goto ERROR_BATCH
   end
   
   -- ca_det_trn
   delete ca_det_trn from #ops_canceladas where dtr_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_det_trn'
      goto ERROR_BATCH
   end
   
   -- ca_transaccion_prv
   delete ca_transaccion_prv from #ops_canceladas where tp_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_transaccion_prv'
      goto ERROR_BATCH
   end
   
   -- ca_operacion_datos_adicionales
   delete ca_operacion_datos_adicionales from #ops_canceladas where oda_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_operacion_datos_adicionales'
      goto ERROR_BATCH
   end
   
   -- ca_abono
   delete ca_abono from #ops_canceladas where ab_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_abono'
      goto ERROR_BATCH
   end
   
   -- ca_abono_det
   delete ca_abono_det from #ops_canceladas where abd_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_abono_det'
      goto ERROR_BATCH
   end
   
   -- ca_otro_cargo
   delete ca_otro_cargo from #ops_canceladas where oc_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_otro_cargo'
      goto ERROR_BATCH
   end
   
   -- ca_operacion_his
   delete ca_operacion_his from #ops_canceladas where oph_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_operacion_his'
      goto ERROR_BATCH
   end

   -- ca_rubro_op_his
   delete ca_rubro_op_his from #ops_canceladas where roh_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_rubro_op_his'
      goto ERROR_BATCH
   end
   
   -- ca_amortizacion_his
   delete ca_amortizacion_his from #ops_canceladas where amh_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_amortizacion_his'
      goto ERROR_BATCH
   end

   -- ca_dividendo_his
   delete ca_dividendo_his from #ops_canceladas where dih_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_dividendo_his'
      goto ERROR_BATCH
   end

   -- ca_cuota_adicional_his
   delete ca_cuota_adicional_his from #ops_canceladas where cah_operacion = operacion
   
   if @@error != 0 
   begin           
      select @w_commit = 'S'
	  select @w_descripcionErr = 'Traslado Operaciones históricos: Error al eliminar registros en ca_cuota_adicional_his'
      goto ERROR_BATCH
   end
   
   commit tran
   
   -- 4. Reestablece tablas destino (base históricos)
   if @w_index_delete = 'S'
   begin
      exec @w_error = cob_cartera_his..sp_crea_elimina_indices
      @i_operacion = 'C'
	  
      if @w_error <> 0
      begin
         select @w_descripcionErr = 'Traslado Operaciones canceladas a históricos: Error al preparar tablas para históricos (crea índices)'
         goto ERROR_BATCH
      end	  
      else
         select @w_index_delete = 'N'
   end
   
end


SALIR:
return 0

ERROR_BATCH: 

if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end
   
if @w_index_delete = 'S'
begin

   exec @w_error_index = cob_cartera_his..sp_crea_elimina_indices
   @i_operacion = 'C'
   
   if @w_error_index <> 0
   begin
      select @w_descripcionErrIndex = 'Traslado Operaciones canceladas a históricos: Error al preparar tablas para históricos (crea índices en sección ERROR)'
      insert into ca_errorlog (er_fecha_proc,    er_error,       er_usuario,  er_tran, er_cuenta,    er_descripcion )
                       values (@w_fecha_proceso, @w_error_index, 'ope-batch', 0,       '0000000000', isnull(@w_descripcionErrIndex,''))  
   end
end

insert into ca_errorlog (er_fecha_proc,    er_error,  er_usuario,  er_tran, er_cuenta,    er_descripcion )
                 values (@w_fecha_proceso, @w_error,  'ope-batch', 0,       '0000000000', isnull(@w_descripcionErr,''))
			 
return 0

GO

