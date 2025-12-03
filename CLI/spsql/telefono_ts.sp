/*************************************************************************/
/*   Archivo:            telefono_ts.sp                                  */
/*   Stored procedure:   sp_telefono_ts                                  */
/*   Base de datos:      cobis                                           */
/*   Producto:           Consolidador                                    */
/*   Disenado por:       WAVB                                            */
/*   Fecha de escritura: Jun/2020                                        */
/*************************************************************************/
/*                           IMPORTANTE                                  */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS', su uso no autorizado queda expresamente prohibido asi      */
/*   como cualquier alteracion o agregado hecho por alguno de sus        */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante.                  */
/*************************************************************************/
/*                            PROPOSITO                                  */
/*   Creacion de transacciones de servicio durante el proceso de update  */
/*   del manejo de telefonos                                             */
/*                                                                       */
/*               MODIFICACIONES                                          */
/*   FECHA          AUTOR          RAZON                                 */
/*   01/07/20       WAVB           Versión Inicial                       */
/*   15/10/20       MBA            Uso de la variable @s_culture         */
/*************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1
           from   sysobjects
           where  name = 'sp_telefono_ts')
  drop proc sp_telefono_ts
go


create proc sp_telefono_ts(
   @s_ssn                int, 
   @s_user               login        = null,
   @s_term               varchar(32)  = null,
   @s_date               datetime,
   @s_srv                varchar(30)  = null,
   @s_lsrv               varchar(30)  = null,
   @s_ofi                smallint     = NULL,
   @s_culture            varchar(10) = 'NEUTRAL',
   @t_trn                int          = null,
   @t_show_version       bit          = 0,
   @i_ente               int          = null,
   @i_direccion          tinyint      = null,
   @i_secuencial         tinyint      = null
)
as
  declare
    @w_sp_name             varchar(32),
    @w_sp_msg              varchar(132)



select
  @w_sp_name = 'sp_telefono_ts'


---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
		
		
--se almacena la informacion anterior a la actualizacion
insert into ts_telefono(
secuencial,       tipo_transaccion,       clase,          fecha,
usuario,          terminal,               srv,            lsrv,
ente,             direccion,              telefono,       valor,
tipo,             cobro,                  oficina,        hora) --DVE
select   
secuencial         =   @s_ssn,        
tipo_transaccion   =   @t_trn,  
clase              =   'P',
fecha              =   @s_date,
usuario            =   @s_user,
terminal           =   @s_term,
srv                =   @s_srv,
lsrv               =   @s_lsrv,
ente               =   @i_ente,
direccion          =   @i_direccion,
telefono           =   @i_secuencial,
valor              =   case when a.te_valor <> b.te_valor then a.te_valor else null end,
tipo               =   case when a.te_tipo_telefono <> b.te_tipo_telefono then a.te_tipo_telefono else null end,
cobro              =   case when a.te_telf_cobro <> b.te_telf_cobro then a.te_telf_cobro else null end,
oficina            =   @s_ofi,
hora               =   getdate()
from  #tmp_telefono   a,   #tmp_telefono b
where a.te_ente      =   @i_ente
and a.te_direccion   =   @i_direccion
and a.te_secuencial  =   @i_secuencial
and a.tipo           =   'A'
and a.te_ente        =   b.te_ente
and a.te_direccion   =   b.te_direccion
and a.te_secuencial  =   b.te_secuencial
and b.tipo           =   'D'


--se almacena la informacion posterior a la actualizacion
insert into ts_telefono(
secuencial,       tipo_transaccion,       clase,          fecha,
usuario,          terminal,               srv,            lsrv,
ente,             direccion,              telefono,       valor,
tipo,             cobro,                  oficina,        hora) --DVE
select   
secuencial         =   @s_ssn,        
tipo_transaccion   =   @t_trn,  
clase              =   'A',
fecha              =   @s_date,
usuario            =   @s_user,
terminal           =   @s_term,
srv                =   @s_srv,
lsrv               =   @s_lsrv,
ente               =   @i_ente,
direccion          =   @i_direccion,
telefono           =   @i_secuencial,
valor              =   case when a.te_valor <> b.te_valor then b.te_valor else null end,
tipo               =   case when a.te_tipo_telefono <> b.te_tipo_telefono then b.te_tipo_telefono else null end,
cobro              =   case when a.te_telf_cobro <> b.te_telf_cobro then b.te_telf_cobro else null end,
oficina            =   @s_ofi,
hora               =   getdate()
from  #tmp_telefono   a,   #tmp_telefono b
where a.te_ente      =   @i_ente
and a.te_direccion   =   @i_direccion
and a.te_secuencial  =   @i_secuencial
and a.tipo           =   'A'
and a.te_ente        =   b.te_ente
and a.te_direccion   =   b.te_direccion
and a.te_secuencial  =   b.te_secuencial
and b.tipo           =   'D'



insert into cobis..cl_actualiza (
ac_ente,           ac_fecha,           ac_tabla,
ac_campo,          ac_valor_ant,       ac_valor_nue,
ac_transaccion,    ac_secuencial1,     ac_secuencial2, 
ac_hora)
select
ac_ente            =   @i_ente,
ac_fecha           =   @s_date,
ac_tabla           =   'cobis..cl_telefono',
ac_campo           =   'te_valor',
ac_valor_ant       =   a.te_valor,
ac_valor_nue       =   b.te_valor,   
ac_transaccion     =   'U',
ac_secuencial1     =   @i_direccion,
ac_secuencial2     =   @i_secuencial,
ac_hora            =   getdate()
from  #tmp_telefono   a,   #tmp_telefono b
where a.te_ente      =   @i_ente
and a.te_direccion   =   @i_direccion
and a.te_secuencial  =   @i_secuencial
and a.tipo           =   'A'
and a.te_ente        =   b.te_ente
and a.te_direccion   =   b.te_direccion
and a.te_secuencial  =   b.te_secuencial
and b.tipo           =   'D'
and a.te_valor <> b.te_valor

go