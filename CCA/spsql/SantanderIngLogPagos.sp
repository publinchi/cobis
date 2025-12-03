/************************************************************************/
/*   Archivo:              SantanderIngLogPagos.sp                      */
/*   Stored procedure:     sp_santander_ing_log_pagos					*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raúl Altamirano Mendez                       */
/*   Fecha de escritura:   Diciembre 2017                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Realiza la insercion en el log de errores para la aplicacion de los*/
/*   pagos para SANTANDER MX.                                           */
/*                              CAMBIOS                                 */
/*      FECHA           AUTOR           RAZON                           */
/*   26/03/2018        D.Cumbal         Cambios Caso 94602              */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_santander_ing_log_pagos')
   drop proc sp_santander_ing_log_pagos
go

create proc sp_santander_ing_log_pagos
@s_ssn int = null,
@s_user login = null,
@s_sesn int = null,
@s_term varchar(30) = null,
@s_date datetime = null,
@s_srv varchar(30) = null,
@s_lsrv varchar(30) = null,
@s_ofi smallint = null,
@s_servicio int = null,
@s_cliente int = null,
@s_rol smallint = null,
@s_culture varchar(10) = null,
@s_org char(1) = null,
@i_secuencial        int,
@i_fecha_gen_orden   datetime,
@i_referencia_banco  varchar(40)  = null,
@i_cuenta            cuenta       = null,
@i_monto_pago        money        = null,
@i_referencia        varchar(64)  = null,
@i_archivo           varchar(255) = null,
@i_resultado         varchar(2)   = null,
@i_corresponsal      catalogo     = null
as

declare 
@w_error       int,
@w_dividendo   int,
@w_est_vigente int,
@w_est_vencida int,
@w_param_fpago_ret catalogo,
@w_fecha_proceso   datetime,
@w_banco           cuenta,
@w_operacionca    int         ,
@w_error_out      int         ,
@w_msg            varchar(255),
@w_secuencial_ing int         ,
@w_secuencial     int         ,
@w_ref_leyenda    varchar(64) ,
@w_referencia     varchar(64) ,
@w_fecha_valor    datetime    ,
@w_forma_pago     catalogo    ,
@w_tipo_error     char(2)     ,         --Domiciliacion Santander
@w_estado_error   catalogo    ,
@w_mensaje_error  varchar(255),
@w_fecha          varchar(8),
@w_pos            TINYINT,
@w_fecha_clave    VARCHAR(32)

select 
@w_dividendo = 0,
@w_param_fpago_ret = 'ND_BCO_MN',
@w_banco           = ltrim(rtrim(substring(@i_referencia_banco, 1, 25))),
@w_forma_pago      = @i_corresponsal

SELECT @w_pos = charindex(' FH',@i_referencia)
SELECT @w_fecha_clave = substring(@i_referencia, @w_pos + 3 , 100)

if substring(@i_referencia ,1,3) = 'SEG'
begin
       select @w_ref_leyenda = @i_referencia,
              @w_referencia = 'PAGO SEGURO'
end   
else  
begin
       --Validar el formato
       select @w_fecha      = substring(@i_referencia,8,8)
       select @w_fecha_valor= convert(datetime,substring(@w_fecha,1,2) + '/' + substring(@w_fecha,3,2)+ '/' + substring(@w_fecha,5,4)),
              @w_referencia = 'PAGO PRESTAMO'
end


if @i_resultado = '00' -- Se cobro Santander
begin
     
     exec @w_error = sp_pago_cartera_srv
          @s_ssn             = @s_ssn               ,
          @s_user            = @s_user              ,
          @s_sesn            = @s_sesn              ,
          @s_term            = @s_term              ,
          @s_date            = @s_date              ,
          @s_srv             = @s_srv               ,
          @s_lsrv            = @s_lsrv              ,
          @s_ofi             = @s_ofi               ,
          @s_servicio        = @s_servicio          ,
          @s_cliente         = @s_cliente           ,
          @s_rol             = @s_rol               ,
          @s_culture         = @s_culture           ,
          @s_org             = @s_org               ,
          @i_banco           = @w_banco             ,
          @i_fecha_valor     = @w_fecha_valor       ,
          @i_forma_pago      = @w_forma_pago        ,
          @i_monto_pago      = @i_monto_pago        ,
          @i_cuenta          = @i_cuenta            , 
          @i_ref_leyenda     = @w_ref_leyenda       ,-- Por seguros VBR
          @o_error           = @w_error_out      out,
          @o_msg             = @w_msg            out,
          @o_secuencial_ing  = @w_secuencial_ing out,
          @o_secuencial      = @w_secuencial     out
          
          
      select @w_tipo_error    = 'DC'    ,
             @w_mensaje_error =  @w_msg,
             @w_estado_error  = convert(varchar,@w_error)
          
                      
end 
else
begin
        select @w_tipo_error    = 'DS',
               @w_estado_error  = @i_resultado
end


select 
@w_operacionca = op_operacion 
from ca_operacion 
where op_banco = @w_banco
if @@rowcount= 0 select @w_operacionca = 0

exec @w_error = sp_estados_cca
@o_est_vigente  = @w_est_vigente out,
@o_est_vencido  = @w_est_vencida out


select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre 
where  fc_producto = 7


--La maxima cuota exigible al momento del pago
select @w_dividendo = isnull(max(@w_dividendo), 0)
from   ca_dividendo
where  di_operacion = @w_operacionca
and    (di_estado = @w_est_vencida or (di_estado = @w_est_vigente and di_fecha_ven = @w_fecha_proceso)) 


insert into ca_santander_log_pagos(
sl_secuencial,  sl_fecha_gen_orden,  sl_banco,
sl_cuenta,      sl_monto_pag,        sl_referencia,
sl_archivo,     sl_tipo_error,       sl_estado,
sl_mensaje_err, sl_dividendo )
values(
-1*@i_secuencial,    @i_fecha_gen_orden,  @w_banco,
@i_cuenta,	      @i_monto_pago,       @w_referencia,
@i_archivo,       @w_tipo_error,       @w_estado_error,
@w_mensaje_error, @w_dividendo)

if @@error != 0   
BEGIN
   print'falla en guardar log en sp_santander_ing_log_pagos'
	return 710001
end


PRINT 'fecha clave LOG ' + @w_fecha_clave  + ' BCO  =  ' + @w_banco

-- ACTUALIZO LA TABLA ORIGEN PAR LUEGO LOS QUE QUEDAN EN ESTADO 'S0'
-- INSERTAR EN LA ca_santander_log_pagos, PERO EN EL SIGUIENTE PROCESO DE PAGOS
UPDATE ca_santander_orden_retiro SET 
	sor_error = @w_tipo_error,
	sor_procesado = 'S'
WHERE sor_fecha_clave = @w_fecha_clave
AND sor_banco = @w_banco

if @@error != 0 return 710002

return 0

go

