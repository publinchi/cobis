/************************************************************************/
/*   Archivo:              cphislik.sp                                  */
/*   Stored procedure:     sp_cpy_historico_lnk                         */
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
/*   Buscar Secuencial retroceso para fecha valor o revesar en lnk      */
/*   al servidor de históricos                                          */
/************************************************************************/
/*                             MODIFICACIONES                           */
/************************************************************************/
/*   FECHA               AUTOR      RAZON                               */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cpy_historico_lnk')
   drop proc sp_cpy_historico_lnk
go

create proc sp_cpy_historico_lnk (
   @i_operacion   int          = 0,
   @i_secuencial  int          = 0
)                 
as declare        
   @w_sp_name     varchar(32),
   @w_servidor    varchar(10),
   @w_comando     varchar(255),
   @w_error       int
   
set ANSI_DEFAULTS ON
set ANSI_WARNINGS ON

-- INICIALIZACION DE VARIABLES
select @w_sp_name = 'sp_cpy_historico_lnk'

/* PARAMETRO GENERAL SERVIDOR HISTORICOS*/
select @w_servidor = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'SRVHIS'

-- ELIMINA HISTORICOS ANTERIORES CON MISMO SECUENCIAL PARA LA OPERACION

begin tran

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

-- TRAE DATOS DE VISTAS LINK

select @w_comando = 'insert into ca_dividendo_his select * from '+ @w_servidor +'.cob_cartera.dbo.ca_dividendo_his'
select @w_comando = @w_comando + ' where dih_operacion  = ' + convert(varchar(25),@i_operacion)
select @w_comando = @w_comando + ' and   dih_secuencial = ' + convert(varchar(25),@i_secuencial)
exec @w_error = sp_sqlexec @w_comando
select @w_comando = ''
if @w_error <> 0 begin
   print 'Error recuperando LINK ca_dividendo_his'
   print @w_comando
   goto ERROR
end


select @w_comando = 'insert into ca_amortizacion_his select * from '+ @w_servidor +'.cob_cartera.dbo.ca_amortizacion_his'
select @w_comando = @w_comando + ' where amh_operacion  = ' + convert(varchar(25),@i_operacion)
select @w_comando = @w_comando + ' and   amh_secuencial = ' + convert(varchar(25),@i_secuencial)
exec @w_error = sp_sqlexec @w_comando
select @w_comando = ''
if @w_error <> 0 begin
   print 'Error recuperando LINK ca_amortizacion_his'
   print @w_comando
   goto ERROR
end

select @w_comando = 'insert into ca_rubro_op_his select * from '+ @w_servidor +'.cob_cartera.dbo.ca_rubro_op_his'
select @w_comando = @w_comando + ' where roh_operacion  = ' + convert(varchar(25),@i_operacion)
select @w_comando = @w_comando + ' and   roh_secuencial = ' + convert(varchar(25),@i_secuencial)
exec @w_error = sp_sqlexec @w_comando
select @w_comando = ''
if @w_error <> 0 begin
   print 'Error recuperando LINK ca_rubro_op_his'
   print @w_comando
   goto ERROR
end

select @w_comando = 'insert into ca_cuota_adicional_his select * from '+ @w_servidor +'.cob_cartera.dbo.ca_cuota_adicional_his'
select @w_comando = @w_comando + ' where cah_operacion  = ' + convert(varchar(25),@i_operacion)
select @w_comando = @w_comando + ' and   cah_secuencial = ' + convert(varchar(25),@i_secuencial)
exec @w_error = sp_sqlexec @w_comando
select @w_comando = ''
if @w_error <> 0 begin
   print 'Error recuperando LINK ca_cuota_adicional'
   print @w_comando
   goto ERROR
end

select @w_comando = 'insert into ca_amortizacion_ant select * from '+ @w_servidor +'.cob_cartera.dbo.ca_amortizacion_ant'
select @w_comando = @w_comando + ' where an_operacion  = ' + convert(varchar(25),@i_operacion)
select @w_comando = @w_comando + ' and   an_secuencial = ' + convert(varchar(25),@i_secuencial)
exec @w_error = sp_sqlexec @w_comando
select @w_comando = ''
if @w_error <> 0 begin
   print 'Error recuperando LINK ca_amortizacion_ant'
   print @w_comando
   goto ERROR
end

commit tran

return 0

ERROR:
rollback tran
return 1

go

