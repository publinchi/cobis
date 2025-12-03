/************************************************************************/
/*	Archivo: 		    valplazo.sp                                     */
/*	Stored procedure: 	sp_valida_plazo                                 */
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
/*	Este programa valida el plazo de una operacion de acuerdo al rango  */
/*  permitido en ca_default_toperacion                                  */
/************************************************************************/  
/*				MODIFICACIONES                                          */
/*	FECHA		AUTOR		RAZON                                       */
/*  18/Mar/2020 Luis Ponce  CDIG Ajustes migracion a Java               */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valida_plazo')
	drop proc sp_valida_plazo
go
create proc sp_valida_plazo  (
               @s_user         login 	= null, 
               @s_term         login 	= null,
               @s_date         datetime = null,
               @s_ofi          smallint = null,
               @i_operacion    char(1),
               @i_operacionca  cuenta,
               @i_moneda       tinyint,
               @i_toperacion   catalogo,
               @i_tplazo       catalogo,
               @i_plazo        int
)
as
declare @w_sp_name               varchar(30),
	    @w_operacionca           int,
        @w_banco                 cuenta,
        @w_toperacion            catalogo,
        @w_tipo_plazo_ori        catalogo,
        @w_plazo_op_ori          smallint,
        @w_tipo_plazo	         catalogo,
        @w_plazo_op              smallint,
        @w_dias_plazo            smallint,
        @w_plazo_en_meses        smallint,
        @w_plazo_en_meses_op     smallint,
        @w_dt_tplazo             catalogo,
        @w_dt_plazo_min          smallint,
        @w_dt_plazo_max          smallint,
        @w_plazo_en_meses_dt_min smallint,
        @w_plazo_en_meses_dt_max smallint,
        @w_error                 int

/*  Captura nombre del Stored Procedure  */
select @w_sp_name   = 'sp_valida_plazo'

/*  MANTIENE TIPO DE PLAZO Y PLAZO ORIGINAL ANTES DE VALIDACION, LOS QUE SE DEVUELVEN SI LA VALIDACION NO PASA  */
select @w_tipo_plazo_ori = @i_tplazo,
       @w_plazo_op_ori   = @i_plazo
                   
if @i_operacion ='U'
begin
    /*SELECCIONA LA OPERACION*/
    select  @w_banco             = opt_banco,
            @w_toperacion        = opt_toperacion,
            @w_tipo_plazo        = opt_tplazo,
            @w_plazo_op          = opt_plazo
    from ca_operacion_tmp
    where opt_operacion = @i_operacionca

    if @@rowcount = 0 --No existe la operacion
    begin
        select @w_error = 701049
        goto ERROR
    end
end

if @i_operacion ='I' or @i_operacion ='U'
begin
    if @i_toperacion is null
       select @i_toperacion = @w_toperacion

    /*CONVIERTE PLAZO DE LA OPERACION A MENSUAL */
    select @i_plazo  = isnull(@i_plazo, @w_plazo_op)
    select @i_tplazo = isnull(@i_tplazo, @w_tipo_plazo)
    
    select @w_dias_plazo = td_factor
    from   ca_tdividendo
    where  td_tdividendo = @i_tplazo

    select @w_plazo_en_meses_op = isnull((@i_plazo * @w_dias_plazo)/30,0)   

    /*OBTIENE RANGO PERMITIDO DE PLAZOS POR LINEA DE CREDITO */
    select  @w_dt_tplazo    = dt_tplazo,
            @w_dt_plazo_min = dt_plazo_min,
            @w_dt_plazo_max = dt_plazo_max
    from   ca_default_toperacion
    where  dt_toperacion = @i_toperacion and
           dt_moneda     = @i_moneda

    /*CONVIERTE PLAZO MINIMO DE LA LINEA DE CREDITO A MENSUAL */
    select @w_dias_plazo = td_factor
    from   ca_tdividendo
    where  td_tdividendo = @w_dt_tplazo
    select @w_plazo_en_meses_dt_min = isnull((@w_dt_plazo_min * @w_dias_plazo)/30,0)

    /*CONVIERTE PLAZO MAXIMO DE LA LINEA DE CREDITO A MENSUAL */
    select @w_dias_plazo = td_factor
    from   ca_tdividendo
    where  td_tdividendo = @w_dt_tplazo
    select @w_plazo_en_meses_dt_max = isnull((@w_dt_plazo_max * @w_dias_plazo)/30,0)

    /*VALIDA PLAZO DE LA OPERACION CONTRA RANGOS PERMITIDOS */
    if @w_plazo_en_meses_op >= @w_plazo_en_meses_dt_min and
       @w_plazo_en_meses_op <= @w_plazo_en_meses_dt_max
    begin
        select @w_error = 0
        return @w_error
    end
    else
    begin
        select @w_error = 701024
        select @i_tplazo = @w_tipo_plazo_ori, --LPO CDIG Ajustes por migracion a Java
               @i_plazo  = @w_plazo_op_ori    --LPO CDIG Ajustes por migracion a Java
        return @w_error
        --select @i_tplazo = @w_tipo_plazo_ori, --LPO CDIG Ajustes por migracion a Java
        --       @i_plazo  = @w_plazo_op_ori    --LPO CDIG Ajustes por migracion a Java
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
