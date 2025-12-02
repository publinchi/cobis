/********************************************************************/
/*    NOMBRE LOGICO:       sp_deudas_cli                            */
/*    NOMBRE FISICO:       sp_deudas_cli.sp                         */
/*    BASE DE DATOS:       cob_credito                              */
/*    PRODUCTO:            Credito                                  */
/*    DISENADO POR:        P. Jarrin                                */
/*    FECHA DE ESCRITURA:  30-Ene-2023                              */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                           PROPOSITO                              */
/*   Obtiene el valor de deudas de un cliente                       */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  30-Ene-2023    P. Jarrin.       Emision Inicial  - S769991      */
/*  28-Jul-2023    P. Jarrin.       Se modifica destino - S866039   */
/*  18-Sep-2023    P. Jarrin.       Ajuste regla B903813-R215336    */
/********************************************************************/

use cob_credito
go

set ANSI_nullS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_deudas_cli')
   drop proc sp_deudas_cli
go

create proc sp_deudas_cli(
        @s_ssn                      int         = null,
        @s_user                     login       = null,
        @s_sesn                     int         = null,
        @s_term                     descripcion = null,
        @s_date                     datetime    = null,
        @s_srv                      varchar(30) = null,
        @s_lsrv                     varchar(30) = null,
        @s_rol                      smallint    = null,
        @s_ofi                      smallint    = null,
        @s_org_err                  char(1)     = null,
        @s_culture                  varchar(10) = 'NEUTRAL',
        @s_error                    int         = null,
        @s_sev                      tinyint     = null,
        @s_msg                      descripcion = null,
        @s_org                      char(1)     = null,
        @t_rty                      char(1)     = null,
        @t_trn                      int         = null,
        @t_debug                    char(1)     = 'N',
        @t_file                     varchar(14) = null,
        @t_from                     varchar(30) = null,
        @t_show_version             bit         = 0,
        @i_cliente                  int         ,
        @o_deuda_corto_plazo        money       = 0 out,
        @o_deuda_largo_plazo        money       = 0 out,
        @o_cuota_mensual            money       = 0 out
)
as
declare 
        @w_sp_name                varchar(32),
        @w_sp_msg                 varchar(100),
        @w_return                 int,
        @w_error                  int,
        @w_dias_anio              int,
        @w_fecha                  datetime,
        @w_id                     int, 
        @w_cliente                int, 
        @w_operacion              int,
        @w_toperacion             varchar(10),
        @w_destino_eco            varchar(10),
        @w_fecha_ini              datetime,
        @w_monto                  money,
        @w_cuota                  money,
        @w_tdividendo             varchar(10),
        @w_variables              varchar(64),
        @w_return_variable        varchar(25),
        @w_return_results         varchar(25),
        @w_return_results_rule    varchar(25),
        @w_last_condition_parent  varchar(10),
        @w_saldo                  money,
        @w_deuda_corto_plazo      money,
        @w_deuda_largo_plazo      money,
        @w_cuota_mensual          money ,
        @w_td_factor              int,
        @w_deuda_corto_plazo_f    money, 
        @w_deuda_largo_plazo_f    money,
        @w_cuota_mensual_f        money,
        @w_fecha_proceso          datetime
        
select  @w_sp_name                = "sp_deudas_cli",
        @w_id                     = 0,
        @w_operacion              = 0,
        @w_toperacion             = '',
        @w_destino_eco            = '',
        @w_monto                  = 0,
        @w_cuota                  = 0,
        @w_variables              = '',
        @w_return_variable        = '',
        @w_return_results         = '',
        @w_return_results_rule    = '',
        @w_last_condition_parent  = '',
        @w_saldo                  = 0,
        @w_deuda_corto_plazo      = 0,
        @w_deuda_largo_plazo      = 0,
        @w_cuota_mensual          = 0,
        @w_deuda_corto_plazo_f    = 0,
        @w_deuda_largo_plazo_f    = 0,
        @w_cuota_mensual_f        = 0
            
        
select @w_dias_anio = pa_smallint
 from cobis..cl_parametro
where pa_producto = 'ADM' 
  and pa_nemonico = 'DIA'
  
select @w_fecha_proceso = fp_fecha 
from cobis..ba_fecha_proceso
  
         
IF OBJECT_ID('tempdb..#tmp_datos') IS NOT NULL
 drop table #tmp_datos
  
create table #tmp_datos
(
id                 int          not null identity(1,1),
cliente            int          null,
operacion          int          null,
banco              varchar (24) null,
toperacion         varchar (10) null,
destino            varchar (10) null,
fecha_ini          datetime     null,
fecha              datetime     null,
monto              money        null,
cuota              money        null,
tdividendo         varchar(10)  null,
factor             int          null,
excluye            char(1)      null,
saldo              money        null,
deuda_corto_plazo  money        null,
deuda_largo_plazo  money        null,
cuota_mensual      money        null
)

insert into #tmp_datos
select op_cliente, op_operacion, op_banco, ltrim(rtrim(op_toperacion)),(select ltrim(rtrim(isnull(tr_cod_actividad,'N')))  from cob_credito..cr_tramite  where tr_tramite = op_tramite), op_fecha_ini, null, 
       isnull(op_monto,0), isnull(op_cuota,0), op_tdividendo, 0, 'S', 0, 0, 0, 0
 from cob_cartera..ca_operacion 
 where op_cliente =  @i_cliente
   and op_estado not in (0,3,6,99)
order by op_operacion
     
declare cursor_ope_cli cursor
    for select id, cliente, operacion, toperacion, destino, fecha_ini, monto, cuota, tdividendo from #tmp_datos order by id
open cursor_ope_cli
fetch next from cursor_ope_cli into @w_id, @w_cliente, @w_operacion, @w_toperacion, @w_destino_eco, @w_fecha_ini, @w_monto, @w_cuota, @w_tdividendo
    
while @@fetch_status = 0
begin   
    select @w_variables = @w_destino_eco + '|' + @w_toperacion
    exec @w_return                 = cob_pac..sp_rules_param_run
         @s_rol                   = @s_rol,
         @i_rule_mnemonic         = 'VALOPE',
         @i_var_values            = @w_variables,
         @i_var_separator         = '|',
         @o_return_variable       = @w_return_variable  out,
         @o_return_results        = @w_return_results   out,
         @o_last_condition_parent = @w_last_condition_parent out

      if @w_return != 0
      begin
         close cursor_ope_cli
         deallocate cursor_ope_cli
         select @w_return  = @w_return
         goto ERROR_FIN
      end
      else
      begin        
        select @w_return_results_rule = replace(@w_return_results,'|','')
        if (@w_return_results_rule != '0')
        begin
            select @w_fecha = (dateadd(dd, @w_dias_anio, @w_fecha_proceso))
            select @w_td_factor = td_factor from cob_cartera..ca_tdividendo where  td_tdividendo = @w_tdividendo
            
            select @w_saldo = sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
              from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
             where am_operacion = di_operacion 
               and am_operacion = @w_operacion
               and am_dividendo = di_dividendo 
               and di_estado not in (3)
            
            select @w_deuda_corto_plazo = sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
              from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
             where am_operacion = di_operacion 
               and am_operacion = @w_operacion
               and am_dividendo = di_dividendo 
               and di_estado not in (3)
               and di_fecha_ven <= @w_fecha
               
            select @w_deuda_largo_plazo = @w_saldo - @w_deuda_corto_plazo
            select @w_cuota_mensual = (@w_cuota * 30 / @w_td_factor)
            
            update #tmp_datos 
              set excluye           = 'N', 
                  fecha             = @w_fecha,
                  factor            = @w_td_factor,
                  saldo             = @w_saldo,
                  deuda_corto_plazo = @w_deuda_corto_plazo, 
                  deuda_largo_plazo = @w_deuda_largo_plazo, 
                  cuota_mensual     = @w_cuota_mensual
            where id = @w_id   

            select @w_saldo = 0, @w_deuda_corto_plazo = 0, @w_deuda_largo_plazo = 0, @w_cuota_mensual = 0           
        end
      end
     fetch next from cursor_ope_cli into @w_id, @w_cliente, @w_operacion, @w_toperacion, @w_destino_eco, @w_fecha_ini, @w_monto, @w_cuota, @w_tdividendo
end  
close cursor_ope_cli
deallocate cursor_ope_cli

select @w_deuda_corto_plazo_f = sum(deuda_corto_plazo),
       @w_deuda_largo_plazo_f = sum(deuda_largo_plazo),
       @w_cuota_mensual_f     = sum(cuota_mensual)
 from #tmp_datos
where excluye = 'N'

select @o_deuda_corto_plazo = isnull(@w_deuda_corto_plazo_f,0), 
       @o_deuda_largo_plazo = isnull(@w_deuda_largo_plazo_f,0),
       @o_cuota_mensual     = isnull(@w_cuota_mensual_f,0) 
       
return 0

ERROR_FIN:
select @o_deuda_corto_plazo = 0,
       @o_deuda_largo_plazo = 0,
       @o_cuota_mensual     = 0 

exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_return     
return @w_return

go
