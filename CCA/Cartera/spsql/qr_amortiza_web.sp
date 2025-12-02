/************************************************************************/
/*   NOMBRE LOGICO:      qr_amortiza_web.sp                             */
/*   NOMBRE FISICO:      sp_qr_table_amortiza_web                       */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:                                                      */
/*   FECHA DE ESCRITURA:                                                */
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
/*                     PROPOSITO                                        */
/*   Consulta de la tabla de amortizacion de una operacion de cartera   */
/*   para la pantalla de Datos del Prestamo version CoreBase            */
/************************************************************************/
/*                              MODIFICACIONES                          */ 
/*    FECHA        AUTOR                        RAZON                   */ 
/* 16/Nov/2020   P.Narvaez     Columnas solo de rubros presentes en la  */
/*                             tabla                                    */
/* 23/Dic/2020   P.Narvaez     Grid Resumen con intereses incorrectos   */
/* 11/Ene/2021   P.Narvaez     Rubros anticipados, CoreBase             */
/* 05/May/2021   G.Fernandez   Suma cuotas de Op. Hijas en Op. Grupales */
/* 04/Ago/2022   K. Rodriguez  Ajuste condición de borrado tabla tmp    */
/*                             divs                                     */
/* 20/Ene/2023   J. Guzman     Ajuste para llamado de SP en consulta de */
/*                             operaciones grupales                     */
/* 28/Feb/2023   K. Rodriguez  S787837 Ajustes por tablas para uso de   */
/*                             reportería                               */
/* 28/Sep/2023   G. Fernandez  R216132 Cambio de calculo a precancelar  */
/* 19/Ago/2024   K. Rodriguez  R240986 Quita Ops hijas anuladas de Sal- */
/*                             dos operación Grupal                     */
/* 30/Sep/2024   A. Quishpe    R244659:Se añade nolock                  */
/************************************************************************/

use cob_cartera
go

if object_id ('sp_qr_table_amortiza_web') is not null
    drop procedure sp_qr_table_amortiza_web
go

create proc sp_qr_table_amortiza_web
(
    @s_date          datetime = null,
    @i_banco         cuenta,  --Numero de prestamo
    @i_opcion        char(1) = 'T', -- T: Todo, R: Rubros, I: Items, C: Consolidado,
	@i_desde_reporte char(1) = 'N', -- Desde reporte (No retorna resulset)
    @t_trn           INT     = NULL  --LPO CDIG Cambio de Servicios a Blis   
    
)
as
declare @w_operacionca             int,
        @w_num_cuota               int,
        @w_saldo_cap                money,
        @w_i                       int,
        @w_j                       int,
        @w_query                   varchar(400),
        @w_error                   int,
        @w_sp_name                 varchar(25),
        @w_est_cancelado           tinyint,
        @w_est_novigente           tinyint,
        @w_est_vigente             tinyint,
        @w_est_castigado           tinyint,
        @w_est_vencido             tinyint,
		@w_est_anulado             tinyint,
        @w_desc_estado             varchar(64),
        @w_cuotas                  int,
        @w_fecha_ult_proceso       datetime,
        @w_saldo_operacion_finan   money,
        @w_return                  int,
        @w_fecha                   datetime,
        @w_producto                tinyint,
        @w_numdec_op               smallint,
        @w_moneda                  SMALLINT,
        @w_tipo_grupal             CHAR(1),
        @w_tt_capital              MONEY,
        @w_tt_interes              MONEY,
        @w_tt_mora                 MONEY,
        @w_tt_int_mora             MONEY,
        @w_tt_otros                MONEY,
        @w_op_tipo_cobro           char(1),
        @w_div_vencido             char(1)
        
    create table #rubros_enamortiz (
    rubro catalogo )        

    select @w_sp_name = 'sp_qr_table_amortiza_web'

    select @w_producto = pd_producto
    from cobis..cl_producto
    where pd_abreviatura = 'CCA'

    select @w_fecha = convert(varchar(10),fc_fecha_cierre,101)
    from cobis..ba_fecha_cierre
    where fc_producto = @w_producto

    select @w_operacionca       = op_operacion,
           @w_moneda            = op_moneda,
           @w_fecha_ult_proceso = op_fecha_ult_proceso,
           @w_op_tipo_cobro     = op_tipo_cobro
    from   ca_operacion with (nolock)
    where  op_banco = @i_banco
    if @@rowcount = 0
    begin
        select @w_error =  710201
        goto ERROR
    end

    --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO:
    /*DETERMINA EL TIPO DE OPERACION ((G)rupal, (I)nterciclo, I(N)dividual)*/
    EXEC @w_return = sp_tipo_operacion
       @i_banco  = @i_banco,
       @o_tipo   = @w_tipo_grupal out

    IF @w_return <> 0
       RETURN @w_return
   --LPO TEC FIN NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO

    exec @w_return = sp_decimales
         @i_moneda    = @w_moneda,
         @o_decimales = @w_numdec_op out
         
    if @w_tipo_grupal = 'G'
    begin
       exec @w_return = sp_qr_table_amortiza_grupal
          @s_date  = @s_date,
          @i_banco = @i_banco
          
       if @w_return <> 0
       begin
          select @w_error = @w_return
          goto ERROR
       end
    end
    else
    begin
       delete ca_qr_rubro_tmp
       where  qrt_pid = @@spid
       
       delete ca_qr_amortiza_tmp
       where  qat_pid = @@spid
       
       --Solo desplegar los rubros que actualmente estan presentes en la tabla de amortizacion
       insert into #rubros_enamortiz
       select distinct am_concepto
       from ca_amortizacion with (nolock)
       where am_operacion = @w_operacionca
       
       insert into ca_qr_rubro_tmp (qrt_pid, qrt_rubro)
       select distinct @@spid, ro_concepto
       from ca_rubro_op with (nolock)
       where ro_operacion = @w_operacionca
       and   ro_fpago    <> 'L'  --solo los rubros que se descuentan en el desembolso no se añaden a la tabla de amortizacion
       and   ro_concepto in (select rubro from #rubros_enamortiz)
       order by ro_concepto
    end
    

    --Rubros
    if @i_opcion = 'R' or @i_opcion = 'T' and @i_desde_reporte = 'N'
    begin
        select co_descripcion, co_concepto
        from ca_qr_rubro_tmp, ca_concepto
        where qrt_pid = @@spid
        and qrt_rubro = co_concepto
        order by qrt_id
    end


    if @i_opcion = 'I' or @i_opcion = 'T'
    begin
    
       /* Se ejecuta lo siguiente unicamente cuando sea distinto de 'G', ya que el proceso de grupal
          se realiza en una validación anterior, ahí se ejecuta todo lo correspondiente y a lo ultimo
          de este siguiente 'if' retorna los valores correspondientes */
          
       if @w_tipo_grupal != 'G'
       begin
          --INSERT DE CUOTA
          insert into ca_qr_amortiza_tmp (qat_pid, qat_dividendo, qat_fecha_ini, qat_fecha_ven, qat_dias_cuota, qat_cuota,qat_estado,qat_porroga)
          select @@spid, di_dividendo, di_fecha_ini, di_fecha_ven,di_dias_cuota, sum(am_cuota + am_gracia), substring(es_descripcion,1,20),di_prorroga
          from ca_dividendo with (nolock), ca_amortizacion with (nolock), ca_estado with (nolock)
          where di_operacion = @w_operacionca
          and   am_operacion = di_operacion
          and   am_dividendo = di_dividendo
          and  di_estado    = es_codigo
          group by di_operacion, di_dividendo, di_fecha_ini,  di_fecha_ven, di_dias_cuota , di_prorroga, es_descripcion
          
          --ACTUALIZAR VALORES DE CADA RUBRO
          select @w_j = min(qrt_id)
          from   ca_qr_rubro_tmp
          where  qrt_pid = @@spid
          
          select @w_i = @w_j
          while @w_i <= @w_j + 14
          begin
             --IF EXISTS(SELECT 1 FROM tempdb..sysobjects WHERE name = '#tmp_dividendo')
             IF OBJECT_ID ('tempdb..#tmp_dividendo', 'U') IS NOT NULL  
             BEGIN
                DROP TABLE #tmp_dividendo
             END
             
             CREATE TABLE #tmp_dividendo (
                d_operacion INT NULL,
                d_dividendo INT NULL,
                d_qrt_id    INT NULL,
                d_qat_pid   INT NULL,
                saldo_cuota MONEY NULL
             )
             
             INSERT INTO #tmp_dividendo (d_operacion ,d_dividendo, d_qrt_id, d_qat_pid, saldo_cuota )           
             select di_operacion ,di_dividendo, qrt_id, qat_pid,  sum(am_cuota + am_gracia)
             from ca_dividendo with (nolock), ca_amortizacion with (nolock), ca_qr_rubro_tmp with (nolock), ca_qr_amortiza_tmp with (nolock) where di_operacion = @w_operacionca
             and am_operacion = di_operacion and am_dividendo = di_dividendo and qat_dividendo = di_dividendo
             and am_concepto = qrt_rubro and qrt_id = @w_i and qat_pid = @@spid and qat_pid = qrt_pid
             group by di_operacion , di_dividendo, qrt_id, qat_pid
             
             IF ((@w_i + 1 - @w_j) = 1)
                update ca_qr_amortiza_tmp set qat_rubro1 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 2)
                update ca_qr_amortiza_tmp set qat_rubro2 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 3)
                update ca_qr_amortiza_tmp set qat_rubro3 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 4)
                update ca_qr_amortiza_tmp set qat_rubro4 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 5)
                update ca_qr_amortiza_tmp set qat_rubro5 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 6)
                update ca_qr_amortiza_tmp set qat_rubro6 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 7)
                update ca_qr_amortiza_tmp set qat_rubro7 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 8)
                update ca_qr_amortiza_tmp set qat_rubro8 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 9)
                update ca_qr_amortiza_tmp set qat_rubro9 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 10)
                update ca_qr_amortiza_tmp set qat_rubro10 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 11)
                update ca_qr_amortiza_tmp set qat_rubro11 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 12)
                update ca_qr_amortiza_tmp set qat_rubro12 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 13)
                update ca_qr_amortiza_tmp set qat_rubro13 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 14)
                update ca_qr_amortiza_tmp set qat_rubro14 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid
             
             IF ((@w_i + 1 - @w_j) = 15)
                update ca_qr_amortiza_tmp set qat_rubro15 = saldo_cuota
                from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid            
                
             select @w_i = @w_i + 1   
          end -- end while rubros   

          --ACTUALIZACION DE VALORES DE RUBROS NEGATIVOS A CERO
          select @w_i = 1
          while @w_i <= 15
          begin   
             IF @w_i = 1
                update ca_qr_amortiza_tmp set qat_rubro1 = 0 where qat_rubro1 < 0
                and qat_pid = @@spid
             
             IF @w_i = 2
                update ca_qr_amortiza_tmp set qat_rubro2 = 0 where qat_rubro2 < 0
                and qat_pid = @@spid
             
             IF @w_i = 3
                update ca_qr_amortiza_tmp set qat_rubro3 = 0 where qat_rubro3 < 0
                and qat_pid = @@spid
             
             IF @w_i = 4
                update ca_qr_amortiza_tmp set qat_rubro4 = 0 where qat_rubro4 < 0
                and qat_pid = @@spid
             
             IF @w_i = 5
                update ca_qr_amortiza_tmp set qat_rubro5 = 0 where qat_rubro5 < 0
                and qat_pid = @@spid
             
             IF @w_i = 6
                update ca_qr_amortiza_tmp set qat_rubro6 = 0 where qat_rubro6 < 0
                and qat_pid = @@spid
             
             IF @w_i = 7
                update ca_qr_amortiza_tmp set qat_rubro7 = 0 where qat_rubro7 < 0
                and qat_pid = @@spid
             
             IF @w_i = 8
                update ca_qr_amortiza_tmp set qat_rubro8 = 0 where qat_rubro8 < 0
                and qat_pid = @@spid
             
             IF @w_i = 9
                update ca_qr_amortiza_tmp set qat_rubro9 = 0 where qat_rubro9 < 0
                and qat_pid = @@spid
             
             IF @w_i = 10
                update ca_qr_amortiza_tmp set qat_rubro10 = 0 where qat_rubro10 < 0
                and qat_pid = @@spid
             
             IF @w_i = 11
                update ca_qr_amortiza_tmp set qat_rubro11 = 0 where qat_rubro11 < 0
                and qat_pid = @@spid
             
             IF @w_i = 12
                update ca_qr_amortiza_tmp set qat_rubro12 = 0 where qat_rubro12 < 0
                and qat_pid = @@spid
             
             IF @w_i = 13
                update ca_qr_amortiza_tmp set qat_rubro13 = 0 where qat_rubro13 < 0
                and qat_pid = @@spid
             
             IF @w_i = 14
                update ca_qr_amortiza_tmp set qat_rubro14 = 0 where qat_rubro14 < 0
                and qat_pid = @@spid
             
             IF @w_i = 15
                update ca_qr_amortiza_tmp set qat_rubro15 = 0 where qat_rubro15 < 0
                and qat_pid = @@spid
             
             select @w_i = @w_i + 1
          end -- end while actualización valores de rubros
          
          --ACTUALIZACION DE VALORES DE CUOTA NEGATIVA A CERO
          update ca_qr_amortiza_tmp
          set    qat_cuota = 0
          where  qat_cuota <0
          and    qat_pid = @@spid
          
          --ACTUALIZACION DE COLUMNA SALDO DE CAPITAL
          select @w_num_cuota = 1
          while 1 = 1
          begin
              select @w_saldo_cap = 0
          
              select @w_saldo_cap = sum(qat_rubro1)
              from   ca_qr_amortiza_tmp
              where  qat_dividendo >= @w_num_cuota
              and    qat_pid = @@spid
          
              if isnull(@w_saldo_cap, 0) = 0
              break
          
              update ca_qr_amortiza_tmp
              set    qat_saldo_cap = @w_saldo_cap
              where  qat_dividendo = @w_num_cuota
              and    qat_pid = @@spid
          
              select @w_num_cuota = @w_num_cuota + 1
          end
       end

       if @i_desde_reporte = 'N'
          /* Retorna los valores al Frontend sin importar el tipo de la operación */
          select qat_dividendo,
                 qat_fecha_ven,
                 qat_dias_cuota,
                 qat_saldo_cap,
                 isnull(qat_rubro1,0)qat_rubro1,
                 isnull(qat_rubro2,0)qat_rubro2,
                 isnull(qat_rubro3,0)qat_rubro3,
                 isnull(qat_rubro4,0)qat_rubro4,
                 isnull(qat_rubro5,0)qat_rubro5,
                 isnull(qat_rubro6,0)qat_rubro6,
                 isnull(qat_rubro7,0)qat_rubro7,
                 isnull(qat_rubro8,0)qat_rubro8,
                 isnull(qat_rubro9,0)qat_rubro9,
                 isnull(qat_rubro10,0)qat_rubro10,
                 isnull(qat_rubro11,0)qat_rubro11,
                 isnull(qat_rubro12,0)qat_rubro12,
                 isnull(qat_rubro13,0)qat_rubro13,
                 isnull(qat_rubro14,0)qat_rubro14,
                 isnull(qat_rubro15,0)qat_rubro15,
                 qat_cuota,
                 qat_estado,
                 qat_porroga
          from   ca_qr_amortiza_tmp
          where  qat_pid = @@spid
          order by qat_dividendo
    end

    if @i_opcion = 'C'
    begin

           exec @w_error = sp_estados_cca
                @o_est_vigente    = @w_est_vigente   out,
                @o_est_cancelado  = @w_est_cancelado out,
                @o_est_novigente  = @w_est_novigente out,
                @o_est_vencido    = @w_est_vencido   out,
				@o_est_anulado    = @w_est_anulado   out

           create table #tmp_total
           (tt_estado   varchar(64) not null,
            tt_capital  money           null,
            tt_interes  money           null,
            tt_mora     money           null,
            tt_int_mora money           null,
            tt_otros    money           null,
            tt_total    money           null,
            tt_pagos    int             null
           )

           --Vencidos
           select @w_cuotas = 0
           select @w_desc_estado = es_descripcion
           from cob_cartera..ca_estado
           where es_codigo = @w_est_vencido

           select @w_cuotas  = isnull(count(di_dividendo),0)
           from cob_cartera..ca_dividendo with (nolock)
           where di_operacion = @w_operacionca
           and   di_estado   = @w_est_vencido 

           CREATE TABLE #tmp_vencidos ( --LPO TEC para que la consulta que se muestra en pantalla diferencie entre proyectado o acumulado
           Concepto catalogo NULL,
           Valor    MONEY    NULL
           )

           IF @w_tipo_grupal = 'G' --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
           BEGIN
              INSERT INTO #tmp_vencidos
              select 'Concepto' = am_concepto,
                     'Valor'    =  round(isnull(sum(am_cuota + am_gracia - am_pagado),0), @w_numdec_op)
              from cob_cartera..ca_dividendo with (nolock),
                   cob_cartera..ca_amortizacion with (nolock),
                   cob_cartera..ca_operacion with (nolock)  -- GFP Ingreso para seleccionar operaciones grupales
              where di_operacion = op_operacion
              and   am_operacion = di_operacion
              and   di_dividendo = am_dividendo
              and   di_estado    = @w_est_vencido 
              AND   op_ref_grupal = @i_banco   -- GFP Seleccionar las operaciones hijas  de acuerdo a la operacion grupal
			  and   op_estado not in (@w_est_anulado)
              group by am_concepto
           END
           ELSE -- Paga los interes acumulados --LPO TEC para que la consulta que se muestra en pantalla diferencie entre proyectado o acumulado
           BEGIN

              INSERT INTO #tmp_vencidos
              select 'Concepto' = am_concepto,
                     'Valor'    =  round(isnull(sum(am_cuota + am_gracia - am_pagado),0), @w_numdec_op)
              from cob_cartera..ca_dividendo with (nolock),
                   cob_cartera..ca_amortizacion with (nolock),
                   cob_cartera..ca_rubro_op with (nolock)
              where di_operacion = @w_operacionca
              and   am_operacion = di_operacion
              and   am_dividendo  between di_dividendo and di_dividendo + charindex (ro_fpago, 'A')  --Anticipados no pagados se incluyen en el valor a pagar
              and   am_operacion  = ro_operacion
              and   di_operacion  = ro_operacion
              and   am_concepto   = ro_concepto
              and   (di_estado    = @w_est_vencido)
              group by am_concepto

           END
		   
		   

           --LPO CDIG Cambio a variables porque MySql no soporta reabrir la tabla temporal #tmp_total
           
           SELECT @w_tt_capital = isnull(sum(Valor),0)
           from   #tmp_vencidos, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro = 'C'
           
           SELECT @w_tt_interes = isnull(sum(Valor),0)
           from   #tmp_vencidos, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro in ('I','F')
           
           SELECT @w_tt_mora = isnull(sum(Valor),0)
           from   #tmp_vencidos, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro = 'M'
           
           SELECT @w_tt_int_mora = isnull(sum(Valor),0)
           from   #tmp_vencidos, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro in ( 'I','F','M')
           
           SELECT @w_tt_otros = isnull(sum(Valor),0)
           from   #tmp_vencidos, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro not in ('C','I','F','M')
           
           insert into #tmp_total
                  (tt_estado     , tt_capital  ,  tt_interes,    tt_mora,    tt_int_mora,    tt_otros,    tt_pagos)
           VALUES (@w_desc_estado, @w_tt_capital, @w_tt_interes, @w_tt_mora, @w_tt_int_mora, @w_tt_otros, @w_cuotas)
           
           --Vigentes
           select @w_cuotas = 0
           select @w_desc_estado = es_descripcion
           from cob_cartera..ca_estado
           where es_codigo = @w_est_vigente

           --Si no se ha pagado los rubros anticipados del dividendo actual, se los debe cobrar primero, se valida con vencidos para no duplicar
           select @w_div_vencido = 'N'
           if exists(select 1 from ca_dividendo where di_operacion = @w_operacionca and di_estado = @w_est_vencido)
              select @w_div_vencido = 'S'

           CREATE TABLE #tmp_no_vigente ( --LPO TEC para que la consulta que se muestra en pantalla diferencie entre proyectado o acumulado
           Concepto catalogo NULL,
           Valor    MONEY    NULL
           )

           IF @w_tipo_grupal = 'G' --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
           BEGIN

              INSERT INTO #tmp_no_vigente
              select 'Concepto' = am_concepto,
                     'Valor'    = round(isnull(sum(am_cuota + am_gracia - am_pagado),0), @w_numdec_op)
              from cob_cartera..ca_dividendo with (nolock),
                   cob_cartera..ca_amortizacion with (nolock),
                   cob_cartera..ca_operacion with (nolock)   -- GFP Ingreso para seleccionar operaciones grupales
              where di_operacion = op_operacion
              and   am_operacion = di_operacion
              and   di_dividendo = am_dividendo
              and   di_estado    = @w_est_vigente
              AND   op_ref_grupal = @i_banco    -- GFP Seleccionar las operaciones hijas  de acuerdo a la operacion grupal
			  and   op_estado not in (@w_est_anulado)
              group by am_concepto

           END
           ELSE
           BEGIN
              INSERT INTO #tmp_no_vigente
              select 'Concepto' = am_concepto,
                     'Valor'    = case when ro_fpago <> 'A' and @w_op_tipo_cobro = 'A' then round(isnull(sum(am_acumulado + am_gracia - am_pagado),0), @w_numdec_op)
                                       else round(isnull(sum(am_cuota + am_gracia - am_pagado),0), @w_numdec_op) end
              from cob_cartera..ca_dividendo with (nolock),
                   cob_cartera..ca_amortizacion with (nolock),
                   cob_cartera..ca_rubro_op with (nolock)
              where di_operacion = @w_operacionca
              and   am_operacion = di_operacion
              and   (@w_div_vencido = 'N' or am_dividendo = di_dividendo + charindex (ro_fpago, 'A'))--Anticipados no pagados se incluyen en el valor a pagar
              and   (@w_div_vencido = 'S' or am_dividendo between di_dividendo and di_dividendo + charindex (ro_fpago, 'A'))
              and   am_operacion  = ro_operacion
              and   di_operacion  = ro_operacion
              and   am_concepto   = ro_concepto
              and   di_estado     = @w_est_vigente
              group by am_concepto, ro_fpago
           END

           select @w_cuotas  = isnull(count(di_dividendo),0)
           from cob_cartera..ca_dividendo with (nolock)
           where di_operacion = @w_operacionca
           and   di_estado    = @w_est_vigente

           --LPO CDIG Cambio a variables porque MySql no soporta reabrir la tabla temporal #tmp_total

           SELECT @w_tt_capital = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro = 'C'
           
           SELECT @w_tt_interes = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro in ('I','F')
           
           SELECT @w_tt_mora = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro = 'M'

           SELECT @w_tt_int_mora = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro in ('I','F','M')
           
           SELECT @w_tt_otros = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro not in ('C','I','F','M')
           
           insert into #tmp_total
                  (tt_estado     , tt_capital  ,  tt_interes,    tt_mora,    tt_int_mora,    tt_otros,    tt_pagos)
           VALUES (@w_desc_estado, @w_tt_capital, @w_tt_interes, @w_tt_mora, @w_tt_int_mora, @w_tt_otros, @w_cuotas)


           --PRECANCELAR
           select @w_cuotas = 0
           select @w_desc_estado = 'PRECANCELAR'

           delete #tmp_no_vigente

           IF @w_tipo_grupal = 'G' --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
           BEGIN

              INSERT INTO #tmp_no_vigente
              select 'Concepto' = am_concepto,
                     'Valor'    = round(isnull(sum(am_acumulado + am_gracia - am_pagado),0), @w_numdec_op)
              from cob_cartera..ca_dividendo with (nolock),
                   cob_cartera..ca_amortizacion with (nolock),
                   cob_cartera..ca_operacion with (nolock),    -- GFP Ingreso para seleccionar operaciones grupales
				   cob_cartera..ca_concepto with (nolock)
              where di_operacion = op_operacion
              and   am_operacion = di_operacion
			  and   am_concepto  = co_concepto
              and   di_dividendo = am_dividendo
			  and   co_categoria IN ('C','I','M')
              AND   op_ref_grupal = @i_banco   -- GFP Seleccionar las operaciones hijas  de acuerdo a la operacion grupal
			  and   op_estado not in (@w_est_anulado)
              group by am_concepto
			  
			  INSERT INTO #tmp_no_vigente
              select 'Concepto' = am_concepto,
                     'Valor'    = round(isnull(sum(am_acumulado + am_gracia - am_pagado),0), @w_numdec_op)
              from cob_cartera..ca_dividendo with (nolock),
                   cob_cartera..ca_amortizacion with (nolock),
                   cob_cartera..ca_operacion with (nolock),    -- GFP Ingreso para seleccionar operaciones grupales
				   cob_cartera..ca_concepto with (nolock)
              where di_operacion = op_operacion
              and   am_operacion = di_operacion
			  and   am_concepto  = co_concepto
              and   di_dividendo = am_dividendo
			  and   co_categoria not IN ('C','I','M')
			  and   di_estado    in (@w_est_vencido, @w_est_vigente)
              AND   op_ref_grupal = @i_banco   -- GFP Seleccionar las operaciones hijas  de acuerdo a la operacion grupal
			  and   op_estado not in (@w_est_anulado)
              group by am_concepto

           END
           ELSE
           BEGIN
              INSERT INTO #tmp_no_vigente
              select 'Concepto' = am_concepto,
                     'Valor'    = round(isnull(sum(am_acumulado + am_gracia - am_pagado),0), @w_numdec_op)
              from cob_cartera..ca_dividendo with (nolock),
                   cob_cartera..ca_amortizacion with (nolock),
				   cob_cartera..ca_concepto with (nolock)
              where di_operacion = @w_operacionca
              and   am_operacion = di_operacion
			  and   am_concepto  = co_concepto
              and   am_dividendo = di_dividendo
			  and   co_categoria IN ('C','I','M')
              group by am_concepto
			  
			  INSERT INTO #tmp_no_vigente
              select 'Concepto' = am_concepto,
                     'Valor'    = round(isnull(sum(am_acumulado + am_gracia - am_pagado),0), @w_numdec_op)
              from cob_cartera..ca_dividendo with (nolock),
                   cob_cartera..ca_amortizacion with (nolock),
				   cob_cartera..ca_concepto with (nolock)
              where di_operacion = @w_operacionca
              and   am_operacion = di_operacion
			  and   am_concepto  = co_concepto
              and   am_dividendo = di_dividendo
			  and   co_categoria not IN ('C','I','M')
			  and   di_estado    in (@w_est_vencido, @w_est_vigente)
              group by am_concepto
           END

           select @w_cuotas  = isnull(count(di_dividendo),0)
           from cob_cartera..ca_dividendo with (nolock)
           where di_operacion = @w_operacionca
           and   di_estado    = @w_est_novigente

           --LPO CDIG Cambio a variables porque MySql no soporta reabrir la tabla temporal #tmp_total

           SELECT @w_tt_capital = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro = 'C'
           
           SELECT @w_tt_interes = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro in ('I','F')
           
           SELECT @w_tt_mora = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro = 'M'

           SELECT @w_tt_int_mora = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro in ('I','F','M')
           
           SELECT @w_tt_otros = isnull(sum(Valor),0)
           from   #tmp_no_vigente, ca_rubro_op
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = Concepto
           and    ro_tipo_rubro not in ('C','I','F','M')
           
           insert into #tmp_total
                  (tt_estado     , tt_capital  ,  tt_interes,    tt_mora,    tt_int_mora,    tt_otros,    tt_pagos)
           VALUES (@w_desc_estado, @w_tt_capital, @w_tt_interes, @w_tt_mora, @w_tt_int_mora, @w_tt_otros, @w_cuotas)


           update #tmp_total
           set tt_total = round(isnull(tt_capital,0) + isnull(tt_int_mora,0) + isnull(tt_otros,0),@w_numdec_op)

           select *
           from #tmp_total
    end
    return 0

ERROR:

exec cobis..sp_cerror
     @t_debug = 'N',
     @t_from  = @w_sp_name,
     @i_num   = @w_error

return @w_error
go
