
/************************************************************************/
/*      Disenado por:           Sonia Rojas                             */
/*      Fecha de escritura:     Noviembre 2017                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pagos_corresponsal_ej')
   drop proc sp_pagos_corresponsal_ej
go
create proc sp_pagos_corresponsal_ej
(
@i_param1        CHAR(1)          = 'I',
@i_param2        varchar(100)     = null,  --@i_referencia 
@i_param3        varchar(64)      = null,  --@i_fecha_pago
@i_param4        varchar(64)      = null,  --@i_monto_pago 
@i_param5        varchar(255)     = null,  --@i_archivo_pago
@i_param6        varchar(255)     = null,  --@i_corresponsal
@i_param7        datetime         = null   --@i_fecha_valor    

)
as
declare 
@s_ssn  int, 
@s_sesn int, 
@s_user login, 
@s_term varchar(64),
@s_date datetime, 
@s_srv varchar(64), 
@s_lsrv varchar(64), 
@s_rol int,
@s_ofi int, 
@s_culture varchar(100), 
@s_org char (1), 
@w_sp_name descripcion,
@w_error int,
@w_msg varchar(100),
@w_fecha_pro  datetime 


exec @s_ssn= ADMIN...rp_ssn

select 
@s_sesn = @s_ssn, 
@s_user = 'admuser', 
@s_term = '0',
@s_date = '07/31/2018', 
@s_srv  = '0', 
@s_lsrv = 'CTSSRV', 
@s_rol = 3,
@s_ofi = 0, 
@s_culture = null, 
@s_org = 'U', 
@w_sp_name = 'sp_pagos_corresponsal_ej',
@w_fecha_pro = fp_fecha from cobis..ba_fecha_proceso



exec @w_error= cob_cartera..sp_pagos_corresponsal 
@i_operacion 		 = @i_param1,
@s_ssn    			 =   @s_ssn, 
@s_sesn    			 =   @s_ssn, 
@s_user              =   @s_user, 
@s_term              =   @s_term,
@s_date              =   @s_date, 
@s_srv               =   @s_srv, 
@s_lsrv              =   @s_lsrv , 
@s_rol               =   @s_rol,
@s_ofi               =   @s_ofi, 
@s_culture           =   @s_culture , 
@s_org               =   @s_org,  
@i_referencia        =   @i_param2, 
@i_fecha_pago        =   @i_param3,
@i_monto_pago        =   @i_param4,
@i_archivo_pago      =   @i_param5, 
@i_corresponsal      =   @i_param6,
@i_fecha_valor       =   @i_param7



	  
if @w_error <> 0
begin 
   select 
   @w_msg = 'Error !:No se pudo procesar el BATCH  de Pagos por Corresponsal'
   goto ERROR_FIN
end	  
	  
	  
return 0
   
ERROR_FIN:
  exec cob_cartera..sp_errorlog 
    @i_fecha       = @w_fecha_pro,
    @i_error       = @w_error,
    @i_usuario     = 'usrbatch',
    @i_tran        = 7999,
    @i_tran_name   = @w_sp_name,
    @i_cuenta      = '',
    @i_descripcion = @w_msg, 
    @i_rollback    = 'S' 
       
return 0
