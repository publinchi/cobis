/************************************************************************/
/*	Archivo:		fetmprej.sp 				*/
/*	Stored procedure:	sp_fecha_reajuste_tmp           	*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		D Aguilar  (GrupoCONTEXT)       	*/
/*	Fecha de escritura:	May. 1999 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA", representantes exclusivos para el Ecuador de la 	*/
/*	"NCR CORPORATION".						*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Generar las fechas de reajuste de una operacion periodica       */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name like 'sp_fecha_reajuste_tmp')
        drop proc sp_fecha_reajuste_tmp
go

create proc sp_fecha_reajuste_tmp(
        @i_operacionca          int = NULL,
        @i_tipo                 char(1) = NULL,
        @i_fecha_reajuste       datetime = NULL, 
        @o_fecha_reajuste       datetime= NULL out, --Fecha Negociada
        @o_fecha_reajuste_new   datetime = NULL out --Fecha Proximo Reajuste
)as  

declare @w_return int,
        @w_est_vencido      tinyint,
        @w_est_novigente    tinyint,
        @w_estado           tinyint,
        @w_tfactor          int,
        @w_tdividendo       catalogo,
        @w_reajuste_periodo int,
        @w_reajuste_fecha   datetime,
        @w_fecha_aux1       datetime,
        @w_fecha_siguiente  datetime,
        @w_fecha_aux2       datetime,
        @w_fecha_rej_aux    datetime,
        @w_reajuste_num int,
        @w_periodo_int  int,
        @w_fecha_ini    datetime,
        @w_fecha_fin    datetime,
        @w_factor       int,
        @w_operacionca  int,
        @w_dias         int,
        @w_error        int,
        @w_periodos_reaj_aux  int,
        @w_periodos_ini       int,
        @w_num_div            int,
        @w_fecha_reaj_ini     datetime,
        @w_sp_name            descripcion,
        @w_fecha_ult_proceso  datetime,
        @w_reajuste_especial  char(1),
        @w_secuencial         int,
 	@w_sector   	      catalogo,
        @w_ro_concepto        catalogo,
        @w_ro_referencial_reajuste catalogo,
        @w_ro_signo_reajuste  char(1),
        @w_ro_factor_reajuste float,
        @w_referencia         catalogo,
        @w_valor_default      float 

select @w_sp_name = 'sp_fecha_reajuste_tmp'

/* SELECCIONAR LOS ESTADOS */
select 
@w_est_vencido   = 2,
@w_est_novigente = 0

/** INFORMACION DE LA OPERACION **/
select 
@w_tdividendo       = opt_tdividendo,
@w_reajuste_periodo = opt_periodo_reajuste,
@w_reajuste_fecha   = opt_fecha_reajuste,
@w_reajuste_num     = 0,
@w_periodo_int      = opt_periodo_int,
@w_fecha_ini        = opt_fecha_ini,
@w_fecha_fin        = opt_fecha_fin,
@w_estado           = opt_estado,
@w_fecha_ult_proceso= opt_fecha_ult_proceso,
@w_reajuste_especial= opt_reajuste_especial,
@w_operacionca      = opt_operacion,
@w_sector           = opt_sector
from ca_operacion_tmp
where opt_operacion = @i_operacionca

/* CAMBIAR DE TIPO DE ACTUALIZACION */


PRINT 'llego a fetmprej.sp @i_tipo' + @i_tipo

if @i_tipo = 'I' begin  


   select @w_tfactor =  td_factor
   from ca_tdividendo
   where td_tdividendo = @w_tdividendo
  
   if @i_fecha_reajuste is not null begin

      select @w_periodos_ini = dit_dividendo * @w_periodo_int
      from ca_dividendo_tmp
      where dit_operacion = @w_operacionca
      and   dit_fecha_ven = @i_fecha_reajuste

      if @@rowcount = 0 begin
         select @w_error = 708111
         goto ERROR
      end

      select 
      @w_fecha_ini      = @i_fecha_reajuste,
      @w_reajuste_num   = -1,
      @w_fecha_reaj_ini = @i_fecha_reajuste

   end else begin

      select  
      @w_reajuste_num = 0,
      @w_periodos_ini = 0,
      @w_fecha_reaj_ini = null

   end


   delete ca_reajuste_det_tmp
   where red_operacion  =  @w_operacionca

   if @@error != 0
   begin 
      select @w_error = 710003
      goto   ERROR 
   end

   delete ca_reajuste_tmp
   where re_operacion = @w_operacionca

   if @@error != 0
   begin 
      select @w_error = 710003
      goto   ERROR 
   end


   while 1=1 begin

      select @w_reajuste_num = @w_reajuste_num + 1

      select @w_periodos_reaj_aux = 
      (@w_reajuste_periodo * @w_reajuste_num) + @w_periodos_ini

      if @w_periodos_reaj_aux % @w_periodo_int = 0 begin

         select @w_num_div = @w_periodos_reaj_aux / @w_periodo_int

         select @w_reajuste_fecha = dit_fecha_ven
         from ca_dividendo_tmp
         where dit_operacion = @w_operacionca
         and   dit_dividendo = @w_num_div

         if @@rowcount = 0 break

      end else begin

         select @w_reajuste_fecha = 
         dateadd(dd, @w_periodos_reaj_aux * @w_tfactor, @w_fecha_ini)

      end

      if @w_reajuste_num = 0
         select @w_reajuste_fecha = @w_fecha_reaj_ini

      if @w_fecha_reaj_ini is null 
         select @w_fecha_reaj_ini = @w_reajuste_fecha

      if @w_reajuste_fecha >= @w_fecha_fin begin
         break
      end
      
      exec @w_secuencial = sp_gen_sec
           @i_operacion  = @w_operacionca

      insert into ca_reajuste_tmp 
      (re_secuencial,re_operacion,re_fecha,
       re_reajuste_especial, re_desagio)
      values 
      (@w_secuencial,@w_operacionca,@w_reajuste_fecha,
       @w_reajuste_especial, 'N')

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end

      declare cursor_rubros cursor for
      select
      rot_concepto,      rot_referencial_reajuste,
      rot_signo_reajuste,rot_factor_reajuste,
      vd_referencia,     vd_valor_default
      from ca_rubro_op_tmp,ca_valor_det
      where rot_operacion  = @w_operacionca
      and   rot_fpago      in ('P','A')
      and   rot_tipo_rubro = 'I'
      and   rot_referencial_reajuste = vd_tipo
      and   vd_sector     = @w_sector
      for read only

      open cursor_rubros
   
      fetch cursor_rubros into
      @w_ro_concepto,@w_ro_referencial_reajuste,
      @w_ro_signo_reajuste,@w_ro_factor_reajuste,@w_referencia,
      @w_valor_default
   
      while   @@fetch_status = 0
      begin
         if (@@fetch_status = -1) 
         begin
            select @w_error = 710004
            goto ERROR
         end 

         ---PRINT 'fetmperj.sp @w_ro_referencial_reajuste' + @w_ro_referencial_reajuste

         if @w_referencia is null
            /* INSERTAR DIRECTAMENTE EL PORCENTAJE A APLICAR */
            insert into ca_reajuste_det_tmp (
            red_secuencial,red_concepto,red_referencial,
            red_signo,red_factor,red_porcentaje)
            values (
            @w_secuencial,@w_ro_concepto,null,
            null,null,isnull(@w_valor_default,0))
         else
            /* INSERTAR EL REFERENCIAL */
            insert into ca_reajuste_det_tmp (
            red_secuencial,red_concepto,red_referencial,
            red_signo,red_factor,red_porcentaje)
            values (
            @w_secuencial,@w_ro_concepto,@w_ro_referencial_reajuste, ---EPB @w_referencia,
            @w_ro_signo_reajuste,@w_ro_factor_reajuste,null)

         if @@error != 0 begin
            select @w_error = 710001
            goto ERROR
         end

         fetch cursor_rubros into
         @w_ro_concepto,@w_ro_referencial_reajuste,
         @w_ro_signo_reajuste,@w_ro_factor_reajuste,@w_referencia,
         @w_valor_default
      end
      close cursor_rubros
      deallocate cursor_rubros
   end  -- fin while

   set rowcount 1

   select @w_fecha_siguiente = re_fecha
   from ca_reajuste_tmp
   where re_operacion = @w_operacionca
   and re_fecha       > @w_fecha_reaj_ini
   order by re_fecha

   set rowcount 0

   update ca_operacion_tmp set 
   opt_fecha_reajuste    = @w_fecha_reaj_ini
   where opt_operacion   = @w_operacionca

   if @@error <> 0 begin
      return 1
   end

   select  
   @o_fecha_reajuste_new = @w_fecha_siguiente,
   @o_fecha_reajuste     = @w_fecha_reaj_ini

   return 0

end /** FIN OPCION I **/

return 0

ERROR:
  return @w_error
go


