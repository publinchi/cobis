/************************************************************************/
/*   Archivo:             batch.sp                                      */
/*   Stored procedure:    sp_batch                                      */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        Fabian de la Torre                            */
/*   Fecha de escritura:  Ene. 98.                                      */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/*            PROPOSITO                                                 */
/*   Procedimiento que realiza la ejecucion del fin de dia de           */
/*   cartera.                                                           */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*   23/abr/2010   Fdo Carvajal   MANEJO SOLO OPS CON NOTAS DEBITO      */
/*   24/Sep/2015   Elcira Pelaez  SACAR DE UNIVERSO LAS NORMALIZACIONES */
/*                                DEL DIA                               */
/*   20/Feb/2019   Adriana Giler  MANEJO CORRECTO DE LOS NEMONICOS FP   */
/*   24/07/2019    Sandro Vallejo Pagos Grupales e Interciclos          */
/*   26/07/2019    Luis Ponce     Cambio Pagos Grupales e Interciclos   */
/*   09/04/2020    Luis Ponce     CDIG Nuevo Esquema de Paralelismo     */
/*   02/07/2020    Luis Ponce     CDIG Default P cuando es fecha valor  */
/*   19/11/2020   Patricio Narvaez   Esquema de Inicio de Dia, 7x24 y   */
/*                                   Doble Cierre automatico            */
/*   19/10/2021   Kevin Rodríguez Inclusión parámetro para reconocer */
/*                                 si viene desde Fecha Valor o Reverso */
/*   10/03/2022   Guisela Fernandez Incluye nueva validacion cuando no  */
/*                                  se envia datos en el @i_param1 por_ */
/*                                  visual batch                        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_batch')
   drop proc sp_batch
go

create proc sp_batch
@i_param1              varchar(255)  = null,
@i_param2              varchar(255)  = null,
@i_param3              varchar(255)  = null,
@i_param4              varchar(255)  = null,   
@i_param5              varchar(255)  = null,  
@i_param6              varchar(255)  = null,     -- FCP Interfaz Ahorros

@i_siguiente_dia       datetime      = null,   
@s_user                varchar(14)   = null,
@s_term                varchar(30)   = null,
@s_date                datetime      = null,
@s_ofi                 smallint      = null,
@i_en_linea            char(1)       = 'N',
@i_banco               cuenta        = null,
@i_pry_pago            char(1)       = 'N', 
@i_aplicar_clausula    char(1)       = 'S',
@i_aplicar_fecha_valor char(1)       = 'N',
@i_control_fecha       char(1)       = 'S',
@i_operacionFR         char(1)       = null,  -- KDR: Fecha valor F o Reversa R
@i_debug               char(1)       = 'N', 
@i_pago_ext            char(1)       = 'N',   ---req 482
@i_simular_cierre      datetime      = null  --Simular el cierre enviando la fecha de cierre diferente a la de la tabla

as
declare
@w_return          int      = 0,
@i_hilo            tinyint  = 1, --LPO CDIG Nuevo Esquema de Paralelismo -- numero de hilos a generar o hilo que debe procesar 
@i_sarta           int, 
@i_batch           int, 
@i_numreg          int = null, --LPO CDIG Nuevo Esquema de Paralelismo -- Numero de registros por hilo. Paralelismo 
@w_tipo_batch      char(1),                           -- FCP Interfaz Ahorros
@i_operacion       char(1)  = 'P'  --Fecha Valor por defecto es 'P'

SELECT @w_return          = 0
SELECT @i_hilo            = 1
SELECT @i_operacion       = 'P'


if @i_param1 is not null and @i_param1 <> 'NULL' --GFP 10/03/2022
   select 
   @i_hilo          = convert(tinyint, rtrim(ltrim(@i_param1))),      --LPO CDIG Nuevo Esquema Paralelismo   
   @i_sarta         = isnull(convert(int       , rtrim(ltrim(@i_param2))),0),
   @i_batch         = isnull(convert(int       , rtrim(ltrim(@i_param3))),0),
   @i_operacion     = convert(char(1)   , rtrim(ltrim(isnull(@i_param4,'P')))),
   @i_numreg        = isnull(convert(int       , rtrim(ltrim(@i_param5))),0),   --LPO CDIG Nuevo Esquema Paralelismo
   @w_tipo_batch    = isnull(convert(char(1), rtrim(ltrim(@i_param6))), 'N')

--LPO CDIG Nuevo Esquema Paralelismo INICIO
IF @i_operacion = 'P'
BEGIN

   create table #ca_rubro_int_tmp(
   ro_operacion          int      null,
   ro_concepto           catalogo null,
   ro_porcentaje         float    null,
   ro_tipo_rubro         char(1)  null,
   ro_provisiona         char(1)  null,
   ro_fpago              char(1)  null,
   ro_concepto_asociado  char(10)  null,
   ro_valor              money    null,
   ro_num_dec            tinyint  null,
   ro_porcentaje_efa     float    null
   )

   create table #ca_rubro_imo_tmp(
   ro_operacion          int      null,
   ro_concepto           catalogo null,
   ro_porcentaje         float    null,
   ro_tipo_rubro         char(1)  null,
   ro_provisiona         char(1)  null,
   ro_fpago              char(1)  null,
   ro_concepto_asociado  char(1)  null,
   ro_valor              money    null,
   ro_num_dec            tinyint  null
   )

END
--LPO CDIG Nuevo Esquema Paralelismo FIN
  
select @i_siguiente_dia = isnull(@i_siguiente_dia,fc_fecha_cierre)
from cobis..ba_fecha_cierre
where fc_producto = 7   

--LPO CDIG Nuevo Esquema Paralelismo INICIO

/* EJECUCION DEL PROCESO BATCH */

if @i_banco is null and @i_operacion = 'P'
begin 

   exec @w_return   = sp_batch2
   @s_user          = @s_user,
   @s_term          = @s_term,
   @s_date          = @s_date,
   @s_ofi           = @s_ofi,
   @i_en_linea      = @i_en_linea,
   @i_siguiente_dia = @i_siguiente_dia,
   @i_pry_pago      = @i_pry_pago,
   @i_sarta         = @i_sarta,	-- Numero de sarta batch 
   @i_batch         = @i_batch,	-- Numero de proceso batch 
   @i_operacion     = @i_operacion,  -- G generar universo a procesar P procesar batch
   @i_control_fecha = @i_control_fecha,   
   @i_hilo          = @i_hilo,       -- numero de hilos a generar o hilo que debe procesar 
   @i_numreg        = @i_numreg,     -- Numero de registros por hilo. Paralelismo 
   @i_debug         = @i_debug, 
   @i_simular_cierre = @i_simular_cierre
end	 
else if @i_banco is not null and @i_operacion = 'P'
begin
  
   exec @w_return = sp_batch1
   @s_user                = @s_user,
   @s_term                = @s_term,
   @s_date                = @s_date,
   @s_ofi                 = @s_ofi,
   @i_en_linea            = @i_en_linea,
   @i_banco               = @i_banco,
   @i_siguiente_dia       = @i_siguiente_dia,
   @i_pry_pago            = @i_pry_pago,
   @i_aplicar_clausula    = @i_aplicar_clausula,
   @i_aplicar_fecha_valor = @i_aplicar_fecha_valor,
   @i_operacionFR         = @i_operacionFR,
   @i_control_fecha       = @i_control_fecha,
   @i_debug               = @i_debug, 
   @i_pago_ext            = @i_pago_ext, --Req 482
   @i_simular_cierre      = @i_simular_cierre   
END
--LPO CDIG Nuevo Esquema Paralelismo FIN

--LPO CDIG Nuevo Esquema Paralelismo INICIO
if @i_operacion = 'G' 
begin 
   truncate table ca_universo -- borrar todos los registros de la tabla 

   exec @w_return = sp_llenauniverso 
   @i_fecha       = @i_siguiente_dia, --@s_date, 
   @i_pago        = 'N', 
   @i_sarta       = @i_sarta, 
   @i_batch       = @i_batch,
   @i_tipo_batch  = @w_tipo_batch  --LPO CDIG Nuevo Esquema Paralelismo
end
--LPO CDIG Nuevo Esquema Paralelismo FIN

return @w_return
go
