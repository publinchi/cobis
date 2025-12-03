use cob_cartera
go

/************************************************************************************/
/*  Archivo:            saldocar.sp             			            */
/*  Stored procedure:   sp_saldo_cartera	                                    */
/*  Base de datos:      cob_cartera                     		            */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Luis Castellanos                                            */
/*  Fecha de creacion:  06/MAY/2020                                                 */
/************************************************************************************/
/*          IMPORTANTE                                                              */
/*  Este programa es propiedad de "COBISCORP". Ha sido desarrollado                 */
/*  bajo el ambiente operativo COBIS-sistema desarrollado por                       */
/*  "COBISCORP S.A."-Ecuador                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como                      */
/*  cualquier alteracion o agregado hecho por alguno de sus                         */
/*  usuarios sin el debido consentimiento por escrito de la                         */
/*  Gerencia General de COBISCORP o su representante.                               */
/************************************************************************************/
/*          PROPOSITO                                                               */
/*  Este procedimiento permite la ejecucion de los procedimientos almacenados para  */
/*  Consulta de Saldos de Cartera		                                    */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  11/MAY/2020       Luis Castellanos        Emision Inicial                       */
/************************************************************************************/


if exists (select 1 from sysobjects where name = 'sp_saldo_cartera')
  drop proc sp_saldo_cartera
go
create proc sp_saldo_cartera
        @s_user                 char(30) 	= null,
        @s_term                 char(30) 	= null,
        @s_ofi                  int 	 	= null,
        @i_operacion            char(1)  	= null,
        @i_operacionca          int      	= null,
        @i_banco                varchar(16)	= null,
        @i_formato_fecha        int    	 	= 101,
        @i_tipo_cobro           char(1)  	= 'P',
	@i_detalle_rubro	char(1)		= 'N',
	@o_msg_matriz           varchar(64) 	= NULL out 
as
declare @w_sp_name              varchar(32),
        @w_return               int,
        @w_error                int,
        @w_operacionca          int,
        @w_dividendo_vig        int,
        @w_fecha_ven            datetime,
        @w_di_fecha_ven         datetime,
        @w_concepto             catalogo,
        @w_vencido1             money,
        @w_vencido2             money,
        @w_vencido3             money,
        @w_vigente1             money,
        @w_vigente2             money,
        @w_vigente3             money,
        @w_porvencer1           money,
        @w_porvencer2           money,
        @w_porvencer3           money,
        @w_vencido_total        money,
        @w_vigente_total        money,
        @w_porvencer_total      money,
        @w_descripcion          varchar(25),
        @w_est_vigente          tinyint,
        @w_est_novigente        tinyint,
        @w_est_vencido          tinyint,
        @w_est_cancelado        tinyint,
        @w_rubro_asoc           catalogo,
        @w_desc_asoc            descripcion,
        @w_moneda_op            smallint,
        @w_num_dec_op           tinyint,
        @w_fecha_proceso        datetime,
	@w_tipo_cobro           char(1),
        @w_op_estado            tinyint,
        @w_di_fecha_ini         datetime,
        @w_op_dias_anio         smallint,
        @w_saldo_cap            money,
        @w_monto_precancelar    money,
        @w_tdividendo           smallint,
        @w_total		money,
	@w_monto_cuota		money
        

-- INICIALIZACION DE VARIABLES
select  @w_sp_name       = 'sp_saldo_cartera'

/* LECTURA DE LA OPERACION ACTIVA  */
/***********************************/
if @i_banco is null and @i_operacionca is null
begin
      select @o_msg_matriz = 'ERROR NO SE INDICA EL NUMERO DE PRESTAMO'
      return 725054 --'No existe la operación'
end

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_novigente  = @w_est_novigente out
   
if @w_error <> 0  return @w_error

-- INFORMACION DE OPERACION 
if @i_operacionca is not null and @i_banco is null
   select @i_banco = op_banco from cob_cartera..ca_operacion where op_operacion = @i_operacionca

select @w_operacionca   = op_operacion,      
       @w_fecha_ven     = op_fecha_fin,
       @w_moneda_op     = op_moneda,
       @w_fecha_proceso = op_fecha_ult_proceso,
       @w_op_estado     = op_estado,
       @w_tdividendo    = op_periodo_int*td_factor,
       @w_tipo_cobro    = isnull(@i_tipo_cobro,op_tipo_cobro)
  from ca_operacion, ca_tdividendo
 where op_banco      = @i_banco
   and td_tdividendo = op_tdividendo

if @@rowcount = 0 begin
   return 701025
end

-- INFORMACION DEL DIVIDENDO VIGENTE 
select
   @w_di_fecha_ven    = di_fecha_ven,
   @w_dividendo_vig   = di_dividendo,
   @w_di_fecha_ini    = di_fecha_ini
   from ca_dividendo
   where di_operacion = @w_operacionca
     and di_estado    = @w_est_vigente

if @@rowcount = 0 begin
   select 
   @w_di_fecha_ven     = @w_fecha_ven,
   @w_di_fecha_ini     = @w_fecha_ven
   
   select @w_dividendo_vig = max(di_dividendo)
   from ca_dividendo
   where di_operacion = @w_operacionca
end 


-- MANEJO DE DECIMALES 
exec @w_return    = sp_decimales
     @i_moneda    = @w_moneda_op,
     @o_decimales = @w_num_dec_op out
if @w_return != 0 begin
  return @w_return
end              

/* Consulta del saldo de los rubros de la operacion */
if @i_operacion = 'S' begin  

   
   CREATE TABLE #saldo_rubros(
   sr_concepto            catalogo,
   sr_descripcion         descripcion,
   sr_tipo_rubro          char(1),
   sr_prioridad           smallint,
   sr_monto_vencido       MONEY,
   sr_monto_vigente_a     MONEY,
   sr_monto_vigente_p     MONEY,
   sr_monto_por_vencer_a  MONEY,
   sr_monto_por_vencer_p  MONEY,
   sr_total_rubro_a       MONEY,
   sr_total_rubro_p       MONEY
   )
   
   
   INSERT INTO #saldo_rubros
   SELECT distinct am_concepto,
          co_descripcion,
          ro_tipo_rubro,
          ro_prioridad,
          0,
          0,
	  0,
	  0,
          0,
          0,
	  0
   from ca_amortizacion,
        ca_rubro_op,
        ca_concepto
   where  am_operacion = @w_operacionca
   and    ro_operacion = am_operacion
   and    am_concepto  = ro_concepto
   and    ro_concepto  = co_concepto

   update #saldo_rubros
   set sr_monto_vencido = isnull((select (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
                        from   ca_amortizacion, ca_dividendo
                        where  di_operacion  = am_operacion
                        and    di_dividendo  = am_dividendo
                        and    di_operacion  = @w_operacionca
                        and    di_estado     = @w_est_vencido
                        and    am_estado     <> @w_est_cancelado
                        and    am_concepto   = AM.am_concepto),0),

   sr_monto_vigente_p =  isnull((SELECT (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
                            from   ca_amortizacion, ca_dividendo
                            where  di_operacion         = am_operacion
                            and    di_dividendo         = am_dividendo
                            and    di_operacion         = @w_operacionca
                            and    di_estado            = @w_est_vigente
                            and    am_estado            <> @w_est_cancelado
                            and    am_concepto   = AM.am_concepto),0),
                         
   sr_monto_vigente_a =  isnull((SELECT (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                            from   ca_amortizacion, ca_dividendo
                            where  di_operacion         = am_operacion
                            and    di_dividendo         = am_dividendo
                            and    di_operacion         = @w_operacionca
                            and    di_estado            = @w_est_vigente
                            and    am_estado            <> @w_est_cancelado
                            and    am_concepto   = AM.am_concepto),0),
                           
   sr_monto_por_vencer_p = isnull((select (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
                          from   ca_amortizacion, ca_dividendo, ca_rubro_op
                          where  di_operacion = am_operacion
                          and    di_dividendo = am_dividendo
                          and    di_operacion = @w_operacionca
                          and    di_estado    = @w_est_novigente
                          and    am_estado   <> @w_est_cancelado
                          and    di_operacion = ro_operacion
                          and    am_operacion = ro_operacion
                          and    ro_concepto  = am_concepto
                          and    am_concepto   = AM.am_concepto),0),

   sr_monto_por_vencer_a = isnull((select (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                          from   ca_amortizacion, ca_dividendo, ca_rubro_op
                          where  di_operacion = am_operacion
                          and    di_dividendo = am_dividendo
                          and    di_operacion = @w_operacionca
                          and    di_estado    = @w_est_novigente
                          and    am_estado   <> @w_est_cancelado
                          and    di_operacion = ro_operacion
                          and    am_operacion = ro_operacion
                          and    ro_concepto  = am_concepto
                          and    am_concepto   = AM.am_concepto),0)

   from #saldo_rubros , ca_amortizacion AM 
   where AM.am_concepto = sr_concepto


   update #saldo_rubros
   set sr_total_rubro_p = sr_monto_vencido + sr_monto_vigente_p + sr_monto_por_vencer_p,
       sr_total_rubro_a = sr_monto_vencido + sr_monto_vigente_a + sr_monto_por_vencer_a
   from #saldo_rubros , ca_amortizacion AM 
   where AM.am_concepto = sr_concepto
   
   if @w_tipo_cobro = 'A'
      select @w_vencido_total   = sum(sr_monto_vencido), 
             @w_vigente_total   = sum(sr_monto_vigente_a), 
             @w_porvencer_total = sum(sr_monto_por_vencer_a), 
             @w_total 	        = sum(sr_monto_vencido+sr_monto_vigente_a+sr_monto_por_vencer_a),
             @w_monto_precancelar = sum(sr_monto_vencido+sr_monto_vigente_a+sr_monto_por_vencer_a),
	     @w_monto_cuota       = sum(sr_monto_vencido+sr_monto_vigente_p)
        from #saldo_rubros
   else
      select @w_vencido_total   = sum(sr_monto_vencido), 
             @w_vigente_total   = sum(sr_monto_vigente_p), 
             @w_porvencer_total = sum(sr_monto_por_vencer_p), 
             @w_total 	        = sum(sr_monto_vencido+sr_monto_vigente_p+sr_monto_por_vencer_p),
             @w_monto_precancelar = sum(sr_monto_vencido+sr_monto_vigente_a+sr_monto_por_vencer_a),
	     @w_monto_cuota       = sum(sr_monto_vencido+sr_monto_vigente_p)
        from #saldo_rubros


   select @w_saldo_cap  = sum(sr_monto_vencido+sr_monto_vigente_a+sr_monto_por_vencer_a)
     from #saldo_rubros
    where sr_tipo_rubro = 'C'

   if @i_detalle_rubro = 'S'
   begin

      if @w_tipo_cobro = 'A'
      SELECT    
      'ITEM'		= sr_concepto         ,
      'DESCRIPTION' 	= sr_descripcion      ,
      'PRIORITY'	= sr_prioridad        ,
      'AMOUNT DUE'	= sr_monto_vencido    ,
      'AMOUNT CURRENT'	= sr_monto_vigente_a    ,   
      'AMOUNT TO EXPIRE'= sr_monto_por_vencer_a ,
      'TOTAL'		= sr_total_rubro_a
      from #saldo_rubros
      else
      SELECT    
      'ITEM'		= sr_concepto         ,
      'DESCRIPTION' 	= sr_descripcion      ,
      'PRIORITY'	= sr_prioridad        ,
      'AMOUNT DUE'	= sr_monto_vencido    ,
      'AMOUNT CURRENT'	= sr_monto_vigente_p    ,   
      'AMOUNT TO EXPIRE'= sr_monto_por_vencer_p ,
      'TOTAL'		= sr_total_rubro_p
      from #saldo_rubros
   end

   SELECT 'AMOUNT DUE'  	= @w_vencido_total, 
	  'AMOUNT CURRENT'  	= @w_vigente_total, 
	  'AMOUNT TO EXPIRE' 	= @w_porvencer_total, 
	  'TOTAL'        	= @w_total, 
	  'PRINCIPAL BALANCE'   = @w_saldo_cap, 
	  'PREPAYMENT'		= @w_monto_precancelar, 
          'FEE'		        = @w_monto_cuota,
	  'PAYMENT DATE' 	= convert(varchar(10),@w_di_fecha_ven,@i_formato_fecha)   

end

go

/*
declare @o_msg varchar(64)

exec sp_api_loans_balances
        @s_user          = 'lcastell',
        @s_term          = 'termx',
        @s_ofi           = 1,
        @i_operacion     = 'S',
        @i_operacionca   = null,
        @i_banco         = '0001004043',
        @i_formato_fecha = 101,
        @i_tipo_cobro    = 'P',
	@i_detalle_rubro = 'S',
	@o_msg_matriz    = @o_msg out 

select @o_msg
*/
