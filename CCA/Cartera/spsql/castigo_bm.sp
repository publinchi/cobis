/************************************************************************/
/*   Stored procedure:     sp_castigo_bm                                */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/************************************************************************/
 
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_castigo_bm')
   drop proc sp_castigo_bm
go
 
 
CREATE proc [dbo].[sp_castigo_bm]
    @i_banco             varchar(26),
    @i_secuencial        int,
    @i_fecha             smalldatetime,
    @o_msg               varchar(100)   out  
as
 

insert into ca_det_trn_bancamia_tmp
select
dtr_secuencial   = @i_secuencial,  
dtr_banco        = dr_banco,   
dtr_dividendo    = 1,  
dtr_concepto     = substring(dr_concepto,1,10),    
dtr_estado       = 1,     
dtr_periodo      = 0, 
dtr_codvalor     = co_codigo * 1000 + 10,     
dtr_monto        = dr_valor_vigente * -1,
dtr_monto_mn     = dr_valor_vigente * -1,
dtr_moneda       = 0, 
dtr_cotizacion   = 1, 
dtr_tcotizacion  = 'C', 
dtr_afectacion   = 'D',
dtr_cuenta       = '',  
dtr_beneficiario = '', 
dtr_monto_cont   = 0,
dtr_fecha_proc   = '01/01/1900',
dtr_tran         = 'CAS',
dtr_archi_ofi    = 0
from cob_credito..cr_dato_operacion_rubro, cob_cartera..ca_concepto_bancamia
where dr_concepto  = co_concepto
and   dr_fecha     = @i_fecha
and   dr_banco     = @i_banco
and   dr_valor_vigente <> 0

if @@error != 0 begin
  select @o_msg = 'Error en insercion ca_det_trn_bancamia_tmp (1)'
  return 7200
end



insert into ca_det_trn_bancamia_tmp
select
dtr_secuencial   = @i_secuencial,  
dtr_banco        = dr_banco,   
dtr_dividendo    = 1,  
dtr_concepto     = substring(dr_concepto,1,10),    
dtr_estado       = 4,     
dtr_periodo      = 0, 
dtr_codvalor     = co_codigo * 1000 + 40,     
dtr_monto        = dr_valor_vigente,
dtr_monto_mn     = dr_valor_vigente,
dtr_moneda       = 0, 
dtr_cotizacion   = 1, 
dtr_tcotizacion  = 'C', 
dtr_afectacion   = 'D',
dtr_cuenta       = '',  
dtr_beneficiario = '', 
dtr_monto_cont   = 0,
dtr_fecha_proc   = '01/01/1900',
dtr_tran         = 'CAS',
dtr_archi_ofi    = 0
from cob_credito..cr_dato_operacion_rubro, cob_cartera..ca_concepto_bancamia
where dr_concepto  = co_concepto
and   dr_fecha     = @i_fecha
and   dr_banco     = @i_banco
and   dr_valor_vigente <> 0

if @@error != 0 begin
  select @o_msg = 'Error en insercion ca_det_trn_bancamia_tmp (2)'
  return 7200
end


insert into ca_det_trn_bancamia_tmp
select
dtr_secuencial   = @i_secuencial,  
dtr_banco        = dr_banco,   
dtr_dividendo    = 1,  
dtr_concepto     = substring(dr_concepto,1,10),    
dtr_estado       = 9,     
dtr_periodo      = 0, 
dtr_codvalor     = co_codigo * 1000 + 90,     
dtr_monto        = dr_valor_suspenso * -1,
dtr_monto_mn     = dr_valor_suspenso * -1,
dtr_moneda       = 0, 
dtr_cotizacion   = 1, 
dtr_tcotizacion  = 'C', 
dtr_afectacion   = 'D',
dtr_cuenta       = '',  
dtr_beneficiario = '', 
dtr_monto_cont   = 0,
dtr_fecha_proc   = '01/01/1900',
dtr_tran         = 'CAS',
dtr_archi_ofi    = 0
from cob_credito..cr_dato_operacion_rubro, cob_cartera..ca_concepto_bancamia
where dr_concepto        = co_concepto
and   dr_fecha           = @i_fecha
and   dr_banco           = @i_banco
and   dr_valor_suspenso <> 0

if @@error != 0 begin
  select @o_msg = 'Error en insercion ca_det_trn_bancamia_tmp (3)'
  return 7200
end



insert into ca_det_trn_bancamia_tmp
select
dtr_secuencial   = @i_secuencial,  
dtr_banco        = dr_banco,   
dtr_dividendo    = 1,  
dtr_concepto     = substring(dr_concepto,1,10),    
dtr_estado       = 4,     
dtr_periodo      = 0, 
dtr_codvalor     = co_codigo * 1000 + 40,     
dtr_monto        = dr_valor_suspenso,
dtr_monto_mn     = dr_valor_suspenso,
dtr_moneda       = 0, 
dtr_cotizacion   = 1, 
dtr_tcotizacion  = 'C', 
dtr_afectacion   = 'D',
dtr_cuenta       = '',  
dtr_beneficiario = '', 
dtr_monto_cont   = 0,
dtr_fecha_proc   = '01/01/1900',
dtr_tran         = 'CAS',
dtr_archi_ofi    = 0
from cob_credito..cr_dato_operacion_rubro, cob_cartera..ca_concepto_bancamia
where dr_concepto  = co_concepto
and   dr_fecha     = @i_fecha
and   dr_banco     = @i_banco
and   dr_valor_suspenso <> 0

if @@error != 0 begin
  select @o_msg = 'Error en insercion ca_det_trn_bancamia_tmp (4)'
  return 7200
end


return 0

go
 