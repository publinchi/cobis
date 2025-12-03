/************************************************************************/
/*      Archivo:                ca_recons_seguros.sp                    */
/*      Stored procedure:       sp_recons_seguros                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Fecha de escritura:     Enero 2014                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/* Reconstruye la tabla de amortizacion de seguros de una operacion     */ 
/* ya desembolsada                                                      */ 
/************************************************************************/
/*                              CAMBIOS                                 */
/*  FECHA     AUTOR             RAZON                                   */
/*  27-Ene-14 Luis Guzman       Emisión Inicial - Req: 403              */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_recons_seguros')
   drop proc sp_recons_seguros
go

create proc sp_recons_seguros
@i_operacion int

as
declare
   @w_operacion             int,
   @w_tramite               int,   
   @w_monto                 money,
   @w_pagos                 int,
   @w_error                 int,
   @w_sp_name               varchar(64),
   @w_gen_hasta             int,
   @w_gen_desde             int,
   @w_gen_desde_original    int,
   @w_saldo_capital         money,
   @w_valor_cuota_cap_tot   money,
   @w_tasa_efa              float,
   @w_est_vigente           int,
   @w_est_vencido           int,
   @w_est_cancelado         int,
   @w_est_novigente         int,
   @w_tasa_seg_desem        float,
   @w_ro_porcentaje_efa     float,
   @w_ro_porcentaje         float,
   @w_monto_poliza          money,
   @w_plan                  int,
   @w_sec_seguro            int,
   @w_tipo_seguro           int,
   @w_sec_renovacion        int,
   @w_tipo_asegurado        int,
   @w_sec_asegurado         int,
   @w_plazo_seguro          int,
   @w_pagos_poliza          int,
   @w_vlr_cuota             money,
   @w_valor_cuota_cap       money,
   @w_valor_cuota_int       money,
   @w_ro_fpago              char(1),
   @w_ro_num_dec            tinyint,
   @w_di_dias_cuota         int,
   @w_porcentaje_int        float,
   @w_factor                float,
   @w_capital_inicial       money,
   @w_cuota_fija            money,
   @w_fecha_proceso         datetime,
   @w_msg                   varchar(255)
   
set nocount on

-- INICIALIZA VARIABLES
Select @w_gen_hasta           = 0,
       @w_gen_desde           = 0,       
       @w_saldo_capital       = 0,
       @w_valor_cuota_cap_tot = 0,              
       @w_tasa_efa            = 0       

-- OBTIENE FECHA DE PROCESO
select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

if @@rowcount = 0
begin
   select @w_msg = 'Error al leer fecha de proceso de cartera',
          @w_error = 801085
   goto ERROR
end

-- ESTADOS DE CARTERA
exec @w_error    = sp_estados_cca
@o_est_vigente   = @w_est_vigente   out,
@o_est_vencido   = @w_est_vencido   out,
@o_est_cancelado = @w_est_cancelado out,
@o_est_novigente = @w_est_novigente out

if @@ERROR <> 0 
begin
   select @w_error = @w_error,
          @w_msg   = 'Error al consultar estados de cartera'
   goto ERROR
end         

-- OBTENER DATOS DEL TRAMITE Y/O BANCO RECIBIDO
select @w_operacion     = op_operacion,
       @w_tramite       = op_tramite,       	   
	   @w_monto         = op_monto	   
from cob_cartera..ca_operacion
where op_operacion = @i_operacion

if @@rowcount = 0 
begin
   print 'NO SE ENCUENTRAN DATOS DEL TRAMITE'
   goto ERROR
end

-- OBTENER NUMERO DE PAGOS PARA LA POLIZA
select @w_pagos = count(1) 
from ca_dividendo 
where di_operacion = @w_operacion
and   di_estado   <> @w_est_cancelado        

-- OBTENER CUOTA HASTA DONDE GENERAR
select @w_gen_hasta = isnull(max(di_dividendo) ,0)
from ca_dividendo 
where di_operacion = @w_operacion

select @w_gen_desde = @w_gen_hasta

-- OBTENER CUOTA DESDE DONDE GENERAR
select @w_gen_desde = isnull(min(di_dividendo) ,0)
from ca_dividendo 
where di_operacion = @w_operacion

select @w_gen_desde_original = @w_gen_desde

-- Buscar Tasa de la Obligacion
select @w_tasa_seg_desem    = 0
       
select top 1 @w_tasa_seg_desem = isnull(ro_porcentaje,0)       
from cob_cartera..ca_rubro_op
where ro_operacion = @w_operacion
and ro_concepto in ('SEGVIDIND', 'SEGVIDPRI', 'SEGEXEQ', 'SEGDAMAT')

-- CREAR TABLAS TEMPORALES DE TRABAJO

create table #seguros(
se_sec_seguro        int         null,
se_tipo_seguro       int         null,
se_sec_renovacion    int         null,
se_tipo_asegurado    int         null,
se_plan              int         null,
se_tramite           int         null,
se_operacion         int         null,
se_monto             money       null,
se_tasa              float       null,
se_fec_devolucion    datetime    null,
se_mto_devolucion    money       null,
se_estado            char(1)     null,
se_sec_asegurado     int         null,
se_plazo_seguro      int         null
)

select * into #seguros_det from cob_cartera..ca_seguros_det  where 1 = 2

insert into #seguros
select 
se_sec_seguro          = st_secuencial_seguro,
se_tipo_seguro         = st_tipo_seguro        ,   
se_sec_renovacion      = 0                     ,
se_tipo_asegurado      = as_tipo_aseg          ,
se_plan                = as_plan               ,
se_tramite             = @w_tramite            ,
se_operacion           = @w_operacion          ,
se_monto               = 0                     ,
se_tasa                = @w_tasa_seg_desem     ,
se_fec_devolucion      = null                  ,
se_mto_devolucion      = null                  ,
se_estado              = 'I'                   ,
se_sec_asegurado       = as_sec_asegurado      ,
se_plazo_seguro        = datediff(mm,as_fecha_ini_cobertura,as_fecha_fin_cobertura)
from cob_credito..cr_seguros_tramite, cob_credito..cr_asegurados
where st_tramite = @w_tramite         
and st_secuencial_seguro = as_secuencial_seguro
and as_tipo_aseg = (case when st_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)         
   
if @@error <> 0 
begin
   select @w_msg   = 'No se pudo insertar a #seguros desde cr_seguros_tramite',
          @w_error = 801085
   goto ERROR

end		 		 	   

delete from #seguros
where se_tipo_seguro in (select sec_tipo_seguro 
                         from ca_seguros_can,#seguros 
                         where sec_tramite     = se_tramite 
                         and   sec_tipo_seguro = se_tipo_seguro)
   
if @@error <> 0 
begin 
   select @w_msg = 'No Se Pudo Eliminar Tramites Cancelados',
          @w_error = 708155
   goto ERROR
end		       

-- ACTUALIZA EL MONTO Y LA TASA DE ACUERDO AL PLAN OBTENIDO
update a set
a.se_monto = isnull(b.ps_valor_mensual,0)
from #seguros a, cob_credito..cr_plan_seguros_vs b
where b.ps_codigo_plan = a.se_plan
and b.ps_tipo_seguro   = a.se_tipo_seguro
and ps_estado = 'V'

if @@error <> 0 
begin
   select @w_msg   = 'No se pudo actualizar valor mensual de tipo de seguro',
          @w_error = 708152
   goto ERROR
end	  

delete from #seguros
where se_monto = 0

if @@error <> 0 
begin 
   select @w_msg = 'No Se Pudo Eliminar Tramites con Monto Iguales a Cero',
          @w_error = 708155
   goto ERROR
end		       

if exists (select 1 from ca_seguros where se_tramite = @w_tramite)
begin
      
   delete ca_seguros_det 
   from ca_seguros
   where sed_sec_seguro = se_sec_seguro
   and   se_tramite     = @w_tramite
   and   se_operacion   = @w_operacion
   
   if @@error <> 0 
   begin 
      select @w_msg = 'No se pudo eliminar los registros relacionados al tramite, ca_seguros_det',
             @w_error = 708155
      goto ERROR
   end		 
                           
   delete from ca_seguros
   where se_tramite   = @w_tramite
   and   se_operacion = @w_operacion
  
   if @@error <> 0 
   begin
      select @w_msg = 'No se pudo eliminar los registros relacionados al tramite, ca_seguros',
      @w_error = 708155
      goto ERROR
   end      
end

-- PASO DE DATOS A TABLA DEFINITIVA
insert into ca_seguros (
se_sec_seguro    , se_tipo_seguro   , se_sec_renovacion, 
se_tramite       , se_operacion     , se_fec_devolucion, 
se_mto_devolucion, se_estado
)
select distinct
se_sec_seguro    , se_tipo_seguro   , se_sec_renovacion, 
se_tramite       , se_operacion     , se_fec_devolucion, 
se_mto_devolucion, se_estado 
from  #seguros

if @@error <> 0 
begin
   select @w_msg   = 'No se pudo insertar en ca_seguros desde #seguros',
          @w_error = 708154
   goto ERROR
end	  

while 1 = 1                                --> realiza el proceso de cada seguro por cada tipo y asegurado
begin
   set rowcount 1
   select @w_monto_poliza   = se_monto,
          @w_tasa_efa       = se_tasa,
          @w_plan           = se_plan,
          @w_sec_seguro     = se_sec_seguro,
          @w_tipo_seguro    = se_tipo_seguro,
          @w_sec_renovacion = se_sec_renovacion, 
          @w_tipo_asegurado = se_tipo_asegurado,
          @w_sec_asegurado  = se_sec_asegurado,
          @w_plazo_seguro   = se_plazo_seguro
   from #seguros
   where se_estado = 'I'
   order by se_sec_seguro,se_tipo_seguro,se_tipo_asegurado, se_sec_asegurado
   
   if @@rowcount = 0 break
   
   set rowcount 0
   
   select 
   @w_pagos_poliza  = (@w_gen_hasta + 1 ) - @w_gen_desde ,            --> Pagos de la poliza basados en el plazo pendiente de la obligacion
   @w_vlr_cuota     = round(@w_monto_poliza,0),                       --> Valor de la cuota (K) basada en el plazo pendiente del asegurado      
   @w_valor_cuota_cap = @w_vlr_cuota,
   @w_valor_cuota_int = 0	                                          --> Valor de la cuota (I) basada en el plazo pendiente del asegurado	     
   
   -- BUSCA FORMA DE PAGO DE LA OPERACION EN LA TEMPORAL
   select 
   @w_ro_fpago    = ro_fpago,
   @w_ro_num_dec  = ro_num_dec
   from cob_cartera..ca_rubro_op
   where ro_operacion = @w_operacion 
   and ro_concepto in ('INT')
   and ro_fpago    in ('P','A','T')
      
   if @w_ro_fpago in ('P', 'T')
      select @w_ro_fpago = 'V'		
	  		     			
   -- BUSCA DIAS DE LA CUOTA EN AL TAMPORAL
   select @w_di_dias_cuota = di_dias_cuota
   from cob_cartera..ca_dividendo
   where di_operacion = @w_operacion
   and   di_dividendo >= 1			 
   
   -- CALCULAR LA TASA EQUIVALENTE
   exec @w_error = sp_conversion_tasas_int
   @i_periodo_o       = 'A',
   @i_modalidad_o     = 'V',
   @i_num_periodo_o   = 1,
   @i_tasa_o          = @w_tasa_efa,
   @i_periodo_d       = 'D',
   @i_modalidad_d     = @w_ro_fpago,
   @i_num_periodo_d   = @w_di_dias_cuota,
   @i_dias_anio       = 360,
   @i_num_dec         = @w_ro_num_dec,
   @o_tasa_d          = @w_porcentaje_int output
      
   if @w_error <> 0 
   begin
      select @w_msg = 'Error en conversion de tasa',
             @w_error = @w_error
      goto ERROR
   end		 
   
   select @w_porcentaje_int = isnull((round(@w_porcentaje_int/12,2) / 100),0)	  -- Devuelve el Interes Nominal Mensual
   select @w_factor = isnull(power(1 + @w_porcentaje_int,@w_pagos_poliza),0)       -- Ayuda a determinar la cuota fija de acuerdo INT Vs Plazo
   
   select @w_capital_inicial = (@w_vlr_cuota * @w_plazo_seguro)
   
   if @w_porcentaje_int = 0 
   begin
      select @w_cuota_fija = @w_capital_inicial
   end 
   else 
   begin
   select @w_cuota_fija = (@w_porcentaje_int*@w_factor*@w_capital_inicial)/(@w_factor-1),
          @w_cuota_fija = round(@w_cuota_fija,0)
   end	  	  	     
   
   if @w_valor_cuota_cap < 0 
      select @w_valor_cuota_cap = 0 
      
   if @w_vlr_cuota < 0 
      select @w_vlr_cuota = 0       
      
   while @w_gen_desde <= @w_gen_hasta    --> Generacion Tabla de Amortizacion de Seguros ca_seguros_det
   begin   
                                 
      select @w_valor_cuota_int = round((@w_capital_inicial * @w_porcentaje_int),0)
         
      if @w_gen_desde = @w_gen_hasta 
      begin
            
         select @w_monto_poliza    = round(@w_monto_poliza * @w_plazo_seguro,0),
                @w_valor_cuota_cap = round(@w_monto_poliza - @w_valor_cuota_cap_tot,0)	           
         
      end
      else 
      begin
         select @w_valor_cuota_cap = round((@w_cuota_fija - @w_valor_cuota_int),0),
                @w_saldo_capital   = round(@w_capital_inicial - @w_valor_cuota_cap,0)
      end
         
      insert into #seguros_det(
      sed_operacion,      sed_sec_seguro,     sed_tipo_seguro, 
      sed_sec_renovacion, sed_tipo_asegurado, sed_estado,
      sed_dividendo,      sed_cuota_cap,      sed_pago_cap,
      sed_cuota_int,      sed_pago_int,       sed_cuota_mora,
      sed_pago_mora,      sed_sec_asegurado                          
      )		 
      values (
      @w_operacion,       @w_sec_seguro,      @w_tipo_seguro, 
      @w_sec_renovacion,  @w_tipo_asegurado,  1, 
      @w_gen_desde,       @w_valor_cuota_cap, 0, 
      @w_valor_cuota_int, 0,                  0, 
      0,                  @w_sec_asegurado                           
      )
         
      select @w_capital_inicial     = @w_saldo_capital,		 		 
             @w_valor_cuota_cap_tot = @w_valor_cuota_cap_tot + @w_valor_cuota_cap
       
      select @w_gen_desde = @w_gen_desde + 1
		 
   end  --> Fin Generacion Tabla de Amortizacion de Seguros ca_seguros_Det
      
   select @w_gen_desde = @w_gen_desde_original
      
   select @w_valor_cuota_cap_tot = 0                   -- Inicializa nuevamente en cero para los siguientes seguros
      
   -- PASO DETALLE A DEFINITIVAS
   insert into ca_seguros_det 
   select * from #seguros_det
      
   if @@error <> 0 
   begin
      select @w_msg   = 'Error en paso detalle de definitivas - ca_seguros_det',
             @w_error = 708154
      goto ERROR
   end		 
                
   update #seguros set se_estado = 'P' 
   where se_sec_seguro   = @w_sec_seguro
   and se_tipo_seguro    = @w_tipo_seguro
   and se_sec_renovacion = @w_sec_renovacion
   and se_tipo_asegurado = @w_tipo_asegurado
   and se_sec_asegurado  = @w_sec_asegurado
   and se_estado         = 'I'
      
   if @@error <> 0 
   begin 
      select @w_msg = 'Error actualizando estado #seguros'
      select @w_error = 708152
      goto ERROR
   end
   
   delete #seguros_det   
   
end
  
set rowcount 0  

--ACTUALIZA LOS PAGOS DE LAS OPERACIONES PROCESADAS
update ca_seguros_det set
sed_pago_cap = sed_cuota_cap
from cob_cartera..ca_amortizacion
where am_operacion  = @i_operacion
and   am_concepto   in ('CAP')
and   am_estado     = 3
and   sed_dividendo = am_dividendo
and   sed_operacion = am_operacion

if @@error <> 0 
begin
   print 'Error actualizando pago capital'
   return 708152  
end   

update ca_seguros_det set
sed_pago_int = sed_cuota_int
from cob_cartera..ca_amortizacion
where am_operacion  = @i_operacion
and   am_concepto   in ('INT')
and   am_estado     = 3
and   sed_dividendo = am_dividendo
and   sed_operacion = am_operacion

if @@error <> 0 
begin
   print 'Error actualizando pago interes'
   return 708152  
end   

--ACTUALIZA LOS ESTADOS DE ACUERDO A LOS PAGOS

update ca_seguros_det set 
sed_estado = 3
where sed_pago_cap  >= sed_cuota_cap 
and   sed_pago_int  >= sed_cuota_int
and   sed_operacion = @i_operacion
   
if @@error <> 0 
begin
   print 'Error actualizando estados para cancelacion de cuotas'
   return 708152  
end   

return 0

ERROR:

exec cob_cartera..sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = @w_error, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return @w_error
go
