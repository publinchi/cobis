/************************************************************************/
/*   NOMBRE LOGICO:      ingaboin.sp                                    */
/*   NOMBRE FISICO:      sp_ing_abono_int                               */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       R. Garces                                      */
/*   FECHA DE ESCRITURA: Feb. 1995                                      */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la Rep�blica de Espa�a y las             */
/*   correspondientes de la Uni�n Europea. Su copia, reproducci�n,      */
/*   alteraci�n en cualquier sentido, ingenier�a reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causar� violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la informaci�n      */
/*   tratada; y por lo tanto, derivar� en acciones legales civiles      */
/*   y penales en contra del infractor seg�n corresponda.               */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Ingreso de abonos                                                  */ 
/*   S: Seleccion de negociacion de abonos automaticos                  */
/*   Q: Consulta de negociacion de abonos automaticos                   */
/*   I: Insercion de abonos                                             */
/*   U: Actualizacion de negociacion de abonos automaticos              */
/*   D: Eliminacion de negociacion de abonos automaticos                */
/************************************************************************/
/*                             MODIFICACIONES                           */
/*      FECHA           AUTOR                  ACTUALIZACION            */
/* 06/Oct/2021   J.Hernandez      Se agrega llamado con afectación a    */
/*                                a BANCOS                              */
/* 20/10/2021    G. Fernandez     Ingreso de nuevo campo de solidario   */
/*                                en ca_abono_det                       */
/* 20/10/2021    G. Fernandez     Actualizacion de parametros en        */
/*                                sp_tran_general                       */
/* 10/01/2021    K. Rodríguez     Recálculo TIR, TEA por Pago Extraord. */
/* 01/06/2022    K. Rodriguez     Ajustes condonaciones                 */
/* 18/07/2022    G. Fernandez     Cambio parametro id_referencia_inter  */
/*                                de int a varchar                      */
/* 28/07/2022    J. Guzman        Se agrega filtro en actualización de  */
/*                                secuencial que viene de bancos        */
/* 30/07/2022    K. Rodriguez     Condonación con pago Acumulado        */
/* 09/08/2022    K. Rodriguez     Valida que al hacer pago no haya con- */
/*                                donaciones pendientes de aplicar      */
/* 10/08/2022    G. Fernandez     R191162 Ingreso de campo para         */
/*                                descipción                            */
/* 05/09/2022    K. Rodriguez     R193119 Val. moneda pago y cuenta ban.*/
/* 03/10/2022    K. Rodriguez     R194612 Ajsutes interfaz con Bancos   */
/* 01/02/2023    K. Rodriguez     S771317 Bandera para pago grupal      */
/* 28/07/2023    G. Fernandez     S857741 Parametros de licitud         */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_ing_abono_int')
   drop proc sp_ing_abono_int
go


create proc sp_ing_abono_int
   @s_user                     login        = null,
   @s_term                     varchar(30)  = null,
   @s_date                     datetime     = null,
   @s_ssn                      int          = null,
   @s_srv                      varchar(30)  = null, 
   @s_sesn                     int          = null,
   @s_ofi                      smallint     = null,
   @s_rol                      smallint     = null, --Req00212 Pequeña Empresa	
   @s_ssn_branch               int          = null,
   @i_accion                   char(1),     
   @i_banco                    cuenta,      
   @i_secuencial               int          = NULL,
   @i_tipo                     char(3)      = NULL,
   @i_fecha_vig                datetime     = NULL,
   @i_ejecutar                 char(1)      = 'N',
   @i_retencion                smallint     = NULL,
   @i_cuota_completa           char(1)      = NULL,   
   @i_anticipado               char(1)      = NULL,   
   @i_tipo_reduccion           char(1)      = NULL, 
   @i_proyectado               char(1)      = NULL,
   @i_tipo_aplicacion          char(1)      = NULL,
   @i_prioridades              varchar(255) = NULL,
   @i_en_linea                 char(1)      = 'S',
   @i_tasa_prepago             float        =  0,
   @i_verifica_tasas           char(1)      = null, 
   @i_dividendo                smallint,
   @i_bv                       char(1)      = null,
   @i_calcula_devolucion       char(1)      = NULL,
   @i_no_cheque                int          = NULL,  
   @i_cuenta                   cuenta       = NULL,  
   @i_mon                      smallint     = NULL,  
   @i_cheque                   int          = null,
   @i_cod_banco                catalogo     = null,
   @i_beneficiario             varchar(50)  = NULL,
   @i_cancela                  char(1)      = NULL,
   @i_renovacion               char(1)      = NULL,
   @i_solo_capital             char(1)      = 'N',
   @i_valor_multa              money        = 0,
   @i_pago_interfaz            char(1)      = 'N',
   @i_id_referencia_inter      varchar(30)  = null,  --GFP 18/07/2022
   @i_canal_inter              int          = 0,
   @i_forma_pago               varchar(10)  = null,
   @i_reg_pago_grupal_padre    char(1)      = 'N',   --KDR Bandera de Inserción en estructuras de abono del pago préstamo Padre (no aplicación de abono)
   @i_reg_pago_grupal_hijo     char(1)      = 'N',   --KDR Bandera de abono de operación Hija desde un pago grupal
   @i_debug                    char(1)      = 'N',
   @i_aplica_licitud           char         = 'N', --GFP Aplica licitud de fondos,
   @o_secuencial_ing           int          = NULL out,
   @o_secuencial_rpa           int          = null out,
   -- Parámetros salida factura electrónica
   @o_guid                     varchar(36)  = null out,
   @o_fecha_registro           varchar(10)  = null out,
   @o_ssn                      int          = null out,
   @o_orquestador_fact         char(1)      = null out
   
as

declare 
@w_sp_name                    descripcion,
@w_return                     int,
@w_fecha_hoy                  datetime,
@w_est_vigente                tinyint,
@w_est_no_vigente             tinyint,
@w_est_vencido                tinyint,
@w_est_cancelado              tinyint,
@w_operacionca                int,
@w_causacion                  char(1),
@w_moneda                     tinyint,
@w_secuencial                 int,
@w_estado                     tinyint,
@w_fecha_ult_proceso          datetime,
@w_fecha                      datetime,
@w_secuencial_ing             int,
@w_i                          int,
@w_j                          int,
@w_k                          int,
@w_concepto_aux               catalogo,
@w_valor                      varchar(20),
@w_error                      int,
@w_numero_recibo              int,
@w_tasa_prestamo              float,
@w_periodicidad               catalogo,
@w_dias_anio                  smallint,
@w_base_calculo               char(1),
@w_fpago                      char(1),
@w_fecha_ult_proc             datetime,
@w_tipo                       varchar(1),
@w_descripcion                varchar(60),
@w_acepta_pago                char(1),
@w_moneda_nacional            tinyint,
@w_cotizacion_hoy             money,
@w_prepago_desde_lavigente    char(1),
@w_ab_dias_retencion          smallint,
@w_parametro_control          catalogo,
@w_dias_retencion             smallint,
@w_forma_pago                 catalogo,
@w_operacion_alterna          int,
@w_num_dec_op                 smallint,
@w_rowcount                   int,
@w_secuencial_pag             int,    -- ITO 10/02/2010
@w_extraordinario             char(1),
@w_monto_inter                money, -- JH Variable del monto pagado
@w_param_ibtran               int,
@w_categoria                  varchar(20),
@w_corr                       char(1),
@w_concepto                   catalogo, 
@w_sec_banco                  INT,
@w_cod_banco                  catalogo,
@w_cuenta                     cuenta,
@w_beneficiario               varchar(50),
@w_cat1                       float,
@w_tir                        float,
@w_tea                        float,
@w_causal                     varchar(14),   -- KDR Causal para Bancos según Forma de Pago.
@w_monto_pag_con_mn           money,
@w_monto_pag_con_mpg          money,
@w_monto_pag_con_mop          money,
@w_monto_con_rub_mn           money,
@w_monto_con_rub_mpg          money,
@w_monto_con_rub_mop          money,
@w_moneda_pago                tinyint,
@w_tipo_cobro                 char(1),
@w_tipo_reduccion             char(1),
@w_saldo_anterior             money

select   @w_sp_name = 'sp_ing_abono_int',
         @w_corr    = 'N'

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

select @w_est_no_vigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

select @w_est_vigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CANCELADO'

select @i_prioridades = isnull(@i_prioridades, '')

select @i_fecha_vig = convert(datetime,convert(varchar, @i_fecha_vig, 101))

select @w_param_ibtran = pa_int  from cobis..cl_parametro
WHERE pa_nemonico = 'IBTRAN'
AND pa_producto = 'CCA'

if @@rowcount = 0  return 725108

-- INGRESO DEL PAGO 
if @i_accion = 'I' begin

   select 
   @w_operacionca             = op_operacion,
   @w_moneda                  = op_moneda,
   @w_estado                  = op_estado,
   @w_fecha_ult_proceso       = op_fecha_ult_proceso,
   @w_periodicidad            = op_tdividendo,
   @w_dias_anio               = op_dias_anio,
   @w_base_calculo            = op_base_calculo,
   @w_tipo                    = op_tipo,   
   @w_prepago_desde_lavigente = op_prepago_desde_lavigente,
   @w_tipo_cobro              = op_tipo_cobro,
   @w_tipo_reduccion          = op_tipo_reduccion
   from   ca_operacion
   where  op_banco  = @i_banco

   if @@rowcount = 0  return 701025

   
   select @w_acepta_pago = es_acepta_pago
   from ca_estado
   where es_codigo = @w_estado
   
   if @w_acepta_pago = 'N' and @i_reg_pago_grupal_padre <> 'S'
      return 701117

   select @w_fecha_hoy = @w_fecha_ult_proceso
   
   -- DETERMINAR EL VALOR DE COTIZACION DEL DIA 
   if @w_moneda = @w_moneda_nacional
      select @w_cotizacion_hoy = 1.0
   else
   begin
      exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda,
      @i_fecha      = @w_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion_hoy output
   end

   -- CALCULAR TASA DE INTERES PRESTAMO
   select 
   @w_tasa_prestamo = isnull(sum(ro_porcentaje),0),
   @w_fpago         = ro_fpago
   from ca_rubro_op
   where ro_operacion  = @w_operacionca
   and   ro_tipo_rubro = 'I'
   and   ro_fpago     in ('A','P','T')
   group by ro_fpago

   if @w_fpago = 'P' select @w_fpago = 'V'
  
   select @i_tasa_prepago = @w_tasa_prestamo 

   -- SI ES UN PAGO DESDE EL FRONT-END, GENERAR EL SECUENCIAL DE INGRESO 
   if @i_secuencial is null
   begin
   
      exec @w_secuencial_ing = sp_gen_sec
      @i_operacion      = @w_operacionca
      
      -- ITO 10/02/2010
      exec @w_secuencial_pag = sp_gen_sec
      @i_operacion      = @w_operacionca
      -- FIN ITO 10/02/2010
   
   end
   else
      select @w_secuencial_ing = @i_secuencial 

   select @o_secuencial_ing = @w_secuencial_ing
 
   -- GENERACION DEL NUMERO DE RECIBO 

   exec @w_return = sp_numero_recibo
   @i_tipo    = 'P',
   @i_oficina = @s_ofi, 
   @o_numero  = @w_numero_recibo out

   if @w_return != 0  return @w_return

   -- INSERCION DE CA_ABONO 
   insert into ca_abono (
   ab_operacion,          ab_fecha_ing,                ab_fecha_pag,
   ab_cuota_completa,     ab_aceptar_anticipos,        ab_tipo_reduccion,
   ab_tipo_cobro,         ab_dias_retencion_ini,       ab_dias_retencion,
   ab_estado,             ab_secuencial_ing,           ab_secuencial_rpa,
   ab_secuencial_pag,     ab_usuario,                  ab_terminal,
   ab_tipo,               ab_oficina,                  ab_tipo_aplicacion,
   ab_nro_recibo,         ab_tasa_prepago,             ab_dividendo,
   ab_calcula_devolucion, ab_prepago_desde_lavigente,  ab_extraordinario,
   ab_ssn)
   values (
   @w_operacionca,        @w_fecha_hoy,                @i_fecha_vig,
   @i_cuota_completa,     @i_anticipado,               @i_tipo_reduccion,
   @i_proyectado,         @i_retencion,                @i_retencion,
   'ING',                 @w_secuencial_ing,           0,
   @w_secuencial_pag,     @s_user,                     @s_term,                -- @w_secuencial_pag por 0
   @i_tipo,               @s_ofi,                      @i_tipo_aplicacion,
   @w_numero_recibo,      @i_tasa_prepago,             @i_dividendo,
   @i_calcula_devolucion, @w_prepago_desde_lavigente,  @i_solo_capital,
   @s_ssn)
   



   -- INSERCION DE CA_DET_ABONO LEYENDO DE CA_DET_ABONO_TMP 
   insert into ca_abono_det(
   abd_secuencial_ing,    abd_operacion,               abd_tipo,  
   abd_concepto,          abd_cuenta,                  abd_beneficiario,            
   abd_monto_mpg,         abd_monto_mop,               abd_monto_mn,                
   abd_cotizacion_mpg,    abd_cotizacion_mop,          abd_moneda,                  
   abd_tcotizacion_mpg,   abd_tcotizacion_mop,         abd_cheque,                  
   abd_cod_banco,         abd_inscripcion,             abd_carga,                   
   abd_porcentaje_con,    abd_secuencial_interfaces,   abd_solidario,    --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
   abd_descripcion)
   select
   @w_secuencial_ing,     @w_operacionca,              abdt_tipo,
   abdt_concepto,         abdt_cuenta,                 isnull(abdt_beneficiario,''), 
   abdt_monto_mpg,        abdt_monto_mop,              abdt_monto_mn,               
   abdt_cotizacion_mpg,   abdt_cotizacion_mop,         abdt_moneda,                 
   abdt_tcotizacion_mpg,  abdt_tcotizacion_mop,        abdt_cheque,                 
   abdt_cod_banco,        abdt_inscripcion,            abdt_carga,                  
   abdt_porcentaje_con,   abdt_secuencial_interfaces,  abdt_solidario,      --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
   abdt_descripcion
   from  ca_abono_det_tmp
   where abdt_user = @s_user
   and   abdt_sesn = @s_sesn
   
   
	-- VALIDACIONES CUANDO SE VA A REGISTRAR/APLICAR UN PAGO TIPO CONDONACIÓN
	if exists (select 1 from ca_abono_det
               where abd_operacion      = @w_operacionca
			   and   abd_secuencial_ing = @w_secuencial_ing
			   and   abd_tipo           = 'CON')
	begin
	   
	   if @i_proyectado <> 'A'
	      return 725168 -- La condonación debe tener como negociación tipo de interés Acumulado.
	
	end
	
    -- Valida que no se aplique el pago si existen condonaciones pendientes, ya que el pago podría aplicarse
    -- a los saldos que se establecieron en la condonación no aplicada.	   
	if exists (select 1 from ca_abono, ca_abono_det
               where ab_operacion     = @w_operacionca
			   and ab_operacion       = abd_operacion
			   and ab_secuencial_ing  = abd_secuencial_ing
			   and abd_tipo           = 'CON'
			   and ab_estado          = 'NA')
    begin
	      return 725173 -- Existen Condonaciones posteriores a la fecha de este pago que deben ser revisadas.
    end 
   

   -- INSERCION DE LAS PRIORIDADES DE PAGO, QUE VIENEN EN UN STRING    
   select @w_concepto_aux = ''
   while @i_prioridades <> '' 
   begin
      set rowcount 1
      select @w_concepto_aux = ro_concepto
      from   ca_rubro_op
      where  ro_operacion = @w_operacionca
      and    ro_fpago     <> 'L'
      and    ro_concepto  > @w_concepto_aux
      order  by ro_concepto

      set rowcount 0
     
      select @w_k = charindex(';',@i_prioridades)

      if @w_k = 0 
      begin
         select @w_k = charindex('#',@i_prioridades)

         if @w_k = 0
            select @w_valor = substring(@i_prioridades, 1, datalength(@w_valor))
         else
            select @w_valor = substring(@i_prioridades, 1, @w_k-1)

         if exists(select 1 from ca_abono_prioridad
         where ap_secuencial_ing = @w_secuencial_ing 
         and   ap_operacion      = @w_operacionca
         and   ap_concepto       = @w_concepto_aux)
         begin
            delete ca_abono_prioridad
            where ap_secuencial_ing = @w_secuencial_ing 
            and   ap_operacion = @w_operacionca
            and   ap_concepto = @w_concepto_aux
            
            select @w_descripcion = @i_prioridades + '-' + @w_valor
            
            insert into ca_errorlog (
            er_fecha_proc, er_error,  er_usuario,
            er_tran,       er_cuenta, er_descripcion )
            values (
            @w_fecha_hoy,  999999,    @s_user,
            0,             @i_banco,  @w_descripcion )
         end

         
         if @w_valor is null or @w_valor = '' or @w_concepto_aux = '' 
         begin
            select @w_descripcion = @i_prioridades + '-' + @w_valor
            
            insert into ca_errorlog (
            er_fecha_proc,er_error,  er_usuario,
            er_tran,      er_cuenta, er_descripcion)
            values (
            @w_fecha_hoy, 999999,    @s_user,
            0,            @i_banco,  @w_descripcion )
         end

          
         insert into ca_abono_prioridad
         values (@w_secuencial_ing,@w_operacionca,@w_concepto_aux,convert(int,@w_valor))

         if @@error != 0 
         begin           
            --PRINT 'ingaboin.sp error insertando en ca_abono_prioridad a secuencial_ing ' + cast(@w_secuencial_ing as varchar) + ' @w_concepto_aux ' + cast(@w_concepto_aux as varchar) + ' @w_valor '+ cast(@w_valor as varchar)
            return 710001
         end

         --select @w_i = @w_i + 1, --LPO CDIG Ajustes por migracion a Java, daba null
         --@w_j = 1 --LPO CDIG Ajustes por migracion a Java, daba null

         break
      end   --if @w_k = 0 
      else 
      begin
         select @w_valor = substring (@i_prioridades, 1, @w_k-1)

         if exists(select 1 from ca_abono_prioridad
         where ap_secuencial_ing = @w_secuencial_ing 
         and   ap_operacion = @w_operacionca
         and   ap_concepto = @w_concepto_aux)
         begin
            select @w_descripcion = @i_prioridades + '-' + @w_valor
            
            insert into ca_errorlog (         
            er_fecha_proc, er_error,  er_usuario,
            er_tran,       er_cuenta, er_descripcion )
            values (
            @w_fecha_hoy,  999999,    @s_user,
            0,             @i_banco,  @w_descripcion )
         end
         
         
         if @w_valor is null or @w_valor = ''  or @w_concepto_aux = '' 
         begin
         
            select @w_descripcion = @i_prioridades + '-' + @w_valor
            
            insert into ca_errorlog (
            er_fecha_proc, er_error,  er_usuario,
            er_tran,       er_cuenta, er_descripcion)
            values (
            @w_fecha_hoy,  999999,    @s_user,
            0,             @i_banco,  @w_descripcion)
         end
            
         insert into ca_abono_prioridad
         values (@w_secuencial_ing,@w_operacionca,@w_concepto_aux,convert(int,@w_valor))
         
         if @@error != 0 return 710001
         
         --select @w_j = @w_j + 1  --LPO CDIG Ajustes por migracion a Java, daba null
         select @i_prioridades = substring(@i_prioridades, @w_k +1,datalength(@i_prioridades) - @w_k)
      end     
   end   ---while @i_prioridades <> '' 
   


   ---NR 296
   ---Si la forma de pago es la parametrizada por el usuario CHLOCAL
   ---y el credito es clase O rotativo, se debe colocar unos dias de retencion al 
   -- Pago apra que solo se aplique pasado este tiempo
   
   select @w_forma_pago = abd_concepto
   from ca_abono_det
   where abd_operacion = @w_operacionca
   and abd_secuencial_ing = @w_secuencial_ing
   and abd_tipo in ('PAG')                     -- KDR Forma de Pago para los detalles tipo PAG
   
   
   select  @w_parametro_control =  pa_char 
   from cobis..cl_parametro
   where pa_nemonico = 'FPCHLO'
   and pa_producto = 'CCA'
   set transaction isolation level read uncommitted
      
      
   if @w_tipo = 'O' and @w_forma_pago =  @w_parametro_control
   begin
      
      select @w_ab_dias_retencion = @i_retencion
      
      select  @w_dias_retencion =  pa_smallint
      from cobis..cl_parametro
      where pa_nemonico = 'DCHLO'
      and pa_producto = 'CCA'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted
      
      if @w_rowcount = 0
         select  @w_dias_retencion = 0
      
      select    @w_ab_dias_retencion  = @w_dias_retencion,
                @i_retencion =  @w_ab_dias_retencion
      
      update ca_abono
      set ab_dias_retencion = @w_ab_dias_retencion,
          ab_dias_retencion_ini = @w_ab_dias_retencion
      where ab_operacion = @w_operacionca
      and  ab_secuencial_ing = @w_secuencial_ing
   
                
   end  

   if exists (select 1 from ca_abono_det
              where  abd_operacion      = @w_operacionca
              and    abd_secuencial_ing = @w_secuencial_ing
              and    abd_tipo           = 'CON')
   begin
   
      select @w_monto_pag_con_mn  = isnull(sum (abd_monto_mn), 0),
	         @w_monto_pag_con_mpg = isnull(sum (abd_monto_mpg), 0),
			 @w_monto_pag_con_mop = isnull(sum (abd_monto_mop), 0)	         
	  from ca_abono_det 
	  where  abd_operacion      = @w_operacionca
      and    abd_secuencial_ing = @w_secuencial_ing
      and    abd_tipo           = 'CON'
	  
	  select @w_monto_con_rub_mn  = isnull(sum (abd_monto_mn), 0),
	         @w_monto_con_rub_mpg = isnull(sum (abd_monto_mpg), 0),
	         @w_monto_con_rub_mop = isnull(sum (abd_monto_mop), 0)
	  from ca_abono_det 
	  where  abd_operacion      = @w_operacionca
      and    abd_secuencial_ing = @w_secuencial_ing
      and    abd_tipo           = 'PAG'
	  
	  if (@w_monto_pag_con_mn <> @w_monto_con_rub_mn
	     or @w_monto_pag_con_mpg <> @w_monto_con_rub_mpg
		 or @w_monto_pag_con_mop <> @w_monto_con_rub_mop)
	     return 725154

   end

   --- NR 296
   /* -- Inicio -- Smora REQ.455
   select @w_operacion_alterna = oa_operacion_alterna
   From ca_operacion_alterna
   Where oa_operacion_original = @w_operacionca
   
   if @@rowcount != 0
   begin
      exec @w_error = sp_decimales
           @i_moneda       = @w_moneda,
           @o_decimales    = @w_num_dec_op out
      
      if @w_error != 0 
          return  @w_error
      
      exec @w_error = sp_dividir_pago_alterna
      @i_operacion_original = @w_operacionca,
      @i_operacion_alterna  = @w_operacion_alterna,
      @i_secuencial_ing     = @w_secuencial_ing,
      @i_num_dec            = @w_num_dec_op
      
      if @w_error != 0  return  @w_error
   end
   -- Fin -- Smora REQ.455
   */
      
   if @i_reg_pago_grupal_padre = 'N'
   begin
      -- Saldo Operación antes del pago
      exec @w_error     = sp_calcula_saldo
      @i_operacion      = @w_operacionca,
      @i_tipo_pago      = @w_tipo_cobro,
      @i_tipo_reduccion = @w_tipo_reduccion,
      @o_saldo          = @w_saldo_anterior out
      
      if @@error <> 0
         return 708201 -- ERROR. Retorno de ejecucion de Stored Procedure

   end
      
   -- CREACION DEL REGISTRO DE PAGO (Aplicar en linea)
   if (@i_fecha_vig = @w_fecha_hoy) and (@i_ejecutar = 'S') and @i_reg_pago_grupal_padre = 'N' -- Registro de Pago Grupal (Padre) no debe ser aplicado          
   begin 
      if @i_debug = 'S'
	  begin
	       print '@i_fecha_vig: ' + convert(varchar(30), @i_fecha_vig)
	       print '@i_ejecutar: ' + convert(varchar(30), @i_ejecutar)
	       print '@w_secuencial_ing: ' + convert(varchar(30), @w_secuencial_ing)
	       print '@w_secuencial_pag: ' + convert(varchar(30), @w_secuencial_pag)
	       print '@w_operacionca: ' + convert(varchar(30), @w_operacionca)
	       print '@i_en_linea: ' + convert(varchar(30), @i_en_linea)
	       print '@i_no_cheque: ' + convert(varchar(30), @i_no_cheque)
	       print '@i_cuenta: ' + convert(varchar(30), @i_cuenta)
	       print '@i_mon: ' + convert(varchar(30), @i_mon)
	       print '@i_dividendo: ' + convert(varchar(30), @i_dividendo)
	       print '@w_cotizacion_hoy: ' + convert(varchar(30), @w_cotizacion_hoy)
        
	  end

      exec @w_return    = sp_registro_abono
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_ofi            = @s_ofi,
      @s_ssn            = @s_ssn,
      @s_sesn           = @s_sesn,
      @s_srv            = @s_srv, 
      @s_ssn_branch     = @s_ssn_branch,	  
      @i_secuencial_ing = @w_secuencial_ing,
      @i_secuencial_pag = @w_secuencial_pag,           -- ITO 11/02/2010
      @i_operacionca    = @w_operacionca,
      @i_en_linea       = @i_en_linea,
      @i_fecha_proceso  = @i_fecha_vig,
      @i_no_cheque      = @i_no_cheque,
      @i_cuenta         = @i_cuenta,   
      @i_mon            = @i_mon,      
      @i_dividendo      = @i_dividendo,
      @i_cotizacion     = @w_cotizacion_hoy,
	  @i_aplica_licitud = @i_aplica_licitud,
	  @o_secuencial_rpa = @o_secuencial_rpa out
       
      if @w_return != 0 return @w_return  
   
      
       -- APLICACION EN LINEA DEL PAGO SIN RETENCION 
      if @i_retencion = 0  and @w_tipo <> 'D'
      begin  --(1)
	  
	     if @i_debug = 'S'
	     begin
	          print '@w_tipo: ' + convert(varchar(30), @w_tipo)
	          print '@i_ejecutar: ' + convert(varchar(30), @i_ejecutar)
	          print '@w_secuencial_ing: ' + convert(varchar(30), @w_secuencial_ing)
	          print '@w_secuencial_pag: ' + convert(varchar(30), @w_secuencial_pag)
	          print '@w_operacionca: ' + convert(varchar(30), @w_operacionca)
	          print '@i_en_linea: ' + convert(varchar(30), @i_en_linea)
	          print '@i_no_cheque: ' + convert(varchar(30), @i_no_cheque)
	          print '@i_cuenta: ' + convert(varchar(30), @i_cuenta)
	          print '@i_mon: ' + convert(varchar(30), @i_mon)
	          print '@i_dividendo: ' + convert(varchar(30), @i_dividendo)
	          print '@w_cotizacion_hoy: ' + convert(varchar(30), @w_cotizacion_hoy)
              print '@i_fecha_vig: ' + convert(varchar(30), @i_fecha_vig)
              print '@i_cancela: ' + convert(varchar(30), @i_cancela)
              print '@i_renovacion: ' + convert(varchar(30), @i_renovacion)
              print '@i_valor_multa: ' + convert(varchar(30), @i_valor_multa)
           
	     end
		 
         exec @w_return    = sp_cartera_abono
         @s_user           = @s_user,
         @s_srv            = @s_srv,            
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_sesn           = @s_sesn,
         @s_ssn            = @s_ssn,
         @s_ofi            = @s_ofi,
         @s_rol		   = @s_rol,
         @i_secuencial_ing = @w_secuencial_ing,
         @i_operacionca    = @w_operacionca,
         @i_fecha_proceso  = @i_fecha_vig,
         @i_en_linea       = @i_en_linea,
         @i_no_cheque      = @i_no_cheque,   
         @i_cuenta         = @i_cuenta,      
         @i_dividendo      = @i_dividendo,
         @i_cancela        = @i_cancela,
         @i_renovacion     = @i_renovacion,
         @i_cotizacion     = @w_cotizacion_hoy,
         @i_valor_multa    = @i_valor_multa,
         @i_canal_inter    = @i_canal_inter
		 
         if @w_return !=0  return @w_return
   
		 if @i_reg_pago_grupal_hijo = 'N'
		 begin
		 
            exec @w_return = sp_tanqueo_fact_cartera
            @s_user             = @s_user,
            @s_date             = @s_date,
            @s_rol              = @s_rol,
            @s_term             = @s_term,
            @s_ofi              = @s_ofi,
            @s_ssn              = @s_ssn,
            @t_corr             = 'N',
            @t_ssn_corr         = null,
            @t_fecha_ssn_corr   = null,
            @i_ope_banco        = @i_banco,
            @i_secuencial_ing   = @w_secuencial_ing,
            @i_tipo_operacion   = 'N', -- Individual
            @i_saldo_anterior   = @w_saldo_anterior,
			@i_fecha_ing        = @w_fecha_hoy,
            @i_externo          = 'N',
            @i_tipo_tran        = 'PAG',
            @i_operacion        = 'I',
            @o_guid             = @o_guid             out,
            @o_fecha_registro   = @o_fecha_registro   out,
            @o_ssn              = @o_ssn              out,
			@o_orquestador_fact = @o_orquestador_fact out
			
			if @w_return !=0  return @w_return
		 
		 end
   
      end ---(FIN de ejecuta sp_cartera_abono (1)
	  
      else
      if @w_tipo = 'D'
      begin
         exec @w_return    = sp_cartera_abono_dd
         @s_user           = @s_user,
         @s_srv            = @s_srv,            
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_sesn           = @s_sesn,
         @s_ssn            = @s_ssn,
         @s_ofi            = @s_ofi,
         @i_secuencial_ing = @w_secuencial_ing,
         @i_operacionca    = @w_operacionca,
         @i_fecha_proceso  = @i_fecha_vig,
         @i_en_linea       = @i_en_linea,
         @i_no_cheque      = @i_no_cheque,
         @i_cotizacion     = @w_cotizacion_hoy
   
         if @w_return !=0 
             return @w_return           
      end 

   end
   
   if @i_reg_pago_grupal_padre = 'N' and @i_reg_pago_grupal_hijo = 'N'
   begin
      -- INTERFAZ CON BANCOS PARA GENERAR MOVIMIENTO BANCARIO
      select @w_concepto      =  abdt_concepto,
      @w_monto_inter   =  abdt_monto_mpg,
      @w_cod_banco     =  abdt_cod_banco,
      @w_cuenta        =  abdt_cuenta,
      @w_beneficiario  =  abdt_beneficiario,
      @w_moneda_pago   =  abdt_moneda
      from  ca_abono_det_tmp
      where abdt_user = @s_user
      and   abdt_sesn = @s_sesn 
            
      select @w_categoria = cp_categoria 
      from cob_cartera..ca_producto
      where cp_producto = @w_concepto
	     
      --JH Afectación PAGO a Banco 
      if(@w_categoria = 'BCOR' OR @w_categoria = 'MOEL')
      begin

         select @w_causal = c.valor 
         from cobis..cl_tabla t, cobis..cl_catalogo c
         where t.tabla  = 'ca_fpago_causalbancos'
         and   t.codigo = c.tabla
         and   c.estado = 'V'
         and   c.codigo = @w_concepto
		      
         if @@rowcount = 0 or @w_causal is null
         begin
            select @w_error = 725139
            return @w_error
         end
	     
         -- KDR 05/09/2022 Valida que la moneda del pago coincida con la moneda de la cuenta bancaria
         if  @w_moneda_pago not in (select cu_moneda 
                                    from cob_bancos..ba_cuenta
                                    where cu_banco   = @w_cod_banco 
                                    and cu_cta_banco = @w_cuenta)
         begin
            select @w_error = 725187 -- Error,la moneda de la cuenta bancaria no coincide con la moneda del desembolso o pago
            return @w_error	   
         end		 
	       	       
         exec @w_return = cob_bancos..sp_tran_general
         @i_operacion      = 'I',
         @i_banco          = @w_cod_banco,
         @i_cta_banco      = @w_cuenta,
         @i_fecha          = @s_date,
         @i_fecha_contable = @s_date,
         @i_tipo_tran      = @w_param_ibtran, -- NOTA DE CREDITO (DEBE TOMARSE DESDE UN NUEVO PARAMETRO GENERAL)
         @i_causa          = @w_causal,        -- KDR Causal de la forma de pago
         @i_documento      = @w_beneficiario , --NRO  DE REFERENCIA BANCARIA INGRESADA
         @i_concepto       = 'INTERFAZ DE PAGO DESDE COBIS CAR',
         @i_beneficiario   = @w_beneficiario,
         @i_valor          = @w_monto_inter,
         @i_cheques        = 0,
         @i_producto       = 7, --CARTERA
         @i_desde_cca      = 'S',
         @i_ref_modulo     = @i_banco,
         @i_modulo         = 7, --CARTERA
         @i_ref_modulo2    = @s_ofi,
         @t_trn            = 171013,
         @s_corr           = @w_corr,
         @s_user           = @s_user,
         @s_ssn            = @s_ssn,
         @s_ofi            = @s_ofi,
         @o_secuencial     = @w_sec_banco out
            
         if @w_return <> 0 
         begin
            select @w_error = @w_return
            return @w_error
         end  
		   
         update ca_abono_det 
         set abd_secuencial_interfaces = @w_sec_banco
         where abd_operacion      = @w_operacionca
         and   abd_secuencial_ing = @w_secuencial_ing
		   
         if @@error != 0 return 710001
      end 
      -- FIN INTERFAZ CON BANCOS
	  
      --JCHS Inserción tabla de interfaz de pago
      if @i_pago_interfaz = 'S'
      begin
	  
         select @w_monto_inter =  abdt_monto_mpg
         from  ca_abono_det_tmp
         where abdt_user = @s_user
         and   abdt_sesn = @s_sesn 
			
			
         INSERT INTO cob_cartera..ca_intefaz_pago
         (
            ip_operacionca     , ip_sdate               , ip_sterm          , ip_ssn,
            ip_ssen            , ip_forma_pago          , ip_banco_pago     , ip_cta_banco_pago,
            ip_aplicar_en_linea, ip_id_referencia_origen, ip_sec_ing_cartera, ip_fecha_pago,
            ip_canal           , ip_monto               , ip_estado
         )
         VALUES
         (
            @w_operacionca      , @s_date               , @s_term            , @s_ssn,
            @s_sesn             , @i_forma_pago         , @i_cod_banco       , @i_cuenta,
            @i_ejecutar         , @i_id_referencia_inter, @w_secuencial_ing  , @i_fecha_vig,
            @i_canal_inter      , @w_monto_inter        , 'N'
         )
	            
         if @@error <> 0
         begin
            select @w_error = 725093
            return  @w_error 
         end 
      end
   end
   
   -- KDR Recálculo de la TIR y TEA por Pago Extraordinario con reduccion de cuota (C) y tiempo(T).
   if @i_tipo_reduccion in ('T', 'C') -- and @i_en_linea = 'S'
   begin
   
      exec @w_return  = sp_tir 
        @i_banco  = @i_banco, 
        @o_cat    = @w_cat1 output, 
        @o_tir    = @w_tir  output, 
        @o_tea    = @w_tea output 
      
      if @w_return <> 0 
      begin
         select @w_error = @w_return
         return @w_error
      end 
	  
      -- ACTUALIZA VALOR DE LA TIR Y TEA.
      update cob_cartera..ca_operacion
      set    op_valor_cat = @w_tir,
             op_tasa_cap = @w_tea
      where  op_operacion = @w_operacionca
      
      if @@error <> 0
      begin
         select @w_error = 705007 -- Error en actualizacion de Operacion
         return  @w_error 
      end 
   
   end -- Recalculo TIR, TEA

end  -- operacion I 

/*consulta cuantos pagos grupales de un credito estan pendientes de aplicar*/
if @i_accion = 'G'
begin
    select @w_operacionca = op_operacion
    from ca_operacion
    where op_banco = @i_banco
    
    select 
    numero_pagos = count(1),
    monto        = sum(co_monto)
    from ca_corresponsal_trn 
    where 
    co_codigo_interno = @w_operacionca 
    and co_tipo       = 'PG' 
    and co_estado     = 'I'
    and co_accion     = 'I'
end

return 0
GO
