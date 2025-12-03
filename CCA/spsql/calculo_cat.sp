/************************************************************************/
/*      Archivo:                calculo_cat.sp                          */
/*      Stored procedure:       sp_calculo_cat                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Armando Miramon                         */
/*      Fecha de escritura:     11-Oct-2019                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA", representantes exclusivos para el Ecuador de la       */
/*      "NCR CORPORATION".                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Este programa se utiliza para calcular el CAT de un credito     */
/*                                                                      */
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      11/Oct/19       A. Miramon      Emision Inicial                 */
/*      10/Dic/19       A. Miramon      Ajuste en cálculo de CAT        */
/*      21/jul/2021     Ricardo Rincón  Se agregan plazos totales según */
/*                                      plazo fijo para año, bimestre,  */
/*										trimestre y semestre            */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_calculo_cat')
   drop proc sp_calculo_cat
go

CREATE PROC sp_calculo_cat(
    @i_banco varchar(10),
--    @o_cat   decimal(18,4) OUT --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    @o_cat   FLOAT OUT --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    
)
AS
BEGIN
    declare @w_operacion int
--    , @w_monto decimal(18,2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    , @w_monto FLOAT --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    , @w_total_plazos int
    , @w_total_dividendos int
    , @w_fecha_inicial datetime
    , @w_fecha_final datetime
--    , @w_comision decimal(18,2) ----LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    , @w_comision FLOAT ----LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
      
--    , @w_interes decimal(18,2)  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
--    , @w_diferencia decimal(18,10) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
--    , @valor_medio decimal(18,10)  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    , @w_interes FLOAT --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    , @w_diferencia FLOAT --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    , @valor_medio FLOAT --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
      
    , @intentos int 
--    , @valor_anterior decimal(18,10)  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    , @valor_anterior FLOAT   --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    , @w_rubroInteres varchar(10)

    -- CONCEPTO RUBRO INTERES
    select @w_rubroInteres = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUINT'

    -- Se obtiene la información del crédito
    select @w_operacion = op_operacion --numero de operacion
        , @w_monto = op_monto --monto del credito
		, @w_fecha_inicial = op_fecha_ini
		, @w_fecha_final = op_fecha_fin
		, @w_total_dividendos = op_plazo
        , @w_total_plazos = (case op_tplazo --plazo total según el tipo de plazo
							when 'A' then 1
							when 'S' then 2
							when 'T' then 4
							when 'B' then 6
							when 'M' then 12
							when 'Q' then 24
                            when 'W' then 52
                            else 0 end)
    from cob_cartera..ca_operacion 
    where op_banco = @i_banco
    
    select @w_interes = (ro_porcentaje/100) 
    from cob_cartera..ca_rubro_op 
    where ro_operacion = @w_operacion and ro_concepto = @w_rubroInteres
    
    --SELECT @w_monto, @w_comision, @w_interes
    
    --Se inicializal las variables que se van a utilizar
    select @w_diferencia = 1
    , @intentos = 0
    , @w_comision = 0
    , @valor_anterior = 0
--    , @valor_medio = isnull((power(1+convert(decimal(18,10),abs(@w_interes)/@w_total_plazos),  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
--                     convert(decimal(18,4),@w_total_plazos))-1), 0)  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    , @valor_medio = isnull((power(1+convert(FLOAT,abs(@w_interes)/@w_total_plazos),  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                     convert(FLOAT, @w_total_plazos))-1), 0)  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
    
    --Se asigna el valor de la comision
    select @w_comision = sum(so_monto_seguro) 
    from cob_cartera..ca_seguros_op
    where so_operacion = @w_operacion and so_tipo_seguro = 'B'
   
    --Se obtiene el primer valor de la diferencia
    select @w_diferencia = abs(@w_monto - (@w_comision + sum(factor)))
    from  (select di_dividendo
--        ,factor = round(convert(decimal(18,5),sum(am_cuota)/(power((1 + @valor_medio),   --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
--          (convert(decimal(18,2),di_dividendo)/convert(decimal(18,2),@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
        ,factor = round(convert(FLOAT,sum(am_cuota)/(power((1 + @valor_medio),   --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
          (convert(FLOAT,di_dividendo)/convert(FLOAT,@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float

    from cob_cartera..ca_dividendo inner join cob_cartera..ca_amortizacion
    on am_operacion = di_operacion and am_dividendo = di_dividendo
    and am_concepto in (select codigo from cobis..cl_catalogo 
        where tabla = (select codigo from cobis..cl_tabla 
        where tabla = 'ca_rubros_cat'))
    where di_operacion = @w_operacion
    group by di_dividendo) as calc_cat

    --select @intentos, @valor_anterior, @w_diferencia, @valor_medio

    if @w_diferencia > 0.1
    begin
        select @valor_anterior = @w_diferencia
        select @valor_medio = @valor_medio + 0.1
    end

    --Intentos por decimas
    while @intentos < 50 and @w_diferencia > 0.1
    begin
        --Se obtiene la diferencia del cálculo de CAT
        select @w_diferencia = abs(@w_monto - (@w_comision + sum(factor)))
        from  (select di_dividendo
--            ,factor = round(convert(decimal(18,5),sum(am_cuota)/(power((1 + @valor_medio), --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
--              (convert(decimal(18,2),di_dividendo)/convert(decimal(18,2),@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
            ,factor = round(convert(FLOAT,sum(am_cuota)/(power((1 + @valor_medio), --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
              (convert(FLOAT,di_dividendo)/convert(FLOAT,@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
        from cob_cartera..ca_dividendo inner join cob_cartera..ca_amortizacion
        on am_operacion = di_operacion and am_dividendo = di_dividendo
        and am_concepto in (select codigo from cobis..cl_catalogo 
            where tabla = (select codigo from cobis..cl_tabla 
            where tabla = 'ca_rubros_cat'))
        where di_operacion = @w_operacion
        group by di_dividendo) as calc_cat
        
        --select @intentos, @valor_anterior, @w_diferencia, @valor_medio
        --Se validan las diferencias
        if @valor_anterior > @w_diferencia
        begin
            select @valor_anterior = @w_diferencia
            select @valor_medio = @valor_medio + 0.1
        end
        else
        begin
            declare
--                @valor_medio_valida decimal(18,10) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
--                , @valor_medio_tmp decimal(18,10)  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                @valor_medio_valida FLOAT  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                , @valor_medio_tmp FLOAT  --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                        
            select @valor_medio_valida = @valor_medio - (floor(@valor_medio*100)/100 - floor(@valor_medio*10)/10) - 0.2
            --select @valor_medio_valida, @valor_medio
        
            --Se ajustan centécimas
            while @valor_medio_valida < @valor_medio
            begin
                select @w_diferencia = abs(@w_monto - (@w_comision + sum(factor)))
                from  (select di_dividendo
--                    ,factor = round(convert(decimal(18,5),sum(am_cuota)/(power((1 + @valor_medio_valida), --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
--                      (convert(decimal(18,2),di_dividendo)/convert(decimal(18,2),@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                    ,factor = round(convert(FLOAT,sum(am_cuota)/(power((1 + @valor_medio_valida), --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                      (convert(FLOAT,di_dividendo)/convert(FLOAT,@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                from cob_cartera..ca_dividendo inner join cob_cartera..ca_amortizacion
                on am_operacion = di_operacion and am_dividendo = di_dividendo
                and am_concepto in (select codigo from cobis..cl_catalogo 
                    where tabla = (select codigo from cobis..cl_tabla 
                    where tabla = 'ca_rubros_cat'))
                where di_operacion = @w_operacion
                group by di_dividendo) as calc_cat
                    
                if @valor_anterior >= @w_diferencia 
                begin
                    select @valor_anterior = @w_diferencia
                    select @valor_medio_tmp = @valor_medio_valida
                end
                
                if @valor_medio_tmp is not null and @w_diferencia > @valor_anterior 
                begin
                    break
                end

                --select @valor_anterior, @w_diferencia, @valor_medio_valida, @valor_medio_tmp
                select @valor_medio_valida = @valor_medio_valida + 0.01
            end
            
            select @valor_medio = @valor_medio_tmp, @valor_medio_tmp = null		    
            select @valor_medio_valida = @valor_medio - (floor(@valor_medio*1000)/1000 - floor(@valor_medio*100)/100)
            select @valor_medio = @valor_medio_valida +.02
            --select @valor_medio_valida, @valor_medio
        
            --Se ajustan milésimas
            while @valor_medio_valida <= @valor_medio
            begin                    
                select @w_diferencia = abs(@w_monto - (@w_comision + sum(factor)))
                from  (select di_dividendo
--                    ,factor = round(convert(decimal(18,5),sum(am_cuota)/(power((1 + @valor_medio_valida), --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
--                      (convert(decimal(18,2),di_dividendo)/convert(decimal(18,2),@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                    ,factor = round(convert(FLOAT ,sum(am_cuota)/(power((1 + @valor_medio_valida), --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                      (convert(FLOAT,di_dividendo)/convert(FLOAT ,@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                from cob_cartera..ca_dividendo inner join cob_cartera..ca_amortizacion
                on am_operacion = di_operacion and am_dividendo = di_dividendo
                and am_concepto in (select codigo from cobis..cl_catalogo 
                    where tabla = (select codigo from cobis..cl_tabla 
                    where tabla = 'ca_rubros_cat'))
                where di_operacion = @w_operacion
                group by di_dividendo) as calc_cat
                    
                if @valor_anterior >= @w_diferencia 
                begin
                    select @valor_anterior = @w_diferencia
                    select @valor_medio_tmp = @valor_medio_valida
                end
                
                if @valor_medio_tmp is not null and  @w_diferencia > @valor_anterior 
                begin
                    break
                end
                    
                --select @valor_anterior, @w_diferencia, @valor_medio_valida
                select @valor_medio_valida = @valor_medio_valida + 0.001
            end
            
            select @valor_medio = @valor_medio_tmp, @valor_medio_tmp = null	    
            select @valor_medio_valida = @valor_medio - (floor(@valor_medio*10000)/10000 - floor(@valor_medio*1000)/1000)
            select @valor_medio = @valor_medio_valida +.002
            --select @valor_medio_valida, @valor_medio
            
            --Se ajustan milésimas
            while @valor_medio_valida <= @valor_medio
            begin
                select @w_diferencia = abs(@w_monto - (@w_comision + sum(factor)))
                from  (select di_dividendo
--                    ,factor = round(convert(decimal(18,5),sum(am_cuota)/(power((1 + @valor_medio_valida), --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
--                      (convert(decimal(18,2),di_dividendo)/convert(decimal(18,2),@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                    ,factor = round(convert(FLOAT ,sum(am_cuota)/(power((1 + @valor_medio_valida), --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                      (convert(FLOAT ,di_dividendo)/convert(FLOAT ,@w_total_plazos))))), 2) --LPO CDIG Volver a dejar en decimal(18,10) en lugar de float
                from cob_cartera..ca_dividendo inner join cob_cartera..ca_amortizacion
                on am_operacion = di_operacion and am_dividendo = di_dividendo
                and am_concepto in (select codigo from cobis..cl_catalogo 
                    where tabla = (select codigo from cobis..cl_tabla 
                    where tabla = 'ca_rubros_cat'))
                where di_operacion = @w_operacion
                group by di_dividendo) as calc_cat
                    
                if @valor_anterior >= @w_diferencia 
                begin
                    select @valor_anterior = @w_diferencia
                    select @valor_medio_tmp = @valor_medio_valida
                end
                
                if @valor_medio_tmp is not null and  @w_diferencia > @valor_anterior 
                begin
                    break
                end
                    
                --select @valor_anterior, @w_diferencia, @valor_medio_valida, @valor_medio_tmp
                select @valor_medio_valida = @valor_medio_valida + 0.0001
            end
            
            select @valor_medio = @valor_medio_tmp

            break
        end

        select @intentos = @intentos + 1
    end

    --Se obtiene el valor de CAT
    select @o_cat = round(@valor_medio*100, 2)
	
	return 0
END
go