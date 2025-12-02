/************************************************************************/
/*	Archivo:		distnomi.sp        			*/
/*	Stored procedure:	sp_distribucion_nomina                  */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Rodrigo Garces-Patricio Narvaez         */
/*	Fecha de escritura:	jun  98 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	Mantenimiento a las tablas de Nomina, ca_definicion_nomina y    */
/*      ca_nomina, ademas a la de cuotas adicionales ca_cuota_adicional */ 
/*	I: Insercion de cuotas  adicionales para el manejo de nomina	*/
/*      D: Eliminacion de registros de nomina           		*/
/*	S: Busqueda de distribuciones					*/
/************************************************************************/
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	16/jun/98      A. Ramirez         Emision Inicial               */
/*					  PERSONALIZACION B.ESTADO      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_distribucion_nomina')
	drop proc sp_distribucion_nomina
go

create proc sp_distribucion_nomina
	@i_operacion		char(1)  = NULL,
       	@i_banco		cuenta   = NULL,
        @i_concepto         	catalogo = NULL,
       	@i_div_inicial		smallint = NULL,
        @i_periodicidad		catalogo = NULL,
	@i_val_inicial		money    = 0,
        @i_por_incremento	float    = 0,
        @i_per_incremento	catalogo = NULL,
        @i_por_abono	        float    = 0
as
declare @w_sp_name		descripcion,
        @w_operacionca          int,
        @w_op_tdividendo        catalogo,
        @w_factor_op		smallint,
        @w_factor_per		smallint,
        @w_factor_inc		smallint,
        @w_factor_i  		smallint,
        @w_factor		smallint,
        @w_dividendos           int,
        @w_total_dividendos     int,
	@w_valor		money,
        @w_valor_final          money,
        @w_contador             int,
        @w_porcentaje           float,
        @w_valor_finmes         money,
        @w_valor_inmes          money,
        @w_cliente              int,
        @w_toperacion           catalogo,
        @w_fecha_div            datetime,
        @w_quincenal            varchar(30),
        @w_return               int,
        @w_error                int   


/*  NOMBRE DEL SP */
select	@w_sp_name = 'sp_distribucion_nomina'

/* INGRESO DEL REGISTRO DE NOMINA */
select 
@w_operacionca   = opt_operacion,
@w_op_tdividendo = opt_tdividendo,
@w_cliente       = opt_cliente,
@w_toperacion    = opt_toperacion
from ca_operacion_tmp
where opt_banco   = @i_banco

if @@rowcount = 0
begin
   select @w_error = 710022   
   goto ERROR
end    

/* INSERCION DE DATOS DE NOMINA Y CUOTAS ADICIONALES */
if @i_operacion = 'I' begin

   /*VALIDACION DE PERIODICIDADES CON RESPECTO A LA OPERACION*/
   select @w_factor_op = td_factor
   from ca_tdividendo
   where td_tdividendo = @w_op_tdividendo

   select @w_factor_per = td_factor
   from ca_tdividendo
   where td_tdividendo = @i_periodicidad

   select @w_factor_inc = td_factor
   from ca_tdividendo
   where td_tdividendo = @i_per_incremento

   if @w_factor_per < @w_factor_op or @w_factor_inc < @w_factor_op
   or @w_factor_inc < @w_factor_per
   begin
      select @w_error = 710099
      goto ERROR              
   end

   begin tran

   /*INSERCION EN CA_DEFINICION_NOMINA*/
   insert into ca_definicion_nomina_tmp (
   dnt_operacion,
   dnt_concepto,
   dnt_div_inicial,
   dnt_periodicidad,
   dnt_val_inicial,
   dnt_por_incremento,
   dnt_per_incremento,
   dnt_por_abono)
   values (
   @w_operacionca,
   @i_concepto,
   @i_div_inicial,
   @i_periodicidad,
   @i_val_inicial,
   @i_por_incremento,
   @i_per_incremento,
   @i_por_abono )

   if @@error != 0 begin
      select @w_error = 710091
      goto ERROR
   end

   /*INSERCION EN CA_NOMINA Y ACTUALIZACION EN CUOTAS ADICIONALES*/

   /*CALCULO DEL NUMERO DE DIVIDENDOS DE LA OPERACION*/
   select @w_total_dividendos = count(dit_dividendo)
   from ca_dividendo_tmp
   where dit_operacion = @w_operacionca  

   /*NUMERO DE DIVIDENDOS PARA EL LAZO*/
   select @w_dividendos = @i_div_inicial

   /*ACTUALIZACION DEL VALOR CON EL % DE INCREMENTO DE ACUERDO A LA PERIODIC.*/
   select @w_factor = @w_factor_per / @w_factor_op
   select @w_factor_i = @w_factor_inc / @w_factor_op
   
   /*CURSOR PARA ACTUALIZAR EL VALOR CON EL PORCENTAJE DEFINIDO*/
   select @w_valor = @i_val_inicial   

   while @w_dividendos <= @w_total_dividendos begin
      if  ((@w_dividendos - @i_div_inicial) % @w_factor_i) = 0 and 
           @w_dividendos <> @i_div_inicial  begin
         /* INCREMENTAR LA CUOTA */
         select @w_valor = (@w_valor + (@w_valor * 
                             @i_por_incremento)/100)
      end
      /*VALIDACION DE QUE EL DIVIDENDO SEA DE CAPITAL*/
      if not exists ( select 1
                 from ca_dividendo_tmp
                 where dit_operacion  = @w_operacionca
                 and   dit_dividendo  = @w_dividendos
                 and   dit_de_capital = 'S' ) begin
         select @w_error = 710102
         goto ERROR
      end
      /*ACTUALIZACION DEL VALOR EN CA_CUOTAS_ADICIONALES PARA EL DIVIDENDO*/
      if @i_concepto <> '2' begin
         update ca_cuota_adicional_tmp
         set cat_cuota = cat_cuota + @w_valor
         from ca_cuota_adicional_tmp
         where cat_operacion = @w_operacionca
         and   cat_dividendo = @w_dividendos

         if @@error != 0 begin
            select @w_error = 710100
            goto ERROR
         end             
         /*INSERCION DE LA DISTRIBUCION EN CA_NOMINA*/
         insert into ca_nomina_tmp (
         not_operacion,
         not_dividendo,
         not_concepto,
         not_valor )
         values (
         @w_operacionca,
         @w_dividendos,
         @i_concepto,
         @w_valor )

         if @@error != 0
         begin
            --print 'aqui6'
            select @w_error = 710091
            goto ERROR
         end
      end
      else   begin
         /*OBTENER PARAMETRO PARA TIPO DE CUOTA QUINCENAL*/
         select @w_quincenal = pa_char
         from cobis..cl_parametro
         where pa_nemonico = 'QUIN'
         and pa_producto   = 'CCA' 
	 set transaction isolation level read uncommitted

         if @w_quincenal <> @w_op_tdividendo begin
            select @w_error = 710108
            goto ERROR
         end

         /*OBTENER PORCENTAJE DE APLICACION PRIMA EN FIN DE MES*/
         select @w_porcentaje = pa_float
         from cobis..cl_parametro
         where pa_nemonico = 'PRI'
         and pa_producto   = 'CCA'
	 set transaction isolation level read uncommitted

         select @w_valor_finmes = (@w_valor * @w_porcentaje)/100

         select @w_valor_inmes = @w_valor - @w_valor_finmes           

         /*VALIDAR FECHA DEL DIVIDENDO*/
         select @w_fecha_div = dit_fecha_ven
         from ca_dividendo_tmp
         where dit_operacion = @w_operacionca
         and   dit_dividendo = @w_dividendos

	 if datepart(dd,@w_fecha_div) = 15         begin
            /*VALOR PARA EL DIA QUINCE*/
            /*INSERCION DE LA DISTRIBUCION EN CA_NOMINA*/
            insert into ca_nomina_tmp (
            not_operacion,
            not_dividendo,
            not_concepto,
            not_valor )
            values (
            @w_operacionca,
            @w_dividendos,
            @i_concepto,
            @w_valor_inmes )

            if @@error != 0  begin
               select @w_error = 710091
               goto ERROR
            end

            update ca_cuota_adicional_tmp
            set cat_cuota = cat_cuota + @w_valor_inmes
            from ca_cuota_adicional_tmp
            where cat_operacion = @w_operacionca
            and   cat_dividendo = @w_dividendos

            if @@error != 0 begin
               select @w_error = 710100
               goto ERROR
            end                

            /*VALOR PARA EL DIA TREINTA*/
            /*INSERCION DE LA DISTRIBUCION EN CA_NOMINA*/
            insert into ca_nomina_tmp (
            not_operacion,
            not_dividendo,
            not_concepto,
            not_valor )
            values (
            @w_operacionca,
            @w_dividendos + 1,
            @i_concepto,
            @w_valor_finmes )

            if @@error != 0  begin
               select @w_error = 710091
               goto ERROR
            end

            update ca_cuota_adicional_tmp
            set cat_cuota = cat_cuota + @w_valor_finmes
            from ca_cuota_adicional_tmp
            where cat_operacion = @w_operacionca
            and   cat_dividendo = @w_dividendos + 1

            if @@error != 0    begin
               select @w_error = 710100
               goto ERROR
            end                      
         end
         else begin
            /*VALOR PARA EL DIA 30*/
            /*INSERCION DE LA DISTRIBUCION EN CA_NOMINA*/
            insert into ca_nomina_tmp (
            not_operacion,
            not_dividendo,
            not_concepto,
            not_valor )
            values (
            @w_operacionca,
            @w_dividendos,
            @i_concepto,
            @w_valor_finmes )

            if @@error != 0  begin
               select @w_error = 710091
               goto ERROR
            end

            update ca_cuota_adicional_tmp
            set cat_cuota = cat_cuota + @w_valor_finmes
            from ca_cuota_adicional_tmp
            where cat_operacion = @w_operacionca
            and   cat_dividendo = @w_dividendos

            if @@error != 0  begin
               select @w_error = 710100
               goto ERROR
            end                                   

            /*VALOR PARA EL DIA QUINCE*/
            /*INSERCION DE LA DISTRIBUCION EN CA_NOMINA*/
            insert into ca_nomina_tmp (
            not_operacion,
            not_dividendo,
            not_concepto,
            not_valor )
            values (
            @w_operacionca,
            @w_dividendos + 1,
            @i_concepto,
            @w_valor_inmes )

            if @@error != 0 begin
               select @w_error = 710091
               goto ERROR
            end
            /*update ca_nomina_tmp
            set not_valor = @w_valor_inmes
            where not_operacion = @w_operacionca
            and   not_dividendo = @w_dividendos - 1

            if @@error != 0 begin
               select @w_error = 705078
               goto ERROR
            end*/

            update ca_cuota_adicional_tmp
            set cat_cuota = cat_cuota + @w_valor_inmes
            from ca_cuota_adicional_tmp
            where cat_operacion = @w_operacionca
            and   cat_dividendo = @w_dividendos + 1

            if @@error != 0 begin
               select @w_error = 710100
               goto ERROR
            end               
         end /*INICIO O FIN DE MES*/
      end /*CONCEPTO PRIMA*/

      select @w_dividendos = @w_dividendos + @w_factor 
       
   end /*WHILE*/

   commit tran

end

/*ELIMINACION DE DATOS DE NOMINA*/
if @i_operacion = 'D' begin
   begin tran

   update ca_cuota_adicional_tmp
   set cat_cuota = cat_cuota - not_valor
   from  ca_cuota_adicional_tmp A,ca_nomina_tmp
   where A.cat_operacion = @w_operacionca
   and   not_operacion    = A.cat_operacion
   and   not_concepto     = @i_concepto    
   and   A.cat_dividendo = not_dividendo

   if @@error <> 0  begin
      select @w_error = 710100
      goto ERROR
   end 

   delete ca_definicion_nomina_tmp
   where dnt_operacion = @w_operacionca    
   and   dnt_concepto  = @i_concepto

   if @@error <> 0 begin
      select @w_error = 710101
      goto ERROR
   end 

   delete ca_nomina_tmp
   where not_operacion = @w_operacionca    
   and   not_concepto  = @i_concepto

   if @@error <> 0 begin
      select @w_error = 710101
      goto ERROR
   end 

   commit tran

end

/*BUSQUEDA DE DATOS DE NOMINA*/
if @i_operacion = 'S' begin

   select
   'Cod.Concepto'   = dnt_concepto,
   'Concepto'       = substring(valor,1,20),
   'Cuota Inicial'    = x.dnt_div_inicial,
   'Periodicidad'   = (select substring(td_descripcion,1,20)
                       from ca_tdividendo 
                       where td_tdividendo = x.dnt_periodicidad),
   'Val.Inicial'    = x.dnt_val_inicial,
   'Por.Incremento' = x.dnt_por_incremento,
   'Per.Incremento' = (select substring(td_descripcion,1,20)
                       from ca_tdividendo 
                       where td_tdividendo = x.dnt_per_incremento),
   'Por.Abono'      = dnt_por_abono
   from ca_definicion_nomina_tmp x, cobis..cl_catalogo C
   where dnt_operacion  = @w_operacionca
   and   C.tabla        = (select codigo
                          from cobis..cl_tabla
                          where tabla = 'ca_concepto_nomina')
   and   x.dnt_concepto = C.codigo  

end

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug='N',    @t_file=null,
   @t_from=@w_sp_name,   @i_num = @w_error
   return @w_error
go

