/************************************************************************/
/*  Archivo:              caprocecastmas.sp                             */
/*  Stored procedure:     sp_procesa_castigo_masivo                     */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         William Lopez                                 */
/*  Fecha de escritura:   23/Ene/2023                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCORP.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCORP para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  Procesa las operaciones para aplicar castigo masivo                 */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR                   RAZON                         */
/*  23/Ene/2023   William Lopez           Emision Inicial               */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_procesa_castigo_masivo' and type = 'P')
    drop procedure sp_procesa_castigo_masivo
go

create procedure sp_procesa_castigo_masivo
(
   @t_debug     char(1)      = 'N',
   @s_culture   varchar(10)  = 'NEUTRAL',
   @s_ssn       int          = null,
   @s_date      datetime     = null,
   @s_user      login        = 'opebatch',
   @s_term      descripcion  = 'TERM BATCH',
   @s_ofi       smallint     = null,
   @i_param1    datetime     --Fecha proceso
)
as 
declare
   @w_sp_name                 varchar(65),
   @w_return                  int,
   @w_retorno_ej              int,
   @w_error                   int,
   @w_fecha_proc              datetime,
   @w_path_destino            varchar(255),
   @w_mensaje                 varchar(1000),
   @w_mensaje_err             varchar(255),
   @w_sarta                   int,
   @w_batch                   int,
   @w_fecha_cierre            datetime,
   @w_cod_prod_cca            int,
   @w_secuencial              int      = null,
   @w_corrida                 int      = null,
   @w_intento                 int      = null,
   @w_est_vigente             smallint,
   @w_est_novigente           smallint,
   @w_est_credito             smallint,
   @w_est_cancelado           smallint,
   @w_est_anulado             smallint,
   @w_est_castigado           smallint,
   @w_est_vencido             smallint,
   @w_op_operacion            int,
   @w_op_toperacion           catalogo,
   @w_op_cliente              int,
   @w_op_estado               tinyint,
   @w_op_fecha_ini            datetime,
   @w_op_fecha_ult_proc       datetime,
   @w_cem_fecha_proceso       datetime,
   @w_cem_op_banco            cuenta,
   @w_cem_fecha_valor         datetime,
   @w_cem_estado_final_op     tinyint,
   @w_msg                     varchar(100)

select @w_sp_name           = 'sp_procesa_castigo_masivo',
       @w_error             = 0,
       @w_return            = 0,
       @w_path_destino      = '',
       @w_mensaje           = '',
       @w_mensaje_err       = null,
       @w_fecha_proc        = @i_param1

select @w_path_destino = ba_path_destino
from   cobis..ba_batch
where  ba_producto    = 7
and    ba_arch_fuente = 'cob_cartera..sp_procesa_castigo_masivo'

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from   cobis..ba_log,
       cobis..ba_batch
where  ba_arch_fuente like '%sp_procesa_castigo_masivo%'
and    lo_batch   = ba_batch
and    lo_estatus = 'E'

exec cobis..sp_ad_establece_cultura
   @o_culture = @s_culture out

-- Código de producto CCA
select @w_cod_prod_cca = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'

-- Fecha de Proceso
select @w_fecha_cierre = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = @w_cod_prod_cca

if @w_fecha_proc in (null,'')
   select @w_fecha_proc = @w_fecha_cierre

--Estados de Cartera
exec @w_return = sp_estados_cca
   @o_est_vigente   = @w_est_vigente   out, --1
   @o_est_novigente = @w_est_novigente out, --0
   @o_est_cancelado = @w_est_cancelado out, --3
   @o_est_credito   = @w_est_credito   out, --99
   @o_est_anulado   = @w_est_anulado   out, --6
   @o_est_castigado = @w_est_castigado out, --4
   @o_est_vencido   = @w_est_vencido   out  --2

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin

   exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = '',
      @t_from  = @w_sp_name,
      @i_num   = @w_return

   return @w_return
end   

--cursor para leer todas las operaciones a castigar masivamente
declare cur_proc_op_castigo_masivo cursor for
   select cem_fecha_proceso,      cem_op_banco,      cem_fecha_valor,      cem_estado_final_op
   from   ca_cambio_estado_masivo
   where  cem_fecha_proceso = @w_fecha_proc
   and    cem_estado_registro in ('I','E')

   open cur_proc_op_castigo_masivo   
   fetch next from cur_proc_op_castigo_masivo into
          @w_cem_fecha_proceso,   @w_cem_op_banco,   @w_cem_fecha_valor,   @w_cem_estado_final_op

   while (@@fetch_status = 0)
   begin
      if (@@fetch_status = -1)
      begin
         select @w_error = 710004

         close cur_saldos_operaciones
         deallocate cur_saldos_operaciones

         exec cobis..sp_cerror
             @t_debug = 'N',
             @t_file  = '',
             @t_from  = @w_sp_name,
             @i_num   = @w_error

         return @w_error
      end

      --iniciar variables
      select @w_op_operacion      = null,
             @w_op_toperacion     = '',
             @w_error             = 0,
             @w_return            = 0,
             @w_op_cliente        = null,
             @w_op_estado         = null,
             @w_op_fecha_ini      = null,
             @w_op_fecha_ult_proc = null,
             @w_mensaje           = '',
             @w_mensaje_err       = '',
             @s_ofi               = null

      --Obtener informacion de prestamo
      select @w_op_operacion        = op_operacion,
             @w_op_toperacion       = op_toperacion,
             @w_op_cliente          = op_cliente,
             @w_op_estado           = op_estado,
             @w_op_fecha_ini        = op_fecha_ini,
             @w_op_fecha_ult_proc   = op_fecha_ult_proceso,
             @s_ofi                 = op_oficina
      from   cob_cartera..ca_operacion
      where  op_banco = @w_cem_op_banco

      if @@rowcount = 0
      begin
         select @w_error       = 725054,  --No existe la operación
                @w_mensaje     = 'No existe la operación'

         goto ERROR_PROC
      end

      if @w_op_fecha_ult_proc > @w_fecha_proc
      begin
         select @w_error       = 725256, --FECHA DE ULTIMO PROCESO DE LA OPERACIÓN ES MAYOR A LA FECHA DE PROCESO DE CASTIGO MASIVO
                @w_mensaje     = 'FECHA DE ULTIMO PROCESO DE LA OPERACIÓN ES MAYOR A LA FECHA DE PROCESO DE CASTIGO MASIVO'

         goto ERROR_PROC
      end

      --Fecha valor
      if @w_cem_fecha_valor != @w_op_fecha_ult_proc
      begin

         exec @s_ssn = ADMIN...rp_ssn

         exec @w_return = sp_fecha_valor
            @s_ssn         = @s_ssn,
            @s_date        = @w_fecha_proc,
            @s_user        = @s_user,
            @s_term        = @s_term,
            @i_fecha_valor = @w_cem_fecha_valor,
            @i_banco       = @w_cem_op_banco,
            @i_operacion   = 'F',
            @i_en_linea    = 'N'

         if @w_return != 0
         begin
            select @w_error  = @w_return,
                   @w_return = 0
            goto ERROR_PROC
         end

      end

      --Cambio de estado manual a castigado

      exec @w_return = sp_cambio_estado_op
         @s_user          = @s_user,
         @s_term          = @s_term,
         @s_date          = @w_fecha_proc,
         @s_ofi           = @s_ofi,
         @i_banco         = @w_cem_op_banco,
         @i_fecha_proceso = @w_op_fecha_ult_proc,
         @i_estado_ini    = @w_op_estado,
         @i_estado_fin    = @w_cem_estado_final_op,
         @i_tipo_cambio   = 'M',   --Manual
         @i_en_linea      = 'N',
         @o_msg           = @w_msg out

      if @w_return != 0
      begin
         select @w_error  = @w_return,
                @w_return = 0
         goto ERROR_PROC
      end

      begin tran

      --Modificacion de registro a Procesado(P)
      if @w_error = 0
      begin
         update ca_cambio_estado_masivo
         set    cem_estado_registro = 'P',
                cem_codigo_error    = null
         where  cem_op_banco = @w_cem_op_banco

         select @w_error = @@error
         if @w_error != 0
         begin
            select @w_mensaje = 'Error al modificar cem_estado_registro tabla ca_cambio_estado_masivo',
                   @w_return  = @w_error

            goto ERROR
         end

      end

      commit tran

      NEXT_LINE_CURSOR:
         fetch next from cur_proc_op_castigo_masivo into
          @w_cem_fecha_proceso,   @w_cem_op_banco,   @w_cem_fecha_valor,   @w_cem_estado_final_op
   end--fin de while

close cur_proc_op_castigo_masivo    
deallocate cur_proc_op_castigo_masivo

return @w_return

ERROR_PROC:

   select @w_mensaje_err = re_valor
   from   cobis..cl_errores inner join cobis..ad_error_i18n 
                            on (numero = pc_codigo_int
                            and re_cultura like '%'+@s_culture+'%')
   where  numero = @w_error

   select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)

   update ca_cambio_estado_masivo
   set    cem_estado_registro = 'E',
          cem_codigo_error    = @w_error
   where  cem_op_banco = @w_cem_op_banco

   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al modificar cem_codigo_error tabla ca_cambio_estado_masivo',
             @w_return  = @w_error

      goto ERROR
   end

   goto NEXT_LINE_CURSOR

ERROR:
   close cur_proc_op_castigo_masivo
   deallocate cur_proc_op_castigo_masivo

   while @@trancount > 0
      rollback tran

   select @w_mensaje_err = re_valor
   from   cobis..cl_errores inner join cobis..ad_error_i18n 
                            on (numero = pc_codigo_int
                            and re_cultura like '%'+@s_culture+'%')
   where  numero = @w_error

   select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)

   exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = null,
      @t_from  = @w_sp_name,
      @i_num   = @w_error

   return @w_error
go
