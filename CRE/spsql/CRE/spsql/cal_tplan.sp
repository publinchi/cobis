/************************************************************************/
/*  Archivo:                cal_tplan.sp                                */
/*  Stored procedure:       sp_cal_tplan                                */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_cal_tplan' and type = 'P')
   drop proc sp_cal_tplan
go

create proc sp_cal_tplan
   @i_operacion	int,
   @i_concepto	char(1),
   @o_retorno      char(1) output 
as
declare	@w_dias_div	          int,
        @w_cont_ddiv          int,
		@w_tdividendo         catalogo,
		@w_periodo_int        int,
		@w_operacion          int,
		@w_fecha_desemb       datetime,
	    @w_fecha_venci        datetime,
		@w_f_inicio           datetime,
		@w_f_fin              datetime,
		@w_dias_vencidos_op	  int,
		@w_div_act            int,
		@w_conexion           int,
        @w_error              int,
        @w_msg                descripcion,
        @w_sp_name            descripcion

select @w_conexion = @@spid * 100

delete cr_cal_tplan_tmp
where  conexion = @w_conexion		

delete cr_res_tplan_tmp
where  conexion = @w_conexion		

delete cr_fin_tplan_tmp
where  conexion = @w_conexion		


if @i_concepto = 'C'
begin
   insert into cr_cal_tplan_tmp
   select @w_conexion,
	  di_fecha_ini,
	  di_fecha_ven,
	  di_dividendo
   from   cob_cartera..ca_amortizacion,
	  cob_cartera..ca_dividendo,
	  cob_cartera..ca_rubro_op
   where  am_operacion   = @i_operacion
   and	  am_operacion	 = di_operacion
   and	  am_operacion	 = ro_operacion
   and	  ro_operacion	 = di_operacion
   and	  am_dividendo   = di_dividendo
   and    ro_concepto    = am_concepto
   and    am_cuota       > 0
   and    ro_tipo_rubro  = 'C'

   if not exists (select 1 from cr_cal_tplan_tmp where dividendo = 1 and conexion = @w_conexion)
   begin

      select @w_fecha_desemb= min(di_fecha_ini)
      from   cob_cartera..ca_dividendo
      where  di_operacion   = @i_operacion

      select @w_fecha_venci = min(di_fecha_ven)
      from   cob_cartera..ca_amortizacion,
	     cob_cartera..ca_dividendo,
	     cob_cartera..ca_rubro_op
      where  am_operacion   = @i_operacion
      and    am_operacion   = di_operacion
      and    am_operacion   = ro_operacion
      and    ro_operacion   = di_operacion
      and    am_dividendo   = di_dividendo
      and    ro_concepto    = am_concepto
      and    am_cuota       > 0
      and    ro_tipo_rubro  = 'C'

      insert into cr_cal_tplan_tmp values
      (@w_conexion, @w_fecha_desemb, @w_fecha_venci, 1)
   end
end

if @i_concepto = 'I'
begin
   insert into cr_cal_tplan_tmp
   select @w_conexion,
	  di_fecha_ini,
	  di_fecha_ven,
	  di_dividendo
   from   cob_cartera..ca_amortizacion,
	  cob_cartera..ca_dividendo,
	  cob_cartera..ca_rubro_op
   where  am_operacion   = @i_operacion
   and	  am_operacion	 = di_operacion
   and	  am_operacion	 = ro_operacion
   and	  ro_operacion	 = di_operacion
   and	  am_dividendo   = di_dividendo
   and    ro_concepto    = am_concepto
   and    am_cuota       > 0
   and    ro_tipo_rubro  = 'I'

   if not exists (select 1 from cr_cal_tplan_tmp where dividendo = 1 and conexion = @w_conexion)
   begin
      select @w_fecha_desemb= min(di_fecha_ini)
      from   cob_cartera..ca_dividendo
      where  di_operacion   = @i_operacion

      select @w_fecha_venci = min(di_fecha_ven)
      from   cob_cartera..ca_amortizacion,
	     cob_cartera..ca_dividendo,
	     cob_cartera..ca_rubro_op
      where  am_operacion   = @i_operacion
      and    am_operacion   = di_operacion
      and    am_operacion   = ro_operacion
      and    ro_operacion   = di_operacion
      and    am_dividendo   = di_dividendo
      and    ro_concepto    = am_concepto
      and    am_cuota       > 0
      and    ro_tipo_rubro  = 'I'

      insert into cr_cal_tplan_tmp values
      (@w_conexion, @w_fecha_desemb, @w_fecha_venci, 1)
   end
end

declare cur_calculo cursor for
select 	fecha_ini,
	fecha_fin,
	dividendo
from  	cr_cal_tplan_tmp
where	conexion = @w_conexion
order by dividendo
for read only
open  cur_calculo
fetch cur_calculo into 
@w_f_inicio,
@w_f_fin,
@w_div_act

while @@fetch_status = 0
begin
   if @@fetch_status = -1
   begin
      close cur_calculo
      deallocate cur_calculo
      select @w_error = 21000,
             @w_msg   = 'ERROR EN CURSOR'
      goto ERROR
   end

   exec cob_cartera..sp_dias_cuota_360
   @i_fecha_ini   = @w_f_inicio,
   @i_fecha_fin   = @w_f_fin,
   @o_dias        = @w_dias_vencidos_op out

   insert into cr_res_tplan_tmp values
   (@w_conexion,@w_f_inicio,@w_f_fin,@w_div_act, @w_dias_vencidos_op )


   fetch cur_calculo into 
   @w_f_inicio,
   @w_f_fin,
   @w_div_act
end
close cur_calculo 
deallocate cur_calculo 

insert into cr_fin_tplan_tmp
select	dias,
	count(1),
	conexion
from	cr_res_tplan_tmp
where	conexion = @w_conexion
group by dias,conexion

if @@rowcount > 1
begin
   select @o_retorno = 'V'
end
else 
begin
   select @o_retorno = 'L'
end

ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = @w_error
   return @w_error  


GO
