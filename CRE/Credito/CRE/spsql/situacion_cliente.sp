/************************************************************************/
/*  Archivo:                situacion_cliente.sp                        */
/*  Stored procedure:       sp_situacion_cliente                        */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_situacion_cliente')
    drop proc sp_situacion_cliente
go


create proc sp_situacion_cliente(
        @s_user               login = null,
        @s_ssn                int = null,
        @s_sesn               int = null,
        @s_date               datetime = null,
        @t_file               varchar(14) = null,
        @t_debug              char(1)  = 'N',
        @i_tramite            int = 0,
        @i_cliente            int = null,
        @i_cliente_sig        int = 0,
        @i_operacion          char(1) = null,
        @i_modo_c             char(2) = null,
        @i_en_tramite         char(1) = null,
        @i_modo               int = null,
        @i_usuario            login = null,
        @i_secuencia          int = null,
        @i_categoria          char(2) = null,
        @i_formato_fecha      int     = null,
        @i_tramite_d          int = null,
        @i_operacion_ban      cuenta = ' ',
        @i_tipo_deuda         char(1) = null,
        @t_show_version        bit    = 0 -- Mostrar la version del programa
    )
as

declare
   @w_sp_name		varchar(32),
   @w_fecha		datetime,
   @w_total             money,
   @w_registros         varchar(10),
   @w_total_registros   int,
   @w_total_cca         money,
   @w_total_cex         money,
   @w_total_visa        money,
   @w_total_sobre       money,
   @w_total_tram        money,
   @w_cliente           int,
   @w_calificacion      catalogo,
   @w_calificacion_peor catalogo,
   @w_est_castigado     tinyint,
   @w_est_judicial      tinyint,
   @w_tot_castigados    money,
   @w_tot_judicial      money,
   @w_convenio          cuenta,
   @w_def_moneda	 tinyint,
   @w_tabla_calif       int,			--Vivi
   @w_spid              smallint --OCU#

select 	@w_sp_name = 'sp_situacion_cliente'

if @t_show_version = 1
begin
    print 'Stored procedure sp_situacion_cliente, Version 4.0.0.0'
    return 0
end

--OCU#
select @w_spid = @@spid

-- Cargo fecha de proceso
select @w_fecha = fp_fecha
from cobis..ba_fecha_proceso

select @i_tramite_d = isnull(@i_tramite_d,0)

if @i_operacion = 'S'
begin

   /**  AFILIACIONES A GLOBAL NET  **/
   if @i_modo_c = 'A'
   BEGIN
      set rowcount 5
      /** RETORNA INFORMACION DE AFILIACIONES AL FRONT-ENT **/
      select '212889' = a.af_ente_mis,
             '212966' = a.af_login,
             '212967' = a.af_nombre_login ,
             '212968' = convert( varchar(10), a.af_fecha_afiliacion, @i_formato_fecha),
             '212969' = isnull(convert(varchar, a.af_perfil), ''),
             '212970' = a.af_perfil_alterno,
             '211399' = isnull( (select y.valor from cobis..cl_tabla x, cobis..cl_catalogo y
                                 where x.tabla = 'bv_tipo_login_estado'
                                   and x.codigo = y.tabla and y.codigo = a.af_estado ), a.af_estado)
        from cob_credito..cr_situacion_cliente,
             cobis..bv_afiliados_bv a
       where sc_usuario   = @s_user
         and sc_secuencia = @s_sesn
         and sc_tramite   = @i_tramite
         and a.af_ente_mis    = sc_cliente
         and ((a.af_ente_mis  = @i_cliente_sig and a.af_login > @i_operacion_ban)
          or a.af_ente_mis  > @i_cliente_sig )
       order by a.af_ente_mis, a.af_ente, a.af_login, a.af_canal

      set rowcount 0
      return
   END
end

delete from cr_cotiz3_tmp      where spid = @w_spid --tabla de cotizaciones

return 0

GO
