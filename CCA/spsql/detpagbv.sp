/************************************************************************/
/*	Archivo: 		detpagbv.sp		 		*/
/*	Stored procedure: 	sp_detalle_pago_bv  			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Xavier Maldonado       			*/
/*	Fecha de escritura: 	Enero 2001				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Sp externo que valida los datos antes de ejecutar sp_interno    */
/*                                                                      */
/************************************************************************/  
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	18-Oct_2016	N.Vite		Migracion Cobis Cloud	                    */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_detalle_pago_bv')
	drop proc sp_detalle_pago_bv
go

create proc sp_detalle_pago_bv
        @s_user                         login        = null,
        @s_ofi                          smallint     = null,
        @s_date                         datetime     = null,
        @s_sesn		                int          = null,
        @s_ssn                          int          = null,
        @s_term                         varchar(30)  = null,
        @i_operacion                    char(1)      = null,
        @i_banco                        cuenta       = null,
        @i_fecha_ini	                datetime     = null,
        @i_fecha_fin			datetime     = null,
        @i_opcion			char(1)	     = null,
        @i_secuencial_ing		int	     = 0,
        @i_secuencial_pag		int	     = 0,
        @i_formato_fecha		tinyint	     = 101
as
declare	@w_sp_name                      descripcion,
       	@w_return 	                int,
	@w_producto			tinyint,
	@w_estado 			char(1),
	@w_op_operacion			int,
	@w_error			int,
	@w_msg			varchar(132)
	
/** INICIALIZAR VARIABLES **/
select	@w_sp_name = 'sp_detalle_pago_bv'


/** CONSULTA SI EL MODULO ESTA EN LINEA O EN BATCH **/
select @w_producto = pd_producto
from  cobis..cl_producto
where pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted

select @w_estado = pm_estado
from  cobis..cl_pro_moneda
where pm_producto = @w_producto
and   pm_moneda = 0
and   pm_tipo = 'R'
set transaction isolation level read uncommitted

/** DATOS CREDITO **/
/*******************/
select @w_op_operacion = op_operacion
from   ca_operacion
where  op_banco = @i_banco


/*EL MODULO ESTA EN LINEA*/
/*************************/
if @w_estado = 'V' begin
   if @i_opcion = 'Q' begin
      set rowcount 20
      select 
      'Fecha' = convert(varchar(10),ab_fecha_pag,@i_formato_fecha),   
      'Total Pagado' = abd_monto_mpg,
      'Forma de Pago' = abd_concepto,
      'Cuenta o Referencia' = abd_cuenta,
      'Sec_ing' = ab_secuencial_ing,
      'Sec_pag' = ab_secuencial_pag
      from ca_abono, ca_abono_det
      where ab_operacion = @w_op_operacion
      and   abd_operacion = @w_op_operacion
      and   ab_operacion = abd_operacion
      and   ab_secuencial_ing = abd_secuencial_ing
      and   ab_estado = 'A'
      and   ab_secuencial_ing > @i_secuencial_ing
      and   (ab_fecha_pag >= @i_fecha_ini or @i_fecha_ini is null)
      and   (ab_fecha_pag <= @i_fecha_fin or @i_fecha_fin is null)
      set rowcount 0
   end

   if @i_opcion = 'D' begin
      select 
      'Numero de Cuota' = dtr_dividendo,
      'Concepto' = dtr_concepto,
      'Valor pagado' = dtr_monto
      from  ca_det_trn
      where dtr_operacion = @w_op_operacion
      and   dtr_secuencial = @i_secuencial_pag
      and   dtr_dividendo != 0   
   end     
end


/*EL MODULO FUERA DE LINEA*/
/*************************/
if @w_estado != 'V' 
	begin
		select @w_error = 40004 --Producto bancario deshabilitado
		select @w_msg = 'Producto bancario deshabilitado'
		goto ERROR       
end

return 0

ERROR:
exec cobis..sp_cerror
	@t_debug  = 'N',    
	@t_file   =  null,
	@t_from   =  @w_sp_name,   
	@i_num    =  @w_error,
	@i_msg 	  = @w_msg
return @w_error    

go



