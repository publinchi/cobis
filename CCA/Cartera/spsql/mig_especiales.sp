/************************************************************************/
/*	Archivo           :	mig_especiales.sp	                            */
/*	Stored procedure  :	sp_migra_especiales	                            */
/*	Base de datos     :	cob_cartera		                                */
/*	Producto          : 	Credito y Cartera	                        */
/*	Disenado por      :  	Elcira Pelaez         	                    */
/*	Fecha de escritura:	jun - 2004 		                                */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/  
/*      		             PROPOSITO		                            */
/*Migracion de Obligaciones por garantias especiales                    */
/************************************************************************/ 
/*                               MODIFICACIONES                         */
/*     FECHA        AUTOR                    RAZON                      */
/*    24/Jun/2022     KDR              Nuevo parámetro sp_liquid        */
/*                                                                      */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_migra_especiales')
	drop proc sp_migra_especiales
go

create proc sp_migra_especiales
   @s_sesn          int,
   @s_date          datetime,
   @s_term          catalogo,
   @s_ofi           int,
   @s_ssn           int,
   @s_user          login,
   @i_fecha_proceso datetime

as declare 
   @w_return         	      int,
   @w_error                   int,
   @w_operacion               int,
   @w_sp_name                 varchar(30),
   @w_fdesebolso              catalogo,
   @w_identificacion		      cuenta,
   @w_digito_che              char(1) ,
   @w_tipo_identificacion     catalogo,
   @w_sector                  catalogo,
   @w_oficina                 int   ,
   @w_moneda                  smallint,
   @w_destino                 catalogo,
   @w_clase_cartera           catalogo,
   @w_fecha_crea              datetime,
   @w_linea                   catalogo,
   @w_monto                   money ,
   @w_tasa_aplicar            catalogo,
   @w_signo                   char(1) ,
   @w_factor                  float ,
   @w_migrada                 cuenta,
   @w_op_banco                cuenta,
   @w_op_banco_anterior       cuenta,
   @w_cliente                 int,
   @w_fecha                   datetime,
   @w_cot_moneda 	            money,
   @w_tcotizacion_mpg 	      char(1),
   @w_tcot_moneda     	      char(1),
   @w_comentario              varchar(255),
   @w_nombre_completo	      descripcion,
   @w_oficial                 int,
   @w_ciudad                  int,
   @w_origen_fondos           catalogo,
   @w_periodicidad_tasa       char(1),
   @w_modalidad_tasa          char(1),
   @w_tipo_tasa               char(1),
   @w_secuencial_ref          int,
   @w_dias_anio               smallint,
   @w_periodicidad            char(1),
   @w_porcentaje_efa          float,
   @w_tasa_base               catalogo,
   @w_secuencial_tasa         int,
   @w_porcentaje_nom          float,
   @w_base_calculo            char(1),
   @w_valor                   float,
   @w_fecha_tasa              datetime,
   @w_codvalor                int,
   @w_secuencial              int,
   @w_num_dias                int,
   @w_toperacion              catalogo,
   @w_gar_admisible           char(1),
   @w_calificacion            char(1),
   @w_tasa_nom                float,
   @w_intereses               money,
   @w_porcentaje_dia          float,
   @w_operacion_ant           int,
   @w_ro_signo           char(1),        
   @w_ro_factor          float,       
   @w_ro_referencial     catalogo,  
   @w_ro_porcentaje      float,   
   @w_ro_porcentaje_aux  float,
   @w_ro_porcentaje_efa  float,
   @w_ts_porcentaje      float,    
   @w_ts_porcentaje_efa  float,
   @w_ts_referencial     catalogo,   
   @w_ts_signo           char(1),         
   @w_ts_factor          float,
   @w_max_sec_tasa       int,
   @w_rubro_int          catalogo,
   @w_estado_act        tinyint,
   @w_fecha_fin         datetime,
   @w_migrada_org       cuenta,
   @w_num_periodo_d     int,
   @w_periodo_d         int
   

       
select @w_sp_name = 'sp_migra_especiales',
       @s_user    = 'sa'

declare recon_fag_migracion cursor for
select 
identificacion,       
digito_che,           
tipo_identificacion,  
sector,               
oficina,              
moneda,               
destino,              
clase_cartera,        
fecha_crea,           
linea,                
monto ,               
tasa_aplicar,         
signo,                
factor,               
migrada
from ca_oper_especiales_mig
where operacion  = 0   --SI ESTE CAMPO ESTA LLENO YA SE PROCESO
order by migrada
for read only

open recon_fag_migracion
  
fetch recon_fag_migracion into 
@w_identificacion,       
@w_digito_che,           
@w_tipo_identificacion,  
@w_sector,               
@w_oficina,              
@w_moneda,               
@w_destino,              
@w_clase_cartera,        
@w_fecha_crea,           
@w_linea,                
@w_monto,                
@w_tasa_aplicar,         
@w_signo,                
@w_factor,               
@w_migrada_org              

while @@fetch_status = 0 
/*CURSOR DE recon_fag_migracion*/
begin
    if (@@fetch_status = -1) 
    return 710004


    --INICIALIZAR VARIABLES

    select   @w_ro_signo           = '',        
             @w_ro_factor          = 0,       
             @w_ro_referencial     = '',  
             @w_ro_porcentaje      = 0,   
             @w_ro_porcentaje_aux  = 0,
             @w_ro_porcentaje_efa  = 0,
             @w_ts_porcentaje      = 0,    
             @w_ts_porcentaje_efa  = 0,
             @w_ts_referencial     = '',   
             @w_ts_signo           = '',         
             @w_ts_factor          = 0,
             @w_max_sec_tasa       = 0,
             @w_rubro_int          = 'INT',
             @w_op_banco_anterior  = '',
             @w_operacion_ant      = 0


    select @w_migrada = substring(@w_migrada_org,1,datalength(@w_migrada_org)-1)
   
    --SACAR LA FORMA DE DESEMBOLSO PARA CADA LINEA
   ----------------------------------------------
   
    select @w_ciudad = of_ciudad
    from cobis..cl_oficina
    where of_oficina = @w_oficina
    if @@rowcount = 0
	begin
       select @w_error = 701102
       goto ERROR_MIG
    end
      
    select @w_fdesebolso = codigo
    from cobis..cl_catalogo
    where tabla = (select codigo from cobis..cl_tabla
                   where tabla = 'ca_especiales')
    and  valor = @w_linea
    if @@rowcount = 0
	begin
       select @w_error = 710344
       goto ERROR_MIG
    end
    
    select @w_comentario = 'MIGRADA POR RECONOCIMIENTO DE GARANTIA' + '-' + @w_fdesebolso
 
    --VALIDAR LA EXISTENCIA DE LA LINEA
	select @w_origen_fondos = dt_categoria
	from  ca_default_toperacion
    where dt_tipo  = 'G'
    and   dt_nace_vencida = 'S'
    and   dt_toperacion = @w_linea
    if @@rowcount = 0
	begin
        select @w_error = 70101
        goto ERROR_MIG
    end
   
    select @w_cliente         = en_ente,
           @w_nombre_completo = en_nomlar,
           @w_oficial         = en_oficial
    from cobis..cl_ente
    where en_ced_ruc = @w_identificacion
    and en_tipo_ced = @w_tipo_identificacion
    if @@rowcount = 0
    begin
        select @w_error = 710104
        goto ERROR_MIG      
    end

   
          
    select @w_op_banco_anterior = op_banco,
           @w_operacion_ant   = op_operacion,
           @w_num_periodo_d   = op_periodo_int,
           @w_periodo_d       = op_tdividendo

    from ca_operacion
    where op_cliente = @w_cliente    
    and   op_migrada = @w_migrada
    and   op_tipo <> 'G'         
    if @@rowcount = 0
    begin
        select @w_error = 0
        PRINT 'No existe oper anterior para migrada Nro.' + @w_migrada + 'cliente' + cast(@w_cliente as varchar)
        goto ERROR_MIG
    end
   --INICIO ATOMICIDAD
   ------------------------
    begin tran
   
        -- SACAR SECUENCIALES SESIONES
        exec @s_ssn = sp_gen_sec 
             @i_operacion  = -1
              
        exec @s_sesn = sp_gen_sec 
             @i_operacion  = -1
      
        --INGRESAR DEUDOR 
      
        exec @w_return     = sp_codeudor_tmp
             @s_sesn       = @s_sesn,
             @s_user       = @s_user,
             @i_borrar     = 'S',
             @i_secuencial = 1,
             @i_titular    = @w_cliente,
             @i_operacion  = 'A',
             @i_codeudor   = @w_cliente,
             @i_ced_ruc    = @w_identificacion,
             @i_rol        = 'D',
             @i_externo    = 'N'
        if @w_return != 0
		begin
           select @w_error = @w_return 
           goto ERROR_MIG
        end
      
      
        -- CREACION DE LA OPERACION EN TEMPORALES
        exec @w_return = sp_crear_operacion
       	@s_user           = @s_user,
      	@s_date           = @i_fecha_proceso,
      	@s_term           = @s_term,
      	@i_cliente        = @w_cliente,
      	@i_nombre         = @w_nombre_completo,
      	@i_sector         = @w_sector,
      	@i_toperacion     = @w_linea,
      	@i_oficina        = @w_oficina,
      	@i_moneda         = @w_moneda,
      	@i_comentario     = @w_comentario,
      	@i_oficial        = @w_oficial, 
      	@i_fecha_ini      = @w_fecha_crea,
      	@i_monto          = @w_monto,
      	@i_monto_aprobado = @w_monto,
      	@i_destino        = @w_destino, ------ojo esta heredando el de la operaci½n que viene
      	@i_ciudad         = @w_ciudad,
      	@i_formato_fecha  = 101,
      	@i_salida         = 'N',
      	@i_fondos_propios = 'N',
      	@i_origen_fondos  = @w_origen_fondos,
        @i_batch_dd       = 'N',
        @i_clase_cartera  = @w_clase_cartera,
      	@o_banco          = @w_op_banco output
      	
        if @w_return != 0 
        begin
            select @w_error = @w_return 
            goto ERROR_MIG
        end
      
        -- PASO A  DEFINITIVAS 
        exec @w_return = sp_operacion_def
      	@s_date   = @i_fecha_proceso,
      	@s_sesn   = @s_sesn,
      	@s_user   = @s_user,
      	@s_ofi    = @w_oficina,
      	@i_banco  = @w_op_banco
      
        if @w_return != 0  
        begin
            select @w_error = @w_return
            goto ERROR_MIG
        end
      
         
        select @w_fecha = fc_fecha_cierre
        from   cobis..ba_fecha_cierre
        where  fc_producto = 7
      
        exec sp_buscar_cotizacion
             @i_moneda     = @w_moneda,
             @i_fecha      = @w_fecha,
             @o_cotizacion = @w_cot_moneda output
      
        select @w_tcotizacion_mpg = 'T',
               @w_tcot_moneda     = 'T'
      
        exec @w_return    = sp_desembolso
             @s_ofi            = @s_ofi,
             @s_term           = @s_term,
             @s_user           = @s_user,
             @s_date           = @s_date,  
             @i_producto       = @w_fdesebolso,  --La misma forma de pago es la de desembolso
             @i_cuenta         = 'MIGRADO AUTOMATICO', 
             @i_beneficiario   = @w_nombre_completo,
             @i_oficina_chg    = @s_ofi,
             @i_banco_ficticio = @w_op_banco, 
             @i_banco_real     = @w_op_banco,
             @i_monto_ds       = @w_monto,
             @i_tcotiz_ds      = @w_tcot_moneda,
             @i_cotiz_ds       = @w_cot_moneda,
             @i_tcotiz_op      = @w_tcotizacion_mpg,
             @i_cotiz_op       = @w_cot_moneda,
             @i_moneda_op      = @w_moneda,
             @i_moneda_ds      = @w_moneda,
             @i_operacion      = 'I',
             @i_externo        = 'N'
      
        if @w_return != 0
		begin
            select @w_error = @w_return
            goto ERROR_MIG
        end
     
        exec @w_return = sp_liquida
             @s_ssn            = @s_ssn,    
             @s_sesn           = @s_sesn,
             @s_user           = @s_user,
             @s_date           = @s_date,
             @s_ofi            = @s_ofi,
             @s_rol            = 1,
             @s_term           = @s_term,
             @i_banco_ficticio = @w_op_banco,
             @i_banco_real     = @w_op_banco,
             @i_afecta_credito = 'N',
             @i_fecha_liq      = @w_fecha_crea,
             @i_tramite_batc   = 'N',
			 @i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
             @i_externo        = 'N'
        if @w_return <> 0 
        begin
            select @w_error = @w_return
            goto ERROR_MIG
        end
        else
        begin
            select @w_operacion = convert(int,@w_op_banco)
            
            select @w_op_banco        = null,
                   @w_dias_anio       = null,
                   @w_base_calculo    = null,
                   @w_toperacion      = null,
                   @w_gar_admisible   = null
            
            select @w_op_banco        = op_banco,
                   @w_dias_anio       = op_dias_anio,
                   @w_base_calculo    = op_base_calculo,
                   @w_toperacion      = op_toperacion,
                   @w_gar_admisible   = op_gar_admisible,
                   @w_fecha_fin       = op_fecha_fin,
                   @w_estado_act      = op_estado
            from ca_operacion
            where op_operacion = @w_operacion
            
            update cob_cartera..ca_operacion 
            set op_anterior          = @w_op_banco_anterior,
                op_migrada           = @w_migrada,
                op_fecha_ult_proceso = @w_fecha_crea,
                op_tipo_reduccion    = 'N'
            where op_banco  = @w_op_banco
            and   op_cliente = @w_cliente
            and   op_tipo  = 'G'
            if @@error != 0  
            begin
               select @w_error = 705007
               goto ERROR_MIG
            end

            if (@w_fecha_fin <= @i_fecha_proceso) 
            begin
                update ca_operacion
                set    op_estado = 9,
                       op_suspendio = 'S'
                where  op_banco = @w_op_banco
               
                update ca_dividendo
                set di_estado = 2
                where di_operacion = @w_operacion
               
                update ca_amortizacion
                set am_estado = 9
                where am_operacion = @w_operacion
                and am_concepto = 'IMO'

                update ca_amortizacion
                set am_estado = 2
                where am_operacion = @w_operacion
                and am_concepto = 'CAP'
               
            end
            
            update ca_transaccion
            set tr_estado = 'NCO',
                tr_observacion = 'MIGRADA'
            where tr_banco = @w_op_banco
            and   tr_tran = 'DES'
            
            update ca_oper_especiales_mig
            set operacion = @w_operacion
            where migrada = @w_migrada_org
       
            ---LEER CARACTERISTICAS DE LA TASA
            select                                                                 
            @w_tasa_base         = vd_referencia,
            @w_periodicidad_tasa = tv_periodicidad,
            @w_modalidad_tasa    = tv_modalidad,
            @w_tipo_tasa         = tv_tipo_tasa
            from  ca_valor, ca_valor_det,ca_tasa_valor
            where va_tipo        = @w_tasa_aplicar
            and   vd_tipo        = @w_tasa_aplicar
            and   tv_nombre_tasa = vd_referencia
            and   vd_sector      = @w_sector
            
            select @w_fecha_tasa = max(vr_fecha_vig)
            from   ca_valor_referencial
            where  vr_tipo      = @w_tasa_base 
            and  vr_fecha_vig <= @w_fecha_crea
            if @@rowcount = 0
            begin
               select @w_error = 701176
               goto ERROR_MIG
            end

            select @w_secuencial_ref = max(vr_secuencial)
            from   ca_valor_referencial
            where  vr_tipo      = @w_tasa_base 
            and  vr_fecha_vig = @w_fecha_tasa
            if @@rowcount = 0
            begin
               select @w_error = 701176
               goto ERROR_MIG
            end
   
            -- TASA BASICA REFERENCIAL 
            select @w_valor     = vr_valor
            from   ca_valor_referencial
            where  vr_tipo      = @w_tasa_base 
            and    vr_secuencial = @w_secuencial_ref
            if @@rowcount = 0
            begin
                select @w_error = 701177
                goto ERROR_MIG
            end
         
            --TASA BASE ES EFECTIVA
            if  @w_tipo_tasa  = 'E'
            begin
                if @w_signo = '+'
                   select @w_porcentaje_efa = @w_valor + @w_factor
                if @w_signo = '-'
                   select @w_porcentaje_efa = @w_valor - @w_factor
                 
                exec @w_return =  sp_conversion_tasas_int               
                @i_dias_anio      = @w_dias_anio,                       
                @i_base_calculo   = @w_base_calculo,
                @i_periodo_o      = 'A',              
                @i_modalidad_o    = 'V',
                @i_num_periodo_o  = 1,                                  
                @i_tasa_o         = @w_porcentaje_efa,
                @i_periodo_d      = @w_periodo_d,                    
                @i_modalidad_d    = @w_modalidad_tasa,
                @i_num_periodo_d  = @w_num_periodo_d,
                @i_num_dec        = 2,
                @o_tasa_d         = @w_porcentaje_nom output
                                                              
                if @w_return <> 0 
                begin
                    select @w_error = @w_return                      
                    goto ERROR_MIG 
                end
            end
         
            --TASA BASE ES NOMINAL
            if  @w_tipo_tasa  = 'N'
            begin
                if @w_signo = '+'
                   select @w_porcentaje_nom = @w_valor + @w_factor
                if @w_signo = '-'
                   select @w_porcentaje_nom = @w_valor - @w_factor

                exec @w_return =  sp_conversion_tasas_int               
                @i_dias_anio      = @w_dias_anio,                       
                @i_base_calculo   = @w_base_calculo,
                @i_periodo_o      = @w_periodicidad_tasa,              
                @i_modalidad_o    = @w_modalidad_tasa,
                @i_num_periodo_o  = 1, 
                @i_tasa_o         = @w_porcentaje_nom,                     ---TASA NOMINAL BASE
                @i_periodo_d      = 'A',                    
                @i_modalidad_d    = 'V',
                @i_num_periodo_d  = 1,
                @i_num_dec        = 2,
                @o_tasa_d         = @w_porcentaje_efa output   ---TASA EFECTIVA DE LA BASE
                                                              
                if @w_return <> 0 
                begin
                    select @w_error = @w_return                      
                    goto ERROR_MIG 
                end
            end
          
            ---FIN LEER CARACTERISTICAS DE LA TASA
            
            --INGRESAR LA TASA PARA LA MORA Y CALCULARLA
            
            if  @w_porcentaje_nom > 0
            begin
                exec @w_secuencial_tasa = sp_gen_sec
                @i_operacion  = @w_operacion
             
                insert into ca_tasas (
                ts_operacion,      ts_dividendo,    ts_fecha,
                ts_concepto,       ts_porcentaje,   ts_secuencial,
                ts_porcentaje_efa, ts_referencial,  ts_signo,
                ts_factor ) 
                values (
                @w_operacion,       1,               @i_fecha_proceso,
                'IMO',              @w_porcentaje_nom,   @w_secuencial_tasa,
                @w_porcentaje_efa,  @w_tasa_aplicar,     @w_signo, 
                @w_factor)	
            
                if @@error <> 0 
                begin
                    select  @w_error = 703118
                    goto ERROR_MIG 
                end
            end
            ELSE
            begin
                --NO EXISTE TASA O ESTA EN 0
                select @w_error = 708147
                goto ERROR_MIG 
            end

            update ca_rubro_op
            set ro_porcentaje      = @w_porcentaje_nom,
                ro_porcentaje_efa  = @w_porcentaje_efa,
                ro_porcentaje_aux  = @w_porcentaje_efa,
                ro_signo           = @w_signo,
                ro_factor          = @w_factor,
                ro_referencial     = @w_tasa_aplicar
            where ro_operacion     = @w_operacion
            and   ro_concepto      = 'IMO'
            
            -- FIN INGRESAR LA TASA PARA LA MORA Y CALCULARLA
            
            
            PRINT 'mig_especiales Operacion' + cast(@w_op_banco as varchar)
         
            --ACTUALIZACION DE TASAS
            --*******************************************************************************************
            --DATOS DE LA TASA INT DE LA ACTIVA ANTERIOR PARA COLOCARLOS A LA NUEVA POR PRESENTACION
            --SEGUN CONTROL DE CAMBIO X33 DE JUNIO -2003
            --******************************************************************************************
          
            select @w_rubro_int = ro_concepto
            from ca_rubro_op,ca_concepto
            where ro_operacion = @w_operacion
            and   ro_concepto = co_concepto
            and   co_categoria = 'I'
            if @@rowcount <> 0
            begin
                select @w_max_sec_tasa = isnull(max(ts_secuencial),0)
                from ca_tasas
                where ts_operacion =  @w_operacion_ant
                and   ts_concepto  = @w_rubro_int
            
                if @w_max_sec_tasa > 0
                begin
                    select    
                    @w_ts_porcentaje     = ts_porcentaje,
                    @w_ts_porcentaje_efa = ts_porcentaje_efa,
                    @w_ts_referencial    = ts_referencial,
                    @w_ts_signo          = ts_signo,
                    @w_ts_factor         = ts_factor
                    from ca_tasas
                    where ts_operacion =  @w_operacion_ant
                    and   ts_concepto  = @w_rubro_int
                    and   ts_secuencial = @w_max_sec_tasa
                  
                    update ca_tasas
                    set 
                    ts_porcentaje     = @w_ts_porcentaje,
                    ts_porcentaje_efa = @w_ts_porcentaje_efa,
                    ts_referencial    = @w_ts_referencial,
                    ts_signo          = @w_ts_signo,
                    ts_factor         = @w_ts_factor
                    where ts_operacion = @w_operacion
                    and   ts_concepto  = @w_rubro_int
                                         
                    select
                    @w_ro_signo          = ro_signo,
                    @w_ro_factor         = ro_factor,
                    @w_ro_referencial    = ro_referencial,
                    @w_ro_porcentaje     = ro_porcentaje,
                    @w_ro_porcentaje_aux = ro_porcentaje_aux,
                    @w_ro_porcentaje_efa = ro_porcentaje_efa
                    from ca_rubro_op
                    where ro_operacion =  @w_operacion_ant
                    and   ro_concepto  = @w_rubro_int
               
                    update ca_rubro_op
                    set
                    ro_signo          = @w_ro_signo,
                    ro_factor         = @w_ro_factor,
                    ro_referencial    = @w_ro_referencial,
                    ro_porcentaje     = @w_ro_porcentaje,
                    ro_porcentaje_aux = @w_ro_porcentaje_aux,
                    ro_porcentaje_efa = @w_ro_porcentaje_efa
                    where ro_operacion = @w_operacion
                    and   ro_concepto  = @w_rubro_int
                end
            end

            --FIN DE ACTUALIZACION DE TASAS
            --*****************************************************************************
         
            -- BORAR TEMPORALES 
            exec @w_return = sp_borrar_tmp
                 @i_banco  = @w_op_banco,
                 @s_date   = @i_fecha_proceso,
                 @s_user   = @s_user
            if @w_return <> 0
            begin
                select  @w_error = @w_return
                goto ERROR_MIG
            end
		END

    commit tran
   
-- FIN  ATOMICIDAD
------------------------
   
goto SIGUIENTE
   
ERROR_MIG:
   
while @@trancount > 0 ROLLBACK
  
BEGIN TRAN
   
    exec sp_errorlog
         @i_fecha       = @i_fecha_proceso,
         @i_error       = @w_error,
         @i_usuario     = 'sa',
         @i_tran        = 7000, 
         @i_tran_name   = @w_sp_name,
         @i_rollback    = 'N',
         @i_cuenta      = @w_migrada_org,
         @i_descripcion = 'MIGRANDO ALTERNAS POR RECONOCIMIENTO DE GARANTIAS ESPCIALES'
   
COMMIT TRAN
   
goto SIGUIENTE
   
SIGUIENTE:
    fetch recon_fag_migracion into 
    @w_identificacion,       
    @w_digito_che,           
    @w_tipo_identificacion,  
    @w_sector,               
    @w_oficina,              
    @w_moneda,               
    @w_destino,              
    @w_clase_cartera,        
    @w_fecha_crea,           
    @w_linea,                
    @w_monto,                
    @w_tasa_aplicar,         
    @w_signo,                
    @w_factor,               
    @w_migrada_org
   

end --CURSOR recon_fag_migracion 

close recon_fag_migracion
deallocate recon_fag_migracion

return 0

go
