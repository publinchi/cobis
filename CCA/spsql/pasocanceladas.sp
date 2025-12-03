/************************************************************************/
/*   Archivo:              pasocanceladas.sp                            */
/*   Stored procedure:     sp_paso_canceladas                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   dic 2006                                     */
/************************************************************************/
/*                          MPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*                         PROPOSITO                                    */
/*   Pasar al fin de mes las canceladas al consolidador                 */
/*   Este programa se basa en un campo de la ca_operacion para el paso  */
/*   op_fecha_ult_mov campo actalizado cuando la oepracion pasa a estado*/
/*   3                                                                  */
/************************************************************************/
/*                       CAMBIOS                                        */
/*   FECHA             AUTOR               CAMBIO                       */
/*                                                                      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_paso_canceladas')
   drop proc sp_paso_canceladas
go

create proc sp_paso_canceladas
@s_date        datetime,      --Fecha de proceso digitada por operador
@s_user        login,
@i_fecha_ini_mes  datetime,
@i_fecha_fin_mes  datetime

as 

declare
@w_error                   int,          
@w_return                  int,    
@w_sp_name                 descripcion,  
@w_fecha1                  datetime,
@w_mes                     smallint,
@w_siguiente_dia           datetime,
@w_mes1                    smallint,
@w_fin_mes                 char(1),
@w_fecha                   datetime,
@w_ciudad                  int,
@w_tasa                    float,
@w_modalidad               char(1),
@w_num_periodicidad        int,
@w_op_operacion            int,   
@w_op_moneda               smallint, 
@w_op_fecha_fin            datetime,   
@w_op_lin_credito          cuenta, 
@w_op_oficial              int,     
@w_op_numero_reest         smallint,
@w_op_banco                cuenta,                
@w_op_cliente              int,              
@w_op_monto                money,                
@w_op_destino              catalogo,     
@w_op_tdividendo           catalogo,           
@w_op_clausula_aplicada    char(1),
@w_op_toperacion           catalogo,   
@w_op_oficina              int,      
@w_op_fecha_liq            datetime,    
@w_op_clase                catalogo,        
@w_op_calificacion         catalogo, 
@w_op_plazo                int,
@w_op_periodo_int          smallint,
@w_tr_fecha_mov            datetime,           
@w_num_cuotas              int,             
@w_tplazo                  catalogo,
@w_periodicidad_cuota      int,
@w_op_fecha_ull_mov        datetime,
@w_dias_plazo              int,
@w_gar_admisible           char(1),
@w_sec                     int,
@w_valor_ult_pago          money,
@w_ccon 		               varchar(30),
@w_sit_castigo 		        varchar(30),
@w_msg_error               varchar(100)


select @w_sp_name              = 'sp_paso_canceladas',
       @w_siguiente_dia        = @s_date,
       @w_error                = 0,
       @w_fin_mes              = 'N'



select @w_siguiente_dia = dateadd(dd,1,@w_siguiente_dia)

exec  sp_dia_habil 
     @i_fecha       = @w_siguiente_dia,
     @i_ciudad      = 11001,  ---BOGOTA
     @o_fecha       = @w_siguiente_dia out



select @w_fecha  = convert(varchar(10),@s_date,101)
select @w_mes    = datepart(mm,@w_fecha)

select @w_fecha1 = convert(varchar(10),@w_siguiente_dia,101)
select @w_mes1   = datepart(mm,@w_fecha1)

if @w_mes1 <> @w_mes 
   select @w_fin_mes = 'S'
else
   select @w_fin_mes = 'N'

if  @w_fin_mes = 'N' 
begin
    PRINT 'No es finde mes'
    return 0
end    

    
if  @w_fin_mes = 'S' 
begin
   
      PRINT 'etro a fin de mes @i_fecha_ini_mes %1! @i_fecha_fin_mes' + @i_fecha_ini_mes + @i_fecha_fin_mes
      
      
      declare cursor_paso_caneladas cursor
      for select distinct can_operacion
      from ca_activas_canceladas
      where can_fecha_can between @i_fecha_ini_mes and @i_fecha_fin_mes
      
      open cursor_paso_caneladas
      
      fetch cursor_paso_caneladas
      into  @w_op_operacion
      
      --while @@fetch_status not in(-1,0)
      while @@fetch_status = 0
      begin
      
         select @w_op_oficina                = op_oficina,
                @w_op_banco                  = op_banco,
                @w_ciudad                    = op_ciudad,
                @w_op_moneda                 = op_moneda,
                @w_op_fecha_fin              = op_fecha_fin,
                @w_op_lin_credito            = op_lin_credito,      
                @w_op_oficial                = op_oficial,          
                @w_op_numero_reest           = op_numero_reest,     
                @w_op_banco                  = op_banco,                
                @w_op_cliente                = op_cliente,          
                @w_op_monto                  = op_monto,               
                @w_op_destino                = op_destino,          
                @w_op_tdividendo             = op_tdividendo,        
                @w_op_clausula_aplicada      = op_clausula_aplicada,
                @w_op_toperacion             = op_toperacion,       
                @w_op_fecha_liq              = op_fecha_liq,        
                @w_op_clase                  = op_clase,            
                @w_op_calificacion           = op_calificacion,     
                @w_op_plazo                  = op_plazo,            
                @w_op_periodo_int            = op_periodo_int,
                @w_op_fecha_ull_mov          = op_fecha_ult_mov,
                @w_gar_admisible             = op_gar_admisible
      
         from ca_operacion
         where op_operacion = @w_op_operacion
         
         ---PRINT 'pasocanceladas.sp' +@w_op_banco
         
         select @w_tasa = ro_porcentaje_efa,
                @w_modalidad = ro_fpago
         from   ca_rubro_op
         where  ro_operacion   = @w_op_operacion
         and    ro_fpago      in ('P','A')
         and    ro_tipo_rubro  = 'I'
         
         select @w_tasa = isnull(@w_tasa,0)
     
         
            
         -- PERIODICIDAD DE LA OPERACION
         select @w_num_periodicidad = td_factor
         from   ca_tdividendo
         where  td_tdividendo = @w_tplazo
         
         select @w_periodicidad_cuota = @w_op_plazo * @w_num_periodicidad
         
         
         if @w_modalidad = 'P'
            select @w_modalidad = 'V'
         else 
            select @w_modalidad = 'A'
            

         select @w_dias_plazo = sum(di_dias_cuota)
         from   ca_dividendo
         where  di_operacion = @w_op_operacion
         and    di_dividendo > 0

         select @w_num_cuotas = count(1)
         from   ca_dividendo
         where  di_operacion = @w_op_operacion


         select @w_sec = isnull(max(ab_secuencial_ing),0)
         from   ca_abono
         where  ab_operacion = @w_op_operacion
         and    ab_tipo = 'PAG'
         and    ab_estado != 'RV'
         
         select @w_valor_ult_pago = sum(abd_monto_mn)
         from   ca_abono, ca_abono_det
         where  ab_operacion = @w_op_operacion
         and    ab_tipo = 'PAG'
         and    ab_estado != 'RV'
         and    ab_secuencial_ing = @w_sec
         and    abd_operacion = ab_operacion
         and    abd_secuencial_ing = ab_secuencial_ing
         and    abd_tipo = 'PAG'

         select @w_ccon = pa_char
         from   cobis..cl_parametro 
         where  pa_nemonico = 'CCON' 
         and    pa_producto = 'CRE'
         set transaction isolation level read uncommitted 

         --SITUACION DE CASTIGO
         select @w_sit_castigo = pa_char
         from   cobis..cl_parametro 
         where  pa_nemonico = 'SITCS' 
         and    pa_producto = 'CRE'
         set transaction isolation level read uncommitted                 
                       
            
        exec @w_return = cob_credito..sp_tmp_datooper
        @s_date                     = @s_date,
        @i_numero_operacion         = @w_op_operacion,
        @i_numero_operacion_banco   = @w_op_banco,
        @i_tipo_operacion           = @w_op_toperacion,
        @i_codigo_producto          = 7,
        @i_codigo_cliente           = @w_op_cliente,
        @i_oficina                  = @w_op_oficina,
        @i_moneda                   = @w_op_moneda,
        @i_monto                    = @w_op_monto,
        @i_tasa                     = @w_tasa,
        @i_periodicidad             = @w_num_periodicidad,
        @i_modalidad                = @w_modalidad,
        @i_fecha_concesion          = @w_op_fecha_liq,
        @i_fecha_vencimiento        = @w_op_fecha_fin,
        @i_dias_vto_div             = 0,
        @i_fecha_vto_div            = @w_op_fecha_fin,
        @i_reestructuracion         = 'N',
        @i_no_renovacion            = 0,
        @i_codigo_destino           = @w_op_destino,
        @i_clase_cartera            = @w_op_clase,
        @i_codigo_geografico        = @w_ciudad,
        @i_fecha_prox_vto           = @w_op_fecha_fin,
        @i_saldo_prox_vto           = 0,
        @i_saldo_cap                = 0,
        @i_saldo_int                = 0,
        @i_saldo_otros              = 0,
        @i_saldo_int_contingente    = 0,
        @i_estado_contable          = 4,
        @i_estado_desembolso        = 'N',
        @i_estado_terminos          = 'N',
        @i_calificacion             = @w_op_calificacion,
        @i_saldo_orden              = null,
        @i_saldo_deuda              = null,
        @i_linea_credito            = @w_op_lin_credito,
        @i_periodicidad_cuota       = @w_periodicidad_cuota,
        @i_edad_mora                = 0,
        @i_valor_mora               = 0,
        @i_fecha_pago               = @w_op_fecha_ull_mov,
        @i_valor_cuota              = 0,
        @i_cuotas_pag               = 0,
        @i_estado_cartera           = 3,
        @i_dias_plazo               = @w_dias_plazo,
        @i_gerente                  = @w_op_oficial,
        @i_num_cuotaven             = 0,
        @i_saldo_cuotaven           = 0,
        @i_admisible                = @w_gar_admisible,
        @i_num_cuotas               = @w_num_cuotas,
        @i_valor_ult_pago           = @w_valor_ult_pago,
        @i_tipo_cambio              = 'N',
        @i_num_reest                = @w_op_numero_reest,
        @i_probabilidad_default     = 0,
        @i_capsusxcor               = 0,
        @i_intsusxcor               = 0,
        @i_ccon                     = @w_ccon,
        @i_sit_castigo	            = @w_sit_castigo,
        @i_fecha                    = @s_date,
        @i_clausula                 = @w_op_clausula_aplicada

 /*Mroa: Comentado por solicitud de Rafael Molano  
         if @w_return != 0
         begin

              PRINT 'pasocancelada.sp error paso de cancelada' + @w_op_banco
              select @w_msg_error = 'pasocancelada.sp error ejecuacion cob_credito..sp_tmp_datooper'
              exec @w_error=cob_ccontable..sp_conauac          
                    @i_empresa         =    1,         
                    @i_producto        =    7,         
                    @i_fecha           =    @s_date,         
                    @i_moneda          =    @w_op_moneda,         
                    @i_referencia      =    @w_op_operacion,         
                    @i_capital         =    0,         
                    @i_saldo_interres  =    0,         
                    @i_saldo_otros     =    0,         
                    @i_contingentes    =    0,         
                    @i_operacion       =    'E',
                    @i_origen          =    'A',          
                    @i_cod_err         =    @w_error,         
                    @i_descripcion_err =    @w_msg_error  
              
         end
         else
          exec @w_error=cob_ccontable..sp_conauac          
                @i_empresa         =    1,         
                @i_producto        =    7,         
                @i_fecha           =    @s_date,         
                @i_moneda          =    @w_op_moneda,         
                @i_referencia      =    @w_op_operacion,         
                @i_capital         =    0,         
                @i_saldo_interres  =    0,         
                @i_saldo_otros     =    0,         
                @i_contingentes    =    0,         
                @i_operacion       =    'I',
                @i_origen          =    'A'                
        
   */
         fetch cursor_paso_caneladas
         into  @w_op_operacion
      
      
      end --while @@fetch_status = 0
   
   close cursor_paso_caneladas
   deallocate cursor_paso_caneladas

end  


return 0
      
go
