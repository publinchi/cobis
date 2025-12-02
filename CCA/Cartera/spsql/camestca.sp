 /***********************************************************************/
/*   Archivo:      camestop.sp            */
/*   Stored procedure:   sp_cambio_estado_est         */
/*   Base de datos:      cob_cartera            */
/*   Producto:       Credito y Cartera         */
/*   Disenado por:        Fabian de la Torre         */
/*   Fecha de escritura:   31/08/1999            */
/************************************************************************/
/*            IMPORTANTE            */
/*   Este programa es parte de los paquetes bancarios propiedad de   */
/*   "MACOSA".                     */
/*   Su uso no autorizado queda expresamente prohibido asi como   */
/*   cualquier alteracion o agregado hecho por alguno de sus      */
/*   usuarios sin el debido consentimiento por escrito de la      */
/*   Presidencia Ejecutiva de MACOSA o su representante.      */
/************************************************************************/
/*            PROPOSITO            */
/*   Ejecuta el camesop.sp para cambio de estado  a CAS = castigado  */
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_cambio_estado_est')
   drop proc sp_cambio_estado_est
go

create proc sp_cambio_estado_est(
   @s_user           login,
   @s_term           varchar(30),
   @s_date           datetime,
   @s_ofi            smallint,
   @i_toperacion     catalogo,
   @i_oficina        smallint,
   @i_banco          cuenta,
   @i_operacionca    int,
   @i_moneda         tinyint,
   @i_fecha_proceso  datetime,
   @i_estado_ini     int,
   @i_estado_fin     int = null, 
   @i_tipo_cambio    char(1),    
   @i_en_linea       char(1),    
   @i_gerente        smallint,
   @i_cliente        int 
      
) 
as
declare
   @w_return            int,
   @w_parametro_cas     catalogo,
   @w_situacion_cliente catalogo,
   @w_est_castigado     int,
   @w_rowcount          int

delete ca_cursor_dividendo_temp
where am_operacion =  @i_operacionca

select @w_est_castigado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CASTIGADO'


select @w_parametro_cas = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'CLICAS'
and    pa_producto = 'CRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount <> 0
begin
   
   select @w_situacion_cliente = en_situacion_cliente
   from   cobis..cl_ente
   where  en_ente = @i_cliente
   set transaction isolation level read uncommitted

   if @w_situacion_cliente =  @w_parametro_cas
   begin
--      PRINT 'camestca.sp @w_situacion_cliente ' + cast(@w_situacion_cliente as varchar)
      
      -- * COTIZACION MONEDA
      exec @w_return =  sp_cambio_estado_op
           @s_user             = @s_user,
           @s_term             = @s_term,
           @s_date             = @s_date,
           @s_ofi              = @s_ofi,
           @i_banco            = @i_banco,
           @i_fecha_proceso    = @i_fecha_proceso,
           @i_estado_ini       = @i_estado_ini,
           @i_estado_fin       = @w_est_castigado,
           @i_tipo_cambio      = 'A',
           @i_en_linea         = @i_en_linea
/*           @i_gerente          = @i_gerente,
           @i_moneda           = @i_moneda,
           @i_oficina          = @i_oficina,
           @i_operacionca      = @i_operacionca,
           @i_toperacion       = @i_toperacion,
           @i_estado_castigado = 'S'              */

      if @w_return != 0
         return  @w_return
      
   end  ---Castigar
end

return 0

go
