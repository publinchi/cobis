/************************************************************************/
/*      NOMBRE LOGICO:          situacion_grupal.sp                     */
/*      NOMBRE FISICO:          sp_situacion_grupal                     */
/*      BASE DE DATOS:          cob_cartera                             */
/*      PRODUCTO:               Cartera                                 */
/*      DISENADO POR:           Kevin Rodríguez                         */
/*      FECHA DE ESCRITURA:     Mayo 2023                               */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Consulta de la Situación de un préstamo grupal                      */
/*                                                                      */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA             AUTOR                   RAZON                     */
/*  11/MAY/2023    K. Rodríguez     Emisión inicial                     */
/*  27/11/2023     E. Medina        Filtro de operaciones anuladas      */
/*                                  R220205                             */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_situacion_grupal')
    drop proc sp_situacion_grupal
go

create proc sp_situacion_grupal (
@s_user             varchar(14)  = null,
@s_date             datetime     = null,
@s_ofi              smallint     = null,
@s_term             varchar (30) = null,
@t_timeout          int          = null,
@i_operacion        char(1)      = 'S',
@i_banco            varchar(24)  = null,
@i_formato_fecha    int          = 103,
@i_debug            char(1)      = 'N'
)
as

declare
@w_sp_name            varchar(32),
@w_error              int,
@w_operacionca        int,
@w_oficina_op         smallint,
@w_fecha_ult_proceso  datetime,
@w_nombre             varchar(64),
@w_tipo_cobro         char(1),
@w_toperacion         varchar(10),
@w_est_vigente        tinyint,
@w_est_cancelado      tinyint,
@w_est_anulado        tinyint,
@w_est_novigente      tinyint,
@w_est_credito        tinyint,
@w_est_suspenso       tinyint,
@w_fecha_proceso      datetime,
@w_grupo_op           int,
@w_oficial_op         smallint,
@w_grupo_desc         varchar(170),
@w_oficina_desc       varchar(170),
@w_oficial_desc       varchar(74),
@w_fecha_ini_op       datetime,
@w_fecha_fin_op       datetime,
@w_fecha_por_vencer   datetime

-- Variables iniciales
select @w_sp_name = 'sp_situacion_grupal'

select
@w_operacionca        = op_operacion,
@w_oficina_op         = op_oficina,
@w_oficial_op         = op_oficial,
@w_fecha_ini_op       = op_fecha_ini,
@w_fecha_fin_op       = op_fecha_fin,
@w_nombre             = op_nombre,
@w_tipo_cobro         = op_tipo_cobro,
@w_toperacion         = op_toperacion,
@w_grupo_op           = op_grupo,
@w_fecha_ult_proceso  = op_fecha_ult_proceso
from ca_operacion
where op_banco = @i_banco

if @@rowcount = 0
begin
   select @w_error = 701013 -- No existe operación activa de cartera
   goto ERROR  
end

-- ESTADOS DE CARTERA
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_credito    = @w_est_credito   out


if @@error <> 0
begin
    set @w_error = 710251 -- Error en consulta de tabla cob_cartera..ca_estado
    goto ERROR
end

select @w_fecha_proceso = fp_fecha 
from cobis..ba_fecha_proceso

if @i_operacion = 'S' -- Search
begin

   select @w_oficina_desc = convert(varchar(10), of_oficina,-1) + '-' + of_nombre 
   from cobis..cl_oficina 
   where of_oficina = @w_oficina_op
   
   select @w_oficial_desc = convert(varchar(10), oc_oficial,-1) + '-' + fu_nombre
   from cobis..cc_oficial, cobis..cl_funcionario 
   where oc_oficial = @w_oficial_op 
   and oc_funcionario = fu_funcionario

   select @w_grupo_desc = convert(varchar(10), gr_grupo,-1) + '-' + gr_nombre
   from cobis..cl_grupo 
   where gr_grupo = @w_grupo_op
   
   select @w_grupo_desc = isnull(@w_grupo_desc, @w_nombre)
     
   select @w_fecha_por_vencer = di_fecha_ven
   from ca_dividendo  
   where di_operacion = @w_operacionca
   and ((di_fecha_ini < @w_fecha_proceso AND di_dividendo > 1) 
        or (di_fecha_ini <= @w_fecha_proceso AND di_dividendo = 1))
   and di_fecha_ven >= @w_fecha_proceso
     
   
   if object_id('tempdb..#situacion_grupal') is not null
      drop table #situacion_grupal
	  
   create table #situacion_grupal(
   cliente_id      int         null,
   cliente         descripcion null,
   cuota           money       null,
   monto           money       null,
   monto_ven_cap   money       null,
   monto_ven_int   money       null,
   monto_ven_imo   money       null,
   monto_ven_otros money       null,
   monto_ven_total money       null,
   monto_vig_cap   money       null,
   monto_vig_int   money       null,
   monto_vig_otros money       null,
   monto_vig_total money       null,
   monto_deu_act   money       null,
   monto_sal_tot   money       null)

		 
   exec @w_error = sp_proyeccion_cuota
   @s_user             = @s_user,
   @s_date             = @s_date,
   @s_ofi              = @s_ofi,
   @s_term             = @s_term,
   @i_operacion        = 'G',
   @i_banco            = @i_banco,
   @i_fecha            = @w_fecha_proceso,
   @i_tipo_cobro       = @w_tipo_cobro,
   @i_formato_fecha    = @i_formato_fecha,
   @i_desde_sit_grupal = 'S',
   @i_debug            = 'N'
	
	
   select 
   'OFICINA'        = @w_oficina_desc,
   'ASESOR'         = @w_oficial_desc,
   'OPERACION'      = @i_banco,
   'GRUPO'          = @w_grupo_desc,
   'PAGOS_AL'       = substring(convert(varchar, isnull(@w_fecha_proceso, '01/01/1900'), @i_formato_fecha),1,15),
   'FECHA_CONCESION'= substring(convert(varchar, isnull(@w_fecha_ini_op, '01/01/1900'), @i_formato_fecha),1,15),
   'FECHA_VENCIMIEN'= substring(convert(varchar, isnull(@w_fecha_fin_op, '01/01/1900') , @i_formato_fecha),1,15),
   'FECHA_POR_VEN'  = substring(convert(varchar, isnull(@w_fecha_por_vencer, '01/01/1900'), @i_formato_fecha),1,15),
   'FECHA_IMPR'     = substring(convert(varchar, isnull(@w_fecha_proceso, '01/01/1900'), @i_formato_fecha),1,15),
   'PRODUCTO'       = @w_toperacion
   
   select
   'CLIENTE'     = cliente_id,
   'NOMBRE'      = cliente,
   'CUOTA'       = cuota,
   'MONTO'       = monto,
   'CAP_VEN'     = monto_ven_cap,
   'INT_VEN'     = monto_ven_int,
   'MORA'        = monto_ven_imo,
   'OTROS_VEN'   = monto_ven_otros,
   'TOTAL_VEN'   = monto_ven_total,
   'CAP_VIG'     = monto_vig_cap,
   'INT_VIG'     = monto_vig_int,
   'OTROS_VIG'   = monto_vig_otros,
   'TOTAL_VIG'   = monto_vig_total,
   'DEUDA_ACT'   = monto_deu_act,
   'SALDO_TOTAL' = monto_sal_tot 
   from #situacion_grupal 

   if object_id('tempdb..#situacion_grupal') is not null
      drop table #situacion_grupal
        
end

if @i_operacion = 'V' -- Validaciones previas a la generación de la Situación Grupal
begin

   select @w_operacionca = op_operacion
   from ca_operacion with (nolock)
   where op_grupal          ='S'
   and op_ref_grupal        = @i_banco
   and op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_suspenso,@w_est_credito)
   
   if @@rowcount = 0
   begin
      select @w_error = 725219 -- Error, la operación padre no tiene operaciones hijas asociadas o estas no están activas
      goto ERROR  
   end

   if exists (select 1
              from ca_operacion with (nolock)
              where op_grupal          ='S'
              and op_ref_grupal        = @i_banco
              and op_fecha_ult_proceso <> @w_fecha_proceso
			  and op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_suspenso,@w_est_credito))
   begin
       select @w_error = 711098 -- Error la fecha valor de las operaciones hijas es diferente a la fecha proceso
       goto ERROR
   end
   
end

return 0
	  
ERROR:

if object_id('tempdb..#situacion_grupal') is not null
   drop table #situacion_grupal
   
   exec cobis..sp_cerror
   @t_debug='N',
   @t_file='',
   @t_from=@w_sp_name,
   @i_num = @w_error
   return @w_error
go
