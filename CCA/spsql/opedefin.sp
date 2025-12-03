/************************************************************************/
/*  NOMBRE LOGICO:        opedefin.sp                                   */
/*  NOMBRE FISICO:        sp_operacion_def_int                          */
/*  BASE DE DATOS:        cob_cartera                                   */
/*  PRODUCTO:             CARTERA                                       */
/*  DISENADO POR:         R Garces                                      */
/*  FECHA DE ESCRITURA:   Jul. 1997                                     */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Transmision definitiva en la creacion/actualizacion de una op   */
/*      llamada interna de sps                                          */
/*                              ACTUALIZACIONES                         */
/*      FECHA          AUTOR               CAMBIO                       */
/*      sep-15-2005    Elcira P.           correcciones defecto 4717 del*/
/*                                         BAC. manejo gar. especiales  */
/*      Mar-19-2013    David.P.            Correccion incidencia REQ343 */
/*                             CAMBIOS                                  */
/*      Ene-05-2016    L. Regalado         Incluir tabla de parametros  */
/*      Mar-29-2019    A. Giler            Calculo del CAT              */
/*      OCT-18-2019    A. Miramon          Ajuste en calculo de CAT     */
/*     May -18-2021    L. Bland�n          Calculo Tir TEa              */
/*      Abr-26-2022    L. Fern�ndez        No actualizar prospecto a    */
/*                                         cliente                      */
/*     24/Jun/2022     KDR                 Nuevo par�metro sp_liquid    */
/*     07/Jun/2023     KDR                 S809862 Tipo Doc. tributario */
/*     26/Sep/2023     KDR                 S910674-R216163 Ajuste asig- */
/*                                         nación Tipo Doc. tributario  */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_operacion_def_int')
	drop proc sp_operacion_def_int
go
create proc sp_operacion_def_int
	@s_date			datetime = null,
	@s_sesn 		int      = null,    
	@s_user			login    = null,
	@s_ofi 			smallint = null,
	@i_banco		cuenta   = null,
    @i_claseoper    cuenta   = 'A',
    @i_desde_cre    char     = 'S'
				
as
declare @w_sp_name              descripcion,
        @w_return               int,
	     @w_error                int,
	     @w_operacionca		     int,
        @w_monto                money,
        @w_moneda               tinyint,
        @w_fecha_ini            datetime,
        @w_fecha_fin            datetime,
        @w_toperacion           catalogo, 
        @w_tplazo               catalogo,
        @w_plazo                int,
        @w_tipo_producto        catalogo,
        @w_reajustable          char(1),
        @w_recalcular           char(1),
        @w_tasa_equivalente     char(1),
        @w_periodo_reajuste     smallint,
        @w_operacionca_tmp      int,
        @w_monto_tmanual        money,
        @w_monto_capital        money,
        @w_tipo_tabla           varchar(10),
        @w_estado_op		        tinyint,
        @w_est_novigente	     tinyint,
        @w_est_credito   	     tinyint,
        @w_pago_caja		        char(1),
        @w_nace_vencida		     char(1), 
        @w_cotiz_ds		        money,
        @w_forma_desem		     varchar(6),
        @w_tipo                 char(1),
        @w_banco_pasiva         cuenta,
        @w_op_pasiva            int,
        @w_op_naturaleza        char(1),
        @w_parametro_fag        catalogo,
        @w_parametro_fng        catalogo,
        @w_parametro_fogacafe   catalogo,
        @w_parametro_usaid      catalogo,
        @w_tramite              int,
        @w_parametro_ong        catalogo,
        @w_fag		        char(1),
        @w_fng                  char(1),
        @w_fog                  char(1),
        @w_usaid                char(1),
        @w_garantia_especial    char(1),
        @w_tipo_esp             catalogo,
        @w_control              char(1),
        @w_parametro_comfga     catalogo,
        @w_comfga               char(1),
        --REQ379
        @w_parametro_fgu        catalogo,
        @w_comfgu               char(1),
        @w_colateral            catalogo,
        @w_cod_tipogar          varchar(64),
        @w_tipo_garantia        varchar(64),
        @w_tipo_superior        varchar(64),
        @w_rubros               char(1),
        @w_tabla_rubros         varchar(64),
        @w_cat                  float,
		@w_cat1                 float,
		@w_tir                  float,
		@w_tea                  float,
		@w_grupal               char(1),         
        @w_op_ref_grupal        varchar(24),
		@w_cliente              int,	
		@w_tipo_doc_fiscal      varchar(3)


create table #conceptos_oped (
 codigo    varchar(10),
 tipo_gar  varchar(64)
 )

create table #rubros_oped (
garantia      varchar(10),
rre_concepto  varchar(64),
tipo_concepto varchar(10),
iva           varchar(5),
)  

/* CARGAR VALORES INICIALES */
select @w_sp_name        = 'sp_operacion_def_int'

select @w_est_novigente = es_codigo 
from ca_estado
where es_descripcion = 'NO VIGENTE'

select @w_est_credito = es_codigo 
from ca_estado
where es_descripcion = 'CREDITO'

/* BORRADO DE TABLAS */
delete ca_garantias_tramite
where  gp_sesion = @@spid

delete gar_especiales
where  ge_sesion = @@spid

---DATOS DE LA OPERACION TEMPORAL
select
@w_tipo_tabla         = opt_tipo_amortizacion,
@w_operacionca_tmp    = opt_operacion
from ca_operacion_tmp
where opt_banco = @i_banco

-- CONTROLAR QUE LA TABLA MANUAL HAYA SIDO MODIFICADA DESPUES DE LA CREACION

if @w_tipo_tabla = 'MANUAL' begin
   select @w_monto_tmanual = sum(amt_cuota + amt_gracia)
   from ca_amortizacion_tmp, ca_rubro_op_tmp
   where amt_operacion = @w_operacionca_tmp
   and   rot_operacion = @w_operacionca_tmp
   and   rot_tipo_rubro= 'C'
   and   amt_concepto  = rot_concepto

   select @w_monto_capital = sum(rot_valor)
   from   ca_rubro_op_tmp
   where  rot_operacion    = @w_operacionca_tmp
   and    rot_tipo_rubro   = 'C' 
 
   
   if @w_monto_tmanual <> @w_monto_capital ---return 710079 
   begin
      print 'Si esta seguro que la TABLA MANUAL esta correcta, favor continua!!'
   end
end


exec @w_return = sp_pasodef
   @i_banco           = @i_banco,
   @i_operacionca     = 'S',
   @i_dividendo       = 'S',
   @i_amortizacion    = 'S',
   @i_cuota_adicional = 'S',
   @i_rubro_op        = 'S',
   @i_relacion_ptmo   = 'S',
   @i_nomina          = 'S', 
   @i_acciones        = 'S', 
   @i_valores         = 'S',
   @i_operacion_ext   = 'S'   --LRE 05/ENE/2017

--PRINT 'sale del paso a las definitivas'

if @w_return <> 0
begin
   delete ca_garantias_tramite
   where  gp_sesion = @@spid
   
   return @w_return
end

--- TIPO DE PRODUCTO 

select @w_tipo_producto = pd_tipo from cobis..cl_producto
where pd_producto = 7  
set transaction isolation level read uncommitted

select 
@w_tipo             = op_tipo,
@w_monto            = op_monto,
@w_moneda           = op_moneda,
@w_cliente          = op_cliente,
@w_fecha_ini        = op_fecha_ini,
@w_fecha_fin        = op_fecha_fin,
@w_toperacion       = op_toperacion,
@w_tplazo           = op_tplazo,
@w_plazo            = op_plazo,
@w_reajustable      = op_reajustable,
@w_periodo_reajuste = op_periodo_reajuste,
@w_operacionca      = op_operacion,
@w_recalcular       = op_recalcular_plazo,
@w_tasa_equivalente = op_usar_tequivalente,
@w_estado_op        = op_estado,
@w_pago_caja        = op_pago_caja,
@w_op_naturaleza    = op_naturaleza,
@w_tramite          = op_tramite,
@w_grupal           = op_grupal,
@w_op_ref_grupal    = op_ref_grupal
from   ca_operacion
where  op_banco    = @i_banco

if @w_toperacion = 'A130COPPRI'
begin
   print 'Esta Operacion no puede ser modificada, su tipo no permite modificacion'
   
   delete ca_garantias_tramite
   where  gp_sesion = @@spid
   
   return 0
end
   
   /*
   -- AMG 2019/10/18 - Calculo de CAT
   exec @w_return = sp_calculo_cat @i_banco = @i_banco, @o_cat = @w_cat out
   --PRINT 'cat: ' + convert(VARCHAR, @w_cat)

   if @w_return != 0
   begin 
      select @w_error = @w_return
      goto ERROR
   end

	
   update cob_cartera..ca_operacion SET 
   		op_valor_cat = @w_cat,
   		op_valor_cat
   where op_operacion = @w_operacionca
   
   if @@error <> 0 
   begin
      select @w_error = 2103001
      goto ERROR
   end
   -- AGI-FIN 2018-03-11

   --------------------------------------------------------------------------------------------------   
   */
   
   -- Actualiza tipo de documento fiscal (Solo a operaciones que no han sido desembolsadas)
   if @w_estado_op in (@w_est_novigente, @w_est_credito)
   begin
   
      if @w_grupal = 'S' and @w_op_ref_grupal is null -- OP Grupal Padre
	     select @w_tipo_doc_fiscal = 'FCF'
      else
	  begin
	  
         exec sp_func_facturacion
         @i_operacion       = 'D', -- Identificar tipo documento tributario
         @i_opcion          = 0,
         @i_tramite         = @w_tramite,
         @o_tipo_doc_fiscal = @w_tipo_doc_fiscal out

	  end

      update ca_operacion_datos_adicionales
      set oda_tipo_documento_fiscal = @w_tipo_doc_fiscal
      where oda_operacion = @w_operacionca
	  
      if @@error <> 0
      begin
         select @w_error = 710002 -- Error en la actualizacion del registro
		 goto ERROR
      end  
	  
   end
   
   --LBP 20210518	
   EXEC @w_return	= sp_tir 
		 @i_banco	= @i_banco, 
		 @o_cat		= @w_cat1 OUTPUT , 
		 @o_tir		= @w_tir  OUTPUT,
		 @o_tea		= @w_tea OUTPUT

	 if @w_return != 0
   begin 
      select @w_error = @w_return
      goto ERROR
   end

   update cob_cartera..ca_operacion SET 
   		op_valor_cat		= @w_tir,
   		op_tasa_cap			= @w_tea
   where op_operacion = @w_operacionca

   if @@error <> 0 begin
      select @w_error = 2103001
      goto ERROR
   end
   --LBP 20210518

   select @w_tramite = op_tramite
   from cob_cartera..ca_operacion
   where op_banco = @i_banco

   select tc_tipo as tipo_sub 
   into #colateral
   from cob_custodia..cu_tipo_custodia
   where tc_tipo_superior = @w_colateral
   
   select @w_cod_tipogar   = tc_tipo,
          @w_tipo_garantia = tc_descripcion,
          @w_tipo_superior = tc_tipo_superior
   from cob_custodia..cu_tipo_custodia, cob_custodia..cu_custodia, #colateral, cob_credito..cr_gar_propuesta
   where tc_tipo = cu_tipo
   and   tc_tipo_superior = tipo_sub
   and   cu_codigo_externo = gp_garantia
   and   gp_tramite = @w_tramite
   and   gp_est_garantia <> 'A'  --acelis ago 12 2012
   and   cu_estado  in ('V','F','P')

/*BUSQUEDA DE CONCEPTOS REQ 379*/
   select @w_rubros = valor 
   from  cobis..cl_tabla t, cobis..cl_catalogo c
   where t.tabla  = 'ca_conceptos_rubros'
   and   c.tabla  = t.codigo
   and   c.codigo = convert(bigint, @w_cod_tipogar)  

   if @w_rubros = 'S' begin

      select @w_tabla_rubros = 'ca_conceptos_rubros_' + cast(@w_cod_tipogar as varchar)

      insert into #conceptos_oped
      select 
      codigo = c.codigo, 
      tipo_gar = @w_cod_tipogar
      from cobis..cl_tabla t, cobis..cl_catalogo c
      where t.tabla  = @w_tabla_rubros
      and   c.tabla  = t.codigo
      
   end --FIN REQ 379

  /*REQ 402*/
   
   insert into #rubros_oped
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'DES',
          iva = 'N'
   from cob_cartera..ca_rubro, #conceptos_oped
   where ru_fpago = 'L'
   and   codigo = ru_concepto
   and   ru_concepto_asociado is  null

   /*COMICION PERIODICO*/
   insert into #rubros_oped
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'PER',
          iva = 'N'
   from cob_cartera..ca_rubro, #conceptos_oped
   where ru_fpago = 'P'
   and   codigo = ru_concepto
   and   ru_concepto_asociado is  null
   
   /*IVA DESEMBOLSO*/
   insert into #rubros_oped
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'DES',
          iva = 'S'
   from cob_cartera..ca_rubro, #conceptos_oped
   where ru_fpago = 'L'
   and   codigo = ru_concepto
   and   ru_concepto_asociado is not null
 
   /*IVA PERIODICO*/
   insert into #rubros_oped
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'PER',
          iva = 'S'
   from cob_cartera..ca_rubro, #conceptos_oped
   where ru_fpago = 'P'
   and   codigo = ru_concepto
   and   ru_concepto_asociado is not null

-------------------------------------------------------------------------------------------------

--GFP Abr-26-2022 Se comenta actualizaci�n de prospecto a cliente 
/*
exec @w_return = sp_cliente
@t_debug        = 'N',
@t_file         = '',
@t_from         = @w_sp_name,
@s_date         = @s_date, 
@i_usuario      = @s_user,
@i_sesion       = @s_sesn,
@i_oficina      = @s_ofi,
@i_producto     = 7,
@i_tipo         = @w_tipo_producto,
@i_monto        = @w_monto,
@i_moneda       = @w_moneda,
@i_fecha        = @w_fecha_ini,
@i_fecha_fin    = @w_fecha_fin,
--@i_toperacion   = @w_toperacion,
@i_banco        = @i_banco,
--@i_tplazo       = @w_tplazo,
--@i_plazo        = @w_plazo,
@i_operacion    = 'I',
@i_claseoper    = @i_claseoper

if @w_return <> 0
begin
   delete ca_garantias_tramite
   where  gp_sesion = @@spid
   
   return @w_return
end
*/
-- GENERACION DE LAS FECHAS DE REAJUSTE 


if isnull(@w_periodo_reajuste,0) <> 0 and @w_reajustable = 'S' 
begin
   
   if @w_tipo = 'C' 
   begin
--PRINT 'antes de sp_fecha_reajuste'
      exec @w_return = sp_fecha_reajuste
      @i_banco       = @i_banco,
      @i_tipo        = 'I' 

      if @w_return <> 0
      begin
         delete ca_garantias_tramite
         where  gp_sesion = @@spid
         
         return @w_return
      end
      


      select @w_op_pasiva = rp_pasiva from ca_relacion_ptmo
      where rp_activa = @w_operacionca
   
      if @@rowcount <> 0
      begin
         
         select @w_banco_pasiva = op_banco
         from ca_operacion
         where op_operacion  = @w_op_pasiva
         if @@rowcount <> 0
            exec @w_return = sp_fecha_reajuste
            @i_banco       = @w_banco_pasiva,
            @i_tipo        = 'I' 
         else
         begin
            delete ca_garantias_tramite
            where  gp_sesion = @@spid
            
            PRINT 'Error Existe relacion de activa y pasiva  pero pasiva no existe'
            return 710135
         end
         
      end
   end
   else
   begin
      exec @w_return = sp_fecha_reajuste
      @i_banco       = @i_banco,
      @i_tipo        = 'I' 

      if @w_return <> 0
      begin
         delete ca_garantias_tramite
         where  gp_sesion = @@spid
         
         return @w_return
      end

   
   end
end 
else begin
   delete ca_reajuste_det
   where red_operacion  = @w_operacionca

   if @@error <> 0 return 710003

   delete ca_reajuste
   where re_operacion = @w_operacionca

   if @@error <> 0 return 710003

   delete ca_reajuste_det_tmp
   where red_operacion = @w_operacionca

   if @@error <> 0 return 710003

   delete ca_reajuste_tmp
   where re_operacion = @w_operacionca

   if @@error <> 0 return 710003

   delete ca_reajuste_det_tmp
   where red_operacion = @w_operacionca
   
end

--- VALORES PARA PAGO POR ATX 
if @w_estado_op <> @w_est_novigente and @w_estado_op <> @w_est_credito
BEGIN

--PRINT 'antes  de sp_valor_atx_mas '
      exec @w_return = sp_valor_atx_mas
      @s_user  = @s_user,
      @s_date  = @s_date,
      @i_banco = @i_banco

      if @w_return <> 0 return @w_return
end

-- TRANSACCION DE SERVICIO 
exec @w_return = sp_tran_servicio
@s_user      = @s_user,
@s_date      = @s_date, 
@s_ofi       = @s_ofi,
@s_term      = 'TERMX',
@i_tabla     = 'ca_operacion', 
@i_clave1    = @w_operacionca 

if @w_return <> 0 begin
   select @w_error = @w_return
   goto ERROR
end


if @w_nace_vencida = 'S' begin
   /* Obtencion de la �ltima fecha en que ha sido ingresada la cotizaci=n */
   exec sp_buscar_cotizacion
        @i_moneda     = @w_moneda,
        @i_fecha      = @w_fecha_ini,
        @o_cotizacion = @w_cotiz_ds output
   
   if @w_moneda <> 0 
      select @w_forma_desem = 'DENVME'
   else
      select @w_forma_desem = 'DENVMN'
   


   exec @w_return = sp_desembolso
   @s_date = @s_date,
   @i_operacion = 'I',
   @i_producto = @w_forma_desem,
   @i_cuenta = '0000000000',
   @i_beneficiario = 'OP. NACE VENCIDA',
   @i_banco_ficticio = @i_banco,
   @i_banco_real = @i_banco,
   @i_fecha_liq = @w_fecha_ini,
   @i_monto_ds = @w_monto,
   @i_tcotiz_ds = 'COT',
   @i_cotiz_ds = @w_cotiz_ds,
   @i_moneda_op = @w_moneda,
   @i_moneda_ds = @w_moneda


   if @w_return <> 0 begin
      select @w_error = @w_return
      goto ERROR
   end

--PRINT 'Luego del desembolso '

   exec @w_return = sp_liquida
   @i_banco_ficticio = @i_banco,
   @i_banco_real = @i_banco,
   @i_fecha_liq = @w_fecha_ini,
   @i_desde_cartera = 'N'          -- KDR No es ejecutado desde Cartera[FRONT]

   if @w_return <> 0 begin
      select @w_error = @w_return
      goto ERROR
   end

--PRINT 'Luego de la liquidacion '
   update ca_operacion 
   set op_estado = 2
   where op_operacion = @w_operacionca

   update ca_dividendo 
   set di_estado = 2
   where di_operacion = @w_operacionca

   update ca_amortizacion 
   set am_estado = 2
   where am_operacion = @w_operacionca
    
end




/* CONTROL DE RUBROS COMISION, CUANDO EXISTE UNA GARANTIA ESPECIAL */
/* PARA LA CONSOLIDACION DE PASIVOS(OP-ACTIVAS Y OP-PASIVAS), EL MODULO CRE */
/* INGRESA A LA PANTALLA DE ACTUALIZACION DE OPERACIONES Y EJECUTA ESTE SP*/  ---XMA

---CODIGO DEL RUBRO COMISION FAG 
select @w_parametro_fag = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFAG'
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION FNG 
select @w_parametro_fng = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFNG'
set transaction isolation level read uncommitted


---CODIGO DEL RUBRO COMISION FOGACAFE
select @w_parametro_fogacafe = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFOG'
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION FOGACAFE
select @w_parametro_usaid = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CMUSAP'
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION COMFGAUNI
select @w_parametro_comfga = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFGA'
set transaction isolation level read uncommitted

--REQ379 TIPO GARANTIA
select @w_parametro_fgu = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMGAR'
set transaction isolation level read uncommitted

if @i_desde_cre = 'S' and @w_op_naturaleza = 'A' and @w_tramite is not null and @w_estado_op = 0 ---SI UNA OBLIGACION TIENE GARANTIAS ESPECIALES, DEBE TENER LOS RUBROS COMISION E IVA
begin


   /* GARANTIAS DE UN TRAMITE */ 
   /***************************/
   if exists (select 1 from cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia
              where gp_tramite  = @w_tramite
              and   gp_garantia = cu_codigo_externo
              and   cu_estado in ('V','F','P')
              )
   begin
      insert into ca_garantias_tramite
      (gp_sesion, gp_garantia, cu_tipo) 
      select @@spid, gp_garantia, cu_tipo
      from cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia
      where gp_tramite  = @w_tramite
      and   gp_garantia = cu_codigo_externo
      and   cu_estado in ('V','F','P')
      if @@error <> 0 or @@rowcount = 0
      print '..ERROR EN CA_GARANTIAS_TRAMITE'
   end
   else
   begin
      insert into ca_garantias_tramite
      values (0,'0', '0') 
   end


   /*ANALIZA SI EL CREDITO TIENE GARANTIA ESPECIAL */
   /************************************************/
   select @w_garantia_especial  = 'N'

   /*PARAMETRO PARA DEFINIR LAS GARANTIAS ESPECIALES*/
   /*************************************************/
   select @w_tipo_esp = pa_char
   from cobis..cl_parametro
   where pa_producto = 'GAR'
   and pa_nemonico   = 'GARESP'

   if @@rowcount = 0
   begin   
      exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_msg   = 'No existe parametro con el nemonico GARESP',
      @i_num   = 2101084
      
      delete ca_garantias_tramite
      where  gp_sesion = @@spid
      
      return 1 
   end

   /*TABLA DE LOS TIPOS DE GARANTIAS ESPECIALES*/
   /**********************************************/
   insert into gar_especiales
   select @@spid,tc_tipo 
   from   cob_custodia..cu_tipo_custodia
   where  tc_tipo  = @w_tipo_esp
   union
   select @@spid,tc_tipo 
   from   cob_custodia..cu_tipo_custodia
   where  tc_tipo_superior  = @w_tipo_esp
   union
   select @@spid,tc_tipo 
   from   cob_custodia..cu_tipo_custodia
   where  tc_tipo_superior in (select tc_tipo from cob_custodia..cu_tipo_custodia
                               where  tc_tipo_superior = @w_tipo_esp)

   if exists (select 1 from ca_garantias_tramite 
              where gp_sesion = @@spid
              and   cu_tipo in (select ge_tipo from gar_especiales
                                where ge_sesion = @@spid ))
   select @w_garantia_especial  = 'S'
   else
   select @w_garantia_especial  = 'N'


   if @w_garantia_especial  = 'S'   ---si tiene garantia especial
   begin
      if exists (select 1 from ca_rubro_op
                 where (ro_concepto   = @w_parametro_fag or ro_concepto not in (select rre_concepto from #rubros_oped where tipo_concepto = 'DES'))
                 and   ro_operacion  = @w_operacionca)
      select @w_fag = 'k'
      else
      select @w_fag = 'x'

      if exists (select 1 from ca_rubro_op
                 where (ro_concepto   = @w_parametro_fng or ro_concepto not in (select rre_concepto from #rubros_oped where tipo_concepto = 'DES'))
                 and   ro_operacion  = @w_operacionca)
      select @w_fng = 'k'
      else 
      select @w_fng = 'x'

      if exists (select 1 from ca_rubro_op
                 where ro_concepto   = @w_parametro_fogacafe
                 and   ro_operacion  = @w_operacionca)
      select @w_fog = 'k'
      else 
      select @w_fog = 'x'


      if exists (select 1 from ca_rubro_op
                 where (ro_concepto   = @w_parametro_usaid or ro_concepto not in (select rre_concepto from #rubros_oped where tipo_concepto = 'DES'))
                 and   ro_operacion  = @w_operacionca)
      select @w_usaid = 'k'
      else 
      select @w_usaid = 'x'
      
      if exists (select 1 from ca_rubro_op
                 where (ro_concepto   = @w_parametro_comfga or ro_concepto not in (select rre_concepto from #rubros_oped where tipo_concepto = 'DES'))
                 and   ro_operacion  = @w_operacionca)
      select @w_comfga = 'k'
      else 
      select @w_comfga = 'x'

      if exists (select 1 from ca_rubro_op
                 where ro_concepto   = @w_parametro_fgu
                 and   ro_operacion  = @w_operacionca)
      select @w_comfgu = 'k'
      else 
      select @w_comfgu = 'x'

      if @w_fag = 'x' and @w_fng = 'x' and @w_fog = 'x' and @w_usaid = 'x' and @w_comfga = 'x' and @w_comfgu = 'x'
      begin
         select @w_error = 710564
         goto ERROR 
      end
   end
end


NEXT:

delete ca_garantias_tramite
where  gp_sesion = @@spid

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug ='N',    
        @t_file  = null,
        @t_from  = @w_sp_name,   
        @i_num   = @w_error
   return @w_error
go


