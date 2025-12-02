/************************************************************************/
/*	Archivo: 		calcanti.sp		 		*/
/*	Stored procedure: 	sp_calcular_anticipados			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Fabian de la Torre, Rodrigo Garces     	*/
/*	Fecha de escritura: 	Ene 98					*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Calcular en ca_rubro_op_tmp los valores de los rubros           */
/*      anticipados                                                     */
/************************************************************************/  
/*				PROPOSITO				*/
/*	FECHA		AUTOR		RAZON				*/
/*	13/May/99	XSA(CONTEXT)	Ejecutar el sp sp_rubro_calculado*/
/*					usando los campos Saldo de la   */
/*					operacion, Saldo por desembolsar*/
/*					y base de calculo para los ru-  */
/*					bros calculados que se cobran en*/
/*					el desembolso.			*/
/************************************************************************/  
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_calcular_anticipados')
	drop proc sp_calcular_anticipados
go
create proc sp_calcular_anticipados (
	@i_operacionca    int,
        @i_causacion      char(1) = 'L' --RBU
)
as
declare	
   @w_sp_name                 	descripcion,
   @w_return 			int,
   @w_concepto			catalogo,
   @w_tipo_rubro		char(1),
   @w_tperiodo			catalogo,  
   @w_periodo			int,
   @w_tasa_valor_aplicar	catalogo, 
   @w_tasa_valor_basico		catalogo, 
   @w_signo			char(1),
   @w_factor			float,
   @w_toperacion                catalogo,
   @w_moneda			tinyint,
   @w_fecha_ini			datetime,
   @w_fecha_fin			datetime,
   @w_monto			money,
   @w_sector			char(1),
   @w_clase			char(1),
   @w_dias_anio			int,
   @w_num_dec			tinyint,
   @w_porcentaje		float,
   @w_valor_rubro		money,
   @w_dias_calc			int,
   @w_dias_calc_aux		int,
   @w_vr_valor			float,
   @w_secuencial                int,
   @w_valor                     float,
   @w_timbre                    catalogo,
   @w_cliente                   int,
   @w_valor_asociado            money,
   @w_concepto_asociado         catalogo,
   @w_saldo_operacion		char(1),
   @w_saldo_por_desem		char(1),
   @w_base_calculo		money,  
   @w_dias_int                  int,    
   @w_categoria_rubro           catalogo,
   @w_categoria_cliente         catalogo,
   @w_porcentaje_categoria      tinyint,
   @w_valor_catagoria           money,
   @w_rango_min			money,
   @w_rango_max			money,
   @w_limite                    char(1),
   @w_fecha                     datetime



/*  Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_calcular_anticipados',
        @w_valor_catagoria  = 0


/*CODIGO DEL RUBRO TIMBRE*/
select @w_timbre = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'TIMBRE'
set transaction isolation level read uncommitted

/** LECTURA DE LOS DATOS DE LA OPERACION **/
select 
@w_toperacion = opt_toperacion,
@w_moneda     = opt_moneda,
@w_fecha_ini  = opt_fecha_ini,
@w_fecha_fin  = opt_fecha_fin,
@w_monto      = opt_monto,
@w_sector     = opt_sector,
@w_dias_anio  = opt_dias_anio,
@w_cliente    = opt_cliente
from  ca_operacion_tmp
where opt_operacion = @i_operacionca

exec @w_return = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out

if @w_return != 0 return @w_return

/** INSERCION DE LOS RUBROS DE LA OPERACION **/

declare rubros cursor for
select  
rot_concepto, rot_tipo_rubro, rot_referencial, 
rot_signo,    rot_factor,     rot_porcentaje,
rot_valor,
rot_saldo_op,   rot_saldo_por_desem,  rot_base_calculo,  
rot_limite
from ca_rubro_op_tmp
where rot_operacion = @i_operacionca
and   rot_fpago     = 'L' --PAGADEROS EN LA LIQUIDACION
for read only

open rubros

fetch rubros into 
@w_concepto,  @w_tipo_rubro,    @w_tasa_valor_aplicar, 
@w_signo,     @w_factor,        @w_porcentaje,
@w_valor,
@w_saldo_operacion,  @w_saldo_por_desem,  @w_base_calculo,  
@w_limite

while (@@fetch_status = 0 ) begin 


   select @w_base_calculo = isnull(@w_base_calculo , 0)

   if @w_tipo_rubro = 'Q'  begin
     exec @w_return 	= sp_rubro_calculado
     @i_tipo 	     	= 'Q',              
     @i_monto       	= @w_base_calculo,  
     @i_concepto    	= @w_concepto,
     @i_operacion   	= @i_operacionca,
     @i_saldo_op    	= @w_saldo_operacion,
     @i_saldo_por_desem = @w_saldo_por_desem,
     @i_porcentaje  	= @w_porcentaje,        
     @o_valor_rubro 	= @w_valor_rubro out

      if @w_return <> 0 return @w_return


   end





   if @w_tipo_rubro in ('I','O','V') begin

      /* DETERMINACION DE LA TASA A APLICAR */ 
      select  
      @w_tasa_valor_basico = vd_referencia,
      @w_clase             = va_clase
      from    ca_valor,ca_valor_det
      where   va_tipo   = @w_tasa_valor_aplicar 
      and     vd_tipo   = @w_tasa_valor_aplicar
      and     vd_sector = @w_sector


      if @w_clase = 'V' 
         select @w_vr_valor = @w_valor
      else begin

        select @w_fecha = max(vr_fecha_vig)
        from ca_valor_referencial
	where vr_tipo       = @w_tasa_valor_basico
	and   vr_fecha_vig <= @w_fecha_ini


        /* DETERMINACION DE LA MAXIMA FECHA PARA LA TASA ENCONTRADA */
        select @w_secuencial = max(vr_secuencial)
        from   ca_valor_referencial 
        where  vr_tipo      = @w_tasa_valor_basico
        and    vr_fecha_vig = @w_fecha

         /* DETERMINACION DEL VALOR DE TASA A APLICAR */ 
         select @w_vr_valor = vr_valor
         from   ca_valor_referencial
         where  vr_tipo       = @w_tasa_valor_basico
         and    vr_secuencial = @w_secuencial 

         select 
         @w_porcentaje  = 0,
         @w_valor_rubro = 0
       end

      if @w_clase = 'V'  begin 
         if @w_tipo_rubro in ('O','I') 
            select  @w_porcentaje = @w_porcentaje

         if @w_tipo_rubro in ('V')  
            select  @w_valor_rubro = @w_vr_valor
      end 
      else begin  

         exec sp_calcula_valor
         @i_base       = @w_vr_valor,
         @i_factor     = @w_factor,
         @i_signo      = @w_signo,
         @o_resultado  = @w_porcentaje out

         if @w_tipo_rubro in ('V') 
            select  
            @w_valor_rubro = @w_porcentaje,
            @w_porcentaje  = 0
      end

      
      /* CALCULO DEL VALOR DEL RUBRO PARA TIPOS INTERES Y PORCENTAJE */
      if @w_tipo_rubro = 'O' begin
         select @w_valor_rubro = @w_porcentaje * @w_monto / 100

         /*AUMENTADO 15/Ene/99*/
         /*SI EL RUBRO ES TIMBRE HACE OTROS CONTROLES*/
         if @w_concepto = @w_timbre   begin
            exec @w_return =  sp_impuesto_timbre
            @i_monto         = @w_monto,
            @i_cliente       = @w_cliente,
            @i_valor         = @w_valor_rubro,
            @o_valor         = @w_valor_rubro out

            if @w_return != 0 return @w_return
         end
      end

      if @w_tipo_rubro = 'I' begin

         select 
         @w_periodo  = ru_periodo,
         @w_tperiodo = ru_tperiodo
         from ca_rubro
         where ru_toperacion = @w_toperacion
         and   ru_moneda     = @w_moneda
         and   ru_concepto   = @w_concepto

         select @w_dias_calc_aux = td_factor * @w_periodo
         from ca_tdividendo
         where td_tdividendo = @w_tperiodo

         select @w_dias_calc = datediff(dd, @w_fecha_ini, @w_fecha_fin)

         if @w_dias_calc_aux is not null       
            if @w_dias_calc_aux < @w_dias_calc
               select @w_dias_calc = @w_dias_calc_aux


         if @i_causacion = 'L'
            select @w_dias_int = @w_dias_calc
         else 
             if @i_causacion = 'E'
                select @w_dias_int = @w_dias_calc - 1

     
         exec @w_return = sp_calc_intereses
         @tasa      = @w_porcentaje,
         @monto     = @w_monto,
         @dias_anio = 360,
         @num_dias  = @w_dias_int, 
         @causacion = @i_causacion,
         @intereses = @w_valor_rubro out


         if @w_return <> 0 return @w_return
      end
   end

   select @w_valor_rubro = round(@w_valor_rubro, @w_num_dec)




   update ca_rubro_op_tmp set
   rot_valor           = @w_valor_rubro,
   rot_porcentaje      = @w_porcentaje
   where rot_operacion = @i_operacionca
   and   rot_concepto  = @w_concepto

   if @@error != 0 return 710002

   fetch rubros into 
   @w_concepto,  @w_tipo_rubro,    @w_tasa_valor_aplicar, 
   @w_signo,     @w_factor,        @w_porcentaje,
   @w_valor,
   @w_saldo_operacion,  @w_saldo_por_desem,  @w_base_calculo,  --XSA 13/May/99
   @w_limite


end

close rubros

deallocate rubros


/*RUBROS ASOCIADOS*/

declare rubro_asociado cursor for
select  
rot_concepto, rot_tipo_rubro,       rot_referencial, 
rot_signo,    rot_factor,           rot_porcentaje,
rot_valor,    rot_concepto_asociado
from ca_rubro_op_tmp
where rot_operacion = @i_operacionca
and   rot_fpago     = 'L' --PAGADEROS EN LA LIQUIDACION
and   rot_concepto_asociado is not null
for read only

open rubro_asociado

fetch rubro_asociado into 
@w_concepto,  @w_tipo_rubro,    @w_tasa_valor_aplicar, 
@w_signo,     @w_factor,        @w_porcentaje,
@w_valor,     @w_concepto_asociado

while (@@fetch_status = 0 ) begin 
 
   /*VALOR DEL RUBRO ASOCIADO*/
   select @w_valor_asociado = rot_valor
   from ca_rubro_op_tmp
   where rot_operacion = @i_operacionca
   and   rot_concepto  = @w_concepto_asociado


   select @w_valor_rubro = @w_porcentaje * @w_valor_asociado / 100.0



   update ca_rubro_op_tmp set
   rot_valor           = @w_valor_rubro
   where rot_operacion = @i_operacionca
   and   rot_concepto  = @w_concepto

   if @@error != 0 return 710002

   fetch rubro_asociado into 
   @w_concepto,  @w_tipo_rubro,    @w_tasa_valor_aplicar, 
   @w_signo,     @w_factor,        @w_porcentaje,
   @w_valor,     @w_concepto_asociado

end

close rubro_asociado

deallocate rubro_asociado

return 0

go     

