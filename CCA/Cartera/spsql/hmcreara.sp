USE cob_cartera
GO
/****** Object:  StoredProcedure [dbo].[sp_crea_operacion_rapida]    Script Date: 08/23/2013 14:10:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select 1 from sysobjects where name = 'sp_crea_operacion_rapida')
   drop proc sp_crea_operacion_rapida 
go

create proc sp_crea_operacion_rapida
   @s_ssn               int = null,
   @s_sesn              int = null,
   @s_date              datetime = null,
   @s_ofi               smallint = null,
   @s_user              login = null,
   @s_rol               smallint = null,
   @s_term              varchar(30) = null,
   @s_srv               varchar(30) = null,
   @s_lsrv              varchar(30) = null,
   @s_error             int = null,
   @s_sev               int = null,
   @s_msg               descripcion = null,
   @s_org               char(1)      = null,   
   @i_sector            catalogo = null,
   @i_toperacion        catalogo = null,
   @i_moneda            tinyint = null,
   @i_monto             money = null,
   @i_monto_aprobado    money = null,
   @i_formato_fecha     int = 101,
   @o_banco             cuenta = null output
      
as
declare 
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_operacionca       int,
   @w_banco             cuenta,
   @w_anterior          cuenta ,
   @w_migrada           cuenta,
   @w_tramite           int,
   @w_cliente           int,
   @w_nombre            descripcion,
   @w_cedula            varchar(30),
   @w_sector            catalogo,
   @w_toperacion        catalogo,
   @w_oficina           smallint,
   @w_moneda            tinyint,
   @w_producto          catalogo,
   @w_comentario        varchar(255),
   @w_oficial           smallint,
   @w_fecha_ini         datetime,
   @w_fecha_f           varchar(10),
   @w_fecha_fin         datetime,
   @w_fecha_ult_proceso datetime,
   @w_fecha_liq         datetime,
   @w_fecha_reajuste    datetime,
   @w_monto             money,
   @w_monto_aprobado    money,
   @w_destino           catalogo,
   @w_lin_credito       cuenta,
   @w_ciudad            int,
   @w_estado            tinyint,
   @w_periodo_reajuste  smallint,
   @w_reajuste_especial char(1),
   @w_tipo              char(1),
   @w_forma_pago        catalogo,
   @w_cuenta            cuenta,
   @w_dias_anio         smallint,
   @w_tipo_amortizacion varchar(30),
   @w_cuota_completa    char(1),
   @w_tipo_cobro        char(1),
   @w_tipo_reduccion    char(1),
   @w_aceptar_anticipos char(1),
   @w_precancelacion    char(1),
   @w_num_dec           tinyint,
   @w_tplazo            catalogo,
   @w_plazo             smallint,
   @w_tdividendo        catalogo,
   @w_periodo_cap       smallint,
   @w_periodo_int       smallint,
   @w_gracia_cap        smallint,
   @w_gracia_int        smallint,
   @w_dist_gracia       char(1),
   @w_fecha_fija        char(1), 
   @w_dia_pago          tinyint,
   @w_cuota_fija        char(1),
   @w_evitar_feriados   char(1),
   @w_tipo_producto     char(1),
   @w_renovacion        char(1),
   @w_ult_dia_habil     char(1),
   @w_mes_gracia        tinyint,
   @w_tipo_aplicacion   char(1),
   @w_reajustable       char(1),
   @w_est_novigente     tinyint,
   @w_est_credito       tinyint,
   @w_dias_dividendo    int,
   @w_dias_aplicar      int,
   @w_clase_cartera     catalogo,
   @w_origen_fondos     catalogo,
   @w_base_calculo      CHAR(1)  --LGU


/* CARGAR VALORES INICIALES */
select 
@w_sp_name = 'sp_crea_operacion_rapida',
@w_est_novigente = 0,
@w_est_credito   = 99


/* VERIFICAR QUE EXISTAN LOS RUBROS NECESARIOS */

if not exists (select 1 from ca_rubro
where  ru_toperacion = @i_toperacion
and    ru_moneda     = @i_moneda
and    ru_tipo_rubro = 'C'
and    ru_crear_siempre = 'S')
begin
   select @w_error = 710016
   goto ERROR
end 

/* DETERMINAR LOS VALORES POR DEFECTO PARA EL TIPO DE OPERACION */

select 
@w_periodo_reajuste     = dt_periodo_reaj,
@w_reajuste_especial    = dt_reajuste_especial,
@w_precancelacion       = dt_precancelacion,
@w_tipo                 = dt_tipo,
@w_cuota_completa   	= dt_cuota_completa,
@w_tipo_reduccion   	= dt_tipo_reduccion,
@w_aceptar_anticipos    = dt_aceptar_anticipos,
@w_tipo_reduccion   	= dt_tipo_reduccion,
@w_tplazo       		= dt_tplazo,
@w_plazo        		= dt_plazo,
@w_tdividendo       	= dt_tdividendo,
@w_periodo_cap      	= dt_periodo_cap,
@w_periodo_int      	= dt_periodo_int,
@w_gracia_cap       	= dt_gracia_cap,
@w_gracia_int       	= dt_gracia_int,
@w_dist_gracia      	= dt_dist_gracia,
@w_dias_anio        	= dt_dias_anio,  
@w_tipo_amortizacion    = dt_tipo_amortizacion,
@w_fecha_fija       	= dt_fecha_fija,
@w_dia_pago         	= dt_dia_pago,
@w_cuota_fija       	= dt_cuota_fija,
@w_evitar_feriados  	= dt_evitar_feriados,
@w_renovacion       	= dt_renovacion,
@w_mes_gracia       	= dt_mes_gracia,
@w_tipo_aplicacion  	= dt_tipo_aplicacion,
@w_tipo_cobro           = dt_tipo_cobro,
@w_ult_dia_habil        = dt_dia_habil,
@w_reajustable          = dt_reajustable,
@w_base_calculo         = dt_base_calculo  --LGU
from ca_default_toperacion
where dt_toperacion = @i_toperacion
and   dt_moneda     = @i_moneda

if @@rowcount = 0 begin
   select @w_error = 710072 
   goto ERROR
end

begin tran

  /* CALCULAR SECUENCIAL Y NUMERO DE BANCO */
   exec @w_operacionca = sp_gen_sec
   @i_operacion   = -1

   select @w_banco = convert(varchar(20),@w_operacionca)

   select @w_estado = @w_est_novigente
   /* OBTENER DATOS DE UN CLIENTE, DESTINO DE CREDITO Y OFICIAL */

   set rowcount 1

   select @w_cliente= en_ente,
          @w_nombre = substring(p_p_apellido,1,16) + ' ' + p_s_apellido + ' ' +
                      substring(en_nombre,1,40),
          @w_cedula = en_ced_ruc
   from cobis..cl_ente
   where     en_subtipo = 'P'
   set transaction isolation level read uncommitted
   
   select @w_destino = b.codigo 
   from cobis..cl_tabla a,cobis..cl_catalogo b
   where a.tabla = 'cr_destino'
   and  b.tabla = a.codigo
   and b.estado = 'V'
   set transaction isolation level read uncommitted

   select @w_oficial = oc_oficial
   from  cobis..cc_oficial,cobis..cl_funcionario,cobis..cl_catalogo
   where oc_oficial       > 0
   and   oc_funcionario   = fu_funcionario
   and   codigo           = oc_tipo_oficial
   and   tabla = (select codigo from cobis..cl_tabla
                  where tabla = 'cc_tipo_oficial')
   order by oc_oficial      
   set transaction isolation level read uncommitted
 
   select @w_producto = cp_producto 
   from ca_producto
   where cp_moneda   = @i_moneda
   and cp_desembolso = 'S'
   and isnull(cp_pcobis,0) = 0

   set rowcount 0
  
   /* TRANSMISION DEL DEUDOR DE LA OPERACION */

   exec @w_return = sp_codeudor_tmp
   @s_ssn    	 = @s_ssn,
   @s_sesn   	 = @s_sesn,
   @s_date   	 = @s_date,
   @s_ofi    	 = @s_ofi,
   @s_user   	 = @s_user,
   @s_rol    	 = @s_rol,
   @s_term   	 = @s_term,
   @s_srv    	 = @s_srv,
   @s_lsrv   	 = @s_lsrv,
   @s_error  	 = @s_error,
   @s_sev    	 = @s_sev,
   @s_msg    	 = @s_msg,
   @t_debug  	 = 'N',
   @t_file   	 = '',
   @t_from   	 = '',
   @i_borrar 	 = 'S',
   @i_secuencial = 1,
   @i_titular 	 = @w_cliente,
   @i_operacion  = @w_banco,
   @i_codeudor   = 1,
   @i_ced_ruc    = @w_cedula,
   @i_rol 		 = 'D'

   /*OBTENCION DE LOS DIAS DE MI DIVIDENDO PARA DIAS CLAUSULA*/
   select @w_dias_dividendo = td_factor
   from ca_tdividendo
   where td_tdividendo = @w_tdividendo

   exec @w_return = sp_consulta_clausula
   @i_dias_dividendo  = @w_dias_dividendo,
   @o_dias_a_aplicar  = @w_dias_aplicar out

   if @w_return <> 0 return @w_return

   /*DESCRIPCIONES DE CLASE DE CARTERA Y ORIGEN DE FONDOS*/
   select @w_clase_cartera = Y.codigo 
   from cobis..cl_tabla X, cobis..cl_catalogo Y
   where X.tabla = 'cr_clase_cartera'
   and   X.codigo= Y.tabla
   set transaction isolation level read uncommitted

   select @w_origen_fondos = Y.codigo 
   from cobis..cl_tabla X, cobis..cl_catalogo Y
   where X.tabla = 'ca_origen_fondos'
   and   X.codigo= Y.tabla
   set transaction isolation level read uncommitted

   /* CREAR LA OPERACION TEMPORAL */
   exec @w_return = sp_operacion_tmp
   @i_operacion         = 'I',
   @i_operacionca       = @w_operacionca,
   @i_banco             = @w_banco,
   @i_anterior          = null ,
   @i_migrada           = null,
   @i_tramite           = null,
   @i_cliente           = @w_cliente,
   @i_nombre            = @w_nombre,
   @i_sector            = @i_sector,
   @i_toperacion        = @i_toperacion,
   @i_oficina           = @s_ofi,
   @i_moneda            = @i_moneda, 
   @i_comentario        = '',
   @i_oficial           = @w_oficial,
   @i_fecha_ini         = @s_date,
   @i_fecha_fin         = @s_date,
   @i_fecha_ult_proceso = @s_date,
   @i_fecha_liq         = @s_date,
   @i_fecha_reajuste    = @s_date,
   @i_monto             = @i_monto, 
   @i_monto_aprobado    = @i_monto_aprobado,
   @i_destino           = @w_destino,
   @i_lin_credito       = null,
   @i_ciudad            = 1,
   @i_estado            = @w_estado,
   @i_periodo_reajuste  = @w_periodo_reajuste,
   @i_reajuste_especial = @w_reajuste_especial,
   @i_tipo              = @w_tipo, --(Hipot/Redes/Normal)
   @i_forma_pago        = @w_producto,
   @i_cuenta            = '111111111111',
   @i_dias_anio         = @w_dias_anio, 
   @i_tipo_amortizacion = @w_tipo_amortizacion,
   @i_cuota_completa    = @w_cuota_completa,
   @i_tipo_cobro        = @w_tipo_cobro,
   @i_tipo_reduccion    = @w_tipo_reduccion,
   @i_aceptar_anticipos = @w_aceptar_anticipos,
   @i_precancelacion    = @w_precancelacion,
   @i_tipo_aplicacion   = @w_tipo_aplicacion,
   @i_tplazo            = @w_tplazo,
   @i_plazo             = @w_plazo,
   @i_tdividendo        = @w_tdividendo,
   @i_periodo_cap       = @w_periodo_cap,
   @i_periodo_int       = @w_periodo_int,
   @i_dist_gracia       = @w_dist_gracia,
   @i_gracia_cap        = @w_gracia_cap,
   @i_gracia_int        = @w_gracia_int,
   @i_dia_fijo          = @w_dia_pago,
   @i_cuota             = 0,
   @i_evitar_feriados   = @w_evitar_feriados,
   @i_renovacion        = @w_renovacion,
   @i_mes_gracia        = @w_mes_gracia,
   @i_reajustable       = @w_reajustable,
   @i_dias_clausula     = @w_dias_aplicar,
   @i_clase_cartera     = @w_clase_cartera,
   @i_ult_dia_habil     = @w_ult_dia_habil,
   @i_origen_fondos     = @w_origen_fondos,
   @i_banca             = @i_sector,
   @i_base_calculo      = @w_base_calculo  -- LGU

   if @w_return != 0 begin 
      select @w_error = @w_return
      goto ERROR
   end

   /* CREAR LOS RUBROS TEMPORALES DE LA OPERACION */
   exec @w_return = sp_gen_rubtmp
   @i_operacionca = @w_operacionca,
   @s_date        = @s_date 
 
   if @w_return != 0 begin 
      select @w_error = @w_return
      goto ERROR
   end

   /* GENERACION DE LA TABLA DE AMORTIZACION */
   exec @w_return = sp_gentabla
   @i_operacionca = @w_operacionca,
   @i_tabla_nueva = 'S',
   @i_actualiza_rubros = 'S',
   @o_fecha_fin = @w_fecha_fin out
    
   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

   /* ACTUALIZACION DE LA OPERACION */

   if isnull(@w_periodo_reajuste,0) != 0 begin

      if @w_periodo_reajuste % @w_periodo_int = 0
         select @w_fecha_reajuste = dit_fecha_ven
         from   ca_dividendo_tmp
         where  dit_operacion = @w_operacionca
         and    dit_dividendo = @w_periodo_reajuste / @w_periodo_int
      else
         select @w_fecha_reajuste = 
         dateadd(dd,td_factor*@w_periodo_reajuste, @s_date)
         from ca_tdividendo
         where td_tdividendo = @w_tdividendo
   end 
   else
      select @w_fecha_reajuste = '01/01/1900'

   update ca_operacion_tmp set 
   opt_fecha_reajuste = @w_fecha_reajuste
   where opt_operacion = @w_operacionca

   if @@error != 0 begin
      select @w_error = 710002
      goto ERROR
   end 

   select @w_fecha_f  = convert(varchar(10),@w_fecha_fin,@i_formato_fecha)

   /* Crear la operacion definitiva */

   exec @w_return = sp_operacion_def
   @s_date   = @s_date,
   @s_sesn   = @s_sesn,
   @s_user   = @s_user,
   @s_ofi    = @s_ofi,
   @i_banco  = @w_banco

   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR
   end

   /* Borrar la operacion temporal */
   delete ca_operacion_tmp
   where opt_operacion = @w_operacionca

   /* Desembolso y liquidacion */

   exec @w_return      = sp_liquidacion_rapida 
   @s_ssn           = @s_ssn,
   @s_sesn          = @s_sesn,
   @s_srv           = @s_srv,
   @s_lsrv          = @s_lsrv,
   @s_user          = @s_user,
   @s_date          = @s_date,
   @s_ofi           = @s_ofi,
   @s_rol           = @s_rol,
   @s_org           = @s_org,
   @s_term          = @s_term,
   @i_banco         = @w_banco,
   @i_producto      = @w_producto ,
   @i_cuenta        = '111111111111',
   @i_beneficiario  = @w_nombre,
   @i_monto_op      = @i_monto,
   @i_moneda_op     = @i_moneda,
   @i_formato_fecha = @i_formato_fecha,
   @i_externo       = 'N', 
   @o_banco_generado  = @w_banco out  /*AUMENTADO 20/10/98*/

   if @w_return <> 0 begin  
     select @w_error = @w_return 
     goto ERROR
   end

   select @w_banco
   select @w_fecha_f

   select es_descripcion 
   from ca_estado, ca_operacion
   where  es_codigo = op_estado
   and op_operacion = @w_operacionca
 
   select @w_tipo 
   select @o_banco = @w_banco

commit tran

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error
GO

