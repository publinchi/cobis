/************************************************************************/
/*   Archivo:                    ingabosim.sp                           */
/*   Stored procedure:           sp_ing_abono_simulado                  */
/*   Base de datos:              cob_cartera                            */
/*   Producto:                   Cartera                                */
/*   Disenado por:               Adriana Giler                          */
/*   Fecha de escritura:         Abril 2019                             */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP S.A.'.                                                  */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                               PROPOSITO                              */
/*   Ingreso de simulación de pagos                                     */ 
/*   S: Seleccion de negociacion de abonos automaticos                  */
/*   Q: Consulta de negociacion de abonos automaticos                   */
/*   I: Insercion de abonos                                             */
/*   U: Actualizacion de negociacion de abonos automaticos              */
/*   D: Eliminacion de negociacion de abonos automaticos                */
/************************************************************************/
/*                             ACTUALIZACIONES                          */
/*      FECHA           AUTOR                  ACTUALIZACION            */
/*   13/May/2020        Luis Castellanos       CDIG Ajuste simulacionPAG*/
/*   20/10/2021         G. Fernandez          Ingreso de nuevo campo de */
/*                                             solidario en ca_abono_det*/
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_ing_abono_simulado')
   drop proc sp_ing_abono_simulado
go


create proc sp_ing_abono_simulado
   @s_user                     login        = null,
   @s_term                     varchar(30)  = null,
   @s_date                     datetime     = null,
   @s_ssn                      int          = null,
   @s_srv                      varchar(30)  = null, 
   @s_sesn                     int          = null,
   @s_ofi                      smallint     = null,
   @s_rol		               smallint     = null, 
   @t_trn                      int,
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
   @i_dividendo                smallint     = 0,
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
   @i_encerar                  char(1),
   @i_moneda                   int          = null,
   @i_factura                  char(16)     = null,
   @i_concepto                 catalogo,
   @i_monto_mpg                money        = 0,
   @i_monto_mop                money       = null,
   @i_monto_mn                 money       = null,
   @i_cotizacion_mpg           money       = null,
   @i_cotizacion_mop           money       = null,  
   @i_tcotizacion_mpg          char(1)     = null,
   @i_tcotizacion_mop          char(1)     = null,
   @i_inscripcion              int         = null,
   @i_carga                    int         = null,
   @i_porcentaje               float       = null,
   @o_secuencial_ing           int          = NULL out
   
as

declare 
@w_sp_name                    descripcion,
@w_return                     int,
@w_fecha_hoy                  datetime,
@w_est_vigente                tinyint,
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
@w_extraordinario             char(1)  

select   @w_sp_name = 'sp_ing_abono_simulado'

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out 

select @i_prioridades = isnull(@i_prioridades, '')

select 
    @w_operacionca             = op_operacion,
    @w_moneda                  = op_moneda,
    @w_estado                  = op_estado,
    @w_fecha_ult_proceso       = op_fecha_ult_proceso,
    @w_periodicidad            = op_tdividendo,
    @w_dias_anio               = op_dias_anio,
    @w_base_calculo            = op_base_calculo,
    @w_tipo                    = op_tipo,   
    @w_prepago_desde_lavigente = op_prepago_desde_lavigente
    from   ca_operacion
    where  op_banco  = @i_banco

if @@rowcount = 0  
Begin
  select @w_error =  701025  
  goto ERROR
end 

-- INGRESO DEL PAGO 
if @i_accion = 'I' 
begin

    if @i_encerar = 'S'   
    begin
      delete ca_abono_det_tmp
      where  abdt_user = @s_user
      and    abdt_sesn = @s_sesn
      if @@error <> 0 return 71003

	  if exists (select 1 from ca_operacion_tmp where opt_operacion = @w_operacionca) --LCA CDIG Ajuste simulacionPAG
	  begin
	     delete ca_operacion_tmp where opt_operacion = @w_operacionca
		 if @@error <> 0 return 71003
	  end
    end
    
    BEGIN TRAN
    
    --INSERCION DE CA_ABONO_DET_TMP 
    insert into ca_abono_det_tmp(
        abdt_user,             abdt_sesn,             abdt_moneda,
        abdt_tipo,             abdt_concepto,         abdt_cuenta,
        abdt_beneficiario,     abdt_monto_mpg,        abdt_monto_mop,
        abdt_monto_mn,         abdt_cotizacion_mpg,   abdt_cotizacion_mop,
        abdt_tcotizacion_mpg,  abdt_tcotizacion_mop,  abdt_cheque,
        abdt_cod_banco,        abdt_inscripcion,      abdt_carga,
        abdt_porcentaje_con,   abdt_solidario)                           --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
    values (                                      
        @s_user,               @s_sesn,               @i_moneda,
        @i_tipo,               @i_concepto,           isnull(@i_cuenta,''),
        @i_factura,            @i_monto_mpg,          @i_monto_mop,
        @i_monto_mn,           @i_cotizacion_mpg,     @i_cotizacion_mop,
        @i_tcotizacion_mpg,    @i_tcotizacion_mop,    @i_no_cheque,
        @i_cod_banco,          @i_inscripcion,        @i_carga,
        @i_porcentaje,         'N')  

    if @@error <> 0
    Begin
      select @w_error =  710216  
      goto ERROR
    end  
 
    select @w_acepta_pago = es_acepta_pago
    from ca_estado
    where es_codigo = @w_estado
   
    if @w_acepta_pago = 'N'
    Begin
      select @w_error =  701117  
      goto ERROR
    end 
    
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
    
    if @w_return != 0  
    begin   
      select @w_error =  @w_return  
      goto ERROR
    end 
 
    -- INSERCION DE CA_ABONO 
    insert into ca_abono (
    ab_operacion,          ab_fecha_ing,                ab_fecha_pag,
    ab_cuota_completa,     ab_aceptar_anticipos,        ab_tipo_reduccion,
    ab_tipo_cobro,         ab_dias_retencion_ini,       ab_dias_retencion,
    ab_estado,             ab_secuencial_ing,           ab_secuencial_rpa,
    ab_secuencial_pag,     ab_usuario,                  ab_terminal,
    ab_tipo,               ab_oficina,                  ab_tipo_aplicacion,
    ab_nro_recibo,         ab_tasa_prepago,             ab_dividendo,
    ab_calcula_devolucion, ab_prepago_desde_lavigente,  ab_extraordinario)
    values (
    @w_operacionca,        @w_fecha_hoy,                @i_fecha_vig,
    @i_cuota_completa,     @i_anticipado,               @i_tipo_reduccion,
    @i_proyectado,         @i_retencion,                @i_retencion,
    'ING',                 @w_secuencial_ing,           0,
    @w_secuencial_pag,     @s_user,                     @s_term,                -- @w_secuencial_pag por 0
    @i_tipo,               @s_ofi,                      @i_tipo_aplicacion,
    @w_numero_recibo,      @i_tasa_prepago,             @i_dividendo,
    @i_calcula_devolucion, @w_prepago_desde_lavigente,  @i_solo_capital)
    
    -- INSERCION DE CA_DET_ABONO LEYENDO DE CA_DET_ABONO_TMP 
    insert into ca_abono_det(
    abd_secuencial_ing,    abd_operacion,               abd_tipo,  
    abd_concepto,          abd_cuenta,                  abd_beneficiario,            
    abd_monto_mpg,         abd_monto_mop,               abd_monto_mn,                
    abd_cotizacion_mpg,    abd_cotizacion_mop,          abd_moneda,                  
    abd_tcotizacion_mpg,   abd_tcotizacion_mop,         abd_cheque,                  
    abd_cod_banco,         abd_inscripcion,             abd_carga,                   
    abd_porcentaje_con,    abd_solidario)                                 --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
    select
    @w_secuencial_ing,     @w_operacionca,              abdt_tipo,
    abdt_concepto,         abdt_cuenta,                 isnull(abdt_beneficiario,''), 
    abdt_monto_mpg,        abdt_monto_mop,              abdt_monto_mn,               
    abdt_cotizacion_mpg,   abdt_cotizacion_mop,         abdt_moneda,                 
    abdt_tcotizacion_mpg,  abdt_tcotizacion_mop,        abdt_cheque,                 
    abdt_cod_banco,        abdt_inscripcion,            abdt_carga,                  
    abdt_porcentaje_con,   abdt_solidario
    from  ca_abono_det_tmp
    where abdt_user = @s_user
    and   abdt_sesn = @s_sesn
    
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
          select @w_error =  710001  
          goto ERROR
        end 

         select @w_i = @w_i + 1,
         @w_j = 1

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
         
         if @@error != 0 
         begin   
          select @w_error =  710001
          goto ERROR
         end 
         
         select @w_j = @w_j + 1
         select @i_prioridades = substring(@i_prioridades, @w_k +1,datalength(@i_prioridades) - @w_k)
      end     
    end   ---while @i_prioridades <> '' 
    
   
    -- CREACION DEL REGISTRO DE PAGO
    if (@i_fecha_vig = @w_fecha_hoy) and (@i_ejecutar = 'S')          
    begin 
       exec @w_return    = sp_registro_abono
       @s_user           = @s_user,
       @s_term           = @s_term,
       @s_date           = @s_date,
       @s_ofi            = @s_ofi,
       @s_ssn            = @s_ssn,
       @s_sesn           = @s_sesn,
       @s_srv            = @s_srv,            
       @i_secuencial_ing = @w_secuencial_ing,
       @i_secuencial_pag = @w_secuencial_pag,         
       @i_operacionca    = @w_operacionca,
       @i_en_linea       = @i_en_linea,
       @i_fecha_proceso  = @i_fecha_vig,
       @i_no_cheque      = @i_no_cheque,
       @i_cuenta         = @i_cuenta,   
       @i_mon            = @i_mon,      
       @i_dividendo      = @i_dividendo,
       @i_cotizacion     = @w_cotizacion_hoy
        
       if @w_return != 0 
       begin   
          select @w_error =  @w_return 
          goto ERROR
       end
        -- APLICACION EN LINEA DEL PAGO SIN RETENCION 
       if @i_retencion = 0  and @w_tipo <> 'D'
       begin  --(1)
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
          @i_simulado       = 'S'  --Pago Simulado
    
          if @w_return !=0  
          begin   
              select @w_error =  @w_return 
              goto ERROR
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
          begin   
              select @w_error =  @w_return 
              goto ERROR
           end           
       end       
    end
  
    --EJECUTANDO EL QRPAGO
    exec @w_return= cob_cartera..sp_qr_pagos 
         @i_banco           = @i_banco,
         @i_formato_fecha   = 103,
         @i_cancela         = @i_cancela
         
    if @w_return !=0 
    begin   
      select @w_error =  @w_return 
      goto ERROR
    end 
   
    EXEC @w_return= cob_cartera..sp_qr_table_amortiza_web 
        @i_banco   = @i_banco,
        @i_opcion  = 'T'
    
    if @w_return !=0 
    begin   
      select @w_error =  @w_return 
      goto ERROR
    end    
        
    while @@trancount > 0 ROLLBACK TRAN
end  -- operacion I 


return 0

ERROR:
 while @@trancount > 0 ROLLBACK TRAN
 Return @w_error 


GO
