/************************************************************************/
/*      Nombre Fisico:          actmor.sp                         		*/
/*      Nombre Logico:       	sp_act_amortiza                         */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Fecha de escritura:     Agosto 2002                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios que son       	*/
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
/*      Actualiza los dividendos Vigentes y  Vencidos en la tabla de    */
/*      Amoritizacion en Operaciones Pasivas                            */
/*                              PROPOSITO                               */
/*      FECHA         AUTOR          CAMBIO                             */
/*      Junio-2010    ELcira Pelaez  Quitar Codigo Causacion Pasivas    */
/*    	06/06/2023	  M. Cordova	 Cambio variable @w_op_calificacion */
/*									 de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_act_amortiza')
   drop proc sp_act_amortiza
go

create proc sp_act_amortiza
(  @s_sesn           int          = NULL,
   @s_user           login        = NULL,
   @s_term           varchar (30) = NULL,
   @s_date           datetime     = NULL,
   @s_ofi            smallint     = NULL,
   @s_ssn            int          = null,
   @s_srv            varchar (30) = null,
   @s_lsrv           varchar (30) = null,
   @t_trn            int          = null,
   @i_operacion      cuenta       = null,
   @i_banco          cuenta       = null,
   @i_dividendo      smallint     = null,
   @i_concepto       char(3)      = null,
   @i_valor_cap      money        = null,
   @i_valor_int      money        = null,
   @i_estado_div     varchar(30)  = null,
   @i_formato_fecha  int          = null
)

as
declare 
   @w_sp_name           descripcion,
   @w_operacionca       int,
   @w_error             int,
   @w_di_dividendo      int,
   @w_di_estado         int,
   @w_di_fecha_ven      datetime,
   @w_dividendo_vig     int,
   @w_est_vigente       int,
   @w_estado            varchar(64),
   @w_dividendo_max_ven int,
   @w_est_vencido       int,
   @w_pagot             money,
   @w_pago_cap          money,
   @w_pago_int          money,
   @w_pago_otr          money,
   @w_dividendo_min_ven int,
   @w_di_dias_cuota     int,
   @w_pago_mora         money,
   @w_fecha_fin_op      datetime,
   @w_op_toperacion     catalogo,
   @w_op_moneda         tinyint,
   @w_op_oficina        smallint,
   @w_fecha_ult_proceso datetime,
   @w_op_oficial        smallint,
   @w_op_gar_admisible  char(1),
   @w_op_reestruc       char(1),
   @w_op_calificacion   catalogo, --MCO 05/06/2023 Se cambio el tipo de dato de char(1) a catalogo
   @w_desc_estado       descripcion,
   @w_cod_valor         int,
   @w_cuota             money,
   @w_insert            char(1),
   @w_am_estado         tinyint,
   @w_secuencial        int,
   @w_min_sec_int       int,
   @w_min_sec_cap       int,
   @w_acumulado_or      money,
   @w_cuota_or          money,
   @w_actualizo         char(1),
   @w_cliente           varchar(30),
   @w_tipo              catalogo,
   @w_tipo_amortizacion catalogo,
   @w_dias_div          int,
   @w_tdividendo        catalogo,
   @w_dias_anio         int,
   @w_sector            catalogo,
   @w_fecha_liq         datetime,
   @w_fecha_ini         datetime,
   @w_fecha_a_causar    datetime,
   @w_clausula          catalogo,
   @w_base_calculo      catalogo,
   @w_causacion         catalogo,
   @w_moneda_nacional   tinyint,
   @w_cotizacion        money,
   @w_monto_op          money,
   @w_cod_cliente       int,
   @w_estado_op         tinyint,
   @w_op_llave_redescuento cuenta,
   @w_parametro_int        catalogo,
   @w_parametro_cap        catalogo,
   @w_am_estado_cap        tinyint,
   @w_cuota_or_cap         money,
   @w_am_estado_int        tinyint,
   @w_cuota_or_int         money,
   @w_cod_valor_cap        int,
   @w_cod_valor_int        int,
   @w_cuota_int            money,
   @w_cuota_cap            money,
   @w_afectacion_cap       char(1),
   @w_afectacion_int       char(1)
   
-- INICIALIZACION DE VARIABLES
select @w_sp_name       = 'sp_act_amortiza',
       @w_est_vigente   = 1,
       @w_est_vencido   = 2,
       @w_insert        = 'N'



-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


select @w_parametro_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
set transaction isolation level read uncommitted


select @w_parametro_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
set transaction isolation level read uncommitted



delete ca_detalle_amor WHERE de_dividendo >= 0
     
select @w_operacionca        = op_operacion,
       @w_op_toperacion      = op_toperacion,
       @w_op_moneda          = op_moneda,
       @w_op_oficina         = op_oficina,
       @w_op_oficial         = op_oficial,
       @w_cliente            = op_nombre,
       @w_cod_cliente        = op_cliente,
       @w_fecha_ult_proceso  = op_fecha_ult_proceso,
       @w_op_gar_admisible   = isnull(op_gar_admisible, ''),
       @w_op_reestruc        = isnull(op_reestructuracion, ''),
       @w_op_calificacion    = isnull(op_calificacion, ''),
       @w_fecha_fin_op       = op_fecha_fin,
       @w_tipo               = op_tipo,
       @w_tipo_amortizacion  = op_tipo_amortizacion,
       @w_dias_div           = op_periodo_int,
       @w_tdividendo         = op_tdividendo,
       @w_dias_anio          = op_dias_anio,
       @w_sector             = op_sector,
       @w_fecha_liq          = op_fecha_liq,
       @w_fecha_ini          = op_fecha_ini,
       @w_clausula           = op_clausula_aplicada,
       @w_base_calculo       = op_base_calculo,
       @w_causacion          = op_causacion,
       @w_monto_op           = op_monto,
       @w_estado_op          = op_estado,
       @w_op_llave_redescuento =    op_codigo_externo
       from   ca_operacion
where  op_banco       = @i_banco




/* DETERMINAR EL VALOR DE COTIZACION DEL DIA */
if @w_op_moneda = @w_moneda_nacional
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
        @o_cotizacion = @w_cotizacion output,
        @i_moneda     = @w_op_moneda,
        @i_fecha      = @w_fecha_ult_proceso
end




if @i_operacion = 'A'
begin
   
   /**DATOS CAPITAL***/
   select @w_am_estado_cap = am_estado
   from   ca_amortizacion
   where  am_operacion = @w_operacionca
   and    am_dividendo = @i_dividendo
   and    am_concepto  = @w_parametro_cap
   

   select @w_cod_valor_cap = co_codigo * 1000 + (@w_am_estado_cap * 10) + 0
   from   ca_concepto
   where  co_concepto = @w_parametro_cap

   
   select @w_min_sec_cap = min(am_secuencia)
   from   ca_amortizacion
   where  am_operacion = @w_operacionca
   and    am_dividendo = @i_dividendo
   and    am_concepto  = @w_parametro_cap
   
   select @w_cuota_or_cap     = am_cuota
   from   ca_amortizacion
   where  am_operacion = @w_operacionca
   and    am_dividendo = @i_dividendo
   and    am_concepto  = @w_parametro_cap
   and    am_secuencia = @w_min_sec_cap
   



   /**DATOS INTERES***/
   select @w_am_estado_int = am_estado
   from   ca_amortizacion
   where  am_operacion = @w_operacionca
   and    am_dividendo = @i_dividendo
   and    am_concepto  = @w_parametro_int
   
  
   select @w_cod_valor_int = co_codigo * 1000 + (@w_am_estado_int * 10) + 0
   from   ca_concepto
   where  co_concepto = @w_parametro_int

   select @w_min_sec_int = min(am_secuencia)
   from   ca_amortizacion
   where  am_operacion = @w_operacionca
   and    am_dividendo = @i_dividendo
   and    am_concepto  = @w_parametro_int
   
 	
   select @w_cuota_or_int = am_cuota
   from   ca_amortizacion
   where  am_operacion = @w_operacionca
   and    am_dividendo = @i_dividendo
   and    am_concepto  = @w_parametro_int
   and    am_secuencia = @w_min_sec_int
   

   exec @w_secuencial = sp_gen_sec
        @i_operacion = @w_operacionca


   -- OBTENER RESPALDO ANTES DE LA APLICACION DEL PAGO
   exec @w_error  = sp_historial
        @i_operacionca  = @w_operacionca,
        @i_secuencial   = @w_secuencial
   
   if @w_error != 0
      goto ERROR




   /*REGISTRO CAPITAL*/

   if @i_valor_cap <> @w_cuota_or_cap
   begin
      if @i_valor_cap > @w_cuota_or_cap
         select @w_cuota_cap = sum(@i_valor_cap - @w_cuota_or_cap),
                @w_afectacion_cap = 'C'

      
      if @i_valor_cap < @w_cuota_or_cap
         select @w_cuota_cap = sum(@w_cuota_or_cap - @i_valor_cap),
                @w_afectacion_cap = 'D'
   end


   /*REGISTRO INTERES*/

   if @i_valor_int <> @w_cuota_or_int
   begin
      if @i_valor_int > @w_cuota_or_int
         select @w_cuota_int = sum(@i_valor_int - @w_cuota_or_int),
                @w_afectacion_int = 'C'

      
      if @i_valor_int < @w_cuota_or_int
         select @w_cuota_int = sum(@w_cuota_or_int - @i_valor_int),
                @w_afectacion_int = 'D'

   end


   /** INSERCION DE CABECERA AJUSTE CONTABLE  **/

   ---if @i_valor_cap <> @w_cuota_or_cap  or   @i_valor_int <> @w_cuota_or_int
   if @i_valor_int <> @w_cuota_or_int
   begin
      insert into ca_transaccion
           (tr_secuencial,         tr_fecha_mov,           tr_toperacion,       tr_moneda,
            tr_operacion,          tr_tran,                tr_en_linea,         tr_banco,
            tr_dias_calc,          tr_ofi_oper,            tr_ofi_usu,          tr_usuario,
            tr_terminal,           tr_fecha_ref,           tr_secuencial_ref,   tr_estado,
            tr_gerente,            tr_comprobante,         tr_fecha_cont,       tr_gar_admisible,
            tr_reestructuracion,   tr_calificacion,        tr_observacion)
      values(@w_secuencial,         @s_date,                @w_op_toperacion,    @w_op_moneda,
            @w_operacionca,        'AJP',                  'S',                 @i_banco,
            0,                     @w_op_oficina,          @s_ofi,              @s_user,
            @s_term,               @w_fecha_ult_proceso,   @w_secuencial,       'ING',
            @w_op_oficial,         0,                      @s_date,             @w_op_gar_admisible,
            @w_op_reestruc,        @w_op_calificacion,     '')
      if @@error != 0
      begin 
         print 'error en la cabecera'
          return 708165
      end

   
      -- INSERCION DETALLE DEL AJUSTE INTERES
      if @i_valor_int <> @w_cuota_or_int
      begin
         insert into ca_det_trn
               (dtr_secuencial,  	dtr_operacion,    dtr_dividendo,    dtr_concepto,
                dtr_estado,      	dtr_periodo,      dtr_codvalor,     dtr_monto,
                dtr_monto_mn,    	dtr_moneda,       dtr_cotizacion,   dtr_tcotizacion,
                dtr_afectacion,  	dtr_cuenta,       dtr_beneficiario, dtr_monto_cont)
         values(@w_secuencial,   	@w_operacionca,   @i_dividendo,     @w_parametro_int,
                @w_am_estado_int,	0,                @w_cod_valor_int, @w_cuota_int,
                @w_cuota_int,        	@w_op_moneda,     1.0,              'N',
                @w_afectacion_int,      '00001',          @w_cliente,       0)
      
         if @@error != 0
         begin 
            print 'error en el interes'
            return 708165
         end
      end


      /**ACTUALIZO INTERES **/
      update ca_amortizacion
      set    am_cuota = @i_valor_int,
             am_acumulado  = @i_valor_int
      where  am_operacion  = @w_operacionca
      and    am_dividendo  = @i_dividendo
      and    am_concepto   = @w_parametro_int
      and    am_secuencia  = @w_min_sec_int

        
      update ca_conciliacion_diaria
      set cd_w  = null,
          cd_z1 = null,
          cd_estado  = 'A'       ---datos Actualizados
      where cd_banco = @i_banco
   end
end


if @i_operacion = 'R'
begin

   -- BUSCAR DIVIDENDO VIGENTE
   select @w_dividendo_vig = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vigente
   
   select @w_dividendo_vig = isnull(@w_dividendo_vig,0)


   
   -- BUSCAR MINIMO DIVIDENDO VENCIDO
   select @w_dividendo_min_ven = min(di_dividendo)
   from ca_dividendo
   where di_operacion = @w_operacionca
   and   di_estado    = @w_est_vencido 
   
   select @w_dividendo_min_ven = isnull(@w_dividendo_min_ven,0)


   
   -- BUSCAR MAXIMO DIVIDENDO VENCIDO
   
   if @w_dividendo_vig = 0   --todos los dividendos estan vencidos
   begin
      select @w_dividendo_max_ven = max(di_dividendo)
      from ca_dividendo
      where di_operacion = @w_operacionca
      and   di_estado    = @w_est_vencido


      select @w_dividendo_vig = @w_dividendo_max_ven
      
      select @w_dividendo_vig = isnull(@w_dividendo_vig,0)
  

      if @w_dividendo_vig = 0  --todos los dividendos estan cancelados
      begin    
         print 'No Existen dividendos Vigentes ni Vencidos...actmor.sp'
         
         insert into ca_detalle_amor
               (de_dividendo,        de_fecha_ven,      de_dias_cuota,
                de_pago_cap,         de_pago_int,       de_pago_mora,
                de_pago_otr,         de_pago,           de_estado )
         values(0,                   @w_fecha_fin_op,   0,
                0,                   0,                 0,
                0,                   0,                 'CANCELADO')
         

         select 'No. CUOTA'         = de_dividendo,
                'FECHA VENCIMIENTO' = convert(varchar(10),de_fecha_ven,@i_formato_fecha),
                'DIAS'              = de_dias_cuota,
                'CAPITAL'           = convert(money, de_pago_cap),
                'INTERES'           = convert(money, de_pago_int),
                'MORA'              = convert(money, de_pago_mora),
                'OTROS'             = convert(money, de_pago_otr),
                'VALOR CUOTA'       = convert(money, de_pago),
                'ESTADO'            = de_estado
         from   ca_detalle_amor
         
         return 0
      end
   end

   
   declare
      cursor_dividendo cursor
      for select di_dividendo,  di_fecha_ven, di_estado,
                 di_dias_cuota
          from   ca_dividendo
          where  di_operacion  =  @w_operacionca
          and    di_dividendo  >=  @w_dividendo_min_ven
          and    di_dividendo  <=  @w_dividendo_vig
          and    di_estado in (@w_est_vigente, @w_est_vencido)
          for read only

   open    cursor_dividendo
   
   fetch cursor_dividendo
   into  @w_di_dividendo,  @w_di_fecha_ven, @w_di_estado,
         @w_di_dias_cuota
   
   while   @@fetch_status = 0
   begin 
      if (@@fetch_status = -1) 
      begin
         select @w_error = 708999
         goto ERROR
      end  
      
      -- Inicializacion de Variables
      select @w_pago_cap  = 0,
             @w_pago_int  = 0,
             @w_pago_mora = 0,
             @w_pago_otr  = 0,
             @w_pagot     = 0


      -- CAPITAL CUOTA
      select @w_pago_cap = am_cuota
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion  = ro_operacion
      and    am_operacion  = @w_operacionca
      and    am_concepto   = ro_concepto
      and    am_dividendo  = @w_di_dividendo
      and    ro_tipo_rubro = 'C'
      
      select @w_pago_cap = isnull(@w_pago_cap,0)
      
      -- INTERES CUOTA
      select @w_pago_int = isnull(am_cuota,0)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion  = ro_operacion
      and    am_operacion  = @w_operacionca
      and    am_concepto   = ro_concepto
      and    am_dividendo  = @w_di_dividendo
      and    am_concepto   = 'INT'
      and    ro_tipo_rubro = 'I'
      
      select @w_pago_int = isnull(@w_pago_int,0)
      
      -- MORA CUOTA
      select @w_pago_mora = isnull(am_cuota,0)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion  = ro_operacion
      and    am_operacion  = @w_operacionca
      and    am_concepto   = ro_concepto
      and    am_dividendo  = @w_di_dividendo
      and    am_concepto   = 'IMO'
      and    ro_tipo_rubro = 'M'
      
      select @w_pago_mora = isnull(@w_pago_mora,0)
      
      -- OTROS RUBROS
      select @w_pago_otr = isnull(am_cuota,0)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion  = ro_operacion
      and    am_operacion  = @w_operacionca
      and    am_concepto   = ro_concepto
      and    am_dividendo  = @w_di_dividendo
      and    ro_tipo_rubro not in ('C','I','M')
      
      select @w_pago_otr = isnull(@w_pago_otr,0)
      
      -- VALOR CUOTA
      select @w_pagot = isnull(sum(@w_pago_cap + @w_pago_int + @w_pago_mora + @w_pago_otr),0)
      
      select @w_estado = es_descripcion
      from   ca_estado
      where  es_codigo = @w_di_estado
      
      if @w_pagot > 0
      begin
         insert into ca_detalle_amor
               (de_dividendo,    de_fecha_ven,     de_dias_cuota,
                de_pago_cap,     de_pago_int,      de_pago_mora,
                de_pago_otr,     de_pago,          de_estado)
         values(@w_di_dividendo, @w_di_fecha_ven,  @w_di_dias_cuota,
                @w_pago_cap,     @w_pago_int,      @w_pago_mora,
                @w_pago_otr,     @w_pagot,         @w_estado)
      end
      
      fetch cursor_dividendo
      into  @w_di_dividendo,  @w_di_fecha_ven, @w_di_estado,
            @w_di_dias_cuota
   end
   

   close cursor_dividendo
   deallocate cursor_dividendo
   
   select 'No. CUOTA'         = de_dividendo,
          'FECHA VENCIMIENTO' = convert(varchar(10),de_fecha_ven,@i_formato_fecha),
          'DIAS'              = de_dias_cuota,
          'CAPITAL'           = convert(money, de_pago_cap),
          'INTERES'           = convert(money, de_pago_int),
          'MORA'              = convert(money, de_pago_mora),
          'OTROS'             = convert(money, de_pago_otr),
          'VALOR CUOTA'       = convert(money, de_pago),
          'ESTADO'            = de_estado
   from   ca_detalle_amor


end

if @i_operacion = 'R'
begin

   select @w_op_toperacion,      
          @w_op_moneda,          
          @w_monto_op,           
          @w_cod_cliente,        
          @w_cliente,            
          @w_op_llave_redescuento,
          @w_estado_op
end

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = @w_error
--        @i_cuenta = ' '

return @w_error


go

