use cob_pac
go

if exists (select 1 from sysobjects where name = 'sp_divisas_credito_busin')
   drop proc sp_divisas_credito_busin
go

create proc sp_divisas_credito_busin(
   @s_date                  datetime     = null,       -- Fecha del sistema
   @s_user                  login        = null,       -- Usuario del sistema
   @s_ssn                   int          = null,       -- Secuencial unico COBIS
   @t_show_version          tinyint      = 0,          -- Versionamiento del SP
   @s_ofi                   smallint    = null,
   @t_trn                   int,
   @t_debug                 char(1)     = 'N',
   @t_file                  varchar(14) = null,
   @i_oficina               smallint    = null,        -- Oficina donde debe ser registrada la transaccion.  Afectará contablemente
   @i_modulo                char(3),                   -- Nemonico del modulo COBIS que origina la operacion de divisas
   @i_moneda_origen         tinyint      = null,         /* Moneda en la cual está expresado el monto a convertir                     */
   @i_operacion             char(1),   
   @i_valor                 money        = 0,         /* Monto a convertir                                                         */
   @i_valor_destino         money        = 0,   
   @i_moneda_destino        tinyint      = null,         /* Moneda en la cual se expresará el monto                                   */
   /*
   @i_transaccion           varchar(5)   = null,
   @i_tasa                  money        = null,
   @i_monto_cv              money        = null,*/
   @i_mon                   tinyint      = null,
   @i_moneda_cv             tinyint      = null,   
   /*@i_valor_tran            money        = null,
   @i_cot_usd               float        = 0,
   @i_factor                float        = 0,
   @i_concepto              catalogo     = null,
   @i_cliente               int          = 0,
   */
   @i_modo                  int          = 1,
   @o_valor_convertido      money = null out,     /* Monto equivalente en la moneda destino                                    */   
   @o_factor                float = null output,         /* Factor de relación de la moneda respecto al dólar(Tesoreria/Contabilidad) */
   @o_cotizacion            float = null output,          /* Cotizacion de la Moneda respecto a la moneda nacional                    */
   @o_cot_usd               float = null output,
   @o_valor_conver_orig     money = null output
)

as declare

  @w_sp_name                varchar(32),      --Nombre de procedure
  @w_tipo_op                estado,                      /* Tipo de Operaci¢n: Compra, Venta o Arbitraje                              */
  @w_mensaje_error          varchar(255),
  @w_mon_local              smallint,
  @w_mon_usd                smallint,
  @w_retorno                int,
  @w_cotizacion             float

select @w_sp_name       = 'sp_divisas_credito_busin'
---- VERSIONAMIENTO DEL PROGRAMA ----
if @t_show_version = 1
begin
    print 'Stored procedure cob_remesas..sp_divisas_credito_busin, Version 1.0.0.0'
    return 0
end

if (@t_trn <> 73930 and @i_operacion = 'C')
begin
    /* No existe codigo de transaccion. */
    exec cobis..sp_cerror
            @i_num  = 101183,
            @t_from = @w_sp_name
    return 1
end

--Consulta la moneda local
select @w_mon_local = pa_tinyint   --0
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

select @w_mon_usd = pa_tinyint  --2
      from cobis..cl_parametro
     where pa_producto = 'ADM'
       and pa_nemonico = 'CDOLAR'

if @i_operacion = 'C'
begin
    
    if @i_mon <> @w_mon_local and @i_moneda_cv <> @w_mon_local and @i_mon <> @i_moneda_cv
    begin
        exec cobis..sp_cerror  -- ERROR EN LA MONEDA DE COMPRA DE DIVISAS, ESCOJA LA MONEDA LOCAL
               @t_from = @w_sp_name,
               @i_num  = 2610063,
               @i_sev  = 0
        return 1
    end

--Existe 2 modos en sp NO busin
--Por especificacion de PQU se especifica solamente modo=1
    if @i_modo = 1
    begin
    
    	select @o_cot_usd = ct_valor
        	  from cob_cartera..cotizacion cot
        	 where ct_fecha = (select max(ct_fecha) from cob_cartera..cotizacion
        	                    where ct_moneda = cot.ct_moneda)
        	   and ct_moneda = @w_mon_usd
        	           	   
    	if(@i_moneda_origen = @i_moneda_destino)
    		select @w_cotizacion = 1
    	else if(@i_moneda_origen <> @w_mon_local )
    	begin
        	select @w_cotizacion = ct_valor
        	  from cob_cartera..cotizacion cot
        	 where ct_fecha = (select max(ct_fecha) from cob_cartera..cotizacion
        	                    where ct_moneda = cot.ct_moneda)
        	   and ct_moneda = @i_moneda_origen
        end
        else
        begin
        	select @w_cotizacion = ct_valor
        	  from cob_cartera..cotizacion cot
        	 where ct_fecha = (select max(ct_fecha) from cob_cartera..cotizacion
        	                    where ct_moneda = cot.ct_moneda)
        	   and ct_moneda = @i_moneda_destino        
        end 
           
		select @o_cotizacion = @w_cotizacion
		select @o_cot_usd = @o_cotizacion
		
		if(@i_moneda_origen = @i_moneda_destino)
			select @o_valor_convertido = @i_valor
		else if(@w_mon_local = @w_mon_usd)
		begin
			if(@w_mon_local = @i_moneda_origen)
				select @o_valor_convertido = round(@i_valor * @o_cotizacion,2)
			else 
			    select @o_valor_convertido = round(@i_valor / @o_cotizacion,2)
	    end
	    else
	    begin
	    	if(@w_mon_local = @i_moneda_origen)
	    		select @o_valor_convertido = round(@i_valor / @o_cotizacion,2)
	    	else
	    	    select @o_valor_convertido = round(@i_valor * @o_cotizacion,2)
	    end
	    
	    select @o_valor_conver_orig = @o_valor_convertido
	    
	    if(@o_valor_convertido is null)
	    begin
	    	exec cobis..sp_cerror
            	@t_debug  =  @t_debug,
            	@t_file   =  @t_file,
            	@t_from   =  @w_sp_name,
            	@i_num    =  902659
	    	return 902659
	    end
			    	
    end


end
return 0

GO
