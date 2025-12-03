/************************************************************************/
/*	Archivo:		       divfact.sp			                        */
/*	Stored procedure:	   sp_divfact                                   */
/*	Base de datos:		   cob_cartera			                        */
/*	Producto: 		       Cartera				                        */
/*	Disenado por:  		Xavier Maldonado 		                        */
/*	Fecha de escritura:	Ago. 2000 				                        */
/************************************************************************/
/*				                    IMPORTANTE                          */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	"COBISCORP".                                                        */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la             */
/*	Presidencia Ejecutiva de COBISCORP o su representante.		        */
/************************************************************************/  
/*	                              PROPOSITO                             */
/*	Genera los dividendos de la nueva operacion en tabla                */
/* ca_dividendo_tmp para las operaciones Documentos Descontados         */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      OCT-2005       Elcira Pelaez  Cambios para el BAC               */
/*      SEP-2006       Elcira Pelaez  Cambios para el RFP 126 BAC       */
/*      NOV-02-20006   E.Pelaez       NR-126 Docmentos Descontados      */
/*      Abr-03-20008   M.Roa          Adicion fecha cancelacion         */
/*      Jun-01-2022    G. Fernandez   Se comenta prints                 */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_divfact')
	drop proc sp_divfact
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_divfact
   @i_operacionca                  int,
   @i_tramite                      int

as
declare 
   @w_sp_name                      descripcion,
   @w_error                        int,
   @w_tramite                      int,
   @w_fecha_ini                    datetime,
   @w_tipo                         char(1),
   @w_tipo_amortizacion            varchar(10),
   @w_contador                     int,
   @w_fecfin_neg                   datetime,
   @w_dias_cuota                   int,
   @w_base_calculo                 char(1),
   @w_causacion                    char(1),   
   @w_moneda                       smallint,
   @w_dias_anio                    smallint,
   @w_float                        float,
   @w_di_dias_cuota                int,
   @w_fa_valor                     money,
   @w_fa_referencia                char(16),
   @w_di_dividendo                 int,
   @w_fa_fecfin_neg                datetime,
   @w_valor_calc                   float,
   @w_tasa_dia                     float,
   @w_dias_int                     int,
   @w_monto                        float,
   @w_tasa_nom                     float,
   @w_tasa_efa                     float,
   @w_num_dec                      float,
   @w_porcentaje_col               money,
   @w_concepto_col                 catalogo,
   @w_parametro_col                catalogo,
   @w_colchon_disp                 money,
   @w_fecha_ini_facturas           datetime,
   @w_rowcount                     int


   
   
-- CARGA DE VARIABLES INICIALES 
select @w_sp_name = 'sp_divfact'

 
 


select @w_tramite           = opt_tramite,
       @w_fecha_ini         = opt_fecha_liq,
       @w_tipo              = opt_tipo,
       @w_tipo_amortizacion = opt_tipo_amortizacion,
       @w_base_calculo      = opt_base_calculo,
       @w_dias_anio         = opt_dias_anio,
       @w_moneda            = opt_moneda,
       @w_causacion         = opt_causacion,
       @w_monto             = opt_monto
       
  from ca_operacion_tmp
 where opt_operacion = @i_operacionca

if @@rowcount = 0 
begin
    select @w_error = 710123 
    goto ERROR
end
 
select @w_fecha_ini_facturas = @w_fecha_ini

exec @w_error = sp_decimales
@i_moneda      = @w_moneda,
@o_decimales   = @w_num_dec out

if @w_error != 0 
   return @w_error

if not exists (select 1 from cob_credito..cr_facturas
               where fa_tramite = @i_tramite ) 
begin
      insert into ca_dividendo_tmp (
      dit_operacion,   dit_dividendo,   dit_fecha_ini,
      dit_fecha_ven,   dit_de_capital,  dit_de_interes,
      dit_gracia,      dit_gracia_disp, dit_estado,
      dit_dias_cuota,  dit_intento,     dit_prorroga,
      dit_fecha_can)
      values (
      @i_operacionca,  1,              '12/12/2000',
      '12/12/2000',    'S',            'S',
      0,               0,              0,
      30,              0,              'N',
      '01/01/1900')

      if @@error <> 0 
      begin
         select @w_error = 710001
         goto ERROR
      end

end 

if @w_tramite is null 
begin
   select @w_error = 70891 
   goto ERROR
end


if (@w_tipo <> 'D') and  (@w_tipo <> 'F' ) 
begin
   select @w_error = 70892 
   goto ERROR
end

if @w_tipo_amortizacion <> 'MANUAL' 
begin
   select @w_error = 70893
   goto ERROR
end

if  exists (select 1 from cob_credito..cr_facturas
               where fa_tramite = @i_tramite ) 
begin
   

  delete ca_dividendo_tmp
  where dit_operacion = @i_operacionca
        

  
   select @w_contador = 1
      
   declare dividendo_fac  cursor for
   select distinct fa_fecfin_neg
     from cob_credito..cr_facturas
    where fa_tramite = @i_tramite
    order by fa_fecfin_neg
    for read only

    open dividendo_fac
   fetch dividendo_fac into
         @w_fecfin_neg

       while (@@fetch_status = 0 )
       begin

       if @@fetch_status = -1 
       begin    
          select @w_error = 70894
          goto  ERROR
       end


      if @w_base_calculo = 'R' 
          select @w_dias_cuota = datediff(dd,@w_fecha_ini,@w_fecfin_neg)

      
      if @w_base_calculo = 'E' 
            exec @w_error = sp_dias_cuota_360
              @i_fecha_ini = @w_fecha_ini,
              @i_fecha_fin = @w_fecfin_neg,
              @o_dias      = @w_dias_cuota out 
              
              if @w_error != 0
                 goto ERROR
    
    
      ---PRINT 'divfact.sp @w_dias_cuota para ca_dividendo' + @w_dias_cuota
      
      insert into ca_dividendo_tmp (
      dit_operacion,   dit_dividendo,   dit_fecha_ini,
      dit_fecha_ven,   dit_de_capital,  dit_de_interes,
      dit_gracia,      dit_gracia_disp, dit_estado,
      dit_dias_cuota,  dit_intento,     dit_prorroga,
      dit_fecha_can)
      values (
      @i_operacionca,   @w_contador,    @w_fecha_ini,
      @w_fecfin_neg,    'S',   		    'S',
      0,		        0,		        0,
      @w_dias_cuota, 	0,              'N',
      '01/01/1900')

      if @@error <> 0 begin
         select @w_error = 710001
         goto ERROR
      end               
      

      select @w_contador = @w_contador + 1,
             @w_fecha_ini = @w_fecfin_neg


      fetch dividendo_fac into
      @w_fecfin_neg

     end

     close dividendo_fac     
     deallocate dividendo_fac     



   --COLOCA A CADA FACTURA EL DIVIDENDO CORRESPONDIENTE
   
   update cob_credito..cr_facturas 
      set fa_dividendo = dit_dividendo
      from ca_dividendo_tmp
    where fa_tramite = @w_tramite
      and dit_operacion = @i_operacionca
      and fa_fecfin_neg  =  dit_fecha_ven
	  
      --GFP se suprime print
	  /*
      if @@rowcount = 0
         PRINT 'cob_cartera divfact.sp no actualizo los dividendos en cr_facturas'
	  */
   
   -- CARGA LA TABLA DE FACTURAS DE CARTERA
   
   if exists (select 1 from  ca_facturas
              where fac_operacion = @i_operacionca)
    delete ca_facturas
    where fac_operacion = @i_operacionca
    
   --GFP se suprime print
   --PRINT 'divfact.sp FECHA INICIO DE LAS FACTIRAS @w_fecha_ini_facturas'+ @w_fecha_ini_facturas
   
   declare interes_facturas  cursor for
   
   select dit_dias_cuota,
          fa_valor,
          fa_referencia,
          dit_dividendo,
          fa_fecfin_neg

    from cob_credito..cr_facturas,
         ca_dividendo_tmp
   where fa_tramite = @i_tramite
      and dit_operacion = @i_operacionca
      and fa_fecfin_neg  =  dit_fecha_ven
      order by fa_dividendo
      
       for read only
   
       open interes_facturas
      fetch interes_facturas into
      
          @w_di_dias_cuota,
          @w_fa_valor,
          @w_fa_referencia,
          @w_di_dividendo,
          @w_fa_fecfin_neg
          
   
      while (@@fetch_status = 0 )
      begin
   
         if @@fetch_status = -1
            begin   
             select @w_error = 70894
             goto  ERROR
          end
          
          

           if @w_base_calculo = 'R' 
                select @w_dias_cuota = datediff(dd,@w_fecha_ini_facturas,@w_fa_fecfin_neg)
      
            
            if @w_base_calculo = 'E' 
                  exec @w_error = sp_dias_cuota_360
                    @i_fecha_ini = @w_fecha_ini_facturas,
                    @i_fecha_fin = @w_fa_fecfin_neg,
                    @o_dias      = @w_dias_cuota out 
                    
                    if @w_error != 0
                       goto ERROR
          
   
          select @w_tasa_nom = rot_porcentaje,
                 @w_tasa_efa = rot_porcentaje_efa
          from   ca_rubro_op_tmp
          where  rot_operacion = @i_operacionca
          and    rot_tipo_rubro = 'I'
   
           if @w_tasa_nom > 0
           begin
             
             
             
              if @w_causacion = 'L' 
               begin
                 exec @w_error = sp_calc_intereses
                 @operacion = @i_operacionca,
                 @tasa      = @w_tasa_nom,  
                 @monto     = @w_fa_valor, ---@w_monto,
                 @dias_anio = 360,
                 @num_dias  = @w_dias_cuota,  
                 @causacion = @w_causacion, 
                 @intereses = @w_float out
              
                 if @w_error != 0 
                  goto ERROR
                
              end
              ELSE 
              begin
      
                 select @w_tasa_dia =(exp((-@w_dias_int/360)* log(1+((@w_tasa_efa/100.0)/(360/360))))-1)
                 select @w_float = (@w_tasa_dia * @w_monto) * - 1
         
              end
              select @w_valor_calc = isnull(@w_float,0),
                     @w_valor_calc = round(@w_float,@w_num_dec)
              
           end
           ELSE
           begin
             select  @w_error = 710037 
             goto ERROR
           end
           
          --GFP se suprime print
          --PRINT 'divfact.sp @w_dias_cuota para ca_facturas'+cast(@w_dias_cuota as varchar)
          
         insert into ca_facturas
               (
               fac_operacion,       fac_nro_factura,   fac_nro_dividendo,   fac_fecha_vencimiento,
               fac_valor_negociado, fac_pagado,        fac_intant,          fac_intant_amo,
               fac_estado_factura,
               fac_dias_factura
               )
   
         values  
              (
               @i_operacionca,       @w_fa_referencia,    @w_di_dividendo,     @w_fa_fecfin_neg, 
               @w_fa_valor,          0,                   @w_valor_calc,        0,
               1,
               @w_dias_cuota          
              )
     
   
         fetch interes_facturas into
                @w_di_dias_cuota,
                @w_fa_valor,
                @w_fa_referencia,
                @w_di_dividendo,
                @w_fa_fecfin_neg
         
   
        end
   
        close interes_facturas     
        deallocate interes_facturas     
        
         select @w_colchon_disp = sum((do_valor_neg - fa_valor))
         from  cob_custodia..cu_documentos,
         cob_credito..cr_facturas
         where fa_tramite = @w_tramite
         and  do_num_negocio =  fa_num_negocio
         and fa_referencia = do_num_doc
    
         set rowcount 1
         select @w_porcentaje_col = fa_porcentaje 
         from  cob_custodia..cu_documentos,
         cob_credito..cr_facturas
         where fa_tramite = @w_tramite
         and  do_num_negocio =  fa_num_negocio
         and fa_referencia = do_num_doc
         set rowcount 0
         
         select @w_porcentaje_col = 100 - @w_porcentaje_col
         
       if @w_porcentaje_col > 0 and @w_colchon_disp > 0 
       begin 

            
            ---CODIGO DEL CONCEPTO
            select @w_parametro_col = pa_char
            from cobis..cl_parametro
            where pa_producto = 'CCA'
            and   pa_nemonico = 'COL'
            select @w_rowcount = @@rowcount
            set transaction isolation level read uncommitted
         
            if @w_rowcount = 0     
            begin
               select @w_error = 710314
               goto ERROR
            end 
         
           
            select @w_concepto_col = co_concepto
            from ca_concepto
            where co_concepto = @w_parametro_col
            
            if @@rowcount = 0     
            begin
               select @w_error = 710316
               goto ERROR
            end             
            
            delete  ca_rubro_op_tmp
            where rot_operacion  = @i_operacionca
            and   rot_concepto   = @w_concepto_col
   

            insert into ca_rubro_op_tmp (
            rot_operacion,           rot_concepto,        rot_tipo_rubro,
            rot_fpago,               rot_prioridad,       rot_paga_mora,
            rot_provisiona,          rot_signo,           rot_factor,
            rot_referencial,         rot_signo_reajuste,  rot_factor_reajuste,
            rot_referencial_reajuste,rot_valor,           rot_porcentaje,
            rot_porcentaje_aux,      rot_gracia,          rot_concepto_asociado,
            rot_principal,           rot_porcentaje_efa,  rot_garantia,
            rot_tipo_puntos,         rot_saldo_op,        rot_saldo_por_desem, 
            rot_num_dec,             rot_limite)
            values (
            @i_operacionca,          @w_concepto_col,     'V', ---Valor Fijo
            'R',                     0,                   'N',
            'N',                     null,                 0,
            null,                    null,                 null,
            null,                    @w_colchon_disp,      @w_porcentaje_col,
            @w_porcentaje_col,       0,                    null, 
            'N',                     0,                    0,
             null,                  'N',                  'N', 
             0,      'N')
            if @@error != 0 
            begin
               select @w_error = 710315
                goto ERROR
            end
         end     

        
        

        
end ---existe facturas

return 0

ERROR:
   return @w_error            
   
   

go
