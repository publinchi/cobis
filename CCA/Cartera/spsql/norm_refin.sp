/************************************************************************/
/*   Nombre Fisico:       norm_refin.sp                                 */
/*   Nombre Logico:       sp_norm_refinanciaciones                      */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez                                 */
/*   Fecha de escritura:  NOV.2014                                      */
/************************************************************************/
/*                               IMPORTANTE                             */
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
/*            MODIFICACIONES                                            */
/*    FECHA           AUTOR                     CAMBIO                  */
/*   NOV.2014     Elcira Pelaez   Req436:Normalizacion Cartera Herr. 3  */
/*                                Refinanciaciones                      */
/*   2015-02-18   Julian Mendigaña Req499:Tasa para cliente especial    */
/*   20/10/2021   G. Fernandez       Ingreso de nuevo campo de          */
/*                                       solidario en ca_abono_det      */
/*    24/Jun/2022     KDR              Nuevo parámetro sp_liquid        */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  @w_peor_calificacion				*/
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_norm_refinanciaciones')
   drop proc sp_norm_refinanciaciones
go
---Version Nov. 13 .15.50 pm
create proc sp_norm_refinanciaciones(
   @s_user           login        = null,
   @s_sesn           int          = null,
   @s_ssn            int          = null,
   @s_ofi            smallint     = null,
   @s_term           varchar(30)  = null,
   @s_date           datetime     = null,
   @i_tramite        int          = null,
   @i_banco          cuenta       = null,
   @i_producto       catalogo     = null,
   @i_referencia     cuenta       = '000000',
   @i_cod_banco      catalogo     = null,
   @i_cheque         cuenta       = null,
   @i_debug          char         = 'N'
)
as

declare  
   @w_sp_name                 varchar(32),                  
   @w_return                  int,
   @w_banco                   varchar(24),
   @w_operacionca             int,
   @w_moneda                  tinyint,
   @w_secuencial              int,
   @w_fecha_ult_proceso       datetime,
   @w_cuota_completa          char(1),
   @w_aceptar_anticipos       char(1),
   @w_tipo_reduccion          char(1),
   @w_tipo_cobro              char(1),
   @w_tipo_aplicacion         char(1),
   @w_cotizacion_mpg          money,
   @w_numero_recibo           int,
   @w_moneda_nacional         smallint,
   @w_cotizacion_hoy          money,
   @w_prepago_desde_lavigente char(1),
   @w_monto_canc              money,
   @w_fecha_cartera           datetime,
   @w_producto                catalogo,
   @w_num_dec                 smallint,
   @w_error                   int,
   @w_msg                     varchar(132),
   @w_total_mora              money,
   @w_operacion_nueva         int,
   @w_monto_desem             money,
   @w_nombre                  varchar(64),
   @w_tramite                 int,
   @w_linea                   int,
   @w_toperacion              catalogo,
   @w_gerente                 int,
   @w_calificacion            catalogo,
   @w_peor_calificacion       catalogo,
   @w_calif_int               tinyint,
   @w_peor_calif_int          tinyint,
   @w_num_reest               int,
   @w_max_num_reest           int,
   @w_banco_nuevo             varchar(24),
   @w_cliente                 int,
   @w_total_diferido          money,
   @w_concepto                catalogo,
   @w_est_diferido            tinyint,
   @w_est_suspenso            tinyint,
   @w_cotizacion_dia          float,
   @w_codvalor                int,
   @w_secuencial_des          int,
   @w_sec_des                 int,
   @w_monto_des               money,
   @w_parametro_cta_pte       catalogo,
   @w_monto_total_canceladas  money,
   @w_anticipados             money,
   @w_valor_cliente           money,
   @w_estado_op               smallint,

   @w_es_campana          char(1),
   @w_campana             int,
   @w_cod_campana         smallint,
   @w_valor_campana       varchar(20),
   @w_util_matriz         smallint,
   @w_op_clase            char(10),
   @w_spread              float,

   @w_signo               char(1),
   @w_valor_excepcion     char(10)--,
   --@w_sector              catalogo

   
select @w_sp_name     = 'sp_norm_refinanciaciones',
       @w_monto_desem = 0,
       @w_valor_cliente = 0

create table #oper_norm
(operacion int, secuencial int)

exec @w_error = sp_estados_cca
     @o_est_suspenso   = @w_est_suspenso  out,
     @o_est_diferido   = @w_est_diferido  out

--- Fecha de Proceso de Cartera 
select @w_fecha_cartera = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

if @@ROWCOUNT = 0
begin
  select @w_msg = 'ERROR, FECHA DE CIERRE DE CARTERA NO ENCONTRADA',
         @w_error = 708153
  goto ERRORFIN
end

---  MONEDA NACIONAL 
select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'

if @@ROWCOUNT = 0
begin
   select @w_msg = 'ERROR, PARAMETRO GENERAL MONEDA NACIONAL NO EXISTE',
          @w_error = 708153
   goto ERRORFIN
end

---COTIZACION DEL DIA
exec sp_buscar_cotizacion
     @i_moneda     = @w_moneda_nacional,
     @i_fecha      = @w_fecha_cartera,
     @o_cotizacion = @w_cotizacion_dia out
    
select @w_cotizacion_dia = isnull(@w_cotizacion_dia,1)    

select @w_num_dec = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'NDE'
and    pa_producto = 'CCA'

if @@ROWCOUNT = 0
begin
   select @w_msg = 'ERROR, PARAMETRO GENERAL NUMERO DE DECIMALES NO EXISTE',
          @w_error = 708153
   goto ERRORFIN
end

select @w_parametro_cta_pte = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'PTENOR'
and    pa_producto = 'CCA'

if @@ROWCOUNT = 0
begin
   select @w_msg = 'ERROR, PARAMETRO PARA CUENTA PUENTE NORMALIZACIONES NO EXISTE',
          @w_error = 708153
   goto ERRORFIN
end

select @w_producto = cp_producto
from   ca_producto
where  cp_producto = @w_parametro_cta_pte

if @@ROWCOUNT = 0
begin
   select @w_msg = 'ERROR, NO ES POSIBLE OBTENER LA FORMA DE PAGO',
          @w_error = 701025
   goto ERRORFIN
end

--- VALIDA QUE EL TRAMITE NO SE ENCUENTRE PERFECCIONADO EN CARTERA 
if exists(select 1
          from   cob_cartera..ca_normalizacion
          where  nm_tramite = @i_tramite
          and    nm_estado <> 'R')
begin
   select @w_msg = 'ERROR, TRAMITE YA PERFECCIONADO',
          @w_error = 708153
   goto ERRORFIN
end

--- OBTIENE LAS OPERACIONES A NORMALIZAR 
select banco=nm_operacion,
       saldo_canc=0
into  #operaciones_refinN
from  cob_credito..cr_normalizacion,
      cob_cartera..ca_operacion,
      cob_cartera..ca_estado
where nm_tramite     = @i_tramite
and   nm_tipo_norm   = 3
and   op_banco       = nm_operacion
and   es_procesa     = 'S'
and   es_codigo      = op_estado  
order by nm_operacion 

select @w_banco = '',
       @w_peor_calificacion = '',
       @w_peor_calif_int = 5,
       @w_max_num_reest = 0

--- HEREDA LOS DIFERIDOS DE LA OPERACIONES A NORMALIZAR 
if @i_debug = 'S' PRINT 'antes de sp_norm_herencia_diferidos'

exec @w_error   = sp_norm_herencia_diferidos
     @i_tramite = @i_tramite

if @w_error <> 0
begin
   select @w_msg = 'ERROR, AL HEREDAR LOS DIFERIDOS PARA EL TRAMITE'
   goto ERRORFIN
end

if  @i_debug  = 'S' PRINT 'antes de while'

select @w_monto_total_canceladas = 0

while 1=1
begin
   select top 1 @w_banco = banco
   from   #operaciones_refinN
   where  banco > @w_banco
   
   if @@rowcount = 0
      break
    
   --- LECTURA DE LA OPERACION 
   select @w_operacionca             = op_operacion,
          @w_moneda                  = op_moneda,
          @w_fecha_ult_proceso       = op_fecha_ult_proceso,
          @w_cuota_completa          = op_cuota_completa,
          @w_aceptar_anticipos       = op_aceptar_anticipos,
          @w_tipo_reduccion          = op_tipo_reduccion,
          @w_tipo_cobro              = op_tipo_cobro,
          @w_tipo_aplicacion         = op_tipo_aplicacion,
          @w_prepago_desde_lavigente = op_prepago_desde_lavigente,
          @w_tramite                 = op_tramite,
          @w_calificacion            = op_calificacion,
          @w_num_reest               = op_numero_reest,
          @w_op_clase                = op_clase
   from   ca_operacion, ca_estado
   where  op_banco             = @w_banco
   and    op_estado            = es_codigo
   and    es_acepta_pago       = 'S'

   if @@ROWCOUNT = 0
   begin
      select @w_msg = 'ERROR, NO ES POSIBLE OBTENER DATOS BASICOS DE LA OPERACION',
             @w_error = 701025
      goto ERRORFIN
   end
   
   if @w_calificacion > @w_peor_calificacion
      select @w_peor_calificacion = @w_calificacion
      
   if @w_num_reest > @w_max_num_reest
      select @w_max_num_reest = @w_num_reest
      
   --- OBTIENE CALIFICACION INTERNA DE LA OPERACION 
   select @w_calif_int = ci_nota
   from   cob_credito..cr_califica_int_mod
   where  ci_banco = @w_banco
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg = 'ERROR, NO ES POSIBLE OBTENER CALIFICACION INTERNA DE LA OPERACION',
             @w_error = 701025
      goto ERRORFIN
   end
   
   if @w_calif_int < @w_peor_calif_int
      select @w_peor_calif_int = @w_calif_int
   
   --- ACTUALIZA EL ESTADO DE COBRANZA A NORMALIZADO 
   update cob_cartera..ca_operacion 
   set    op_estado_cobranza = 'NO'
   where  op_operacion = @w_operacionca
   
   --- DETERMINAR EL VALOR DE COTIZACION DEL DIA / MONEDA OPERACION 
   if @w_moneda = @w_moneda_nacional
      select @w_cotizacion_hoy = 1.0
   else
   begin
      exec sp_buscar_cotizacion
           @i_moneda     = @w_moneda,
           @i_fecha      = @w_fecha_ult_proceso,
           @o_cotizacion = @w_cotizacion_hoy output
   end

   --- VALOR COTIZACION MONEDA DE PAGO 
   exec @w_error = sp_buscar_cotizacion
   @i_moneda     = @w_moneda,
   @i_fecha      = @w_fecha_ult_proceso,
   @o_cotizacion = @w_cotizacion_mpg output
   
   if @w_error <> 0
   begin
     select @w_msg = 'ERROR, AL BUSCAR COTIZACION',
            @w_error = 708153
     goto ERRORFIN
   end
   
   --- OBTIENE EL SALDO A CANCELACION DE CADA UNA DE LA OPERACION A PERFECCIONAR 
   exec @w_error     = sp_calcula_saldo
        @i_operacion = @w_operacionca,
        @i_tipo_pago = 'A',
        @o_saldo     = @w_monto_canc out
   
   if @w_error <> 0
   begin
     select @w_msg = 'ERROR, AL OBTENER EL SALDO DE CANCELACION DE LA OPERACION ' + cast(@w_operacionca as varchar),
            @w_error = 708153
     goto ERRORFIN
   end
    
   select @w_monto_total_canceladas = @w_monto_total_canceladas + @w_monto_canc

   --- GENERAR EL SECUENCIAL DE INGRESO     
   exec @w_secuencial = sp_gen_sec
        @i_operacion       = @w_operacionca
   
   if @w_secuencial  = 0
   begin
      select @w_msg = 'ERROR, NO ES POSIBLE OBTENER SECUENCIAL PARA EL PAGO',
             @w_error = 710106
      goto ERRORFIN
   end
   
   select @w_numero_recibo   = @w_secuencial

   if @i_debug = 'S'
      print 'registrar pago de la operacion ' + @w_banco

   --- INSERCION DE CA_ABONO 
   insert into ca_abono 
   (
   ab_operacion,          ab_fecha_ing,          ab_fecha_pag,            
   ab_cuota_completa,     ab_aceptar_anticipos,  ab_tipo_reduccion,            
   ab_tipo_cobro,         ab_dias_retencion_ini, ab_dias_retencion,     
   ab_estado,             ab_secuencial_ing,     ab_secuencial_rpa,
   ab_secuencial_pag,     ab_usuario,            ab_terminal,             
   ab_tipo,               ab_oficina,            ab_tipo_aplicacion,           
   ab_nro_recibo,         ab_tasa_prepago,       ab_dividendo,          
   ab_prepago_desde_lavigente                                      
   )                                                               
   values                                                          
   (                                                               
   @w_operacionca,        @w_fecha_cartera,      @w_fecha_cartera,            
   @w_cuota_completa,     @w_aceptar_anticipos,  @w_tipo_reduccion,            
   'A',                   0,                     0,                     
   'ING',                 @w_secuencial,         0,
   0,                     @s_user,               @s_term,                 
   'PAG',                 @s_ofi,                'C',           
   @w_numero_recibo,      0,                     0,          
   @w_prepago_desde_lavigente                    
   )                                             
   
   if @@error <> 0 begin
      print 'ERROR EN INGRESO DE ABONO EN TABLA CA_ABONO'
      select @w_error = 710294
   
      goto ERRORFIN
   end
   
   --- INSERCION DE CA_DET_ABONO                
   insert into ca_abono_det                      
   (                                             
   abd_secuencial_ing,    abd_operacion,         abd_tipo,                 
   abd_concepto,          abd_cuenta,            abd_beneficiario,             
   abd_monto_mpg,         abd_monto_mop,         abd_monto_mn,          
   abd_cotizacion_mpg,    abd_cotizacion_mop,    abd_moneda,
   abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,               
   abd_cod_banco,         abd_solidario                                  --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
   )                                             
   values                                        
   (                                             
   @w_secuencial,         @w_operacionca,        'PAG',                    
   @w_producto,           '',                    '',   
   @w_monto_canc,         @w_monto_canc,         @w_monto_canc,          
   @w_cotizacion_mpg,     @w_cotizacion_hoy,     @w_moneda,
   'N',                   'N',                   0,                
   '',                    'N'
   )
   
   if @@error <> 0 begin
      print 'ERROR EN INGRESO DETALLE DE ABONO EN TABLA CA_ABONO_DET'
      select @w_error = 710295
   
      goto ERRORFIN
   end
   
   --- INSERTAR PRIORIDADES 
   insert into ca_abono_prioridad (
   ap_secuencial_ing, ap_operacion,   ap_concepto, ap_prioridad)
   select   
   @w_secuencial,     @w_operacionca, ro_concepto, ro_prioridad 
   from ca_rubro_op 
   where ro_operacion =  @w_operacionca
   and   ro_fpago not in ('L','B')
   
   if @@error <> 0 begin
      print 'ERROR EN INGRESO DE PRIORIDAD DE ABONO EN TABLA CA_ABONO_PRIORIDAD'
      select @w_error = 710001
   
      goto ERRORFIN
   end
   
   if @@error <> 0  
      return 710001
   
   if @w_fecha_cartera = @w_fecha_ult_proceso
    begin
   
      ---CREACION DEL REGISTRO DE PAGO
      exec @w_return    = sp_registro_abono
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_ofi            = @s_ofi,
      @s_sesn           = @s_sesn,
      @s_ssn            = @s_ssn,
      @i_secuencial_ing = @w_secuencial,
      @i_en_linea       = 'S',
      @i_fecha_proceso  = @w_fecha_cartera,
      @i_operacionca    = @w_operacionca,
      @i_cotizacion     = @w_cotizacion_hoy
      
      if @w_return <> 0
      begin
         select @w_msg = 'ERROR, NO ES POSIBLE REGISTRAR EL PAGO',
                @w_error = @w_return
         goto ERRORFIN
      end
      
      ---APLICACION EN LINEA DEL PAGO SIN RETENCION
      
      exec @w_return = sp_cartera_abono
           @s_user           = @s_user,
           @s_term           = @s_term,
           @s_date           = @s_date,
           @s_sesn           = @s_sesn,
           @s_ofi            = @s_ofi,
           @i_secuencial_ing = @w_secuencial,
           @i_fecha_proceso  = @w_fecha_cartera,
           @i_en_linea       = 'N',
           @i_operacionca    = @w_operacionca,
           @i_cotizacion     = @w_cotizacion_hoy,
           @i_por_rubros     = 'S',
           @i_pago_ext       = 'S',
           @i_es_norm        = 'S'
      
      if @w_return <> 0
      begin
         select @w_msg = 'ERROR, NO ES POSIBLE APLICAR EL PAGO',
                @w_error = @w_return
         goto ERRORFIN
      end


      update ca_abono_det
      set abd_monto_mpg    = abd_monto_mop
      where abd_operacion  = @w_operacionca
      and   abd_secuencial_ing = @w_secuencial
      and   abd_tipo           = 'PAG'
      
      if @@error <> 0
      begin
         select 
         @w_msg = 'ERROR AL ACTUALIZAR DETALLE DE ABONO EN TABLA CA_ABONO_DET',
         @w_error   = 710002          
   
         goto ERRORFIN
      end
      
      update ca_det_trn
      set dtr_monto = dtr_monto_mn
      from ca_abono
      where ab_operacion = @w_operacionca
      and   ab_operacion = dtr_operacion
      and   ab_secuencial_ing = @w_secuencial
      and   ab_secuencial_rpa = dtr_secuencial
      and   dtr_dividendo     = -1
      
      if @@error <> 0
      begin
         select 
         @w_msg = 'ERROR AL ACTUALIZAR DETALLE DE TRANSACCION EN TABLA CA_DET_TRN',
         @w_error   = 710002          
   
         goto ERRORFIN
      end
      
      /* ACTUALIZA EL VALOR DE LA NORMALIZACION YA QUE PUEDEN HABER ORDENES DE PAGO CANCELADAS POR EL CLIENTE */
      update cob_credito..cr_op_renovar
      set or_saldo_original  = @w_monto_canc
      where or_tramite       = @i_tramite
      and   or_num_operacion = @w_banco
      
      if @@error <> 0
      begin
         select 
         @w_msg = 'ERROR AL ACTUALIZAR SALDO ORIGINAL EN TABLA CR_OP_RENOVAR',
         @w_error   = 710002          
   
         goto ERRORFIN
      end
      
      --- ALMACENA EL NUMERO DE LA OPERACION Y EL SECUENCIAL CON EL CUAL SE REALIZO EL PAGO 
      insert into #oper_norm
      values(@w_operacionca, @w_secuencial)
      
      --- OBTIENE EL CUPO ASOCIADO A LA OPERACION NORMALIZADA 
      select @w_linea = tr_linea_credito
      from cob_credito..cr_tramite 
      where tr_tramite = @w_tramite
    
      /* --AGI  COMENTADO TERMPORAL HASTA CORDINAR CON CREDITO EL CAMPO LI_FECHA_MOD    
      if @w_linea is not null
      begin
		  --- ANULA LOS CUPOS ASOCIADOS A LA OPERACION NORMALIZADA 
		  update cob_credito..cr_linea
		  set li_estado = 'A',
			  li_fecha_mod = @w_fecha_cartera
		  where li_numero = @w_linea
	      
		  if @@ROWCOUNT = 0
		  begin
			 select 
			 @w_msg = 'ERROR NO SE ENCONTRO EL CUPO ASOCIADO A LA OPERACION',
			 @w_error   = 710002          
	   
			 goto ERRORFIN
		  end
       end  */ --FIN AGI
       
   end 
   ELSE
   begin
      PRINT 'ATENCION OPERACION NO SE CANCELARA POR QUE TIENE FECHA DE PROCESO DIFERENTE'
      return 724510
   end
end

if  @i_debug  = 'S' PRINT 'antes de  sp_valida_perfeccionamiento'
exec @w_error = sp_valida_perfeccionamiento
     @s_user           = @s_user,
     @s_ofi            = @s_ofi,
     @s_term           = @s_term,
     @s_date           = @s_date,
     @i_tramite        = @i_tramite,
     @i_momento_perf   = 'CANCELADAS',
     @i_debug          = @i_debug

if @w_error <> 0
   goto ERRORFIN

---CALCULA LA TASA PONDERADA PAR ALA NUEVA OPERACION   
if  @i_debug  = 'S'
    PRINT 'antes de  sp_tasa_normalizacion'

exec @w_error = sp_tasa_normalizacion
     @s_user           = @s_user,
     @s_ofi            = @s_ofi,
     @s_term           = @s_term,
     @s_date           = @s_date,
     @i_tramite        = @i_tramite,
     @i_tipo_norm      = 3,               --req 499, tipo 3 refinanciacion
     @i_debug          = @i_debug

if @w_error <> 0
   goto ERRORFIN

--- OBTIENE DATOS DE LA NUEVA OPERACION NUEVA 
select @w_operacion_nueva  = op_operacion,
       @w_banco_nuevo      = op_banco,
       @w_toperacion       = op_toperacion,
       @w_moneda           = op_moneda,
       @w_nombre           = op_nombre,
       @w_gerente          = op_oficial,
       @w_cliente          = op_cliente
from cob_cartera..ca_operacion
where op_tramite = @i_tramite

if @@ROWCOUNT = 0
begin
   select @w_msg = 'ERROR, NO ES SE ENCUENTRA OPERACION PARA DESEMBOLSAR',
          @w_error = @w_return
   goto ERRORFIN
end

if  @i_debug  = 'S'
    PRINT 'antes de  sp_desembolso Q'

exec @w_return = sp_desembolso
     @s_ofi            = @s_ofi,
     @s_term           = @s_term,
     @s_user           = @s_user,
     @s_date           = @s_date,
     @i_formato_fecha  = 103,
     @i_renovaciones   = 'S',
     @i_operacion      = 'Q',
     @i_desde_cre      = 'N',
     @i_banco_ficticio = @w_banco_nuevo,
     @i_banco_real     = @w_banco_nuevo,
     @i_pasar_tmp      = 'S',
     @i_externo        = 'N',
     @i_crea_ext       = 'N',
     @i_origen         = 'B'

if @w_return <> 0
begin
   select @w_msg = 'ERROR, AL DESEMBOLSAR OPERACION OPERACION Q',
         @w_error = @w_return
   goto ERRORFIN
end

select @w_valor_cliente    = opt_monto
from   ca_operacion_tmp
where  opt_operacion = @w_operacion_nueva

select @w_anticipados = round(isnull(sum(rot_valor),0),0)
from   ca_rubro_op_tmp
where  rot_operacion = @w_operacion_nueva
and    rot_fpago     = 'L'

if @i_debug = 'S'
begin
   print 'DESCUENTOS :' + convert(varchar, @w_anticipados)
   if not exists(select 1 from ca_operacion_tmp
                 where  opt_operacion = @w_operacion_nueva)
   begin
      print 'ERROR AL PASAR A TERMPORALES QUE DEBIO HACER EL sp_desembolso : ' + convert(varchar, @w_operacion_nueva)
   end
end

select @w_valor_cliente = @w_valor_cliente - @w_anticipados - @w_monto_total_canceladas


-- DESEMBOLSO NUEVO CREDITO  PARTE FIJA CUENTA PUENTE
if  @i_debug  = 'S' PRINT 'antes de  sp_desembolso  AUTOMATICO : ' + cast ( @w_monto_total_canceladas as varchar)

if @w_monto_total_canceladas <= 0
begin
      PRINT 'ATENCION ERROR EN VALOR DE CANCELACION DE OPERACIONES REFINANCIADAS'
      return 701121
end

exec @w_return = sp_desembolso
@s_ofi            = @s_ofi,
@s_term           = @s_term,
@s_user           = @s_user,
@s_date           = @s_date,
@i_producto       = @w_producto,
@i_cuenta         = 'AUTOMATICO', 
@i_beneficiario   = @w_nombre,
@i_oficina_chg    = @s_ofi,
@i_banco_ficticio = @w_banco_nuevo,
@i_banco_real     = @w_banco_nuevo,
@i_monto_ds       = @w_monto_total_canceladas,
@i_tcotiz_ds      = 'N',
@i_cotiz_ds       = 1.0,
@i_tcotiz_op      = 'N',
@i_cotiz_op       = @w_cotizacion_hoy,
@i_moneda_op      = @w_moneda,
@i_moneda_ds      = @w_moneda,
@i_operacion      = 'I',
@i_externo        = 'N',
@i_crea_ext       = 'N',
@i_origen         = 'B'

if @w_return <> 0
begin
 select @w_msg = 'ERROR, AL DESEMBOLSAR OPERACION OPERACION I',
        @w_error = @w_return
 goto ERRORFIN
end

--- REGISTRO DE LA PARTE QUE LE CORRESPONDE AL CLIENTE
if  @i_debug  = 'S' PRINT 'antes de  sp_desembolso  PARA EL CLIENTE : ' + cast ( @w_valor_cliente as varchar)

if @w_valor_cliente <= 0
begin
      PRINT 'VALOR SOLICITADO NO ES SUFICIENTE PARA CUBRIR LOS COSTOS Y CANCELACIONES'
      return 701121
end


exec @w_return = sp_desembolso
@s_ofi            = @s_ofi,
@s_term           = @s_term,
@s_user           = @s_user,
@s_date           = @s_date,
@i_producto       = @i_producto,
@i_cuenta         = @i_referencia, 
@i_beneficiario   = @w_nombre,
@i_oficina_chg    = @s_ofi,
@i_banco_ficticio = @w_banco_nuevo,
@i_banco_real     = @w_banco_nuevo,
@i_monto_ds       = @w_valor_cliente,
@i_tcotiz_ds      = 'N',
@i_cotiz_ds       = 1.0,
@i_tcotiz_op      = 'N',
@i_cotiz_op       = @w_cotizacion_hoy,
@i_moneda_op      = @w_moneda,
@i_moneda_ds      = @w_moneda,
@i_operacion      = 'I',
@i_externo        = 'N',
@i_crea_ext       = 'N',
@i_origen         = 'B'

if @w_return <> 0
begin
 select @w_msg = 'ERROR, AL DESEMBOLSAR OPERACION OPERACION I',
        @w_error = @w_return
 goto ERRORFIN
end


select @w_sec_des    = min(dm_secuencial)
from   ca_desembolso
where  dm_operacion  = @w_operacion_nueva
and    dm_estado     = 'NA'

select @w_monto_des      = isnull(sum(dm_monto_mop),0)
from   ca_desembolso
where  dm_operacion    = @w_operacion_nueva
and    dm_secuencial   = @w_sec_des

if @i_debug = 'S'
   print 'monto a desembolsar: ' +convert(varchar, isnull(@w_monto_des, 0))

/*
update ca_operacion
set   op_monto = @w_monto_des,
      op_monto_aprobado = @w_monto_des
where op_tramite = @i_tramite

update ca_operacion_tmp
set opt_monto = @w_monto_des,
   opt_monto_aprobado = @w_monto_des
where opt_tramite = @i_tramite
     
update ca_rubro_op
set ro_valor = @w_monto_des
where ro_operacion = @w_operacion_nueva
and   ro_concepto = 'CAP'

update ca_rubro_op_tmp 
set rot_valor = @w_monto_des
where rot_operacion = @w_operacion_nueva
and   rot_concepto = 'CAP'
*/
if  @i_debug  = 'S' PRINT 'antes de  sp_liquida'
   
exec @w_return = sp_liquida
     @s_ssn            = @s_ssn,
     @s_sesn           = @s_sesn,
     @s_user           = @s_user,
     @s_date           = @s_date,
     @s_ofi            = @s_ofi,
     @s_rol            = 1,
     @s_term           = @s_term,
     @i_banco_ficticio = @w_banco_nuevo,
     @i_banco_real     = @w_banco_nuevo,
     @i_afecta_credito = 'N',
     @i_fecha_liq      = @w_fecha_cartera,
     @i_tramite_batc   = 'N',
	 @i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
     @i_externo        = 'N'

if @w_return <> 0
begin
   select @w_msg = 'ERROR, AL LIQUIDAR OPERACION',
          @w_error = @w_return
   goto ERRORFIN
end

--- OBTIENE NUEVO NUMERO DE BANCO 
select @w_banco_nuevo = op_banco,
       @w_estado_op   = op_estado
from cob_cartera..ca_operacion
where op_tramite = @i_tramite

if @w_estado_op <> 1
begin
 select @w_msg = 'ERROR, OPERACION NUEVA NO TIENE EL ESTADO VIGENTE',
        @w_error = 705036
 goto ERRORFIN
end

--- HEREDA LA PEOR CALIFICACION Y LA MARCA DE REESTRUCTURADOS 
if @w_peor_calificacion = ''
   select @w_peor_calificacion = 'A'
   
update cob_cartera..ca_operacion
set    op_calificacion = @w_peor_calificacion,
       op_numero_reest = @w_max_num_reest + 1,
       op_reestructuracion = 'S'
where op_tramite = @i_tramite    

delete cob_credito..cr_califica_int_mod
where ci_banco = @w_banco_nuevo

--- CREA CALIFICACION INTERNA DE LA NUEVA OPERACION CON LA PEOR CALIFICACION DE LAS OPERACIONES RENOVADAS 
insert into cob_credito..cr_califica_int_mod
      (ci_producto,   ci_toperacion,    ci_moneda,     
       ci_cliente,    ci_banco,         ci_fecha,      
       ci_nota)
values(7,             @w_toperacion,    @w_moneda,
       @w_cliente,    @w_banco_nuevo,   @w_fecha_cartera,
       @w_peor_calif_int)

---select * from #oper_norm
---REGISTRO VALOR DIFERIDO
select @w_total_diferido = 0

--- OBTIENE SECUENCIAL DEL DESEMBOLSO PARA LA OPERACION NUEVA 
select @w_secuencial_des = tr_secuencial
from   cob_cartera..ca_transaccion 
where  tr_operacion  = @w_operacion_nueva
and    tr_tran       = 'DES'
and    tr_estado     <> 'RV'
and    tr_secuencial > 0

---PONER EL NRO. DE OBLIGACIN AL TRAMITE
update cob_credito..cr_tramite
set tr_numero_op       = @w_operacion_nueva,
    tr_numero_op_banco = @w_banco_nuevo
where tr_tramite = @i_tramite

--- GENERA DIFERIDOS PARA LA NORMALIZACION
if  @i_debug  = 'S' PRINT 'antes de  sp_norm_genera_diferidos'
exec @w_error   = sp_norm_genera_diferidos
     @s_date    = @s_date,
     @i_tramite = @i_tramite,
     @i_cotizacion_dia = @w_cotizacion_dia,
     @i_secuencial_des = @w_secuencial_des
if @w_error <> 0
begin
 select @w_msg = 'ERROR, AL GENRAR LOS DIFERIDOS PARA EL TRAMITE'
 goto ERRORFIN
end



--- INSERTA TABLA DE CONTROL DE NORMALIZACION DE CARTERA 
insert into ca_normalizacion (nm_tramite, nm_cliente, nm_tipo_norm, nm_estado, nm_fecha_apl)
values (isnull(@i_tramite,0), @w_cliente, 3, 'A', @s_date)

if @@error <> 0
begin
   --- ERROR AL INSERTAR EN TABLA DE CONTROL DE NORMALIZACION DE CARTERA 
   select 
   @w_msg   = 'ERROR AL INSERTAR EN TABLA DE CONTROL DE NORMALIZACION DE CARTERA',
   @w_error = 710001

   goto ERRORFIN
end  


--Modificacion spread

select @w_campana = cc_campana
from cob_credito..cr_cliente_campana, cob_credito..cr_campana
where cc_campana      = ca_codigo
and   cc_cliente      = @w_cliente
and   ca_tipo_campana = 3    -- tipo campaña normalizacion 3
and   cc_estado       = 'V'
and   ca_estado       = 'V'
   
   
if isnull(@w_campana,0) <> 0 
begin
   select @w_valor_excepcion =  pe_char
   from   cob_credito..cr_param_especiales_norm
   where  pe_campana  = @w_campana
   and    pe_tipo_campana = 3
   and    pe_tipo_normalizacion   = 3 -- @i_tipo_norm
   and    pe_regla  = 'TASA'
   and    pe_estado = 'V'

   if isnull(@w_valor_excepcion,'0')  = 'S'
   begin
      exec @w_error     = cob_cartera..sp_matriz_valor
      @i_matriz    = 'VAL_MATRIZ',
      @i_fecha_vig = @s_date,
      @i_eje1      = @w_toperacion,
      @i_eje2      = 'VAL_NORM',
      @o_valor     = @w_util_matriz out,
      @o_msg       = @w_msg out

      if @w_util_matriz = 0 return 0 --> LA MATRIZ NO ES UTILIZADA POR LA LINEA

      exec @w_error  = sp_matriz_valor
	        @i_matriz      = 'VAL_NORM',      
	        @i_fecha_vig   = @s_date,  
	        @i_eje1        = 3, --@i_tipo_norm,  
            @i_eje2        = @w_campana,  
            @i_eje3        = @w_op_clase,
	        @o_valor       = @w_spread out, 
	        @o_msg         = @w_msg    out

      if @w_error <> 0
         return @w_error

         
         
   end
 end  

--aca


if isnull(@w_campana,0) = 0 
begin
-- ACTUALIZA SPREAD A CERO
   update ca_rubro_op with (rowlock)
   set  ro_factor           = 0
   where  ro_operacion = @w_operacion_nueva
   and    ro_tipo_rubro = 'I'

   update ca_rubro_op_tmp with (rowlock)
   set   rot_factor           = 0
   where  rot_operacion = @w_operacion_nueva
   and    rot_tipo_rubro = 'I'
end
else
begin
   
   exec @w_error     = cob_cartera..sp_matriz_valor
        @i_matriz    = 'VAL_MATRIZ',
        @i_fecha_vig = @s_date,
        @i_eje1      = @w_toperacion,
        @i_eje2      = 'VAL_NORM',
        @o_valor     = @w_util_matriz out,
        @o_msg       = @w_msg out
   
    if @w_util_matriz = 0 return 0 --> LA MATRIZ NO ES UTILIZADA POR LA LINEA
   
    exec @w_error  = cob_cartera..sp_matriz_valor
         @i_matriz      = 'VAL_NORM',      
         @i_fecha_vig   = @s_date,  
         @i_eje1        = 3,--@i_tipo_norm,  
         @i_eje2        = @w_campana,  
         @i_eje3        = @w_op_clase,
         @o_valor       = @w_spread out, 
         @o_msg         = @w_msg    out

     if @w_error <> 0
         return @w_error
         
         
     
     if @w_spread < 0 
        select @w_signo = '-'
     else   
        select @w_signo = '+'
   
     update ca_rubro_op with (rowlock)
     set  ro_factor           = abs(@w_spread),
          ro_signo = @w_signo
     where  ro_operacion = @w_operacion_nueva
     and    ro_tipo_rubro = 'I'

     update ca_rubro_op_tmp with (rowlock)
     set   rot_factor           = abs(@w_spread),
           rot_signo = @w_signo
     where  rot_operacion = @w_operacion_nueva
     and    rot_tipo_rubro = 'I'   

     update cob_cartera..ca_tasas     
     set     ts_signo = @w_signo,
             ts_factor = abs(@w_spread)
     from  ca_tasas 
     where ts_operacion  = @w_operacion_nueva
     and   ts_dividendo > 0 

   
end 


return 0
       
ERRORFIN:
   if @i_debug = 'S'
      print @w_msg

return @w_error

go

