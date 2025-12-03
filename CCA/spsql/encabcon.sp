/************************************************************************/
/*   Archivo:              encabcon.sp                                  */
/*   Stored procedure:     sp_encab_consulta                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Juan Bernardo Quinche                        */
/*   Fecha de escritura:   Mayo 2008                                    */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                               PROPOSITO                              */
/*   Encabezado para realizar consultas generales                       */
/************************************************************************/
/*                             MODIFICACIONES                           */
/*   FECHA              AUTOR          RAZON                            */
/*   19-Enero-2012  Luis C. Moreno RQ293 Saldo por amort. reconocimiento*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_encab_consulta')
   drop proc sp_encab_consulta
go

create proc sp_encab_consulta
   @s_date              datetime    = null,
   @s_ssn               int         = null,
   @s_srv               varchar(30) = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_ofi               smallint    = null,
   @i_banco             cuenta      = null,
   @i_operacion         char(1)     = null,
   @i_formato_fecha     int         = null,
   @i_moneda            int         = null

as

declare
   @w_sp_name              varchar(32),
   @w_error                int,
   @w_estado_op            smallint,           
   @w_num_dec              tinyint,
   @w_moneda_nacional      tinyint,
   @w_operacionca          int,
   @w_fecha_ven            datetime,
   @w_di_fecha_ven         datetime,
   @w_est_no_vigente       tinyint,
   @w_est_vigente          tinyint,
   @w_est_vencido          tinyint,
   @w_est_cancelado        tinyint,
   @w_est_castigado        tinyint,
   @w_est_anulado          tinyint,
   @w_est_condonado        tinyint,
   @w_est_suspenso         tinyint,
   @w_vlr_x_amort          money     -- REQ 293: RECONOCIMIENTO GARANTIAS FNG Y USAID
   
/* CAPTURA NOMBRE DE STORED PROCEDURE */
select @w_sp_name = 'sp_encab_consulta'

/* ESTADOS DE CARTERA */
select @w_est_no_vigente = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'NO VIGENTE'

select @w_est_vigente = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'CANCELADO'

select @w_est_castigado = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'CASTIGADO'

select @w_est_anulado = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'ANULADO'

select @w_est_condonado = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'CONDONADO'

select @w_est_suspenso = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'SUSPENSO'


exec @w_error = sp_decimales
     @i_moneda    = @i_moneda,
     @o_decimales = @w_num_dec out

/* CODIGO DE LA MONEDA LOCAL */
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

/* SELECCIONA LA OPERACION */
if @i_operacion = 'T' -- Todas las operaciones independiente de su estado
begin
   select @w_operacionca = op_operacion,
          @w_fecha_ven   = op_fecha_fin
   from   ca_operacion
   where  op_banco   = @i_banco
   
end
else
begin    --cuando es 'Q', Realiza esta consulta
   select @w_operacionca = op_operacion,
          @w_fecha_ven   = op_fecha_fin
   from   ca_operacion
   where  op_banco   = @i_banco
   and    op_estado  in (@w_est_vigente,@w_est_vencido,@w_est_suspenso,@w_est_cancelado)
   if @@rowcount = 0
   begin
      select @w_error = 701010
      goto ERROR
   end  
end

if @i_operacion='Q' or @i_operacion = 'T'
begin
    select @w_di_fecha_ven = di_fecha_ven
    from   ca_dividendo
    where  di_operacion = @w_operacionca
    and    di_estado    = 1  -- Dividendo vigente
   
    select @w_di_fecha_ven = isnull(@w_di_fecha_ven, @w_fecha_ven)
   
    /* LCM - 293: CONSULTA LA TABLA DE RECONOCIMIENTO PARA VALIDAR SI LA OBLIGACION TIENE RECONOCIMIENTO */
    select @w_vlr_x_amort = 0

    select @w_vlr_x_amort = pr_vlr - pr_vlr_amort
    from ca_pago_recono with (nolock)
    where pr_operacion = @w_operacionca
    and   pr_estado    = 'A'

    /* DATOS DE LA CABECERA */
    select op_toperacion,
           op_oficina,
           op_banco,
           op_moneda,
           op_oficial,
           convert(varchar, op_fecha_fin, @i_formato_fecha),   
           convert(float, op_monto_aprobado), 
           convert(float, op_monto), 
           es_descripcion,
           op_cliente,
           op_nombre,
           convert(varchar, @w_di_fecha_ven, @i_formato_fecha),
           convert(varchar, op_fecha_ult_proceso, @i_formato_fecha),
           convert(float, @w_vlr_x_amort)--RQ293 Saldo amortizacion reconocimiento
    from   ca_operacion, ca_estado
    where  op_operacion = @w_operacionca
    and    es_codigo    = op_estado
end

return 0

ERROR:

exec cobis..sp_cerror
     @t_debug = 'N',
     @t_from  = @w_sp_name,
     @i_num   = @w_error
return @w_error
                                                    
go

