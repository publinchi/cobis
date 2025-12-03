/************************************************************************/
/*Archivo             :   concidia.sp                                   */
/*Stored procedure    :   sp_conciliacion_diaria                        */
/*Base de datos       :   cob_cartera                                   */
/*Producto            :   Credito y Cartera                             */
/*Disenado por        :   Elcira Pelaez                                 */
/*Fecha de escritura  :   Feb.2003                                      */
/************************************************************************/
/*                       IMPORTANTE                                     */
/*Este programa es parte de los paquetes bancarios propiedad de         */
/*"MACOSA"                                                              */
/*Su uso no autorizado queda expresamente prohibido asi como            */
/*cualquier alteracion o agregado hecho por alguno de sus               */
/*usuarios sin el debido consentimiento por escrito de la               */
/*Presidencia Ejecutiva de MACOSA o su representante.                   */
/************************************************************************/
/*                      PROPOSITO                                       */
/*Procedimiento que saca la informacion de los vencimientos del         */
/*de los bancos de segundo piso                                         */
/*      para insertcarlos en la estructura ca_conciliacion_diaria       */
/*      Inserta Las  operaciones con cuotas vencidas y  vigentes  que   */
/*      vencen en la fecha de proceso                                   */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA          AUTOR             CAMBIOS                        */
/*     Mar 2003      Monica Marino  Compilaci½n                         */  
/*     oct 2004        Elcira Pelaez    sacar la tasa con la que se     */
/*                                      calculo el dividendeo que vence */ 
/*     jun 2006        Elcira Pelaez    def.BAC Nro.6712  val INT       */
/************************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_conciliacion_diaria')
   drop proc sp_conciliacion_diaria
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


create proc sp_conciliacion_diaria
@i_fecha_proceso     datetime


as

declare 
   @w_error                   int,
   @w_return                  int,
   @w_sp_name                 descripcion,
   @w_fecha_proceso           datetime,
   @w_contador                int,
   @w_est_vigente             tinyint,
   @w_est_vencido             tinyint,
   @w_est_novigente           tinyint,
   @w_est_cancelado           tinyint,
   @w_est_credito             tinyint,
   @w_est_suspenso            tinyint,
   @w_est_castigado           tinyint,
   @w_est_anulado             tinyint,
   @w_est_novedades           tinyint,
   @w_op_banco                cuenta,
   @w_op_tramite              int,
   @w_op_oficina              int,
   @w_op_codigo_externo       cuenta,
   @w_op_fecha_ini            datetime,
   @w_op_nombre               varchar(15),
   @w_op_sector               char(1),
   @w_op_tdividendo           char(1),
   @w_op_tipo_linea           catalogo,
   @w_op_cliente              int,
   @w_op_moneda               tinyint,
   @w_saldo_capital           money,
   @w_referencial             catalogo,
   @w_tasa_mercado            varchar(10),
   @w_tipo_tasa               char(10),
   @w_modalidad               char(1),
   @w_fpago                   char(1),
   @w_op_operacion            int,
   @w_op_margen_redescuento   float,
   @w_signo                   char(1),
   @w_tasa_referencial        varchar(10),
   @w_puntos                  money,  
   @w_abono_capital           money,
   @w_abono_interes           float,
   @w_op_opcion_cap           char(1),
   @w_num_dec_op              int,
   @w_moneda_mn               smallint,
   @w_saldo_redescuento       money,
   @w_tasa_nominal            float,
   @w_tasa_nominal_unica      float,
   @w_puntos_c                varchar(5),
   @w_norma_legal             varchar(255),
   @w_di_dividendo            smallint,
   @w_prox_pago_int           datetime,
   @w_di_dias_cuota           int,
   @w_tasa_pactada            varchar(30),
   @w_valor_capitalizar       float,
   @w_porcentaje_capitalizar  float,
   @w_identificacion          numero,
   @w_fecha_desembolso        datetime,
   @w_op_fecha_ult_proceso    datetime,
   @w_ciudad_nacional         int,
   @w_di_fecha_ven            datetime,
   @w_di_fecha_ini            datetime,
   @w_cotizacion              float,
   @w_num_dec_n               smallint,
   @w_moneda_nacional         smallint,
   @w_num_dec                 smallint,
   @w_moneda_n                smallint,
   @w_tipo_identificacion     char(2),
   @w_fecha_para_tasa         datetime
   


--  CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name          = 'sp_conciliacion_diaria'

select @w_fecha_proceso = @i_fecha_proceso


--PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted



--EL PROCESO DE CARGA PARA CONCILIACION NO SE DEBE EJECUTAR EN DIAS FESTIVOS
--NACIONALES, EL SIGUIENTE DIA HABIL RECOGE LOS FESTIVOS ANTERIORES SEGUN FINAGRO

if exists (select 1 from cobis..cl_dias_feriados
           where df_fecha = @w_fecha_proceso
           and   df_ciudad = @w_ciudad_nacional)
           begin
            PRINT 'concidia.sp EN DIAS FESTIVOS NO SE PUEDE EJECUTAR ESTE PROCESO'
            return 0
           end
           
--ERSPALDO DE LOS PAGOS PROCESADOS POR FECHA
insert into ca_conciliacion_diaria_his
select * from ca_conciliacion_diaria
where cd_estado = 'P'

--SE LIMPIA LA TABLA PARA VOLVER A CARGAR LOS VENCIMIENTOS
truncate table ca_conciliacion_diaria

select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


           
--SE ELIMINAN LOS REGISTROS EN ESTADO N PORQUE ESTE PROGRAMA LOS VUELVE A CARGAR
 
 
--CURSOR PARA LEER LOS VENCIMIENTOS MENORES O IGUALES A LA FECHA DE PROCESO 
declare cursor_carga_vtos_dia cursor for
select 
   op_cliente,                          op_moneda,           isnull(op_margen_redescuento,100),
   op_banco,                            op_tramite,          op_oficina,
   isnull(op_codigo_externo,op_banco),  op_fecha_ini,        substring(op_nombre,1,15),
   op_sector,                           op_tdividendo,       op_tipo_linea,
   op_opcion_cap,                       op_operacion,        op_fecha_ini,
   di_dividendo,                        di_dias_cuota,       op_fecha_ult_proceso,
   di_fecha_ven,                        di_fecha_ini
from cob_cartera..ca_operacion,
     cob_cartera..ca_dividendo
where op_operacion = di_operacion
and   op_tipo = 'R'  ---Solo Pasivas REDESCUENTO
and di_fecha_ven <=  @w_fecha_proceso  
and di_estado in (1,2)
and  op_estado in (1,2,4,5,8,9,10)
      
open  cursor_carga_vtos_dia

fetch cursor_carga_vtos_dia into 
   @w_op_cliente,                       @w_op_moneda,           @w_op_margen_redescuento,
   @w_op_banco,                         @w_op_tramite,          @w_op_oficina,
   @w_op_codigo_externo,                @w_op_fecha_ini,        @w_op_nombre,
   @w_op_sector,                        @w_op_tdividendo,       @w_op_tipo_linea,
   @w_op_opcion_cap,                    @w_op_operacion,        @w_fecha_desembolso,
   @w_di_dividendo,                     @w_di_dias_cuota,       @w_op_fecha_ult_proceso,
   @w_di_fecha_ven,                     @w_di_fecha_ini

while @@fetch_status = 0 
begin   
   if @@fetch_status = -1 
   begin    
     PRINT 'concidia.sp No hay datos para conciliacion diaria '
   end   

     
     ---PRINT 'concidia.sp banco' + @w_op_banco

      --- LECTURA DE DECIMALES 
      exec @w_return = sp_decimales
      @i_moneda       = @w_op_moneda,
      @o_decimales    = @w_num_dec out,
      @o_mon_nacional = @w_moneda_n out,
      @o_dec_nacional = @w_num_dec_n out

      select 
      @w_op_nombre  = rtrim(p_p_apellido)+' '+rtrim(p_s_apellido)+' '+rtrim(en_nombre)
      from  cobis..cl_ente
      where en_ente = @w_op_cliente
      set transaction isolation level read uncommitted


      -- SALDO_CAPITAL 
      select @w_saldo_capital     = 0,
             @w_saldo_redescuento = 0
      
      select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from  ca_dividendo, ca_amortizacion, ca_rubro_op
      where ro_operacion  = @w_op_operacion
      and   ro_tipo_rubro = 'C'  --Capital
      and   am_operacion  = ro_operacion
      and   am_concepto   = ro_concepto
      and   di_operacion  = ro_operacion
      and   am_dividendo  = di_dividendo
      and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
      and   am_estado     <>  3  -- Cancelado 

       select @w_saldo_redescuento = isnull(@w_saldo_capital,0)



    --  FORMULA TASA 
    select @w_referencial  = ro_referencial,
           @w_signo        = ro_signo,
           @w_puntos       = convert(money,ro_factor),
           @w_fpago        = ro_fpago,
           @w_tasa_nominal_unica = isnull(ro_porcentaje,0) -- JCQ 07/15/2003 En caso de que no exista Valor 
    from  ca_rubro_op,ca_operacion
    where ro_operacion = @w_op_operacion
    and   ro_concepto  = 'INT'
    and   ro_operacion = op_operacion


       ---LA FECHA DE LA TASA DEBE SER LA DEL INICIO DEL DIVIDENDO
       ---ES CON LA QUE SE INSERTO EL REAJUSTE
       
       select @w_fecha_para_tasa = di_fecha_ini
       from ca_dividendo
       where di_operacion = @w_op_operacion
       and   di_dividendo = @w_di_dividendo
       
       select @w_tasa_nominal = isnull(ts_porcentaje,0)
       from ca_tasas
       where ts_operacion = @w_op_operacion
       and   ts_dividendo = @w_di_dividendo
       and   ts_concepto  in('INT','INTANT')
       and   ts_fecha    = @w_fecha_para_tasa
       if @@rowcount = 0
          select @w_tasa_nominal = @w_tasa_nominal_unica
        
       
    select @w_tasa_mercado = vd_referencia
    from  ca_valor_det
    where vd_tipo = @w_referencial  
    and   vd_sector = @w_op_sector  


      --MODALIDAD TASA 
    select @w_modalidad = 'V'  ---Por defecto
    if @w_fpago = 'P'
       select @w_modalidad = 'V'

      if @w_fpago = 'A'
       select @w_modalidad = 'A'

    ---Convertir los puntos a char
    select @w_puntos_c  = convert(varchar(5),@w_puntos)

    ---Concatenar la tasa para mostrar segun solicitud
    select @w_tasa_mercado = rtrim(ltrim(@w_tasa_mercado))
            select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c   ----+ '(' + @w_op_tdividendo + @w_modalidad + ')'
   

        --NORMA LEGAL 
    /*
    select @w_norma_legal = substring(dt_valor,1,4) 
    from cob_credito..cr_datos_tramites
    where dt_dato = 'NL'
    and   dt_tramite = @w_op_tramite
    */

    select @w_norma_legal = substring(op_codigo_externo,4,4)
    from cob_cartera..ca_operacion
    where op_banco  = @w_op_banco


    --ABONO CAPITAL 
    select @w_abono_capital = isnull(sum(am_cuota + am_gracia - am_pagado),0)
    from  ca_amortizacion, ca_rubro_op
    where ro_operacion  =  @w_op_operacion
    and   ro_tipo_rubro =  'C'  --Capital
    and   am_operacion  =  ro_operacion
    and   am_concepto   =  ro_concepto
    and   am_dividendo  =  @w_di_dividendo

    --ABONO INTERES
    select @w_abono_interes = isnull(sum(am_cuota + am_gracia - am_pagado),0)
    from  ca_amortizacion, ca_rubro_op
    where ro_operacion  =  @w_op_operacion
    and   ro_tipo_rubro =  'I'  --Interes
    and   am_operacion  =  ro_operacion
    and   am_concepto   =  ro_concepto
    and   am_dividendo  =  @w_di_dividendo
    and   am_estado     != 3


    exec sp_dias_cuota_360
    @i_fecha_ini  = @w_di_fecha_ini,
    @i_fecha_fin  = @w_di_fecha_ven,
    @o_dias       = @w_di_dias_cuota out


    --PROXIMO PAGO INTERES
    select @w_prox_pago_int = di_fecha_ven
    from ca_dividendo
    where di_operacion = @w_op_operacion 
    and di_dividendo = @w_di_dividendo + 1

    if @w_prox_pago_int is null
       select @w_prox_pago_int = '01/01/1900'

            --VALOR A CAPITALIZAR 

    select @w_valor_capitalizar = 0,
           @w_porcentaje_capitalizar = 0  -- JCQ 07/15/2003 Se inicializa El porcentaje a Capitalizar

    if @w_op_opcion_cap = 'S'  
    begin
       if exists (select 1 from ca_acciones
         where  ac_operacion = @w_op_operacion
         and    @w_di_dividendo between  ac_div_ini and ac_div_fin)  
          begin
             select @w_porcentaje_capitalizar = ac_porcentaje
             from ca_acciones
             where  ac_operacion = @w_op_operacion
             and  @w_di_dividendo between  ac_div_ini and ac_div_fin
             
             select @w_valor_capitalizar = (@w_abono_interes * @w_porcentaje_capitalizar )/100
             select @w_abono_interes = round(@w_abono_interes - @w_valor_capitalizar,@w_num_dec)
          end       
    end



    --TIPO DE IDENTIFICACION
    select @w_tipo_identificacion = en_tipo_ced
    from cobis..cl_ente
    where en_ente = @w_op_cliente
    set transaction isolation level read uncommitted


    --IDENTIFICACION
    select @w_identificacion = en_ced_ruc
    from cobis..cl_ente
    where en_ente = @w_op_cliente
    set transaction isolation level read uncommitted



    if ltrim(rtrim(@w_tipo_identificacion)) = 'N'   ---solo para tipo de identificacion NIT, NO SE TOMA EN CUENTA EL DIGITO VERIFICADOR
       select @w_identificacion = substring (@w_identificacion,1,9) 

    select @w_cotizacion = 0          

    if  @w_op_moneda <> @w_moneda_nacional
    begin
        exec sp_buscar_cotizacion
        @i_moneda     = @w_op_moneda,
        @i_fecha      = @w_di_fecha_ven,    
        @o_cotizacion = @w_cotizacion output

        select @w_abono_capital     = round((@w_abono_capital * @w_cotizacion),2)
        select @w_abono_interes     = round((@w_abono_interes * @w_cotizacion),2)
        select @w_saldo_redescuento = round((@w_saldo_redescuento * @w_cotizacion),0)
        if @w_abono_interes  > 0 and @w_abono_interes  <  1
           select  @w_abono_interes = 1
           
        if  @w_abono_capital > 0  and @w_abono_capital < 1
           select @w_abono_capital = 1

    end     
    else      
      select @w_cotizacion = 1
       
        
    if @w_abono_interes > 0.1 or @w_abono_capital > 0.1
    begin
             insert into ca_conciliacion_diaria  (
                cd_fecha_proceso,                   cd_fecha_ven_cuota,
                cd_banco,                           cd_operacion,
                cd_tramite,                         cd_oficina,
                cd_llave_redescuento,               cd_fecha_redescuento,
                cd_nombre,                          cd_dias_interes,     
                cd_tasa_nominal,                    cd_formula_tasa,    
                cd_saldo_redescuento,               cd_abono_capital,
                cd_abono_interes,                   cd_modalidad_pago,    
                cd_norma_legal,                     cd_prox_interes,    
                cd_valor_capitalizar,               cd_banco_sdo_piso,   
                cd_estado,                          cd_identificacion,            
                cd_dividendo,                       cd_z1, 
                cd_w,                               cd_fecha_desembolso, 
                cd_cotizacion)
          values (
                @w_op_fecha_ult_proceso,            @w_di_fecha_ven,
                @w_op_banco,                        @w_op_operacion,
                @w_op_tramite,                      @w_op_oficina,
                @w_op_codigo_externo,               @w_op_fecha_ini,
                @w_op_nombre,                       @w_di_dias_cuota,
                @w_tasa_nominal,                    @w_tasa_pactada,
                @w_saldo_redescuento,               @w_abono_capital,  
                @w_abono_interes,                   @w_modalidad, 
                @w_norma_legal,                     @w_prox_pago_int,
                @w_valor_capitalizar,               @w_op_tipo_linea,                
                'N',                                @w_identificacion,
                @w_di_dividendo,                    '',
                '',                                 @w_fecha_desembolso,
                @w_cotizacion)
                if @@error != 0
                   PRINT 'error al insertar en ca_conciliacion_diaria' + @w_op_banco
                
     end
           --FIN   

fetch cursor_carga_vtos_dia into 
        @w_op_cliente,          @w_op_moneda,    @w_op_margen_redescuento,
        @w_op_banco,            @w_op_tramite,   @w_op_oficina,
        @w_op_codigo_externo,   @w_op_fecha_ini, @w_op_nombre,
        @w_op_sector,           @w_op_tdividendo,@w_op_tipo_linea,
        @w_op_opcion_cap,       @w_op_operacion, @w_fecha_desembolso,
        @w_di_dividendo,        @w_di_dias_cuota,@w_op_fecha_ult_proceso,
        @w_di_fecha_ven,        @w_di_fecha_ini

     end -- cursor_carga_vtos_dia 

     close cursor_carga_vtos_dia
     deallocate cursor_carga_vtos_dia
 
return 0

go


