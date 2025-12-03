/************************************************************************/
/*	Archivo:               crea_renovacion.sp                           */
/*	Stored procedure:	   sp_crea_renovacion                           */
/*	Base de datos:         cob_cartera                                  */
/*	Producto: 		       Credito y Cartera                            */
/*	Disenado por:          I.Yupa                                       */
/*	Fecha de escritura:	03/05/2017                                      */
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
/* sp creado con la finalidad de realizacion el proceso de renovacion,  */
/* y deembolso de la operacion renovada                                 */
/************************************************************************/
/*				MODIFICACIONES                                          */
/*	FECHA		   AUTOR		      RAZON                             */
/*  03/05/2017	Ignacio Yupa 	Emision inicial                         */
/*  20/04/2019  Luis Barron     Adecuacion de proceso de renoacion      */
/*  27/06/2019  Adriana Giler   Enviar Oficina en creacion Operacion    */
/*  30/Jul/2019 Luis Ponce      Forma de Pago Debito Cuenta Ahorros     */
/*  27/08/2019  Adriana Giler   Calculo correcto de Valores a renovar   */
/*  11/Jun/2020 Luis Ponce      CDIG Multimoneda                        */
/*  17/Jul/2020 Luis Ponce      CDIG Nuevos campos Pantalla Renovaciones*/
/*  15/Oct/2020 P.Narvaez       Correcion tipo de plazo                 */
/* 06/Ene/2021   P.Narvaez  Tipo de Reestructuracion/Tipo Renovacion    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crea_renovacion')
	drop proc sp_crea_renovacion
go


create proc sp_crea_renovacion ( 
   @s_user                 login       = null,
   @s_date                 datetime    = null,
   @s_ofi                  smallint    = null,
   @s_term                 varchar(30) = null, 
   @s_ssn                  int         = null,
   @s_sesn                 int         = null,
   @s_srv			         varchar(30) = NULL,
   @s_lsrv			         varchar(30) = NULL, 
   @t_debug                char(1)  	='N',
   @t_file                 varchar(14) = null,
   @t_from	               descripcion = null,
   @i_operacion            char(2)     = null,
   @i_operacionesA         varchar(500)= '',
   @i_operacionesB         varchar(500)= '',
   @i_operacionesC         varchar(500)= '',
   @i_operacionesD         varchar(500)= '',
   @i_toperacion           catalogo 	= null,
   @i_saldo_renovar        money       = null,
   @i_plazo                smallint 	= null,
   @i_tplazo               catalogo 	= null,
   @i_moneda               smallint    = null,   
   @i_ente                 int         = null,
   @i_forma_pago           catalogo    = null,
   @i_cuenta_banco         cuenta      = null,   
   @i_tipo_cuota           catalogo    = null,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_periodo_cap          catalogo    = null,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_periodo_int          catalogo    = null,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_dia_fijo             CHAR(1)     = null,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_dia_pago             INT         = null,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_per_gracia_cap       INT         = null,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_per_gracia_int       INT         = null,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_forma_cobro_gracia   CHAR(1)     = null,   --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones (En primera cuota, cutas restantes o periodos muertos)
   @i_tipo_renovacion      char(1)     = 'R',    --R: Renovacion, puede haber otro tipo de renovacion por ejemplo F: Refinanciamiento, etc.
   @o_banco_generado       cuenta      = null out,
   @o_tramite_generado     int         = null out
)
as
declare
@w_sp_name        varchar(30),
@w_return         int,
@w_tramite        int,
@w_operaciones    varchar(8000),
@w_operacionesValidar varchar(8000),
@w_k              smallint,
@w_banco          cuenta,
@w_largo_trama    smallint,
@w_sc             char(1),
@w_op_banco       cuenta,
@w_saldo          money,
@w_operacionca    int,
@w_msg            varchar(100),
@w_estado_operacion           tinyint,
@w_fecha_ult_proceso          datetime,
@w_estado_fin                 tinyint,
@w_num_dec                    tinyint,
@w_moneda_n                   tinyint,
@w_moneda_op_ant              INT, --LPO CDIG Multimoneda
@w_num_dec_mn                 tinyint,
@w_nomlar                     varchar(100),
@w_saldo_liquidar			money,
@w_op_cuenta				varchar(30),
@w_oficial						int,
@w_cod_tipo_plazo		char(1),
@w_op_banco_tmp		varchar(20),
@w_forma_pago			varchar(100),
@w_sector           catalogo,
@w_ciudad           int,    
@w_destino          catalogo,
@w_clase            catalogo,
@w_origen_fondos    catalogo,
@w_fondos_propios   char(1),
@w_tipo_empresa     catalogo,
@w_banca            catalogo,
@w_periodo_cap      smallint,
@w_periodo_int      smallint,
@w_operacion        cuenta,
@w_ndah_finan       catalogo

select @w_sp_name = 'sp_crea_renovacion'

-- MANEJO DE DECIMALES
exec @w_return = sp_decimales
     @i_moneda       = @i_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_mn out
	 
--Se valida el tipo de plazo que se manda
select @w_cod_tipo_plazo = td_tdividendo
from cob_cartera..ca_tdividendo where td_tdividendo = @i_tplazo
if @w_cod_tipo_plazo is null
	select @i_tplazo = 'M'
else
	select @i_tplazo = @w_cod_tipo_plazo
	

--LPO TEC Forma de pago Debito en Cuenta
select @w_ndah_finan = pa_char
from cobis..cl_parametro
where pa_nemonico = 'DEBCTA'
and pa_producto = 'CCA'

if @@rowcount = 0 
   RETURN 201196

--Se obtiene la forma de pago
select @w_forma_pago = isnull(pa_char,@w_ndah_finan) --'NDAH_FINAN')
from cobis..cl_parametro
where pa_producto = 'CCA' and pa_nemonico = 'RENOV0'

--Obtener Datos de la Operación a RENOVAR

select @w_oficial        = op_oficial,
       @w_sector         = op_sector,
       @w_ciudad         = op_ciudad,
       @w_destino        = op_destino,
       @w_clase          = op_clase,
       @w_origen_fondos  = op_origen_fondos,
       @w_fondos_propios = op_fondos_propios,
       @w_tipo_empresa   = op_tipo_empresa,
       @w_banca          = op_banca,
       @w_periodo_cap    = op_periodo_cap,
       @w_periodo_int    = op_periodo_int
from ca_operacion
where op_banco = @i_operacionesA


if @i_operacion = 'I'
begin   
   select @w_tramite = 0
   select @w_sc = ','
   select @w_operaciones = @i_operacionesA + @i_operacionesB + @i_operacionesC + @i_operacionesD
   select @w_operacionesValidar = @i_operacionesA + @i_operacionesB + @i_operacionesC + @i_operacionesD
   select @w_largo_trama = len(@w_operaciones)   
   
   if @w_largo_trama > 0
   begin
      select @w_k           = charindex (@w_sc, @w_operaciones)
      while @w_k > 0 
      begin
         select @w_banco       = substring(@w_operaciones, 1, @w_k - 1)
         select @w_operaciones = substring(@w_operaciones, @w_k+1, @w_largo_trama)
         select @w_k  = charindex (@w_sc, @w_operaciones)
                  
         select @w_operacionca = op_operacion,
                @w_oficial        = op_oficial,
                @w_sector         = op_sector,
                @w_ciudad         = op_ciudad,
                @w_destino        = op_destino,
                @w_clase          = op_clase,
                @w_origen_fondos  = op_origen_fondos,
                @w_fondos_propios = op_fondos_propios,
                @w_tipo_empresa   = op_tipo_empresa,
                @w_banca          = op_banca,
                @w_periodo_cap    = op_periodo_cap,
                @w_periodo_int    = op_periodo_int,
                @w_moneda_op_ant  = op_moneda --LPO CDIG Multimoneda
         
         from ca_operacion
         where op_banco = @w_banco
         
         if @w_tramite = 0  --Crear Tramite
         begin
            exec @w_return = cob_credito..sp_tramite_cca 
                  @s_ssn                = @s_ssn, 
                  @s_user               = @s_user,
                  @s_sesn               = @s_ssn, 
                  @s_term               = @s_term,
                  @s_date               = @s_date, 
                  @s_srv                = @s_srv,
                  @s_lsrv               = @s_lsrv,
                  @s_ofi                = @s_ofi,
                  @t_trn                = 21020,
                  @i_oficina_tr         = @s_ofi,
                  @i_usuario_tr         = @s_user,
                  @i_fecha_crea         = @s_date, 
                  @i_oficial            = @w_oficial,
                  @i_sector             = @w_sector,
                  @i_ciudad             = @w_ciudad,  
                  @i_fecha_apr          = @s_date, 
                  @i_usuario_apr        = @s_user,      
                  @i_toperacion         = @i_toperacion,
                  @i_producto           = 'CCA',
                  @i_monto              = @i_saldo_renovar, 
                  @i_tipo               = 'R',
                  @i_moneda             = @i_moneda, 
                  @i_periodo            = @i_tplazo,
                  @i_num_periodos       = 0,
                  @i_destino            = @w_destino,
                  @i_ciudad_destino     = @w_ciudad,
                  @i_cliente            = @i_ente, 
                  @i_clase              = @w_clase,
                  @i_monto_mn           = @i_saldo_renovar, 
                  @i_monto_des          = @i_saldo_renovar,
                  @o_tramite            = @w_tramite out   
                  
                 if @w_return <> 0
                 begin
                     select @w_msg = 'Error al momento de crear tramite de renovación'
                     goto ERROR         
                 end
         end
         
         
         select @w_saldo = 0
         
         --AGI. Obtener saldo real para cancelar la operacion 
         exec sp_calcula_saldo
         @i_operacion          = @w_operacionca,
         @i_renovacion         = 'S',
         @o_saldo             = @w_saldo out
    
    
         exec @w_return = cob_credito..sp_op_renovar
         @t_trn                = 21130,
         @s_date               = @s_date,
         @s_user               = @s_user, 
         @s_term               = @s_term,
         @s_ofi                = @s_ofi,
         @s_lsrv               = @s_lsrv,
         @s_srv                = @s_srv,
         @s_ssn                = @s_ssn,
         @i_operacion          = 'I',
         @i_tramite            = @w_tramite, 
         @i_num_operacion      = @w_banco, 
         @i_abono              = 0,
         @i_moneda_abono       = @i_moneda,        -- LPO CDIG Multimoneda--0
         @i_moneda_original    = @w_moneda_op_ant, -- LPO CDIG Multimoneda--0         
         @i_saldo_original     = @w_saldo, 
         @i_producto           = "CCA"
            
         if @w_return <> 0
         begin
            select @w_msg = 'Error al momento de sp_op_renovar renovación'
            goto ERROR            
         end
      end 
   end 

   exec @w_return = cob_cartera..sp_ren_autoriza
   @s_date     = @s_date, 
   @s_term     = @s_term,
   @s_ofi      = @s_ofi,
   @i_tramite  = @w_tramite, 
   @i_usuario  = @s_user,
   @t_trn      = 7979
   
   if @w_return <> 0
   begin
      select @w_msg = 'Error al momento de sp_ren_autoriza renovación'
      goto ERROR 
   end
   
   SELECT @w_nomlar = en_nomlar FROM cobis..cl_ente WHERE en_ente = @i_ente
       
   --CREACION OPERACION RENOVAR
   exec @w_return = cob_cartera..sp_crear_operacion
	@s_user                 = @s_user,
	@s_sesn                 = @s_sesn,
	@s_term                 = @s_term,
	@s_date                 = @s_date,
    @s_ofi                  = @s_ofi,
	@i_cliente              = @i_ente,
	@i_nombre               = @w_nomlar,
	@i_toperacion           = @i_toperacion,
	@i_oficina              = @s_ofi,
	@i_moneda               = @i_moneda, -- LPO CDIG Multimoneda --0,
	@i_comentario           = 'RENOVACION',
	@i_oficial              = @w_oficial,
	@i_fecha_ini            = @s_date,
	@i_monto                = @i_saldo_renovar,
	@i_monto_aprobado       = @i_saldo_renovar,
	@i_destino              = @w_destino,
	@i_ciudad               = @w_ciudad,
	@i_forma_pago           = @w_forma_pago,
	@i_cuenta               = @i_cuenta_banco,
	@i_formato_fecha        = 103,
	@i_clase_cartera        = @w_clase,
	@i_origen_fondos        = @w_origen_fondos,
	@i_fondos_propios       = @w_fondos_propios ,
	@i_tipo_empresa         = @w_tipo_empresa,
	@i_batch_dd             = 'N',
	@i_reestructuracion     = 'N',
	@i_banca                = @w_banca,
	@i_plazo                = @i_plazo,
	@i_tplazo               = @i_tplazo,	
	@i_tdividendo           = @i_tipo_cuota,  --@i_tplazo,      --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
	@i_periodo_cap          = @i_periodo_cap, --@w_periodo_cap, --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
	@i_periodo_int          = @i_periodo_int, --@w_periodo_int, --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_fecha_fija           = @i_dia_fijo,    --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_dia_pago             = @i_dia_pago,    --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_gracia_cap           = @i_per_gracia_cap,     --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_gracia_int           = @i_per_gracia_int,     --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_dist_gracia          = @i_forma_cobro_gracia, --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones     	
	@i_en_linea		         = 'S',
	@i_sector               = @w_sector,
   @i_tramite              = @w_tramite,
   @i_tipo_renovacion      = @i_tipo_renovacion,
	@o_banco                = @w_op_banco output
    
   if @w_return <> 0
   begin
   print '4.@s_ofi == ' + cast(@s_ofi as varchar)
      select @w_msg = 'Error al momento de sp_crear_operacion renovación'
      goto ERROR       
   end
   
   exec @w_return = sp_operacion_def
   @s_date   = @s_date,
   @s_sesn   = @s_ssn,
   @s_user   = @s_user,
   @s_ofi    = @s_ofi,
   @i_banco  = @w_op_banco  
   
   if @w_return <> 0
   begin
      select @w_msg = 'Error al momento de sp_operacion_def renovación'
      goto ERROR      
   end

   update cob_cartera..ca_operacion 
   set op_fecha_ult_proceso = @s_date,
       op_estado = 0,
	   op_tramite = @w_tramite
   where op_banco = @w_op_banco   
   if @@error <> 0
   begin
      select @w_msg = 'Error al momento de actualizar operación renovación',
             @w_return = @@error
      goto ERROR
   end
       
   update cob_credito..cr_tramite 
   set tr_estado = 'A',
   tr_numero_op_banco = @w_op_banco
   where tr_tramite = @w_tramite
   if @@error <> 0
   begin
      select @w_msg = 'Error al momento de actualizar tramite de renovación',
             @w_return = @@error
      goto ERROR
   end
   
      
   exec @w_return = sp_renovacion
   @s_ssn           = @s_ssn,
   @s_sesn          = @s_sesn,
   @s_date          = @s_date,
   @s_user          = @s_user,
   @s_term          = @s_term,
   @s_ofi           = @s_ofi,
   @i_banco         = @w_op_banco, -- OBLIGACION NUEVA
   @i_detalledes    = 'S',
   @i_verificar     = 'N',
   @i_valor_renovar = @i_saldo_renovar,
   @i_forma_pago    = @i_forma_pago,
   @i_cuenta_banco  = @i_cuenta_banco,
   --@i_moneda        = @i_moneda, -- LPO CDIG Multimoneda
   @o_banco_generado =  @o_banco_generado out
   if @w_return <> 0
   begin
      select @w_msg = 'Error al momento de sp_renovacion renovación ' + cast(@w_return as varchar)
      goto ERROR
   end


	-- FBO Num tramite
	select @o_tramite_generado = op_tramite from ca_operacion where op_banco = @o_banco_generado

	select @w_estado_operacion  = op_estado,
		   @w_fecha_ult_proceso = op_fecha_ult_proceso
	from   ca_operacion, cob_credito..cr_tramite
	where  op_banco   = @o_banco_generado
	and    op_tramite is not null
	and    op_tramite = tr_tramite   

	
   --VALIDACION ESTADOS DE CREACION
   exec @w_return = sp_estado_renreest
      @s_date             = @w_fecha_ult_proceso,           
      @i_operacion        = 'R',   
      @i_tipo             = 'R',      
      @i_operaciones       = @w_operacionesValidar,
      @o_estado           = @w_estado_fin out
   
   if @w_return <> 0 
   begin
      select @w_msg = 'Error al momento de ejecutar sp_estado_renreest renovación'
      goto ERROR   
   end
   
   
   if @w_estado_fin <> @w_estado_operacion
   begin
      exec @w_return = sp_cambio_estado_op
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_ofi            = @s_ofi,
      @i_banco          = @o_banco_generado,
      @i_fecha_proceso  = @w_fecha_ult_proceso,
      @i_estado_ini     = @w_estado_operacion, 
      @i_estado_fin     = @w_estado_fin,
      @i_tipo_cambio    = 'M',
      @i_en_linea       = 'N'

      if @w_return <> 0 
      begin
         select @w_msg = 'Error al momento de ejecutar sp_cambio_estado_op renovación'
         goto ERROR  
      end      
   end

   
end

return 0

ERROR:

exec cobis..sp_cerror
            @t_debug  = 'N',         
            @t_file   = null,
            @t_from   = @w_sp_name,   
            @i_num    = @w_return,
            @i_msg    = @w_msg
            
return @w_return

go
