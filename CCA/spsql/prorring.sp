/************************************************************************/
/*      Nombre Fisico:          prorring.sp                             */
/*      Nombre Logico:          sp_prorroga_cuota_ing                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Xavier Maldonado                        */
/*      Fecha de escritura:     Febrero 2001                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                              PROPOSITO                               */
/*      Ingreso, Actualizacion,Eliminaci¢n(Reversa), Fecha valor, para  */
/*      cuotas prorrogadas.                                             */
/*                            ACTUALIZACIONES                           */
/*      FECHA            AUTOR          MODIFICACION                    */
/*      jul-2005         Elcira Pelaez  Redondeo a decimales de la mon. */
/*      Ago-2005         Elcira Pelaez  Colocar operacion en  la tabla  */
/*                                      ca_detalle                      */
/*      mar-2006         Elcira Pelaez  defecto 6123                    */
/*      mar-2006         John Jairo Rendon  Optimizacion                */
/*      Mayo-2006        Elcira Pelaez   def. 6603 BAC                  */
/*      sep-2006         Elcira Pelaez   def. 7179 BAC                  */
/*      feb-2007         Elcira Pelaez   def. 7955 BAC                  */
/*      Jun-2010         Elcira Pelaez   Quitar Causacion Pasivas   y   */
/*                                       comentados                     */
/*      16-Ago-2019      Luis Ponce      Ajuste Prorroga Individual     */
/*      22-Ago-2019      Sandro Vallejo  Prorroga Grupal e Interciclos  */
/*      26-Ago-2019      Luis Ponce      Ajustes Prorroga Grupal-Interci*/
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_prorroga_cuota_ing')
   drop proc sp_prorroga_cuota_ing
go

create proc sp_prorroga_cuota_ing
(  
   @t_trn                  int      = NULL,
   @s_org                  char(1)      = NULL,
   @s_sesn                 int          = NULL,
   @s_user                 login        = NULL,
   @s_term                 varchar (30) = NULL,
   @s_date                 datetime     = NULL,
   @s_ofi                  smallint     = NULL,
   @s_ssn                  int          = null,
   @s_srv                  varchar (30) = null,
   @s_lsrv                 varchar (30) = null,
   @i_operacion            char(1)      = null,
   @i_banco                cuenta       = null,
   @i_fecha                datetime     = null,
   @i_formato_fecha        smallint     = null,
   @i_cuota                smallint     = null,
   @i_valor_calculado      money        = null,
   @i_fecha_vencimiento    datetime     = null,
   @i_fecha_max_prorroga   datetime     = null,
   @i_fecha_prorroga       datetime     = null,
   @i_modo                 char(1)      = null,
   @o_valor_cuota          money        = null out,
   @o_secuencial_prorroga  int          = null out  --LPO TEC Prorroga Grupal
)

as
declare 
   @w_sp_name           varchar(32),
   @w_operacionca       int,
   @w_return            int,
   @w_error             int,
   @w_di_dividendo      int,
   @w_fecha_ult_proceso datetime,
   @w_di_fecha_ini      datetime,
   @w_di_estado         tinyint,
   @w_est_cancelado     int,
   @w_est_vigente       int,
   @w_est_vencido       int,
   @w_di_fecha_ven      datetime,
   @w_saldo_cap         money,
   @w_cuota_capital     money,
   @w_causacion_acum    money,
   @w_valor_cuota       money,
   @w_num_dias          int,
   @w_tasa              float,
   @w_iva_tasa          float,
   @intereses           money,
   @w_iva               money,
   @w_iva_intereses     money, 
   @w_periodo_int       smallint,
   @w_dias_anio         int,
   @w_causacion         char(1),
   @w_tdividendo        char(1),
   @w_moneda            smallint,
   @w_base_calculo      char(1),
   @w_secuencial_prorroga  int,
   @w_toperacion        catalogo,
   @w_oficina           smallint,
   @w_gerente           smallint,
   @w_fecha_hoy         datetime,
   @w_concepto_int      catalogo,
   @w_secuencia         int,
   @w_otros             money,
   @w_gar_admisible     char(1),
   @w_reestructuracion  char(1),
   @w_calificacion      catalogo,
   @w_dividendo_max     smallint,
   @w_fecha_ini         datetime,
   @w_est_novigente     int,
   @w_saldo_cap1        money,
   @w_saldo_cap_cuota   money,
   @w_pagado_cap_cuota  money,
   @w_total_int         money,
   @w_estado            catalogo,
   @w_fecha_ven         datetime,
   @w_fecha_pro         datetime,
   @w_llave_red_activa  cuenta,
   @w_banco             cuenta,
   @w_tipo              char(1),
   @w_oficina_oper      smallint,
   @w_tramite           int,
   @w_ente              int,
   @w_cod_entidad       catalogo,
   @w_nom_entidad       descripcion,
   @w_linea_credito     catalogo,
   @w_cod_entidad_int   int,
   @w_op_nombre         descripcion,
   @w_ced_ruc           numero,
   @w_tipo_iden         char(2),
   @w_moneda_nacional      tinyint,
   @w_cotizacion           money,
   @w_contador             int,
   @w_dias                 money,
   @w_fecha_ven_cuota_dos  datetime,
   @w_td_factor            int,
   @w_tplazo               catalogo,
   @w_ro_concepto          catalogo,
   @w_am_cuota             money,
   @w_am_acumulado         money,
   @w_am_pagado            money,
   @w_num_dec              tinyint,
   @aux_1                  int,
   @aux_2                  int,
   @w_operacion_pasiva     int

-- INICIALIZACION DE VARIABLES
select @w_est_novigente =  0,
       @w_est_vigente   =  1,
       @w_est_vencido   =  2,
       @w_est_cancelado =  3,
       @w_contador      =  0

--CODIGO DEL CONCEPTO INTERES
select @w_concepto_int = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'



select @w_operacionca        = op_operacion,
       @w_toperacion         = op_toperacion,
       @w_periodo_int        = op_periodo_int,
       @w_tdividendo         = op_tdividendo,
       @w_moneda             = op_moneda,
       @w_dias_anio          = op_dias_anio,
       @w_causacion          = op_causacion,
       @w_base_calculo       = op_base_calculo,
       @w_oficina            = op_oficina,
       @w_gerente            = op_oficial,
       @w_gar_admisible      = op_gar_admisible,
       @w_reestructuracion   = op_reestructuracion,
       @w_calificacion       = op_calificacion,
       @w_fecha_ult_proceso  = op_fecha_ult_proceso,
       @w_tipo               = op_tipo,
       @w_llave_red_activa   = op_codigo_externo,
       @w_fecha_ini          = op_fecha_ini,
       @w_tplazo             = op_tplazo
from   ca_operacion
where  op_banco = @i_banco

exec @w_return = sp_decimales
     @i_moneda       = @w_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @aux_1  out,
     @o_dec_nacional = @aux_2 out

select @w_td_factor = td_factor * @w_periodo_int
from   ca_tdividendo
where  td_tdividendo = @w_tdividendo

-- DETERMINAR EL VALOR DE COTIZACION DEL DIA
if @w_moneda = @w_moneda_nacional
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
        @i_moneda     = @w_moneda,
        @i_fecha      = @w_fecha_ult_proceso,
        @o_cotizacion = @w_cotizacion output
end


-- MAXIMO DIVIDENDO
select @w_dividendo_max = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @w_operacionca

-- CALCULAR IVA DE LA TASA DE INTERES PRESTAMO
      select @w_iva_tasa = 0
      
      select @w_iva_tasa = isnull(sum(ro_porcentaje),0)
      from   ca_rubro_op
      where  ro_operacion  = @w_operacionca
      and    ro_tipo_rubro = 'O'
      and    ro_fpago     in ('A','P')
      AND    ro_concepto_asociado = @w_concepto_int  --LPO TEC
      group  by ro_fpago

-- VALIDAR QUE LOS RUBROS ANTICIPADOS ESTEN CANCELADOS ANTES DE REALIZAR LA PRORROGA
-- *********************************************************************************
if exists (select 1
           from   ca_rubro_op, ca_amortizacion
           where  ro_operacion  = am_operacion
           and    ro_operacion  = @w_operacionca
           and    ro_concepto   = am_concepto
           and    am_dividendo  = @i_cuota + 1
           and    ro_fpago = 'A'
           having sum(am_cuota - am_pagado)!= 0 )
begin
   return 710525
end


if @i_operacion = 'I'
begin
   
   if @i_modo = 'A'
   begin            
      delete ca_detalle
      where de_operacion = @w_operacionca

      -- CALCULAR TASA DE INTERES PRESTAMO
      select @w_tasa = isnull(sum(ro_porcentaje),0)
      from   ca_rubro_op
      where  ro_operacion  = @w_operacionca
      and    ro_tipo_rubro = 'I'
      and    ro_fpago     in ('A','P')
      group  by ro_fpago
           
      select @w_fecha_ven_cuota_dos = di_fecha_ven
      from ca_dividendo
      where di_operacion = @w_operacionca
      and   di_dividendo = @i_cuota + 1

      declare
         cursor_dividendo_qry cursor
         for select di_dividendo, 
                    di_fecha_ini, 
                    di_fecha_ven, 
                    di_estado
             from   ca_dividendo
             where  di_operacion  =  @w_operacionca
             and    di_dividendo  >= @i_cuota
             and    di_dividendo  <= @i_cuota + 1    ---@w_dividendo_max
             and    di_estado in  (@w_est_vigente, @w_est_vencido, @w_est_novigente)
         for read only
      
      open   cursor_dividendo_qry
      
      fetch  cursor_dividendo_qry
      into   @w_di_dividendo, @w_fecha_ini, @w_di_fecha_ven, @w_di_estado 

      while   @@fetch_status = 0
      begin
         if (@@fetch_status = -1)
         begin
            return 708157
         end
         
         if @w_di_estado = 1
            select @w_estado = 'VIGENTE'
            
         if @w_di_estado = 0
            select @w_estado = 'NO VIGENTE'         

         if  @w_di_fecha_ven <= @i_fecha_prorroga   and @w_di_estado = 1
         begin
            select @w_contador = @w_contador + 1
            
               exec sp_dias_base_comercial
                    @i_fecha_ini = @w_di_fecha_ven,
                    @i_fecha_ven = @i_fecha_prorroga,
                    @i_opcion    = 'D',
                    @o_dias_int  = @w_num_dias out
            
               -- DETERMINAR EL SALDO DE CAPITAL
               select @w_saldo_cap1 = sum(am_cuota+am_gracia)
               from   ca_amortizacion, ca_rubro_op
               where  am_operacion  = @w_operacionca
               and    am_estado     != @w_est_cancelado
               and    ro_operacion  = am_operacion
               and    ro_concepto   = am_concepto
               and    ro_tipo_rubro = 'C'   -- (C)apital
               
               -- DETERMINAR VALOR DE CAP. MENORES A CUOTA ACTUAL
               select @w_saldo_cap_cuota  = isnull(sum(am_cuota+am_gracia),0)
               from   ca_amortizacion, ca_rubro_op
               where  am_operacion  = @w_operacionca
               and    am_estado    != @w_est_cancelado
               and    am_dividendo  < @w_di_dividendo
               and    ro_operacion  = am_operacion
               and    ro_concepto   = am_concepto
               and    ro_tipo_rubro = 'C'   ---(C)apital
               -- DETERMINAR VALOR PAGADO DE CAP. = A CUOTA ACTUAL
               select @w_pagado_cap_cuota  = isnull(sum(am_pagado),0)
               from   ca_amortizacion, ca_rubro_op
               where  am_operacion  = @w_operacionca
               and    am_estado    != @w_est_cancelado
               and    am_dividendo  = @w_di_dividendo
               and    ro_operacion  = am_operacion
               and    ro_concepto   = am_concepto
               and    ro_tipo_rubro = 'C'   ---(C)apital
               
               -- DETERMINAR VALOR CAPITAL PARA CALCULO DE CUOTA
               select @w_saldo_cap  = isnull(sum(@w_saldo_cap1 - @w_saldo_cap_cuota - @w_pagado_cap_cuota),0)
               
               --- CALCULO DE INTERES A PRORROGAR
               select @intereses = ((@w_tasa * @w_saldo_cap)/(100 * @w_dias_anio)) * @w_num_dias
          
               -- DETERMINAR CUOTA DE CAPITAL
               select @w_cuota_capital = isnull(sum(am_cuota + am_gracia - am_pagado),0) --LPO CDIG am_pagado
               from   ca_amortizacion, ca_rubro_op
               where  am_operacion  = @w_operacionca
               and    am_operacion  = ro_operacion
               and    am_dividendo  = @w_di_dividendo
               and    am_concepto   = ro_concepto
               and    ro_tipo_rubro = 'C'
               and    am_estado     != @w_est_cancelado
               
               -- DETERMINAR INTERES CUOTA
               select @w_causacion_acum = isnull(sum(am_cuota + am_gracia - am_pagado),0)
               from   ca_amortizacion
               where  am_operacion = @w_operacionca
               and    am_dividendo = @w_di_dividendo
               and    am_concepto  = @w_concepto_int
              
               -- DETERMINAR SUMA INTERES PROYECTADO + INT. POR PRORROGA
               
               select @w_total_int = isnull(sum(@w_causacion_acum + @intereses),0)
               
               --- CALCULO DE IVA INTERES A PRORROGAR
               select @w_iva_intereses = ((@w_iva_tasa * @w_total_int)/(100))
               
               -- DETERMINAR VALOR DE OTROS RUBROS DE CUOTA
               select @w_otros = isnull(sum(am_cuota + am_gracia - am_pagado),0)
               from   ca_amortizacion, ca_rubro_op
               where  am_operacion  = @w_operacionca
               and    am_operacion  = ro_operacion
               and    am_dividendo  = @w_di_dividendo
               and    am_concepto   = ro_concepto
               --and    ro_tipo_rubro not in ('C','I','O')
               and    ro_tipo_rubro not in ('C','I') --LPO CDIG Se quita el 'O'
               and    am_estado     != @w_est_cancelado
               
               select @w_otros = @w_otros + @w_iva_intereses 
               select @w_valor_cuota = isnull(sum(@w_total_int + @w_cuota_capital + @w_otros),0)  
                             
               if @w_contador > 1 
               begin
                  select @w_fecha_ini = @w_di_fecha_ven,
                         @w_total_int = 0,   
                         @w_otros = 0,
                         @w_valor_cuota = 0,   
                         @w_estado = 'VIRTUAL'
               end
               
               if @w_valor_cuota >= 0
               begin
                  insert into ca_detalle
                        (de_operacion,
                        de_dividendo,     de_fechaini,    de_fecha,
                         de_pago_cap,      de_pago_int,    de_pago_otr,
                         de_pago,          de_estado,      de_max_pago)
                  values(@w_operacionca,
                         @w_di_dividendo,  @w_fecha_ini,   @i_fecha_prorroga,
                         @w_cuota_capital, @w_total_int,   @w_otros,
                         @w_valor_cuota,   @w_estado,      convert(money,@w_num_dias))

                    if @@error != 0
                     return 708154
                                          
               end 
         end -- if  @w_di_fecha_ven <= @i_fecha_prorroga
         
         if  (@w_fecha_ini  < @i_fecha_prorroga) and  (@i_fecha_prorroga <=  @w_di_fecha_ven) and @w_di_estado = 0
         begin
            exec sp_dias_base_comercial
                 @i_fecha_ini = @i_fecha_prorroga,
                 @i_fecha_ven = @w_di_fecha_ven,
                 @i_opcion    = 'D',
                 @o_dias_int  = @w_num_dias out
            
            if @i_fecha_prorroga = @w_di_fecha_ven
               select  @w_num_dias = 0
            
            -- DETERMINAR EL SALDO DE CAPITAL
            select @w_saldo_cap1 = sum(am_cuota+am_gracia)
            from   ca_amortizacion, ca_rubro_op
            where  am_operacion   = @w_operacionca
            and    am_estado     != @w_est_cancelado
            and    ro_operacion   = am_operacion
            and    ro_concepto    = am_concepto
            and    ro_tipo_rubro  = 'C'   -- (C)apital
            
            -- DETERMINAR VALOR DE CAP. MENORES A CUOTA ACTUAL
            select @w_saldo_cap_cuota  = isnull(sum(am_cuota+am_gracia),0)
            from   ca_amortizacion, ca_rubro_op
            where  am_operacion  = @w_operacionca
            and    am_estado    != @w_est_cancelado
            and    am_dividendo  < @w_di_dividendo
            and    ro_operacion  = am_operacion
            and    ro_concepto   = am_concepto
            and    ro_tipo_rubro = 'C'   ---(C)apital
            
            -- DETERMINAR VALOR PAGADO DE CAP. = A CUOTA ACTUAL
            select @w_pagado_cap_cuota  = isnull(sum(am_pagado),0)
            from   ca_amortizacion, ca_rubro_op
            where  am_operacion  = @w_operacionca
            and    am_estado    != @w_est_cancelado
            and    am_dividendo  = @w_di_dividendo
            and    ro_operacion  = am_operacion
            and    ro_concepto   = am_concepto
            and    ro_tipo_rubro = 'C'   ---(C)apital
            
            -- DETERMINAR VALOR CAPITAL PARA CALCULO DE CUOTA
            select @w_saldo_cap  = isnull(sum(@w_saldo_cap1 - @w_saldo_cap_cuota - @w_pagado_cap_cuota),0)
           
            --- CALCULO DE INTERES A PRORROGAR
            select @intereses = ((@w_tasa * @w_saldo_cap)/(100 * @w_dias_anio)) * @w_num_dias
            
                          
            -- DETERMINAR CUOTA DE CAPITAL
            select @w_cuota_capital = isnull(sum(am_cuota + am_gracia),0)
            from   ca_amortizacion, ca_rubro_op
            where  am_operacion  = @w_operacionca
            and    am_operacion  = ro_operacion
            and    am_dividendo  = @w_di_dividendo
            and    am_concepto   = ro_concepto
            and    ro_tipo_rubro = 'C'
            and    am_estado     != @w_est_cancelado
            
            select @w_causacion_acum = 0
            
            -- DETERMINAR SUMA INTERES PROYECTADO + INT. POR PRORROGA
            select @w_total_int = isnull(sum(@w_causacion_acum + @intereses),0)
            
             --- CALCULO DE IVA INTERES A PRORROGAR
            select @w_iva_intereses = ((@w_iva_tasa * @w_total_int)/(100))
            
            -- DETERMINAR VALOR DE OTROS RUBROS DE CUOTA
            select @w_otros = isnull(sum(am_cuota + am_gracia - am_pagado),0)
            from   ca_amortizacion, ca_rubro_op
            where  am_operacion  = @w_operacionca
            and    am_operacion  = ro_operacion
            and    am_dividendo  = @w_di_dividendo
            and    am_concepto   = ro_concepto
            and    ro_tipo_rubro not in ('C','I','O')
            and    am_estado     != @w_est_cancelado
            
            select @w_otros = @w_otros + @w_iva_intereses
            select @w_valor_cuota = isnull(sum(@w_total_int + @w_cuota_capital + @w_otros),0) 
            
            select @w_estado = 'NO VIGENTE' 
            
            if @w_valor_cuota >= 0
            begin
               
               
               insert into ca_detalle
                     (de_operacion,
                      de_dividendo,     de_fechaini,       de_fecha,
                      de_pago_cap,      de_pago_int,       de_pago_otr,
                      de_pago,          de_estado,         de_max_pago)
               values(@w_operacionca,
                      @w_di_dividendo,  @i_fecha_prorroga, @w_di_fecha_ven,    ---values(@w_di_dividendo,  @w_fecha_ini,   @i_fecha_prorroga,
                      @w_cuota_capital, @w_total_int,      @w_otros,
                      @w_valor_cuota,   @w_estado,         convert(money,@w_num_dias))


              if @@error != 0
                 return 708154
                                 
            end
         end  --(@w_fecha_ini  < @i_fecha_prorroga) and  (@i_fecha_prorroga <=  @w_di_fecha_ven)
         
         fetch   cursor_dividendo_qry
         into    @w_di_dividendo, 
                 @w_fecha_ini, 
                 @w_di_fecha_ven, 
                 @w_di_estado
      end -- WHILE PRINCIPAL  
      
      close cursor_dividendo_qry
      deallocate cursor_dividendo_qry
           
      
      select 'No. CUOTA'         = de_dividendo,
             'FECHA INICIO'      = convert(varchar(10),de_fechaini,@i_formato_fecha),
             'FECHA VENCIMIENTO' = convert(varchar(10),de_fecha,@i_formato_fecha),
             'PAGO CAPITAL'      = round(convert(money, de_pago_cap),@w_num_dec),
             'PAGO INTERES'      = round(convert(money, de_pago_int),@w_num_dec),
             'PAGO OTROS'        = round(convert(money, de_pago_otr),@w_num_dec),
             'PAGO TOTAL'        = round(convert(money, de_pago),@w_num_dec),
             'ESTADO'            = de_estado
      from   ca_detalle
      where de_operacion = @w_operacionca     
   end
   
   if @i_modo = 'B'  
   begin    --BOTON TRANSMITIR PRORROGA   
      declare
         cursor_ca_detalle cursor
         for select de_dividendo,     de_fechaini,    de_fecha,
                    de_pago_cap,      de_pago_int,    de_pago_otr,
                    de_pago,          de_estado,      de_max_pago
             from   ca_detalle
             where  de_operacion = @w_operacionca
             order  by de_dividendo
      
      open cursor_ca_detalle
      
      fetch cursor_ca_detalle
      into  @w_di_dividendo,  @w_fecha_ini,   @w_fecha_pro,
            @w_cuota_capital, @w_total_int,   @w_otros,
            @w_valor_cuota,   @w_estado,      @w_dias
      
      while @@fetch_status = 0
      begin
         if (@@fetch_status = -1)
         begin
            close cursor_ca_detalle
            deallocate cursor_ca_detalle
            return 708157
         end
         
         if @w_estado = 'NO VIGENTE'
            select @w_fecha_pro = @w_fecha_ini
         
         select @w_di_fecha_ini = di_fecha_ini,
                @w_di_fecha_ven = di_fecha_ven,
                @w_di_estado    = di_estado
         from   ca_dividendo
         where  di_operacion = @w_operacionca
         and    di_dividendo = @w_di_dividendo

         if @w_di_fecha_ven <= @w_fecha_pro and @w_di_estado  = 1
         begin
               exec @w_secuencial_prorroga =  sp_gen_sec
                    @i_operacion =  @w_operacionca

               exec cob_cartera..sp_historial
                    @i_operacionca = @w_operacionca,
                    @i_secuencial  = @w_secuencial_prorroga
                              
               insert into ca_prorroga
                     (pr_operacion,        pr_nro_cuota,      pr_fecha_proc,
                      pr_fecha_venc_ini,   pr_fecha_venc_pr,  pr_usuario)
               values(@w_operacionca,      @w_di_dividendo,   @s_date,
                      @w_di_fecha_ven,     @w_fecha_pro,      @s_user)
               
               if @@error != 0
               begin
                    close cursor_ca_detalle
                    deallocate cursor_ca_detalle
                  return 710531
               END   
               ---Transaccion de servicio - Inserción de Prorroga
               insert into cob_cartera..ca_prorroga_ts
                     (prs_fecha_proceso_ts,  prs_fecha_ts,     prs_usuario_ts,
                      prs_oficina_ts,        prs_terminal_ts,  prs_tipo_transaccion_ts,
                      prs_origen_ts,         prs_clase_ts,     prs_operacion,
                      prs_nro_cuota,         prs_fecha_proc,   prs_fecha_venc_ini,
                      prs_fecha_venc_pr,     prs_usuario
                     )
               values(@s_date,               getdate(),        @s_user,
                      @s_ofi,                @s_term,          isnull(@t_trn,1),
                      isnull(@s_org,'L'),    'N',              @w_operacionca,
                      @w_di_dividendo,       @s_date,          @w_di_fecha_ven,
                      @w_fecha_pro, @s_user)
               
               if @@error != 0
               begin
                close cursor_ca_detalle
                deallocate cursor_ca_detalle
                  return      710047         
               END
            
           
            -- ACTUALIZAR DIVIDENDO
            update ca_dividendo
            set    di_fecha_ven = @w_fecha_pro,
                   di_prorroga  = 'S',
                   di_dias_cuota = di_dias_cuota + convert(int,@w_dias)
            where  di_operacion = @w_operacionca
            and    di_dividendo = @w_di_dividendo

            if @@error != 0
            begin
                close cursor_ca_detalle
                deallocate cursor_ca_detalle
               return      705043         
            END
            
            -- ACTUALIZAR AMORTIZACION
            select @w_secuencia = max(am_secuencia)
            from   ca_amortizacion
            where  am_operacion = @w_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_concepto_int
            
            update ca_amortizacion
            set    am_cuota  =  am_pagado + round(@w_total_int,@w_num_dec) , ---ACT AGO042005
                   am_estado = 1
            where  am_operacion = @w_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_concepto_int
            and    am_secuencia = @w_secuencia
                        
            if @@error != 0
            begin
                close cursor_ca_detalle
                deallocate cursor_ca_detalle
               return      705050         
            END
            
           select @w_iva = am_cuota 
           from ca_amortizacion
           where  am_operacion = @w_operacionca
           and    am_dividendo = @w_di_dividendo
           and    am_concepto  = @w_concepto_int
           and    am_secuencia = @w_secuencia
           
           select @w_iva_intereses = ((@w_iva_tasa * @w_iva)/(100))
           
           update ca_amortizacion
           set    am_cuota  =  round(@w_iva_intereses,@w_num_dec) , ---ACT AGO042005
                  am_estado = 1
           where  am_operacion = @w_operacionca
           and    am_dividendo = @w_di_dividendo
           and    am_concepto  = 'IVA_INT'
           and    am_secuencia = @w_secuencia
                        
            if @@error != 0
            begin
                close cursor_ca_detalle
                deallocate cursor_ca_detalle
               return      705050         
            END

           
            insert ca_transaccion
                  (tr_secuencial,              tr_fecha_mov,          tr_toperacion,               tr_moneda,
                   tr_operacion,               tr_tran,               tr_en_linea,                 tr_banco,
                   tr_dias_calc,               tr_ofi_oper,           tr_ofi_usu,                  tr_usuario,
                   tr_terminal,                tr_fecha_ref,          tr_secuencial_ref,           tr_estado,
                   tr_observacion,             tr_gerente,            tr_gar_admisible,            tr_reestructuracion,
                   tr_calificacion,            tr_fecha_cont,         tr_comprobante)
            values(@w_secuencial_prorroga,     @s_date,               @w_toperacion,               @w_moneda,
                   @w_operacionca ,            'PRO',                 'S',                         @i_banco,
                   convert(int,@w_dias),       @w_oficina,            @s_ofi,                      @s_user,
                   @s_term,                    @w_fecha_ult_proceso,  @w_secuencial_prorroga,      'ING',
                   '',                         @w_gerente,            isnull(@w_gar_admisible,''), isnull(@w_reestructuracion,''),
                   isnull(@w_calificacion,''), @w_fecha_ult_proceso,  0) 
                   
                   if @@error != 0
                   begin
                        close cursor_ca_detalle
                        deallocate cursor_ca_detalle
                      return  703041
                   END
         end
         
         if (@w_di_fecha_ini < @w_fecha_pro)  and  (@w_fecha_pro < @w_di_fecha_ven) and @w_di_estado  = 0
         begin
            
            
            -- ACTUALIZAR DIVIDENDO
            update ca_dividendo
            set    di_fecha_ini = @w_fecha_ini,  
                   di_prorroga  = 'N',
                   di_dias_cuota = convert(int,@w_dias)    ----@w_num_dias
            where  di_operacion = @w_operacionca
            and    di_dividendo = @w_di_dividendo

            if @@error != 0
           begin
                close cursor_ca_detalle
                deallocate cursor_ca_detalle
               return      705043         
            END
            
            -- ACTUALIZAR AMORTIZACION
            select @w_secuencia = max(am_secuencia)
            from   ca_amortizacion
            where  am_operacion = @w_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_concepto_int
            
            update ca_amortizacion
            set    am_cuota  = @w_total_int,
                   am_estado = 0
            where  am_operacion = @w_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_concepto_int
            and    am_secuencia = @w_secuencia

            if @@error != 0
            begin
                close cursor_ca_detalle
                deallocate cursor_ca_detalle
               return      705050         
            END
            
           select @w_iva = am_cuota 
           from ca_amortizacion
           where  am_operacion = @w_operacionca
           and    am_dividendo = @w_di_dividendo
           and    am_concepto  = @w_concepto_int
           and    am_secuencia = @w_secuencia
           
           select @w_iva_intereses = ((@w_iva_tasa * @w_iva)/(100))
           
           update ca_amortizacion
           set    am_cuota  =  round(@w_iva_intereses,@w_num_dec) , ---ACT AGO042005
                  am_estado = 1
           where  am_operacion = @w_operacionca
           and    am_dividendo = @w_di_dividendo
           and    am_concepto  = 'IVA_INT'
           and    am_secuencia = @w_secuencia
                        
            if @@error != 0
            begin
                close cursor_ca_detalle
                deallocate cursor_ca_detalle
               return      705050   
           END 
         end
         
         if (@w_di_fecha_ini < @w_fecha_pro)  and  (@w_fecha_pro = @w_di_fecha_ven) and @w_di_estado  = 0
         begin
            
            -- ACTUALIZAR DATOS CUOTA ANTERIOR
            -- *******************************
            declare
               cursor_ca_detalle1 cursor
               for select ro_concepto
                   from   ca_rubro_op
                   where  ro_operacion = @w_operacionca
                   and    ro_tipo_rubro <> 'I'
                   order by ro_concepto
            
            open cursor_ca_detalle1
            fetch cursor_ca_detalle1
            into  @w_ro_concepto
            
            while @@fetch_status = 0
            begin
               if (@@fetch_status = -1)
               begin
                  return 708157
               end
               
               select @w_am_cuota     = 0,
                      @w_am_acumulado = 0,
                      @w_am_pagado    = 0
               
               select @w_am_cuota     = isnull(am_cuota,0),
                      @w_am_acumulado = isnull(am_acumulado,0),
                      @w_am_pagado    = isnull(am_pagado,0) 
               from ca_amortizacion
               where am_operacion  = @w_operacionca
               and   am_dividendo  = @w_di_dividendo 
               and   am_concepto   = @w_ro_concepto
               
               update ca_amortizacion
               set    am_cuota = am_cuota     +  @w_am_cuota,
                      am_acumulado = am_acumulado +  @w_am_acumulado,
                      am_pagado    = am_pagado    +  @w_am_pagado,
                      am_estado    = 1
               from   ca_amortizacion
               where  am_operacion  = @w_operacionca
               and    am_dividendo  = @w_di_dividendo - 1
               and    am_concepto   = @w_ro_concepto
               
               fetch cursor_ca_detalle1
               into  @w_ro_concepto
            end
            
            close cursor_ca_detalle1
            deallocate cursor_ca_detalle1
            
            delete ca_dividendo
            where di_operacion  = @w_operacionca
            and   di_dividendo  = @w_di_dividendo
            
            delete ca_amortizacion
            where am_operacion  = @w_operacionca
            and   am_dividendo  = @w_di_dividendo
            
            delete ca_correccion
            where co_operacion  = @w_operacionca
            and   co_dividendo  = @w_di_dividendo
            
            delete ca_cuota_adicional
            where ca_operacion  = @w_operacionca
            and   ca_dividendo  = @w_di_dividendo
            
            update ca_dividendo
            set di_dividendo = di_dividendo - 1
            where di_operacion  = @w_operacionca
            and   di_dividendo  >= @w_di_dividendo
            
            update ca_amortizacion
            set am_dividendo = am_dividendo - 1
            where am_operacion  = @w_operacionca
            and   am_dividendo  >= @w_di_dividendo
            
            update ca_correccion
            set co_dividendo = co_dividendo - 1
            where co_operacion  = @w_operacionca
            and   co_dividendo  >= @w_di_dividendo
            
            update ca_cuota_adicional
            set ca_dividendo = ca_dividendo - 1
            where ca_operacion  = @w_operacionca
            and   ca_dividendo  >= @w_di_dividendo
         end
         
         fetch cursor_ca_detalle
         into  @w_di_dividendo,  @w_fecha_ini,   @w_fecha_pro,
               @w_cuota_capital, @w_total_int,   @w_otros,
               @w_valor_cuota,   @w_estado,      @w_dias
      end -- WHILE PRINCIPAL
      close cursor_ca_detalle
      deallocate cursor_ca_detalle
      
       select @o_secuencial_prorroga = @w_secuencial_prorroga --LPO TEC INICIO Prorroga Grupal        
          
      if @w_tipo = 'C'
      begin
         
         select @w_operacion_pasiva = rp_pasiva
         from   ca_relacion_ptmo
         where  rp_activa = @w_operacionca
         
         if @w_operacion_pasiva is not null
         begin
            
            select @w_fecha_ult_proceso = op_fecha_ult_proceso,
                   @w_oficina_oper      = op_oficina,
                   @w_tramite           = op_tramite,
                   @w_banco             = op_banco,
                   @w_ente              = op_cliente,
                   @w_cod_entidad       = op_tipo_linea,
                   @w_linea_credito     = op_toperacion,
                   @w_tipo              = op_tipo,
                   @w_op_nombre         = op_nombre
            from   ca_operacion
            where  op_operacion         = @w_operacion_pasiva
            and    op_codigo_externo    = @w_llave_red_activa
            and    op_tipo = 'R'
            
            if @@rowcount = 0
            begin
               PRINT 'MSG. INFORMATIVO !!!Esta operacion es de redescuento revisar la pasiva.. Continuar'
            end
            else
            begin
               select @w_nom_entidad   = valor
               from   cobis..cl_catalogo
               where  tabla = (select codigo
                               from   cobis..cl_tabla
                               where  tabla  = 'ca_tipo_linea')
                               and    codigo = @w_cod_entidad 
               
               select @w_cod_entidad_int = convert(int,@w_cod_entidad)
               
               select @w_ced_ruc = en_ced_ruc,
                      @w_tipo_iden = en_tipo_ced
               from   cobis..cl_ente 
               where  en_ente = @w_ente
               
               -- INSERCION EN ARCHIVO REDESCUENTOS
               exec @w_return = cob_credito..sp_crea_op_redes
                    @s_ssn             = @s_ssn,
                    @s_ofi             = @s_ofi,
                    @s_user            = @s_user,
                    @s_date            = @s_date,
                    @s_term            = @s_term,
                    @i_tramite         = @w_tramite,  --TRAMITE PASIVA
                    @i_modo            = 1 --Crea archivo redescuento
               
               if @w_return != 0 or  @@error != 0
                  return 710095
                  
             end --pasiva con llave de redescuento diferente
             

         end
         ELSE
            PRINT 'MENSAJE INFORMATIVO !!!Esta operacion es de redescuento y no tiene la pasiva asociada'
      END      
   end -- MODO B
end ---I

return 0
go
