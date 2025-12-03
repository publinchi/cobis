/************************************************************************/
/*	Archivo: 		    valmonto.sp                                     */
/*	Stored procedure: 	sp_valida_monto                                 */
/*	Base de datos:  	cob_cartera                                     */
/*	Producto: 		    Cartera                                         */
/*	Disenado por:  		Miguel Roa                                      */
/*	Fecha de escritura: 2008-04-09                                      */
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
/*	Este programa valida el monto de una operacion de acuerdo al rango  */
/*  permitido en ca_default_toperacion                                  */
/************************************************************************/  
/*				MODIFICACIONES                                          */
/*	FECHA		AUTOR		RAZON                                       */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valida_monto')
	drop proc sp_valida_monto
go
create proc sp_valida_monto  (
               @s_user         login 	= null, 
               @s_term         login 	= null,
               @s_date         datetime = null,
               @s_ofi          smallint = null,
               @i_operacion    char(1),
               @i_operacionca  cuenta,
               @i_moneda       tinyint,
               @i_toperacion   catalogo,
               @i_monto        money
)
as
declare @w_sp_name               varchar(30),
	    @w_operacionca           int,
        @w_banco                 cuenta,
        @w_toperacion            catalogo,
        @w_monto_ori             money,
        @w_monto                 money,
        @w_dt_monto_min          money,
        @w_dt_monto_max          money,
        @w_error                 int,
        @w_ref_grupal            int

/*  Captura nombre del Stored Procedure  */
select @w_sp_name   = 'sp_valida_monto'

/*  MANTIENE EL MONTO ORIGINAL DEL PRESTAMO ANTES DE VALIDACION, VALOR QUE SE DEVUELVE SI LA VALIDACION NO PASA  */
select @w_monto_ori = @i_monto

if @i_operacion ='I'
begin
     
     
    select @w_ref_grupal = op_ref_grupal
    from cob_cartera..ca_operacion
    where op_operacion = @i_operacionca AND op_grupal = 'S' 
    
	
    /*OBTIENE RANGO PERMITIDO DE MONTOS POR LINEA DE CREDITO */
    select  @w_dt_monto_min = dt_monto_min,
            @w_dt_monto_max = dt_monto_max
    from   ca_default_toperacion
    where  dt_toperacion = @i_toperacion and
           dt_moneda     = @i_moneda
    
    /*VALIDA MONTO DE LA OPERACION CONTRA RANGOS PERMITIDOS */
    IF @w_ref_grupal IS not null
	begin
	    if @i_monto >= @w_dt_monto_min and
	       @i_monto <= @w_dt_monto_max
	    begin
	        select @w_error = 0
	        return @w_error
	    end
	    else
	    begin
	        Select @w_error = 701027
	        return @w_error
	        select @i_monto = @w_monto_ori
	    end
    end
end
                   
if @i_operacion ='U'
begin
    /*SELECCIONA LA OPERACION  */
    select  @w_banco             = opt_banco,
            @w_toperacion        = isnull(@i_toperacion,opt_toperacion),
            @w_monto             = isnull(@w_monto_ori,opt_monto),
            @w_ref_grupal        = opt_ref_grupal
    from ca_operacion_tmp
    where opt_operacion = @i_operacionca

    if @@rowcount = 0 --No existe la operacion
    begin
        select @w_error = 701049
        goto ERROR
    end
    else
    begin
		if @w_ref_grupal is not null
		begin
	        if @i_toperacion is null
	          select @i_toperacion = @w_toperacion 
	            /*OBTIENE RANGO PERMITIDO DE MONTOS POR LINEA DE CREDITO */
	        select  @w_dt_monto_min = dt_monto_min,
	                @w_dt_monto_max = dt_monto_max
	        from   ca_default_toperacion
	        where  dt_toperacion = @i_toperacion and
	               dt_moneda     = @i_moneda
	
	        /*VALIDA MONTO DE LA OPERACION CONTRA RANGOS PERMITIDOS */
	        if @w_monto >= @w_dt_monto_min and
	           @w_monto <= @w_dt_monto_max
	        begin
	            select @w_error = 0
	            return @w_error
	        end
	        else
	        begin           
	            select @w_error = 701027
	            return @w_error
	            select @i_monto = @w_monto_ori
	        end
	      end
    end
end

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug  ='N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = @w_error,
        @i_sev    = 1
--        @i_cuenta = ' '
   return @w_error        
go
