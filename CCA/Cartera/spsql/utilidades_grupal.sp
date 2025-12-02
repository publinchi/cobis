/********************************************************************/
/*   NOMBRE LOGICO:      utilidades_grupal.sp                       */
/*   NOMBRE FISICO:      sp_utilidades_grupal                       */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Kevin Rodríguez                            */
/*   FECHA DE ESCRITURA: Junio 2023                                 */
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
/*   Programa que obtiene información variada de un préstamo grupal */ 
/*   F: Consulta de fecha valor de préstamo grupal                  */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  28-Jun-2023    K. Rodriguez     Emision Inicial                 */
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_utilidades_grupal')
   drop proc sp_utilidades_grupal
go

create proc sp_utilidades_grupal
@s_user                login,
@s_date                datetime,
@s_term                varchar(30),
@s_ofi                 smallint,
@s_ssn                 int,
@s_sesn                int,
@i_operacion           char(1),
@i_opcion              tinyint,
@i_banco               cuenta,
@o_fecha_valor_grupal  datetime = null out

as
declare 
@w_sp_name            descripcion,
@w_error              int,
@w_banco_actual       cuenta,
@w_tipo_grupal        char(1),
@w_fecha_valor_grupal datetime,
@w_fecha_proceso      datetime

-- Establecimiento de variables locales iniciales
select @w_sp_name   = 'sp_utilidades_grupal',
       @w_error     = 0

exec @w_error = sp_tipo_operacion
     @i_banco  = @i_banco,
     @o_tipo   = @w_tipo_grupal out

if @w_error <> 0
   goto ERROR

if @w_tipo_grupal <> 'G'
begin
   select @w_error = 70203 -- ERROR: OPERACION NO EXISTE O NO ES UNA OPERACION GRUPAL
   goto ERROR
end
   
-- Fecha proceso
select @w_fecha_proceso = fp_fecha 
from cobis..ba_fecha_proceso

-- Consulta Fecha valor Grupal
if @i_operacion = 'F'
begin

   select @w_fecha_valor_grupal = fvg_fecha_valor
   from ca_en_fecha_valor_grupal
   where fvg_banco = @i_banco
   
   -- Fecha valor para Pago Grupal
   if @i_opcion = 0
   begin
      select @o_fecha_valor_grupal = isnull(@w_fecha_valor_grupal, @w_fecha_proceso)  
   end

end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',    
@t_file  = null,
@t_from  = @w_sp_name,   
@i_num   = @w_error
  
return @w_error
go
