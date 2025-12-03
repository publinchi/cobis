/************************************************************************/
/*  Archivo:                for_si001.sp                                */
/*  Stored procedure:       sp_for_si001                                */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_for_si001')
    drop proc sp_for_si001
go

create proc sp_for_si001(
	@i_fecha		datetime
)
as
declare
	@w_banco			cuenta,
	@w_fecha_ult_pag_cap		datetime,	
	@w_fecha_ult_pag_int		datetime,
        @w_max_sec              	int,
        @w_operacion            	int,
        @w_mensaje              	descripcion,
	@w_cotizacion			float,
	@w_pcalificacion_e		int,
	@w_dc_tipo_id           	char(2),
	@w_dc_iden_N 			numero,
	@w_dc_iden   			numero,
	@w_dc_digito 			char(1),
	@w_digito    			char(1),
	@w_dc_tipo_compania 		varchar(10),
	@w_compania 			varchar(10),
	@w_iden     			numero,
	@w_li_monto 			money,
	@w_op_tdividendo 		char(1),
	@w_ro_fpago             	char(1),
	@w_ro_porcentaje        	float,
	@w_modalidad            	char(1),
	@w_ro_referencial       	catalogo,
	@w_tipo_tasa            	char(1),
	@w_provision_cap		money,
	@w_provision_int 		money,
	@w_provision_otros		money,
	@w_saldo_mora			money,
	@w_saldo_correccion		money,
	@w_saldo_int_causado		money,
	@w_gp_garantia			varchar(64),
	@w_cn_situacion			catalogo,
	@w_situacion			catalogo,
	@w_producto			tinyint,
	@w_dg_gar_est_deu		char(1),
	@w_po_fvigencia_fin		datetime,
	@w_fecha_insp			datetime,
        @w_op_numero_reest      	tinyint,
	@w_op_tramite           	int,
	@w_ro_signo             	char(1),
	@w_ro_factor 			float,
        @w_calificacion_e       	int,
        @w_dc_nombre            	descripcion,
	@w_dc_actividad			varchar(10),
	@w_dc_cliente			int,
	@w_info_gar			catalogo,
	@w_valor_avaluo			money,
	@w_cu_valor_inicial		money,
	@w_dg_monto_distr_ini_a		money,
	@w_dg_monto_distr_ini_b		money,
	@w_estado			catalogo,
	@w_cu_porcentaje_cobertura	float,
	@w_dg_porc_resp_a		float,
	@w_dg_porc_resp_b		float,
	@w_cu_valor_actual		money,
	@w_dg_valor_resp_a		money,
	@w_dg_valor_resp_b		money,

	/** VARIABLES DEL CURSOR **/
	@w_fo_banco			cuenta,  		
	@w_fo_producto			tinyint,			
	@w_fo_pcalficacion_e		int,
	@w_fo_dias_mora			smallint,    
	@w_fo_clase			tinyint,	
	@w_fo_nit			numero,		
	@w_fo_digito			numero,
	@w_fo_tipo_id			numero,		
	@w_fo_nombre			descripcion,	    
	@w_fo_tcliente			catalogo,	
	@w_fo_ciiu			catalogo, 		
	@w_fo_cliente_cobis		int,		
	@w_fo_mod_pag_int		char(1),	
	@w_fo_ttasa			catalogo,	    
	@w_fo_saldo_int_cau		money,
	@w_fo_saldo_int_mora_m		money,	 
	@w_fo_concordato		catalogo,		
	@w_fo_inf_gar			catalogo,		
	@w_fo_valor_avaluo		money, 
	@w_fo_estado			catalogo,
        @w_fo_estado_contable           varchar(10)
     




create table #cr_formato_sib
(fo_clase                      tinyint,         
fo_calificacion                char(1),     
fo_pcalficacion_e              int,             
fo_banco                       cuenta,          
fo_producto                    tinyint,         
fo_cliente_cobis               int,             
fo_tipo_id                     numero,          
fo_nit                         numero,          
fo_digito                      numero,          
fo_nombre                      descripcion,     
fo_oficina                     smallint,        
fo_linea                       cuenta,          
fo_tcliente                    catalogo,        
fo_tvinculacion                descripcion,     
fo_fecha_desembolso            datetime,        
fo_fecha_vencimiento           datetime,       
fo_plazo                       smallint,       
fo_per_cap                     char(1),    
fo_mod_pag_cap                 char(1),    
fo_per_int                     char(1),    
fo_mod_pag_int                 char(1),    
fo_ttasa                       catalogo,       
fo_base                        catalogo,       
fo_spread                      float,          
fo_tasa_cte                    float,         
fo_tasa_mora                   float,         
fo_monto_des                   money,         
fo_saldo_cap                   money,         
fo_fecha_ult_pag_cap           datetime,      
fo_fecha_ult_pag_int           datetime,      
fo_fecha_ini_mora              datetime,      
fo_dias_mora                   smallint,      
fo_prov_cap                    money,         
fo_saldo_int                   money,     
fo_saldo_int_cau               money,     
fo_saldo_corr_mon              money,     
fo_saldo_int_mora              money,     
fo_saldo_int_mora_m            money,     
fo_int_capitalizado            catalogo,  
fo_castigado                   catalogo,  
fo_saldo_otros                 money,     
fo_int_reest                   money,     
fo_prov_int                    money,     
fo_prov_otros                  money,     
fo_int_sus                     money,     
fo_cupo                        cuenta,    
fo_tipo_gar                    tinyint,   
fo_val_gar_hip                 money,     
fo_proc_cub_hip                float,     
fo_val_cub_hip                 money,     
fo_val_gar_pre                 money,           
fo_proc_cub_pre                float,           
fo_val_cub_pre                 money,           
fo_val_gar_otr                 money,           
fo_proc_cub_otr                float,           
fo_val_cub_otr                 money,           
fo_valor_avaluo                money,           
fo_fecha_avaluo                datetime,        
fo_fecha_ven_gar               datetime,        
fo_inf_gar                     catalogo,        
fo_nun_suspen                  catalogo,        
fo_reestruturada               catalogo,        
fo_num_reest                   tinyint,         
fo_reest_ley                   catalogo,        
fo_reest_ext                   catalogo,        
fo_concordato                  catalogo,        
fo_ciiu                        catalogo,        
fo_estado                      catalogo,        
fo_nom_oficina                 descripcion,     
fo_num_garantia                descripcion,     
fo_moneda                      tinyint,         
fo_clase_gar                   catalogo,
fo_estado_contable             catalogo        
)


/**** CREACION DE INDICES PARA #cr_formato_sib ***/
/*************************************************/
CREATE UNIQUE NONCLUSTERED INDEX cr_formato_sib_1 on #cr_formato_sib (fo_producto, fo_banco)
CREATE NONCLUSTERED INDEX cr_formato_sib_2 on #cr_formato_sib (fo_cliente_cobis)
CREATE NONCLUSTERED INDEX cr_formato_sib_3 on #cr_formato_sib (fo_clase)




/** SELECCION DE LA COTIZACION DEL 1er DIA DEL SIGUIENTE MES **/
/************************************************************/
select @w_cotizacion  = 0

select @w_cotizacion = convert(float,ct_valor)
from   cob_conta..cb_cotizacion
where  ct_moneda	= 2 --UVR
and    ct_fecha	= convert(datetime,'01'+substring(convert(varchar(10),dateadd(mm,1,@i_fecha),103),3,8),103)



/** INSERCION DE REGISTROS NO CALCULADOS **/
/******************************************/
insert into #cr_formato_sib(
fo_clase,					fo_calificacion,		
fo_pcalficacion_e,				fo_banco,					
fo_producto,					fo_cliente_cobis,
fo_nit,						fo_digito,			
fo_nombre,					fo_tipo_id,					
fo_oficina,					fo_linea,		
fo_tcliente,					fo_tvinculacion,		
fo_fecha_desembolso,				fo_fecha_vencimiento,				
fo_plazo,					fo_per_cap,		
fo_mod_pag_cap,					fo_per_int,			
fo_mod_pag_int,					fo_ttasa,					
fo_base,					fo_spread,		
fo_tasa_cte,					fo_tasa_mora,			
fo_monto_des,					fo_saldo_cap,					
fo_fecha_ult_pag_cap,				fo_fecha_ult_pag_int,	
fo_fecha_ini_mora,				fo_dias_mora,			
fo_prov_cap,					fo_saldo_int,					
fo_saldo_int_cau,				fo_saldo_corr_mon,	
fo_saldo_int_mora,				fo_saldo_int_mora_m,		
fo_int_capitalizado,				fo_castigado,					
fo_saldo_otros,					fo_int_reest,		
fo_prov_int,					fo_prov_otros,			
fo_int_sus,					fo_cupo,					
fo_tipo_gar,					fo_val_gar_hip,					
fo_proc_cub_hip,				fo_val_cub_hip,
fo_val_gar_pre,					fo_proc_cub_pre,		
fo_val_cub_pre,					fo_val_gar_otr,					
fo_proc_cub_otr,				fo_val_cub_otr,
fo_valor_avaluo,				fo_fecha_avaluo,		
fo_fecha_ven_gar,				fo_inf_gar,					
fo_nun_suspen,					fo_reestruturada,
fo_num_reest,					fo_reest_ley,			
fo_reest_ext,					fo_concordato,					
fo_ciiu,					fo_estado,
fo_nom_oficina,					fo_num_garantia,		
fo_moneda,					fo_clase_gar,					
fo_estado_contable	
)


select	
convert(tinyint,do_clase_cartera),		do_calificacion,			
0,  						do_numero_operacion_banco,			
do_codigo_producto,				do_codigo_cliente,
'',						'',					
'',						'',						
do_oficina,					do_tipo_operacion,
'2',						'N',					
convert(varchar(10),do_fecha_concesion,111),	convert(varchar(10),do_fecha_vencimiento,111),	
isnull(round((do_plazo_dias/30),0),0),		'',	
'',						'',						
'',						'',						
'',						0,						
isnull(do_tasa,0),				0,						

case do_moneda					
when 0 then do_monto				
else do_monto*@w_cotizacion 			
end,						

case do_moneda
when 0 then do_saldo_cap
else do_saldo_cap*@w_cotizacion
end,

isnull(convert(varchar(10),do_fecha_pago,111),'01/01/1900'),    isnull(convert(varchar(10),do_fecha_pago,111),'01/01/1900'),
isnull(convert(varchar(10),do_fecha_vto_div,111),'01/01/1900'), isnull(do_dias_vto_div,0), 			

0,						case do_moneda					
						when 0 then do_saldo_int
						else do_saldo_int*@w_cotizacion 
						end,	
										
0,						0,						


case do_moneda					
when 0 then do_valor_mora
else do_valor_mora*@w_cotizacion 
end,						0,
						
'2',						'2',

case do_moneda						
when 0 then do_saldo_otros
else do_saldo_otros*@w_cotizacion 
end,						0,

					
0,						0,

case do_moneda					
when 0 then do_saldo_int_contingente
else do_saldo_int_contingente*@w_cotizacion 
end,						'0',


case do_tipo_garantias				
when 'O' then 2
else 1
end,						0,
				

0,						0,	
0,						0,
0,						0,
0,						0,
2,						'01/01/1900',					

'01/01/1900',					'2',						

'0',						case do_reestructuracion			
						when 'S' then '1'				
						else '2'					
						end,							


case do_reestructuracion			
when 'S' then isnull(do_num_reest,1)
else 0
end,						'2',	

'2',						'2',		
				
'',						case do_estado_cartera				
						when 1 then 'VIGENTE'				
						when 2 then 'VENCIDO'
						when 3 then 'CANCELADO'
						when 4 then 'CASTIGADO'
						when 6 then 'ANULADO'
						when 9 then 'SUSPENSO'
						end,

(select of_nombre from cobis..cl_oficina	
where of_oficina = X.do_oficina),		'',	

do_moneda,					do_tipo_garantias,				

convert(varchar(10),do_estado_contable)

from	cr_dato_operacion X
where	do_tipo_reg		= 'M'
and	do_codigo_producto	> 0
and	do_numero_operacion	> 0
and     do_fecha		= @i_fecha    --No INDEX


/*** CURSOR ***/
/**************/

declare cur_operacion cursor for
select 	fo_banco,  		fo_producto,			fo_pcalficacion_e,	fo_dias_mora,	fo_clase,	
	fo_nit,			fo_digito,			fo_tipo_id,		fo_nombre,	fo_tcliente,
	fo_ciiu, 		fo_cliente_cobis,		fo_mod_pag_int,		fo_ttasa,	fo_saldo_int_cau,
	fo_saldo_int_mora_m, 	fo_concordato,			fo_inf_gar,		fo_valor_avaluo,fo_estado,
        fo_estado_contable
from #cr_formato_sib
order by fo_banco

open cur_operacion
fetch cur_operacion into 
	@w_fo_banco,  		@w_fo_producto,			@w_fo_pcalficacion_e,	@w_fo_dias_mora,    @w_fo_clase,	
	@w_fo_nit,		@w_fo_digito,			@w_fo_tipo_id,		@w_fo_nombre,	    @w_fo_tcliente,
	@w_fo_ciiu, 		@w_fo_cliente_cobis,		@w_fo_mod_pag_int,	@w_fo_ttasa,	    @w_fo_saldo_int_cau,
	@w_fo_saldo_int_mora_m, @w_fo_concordato,		@w_fo_inf_gar,		@w_fo_valor_avaluo, @w_fo_estado,
        @w_fo_estado_contable
while @@fetch_status = 0
begin

   if @@fetch_status = -1 
      return  70899 




   if @w_producto = 7
   begin

      /** ACTUALIZACION CR_FORMATO_SIB fo_per_cap, fo_mod_pag_cap,fo_per_int,fo_mod_pag_int,fo_ttasa, fo_base, fo_spread, fo_num_reest,fo_tasa_mora **/
      /***********************************************************************************************************************************************/
      select @w_operacion       = op_operacion,
             @w_op_tdividendo   = op_tdividendo,
             @w_op_numero_reest = isnull(op_numero_reest,0),
             @w_op_tramite      = op_tramite
      from cob_cartera..ca_operacion
      where op_banco = @w_fo_banco

      select @w_ro_fpago       = ro_fpago,
             @w_ro_referencial = ro_referencial,
             @w_ro_signo       = ro_signo,
             @w_ro_factor      = ro_factor
      from cob_cartera..ca_rubro_op 
      where ro_operacion = @w_operacion
      and   ro_concepto in ('INT','INTANT')

      select @w_ro_porcentaje = ro_porcentaje
      from cob_cartera..ca_rubro_op 
      where ro_operacion = @w_operacion
      and   ro_concepto  = 'IMO'

      if @w_ro_fpago = 'P'
         select @w_modalidad = 'V'
      else
         select @w_modalidad = 'A'


      if @w_ro_referencial = 'TFIJA'
         select @w_tipo_tasa = '1'
      else
         select @w_tipo_tasa = '2'


      update  #cr_formato_sib
      set  fo_per_cap	     = @w_op_tdividendo,  
	   fo_mod_pag_cap    = 'V',
   	   fo_per_int	     = @w_op_tdividendo, 
	   fo_mod_pag_int    = @w_modalidad,
	   fo_ttasa          = @w_tipo_tasa,
	   fo_base	     = @w_ro_referencial,
	   fo_spread         = @w_ro_factor,
	   fo_num_reest      = isnull(@w_op_numero_reest,0),
           fo_tasa_mora      = round(@w_ro_porcentaje,2)
      where fo_producto      = @w_fo_producto
      and   fo_banco         = @w_fo_banco
      and   fo_cliente_cobis = @w_fo_cliente_cobis



      /** ACTUALIZACION CR_FORMATO_SIB fo_saldo_int_cau,fo_saldo_corr_mon,fo_saldo_int_mora_m **/
      /*****************************************************************************************/
      select @w_saldo_int_causado = isnull(sum(dtr_monto_mn),0)
      from   cob_cartera..ca_transaccion,cob_cartera..ca_det_trn 
      where  tr_operacion	 	= dtr_operacion
      and    tr_secuencial    		= dtr_secuencial
      and    tr_banco	 		= @w_fo_banco
      and    tr_estado	 		= 'CON' 
      and    dtr_concepto	 	= 'INT'
      and    tr_tran		 	= 'PRV'
      and    datepart(mm,tr_fecha_ref)  = datepart(mm,@i_fecha) 
      and    datepart(yy,tr_fecha_ref)  = datepart(yy,@i_fecha)
   
      select @w_saldo_mora = isnull(sum(dtr_monto_mn),0)
      from   cob_cartera..ca_transaccion,cob_cartera..ca_det_trn 
      where  tr_operacion	 	= dtr_operacion
      and    tr_secuencial    		= dtr_secuencial
      and    tr_banco	 		= @w_fo_banco
      and    tr_estado	 		= 'CON' 
      and    dtr_concepto	 	= 'IMO'
      and    tr_tran		 	= 'PRV'
      and    datepart(mm,tr_fecha_ref)  = datepart(mm,@i_fecha) 
      and    datepart(yy,tr_fecha_ref)  = datepart(yy,@i_fecha)

      select @w_saldo_correccion = isnull(sum(dtr_monto_mn),0)
      from   cob_cartera..ca_transaccion,cob_cartera..ca_det_trn 
      where  tr_operacion	 	= dtr_operacion
      and    tr_secuencial    		= dtr_secuencial
      and    tr_banco	 		= @w_fo_banco
      and    tr_estado	 		= 'CON' 
      and    tr_tran	 		= 'CMO'
      and    datepart(mm,tr_fecha_ref)  = datepart(mm,@i_fecha) 
      and    datepart(yy,tr_fecha_ref)  = datepart(yy,@i_fecha)

      update  #cr_formato_sib
      set   fo_saldo_int_cau    = @w_saldo_int_causado,
            fo_saldo_int_mora_m = @w_saldo_mora,	
            fo_saldo_corr_mon   = @w_saldo_correccion
      where fo_producto         = @w_fo_producto
      and   fo_banco            = @w_fo_banco
      and   fo_cliente_cobis    = @w_fo_cliente_cobis


      set rowcount 1

 
      /** MAXIMO SECUENCIAL DE PAGO DE CAPITAL **/
      /******************************************/
      select @w_max_sec = 0

      select @w_max_sec = max(ar_secuencial)
      from   cob_cartera..ca_abono_rubro
      where  ar_operacion = @w_operacion
      and    ar_concepto  = 'CAP'

      /** ULTIMA FECHA DE PAGO DE CAPITAL **/
      /*************************************/
      select @w_fecha_ult_pag_cap = null

      select @w_fecha_ult_pag_cap = ab_fecha_pag
      from   cob_cartera..ca_abono_rubro,cob_cartera..ca_abono
      where  ar_operacion  = @w_operacion
      and    ar_secuencial = @w_max_sec
      and    ar_concepto   = 'CAP'
      and    ar_operacion  = ab_operacion
      and    ar_secuencial = ab_secuencial_pag


      /** MAXIMO SECUENCIAL DE PAGO DE INTERES **/
      select @w_max_sec = 0

      select @w_max_sec = max(ar_secuencial)
      from   cob_cartera..ca_abono_rubro
      where  ar_operacion = @w_operacion
      and    ar_concepto  = 'INT'

      /** ULTIMA FECHA DE PAGO INTERES **/
      /**********************************/

      select @w_fecha_ult_pag_int = null

      select @w_fecha_ult_pag_int = ab_fecha_pag
      from   cob_cartera..ca_abono_rubro,cob_cartera..ca_abono
      where  ar_operacion  = @w_operacion
      and    ar_secuencial = @w_max_sec
      and    ar_concepto   = 'INT'
      and    ar_operacion  = ab_operacion
      and    ar_secuencial = ab_secuencial_pag

      set rowcount 0 

      /** ACTUALIZACION CAMPOS DE FECHA ULTIMO PAGO DE CAPITAL Y DE INTERES **/
      /***********************************************************************/
      update #cr_formato_sib
      set    fo_fecha_ult_pag_int = convert(varchar(10),@w_fecha_ult_pag_int,111),
	     fo_fecha_ult_pag_cap = convert(varchar(10),@w_fecha_ult_pag_cap,111)
      where fo_producto      = @w_fo_producto
      and   fo_banco         = @w_fo_banco
      and   fo_cliente_cobis = @w_fo_cliente_cobis
   end



   /** ACTUALIZACION CR_FORMATO_SIB FO_PCALIFICACION_E **/
   /*****************************************************/
   select @w_pcalificacion_e = isnull(round(((@w_fo_dias_mora) - pc_desde*30),0) ,0)
   from   cr_param_calif
   where  pc_clase	= convert(varchar(1),@w_fo_clase)
   and    pc_calificacion = 'E'


   if @w_pcalificacion_e <= 0 
      select @w_calificacion_e = 0
   else
      select @w_calificacion_e = @w_pcalificacion_e

   update #cr_formato_sib
   set    fo_pcalficacion_e = @w_pcalificacion_e
   where fo_producto      = @w_fo_producto
   and   fo_banco         = @w_fo_banco
   and   fo_cliente_cobis = @w_fo_cliente_cobis




   /** ACTUALIZACION CR_FORMATO_SIB fo_nit,fo_digito,fo_tipo_id,fo_nombre,co_tcliente,fo_ciiu **/
   /********************************************************************************************/
   select @w_dc_tipo_id 	   = dc_tipo_id,
          @w_dc_iden_N    	   = substring(dc_iden,1,(datalength(dc_iden)-1)),
          @w_dc_iden    	   = dc_iden,
          @w_dc_digito  	   = dc_digito,
          @w_dc_tipo_id  	   = dc_tipo_id,
          @w_dc_nombre  	   = dc_nombre,
          @w_dc_tipo_compania      = dc_tipo_compania,
          @w_dc_actividad          = dc_actividad,
          @w_dc_cliente            = dc_cliente
   from	cr_dato_cliente
   where  dc_tipo_reg = 'M'
   and    dc_cliente  = @w_fo_cliente_cobis


   if @w_dc_tipo_id = 'N'	
      select @w_iden = @w_dc_iden_N
   else
      select @w_iden = @w_dc_iden 

   if @w_dc_digito = 'N'	
      select @w_digito = null
   else
      select @w_digito = @w_dc_digito

   if @w_dc_tipo_compania = 'OF'	
      select @w_compania = '3'
   else
      select @w_compania = '2'


   /** FORMATO SIB **/
   /*****************/
   if @w_dc_tipo_id = 'N' 
      update #cr_formato_sib
      set fo_nit	   = @w_iden,
	  fo_tipo_id       = @w_dc_tipo_id,
   	  fo_nombre	   = @w_dc_nombre,
          fo_ciiu 	   = @w_dc_actividad,
          fo_digito        = @w_digito,
          fo_tcliente	   = @w_compania
      where fo_producto      = @w_fo_producto
      and   fo_banco         = @w_fo_banco
      and   fo_cliente_cobis = @w_fo_cliente_cobis



   /** ACTUALIZACION CR_FORMATO_SIB fo_tvinculacion **/
   /**************************************************/
   if exists (select 1 from cobis..cl_instancia
     where in_relacion in (201,202,203,204)
	      and   in_ente_i   = 2206789
 	      and   in_ente_d   = @w_fo_cliente_cobis)

   update  #cr_formato_sib
   set	   fo_tvinculacion  = 'S'
   where fo_producto      = @w_fo_producto
   and   fo_banco         = @w_fo_banco
   and   fo_cliente_cobis = @w_fo_cliente_cobis



   /** ACTUALIZACION CR_FORMATO_SIB fo_cupo **/
   /******************************************/
   select @w_li_monto = isnull(li_monto,0)
   from   cr_dato_operacion, cr_linea
   where  do_tipo_reg 	            = 'M'
   and    do_codigo_cliente         = @w_fo_cliente_cobis
   and    do_numero_operacion_banco = @w_fo_banco
   and	  do_codigo_producto        = @w_fo_producto	
   and	  do_linea_credito          = li_num_banco

   update #cr_formato_sib
   set	  fo_cupo = @w_li_monto
   where fo_producto      = @w_fo_producto
   and   fo_banco         = @w_fo_banco
   and   fo_cliente_cobis = @w_fo_cliente_cobis



   /** ACTUALIZACION CR_FORMATO_SIB fo_prov_cap, fo_prov_int,fo_prov_otros **/
   /*************************************************************************/
   select @w_provision_cap = isnull(sum(cp_prov+cp_prova),0)
   from   cr_calificacion_provision
   where  cp_num_banco  = @w_fo_banco	
   and    cp_producto   = @w_fo_producto
   and    cp_concepto   = '1'

   select @w_provision_int = isnull(sum(cp_prov+cp_prova),0)
   from   cr_calificacion_provision
   where  cp_num_banco  = @w_fo_banco	
   and    cp_producto   = @w_fo_producto
   and    cp_concepto   = '2'

   select @w_provision_otros = isnull(sum(cp_prov+cp_prova),0)
   from   cr_calificacion_provision
   where  cp_num_banco    = @w_fo_banco	
   and    cp_producto     = @w_fo_producto
   and    cp_concepto not in ('1','2')

   update  #cr_formato_sib
   set 	fo_prov_cap       = @w_provision_cap,
        fo_prov_int       = @w_provision_int,
        fo_prov_otros     = @w_provision_otros 
   where fo_producto      = @w_fo_producto
   and   fo_banco         = @w_fo_banco
   and   fo_cliente_cobis = @w_fo_cliente_cobis




   /** ACTUALIZACION CR_FORMATO_SIB fo_num_garantia **/
   /**************************************************/
   select @w_gp_garantia = gp_garantia
   from cob_credito..cr_gar_propuesta
   where gp_tramite = @w_op_tramite

   update #cr_formato_sib
   set    fo_num_garantia  = @w_gp_garantia
   where  fo_producto      = @w_fo_producto
   and    fo_banco         = @w_fo_banco
   and    fo_cliente_cobis = @w_fo_cliente_cobis



   /** ACTUALIZACION CR_FORMATO_SIB fo_concordato **/
   /************************************************/
   select @w_cn_situacion =  cn_situacion
   from cob_credito..cr_concordato
   where cn_cliente   = @w_fo_cliente_cobis

   if @w_cn_situacion = 'CON'
      select @w_situacion  = '1'
   else
      select @w_situacion  = '2'

   update  #cr_formato_sib
   set     fo_concordato    = @w_situacion
   where fo_producto        = @w_fo_producto
   and   fo_banco           = @w_fo_banco
   and   fo_cliente_cobis   = @w_fo_cliente_cobis


   /** ACTUALIZACION CR_FORMATO_SIB fo_inf_gar **/
   /*********************************************/
   select @w_dg_gar_est_deu = dg_gar_est_deu
   from   cr_dato_garantia
   where  dg_garantia  = @w_gp_garantia
   and    dg_producto  = @w_fo_producto
   and    dg_operacion = @w_operacion


   if @w_dg_gar_est_deu = 'S'
      select @w_info_gar = '1'
   else 
      select @w_info_gar = '2'


   /** ACTUALIZACION CR_FORMATO_SIB fo_fecha_avaluo **/
   /**************************************************/
   select @w_po_fvigencia_fin = isnull(convert(varchar(10),max(po_fvigencia_fin),111), '01/01/1900')
   from   cr_dato_garantia,   cob_custodia..cu_poliza
   where  dg_garantia  = po_codigo_externo
   and    dg_producto  = @w_fo_producto
   and    dg_operacion = @w_operacion


   /** ACTUALIZACION CR_FORMATO_SIB fo_fecha_ven_gar,fo_valor_avaluo **/
 /*******************************************************************/
   select @w_fecha_insp  = convert(varchar(10),max(in_fecha_insp),111)
   from   cr_dato_garantia, cob_custodia..cu_inspeccion
   where  dg_garantia  = in_codigo_externo
   and    dg_producto  = @w_fo_producto
   and    dg_operacion = @w_operacion

   if @w_fecha_insp is null
      select @w_valor_avaluo = 2
   else
      select @w_valor_avaluo = 1



   /** ACTUALIZACION CR_FORMATO_SIB fo_val_gar_otr,fo_proc_cub_otr,fo_val_cub_otr **/
   /********************************************************************************/
   select @w_cu_valor_inicial        = cu_valor_inicial,
          @w_cu_porcentaje_cobertura = cu_porcentaje_cobertura,
          @w_cu_valor_actual         = cu_valor_actual
   from cob_cartera..ca_operacion,
	cob_credito..cr_gar_propuesta,
	cob_custodia..cu_custodia
   where op_tramite        = gp_tramite
   and   op_banco          = @w_fo_banco
   and 	 gp_garantia       = cu_codigo_externo
   and   cu_clase_custodia = 'O'



   /** ACTUALIZACION CR_FORMATO_SIB fo_val_gar_hip,fo_proc_cub_hip,fo_val_cub_hip **/
   /********************************************************************************/
   select @w_dg_monto_distr_ini_a = dg_monto_distr_ini,
          @w_dg_porc_resp_a       = dg_porc_resp,
          @w_dg_valor_resp_a      = dg_valor_resp
   from cr_dato_garantia,cob_custodia..cu_custodia
   where dg_garantia	  = cu_codigo_externo
   and	 dg_producto 	  = @w_fo_producto
   and   dg_operacion     = @w_operacion
   and   cu_tipo  in( '1000','1100','1140','1130','1120','1100','1110')



   /** ACTUALIZACION CR_FORMATO_SIB fo_val_gar_pre,fo_proc_cub_pre,fo_val_cub_pre **/
   /********************************************************************************/
   select @w_dg_monto_distr_ini_b = dg_monto_distr_ini,
          @w_dg_porc_resp_b       = dg_porc_resp,
          @w_dg_valor_resp_b      = dg_valor_resp
   from cr_dato_garantia,cob_custodia..cu_custodia
   where  dg_garantia	  = cu_codigo_externo
   and	 dg_producto 	  = @w_fo_producto
   and   dg_operacion     = @w_operacion
   and   cu_tipo  in( '2000','2100','2100','2110','2120','2130','2140')


   update  #cr_formato_sib
   set  fo_inf_gar       = @w_info_gar,
        fo_fecha_avaluo  = isnull(@w_po_fvigencia_fin,'01/01/1900'),
        fo_fecha_ven_gar = isnull(@w_fecha_insp,'01/01/2004'),
	fo_valor_avaluo  = isnull(@w_valor_avaluo,0),
 	fo_val_gar_otr   = isnull(@w_cu_valor_inicial,0),
	fo_proc_cub_otr  = isnull(@w_cu_porcentaje_cobertura,0), 
	fo_val_cub_otr   = isnull(@w_cu_valor_actual,0),         
 	fo_val_gar_hip   = isnull(@w_dg_monto_distr_ini_a,0),
	fo_proc_cub_hip  = isnull(@w_dg_porc_resp_a,0),
	fo_val_cub_hip   = isnull(@w_dg_valor_resp_a,0),
	fo_val_gar_pre   = isnull(@w_dg_monto_distr_ini_b,0),
	fo_proc_cub_pre  = isnull(@w_dg_porc_resp_b,0),
	fo_val_cub_pre   = isnull(@w_dg_valor_resp_b,0)
   where fo_producto      = @w_fo_producto
   and   fo_banco         = @w_fo_banco
   and   fo_cliente_cobis = @w_fo_cliente_cobis



   /** OTROS PRODUCTOS **/
   /*********************/
   if @w_fo_producto in (50,51,58,48)
   begin
      if ltrim(rtrim(@w_fo_estado_contable)) = '1'
         select @w_estado  = 'VIGENTE'

      if ltrim(rtrim(@w_fo_estado_contable)) = '2'
         select @w_estado  = 'VENCIDO'

      if ltrim(rtrim(@w_fo_estado_contable)) = '3'
         select @w_estado  = 'CANCELADO'

      if ltrim(rtrim(@w_fo_estado_contable)) = '4'
         select @w_estado  = 'CASTIGADO'

      if ltrim(rtrim(@w_fo_estado_contable)) = '5'
         select @w_estado  = 'ANULADO'

      update #cr_formato_sib
      set	  fo_estado = @w_estado  
      where fo_producto      = @w_fo_producto
      and   fo_banco         = @w_fo_banco
      and   fo_cliente_cobis = @w_fo_cliente_cobis

   end


fetch cur_operacion into 
	@w_fo_banco,  		@w_fo_producto,			@w_fo_pcalficacion_e,	@w_fo_dias_mora,    @w_fo_clase,	
	@w_fo_nit,		@w_fo_digito,			@w_fo_tipo_id,		@w_fo_nombre,	    @w_fo_tcliente,
	@w_fo_ciiu, 		@w_fo_cliente_cobis,		@w_fo_mod_pag_int,	@w_fo_ttasa,	    @w_fo_saldo_int_cau,
	@w_fo_saldo_int_mora_m, @w_fo_concordato,		@w_fo_inf_gar,		@w_fo_valor_avaluo, @w_fo_estado,
        @w_fo_estado_contable


end
close cur_operacion
deallocate cur_operacion





/** INSERCION DE DATOS EN NUEVAS TABLAS **/
/*****************************************/
--alter	 table cr_formato_rf unpartition
truncate table cr_formato_rf
--alter	 table cr_formato_rf partition 1000



/** TABLA cr_formato_rf **/
/*************************/
insert  into cr_formato_rf
select 	fo_clase,
	fo_nit,
	fo_banco,
	fo_nombre,
	fo_fecha = substring(fo_fecha_desembolso,9,2)+substring(fo_fecha_desembolso,6,2)+substring(fo_fecha_desembolso,1,4),
	convert(char(15),round(fo_monto_des,0)),
	fo_modalidad = case fo_moneda
	when 0 then 'P'
	else 'U'
	end,
	convert(char(15),round(fo_saldo_cap,0)),
	fo_saldo_cap_corr = convert(char(15),0),
	convert(char(15),round(fo_saldo_int,0)),
	convert(char(15),round(fo_saldo_otros,0)),
	fo_saldo = convert(char(15),round(fo_saldo_cap + fo_saldo_int + fo_saldo_otros + fo_int_sus,0)),
	fo_clase_gar,
	fo_especial = convert(char(15),0),
	fo_val_gar = convert(char(15),round(fo_val_cub_pre + fo_val_cub_hip + fo_val_cub_otr,0)),
	convert(char(15),round(fo_int_sus,0)),
	convert(char(15),round(fo_prov_cap,0)),
	fo_prov_cap_corr = convert(char(15),0),
	convert(char(15),round(fo_prov_int,0)),
	convert(char(15),round(fo_prov_otros,0)),
	fo_prov = convert(char(15),round(fo_prov_cap+fo_prov_int+fo_prov_otros,0)),
	fo_calificacion,
	substring(fo_fecha_ini_mora,9,2)+substring(fo_fecha_ini_mora,6,2)+substring(fo_fecha_ini_mora,1,4),
	convert(char(5),fo_dias_mora),
	fo_estado = 'N',
	fo_terr = case fo_tcliente
	when '3' then 'S'			
	else 'N'
	end
from 	#cr_formato_sib
where   fo_clase in (1,2,3)




/** TABLA cr_formato_rfm **/
/**************************/
--alter	 table cr_formato_rfm unpartition
truncate table cr_formato_rfm
--alter	 table cr_formato_rfm partition 1000



insert  into cr_formato_rfm
select 	1,
	fo_nit,
	fo_banco,
	fo_nombre,
	fo_fecha = substring(fo_fecha_desembolso,9,2)+substring(fo_fecha_desembolso,6,2)+substring(fo_fecha_desembolso,1,4),
	convert(char(15),round(fo_monto_des,0)),
	fo_modalidad = case fo_moneda
	when 0 then 'P'
	else 'U'
	end,
	convert(char(15),round(fo_saldo_cap,0)),
	fo_saldo_cap_corr = convert(char(15),0),
	convert(char(15),round(fo_saldo_int,0)),
	convert(char(15),round(fo_saldo_otros,0)),
	fo_saldo = convert(char(15),round(fo_saldo_cap + fo_saldo_int + fo_saldo_otros + fo_int_sus,0)),
	fo_clase_gar,
	fo_especial = convert(char(15),0),
	fo_val_gari = convert(char(15),round(fo_val_gar_pre + fo_val_gar_hip + fo_val_gar_otr,0)),
	fo_val_gar = convert(char(15),round(fo_val_cub_pre + fo_val_cub_hip + fo_val_cub_otr,0)),
	convert(char(15),round(fo_int_sus,0)),
	convert(char(15),round(fo_prov_cap,0)),
	fo_prov_cap_corr = convert(char(15),0),
	convert(char(15),round(fo_prov_int,0)),
	convert(char(15),round(fo_prov_otros,0)),
	fo_prov = convert(char(15),round(fo_prov_cap+fo_prov_int+fo_prov_otros,0)),
	fo_calificacion,
	substring(fo_fecha_ini_mora,9,2)+substring(fo_fecha_ini_mora,6,2)+substring(fo_fecha_ini_mora,1,4),
	fo_dias_mora,
	fo_estado = 'N',
	fo_terr = case fo_tcliente
	when '3' then 'S'			
	else 'N'
	end
from 	#cr_formato_sib
where   fo_clase = 4



/** TABLA cr_formato_re **/
/*************************/

--alter	 table cr_formato_re unpartition
truncate table cr_formato_re
--alter	 table cr_formato_re partition 1000



insert  into cr_formato_re
select 	fo_clase,
	fo_banco,
	fo_fecha = substring(convert(varchar(10),do_fecha_reest,111),9,2)+substring(convert(varchar(10),do_fecha_reest,111),6,2)+substring(convert(varchar(10),do_fecha_reest,111),1,4),
	fo_calificacion_ant = '',
	fo_calificacion,
	fo_per_int,
	null,
	fo_saldo_cap_ant = 0,
	fo_saldo_int_ant = 0,
	fo_saldo_otr_ant = 0,
	fo_prov_cap_ant = 0,
	fo_prov_int_ant = 0,
	fo_prov_otr_ant = 0
from 	#cr_formato_sib,
	cr_dato_operacion
where   fo_clase in (1,2,3)
and	do_numero_operacion_banco = fo_banco
and     do_codigo_producto = fo_producto
and     do_tipo_reg 	   = 'M'
and     fo_reestruturada   = '1'




/** TABLA cr_formato_rem **/
/**************************/

--alter	 table cr_formato_rem unpartition
truncate table cr_formato_rem
--alter	 table cr_formato_rem partition 1000



insert  into cr_formato_rem
select 	1,
	fo_banco,
	fo_fecha = substring(do_fecha_reest,9,2)+substring(do_fecha_reest,6,2)+substring(do_fecha_reest,1,4),
	fo_calificacion_ant = '',
	fo_calificacion,
	fo_per_int,
	null,
	fo_saldo_cap_ant = 0,
	fo_saldo_int_ant = 0,
	fo_saldo_otr_ant = 0,
	fo_prov_cap_ant = 0,
	fo_prov_int_ant = 0,
	fo_prov_otr_ant = 0
from 	#cr_formato_sib,
	cr_dato_operacion
where   fo_clase = 4
and	do_numero_operacion_banco = fo_banco
and     do_codigo_producto = fo_producto
and     do_tipo_reg 	   = 'M'
and     fo_reestruturada   = '1'




/** TABLA cr_formato_co **/
/*************************/

--alter	 table cr_formato_co unpartition
truncate table cr_formato_co
--alter	 table cr_formato_co partition 1000


insert  into cr_formato_co
select 	convert(tinyint,op_clase),
	op_banco,
	de_ced_ruc
from 	cr_dato_operacion,
	cob_cartera..ca_operacion,
	cr_deudores
where 	do_numero_operacion_banco = op_banco
and	do_codigo_producto = 7
and	do_tipo_reg = 'M'
and     de_tramite  = op_tramite
and     de_rol in ('C')
and     op_clase  in ('1','2','3')



/** TABLA cr_formato_com **/
/**************************/

--alter	 table cr_formato_com unpartition
truncate table cr_formato_com
--alter	 table cr_formato_com partition 1000


insert  into cr_formato_com
select 	convert(tinyint,op_clase),
	op_banco,
	de_ced_ruc
from 	cr_dato_operacion,
	cob_cartera..ca_operacion,
	cr_deudores
where 	do_numero_operacion_banco = op_banco
and	do_codigo_producto = 7
and	do_tipo_reg = 'M'
and     de_tramite  = op_tramite
and     de_rol in ('C')
and     op_clase  = '4'



return 0
                                                                                                                                                                                                                                               

GO

