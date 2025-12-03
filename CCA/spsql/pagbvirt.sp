/************************************************************************/
/*	Archivo: 		pagbvirt.sp		 		*/
/*	Stored procedure: 	sp_pago_banca_virtual  			*/
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

if exists (select 1 from sysobjects where name = 'sp_pago_banca_virtual')
	drop proc sp_pago_banca_virtual
go

create proc sp_pago_banca_virtual (
        @s_user                         login        = null,
        @s_ofi                          smallint     = null,
        @s_date                         datetime     = null,
        @s_sesn		                int          = null,
        @s_ssn                          int          = null,
        @s_term                         varchar(30)  = null,
        @i_operacion                    char(1)      = null,
        @i_banco                        cuenta       = null,
        @i_fecha_vig                    datetime     = null,
        @i_forma_pago                   varchar(10)  = null,   
        @i_cuenta_cliente               cuenta       = null,
        @i_aceptar_anticipos            char(1)      = null,
        @i_tipo_reduccion               char(1)      = null,    -- N:NORMAL T:REDUCCION TIEMPO C:REDUCCION CUOTA
        @i_monto                        money        = null
)
as
declare	@w_sp_name                      descripcion,
       	@w_return 	                int,
	@w_cliente                      int,
	@w_toperacion                   catalogo,
	@w_moneda                       tinyint,
        @w_producto                     tinyint,          
        @w_estado                       char(1),
        @w_error                        int,
        @w_op_operacionca               int,            
        @w_op_banco                     cuenta,
        @w_op_nombre                    descripcion,
	@w_op_moneda                    tinyint,
	@w_op_cuota_completa            char(1),
	@w_op_tipo_cobro                char(1), 
	@w_op_tipo_reduccion            char(1),
        @w_op_tipo_aplicacion           char(1),
	@w_op_aceptar_anticipos         char(1),
	@w_op_precancelacion            char(1),
        @w_prioridad                    tinyint,
        @w_contador                     tinyint,
        @w_prioridad_arreglo            varchar(20),
        @w_prioridad_arreglo2           varchar(20),
        @w_cotizacion                   float,
        @w_tasa_prepago                 float,
        @w_concepto                     varchar(10),
        @w_cantidad_pri                 smallint,
        @w_count                        smallint,
		@w_msg			                varchar(132)

/*  Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_pago_banca_virtual'

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

/*EL MODULO ESTA EN LINEA*/
/*************************/
if @w_estado = 'V' begin
   if @i_operacion = 'I' 
      select @w_op_operacionca  = op_operacion,
      @w_op_banco             = op_banco,
      @w_op_nombre            = op_nombre,
      @w_op_moneda            = op_moneda,
      @w_op_cuota_completa    = op_cuota_completa,
      @w_op_tipo_cobro        = op_tipo_cobro,
      @w_op_tipo_reduccion    = op_tipo_reduccion,
      @w_op_tipo_aplicacion   = op_tipo_aplicacion,
      @w_op_aceptar_anticipos = op_aceptar_anticipos,
      @w_op_precancelacion    = op_precancelacion
      from ca_operacion
      where op_banco = @i_banco                

      if @@rowcount = 0 begin
         select @w_error = 705068
         goto ERROR
      end

      if @i_aceptar_anticipos = 'S'
         select @w_op_tipo_reduccion = @i_tipo_reduccion,
         @w_count             = 0,
         @w_cantidad_pri      = 0                    
                 
      select @w_cantidad_pri = count(*)
      from ca_rubro_op
      where ro_operacion    = @w_op_operacionca
                 
      declare prioridad cursor for
      select ro_concepto,ro_prioridad
      from ca_rubro_op
      where ro_operacion    = @w_op_operacionca
      order by ro_concepto 
      for read only

      open prioridad

      fetch prioridad into  @w_concepto,@w_prioridad

      if (@@fetch_status != 0) begin
         close prioridad
	 return 710124
      end

      while (@@fetch_status = 0 ) begin 
         select @w_count = @w_count + 1  
         select @w_prioridad_arreglo = convert(varchar(10),@w_prioridad)  

         if @w_cantidad_pri <> @w_count 
            select @w_prioridad_arreglo2 = @w_prioridad_arreglo2 + convert(varchar(10),@w_prioridad_arreglo) + ';'     
         else
            select @w_prioridad_arreglo2 = @w_prioridad_arreglo2 + convert(varchar(10),@w_prioridad_arreglo) + '#'             

         fetch prioridad into @w_concepto,@w_prioridad
      end
      close prioridad
      deallocate prioridad

     /* COTIZACION*/
     /*************/
     select @w_cotizacion = 1

    /*TASA APLICADA */
    /****************/
    select @w_tasa_prepago = ro_porcentaje
    from ca_rubro_op
    where ro_operacion = @w_op_operacionca
    and ro_concepto    = 'INT'

    /*INSERCION DEL REGISTRO*/
    /************************/
    begin tran
    exec @w_return = sp_ing_detabono
    @s_user	       = @s_user,
    @s_date	       = @s_date,
    @s_sesn	       = @s_sesn,
    @t_trn             = 7059,
    @i_accion 	       = 'I',
    @i_encerar         = 'S',
    @i_tipo	       = 'PAG',
    @i_concepto        = @i_forma_pago,
    @i_cuenta 	       = @i_cuenta_cliente,
    @i_moneda 	       = @w_op_moneda,     
    @i_beneficiario    = @w_op_nombre,     
    @i_monto_mpg       = @i_monto,    
    @i_monto_mop       = @i_monto,    
    @i_monto_mn        = @i_monto, 
    @i_cotizacion_mpg  = @w_cotizacion,
    @i_cotizacion_mop  = @w_cotizacion,  
    @i_tcotizacion_mpg = 'COT',    
    @i_tcotizacion_mop = 'COT'  

    if @w_return != 0 begin
     select @w_error = @w_return
     goto ERROR
    end    

    exec @w_return = sp_ing_abono 
    @s_user		= @s_user,
    @s_term		= @s_term,
    @s_date		= @s_date,
    @s_sesn		= @s_sesn,
    @s_ssn		= @s_ssn,
    @s_ofi 		= @s_ofi,
    @t_trn              = 7058,
    @i_accion		= 'I',
    @i_banco		= @i_banco,
    @i_tipo 		= 'PAG',
    @i_fecha_vig	= @s_date, 
    @i_ejecutar		= 'S',     
    @i_retencion    	= 0,        
    @i_cuota_completa 	= @w_op_cuota_completa,   
    @i_anticipado    	= @i_aceptar_anticipos,   
    @i_tipo_reduccion	= @w_op_tipo_reduccion,   
    @i_proyectado     	= @w_op_tipo_cobro,       
    @i_tipo_aplicacion 	= @w_op_tipo_aplicacion,  
    @i_prioridades  	= @w_prioridad_arreglo2,
    @i_en_linea		= 'S',
    @i_tasa_prepago     = @w_tasa_prepago,
    @i_verifica_tasas   = 'S'             
   
    if @w_return != 0 begin
       select @w_error = @w_return
       goto ERROR
    end    

  commit tran
end


/*EL MODULO FUERA DE LINEA*/
/*************************/

if @w_estado != 'V' begin
   /*PAGO*/
   /*******************/
   if @i_operacion = 'I' begin   
      select @w_error = 40004 --NO EXISTE DATO SOLICITADO
	  select @w_msg = 'Producto bancario deshabilitado'
	  goto ERROR
   end
end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug  = 'N',    
@t_file   =  null,
@t_from   =  @w_sp_name,   
@i_num    =  @w_error,
@i_msg 	  =  @w_msg
return @w_error    

go



