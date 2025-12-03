/****************************************************************/
/* ARCHIVO:              sp_vencimiento.sp                      */
/* Stored procedure:	 sp_vencimiento	          	            */
/* BASE DE DATOS:        cob_custodia 					        */
/* PRODUCTO:             GARANTIAS              	            */
/****************************************************************/
/*                         IMPORTANTE                           */
/* Esta aplicacion es parte de los paquetes bancarios propiedad */
/* de MACOSA S.A.						                        */
/* Su uso no  autorizado queda  expresamente prohibido asi como */
/* cualquier  alteracion  o agregado  hecho por  alguno  de sus */
/* usuarios sin el debido consentimiento por escrito de MACOSA. */
/* Este programa esta protegido por la ley de derechos de autor */
/* y por las  convenciones  internacionales de  propiedad inte- */
/* lectual.  Su uso no  autorizado dara  derecho a  MACOSA para */
/* obtener  ordenes de  secuestro o retencion y  para perseguir */
/* penalmente a los autores de cualquier infraccion.            */
/****************************************************************/
/*                      MODIFICACIONES                          */
/* FECHA               AUTOR                         RAZON      */
/* 28/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/* 04/May/2019       Mariela Cabay  	        Moneda por param*/
/****************************************************************/


USE cob_custodia
go

IF OBJECT_ID('dbo.sp_vencimiento') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_vencimiento
    IF OBJECT_ID('dbo.sp_vencimiento') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_vencimiento >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_vencimiento >>>'
END
go
create proc sp_vencimiento (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_filial             tinyint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo_cust          descripcion  = null,
   @i_custodia           int  = null,
   @i_vencimiento        smallint  = null,
   @i_custodia_desde     int  = null,
   @i_fecha_emision      datetime = null, ---GCR:Fecha de Emision
   @i_fecha              datetime  = null, ---GCR: Fecha de Vencimiento
   @i_fecha_tol          datetime = null, ---GCR: Fecha Efectiva (con Tolerancia)
   @i_subtotal           money = null, ---GCR
   @i_iva                money = null, ---GCR
   @i_valor              money = null,
   @i_ret_iva            money = null, ---GCR
   @i_ret_fte            money = null, ---GCR
   @i_instruccion        varchar(255)  = null,
   @i_sujeto_cobro       char(  1)  = null,
   @i_num_factura        varchar( 20)  = null,
   @i_cta_debito         ctacliente  = null,
   @i_mora           	 money = 0,
   @i_comision		 money = null,
   @i_formato_fecha      int     = null,
   @i_cond1              descripcion = null,
   @i_cond2              descripcion = null,
   @i_cond3              descripcion = null,
   @i_cond4              descripcion = null,
   @i_cond5              descripcion = null,
   @i_param1             descripcion = null,
   @i_estado_colateral   char(1) = null,
   @i_fecha_salida       datetime = null,
   @i_fecha_retorno      datetime = null,
   @i_destino_colateral  catalogo = null,
   @i_segmento           catalogo = null,
   @i_login              varchar(30) = null,
   @i_colateral          char(1)     = null,
   @i_beneficiario       varchar(64) = null,
   @i_deudor             int  = null, ---GCR
   @i_cliente            int = null, ---GCR
   @i_estado             catalogo = null, ---GCR
   @i_banco              varchar(30) = null, --REF:LRC feb.16.2009 catalogo = null, ---GCR
   @i_cedruc             varchar(30) = null, ---GCR
   @i_tolerancia         tinyint = null, ---GCR
   @i_localidad          int = null, ---GCR
   @i_razon_rechazo      catalogo = null, ---GCR
   @i_propietario        descripcion = null, ---GCR
   @i_secuencial         int = null, ---GCR
   @i_tramite            int = null,      --LRE 25/May/2007
   @i_estado_ini         char(1)  = null, --LRE 25/May/2007
   @i_estado_fin         char(1)  = null,  --LRE 25/May/2007
   --II LRC 12/10/2009
   @i_descuento          money = null,
   @i_porc_iva           float = null,
   @i_porc_ret_fte       float = null,
   --FI LRC 12/10/2009
   @i_fecha_desde        datetime = null,
   @i_fecha_hasta        datetime = null 
)

as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo_cust          descripcion,
   @w_custodia           int,
   @w_vencimiento        smallint,
   @w_fecha              datetime,
   @w_valor              money,
   @w_instruccion        varchar(255),
   @w_sujeto_cobro       char(  1),
   @w_num_factura        varchar( 20),
   @w_cta_debito         ctacliente,
   @w_ultimo		 smallint,
   @w_error              int,
   @w_mora               money,
   @w_comision           money,
   @w_monto_comision     money,
   @w_diferencia         money,
   @w_diferencia1        money,
   @w_des_tipo		 descripcion,
   @w_total_vencimiento  money,
   @w_total_mora         money, 
   @w_total_comision     money,
   @w_suma_ven           money,
   @w_suma_rec           money,
   @w_codigo_externo     varchar(64),
   @w_estado_colateral   char(1),
   @w_estado             char(1),
   @w_fecha_salida       datetime,
   @w_fecha_retorno      datetime,
   @w_destino_colateral  catalogo,
   @w_segmento           catalogo,
   @w_des_estado_col     varchar(30),  
   @w_des_destino_col    varchar(30),  
   @w_des_segmento       varchar(30),
   @w_moneda             tinyint,
   @w_status             int,
   @w_valor_actual       money,
   @w_estado_gar         char(1),
   @w_contabilizar       char(1),
   @w_beneficiario       varchar(64),
   @w_banco              catalogo, ---GCR
   @w_des_banco          varchar(30), ---GCR
   @w_cliente            int, ---GCR
   @w_grupo              int, ---GCR
   @w_grupo_deu          int, ---GCR
   @w_estado_ve          catalogo, ---GCR
   @w_des_estado         varchar(30), ---GCR
   @w_deudor             int, ---GCR   
   @w_msg_error          descripcion, ---GCR
   @w_ddr                tinyint, ---GCR
   @w_tolmax             tinyint, ---GCR
   @w_fecha_aux          datetime, ---GCR
   @w_fecha_tolerancia   datetime, ---GCR
   @w_fecha_emision      datetime, ---GCR
   @w_ciudad             int, ---GCR
   @w_localidad          int, ---GCR
   @w_des_localidad      descripcion, ---GCR
   @w_causal_vin         catalogo, ---GCR
   @w_tipo_vin           catalogo, ---GCR
   @w_vinculado          char(1), ---GCR
   @w_siguiente          int, ---GCR
   @w_fecha_vcto_gar     datetime, ---GCR
   @w_valor_gar          money, ---GCR
   @w_oficial            smallint, ---GCR
   @w_secuencial         int, ---GCR
   @w_subtotal           money, ---GCR
   @w_iva                money, ---GCR
   @w_ret_iva            money, ---GCR
   @w_ret_fte            money, ---GCR
   @w_estado_op          tinyint, ---GCR
   @w_etapa_inicial      tinyint, ---GCR
   @w_etapa_control      tinyint, ---GCR
   @w_tramite            int, ---GCR
   @w_carchq             catalogo,     --LRE 23/Mayo/07
   @w_pagares_lc         catalogo,     --LRE 23/Mayo/07
   @w_facturas           catalogo,     --LRE 23/Mayo/07
   @w_tipo               descripcion,   --LRE 29/Mayo/07
   @w_fuente_valor       catalogo,
   @w_girador            int,
   @w_fecha_dep          varchar(10),
   @w_msg_fdep           descripcion, 
   @w_cedruc             varchar(30),
   @w_descuento          money,
   @w_porc_iva           float,
   @w_porc_ret_fte       float,
   @w_cambio_formato     datetime,
   @w_valor_aux          money,
   @pos                  INT, --numeric(20),
   @piece                varchar(50),
   @string               varchar(500),
   @w_garchq             catalogo     --DAR 24/Oct/2013   

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_vencimiento'

/***********************************************************/
/* Codigos de Transacciones                                */


if (@t_trn <> 19030 and @i_operacion = 'I') or
   (@t_trn <> 19031 and @i_operacion = 'U') or
   (@t_trn <> 19032 and (@i_operacion = 'D' or @i_operacion = 'R')) or ---GCR
   (@t_trn <> 19033 and @i_operacion = 'V') or
   (@t_trn <> 19034 and @i_operacion = 'S') or
   (@t_trn <> 19035 and @i_operacion = 'Q') or
   (@t_trn <> 19036 and @i_operacion = 'A') or
   (@t_trn <> 19037 and @i_operacion = 'T') or ---GCR
   (@t_trn <> 19038 and (@i_operacion = 'Z' or @i_operacion = 'E' or @i_operacion = 'X')) ---GCR   
   --@i_operacion = 'C' 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end
select @w_moneda = pa_tinyint 
from cl_parametro 
where  pa_producto = 'ADM' 
and pa_nemonico = 'MLO'

--II LRC 12/14/2009
select @w_cambio_formato = dateadd(dd,1,getdate())
if @i_tipo_cust = '920' or 
  --II LRC 02/11/2010 en pantalla de notificacion no se eniva @i_tipo_cust
  (@i_tipo_cust = null 
   and exists (select 1
                 from /*cob_credito..cr_gar_propuesta,*/ cob_custodia..cu_custodia
                where --gp_tramite = @i_tramite
                 -- and cu_codigo_externo = gp_garantia
                 /* and*/ cu_tipo = '920'))
  --FI LRC 02/11/2010 
begin
  /*select @w_cambio_formato = pa_char
    from cobis..cl_parametro
   where pa_producto = 'CRE'
     and pa_nemonico = 'NFFACT'*/
	 print 'pendiente'
end
--FI LRC 12/14/2009

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
    select 
         @w_filial = ve_filial,
         @w_sucursal = ve_sucursal,
         @w_tipo_cust = ve_tipo_cust,
         @w_custodia = ve_custodia,
         @w_vencimiento = ve_vencimiento,
         @w_fecha = ve_fecha,         
         @w_valor = ve_valor,
         @w_instruccion = ve_instruccion,
         @w_sujeto_cobro = ve_sujeto_cobro,
         @w_num_factura = ve_num_factura,
         @w_cta_debito = ve_cta_debito,
         @w_mora = ve_mora,
         @w_comision = ve_comision,
         @w_codigo_externo = ve_codigo_externo,
         @w_estado_colateral = ve_estado_colateral,
         @w_fecha_salida = ve_fecha_salida,
         @w_fecha_retorno = ve_fecha_retorno,
         @w_destino_colateral = ve_destino_colateral,
         @w_segmento = ve_segmento,
         @w_beneficiario = ve_beneficiario,
         @w_localidad = ve_localidad, ---GCR
         @w_cliente = ve_deudor, ---GCR
         @w_banco = ve_banco, ---GCR
         @w_tolmax = ve_tolerancia, ---GCR
         @w_fecha_tolerancia = ve_fecha_tolerancia, ---GCR
         @w_fecha_emision    = ve_fecha_emision, ---GCR
         @w_estado_ve = ve_estado, ---GCR
         @w_subtotal = ve_subtotal, ---GCR
         @w_iva = ve_iva, ---GCR
         @w_ret_iva = ve_ret_iva, ---GCR
         @w_ret_fte = ve_ret_fte, ---GCR
         @w_cedruc = ve_ced_ruc,   --REF:LRC feb.26.2009
         --II LRC 12/10/2009
         @w_descuento = ve_descuento,
         @w_porc_iva  = ve_porc_iva,
         @w_porc_ret_fte = ve_porc_ret_fte
         --FI LRC 12/10/2009
    from cob_custodia..cu_vencimiento
    where 
         ve_filial = @i_filial and
         ve_sucursal = @i_sucursal and
         ve_tipo_cust = @i_tipo_cust and
         ve_custodia = @i_custodia and
         ve_vencimiento = @i_vencimiento

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin

    --REF:LRC feb.26.2009 Inicio
    /*select @w_carchq = pa_char
      from cobis..cl_parametro
     where pa_producto = 'CCA'
       and pa_nemonico = 'GARCHE'

    select @w_garchq = pa_char
      from cobis..cl_parametro
     where pa_producto = 'CCA'
       and pa_nemonico = 'CHQCOB'*/
     
    if @i_tipo_cust not in (@w_carchq, @w_garchq)
    begin
    --REF:LRC feb.26.2009 Fin
      ---Dias minimos entre la fecha de emision y la fecha de proceso
      /*select @w_ddr = pa_tinyint
        from cobis..cl_parametro
       where pa_producto = 'GAR'
         and pa_nemonico = 'DDR'*/
    
      if datediff(dd,@i_fecha_emision,@s_date) < @w_ddr
      begin
        exec cobis..sp_cerror	
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901026
        return 1 
      end
    
      if exists (select 1
                 from cu_vencimiento
                where ve_deudor = @i_cliente               
                  and ve_num_factura = @i_num_factura
                  and ve_tipo_cust = @i_tipo_cust) and @i_operacion = 'I'
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901002
         return 1 
      end
      
      if @i_fecha < @s_date 
      begin 
      /* La fecha de vencimiento debe ser mayor o igual a la fecha actual */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1903007
        return 1 
      end              
   else
      if exists (select 1
                 from cu_vencimiento
                where ve_num_factura = @i_num_factura
                  and ve_banco = @i_banco
                  and ve_tipo_cust = @i_tipo_cust) and @i_operacion = 'I'
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901002
         return 1 
      end   
   end

  /*        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
*/

   select @w_estado_gar = cu_estado
     from cu_custodia
    where cu_codigo_externo = @w_codigo_externo 


   if @w_estado_gar = 'C' or @w_estado_gar = 'A' --Cancelado
   begin		/*****la parte de abajo ya estaba comentado*******/

   /* LG 02/02/2016 Se quita emision de mensaje a pedido de Lidia Tutiven*/   
   /* No puede registrar vencimientos de una garantia cancelada */
   /*    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1905010*/
       return 1 
   end 

   ---GCR:Seccion Eliminada   
    
   if @i_filial is NULL or 
      @i_sucursal is NULL or 
      @i_tipo_cust is NULL or 
      @i_custodia is NULL or 
      @i_valor is NULL 

   begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
   end

   if @i_tolerancia is null
   begin
      select @w_tolmax = isnull(datediff (dd, @i_fecha,@i_fecha_tol),0)
      select @i_tolerancia = @w_tolmax
   end

   if @i_estado not in ('I', 'N', 'T','C','D') ---GCR: Solo se admiten estos estados
   begin   
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901025
        return 1 
   end


   if @i_tipo_cust not in (@w_carchq, @w_garchq)
   begin
	   select @w_tramite = null
	   /*select @w_tramite = op_tramite,
		  @w_estado_op = op_estado
	     from cob_credito..cr_gar_propuesta,
		  cob_cartera..ca_operacion
	    where gp_tramite = op_tramite
	      and gp_garantia = @w_codigo_externo*/

	   if @w_tramite is not null
	   begin
	       ---Cantidad de veces que ha pasado por la estacion inicial
	     /*select @w_etapa_inicial = count(1)
			 from cob_credito..cr_ruta_tramite
			 where rt_tramite = @w_tramite
		  and rt_paso = 1*/

	       ---Cantidad de veces que ha pasado por la etapa LEGAL
	     /*select @w_etapa_control = count(1)
		 from cob_credito..cr_ruta_tramite
		where rt_tramite = @w_tramite
		  and rt_etapa = 3
		  and rt_salida is not null*/
		  print 'pendiente'
	   end

	   --
	   if @i_estado = 'I' 
	   begin
	      if (@w_tramite is not null) and not ((@w_etapa_inicial < @w_etapa_control) or @w_estado_op = 99)
	      begin   
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 1901028
		return 1 
	      end

	      if (@w_tramite is not null) and ( @w_estado_op <> 99)
	      begin   
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 1901028
		return 1 
	      end

	   end

	   if @i_estado = 'N' 
	   begin
	      if (@w_tramite is null) 
	      begin   
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 1901028
		return 1 
	      end

	      if (@w_etapa_inicial > @w_etapa_control) or (@w_estado_op not in (0,99))
	      begin      
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 1901028
		return 1 
	      end
	   end        

	   if @i_estado = 'T' 
	   begin
	      if (@w_tramite is null) or (@w_estado_op in (0,99,3,11))
	      begin   
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 1901028
		return 1 
	      end
	   end
   end --@i_tipo_cust <> @w_carchq

end

/* Insercion del registro */
/**************************/

if @i_operacion = 'I'
begin
    if @w_existe = 1
    begin
    /* Registro ya existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1 
    end

   if @i_tipo_cust not in  (@w_carchq, @w_garchq)
   begin
	   ---GCR:Control para no exeder monto de la garantia   
	   --II LRC 12/14/2009
	   select @w_valor_aux = @i_valor
	   if (select cu_fecha_ingreso 
		 from cob_custodia..cu_custodia
		where cu_codigo_externo = @w_codigo_externo) < @w_cambio_formato
	   begin
	     select @w_suma_ven = isnull(sum(ve_valor),0)        
	       from cu_vencimiento
	      where ve_codigo_externo = @w_codigo_externo 
		and ve_estado not in ('D','V','P')     
	   end
	   else
	   begin
	     select @w_suma_ven = isnull(sum(ve_valor - ve_ret_fte),0)
	       from cu_vencimiento
	      where ve_codigo_externo = @w_codigo_externo 
		and ve_estado not in ('D','V','P')
	     select @w_valor_aux = @w_valor_aux - @i_ret_fte        
	   end
	   --FI LRC 12/14/2009

	    select @w_diferencia = isnull(cu_valor_actual,0) 
				   - (@w_suma_ven + @w_valor_aux) --LRC 12/16/2009
	      from cu_custodia   
	     where cu_codigo_externo = @w_codigo_externo 

	    if @w_diferencia < 0
	    begin 
	    /* Valor de la diferencia debe ser positiva */
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 1903004
		return 1 
	    end  
    end --@i_tipo_cust <> @w_carchq

    begin tran
       select @w_ultimo = isnull(max(ve_vencimiento),0)+1
         from cu_vencimiento
        where ve_filial    = @i_filial 
          and ve_sucursal  = @i_sucursal
          and ve_tipo_cust = @i_tipo_cust
          and ve_custodia  = @i_custodia

       ---GCR:Seccion Eliminada
 
         insert into cu_vencimiento(
              ve_filial,
              ve_sucursal,
              ve_tipo_cust,
              ve_custodia,
              ve_vencimiento,
              ve_fecha_emision, ---GCR
              ve_fecha,
              ve_subtotal, ---GCR
              ve_iva, ---GCR
              ve_valor,
              ve_ret_iva, ---GCR
              ve_ret_fte, ---GCR
              ve_instruccion,
              ve_sujeto_cobro,
              ve_num_factura,
              ve_cta_debito,
              ve_mora,
              ve_comision,
              ve_codigo_externo,
              ve_estado_colateral,
              ve_fecha_salida,
              ve_fecha_retorno,
              ve_destino_colateral,
              ve_segmento,
              ve_beneficiario,              
              ve_banco, ---GCR
              ve_deudor, ---GCR
              ve_localidad, ---GCR
              ve_tolerancia, ---GCR
              ve_fecha_tolerancia, ---GCR
              ve_estado, ---GCR
              ve_ced_ruc,  --REF:LRC feb.26.2009
              --II LRC 12/14/2009
              ve_descuento,
              ve_porc_iva,
              ve_porc_ret_fte)
              --FI LRC 12/14/2009
         values (
              @i_filial,
              @i_sucursal,
              @i_tipo_cust,
              @i_custodia,
              @w_ultimo,
              @i_fecha_emision, ---GCR
              @i_fecha,
              @i_subtotal, ---GCR
              @i_iva, ---GCR
              @i_valor,
              @i_ret_iva, ---GCR
              @i_ret_fte, ---GCR
              @i_instruccion,
              @i_sujeto_cobro,
              @i_num_factura,
              @i_cta_debito,
              @i_mora,
              @w_monto_comision,
              @w_codigo_externo,
              @i_estado_colateral,
              @i_fecha_salida, 
              @i_fecha_retorno, 
              @i_destino_colateral,
              @i_segmento,
              @i_beneficiario,
              @i_banco, ---GCR
              @i_cliente, ---GCR
              @i_localidad, ---GCR
              @i_tolerancia, ---GCR
              @i_fecha_tol, ---GCR
              @i_estado, ---GCR
              @i_cedruc,  --REF:LRC feb.26.2009
              --II LRC 12/14/2009
	      @i_descuento,
              @i_porc_iva,
              @i_porc_ret_fte
              )
              --FI LRC 12/14/2009
              
         if @@error <> 0 
         begin

         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_vencimiento
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_vencimiento',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_vencimiento,
         @i_fecha,
         @i_subtotal, ---GCR
         @i_iva, ---GCR
         @i_valor,
         @i_ret_iva, ---GCR
         @i_ret_fte, ---GCR
         @i_instruccion,
         @i_sujeto_cobro,
         @i_num_factura,
         @i_cta_debito,
         @i_mora,
         @i_comision,
         @w_codigo_externo,
         @i_estado_colateral,
         @i_fecha_salida, 
         @i_fecha_retorno, 
         @i_destino_colateral,
         @i_segmento,
         @i_cliente, ---GCR
         @i_localidad, ---GCR
         @i_banco, ---GCR
         @i_tolerancia, ---GCR
         @i_fecha_tol, ---GCR
         @i_estado, ---GCR
         --II LRC 12/10/2009
         @i_descuento,
         @i_porc_iva,
         @i_porc_ret_fte)
         --FI LRC 12/10/2009

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end 
         select @w_ultimo
    commit tran 
    return 0
end


/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin
    if @w_existe = 0
    begin
    /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
    end

    --Aumentado por LCA
    if exists(select * from cu_recuperacion
               where re_codigo_externo = @w_codigo_externo
                 and re_vencimiento    = @i_vencimiento)
    begin
    /* Ya tiene recuperaciones */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907008
        return 1 
    end

   --DAR 01OCT2013
   if @i_tipo_cust not in (@w_carchq, @w_garchq)
   begin

	    --PSE 26/Abr/07, control para Factoring
	    if exists (select 1
			 /*from cob_credito..cr_gar_propuesta,cob_cartera..ca_operacion
			  where gp_tramite = op_tramite         
			  and gp_garantia = @w_codigo_externo
			  and op_estado not in (0,3,11,99)*/)
			
	    begin    
		exec cobis..sp_cerror
		  @t_debug = @t_debug,
		  @t_file  = @t_file, 
		  @t_from  = @w_sp_name,
		  @i_num   = 1905016
		return 1 
	    end

	    ---GCR:Control para no exeder monto de la garantia
	   --II LRC 12/14/2009
	   select @w_valor_aux = @i_valor
	   if (select cu_fecha_ingreso 
		 from cob_custodia..cu_custodia
		where cu_codigo_externo = @w_codigo_externo) < @w_cambio_formato
	   begin    
	     select @w_suma_ven = isnull(sum(ve_valor),0)
	       from cu_vencimiento
	      where ve_codigo_externo = @w_codigo_externo
		and ve_estado not in ('D','V','P')
		and ve_vencimiento <> @i_vencimiento

	   end
	   else
	   begin
	     select @w_suma_ven = isnull(sum(ve_valor - ve_ret_fte),0)
	       from cu_vencimiento
	      where ve_codigo_externo = @w_codigo_externo
		and ve_estado not in ('D','V','P')
		and ve_vencimiento <> @i_vencimiento   
	     select @w_valor_aux = @w_valor_aux - @i_ret_fte   
	   end
	   --FI LRC 12/14/2009

	    select @w_diferencia = isnull(cu_valor_actual,0) 
				   - (@w_suma_ven + @w_valor_aux) --LRC 12/16/2009
	      from cu_custodia   
	     where cu_codigo_externo = @w_codigo_externo 

	    if @w_diferencia < 0
	    begin 
	    /* Valor de la diferencia debe ser positiva */
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 1903004
		return 1 
	    end  

    end --@i_tipo_cust <> @w_carchq


    --Aumentado por LCA
      
    begin tran
         update cob_custodia..cu_vencimiento
         set  ve_fecha_emision = @i_fecha_emision, ---GCR
              ve_fecha = @i_fecha,
              ve_subtotal = case when @i_tipo_cust = @w_garchq then isnull(@i_subtotal,@i_valor) else @i_subtotal end,
              ve_iva = @i_iva, ---GCR
              ve_valor = @i_valor,
              ve_ret_iva = @i_ret_iva, ---GCR
              ve_ret_fte = @i_ret_fte, ---GCR
              ve_instruccion = @i_instruccion,
              ve_sujeto_cobro = @i_sujeto_cobro,
              ve_num_factura = @i_num_factura,
              ve_cta_debito = @i_cta_debito,
              ve_mora = @i_mora,
              ve_comision = @w_comision,
              ve_codigo_externo = @w_codigo_externo,
              ve_estado_colateral = @i_estado_colateral,
              ve_fecha_salida = @i_fecha_salida,
              ve_fecha_retorno = @i_fecha_retorno,
              ve_destino_colateral = @i_destino_colateral,
              ve_segmento = @i_segmento,
              ve_beneficiario = @i_beneficiario,
              ve_deudor = @i_cliente, ---GCR
              ve_localidad = @i_localidad, ---GCR
              ve_banco = @i_banco, ----GCR
              ve_tolerancia = @i_tolerancia, ---GCR
              ve_fecha_tolerancia = @i_fecha_tol, ---GCR
              ve_estado = @i_estado, ---GCR
              ve_ced_ruc = @i_cedruc,  --REF:LRC feb.26.2009
              --II LRC 12/14/2009
              ve_descuento = @i_descuento,
              ve_porc_iva  = @i_porc_iva,
              ve_porc_ret_fte = @i_porc_ret_fte
              --FI LRC 12/14/2009
         where 
         ve_filial = @i_filial and
         ve_sucursal = @i_sucursal and
         ve_tipo_cust = @i_tipo_cust and
         ve_custodia = @i_custodia and
         ve_vencimiento = @i_vencimiento

         if @@error <> 0 
         begin
         /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1 
         end

         ---GCR:seccion Eliminada

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_vencimiento
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_vencimiento',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_vencimiento,
         @w_fecha,
         @w_subtotal, ---GCR
         @w_iva, ---GCR
         @w_valor,
         @w_ret_iva, ---GCR
         @w_ret_fte, ---GCR
         @w_instruccion,
         @w_sujeto_cobro,
         @w_num_factura,
         @w_cta_debito,
         @w_mora,
         @w_comision,
         @w_codigo_externo,
         @w_estado_colateral,
         @w_fecha_salida, 
         @w_fecha_retorno, 
         @w_destino_colateral,
         @w_segmento,
         @w_cliente, ---GCR
         @w_localidad, ---GCR
         @w_banco, ---GCR
         @w_tolmax, ---GCR
         @w_fecha_tolerancia, ---GCR
         @w_estado_ve, ---GCR
         --FI LRC 12/10/2009
         @w_descuento,
         @w_porc_iva,
         @w_porc_ret_fte)
         --II LRC 12/10/2009

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end            


         /* Transaccion de Servicio */
         /***************************/

         insert into ts_vencimiento
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_vencimiento',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_vencimiento,
         @i_fecha,
         @i_subtotal, ---GCR
         @i_iva, ---GCR
         @i_valor,
         @i_ret_iva, ---GCR
         @i_ret_fte, ---GCR
         @i_instruccion,
         @i_sujeto_cobro,
         @i_num_factura,
         @i_cta_debito,
         @i_mora,
         @i_comision,
         @w_codigo_externo,
         @i_estado_colateral,
         @i_fecha_salida, 
         @i_fecha_retorno, 
         @i_destino_colateral,
         @i_segmento,
         @i_cliente, ---GCR
         @i_localidad, ---GCR
         @i_banco, ---GCR
         @i_tolerancia, ---GCR
         @i_fecha_tol, ---GCR
         @i_estado, ---GCR
         --II LRC 12/10/2009
         @i_descuento,
         @i_porc_iva,
         @i_porc_ret_fte)
         --FI LRC 12/10/2009         

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Eliminacion de registros */
/****************************/

if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
    /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1 
    end

/***** Integridad Referencial *****/
/*****                        *****/
    /* CONTROLAR QUE NO SE ELIMINEN VENCIMIENTOS CON RECUPERACIONES */
    if exists (select 1 from cu_recuperacion
                where re_codigo_externo = @w_codigo_externo
                  and re_vencimiento = @i_vencimiento)
       return 2   -- No se puede eliminar
    else
    begin
    begin tran
         delete cob_custodia..cu_vencimiento
         where 
             ve_filial = @i_filial and
             ve_sucursal = @i_sucursal and
             ve_tipo_cust = @i_tipo_cust and
             ve_custodia = @i_custodia and
             ve_vencimiento = @i_vencimiento 
                                        
         if @@error <> 0
         begin
         /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1907001
             return 1 
         end
            

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_vencimiento
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_vencimiento',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_vencimiento,
         @w_fecha,
         @w_subtotal, ---GCR
         @w_iva, ---GCR
         @w_valor,
         @w_ret_iva, ---GCR
         @w_ret_fte, ---GCR
         @w_instruccion,
         @w_sujeto_cobro,
         @w_num_factura,
         @w_cta_debito,
         @w_mora, 
         @w_comision,
         @w_codigo_externo,
         @w_estado_colateral,
         @w_fecha_salida, 
         @w_fecha_retorno, 
         @w_destino_colateral,
         @w_segmento,
         @w_cliente, ---GCR
         @w_localidad, ---GCR
         @w_banco, ---GCR
         @w_tolmax, ---GCR
         @w_fecha_tolerancia, ---GCR
         @w_estado_ve,  ---GCR
         --II LRC 12/10/2009
         @w_descuento,
         @w_porc_iva,
         @w_porc_ret_fte)
         --FI LRC 12/10/2009         

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
    end
end

/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if @w_existe = 1
    begin 

         select @w_des_estado_col = A.valor
           from cobis..cl_catalogo A,cobis..cl_tabla B
           where B.codigo = A.tabla and
               B.tabla = 'cu_estado_colateral' and
               A.codigo = @w_estado_colateral

         select @w_des_destino_col = A.valor
           from cobis..cl_catalogo A,cobis..cl_tabla B
           where B.codigo = A.tabla and
               B.tabla = 'cu_destino_colateral' and
               A.codigo = @w_destino_colateral

         select @w_des_segmento = A.valor
           from cobis..cl_catalogo A,cobis..cl_tabla B
           where B.codigo = A.tabla and
               B.tabla = 'cu_segmento' and
               A.codigo = @w_segmento

        /* select @w_des_banco = ba_descripcion 
           from cobis..cl_banco_rem
          where convert(varchar(10),ba_banco) = @w_banco
            and ba_estado = 'V'*/

         --DAR 01OCT2013
         --buscar por coincidencia el codigo del banco
         if @@rowcount = 0
         begin
                select @w_des_banco = @w_banco 
                select @string = @w_des_banco
		select @pos = patindex('% %' , @string)
		while @pos <> 0
		begin
		   select @piece =LEFT(@string, @pos-1)
		   select @string = stuff(@string,1, @pos,NULL)
		   select @pos = charindex(' ' , @string)
		end
		--print @string  --Ultima palabra del string //ya estaba esta linea comentada
                select @string = '%' + upper(@string) + '%'
                /*select @w_banco = convert(varchar(10),ba_banco)
                  from cobis..cl_banco_rem
                 where ba_descripcion  like @string 
                   and ba_estado = 'V'*/
		       
         end

         select @w_des_estado = A.valor
           from cobis..cl_catalogo A,cobis..cl_tabla B
           where B.codigo = A.tabla and
               B.tabla = 'cu_estado_docum' and
               A.codigo = @w_estado_ve


         select @w_des_tipo = tc_descripcion
           from cu_tipo_custodia
          where tc_tipo = @w_tipo_cust

         select @w_total_vencimiento = sum(re_valor),
                @w_total_mora        = sum(re_cobro_mora),
                @w_total_comision    = sum(re_cobro_comision)
           from cu_recuperacion
          where re_codigo_externo = @w_codigo_externo
            and re_vencimiento = @i_vencimiento          

         /*select @w_des_localidad = ci_descripcion
           from cobis..cl_ciudad
          where ci_ciudad = @w_localidad  */       

         select 
              @w_filial,
              @w_sucursal,
              @w_tipo_cust,
              @w_des_tipo,
              @w_custodia,  --5
              @w_vencimiento,
              convert(char(10),@w_fecha,@i_formato_fecha),
              @w_valor,  --8
              @w_instruccion,
              @w_num_factura, -- 10
              @w_total_vencimiento,
              @w_total_mora,
              @w_total_comision,  
              @w_estado_colateral, -- 14
              @w_des_estado_col,
              @w_destino_colateral,
              @w_des_destino_col,
              @w_segmento, 
              @w_des_segmento,
              convert(char(10),@w_fecha_salida,@i_formato_fecha),
              convert(char(10),@w_fecha_retorno,@i_formato_fecha),
              @w_beneficiario,  -- 22
              @w_cliente,       ---GCR
              @w_banco, ---GCR   24
              @w_des_banco, ---GCR  25
              @w_estado_ve, ---GCR  26
              @w_des_estado, ---GCR 
              @w_cta_debito, ---GCR 
              convert(char(10),@w_fecha_emision,@i_formato_fecha), ---GCR
              convert(char(10),@w_fecha_tolerancia,@i_formato_fecha), ---GCR 30
              @w_localidad, ---GCR
              @w_des_localidad, ---GCR
              @w_subtotal, ---GCR
              @w_iva, ---GCR
              @w_ret_iva, ---GCR
              @w_ret_fte,
              @w_cedruc,  --37
              @w_descuento  --LRC 12/14/2009              
    end 
    else
    begin
    /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005
        return 1 
    end
    return 0
end

if @i_operacion = 'S'
begin

     --DAR 08OCT2013
     --pantalla de busqueda por varias consultas
     if @i_modo = 10
     begin
	     set rowcount 20

	     select 'NRO.'        = ve_vencimiento,
	            /*'CLIENTE'     = (select en_ente from cobis..cl_ente
	                                                where en_ente = (select max(cg_ente) from cob_custodia..cu_cliente_garantia 
	                                                                                where cg_codigo_externo = V.ve_codigo_externo)),
	            'NOMBRE CLIENTE'= (select en_nomlar from cobis..cl_ente
	                                                where en_ente = (select max(cg_ente) from cob_custodia..cu_cliente_garantia 
	                                                                                where cg_codigo_externo = V.ve_codigo_externo)),*/
		    'DEUDOR'      = ve_deudor,
		    'NOMBRE GIRADOR'= substring(ve_beneficiario,1,64),
		    'DOCUMENTO'   = ve_num_factura, 
		    'VALOR.DOCUMENTO' = ve_valor,
		    'VALOR RECUPERADO' = (select isnull(sum(re_valor + re_ret_fte + re_ret_fte),0)
					    from cu_recuperacion
					   where re_codigo_externo = V.ve_codigo_externo
					     and re_vencimiento = V.ve_vencimiento),
		    'F.EMISION' = convert(char(10),ve_fecha_emision,@i_formato_fecha),
		    'F.VENCIMIENTO' = convert(char(10),ve_fecha,@i_formato_fecha),
		    'F.EFECTIVA' = convert(char(10),ve_fecha_tolerancia,@i_formato_fecha),
		    'ESTADO'= ve_estado,
		   /* 'NOMBRE BANCO' = case when isnumeric(V.ve_banco) = 1
		                          then (select ba_descripcion from cobis..cl_banco_rem
                                                               where convert(varchar(10),ba_banco) = V.ve_banco
                                                                 and ba_estado = 'V'
																 
		                               )
		                          else V.ve_banco
		                          end,*/
		    'TIPO_CUSTODIA' = ve_tipo_cust,                      
		    'CUSTODIA' = ve_custodia  --DAR
	     from cu_vencimiento V 
	     where ve_filial          = @i_filial
	       and ve_sucursal        = @i_sucursal
	       and (ve_tipo_cust      = @i_tipo_cust or @i_tipo_cust is null)
	       and (ve_deudor         = @i_cliente or @i_cliente is null)
	       and ((ve_fecha_tolerancia between @i_fecha_desde and @i_fecha_hasta) or @i_fecha_desde is null)
	       and ((ve_estado not in ('D','P','V') and @i_estado = 'PC') or  --PENDIENTES DE COBRO
	           (ve_estado = 'P' and @i_estado = 'EC') or                  --ENVIADOS AL COBRO
	           (@i_estado = 'T'))                                         --TODOS
	       and (((ve_custodia       = @i_custodia_desde and ve_vencimiento > @i_vencimiento) or  
		   (ve_custodia       > @i_custodia_desde)) or @i_custodia_desde is null)
	       order by ve_custodia,ve_vencimiento

	     if @@rowcount = 0 
	     begin
	       exec cobis..sp_cerror
		 @t_debug = @t_debug,
		 @t_file  = @t_file,
		 @t_from  = @w_sp_name,
		 @i_num   = 1901003
	       return 1
	     end                 

	     set rowcount 0

	     return 0      
     end


     --LRE 29/Mayo/2007
     if @i_modo = 99
     begin

       /*select @w_carchq = pa_char
         from cobis..cl_parametro
        where pa_producto = 'CCA'
         and pa_nemonico = 'GARCHE'

       select @w_facturas = pa_char
         from cobis..cl_parametro
        where pa_producto = 'GAR'
          and pa_nemonico = 'FAC' 

       select @w_pagares_lc = pa_char
         from cobis..cl_parametro
        where pa_producto = 'GAR'
          and pa_nemonico = 'PAG'

       select @w_garchq = pa_char
         from cobis..cl_parametro
        where pa_producto = 'CCA'
          and pa_nemonico = 'CHQCOB'*/

       select @w_tipo     = cu_tipo,
              @w_filial   = cu_filial,
              @w_sucursal = cu_sucursal,
              @w_custodia = cu_custodia
         from --cob_credito..cr_gar_propuesta, 
              cob_custodia..cu_custodia
        where --gp_garantia = cu_codigo_externo
         -- and gp_tramite = @i_tramite
          /*and*/ cu_tipo in (@w_carchq, @w_facturas,@w_pagares_lc,@w_garchq)
         

        select @i_filial   = @w_filial,
               @i_sucursal = @w_sucursal,
               @i_tipo_cust= @w_tipo,
               @i_custodia = @w_custodia
     end

     --DAR 08NOV2013
     if @i_custodia is not null and @i_vencimiento is not null
        select @i_custodia_desde = @i_custodia

     set rowcount 20
     --GCR:Nuevo esquema de la consulta

     select "NRO." = ve_vencimiento,
            "DEUDOR" = ve_deudor,
            "NOMBRE" = substring(ve_beneficiario,1,64),
            "DOCUMENTO" = ve_num_factura, 
            "SUBTOTAL" = case when ve_tipo_cust = '990' then ve_valor else isnull(ve_subtotal,0) end,
            --II LRC 12/14/2009
            "DSCTO" = isnull(ve_descuento,0), 
            "IVA" = isnull(ve_iva,0),
            "T.DOCUMENTO" = case when (select cu_fecha_ingreso 
                                       from cob_custodia..cu_custodia
                                       where cu_codigo_externo = V.ve_codigo_externo
                                    ) < @w_cambio_formato
                               then ve_valor
                               else ve_valor + ve_iva
                          end,
            --FI LRC 12/14/2009
            "RET.IVA" = isnull(ve_ret_iva,0),
            "RET.FUENTE" = isnull(ve_ret_fte,0),
            "VALOR RECUPERADO" = (select isnull(sum(re_valor + re_ret_fte + re_ret_fte),0)
                                    from cu_recuperacion
                                   where re_codigo_externo = V.ve_codigo_externo
                                     and re_vencimiento = V.ve_vencimiento),
            "F.EMISION" = convert(char(10),ve_fecha_emision,@i_formato_fecha),
            "F.VENCIMIENTO" = convert(char(10),ve_fecha,@i_formato_fecha),
            "F.EFECTIVA" = convert(char(10),ve_fecha_tolerancia,@i_formato_fecha),
            "ESTADO"= ve_estado,
            "CUSTODIA" = ve_custodia  --DAR
     from cu_vencimiento V 
     where ve_filial          = @i_filial
       and ve_sucursal        = @i_sucursal
       and (ve_tipo_cust      = @i_tipo_cust or @i_tipo_cust is null)
       and (ve_custodia       = @i_custodia or @i_custodia is null)
       and ((ve_fecha_tolerancia between @i_fecha_desde and @i_fecha_hasta) or @i_fecha_desde is null)
       and ve_estado not in ('D','P','V')
       and (ve_codigo_externo in (select cg_codigo_externo from cu_cliente_garantia 
                                   where cg_ente = @i_cliente and cg_principal = 'S') or @i_cliente is null)
       and (((ve_custodia       = @i_custodia_desde and ve_vencimiento > @i_vencimiento) or  
           (ve_custodia       > @i_custodia_desde)) or @i_custodia_desde is null)
       order by ve_custodia,ve_vencimiento
        
     if @@rowcount = 0 
     begin
       exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 1901003
       return 1
     end                 
     
     set rowcount 0

end 
---GCR:Seccion Eliminada


--REF:LRC feb.25.2009 Inicio --cheques
if @i_operacion = 'B'/*todo lo de operacion B ya estaba comentado*/
begin
     set rowcount 20
     select 'NRO.' = ve_vencimiento,
            'GIRADOR' = ve_ced_ruc,
            'NOMBRE' = substring(ve_beneficiario,1,64),
            'CHEQUE' = ve_num_factura, 
            --"SUBTOTAL" = isnull(ve_subtotal,0),
            --"IVA" = isnull(ve_iva,0),
            'VALOR' = ve_valor,
            --"RET.IVA" = isnull(ve_ret_iva,0),
            --"RET.FUENTE" = isnull(ve_ret_fte,0),
            'VALOR RECUPERADO' = (select isnull(sum(re_valor + re_ret_fte + re_ret_fte),0)
                                    from cu_recuperacion
                                   where re_codigo_externo = V.ve_codigo_externo
                                     and re_vencimiento = V.ve_vencimiento),
            'F.EMISION' = convert(char(10),ve_fecha_emision,@i_formato_fecha),
            'F.DEPOSITO' = convert(char(10),ve_fecha,@i_formato_fecha),
            'F.EFECTIVA' = convert(char(10),ve_fecha_tolerancia,@i_formato_fecha),
            'ESTADO'= ve_estado
     from cu_vencimiento V 
     where ve_filial          =  @i_filial
       and ve_sucursal        = @i_sucursal
       and ve_tipo_cust       = @i_tipo_cust
       and ve_custodia        = @i_custodia      
       and ve_estado not in ('D','P','V')
       and (ve_vencimiento > @i_vencimiento or @i_vencimiento is null)
       order by ve_vencimiento
        
     if @@rowcount = 0 and @i_vencimiento is null  
     begin
       exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 1901003
       return 1
     end                 
     set rowcount 0

end 
--REF:LRC feb.25.2009 Fin

if @i_operacion = 'A'
begin
   set rowcount 20
   ---GCR: La Consulta se realiza por Nro de Documento
   select "VENCIMIENTO"=ve_vencimiento,
          "DOCUMENTO" = ve_num_factura,           
          "DEUDOR"=substring(ve_beneficiario,1,50),
          "VALOR"=ve_valor,  --MVI 07/09/96
          "F.EMISION"=convert(char(10),ve_fecha_emision,convert(int,@i_cond5)),
          "F.VCTO"=convert(char(10),ve_fecha,convert(int,@i_cond5)),
          "F.EFECTIVA"=convert(char(10),ve_fecha_tolerancia,convert(int,@i_cond5)),
          "COD.DEUDOR" = ve_deudor          
     from cu_vencimiento
    where ve_filial    = convert(tinyint,@i_cond1)
      and ve_sucursal  = convert(smallint,@i_cond2)
      and ve_tipo_cust = @i_cond3
      and ve_custodia  = convert(int,@i_cond4)
      and ve_estado not in ('V','D','P') 
      and (ve_vencimiento > convert(tinyint,@i_param1) or @i_param1 is null)
   order by ve_vencimiento

   if @@rowcount = 0
   begin
     set rowcount 0
     if @i_param1 is null
       select @w_error = 1901003
     else
       select @w_error = 1901004

     exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = @w_error
     return 1 
   end
   set rowcount 0

end 

if @i_operacion = 'V'
begin

  /*        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
*/

   ---GCR:Valores recuperados de la factura

   select @w_ret_iva = isnull(sum(re_ret_iva),0),
          @w_ret_fte = isnull(sum(re_ret_fte),0),
          @w_suma_rec = isnull(sum(re_valor),0)
     from cu_recuperacion, cu_vencimiento
    where re_codigo_externo  = @w_codigo_externo
      and ve_codigo_externo = re_codigo_externo    
      and ve_num_factura = @i_num_factura        
      and re_vencimiento = ve_vencimiento  --LRC oct.25.2007

   select convert(char(10),ve_fecha,@i_formato_fecha),
          ve_valor,    --MVI 07/09/96
          ve_beneficiario,
          ve_deudor, ---GCR
          convert(char(10),ve_fecha_emision,@i_formato_fecha), ---GCR
          convert(char(10),ve_fecha_tolerancia,@i_formato_fecha), ---GCR
          (ve_valor - ve_ret_iva - ve_ret_fte) -  @w_suma_rec, ---GCR
          (ve_ret_iva - @w_ret_iva), ---GCR
          (ve_ret_fte - @w_ret_fte), ---GCR
          ve_vencimiento ---GCR
     from cu_vencimiento
    where ve_filial      = @i_filial
      and ve_sucursal    = @i_sucursal
      and ve_tipo_cust   = @i_tipo_cust
      and ve_custodia    = @i_custodia
---      and ve_vencimiento = @i_vencimiento GCR
      and ve_num_factura = @i_num_factura
      and ve_estado not in ('V','D','P')  ---GCR

   if @@rowcount = 0
   begin
     exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1901005
    return 1 
  end

end

if @i_operacion = 'Z'
begin
     /* Control del valor total de vencimientos  */
    select @w_diferencia = cu_valor_actual - @i_valor
      from cu_custodia
     where cu_filial     = @i_filial 
       and cu_sucursal   = @i_sucursal 
       and cu_tipo       = @i_tipo_cust
       and cu_custodia   = @i_custodia
    select @w_diferencia1 = @w_diferencia - isnull(sum(ve_valor),0) 
      from cu_vencimiento
     where ve_filial     = @i_filial 
       and ve_sucursal   = @i_sucursal 
       and ve_tipo_cust  = @i_tipo_cust
       and ve_custodia   = @i_custodia 
       and (ve_vencimiento <> @i_vencimiento or @i_vencimiento is null)
  
    if @w_diferencia1 < 0
    begin 
    /* Valor de la diferencia debe ser positiva /**ya estaba comentado***/
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1903004  */
        return 1 
    end
    return 0
 end    


---GCR:VALIDACION DE ARCHIVO EXCEL
---------------------------------
if @i_operacion = 'E'
begin

  select @w_codigo_externo = null,
         @w_msg_error = null,
         @w_deudor = null,
         @w_tolmax = 0,
         @w_fecha_tolerancia = null,
         @w_fecha_aux = null,
         @w_cliente = null,
         @w_causal_vin = null,
         @w_tipo_vin = null,
         @w_vinculado = null,         
         @w_grupo = null,
         @w_grupo_deu = null,
         @w_estado = null

  if @i_custodia <> null --- Invocado desde garantais
  begin

    ---Verificar preexistencias
    select @w_codigo_externo = cu_codigo_externo,
           @w_valor_actual = cu_valor_actual,
           @w_estado = cu_estado
      from cu_custodia
     where cu_filial = @i_filial
       and cu_sucursal = @i_sucursal
       and cu_tipo = @i_tipo_cust
       and cu_custodia = @i_custodia

    if @w_codigo_externo = null
    begin
      select @w_msg_error = 'GARANTIA NO EXISTE'
      goto SALIR
    end    

    if @w_estado in ('C','A')
    begin
      select @w_msg_error = 'GARANTIA CANCELADA O ANULADA'
      goto SALIR
    end    

  
    --En modo 1 se valida el total de valores validos del archivo
    if @i_modo = 1 
    begin

      select @w_suma_ven = isnull(sum(ve_valor),0)        
        from cu_vencimiento
       where ve_filial = @i_filial
         and ve_sucursal = @i_sucursal
         and ve_tipo_cust = @i_tipo_cust
         and ve_custodia = @i_custodia
        print 'i_valor %1!, %2!, %3!'+@i_valor+@w_suma_ven+@w_valor_actual
      if (@i_valor + @w_suma_ven) <> @w_valor_actual
      begin
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1903004
        return 1 
      end
      return 0
    end  

  end --- Invocado desde Garantias

    if not exists(select 1
                    /*from cobis..cl_ciudad
                   where ci_ciudad = @i_localidad*/)
    begin
      select @w_msg_error = 'EL CODIGO DE LOCALIDAD ES ERRONEO'
      goto SALIR
    end

    ---Dias minimos entre la fecha de emision y la fecha de proceso
    /*select @w_ddr = pa_tinyint
      from cobis..cl_parametro
     where pa_producto = 'GAR'
       and pa_nemonico = 'DDR'*/

    if datediff(dd,@i_fecha_emision,@s_date) < @w_ddr
    begin
      select @w_msg_error = 'FECHA DE EMISION GENERA DISPUTA COMERCIAL'
      goto SALIR
    end

    ----Validacion de Fechas
    if (@i_fecha_emision > @i_fecha) or
       (@i_fecha_emision > @i_fecha_tol) or
       (@i_fecha > @i_fecha_tol) 
    begin
      select @w_msg_error = 'FECHAS INCONSISTENTES'
      goto SALIR
    end
    
    ---Validar Deudor
    /*select @w_deudor = en_ente,
           @w_causal_vin = en_causal_vinculacion,
           @w_tipo_vin = en_tipo_vinculacion,
           @w_vinculado = isnull(en_vinculacion,'N'),
           @w_grupo_deu = en_grupo
      from cobis..cl_ente
     where en_ced_ruc = @i_cedruc*/

    if @w_deudor = null
    begin
      select @w_msg_error = 'NO EXISTE REGISTRO DE DEUDOR'
      goto SALIR
    end

    ---Validar Vinculados
    ---------------------
    if @i_cliente = null ----Invocado desde Garantias
       select @w_cliente = cg_ente
         from cu_cliente_garantia 
        where cg_codigo_externo = @w_codigo_externo
          and cg_principal = 'S'
    else
       select @w_cliente = @i_cliente

    if @w_deudor = @w_cliente
    begin      
      select @w_msg_error = 'DEUDOR Y CLIENTE SON EL MISMO'
      goto SALIR
    end

    /*select @w_grupo = en_grupo
      from cobis..cl_ente
     where en_ente = @w_cliente*/

    if (@w_grupo <> null and @w_grupo_deu <> null) and (@w_grupo = @w_grupo_deu)
    begin      
      select @w_msg_error = 'DEUDOR VINCULADO CON EL CLIENTE'
      goto SALIR
    end

    if @w_vinculado = 'S'
    begin      
      select @w_msg_error = 'VINCULADO, TIPO:' + isnull(@w_tipo_vin, ' ') +
                            ' CAUSAL:' + isnull(@w_causal_vin, ' ')
      goto SALIR
    end


    ---Validar Incumplidos
    -----------------------
    if exists (select 1
                 /*from cobis..cl_incumplidos
              where in_cedula = @i_cedruc
                and in_estado = 'INH'*/)
    begin      
      select @w_msg_error = 'DEUDOR INCUMPLIDO INHABILITADO'
      goto SALIR
    end


    ---Validar Banco
    ----------------
    if @i_banco <> null
    begin
       if not exists (select 1
                         /*from cobis..cl_banco_rem
                        where convert(varchar(10),ba_banco) = @i_banco
                          and ba_estado = 'V'*/)
       begin
         select @w_msg_error = 'CODIGO DE BANCO INCORRECTO'
         goto SALIR
       end
    end


-------  AME 05/21/2008 Se a¤ade logica para regularizar inconsistencia generada cuando desde garantia anulan garantia 920
      if (select cu_estado from cu_custodia,cu_vencimiento where ve_deudor = @w_deudor
                  and ve_num_factura = @i_num_factura
                  and ve_tipo_cust = @i_tipo_cust
                  and ve_codigo_externo = cu_codigo_externo ) = 'A'
          begin
             
              delete cu_vencimiento
                where ve_deudor = @w_deudor
                  and ve_num_factura = @i_num_factura
                  and ve_tipo_cust = @i_tipo_cust
          end


    if exists (select 1
                 from cu_vencimiento
                where ve_deudor = @w_deudor
                  and ve_num_factura = @i_num_factura
                  and ve_tipo_cust = @i_tipo_cust)
    begin
      select @w_msg_error = 'DOCUMENTO YA REGISTRADO'
      goto SALIR
    end     

    ---Obtener datos de Tolerancia
    ------------------------------   

    select @w_tolmax = datediff (dd, @i_fecha,@i_fecha_tol)
					/*ya estaba comentado*/
   /* select @w_ciudad = of_ciudad
      from cobis..cl_oficina
     where of_filial = @i_filial
       and of_oficina = @i_sucursal

    select @w_tolmax = isnull(to_tolerancia,0)
      from cu_tolerancia
     where to_cliente = @w_cliente
       and to_deudor = @w_deudor
       and to_tipo_cust = @i_tipo_cust
    
    if @w_tolmax <> 0
    begin
      select @w_fecha_aux = dateadd(dd,@w_tolmax, @i_fecha)

      exec @w_return = cob_cartera..sp_dia_habil 
        @i_fecha     = @w_fecha_aux,
        @i_ciudad    = @w_ciudad,
        @o_fecha     = @w_fecha_tolerancia out
   
      if @w_return !=0 begin
        select @w_msg_error = "ERROR EN CALCULO DE FECHA CON TOLERANCIA"
        goto SALIR
      end
    end
    else
      select @w_fecha_tolerancia = @i_fecha */


SALIR:
    select @w_msg_error
    select @w_deudor
    select @w_tolmax

    return 0
end    

--REF:LRC: feb.16.2009 VALIDACION DE ARCHIVO EXCEL PARA CHEQUES
---------------------------------
if @i_operacion = 'X'
begin
    select @w_fecha_dep = convert(varchar, @i_fecha, @i_formato_fecha)
    
    if not exists(select 1
                   /* from cobis..cl_ciudad
                   where ci_ciudad = @i_localidad*/)
    begin
      select @w_msg_error = 'EL CODIGO DE LOCALIDAD ES ERRONEO'
      goto SALIR2
    end

    ---Meses minimos de vigencia de un cheque
    /*select @w_ddr = pa_tinyint
      from cobis..cl_parametro
     where pa_producto = 'GAR'
       and pa_nemonico = 'MVICHQ'*/

    if datediff(mm,@i_fecha_emision,@s_date) > @w_ddr
    begin
      select @w_msg_error = 'LA FECHA DE VIGENCIA DEL CHEQUE HA EXPIRADO'
      goto SALIR2
   end

   --Validar que la fecha de deposito sea dia laborable
   /*exec @w_return = cob_cartera..sp_dia_habil
        @i_fecha    = @i_fecha,  --@i_fecha_tol,
        @i_ciudad   = @i_localidad,
        @o_fecha    = @w_fecha_aux out*/

   if @w_return != 0
   begin
     select @w_msg_error = 'ERROR AL OBTENER DIA HABIL'
     goto SALIR2
   end   
   
   if @w_fecha_aux != @i_fecha  --@i_fecha_tol
   begin
     select @w_msg_fdep = 'FECHA CORRESPONDE A DIA NO LABORABLE, SE CAMBIO FECHA DEPOSITO'
     select @w_fecha_dep = convert(varchar, @w_fecha_aux, @i_formato_fecha)     
   end
   /****ya estaba comentado inicio*****/
   ----Validacion de Fechas
   --if @i_fecha_tol < @i_fecha_emision  --fecha deposito < fecha emision
   --begin
   --  select @w_msg_error = "FECHA DEPOSITO NO PUEDE SER MENOR A FECHA DE EMISION"
   --  goto SALIR2
   --end    

   --Validar Girador y Cliente no sea el mismo 
   --en el caso de que se ingrese cedula del girador 
   /*fin**/

   /*select @w_girador = en_ente
     from cobis..cl_ente
    where en_ced_ruc = @i_cedruc*/

   if @w_girador = @i_cliente
   begin      
     select @w_msg_error = 'DEUDOR Y CLIENTE SON EL MISMO'
     goto SALIR2
   end
    
   -- Se agrega logica para regularizar inconsistencia generada cuando desde garantia anulan garantia
   if exists (select 1   --LRC 05.13.2010
         from cu_custodia, cu_vencimiento 
        where ve_ced_ruc = @i_cedruc
          and ve_num_factura = @i_num_factura  --Nro Cheque
          and ve_tipo_cust = @i_tipo_cust
          and ve_codigo_externo = cu_codigo_externo
          and cu_estado = 'A') --LRC 05.13.2010
   begin             
     delete cu_vencimiento
      where ve_ced_ruc = @i_cedruc   
        and ve_num_factura = @i_num_factura --Nro Cheque
        and ve_tipo_cust = @i_tipo_cust
   end

   --DAR 01OCT2013
   --BUSCAR COINCIDENCIA DEL NOMBRE DEL BANCO INGRESADO X EL USUARIO POR EL CODIGO DEL BANCO EN EL CATALOGO
   select @w_des_banco = @i_banco
   select @string = @w_des_banco
   select @pos = patindex('% %' , @string)
   while @pos <> 0
   begin
      select @piece =LEFT(@string, @pos-1)
      select @string = stuff(@string,1, @pos,NULL)
      select @pos = charindex(' ' , @string)
   end
   select @string = '%' + upper(@string) + '%'
   /*select @i_banco = convert(varchar(10),ba_banco)
     from cobis..cl_banco_rem
    where ba_descripcion like @string 
      and ba_estado = 'V'*/

   if @@rowcount = 0
   begin
      select @w_msg_error = 'BANCO NO EXISTE EN tabla cl_banco_rem'
      goto SALIR2
   end

   if exists (select 1
                from cu_vencimiento
               where ve_ced_ruc = @i_cedruc   
                 and ve_num_factura = @i_num_factura --Nro Cheque
                 and ve_tipo_cust = @i_tipo_cust
                 and (ve_banco = @i_banco or ve_banco like @w_des_banco))
   begin
      select @w_msg_error = 'CHEQUE YA REGISTRADO'
      goto SALIR2
   end     


SALIR2:
    --print '@w_fecha_dep %1!', @w_fecha_dep
    select @w_msg_error
    select @w_fecha_dep
    select @w_msg_fdep
    return 0
end


---GCR:RECHAZO DE DOCUMENTOS	
----------------------------
if @i_operacion = 'R'
begin

 /*        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
*/

  ---No se puede Rechazar si tiene operacion aprobada
  if exists (select 1
               from cu_vencimiento/*,
                    cob_credito..cr_gar_propuesta,
                    cob_cartera..ca_operacion*/
              where ve_codigo_externo = @w_codigo_externo /*and
                    gp_garantia = ve_codigo_externo and
                    op_tramite  = gp_tramite and
                    op_estado not in (99,3,11)*/)
  begin
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = 1905016
    return 1 
  end


  --No se puede rechazar si posee recuperaciones
  if exists (select 1 from cu_recuperacion
              where re_codigo_externo = @w_codigo_externo and
                    re_vencimiento = @i_vencimiento)
  begin
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = 1907019
    return 1 
  end

  ---GCR:Control para no exeder monto de la garantia
  --II LRC 12/14/2009
  if (select cu_fecha_ingreso 
        from cob_custodia..cu_custodia
       where cu_codigo_externo = @w_codigo_externo) < @w_cambio_formato
  begin
  --FI LRC 12/14/2009
    select @w_suma_ven = isnull(sum(ve_valor),0)
      from cu_vencimiento
     where ve_codigo_externo = @w_codigo_externo 
       and ve_estado not in ('D','V','P')
       and ve_vencimiento <> @i_vencimiento
  end
  --II LRC 12/14/2009
  else
  begin
    select @w_suma_ven = isnull(sum(ve_valor - ve_ret_fte),0)
      from cu_vencimiento
     where ve_codigo_externo = @w_codigo_externo 
       and ve_estado not in ('D','V','P')
       and ve_vencimiento <> @i_vencimiento  
  end
  --FI LRC 12/14/2009
  
  select @w_diferencia = isnull(cu_valor_actual,0) - @w_suma_ven
    from cu_custodia   
   where cu_codigo_externo = @w_codigo_externo 

  if @w_diferencia < 0
  begin 
    /* Valor de la diferencia debe ser positiva */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1903004
        return 1 
  end  

  begin tran
  
     update cu_vencimiento
        set ve_estado = 'V',
            ve_fecha_rechazo = @s_date,
            ve_razon_rechazo = @i_razon_rechazo,
            ve_desc_rechazo = @i_instruccion
      where ve_codigo_externo = @w_codigo_externo
        and ve_vencimiento = @i_vencimiento

     if @@error <> 0 
     begin
       /* Error en actualizacion de registro */
        exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 1905015
        return 1 
     end

  commit tran      

end


-------------------------
---MANEJO PARA TEMPORALES
-------------------------
if @i_operacion = 'T' 
begin

  ---OBTENCION DE SECUENCIAL
  --------------------------
  if @i_modo = 0
  begin
     /*exec @w_return = cobis..sp_cseqnos
       @t_from       = @w_sp_name,
       @i_tabla      = "cu_vencimiento_tmp",
       @o_siguiente  = @w_secuencial out*/

     if @w_return <> 0 
        return 1

     select @w_secuencial
  end

  ---GRABAR EN TEMPORAL
  ----------------------
  if @i_modo = 1
  begin   

     select @w_ultimo = isnull(max(vt_vencimiento),0)+1
       from cu_vencimiento_tmp
      where vt_secuencial = @i_secuencial
 
     --II LRC 12/10/2009
     if @i_ret_iva = null
     begin
       select @i_ret_iva = 0
     end
     --FI LRC 12/10/2009
     
     if @i_banco is not null and isnumeric(@i_banco) <> 1
     begin
        --DAR 01OCT2013
        --buscar el codigo del banco que pertenece su descripcion
	select @w_des_banco = @i_banco
	select @string = @w_des_banco
	select @pos = patindex('% %' , @string)
	while @pos <> 0
	begin
	   select @piece =LEFT(@string, @pos-1)
	   select @string = stuff(@string,1, @pos,NULL)
	   select @pos = charindex(' ' , @string)
	end
	--print @string  --Ultima palabra del string
	select @string = '%' + upper(@string) + '%'
	/*select @i_banco = convert(varchar(10),ba_banco)
	  from cobis..cl_banco_rem
	 where ba_descripcion like @string 
	   and ba_estado = 'V'*/
     end
     
     begin tran
 
     insert into cu_vencimiento_tmp(
        vt_secuencial, vt_filial, vt_sucursal,
        vt_tipo_cust, vt_vencimiento, vt_deudor, 
        vt_beneficiario, vt_fecha_emision, vt_fecha,
        vt_fecha_tolerancia, vt_subtotal, vt_iva,
        vt_valor, vt_ret_iva, vt_ret_fte, 
        vt_instruccion,
        vt_num_factura, vt_cta_debito, vt_banco,
        vt_localidad, vt_tolerancia, vt_estado, vt_ced_ruc,  --REF:LRC feb.16.2009
        vt_descuento, vt_porc_iva, vt_porc_ret_fte)          --LRC 12/10/2009
     values (
        @i_secuencial, @i_filial, @i_sucursal,
        @i_tipo_cust, @w_ultimo, @i_deudor,
        @i_beneficiario, @i_fecha_emision, @i_fecha,
        @i_fecha_tol, isnull(@i_subtotal,0), isnull(@i_iva, 0),  --LRC 02/01/2010
        @i_valor, @i_ret_iva, isnull(@i_ret_fte,0), --LRC 02/01/2010
        @i_instruccion,              
        @i_num_factura, @i_cta_debito, @i_banco,
        @i_localidad, @i_tolerancia, @i_estado, @i_cedruc,  --REF:LRC feb.16.2009
        isnull(@i_descuento,0), @i_porc_iva, @i_porc_ret_fte)  --LRC 12/10/2009 --LRC 02/01/2010

     if @@error <> 0 
     begin
       /* Error en insercion de registro */
       exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1903001

       delete cu_vencimiento_tmp 
        where vt_secuencial = @i_secuencial

       return 1 
     end

     commit tran 
     return 0
  end --- @i_modo = 1


  ---CREAR GARANTIAS Y DOCUMENTOS
  -------------------------------
  if @i_modo = 2
  begin   
    --REF:LRC feb.17.2009 Inicio
    /*select @w_facturas = pa_char
      from cobis..cl_parametro
     where pa_producto = 'GAR'
      and pa_nemonico = 'FAC'

    select @w_carchq = pa_char
      from cobis..cl_parametro
     where pa_producto = 'CCA'
       and pa_nemonico = 'GARCHE'*/        
    --REF:LRC feb.17.2009 Fin
   
    select @w_fecha_vcto_gar = max(vt_fecha_tolerancia),
           --LRC 12/10/2009 @w_valor_gar = isnull(sum(vt_valor),0)
           @w_valor_gar = isnull(sum(vt_valor - vt_ret_fte),0) --LRC 12/10/2009 
      from cu_vencimiento_tmp
     where vt_secuencial = @i_secuencial

    /*select @w_oficial = en_oficial
      from cobis..cl_ente
     where en_ente = @i_cliente*/

    --REF:LRC feb.17.2009 Inicio
    if @i_tipo_cust = @w_facturas
       select @w_fuente_valor = 'F'
    else
    begin
       select @w_fuente_valor = 'O'       
       if @i_tipo_cust = @w_carchq  
       begin
         --Numero de dias de prorroga para el ultimo cobro de cheque
         /*select @w_ddr = pa_tinyint
           from cobis..cl_parametro
          where pa_producto = 'GAR'
            and pa_nemonico = 'NDPUCC'*/

         if @@rowcount = 0
         begin
           exec cobis..sp_cerror	
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1900000,
                @i_msg   = 'No existe parametro general NDPUCC'
           return 1        
         end       
         select @w_fecha_vcto_gar = dateadd(dd, @w_ddr, @w_fecha_vcto_gar)
       end
    end
    --REF:LRC feb.17.2009 Fin   
    
    BEGIN TRAN

    ---Crear Garantia
    exec @w_return = cob_custodia..sp_custodia
      @s_ssn      = @s_ssn,
      @s_date     = @s_date,
      @s_user     = @s_user,
      @s_term     = @s_term,
      @s_corr     = @s_corr,
      @s_ssn_corr = @s_ssn_corr,
      @s_ofi      = @s_ofi,
      @t_rty      = @t_rty,
      @t_trn      = 19090,
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @t_from,     
      @i_operacion= 'I',
      @i_filial   = @i_filial,
      @i_sucursal = @i_sucursal,
      @i_tipo     = @i_tipo_cust,
      @i_estado   = "P",
      @i_fecha_ingreso = @s_date,
      @i_valor_inicial = @w_valor_gar,
      @i_valor_actual  = @w_valor_gar, 
      @i_moneda   = @w_moneda,
      @i_inspeccionar = 'N',
      @i_motivo_noinsp = 'N',
      @i_fuente_valor = @w_fuente_valor, --REF:LRC feb.17.2009 'F',
      @i_compartida   = 'N',
      @i_suficiencia_legal = 'O',
      @i_cobranza_judicial = 'N',
      @i_cobrar_comision   = 'N',
      @i_abierta_cerrada   = 'C',
      @i_adecuada_noadec   = 'O',
      @i_ente = @i_cliente,
      @i_principal = 'S',
      @i_propietario = @i_propietario,
      @i_oficina_contabiliza = @i_sucursal,
      @i_fecha_vencimiento = @w_fecha_vcto_gar,
      @i_commit      = 'N',
      @o_custodia    = @w_custodia out,
      @o_codigo_externo = @w_codigo_externo out

    if @w_return <> 0 
    begin
      exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1903015
      return 1 
    end

    ---Crear Cliente
    exec @w_return = cob_custodia..sp_cliente_garantia
      @s_ssn      = @s_ssn,
      @s_date     = @s_date,
      @s_user     = @s_user,
      @s_term     = @s_term,
      @s_corr     = @s_corr,
      @s_ssn_corr = @s_ssn_corr,
      @s_ofi      = @s_ofi,
      @t_rty      = @t_rty,
      @t_trn      = 19040,
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @t_from,      
      @i_operacion= 'I',
      @i_modo     = 0,
      @i_filial   = @i_filial,
      @i_sucursal = @i_sucursal,
      @i_tipo_cust= @i_tipo_cust,
      @i_custodia = @w_custodia,
      @i_ente     = @i_cliente,
      @i_nombre   = @i_propietario,
      @i_principal = 'S',
      @i_oficial  = @w_oficial

    if @w_return <> 0 
    begin
      exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1903001
      return 1 
    end


    ---Crear Documentos
    -------------------
    insert into cu_vencimiento (
      ve_filial, ve_sucursal, ve_tipo_cust,
      ve_custodia, ve_vencimiento, ve_fecha,
      ve_subtotal, ve_iva, ve_valor,
      ve_ret_iva, ve_ret_fte, ve_instruccion,
      ve_num_factura,
      ve_cta_debito, ve_codigo_externo , ve_beneficiario,
      ve_deudor, ve_localidad, ve_fecha_emision,
      ve_tolerancia, ve_fecha_tolerancia,  ve_banco,
      ve_estado, ve_ced_ruc,  --REF:LRC feb.16.2009
      ve_descuento, ve_porc_iva, ve_porc_ret_fte) --LRC 12/10/2009
    select       
      vt_filial, vt_sucursal, vt_tipo_cust,
      @w_custodia, vt_vencimiento, vt_fecha,
      vt_subtotal, vt_iva, vt_valor,
      vt_ret_iva, vt_ret_fte, vt_instruccion,
      vt_num_factura,
      vt_cta_debito, @w_codigo_externo, vt_beneficiario,
      vt_deudor, vt_localidad, vt_fecha_emision,
      vt_tolerancia, vt_fecha_tolerancia, vt_banco,
      'I', vt_ced_ruc, --REF:LRC feb.16.2009
      vt_descuento, vt_porc_iva, vt_porc_ret_fte --LRC 12/10/2009
      from cu_vencimiento_tmp
     where vt_secuencial = @i_secuencial

    if @@error <> 0 
    begin
       /* Error en insercion de registro */
       exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1903001
       return 1 
    end

    ---Borrar temporal
    ------------------
    delete cu_vencimiento_tmp
     where vt_secuencial = @i_secuencial

    COMMIT TRAN

    select @w_codigo_externo 
    return 0     

  end --- @i_modo = 2


  ---Borra TMP
  --------------
  if @i_modo = 3
  begin   
    begin tran
    delete cu_vencimiento_tmp
     where vt_secuencial = @i_secuencial
    commit tran
  end

end

/* LRE 23/Mayo/2007 Cambio de estado de los documentos atadados a una garantia de Factoring Comercial */

if @i_operacion = 'C' 
begin

  /*select @w_carchq = pa_char
    from cobis..cl_parametro
   where pa_producto = 'CCA'
     and pa_nemonico = 'GARCHE'

  select @w_facturas = pa_char
    from cobis..cl_parametro
   where pa_producto = 'GAR'
    and pa_nemonico = 'FAC'

  select @w_pagares_lc = pa_char
    from cobis..cl_parametro
   where pa_producto = 'GAR'
     and pa_nemonico = 'PAG'*/


  if exists (select 1 
               from --cob_credito..cr_gar_propuesta, 
                    cob_custodia..cu_custodia, 
                    cob_custodia..cu_vencimiento 
              where --gp_garantia = cu_codigo_externo
                /*and*/ cu_codigo_externo = ve_codigo_externo
                --and gp_tramite = @i_tramite
                and cu_tipo in (@w_carchq, @w_facturas,@w_pagares_lc))

  begin
    if @i_estado_ini <> @i_estado_fin
    begin 

      update cob_custodia..cu_vencimiento 
         set ve_estado = @i_estado_fin
        from --cob_credito..cr_gar_propuesta, 
             cob_custodia..cu_custodia, 
             cob_custodia..cu_vencimiento 
       where --gp_garantia = cu_codigo_externo
         /*and*/ cu_codigo_externo = ve_codigo_externo
        -- and gp_tramite = @i_tramite
         and cu_tipo in (@w_carchq, @w_facturas,@w_pagares_lc)
         and ve_estado = @i_estado_ini

      if @@error <> 0 
      begin
        /* Error en actualizacion de registro */
        exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1905001
        return 1
      end
    end
  end
  else
   begin
     print 'Error no existen documentos ingresados ' 

     /* Error No encuentra documentos asociados */
     exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = 1903001
     return 1 
   end 

end

if @i_operacion = 'P' 
begin 
  /*        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
*/
        
   if exists(select 1 
             from cob_custodia..cu_vencimiento
             where ve_filial = @i_filial and
                   ve_sucursal = @i_sucursal and
                   ve_tipo_cust = @i_tipo_cust and
                   ve_custodia = @i_custodia and
		   convert(varchar(10),ve_fecha,@i_formato_fecha) = convert(varchar(10),convert(datetime,@i_fecha),@i_formato_fecha) and
		   ve_valor = @i_valor and
                   ve_instruccion = @i_instruccion and
                   ve_num_factura = @i_num_factura and
                   ve_cta_debito = @i_cta_debito and
                   ve_codigo_externo = @w_codigo_externo and
                   convert(varchar(10),ve_fecha_emision,@i_formato_fecha) = convert(varchar(10),convert(datetime,@i_fecha_emision),@i_formato_fecha) and
		   ve_deudor = @i_cliente and
                   ve_banco = @i_banco and
		   ve_localidad = @i_localidad and
		   convert(varchar(10),ve_fecha_tolerancia,@i_formato_fecha) = convert(varchar(10),convert(datetime,@i_fecha_tol),@i_formato_fecha)				   
            )
	begin		
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1
	end	
end
go
--EXEC sp_procxmode 'dbo.sp_vencimiento', 'unchained'
go
IF OBJECT_ID('dbo.sp_vencimiento') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.sp_vencimiento >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.sp_vencimiento >>>'
go