/************************************************************************/
/*   Archivo:              cambibc.sp                                   */
/*   Stored procedure:     sp_cambia_ibc                                */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Xavier Maldonado                             */
/*   Fecha de escritura:   Nov. 2002                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                          CAMBIOS                                     */
/*    FECHA           AUTOR         CAMBIO                              */
/*    MAR-2010        EPB           Inr. 16752 Tasas                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambia_ibc')
   drop proc sp_cambia_ibc
go

---Inc. 30479 SEP-02-2011 Partiendo de la Ver. 25

create proc sp_cambia_ibc
   @s_date                       datetime,
   @s_user                       login,
   @s_term                       varchar(30),
   @s_ofi                        smallint,
   @i_operacionca                int,
   @i_moneda                     smallint,
   @i_fecha_proceso              datetime,
   @i_ibc_mn                     char(1),
   @i_ibc_me                     char(1),
   @i_moneda_nacional            tinyint,
   @i_moneda_uvr                 tinyint,
   @i_concepto_int               catalogo,
   @i_param_ibc_mn               varchar(10),
   @i_param_ibc_me               varchar(10),
   @i_est_novigente              tinyint,
   @i_est_cancelado              tinyint,
   @i_est_credito                tinyint,
   @i_est_castigado              tinyint,
   @i_est_comext                 tinyint,
   @i_en_linea                   char(1),
   @i_num_dec                    tinyint,
   @i_concepto_cap               catalogo,
   @i_cotizacion                 money,
   @i_pago_ext                   char(1)   = 'N'  ---req 482
   
as declare 
   @w_error                      int,
   @w_op_banco                   cuenta,
   @w_op_sector                  catalogo,
   @w_op_tdividendo              char(1),
   @w_op_periodo_int             smallint,
   @w_op_base_calculo            char(1),
   @w_op_dias_anio               smallint,
   @w_op_migrada                 cuenta,
   @w_op_reajuste_especial       char(1), 
   @w_ro_fpago                   char(1),
   @w_ro_num_dec                 tinyint,
   @w_max_fecha_tlu              datetime,
   @w_secuencial_tlu             int,
   @w_valor_actual_tlu           float,
   @w_vd_referencia              catalogo,
   @w_ut_referencial             catalogo,
   @w_ut_signo                   char(1),
   @w_ut_factor                  float,
   @w_ut_reajuste_especial       char(1),
   @w_ut_tipo_puntos             char(1),
   @w_ut_fecha_pri_referencial   datetime,
   @w_tasa_puntos_efa            float,
   @w_tasa_puntos_nom            float,
   @w_max_fecha_ref              datetime,
   @w_valor_tasa_ref             float,
   @w_por_efa_actual             float,
   @w_referencial_ajuste         catalogo,
   @w_signo_ajuste               char(1),
   @w_factor_ajuste              float,
   @w_porcentaje_ajuste          float,
   @w_tipo_puntos_ajuste         char(1),
   @w_porc_efa_final             float,
   @w_ut_porcentaje_efa          float,
   @w_ut_porcentaje              float,
   @w_op_clase                   catalogo,
   @w_iden_ref                   char(3),
   @w_fec_tasas                  datetime,
   @w_di_vigente                 smallint,
   @w_sec_tasas                  int,
   @w_ut_fecha_ref               datetime,
   @w_porcentaje_nom             float,
   @w_ts_tasa_ref                catalogo,
   @w_secuencial_reg             int,
   @w_recupera_tasa_inicial      char(1),
   @w_porc_efa_final_comp        float,
   @w_por_efa_actual_comp        float,
   @w_referencial_hoy            catalogo,
   @w_fecha                      datetime,
   @w_modalidad_d                char(1),
   @w_tr_tipo                    char(1),
   @w_op_tramite                 int,
   @w_TCERO                      catalogo

-- SI NO CAMBIO EL IBC EN MONEDA NACIONAL Y LA OPERACION ES MN, LEER SIGUIENTE
if (@i_moneda = @i_moneda_nacional or @i_moneda = @i_moneda_uvr) and @i_ibc_mn = 'N'
   return 0

-- SI NO CAMBIO EL IBC EN MONEDA EXTRANJERA Y LA OPERACION ES ME, LEER SIGUIENTE
if (@i_moneda <> @i_moneda_nacional and @i_moneda <> @i_moneda_uvr) and @i_ibc_me = 'N'
   return 0
   

select 
@w_op_banco               = op_banco,
@w_op_sector              = op_sector,
@w_op_reajuste_especial   = isnull(op_reajuste_especial, 'N'),
@w_op_tdividendo          = op_tdividendo,
@w_op_periodo_int         = op_periodo_int,
@w_op_base_calculo        = op_base_calculo,
@w_op_dias_anio           = op_dias_anio,
@w_op_migrada             = isnull(op_migrada,''),
@w_op_clase               = op_clase,
@w_op_tramite             = op_tramite 
from   ca_operacion with (nolock)
where  op_operacion = @i_operacionca
   
if @w_op_clase = '4' and @i_fecha_proceso < '01/01/2011'
   return 0

select @w_TCERO = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'TACERO'
and   pa_producto = 'CCA'

if @@rowcount = 0   
   select @w_TCERO = 'TCERO'   

select @w_tr_tipo = tr_tipo 
from cob_credito..cr_tramite 
where tr_tramite = @w_op_tramite 

   -- SE SALE PORQUE EN EL REAJUSTE SE CONTROLARA LA USURA
if exists( select 1 from ca_reajuste  with (nolock)
            where re_operacion = @i_operacionca
              and re_fecha     = @i_fecha_proceso)
begin              
   ---PRINT 'cambibc.sp YA HAY REAJSUTE INSERTADO'
   return 0 
end



-- OBTENER LA ULTIMA TASA PACTADA
if not exists (select 1 from   ca_ultima_tasa_op with (nolock)
               where  ut_operacion = @i_operacionca
               and    ut_concepto  = @i_concepto_int
               )
begin               
   exec @w_error =  sp_buscar_tasa_operacion
   @s_date         = @s_date,
   @i_operacionca  = @i_operacionca

   if @w_error <> 0  
   begin
      if @i_pago_ext = 'N'
         PRINT 'Error Ejecutando sp_buscar_tasa_operacion desde cambibc.sp'
      
	  return @w_error
   end
	      
end

select 
@w_ut_referencial            = ut_referencial,
@w_ut_signo                  = ut_signo,
@w_ut_factor                 = ut_factor,
@w_ut_reajuste_especial      = ut_reajuste_especial,
@w_ut_tipo_puntos            = ut_tipo_puntos,
@w_ut_fecha_pri_referencial  = ut_fecha_pri_referencial,
@w_ut_porcentaje             = ut_porcentaje,
@w_ut_porcentaje_efa         = ut_porcentaje_efa           ---EFECTIVA NEGOCIADA OR
from   ca_ultima_tasa_op with (nolock)
where  ut_operacion = @i_operacionca
and    ut_concepto  = @i_concepto_int

if @@rowcount = 0 
begin
 PRINT 'cambibc.sp Error Ejecutando busqueda de tasa BAse en ca_ultima_tasa_op'
 return  710281
     
end
 
if @w_ut_referencial like 'TLU%'
or @w_ut_referencial like 'TMM%'
begin
   PRINT 'cambibc.sp No hay  tasa en ca_ultima_tasa_op SOLUCION: Registrar un reajuste con fecha = a la fecha de la operacion' 
   return 722102
end

-- DATOS DE LOS INTERESES EN LAS CONDICIONES ACTUALES QUE PODRIAN SER TLU
select 
@w_ro_fpago          = ro_fpago,
@w_ro_num_dec        = ro_num_dec,
@w_por_efa_actual    = ro_porcentaje_efa,
@w_referencial_hoy   = ro_referencial
from   ca_rubro_op with (nolock)
where  ro_operacion  = @i_operacionca
and    ro_concepto   = @i_concepto_int


/*VALORES TASA NEGOCIADA POR EL CREDITO*/
select 
@w_ut_referencial     = ut_referencial,
@w_ut_signo           = ut_signo,
@w_ut_factor          = ut_factor,
@w_ut_tipo_puntos     = ut_tipo_puntos,
@w_ut_porcentaje      = ut_porcentaje,
@w_ut_porcentaje_efa  = ut_porcentaje_efa,
@w_ut_fecha_ref       = ut_fecha_pri_referencial    
from ca_ultima_tasa_op
where ut_operacion   = @i_operacionca
and   ut_concepto    = @i_concepto_int


/*VALORES TASA REFERENCIAL*/
select @w_max_fecha_tlu = max(vr_fecha_vig)
from   ca_valor_referencial with (nolock)
where  vr_tipo       = @i_param_ibc_mn
and    vr_fecha_vig <= @i_fecha_proceso

if @@rowcount = 0 return 722105

select @w_secuencial_tlu = max(vr_secuencial)
from   ca_valor_referencial with (nolock)
where  vr_tipo      = @i_param_ibc_mn
and    vr_fecha_vig = @w_max_fecha_tlu

if @@rowcount = 0 return 722106

select @w_valor_actual_tlu = vr_valor
from   ca_valor_referencial with (nolock)
where  vr_tipo       = @i_param_ibc_mn
and    vr_secuencial = @w_secuencial_tlu

if @@rowcount = 0 return 722107

---print 'cambibc.sp @w_ut_porcentaje_efa' + cast(@w_ut_porcentaje_efa as varchar(20))
---print 'cambibc.sp @w_ut_porcentaje' + cast(@w_ut_porcentaje as varchar(20))
---print 'cambibc.sp @w_valor_actual_tlu' + cast(@w_valor_actual_tlu as varchar(20)) + ' @i_param_ibc_mn ' + cast (@i_param_ibc_mn as varchar)

if @w_ut_porcentaje_efa is null or @w_ut_porcentaje_efa < 0 return 722103
if @w_ut_porcentaje is null or @w_ut_porcentaje < 0 return 722104
 
if @w_ut_porcentaje_efa  <=  @w_valor_actual_tlu -- SE USA LA PACTADA POR SER MENOR
begin
   ---print 'cambibc.sp entroooo UNO esta ok'
   select 
   @w_referencial_ajuste  = @w_ut_referencial,  --jbq
   @w_signo_ajuste        = @w_ut_signo,        --jbq
   @w_factor_ajuste       = @w_ut_factor,       --jbq
   @w_porcentaje_ajuste   = @w_ut_porcentaje_efa,
   @w_tipo_puntos_ajuste  = 'e',
   @w_porc_efa_final      = @w_ut_porcentaje_efa,
   @w_porcentaje_nom      = @w_ut_porcentaje
   
end else 
begin

   if @i_moneda in (@i_moneda_nacional, @i_moneda_uvr)
      select @w_referencial_ajuste = @i_param_ibc_mn
   else
      select @w_referencial_ajuste = @i_param_ibc_me
   
   ---print 'cambibc.sp entroooo DOS  QUEDARA LA TLU esta ok'
   if @w_ro_fpago = 'P'
      select @w_modalidad_d = 'V'
   else   
      select @w_modalidad_d = 'A'
      
   select 
   @w_signo_ajuste        = '+',
   @w_factor_ajuste       = 0,
   @w_porcentaje_ajuste   = @w_valor_actual_tlu,   --jbq
   @w_tipo_puntos_ajuste  = 'E',
   @w_porc_efa_final      = @w_valor_actual_tlu

  exec @w_error    =  sp_conversion_tasas_int
    @i_base_calculo   = @w_op_base_calculo,
    @i_dias_anio      = @w_op_dias_anio,
    @i_periodo_o      = 'A',
    @i_num_periodo_o  = 1, 
    @i_modalidad_o    = 'V',
    @i_tasa_o         = @w_valor_actual_tlu,
    @i_periodo_d      = @w_op_tdividendo,
    @i_num_periodo_d  = @w_op_periodo_int ,
    @i_modalidad_d    = @w_modalidad_d, 
    @i_num_dec        = @w_ro_num_dec,
    @o_tasa_d         = @w_porcentaje_nom output  -- NOMINAL DE TASA USURA

    if @w_error <> 0 
       return @w_error
        

end

---Redondear a 2 decimales por que hay unas tasa ya almacenadas
--con 2 decimales entonces simepre entrara a reajustar

select @w_porc_efa_final_comp = round(@w_porc_efa_final, 2)
select @w_por_efa_actual_comp = round(@w_por_efa_actual, 2)

---print 'cambibc.sp @w_porc_efa_final_comp: ' + cast( @w_porc_efa_final_comp  as varchar(20)) + '@w_por_efa_actual_comp  ' + cast(@w_por_efa_actual_comp as varchar(20))

if  abs(@w_porc_efa_final_comp - @w_por_efa_actual_comp) >= 0.0001 
begin  --- 2

   ---print 'cambibc.sp puesto antes de  sp_insertar_reajustes'+ cast(@w_referencial_ajuste as varchar(20)) + '@w_por_efa_actual ' + cast(@w_porcentaje_ajuste as varchar(20)) + '@i_param_ibc_mn' + CAST(@i_param_ibc_mn as varchar)
   IF @w_referencial_hoy IS NOT NULL
      select   @w_iden_ref  = substring(@w_referencial_hoy,1,3)

   
   if @w_referencial_ajuste <> ''
     select @w_porcentaje_ajuste = 0

    ---print 'bambbc.sp @w_iden_ref:  ' + CAST (@w_iden_ref as varchar)
    
     
---COMO ELCONTROL DE USURA RECUPERA UNA NUEVA TATASA QUE YA TENIA
---EL SISTEMA SIMPLEMTNE LE PONE LA QUE DEBE SER 
    select @w_recupera_tasa_inicial = 'N' 
	if @w_iden_ref  =  'TLU'
	begin  ---RECUPERA
	
       ---PRINT 'cambibc.sp entro a dejar la misma tasa inicial por que es la recuperada: ' + CAST (@w_iden_ref as varchar)	
       
	   select @w_recupera_tasa_inicial = 'S'
	   
	   select @w_di_vigente = di_dividendo
	   from ca_dividendo  
	   where di_operacion = @i_operacionca
	   and   di_estado = 1
	   
	   select @w_fec_tasas = isnull(max(ts_fecha),'01/01/1900')
	   from   ca_tasas with (nolock)
	   where  ts_operacion      = @i_operacionca
	   and    ts_dividendo      = @w_di_vigente
	   and    ts_concepto       = @i_concepto_int
	   and    ts_fecha         <= @i_fecha_proceso
	   
	   select @w_sec_tasas = isnull(max(ts_secuencial),-999)
	   from   ca_tasas with (nolock)
	   where  ts_operacion      = @i_operacionca
	   and    ts_dividendo      = @w_di_vigente
	   and    ts_concepto       = @i_concepto_int
	   and    ts_fecha          = @w_fec_tasas
	   
	   if not exists(select 1 from ca_tasas with (nolock)
	   where  ts_operacion      = @i_operacionca
	   and    ts_dividendo      = @w_di_vigente
	   and    ts_concepto       = @i_concepto_int
	   and    ts_porcentaje_efa = @w_porc_efa_final
	   and    ts_fecha          = @w_fec_tasas
	   and    ts_secuencial     = @w_sec_tasas)
	   begin ---3
			select  @w_ts_tasa_ref  = ltrim(rtrim(tv_nombre_tasa))
			from   ca_valor_det, ca_tasa_valor
			where  vd_tipo       = @w_referencial_ajuste
			and    vd_sector     = @w_op_sector
			and    vd_referencia = tv_nombre_tasa

		   select @w_fecha = max(vr_fecha_vig)
           from   ca_valor_referencial
           where  vr_tipo =  @w_ts_tasa_ref
           and    vr_fecha_vig  <= @w_ut_fecha_ref

 		    select @w_valor_tasa_ref = isnull(max(vr_valor),0)
	        from   ca_valor_referencial
	        where  vr_tipo    = @w_ts_tasa_ref
	        and    vr_secuencial = (select max(vr_secuencial)
	                               from ca_valor_referencial
	                               where vr_tipo     = @w_ts_tasa_ref
	                               and vr_fecha_vig  = @w_fecha)	      

	          exec @w_secuencial_reg =  sp_gen_sec
              @i_operacion  =  @i_operacionca
	   
		      insert into ca_tasas (
		      ts_operacion,      ts_dividendo,         ts_fecha,
		      ts_concepto,       ts_porcentaje,        ts_secuencial,
		      ts_porcentaje_efa, ts_referencial,       ts_signo,
		      ts_factor,         ts_valor_referencial, ts_fecha_referencial,
		      ts_tasa_ref )
		      values(
		      @i_operacionca,    isnull(@w_di_vigente,0),         @i_fecha_proceso,
		      @i_concepto_int,   isnull(@w_porcentaje_nom,0),     @w_secuencial_reg,
		      @w_porc_efa_final, @w_referencial_ajuste, @w_signo_ajuste,
		      @w_factor_ajuste,  @w_valor_tasa_ref ,    @w_ut_fecha_ref,
		      @w_ts_tasa_ref )
		      
		      if @@error <> 0 
		       begin
		          PRINT 'cambibc.sp saliopor error  @w_porcentaje_nom:  ' + CAST (@w_porcentaje_nom as varchar)
		          return 703118
		       end
	   end ---3
	   
	   -- ACTUALIZACION DE TASAS EN ca_rubro_op
	   update ca_rubro_op with (rowlock) set
	   ro_porcentaje           = @w_porcentaje_nom,
	   ro_porcentaje_efa       = @w_porc_efa_final,
	   ro_porcentaje_aux       = @w_porc_efa_final,
	   ro_referencial          = @w_referencial_ajuste,
	   ro_signo                = @w_signo_ajuste,
	   ro_factor               = @w_factor_ajuste,
	   ro_tipo_puntos          = isnull(@w_tipo_puntos_ajuste, ro_tipo_puntos)
	   where  ro_operacion = @i_operacionca
	   and    ro_concepto  = @i_concepto_int
	   
	   if @@error <> 0  return 710002
	   
	   ---VALIDAR SI ES NORMALIZACION Y TASA CERO PARA ENVIAR EL VALOR EN FACTOR
	   if @w_tr_tipo = 'M' and @w_referencial_ajuste = @w_TCERO
	   begin
	      select @w_factor_ajuste = @w_porc_efa_final
	   end
	      exec @w_error = sp_insertar_reajustes
		   @s_date            = @s_date,
		   @s_ofi             = 9000,
		   @s_user            = @s_user,
		   @s_term            = 'RECUP-TASA',
		   @i_banco           = @w_op_banco,
		   @i_especial        = @w_op_reajuste_especial,
		   @i_fecha_reajuste  = @i_fecha_proceso,
		   @i_concepto        = @i_concepto_int,
		   @i_referencial     = @w_referencial_ajuste,  --JCQ 03/04/2003
		   @i_signo           = @w_signo_ajuste,
		   @i_factor          = @w_factor_ajuste,       --JCQ 03/04/2003
		   @i_porcentaje      = @w_porcentaje_ajuste,
		   @i_desagio         = @w_tipo_puntos_ajuste
	   
	   if @w_error <> 0  
	   begin
	      PRINT 'Error Ejecutando sp_insertar_reajustes Recuperando tasa dede cambibc.sp : ' + cast ( @w_error as varchar)
    		 if @w_error <> 0  
			 begin
				  exec sp_errorlog 
				  @i_fecha     = @s_date,
				  @i_error     = @w_error,
				  @i_usuario   = @s_user,
				  @i_tran      = 7998,
				  @i_tran_name = 'sp_insertar_reajustes',
				  @i_cuenta    = @w_op_banco,
				  @i_rollback  = 'N'
		      
				  select @w_error = 0
			  end
	   end
   end   ---RECUPERA
   else
   begin ---1
      ---print 'cambibc.sp entro por este @w_referencial_ajuste ' + CAST ( @w_referencial_ajuste as varchar) +  ' @w_porcentaje_ajuste ' + CAST (@w_porcentaje_ajuste as varchar) +  ' @w_por_efa_actual: ' + CAST ( @w_por_efa_actual as varchar) + ' @w_valor_actual_tlu: ' + CAST (@w_valor_actual_tlu as varchar)
      ---VAlidar nuevamente con la TLU

       if @w_por_efa_actual >  @w_valor_actual_tlu
       begin    
	      exec @w_error = sp_insertar_reajustes
		   @s_date            = @s_date,
		   @s_ofi             = 9000,
		   @s_user            = @s_user,
		   @s_term            = 'CONTR-USUR',
		   @i_banco           = @w_op_banco,
		   @i_especial        = @w_op_reajuste_especial,
		   @i_fecha_reajuste  = @i_fecha_proceso,
		   @i_concepto        = @i_concepto_int,
		   @i_referencial     = @w_referencial_ajuste,  --JCQ 03/04/2003
		   @i_signo           = @w_signo_ajuste,
		   @i_factor          = @w_factor_ajuste,       --JCQ 03/04/2003
		   @i_porcentaje      = @w_porcentaje_ajuste,
		   @i_desagio         = @w_tipo_puntos_ajuste
		   
		   if @w_error <> 0  
		   begin
		      PRINT 'Error Ejecutando sp_insertar_reajustes por USURA dede cambibc.sp : ' + cast ( @w_error as varchar)
		      exec sp_errorlog 
		      @i_fecha     = @s_date,
		      @i_error     = @w_error,
		      @i_usuario   = @s_user,
		      @i_tran      = 7998,
		      @i_tran_name = 'sp_insertar_reajustes',
		      @i_cuenta    = @w_op_banco,
		      @i_rollback  = 'N'
		      
		      select @w_error = 0
		   end
       end
   end  ----1
end --- 2

return 0
go

