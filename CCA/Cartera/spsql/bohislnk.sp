/************************************************************************/
/*   Archivo:              bohislik.sp                                  */
/*   Stored procedure:     sp_bor_historico_lnk                         */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         lnk                                          */
/*   Fecha de escritura:   Dic/09                                       */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Borrar Secuencial retroceso para fecha valor o revesar en lnk      */
/*   al servidor de históricos                                          */
/************************************************************************/
/*                             MODIFICACIONES                           */
/************************************************************************/
/*   FECHA               AUTOR      RAZON                               */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_bor_historico_lnk')
   drop proc sp_bor_historico_lnk
go

create proc sp_bor_historico_lnk (
   @i_operacion   int          = 0,
   @i_secuencial  int          = 0
)                 
as declare        
   @w_sp_name     varchar(32),
   @w_servidor    varchar(10),
   @w_comando     varchar(255),
   @w_error       int
   
-- INICIALIZACION DE VARIABLES
select @w_sp_name = 'sp_bor_historico_lnk'

-- ELIMINA HISTORICOS ANTERIORES CON MISMO SECUENCIAL PARA LA OPERACION

delete ca_dividendo_his 
where dih_operacion  = @i_operacion
and   dih_secuencial = @i_secuencial
if @@error != 0
   goto ERROR

delete ca_amortizacion_his 
where amh_operacion  = @i_operacion
and   amh_secuencial = @i_secuencial
if @@error != 0
   goto ERROR

delete ca_rubro_op_his 
where roh_operacion  = @i_operacion
and   roh_secuencial = @i_secuencial
if @@error != 0
   goto ERROR

delete ca_cuota_adicional_his 
where cah_operacion  = @i_operacion
and   cah_secuencial = @i_secuencial
if @@error != 0
   goto ERROR

delete ca_amortizacion_ant 
where an_operacion  = @i_operacion
and   an_secuencial = @i_secuencial
if @@error != 0
   goto ERROR
   
delete ca_seguros_his
where seh_operacion  = @i_operacion
and   seh_secuencial = @i_secuencial
if @@error != 0
   goto ERROR
   
delete ca_seguros_det_his
where sedh_operacion  = @i_operacion
and   sedh_secuencial = @i_secuencial
if @@error != 0
   goto ERROR     
   
delete ca_seguros_can_his
where sech_operacion  = @i_operacion
and   sech_secuencial = @i_secuencial
if @@error != 0
   goto ERROR    


return 0

ERROR:
return 1

go
