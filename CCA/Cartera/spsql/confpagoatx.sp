/************************************************************************/
/*   Stored procedure:     sp_confirma_pago_atx                         */
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
/*      Confirma la aplicacion del pago en atx o servicios bancarios    */
/************************************************************************/  
/*                           MODIFICACIONES                             */
/*      FECHA           AUTOR             RAZON                         */
/************************************************************************/ 
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_confirma_pago_atx')
   drop proc sp_confirma_pago_atx
go
 
create proc sp_confirma_pago_atx
   @s_ssn               int          = null,
   @s_date              datetime     = null,
   @s_user              login        = null,
   @s_term              descripcion  = null,
   @s_ofi               smallint     = null,
   @t_debug             char(1)      = 'N',
   @t_file              varchar(14)  = null,
   @t_trn               smallint     = null,
   @i_operacion         char(1)      = null,
   @i_operacionca       int          = null,
   @i_cheque            int          = null,
   @i_idlote            int          = null,
   @i_valor             money        = null,
   @i_secuencial        int          = null,
   @i_pagado			 char(1)      = null
as declare
   @w_sp_name            varchar(30),
   @w_return             int,
   @w_error              int,
   @w_rowcount           int,
   @w_pa_cheger          varchar(30),
   @w_pa_cheotr          varchar(30),    
   @w_referencia         cuenta,
   @w_producto           char(1),
   @w_est_vigente        tinyint,
   @w_est_vencido        tinyint,
   @w_est_castigado      tinyint,
   @w_est_suspenso       tinyint

/* INICIALIZACION VARIABLES */
select 
    @w_sp_name        = 'sp_confirma_pago_atx'

/* LECTURA DE PARAMETROS ESTADOS DE CARTERA */
select @w_est_vigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_castigado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CASTIGADO'

select @w_est_suspenso  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'SUSPENSO'


/* LECTURA DEL PARAMETRO CHEQUE DE GERENCIA */
select @w_pa_cheger = pa_char
from   cobis..cl_parametro
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'CHEGER'
select @w_rowcount    = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 701012 --No existe parametro cheque de gerencia
   goto ERROR
end

/* LECTURA DEL PARAMETRO CHEQUE LOCAL (Otros Bancos) */
select @w_pa_cheotr = pa_char
from   cobis..cl_parametro
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'CHELOC'
select @w_rowcount    = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 701012 --No existe parametro cheque de Otros Bancos
   goto ERROR
end

/* OBTENER DATOS DE LA OPERACION */
select @w_referencia = op_banco
from   ca_operacion
where  op_operacion	 = @i_operacionca
and    op_estado     in (@w_est_vigente,@w_est_vencido,@w_est_castigado,@w_est_suspenso)

if @@rowcount = 0 begin
   select @w_error = 701013 --No existe operacion activa de cartera
   goto ERROR
end

/* VERIFICAR DESEMBOLSO A CONFIRMAR */
if @i_operacion <> 'P' begin
   select @w_producto = dm_producto
   from ca_desembolso
   where  dm_operacion = @i_operacionca
   and    dm_cheque    = 0
   and    dm_idlote    = 0
   and    dm_monto_mn  = @i_valor
   and    dm_estado    = 'A'
   
   if @@rowcount = 0    begin
       select @w_error = 701121 --No existe desembolso
       goto ERROR
   end
end

/* OPCIONES DE PROCESO */
if @i_operacion = 'A' --Opcion de confirmacion de aplicacion del pago en ATX o Servicios Bancarios
begin
    if @w_producto = @w_pa_cheger --Confirmacion de aplicacion del desembolso con cheque de gerencia
    begin
       --ACTUALIZAR SOLO SI CUMPLE OPERACION, CHEQUE, VALOR IDLOTE( SI NO RETORNAR CODIGO ERROR)
       update ca_desembolso
       set dm_cheque     = @i_cheque,
           dm_idlote     = @i_idlote,
           dm_secuencial = @i_secuencial
       where  dm_operacion	= @i_operacionca
       and    dm_monto_mn  = @i_valor
       and    dm_estado    = 'A'
    end
    else begin --Confirmacion de aplicacion del desembolso efectuado en otro tipo de pago
       --ACTUALIZAR SOLO SI CUMPLE OPERACION, VALOR( SI NO RETORNAR CODIGO ERROR)
       update ca_desembolso
       set dm_secuencial = @i_secuencial
       where  dm_operacion	= @i_operacionca
       and    dm_monto_mn  = @i_valor
       and    dm_estado    = 'A'  --MRoa: Cambiar el valor por un parámetro
    end
end

if @i_operacion = 'P' begin --Opcion de confirmacion de pago en Servicios bancarios
   update ca_desembolso
   set dm_pagado       = @i_pagado,
       dm_cheque       = @i_cheque
   where  dm_operacion = @i_operacionca
   and    dm_estado    = 'A'
end

return 0

ERROR:
   exec cobis..sp_cerror 
        @t_debug = 'N',
        @t_file  = '',  
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return @w_error
 
go