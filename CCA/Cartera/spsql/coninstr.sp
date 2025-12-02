/************************************************************************/
/*   Archivo:              coninstr.sp                                  */
/*   Stored procedure:     sp_cons_inst_tram                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Tania B.                                     */
/*   Fecha de escritura:   Agosto 2017                                  */
/************************************************************************/
/*                            IMPORTANTE                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Programa consulta datos del trámite del proceso de workflow actual */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA        AUTOR             RAZON                                */
/*  16/Ago/2017  Tania B.          Emision inicial                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cons_inst_tram')
   drop proc sp_cons_inst_tram
go

create proc sp_cons_inst_tram 
@i_ente          int          = null,
@i_nom_proceso   varchar(150) = null

as 
declare
@w_sp_name              varchar(64),
@w_error                int,
@w_inst_proc            int,
@w_tramite              int,
@w_fecha_ini_act        datetime,
@w_monto_garantia       money,
@w_nombre_act           varchar(100),
@w_currency_desc        varchar(50) = '',
@w_moneda               int,
@w_msg                  varchar(250),
@w_id_act               int,
@w_garliq_estado        char(1) = 'S',
@w_monto_gar_pagado_tot money,
@w_monto_aprobado_tot   money,
@w_porcentaje_monto     float,
@w_monto_gar_tot        money,
@w_monto_gar            money

select @w_sp_name = 'sp_cons_inst_tram'

exec @w_error= cob_workflow..sp_cons_instancia
@i_ente          = @i_ente,
@i_operacion     = 'Q',
@i_nom_proceso   = @i_nom_proceso,
@o_inst_proc     = @w_inst_proc output,
@o_tramite       = @w_tramite output, 
@o_fecha_ini_act = @w_fecha_ini_act output,
@o_id_act        = @w_id_act output,
@o_nombre_act    = @w_nombre_act output

if @w_error <> 0 goto ERROR

--Parametro porcentaje para el calculo de la garantia
select @w_porcentaje_monto = pa_float
from cobis..cl_parametro 
where pa_nemonico = 'PGARGR' 
and pa_producto = 'CCA'


--PENDIENTE: 1. Cuando hay aumento de monto. 2.Aumenta integrante 3. Hay garantía líquida por cobrar
select @w_monto_aprobado_tot = isnull(sum(tg_monto),0)
from cob_credito..cr_tramite_grupal
where tg_tramite = @w_tramite

if exists(select 1 from cob_cartera..ca_garantia_liquida where gl_tramite = @w_tramite)
begin
   exec @w_error = sp_genera_xml_gar_liquida
   @i_tramite           = @w_tramite,
   @i_opcion            = 'Q',
   @i_vista_previa      = 'N',
   @o_gar_pendiente     = @w_garliq_estado out
end
   
if @w_error <> 0 goto ERROR

select @w_monto_gar_tot = (@w_monto_aprobado_tot  * @w_porcentaje_monto)/100

select @w_moneda = tr_moneda
from cob_credito..cr_tramite
where tr_tramite = @w_tramite

if @w_moneda is null
begin
   select @w_error = 70130 --ERROR AL CONSULTAR DATOS DEL TRÁMITE
end

select @w_currency_desc = mo_nemonico 
from cobis..cl_moneda
where mo_moneda = @w_moneda

if @w_currency_desc is null
begin
   select @w_error = 701069 --No existe moneda
   select @w_msg = 'No existe moneda'
   goto ERROR
end


select 
@w_monto_aprobado_tot, 
@w_monto_gar_tot, 
@w_nombre_act, 
@w_currency_desc, 
@w_inst_proc, 
@w_id_act,
@w_tramite,
@w_garliq_estado

return 0


ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_msg = @w_msg,
@i_num   = @w_error

go
