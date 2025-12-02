/****************************************************************************/
/*   Archivo             :  asig_seg_deu_ven.sp                             */
/*   Stored procedure    :  sp_asigna_segdeuven                             */
/*   Base de datos       :  cob_cartera                                     */
/*   Producto            :  Cartera                                         */
/*   Disenado por        :  Liana Coto                                      */
/*   Fecha de escritura  :  26/MAR/2014                                     */
/****************************************************************************/
/*                           IMPORTANTE                                     */
/*   Este programa es parte de los paquetes bancarios propiedad de          */
/*   'MACOSA'.                                                              */
/*   Su uso no autorizado queda expresamente prohibido asi como cualquier   */
/*   alteracion o agregado hecho por alguno de sus usuarios sin el debido   */
/*   consentimiento por escrito de la Presidencia Ejecutiva de MACOSA o     */
/*   su representante.                                                      */
/****************************************************************************/
/*                           PROPOSITO                                      */
/*   Asigna el valor del rubro SEGDEUVEN, a todos aquellas operaciones      */
/*   de EMPLEADOS que se le realice traslado de línea cuando dejan de ser   */
/*   empleados de la institución                                            */
/****************************************************************************/
/*                           MODIFICACIONES                                 */
/*      FECHA           AUTOR                 RAZON                         */
/*   26/MAR/2014      Liana Coto      Emisión Inicial --Req 406             */
/****************************************************************************/

use
cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_asigna_segdeuven')
   drop proc sp_asigna_segdeuven
go

create proc sp_asigna_segdeuven
@i_operacion        int,
@i_tl_linea_destino varchar(10)

as
declare
@w_nro_periodos     int,
@w_valor_tasa_ref   float,
@w_operacion        int,
@w_saldo_cap        money,
@w_di_dividendo     int,
@w_valor_recalculo  money,
@w_ro_porcentaje    int,
@w_sp_name          descripcion,
@w_max_fecha        datetime,
@w_max_sec          int,
@w_di_fecha_ini     datetime,
@w_cuota_hoy        int,
@w_error            int,
@w_mensaje          descripcion,
@w_fecultpro        datetime,
@w_tl_linea_destino varchar(10),
@w_monto_ini        money

select @w_sp_name          = 'sp_asigna_segdeuven',
       @w_nro_periodos     = 1,
       @w_operacion        = @i_operacion,
	   @w_tl_linea_destino = @i_tl_linea_destino,
	   @w_error            = 0
	   
/*** OBTENIENDO EL VALOR DE LA TASA REFERENCIAL ***/
select @w_fecultpro  = op_fecha_ult_proceso,
       @w_monto_ini  = op_monto
from   cob_cartera..ca_operacion
where  op_operacion = @i_operacion

     if @@rowcount = 0
		begin
          select @w_error   = 710244
                 print ' EEROR OBTENIENDO LA FECHA  '				 
          goto ERRORFIN
        end

select @w_max_fecha = max(vr_fecha_vig)
from   ca_valor_referencial with (nolock)
where  vr_tipo      = 'TSEGVEN'
and    vr_fecha_vig <= @w_fecultpro

     if @@rowcount = 0
		begin
          select @w_error   = 710244
                 print ' ERROR OBTENIENDO LA MAXIMA FECHA DE VIGENCIA '
          goto ERRORFIN
        end

select @w_max_sec   = max(vr_secuencial)
from   ca_valor_referencial with (nolock)
where  vr_tipo      = 'TSEGVEN'
and    vr_fecha_vig = @w_max_fecha

     if @@rowcount = 0
		begin
          select @w_error   = 710244
                 print ' ERROR OBTENIENDO EL MAXIMO SECUENCIAL '
          goto ERRORFIN
        end
            
select @w_valor_tasa_ref = vr_valor
from   ca_valor_referencial with (nolock)
where  vr_tipo           = 'TSEGVEN'
and    vr_fecha_vig      = @w_max_fecha
and    vr_secuencial     = @w_max_sec	

     if @@rowcount = 0
		begin
          select @w_error   = 710244
                 print ' ERROR OBTENIENDO EL VALOR DE TASA REFERENCIAL '
          goto ERRORFIN
        end

/*** OBTENIENDO EL NÚMERO DE PERIODOS DE LA OPERACION ***/   	   
select @w_nro_periodos = op_periodo_int * td_factor/30 
from   ca_operacion, ca_tdividendo 
where  op_operacion    = @w_operacion
and    op_tdividendo   = td_tdividendo

     if @@rowcount = 0
		begin
          select @w_error   = 710244
                 print ' ERROR OBTENIENDO EL NUMERO DE PERIODOS '
          goto ERRORFIN
        end

if @w_tl_linea_destino in (select c.codigo from  cobis..cl_catalogo c, cobis..cl_tabla d where d.codigo = c.tabla and d.tabla = 'ca_lineas_em')
begin
    goto ERRORFIN
end
else
begin
   /***  OBTENIENDO EL SALDO CAPITAL PARA CADA DIVIDENDO DE LA OPERACIÓN ***/
   select * into #operEmple
   from ca_operacion with (nolock), 
        ca_dividendo with (nolock)
   where op_operacion  = @w_operacion 
   and   di_operacion  = op_operacion
   and   op_estado not in (0,99,6)

   select @w_di_dividendo = 0      
      while 1 = 1 
      begin
	       set rowcount 1
		   select @w_di_dividendo = di_dividendo,
		          @w_di_fecha_ini = di_fecha_ini
		   from   #operEmple with (nolock)
		   where  di_operacion    = @w_operacion
		   and    di_dividendo    > @w_di_dividendo
		   order by di_dividendo
		
   	       if @@rowcount = 0 
		   begin
		     set rowcount 0
		     break
		   end
		   set rowcount 0
            
		   select @w_cuota_hoy       = 0,
		          @w_valor_recalculo = 0,
		          @w_saldo_cap       = 0
			
		   select @w_saldo_cap  = isnull(sum(am_cuota),0)
		   from   ca_amortizacion, ca_rubro_op
		   where  am_operacion  = @w_operacion
		   and    ro_operacion  = am_operacion
		   and    am_dividendo  >= @w_di_dividendo
		   and    ro_concepto   = am_concepto 
		   and    ro_tipo_rubro = 'C'   
		
		   if @@rowcount = 0
		   begin
              select @w_error   = 710244
                     print ' ERROR EN LA CONSULTA DEL SALDO CAPITAL '
                     goto ERRORFIN
           end
				 
        /*** CALCULANDO EL NUEVO VALOR DEL RUBRO ***/
           select @w_valor_recalculo = round(@w_saldo_cap * @w_valor_tasa_ref/100.0,0)

        /*** ACTUALIZACIÓN DEL RUBRO SEGDEUVEN ***/

           /*** ACTUALIZANDO RUBRO EN CA_AMORTIZACIÓN ***/
	       update ca_amortizacion
	       set   am_concepto  = 'SEGDEUVEN',
                 am_cuota     = @w_valor_recalculo
           from  ca_amortizacion with (nolock),
                 ca_dividendo b   with (nolock),
                 #operEmple a
	       where am_operacion    = @w_operacion
           and   am_concepto     = 'SEGDEUEM'
           and   am_operacion    = b.di_operacion
	       and   am_operacion    = a.op_operacion
	       and   b.di_operacion  = a.op_operacion
	       and   am_dividendo    = a.di_dividendo
	       and   b.di_dividendo  = a.di_dividendo
		   and   a.di_dividendo  = @w_di_dividendo
	       and   b.di_estado     in (0,1)
		
		   if @@error <> 0 
		   begin
             select @w_error   = 710002
                    print ' ERROR EN LA ACTUALIZACION ca_amortizacion'
                    goto ERRORFIN
           end
		
      end --while
      
     if exists (select  1 from ca_dividendo
                where di_operacion = @i_operacion
                and di_estado = 2)
     begin
        insert into ca_rubro_op
                   (ro_operacion,             ro_concepto,             ro_tipo_rubro,
                    ro_fpago,                 ro_prioridad,            ro_paga_mora,
                    ro_provisiona,            ro_signo,                ro_factor,
                    ro_referencial,           ro_signo_reajuste,       ro_factor_reajuste,
                    ro_referencial_reajuste,  ro_valor,                ro_porcentaje,
                    ro_gracia,                ro_porcentaje_aux,       ro_principal,
                    ro_porcentaje_efa,        ro_concepto_asociado,    ro_garantia,
                    ro_tipo_puntos,           ro_saldo_op,             ro_saldo_por_desem,
                    ro_base_calculo,          ro_num_dec,              ro_tipo_garantia,
                    ro_nro_garantia,          ro_porcentaje_cobertura,
                    ro_valor_garantia,        ro_tperiodo,             ro_periodo,
                    ro_saldo_insoluto,        ro_porcentaje_cobrar,    ro_calcular_devolucion,
                    ro_limite)
        select      @w_operacion,             ru_concepto,             ru_tipo_rubro,
                    ru_fpago,                 ru_prioridad + 1,        ru_paga_mora,
                    ru_provisiona,            '+',                     0,
                    ru_referencial,           null,                    0,
                    null,                     0,                       isnull(@w_valor_tasa_ref,0),
                    0,                        isnull(@w_valor_tasa_ref,0), ru_principal,
                    0,                        ru_concepto_asociado,    0,
                    'B',                      ru_saldo_op,             ru_saldo_por_desem, 
                    @w_monto_ini,             6,                       ru_tipo_garantia,   
                    null,                     ru_porcentaje_cobertura, 
                    ru_valor_garantia,        ru_tperiodo,             ru_periodo,  
                    ru_saldo_insoluto,        ru_porcentaje_cobrar,    ru_calcular_devolucion,
                    ru_limite
         from   ca_rubro
         where  ru_toperacion = @w_tl_linea_destino
         and    ru_moneda     = 0 
         and    ru_concepto   = 'SEGDEUVEN' 

         if @@error <> 0 
         begin
            select @w_error   = 710002
            print ' ERROR EN LA CREACION DEL RUBRO SEGDEUVWEN ca_rubro_op'
            goto ERRORFIN
         end
      end
      else
      begin
        /*** ACTUALIZANDO RUBRO EN CA_RUBRO_OP ***/
        update ca_rubro_op
	    set   ro_concepto    =   'SEGDEUVEN',
              ro_porcentaje  =  @w_valor_tasa_ref	
	    where ro_operacion   =  @w_operacion
	    and   ro_concepto    = 'SEGDEUEM' 
	    
        if @@error <> 0 
        begin
           select @w_error   = 710002
           print ' ERROR EN LA ACTUALIZACION ca_rubro_op'
           goto ERRORFIN
        end

	 end
		
end --IF
 return 0
 
ERRORFIN:
   
return @w_error

go

