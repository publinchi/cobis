
/************************************************************************/
/*   NOMBRE LOGICO:      pagnoapl.sp                                    */
/*   NOMBRE FISICO:      sp_pagos_noaplicados                           */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       MPO                                            */
/*   FECHA DE ESCRITURA: Ene. 1998                                      */
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
/*                         MODIFICACIONES                               */
/*      FECHA        AUTOR          CAMBIO                              */
/*     NOV.2015      EPB             Tiket0285483 Banamia manejo        */
/*                                     @i_en_linea                      */
/*     AGO.2023      Kevin Rodríguez R214639 No aplicar pagos anteriores*/
/*                                   a la Migración                     */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pagos_noaplicados')
   drop proc sp_pagos_noaplicados
go

create proc sp_pagos_noaplicados
@s_user                 login = null,
@s_term                 varchar(30) = null,
@s_date                 datetime = null,
@s_ofi                  smallint = null,
@s_ssn                  int = null,
@s_sesn			        int = null,
@s_srv                  varchar(30) = null,
@i_secuencial_ing       int,
@i_banco                cuenta,
@i_en_linea             char(1) = 'S'
as  
declare 
@w_error		        int,
@w_sp_name		        descripcion,
@w_fecha_ult_proceso	datetime,
@w_return		        int,
@w_ab_estado		    char(10),
@w_operacionca          int,
@w_concepto_int         catalogo,
@w_fecha_pago           datetime,
@w_secuencial_pag       int,
@w_oficial              int,
@w_periodo_int          smallint,
@w_gar_admisible        char(1),
@w_oficina              int,
@w_causacion            char(1),
@w_monto		        money,
@w_periodicidad         catalogo,
@w_moneda		        tinyint,
@w_estado               tinyint,
@w_toperacion		    catalogo,
@w_dias_anio            smallint,
@w_base_calculo         char(1),
@w_moneda_nacional      tinyint,
@w_cotizacion_hoy       money,
@w_op_tipo              char(1),
@w_tran_mig             int


-- INICIALIZACION DE VARIABLES 
select @w_sp_name = 'sp_pagos_noaplicados'


select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


-- SACAR EN NUMERO DE LA OPERACION 
select 
   @w_operacionca       = op_operacion,
   @w_monto             = op_monto,
   @w_toperacion        = op_toperacion,
   @w_estado            = op_estado,
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
   @w_periodo_int       = op_periodo_int,
   @w_periodicidad      = op_tdividendo,
   @w_dias_anio         = op_dias_anio,
   @w_base_calculo      = op_base_calculo,
   @w_oficial           = op_oficial,
   @w_oficina           = op_oficina,
   @w_gar_admisible     = op_gar_admisible,
   @w_moneda            = op_moneda,
   @w_op_tipo           = op_tipo
from ca_operacion
where op_banco = @i_banco

-- INFORMACION DEL ABONO A APLICAR 
select @w_ab_estado  = ab_estado,
       @w_fecha_pago = ab_fecha_pag
from ca_abono
where ab_secuencial_ing = @i_secuencial_ing
  and ab_operacion      = @w_operacionca

if @@rowcount = 0 
begin
   select @w_error = 710001
   goto ERROR
end

-- LA FECHA DE PROCESO DE LA OPERACION DEBE SER IGUAL A LA FECHA DE APLICACION DEL PAGO
if @w_fecha_ult_proceso <>   @w_fecha_pago
begin
   select @w_error = 710069
   goto ERROR        
end

-- Secuencial de transacción de Migración
select @w_tran_mig = tr_secuencial 
from ca_transaccion with (nolock)
where tr_operacion = @w_operacionca
and tr_tran = 'MIG'
and tr_estado <> 'RV'

if  @i_secuencial_ing < @w_tran_mig -- KDR Pagos No aplicados antes de la Migración no se aplican
begin
   select @w_error = 725298 -- Existen pagos no aplicados anteriores a la transacción de Migración, los cuales no se aplicarán
   goto ERROR        
end

--DETERMINAR EL VALOR DE COTIZACION DEL DIA
if @w_moneda = @w_moneda_nacional
   select @w_cotizacion_hoy = 1.0
else
begin
   exec sp_buscar_cotizacion
        @i_moneda     = @w_moneda,
        @i_fecha      = @w_fecha_ult_proceso,
        @o_cotizacion = @w_cotizacion_hoy output
end

begin tran
-- APLICACION DEL PAGO
if @w_ab_estado = 'ING' 
begin
   exec @w_return = sp_registro_abono
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @s_sesn           = @s_sesn,
   @s_ssn            = @s_ssn,
   @i_secuencial_ing = @i_secuencial_ing,
   @i_fecha_proceso  = @s_date,
   @i_operacionca    = @w_operacionca,
   @i_cotizacion     = @w_cotizacion_hoy,
   @i_en_linea       = @i_en_linea

   if @w_return <>  0 
   begin
      select @w_error = @w_return
      goto ERROR
   end    
end

if @w_ab_estado in ('ING','NA') and @w_op_tipo <> 'D'
begin
   exec @w_return = sp_cartera_abono
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_sesn           = @s_sesn,
   @s_ofi            = @s_ofi,
   @i_secuencial_ing = @i_secuencial_ing,
   @i_fecha_proceso  = @s_date,
   @i_operacionca    = @w_operacionca,
   @i_cotizacion     = @w_cotizacion_hoy,
   @i_en_linea       = @i_en_linea

   if @w_return <> 0 
   begin
      select @w_error = @w_return
      goto ERROR
   end  
end
ELSE
if @w_op_tipo = 'D' 
begin

   exec @w_return = sp_cartera_abono_dd
   @s_user           = @s_user,
   @s_srv            = @s_srv,            
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_sesn           = @s_sesn,
   @s_ssn            = @s_ssn,
   @s_ofi            = @s_ofi,
   @i_secuencial_ing = @i_secuencial_ing,
   @i_operacionca    = @w_operacionca,
   @i_fecha_proceso  = @s_date,
   @i_en_linea       = @i_en_linea,
   @i_cotizacion     = @w_cotizacion_hoy

   if @w_return <> 0 
   begin
      select @w_error = @w_return
      goto ERROR
   end  
                 
end           
                       


commit tran

return 0

ERROR:
  if @i_en_linea = 'S'
  begin
   exec cobis..sp_cerror
   @t_debug='N',    
   @t_file=null,
   @t_from=@w_sp_name,
   @i_num = @w_error
   return @w_error  
  end
  ELSE
  begin
    PRINT 'Error Fuera De linea'
	return @w_error
  end
go

