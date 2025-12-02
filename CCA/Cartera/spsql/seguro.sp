/************************************************************************/
/*	Nombre Fisico: 			seguro.sp		 							*/
/*	Nombre Logico: 			sp_seguro               					*/
/*	Base de datos:  		cob_cartera									*/
/*	Producto: 				Cartera										*/
/*	Disenado por:  			Jorge Tellez C.     						*/
/*	Fecha de escritura: 	16 Feb 1999 								*/
/************************************************************************/
/*				IMPORTANTE												*/
/*   Este programa es parte de los paquetes bancarios que son       	*/
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
/*				PROPOSITO												*/
/*	Calculo del valor a cobrar por seguro                           	*/
/*				CAMBIOS													*/
/*	FEB-14-2002		RRB	      Agregar campos al insert					*/
/*					      en ca_transaccion								*/
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/  
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_seguro')
	drop proc sp_seguro
go
create proc sp_seguro (
   @s_ofi            smallint,
   @s_user           login,
   @s_term           varchar(30),
   @s_date           datetime, 
   @i_operacionca    int,
   @i_fecha_ult_pro  datetime,
   @i_moneda         smallint,
   @i_en_linea       char(1),
   @i_banco          cuenta,
   @i_oficina        smallint, 
   @i_toperacion     catalogo,
   @i_sector         catalogo,
   @i_cliente        int
)
as
declare	
   @w_sp_name        descripcion,
   @w_sum_total      float,
   @w_valor_seguro   float, 
   @w_div_vigent     int, 
   @w_concepto       catalogo,         
   @w_sector         catalogo,
   @w_tasa           float,
   @w_secuencial     int,
   @w_return         int,
   @w_codvalor       int,
   @w_est_vigente    int,
   @w_dtr_monto      money,
   @w_tr_estado      catalogo,
   @w_gerente        smallint,
   @w_gar_admisible	 char(1), ---RRB:feb-14-2002 para circular 50
   @w_reestructuracion	 char(1), ---RRB:feb-14-2002 para circular 50
   @w_calificacion	 catalogo  ---RRB:feb-14-2002 para circular 50

/*  INICIALIZACION DE VARIABLES */
select	
@w_sp_name = 'sp_seguro',
@w_est_vigente    = 1


select @w_gerente   = op_oficial,
@w_gar_admisible    = op_gar_admisible, 	---RRB:feb-14-2002 para circular 50
@w_reestructuracion = op_reestructuracion,	---RRB:feb-14-2002 para circular 50
@w_calificacion	    = op_calificacion 		---RRB:feb-14-2002 para circular 50
from ca_operacion
where op_operacion = @i_operacionca

/* TCERO  TASA CERO PARA PERSONAS JURIDICAS */
if exists (select 1 from cobis..cl_ente 
           where en_ente    = @i_cliente
           and   en_subtipo = 'C') --COMPANIA 
   return 0 
 
/* CALCULAR SALDO INSOLUTO DE LA DEUDA */
select
@w_sum_total = sum( am_cuota + am_gracia - am_pagado)
from ca_amortizacion
where am_operacion = @i_operacionca

/* SE BUSCA EL DIVIDENDO QUE ESTE EN ESTADO VIGENTE */
select @w_div_vigent = di_dividendo
from ca_dividendo 
where di_operacion = @i_operacionca      
and di_estado = @w_est_vigente                  -- ESTADO VIGENTE 

/* SI NO EXISTE DIVIDENDO VIGENTE, SE ACTUALIZA EL ULTIMO DIVIDENDO */
if @@rowcount = 0 begin

   select @w_div_vigent = max(di_dividendo)
   from ca_dividendo 
   where di_operacion = @i_operacionca      

end

/* PARA CONTABILIDAD */
/* VERIFICAR NECESIDAD DE CREAR NUEVA TRANSACCION */

select @w_secuencial = max(tr_secuencial)
from ca_transaccion
where tr_operacion = @i_operacionca

select @w_secuencial = isnull(@w_secuencial, 0)

select @w_tr_estado = tr_estado 
from ca_transaccion
where tr_secuencial = @w_secuencial
and   tr_tran = 'PRV'
and   tr_estado in ('CON','ING')

if @@rowcount = 0 begin

   exec @w_secuencial = sp_gen_sec
        @i_operacion  = @i_operacionca

   /* OBTENER RESPALDO EN QUIEBRE DE CAUSACION */
   exec @w_return  = sp_historial
   @i_operacionca  = @i_operacionca,
   @i_secuencial   = @w_secuencial

   if @w_return <> 0 return @w_return

   /* SE INGRESA EL MAESTRO DE LA TRANSACCION MONETARIA */   
   insert into ca_transaccion (
   tr_secuencial,     tr_fecha_mov,  tr_toperacion,
   tr_moneda,         tr_operacion,  tr_tran,
   tr_en_linea,       tr_banco,      tr_dias_calc,
   tr_ofi_oper,       tr_ofi_usu,    tr_usuario,
   tr_terminal,       tr_fecha_ref,  tr_secuencial_ref,
   tr_estado,	      tr_gerente ,   tr_gar_admisible,	---RRB:feb-14-2002 para circular 50
   tr_reestructuracion , 	     tr_calificacion, 	---RRB:feb-14-2002 para circular 50
   tr_observacion,    tr_fecha_cont,       tr_comprobante)
   values (
   @w_secuencial,     @s_date,              @i_toperacion,   
   @i_moneda,         @i_operacionca,       'PRV',
   @i_en_linea,       @i_banco,             0,
   @i_oficina,        @s_ofi,               @s_user,
   @s_term,           @i_fecha_ult_pro,     0,
   'ING',             @w_gerente ,	    isnull(@w_gar_admisible,''),	---RRB:feb-14-2002 para circular 50
   isnull(@w_reestructuracion,''),	    isnull(@w_calificacion,''),	---RRB:feb-14-2002 para circular 50   
   '',			@s_date,	    0)

   if @@error != 0 begin
      PRINT 'seguro.sp error 1'
      return 708165  
   end

   select @w_tr_estado = 'ING'
end


/* RUBROS TIPO SEGURO */
declare rubros cursor for 
select ro_concepto  
from ca_rubro_op 
where ro_operacion = @i_operacionca
and ro_principal = 'S'       -- SI ES CAMPO SEGURO 
for read only

open rubros 

fetch rubros into @w_concepto 

while @@fetch_status = 0
Begin
   /* TRAE EL VALOR DE LA TASA */
   exec @w_return = sp_consulta_tasas 
   @i_operacionca = @i_operacionca,
   @i_dividendo	  = @w_div_vigent,
   @i_concepto	  = @w_concepto,
   @i_sector      = @i_sector, 
   @i_fecha	  = @i_fecha_ult_pro,
   @o_tasa	  = @w_tasa out

   if @w_return <> 0 return @w_return

   select @w_tasa = isnull( @w_tasa, 0 ) 
   /* CALCULO DEL VALOR A COBRAR DE SEGURO */ 
   select @w_valor_seguro = @w_sum_total * @w_tasa / 100

   if @w_valor_seguro = 0 Begin
      fetch rubros into @w_concepto 
      continue
   end     

   /* ACTUALIZA EL VALOR A CANCELAR POR CONCEPTO DE SEGURO */
   update ca_amortizacion set 
   am_cuota     = am_cuota     + @w_valor_seguro,
   am_acumulado = am_acumulado + @w_valor_seguro
   where am_operacion = @i_operacionca      
   and am_concepto  = @w_concepto
   and am_dividendo = @w_div_vigent 

   /* ASIGNACION DEL CODIGO CONCEPTO */
   select @w_codvalor = co_codigo * 1000 
   from ca_concepto 
   where co_concepto = @w_concepto 

   select @w_dtr_monto = dtr_monto 
   from ca_det_trn
   where dtr_secuencial = @w_secuencial
   and   dtr_operacion  = @i_operacionca
   and   dtr_codvalor   = @w_codvalor 

   if @@rowcount = 0 begin

      /*ASIGNACION DE DETALLE DE LA TRANSACCION MONETARIA */ 
      insert into ca_det_trn (
      dtr_secuencial, dtr_operacion,    dtr_dividendo, 
      dtr_concepto,
      dtr_estado,     dtr_periodo,      dtr_codvalor,
      dtr_monto,      dtr_monto_mn,     dtr_moneda,
      dtr_cotizacion, dtr_tcotizacion,  dtr_afectacion,
      dtr_cuenta,     dtr_beneficiario, dtr_monto_cont )
      values (
      @w_secuencial,   @i_operacionca,   @w_div_vigent,
      @w_concepto,
      0,               0,                @w_codvalor,
      @w_valor_seguro, 0,                @i_moneda,
      0,               'N',              'D', 
      "",              '',               0 )  

      if @@error != 0 return 708166   

   end else begin

      if @w_tr_estado = 'CON' select @w_dtr_monto = @w_valor_seguro
      else  select @w_dtr_monto = @w_dtr_monto + @w_valor_seguro

      update ca_det_trn set
      dtr_monto         = @w_dtr_monto,
      dtr_cotizacion    = 0,
      dtr_monto_mn      = 0
      where dtr_secuencial  = @w_secuencial
      and   dtr_operacion   = @i_operacionca
      and   dtr_codvalor    = @w_codvalor 

      if @@error != 0 begin
      PRINT 'seguro.sp error 2'
         return 708165
      end

   end

   fetch rubros into @w_concepto 

end 
close rubros
deallocate rubros
return 0

go     

