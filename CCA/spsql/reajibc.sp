/************************************************************************/
/*   Archivo:             reajibc.sp                                    */
/*   Stored procedure:    sp_reajuste_ibc                               */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        P. Narvaez                                    */
/*   Fecha de escritura:   25/Mayo/98                                   */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                              PROPOSITO                               */
/*   Transforma las tasas de reajuste a Efectivo Anual(Anual Vencido)   */
/*   Compara si es mayor que el 1.5 del IBC, genrea un error            */
/*   del porque no se reajusto                                          */
/************************************************************************/  
/*                        MODIFICACIONES                                */
/*  FECHA                 AUTOR          CAMBIOS                        */
/*  03-FEB-2020           Luis Ponce    Ajustes Migracion Core Digital  */
/*  03-ABR-2020           Luis Ponce    CDIG No manejar tasa equivalente*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reajuste_ibc')
   drop proc sp_reajuste_ibc
go

---Inc. 22120 partiendo de La ver. 7 Junio-13-2011

create proc sp_reajuste_ibc
   @i_operacionca      int,
   @i_secuencial       int,
   @i_fecha_proceso    datetime,
   @i_moneda_uvr       tinyint,
   @i_moneda_local     tinyint,
   @o_reajustar        char(1) out
as
declare 
   @w_return                     int,
   @w_error                      int,
   @w_concepto                   catalogo,
   @w_valor_referencial          money,
   @w_porcentaje                 float,
   @w_porcentaje_efa             float,
   @w_porcentaje_aux             float,
   @w_tasa_efe_anual             float,
   @w_referencial                catalogo,
   @w_modalidad_op               char(1),
   @w_periodicidad_op            catalogo,
   @w_factor                     float,
   @w_signo                      char(1),
   @w_sector                     catalogo,
   @w_dias_anio                  smallint,
   @w_base_calculo               char(1),
   @w_di_vigente                 smallint,
   @w_fpago                      char(1),
   @w_num_periodo_int            smallint,
   @w_valor_reajuste             float,
   @w_valor_rubro                float,
   @w_rubros                     tinyint,
   @w_tot_parcial                float,
   @w_contador                   tinyint,
   @w_cliente                    int,
   @w_tcero                      varchar(10),
   @w_fecha_di_ven               datetime,
   @w_dias_cuota                 int,
   @w_tipo_tasa                  char(1),
   @w_tipo_puntos                char(1),
   @w_usar_tasa_eq               char(1),
   @w_moneda                     int,
   @w_porcentaje_org             float,
   @w_num_dec_tapl               tinyint,
   @w_convertir_tasa             char(1),
   @w_tasa_referencial           catalogo,
   @w_banco                      cuenta,
   @w_tasa_anterior              float,
   @w_descripcion                descripcion,
   @w_clase                      char(1),
   @w_tipopuntos                 char(1),
   @w_porcentaje_red             float,
   @w_fecha                      datetime,
   @w_valor_tasa_ref             float,
   @w_fecha_tasaref              datetime,
   @w_ts_tasa_ref                catalogo,
   @w_op_clase                   char,
   @w_di_dias_cuota              int,
   @w_di_fecha_ini               datetime,
   @w_di_fecha_ven               datetime,
   @w_secuencial                 int,
   @w_sec_tasas                  int,
   @w_fec_tasas                  datetime,
   @w_ro_porcentaje_efa          float,
   @w_iden_ref                   char(3),
   @w_re_reajuste_especial       char(1),
   @w_fecha_hoy                  datetime

   
/* DETERMINAR EL SECUENCIAL DEL REAJUSTE */   
select @w_secuencial = isnull(max(re_secuencial),0)
from ca_reajuste
where re_operacion = @i_operacionca
and   re_fecha     = @i_fecha_proceso


if @w_secuencial = 0 return 0  -- si no hay reajuste salir

select @w_tipopuntos     = re_desagio
from ca_reajuste
where re_operacion  = @i_operacionca
and   re_fecha      = @i_fecha_proceso
and   re_secuencial = @w_secuencial

   
-- DATOS DE LA OPERACION
select 
@w_sector          = op_sector,
@w_dias_anio       = op_dias_anio,
@w_base_calculo    = op_base_calculo,
@w_num_periodo_int = op_periodo_int,
@w_periodicidad_op = op_tdividendo,
@w_usar_tasa_eq    = op_usar_tequivalente,
@w_cliente         = op_cliente,
@w_moneda          = op_moneda,
@w_convertir_tasa  = op_convierte_tasa,
@w_banco           = op_banco,
@w_op_clase        = op_clase,
@w_re_reajuste_especial = op_reajuste_especial
from   ca_operacion with (nolock)
where  op_operacion = @i_operacionca

select 
@w_di_vigente    = di_dividendo,
@w_fecha_di_ven  = di_fecha_ven
from   ca_dividendo with (nolock)
where  di_operacion = @i_operacionca
and    di_estado    = 1 
        
-- CONTROLAR SI HOY VENCE EL DIVIDENDO VIGENTE
if @w_fecha_di_ven = @i_fecha_proceso  select @w_di_vigente = @w_di_vigente + 1

select 
@w_di_dias_cuota = di_dias_cuota,
@w_di_fecha_ini  = di_fecha_ini,
@w_di_fecha_ven  = di_fecha_ven
from   ca_dividendo with (nolock)
where  di_operacion = @i_operacionca
and    di_dividendo = @w_di_vigente



-- LAZO DE TODOS LOS RUBROS TIPO INTERES DE ca_rubro_op
declare rubro cursor for select 
ro_concepto,    ro_porcentaje_aux,   ro_fpago, 
ro_tipo_puntos, ro_num_dec,          ro_porcentaje_efa
from  ca_rubro_op with (nolock)
where ro_operacion  = @i_operacionca
and   ro_tipo_rubro = 'I' 
for read only

open rubro 

fetch rubro into  
@w_concepto,    @w_porcentaje_aux,   @w_fpago, 
@w_tipo_puntos, @w_num_dec_tapl,     @w_ro_porcentaje_efa

if (@@fetch_status != 0) begin
   close rubro
   deallocate rubro
   return 0    -- NO EXISTEN RUBROS TIPO INTERES PARA EL CALCULO
end

while(@@fetch_status = 0)  begin

   -- DATOS DE TABLAS  DE REAJUSTE
   select 
   @w_referencial    = red_referencial,
   @w_signo          = red_signo,
   @w_factor         = red_factor,
   @w_porcentaje_red = isnull(red_porcentaje, 0) --Porcentaje ingresado directamente, sin Tasa Referencial
   from   ca_reajuste_det with (nolock)
   where  red_operacion  = @i_operacionca
   and    red_concepto   = @w_concepto
   and    red_secuencial = @w_secuencial
   
   if @@rowcount = 0 goto SIG_RUBRO

   if @w_fpago = 'P'
      select @w_modalidad_op   = 'V'
   else
      select @w_modalidad_op   = 'A'
   
   select @w_tasa_anterior = @w_porcentaje_aux  --Tasa Original del INT
   
   
   if @w_factor > 0 begin
      if @w_tipopuntos is null or @w_tipopuntos = '' select @w_tipopuntos = 'B'
   end
   
   if @w_referencial is not null and isnull(@w_porcentaje_red, 0) = 0 begin         -- REQ 175:PEQUEÑA EMPRESA - isnull(@w_porcentaje_red, 0) = 0
   
      -- SACAR LA CLASE DE TASA
      select @w_clase = va_clase
      from   ca_valor with (nolock)
      where  va_tipo = @w_referencial
      
      if @w_clase = 'V' begin  
         select @w_porcentaje = vd_valor_default
         from   ca_valor_det with (nolock)
         where  vd_tipo = @w_referencial
         and    vd_sector = @w_sector
      end
      
      if @w_clase = 'F' begin
        
         exec @w_return = sp_tasas_actuales
         @i_operacionca       =  @i_operacionca,
         @i_referencia        =  @w_referencial,
         @i_concepto          =  @w_concepto,
         @i_reajuste          =  'S',
         @i_fecha_proceso     =  @i_fecha_proceso,
         @o_tasa_nom          =  @w_porcentaje     OUTPUT,
         @o_tasa_efa          =  @w_porcentaje_efa OUTPUT,
         @o_valor_tasa_ref    =  @w_valor_tasa_ref OUTPUT,
         @o_fecha_tasa_ref    =  @w_fecha_tasaref  OUTPUT,
         @o_ts_tasa_ref       =  @w_ts_tasa_ref    OUTPUT
         
         if @w_return != 0 
         BEGIN --LPO manejo de errores dentro de un cursor
            close rubro
            deallocate rubro
            return @w_return
         END

         
      end -- clase F
      
   end ELSE begin  -- Referencial es Null. Reajustar a el porcentaje directo (que es un valor efectivo anual)

      exec @w_return =  sp_conversion_tasas_int
      @i_dias_anio      = @w_dias_anio,
      @i_base_calculo   = @w_base_calculo,
      @i_periodo_o      = 'A',
      @i_num_periodo_o  = 1,
      @i_modalidad_o    = 'V',
      @i_tasa_o         = @w_porcentaje_red,
      @i_periodo_d      = 'A', --'D', --LPO CDIG No manejar tasa equivalente
      @i_num_periodo_d  = 1, --@w_di_dias_cuota, -- A LA MODALIDAD DE LA CUOTA --LPO CDIG No manejar tasa equivalente
      @i_modalidad_d    = 'V', --@w_modalidad_op, --LPO CDIG No manejar tasa equivalente
      @i_num_dec        = @w_num_dec_tapl,
      @o_tasa_d         = @w_porcentaje  output   ---Nominal del valor dado
      
         if @w_return != 0 
         BEGIN --LPO manejo de errores dentro de un cursor
            close rubro
            deallocate rubro
            return @w_return
         END

      
      select @w_porcentaje_efa = @w_porcentaje_red,
             @w_porcentaje = @w_porcentaje_red  --LPO CDIG No manejar tasa equivalente
      
   end
   
   --  OBTENCION DE LA TASA QUE SE VA A MANTENER COMO TASA ORIGINAL... ro_porcentaje_aux
   
   if @w_referencial is not null
      select @w_porcentaje_aux = @w_porcentaje
   else
      select @w_porcentaje_aux = @w_porcentaje_red
   
   
   if abs(@w_ro_porcentaje_efa - @w_porcentaje_efa) < 0.0001
      select @o_reajustar = 'N' 
   else
      select @o_reajustar = 'S'
   
   if @w_porcentaje < 0
      select 
      @w_porcentaje     = 0,
      @w_porcentaje_efa = 0
      
 
   select 
   @w_porcentaje     = round(@w_porcentaje,     isnull(@w_num_dec_tapl,2)), --LPO isnull(2)
   @w_porcentaje_efa = round(@w_porcentaje_efa, isnull(@w_num_dec_tapl,2))  --LPO isnull(2)

   
   select @w_fec_tasas = isnull(max(ts_fecha),'01/01/1900')
   from   ca_tasas with (nolock)
   where  ts_operacion      = @i_operacionca
   and    ts_dividendo      = @w_di_vigente
   and    ts_concepto       = @w_concepto
   and    ts_fecha         <= @i_fecha_proceso
   
   select @w_sec_tasas = isnull(max(ts_secuencial),-999)
   from   ca_tasas with (nolock)
   where  ts_operacion      = @i_operacionca
   and    ts_dividendo      = @w_di_vigente
   and    ts_concepto       = @w_concepto
   and    ts_fecha          = @w_fec_tasas
   
   if not exists(select 1 from ca_tasas with (nolock)
   where  ts_operacion      = @i_operacionca
   and    ts_dividendo      = @w_di_vigente
   and    ts_concepto       = @w_concepto
   and    ts_porcentaje_efa = @w_porcentaje_efa
   and    ts_fecha          = @w_fec_tasas
   and    ts_secuencial     = @w_sec_tasas)
   begin
   
      insert into ca_tasas (
      ts_operacion,      ts_dividendo,         ts_fecha,
      ts_concepto,       ts_porcentaje,        ts_secuencial,
      ts_porcentaje_efa, ts_referencial,       ts_signo,
      ts_factor,         ts_valor_referencial, ts_fecha_referencial,
      ts_tasa_ref )
      values(
      @i_operacionca,    @w_di_vigente,         @i_fecha_proceso,
      @w_concepto,       @w_porcentaje,         @i_secuencial,
      @w_porcentaje_efa, @w_referencial,        @w_signo,
      @w_factor ,        @w_valor_tasa_ref ,    @w_fecha_tasaref,
      @w_ts_tasa_ref )
      
      if @@ERROR != 0 
      BEGIN --LPO manejo de errores dentro de un cursor
         close rubro
         deallocate rubro
         return 703118
      END      
   END
   
   -- ACTUALIZACION DE TASAS EN ca_rubro_op
   update ca_rubro_op with (rowlock) set
   ro_porcentaje           = @w_porcentaje,
   ro_porcentaje_efa       = @w_porcentaje_efa,
   ro_porcentaje_aux       = @w_porcentaje_aux,
   ro_referencial          = @w_referencial,
   ro_signo                = @w_signo,
   ro_factor               = @w_factor,
   ro_tipo_puntos          = isnull(@w_tipopuntos, ro_tipo_puntos)
   where  ro_operacion = @i_operacionca
   and    ro_concepto  = @w_concepto
   
   if @@ERROR != 0 
   BEGIN --LPO manejo de errores dentro de un cursor
      close rubro
      deallocate rubro
      return 710002
   END      

   

	---LA TASA ULTIMA INSERTADA POR EL USUARIO ES LA UNICA QUE REEMPLAZA LA TASA BASICA PARA 
	---FUTURAS VALIDACIONES. LOS MIVIMIENTOS POR TLU NO DEBEN CAMBIAR LA TASA
	
	IF @w_referencial IS NOT NULL
   begin
	   SELECT @w_iden_ref  = substring(@w_referencial,1,3)
	
		if @w_iden_ref  <>  'TLU'
		begin
		
		    select @w_fecha_hoy = fc_fecha_cierre
		    from cobis..ba_fecha_cierre
		    where fc_producto = 7
		
			if @w_referencial is null
			   select @w_factor = @w_porcentaje
			
			delete ca_ultima_tasa_op           
			where ut_operacion = @i_operacionca
	
			----PRINT 'reajibc.sp entro a cambiar la Tasa_basica en 	ca_ultima_tasa_op'
				
			insert into  ca_ultima_tasa_op
			      (ut_operacion,             ut_concepto,               ut_referencial, ut_signo,
			       ut_factor,                ut_reajuste_especial,      ut_tipo_puntos,
			       ut_fecha_pri_referencial, ut_fecha_act,              ut_porcentaje,  ut_porcentaje_efa      
			      ) 
			values(@i_operacionca,           @w_concepto,               @w_referencial,    @w_signo,
			       @w_factor,                @w_re_reajuste_especial,   @w_tipopuntos,
			       @i_fecha_proceso,         @w_fecha_hoy,              @w_porcentaje,   @w_porcentaje_efa)
			
	       if @@ERROR != 0 
	       BEGIN --LPO manejo de errores dentro de un cursor
	         close rubro
	         deallocate rubro
	         return 722002
	       END      		   
		end
   end
           
   SIG_RUBRO:
   fetch rubro
   into  @w_concepto, @w_porcentaje_aux, @w_fpago, @w_tipo_puntos, @w_num_dec_tapl, @w_ro_porcentaje_efa
   
end   ---Cursor rubros

close rubro
deallocate rubro

return 0


GO

