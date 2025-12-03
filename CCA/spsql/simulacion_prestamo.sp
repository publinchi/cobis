/****************************************************************************/
/*      NOMBRE LOGICO:          simulacion_prestamo.sp                      */
/*      NOMBRE FISICO:          sp_simulacion_prestamo                      */
/*      BasE DE DATOS:          cob_cartera                                 */
/*      PRODUCTO:               Cartera                                     */
/*      DISENADO POR:                                                       */
/*      FECHA DE ESCRITURA:                                                 */
/****************************************************************************/
/*                     IMPORTANTE                                           */
/*   Este programa es parte de los paquetes bancarios que son               */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,          */
/*   representantes exclusivos para comercializar los productos y           */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida         */
/*   y regida por las Leyes de la República de España y las                 */
/*   correspondientes de la Unión Europea. Su copia, reproducción,          */
/*   alteración en cualquier sentido, ingeniería reversa,                   */
/*   almacenamiento o cualquier uso no autorizado por cualquiera            */
/*   de los usuarios o personas que hayan accedido al presente              */
/*   sitio, queda expresamente prohibido; sin el debido                     */
/*   consentimiento por escrito, de parte de los representantes de          */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto          */
/*   en el presente texto, causará violaciones relacionadas con la          */
/*   propiedad intelectual y la confidencialidad de la información          */
/*   tratada; y por lo tanto, derivará en acciones legales civiles          */
/*   y penales en contra del infractor según corresponda.                   */
/****************************************************************************/
/*                              PROPOSITO                                   */
/*  Este programa realiza la generacion de estados en cuenta de cartera     */
/****************************************************************************/
/*                           MODIFICACIONES                                 */
/*  FECHA           AUTOR           RAZON                                   */
/*  07/07/2023   K. Rodriguez     Cambio tipo dato var local sector y clase */
/*  07/07/2023   E. Baez          R214665 Error Simulación fecha fija y dia */
/*                                de pago.                                  */
/*  02/10/2023   M. Cordova       Setear variable valor @w_tipo_cobro = P   */
/*  09/07/2024   B. Dueñas        Agregar mora y tea en tabla amort de simu */
/****************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_simulacion_prestamo')
   drop proc sp_simulacion_prestamo
go

create proc sp_simulacion_prestamo (
    @i_cliente      int         = 0,
    @i_toperacion   varchar(10),
    @i_moneda       int,
    @i_fecha_ini    datetime    = null,
    @i_monto        money,
    @i_tasa         float       = null,
    @i_plazo        int         = null,
    @i_frecuencia   varchar(10) = null,
    @i_borra_tmp    char(1)     = 'S',
    @i_opcion       char(1)     = 'C',
    @i_banco        varchar(16) = null,
    @i_dia_pago     int         = null,
    @i_fecha_fija   char(1)     = null,
    @o_tasa         float       = null out,
    @o_banco        cuenta      = null out
)
as
declare @w_return               int,
        @w_msg                  varchar(255),
        @w_sp_name              varchar(30),
        @w_fecha                datetime,
        @w_cliente              int,
        @w_name_cliente         varchar(255),
        @w_ced_ruc              varchar(30),
        @w_comentario           varchar(255),
        --@w_periodo            char(1),
        @w_toperacion           catalogo,
        @w_monto                money,
        @w_oficial              int,
        @w_oficina              int,
        @w_ciudad               int,
        @w_sector               catalogo,
        @w_clase                catalogo,
        @w_destino              catalogo,
        @w_formato_fecha        int,
        @w_operacion            int,
        @w_user                 varchar(30),
        @w_sesn                 int,
        @w_moneda               tinyint,
        @w_dias_anio            smallint,
        @w_tipo_amortizacion    varchar(10),
        @w_tplazo               catalogo,
        @w_plazo                smallint,
        @w_tdividendo           catalogo,
        @w_periodo_cap          smallint,
        @w_periodo_int          smallint,
        @w_dist_gracia          char(1),
        @w_gracia_cap           smallint,
        @w_gracia_int           smallint,
        @w_dia_fijo             tinyint,
        @w_cuota                money,
        @w_evitar_feriados      char(1),
        @w_mes_gracia           tinyint,
        @w_dias_gracia          tinyint,
        @w_periodo_crecimiento  smallint,
        @w_tipo_crecimiento     char(1),
        @w_base_calculo         char(1),
        @w_dia_habil            char(1),
        @w_recalcular_plazo     char(1),
        @w_tipo_redondeo        tinyint,
        @w_causacion            char(1),
        @w_grupo_fact           int,
        @w_fila                 int,
        @w_no_fila              int,
        @w_dividendo            int,
        @w_tasa                 float,
        @w_tipo_cobro           char(1),
        @w_mora_retroactiva     char(1),
        @w_banco                VARCHAR(24),
        @w_tea                  float,
        @w_imo                  float,
        @w_mora                 float

-- CAPTURA NOMBRE DE STORED PROCEDURE
select @w_sp_name = 'sp_simulacion_prestamo'

if @i_opcion = 'C'
begin

if (@i_fecha_ini is null)
begin
    select  @w_fecha = fp_fecha from cobis..ba_fecha_proceso
end
else
begin
    select  @w_fecha = @i_fecha_ini
end

select  @w_monto        = @i_monto,
        @w_oficial      = 3,
        @w_oficina      = 1,
        @w_formato_fecha= 103,
        @w_ciudad       = 1,
        --@w_sector     = 2,
        --@w_clase      = 2,
        @w_destino      = '01',
        @w_toperacion   = @i_toperacion,
        @w_cliente      = @i_cliente,
        @w_moneda       = @i_moneda,
        @w_user         = 'admuser',
        @w_sesn         = 100

if (@i_cliente > 0)
begin
    if (@w_toperacion != 'GRUPAL')
    begin
        select  @w_name_cliente = en_nomlar,
                @w_ced_ruc      = en_ced_ruc,
                @w_comentario   = 'SIMULACION OPERACION ' + @i_toperacion
            from cobis..cl_ente
            where en_ente = @w_cliente
    end
    else
    begin
        select  @w_name_cliente = gr_nombre,
                @w_comentario   = 'SIMULACION OPERACION ' + @i_toperacion
        from cobis..cl_grupo
        where gr_grupo = @w_cliente
    end

    if (@@error != 0 or @@rowcount != 1)
    begin
        select @w_return = 710593
        goto ERRORFIN
    end
end
else
begin
    select  @w_name_cliente = 'CLIENTE TEMPORAL SIMULACION',
            @w_ced_ruc      = '9999999999',
            @w_comentario   = 'SIMULACION OPERACION ' + @i_toperacion,
            @w_cliente      = -1,
            @i_cliente      = -1
end

if (@w_toperacion = 'GRUPAL' and isnull(@i_frecuencia, 'W') = 'W' and isnull(@i_plazo, 4) = 4)
begin
    select @i_plazo = 16
end
else if (@w_toperacion = 'GRUPAL')
begin
    select @w_return = 724672
    goto ERRORFIN
end

select  @w_sector   = dt_clase_sector,
        @w_clase    = dt_clase_cartera
    from cob_cartera..ca_default_toperacion
    where dt_toperacion = @i_toperacion

if (@@error != 0 or @@rowcount != 1)
begin
    select @w_return = 701002
    goto ERRORFIN
end

exec @w_return  = cob_cartera..sp_codeudor_tmp
    @s_user         = @w_user,
    @s_sesn         = @w_sesn,
    @i_secuencial   = 1,
    @i_titular      = @w_cliente,
    @i_codeudor     = @w_cliente,
    @i_ced_ruc      = @w_ced_ruc,
    @i_rol          = 'D',
    @i_borrar       = 'S',
    --@i_borrar_codeu   = 'C',
    --@i_segvida    = '',
    --@t_trn            = 7005,
    @i_operacion    = 'A'

if @@error != 0 or @w_return != 0
begin
   -- select @w_return = case when @w_return > 0 then @w_return else 724658 end
   if @w_return > 0
      select @w_return = @w_return
   else
      select @w_return = 724658
      
   goto ERRORFIN
end
exec @w_return          = sp_crear_operacion
    @s_user             = @w_user,
    @s_ofi              = @w_oficina,
    --@i_tramite        = @w_tramite_0,
    @s_date             = @w_fecha,
    @s_term             = @w_user,
    @i_cliente          = @w_cliente,
    @i_nombre           = @w_name_cliente,
    @i_sector           = @w_sector,
    @i_toperacion       = @w_toperacion,
    @i_oficina          = @w_oficina,
    @i_moneda           = @w_moneda,
    @i_comentario       = @w_comentario,
    @i_oficial          = @w_oficial,
    @i_fecha_ini        = @w_fecha,
    @i_monto            = @w_monto,
    @i_monto_aprobado   = @w_monto,
    @i_destino          = @w_destino,
    @i_ciudad           = @w_ciudad,
    @i_formato_fecha    = @w_formato_fecha,
    @i_clase_cartera    = @w_clase,
    @i_salida           = 'N',
    @i_fondos_propios   = 'S',
    @i_origen_fondos    = '1',
    @i_batch_dd         = 'N',
    @i_banca            = '1',
    @i_simulacion       = 'S',
    @i_fecha_fija       = @i_fecha_fija,
    @i_grupal           = 'N',
    @i_no_banco         = 'N',
    @i_plazo            = @i_plazo,
    @i_tplazo           = @i_frecuencia,
    @i_tdividendo       = @i_frecuencia,
    @i_dia_pago         = @i_dia_pago,
    -- @i_tasa           = @w_tasa,
    --@t_trn                = 7010,
    ----@i_anterior         = '',
    ----@i_migrada          = '',
    ----@i_tipo_empresa     = '',
    ----@i_validacion       = '',
    ----@i_reestructuracion = '',
    ----@i_numero_reest     = '',
    ----@i_oper_pas_ext     = '',
     @o_banco          = @w_banco output

if @@error != 0 or @w_return != 0
begin
    --select @w_return = case when @w_return > 0 then @w_return else 724659 end
    if @w_return > 0
       select @w_return = @w_return
    else
       select @w_return = 724659
       
    goto ERRORFIN
end

SELECT @w_operacion=opt_operacion FROM cob_cartera..ca_operacion_tmp
WHERE  opt_banco=@w_banco

select
    @w_tipo_cobro           = opt_tipo_cobro,
    @w_tipo_amortizacion    = opt_tipo_amortizacion,
    @w_tipo_redondeo        = opt_tipo_redondeo,
    @w_base_calculo         = opt_base_calculo,
    @w_dias_anio            = opt_dias_anio,
    @w_gracia_cap           = opt_gracia_cap,
    @w_gracia_int           = opt_gracia_int,
    @w_dist_gracia          = opt_dist_gracia,
    @w_tplazo               = opt_tplazo,
    @w_plazo                = isnull(@i_plazo, opt_plazo),
    @w_tdividendo           = isnull(@i_frecuencia, opt_tdividendo),
    @w_periodo_cap          = opt_periodo_cap,
    @w_cuota                = opt_cuota,
    @w_evitar_feriados      = opt_evitar_feriados,
    @w_dia_habil            = opt_dia_habil,
    @w_recalcular_plazo     = opt_recalcular_plazo,
    @w_mora_retroactiva     = opt_mora_retroactiva,
    @w_dia_fijo             = opt_dia_fijo,
    @w_periodo_crecimiento  = opt_periodo_crecimiento,
    @w_dias_gracia          = 0,
    @w_cuota                = 0,
    @w_tasa                 = @i_tasa,
    @w_mes_gracia           = opt_mes_gracia,
    @w_tipo_crecimiento     = opt_tipo_crecimiento,
    @w_causacion            = opt_causacion,
    @w_grupo_fact           = opt_grupo_fact,
    @w_toperacion           = opt_toperacion,
    @w_moneda               = opt_moneda,
    @w_periodo_int          = opt_periodo_int
from cob_cartera..ca_operacion_tmp
where opt_operacion = @w_operacion

if (@@error != 0 or @@rowcount != 1)
begin
    select @w_return = 724660
    goto ERRORFIN
end

--if (@i_plazo is not null and @i_frecuencia is not null and @i_frecuencia <> 'M')
--begin
--  select @w_plazo = case  when @w_tdividendo = 'W' then @w_plazo * 4
--                          when @w_tdividendo = 'Q' then @w_plazo * 2
--                    end
--end

select @w_tipo_cobro = 'P' -- MCO cambio para que no seleccione el tipo de cobro de la operacion tmp Acumulado sino Proyectado a cuanto saldria a fin de mes


exec @w_return              = sp_modificar_operacion
    @i_tipo_amortizacion    = @w_tipo_amortizacion,
    @i_tipo_redondeo        = @w_tipo_redondeo,
    @i_base_calculo         = @w_base_calculo,
    @i_dias_anio            = @w_dias_anio,
    @i_gracia_cap           = @w_gracia_cap,
    @i_gracia_int           = @w_gracia_int,
    @i_banco                = @w_banco,
    @i_fecha_ini            = @w_fecha,
    @i_dist_gracia          = @w_dist_gracia,
    @i_tplazo               = @w_tplazo,
    @i_plazo                = @w_plazo,
    @i_tdividendo           = @w_tdividendo,
    @i_periodo_cap          = @w_periodo_cap,
    @i_fecha_fija           = @i_fecha_fija,
    --@i_operacion          = 'U',
    --@i_en_linea           = 'S',
    --@i_fecha_fija         = 'N',
    --@i_cuota_fija         = 'S', --'N',
    --@t_trn                = 7061,
    @i_cuota                = @w_cuota,
    @i_evitar_feriados      = @w_evitar_feriados,
    @i_ult_dia_habil        = @w_dia_habil,
    @i_recalcular           = @w_recalcular_plazo,
    @i_mora_retroactiva     = @w_mora_retroactiva,
    @i_dia_fijo             = @w_dia_fijo,
    @i_periodo_crecimiento  = @w_periodo_crecimiento,
    @i_dias_gracia          = @w_dias_gracia,
    @i_mes_gracia           = @w_mes_gracia,
    @i_tipo_crecimiento     = @w_tipo_crecimiento,
    @i_causacion            = @w_causacion,
    @i_grupo_fact           = @w_grupo_fact,
    @i_toperacion           = @w_toperacion,
    @i_moneda               = @w_moneda,
    @i_tasa                 = @w_tasa,
    @i_calcular_tabla       = 'S',
    @i_formato_fecha        = @w_formato_fecha,
    @i_periodo_int          = @w_periodo_int,
    @i_regenera_rubro       = 'S',
    @i_grupal               = 'N'

if @@error != 0 or @w_return != 0
begin
    --select @w_return = case when @w_return > 0 then @w_return else 724661 end
    if  @w_return > 0
      select @w_return = @w_return
    else
       select @w_return = 724661
       
    goto ERRORFIN
end

end -- Opcion 'C'

if @i_opcion = 'Q' or @i_opcion = 'C'
begin

select @w_banco = isnull(@i_banco, @w_banco)
select @w_operacion = opt_operacion
from cob_cartera..ca_operacion_tmp
where opt_banco = @w_banco

select @w_tea = isnull(round(convert(decimal(18,2), sum(rot_porcentaje)) , 2), 0)
from cob_cartera..ca_rubro_op_tmp, cob_cartera..ca_concepto
where rot_operacion = @w_operacion
and rot_concepto = co_concepto
and co_categoria = 'I'

select @w_imo = isnull(round(convert(decimal(18,2), sum(rot_porcentaje)), 2), 0)
from cob_cartera..ca_rubro_op_tmp, cob_cartera..ca_concepto
where rot_operacion = @w_operacion
and rot_concepto = co_concepto
and co_categoria = 'M'


select @w_mora = isnull((@w_imo - @w_tea), 0)

declare @resultado as table
(
    id_key      int identity,
    dividendo   int,
    fecha       datetime,
    saldo       money,
    capital     money,
    interes     money,
    iva         money,
    otros       money,
    total       money,
    mora        float,
    tea         float
)

insert into @resultado (dividendo, fecha, saldo, capital, interes, iva, otros, total, mora, tea)
    select dit_dividendo, dit_fecha_ven, 0, 0, 0, 0, 0, 0, @w_mora, @w_tea
    from cob_cartera..ca_dividendo_tmp
    where dit_operacion = @w_operacion
    order by dit_dividendo

if (@@error != 0)
begin
    select @w_return = 724662
    goto ERRORFIN
end

update @resultado set capital = isnull(case when @w_tipo_cobro = 'A' then
                                        (case when amt_acumulado + amt_gracia - amt_pagado < 0 then 0 else amt_acumulado + amt_gracia - amt_pagado end)
                                    else
                                        (amt_cuota - amt_pagado + amt_gracia)
                                    end, 0)
    from cob_cartera..ca_amortizacion_tmp
    where amt_operacion = @w_operacion
    and amt_concepto = 'CAP'
    and dividendo = amt_dividendo

if (@@error != 0)
begin
    select @w_return = 724663
    goto ERRORFIN
end

update @resultado set interes = isnull(case when @w_tipo_cobro = 'A' then
                                        (case when amt_acumulado + amt_gracia - amt_pagado < 0 then 0 else amt_acumulado + amt_gracia - amt_pagado end)
                                    else
                                        (amt_cuota - amt_pagado + amt_gracia)
                                    end, 0)
    from cob_cartera..ca_amortizacion_tmp
    where amt_operacion = @w_operacion
    and amt_concepto = 'INT'
    and dividendo = amt_dividendo

if (@@error != 0)
begin
    select @w_return = 724664
    goto ERRORFIN
end

update @resultado set iva = isnull(case when @w_tipo_cobro = 'A' then
                                        (case when amt_acumulado + amt_gracia - amt_pagado < 0 then 0 else amt_acumulado + amt_gracia - amt_pagado end)
                                    else
                                        (amt_cuota - amt_pagado + amt_gracia)
                                    end, 0)
    from cob_cartera..ca_amortizacion_tmp
    where amt_operacion = @w_operacion
    and amt_concepto = 'IVA_INT'
    and dividendo = amt_dividendo

if (@@error != 0)
begin
    select @w_return = 724665
    goto ERRORFIN
end

--LPO Cambiar esta sentencia:
/*
update a set otros = b.total
from @resultado a inner join (
            SELECT amt_dividendo, isnull(sum(case when @w_tipo_cobro = 'A' then
                                        (case when amt_acumulado + amt_gracia - amt_pagado < 0 then 0 else amt_acumulado + amt_gracia - amt_pagado end)
                                    else
                                        (amt_cuota - amt_pagado + amt_gracia)
                                    end), 0) as total
            from cob_cartera..ca_amortizacion_tmp
            where amt_operacion = @w_operacion
            and amt_concepto not in ('CAP', 'INT', 'IVA_INT')
            group by amt_dividendo) b
on a.dividendo = b.amt_dividendo
*/

CREATE TABLE #resul_parcial 
(rp_dividendo INT NULL, 
 rp_total     MONEY NULL)


INSERT INTO #resul_parcial (rp_dividendo, rp_total)
SELECT amt_dividendo, isnull(sum(case when @w_tipo_cobro = 'A' then
                                    (case when amt_acumulado + amt_gracia - amt_pagado < 0 then 0
                                     else amt_acumulado + amt_gracia - amt_pagado
                                      end)
                                 else
                                    (amt_cuota - amt_pagado + amt_gracia)
                                 end), 0)
from cob_cartera..ca_amortizacion_tmp
where amt_operacion = @w_operacion
  and amt_concepto not in ('CAP', 'INT', 'IVA_INT')
group by amt_dividendo


update @resultado
set otros = rp_total
FROM #resul_parcial
WHERE dividendo = rp_dividendo


if (@@error != 0)
begin
    select @w_return = 724666
    goto ERRORFIN
end

update @resultado set total = capital + interes + iva + otros

if (@@error != 0)
begin
    select @w_return = 724667
    goto ERRORFIN
end

select  @w_fila = min(id_key) from @resultado
select  @w_no_fila  = max(id_key) from @resultado

while @w_fila <= @w_no_fila
begin
    select @w_dividendo = dividendo from @resultado where id_key = @w_fila

    update a set saldo = b.total
        from @resultado a inner join (
            select sum(capital) as total
                from @resultado
                where dividendo > (@w_dividendo - 1)
        ) b on id_key = @w_fila

    if (@@error != 0)
    begin
        select @w_return = 724668
        goto ERRORFIN
    end

    select @w_fila = @w_fila + 1
end

select dividendo, fecha, saldo, capital, interes, iva, otros, total, mora, tea
    from @resultado

if (@@error != 0)
begin
    select @w_return = 724670
    goto ERRORFIN
END

select @o_tasa = rot_porcentaje
    from cob_cartera..ca_rubro_op_tmp
    where rot_operacion = @w_operacion
    and rot_concepto = 'INT'

if (@@error != 0 or @@rowcount != 1)
begin
    select @w_return = 724669
    goto ERRORFIN
end
set @o_banco = @w_banco
end -- Opcion = 'Q'


--PRINT 'ELIMINACION DE LA INFORMACION EN TEMPORALES'
if @i_borra_tmp = 'S'
begin
    exec @w_return = sp_borrar_tmp
         @s_sesn   = @w_sesn,
         @s_user   = @w_user,
         @s_term   = @w_user,
         @i_banco  = @w_banco
end

if @@error != 0 or @w_return != 0
begin
    --select @w_return = case when @w_return > 0 then @w_return else 724671 end
    if @w_return > 0
       select @w_return = @w_return
    else
       select @w_return = 724671
       
    goto ERRORFIN
end

return 0

ERRORFIN:

exec cobis..sp_cerror
    @t_debug= 'N',
    @t_file = null,
    @t_from = @w_sp_name,
    @i_num  = @w_return,
    @i_msg  = @w_msg

return @w_return


GO
