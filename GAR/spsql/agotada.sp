/************************************************************************/
/*	Archivo:                agotada.sp                                  */
/*	Stored procedure:       sp_agotada                                  */
/*	Base de datos:          cob_custodia                                */
/*	Producto:               garantias                                   */
/*	Disenado por:           Milena Gonzalez                             */
/*	Fecha de escritura:     Diciembre-2000                              */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	'MACOSA', representantes exclusivos para el Ecuador de la           */
/*	'NCR CORPORATION'.                                                  */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier alteracion o agregado hecho por alguno de sus             */
/*	usuarios sin el debido consentimiento por escrito de la             */
/*	Presidencia Ejecutiva de MACOSA o su representante.                 */
/*                          PROPOSITO                                   */
/*	Este programa cada vez que se efectua un pago desde Cartera, se     */
/*      encargara  actualizar el valor actual  de    la(s) garantia(s)  */
/*      que amparan una operacion. Esto aplica para garantias cerradas  */
/*      y con agotamiento.                                              */
/*				MODIFICACIONES                                          */
/*	FECHA		AUTOR		RAZON                                       */
/************************************************************************/
use cob_custodia
go
if exists (select 1 from sysobjects where name = 'sp_agotada')
    drop proc sp_agotada
go
create proc sp_agotada (
   @s_ssn                int         = null,
   @s_date               datetime    = null,
   @s_user               login       = null,
   @s_term               descripcion = null,
   @s_ofi                smallint    = null,
   @t_trn                smallint    = null,
   @t_debug              char(1)     = 'N',
   @t_file               varchar(14) = NULL,
   @t_from               varchar(30) = NULL,
   @i_operacion          char(1)     = null, 
   @i_monto              float       = null, 
   @i_monto_mn           float       = null, 
   @i_moneda             int         = null, 
   @i_tramite            int         = null, 
   @i_agotada            char(1)     = null,
   @i_saldo_cap_gar      money       = null,
   @i_capitaliza         char(1)     = 'N',
   @i_en_linea           char(1)     = null --CAV Req 371 - Para controlar errores en WS
)
as
   declare
   @w_return             int,
   @w_today              datetime,
   @w_sp_name            varchar(32), 
   @w_tramite            int,    
   @w_producto           catalogo,
   @w_codigo_externo     varchar(64),
   @w_porcentaje         float,
   @w_moneda_gar         tinyint,
   @w_moneda_oblig       tinyint,  
   @w_monto_oblig        float,    
   @w_moneda_loc         tinyint,  
   @w_valor_mn_pago      float,   
   @w_valor_mn_gar       float,   
   @w_valor_pago         float,
   @w_cobertura          float,
   @w_disponible         float,
   @w_disp               float,
   @w_pago               char(1),
   @w_ban                char(1),
   @w_valor_actual       float,
   @w_valor_actual_cal   float,
   @w_valor_inicial      float,
   @w_cont               int,
   @w_monto              float,   
   @w_cotizacion_pago    money,   
   @w_cotizacion_gar     money,   
   @w_operacionca        int,       
   @w_cuota              float,     
   @w_porcen             float,     
   @w_porcen1            float,     
   @w_descripcion        varchar(64),
   @w_filial             smallint,
   @w_sucursal           smallint,
   @w_tipo_cust          descripcion,
   @w_custodia           int,
   @w_secuencial         int,
   @w_error              int,
   @w_valor              money,   
   @w_secuencial_max     int,     
   @w_capital_pagado     float,   
   @w_valor_monto_aprob  float,   
   @w_monto_aprob        float,   
   @w_total              float,   
   @w_mon_monto_aprob    tinyint, 
   @w_agotada            char(1),
   @w_codigo             varchar(64),
   @w_diferencia         money,
   @w_tipo_sup      	 varchar(64) ,
   @w_tipo     		 varchar(64),
   @w_porcentaje_gp	 float

if @s_date is null begin
   select 
   @s_date = fp_fecha
   from cobis..ba_fecha_proceso
end

select 	@w_sp_name 	= 'sp_agotada',
	@w_today 	= convert(varchar(10),@s_date,101),
	@w_ban 		= 'S',
	@w_cont 	= 1

if (@t_trn <> 19911)
begin
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1901006 
end

declare	cursor_consulta cursor for
select 	cu_codigo_externo,
	    isnull(cu_porcentaje_cobertura,0)/100
from   	cob_custodia..cu_custodia, 
	    cob_credito..cr_gar_propuesta
where  	gp_tramite  	= @i_tramite
and    	gp_garantia 	= cu_codigo_externo
and    	cu_agotada  	= 'S'
and 	cu_estado	    = ('V')
for read only

open 	cursor_consulta
fetch 	cursor_consulta 
into    @w_codigo_externo,
        @w_porcentaje_gp

if (@@fetch_status = -1)  
begin
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = @w_sp_name,
   @i_num   = 1909001
   return 1909001
end

if @@fetch_status != 0 
begin
   close cursor_consulta
   return 0
end

while @@fetch_status = 0
begin 

   select @w_porcentaje_gp = isnull(@w_porcentaje_gp,0)
   
   exec sp_compuesto
   @t_trn       = 19245,
   @i_operacion = 'Q',
   @i_compuesto = @w_codigo_externo,
   @o_filial    = @w_filial out,
   @o_sucursal  = @w_sucursal out,
   @o_tipo      = @w_tipo out,
   @o_custodia  = @w_custodia out
   
   select @w_tipo_sup = tc_tipo_superior
   from   cob_custodia..cu_tipo_custodia
   where  tc_tipo = @w_tipo
  
  
  if @i_operacion = 'P'
     select  @w_valor_actual 	= (isnull(@i_saldo_cap_gar,0)-isnull(@i_monto_mn,0))* @w_porcentaje_gp
  else
     select  @w_valor_actual 	= (isnull(@i_saldo_cap_gar,0)) * @w_porcentaje_gp
   
   if @i_en_linea = 'N'
      select @i_en_linea = 'S'
   else
      select @i_en_linea = 'N'
     
   exec @w_return = sp_modvalor
        @s_date            = @s_date,
        @s_user            = @s_user,
        @i_operacion       = 'I',
        @i_filial          = @w_filial ,
        @i_sucursal        = @w_sucursal ,
        @i_tipo_cust       = @w_tipo ,
        @i_custodia        = @w_custodia ,
        @i_fecha_tran      = @w_today,
        @i_debcred         = 'D',
        @i_valor           = @w_valor_actual,
        @i_descripcion     = 'PAGO DE CUOTA',
        @i_usuario         = @s_user,
        @i_terminal        = @s_term,
        @i_autoriza        = 'garbatch',
        @i_valor_cobertura = @w_valor_actual, --Para Colaterales Agotadas, el valor comercial es el mismo Valor actual
        @i_nuevo_comercial = @w_valor_actual,        
        @i_tipo_superior   = @w_tipo_sup,
		@i_banderabe       = @i_en_linea --CAV Req 371 - Para controlar errores en WS
   
   if @w_return <> 0 
   begin
      if @w_return is null or @w_return  = 0
         select @w_return = 1905001

      exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_num   = @w_return
      return @w_return 
   end
   
  select @w_porcentaje_gp = 0

  fetch  cursor_consulta 
  into   @w_codigo_externo,
         @w_porcentaje_gp
  end
close cursor_consulta
deallocate cursor_consulta

return 0
                                                                                                                                           
go