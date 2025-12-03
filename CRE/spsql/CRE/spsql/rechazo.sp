/************************************************************************/
/*  Archivo:                rechazo.sp                                  */
/*  Stored procedure:       sp_rechazo                                  */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          jfescobar        Emision Inicial                  */
/*  07/04/22          pmoreno          Seteo @i_tipo_causal en caso de  */
/*                                     rechazo para actualizar estado de*/ 
/*                                     tramite                          */
/*  18/11/22          dmorales         Se añade logica para actualizar  */
/*                                     operaciones hijas                */ 
/*  27/11/24          GRomero          R246371 reachazo de solic estado 6*/
/*  05/05/25          dmorales         R268732 Rechazo de op hijas      */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_rechazo')
    drop proc sp_rechazo
go

create proc sp_rechazo(
   @s_ssn               int          = null,
   @s_user              Varchar (14) = null,
   @s_term              varchar(64)  = null,
   @s_date              datetime     = null,
   @s_ofi               smallint     = null,
   /**** LC Req 368 26/08/2013****/
   @s_lsrv              varchar(30)  = null,
   @s_srv               varchar(30)  = null,
   @t_debug             char(1)      = 'N',
   @t_file              varchar(14)  = null,
    /**** LC Req 368 26/08/2013****/
   @i_tramite           int          = null,
   @i_etapa             tinyint      = null,
   @i_estacion          smallint     = null,
   @i_observaciones     varchar(255) = null,
   @i_producto          varchar(10)  = null,
   @i_tipo_causal       char(1)      = null,
   @i_tipo_tramite      char(1)      = null,
   @i_etapa_actual      tinyint      = null
)
as

declare
   @w_today             datetime,     /* FECHA DEL DIA      */
   @w_sp_name           varchar(32),  /* NOMBRE STORED PROC */
   @w_msg               varchar(140),
   @w_commit            char(1),
   @w_toperacion        varchar(10),
   @w_producto          varchar(10),
   @w_monto             money,
   @w_return            int,
   @w_secuencia          smallint,
   @w_fecha             datetime,
   @w_estado_novig       tinyint,
   @w_estado_anulado    tinyint,
   @w_salida            tinyint,
   @w_causal            varchar(10),
   @w_tcausal           varchar(10),
   @w_num_operacion     varchar(24),
   @w_error             int,
   @w_op_operacion      int,
   @w_rowcount          int,
   @w_cefinal           tinyint,
   @w_estado_inicial    char(1),      -- Estado inicial del trámite
   @w_fuente_recurso    char(10),     -- Fuente de Recurso del trámite
   @w_tipo_tr           char(1),
   @w_linea_cre         int,
   @w_om_monto          money,
   @w_om_utilizado      money,
   @w_om_reservado      money,
   @w_cliente           int,
   @w_desiste           char(1),       -- ADI: INC 14913
   @w_prod_credito      tinyint,       -- GAL 03/MAY/2011 - PAQ1 REQ 216/231
   @w_lin_credito       cuenta,         -- JAR REQ 215
   @w_op_estado         smallint,
   @w_max_sec           int,           -- LC Req 368 26/08/2013
   @w_tramite_org       int,
   @w_garantia          varchar(64),
   @w_tramite_gar       int,
   @w_tr_cliente        int,         -- Req. 422 IB
   @w_en_ced_ruc        numero,
   @w_en_tipo_ced       varchar(2),
   @w_version_max       int,
   @w_tr_estado         char(1),
   @w_mensaje           varchar(1000),
   @w_valorhra          char(1),
   @w_tr_mercado        catalogo,
   @w_tr_destino        catalogo,
   @w_tr_act_financiar  catalogo,
   @w_user              varchar(30),
   @w_rol               tinyint,
   @w_referencia        int,
   @w_estado            char(1),
   @w_op_banco          varchar(24),
   @w_estado_op         int, --R246371
   @w_estado_credito    tinyint  --R246371


/* INICIALIZACION DE VARIABLES */
select @w_fecha = getdate()
select @w_today = dateadd (ss,datepart(ss,@w_fecha),
                 (dateadd (mi,datepart(mi,@w_fecha),
                 (dateadd (hh,datepart(hh,@w_fecha),
                  convert (datetime, convert(varchar(10),@s_date,101)))))))


select
@w_sp_name      = 'sp_rechazo',
@w_commit       = 'N',
@w_prod_credito = 21        -- GAL 03/MAY/2011 - PAQ1 REQ 216/231

if (@i_tipo_causal is null) --PMO
begin
	select @i_tipo_causal = 'Z'
end

select @w_tcausal = null
select @w_causal  = 'DEFAULT' --null
select @w_desiste = 'N'               -- ADI: INC 14913

select
@w_cefinal = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'CEF'
and   pa_producto = 'CRE'


/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_tramite is null
begin
   /* CAMPOS NOT NULL CON VALORES NULOS */
   select @w_error = 2101001
   goto ERROR
end


select @w_op_banco  = op_banco, 
       @w_estado_op = op_estado --R246371
from cob_cartera..ca_operacion where op_tramite = @i_tramite

select @w_estado_credito = pa_tinyint --R246371
from  cobis..cl_parametro
where pa_nemonico ='ESTCRE'
and   pa_producto = 'CRE'
if @w_rowcount = 0
begin
   /* No existe valor de parametro */
   select @w_error = 2101084
   goto ERROR
end
--------------------------------------------------------------------
--SRA: Toma el estado inicial del tramite a ser rechazado
--Unicamente los tramites en estado 'A': Aprobados y 'D' : Devueltos
-- actualizan montos reservados y saldos de las Fuentes de Recursos
---------------------------------------------------------------------
select @w_estado_inicial = tr_estado,
       @w_fuente_recurso = tr_fuente_recurso,
       @w_monto          = tr_monto,
       @w_tipo_tr        = tr_tipo,
       @w_producto       = tr_producto,
       @w_toperacion     = tr_toperacion,
       @w_linea_cre      = tr_linea_credito ,
       @w_cliente        = tr_cliente
from   cr_tramite
where  tr_tramite = @i_tramite


------------------------------------------------------------------------------------
/*                    INICIO REQUERIMIENTO 0173 PEQUEÑA EMPRESA                   */
/*RECHAZO DE TRAMITES DE CUPO PARA SER REACTIVADOS POSTERIORMENTE SI CABE EL CASO */
------------------------------------------------------------------------------------

if @i_tipo_causal = 'Z' and @i_tipo_tramite = 'C'  -- Definitivo
begin

   begin tran
   select @w_commit = 'S'

   update cr_tramite
   set    tr_estado = 'Z',
          tr_fecha_apr = @s_date
   where  tr_tramite = @i_tramite

   if @@error <> 0  begin
      select @w_error = 2105001
      goto ERROR
   end
   
   if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin
	
	    update cr_tramite 
        set    tr_estado = 'Z',
               tr_fecha_apr = @s_date
       from cr_tramite 
	   inner join cob_cartera..ca_operacion O on op_tramite = tr_tramite
	   where op_ref_grupal = @w_op_banco
		
      if @@error <> 0  begin
        select @w_error = 2105001
        goto ERROR
      end		
    end
   
   
   
   --------------------------------------------------------------------------------------------------------------------
   --FILTROS REQ: 164
   --LPO INICIO 07/Oct/2010

   --delete cr_valor_variables_filtros
   --where vv_ruta    = 0
   --  and vv_etapa   = 0
   --  and vv_ente    = @w_cliente

   --FILTROS REQ: 164
   --LPO FIN 07/Oct/2010
   --------------------------------------------------------------------------------------------------------------------

   update cob_credito..cr_ruta_tramite
   set rt_salida = @w_today
   where rt_tramite = @i_tramite
   and rt_salida is null

   if @@error <> 0 begin
      select @w_error = 2105001
      goto ERROR
   end

   update cr_linea
   set    li_estado    = 'A',
          li_num_banco = ''
   where li_tramite    = @i_tramite

   if @@error <> 0  begin
      select @w_error = 2105001
      goto ERROR
   end

   -- INI JAR Req. 151
   update cr_cliente_campana set
      cc_estado = 'V'
     from cr_tramite
    where tr_tramite = @i_tramite
      and cc_cliente = tr_cliente
      and cc_estado  = 'C'

   if @@error <> 0
   begin
      select @w_error = 2105001
      goto ERROR
   end
   -- FIN JAR Req. 151

  /* select @w_tcausal = cq_tipo
   from   cr_cau_etapa
   where  cq_tipo = 'NEG'
   and    cq_tipo_tramite = @i_tipo_tramite
   and    cq_etapa = @i_etapa_actual
   set transaction isolation level read uncommitted

   if @w_tcausal is null
   begin
      select @w_error = 2108011
      goto ERROR
   end*/

   select @w_causal = cr_requisito
   from   cr_cau_tramite
   where  cr_tramite = @i_tramite
   and    cr_etapa   = @i_etapa_actual
   and    cr_tipo    = 'NEG'

   if @w_causal is null
   begin
      select @w_error = 2108012
      goto ERROR
   end
 /* LC Req 368 26/08/2013 */
/****Insert tran servicio ****/

/* TRANSACCION DE SERVICIO REGISTRO ANTERIOR */
insert into ts_tramite (
   secuencial,                           tipo_transaccion,                       clase,
   fecha,                                usuario,                                terminal,
   oficina,                              tabla,                                  lsrv,
   srv,                                  tramite,                                tipo,
   oficina_tr,                           usuario_tr,                             fecha_crea,
   oficial,                              sector,                                 ciudad,
   estado,                               nivel_ap,                               fecha_apr,
   usuario_apr,                          truta,                                  numero_op,
   numero_op_banco,                      proposito,                              razon,
   txt_razon,                            efecto,                                 cliente,
   grupo,                                fecha_inicio,                           num_dias,
   per_revision,                         condicion_especial,                     linea_credito,
   toperacion,                           producto,                               monto,
   moneda,                               periodo,                                num_periodos,
   destino,                              ciudad_destino,                         cuenta_corriente,
   renovacion,                           rent_actual,                            rent_solicitud,
   rent_recomend,                        prod_actual,                            prod_solicitud,
   prod_recomend,                        clasecca,                               admisible,
   noadmis,                              relacionado,                            pondera,
   tipo_producto,                        origen_bienes,                          localizacion,
   plan_inversion,                       naturaleza,                             tipo_financia,
   forward,                              elegible,                               emp_emisora,
   num_acciones,                         responsable,                            negocio,
   reestructuracion,                     concepto_credito,                       aprob_gar,
   mercado_objetivo,                     tipo_productor,                         valor_proyecto,
   sindicado,                            margen_redescuento,                     asociativo,
   incentivo,                            fecha_eleg,                             fecha_redes,
   solicitud,                            montop,                                 montodesembolsop,
   mercado,                              carta_apr,                              fecha_aprov,
   fmax_redes,                           f_prorroga,                             sujcred,
   fabrica,                              callcenter,                             apr_fabrica,
   monto_solicitado,                     tipo_plazo,                             tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito,						 alterno)
   select
	 @s_ssn,                             21120,                                  'P',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite,      							tr_tipo,
   tr_oficina,                           tr_usuario,      							tr_fecha_crea,
   tr_oficial,                           tr_sector, 	  							tr_ciudad,
   tr_estado, /*'Z',*/    				 tr_nivel_ap,							    tr_fecha_apr,
   tr_usuario_apr,   					 tr_truta, 								  tr_numero_op,
   tr_numero_op_banco, 					 tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                             tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion, 						 tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   --tr_num_acciones,                    tr_responsable,                          tr_negocio,
   tr_num_acciones,    					 tr_responsable,                          tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,       					 tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg,     			          tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito,						 1
   from cr_tramite
   where tr_tramite = @i_tramite

      if @@error <> 0
   begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2103003
      return 2103003
   end



		   /* TRANSACCION DE SERVICIO REGISTRO ACTUAL */
   insert into ts_tramite (
   secuencial,                           tipo_transaccion,                       clase,
   fecha,                                usuario,                                terminal,
   oficina,                              tabla,                                  lsrv,
   srv,                                  tramite,                                tipo,
   oficina_tr,                           usuario_tr,                             fecha_crea,
   oficial,                              sector,                                 ciudad,
   estado,                               nivel_ap,                               fecha_apr,
   usuario_apr,                          truta,                                  numero_op,
   numero_op_banco,                      proposito,                              razon,
   txt_razon,                            efecto,                                 cliente,
   grupo,                                fecha_inicio,                           num_dias,
   per_revision,                         condicion_especial,                     linea_credito,
   toperacion,                           producto,                               monto,
   moneda,                               periodo,                                num_periodos,
   destino,                              ciudad_destino,                         cuenta_corriente,
   renovacion,                           rent_actual,                            rent_solicitud,
   rent_recomend,                        prod_actual,                            prod_solicitud,
   prod_recomend,                        clasecca,                               admisible,
   noadmis,                              relacionado,                            pondera,
   tipo_producto,                        origen_bienes,                          localizacion,
   plan_inversion,                       naturaleza,                             tipo_financia,
   forward,                              elegible,                               emp_emisora,
   num_acciones,                         responsable,                            negocio,
   reestructuracion,                     concepto_credito,                       aprob_gar,
   mercado_objetivo,                     tipo_productor,                         valor_proyecto,
   sindicado,                            margen_redescuento,                     asociativo,
   incentivo,                            fecha_eleg,                             fecha_redes,
   solicitud,                            montop,                                 montodesembolsop,
   mercado,                              carta_apr,                              fecha_aprov,
   fmax_redes,                           f_prorroga,                             sujcred,
   fabrica,                              callcenter,                             apr_fabrica,
   monto_solicitado,                     tipo_plazo,                             tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito,						 alterno)

   select
	 @s_ssn,                               21120,                                  'N',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite,  								tr_tipo,
   tr_oficina,                           tr_usuario,  								tr_fecha_crea,
   tr_oficial,                           tr_sector, 								tr_ciudad,
   @i_tipo_causal,       				 tr_nivel_ap,							    tr_fecha_apr,
   tr_usuario_apr,   					 tr_truta, 								  tr_numero_op,
   tr_numero_op_banco, 					 tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                             tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion, 						 tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   --tr_num_acciones,                    tr_responsable,                          tr_negocio,
   tr_num_acciones,    					 tr_responsable,                          tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,       					 tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg, 				          tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito,						 1
   from cr_tramite
   where tr_tramite = @i_tramite

      if @@error <> 0
   begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2103003
      return 2103003
   end

		 select @w_max_sec = MAX(secuencial)
		 from ts_tramite
		 where tramite =  @i_tramite



  /* LC Req 368 26/08/2013 */


   if @w_commit = 'S' commit tran
   return 0
end
------------------------------------------------------------------------------------
/*                    FIN REQUERIMIENTO 0173 PEQUEÑA EMPRESA                      */
/*RECHAZO DE TRAMITES DE CUPO PARA SER REACTIVADOS POSTERIORMENTE SI CABE EL CASO */
------------------------------------------------------------------------------------


/* VALIDACIONES PARA CAUSALES ESP. CD00020 BCO. AGRARIO */
/********************************************************/
if @i_tipo_causal = 'A'  -- Aplazamiento
begin
  /* select @w_tcausal = cq_tipo
   from   cr_cau_etapa
   where  cq_tipo     = 'APL'
   and    cq_tipo_tramite = @i_tipo_tramite
   and    cq_etapa    = @i_etapa_actual
   set transaction isolation level read uncommitted

   if @w_tcausal is null
   begin
      select @w_error = 2108011
      goto ERROR
   end
*/
   select @w_causal = cr_requisito
   from   cr_cau_tramite
   where  cr_tramite = @i_tramite
   and    cr_etapa   = @i_etapa_actual
   and    cr_tipo    = 'APL'

   if @w_causal is null
   begin
      select @w_error = 2108012
      goto ERROR
   end
end

if @i_tipo_causal = 'D'  -- Devolucion
begin
  /* select @w_tcausal = cq_tipo
   from   cr_cau_etapa
   where  cq_tipo = 'DEV'
   and    cq_tipo_tramite = @i_tipo_tramite
   and    cq_etapa = @i_etapa_actual
   set transaction isolation level read uncommitted

   if @w_tcausal is null
   begin
      select @w_error = 2108011
      goto ERROR
   end
*/
   select @w_causal = cr_requisito
   from   cr_cau_tramite
   where  cr_tramite = @i_tramite
   and    cr_etapa   = @i_etapa_actual
   and    cr_tipo    = 'DEV'

   if @w_causal is null
   begin
      select @w_error = 2108012
      goto ERROR
   end

end

begin tran
select @w_commit = 'S'

if @i_tipo_causal = 'Z'  -- Definitivo
begin

   update cr_tramite
   set    tr_estado = 'Z'
   where  tr_tramite = @i_tramite

   if @@error <> 0  begin
      select @w_error = 2105001
      goto ERROR
   end
   
    if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin
	
	    update cr_tramite
        set    tr_estado = 'Z',
               tr_fecha_apr = @s_date
       from cr_tramite
	   inner join cob_cartera..ca_operacion  on op_tramite = tr_tramite
	   where op_ref_grupal = @w_op_banco
		
      if @@error <> 0  begin
        select @w_error = 2105001
        goto ERROR
      end		
    end
   --------------------------------------------------------------------------------------------------------------------
   --FILTROS REQ: 164
   --LPO INICIO 07/Oct/2010

   --delete cr_valor_variables_filtros
   --where vv_ruta    = 0
   --  and vv_etapa   = 0
   --  and vv_ente    = @w_cliente

   --FILTROS REQ: 164
   --LPO FIN 07/Oct/2010
   --------------------------------------------------------------------------------------------------------------------

   update cr_tramite
   set    tr_fecha_apr = getdate()
   where  tr_tramite = @i_tramite
   and    tr_fecha_apr is null

   if @@error <> 0  begin
      select @w_error = 2105001
      goto ERROR
   end

   -- INI JAR Req. 151
   update cr_cliente_campana set
      cc_estado = 'V'
     from cr_tramite
    where tr_tramite = @i_tramite
      and cc_cliente = tr_cliente
      and cc_estado  = 'C'

   if @@error <> 0
   begin
      select @w_error = 2105001
      goto ERROR
   end
   -- FIN JAR Req. 151

   /*select @w_tcausal = cq_tipo
   from   cr_cau_etapa
   where  cq_tipo = 'NEG'
   and    cq_tipo_tramite = @i_tipo_tramite
   and    cq_etapa = @i_etapa_actual
   set transaction isolation level read uncommitted

   if @w_tcausal is null
   begin
      select @w_error = 2108011
      goto ERROR
   end*/

   select @w_causal = cr_requisito
   from   cr_cau_tramite
   where  cr_tramite = @i_tramite
   and    cr_etapa   = @i_etapa_actual
   and    cr_tipo    = 'NEG'

   if @w_causal is null
   begin
      select @w_error = 2108012
      goto ERROR
   end

   -- MARCAR UTILIZACION DE CREDITOS ASOCIATIVOS
   exec @w_error  = sp_in_cupos_asoc
   @s_date  = @s_date,
   @i_operacion   = 'N',
   @i_tramite  = @i_tramite

   if @@error <> 0 or @w_error <> 0
   begin
      if @w_error is null select @w_error = 2101001
      goto ERROR
   end

   /****** LC Req 368 26/08/2013 *******/

		 /****Insert tran servicio ****/

		 /* TRANSACCION DE SERVICIO REGISTRO  */
   insert into ts_tramite (
   secuencial,                           tipo_transaccion,                       clase,
   fecha,                                usuario,                                terminal,
   oficina,                              tabla,                                  lsrv,
   srv,                                  tramite,                                tipo,
   oficina_tr,                           usuario_tr,                             fecha_crea,
   oficial,                              sector,                                 ciudad,
   estado,                               nivel_ap,                               fecha_apr,
   usuario_apr,                          truta,                                  numero_op,
   numero_op_banco,                      proposito,                              razon,
   txt_razon,                            efecto,                                 cliente,
   grupo,                                fecha_inicio,                           num_dias,
   per_revision,                         condicion_especial,                     linea_credito,
   toperacion,                           producto,                               monto,
   moneda,                               periodo,                                num_periodos,
   destino,                              ciudad_destino,                         cuenta_corriente,
   renovacion,                           rent_actual,                            rent_solicitud,
   rent_recomend,                        prod_actual,                            prod_solicitud,
   prod_recomend,                        clasecca,                               admisible,
   noadmis,                              relacionado,                            pondera,
   tipo_producto,                        origen_bienes,                          localizacion,
   plan_inversion,                       naturaleza,                             tipo_financia,
   forward,                              elegible,                               emp_emisora,
   num_acciones,                         responsable,                            negocio,
   reestructuracion,                     concepto_credito,                       aprob_gar,
   mercado_objetivo,                     tipo_productor,                         valor_proyecto,
   sindicado,                            margen_redescuento,                     asociativo,
   incentivo,                            fecha_eleg,                             fecha_redes,
   solicitud,                            montop,                                 montodesembolsop,
   mercado,                              carta_apr,                              fecha_aprov,
   fmax_redes,                           f_prorroga,                             sujcred,
   fabrica,                              callcenter,                             apr_fabrica,
   monto_solicitado,                     tipo_plazo,                             tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito,						 alterno)

   select
   @s_ssn,                               21120,                                  'P',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite,        											tr_tipo,
   tr_oficina,                           tr_usuario,        											tr_fecha_crea,
   tr_oficial,                           tr_sector, 	      											tr_ciudad,
   tr_estado, /*'Z',*/    											         tr_nivel_ap,													    tr_fecha_apr,
   tr_usuario_apr,   										 tr_truta, 															  tr_numero_op,
   tr_numero_op_banco, 								   tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                             tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion, 										   tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   --tr_num_acciones,                    tr_responsable,                          tr_negocio,
   tr_num_acciones,    					tr_responsable,                           tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,       									 tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg, 								          tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito,							2
   from cr_tramite
   where tr_tramite = @i_tramite

      if @@error <> 0
   begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2103003
      return 2103003
   end



		   /* TRANSACCION DE SERVICIO REGISTRO ACTUAL */
   insert into ts_tramite (
   secuencial,                           tipo_transaccion,                       clase,
   fecha,                                usuario,                                terminal,
   oficina,                              tabla,                                  lsrv,
   srv,                                  tramite,                                tipo,
   oficina_tr,                           usuario_tr,                             fecha_crea,
   oficial,                              sector,                                 ciudad,
   estado,                               nivel_ap,                               fecha_apr,
   usuario_apr,                          truta,                                  numero_op,
   numero_op_banco,                      proposito,                              razon,
   txt_razon,                            efecto,                                 cliente,
   grupo,                                fecha_inicio,                           num_dias,
   per_revision,                         condicion_especial,                     linea_credito,
   toperacion,                           producto,                               monto,
   moneda,                               periodo,                                num_periodos,
   destino,                              ciudad_destino,                         cuenta_corriente,
   renovacion,                           rent_actual,                            rent_solicitud,
   rent_recomend,                        prod_actual,                            prod_solicitud,
   prod_recomend,                        clasecca,                               admisible,
   noadmis,                              relacionado,                            pondera,
   tipo_producto,                        origen_bienes,                          localizacion,
   plan_inversion,                       naturaleza,                             tipo_financia,
   forward,                              elegible,                               emp_emisora,
   num_acciones,                         responsable,                            negocio,
   reestructuracion,                     concepto_credito,                       aprob_gar,
   mercado_objetivo,                     tipo_productor,                         valor_proyecto,
   sindicado,                            margen_redescuento,                     asociativo,
   incentivo,                            fecha_eleg,                             fecha_redes,
   solicitud,                            montop,                                 montodesembolsop,
   mercado,                              carta_apr,                              fecha_aprov,
   fmax_redes,                           f_prorroga,                             sujcred,
   fabrica,                              callcenter,                             apr_fabrica,
   monto_solicitado,                     tipo_plazo,                             tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito,						 alterno)
   select
   @s_ssn,                               21120,                                  'N',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite,            					tr_tipo,
   tr_oficina,                           tr_usuario,        	 					tr_fecha_crea,
   tr_oficial,                           tr_sector, 	      						tr_ciudad,
   @i_tipo_causal,       				 tr_nivel_ap,							    tr_fecha_apr,
   tr_usuario_apr,   					 tr_truta, 								  tr_numero_op,
   tr_numero_op_banco, 					 tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                             tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion, 										   tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   --tr_num_acciones,                    tr_responsable,                          tr_negocio,
   tr_num_acciones,    					 tr_responsable,                          tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,       									 tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg, 								          tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito,						 2
   from cr_tramite
   where tr_tramite = @i_tramite

      if @@error <> 0
   begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2103003
      return 2103003
   end

		  select @w_max_sec = MAX(secuencial)
		 from ts_tramite
		 where tramite =  @i_tramite


  /* FIN -- LC Req 368 26/08/2013 */

/*
   exec @w_error = cobis..sp_tarea
   @i_operacion     = 'M',
   @i_ente          = @w_cliente,
   @i_tipo          = 'R',
   @i_motivo_cierre = 'Z',
   @i_producto      = @w_prod_credito,
   @i_fecha_proc    = @s_date

   if @w_error <> 0
      goto ERROR
*/
      
end


if @i_tipo_causal = 'X'  -- Definitivo
begin


   /*select @w_tcausal = cq_tipo
   from   cr_cau_etapa
   where  cq_tipo = 'ANU'
   and    cq_tipo_tramite = @i_tipo_tramite
   and    cq_etapa = @i_etapa_actual
   set transaction isolation level read uncommitted

   if @w_tcausal is null
   begin
      select @w_error = 2108011
      goto ERROR
   end*/

   select @w_causal = cr_requisito
   from   cr_cau_tramite
   where  cr_tramite = @i_tramite
   and    cr_etapa   = @i_etapa_actual
   and    cr_tipo    = 'ANU'

   if @w_causal is null and @i_etapa_actual <> @w_cefinal
   begin
      select  @w_error = 2108012
      goto ERROR
   end

   -- MARCAR UTILIZACION DE CREDITOS ASOCIATIVOS
   exec @w_error  = sp_in_cupos_asoc
   @s_date  = @s_date,
   @i_operacion   = 'N',
   @i_tramite  = @i_tramite

   if @@error <> 0 or @w_error <> 0
   begin
      if @w_error is null select @w_error = 2101001
      goto ERROR
   end
end

if @i_tipo_causal = 'R'  -- Definitivo
begin
   /*select @w_tcausal = cq_tipo
   from   cr_cau_etapa
   where  cq_tipo = 'DES'
   and    cq_tipo_tramite = @w_tipo_tr
   and    cq_etapa = @i_etapa_actual
   set transaction isolation level read uncommitted

   if @w_tcausal is null
   begin
      select @w_error = 2108011
      goto ERROR
   end*/

   select @w_causal = cr_requisito
   from   cr_cau_tramite
   where  cr_tramite = @i_tramite
   and    cr_etapa   = @i_etapa_actual
   and    cr_tipo    = 'DES'

   if @w_causal is null
   begin
      select @w_error = 2108012
      goto ERROR
   end

  -- MARCAR UTILIZACION DE CREDITOS ASOCIATIVOS
   exec @w_error  = sp_in_cupos_asoc
   @s_date  = @s_date,
   @i_operacion   = 'N',
   @i_tramite  = @i_tramite

   if @@error <> 0 or @w_error <> 0
   begin
      if @w_error is null select @w_error = 2101001
      goto ERROR
   end
end

if @i_tipo_causal = 'S'  -- Definitivo
begin

   /*select @w_tcausal = cq_tipo
   from   cr_cau_etapa
   where  cq_tipo = 'DES'
   and    cq_tipo_tramite = @i_tipo_tramite
   and    cq_etapa = @i_etapa_actual
   set transaction isolation level read uncommitted

   if @w_tcausal is null
   begin
      select @w_error = 2108011
      goto ERROR
   end*/

   select @w_causal = cr_requisito
   from   cr_cau_tramite
   where  cr_tramite = @i_tramite
   and    cr_etapa   = @i_etapa_actual
   and    cr_tipo    = 'DES'

   if @w_causal is null
   begin
      select @w_error = 2108012
      goto ERROR
   end

   -- MARCAR UTILIZACION DE CREDITOS ASOCIATIVOS
   exec @w_error  = sp_in_cupos_asoc
   @s_date  = @s_date,
   @i_operacion   = 'N',
   @i_tramite  = @i_tramite

   if @@error <> 0 or @w_error <> 0
   begin
      if @w_error is null select @w_error = 2101001
      goto ERROR
   end
end


/* FIN VALIDACIONES CD00020*/
/***************************/

select   @w_estado_novig = pa_tinyint
from  cobis..cl_parametro
where    pa_nemonico = 'ESTNVG'
and   pa_producto = 'CRE'

select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   /* No existe valor de parametro */
   select @w_error = 2101084
   goto ERROR
end

select   @w_estado_anulado = pa_tinyint
from  cobis..cl_parametro
where    pa_nemonico = 'ESTANU'
and   pa_producto = 'CRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   /* No existe valor de parametro */
   select @w_error = 2101084
   goto ERROR
end

if @i_tipo_causal = 'R'
begin
   if @w_tipo_tr not in('O','R','U', 'T')
   begin
      print 'LOS TRAMITES QUE PERMITEN DESISITIMIENTO SON SOLICITUD,RENOVACIONES Y OPERACIONES ORIGINALES'

      select @w_error = 2103001
      goto ERROR
   end

   if @w_tipo_tr in('O','R', 'U', 'T')
   begin
      if exists (select   1
                 from     cob_cartera..ca_operacion
                 where    op_tramite = @i_tramite
                 and      op_estado  = @w_estado_novig)
      begin
         update cob_cartera..ca_operacion
         set    op_estado            = @w_estado_anulado,
                op_fecha_ult_proceso = @w_fecha
         where  op_tramite = @i_tramite

         if @@error <> 0  begin
            select @w_error = 2105001
            goto ERROR
         end
		 
		 if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
		 begin
			
			update cob_cartera..ca_operacion
            set    op_estado            = @w_estado_anulado,
                   op_fecha_ult_proceso = @w_fecha
			where op_ref_grupal = @w_op_banco
			
			if @@error <> 0  begin
                 select @w_error = 2105001
                 goto ERROR
            end
			
		 end
		 
      end
      else
      begin
         print 'EL ESTADO DE LA OBLIGACION NO PERMITE DESISTIMIENTO'

         select @w_error = 2103001
         goto ERROR
      end
   end

   select @w_desiste = 'S'
end --if @i_tipo_causal = 'R'

if @i_tipo_causal='R'
   select @i_tipo_causal='Z'

update cr_tramite
set    tr_estado = @i_tipo_causal,
       tr_fecha_apr = @s_date,
       tr_forward = case when tr_forward is not null then 'S' else tr_forward end
where  tr_tramite = @i_tramite

   /****** LC Req 368 26/08/2013 *******/

		 /****Insert tran servicio ****/



		 /* TRANSACCION DE SERVICIO REGISTRO  */
   insert into ts_tramite (
   secuencial,                           tipo_transaccion,                       clase,
   fecha,                                usuario,                                terminal,
   oficina,                              tabla,                                  lsrv,
   srv,                                  tramite,                                tipo,
   oficina_tr,                           usuario_tr,                             fecha_crea,
   oficial,                              sector,                                 ciudad,
   estado,                               nivel_ap,                               fecha_apr,
   usuario_apr,                          truta,                                  numero_op,
   numero_op_banco,                      proposito,                              razon,
   txt_razon,                            efecto,                                 cliente,
   grupo,                                fecha_inicio,                           num_dias,
   per_revision,                         condicion_especial,                     linea_credito,
   toperacion,                           producto,                               monto,
   moneda,                               periodo,                                num_periodos,
   destino,                              ciudad_destino,                         cuenta_corriente,
   renovacion,                           rent_actual,                            rent_solicitud,
   rent_recomend,                        prod_actual,                            prod_solicitud,
   prod_recomend,                        clasecca,                               admisible,
   noadmis,                              relacionado,                            pondera,
   tipo_producto,                        origen_bienes,                          localizacion,
   plan_inversion,                       naturaleza,                             tipo_financia,
   forward,                              elegible,                               emp_emisora,
   num_acciones,                         responsable,                            negocio,
   reestructuracion,                     concepto_credito,                       aprob_gar,
   mercado_objetivo,                     tipo_productor,                         valor_proyecto,
   sindicado,                            margen_redescuento,                     asociativo,
   incentivo,                            fecha_eleg,                             fecha_redes,
   solicitud,                            montop,                                 montodesembolsop,
   mercado,                              carta_apr,                              fecha_aprov,
   fmax_redes,                           f_prorroga,                             sujcred,
   fabrica,                              callcenter,                             apr_fabrica,
   monto_solicitado,                     tipo_plazo,                             tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito,						alterno)

   select
   @s_ssn,                               21120,                                  'P',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite, 								tr_tipo,
   tr_oficina,                           tr_usuario, 								tr_fecha_crea,
   tr_oficial,                           tr_sector, 								tr_ciudad,
   tr_estado, /*'Z',*/    				 tr_nivel_ap,							    tr_fecha_apr,
   tr_usuario_apr,   					 tr_truta, 								  tr_numero_op,
   tr_numero_op_banco, 					 tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                             tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion, 						 tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   --tr_num_acciones,                    tr_responsable,                          tr_negocio,
   tr_num_acciones,    					 tr_responsable,                          tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,       					tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg, 				          tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito,						3
   from cr_tramite
   where tr_tramite = @i_tramite

      if @@error <> 0
   begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
     exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2103003
      return 2103003

   end




		   /* TRANSACCION DE SERVICIO REGISTRO ACTUAL */
   insert into ts_tramite (
   secuencial,                           tipo_transaccion,                       clase,
   fecha,                                usuario,                                terminal,
   oficina,                              tabla,                                  lsrv,
   srv,                                  tramite,                                tipo,
   oficina_tr,                           usuario_tr,                             fecha_crea,
   oficial,                              sector,                                 ciudad,
   estado,                               nivel_ap,                               fecha_apr,
   usuario_apr,                          truta,                                  numero_op,
   numero_op_banco,                      proposito,                              razon,
   txt_razon,                            efecto,                                 cliente,
   grupo,                                fecha_inicio,                           num_dias,
   per_revision,                         condicion_especial,                     linea_credito,
   toperacion,                           producto,                               monto,
   moneda,                               periodo,                                num_periodos,
   destino,                              ciudad_destino,                         cuenta_corriente,
   renovacion,                           rent_actual,                            rent_solicitud,
   rent_recomend,                        prod_actual,                            prod_solicitud,
   prod_recomend,                        clasecca,                               admisible,
   noadmis,                              relacionado,                            pondera,
   tipo_producto,                        origen_bienes,                          localizacion,
   plan_inversion,                       naturaleza,                             tipo_financia,
   forward,                              elegible,                               emp_emisora,
   num_acciones,                         responsable,                            negocio,
   reestructuracion,                     concepto_credito,                       aprob_gar,
   mercado_objetivo,                     tipo_productor,                         valor_proyecto,
   sindicado,                            margen_redescuento,                     asociativo,
   incentivo,                            fecha_eleg,                             fecha_redes,
   solicitud,                            montop,                                 montodesembolsop,
   mercado,                              carta_apr,                              fecha_aprov,
   fmax_redes,                           f_prorroga,                             sujcred,
   fabrica,                              callcenter,                             apr_fabrica,
   monto_solicitado,                     tipo_plazo,                             tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito,						 alterno)
   select
   @s_ssn,                               21120,                                  'N',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite,								tr_tipo,
   tr_oficina,                           tr_usuario,  								tr_fecha_crea,
   tr_oficial,                           tr_sector, 								tr_ciudad,
   @i_tipo_causal,      				 tr_nivel_ap,							    tr_fecha_apr,
   tr_usuario_apr,   					 tr_truta, 								  tr_numero_op,
   tr_numero_op_banco, 					 tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                             tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion, 						 tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   --tr_num_acciones,                    tr_responsable,                          tr_negocio,
   tr_num_acciones,    					 tr_responsable,                          tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,       					 tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg, 				          tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito,						3
   from cr_tramite
   where tr_tramite = @i_tramite

      if @@error <> 0
   begin
      /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2103003
      return 2103003
   end



  /* FIN -- LC Req 368 26/08/2013 */




if @@error <> 0  begin
   select @w_error = 2105001
   goto ERROR
end

/* TEC - JES
if @i_tipo_causal = 'D' and @w_tipo_tr in ('C','O','R','E')
begin
   exec @w_error        = sp_estado_mir
        @i_tramite      = @i_tramite,
        @i_devuelto_mir = 'S'

   if @w_error <> 0
   begin
      goto ERROR
   end
end */

/* ACTUALIZACION DE RESERVADO DEL CUPO */
/* TEC - JES
if @w_tipo_tr in ('U','T') and @i_tipo_causal = 'Z'  -- JAR REQ 215
begin
   if @w_linea_cre is null
   begin
      select
      @w_error = 2101084,
      @w_msg   = 'Utilizacion o Unificacion sin relacion con linea de credito'
      goto ERROR
   end

   -- INI JAR REQ 215
   exec @w_return = sp_reservado
      @i_linea = @w_linea_cre

   if @w_return <> 0 begin
      select @w_error = @w_return
      goto ERROR
   end
   -- FIN JAR REQ 215
end
*/


--------------------------------------------------------------------------------------------------------------------
--FILTROS REQ: 164
--LPO INICIO 07/Oct/2010

if @i_tipo_causal = 'Z'
begin
   delete cr_valor_variables_filtros
   where vv_ruta    = 0
     and vv_etapa   = 0
     and vv_ente    = @w_cliente
end

--FILTROS REQ: 164
--LPO FIN 07/Oct/2010
--------------------------------------------------------------------------------------------------------------------


/* BORRAR LA TABLA DE SECUENCIAS A SEGUIR POR EL TRAMITE */
delete from cr_secuencia
where se_tramite  = @i_tramite
and   se_etapa    > 0
and   se_estacion > 0

if  @@error <> 0
begin
   select @w_error = 2107001
   goto ERROR
end

update cr_linea
set    li_estado    = 'A',
       li_num_banco = ''
where li_tramite    = @i_tramite

if @@error <> 0  begin
   select @w_error = 2105001
   goto ERROR
end

-- Borrar registros de redescuento
/* JES - TEC
select
@w_num_operacion = re_operacion
from  cr_archivo_redescuento
where re_tramite = @i_tramite

if @w_num_operacion is not null
begin
   exec @w_error = sp_archivo_redescuento
   @t_trn           = 21780,
   @i_operacion     = 'D',
   @i_num_operacion = @w_num_operacion

   if @@error <> 0 or @w_error <> 0
   begin
      if @w_error is null select @w_error = 2101001
      goto ERROR
   end
end
*/

-- Borrar Datos Linea Reservada
delete from cr_lin_reservado
where lr_tramite     = @i_tramite
and   lr_toperacion  > '0'
and   lr_moneda   > 0

if  @@error <> 0
begin
   /* REGISTRO A ELIMINAR NO EXISTE */
   select @w_error = 2107002
   goto ERROR
end

/**R246371**/
if @w_estado_op=@w_estado_credito
begin
   update cob_cartera..ca_operacion
   set    op_estado            = @w_estado_anulado,
          op_fecha_ult_proceso = @w_fecha
   where  op_tramite           = @i_tramite

   if @@error <> 0  begin
      select @w_error = 2105001
      goto ERROR
   end
   
   --R268732: Rechazo op hijas
   if exists (select 1 from cob_cartera..ca_operacion with(nolock) where op_ref_grupal = @w_op_banco)
   begin
	  update cob_cartera..ca_operacion
	  set    op_estado             = @w_estado_anulado,
			  op_fecha_ult_proceso = @w_fecha
	  where  op_ref_grupal         = @w_op_banco

	  if @@error <> 0  begin
		  select @w_error = 2105001
		  goto ERROR
	  end
   end
end 
/**R246371**/

select @w_salida = op_estado
from   cob_cartera..ca_operacion
where  op_tramite = @i_tramite

/* NO SE USA EN ESTA VERSION
if @w_salida = @w_estado_novig
begin
   if @i_tipo_causal <> 'R'
   begin
      select   @w_secuencia = rt_secuencia
      from     cr_ruta_tramite
      where    rt_salida    is null
      and      rt_tramite   = @i_tramite
      and      rt_secuencia > 0

      if @@rowcount = 0
      begin
         REGISTRO NO EXISTE 
         select @w_error = 2101005
         goto ERROR
      end

       INSERCION DE REGISTRO EN RUTA TRAMITE 
	   TEC - JES
      select @s_ssn = @s_ssn + 1
      exec @w_return = sp_ruta_tramite
      @s_ssn   = @s_ssn,
      @s_ofi   = @s_ofi,
      @t_trn   = 21106,
      @i_operacion = 'U',
      @i_tramite   = @i_tramite,
      @i_salida    = @w_today,
      @i_secuencia = @w_secuencia,
      @i_asociado  = NULL,
      @s_date      = @s_date

      if @w_return <> 0
      begin
         select @w_error = @w_return
         goto ERROR
      end
	  
   end --if @i_tipo_causal <> 'R'
end --if @w_salida = 0
*/

if @w_producto = 'CCA'
begin
   select @w_op_operacion = op_operacion,
          @w_op_estado    = op_estado
   from   cob_cartera..ca_operacion
   where  op_tramite  = @i_tramite

   if @w_op_estado in (1,2,4,9)
    begin
         select
         @w_error = 2110345
         goto ERROR
    end


   if exists ( select 1
             from  cob_cartera..ca_transaccion
                where tr_operacion  = @w_op_operacion
                and   tr_estado = 'ING'
                and   tr_tran <> 'PRV')--LAs PRV contabilizan en la ca_transaccion_prv
   begin
      /*Y DESPUES SI HACER EL RECHAZO */
      ---INC.39524
         select
         @w_error = 2110346
         goto ERROR
   end
   else
   begin
	   if exists ( select 1
	             from  cob_cartera..ca_transaccion_prv
	                where tp_operacion  = @w_op_operacion
	                and   tp_estado = 'ING')
	   begin
	      /*Y DESPUES SI HACER EL RECHAZO */
	      ---INC.39524
	         select
	         @w_error = 2110347
	         goto ERROR
	   end
	   --else
	   --begin
	   --   delete cob_cartera..ca_dividendo
	   --   where  di_operacion = @w_op_operacion

	   --   if @@error <> 0
	   --   begin
	         /*ERROR EN ACTUALIZACION DE REGISTRO */
	   --      select
	   --      @w_error = 2105001,
	   --      @w_msg   = 'Error en actualizacion de estado de operacion de Cartera'
	   --      goto ERROR
	   --   end

	   --   delete cob_cartera..ca_amortizacion
	   --   where  am_operacion = @w_op_operacion

	   --   if @@error <> 0
	   --   begin
	         /*ERROR EN ACTUALIZACION DE REGISTRO */
	   --      select
	   --      @w_error = 2105001,
	   --      @w_msg   = 'Error en actualizacion de estado de operacion de Cartera'
	   --      goto ERROR
	   --   end


	   --   delete cob_cartera..ca_rubro_op
	   --   where ro_operacion = @w_op_operacion

	   --   if @@error <> 0
	   --   begin
	         /*ERROR EN ACTUALIZACION DE REGISTRO */
	   --      select
	   --      @w_error = 2105001,
	   --      @w_msg   = 'Error en actualizacion de estado de operacion de Cartera'
	   --      goto ERROR
	   --   end


	   --   delete cob_cartera..ca_reajuste
	   --   where re_operacion = @w_op_operacion

	   --   if @@error <> 0
	   --   begin
	         /*ERROR EN ACTUALIZACION DE REGISTRO */
	   --      select
	   --      @w_error = 2105001,
	   --      @w_msg   = 'Error en actualizacion de estado de operacion de Cartera'
	   --      goto ERROR
	   --   end


	   --   delete cob_cartera..ca_reajuste_det
	   --   where  red_operacion = @w_op_operacion

	   --   if @@error <> 0
	   --   begin
	         /*ERROR EN ACTUALIZACION DE REGISTRO */
	   --      select
	   --      @w_error = 2105001,
	   --      @w_msg   = 'Error en actualizacion de estado de operacion de Cartera'
	   --      goto ERROR
	   --   end


	   --   delete cob_cartera..ca_operacion
	   --   where op_tramite   = @i_tramite

	   --   if @@error <> 0
	   --   begin
	         /*ERROR EN ACTUALIZACION DE REGISTRO */
	   --      select
	   --      @w_error = 2105001,
	   --      @w_msg   = 'Error en actualizacion de estado de operacion de Cartera'
	   --      goto ERROR
	   --   end
      --end ---else
   end --else
end--If @w_producto = 'CCA'

/* ADI: INC 14913 SOLO PARA OPCION DE DESISTIMIENTO */
------------------------------------------------------------------------------
--SRA: Actualiza el monto reservado  y el saldo de la fuente de recursos
------------------------------------------------------------------------------

if @w_estado_inicial = 'A' and @w_tipo_tr not in ('E' , 'C') and
   @w_desiste = 'S'
begin
   exec @w_return      = sp_actualiza_resal_fuente
   @s_user             = @s_user,
   @i_fuente_recurso   = @w_fuente_recurso,
   @i_modo             = 'R',
   @i_valor            = @w_monto,
   @i_tramite          = @i_tramite

   if @w_return  <>   0
   begin
      select @w_error = 2110348
      goto ERROR
   end
end
/* ADI: FIN - INC 14913 SOLO PARA OPCION DE DESISTIMIENTO */


delete cob_cartera..ca_relacion_ptmo
where rp_pasiva = @w_op_operacion
if  @@error <> 0
begin
    select @w_error = 2107001
    goto ERROR
end

------------------------------------------------------------------------------
--SRA: Se Actualiza el estado de la garantia automática Tipo Pagaré cuando el
--Tramite es regresado de Cartera y es rechazado
------------------------------------------------------------------------------
if @w_estado_inicial = 'A'
begin
   exec @w_return  = sp_crea_gar_aut
   @s_date         = @s_date,
   @s_user         = @s_user,
   @s_term         = @s_term,
   @s_ofi          = @s_ofi,
   @i_op_tramite   = @i_tramite,
   @i_operacion    = 'R'
   if @w_return  <>   0
   begin
      select @w_error = @w_return
      goto ERROR
   end
end
--------------------------------------------------------------------------------------
--SRA: Si se rechaza el tramite se anula la transaccion en cajas de Estudio Crediticio
--------------------------------------------------------------------------------------
exec @w_return      = sp_trncj_ec
@t_trn         = 22232,
@t_debug       = 'N',
@s_date        = @s_date,
@s_user        = @s_user,
@i_operacion   = 'R',
@i_tramite     = @i_tramite
if  @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end


-----------------------------------------------------------------------------------------
--Si se rechaza el tramite se anula la transaccion en cajas de Abono por Reestructuracion
-----------------------------------------------------------------------------------------
if @w_tipo_tr     = 'E' begin
   exec @w_return = sp_trn_cj_reest
   @s_date         = @s_date,
   @s_user         = @s_user,
   @i_operacion    = 'R',
   @i_tramite      = @i_tramite

   if  @w_return <> 0
   begin
      select @w_error = @w_return
      goto ERROR
   end
   ---INC. 115734 CUADO SE RECHAZA UN TRAMITE DE RESTRUCTURACION
   ---            LA GARANTIA DEBE VOLVER A SU TRAMITE ORIGINAL
   ---            ESTA QUEDANDO ATADA AL TRAMITE ANULADO
   ---            ESTE SE RECUPERA DE LA TABLA DE TRABAJO
   select @w_tramite_org = 0
   select @w_tramite_org = gpt_tramite,
          @w_garantia    = gpt_garantia
   from   cob_cartera..ca_gar_propuesta_tmp
   where  gpt_tramite_E = @i_tramite --tramite a rechazar

   if @w_tramite_org > 0 begin
      select top 1 1
      from  cob_credito..cr_gar_propuesta
      where gp_garantia = @w_garantia
      and   gp_tramite  = @w_tramite_org

      if @@rowcount = 0 begin
         update cob_credito..cr_gar_propuesta
         set    gp_tramite = @w_tramite_org
         where  gp_tramite = @i_tramite --tramite a rechazar

         if @@error <> 0 begin
            select
            @w_error = 2110349
            goto ERROR
         end
      end
   end
end


/* INSERCION EN EL ARCHIVO HISTORICO */
exec  @w_error = sp_hist_credito
@s_date    = @s_date,
@i_tramite = @i_tramite,
@i_operacion = 'R',                   -- OPERACION DE RECHAZO
@i_observaciones = @i_observaciones

if @@error <> 0 or @w_error <> 0
begin
   -- ERROR EN ACTUALIZACION DE REGISTRO
   if @w_error is null select @w_error = 2101001
   goto ERROR
end

-- Se actualiza la fecha de salida de la tabla cr_ruta_tramite.
if @i_tipo_causal = 'Z'
begin
   update cob_credito..cr_ruta_tramite
   set rt_salida = @w_today
   where rt_tramite = @i_tramite
   and rt_salida is null

   if @@error <> 0 begin
      select @w_error = 2105001
      goto ERROR
   end
end

-- REQ. 422 27/06/2014
if @i_tipo_causal = 'Z'
begin
   declare
      @w_debe_llamar   char

   select @w_debe_llamar = 'S'

   -- Validacion para oficinas
   select @w_valorhra = pa_char
   from cobis..cl_parametro
   where pa_nemonico = 'OFIHRA'

   if @w_valorhra = 'X'
		select @w_debe_llamar = 'N'

   if @w_valorhra = 'S'
   begin
      if not exists (select 1
                     from cobis..cl_tabla t,
                     cobis..cl_catalogo c
                     where t.tabla  = 'cr_oficina_hra'
                     and   c.tabla  = t.codigo
                     and   c.codigo = convert(varchar(10),@s_ofi)
                     and   c.estado = 'V')
      select @w_debe_llamar = 'N'
   end

      --Seleccionando el cliente al que corresponde el tramite
      select @w_tr_cliente       = tr_cliente,
             @w_tr_destino       = tr_destino,
             @w_tr_act_financiar = tr_act_financiar,
             @w_tr_mercado       = tr_mercado
      from cob_credito..cr_tramite
      where tr_tramite = @i_tramite

      if @@rowcount = 0
      begin
         select
         @w_error = 2110335
         goto ERROR
      end

      select @w_estado = 'N'

      select @w_estado = af_estado
      from cob_credito..cr_act_financiar
      where af_mercado       = @w_tr_mercado
      and   af_destino       = @w_tr_destino
      and   af_act_financiar = @w_tr_act_financiar

      if @w_estado = 'N'
		select @w_debe_llamar = 'N'

      if @w_debe_llamar = 'S'
      begin
         --Obteniendo la cedula del cliente
         select @w_en_ced_ruc  = en_ced_ruc,
                @w_en_tipo_ced = en_tipo_ced
         from cobis..cl_ente
         where en_ente = @w_tr_cliente

         if @@rowcount = 0
         begin
            select
            @w_error = 2110190
            goto ERROR
         end

         --Obteniendo la version maxima de los registros generales
         select @w_version_max = MAX(ge_nro_version)
         from cob_externos..ex_generales_hra GHRA
         where ge_tipo_id   = @w_en_tipo_ced
         and   ge_numero_id = @w_en_ced_ruc

         select @w_tr_estado = '3'
         /*
         --CONSULTAR COMO INVOCAR AL SERVIDOR DE MIDDLEWARE
         exec @w_return = CTSXPSERVER2.cob_procesador..sp_act_estado_hra_ws
              @t_trn          = 26530,
              @s_ofi          = @s_ofi,
              @s_user         = @w_user,
              @s_rol          = @w_rol,
	          @i_num_doc      = @w_en_ced_ruc,
	          @i_flujo        = @w_version_max,
	          @i_estado       = @w_tr_estado,
	          @i_tramite      = @i_tramite,
	          @o_referencia   = @w_referencia out,
	          @o_mensaje      = @w_mensaje out,
	          @o_estado       = @w_estado out

         if @w_return <> 0
         begin
            print 'ERROR ACTUALIZANDO ESTADO FLUJO CAJA AGROPECUARIO: @w_return '+ cast(@w_return as varchar)
            goto ERROR
         end

         if @w_estado <> '1'
         begin
            select @w_msg = isnull(@w_mensaje,'ERROR INSERTANDO RELACION CUENTA EN EL MIDDLEWARE')
            goto ERROR
         end
         */
      end
end


if @w_commit = 'S' commit tran
FIN:
return 0

ERROR:

if @w_commit = 'S' rollback tran

   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = @w_error

   return 1
go
