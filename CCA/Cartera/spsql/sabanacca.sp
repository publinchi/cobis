/************************************************************************/
/*   NOMBRE LOGICO:      sabanacca.sp                                   */
/*   NOMBRE FISICO:      sp_sabana_cca                                  */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:                                                      */
/*   FECHA DE ESCRITURA:                                                */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                            PROPOSITO                                 */
/* Generación de la sábana de cartera para la generación de regulatorio */
/************************************************************************/
/*                            CAMBIOS                                   */
/*  01/07/2019  Adriana Giler       Ajuste Te Creemos                   */
/*  17/01/2020  Luis Ponce          ##tmp_sabana no está en cob_cartera */
/*  14/08/2023  Kevin Rodriguez     B880700 Corrección SP de error log  */
/*  06/11/2023  Erwing Medina       R218792 Optimización  batch size    */
/*  04/01/2024  Kevin Rodriguez     R222838 Se ajusta valores de rubros */
/*                                  para que incluyan valores de gracia */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_sabana_cca')
   drop proc sp_sabana_cca
go

create proc sp_sabana_cca
(  
   @i_param1  datetime = null 
)
as declare
   @w_return                int,
   @w_sp_name               varchar(32),
   @w_path_destino          varchar(200), 
   @w_s_app                 varchar(40),
   @w_cmd                   varchar(5000),
   @w_destino               varchar(255),
   @w_mensaje               varchar(100),
   @w_path                  varchar(255),
   @w_errores               varchar(255),
   @w_comando               varchar(6000),
   @w_error                 int,
   @w_operacion             int,
   @w_fec_proceso           datetime,
   @w_ffecha                int,
   @w_fini_periodo          datetime,
   @w_ffin_periodo          datetime,
   @w_periodo               char(6),
   @w_max_operacion         int,   
   @w_est_cancelado         tinyint,
   @w_est_suspenso          tinyint,
   @w_est_diferido          tinyint,
   @w_est_vigente           tinyint,
   @w_est_vencido           tinyint,
   @w_est_novigente         tinyint,
   @w_est_credito           tinyint,
   @w_ult_cap_pagado        money,
   @w_ult_int_pagado        money,
   @w_ult_cap_pagado_fecha  datetime,
   @w_ult_int_pagado_fecha  datetime,
   @w_ope_sabana            int,
   @w_secuencial            int,
   @w_ope_sabana_sgte       int,
   @w_respaldo_mes          int,
   @w_fin_mes_respaldo      datetime,
   @w_fborrar               datetime,
   @w_fecha_uno             datetime,
   @w_max_fecha             datetime
   

select @w_sp_name = 'sp_sabana_cca'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   out
   
/* OBTENER VALOR DE RESPALDO */
Select @w_respaldo_mes = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'RESREG'
and   pa_producto = 'CCA'
   
/* OBTENIENDO DATOS */
select @w_periodo = left(convert(varchar,fp_fecha,112),6),
       @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso

/* OBTENIENDO FECHA INICIAL Y FINAL DEL PERIODO */
select @w_fini_periodo = convert(datetime, '01/' + 
                         right('00' + convert(varchar, month(@w_fec_proceso)), 2) + '/' + 
                         convert(varchar, year(@w_fec_proceso)), 103), 
       @w_ffin_periodo = @w_fec_proceso

select @w_ffecha = 103

select @w_operacion = 0

select @w_max_operacion = max(op_operacion)
from ca_operacion

delete ca_sabana_regulatorio
where sr_fecha_proceso = @w_fec_proceso

--Si cambio el mes, eliminar los datos de todo el mes anterior, excepto fin de mes
select @w_max_fecha = max(sr_fecha_proceso)
from ca_sabana_regulatorio

if month(@w_max_fecha) != month(@w_fec_proceso)
    select @w_fecha_uno = convert(datetime, '01/' + 
                         right('00' + convert(varchar, month(@w_fec_proceso)), 2) + '/' + 
                         convert(varchar, year(@w_fec_proceso)), 103)
else
    select @w_fecha_uno = @w_fec_proceso

if day(@w_fecha_uno) = 1
begin
    select @w_fin_mes_respaldo = datediff(d,1,@w_fecha_uno)   
    select @w_fborrar = convert(datetime, '01/' + 
                         right('00' + convert(varchar, month(@w_fin_mes_respaldo)), 2) + '/' + 
                         convert(varchar, year(@w_fin_mes_respaldo)), 103)
 

    while @w_fborrar != @w_fin_mes_respaldo
    begin
        delete ca_sabana_regulatorio
        where sr_fecha_proceso = @w_fborrar
        
        if @@error != 0
        begin
            SELECT @w_mensaje =  'Error Eliminando Historico Mensual'
            goto ERROR
        end
        
        select @w_fborrar = dateadd(d,1,@w_fborrar) 
    end
end

--Eliminando los Meses 
select @w_respaldo_mes = (@w_respaldo_mes -1 )* (-1)
select @w_fborrar = dateadd(mm,@w_respaldo_mes ,@w_fin_mes_respaldo)
select @w_fborrar = dateadd(dd,-1 ,@w_fborrar)

delete ca_sabana_regulatorio
where sr_fecha_proceso <= @w_fborrar 

if @@error != 0
begin
    SELECT @w_mensaje =  'Error Eliminando Historico'
    goto ERROR
end

---------------------------------------
-- Creando Temporal para trabajo
---------------------------------------
select *
into ##tmp_sabana
from ca_sabana_regulatorio
where 2 = 1

if @@error != 0
begin
    SELECT @w_mensaje = 'Error Creando Temporal de Trabajo'
    goto ERROR
end

alter table ##tmp_sabana drop column  sr_fecha_proceso

create index idx1 on ##tmp_sabana (sr_operacion)

set rowcount 10000

while 1=1 
begin
    insert into ##tmp_sabana(
            sr_periodo,            sr_operacion,            sr_cliente,         sr_nom_cliente,     
            sr_oficina,            sr_toperacion,      sr_fecha_ini,            sr_fecha_fin,       sr_monto,               
            sr_plazo,              sr_tplazo,          sr_banco,                
            sr_val_capital,     
            sr_val_interes,    
            sr_val_imo,
            sr_val_dev,      
            sr_val_dev_m,
            sr_dias_dev,    
            sr_val_comision,         
            sr_reserva,            sr_rango,           sr_estado_cont,         sr_estado,
            sr_tasa,                 
            sr_int_vencidos,
            sr_val_ahorro,     
            sr_cap_vigente,        
            sr_cap_vencido,     
            sr_cap_no_vig,           
            sr_int_vigente,     
            sr_int_vencido,
            sr_int_no_vig,         
            sr_delegacion_dir,  sr_estado_dir,           
            sr_fecha_ultpago,   
            sr_rfc_cliente,
            sr_cuota_inicial,      
            sr_nro_cuota,           
            sr_nro_cuota_pend,     
            sr_fecha_ven_ini,   
            sr_cta_ahorro,          sr_destino,            sr_fecha_ult_proceso,  sr_oficial,
            sr_ult_cap_pagado,      sr_ult_cap_pag_fecha,  sr_ult_int_pagado,    sr_ult_int_pag_fecha   )      
    select  
            @w_periodo,             op_operacion,            op_cliente,         en_nomlar,
            op_oficina,             op_toperacion,     op_fecha_ini,            op_fecha_fin,       op_monto,
            op_plazo,               op_tplazo,         op_banco,            
           
            isnull((select sum(am_cuota + am_gracia - am_pagado)            -- sr_val_capital
                    from ca_amortizacion 
                    where am_operacion = b.op_operacion
                    and am_concepto = 'CAP'
                    and am_estado != @w_est_cancelado),0),
           
            isnull((select sum(am_cuota + am_gracia  - am_pagado)            -- sr_val_interes
            from ca_amortizacion inner join dbo.ca_dividendo
                on am_operacion = di_operacion 
                and am_dividendo = di_dividendo                
                and di_estado = @w_est_vigente
            where am_operacion = b.op_operacion
            and am_concepto = 'INT'
            and am_estado != @w_est_cancelado),0),
          
            isnull((select sum(am_cuota + am_gracia  - am_pagado)           --sr_val_imo
            from ca_amortizacion inner join dbo.ca_dividendo
                on am_operacion = di_operacion and am_dividendo = di_dividendo
                and am_estado <> @w_est_diferido 
                and am_concepto = 'IMO'
            where am_operacion = b.op_operacion 
            and di_fecha_ini <= @w_ffin_periodo
            group by am_operacion),0),
            
            --sr_val_dev
            isnull((select isnull(sum(
                    case when(di_fecha_ini < @w_fini_periodo and di_fecha_ven <= @w_ffin_periodo and di_fecha_ven >= @w_fini_periodo) 
                            then am_cuota/datediff(dd, di_fecha_ini, di_fecha_ven)*(datediff(dd, @w_fini_periodo, di_fecha_ven)+1)
                    when (di_fecha_ini < @w_fini_periodo and di_fecha_ven > @w_ffin_periodo and di_fecha_ven >= @w_fini_periodo) 
                            then am_cuota/datediff(dd, di_fecha_ini, di_fecha_ven)*(datediff(dd, @w_fini_periodo, di_fecha_ven)+1)
                    when (di_fecha_ini >= @w_fini_periodo and di_fecha_ven <= @w_ffin_periodo) 
                    then am_cuota
                    when ((di_fecha_ini >= @w_fini_periodo and di_fecha_ini <= @w_ffin_periodo)and di_fecha_ven > @w_ffin_periodo) 
                            then (am_cuota/datediff(dd, di_fecha_ini, di_fecha_ven)*datediff(dd, di_fecha_ini, @w_ffin_periodo))
                    end), 0.0)
            from cob_cartera.dbo.ca_amortizacion inner join cob_cartera.dbo.ca_dividendo
                on am_operacion = di_operacion and am_dividendo = di_dividendo 
            where am_operacion = b.op_operacion 
            and am_concepto  ='INT'
            and am_estado <> @w_est_diferido 
            and di_fecha_ini <= @w_ffin_periodo 
            group by am_operacion),0),
            
            --sr_val_dev_m
           isnull((select isnull(sum(dtr_monto), 0.0)
                    from cob_cartera.dbo.ca_det_trn inner join cob_cartera.dbo.ca_transaccion_prv 
                        on tp_operacion=dtr_operacion and tp_secuencial_ref=dtr_secuencial
                    and tp_fecha_mov >= @w_fini_periodo and tp_fecha_mov <= @w_ffin_periodo
                    and tp_estado <> 'RV'  and dtr_concepto='IMO' 
                    and dtr_estado <> @w_est_diferido
                    where dtr_operacion = b.op_operacion
                    group by dtr_operacion),0),
                    
            --sr_dias_dev
            isnull((select datediff(dd,min(di_fecha_ven), @w_fec_proceso) 
                    from ca_dividendo
                    where di_operacion= b.op_operacion 
                    and di_estado = @w_est_vencido),0),
                    
            --sr_val_comision
            isnull((select ro_valor                                             
                   from ca_rubro_op 
                   where ro_operacion = b.op_operacion 
                   and ro_concepto = 'CO'
                   and op_fecha_ini >= @w_fini_periodo),0) ,
            
            0,                      1,                 0,                    op_estado,
            
            --sr_tasa
            isnull((select sum(ro_porcentaje)                                           
                   from ca_rubro_op 
                   where ro_operacion = b.op_operacion  
                   and ro_concepto = 'INT'), 0)  ,
           
            -- sr_int_vencidos
            isnull((select sum(am_cuota + am_gracia - am_pagado)  
            from ca_amortizacion inner join ca_dividendo
                on am_operacion = di_operacion and am_dividendo = di_dividendo 
                and di_estado = @w_est_vencido
            where am_operacion = b.op_operacion 
            and am_concepto  = 'INT'),0), 
                         
            --sr_val_ahorro            
            isnull((select ah_disponible                                      
                    from cob_ahorros..ah_cuenta
                    where ah_cta_banco = b.op_cuenta),''),
            
            -- sr_cap_vigente
            isnull((select sum(am_cuota + am_gracia - am_pagado)  
            from ca_amortizacion inner join ca_dividendo
                on am_operacion = di_operacion and am_dividendo = di_dividendo 
                and di_estado = @w_est_vigente
            where am_operacion = b.op_operacion 
            and am_concepto  = 'CAP'),0),     
                    
            -- sr_cap_vencido        
            isnull((select sum(am_cuota + am_gracia - am_pagado)                          
            from ca_amortizacion inner join ca_dividendo
                on am_operacion = di_operacion and am_dividendo = di_dividendo 
                and di_estado = @w_est_vencido
            where am_operacion = b.op_operacion 
            and am_concepto  = 'CAP'),0),
            
            -- sr_cap_no_vig
            isnull((select sum(am_cuota + am_gracia - am_pagado)   
            from ca_amortizacion inner join ca_dividendo
                on am_operacion = di_operacion and am_dividendo = di_dividendo 
                and di_estado = @w_est_novigente
            where am_operacion = b.op_operacion 
            and am_concepto  ='CAP'),0),    
            
            -- sr_int_vigente            
            isnull((select sum(am_cuota + am_gracia - am_pagado)                          
            from ca_amortizacion inner join ca_dividendo
                on am_operacion = di_operacion and am_dividendo = di_dividendo 
                and di_estado = @w_est_vigente
            where am_operacion = b.op_operacion 
            and am_concepto  = 'INT'),0),            
            
            -- sr_int_vencido
            isnull((select sum(am_cuota + am_gracia - am_pagado)   
            from ca_amortizacion inner join ca_dividendo
                on am_operacion = di_operacion and am_dividendo = di_dividendo 
                and di_estado = @w_est_vencido
            where am_operacion = b.op_operacion 
            and am_concepto  ='INT'),0),
            
            -- sr_int_no_vig        
            isnull((select sum(am_cuota + am_gracia - am_pagado)                          
            from ca_amortizacion inner join ca_dividendo
                on am_operacion = di_operacion and am_dividendo = di_dividendo 
                and di_estado = @w_est_novigente
            where am_operacion = b.op_operacion 
            and am_concepto  ='INT'),0),                   
                              
            isnull(ci_descripcion,''),    isnull(pv_descripcion,''),          
            
            -- sr_fecha_ultpago
            isnull((select max(tr_fecha_ref)
             from ca_transaccion
             where tr_operacion = b.op_operacion 
             and tr_tran = 'PAG' 
             and tr_estado <> 'RV'), '01/01/1900'),

            en_ced_ruc,
           
            -- sr_cuota_inicial
            isnull((select sum(amh_cuota)                                   
            from  ca_amortizacion_his 
            where amh_operacion = b.op_operacion  
            and amh_dividendo = 2
            and amh_secuencial = (select min(oph_secuencial) 
                                  from  ca_operacion_his 
                                  where oph_operacion = b.op_operacion )),0),

            op_plazo,
            
            -- sr_nro_cuota_pend
            op_plazo - isnull((select count(di_operacion)                   
                               from  ca_dividendo 
                               where di_operacion = b.op_operacion 
                               and di_estado = @w_est_cancelado),0),
            
            --sr_fecha_ven_ini            
            isnull((select oph_fecha_fin                                           
             from  ca_operacion_his 
             where oph_operacion = b.op_operacion 
             and oph_secuencial = (select min(oph_secuencial) 
                                  from  ca_operacion_his 
                                  where oph_operacion = b.op_operacion )), '01/01/1900'),
         
            isnull(op_cuenta, ''),
            isnull(op_destino, '') ,          
            op_fecha_ult_proceso,  
            op_oficial,
            0,      '01/01/1900',  0,    '01/01/1900' 
   
    from ca_operacion b, cobis..cl_ente a
    LEFT OUTER JOIN cobis..cl_direccion on di_ente = en_ente
                    and   di_tipo = 'RE'
                    and   di_direccion = (select max(di_direccion) from cobis..cl_direccion
                                          where di_ente = a.en_ente
                                          and   di_tipo = 'RE')
    LEFT OUTER JOIN cobis..cl_ciudad on ci_ciudad    = di_ciudad
    LEFT OUTER JOIN cobis..cl_provincia on pv_provincia = ci_provincia
    where op_operacion > @w_operacion
    and   op_cliente = en_ente   
    order by op_operacion 
    
    if @@error != 0
    begin
        SELECT @w_mensaje = 'Error obteniendo Datos Sabana de Regulatorios'
        goto ERROR
    end

    /* ACTUALIZAR ESTADO CONTABLE */
    update ##tmp_sabana
    set sr_estado_cont = (case when sr_dias_dev <= 90 then 1
                          when sr_dias_dev > 90 and sr_estado not in (4, 14, 15) then 8
                          else 4 end)
    where sr_operacion > @w_operacion
    
    if @@error != 0
    begin
        print 'Error Actualizando Estados Contables'
        goto ERROR
    end
    
    select @w_operacion = max(sr_operacion)
    from ##tmp_sabana
    
    if @w_max_operacion = @w_operacion
        break        
end

/* ELIMINAR ESTADOS NO VIGENTES Y EN CREDITO */
delete ##tmp_sabana
where  sr_estado in (@w_est_novigente, @w_est_credito)

/* OBTENER DATOS RESTANTES */
Select @w_ope_sabana = min(sr_operacion)-1
from ##tmp_sabana

select @w_max_operacion = max(sr_operacion)
from ##tmp_sabana



while 1=1
begin    
    Select @w_ope_sabana_sgte = @w_ope_sabana
    select @w_ope_sabana = 0
    
    Select @w_ope_sabana = min(sr_operacion)
    from ##tmp_sabana
    where sr_operacion > @w_ope_sabana_sgte
    
    
    --ENCERO VARIABLES
    select @w_secuencial = 0,
           @w_ult_cap_pagado = 0,
           @w_ult_cap_pagado_fecha = '01/01/1900',
           @w_ult_int_pagado = 0,
           @w_ult_int_pagado_fecha = '01/01/1900'
            
    --ULTIMO CAPITAL PAGADO:  VALOR Y FECHA
    select @w_secuencial =  max(tr_secuencial) 
    from ca_det_trn 
    inner join ca_transaccion 
               on tr_operacion = dtr_operacion 
               and tr_secuencial = dtr_secuencial
               and tr_tran = 'PAG' 
               and tr_estado <> 'RV' 
               and dtr_concepto = 'CAP'
    where dtr_operacion = @w_ope_sabana
    
    select @w_ult_cap_pagado = isnull(dtr_monto, 0.0), 
           @w_ult_cap_pagado_fecha = isnull(tr_fecha_ref,'01/01/1900')
    from ca_det_trn 
    inner join ca_transaccion 
        on tr_operacion = dtr_operacion 
        and tr_secuencial = dtr_secuencial
        and tr_tran = 'PAG' 
        and tr_estado <> 'RV' 
        and dtr_concepto = 'CAP'
    where dtr_operacion = @w_ope_sabana 
    and dtr_secuencial = @w_secuencial
    
    
    --ULTIMO INTERES PAGADO:  VALOR Y FECHA
    select @w_secuencial = max(tr_secuencial) 
    from ca_det_trn 
    inner join ca_transaccion 
        on tr_operacion = dtr_operacion 
        and tr_secuencial = dtr_secuencial
        and tr_tran = 'PAG' 
        and tr_estado <> 'RV' 
        and dtr_concepto = 'INT'
    where dtr_operacion = @w_ope_sabana
    
    
    select @w_ult_int_pagado = isnull(dtr_monto, 0.0), 
           @w_ult_int_pagado_fecha = isnull(tr_fecha_ref,'01/01/1900')
    from ca_det_trn 
    inner join ca_transaccion 
        on tr_operacion = dtr_operacion 
        and tr_secuencial = dtr_secuencial
        and tr_tran = 'PAG' 
        and tr_estado <> 'RV' 
        and dtr_concepto = 'INT'
    where dtr_operacion = @w_ope_sabana 
    and dtr_secuencial = @w_secuencial
    
    --ACTUALIZANDO DATOS
    Update ##tmp_sabana
    set sr_ult_cap_pagado       = @w_ult_cap_pagado,
        sr_ult_cap_pag_fecha    = @w_ult_cap_pagado_fecha,  
        sr_ult_int_pagado       = @w_ult_int_pagado,  
        sr_ult_int_pag_fecha    = @w_ult_int_pagado_fecha
    where sr_operacion = @w_ope_sabana
    
    if @@error != 0
    begin
        SELECT @w_mensaje = 'Error Actualizando datos de ultimos capitales pagados'
        goto ERROR
    end
    
    if @w_max_operacion = @w_ope_sabana
        break
end            

set rowcount 0

---------------------------------------
-- Insertar de Temporal a real
---------------------------------------
insert ca_sabana_regulatorio
select @w_fec_proceso, *
from ##tmp_sabana

if @@error != 0
begin
    SELECT @w_mensaje = 'Error pasando datos generados de Temporales a Reales'
    goto ERROR
end

----------------------------------------
--	Generar Archivo Plano
----------------------------------------

select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

select @w_path = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 7
		
--select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..##tmp_sabana out '  --LPO TEC ##tmp_sabana no estan cob_cartera se quita esa parte
select @w_cmd = @w_s_app + 's_app bcp -auto -login ##tmp_sabana out '  --LPO TEC ##tmp_sabana no estan cob_cartera se quita esa parte

select 	@w_destino= @w_path + 'SABANA_REGULATORIOS_' +  replace(CONVERT(varchar(10), @w_fec_proceso, @w_ffecha),'/', '')+ '.txt',
	    @w_errores  = @w_path + 'SABANA_REGULATORIOS_' +  replace(CONVERT(varchar(10), @w_fec_proceso, @w_ffecha),'/', '')+ '.err'

select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -T -e ' + @w_errores + ' -t"|" ' + '-config ' + @w_s_app + 's_app.ini'

PRINT ' CMD: ' + @w_comando 

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select
   @w_error = 724681,
   @w_mensaje = 'Error generando Archivo de Sabana de Regulatorios'
   goto ERROR
end


return 0

ERROR:
exec cob_cartera..sp_errorlog 
	@i_fecha        = @w_fec_proceso,
	@i_error        = @w_error,
	@i_usuario      = 'usrbatch',
	@i_tran         = 26004,
	@i_descripcion  = @w_mensaje,
	@i_tran_name    = @w_sp_name,
	@i_rollback     = 'S'
    
return @w_error

go
