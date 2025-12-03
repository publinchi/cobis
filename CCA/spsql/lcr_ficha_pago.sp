
USE cob_cartera
GO
/* ********************************************************************* */
/*      Archivo:                lcr_consultar_pag.sp                     */
/*      Stored procedure:       lcr_consultar_pag                        */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Disenado por:           Andy Gonzalez                            */
/*      Fecha de escritura:     01/10/2018                               */
/* ********************************************************************* */
/*                              IMPORTANTE                               */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      "MACOSA", representantes exclusivos para el Ecuador de la        */
/*      "NCR CORPORATION".                                               */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de sus          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de MACOSA o su representante.              */
/* ********************************************************************* */
/*                              PROPOSITO                                */
/*   Mantenimiento tala de referencias para LCR                          */
/* ********************************************************************* */


if exists (select 1 from sysobjects where name = 'sp_lcr_ficha_pago')
   drop proc sp_lcr_ficha_pago
go
create proc sp_lcr_ficha_pago

@s_user            login        = 'admuser',--1
@s_term            varchar(32)  = 'consola',--2
@i_opcion          char(2),                 --3
@i_banco           varchar(32)  = null,     --4
@i_tipo            tinyint      = 1,        --5 PDF(1), email(2)         
@i_secuencial      int          = null,     --6
@i_operacionca     int          = null,     --7

@o_banco           varchar(32)  = null   out ,
@o_nombre          varchar(255) = null   out ,    
@o_fecha_pago      datetime     = null   out ,
@o_pago_total      money        = null   out ,
@o_cuota_minima    money        = null   out ,
@o_institucion     descripcion  = null   out ,
@o_referencia      varchar(255) = null   out , 
@o_convenio        varchar(255) = null   out  
as


declare
@w_sp_name            varchar(32),
@w_operacionca 		  int,
@w_fecha_liq          datetime,
@w_fecha_ven          datetime,
@w_moneda             smallint,
@w_oficina            smallint,
@w_return             int,
@w_grupo              int,
@w_tg_tramite         int,
@w_ref_santander      varchar(64),
@w_secuencial         int,
@w_precancela_dias    int,
@w_convenio           varchar(32),
@w_nombre_banco       varchar(32),
@w_mail               varchar(64),
@w_estado             varchar(1),
@w_tramite            int,
@w_id_corresp         int,
@w_corresponsal       varchar(255),
@w_descripcion_corresp   varchar(255),
@w_sp_corresponsal     varchar(255),
@w_referencia          varchar(255),
@w_cliente             int,
@w_error               int ,
@w_est_vigente         int ,
@w_est_vencida         int ,
@w_fecha_proceso       datetime,
@w_monto_op            money, 
@w_num_dec             int,
@w_param_umbral        money ,
@w_saldo_capital       money

select @w_sp_name = 'sp_lcr_ficha_pago'


--PARAMETRO UMBRAL
select @w_param_umbral = pa_money
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'LCRUMB'
and    pa_producto = 'CCA'

select @w_param_umbral = isnull(@w_param_umbral,100)


if @i_opcion = 'I' begin

   --Fecha proceso
   select @w_fecha_proceso =  fp_fecha
   from cobis..ba_fecha_proceso
   
   --estados cca
   exec @w_error        = sp_estados_cca
   @o_est_vigente  = @w_est_vigente out,
   @o_est_vencido  = @w_est_vencida out
   
   select
   @w_operacionca = op_operacion,
   @w_fecha_liq   = op_fecha_liq,
   @w_moneda      = op_moneda,
   @w_oficina     = op_oficina,
   @w_cliente     = op_cliente,
   @o_nombre      = op_nombre,           --NOMBRE DEL CLIENTE 
   @o_banco       = op_banco,            --NUMERO DEL CREDITO         --MONTO DE LA LINEA 
   @o_pago_total  = op_monto_aprobado    --PAGO PARA NO GENERAR INTERESES 
   from cob_cartera..ca_operacion
   where op_estado  not in (3,0)
   and op_toperacion = 'REVOLVENTE'
   and op_banco      = @i_banco
   order by op_operacion
   
   if (@@rowcount = 0) begin
     select @w_return = 70121
     goto ERROR
   end
   
   -- CONTROL DEL NUMERO DE DECIMALES
   exec @w_error = sp_decimales
   @i_moneda       = @w_moneda,
   @o_decimales    = @w_num_dec out
   
   --PAGO TOTAL
   select @o_pago_total = isnull(sum(am_acumulado - am_pagado),0)
   from cob_cartera..ca_amortizacion
   where am_operacion = @w_operacionca
   
   if @o_pago_total < 0 select @o_pago_total = 0
   
   --FECHA DE PROXIMO PAGO 
   
   select @o_fecha_pago = max(di_fecha_ven) 
   from ca_dividendo    
   where  di_operacion  = @w_operacionca
   and    di_estado	in (@w_est_vigente, @w_est_vencida)
   
   if (@@rowcount = 0) begin
     select @w_return = 70121
     goto ERROR
   end
   
   --PAGO MINIMO 
   select @o_cuota_minima = isnull(sum(am_cuota - am_pagado),0)
   from ca_amortizacion, ca_dividendo
   where am_operacion = @w_operacionca
   and am_operacion   = di_operacion
   and am_dividendo   = di_dividendo
   and (di_estado     = @w_est_vencida or (di_estado = @w_est_vigente and di_fecha_ven = @w_fecha_proceso ))
 	
   select @o_fecha_pago  = @w_fecha_proceso 
   
   if @o_cuota_minima = 0 begin
   	
      exec @w_error  = cob_cartera..sp_lcr_calc_corte
      @i_operacionca   = @w_operacionca,
      @i_fecha_proceso = @w_fecha_proceso,
      @o_fecha_corte   = @o_fecha_pago out
  		
      if @w_error <> 0  goto ERROR   
	  	
	   --PAGO MINIMO 
      select @w_saldo_capital = isnull(sum(am_cuota - am_pagado),0) 
      from ca_amortizacion
      where am_operacion = @w_operacionca
      and am_concepto = 'CAP'
      
      if @w_saldo_capital < @w_param_umbral select @o_cuota_minima  = @w_param_umbral 
		else begin 
			select @o_cuota_minima =  round(@w_saldo_capital/3, 0) 
			if @o_cuota_minima < @w_param_umbral select @o_cuota_minima = @w_param_umbral
		end
      
   end  
 

 
   --GENERACION DE LAS REFERENCIAS 
   
   exec @w_secuencial = cob_cartera..sp_gen_sec
   @i_operacion       = @w_operacionca
   
   select top 1 @w_mail = di_descripcion
   from cobis..cl_direccion
   where di_tipo = 'CE'
   and di_ente = @w_cliente
   order by di_direccion
   
   
   
   if not exists (select 1 from ca_lcr_referencia where lr_operacion = @w_operacionca and lr_cliente = @w_cliente) begin
   
   
     exec @w_secuencial = cob_cartera..sp_gen_sec
     @i_operacion       = @w_operacionca		    
     
     insert into ca_lcr_referencia (
     lr_secuencial,     lr_monto_op,     lr_cuota_minima, 
     lr_pago_total,     lr_operacion,    lr_banco,          
     lr_cliente,        lr_fecha_pro,    lr_fecha_corte,    
     lr_user,           lr_term,         lr_estado,		 
     lr_fecha_liq,	     lr_nombre_cl,	  lr_mail)
     values(
     @w_secuencial,     @o_pago_total ,   @o_cuota_minima,
     @o_pago_total,     @w_operacionca,   @o_banco,
     @w_cliente ,       @w_fecha_proceso, @o_fecha_pago,     
     @s_user    ,       @s_term,          'I',               
     @w_fecha_liq ,     @o_nombre,        @w_mail)
     
     
     if @@error != 0  begin
   	 select @w_return = 70180
   	 goto ERROR
     end	   
     
   end
   else begin
     
     select @w_secuencial = lr_secuencial 
     from  ca_lcr_referencia 
     where lr_operacion = @w_operacionca 
     and   lr_cliente   = @w_cliente
     
   
     update ca_lcr_referencia set 
     lr_monto_op      = @w_monto_op,
     lr_fecha_pro     = @w_fecha_proceso,
     lr_fecha_liq     = @w_fecha_liq,
     lr_mail          = @w_mail,
     lr_pago_total    = @o_pago_total,
	 lr_cuota_minima  = @o_cuota_minima,
	 lr_fecha_corte   = @o_fecha_pago
     where lr_operacion = @w_operacionca 
     and   lr_cliente   = @w_cliente
     
     delete ca_lcr_referencia_det  
     where lrd_secuencial = @w_secuencial
     and   lrd_operacion  = @w_operacionca
     and   lrd_cliente    = @w_cliente
    
   end 
   
   
   select @w_id_corresp = 0
   
   
   while 1 = 1 begin 
   
     select top 1
     @w_id_corresp          = co_id,   
     @w_corresponsal        = co_nombre,
     @w_descripcion_corresp = co_descripcion,
     @w_sp_corresponsal     = co_sp_generacion_ref
     from  ca_corresponsal 
     where co_id            > @w_id_corresp
     and   co_estado        = 'A'
     order by co_id asc
     
     if @@rowcount = 0 break 
	 
	 
	 
	 select  @w_convenio = ctr_convenio
	 from ca_corresponsal_tipo_ref
	 where ctr_tipo_cobis = 'PI'
	 and ctr_co_id =  @w_id_corresp
	 
     if @@rowcount = 0 break	 
     
     exec @w_return    = @w_sp_corresponsal
     @i_tipo_tran      = 'PI',
     @i_id_referencia  = @w_operacionca ,
     @i_monto          = @o_cuota_minima,
     @i_monto_desde    = null,
     @i_monto_hasta    = null,
     @i_fecha_lim_pago = @w_fecha_ven,	  
     @o_referencia     = @w_referencia out
     
     
     if @w_return <> 0 begin           
     GOTO ERROR
     end
     
     insert into ca_lcr_referencia_det 
     (lrd_secuencial, lrd_operacion,   lrd_cliente, lrd_corresponsal, lrd_institucion,         lrd_referencia, lrd_convenio)
     values
     (@w_secuencial,  @w_operacionca,  @w_cliente,    @w_corresponsal,  isnull(@w_descripcion_corresp,''), isnull(@w_referencia,''),   isnull(@w_convenio, ''))
     
   end   
   
   select 
   @o_referencia  = @w_referencia,
   @o_convenio    = @w_convenio,
   @o_institucion = @w_corresponsal
   
   if @i_tipo = 1   select @w_estado = 'X'
     else select @w_estado = 'P'
   
   if exists (select 1 from cob_cartera..ca_ns_lcr_referencia 
   		 where nlr_codigo =  @w_secuencial 
   		  and nlr_operacion = @w_operacionca) begin
   
     update cob_cartera..ca_ns_lcr_referencia set
     nlr_estado = @w_estado
     where nlr_codigo = @w_secuencial 
     and nlr_operacion = @w_operacionca	 
     
   end
   else
     insert into cob_cartera..ca_ns_lcr_referencia (nlr_codigo, nlr_operacion, nlr_estado)
     values(@w_secuencial, @w_operacionca, @w_estado)	
   
   
   
   select 
   'SECUENCIAL'        = lr_secuencial, 
   'FECHA_PROX_PAGO'   = convert(varchar,datepart(dd,lr_fecha_corte))+'-'+
                         (case datepart(mm,lr_fecha_corte) 
                         when  '01' then 'Ene'
                         when  '02' then 'Feb'
                         when  '03' then 'Mar'
                         when  '04' then 'Abr'
                         when  '05' then 'May'
                         when  '06' then 'Jun'
                         when  '07' then 'Jul'
                         when  '08' then 'Ago'
                         when  '09' then 'Sep'
                         when  '10' then 'Oct'
                         when  '11' then 'Nov'
                         when  '12' then 'Dic'
                         end) +'-'+ convert(varchar,datepart(yyyy,lr_fecha_corte)),
   'PAGO_MINIMO'       = lr_cuota_minima,
   'PAGO_SIN_INTERES'  = lr_pago_total, 
   'CREDITO'           = lr_banco, 
   'NOMBRE_DEL_CLIENTE'=lr_nombre_cl 
   from dbo.ca_lcr_referencia
   where lr_secuencial = @w_secuencial  
   and lr_operacion    =  @w_operacionca  
   
   
   select 
   'INSTITUCION'= isnull(lrd_institucion , ''), 
   'REFERENCIA' = isnull(lrd_referencia  , ''),
   'CONVENIO'   = isnull(lrd_convenio    , '')
   from dbo.ca_lcr_referencia_det
   where lrd_secuencial = @w_secuencial  
   and   lrd_operacion  = @w_operacionca  
   
end

if @i_opcion = 'G' begin
   select 
   'SECUENCIAL'        = lr_secuencial, 
   'FECHA_PROX_PAGO'   = convert(varchar,datepart(dd,lr_fecha_corte))+'-'+
                         (case datepart(mm,lr_fecha_corte) 
                         when  '01' then 'Ene'
                         when  '02' then 'Feb'
                         when  '03' then 'Mar'
                         when  '04' then 'Abr'
                         when  '05' then 'May'
                         when  '06' then 'Jun'
                         when  '07' then 'Jul'
                         when  '08' then 'Ago'
                         when  '09' then 'Sep'
                         when  '10' then 'Oct'
                         when  '11' then 'Nov'
                         when  '12' then 'Dic'
                         end) +'-'+ convert(varchar,datepart(yyyy,lr_fecha_corte)),
   'PAGO_MINIMO'       = lr_cuota_minima,
   'PAGO_SIN_INTERES'  = lr_pago_total, 
   'CREDITO'           = lr_banco, 
   'NOMBRE_DEL_CLIENTE'= lr_nombre_cl,
   'MAIL'              = lr_mail,
   'CLIENTE'           = lr_cliente
   from dbo.ca_lcr_referencia
   where lr_secuencial = @i_secuencial  
   and   lr_operacion  = @i_operacionca  
   
   
   select 
   'institucion' = isnull(lrd_institucion  ,''), 
   'referencia'  = isnull(lrd_referencia   ,''),
   'convenio'    = isnull(lrd_convenio     ,''), 
   'cliente'     = lrd_cliente
   from dbo.ca_lcr_referencia_det
   where lrd_secuencial = @i_secuencial  
   and   lrd_operacion  = @i_operacionca

end 
  
RETURN 0

ERROR:
set transaction isolation level read uncommitted

exec cobis..sp_cerror
	@t_from = @w_sp_name,
	@i_num  = @w_return

return @w_return

go


