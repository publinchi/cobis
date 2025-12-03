/********************************************************************/
/*   NOMBRE LOGICO:      sp_utilidades.sp                           */
/*   NOMBRE FISICO:      sp_utilidades                              */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Kevin Rodríguez                            */
/*   FECHA DE ESCRITURA: Diciembre 2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                           PROPOSITO                              */
/*   Programa que obtiene o realiza operaciones varias              */ 
/*   N: Notificaciones                                              */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA          AUTOR          RAZON                             */
/*  05-Dic-2023    K. Rodriguez   Emision Inicial                   */
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_utilidades')
   drop proc sp_utilidades
go

create proc sp_utilidades
@i_operacion           char(1),
@i_opcion              tinyint,
@i_fecha               datetime = null,     -- Parametro genérico 
@o_fecha1              datetime = null out, -- Parámetro out genérico
@o_fecha2              datetime = null out  -- Parámetro out genérico

as
declare 
@w_sp_name            descripcion,
@w_error              int,
@w_fecha_envio        datetime,
@w_previous_datefirst tinyint,
@w_param_hora_ini     tinyint,
@w_param_hora_fin     tinyint,
@w_hora_inicio        datetime,
@w_hora_fin           datetime


-- Establecimiento de variables locales iniciales
select @w_sp_name   = 'sp_utilidades',
       @w_error     = 0

-- Notificaciones
if @i_operacion = 'N'
begin

   -- Establecer Fecha de envio notificacion
   if @i_opcion = 0
   begin
   
      select @w_fecha_envio        = @i_fecha,
	         @w_previous_datefirst = @@datefirst
			 
	  select @w_previous_datefirst = isnull(@w_previous_datefirst, 7)

      -- Establecer domingo como primer día de la semana
      set datefirst 7
      
	  -- Si la fecha viene con hora, minutos, segundos distintos de 12:00:00
	  select @w_fecha_envio = dateadd(hh, -datepart(hh, @w_fecha_envio), @w_fecha_envio)
      select @w_fecha_envio = dateadd(mi, -datepart(mi, @w_fecha_envio), @w_fecha_envio)
      select @w_fecha_envio = dateadd(ss, -datepart(ss, @w_fecha_envio), @w_fecha_envio)
  
	  -- Establecer día de envio de notificacion entre Lunes(1) a Viernes(6)
      while (select datepart(dw, @w_fecha_envio)) not between 2 and 6
      begin
         select @w_fecha_envio = dateadd(day, 1, @w_fecha_envio)
      end
	  
      -- Reestablecer valor datefirst
      set datefirst @w_previous_datefirst
	  
	  select @o_fecha1 = @w_fecha_envio
	  
   end
   
   -- Establecer horario de envio de notificacion
   if @i_opcion = 1
   begin
   
      -- Hora inicio para enviar notificacion
      select @w_param_hora_ini =  pa_tinyint
      from   cobis..cl_parametro
      where  pa_nemonico = 'HINIME'
      and    pa_producto = 'CCA'
      set transaction isolation level read uncommitted
      
      -- Hora fin (máxima) para enviar notificacion
      select @w_param_hora_fin =  pa_tinyint
      from   cobis..cl_parametro
      where  pa_nemonico = 'HFINME'
      and    pa_producto = 'CCA'
      set transaction isolation level read uncommitted
	  
      select @w_hora_inicio = dateadd(hh, isnull(@w_param_hora_ini, 08), @i_fecha),
             @w_hora_fin    = dateadd(hh, isnull(@w_param_hora_fin, 18), @i_fecha)
			 
      select @o_fecha1 = @w_hora_inicio,
	         @o_fecha2 = @w_hora_fin
   end

end

return 0

ERROR:
return @w_error
go
