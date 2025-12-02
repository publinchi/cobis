/************************************************************************/
/*	Archivo:		    defa_top.sp                                     */
/*	Stored procedure:	sp_default_toperacion                           */
/*	Base de datos:		cob_cartera                                     */
/*	Producto: 		    Credito y Cartera                               */
/*	Disenado por:  		F.Espinosa                                      */
/*	Fecha de escritura:	04/03/1995                                      */
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
/*	Este programa procesa los defaults por tipo de operacion            */
/*	I: Insercion de default por tipo de operacion                       */
/*	U: Actualizacion de default por tipo de operacion                   */
/*	Q: Consulta de default por tipo de operacion                        */
/************************************************************************/
/*				MODIFICACIONES                                          */
/*	FECHA		AUTOR		RAZON                                       */
/*	03/04/1995	Fabian Espinosa	Emision inicial                         */
/*  Abr-10-2008 MRoa  Adicion dt_tipo_calif, plazos minimo y maximo     */
/*                    clase de sector                                   */
/*  Ene-11-2017 DFu   Adicion opcion para consultar tipos de operaciones*/
/*                    para renovaciones (operacion R)                   */
/*  May-08-2019 AGi   Adicion dt_admin_individual para grupales         */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_default_toperacion')
	drop proc sp_default_toperacion
go


create proc sp_default_toperacion ( 
    @s_user                 login       = null,
    @s_date                 datetime    = null,
    @s_ofi                  smallint    = null,
    @s_term                 varchar(30) = null, 
	@t_debug                char(1) 	='N',
	@t_file                 varchar(14) = null,
	@t_from	                descripcion = null,
	@i_operacion            char(2)         , 
	@i_toperacion           catalogo 	= null,
	@i_moneda               tinyint 	= null,
	@i_reajustable          char(1) 	= null,
	@i_periodo_reaj         smallint 	= null,
	@i_reajuste_especial    char(1) 	= null,
	@i_renovacion           char(1) 	= null,
	@i_tipo                 char(1) 	= null,
	@i_estado               catalogo	= null,
	@i_precancelacion       char(1) 	= null,
	@i_cuota_completa       char(1) 	= null,
	@i_tipo_cobro           char(1) 	= null,
	@i_tipo_reduccion       char(1) 	= null,
	@i_aceptar_anticipos	char (1) 	= null,
    @i_tipo_aplicacion      char(1)		= null,
	@i_tplazo               catalogo 	= null,
	@i_plazo                smallint 	= null,
	@i_tdividendo           catalogo 	= null,
	@i_periodo_cap          smallint 	= null,
	@i_periodo_int          smallint 	= null,
	@i_gracia_cap           smallint 	= null,
	@i_gracia_int           smallint 	= null,
	@i_dist_gracia          char(1) 	= null,
	@i_dias_anio            smallint 	= null,
	@i_tipo_amortizacion	varchar(10) = null,
	@i_fecha_fija           char(1) 	= null,
	@i_dia_pago             tinyint 	= null,
	@i_cuota_fija           char(1) 	= null,
	@i_dias_gracia          tinyint 	= null,
    @i_evitar_feriados      char(1)     = null,
    @i_mes_gracia           tinyint     = null,
    @i_base_calculo         char(1)     = 'R', 
    @i_prd_cobis            tinyint     = 7,
    @i_ult_dia_habil        char(1)     = 'N', 
    @i_recalcular           char(1)     = 'N' ,
    @i_codigo               catalogo    = null, --dt_usar_tequivalente
	@i_tipo_redondeo        tinyint		= null,
    @i_causacion            char(1)		= 'L',
    @i_convierte_tasa       char(1)		= 'S',   
    @i_tipo_linea 	    	char(10)	= 'PRO',  
    @i_subtipo_linea    	char(10)	=  null,  
    @i_bvirtual 	    	char(1)		= 'S',  
    @i_extracto             char(1)		= 'S',  
	@i_naturaleza           char(1)     = 'A',
	@i_pago_caja            char(1)		= 'S',
	@i_nace_vencida         char(1)		= 'N',
	@i_calcula_devolucion	char(1)		= 'N',
	@i_categoria            catalogo	= null,
	@i_entidad_convenio	    catalogo	= null,
    @i_mora_retroactiva     char(1)     = null,
    @i_prepago_desde_lavigente     char(1)  = null,
    @i_dias_anio_mora       smallint    = null,
    @i_tipo_calif           catalogo    = null,
    @i_plazo_min            smallint    = null,
    @i_plazo_max            smallint    = null,
    @i_monto_min            money       = null,
    @i_monto_max            money       = null,
    @i_clase_sector         catalogo    = null,
    @i_clase_cartera        catalogo    = null,
    @i_gar_admisible        char(1)     = null,
    @i_afecta_cupo          char(1)     = null,
    @i_control_dia_pago     char(1)     = null,
    @i_porcen_colateral     float       = null,
    @i_admin_individual     char(1)     = 'S'
)
as
declare
    @w_sp_name		    descripcion,
	@w_return		    int,
	@w_toperacion	    catalogo,
	@w_moneda		    tinyint,
	@w_reajustable	    char(1),
	@w_periodo_reaj		smallint,
	@w_reajuste_especial	char(1),
	@w_renovacion		char(1),
	@w_precancelacion	char(1),
	@w_tipo			    char(1),
	@w_desc_tipo		descripcion,
	@w_estado		    catalogo,
	@w_cuota_completa	char(1),
	@w_tipo_cobro	    char(1),
	@w_tipo_reduccion	char(1),
	@w_aceptar_anticipos	char (1),
	@w_dias_anio		smallint,
	@w_tipo_amortizacion	varchar(10),
	@w_fecha_fija		char(1),
	@w_cuota_fija		char(1),
	@w_dias_gracia		tinyint,
	@w_dia_pago		    tinyint,
	@w_tplazo		    catalogo,
	@w_desc_tplazo		descripcion,
	@w_plazo		    smallint,
	@w_tdividendo		catalogo,
	@w_desc_tdiv		descripcion,
	@w_periodo_cap		smallint,
	@w_periodo_int		smallint,
	@w_gracia_cap		smallint,
	@w_gracia_int		smallint,
	@w_dist_gracia	    char(1),
 	@w_desc_estado		descripcion,
	@w_descripcion		descripcion,
	@w_valor_referencial 	float,
	@w_valor_total 		float, 
	@w_signo		    char(1),
	@w_factor		    float,
	@w_clase		    char(1),
	@w_tasa_refe		catalogo,
    @w_evitar_feriados  char(1),  
    @w_tipo_aplicacion  char(1),  
    @w_mes_gracia       tinyint,  
    @w_error            int,
    @w_clave1           varchar(255),
    @w_clave2           varchar(255),
    @w_max_dia_grac     int,    
    @w_base_calculo     char(1),
    @w_ult_dia_habil    char(1),
    @w_recalcular       char(1),
    @w_prd_cobis        tinyint,
    @w_des_prd_cobis    descripcion,
	@w_tipo_redondeo	tinyint,
    @w_causacion        char(1),
    @w_convertir_tasa   char(1),
    @w_tipo_linea       char(10),
    @w_tipo_desc        char(40),
    @w_subtipo_linea    char(10),
    @w_subtipo_desc     char(40),
    @w_bvirtual         char(1),
    @w_extracto         char(1),
	@w_naturaleza		char(1),
	@w_pago_caja		char(1), 
	@w_nace_vencida		char(1),
	@w_calcula_devolucion	char(1), 
	@w_categoria		    catalogo,
	@w_categoria_desc	    char(40),
	@w_descripcion_top	    descripcion,
    @w_entidad_convenio     catalogo,
    @w_desc_entidad_convenio descripcion,
    @w_mora_retroactiva     char(1),
    @w_prepago_desde_lavigente char(1),
    @w_cod_entidad          catalogo,
    @w_dias_anio_mora       smallint,
    @w_tipo_calif           catalogo,
    @w_des_tipo_calif       descripcion,
    @w_plazo_min            smallint,
    @w_plazo_max            smallint, 
    @w_monto_min            money, 
    @w_monto_max            money,
    @w_clase_sector         catalogo,
    @w_desc_clase_sector    descripcion,
    @w_clase_cartera        catalogo,
    @w_desc_clase_cartera   descripcion,
    @w_gar_admisible        char(1),
    @w_afecta_cupo          char(1),
    @w_control_dia_pago     char(1),
    @w_porcen_colateral     float,
    @w_admin_individual     char(1)


/*  Inicializar nombre del stored procedure  */
select	@w_sp_name = 'sp_default_toperacion'


if @i_operacion = 'U' begin
   if exists (select 1 from ca_default_toperacion 
	      where dt_toperacion = @i_toperacion
	      and   dt_moneda     = @i_moneda)
      select @i_operacion = 'U'
   else
      select @i_operacion = 'I'
end


-- CONSULTA CODIGO DE FINAGRO EN PARAMETRO GENERAL
select  @w_cod_entidad = pa_char
from    cobis..cl_parametro
where   pa_nemonico = 'FINAG'
and     pa_producto = 'CCA'
set transaction isolation level read uncommitted

if @i_prepago_desde_lavigente = 'S' and (@i_tipo <> 'R' or @i_tipo_linea <> @w_cod_entidad)
begin
   select @w_error = 710463
   goto ERROR
end
   
/* ** Insert ** */
if @i_operacion = 'I' begin

   /* AUMENTO 03/02/1999 */ 
   select @w_max_dia_grac = pa_int 
   from cobis..cl_parametro 
   where pa_producto = 'CCA' 
   and  pa_nemonico = 'MDG'
   set transaction isolation level read uncommitted

   if @w_max_dia_grac < @i_dias_gracia begin
      select @w_error = 701180
      goto ERROR
   end


   begin tran

   /* verificar que exista el tipo de operacion */
   exec @w_return = cobis..sp_catalogo
   @t_debug       = @t_debug,
   @t_file        = @t_file,
   @t_from        = @w_sp_name,
   @i_tabla       = 'ca_toperacion',
   @i_operacion   = 'E',
   @i_codigo      = @i_toperacion
   
   /* si no existe, error */
   if @w_return != 0 begin
      select @w_error = 101000
      goto ERROR
   end

   /* verificar que exista la moneda */
   if not exists(select 1 from cobis..cl_moneda
                 where mo_moneda = @i_moneda) begin
      select @w_error = 101045
      goto ERROR
   end
 
   if (@i_tipo = 'O' and  (@i_tipo_cobro <> 'A' or @i_tipo_reduccion <> 'N') 
      and @i_aceptar_anticipos = 'S')
      or (@i_tipo = 'O' and (@i_tipo_cobro <> 'A' or @i_tipo_reduccion <> ' ') 
      and @i_aceptar_anticipos = 'N') begin
      select @w_error = 710096
      goto ERROR
   end 
		
   /*CONTROL DE RUBROS REAJUSTABLES SI LA OPERACION ES REAJUSTABLE*/
   /*AUMENTADO 01/01/98*/
   if exists(select 1 from ca_rubro
             where ru_toperacion = @i_toperacion
             and  ru_moneda      = @i_moneda
             and  ru_tipo_rubro in ('I')
             and  ru_reajuste is null) begin
      if @i_reajustable = 'S' begin
         select @w_error = 710122
         goto ERROR
      end
   end
   /* insertar los parametros de entrada */

   /* VALIDAR PLAZO MINIMO Y PLAZO MAXIMO */
   if @i_plazo_min > @i_plazo_max begin
         select @w_error = 701188
         goto ERROR
      end

   insert into ca_default_toperacion (
   dt_toperacion,              dt_moneda,               dt_reajustable,
   dt_periodo_reaj,            dt_reajuste_especial,    dt_renovacion, 
   dt_precancelacion,          dt_tipo,                 dt_estado,
   dt_cuota_completa,          dt_tipo_cobro,           dt_tipo_reduccion,
   dt_aceptar_anticipos,       dt_tplazo,               dt_plazo,
   dt_tdividendo,              dt_periodo_cap,          dt_periodo_int, 
   dt_gracia_cap,              dt_gracia_int,           dt_dist_gracia, 
   dt_dias_anio,               dt_tipo_amortizacion,    dt_fecha_fija,
   dt_cuota_fija,              dt_dias_gracia,          dt_dia_pago,
   dt_evitar_feriados,         dt_tipo_aplicacion,      dt_mes_gracia,
   dt_base_calculo,            dt_dia_habil,            dt_recalcular_plazo,
   dt_prd_cobis,               dt_tipo_redondeo,        dt_causacion,
   dt_convertir_tasa,          dt_tipo_linea,           dt_subtipo_linea, 
   dt_bvirtual,                dt_extracto, 		    dt_naturaleza,
   dt_pago_caja, 	           dt_nace_vencida,	        dt_calcula_devolucion,  
   dt_categoria,               dt_entidad_convenio,     dt_mora_retroactiva,
   dt_prepago_desde_lavigente, dt_dias_anio_mora,       dt_tipo_calif,
   dt_plazo_min,               dt_plazo_max,            dt_monto_min,
   dt_monto_max,               dt_clase_sector,         dt_clase_cartera,
   dt_gar_admisible,           dt_afecta_cupo,          dt_control_dia_pago,
   dt_porcen_colateral,        dt_admin_individual
   )
   values  (
   @i_toperacion,               @i_moneda,               @i_reajustable, 
   @i_periodo_reaj,             @i_reajuste_especial,    @i_renovacion,
   @i_precancelacion,           @i_tipo,                 @i_estado,
   @i_cuota_completa,           @i_tipo_cobro,           @i_tipo_reduccion, 
   @i_aceptar_anticipos,        @i_tplazo,               @i_plazo, 
   @i_tdividendo,               @i_periodo_cap,          @i_periodo_int, 
   @i_gracia_cap,               @i_gracia_int,           @i_dist_gracia, 
   @i_dias_anio,                @i_tipo_amortizacion,    @i_fecha_fija,          
   @i_cuota_fija,               @i_dias_gracia,          isnull(@i_dia_pago,0),
   @i_evitar_feriados,          @i_tipo_aplicacion,      @i_mes_gracia,
   @i_base_calculo,             @i_ult_dia_habil,        @i_recalcular , 
   @i_prd_cobis,                @i_tipo_redondeo,	     @i_causacion,
   @i_convierte_tasa,           @i_tipo_linea,           @i_subtipo_linea,
   @i_bvirtual,                 @i_extracto, 	  	     @i_naturaleza,
   @i_pago_caja, 	            @i_nace_vencida,	     @i_calcula_devolucion, 
   @i_categoria,                @i_entidad_convenio,     @i_mora_retroactiva,
   @i_prepago_desde_lavigente,  @i_dias_anio_mora,       @i_tipo_calif,
   @i_plazo_min,                @i_plazo_max,            @i_monto_min,
   @i_monto_max,                @i_clase_sector,         @i_clase_cartera,
   @i_gar_admisible,            @i_afecta_cupo,          @i_control_dia_pago,
   @i_porcen_colateral,         @i_admin_individual
   )


   /* si no se pudo insertar, error */
   if @@error != 0 begin
      select @w_error = 703067 
      goto ERROR
   end

   select @w_clave1 = convert(varchar(255),@i_toperacion)
   select @w_clave2 = convert(varchar(255),@i_moneda)

   exec @w_return = sp_tran_servicio
   @s_user    = @s_user,
   @s_date    = @s_date,
   @s_ofi     = @s_ofi,
   @s_term    = @s_term,
   @i_tabla   = 'ca_default_toperacion',
   @i_clave1  = @w_clave1,
   @i_clave2  = @w_clave2

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

   --MPO Ref. 016 06/02/2002
   /*ACTUALIZAR LA TABLA DE CREDITO */
   select @w_descripcion_top = c.valor
   from   cobis..cl_tabla t, cobis..cl_catalogo c
   where  t.tabla = 'ca_toperacion'
   and    t.codigo = c.tabla
   and    c.codigo = @i_toperacion
   set transaction isolation level read uncommitted

   
/* REVISAR CON PABLO   insert cob_credito..	cr_toperacion
   (to_toperacion, to_producto, to_descripcion, to_estado)
   values
   (@i_toperacion, 'CCA',	@w_descripcion_top, 'V')

   if @@error != 0 begin
      PRINT 'defa_top.sp error insertando en tabla cr_toperacion'
      select @w_error = 705041
      goto ERROR
   end
*/
   
   commit tran

end


/* ** Update ** */
if @i_operacion = 'U' begin
   select @w_max_dia_grac = pa_int 
   from cobis..cl_parametro 
   where pa_producto = 'CCA' 
   and  pa_nemonico = 'MDG'
   set transaction isolation level read uncommitted


   if @w_max_dia_grac < @i_dias_gracia begin
      select @w_error = 701180
      goto ERROR
   end 
      
   /* seleccionar los datos anteriores */
   select
   @w_toperacion		= dt_toperacion,	
   @w_moneda		    = dt_moneda,
   @w_reajustable		= dt_reajustable,
   @w_periodo_reaj		= dt_periodo_reaj,
   @w_reajuste_especial	= dt_reajuste_especial,
   @w_renovacion		= dt_renovacion,
   @w_precancelacion 	= dt_precancelacion,
   @w_tipo		        = dt_tipo,
   @w_estado		    = dt_estado,
   @w_cuota_completa 	= dt_cuota_completa,
   @w_tipo_cobro 	    = dt_tipo_cobro,
   @w_tipo_reduccion 	= dt_tipo_reduccion,
   @w_aceptar_anticipos = dt_aceptar_anticipos,
   @w_dias_anio 		= dt_dias_anio,
   @w_tipo_amortizacion = dt_tipo_amortizacion,
   @w_fecha_fija 		= dt_fecha_fija,
   @w_cuota_fija 		= dt_cuota_fija,
   @w_dias_gracia 		= dt_dias_gracia,
   @w_dia_pago 	        = dt_dia_pago,
   @w_tplazo 		    = dt_tplazo,
   @w_plazo 		    = dt_plazo,
   @w_tdividendo 		= dt_tdividendo,
   @w_periodo_cap 		= dt_periodo_cap,
   @w_periodo_int 		= dt_periodo_int,
   @w_dist_gracia 	    = dt_dist_gracia,
   @w_base_calculo 	    = dt_base_calculo,
   @w_ult_dia_habil 	= dt_dia_habil,
   @w_recalcular 	    = dt_recalcular_plazo , 
   @w_prd_cobis         = dt_prd_cobis,       
   @w_tipo_redondeo		= dt_tipo_redondeo,   
   @w_causacion         = dt_causacion,       
   @w_convertir_tasa    = dt_convertir_tasa,
   @w_tipo_linea        = dt_tipo_linea,
   @w_subtipo_linea     = dt_subtipo_linea,
   @w_bvirtual          = dt_bvirtual,
   @w_extracto          = dt_extracto,
   @w_naturaleza		= dt_naturaleza,
   @w_pago_caja			= dt_pago_caja,
   @w_nace_vencida		= dt_nace_vencida,
   @w_calcula_devolucion	   = dt_calcula_devolucion, 
   @w_categoria			       = dt_categoria,
   @w_entidad_convenio         = dt_entidad_convenio,
   @w_mora_retroactiva         = dt_mora_retroactiva,
   @w_prepago_desde_lavigente  = dt_prepago_desde_lavigente,
   @w_dias_anio_mora           = dt_dias_anio_mora,
   @w_tipo_calif               = dt_tipo_calif,
   @w_plazo_min                = dt_plazo_min,
   @w_plazo_max                = dt_plazo_max,
   @w_monto_min                = dt_monto_min,
   @w_monto_max                = dt_monto_max,
   @w_clase_sector             = dt_clase_sector,
   @w_clase_cartera            = dt_clase_cartera,
   @w_gar_admisible            = dt_gar_admisible,
   @w_afecta_cupo              = dt_afecta_cupo,
   @w_control_dia_pago         = dt_control_dia_pago,
   @w_porcen_colateral         = dt_porcen_colateral,
   @w_admin_individual         = dt_admin_individual
   from	ca_default_toperacion
   where   dt_toperacion = @i_toperacion
   and     dt_moneda     = @i_moneda

   /* si no existen datos anteriores, error */
   if @@rowcount = 0 begin
      select @w_error = 701110
      goto ERROR
   end

   if (@i_tipo = 'O' and  (@i_tipo_cobro <> 'A' or @i_tipo_reduccion <> 'N') 
      and @i_aceptar_anticipos = 'S')
      or (@i_tipo = 'O' and (@i_tipo_cobro <> 'A' or @i_tipo_reduccion <> ' ') 
      and @i_aceptar_anticipos = 'N') begin                                        
      select @w_error = 710096                  
      goto ERROR                                
   end                                          

   /*AUMENTADO 01/01/98*/
   /*CONTROL DE RUBROS REAJUSTABLES SI LA OPERACION ES REAJUSTABLE*/
   if exists(select 1 from ca_rubro
             where ru_toperacion = @i_toperacion
             and  ru_moneda      = @i_moneda
             and  ru_tipo_rubro in ('I')
             and  ru_reajuste is null) begin
      if @i_reajustable = 'S'  begin
         select @w_error = 710122
         goto ERROR
      end
   end



   begin tran

   select @w_clave1 = convert(varchar(255),@i_toperacion)
   select @w_clave2 = convert(varchar(255),@i_moneda)


   exec @w_return = sp_tran_servicio
   @s_user    = @s_user,
   @s_date    = @s_date,
   @s_ofi     = @s_ofi,
   @s_term    = @s_term,
   @i_tabla   = 'ca_default_toperacion',
   @i_clave1  = @w_clave1,
   @i_clave2  = @w_clave2

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end           

   /* VALIDAR PLAZO MINIMO Y PLAZO MAXIMO */
   if @i_plazo_min > @i_plazo_max begin
         select @w_error = 701188
         goto ERROR
      end

   update ca_default_toperacion set

   dt_toperacion            = @i_toperacion,	
   dt_moneda		        = @i_moneda,
   dt_reajustable		    = @i_reajustable,
   dt_periodo_reaj		    = @i_periodo_reaj,
   dt_reajuste_especial	    = @i_reajuste_especial,
   dt_renovacion		    = @i_renovacion,
   dt_precancelacion 	    = @i_precancelacion,
   dt_tipo		            = @i_tipo,
   dt_estado		        = @i_estado,
   dt_cuota_completa 	    = @i_cuota_completa,
   dt_tipo_cobro 	        = @i_tipo_cobro,
   dt_tipo_reduccion 		= @i_tipo_reduccion,
   dt_aceptar_anticipos 	= @i_aceptar_anticipos,
   dt_dias_anio 		    = @i_dias_anio,
   dt_tipo_amortizacion 	= @i_tipo_amortizacion,
   dt_fecha_fija 		    = @i_fecha_fija,
   dt_cuota_fija 		    = @i_cuota_fija,
   dt_dias_gracia 		    = @i_dias_gracia,
   dt_dia_pago 		        = isnull(@i_dia_pago,0),
   dt_tplazo 	 	        = @i_tplazo,
   dt_plazo 		        = @i_plazo,
   dt_tdividendo 		    = @i_tdividendo,
   dt_periodo_cap 	    	= @i_periodo_cap,
   dt_periodo_int 		    = @i_periodo_int,
   dt_gracia_cap 	    	= @i_gracia_cap,
   dt_gracia_int 		    = @i_gracia_int,
   dt_dist_gracia 	        = @i_dist_gracia,
   dt_evitar_feriados       = @i_evitar_feriados,
   dt_tipo_aplicacion       = @i_tipo_aplicacion, 
   dt_mes_gracia	        = @i_mes_gracia,
   dt_base_calculo	        = @i_base_calculo,
   dt_dia_habil  	        = @i_ult_dia_habil,
   dt_recalcular_plazo	    = @i_recalcular ,
   dt_prd_cobis             = @i_prd_cobis,  
   dt_tipo_redondeo		    = @i_tipo_redondeo,
   dt_causacion             = @i_causacion,    
   dt_convertir_tasa        = @i_convierte_tasa,
   dt_tipo_linea            = @i_tipo_linea,
   dt_subtipo_linea         = @i_subtipo_linea,
   dt_bvirtual              = @i_bvirtual,
   dt_extracto              = @i_extracto,
   dt_naturaleza 		    = @i_naturaleza,
   dt_pago_caja			    = @i_pago_caja,
   dt_nace_vencida          = @i_nace_vencida,
   dt_calcula_devolucion    = @i_calcula_devolucion,  
   dt_categoria			    = @i_categoria,
   dt_entidad_convenio      = @i_entidad_convenio,
   dt_mora_retroactiva      = @i_mora_retroactiva,
   dt_prepago_desde_lavigente   = @i_prepago_desde_lavigente,
   dt_dias_anio_mora            = @i_dias_anio_mora,
   dt_tipo_calif            = @i_tipo_calif,
   dt_plazo_min             = @i_plazo_min,
   dt_plazo_max             = @i_plazo_max,
   dt_monto_min             = @i_monto_min,
   dt_monto_max             = @i_monto_max,
   dt_clase_sector          = @i_clase_sector,
   dt_clase_cartera         = @i_clase_cartera,
   dt_gar_admisible         = @i_gar_admisible,
   dt_afecta_cupo           = @i_afecta_cupo,
   dt_control_dia_pago      = @i_control_dia_pago,
   dt_porcen_colateral      = @i_porcen_colateral,
   dt_admin_individual      = @i_admin_individual
   
   where   dt_toperacion = @i_toperacion
   and	dt_moneda = @i_moneda
	   	
   /* error en actualizacion */
   if @@error != 0 begin
      PRINT 'defa_top.sp error actualizando ca_default_toperacion'
      select @w_error = 705041
      goto ERROR
   end


   /*ACTUALIZAR LA TABLA DE CREDITO */
/*
   update cob_credito..	cr_toperacion set
   to_estado = @i_estado
   where to_toperacion = @i_toperacion
   and   to_producto   = 'CCA'

   if @@error != 0 begin
      PRINT 'defa_top.sp error actualizando cr_toperacion'
      select @w_error = 705041
      goto ERROR
   end
*/

   commit tran

end

/* PERSONALIZACION BANCO DEL ESTADO */
if @i_operacion = 'H' begin
   select     x.dt_toperacion, c.valor
   from
   ca_default_toperacion x ,
   cobis..cl_catalogo c,
   cobis..cl_tabla d
   where x.dt_tipo = 'R'
   and x.dt_moneda = @i_moneda
   and d.tabla     = 'ca_toperacion'
   and d.codigo    = c.tabla
   and c.codigo    = x.dt_toperacion
   and (x.dt_toperacion=@i_codigo or @i_codigo is null)
end

if @i_operacion = 'Q' begin
   if exists ( select 1 from ca_default_toperacion
               where dt_toperacion = @i_toperacion
	           and dt_moneda       = @i_moneda)  begin

      select @w_cuota_completa	= dt_cuota_completa,
      @w_tipo_cobro		        = dt_tipo_cobro,
      @w_tipo_reduccion		    = dt_tipo_reduccion,
      @w_aceptar_anticipos	    = dt_aceptar_anticipos,
      @w_dias_anio		        = dt_dias_anio,
      @w_tipo_amortizacion	    = dt_tipo_amortizacion,
      @w_cuota_fija		        = dt_cuota_fija,
      @w_fecha_fija		        = dt_fecha_fija,
      @w_dias_gracia		    = dt_dias_gracia,
      @w_dia_pago		        = dt_dia_pago,
      @w_tplazo			        = dt_tplazo,
      @w_desc_tplazo		    = (select td_descripcion
                                       from ca_tdividendo
                                       where td_tdividendo = x.dt_tplazo),
      @w_plazo		            = dt_plazo,
      @w_tdividendo	            = dt_tdividendo,
      @w_desc_tdiv	            = (select td_descripcion
                                       from ca_tdividendo
                                       where td_tdividendo = x.dt_tdividendo),
      @w_periodo_cap 		    = dt_periodo_cap,
      @w_periodo_int		    = dt_periodo_int,
      @w_gracia_cap 		    = dt_gracia_cap,
      @w_gracia_int		        = dt_gracia_int,
      @w_dist_gracia		    = dt_dist_gracia,
      @w_reajustable		    = dt_reajustable,
      @w_periodo_reaj		    = dt_periodo_reaj,
      @w_reajuste_especial	    = dt_reajuste_especial,
      @w_renovacion		        = dt_renovacion,
      @w_precancelacion		    = dt_precancelacion,
      @w_tipo		            = dt_tipo,
      @w_estado			        = dt_estado,
      @w_desc_estado		    = c.valor,
      @w_evitar_feriados        = dt_evitar_feriados,
      @w_tipo_aplicacion        = dt_tipo_aplicacion,
      @w_mes_gracia             = dt_mes_gracia,
      @w_base_calculo           = dt_base_calculo, 
      @w_ult_dia_habil          = dt_dia_habil, 
      @w_recalcular             = dt_recalcular_plazo ,
      @w_prd_cobis              = dt_prd_cobis,          
      @w_tipo_redondeo		    = dt_tipo_redondeo,	
      @w_causacion              = dt_causacion,         
      @w_convertir_tasa         = dt_convertir_tasa,
      @w_tipo_linea             = dt_tipo_linea,
      @w_subtipo_linea          = dt_subtipo_linea,
      @w_bvirtual               = dt_bvirtual,
      @w_extracto               = dt_extracto,
      @w_naturaleza             = dt_naturaleza,
      @w_pago_caja		        = dt_pago_caja,
      @w_nace_vencida		    = dt_nace_vencida,
      @w_calcula_devolucion	    = dt_calcula_devolucion, 
      @w_categoria		        = dt_categoria,
      @w_entidad_convenio       = dt_entidad_convenio,
      @w_mora_retroactiva       = dt_mora_retroactiva,
      @w_prepago_desde_lavigente = dt_prepago_desde_lavigente,
      @w_dias_anio_mora         = dt_dias_anio_mora,
      @w_tipo_calif             = dt_tipo_calif,
      @w_plazo_min              = dt_plazo_min,
      @w_plazo_max              = dt_plazo_max,
      @w_monto_min              = dt_monto_min,
      @w_monto_max              = dt_monto_max,
      @w_clase_sector           = dt_clase_sector,
      @w_clase_cartera          = dt_clase_cartera,
      @w_gar_admisible          = dt_gar_admisible,
      @w_afecta_cupo            = dt_afecta_cupo,
      @w_control_dia_pago       = dt_control_dia_pago,
      @w_porcen_colateral       = dt_porcen_colateral
      

      from ca_default_toperacion x, 
           cobis..cl_catalogo c with (nolock), 
           cobis..cl_tabla d with (nolock)
      where dt_toperacion = @i_toperacion
      and dt_moneda       = @i_moneda
      and d.tabla         = 'cl_estado_ser' 
      and d.codigo        = c.tabla
      and c.codigo        = dt_estado  

      select @w_des_tipo_calif  = B.valor
      from   cobis..cl_tabla A,cobis..cl_catalogo B
      where  A.tabla       = 'cr_tipo_calif'
      and    A.codigo      = B.tabla
      and    B.codigo      = @w_tipo_calif
     
      select @w_desc_tipo  = B.valor
      from   cobis..cl_tabla A,cobis..cl_catalogo B
      where  A.tabla       = 'ca_tipo_prestamo'
      and    A.codigo      = B.tabla
      and    B.codigo      = @w_tipo
      set transaction isolation level read uncommitted

      select @w_descripcion = null,
      @w_clase      = null,
      @w_signo      = null,
      @w_factor	    = null,
      @w_tasa_refe  = null

      select @w_valor_referencial = null,
      @w_valor_total  = null


      select @w_des_prd_cobis = pd_descripcion 
      from cobis..cl_producto
      where pd_estado   = 'V'
      and   pd_producto = @w_prd_cobis
      set transaction isolation level read uncommitted
     
      
      select @w_tipo_desc = valor from cobis..cl_catalogo
      where tabla = (select codigo from cobis..cl_tabla
                       where tabla = 'ca_tipo_linea')
      and codigo = @w_tipo_linea
      set transaction isolation level read uncommitted


      --select @w_subtipo_desc = si_descripcion
      --from ca_subtipo_linea
      --where si_codigo = @w_subtipo_linea
      --and si_tipo_linea = @w_tipo_linea

      select @w_subtipo_desc  = B.valor
      from   cobis..cl_tabla A,cobis..cl_catalogo B
      where  A.tabla       = 'ca_subtipo_linea'
      and    A.codigo      = B.tabla
      and    B.codigo      = @w_subtipo_linea
      set transaction isolation level read uncommitted

      select @w_categoria_desc  = B.valor
      from   cobis..cl_tabla A,cobis..cl_catalogo B
      where  A.tabla       = 'ca_categoria_linea'
      and    A.codigo      = B.tabla
      and    B.codigo      = @w_categoria
      set transaction isolation level read uncommitted

      select @w_desc_entidad_convenio = B.valor
      from   cobis..cl_tabla A,cobis..cl_catalogo B
      where  A.tabla       = 'ca_entidad_convenio'
      and    A.codigo      = B.tabla
      and    B.codigo      = @w_entidad_convenio
      set transaction isolation level read uncommitted

      select @w_desc_clase_sector  = B.valor
      from   cobis..cl_tabla A,cobis..cl_catalogo B
      where  A.tabla       = 'cr_tipo_calif'
      and    A.codigo      = B.tabla
      and    B.codigo      = @w_clase_sector
      set transaction isolation level read uncommitted
      
      select @w_desc_clase_cartera  = B.valor
      from   cobis..cl_tabla A,cobis..cl_catalogo B
      where  A.tabla       = 'cr_clase_cartera'
      and    A.codigo      = B.tabla
      and    B.codigo      = @w_clase_cartera
      set transaction isolation level read uncommitted
            
      select
      @w_cuota_completa,        '',                         '',                       '',                      --04
      @w_tipo_cobro,            '',                         @w_tipo_reduccion,        @w_aceptar_anticipos,    --08
      @w_dias_anio,               @w_tipo_amortizacion,       @w_cuota_fija,            @w_fecha_fija,         --12
      '',                         @w_dias_gracia,             @w_dia_pago,              @w_tplazo,             --16
      @w_desc_tplazo,             @w_plazo,                   @w_tdividendo,            @w_desc_tdiv,          --20
      @w_periodo_cap,             @w_periodo_int,             @w_gracia_cap,            @w_gracia_int,         --24
      @w_dist_gracia,             @w_reajustable,             @w_periodo_reaj,          @w_renovacion,         --28
      @w_precancelacion,          @w_tipo,                    0,                        '',                    --32
      @w_descripcion,             @w_valor_referencial,       @w_valor_total,           @w_estado,             --36
      @w_desc_estado,             0,                          @w_reajuste_especial,     '',                    --40
      0,                          @w_evitar_feriados,         @w_tipo_aplicacion,       @w_mes_gracia,         --44 
      @w_desc_tipo,               @w_base_calculo,            @w_ult_dia_habil,         @w_recalcular,         --48
      @w_prd_cobis,               @w_des_prd_cobis,           @w_tipo_redondeo,	        @w_causacion,          --52
      @w_convertir_tasa,          @w_tipo_linea,              @w_tipo_desc,             @w_subtipo_linea,      --56
      @w_subtipo_desc,            @w_bvirtual,                @w_extracto, 	            @w_naturaleza,         --60
      @w_pago_caja,    		      @w_nace_vencida,            @w_calcula_devolucion,    @w_categoria,          --64
      @w_categoria_desc,          @w_entidad_convenio,        @w_desc_entidad_convenio, @w_mora_retroactiva,   --68
      @w_prepago_desde_lavigente, @w_dias_anio_mora,          @w_tipo_calif,            @w_des_tipo_calif,     --72
      @w_plazo_min,               @w_plazo_max,               @w_monto_min,             @w_monto_max,          --76
      @w_clase_sector,            @w_desc_clase_sector,       @w_clase_cartera,         @w_desc_clase_cartera, --80
      @w_gar_admisible,           @w_afecta_cupo,             @w_control_dia_pago,      @w_porcen_colateral    --84
   end
   else 

      select  dt_cuota_completa,'','','',
      dt_tipo_cobro,          '',                  dt_tipo_reduccion,
      dt_aceptar_anticipos,   dt_dias_anio,        dt_tipo_amortizacion, --10
      dt_cuota_fija,          dt_fecha_fija,       '',
      dt_dias_gracia,         dt_dia_pago, dt_tplazo,
      desc_tplaz =(select td_descripcion
                   from ca_tdividendo
                   where td_tdividendo = X.dt_tplazo),
      dt_plazo,               dt_tdividendo,
      desc_tdiv=(select td_descripcion
                 from ca_tdividendo
                 where td_tdividendo = X.dt_tdividendo), 
      dt_periodo_cap,         dt_periodo_int,      dt_gracia_cap,
      dt_gracia_int,          dt_dist_gracia,      dt_reajustable,
      dt_periodo_reaj,        dt_renovacion,       dt_precancelacion,
      dt_tipo,                0, 
      null,                   null,	           null,	
      dt_estado,              c.valor,             0,
      dt_reajuste_especial,   '',                  0,
      dt_evitar_feriados,     dt_tipo_aplicacion,  dt_mes_gracia,
      dt_base_calculo,        dt_dia_habil,        dt_recalcular_plazo ,
      dt_prd_cobis,           null,	           null,
      null,	              null,                null,
      dt_tipo_linea,          dt_subtipo_linea,    dt_bvirtual,
      dt_extracto,            dt_naturaleza,       dt_pago_caja, 
      dt_nace_vencida,        dt_calcula_devolucion,dt_categoria                   --MPO 17JUL2001
      from ca_default_toperacion X,cobis..cl_catalogo c, cobis..cl_tabla d
      where dt_toperacion = 'DEF'
      and dt_moneda     = 0
      and d.tabla       = 'cl_estado_ser'
      and d.codigo      = c.tabla
      and c.codigo      = dt_estado  


end

/* CONSULTAR TIPOS DE OPERACION PARA RENOVACIONES */
if @i_operacion = 'R' 
begin
    SELECT 'codigo'      = b.codigo, 
           'descripcion' = b.valor
    FROM    cobis..cl_tabla a,
            cobis..cl_catalogo b, 
            cob_cartera..ca_default_toperacion c
    WHERE   a.codigo = b.tabla
    AND     a.tabla = 'ca_toper_ren'
    and     dt_toperacion = b.codigo
    and     dt_moneda = @i_moneda
end


return 0

ERROR:

exec cobis..sp_cerror
@t_debug  = 'N',         
@t_file   = null,
@t_from   = @w_sp_name,   
@i_num    = @w_error
--@i_cuenta = ' '
return @w_error

go

