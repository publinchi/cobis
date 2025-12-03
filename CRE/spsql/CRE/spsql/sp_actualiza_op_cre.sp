/**************************************************************************/
/*  Archivo:                    sp_actualiza_op_cre.sp                    */
/*  Stored procedure:           sp_actualiza_op_cre                       */
/*  Base de Datos:              cob_credito                               */
/*  Producto:                   Credito                                   */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial TOPAZ,            */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de TOPAZ TECHNOLOGIES S.L., sociedad constituida           */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   TOPAZ TECHNOLOGIES S.L. El incumplimiento de lo dispuesto            */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada; y por lo tanto, derivará en acciones legales civiles        */
/*   y penales en contra del infractor según corresponda.                 */
/**************************************************************************/
/*                          PROPOSITO                                     */
/*  Este stored procedure permite forzar actualizacion de operacion       */
/*                                                                        */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA          AUTOR                            RAZON                 */
/*  09/Nov/2021   Dilan Morales           implementacion                  */
/*  23/Dic/2021   Dilan Morales           Cambios para actualizar op      */
/*                                        grupal e individual             */
/*  24/Feb/2022   Dilan Morales           Se añade operación para pasar a */
/*                                        tablas definitivas              */
/*  09/Mar/2022   Dilan Morales           Se añade validacion cuando tipo */
/*                                        tramite es distinto a linea de  */
/*                                        credito                         */
/*  15/Mar/2022   Dilan Morales           Se añade operación para actuali-*/
/*                                        zar operacion grupal            */
/*  29/Jun/2022   Dilan Morales           Se corrige update op hijas      */
/*  06/Jul/2022   Dilan Morales           Update tr_plazo en op hijas     */
/*  06/Jul/2022   Dilan Morales           se cambia orden de sps para     */
/*                                        operacion G                     */
/*  26/Jul/2022   Bruno Duenas            Se agrega variable para paso tmp*/
/*                                        en operacion F                  */
/*  29/07/2022  Dilan Morales             Se cambia logica de cálculo     */
/*                                        de rubros                       */
/*  17/08/2022  Dilan Morales           R-191711: Se añade transaccionalidad*/
/*  18/08/2022  Dilan Morales           R-191499: Se envia cuota en 0     */
/*  14/09/2022  Dilan Morales             R-192772: Optimizacion          */
/*                                        de transacciones                */
/*  30/11/2023  Bruno Dueñas              Se agrega no lock-R220601       */
/*  08/07/2024  Dilan Morales             R239478: Se añade codigo para   */
/*                             			  actualizar tea y tir            */  
/*  08/07/2024  Dilan Morales             R239478: Se añade codigo para   */
/*                             			  actualizar tea y tir            */ 
/*  09/04/2025  Dilan Morales             R261705: Se modifica manejo de  */
/*                             			  op hijas en operacion G         */ 
/**************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_actualiza_op_cre' and type = 'P')
    drop proc sp_actualiza_op_cre
go

create proc sp_actualiza_op_cre
(
  @s_ssn                int         = null,
  @s_user               varchar(30) = null,
  @s_sesn               int         = null,
  @s_term               varchar(30) = null,
  @s_date               datetime    = null,
  @s_srv                varchar(30) = null,
  @s_lsrv               varchar(30) = null,
  @s_rol                smallint    = null,
  @s_ofi                smallint    = null,
  @s_org_err            char(1)     = null,
  @s_error              int         = null,
  @s_sev                tinyint     = null,
  @s_msg                descripcion = null,
  @s_org                char(1)     = null,
  @t_rty                char(1)     = null,
  @t_trn                int         = null,
  @t_debug              char(1)     = 'N',
  @t_file               varchar(14) = null,
  @t_from               varchar(30) = null,
  @i_operacion          char(1)     = null,
  @i_tramite            int         = null,
  @i_grupo_contable     catalogo    = null,
  @i_banco              int         = null,
  @i_dias_gracia        smallint    = null  ,
  @i_fecha_fija         char(1)     = 'S',
  @i_pasa_tmp           char(1)     = 'S' 
  

)
as

declare
        @w_sp_name              varchar (30),
        @w_return               int,
        @w_error                int,
        @w_operacionca          int,
        @w_banco                cuenta,
        @w_monto                money,
        @w_op_monto             money,
        @w_pasa_tmp_and_def     char(1),
        @w_grupal               char(1),
        @w_tr_tipo              char(1),
        --DMO DATOS DE OPERACION PADRE
        @w_moneda_padre         tinyint,
        @w_fecha_ini_padre      datetime,
        @w_fecha_fin_padre      datetime,
        @w_fecha_pri_cuot_padre datetime,
        @w_fecha_liq_padre      datetime,
        @w_fecha_reajuste_padre datetime,
        @w_periodo_reajuste_padre smallint,
        @w_reajuste_especial_padre char(1),
        @w_tipo_padre           char(1),
        @w_dias_anio_padre      smallint,
        @w_tipo_amortizacion_padre    varchar(10),
        @w_cuota_completa_padre  char(1),
        @w_tipo_cobro_padre      char(1),
        @w_tipo_reduccion_padre  char(1),
        @w_aceptar_anticipos_padre    char(1),
        @w_precancelacion_padre  char(1),
        @w_tipo_aplicacion_padre char(1),
        @w_tplazo_padre          catalogo,
        @w_plazo_padre           int,    
        @w_tdividendo_padre      catalogo,
        @w_periodo_cap_padre     int    ,
        @w_periodo_int_padre     int    ,
        @w_dist_graci_padre      char(1),
        @w_gracia_cap_padre      int    ,
        @w_gracia_int_padre      int    ,
        @w_dia_fijo_padre        int    ,
        @w_evitar_feriados_padre char(1),
        @w_mes_gracia_padre      tinyint,
        @w_dias_gracia_padre     smallint,
        @w_reajustable_padre     char(1),
        @w_base_calculo_padre    char(1),
        @w_capitalizacion_padre  char(1),
        @w_tramite_padre         int,
        @w_tramite_hijo          int,
        @w_operacion_hija        int, 
        @w_banco_hija            cuenta,
        @w_banco_padre           cuenta,
        @w_cuota                 money,
        @w_transaccion           char(1),
		@w_tir_padre             float,
        @w_tea_padre             float,
		@w_id               	 int,
		@w_max_id           	 int
    

-- CARGAR VALORES INICIALES
select @w_sp_name = 'sp_actualiza_op_cre'

select  @w_transaccion = 'N'

IF (@i_operacion != 'G')
BEGIN 
    if(@i_tramite is null)
    begin
        select @w_error = 2110179
        goto   ERROR
    end

    select @w_tr_tipo = tr_tipo 
    from cob_credito..cr_tramite with (nolock) 
    where tr_tramite = @i_tramite
    
END


--DMO UPDATE PARA GRUPO CONTABLE
IF(@i_operacion = 'U' and @w_tr_tipo != 'L')
BEGIN

    select
    @w_operacionca      = op_operacion,
    @w_banco            = op_banco,
    @w_monto            = op_monto
    from cob_cartera..ca_operacion with (nolock)
    where op_tramite      = @i_tramite
    
    if(@w_operacionca is null or @w_banco is null)
    begin
        select @w_error = 2110180
        goto   ERROR
    end
    
    if not exists(select 1 from cob_cartera..ca_operacion_tmp with (nolock) where opt_operacion = @w_operacionca)
    begin
        exec @w_return = cob_cartera..sp_pasotmp
                @s_user            = @s_user,
                @s_term            = @s_term,
                @i_banco           = @w_banco,
                @i_operacionca     = 'S',
                @i_dividendo       = 'S',
                @i_amortizacion    = 'S',
                @i_cuota_adicional = 'S',
                @i_rubro_op        = 'S',
                @i_relacion_ptmo   = 'S',
                @i_nomina          = 'S',
                @i_acciones        = 'S',
                @i_valores         = 'S'
                
        if @w_return != 0 
        begin
            select @w_error = @w_return
            goto   ERROR
        end
      
    end

    
    if exists (select 1 from cob_credito..cr_tramite_grupal with (nolock) where tg_operacion =@w_operacionca)
    begin
        select @w_grupal = 'S'
    end
    else
    begin
        select @w_grupal = 'N'
    end
    
    --DMO
    select  @w_transaccion = 'S'
    begin tran
    
    
    exec    @w_return = cob_cartera..sp_modificar_operacion
            @s_user              = @s_user,
            @s_date              = @s_date,
            @s_ofi               = @s_ofi,
            @s_term              = @s_term,
            @i_calcular_tabla    = 'S', 
            @i_tabla_nueva       = 'S',
            @i_grupal            = @w_grupal,
            @i_grupo_contable    = @i_grupo_contable,
            @i_operacionca       = @w_operacionca,
            @i_banco             = @w_banco,
            @i_cuota             = 0
            
    if @w_return != 0 
    begin
        select @w_error = @w_return
        goto   ERROR
    end
    
      --Se llama para manejar rubros calculados
    exec @w_return = cob_cartera..sp_xsell_actualiza_monto_op
         @i_banco           = @w_banco,
         @s_user            = @s_user,
         @s_term            = @s_term,
         @s_ofi             = @s_ofi,
         @s_date            = @s_date,
         @i_monto_nuevo     = @w_monto,
         @i_recalcular_rub  = 'S',
         @i_pasa_a_temporales = 'N',
         @i_pasar_a_def     = 'N',
         @i_grupal          = @w_grupal,
         @o_monto_calculado = @w_op_monto out
         
    if @w_return != 0 
    begin
        select @w_error = @w_return
        goto   ERROR
    end
    
    exec    @w_return = cob_cartera..sp_pasodef
            @i_banco            = @w_banco,
            @i_operacionca      = 'S',
            @i_dividendo        = 'S',
            @i_amortizacion     = 'S',
            @i_cuota_adicional  = 'S',
            @i_rubro_op         = 'S',
            @i_relacion_ptmo    = 'S',
            @i_nomina           = 'S',
            @i_acciones         = 'S',
            @i_valores          = 'S'   
                
    if @w_return != 0 
    begin
        select @w_error = @w_return
        goto   ERROR
    end
    
    exec    @w_return = cob_cartera..sp_borrar_tmp
            @s_user       = @s_user,
             --@s_sesn       = @s_sesn,
            @s_term       = @s_term,
            @i_desde_cre  = 'S',
            @i_banco      = @w_banco
    
    if @w_return != 0 
    begin
        select @w_error = @w_return
        goto   ERROR
    end

END


    --DMO SE ACTUALIZA OPERACIONES HIJAS
IF (@i_operacion = 'G')
BEGIN
    if(@i_banco is null)
    begin
        select @w_error = 2110179
        goto   ERROR
    end
    
    
    --DMO DESDE EL FRON SE ENVIA NUMERO DE OPERACION EN EL @i_banco
    select @w_operacionca = @i_banco
    
    --Se obtiene datos del padre
    select @w_banco_padre               =opt_banco,
           @w_tramite_padre             =opt_tramite,
           @w_moneda_padre              =opt_moneda, 
           @w_fecha_ini_padre           =opt_fecha_ini,
           @w_fecha_fin_padre           =opt_fecha_fin,
           @w_fecha_pri_cuot_padre      =opt_fecha_pri_cuot,
           @w_fecha_liq_padre           =opt_fecha_liq,
           @w_fecha_reajuste_padre      =opt_fecha_reajuste,
           @w_periodo_reajuste_padre    =opt_periodo_reajuste,
           @w_reajuste_especial_padre   =opt_reajuste_especial,
           @w_tipo_padre                =opt_tipo,
           @w_dias_anio_padre           =opt_dias_anio,
           @w_tipo_amortizacion_padre   =opt_tipo_amortizacion,
           @w_cuota_completa_padre      =opt_cuota_completa,
           @w_tipo_cobro_padre          =opt_tipo_cobro,
           @w_tipo_reduccion_padre      =opt_tipo_reduccion,
           @w_aceptar_anticipos_padre   =opt_aceptar_anticipos,
           @w_precancelacion_padre      =opt_precancelacion,
           @w_tipo_aplicacion_padre     =opt_tipo_aplicacion,
           @w_tplazo_padre              =opt_tplazo,
           @w_plazo_padre               =opt_plazo,
           @w_tdividendo_padre          =opt_tdividendo,
           @w_periodo_cap_padre         =opt_periodo_cap,
           @w_periodo_int_padre         =opt_periodo_int,
           @w_dist_graci_padre          =opt_dist_gracia,
           @w_gracia_cap_padre          =opt_gracia_cap,
           @w_gracia_int_padre          =opt_gracia_int,
           @w_dia_fijo_padre            =opt_dia_fijo,
           @w_evitar_feriados_padre     =opt_evitar_feriados,
           @w_mes_gracia_padre          =opt_mes_gracia,
           @w_reajustable_padre         =opt_reajustable,
           @w_base_calculo_padre        =opt_base_calculo,
		   @w_tea_padre                 =opt_tasa_cap,
		   @w_tir_padre                 =opt_valor_cat
    from cob_cartera..ca_operacion_tmp with (nolock) 
    where opt_operacion = @w_operacionca
    
    
    select @w_capitalizacion_padre = or_capitaliza
    from cob_credito..cr_op_renovar with(nolock)
    where or_tramite = @w_tramite_padre
    
    if(@i_dias_gracia is null)
    BEGIN 
        select @i_dias_gracia =dit_gracia
        from   cob_cartera..ca_dividendo_tmp with (nolock)
        where  dit_operacion =  @w_operacionca
        and    dit_dividendo = 1
        
        if isnull(@w_dia_fijo_padre,0) = 0
           select @i_fecha_fija = 'N'
        else
           select @i_fecha_fija = 'S'   
    END
    
    if(@w_fecha_pri_cuot_padre is null)
    BEGIN
    
        select @w_fecha_pri_cuot_padre = dit_fecha_ven  
        FROM cob_cartera..ca_dividendo_tmp with (nolock)
        where  dit_operacion =  @w_operacionca 
        and  dit_dividendo = 1
        
        update cob_cartera..ca_operacion_tmp with (rowlock)
        set opt_fecha_pri_cuot = @w_fecha_pri_cuot_padre 
        where opt_operacion  =  @w_operacionca 
        
        if @@error <> 0
        begin
            select @w_error = 705007
            goto   ERROR
        end
        
        update cob_cartera..ca_operacion with (rowlock)
        set op_fecha_pri_cuot = @w_fecha_pri_cuot_padre 
        where op_operacion  =  @w_operacionca
        
        if @@error <> 0
        begin
            select @w_error = 705007
            goto   ERROR
        end
        
    
    END
	
	
	create table #temp_op_modificar(
        id 				int identity(1,1),
		op_operacion 	int,
        op_banco 		cuenta,
		op_monto		money,
		op_tramite		int
    )
	
	
	create table #temp_op_borrar(
		id 				int identity(1,1),
        op_banco 		cuenta
    )
	
	
	
	insert into #temp_op_modificar 
	(op_operacion, op_banco, op_monto, op_tramite)
	select  
	tg_operacion , op_banco , op_monto, op_tramite
    from cob_credito..cr_tramite_grupal with (nolock),  -- posible inner join
	     cob_cartera..ca_operacion with (nolock)
    where tg_operacion = op_operacion 
	and tg_tramite = @w_tramite_padre 
	and tg_participa_ciclo = 'S'
	
	
	select  @w_max_id 	= null,
            @w_id 		= null
			
    select @w_max_id 	= max(id) from #temp_op_modificar
    select @w_id 		= 1
	
	
	while @w_id <= @w_max_id
    begin
		select 	@w_operacion_hija 	= null, 
				@w_banco_hija 		= null, 
				@w_monto 			= null, 
				@w_tramite_hijo		= null
				
		select 	@w_operacion_hija 	= op_operacion, 
				@w_banco_hija 		= op_banco, 
				@w_monto 			= op_monto, 
				@w_tramite_hijo		= op_tramite
		from #temp_op_modificar
		where id = @w_id
			
		--creacion de temporales
        exec    @w_return     = cob_cartera..sp_pasotmp
                @s_user            = @s_user,
                @s_term            = @s_term,
                @i_banco           = @w_banco_hija,
                @i_operacionca     = 'S',
                @i_dividendo       = 'S',
                @i_amortizacion    = 'S',
                @i_cuota_adicional = 'S',
                @i_rubro_op        = 'S',
                @i_relacion_ptmo   = 'S',
                @i_nomina          = 'S',
                @i_acciones        = 'S',
                @i_valores         = 'S'
                
        if @w_return != 0 
        begin
            select @w_error = @w_return
            goto   BORRAR_TMP_GRUPAL
        end
		
		insert into #temp_op_borrar (op_banco)
		values (@w_banco_hija)
		

        exec    @w_return = cob_cartera..sp_modificar_operacion
                @s_user                 = @s_user,
                @s_date                 = @s_date,
                @s_ofi                  = @s_ofi,
                @s_term                 = @s_term,
                @i_calcular_tabla       = 'S', 
                @i_tabla_nueva          = 'S',          
                @i_operacionca          = @w_operacion_hija,
                @i_banco                = @w_banco_hija,
                @i_moneda               = @w_moneda_padre , 
                @i_fecha_ini            = @w_fecha_ini_padre ,
                @i_fecha_fin            = @w_fecha_fin_padre,
                @i_fecha_pri_cuot       = @w_fecha_pri_cuot_padre,
                @i_fecha_liq            = @w_fecha_liq_padre,
                @i_fecha_reajuste       = @w_fecha_reajuste_padre,
                @i_periodo_reajuste     = @w_periodo_reajuste_padre,
                @i_reajuste_especial    = @w_reajuste_especial_padre,
                @i_tipo                 = @w_tipo_padre,
                @i_dias_anio            = @w_dias_anio_padre,
                @i_tipo_amortizacion    = @w_tipo_amortizacion_padre,
                @i_cuota_completa       = @w_cuota_completa_padre,
                @i_tipo_cobro           = @w_tipo_cobro_padre,
                @i_tipo_reduccion       = @w_tipo_reduccion_padre,
                @i_aceptar_anticipos    = @w_aceptar_anticipos_padre,
                @i_precancelacion       = @w_precancelacion_padre,
                @i_tipo_aplicacion      = @w_tipo_aplicacion_padre,
                @i_tplazo               = @w_tplazo_padre,
                @i_plazo                = @w_plazo_padre,
                @i_tdividendo           = @w_tdividendo_padre,
                @i_periodo_cap          = @w_periodo_cap_padre,
                @i_periodo_int          = @w_periodo_int_padre,
                @i_dist_gracia          = @w_dist_graci_padre,
                @i_gracia_cap           = @w_gracia_cap_padre,
                @i_gracia_int           = @w_gracia_int_padre,
                @i_dia_fijo             = @w_dia_fijo_padre,
                @i_cuota                = 0, 
                @i_evitar_feriados      = @w_evitar_feriados_padre,
                @i_mes_gracia           = @w_mes_gracia_padre,
                @i_dias_gracia          = @i_dias_gracia,
                @i_reajustable          = @w_reajustable_padre,
                @i_base_calculo         = @w_base_calculo_padre,
                @i_fecha_fija           = @i_fecha_fija , 
                @i_grupal               = 'S' --@i_grupal
                --@i_es_grupal          = 'S' --@i_es_grupal 
                
        if @w_return != 0 
        begin
            select @w_error = @w_return
            goto   BORRAR_TMP_GRUPAL
        end
        
          --Se llama para manejar rubros calculados
        exec @w_return = cob_cartera..sp_xsell_actualiza_monto_op
               @i_banco           = @w_banco_hija,
               @s_user            = @s_user,
               @s_term            = @s_term,
               @s_ofi             = @s_ofi,
               @s_date            = @s_date,
               @i_monto_nuevo     = @w_monto,
               @i_recalcular_rub  = 'S',
               @i_pasa_a_temporales = 'N',
               @i_pasar_a_def     = 'N',
               @o_monto_calculado = @w_op_monto out
        
        if @w_return != 0 
        begin
            select @w_error = @w_return
            goto   BORRAR_TMP_GRUPAL
        end
		
		select @w_id = @w_id + 1
	end
	
	
	
	select  @w_max_id 	= null,
            @w_id 		= null
			
    select @w_max_id 	= max(id) from #temp_op_borrar
    select @w_id 		= 1
	
	select  @w_transaccion = 'S'
	begin tran
	while @w_id <= @w_max_id
    begin
		select 	@w_banco_hija 		= null
				
		select @w_banco_hija 		= op_banco
		from #temp_op_borrar
		where id = @w_id
		
		
		exec    @w_return = cob_cartera..sp_pasodef
            @i_banco            = @w_banco_hija,
            @i_operacionca      = 'S',
            @i_dividendo        = 'S',
            @i_amortizacion     = 'S',
            @i_cuota_adicional  = 'S',
            @i_rubro_op         = 'S',
            @i_relacion_ptmo    = 'S',
            @i_nomina           = 'S',
            @i_acciones         = 'S',
            @i_valores          = 'S'   
                
		if @w_return != 0 
		begin
			select @w_error = @w_return
			rollback tran
			select  @w_transaccion = 'N'
			goto   BORRAR_TMP_GRUPAL
		end
		
		select @w_id = @w_id + 1
	end
	commit tran
	select  @w_transaccion = 'N'
	
	
	BORRAR_TMP_GRUPAL:
		select  @w_max_id 	= null,
				@w_id 		= null
				
		select @w_max_id 	= max(id) from #temp_op_borrar
		select @w_id 		= 1
		
		while @w_id <= @w_max_id
		begin
			select 	@w_banco_hija = null
					
			select @w_banco_hija  = op_banco
			from #temp_op_borrar
			where id = @w_id

			exec    @w_return = cob_cartera..sp_borrar_tmp
					@s_user       = @s_user,
					@s_term       = @s_term,
					@i_desde_cre  = 'S',
					@i_banco      = @w_banco_hija

			if @w_return != 0 
			begin
				select @w_error = @w_return
				goto   ERROR
			end
			
			
			select @w_id = @w_id + 1
		end
		
		if @w_error != 0 
		begin
			goto   ERROR
		end
	
	select  @w_transaccion = 'S'
	begin tran
	update cob_credito..cr_tramite
    set tr_plazo = @w_plazo_padre
    where tr_tramite in (select op_tramite from #temp_op_modificar)
	
	if @@error <> 0
    begin
        select @w_error = 2110396
        goto   ERROR
    end
	
	update cob_cartera..ca_operacion
	set op_tasa_cap = @w_tea_padre,
	    op_valor_cat = @w_tir_padre
	where op_ref_grupal = @w_banco_padre
	
	if @@error <> 0
    begin
		select @w_error = 2110396
		goto ERROR
    end
    
    --DMO SE ACTUALIZA OPERACION PADRE
    exec @w_return =  cob_credito..sp_actualiza_grupal
        @i_banco        = @w_banco_padre  ,
        @i_tramite      =  @w_tramite_padre,
        @i_desde_cca    = 'C'
    if @w_return != 0 
    begin
        select @w_error = @w_return
        goto   ERROR
    end
	commit tran
	select  @w_transaccion = 'N'
END
--FIN DMO SE ACTUALIZA OPERACIONES HIJAS

--DMO PASA A DEFINITIVAS OPERACION
IF(@i_operacion = 'F' and @w_tr_tipo != 'L')
BEGIN 

    select
    @w_operacionca      = op_operacion,
    @w_banco            = op_banco,
    @w_monto            = op_monto
    from cob_cartera..ca_operacion with (nolock)
    where op_tramite      = @i_tramite
    
    if(@w_operacionca is null or @w_banco is null)
    begin
        select @w_error = 2110180
        goto   ERROR
    end
    
    if exists(select 1 from cob_cartera..ca_operacion_tmp with (nolock) where opt_operacion = @w_operacionca)
    begin
        --DMO
        select  @w_transaccion = 'S'
        begin tran
        
        exec    @w_return = cob_cartera..sp_pasodef
                @i_banco            = @w_banco,
                @i_operacionca      = 'S',
                @i_dividendo        = 'S',
                @i_amortizacion     = 'S',
                @i_cuota_adicional  = 'S',
                @i_rubro_op         = 'S',
                @i_relacion_ptmo    = 'S',
                @i_nomina           = 'S',
                @i_acciones         = 'S',
                @i_valores          = 'S'   
                    
        if @w_return != 0 
        begin
            select @w_error = @w_return
            goto   ERROR
        end
        
        exec    @w_return = cob_cartera..sp_borrar_tmp
                @s_user       = @s_user,
                 --@s_sesn       = @s_sesn,
                @s_term       = @s_term,
                @i_desde_cre  = 'S',
                @i_banco      = @w_banco
        
        if @w_return != 0 
        begin
            select @w_error = @w_return
            goto   ERROR
        end
        
        if @i_pasa_tmp = 'S' or @i_pasa_tmp is null
        begin
           --creacion de temporales
           exec    @w_return     = cob_cartera..sp_pasotmp
                   @s_user            = @s_user,
                   @s_term            = @s_term,
                   @i_banco           = @w_banco,
                   @i_operacionca     = 'S',
                   @i_dividendo       = 'S',
                   @i_amortizacion    = 'S',
                   @i_cuota_adicional = 'S',
                   @i_rubro_op        = 'S',
                   @i_relacion_ptmo   = 'S',
                   @i_nomina          = 'S',
                   @i_acciones        = 'S',
                   @i_valores         = 'S'
                   
           if @w_return != 0 
           begin
               select @w_error = @w_return
               goto   ERROR
           end
        end
    end

END

--DMO ACTUALIZA OPERACION PADRE
IF(@i_operacion = 'P' and @w_tr_tipo != 'L')
BEGIN 
     
    select @w_tramite_padre = tg_tramite  
    from cob_credito..cr_tramite_grupal with (nolock)
    inner join
    cob_cartera..ca_operacion with (nolock)
    on tg_operacion = op_operacion 
    where op_tramite = @i_tramite --DMO TRAMITE HIJO


    if(@w_tramite_padre is not null)
    BEGIN 
        select  @w_banco_padre = op_banco  
        from cob_cartera..ca_operacion with (nolock)
        where op_tramite = @w_tramite_padre 
    
        
        --DMO
        select  @w_transaccion = 'S'
        begin tran
        
        --DMO SE ACTUALIZA OPERACION PADRE
        exec @w_return =  cob_credito..sp_actualiza_grupal
            @i_banco        = @w_banco_padre  ,
            @i_tramite      =  @w_tramite_padre,
            @i_desde_cca    = 'N'
        if @w_return != 0 
        begin
            select @w_error = @w_return
            goto   ERROR
        end
    END 

END

if(@w_transaccion = 'S') commit tran

return 0

ERROR:
   if(@w_transaccion = 'S') rollback tran
   exec cobis..sp_cerror
   @t_debug='N',@t_file='',
   @t_from =@w_sp_name, @i_num = @w_error
   return @w_error
GO