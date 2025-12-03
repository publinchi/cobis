/************************************************************************/
/*  Archivo:            carubconac.sp                                   */
/*  Stored procedure:   sp_rubro_cond_ac                                */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:       Gabriel Alvis                                   */
/*  Fecha de escritura: 06/Ene/2011                                     */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Generacion de tabla temporal con rubros de condonacion para         */
/*  operaciones con acuerdo de pago                                     */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA         AUTOR             RAZON                               */
/************************************************************************/

use cob_cartera
go

if object_id('sp_rubro_cond_ac') is not null
   drop proc sp_rubro_cond_ac
go

create proc sp_rubro_cond_ac
@i_operacionca          int          = null,
@i_sec_acuerdo          int          = null,
@i_decimales            tinyint      = null
as

declare
@w_est_vigente                tinyint,
@w_est_no_vigente             tinyint,
@w_est_vencido                tinyint,
@w_est_cancelado              tinyint,
@w_cap_cond                   money,
@w_int_cond                   money,
@w_imo_cond                   money,
@w_otr_cond                   money,
@w_monto_otros                money,
@w_monto_parcial              money,
@w_monto_cond                 money,
@w_tacuerdo                   char(1),
@w_param_cap                  varchar(30),
@w_param_int                  varchar(30),
@w_param_mora                 varchar(30),
@w_param_honabo               varchar(30),
@w_param_ivahonabo            varchar(30),
@w_concepto                   catalogo


/** LECTURA DE CA_ESTADO **/
select 
@w_est_no_vigente = 0,
@w_est_vigente    = 1,
@w_est_vencido    = 2,
@w_est_cancelado  = 3

-- PARAMETROS DE CONCEPTOS
select @w_param_cap = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'CAP'
and    pa_producto = 'CCA'

if @@rowcount = 0 
   return 701060

select @w_param_int = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'

if @@rowcount = 0 
   return 701059

select @w_param_mora = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'IMO'
and    pa_producto = 'CCA'

if @@rowcount = 0 
   return 701084

select @w_param_honabo = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'HONABO'
and    pa_producto = 'CCA'

if @@rowcount = 0 
   return 701015

select @w_param_ivahonabo = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'IVAHOB'
and    pa_producto = 'CCA'

if @@rowcount = 0 
   return 701015

   
select 
@w_tacuerdo = ac_tacuerdo,
@w_cap_cond = ac_cap_cond, 
@w_int_cond = ac_int_cond,-- - ac_int_cond_pry,
@w_imo_cond = ac_imo_cond,-- - ac_imo_cond_pry,
@w_otr_cond = ac_otr_cond-- - ac_otr_cond_pry
from cob_credito..cr_acuerdo
where ac_acuerdo = @i_sec_acuerdo
and   ac_fecha_proy = (Select min(ac_fecha_proy) from cob_credito..cr_acuerdo where ac_acuerdo = @i_sec_acuerdo and ac_estado = 'V') 
if @@rowcount = 0
   return 2108033
   
-- CAPITAL
if @w_cap_cond > 0
   insert into #cond_x_acuerdo values(@w_param_cap, @w_cap_cond)

-- INTERES
if @w_int_cond > 0
   insert into #cond_x_acuerdo values(@w_param_int, @w_int_cond)

-- MORA
if @w_imo_cond > 0
   insert into #cond_x_acuerdo values(@w_param_mora, @w_imo_cond)

-- DISTRIBUCION DE OTROS RUBROS
if @w_otr_cond > 0
begin
   insert into #cond_x_acuerdo
   select am_concepto, sum(am_acumulado - am_pagado)
   from ca_dividendo, ca_amortizacion
   where di_operacion  = @i_operacionca
   and   di_estado    in (@w_est_vigente, @w_est_vencido)
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   am_concepto not in (@w_param_cap, @w_param_int, @w_param_mora, @w_param_honabo, @w_param_ivahonabo)
   group by am_concepto
   having sum(am_acumulado - am_pagado) > 0      

   select @w_monto_otros = sum(valor)
   from #cond_x_acuerdo
   where concepto not in (@w_param_cap, @w_param_int, @w_param_mora, @w_param_honabo, @w_param_ivahonabo)

   select top 1 
   @w_concepto = concepto
   from #cond_x_acuerdo
   where concepto not in (@w_param_cap, @w_param_int, @w_param_mora, @w_param_honabo, @w_param_ivahonabo)
   order by concepto

   update #cond_x_acuerdo
   set valor = round(@w_otr_cond * (cast(valor as float) / cast(@w_monto_otros as float)), @i_decimales)
   where concepto not in (@w_param_cap, @w_param_int, @w_param_mora, @w_param_honabo, @w_param_ivahonabo, @w_concepto)
   
   select @w_monto_parcial = sum(valor)
   from #cond_x_acuerdo
   where concepto not in (@w_param_cap, @w_param_int, @w_param_mora, @w_param_honabo, @w_param_ivahonabo, @w_concepto)

   -- AJUSTE DEL ULTIMO VALOR
   update #cond_x_acuerdo
   set valor = @w_otr_cond - @w_monto_parcial
   where concepto = @w_concepto      
end

return 0
go
