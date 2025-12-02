/***********************************************************************/
/*      Archivo:                        rees_calc_monto.sp          */
/*      Stored procedure:               sp_rees_calc_monto             */
/*      Base de Datos:                  cob_pac                        */
/*      Producto:                       Credito                        */
/*      Disenado por:                   Geovanny Duran                 */
/***********************************************************************/
/*        IMPORTANTE                                                   */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "COBISCORP", representantes exclusivos para el Ecuador de la       */
/*  "COBISCORP CORPORATION".                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier alteracion o agregado hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de la            */
/*  Presidencia Ejecutiva de COBISCORP o su representante.             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*  Genera el monto a reestructura en base a la operacion y parametro  */
/*  tipo de monto                                                      */
/*                                                                     */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/*      14/Dic/2016     Geovanny Duran          Emision Inicial        */
/*      09/Sep/2017     Paulina Quezada         Correccion saldos      */
/*      19/01/2021      KDR (Dilan Morales)     Ajuste Saldo Reestruct.*/
/***********************************************************************/
use cob_cartera
go

 if exists (select 1 from sysobjects where name = 'sp_rees_calc_monto')
    DROP PROCEDURE  sp_rees_calc_monto
go

create proc sp_rees_calc_monto
@s_user        	varchar(30) 	= null,
@s_sesn         int             = null,
@s_term        	varchar(30) 	= null,
@s_date        	datetime	    = null,
@i_tmonto       char(1)         = 'N',
@i_banco_rees   cuenta,
@i_moneda       int             = null,
@o_monto_rees   money out,
@o_tipo_op      char(1)         = null out,
@o_msg_error    varchar(255)    = null out

as 

/* Declaraciones de variables de operacion */
declare @w_sp_name	    varchar(30),
	@w_date		        datetime,
	@w_msg		        varchar(50),
	@w_error	        int,
	@w_operacion_rest   int,	    -- numero secuencial de operacion a reestructurar
	@w_saldo_rest       money, 		-- saldo de operacion a reestructurar
	@w_interes            catalogo,  --PQU
    @w_moneda_o           tinyint,
        @w_moneda_d           tinyint,
        @w_codmn              tinyint,
        @w_codusd             tinyint,
        @w_cambio_of          money,
        @w_rel_m1             money,
        @w_rel_m2             money,
        @w_cambio_ofm1        money,
        @w_cambio_ofm2        money,
        @w_monto_mn           money,
        @w_tipo_op            char(1),
        @w_divdol             char(1),
        @w_valor_convertido   money
    
	
/*-- setear variables de operacion */
select @w_sp_name = 'sp_rees_calc_monto'
select @w_date = fp_fecha from cobis..ba_fecha_proceso

select @w_interes = isnull(pa_char, 'INT')
from cobis..cl_parametro 
where pa_nemonico = 'INT'
and   pa_producto = 'CCA'


/*-- Operacion a reestructurar*/
select @w_operacion_rest  = op_operacion,
       @w_moneda_o        = op_moneda,
       @w_moneda_d        = @i_moneda
  from cob_cartera..ca_operacion
 where op_banco = @i_banco_rees
   
   if @@rowcount = 0
   begin
      /** registro no existe **/
      exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = ' ', 
      @t_from  = @w_sp_name,
      @i_num   = 2101010
      return 2101010 	
   end

/*-- Valido existencia de dato en el catalogo*/
if not exists(select 1 from cobis..cl_tabla a, cobis..cl_catalogo b
               where a.tabla = 'cr_monto_rees'
                 and a.codigo = b.tabla
                 and b.codigo = @i_tmonto)
begin
      exec cobis..sp_cerror
        @t_debug = 'N',
        @t_file  = ' ', 
        @t_from  = @w_sp_name,
        @i_num   = 101000
      return 101000 
end

/*-- VALIDACION DEL MONTO*/
if @i_tmonto = 'N'
begin
    select @w_saldo_rest = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) )--PQU integracion - isnull(am_exponencial,0))
      from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
     where  ro_operacion = @w_operacion_rest
       and  ro_tipo_rubro in ('C')    -- tipo de rubro capital
       and  am_operacion = ro_operacion
       and  am_concepto  = ro_concepto   
end
if @i_tmonto = 'S'
begin
    select @w_saldo_rest = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0))--PQU integracion - isnull(am_exponencial,0))
      from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
     where  ro_operacion = @w_operacion_rest
       and  ro_tipo_rubro in ('C')    -- capital 
       and  am_operacion = ro_operacion
       and  am_concepto  = ro_concepto   
	   
	select @w_saldo_rest = sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0) ) + @w_saldo_rest --PQU quité el am_exponencial
      from   cob_cartera..ca_amortizacion
     where  am_operacion = @w_operacion_rest
       and  am_concepto  = @w_interes  --PQU debido a que hay otros conceptos que se comportan como interés
end
if @i_tmonto = 'T'
begin
     select @w_saldo_rest = isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)--PQU integracion - isnull(am_exponencial,0)) 
       from cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
       where ro_operacion = @w_operacion_rest
       and ro_tipo_rubro in ('C') -- capital
       and am_operacion = ro_operacion
       and am_concepto = ro_concepto
       
    select @w_saldo_rest = isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0) + @w_saldo_rest --PQU quité el am_exponencial
       from cob_cartera..ca_amortizacion
       where am_operacion = @w_operacion_rest
       and am_concepto = @w_interes --PQU debido a que hay otros conceptos que se comportan como interés
       
    select @w_saldo_rest = @w_saldo_rest + isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)
       from cob_cartera..ca_amortizacion,
       cob_cartera..ca_dividendo
       where am_operacion = di_operacion and
       am_operacion = @w_operacion_rest and
       am_dividendo = di_dividendo and
       am_concepto not in('CAP', 'INT') and
       di_estado not in (0 , 3)
       
end

set @w_saldo_rest = isnull(@w_saldo_rest,0)

if (@w_moneda_d is not null) and (@w_moneda_d>=0) and (@w_moneda_o != @w_moneda_d) and (@w_saldo_rest>0)
begin
    -- PASO OBLIGATORIO POR DÓLARES EN COMPRA / VENTA DE MONEDA EXTRANJERA
    select @w_divdol = pa_char from cobis..cl_parametro where pa_producto = 'SBA' and pa_nemonico = 'MDIDOL'
    -- BUSCA CODIGO DE MONEDAS
    select @w_codmn  = pa_tinyint from cobis..cl_parametro where pa_producto = 'ADM' and pa_nemonico = 'MLO'
    select @w_codusd = pa_tinyint from cobis..cl_parametro where pa_producto = 'ADM' and pa_nemonico = 'CDOLAR'


    -- DETERMINAR SI ES COMPRA/VENTA O ARBITRAJE
    if isnull(@w_divdol,'S') = 'S'
    begin
        -- La compra y venta será siempre entre dolares y moneda nacional, si fuera otra moneda dura se requiere generar la operacion de compra/venta de dolares y el arbitraje entre el dolar y la moneda dura
        if (@w_moneda_o = @w_codusd and @w_moneda_d = @w_codmn)
            set @w_tipo_op = 'C'  -- Compra
        else if (@w_moneda_o = @w_codmn and @w_moneda_d = @w_codusd)
            set @w_tipo_op = 'V'  -- Venta
        else
            set @w_tipo_op = 'A'  -- Arbitraje
    end
    else
    begin
        -- ARBITRAJE SE APLICA CUANDO LA NEGOCIACION ES ENTRE DOS MONEDAS EXTRANJERAS
        if @w_moneda_o <> @w_codmn
            set @w_tipo_op = 'C'  -- Compra
        else
            set @w_tipo_op = 'V'  -- Venta
    end
    set @o_tipo_op = @w_tipo_op

    -- LECTURA DE COTIZACIONES CONTABLES DEL DOLAR
    select @w_cambio_of = C1.ct_valor
    from   cob_conta..cb_cotizacion C1
    where  C1.ct_empresa = 1
    and    C1.ct_moneda  = @w_codusd
    and    ct_fecha = (select max (C2.ct_fecha) from cob_conta..cb_cotizacion C2 where C2.ct_empresa = 1 and C2.ct_moneda= @w_codusd and C2.ct_fecha <= @w_date)
    if @w_cambio_of is null
    begin
        select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL LEER LA COTIZACION CONTABLE DEL DOLAR'
        return 2902848
    end

    -- COTIZACON MONEDA ORIGEN
    if @w_moneda_o = @w_codmn
        set @w_cambio_ofm1 = 1
    else
    begin
        select @w_cambio_ofm1 = C1.ct_valor
        from   cob_conta..cb_cotizacion C1
        where  C1.ct_empresa = 1
        and    C1.ct_moneda  = @w_moneda_o
        and    ct_fecha = (select max (C2.ct_fecha) from cob_conta..cb_cotizacion C2 where C2.ct_empresa = 1 and C2.ct_moneda= @w_moneda_o and C2.ct_fecha <= @w_date)
        if @w_cambio_ofm1 is null
        begin
            select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL LEER LA COTIZACION CONTABLE DE LA MONEDA ORIGEN'
            return 2902849
        end
    end

    -- COTIZACON MONEDA DESTINO
    if @w_moneda_d = @w_codmn
    begin
        set @w_cambio_ofm2 = 1
    end
    else
    begin
        select @w_cambio_ofm2 = C1.ct_valor
        from   cob_conta..cb_cotizacion C1
        where  C1.ct_empresa = 1
        and    C1.ct_moneda  = @w_moneda_d
        and    ct_fecha = (select max (C2.ct_fecha) from cob_conta..cb_cotizacion C2 where C2.ct_empresa = 1 and C2.ct_moneda= @w_moneda_d and C2.ct_fecha <= @w_date)
        if @w_cambio_ofm2 is null
        begin
            select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL LEER LA COTIZACION CONTABLE DE LA MONEDA DESTINO'
            return 2902850
        end
    end

    -- CALCULO DE LA RELACION CON RESPECTO AL DOLAR DE LAS MONEDAS DE ORIGEN Y DESTINO
    if @w_moneda_o = @w_codmn
        set @w_rel_m1 = 1
    else
        set @w_rel_m1 = @w_cambio_ofm1 / @w_cambio_of
    -- CALCULO DEL MONTO CONVERTIDO
    if @w_moneda_d = @w_codmn
        set @w_rel_m2 = 1
    else
        set @w_rel_m2 = @w_cambio_ofm2 / @w_cambio_of

    if @w_tipo_op = 'V' -- Cálculo del monto convertido: Venta
    begin
        set @w_valor_convertido = @w_saldo_rest * @w_rel_m2 * @w_cambio_of
    end
    else if @w_tipo_op = 'C' -- Cálculo del monto convertido: Compra
    begin
      set @w_valor_convertido = @w_saldo_rest * @w_rel_m1 * @w_cambio_of
    end
    else if @w_tipo_op = 'A' -- Cálculo del monto convertido: Arbitraje
    begin
        -- La moneda de origen y destino son moneda extranjera y una de ellas es dólares.  Regulatoriamente en CR toda operación de divisas debe realizarse con el dólar americano
        if @w_moneda_o <> @w_codmn and @w_moneda_d <> @w_codmn
        begin
            set @w_monto_mn = @w_saldo_rest * @w_rel_m1 * @w_cambio_of
            set @w_valor_convertido = @w_monto_mn / (@w_rel_m2 * @w_cambio_of)
        end
        -- Si la moneda destino es ME ==> Venta de dólares, y arbitraje dólar vs. moneda extranjera (compra dólar - venta ME)
        if @w_moneda_d <> @w_codmn and @w_moneda_o = @w_codmn
        begin
            set @w_valor_convertido = @w_saldo_rest / (@w_rel_m2 * @w_cambio_of)
        end
        -- Si la moneda origen es ME ==> Arbitraje moneda extranjera vs. dólar (compra ME - venta dólar), y compra dólar
        if @w_moneda_o <> @w_codmn and @w_moneda_d = @w_codmn
        begin
            set @w_valor_convertido = @w_saldo_rest * @w_rel_m1 * @w_cambio_of
        end
    end  -- FIN: if @w_tipo_op = 'A'
    --print 'VAL_O[%1!]-VAL_D[%2!]-TIPO[%3!]-MONE_O[%4!]-MONE_D[%5!]' ,@w_saldo_rest,@w_valor_convertido,@w_tipo_op ,@w_moneda_o,@w_moneda_d
set @w_saldo_rest = @w_valor_convertido
end

set @o_monto_rees = round(@w_saldo_rest,2)

return 0
go

