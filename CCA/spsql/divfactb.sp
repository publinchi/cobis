/************************************************************************/
/*	Archivo:		    divfactb.sp                                     */
/*	Stored procedure:	sp_divfact_batch                                */
/*	Base de datos:		cob_cartera                                     */
/*	Producto: 		    Cartera                                         */
/*	Disenado por:  		Xavier Maldonado                                */
/*	Fecha de escritura:	Ago. 2000                                       */
/************************************************************************/
/*				IMPORTANTE                                              */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	"MACOSA".                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier alteracion o agregado hecho por alguno de sus             */
/*	usuarios sin el debido consentimiento por escrito de la             */
/*	Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*				PROPOSITO                                               */
/*	Genera los dividendos de la nueva operacion en tabla                */
/*      ca_dividendo_tmp para las operaciones de factoring.             */
/*      Abr-03-20008   M.Roa          Adicion fecha cancelacion         */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_divfact_batch')
	drop proc sp_divfact_batch
go


create proc sp_divfact_batch
   @i_operacionca                  int,
   @i_tramite                      int

as
declare 
   @w_sp_name                      descripcion,
   @w_return                       int,
   @w_error                        int,
   @w_dividendo                    int,
   @w_dias_cuota                   int, --DAG
   @w_dia_fijo                     int,
   @w_est_no_vigente               tinyint,
   @w_est_vigente                  tinyint,
   @w_tramite                      int,
   @w_toperacion                   catalogo,
   @w_fecha_ini                    datetime,
   @w_tipo                         char(1),
   @w_tipo_amortizacion            varchar(10),
   @w_contador                     int,
   @w_valor                        money,
   @w_fecfin_neg                   datetime,
   @w_num_negocio                  varchar(64),
   @w_err                          int,
   @w_grupo 			   int,
   @w_num_doc			   varchar(16),
   @w_proveedor		           int,
   @w_prorroga                     char(1)  
   
/* CARGA DE VARIABLES INICIALES */
select @w_sp_name = 'sp_divfact_batch'

select @w_err = 0

select @w_tramite           = opt_tramite,
       @w_toperacion        = opt_toperacion,
       @w_fecha_ini         = opt_fecha_liq,
       @w_tipo              = opt_tipo,
       @w_tipo_amortizacion = opt_tipo_amortizacion
  from ca_operacion_tmp
 where opt_operacion = @i_operacionca

if @@rowcount = 0 begin
    select @w_error = 710123 
    goto ERROR
end
  
if exists (select 1 from ca_prorroga
           where pr_operacion = @i_operacionca
           and   pr_nro_cuota = 1)
select @w_prorroga = 'S'
else
select @w_prorroga = 'N'
 
--print 'estoy en %1! sp_divfact_batch', @i_tramite 
if not exists (select 1 from cob_credito..cr_facturas
               where fa_tram_prov = @i_tramite ) begin
      insert into ca_dividendo_tmp (
      dit_operacion,   dit_dividendo,   dit_fecha_ini,
      dit_fecha_ven,   dit_de_capital,  dit_de_interes,
      dit_gracia,      dit_gracia_disp, dit_estado,
      dit_dias_cuota,  dit_prorroga, 	dit_intento,
      dit_fecha_can)
      values (
      @i_operacionca,   1,   		 '12/12/2000',
      '12/12/2000',    'S',   		 'S',
      0, 		        0,   		  0,
      30, 		        @w_prorroga,  0,
      '01/01/1900')

      if @@error <> 0 begin
         select @w_error = 710001
         goto ERROR
         end
      else begin
         select @w_err = 1
         goto ERROR
      end
end 


if (@w_tipo <> 'D') and (@w_tipo <> 'F') begin
   select @w_error = 70892 
   goto ERROR
end

if @w_tipo_amortizacion <> 'MANUAL' begin
   select @w_error = 70893
   goto ERROR
end

select @w_contador = 0

begin
declare dividendo_fac  cursor for
   select fa_tramite,fa_valor,fa_fecfin_neg,fa_num_negocio,
          fa_grupo,fa_referencia,fa_proveedor 
     from cob_credito..cr_facturas
    where fa_tram_prov = @i_tramite
    order by fa_fecfin_neg
    for read only

    open dividendo_fac
   fetch dividendo_fac into
         @w_tramite,@w_valor,@w_fecfin_neg,@w_num_negocio,
         @w_grupo,@w_num_doc,@w_proveedor

       while (@@fetch_status = 0 ) begin

       if @@fetch_status = -1 begin    /* error en la base */
          select @w_error = 70894
          goto  ERROR
       end

      select @w_contador = @w_contador + 1
     
     if @w_fecha_ini < @w_fecfin_neg 
        select @w_dias_cuota = isnull(datediff(dd,@w_fecha_ini,@w_fecfin_neg),0)
     else begin
        select @w_error = 70895
        goto  ERROR
     end

       if exists(select 1 from ca_prorroga
                 where pr_operacion = @i_operacionca
                 and   pr_nro_cuota = @w_contador)
          select @w_prorroga = 'S'
       else
          select @w_prorroga = 'N'


      insert into ca_dividendo_tmp (
      dit_operacion,   dit_dividendo,   dit_fecha_ini,
      dit_fecha_ven,   dit_de_capital,  dit_de_interes,
      dit_gracia,      dit_gracia_disp, dit_estado,
      dit_dias_cuota,  dit_prorroga,	dit_intento,
      dit_fecha_can)
      values (
      @i_operacionca,   @w_contador,    @w_fecha_ini,
      @w_fecfin_neg,    'S',   		    'S',
      0,   		        0,   		    0,
      @w_dias_cuota, 	@w_prorroga,	0,
      '01/01/1900')

      if @@error <> 0 begin
         select @w_error = 710001
         goto ERROR
      end               

      update cob_credito..cr_facturas
      set fa_div_hijo = @w_contador
      where fa_tram_prov = @i_tramite
        and fa_grupo = @w_grupo
        and fa_referencia = @w_num_doc
        and fa_proveedor = @w_proveedor
         
     
      fetch dividendo_fac into
      @w_tramite,@w_valor,@w_fecfin_neg,@w_num_negocio,
      @w_grupo,@w_num_doc,@w_proveedor 
     end

     close dividendo_fac     
     deallocate dividendo_fac     
     select @w_err = 1    
     --goto ERROR
end

ERROR:
   if @w_err = 0
      return @w_error            
   else
      return 0

go
