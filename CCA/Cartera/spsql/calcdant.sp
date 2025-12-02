/************************************************************************/
/*	Nombre Fisico       :		calcdant.sp                             */
/*	Nombre Logico   	:	   	sp_calculo_diario_int_dd                */
/*	Base de datos       :		cob_cartera                             */
/*	Producto            : 		Cartera                                 */
/*	Disenado por        :  		Elcira Pelaez Burbano                   */
/*	Fecha de escritura  :	   	oct-2005                                */
/************************************************************************/
/*		              IMPORTANTE                                        */
/*	Este programa es parte de los paquetes bancarios que son       		*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*		              PROPOSITO                                         */
/*	Procedimiento que realiza el calculo diario de intereses            */
/* para documentos descontados   el cual se calcula por cada una de     */
/* las facturas dia a dia y se actualiza con este valor la tabla        */
/*  ca_amortizacion y se genera  la transaccion AMO respectiva          */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/*   NOV-02-20006    E.Pelaez         NR-126 Docmentos Descontados      */
/*   JUN-05-2007     John Jairo Rendon Optimizacion                     */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calculo_diario_int_dd')
	drop proc sp_calculo_diario_int_dd
go

create proc sp_calculo_diario_int_dd
   @s_user  	     login,
   @s_term	        varchar(30),
   @s_date	        datetime,
   @s_ofi	        smallint,
   @i_fecha_proceso datetime,
   @i_operacionca   int,
   @i_cotizacion    float


as declare
   @w_secuencial            int,
   @w_error                 int,
   @w_return                int,
   @w_sp_name               descripcion,
   @w_dif                   money,
   @w_fac_nro_dividendo     int,
   @w_fac_nro_factura       varchar(16),
   @w_fac_intant            money, 
   @w_gar_admisible         char(1),             
   @w_reestructuracion      char(1),
   @w_calificacion	        catalogo,
   @w_op_fecha_ult_proceso  datetime,
   @w_moeda                 smallint,
   @w_op_oficial            int,
   @w_toperacion            catalogo,
   @w_valor_dia             money,
   @w_valor_dia_sobra       money,
   @w_am_concepto           catalogo,
   @w_am_estado             smallint,
   @w_am_periodo            smallint,
   @w_concepto_dd           char(62),
   @w_monto_prv             money,
   @w_dtr_monto             money,
   @w_dtr_monto_mn          money,
   @w_cot_mn                money,
   @w_num_dec               smallint,
   @w_monto_mn              money,
   @w_codvalor              int,
   @w_dividendo             int,
   @w_am_dividendo          smallint,
   @w_am_cuota              money,
   @w_moneda                smallint,
   @w_oficina               int,
   @w_am_acumulado          money,
   @w_valor_int_total       money,
   @w_valor_sobra           money,
   @w_tipo_garantia         tinyint,
   @w_banco                 cuenta,
   @w_moneda_nac            smallint,
   @w_num_dec_mn            tinyint,
   @w_dtr_cuenta            char(3),
   @w_fac_dias_factura      int,
   @w_valor_dia_aux         money,
   @w_amortizado            money,
   @w_amortizo              char(1),
   @w_max_cuota             int
   

-- VARIABLES DE TRABAJO 

select  @w_sp_name         = 'sp_calculo_diario_int_dd',
        @w_am_estado       = 3,
        @w_am_periodo      = 0,
        @w_valor_int_total = 0, 
        @w_valor_dia_sobra = 0,
        @w_monto_prv       = 0,
        @w_amortizo        = 'N',
        @w_max_cuota       = 0




if not exists (select 1 from ca_facturas
                 where fac_operacion = @i_operacionca)

  return 710149



if not exists (select 1 from ca_facturas
where fac_operacion = @i_operacionca
and   fac_intant_amo < fac_intant)
   return 0
   

select 
@w_gar_admisible        = isnull(op_gar_admisible,''),
@w_reestructuracion     = isnull(op_reestructuracion,'N'),
@w_calificacion	      = isnull(op_calificacion,'A'),
@w_op_fecha_ult_proceso = op_fecha_ult_proceso,
@w_moneda                = op_moneda ,
@w_op_oficial           = op_oficial,
@w_toperacion           = op_toperacion,
@w_oficina              = op_oficina,
@w_banco                = op_banco
from ca_operacion
where op_operacion =   @i_operacionca

if @w_gar_admisible = 'S'
   select @w_tipo_garantia = 1  --admisible



-- MANEJO DE DECIMALES 
exec @w_return  = sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec out,
@o_mon_nacional = @w_moneda_nac out,
@o_dec_nacional = @w_num_dec_mn out

if @w_return <> 0 
   return @w_return

      
select @w_concepto_dd    = ro_concepto
from ca_rubro_op
where ro_operacion = @i_operacionca
and ro_tipo_rubro = 'I'

if @@rowcount != 1
   return 0

               
                 


select @w_max_cuota = max(di_dividendo)
from ca_dividendo
where di_operacion = @i_operacionca

select @w_valor_int_total = 0      

declare 

  cursor_div_vigente cursor 
  
for select fac_nro_dividendo, 
           fac_nro_factura,
           fac_intant, 
           fac_dias_factura

from   ca_facturas, ca_dividendo
where  di_operacion = @i_operacionca
and    fac_operacion = di_operacion
and    di_dividendo = fac_nro_dividendo
and    di_estado != 3
and    fac_intant_amo < fac_intant
order by di_dividendo

for read only

open    cursor_div_vigente

fetch   cursor_div_vigente  
into    @w_fac_nro_dividendo,
        @w_fac_nro_factura,
        @w_fac_intant,
        @w_fac_dias_factura
        

--while   @@fetch_status not in (-1,0)
while   @@fetch_status = 0
begin 
      select @w_valor_dia = 0,
             @w_valor_dia_aux = 0,
             @w_amortizado    = 0
             
      select @w_valor_dia =  isnull(round(@w_fac_intant / (1.0 * @w_fac_dias_factura) ,@w_num_dec) ,0)
      select @w_valor_dia_aux = @w_valor_dia
     
      
      select @w_amortizado = fac_intant_amo
      from ca_facturas
      where fac_operacion = @i_operacionca
      and   fac_nro_dividendo  = @w_fac_nro_dividendo
      and   fac_nro_factura  = @w_fac_nro_factura      
      
      select @w_valor_dia = @w_valor_dia + @w_amortizado
      
      
      if @w_valor_dia > @w_fac_intant
      begin
         update ca_facturas
         set fac_intant_amo = fac_intant
         where fac_operacion = @i_operacionca
         and   fac_nro_dividendo  = @w_fac_nro_dividendo
         and   fac_nro_factura  = @w_fac_nro_factura
      end
      ELSE
      begin
         update ca_facturas
         set fac_intant_amo = fac_intant_amo + @w_valor_dia_aux
         where fac_operacion = @i_operacionca
         and   fac_nro_dividendo  = @w_fac_nro_dividendo
         and   fac_nro_factura  = @w_fac_nro_factura         
      end            

      
      select @w_valor_int_total =   @w_valor_int_total + isnull(@w_valor_dia_aux,0)

   fetch   cursor_div_vigente  
   
   into    @w_fac_nro_dividendo,
           @w_fac_nro_factura,
           @w_fac_intant, 
           @w_fac_dias_factura
           
                  
end  --CURSOR
      
close cursor_div_vigente
deallocate cursor_div_vigente


--ACTUALIZAION TABLA DE AMORTIZACION
select @w_monto_prv = @w_valor_int_total
select @w_valor_sobra = 0 


select @w_amortizo = 'N'
if @w_valor_int_total > 0
begin
   declare 
   
     cursor_amortizacion cursor 
     
   for select   am_cuota,    
                am_acumulado,
                am_concepto, 
                am_dividendo 
   
   from ca_amortizacion,
        ca_rubro_op
   where am_operacion = @i_operacionca
   and   am_concepto = ro_concepto
   and   am_estado   = 3
   and   am_acumulado < am_cuota
   and   ro_operacion =  am_operacion
   and   ro_tipo_rubro = 'I'
   and   (@w_valor_int_total > 0 or  @w_valor_sobra > 0 )
   
   open    cursor_amortizacion
   
   fetch   cursor_amortizacion  
   
   into    @w_am_cuota,           
           @w_am_acumulado,       
           @w_am_concepto,        
           @w_am_dividendo       
   
--   while   @@fetch_status not in (-1,0)
   while   @@fetch_status = 0
   begin      
         
         select @w_amortizo = 'S'   
         select @w_dif = 0.0
         select @w_dif = @w_am_cuota - @w_am_acumulado

         
         select @w_am_acumulado = @w_am_acumulado + @w_valor_int_total + @w_valor_sobra
         if @w_am_acumulado <= @w_am_cuota
         begin
         
            update ca_amortizacion
            set    am_acumulado = @w_am_acumulado
            from ca_amortizacion
            where am_operacion =  @i_operacionca
            and   am_dividendo =  @w_am_dividendo
            and   am_concepto  =  @w_am_concepto
            
            select @w_valor_sobra = 0,
                   @w_valor_int_total = 0
         
            
         end
         ELSE
         begin
            
           select @w_valor_sobra = @w_valor_int_total -  @w_dif
         
            update ca_amortizacion
            set    am_acumulado = am_cuota
            from ca_amortizacion
            where am_operacion =  @i_operacionca
            and   am_dividendo =  @w_am_dividendo
            and   am_concepto  =  @w_am_concepto
            
            select @w_valor_int_total = 0


             if  @w_max_cuota = @w_am_dividendo 
                  select @w_monto_prv = @w_dif            
            
         end   
 
    
   
      fetch   cursor_amortizacion  
      
      into    @w_am_cuota,           
              @w_am_acumulado,       
              @w_am_concepto,        
              @w_am_dividendo       
              
               
   end  --CURSOR
         
   close cursor_amortizacion
   deallocate cursor_amortizacion
   
   
   ---TRANSACCION
   
    if @w_monto_prv <> 0  and @w_amortizo = 'S'
   begin 

 
   
          select @w_dtr_monto    = 0,
                 @w_dtr_monto_mn = 0

        
      select @w_dividendo = di_dividendo
      from ca_dividendo
      where di_operacion = @i_operacionca
      and   di_estado = 1
      
      select @w_monto_mn = round(@w_monto_prv * @i_cotizacion , @w_num_dec),
             @w_cot_mn   = @i_cotizacion
   
   
      select @w_secuencial = null
                   
      exec @w_error = sp_valida_existencia_prv
           @s_user              = @s_user,
           @s_term              = @s_term,
           @s_date              = @s_date,
           @s_ofi               = @s_ofi ,
           @i_en_linea          = 'N',
           @i_operacionca       = @i_operacionca,
           @i_fecha_proceso     = @w_op_fecha_ult_proceso,
           @i_tr_observacion    = 'AMORTIZACION INTERESES DOCUMETNOS DESCONTADOS',
           @i_gar_admisible     = @w_gar_admisible,
           @i_reestructuracion  = @w_reestructuracion,
           @i_calificacion      = @w_calificacion,
           @i_toperacion        = @w_toperacion,
           @i_moneda            = @w_moneda,
           @i_oficina           = @w_oficina,
           @i_banco             = @w_banco,
           @i_gerente           = @w_op_oficial,
           @i_moneda_uvr        = 2,
           @i_tipo              = 'D',
           @i_tran              = 'AMO',
           @o_secuencial        = @w_secuencial  out
   
      
      if @w_error != 0
         return @w_error
      
   
      select @w_codvalor = co_codigo * 1000 + @w_am_estado * 10 + 0
      from  ca_concepto
      where co_concepto    = @w_concepto_dd
      
      if @@rowcount = 0  
         return 710252
         
         
      	select @w_dtr_monto = dtr_monto,
      	       @w_dtr_monto_mn = dtr_monto_mn
         	from ca_det_trn
      	where dtr_secuencial = @w_secuencial
      	and   dtr_operacion  = @i_operacionca
      	and   dtr_codvalor   = @w_codvalor
      	and   dtr_dividendo  = @w_dividendo
      	and   dtr_concepto   = @w_concepto_dd
      	and   dtr_periodo    = @w_am_periodo
      	and   dtr_estado     = @w_am_estado
      	if @@rowcount = 0 
      	begin 
               
      	   insert into ca_det_trn (
      	   dtr_secuencial, dtr_operacion,    dtr_dividendo,
      	   dtr_concepto,
      	   dtr_estado,     dtr_periodo,      dtr_codvalor,
      	   dtr_monto,      dtr_monto_mn,     dtr_moneda,
      	   dtr_cotizacion, dtr_tcotizacion,  dtr_afectacion,
      	   dtr_cuenta,     dtr_beneficiario, dtr_monto_cont )
      	   values (
      	   @w_secuencial,  @i_operacionca,   @w_dividendo,
      	   @w_concepto_dd, 
      	   @w_am_estado,   @w_am_periodo,    @w_codvalor,
      	   @w_monto_prv,   @w_monto_mn,      @w_moneda,
      	   @w_cot_mn,      'N',              'D',
      	   '1',             '',               0 )
      	   if @@error != 0 
      	   return 708166
      
      	end
      	else 
      	begin 
         
            select @w_dtr_monto    = isnull(@w_dtr_monto, 0)    + @w_monto_prv,
                   @w_dtr_monto_mn = isnull(@w_dtr_monto_mn, 0) + @w_monto_mn
         
   
      	   update ca_det_trn set
      	   dtr_monto         = @w_dtr_monto,
      	   dtr_cotizacion    = @w_cot_mn,
      	   dtr_monto_mn      = @w_dtr_monto_mn
   
      	   where dtr_secuencial  = @w_secuencial
      	   and   dtr_operacion   = @i_operacionca
      	   and   dtr_codvalor    = @w_codvalor
      	   and   dtr_dividendo  = @w_dividendo
      	   and   dtr_concepto   = @w_concepto_dd
      	   and 	 dtr_periodo    = @w_am_periodo
      	   and   dtr_estado     = @w_am_estado
      
      	   if @@error != 0  
      	      return 708165
   
         end
   
         
   end  
   
end --si  de @w_valor_int_total


set rowcount 0

return 0

go
