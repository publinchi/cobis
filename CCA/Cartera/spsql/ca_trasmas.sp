/************************************************************************/
/*   Archivo:             ca_trasmas.sp                                 */
/*   Stored procedure:    sp_traslado_masivo                            */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Edwin Rodriguez                               */
/*   Fecha de escritura:  27/Ene/2014                                   */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta para imprimir la tabla de amortizacion y en caso de la    */
/* simulacion  solamente es una opcion mas.                             */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*      FECHA              AUTOR              RAZON                     */
/*      Ene-27-2014       Edwin Rodriguez     Emicion Inicial           */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_traslado_masivo')
   drop proc sp_traslado_masivo
go
---Inc 24695  JUL-06-2011 pariendo de la Ver. 18
create proc sp_traslado_masivo (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               smallint    = null,
   @i_operacion         char(1)     = null,
   @i_Archivo           varchar(64) = null,
   @i_tipo_id           char(10)    = null,
   @i_id_cliente        varchar(10) = null,
   @i_oficina_origen    int         = null,
   @i_oficina_destino   int         = null,
   @i_ejecu_destino     int         = null,
   @i_origen            varchar(64) = null
)
as
declare
   @w_sp_name         varchar(32),
   @w_error           int,
   @w_secuencial      int,
   @w_msg             varchar(64)

   
select   
@w_sp_name       = 'sp_traslado_masivo'


if @i_operacion = 'I' begin

   insert into cobis..tmp_traslado (
          tr_tipoid,          tr_cedruc,       tr_ofiori,
          tr_ofides,          tr_ejedes)
   values(@i_tipo_id,         @i_id_cliente,   @i_oficina_origen,
          @i_oficina_destino, @i_ejecu_destino)

   
   if @@error <> 0 begin
      select 
         @w_error = 710001,
         @w_msg   = 'Error al Insertar en Tabla tmp_traslado'
      goto ERROR
   end
end

if @i_operacion = 'C' begin

   select @w_secuencial = max(bt_secuencial)
   from cob_cartera..ca_bitacora_traslados

   select @w_secuencial = 0,
          @w_secuencial = @w_secuencial + 1

   insert into cob_cartera..ca_bitacora_traslados (
          bt_secuencial,   bt_archivo,     bt_oficina,
          bt_usuario,      bt_fecha_carga)
   values(@w_secuencial,   @i_Archivo,     @s_ofi,
          @s_user,         getdate())

   if @@error <> 0 begin
      select 
         @w_error = 710001,
         @w_msg   = 'Error al Insertar en Tabla tmp_traslado'
      goto ERROR
   end
   
end

return 0

ERROR:
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   return 1
go