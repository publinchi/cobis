
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_regenera_condiciones') 
   drop proc sp_regenera_condiciones
go

create proc sp_regenera_condiciones(
@i_operacion  int,
@i_tasa       float,
@i_FNG        float   
)
as
declare @w_fecha     datetime,
        @w_operacion int,
        @w_fecha_des datetime,
        @w_banco     varchar(20),
        @w_estado    int,
        @w_return    int,
        @w_new_banco varchar(20),
        @w_respuesta char(1),
        @w_secdesem  int,
        @w_oficina   int

   select @w_fecha     = op_fecha_ult_proceso,
          @w_banco     = op_banco,
          @w_estado    = op_estado,
          @w_fecha_des = op_fecha_liq,
          @w_oficina   = op_oficina
   from ca_operacion
   where op_operacion = @i_operacion

   delete ca_operacion_tmp
   where opt_operacion = @i_operacion
 
   -- Fecha Valor al desembolso

   exec @w_return = sp_fecha_valor 
   @s_user              = 'sa',        
   @s_term              = 'Terminal', 
   @s_date              = @w_fecha,
   @i_banco             = @w_banco,
   @i_operacion         = 'F',
   @i_fecha_valor       = @w_fecha_des,
   @i_en_linea          = 'S',
   @i_control_fecha     = 'N',
   @i_debug             = 'S'

   if @w_return != 0 begin
      print ' Error en Fecha Valor ' + cast(@w_banco as varchar)
      goto ERROR
   end
    
   exec @w_return = sp_crear_tmp
   @s_user            = 'sa',
   @s_term            = 'term',
   @i_banco           = @w_banco,
   @i_bloquear_salida = 'N',
   @i_accion          = 'A'

   if @w_return != 0 begin
      print ' Error al Generar Temporal ' + cast(@w_banco as varchar)
      goto ERROR
   end

   -- Actualiza Tasa si es requerida
   if @i_tasa > 0 begin
      update ca_operacion_tmp set
      opt_clase = '1', opt_sector = '1'
      where opt_operacion = @i_operacion
   end

   --Elimina los rubros solicitados
   delete ca_rubro_op_tmp
   where rot_operacion = @i_operacion 
   and   rot_concepto in ('IVAMIPYMES','MIPYMES')
      
   delete ca_amortizacion_tmp
   where amt_operacion = @i_operacion


   exec @w_return = sp_modificar_operacion_int
   @s_user              = 'sa',
   @s_sesn              = 1,
   @s_date              = @w_fecha,
   @s_ofi               = @w_oficina,
   @s_term              = 'term',
   @i_calcular_tabla    = 'S', 
   @i_tabla_nueva       = 'S',
   @i_salida            = 'N',
   @i_operacionca       = @i_operacion,
   @i_banco             = @w_banco,
   @i_cuota             = 0
             
   if @w_return != 0 begin
      print ' Error en Modificar Operacion ' + cast(@w_banco as varchar)
      goto ERROR
   end

   exec @w_return = sp_calculo_fng_porcentaje
   @i_operacion      = @i_operacion,
   @i_porcentaje     = @i_FNG

   if @w_return != 0 begin
      print ' Error al Generar FNG con nuevo valor' + cast(@w_banco as varchar)
      goto ERROR
   end

   if @i_tasa > 0 begin
      update ca_operacion_tmp set
      opt_clase = '4', opt_sector = '4'
      where opt_operacion = @i_operacion
   end

   update ca_amortizacion_tmp set
   amt_estado = 1
   where amt_operacion = @i_operacion
   and   amt_dividendo = 1

   update ca_dividendo_tmp set
   dit_estado = 1
   where dit_operacion = @i_operacion
   and   dit_dividendo = 1

   exec @w_return = sp_pasodef
        @i_banco           = @w_banco,
        @i_operacionca     = 'S',
        @i_dividendo       = 'S',
        @i_amortizacion    = 'S',
        @i_cuota_adicional = 'S',
        @i_rubro_op        = 'S',
        @i_relacion_ptmo   = 'S',
        @i_nomina          = 'S',
        @i_acciones        = 'S',
        @i_valores         = 'S'
        
   if @w_return != 0 begin
      print ' Error en Paso a Definitivas ' + cast(@w_banco as varchar)
      goto ERROR
   end


ERROR:
return @w_return

go

/*

exec cob_cartera..sp_regenera_condiciones
@i_operacion  = 857924 ,
@i_tasa       = 2,
@i_FNG        = 1.5   

*/