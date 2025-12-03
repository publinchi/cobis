/************************************************************************/
/*   NOMBRE LOGICO:      sp_cuotas_vencer.sp                            */            
/*   NOMBRE FISICO:      sp_cuotas_vencer                               */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Juan Carlos Guzman                             */
/*   FECHA DE ESCRITURA: 16/Nov/2022                                    */
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
/*                        PROPOSITO                                     */
/*  Envío de mensajes de texto a clientes los cuales tengan cuotas de   */
/*  préstamos próximas a vencer para recordarles.                       */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA          AUTOR             RAZON                              */
/*  16/Nov/2022    Juan C. Guzman    Emision Inicial                    */
/*  17/Mar/2022    Kevin Rodríguez   S795148 Ajuste envio notif. via SMS*/
/*  05/Nov/2023    Mariela Cabay     Control de telf vacíos para SMS    */
/*  05/Dic/2023    Kevin Rodríguez   R220842 Fecha y horario envio notif*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cuotas_vencer' and type = 'P')
    drop procedure sp_cuotas_vencer
go

create procedure sp_cuotas_vencer
(
   @i_param1    datetime,            --FECHA DE PROCESO
   @i_param2    char(1)    = 'N'     --VALIDAR FERIADOS 'S' o 'N'
)
as

declare @w_fecha_proceso      datetime,
        @w_valida_feriados    char(1),
        @w_ciudad_nal         int,
        @w_fecha_desde        datetime,
        @w_fecha_hasta        datetime,
        @w_fecha_habil        datetime,
        @w_num_cliente        int,
        @w_num_operacion      varchar(24),
        @w_num_cel            varchar(20),
        @w_error              int,
        @w_contenido_msg      varchar(200),
        @w_err_cursor         char(1),
        @w_mensaje            varchar(500),
        @w_retorno_ej         int,
		@w_fecha_envio        datetime,
		@w_hora_ini           datetime,
		@w_hora_fin           datetime
		

select @w_fecha_proceso    = @i_param1,
       @w_valida_feriados  = @i_param2,
       @w_err_cursor       = 'N',
       @w_retorno_ej       = 0

/* Tabla temporal */

if exists (select 1 from sysobjects where name = '#cuotas_por_vencer')
   drop table #cuotas_por_vencer
   
create table #cuotas_por_vencer(
   cv_cod_cliente     int          null,
   cv_num_operacion   varchar(24)  null,
   cv_num_celular     varchar(20)  null
)

-- Fecha proceso
select @w_fecha_proceso = isnull(@w_fecha_proceso, fp_fecha)
from cobis..ba_fecha_proceso

/* Parametros generales */

select @w_ciudad_nal = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

-- ** Establecer fecha y horario de envio

-- Establece siguiente día a la fecha proceso.
select @w_fecha_envio = dateadd(dd, 1, @w_fecha_proceso)

exec @w_error = sp_utilidades -- Fecha envio
@i_operacion = 'N',
@i_opcion    = 0,
@i_fecha     = @w_fecha_envio,
@o_fecha1    = @w_fecha_envio out 

if @w_error != 0
begin
   select @w_mensaje = 'Error en establecimiento de fecha de envío de notificación'
   goto ERROR
end

exec @w_error = sp_utilidades -- Rango de horario envio
@i_operacion = 'N',
@i_opcion    = 1,
@i_fecha     = @w_fecha_envio,
@o_fecha1    = @w_hora_ini out,
@o_fecha2    = @w_hora_fin out 

if @w_error != 0
begin
   select @w_mensaje = 'Error en establecimiento de horario de envío de notificación'
   goto ERROR
end

-- ** Fin fecha y horario de envio

select @w_fecha_desde = dateadd(day, 2, @w_fecha_proceso)

if @w_valida_feriados = 'N'
begin
   select @w_fecha_hasta = dateadd(day, 2, @w_fecha_proceso)
end
else
begin
   exec sp_dia_habil 
      @i_fecha  = @w_fecha_desde,
      @i_ciudad = @w_ciudad_nal,
      @o_fecha  = @w_fecha_habil out
      
   if @w_fecha_desde = @w_fecha_habil
   begin
      select @w_fecha_hasta = @w_fecha_habil
   end
   else
   begin
      select @w_fecha_hasta = dateadd(day, 1, @w_fecha_habil)
   end
end

insert into #cuotas_por_vencer
select ea_ente, 
       op_banco,
       ea_telef_recados
from ca_operacion,
     ca_dividendo,
     cobis..cl_ente_aux
where op_operacion = di_operacion
and   op_cliente = ea_ente
and   op_estado not in (0, 3, 99, 6, 4)
and   di_estado <> 3
and   di_fecha_ven between @w_fecha_desde and @w_fecha_hasta


declare cur_cuotas_vencer cursor
for select 
       cv_cod_cliente,
       cv_num_operacion,
       cv_num_celular
    from #cuotas_por_vencer

    open cur_cuotas_vencer
    fetch next from cur_cuotas_vencer into
       @w_num_cliente,
       @w_num_operacion,
       @w_num_cel
       
    while(@@fetch_status = 0)
    begin
       if (@@fetch_status = -1)
       begin
          select @w_error  = 710004
       
          close cur_cuotas_vencer    
          deallocate cur_cuotas_vencer
       
          goto ERROR
       end
       
       select @w_contenido_msg = 'Estimado(a) cliente, ENLACE le recuerda que su crédito ' + @w_num_operacion + ' está próximo a vencer.' +
                                 ' Haz puntual tu pago en nuestras agencias o colectores autorizados.'
       
       select @w_num_cel = trim(@w_num_cel)
       if @w_num_cel is not null and @w_num_cel != ''
		begin
		   exec @w_error = cobis..sp_despacho_ins
		   @i_cliente         = @w_num_cliente,
		   @i_template        = 0,                
		   @i_servicio        = 1,                
		   @i_estado          = 'P',
		   @i_tipo            = 'SMS',
		   @i_tipo_mensaje    = 'I',          
		   @i_prioridad       = 1,
		   @i_to              = @w_num_cel,                     
		   @i_subject         = 'NOTIFICACIÓN CUOTAS A VENCER',          
		   @i_body            = @w_contenido_msg,
		   @i_content_manager = 'TEXT',
		   @i_retry           = 'S',
		   @i_fecha_envio     = @w_fecha_envio,
           @i_hora_ini        = @w_hora_ini,
           @i_hora_fin        = @w_hora_fin,
		   @i_max_tries       = 2
		   
		   if @w_error != 0
		   begin
			  select @w_mensaje    = 'Error en ejecución de sp_despacho_ins',
					 @w_err_cursor = 'S'

			  goto ERROR
		   end
		end
       
       
       NEXT_LINE_CURSOR:
       fetch next from cur_cuotas_vencer into
          @w_num_cliente,
          @w_num_operacion,
          @w_num_cel
          
    end  --End While
    
close cur_cuotas_vencer    
deallocate cur_cuotas_vencer

return 0


ERROR:
   
   exec @w_retorno_ej = cobis..sp_ba_error_log
        @i_sarta      = 7002,
        @i_batch      = '',
        @i_secuencial = null,
        @i_corrida    = null,
        @i_intento    = null,
        @i_error      = @w_error,
        @i_detalle    = @w_mensaje   
        
   if @w_err_cursor = 'S'
   begin
      select @w_err_cursor = 'N'
   
      goto NEXT_LINE_CURSOR
   end 
   
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end
   
go
