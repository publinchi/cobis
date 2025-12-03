/************************************************************************/
/*      Archivo:                recalrop.sp                             */
/*      Stored procedure:       sp_recal_rubros_ot_periodos             */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira PElaez                           */
/*      Fecha de escritura:     mar. 2003                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Recalculo de los rubros que tienen periodos de pago diferentes a*/
/*      la periodicidad el interes                                      */
/*      Este sp es llamado desde:					*/
/*      modopin.sp.- en el momento que hay regeneracion de la tabla     */
/*      de amortizacion							*/
/*                             CAMBIOS                                  */
/*      								*/
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_recal_rubros_ot_periodos')
   drop proc sp_recal_rubros_ot_periodos
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_recal_rubros_ot_periodos
@i_operacion	int

as
declare
@w_sp_name		varchar(30),
@w_concepto		catalogo,
@w_opt_tdividendo	catalogo,
@w_opt_periodo_int	int,
@w_dias_div		int,
@w_cuotas_atras		int,
@w_total_presente	money,
@w_num_dec              smallint,
@w_moneda               smallint,
@w_return               int,
@w_porcentaje           float,
@w_error                int,
@w_parametrot_fag        catalogo,
@w_porcentaje_cobertura char(1),
@w_tramite              int,
@w_tipo_garantia        varchar(64),
@w_porcen_cobertura     float,
@w_tipo_productor       catalogo,
@w_dias_plazo           int,
@w_gracia_en_meses      int,
@w_cliente              int,
@w_monto                money,
   @w_tplazo      	 catalogo,
   @w_plazo       	 smallint,
   @w_valor_act_garantia money,
   @w_valor              money,
   @w_plazo_en_meses     int,
   @w_tasa_comision      float,
   @w_valor_rubro        money,
   @w_gracia_cap         smallint,
   @w_concepto_asociado  catalogo,
   @w_iva_siempre      char(1),
   @w_referencial        catalogo,
   @w_sector             catalogo,
   @w_rowcount           int






/** INICIALIZACION VARIABLES **/
select @w_sp_name = 'sp_recal_rubros_ot_periodos',
@w_concepto	    = ''


/** VALIDAR EXISTENCIA DE RUBROS  CON PERIODICIDAD DIFERENTE **/
if not exists (select 1 from   ca_rubro_op_tmp
where  rot_operacion = @i_operacion
and    rot_fpago     in ('P','A')
and    rot_periodo > 0)
return 0



/** DATOS OPERACION **/
select @w_opt_tdividendo  = opt_tdividendo,
       @w_opt_periodo_int = opt_periodo_int,
       @w_moneda          = opt_moneda,
       @w_monto           = opt_monto,
       @w_tramite         = opt_tramite,
       @w_tplazo          = opt_tplazo,
       @w_plazo           = opt_plazo,
       @w_cliente         = opt_cliente,
       @w_sector          = opt_sector
from ca_operacion_tmp
where opt_operacion	= @i_operacion

/*NUMERO DE DECIMALES*/
exec @w_return = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out
if @w_return != 0 
   return  @w_return

/*CODIGO DEL RUBRO COMISION FAG */
select @w_parametrot_fag = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFAG'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 710370

/** NUMERO DE DIAS POR DIVIDENDO **/
select @w_dias_div = td_factor * @w_opt_periodo_int
from   ca_tdividendo
where  td_tdividendo = @w_opt_tdividendo

declare cursor_act_rubros_otperido cursor for 
select
rot_concepto,
rot_porcentaje,
rot_porcentaje_cobertura,
rot_tipo_garantia,
rot_concepto_asociado,
rot_iva_siempre,
rot_referencial
from  ca_rubro_op_tmp
where rot_operacion = @i_operacion
and   rot_fpago     in ('P','A')
and   rot_periodo > 0
for read only

open cursor_act_rubros_otperido

fetch cursor_act_rubros_otperido into
@w_concepto,
@w_porcentaje,
@w_porcentaje_cobertura,
@w_tipo_garantia,
@w_concepto_asociado,
@w_iva_siempre,
@w_referencial

while   @@fetch_status = 0 begin /*WHILE CURSOR PRINCIPAL*/

   if (@@fetch_status = -1) return 708999


   if  @w_porcentaje <=  0 begin
       select @w_error = 710387
       return @w_error
   end


   if @w_tipo_garantia is not null begin
      set rowcount 1
      select @w_porcen_cobertura   = cu_porcentaje_cobertura
      from cob_credito..cr_gar_propuesta, 
           cob_custodia..cu_custodia,
           cob_custodia..cu_tipo_custodia
      where gp_tramite  =  @w_tramite
      and gp_garantia   =  cu_codigo_externo
      and (cu_tipo      =  @w_tipo_garantia or cu_tipo = tc_tipo_superior)
      if @@rowcount =  0 begin  
         select @w_porcen_cobertura = 80 ---para pruebas
         --select @w_error = 710371
         --return @w_error
      end
      set rowcount 0
   end




   /* PARA RUBROS CALCULADOS TENIENDO EN CUENTA EL PORCENTAJE DE COBERTURA DE LA GARANTIA*/
   if @w_porcentaje_cobertura = 'S' begin

        select @w_valor  = isnull((@w_monto * @w_porcen_cobertura)/100,0)

     
      /* RUBRO TIPO COMISION FAG */
      if @w_concepto = @w_parametrot_fag begin


         select @w_tipo_productor = en_casilla_def
         from cobis..cl_ente
         where en_ente = @w_cliente
	 set transaction isolation level read uncommitted

         if @w_tipo_productor is null begin
	      if @@rowcount =  0 begin  
        	 select @w_error = 710373
	         return @w_error
	      end
         end

        ---CUANTOS MESSES TIENE EL PLAZO DEFINIDO PARA EL CREDITO 
 	select @w_dias_plazo = td_factor 
	from   ca_tdividendo
	where  td_tdividendo = @w_tplazo
	select @w_plazo_en_meses = isnull((@w_plazo * @w_dias_plazo)/30,0)


        select @w_gracia_en_meses = 0
        if  @w_gracia_cap > 0
            select @w_gracia_en_meses = isnull((@w_dias_div * @w_gracia_cap) / 30,0)


        ---SACAR EL VALOR DE LA TABLA ca_tablas_dos_rangos

	select @w_tasa_comision = isnull(tdr_tasa,0)
	 from ca_tablas_dos_rangos
	where tdr_concepto = @w_parametrot_fag
	and   tdr_variable = @w_tipo_productor
	and @w_plazo_en_meses  between tdr_valor1_min    and  tdr_valor1_max ---Plazo
	and @w_gracia_en_meses between tdr_valor2_min    and  tdr_valor2_max  ---Gracia
        if @@rowcount = 0 begin
           PRINT 'rubrocal.sp no tiene comision FAG'
           return 0
        end
        select @w_porcentaje =  @w_tasa_comision
       

      end   ---COMISION FAG 
   end

   if @w_concepto_asociado is not null begin

      select @w_valor = rot_valor
      from ca_rubro_op_tmp
      where rot_operacion  = @i_operacion
      and rot_concepto = @w_concepto_asociado


      ---PARA IVA
      if @w_iva_siempre = 'S'  begin

        /* DETERMINACION DE LA TASA A APLICAR */ 
        select  
        @w_porcentaje  = isnull(vd_valor_default,0)
        from    ca_valor,ca_valor_det
        where   va_tipo   = @w_referencial 
        and     vd_tipo   = @w_referencial
        and     vd_sector = @w_sector

       if @@rowcount = 0  begin
          print '(recalrop.sp) concepto asociado. Parametrizar Tasa para rubro..' + cast ( @w_referencial as varchar)
          return  710076
      end
     end
      ---PARA IVA
    


   end

  
   select @w_valor_rubro        = isnull(@w_valor * @w_porcentaje/100 ,0)
   select @w_valor_rubro        = round(@w_valor_rubro,@w_num_dec)

   /*ACTUALIZACION DE LOS VALORES EN LA TABLA DE RUBROS*/

   if @w_valor_rubro >= 0 begin

    update ca_rubro_op_tmp
    set rot_valor          =  @w_valor_rubro,
        rot_porcentaje     = @w_porcentaje,
        rot_porcentaje_efa = @w_porcentaje
    where rot_operacion = @i_operacion
    and   rot_concepto  = @w_concepto
	if @@error != 0 
	return 705003
   end 
  

 fetch   cursor_act_rubros_otperido into
 @w_concepto,
 @w_porcentaje,
 @w_porcentaje_cobertura,
 @w_tipo_garantia,
 @w_concepto_asociado,
 @w_iva_siempre,
 @w_referencial

end /*WHILE CURSOR RUBROS*/
close cursor_act_rubros_otperido
deallocate cursor_act_rubros_otperido



return 0
go
