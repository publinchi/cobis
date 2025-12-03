/************************************************************************/
/*	Archivo: 	        modvalor.sp                                     */ 
/*	Stored procedure:       sp_modvalor                                 */ 
/*	Base de datos:  	cob_custodia				                    */
/*	Producto:               garantias               		            */
/*	Disenado por:           					                        */
/*	Fecha de escritura:     Abril-1997  				                */
/************************************************************************/
/*				IMPORTANTE				                                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	"MACOSA", representantes exclusivos para el Ecuador de la 	        */
/*	"NCR CORPORATION".						                            */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/
/*				PROPOSITO				                                */
/*	Este programa se encargara  insertar en las tablas utilizadas       */
/*      para la contabilizacion cu_transaccion y cu_det_trn un          */
/*      debito o un crdito                                              */
/************************************************************************/
/*				MODIFICACIONES				                            */
/*	FECHA		AUTOR		      RAZON		                            */
/*	Mayo-1998       Laura Alvarado	      Emision Inicial         	    */	
/*      Oct-2002        Luis Alfredo Z.	      Parametro tipo Garantia   */
/************************************************************************/

use cob_custodia
go
if exists (select 1 from sysobjects where name = 'sp_modvalor')
    drop proc sp_modvalor
go
create proc sp_modvalor (
   @s_date               datetime   = null,
   @s_term               descripcion = null,  
   @s_ofi                smallint   = null,
   @s_user               login      = null,
   @i_usuario            login      = null,
   @i_terminal           login      = null,
   @i_operacion          char(1)    = null,
   @i_filial             tinyint    = null,
   @i_sucursal           smallint   = null,
   @i_tipo_cust          varchar(64)= null,
   @i_custodia           int        = null,
   @i_fecha_tran         datetime,
   @i_debcred            char(1)    = null,
   @i_valor              float = 0,
   @i_num_acciones       float = 0,
   @i_valor_accion       money = 0,
   @i_valor_cobertura    float = 0,
   @i_descripcion        varchar(64) = null,
   @i_autoriza           varchar(25) = null,	--NVR1
   @i_batch              char(1)     = null,
   @i_nuevo_comercial    money = 0,
   @i_recuperacion       char(1)  = null,
   @i_tipo_superior      varchar(64) = null,
   @i_codigo_valor       int = null, --emg si llamado de modvalor desde otro sp para distribucion
   @i_perfil             catalogo = null,
   @i_agotada            char(1) = null,
   @i_viene_activgar     char(1) = null,
   @i_banderabe          char(1) = null, --CAV Req 371 - Para controlar errores en WS
   @i_codigo_externo     varchar(64),
   @i_afecta_prod        char(1) = 'N'
)
as

declare
   @w_today              datetime,
   @w_hora               varchar(8),
   @w_retorno            int,          /* valor que retorna           */
   @w_sp_name            varchar(32),  /* nombre stored proc          */
   @w_existe             tinyint,      /* existe el registro          */
   @w_perfil             catalogo,     /* perfil del cambio de estado */
   @w_contabiliza        char(1),      /* indica si se contabiliza    */
   @w_tran               catalogo,
   @w_error		         int,
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_descripcion        varchar(64),
   @w_contabilizar       char(1),
   @w_secuencial         int,
   @w_tsuperior          varchar(64),
   @w_tipo               varchar(64),
   @w_custodia           int,
   @w_valor_actual       float,		
   @w_valor_hip          money,
   @w_valor_com          money,
   @w_valor_con          money,
   @w_valor_fut          money,
   @w_valor_xcan         money,
   @w_codvalor           int,
   @w_codvalorx          int,
   @w_valor_compartida   money,
   @w_valor_aux          float,		
   @w_codigo_externo     varchar(64),
   @w_porcen_cobertura   float,
   @w_porcen_compartida  float,
   @w_valor              float,		
   @w_valor_cobertura    float,		
   @w_valor_accion       money,
   @w_num_acciones       float,		
   @w_estado             catalogo,
   @w_oficina_contabiliza smallint,
   @w_clase_custodia      char(1),
   @w_abierta_cerrada     char(1),
   @w_tipo_bien           char(1),
   @w_cuantia             char(1),		
   @w_compartida	      char(1),
   @w_valor_contable      money,
   @w_porcentaje	      float,
   @w_valor_compartido    money,
   @w_valor_recuperado    money,
   @w_monetaria		      char(1),
   @w_moneda		      tinyint,
   @w_agotada             char(1), --pga 10jul2001
   @w_estado_gar	      char(1),
   @w_fecha_ingreso       int,		
   @w_hoy  		          int,
   @w_c01                 varchar(30), ---LAZ
   @w_valor_respaldo      money,
   @w_clase_cartera       catalogo,
   @w_calificacion        char(1),
   @w_signo               smallint,
   @w_valor_contab        money,
   @w_clase_carterai      catalogo,
   @w_codigo_externo_rev  varchar(64),
   @w_secuencial_rev      int,
   @w_valor_anterior      money,
   @w_valor_nuevo         money,
   @w_valor_futuros       money,
   @w_sec_ini             int,           
   @w_sec_fin             int,
   @w_tramite             int,
   @w_return              int,
   @w_valor_original      money,
   @w_msg                 varchar(255),
   @w_porcentaje_resp     float,
   @w_porcentaje_para     float,
   @w_valor_resp_garantia money,
   @w_monto               money,
   @w_tipo_cust           varchar(64),
   @w_fag                 varchar(10),
   @w_estado_tr           char(1),
   @w_valor_inicial       money,
   @w_nuevo_comercial     money

select @w_sp_name = 'sp_modvalor'

select @w_today = convert(varchar(10),@s_date,101)

select @w_hora = convert(varchar(8),getdate(),108)

select @w_contabiliza = 'S'

select @w_valor_original = @i_nuevo_comercial --ADI USAID

select @w_tramite = 0

-- Parametro FAG        

select @w_fag = pa_char
from   cobis..cl_parametro
where  pa_producto = 'GAR'
and    pa_nemonico = 'CODFAG' 

if @i_nuevo_comercial < 0
   select @i_nuevo_comercial = 0

if @i_valor_accion < 0
   select @i_valor_accion = 0

if @i_valor_cobertura < 0
   select @i_valor_cobertura = 0

if @w_valor_cobertura < 0
   select @w_valor_cobertura = 0

if @w_valor_actual < 0
   select @w_valor_actual = 0

if @w_valor_nuevo < 0
   select @w_valor_nuevo = 0

if @w_valor_contable < 0
   select @w_valor_contable = 0

if @w_valor_compartida < 0
   select @w_valor_compartida = 0

if @w_valor_recuperado < 0
   select @w_valor_recuperado = 0

/***********************************************************/
/* Codigos de Transacciones                                */

if @i_operacion = 'I'
begin
   if @i_filial     is NULL or
      @i_fecha_tran is NULL or
      @i_debcred    is NULL or
      @i_valor      is NULL or
	 ((@i_sucursal   is NULL or
      @i_tipo_cust  is NULL or
      @i_custodia   is NULL) and
	  @i_codigo_externo is NULL)
   begin
      select @w_error = 1901001
        goto ERROR
   end

   if @i_codigo_externo is null
   begin
      select
      @w_filial                = cu_filial,
      @w_sucursal              = cu_sucursal,
      @w_tipo                  = cu_tipo,
      @w_custodia              = cu_custodia,
      @w_valor_actual          = isnull(cu_valor_inicial, 0),
      @w_valor_compartida      = cu_valor_compartida,
      @w_estado                = cu_estado,
      @w_oficina_contabiliza   = cu_oficina_contabiliza,
      @w_codigo_externo        = cu_codigo_externo,
      --@w_admisible           = cu_adecuada_noadec, emg feb-16-02
      @w_clase_custodia        = cu_clase_custodia,
      @w_abierta_cerrada       = cu_abierta_cerrada,
      @w_porcen_cobertura      = cu_porcentaje_cobertura,     
      @w_compartida	        = cu_compartida,
      @w_moneda		        = cu_moneda, 
      @w_agotada               = cu_agotada, --pga10jul2001
      @w_clase_carterai        = cu_clase_cartera
      from cu_custodia
      where cu_filial          = @i_filial
        and cu_sucursal        = @i_sucursal
        and cu_tipo            = @i_tipo_cust
        and cu_custodia        = @i_custodia

      if @@rowcount <> 1
      begin
         select @w_error = 1905002
         goto ERROR
      end
   end
   else
   begin
      select
      @w_filial                = cu_filial,
      @w_sucursal              = cu_sucursal,
      @w_tipo                  = cu_tipo,
      @w_custodia              = cu_custodia,
      @w_valor_actual          = isnull(cu_valor_inicial, 0),
      @w_valor_compartida      = cu_valor_compartida,
      @w_estado                = cu_estado,
      @w_oficina_contabiliza   = cu_oficina_contabiliza,
      @w_codigo_externo        = cu_codigo_externo,
      --@w_admisible           = cu_adecuada_noadec, emg feb-16-02
      @w_clase_custodia        = cu_clase_custodia,
      @w_abierta_cerrada       = cu_abierta_cerrada,
      @w_porcen_cobertura      = cu_porcentaje_cobertura,     
      @w_compartida	        = cu_compartida,
      @w_moneda		        = cu_moneda, 
      @w_agotada               = cu_agotada, --pga10jul2001
      @w_clase_carterai        = cu_clase_cartera
      from cu_custodia
      where cu_codigo_externo = @i_codigo_externo

	  if @@rowcount <> 1
      begin
         select @w_error = 1905002
         goto ERROR
      end
   end

   select @w_nuevo_comercial = @i_nuevo_comercial, @w_valor_cobertura = @i_valor_cobertura

   if @i_afecta_prod = 'S'
   begin
      if @i_debcred = 'D'  
	     select @w_nuevo_comercial = @w_valor_actual - @i_valor
	  else 
	     select @w_nuevo_comercial = @w_valor_actual + @i_valor

	  select @w_valor_cobertura = @w_nuevo_comercial
   end

   begin tran
   update cu_custodia

   set cu_valor_inicial      = @w_nuevo_comercial,
       cu_valor_actual       = @w_valor_cobertura,
       cu_fecha_modificacion = @s_date,
       cu_autoriza           = @i_autoriza
   where  cu_codigo_externo  = @w_codigo_externo

   if @@error <> 0 
   begin
   /* Error en insercion de registro */
      select @w_error = 1905001
      goto ERROR
   end

   -- Si la garantia esta como propuesta y asociada a un tramite
   select @w_tramite         = gp_tramite,
          @w_monto           = tr_monto,
          @w_porcentaje_resp = gp_porcentaje,
          @w_porcentaje_para = tc_porcen_cobertura,
          @w_estado_tr       = tr_estado
   from cob_credito..cr_gar_propuesta , cob_credito..cr_tramite, cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia
   where gp_garantia = @w_codigo_externo
   and   gp_tramite  = tr_tramite
   and   gp_garantia = cu_codigo_externo
   and   cu_tipo     = tc_tipo

   if @w_estado = 'P' or ( @w_estado_tr = 'D' and @w_estado = 'F') begin   
      if @w_tramite > 0 begin
         select tipo = tc_tipo
         into #fag
         from cob_custodia..cu_tipo_custodia
         where tc_tipo_superior = @w_fag

         if not exists (select 1 from #fag where tipo = @w_tipo) begin
            select @w_porcentaje_resp = (@i_nuevo_comercial * @w_porcentaje_para) / @w_monto
            select @w_valor_resp_garantia = @i_valor_cobertura
         end
         else begin
            select @w_valor_resp_garantia = (@i_nuevo_comercial * @w_porcentaje_resp) / 100
         end

         update cob_credito..cr_gar_propuesta
         set gp_porcentaje          = @w_porcentaje_resp,
             gp_valor_resp_garantia = @w_valor_resp_garantia
         where gp_garantia = @w_codigo_externo
      end
   end
   else begin
      -- Crear transaccion para Contabilizar por Cambio de Valor
      exec @w_error = cob_custodia..sp_transaccion
      @s_date           = @s_date,
      @s_user           = @i_usuario,
      @s_term           = @s_term,
      @i_codigo_externo = @w_codigo_externo,
      @i_tipo_tran      = 'VAL',
      @i_estado_gar     = @w_estado,
      @i_valor          = @i_nuevo_comercial,
      @i_valor_ant      = @w_valor_actual,
	  @i_banderabe      = @i_banderabe        --CAV Req 371 - Para controlar errores en WS

      if @w_error <> 0 begin
         select @w_msg =  'Error en creacion de transaccion contable'
         select    @w_error = 1910001
         goto ERROR
      end
   end

   commit tran
end  --Operacion 'I'

return 0

ERROR:
   return @w_error
go