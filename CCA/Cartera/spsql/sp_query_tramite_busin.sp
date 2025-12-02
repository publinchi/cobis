use cob_pac
go

if exists (select 1 from sysobjects where name = 'sp_query_tramite_busin')
   drop proc sp_query_tramite_busin
go

create proc sp_query_tramite_busin (
       @t_debug            char(1)     = 'N',
       @t_file             varchar(14) = null,
       @t_from             varchar(30) = null,
       @i_tramite          int         = null,
       @i_numero_op_banco  cuenta      = null,
       @i_linea_credito    cuenta      = null,
       @i_producto         catalogo    = null,
       @i_es_acta          char(1)     = null
)
as
declare @w_tramite            int,
        @w_truta              tinyint,
        @w_tipo               char(1),
        @w_desc_tipo          descripcion,
        @w_oficina_tr         smallint,
        @w_desc_oficina       descripcion,
        @w_usuario_tr         login,
        @w_nom_usuario_tr     varchar(30),
        @w_fecha_crea         datetime,
        @w_oficial            smallint,
        @w_sector             catalogo,
        @w_ciudad             smallint,
        @w_desc_ciudad        descripcion,
        @w_estado             char(1),
        @w_nivel_ap           tinyint,
        @w_fecha_apr          datetime,
        @w_usuario_apr        login,
        @w_nom_usuario_apr    varchar(30),
        @w_secuencia          smallint,
        @w_numero_op          int,
        @w_numero_op_banco    cuenta,
        @w_desc_ruta          descripcion,
        @w_proposito          catalogo,
        @w_des_proposito      descripcion,
        @w_razon              catalogo,
        @w_des_razon          descripcion,
        @w_txt_razon          varchar(255),
        @w_efecto             catalogo,
        @w_des_efecto         descripcion,
        @w_cliente            int,
        @w_grupo              int,
        @w_fecha_inicio       datetime,
        @w_num_dias           smallint,
        @w_per_revision       catalogo,
        @w_condicion_especial varchar(255),
        @w_linea_credito      int,        /* renovaciones y operaciones */
        @w_toperacion         catalogo,
        @w_producto           catalogo,
        @w_monto              money,
        @w_moneda             tinyint,
        @w_periodo            catalogo,
        @w_num_periodos       smallint,
        @w_destino            catalogo,
        @w_ciudad_destino     smallint,
        @w_cuenta_corriente   cuenta,
        @w_garantia_limpia    char(1),
        @w_renovacion         smallint,
        @w_aprob_por          login,
        @w_nivel_por          tinyint,
        @w_comite             catalogo,
        @w_acta               cuenta,
        @w_fecha_concesion    datetime,
        -- variables para datos adicionales de operaciones de cartera
        @w_fecha_reajuste     datetime,
        @w_monto_desembolso   money,
        @w_periodo_reajuste   tinyint,
        @w_reajuste_especial  char(1),
        @w_forma_pago         catalogo,
        @w_cuenta             cuenta,
        @w_cuota_completa     char(1),
        @w_tipo_cobro         char(1),
        @w_tipo_reduccion     char(1),
        @w_aceptar_anticipos  char(1),
        @w_precancelacion     char(1),
        @w_tipo_aplicacion    char(1),
        @w_renovable          char(1),
        @w_reajustable        char(1),
        @w_val_tasaref        float,
        @w_cuenta_certificado cuenta,
        @w_alicuota           catalogo,
        @w_alicuota_aho       catalogo, --DMO 11/10/99
        @w_doble_alicuota     char(1),  --DMO 11/10/99
        @w_tdividendo         catalogo, --DMO
        @w_desc_tdividendo    descripcion, --DMO
		@w_motivo_uno         varchar(255),  -- Etapa de Rechazo JRU
		@w_motivo_dos         varchar(255),  -- Etapa de Rechazo JRU
		@w_motivo_rechazo     catalogo, -- Etapa de Rechazo JRU
        
        /* variables para completar datos del registro de un tramite */
        @w_des_oficial        descripcion,
        @w_des_sector         descripcion,
        @w_des_nivel_ap       descripcion,
        @w_nom_ciudad         descripcion, /*descripcion de tr_ubicacion */
        @w_nom_cliente        varchar(255),
        @w_ciruc_cliente      numero,
        @w_nom_grupo          descripcion,
        @w_des_per_revision   descripcion,
        @w_des_segmento       descripcion,
        @w_des_toperacion     descripcion,
        @w_des_moneda         descripcion,
        @w_des_periodo        descripcion,
        @w_des_destino        descripcion,
        @w_nom_aprob_por      descripcion,
        @w_des_fpago          descripcion,
        @w_li_num_banco       cuenta,
        @w_des_comite         descripcion,
        @w_paso               tinyint,
        @w_numero_operacion   int,
        @w_cont_dividendos    int,
        -- variables para operacion a reestructurar
        @w_banco_rest         cuenta,               --numero de banco
        @w_operacion_rest     int,                  --secuencial
        @w_toperacion_rest    catalogo,             --tipo de operacion
        @w_fecha_vto_rest     datetime,             --fecha vencimiento
        @w_monto_rest         money,                --monto original
        @w_saldo_rest         money,                --saldo capital
        @w_moneda_rest        tinyint,              --moneda
        @w_renovacion_rest    smallint,             --numero de renovacion
        @w_renovable_rest     char(1),              --renovable
        @w_fecha_ini_rest     datetime,             --fecha concesion
        @w_producto_rest      catalogo,             --producto
        
        @w_actividad_destino  catalogo,             --SPO Codigo actividad destino de la operacion
        @w_descripcion_ad     descripcion,          --SPO Descripcion actividad destino
        @w_tipo_cca           catalogo,             --SPO Tipo cartera
        @w_seg_cre            catalogo,             --SRA Segmento Credito 18/09/2007
        @w_descripcion_segmento descripcion,        --SRA Segmento Credito 18/09/2007
        @w_descripcion_tipo   descripcion,          --SPO Descripcion tipo cartera
        @w_clase_bloqueo      char(1),
        @w_op_banco           varchar(24),
        @w_op_compania        int,                  --Institucion Deudor
        @w_desc_compania      descripcion,
        @w_op_vinculado       char(1),              --Datos Vinculacion
        @w_op_cliente         int,
        @w_op_causal_vinc     catalogo,
        @w_op_tipo_vinc       catalogo,
        @w_causal_vinc_desc   descripcion,
        @w_tipo_vinc_desc     descripcion,
        @w_verificador        catalogo,
        @w_des_verificador    descripcion,
        @w_parroquia          catalogo,
        @w_des_parroquia      descripcion,
        @w_fecha_liq          datetime,             --PBE 3039
        @w_fecha_venc         datetime,              --PBE 3039
        @w_simbolo_moneda     varchar(10),
        @w_provincia          smallint,
        @w_fecha_venci        datetime,
        @w_clase              catalogo,
        @w_dias_anio          smallint,
        @w_fecha_ven          datetime,
        @w_rotativa           char(1),
        @w_linea              int,
        @w_fecha_ini          datetime,
        @w_dias               int
        
/* Chequeo de Existencias */
/**************************/
SELECT @w_tramite = tr_tramite,
       @w_truta = tr_truta,
       @w_tipo = tr_tipo,
       @w_oficina_tr = tr_oficina,
       @w_usuario_tr = tr_usuario,
       @w_nom_usuario_tr = substring(a.fu_nombre,1,30),
       @w_fecha_crea = tr_fecha_crea,
       @w_oficial = tr_oficial,
       @w_sector = tr_sector,
       @w_ciudad = tr_ciudad,
       @w_estado = tr_estado,
       @w_nivel_ap = tr_nivel_ap,
       @w_fecha_apr = tr_fecha_apr,
       @w_usuario_apr        = tr_usuario_apr,
       @w_nom_usuario_apr = substring(b.fu_nombre,1,30),
       @w_numero_op = tr_numero_op,
       @w_numero_op_banco = tr_numero_op_banco,
       @w_proposito = tr_proposito, /* garantias*/
       @w_razon = tr_razon,
       @w_txt_razon = rtrim(tr_txt_razon),
       @w_efecto = tr_efecto,
       @w_cliente = tr_cliente, /*lineas*/
       @w_grupo = tr_grupo,
       @w_fecha_inicio = tr_fecha_inicio,
       @w_num_dias = tr_num_dias,
       @w_per_revision = tr_per_revision,
       @w_condicion_especial = tr_condicion_especial,
       @w_linea_credito = tr_linea_credito,  /*renov. y operaciones*/
       @w_toperacion = tr_toperacion,
       @w_producto = tr_producto,
       @w_monto = tr_monto,
       @w_moneda = tr_moneda,
       @w_periodo = tr_periodo,
       @w_num_periodos = tr_num_periodos,
       @w_destino = tr_destino,
       @w_ciudad_destino = tr_ciudad_destino,
       @w_cuenta_corriente = tr_cuenta_corriente,
       @w_garantia_limpia = NULL,    ---tr_garantia_limpia,
       @w_renovacion = tr_renovacion,
       @w_aprob_por = tr_aprob_por,
       @w_nivel_por = tr_nivel_por,
       @w_comite    = tr_comite,
       @w_acta      = tr_acta,
       @w_fecha_concesion = tr_fecha_concesion,
       @w_cuenta_certificado = NULL,    --tr_cuenta_certificado,
       @w_alicuota   = NULL,  ---tr_alicuota,
       @w_alicuota_aho = NULL, ---tr_alicuota_aho, --DMO 11/10/99
       @w_doble_alicuota = NULL,  ---tr_doble_alicuota,  --DMO 11/10/99
       @w_actividad_destino = NULL,   ---tr_actividad_destino,  --SPO Actividad destino op.
       @w_tipo_cca          = NULL,   ---tr_tipo_cca,            --SPO Clase de cartera
       @w_verificador       = NULL,   ---tr_verificador,
       @w_seg_cre           = NULL    ---tr_seg_cre
FROM cob_credito..cr_tramite
LEFT JOIN cobis..cl_funcionario a ON tr_usuario = a.fu_login
LEFT JOIN cobis..cl_funcionario b ON tr_usuario_apr = b.fu_login
--     cobis..cl_funcionario a,
--     cobis..cl_funcionario b
WHERE tr_tramite = @i_tramite	   
-- Si registro no existe ==> error
if @@rowcount = 0
  begin
     /*Registro no existe */
     exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = 'sp_query_tramite_busin',
     @i_num   = 2101005
     return 1
  end

/*********** TRAER DATOS COMPLEMENTARIOS **************/
-- Obtener la secuencia en la que se encuentra en su ruta
select @w_secuencia = rt_secuencia,
       @w_paso       = rt_paso
  from cob_credito..cr_ruta_tramite
 where rt_tramite    = @i_tramite
   and rt_salida    is NULL
if @@rowcount = 0
  begin
     select @w_secuencia = max(rt_secuencia)
       from cob_credito..cr_ruta_tramite
      where rt_tramite   = @i_tramite
  end
  
-- descripcion de la ruta
select @w_desc_ruta = ru_descripcion
  from cob_credito..cr_truta
 where ru_truta = @w_truta

-- descripcion del tipo de tramite
select @w_desc_tipo = tt_descripcion
  from cob_credito..cr_tipo_tramite
 where tt_tipo = @w_tipo

-- descripcion de la oficina
select @w_desc_oficina = of_nombre
  from cobis..cl_oficina
 where of_oficina = @w_oficina_tr

-- descripcion y provincia de la ciudad
select @w_desc_ciudad = ci_descripcion
  from cobis..cl_ciudad
 where ci_ciudad = @w_ciudad

-- numero de banco de la linea de credito
select @w_li_num_banco = li_num_banco
  from cob_credito..cr_linea
 where li_numero = @w_linea_credito

-- nombre del oficial
select @w_des_oficial = substring(fu_nombre,1,30)
  from cobis..cc_oficial, cobis..cl_funcionario
 where oc_oficial = @w_oficial
   and oc_funcionario = fu_funcionario

-- descripcion del sector
select @w_des_sector = a.valor
  from cobis..cl_catalogo a, cobis..cl_tabla b
 where b.tabla  = 'cc_sector'
   and a.codigo = @w_sector
   and a.tabla  = b.codigo

-- descripcion del destino
if @w_destino is not null
  begin
    select @w_des_destino = a.valor
      from cobis..cl_catalogo a, cobis..cl_tabla b
     where a.codigo = @w_destino
       and a.tabla  = b.codigo
       and b.tabla  = 'cr_destino'
  end

-- descripcion de la actividad  SPO
if @w_actividad_destino is not null
  begin
     select @w_descripcion_ad = ae_descripcion
       from cobis..cl_act_economica
      where ae_codigo = @w_actividad_destino
  end

-- Clase de cartera SPO
if @w_tipo_cca is not null
  begin
    select @w_descripcion_tipo = a.valor
      from cobis..cl_catalogo a, cobis..cl_tabla b
     where a.codigo = @w_tipo_cca
       and a.tabla  = b.codigo
       and b.tabla  = 'ca_tipo_cartera'
  end

-- Tipo Segmento Credito SRA 18/09/2007
        if @w_seg_cre is not null
                select @w_descripcion_segmento = a.valor
                from cobis..cl_catalogo a, cobis..cl_tabla b
                where a.codigo = @w_seg_cre
                and a.tabla = b.codigo
                and b.tabla = 'ca_segmento_credito'


-- nivel de aprobacion
        if @w_nivel_ap is not null
                select @w_des_nivel_ap = a.valor
                from cobis..cl_catalogo a, cobis..cl_tabla b
                where a.codigo = convert(varchar(10),@w_nivel_ap)
                and   a.tabla = b.codigo
                and   b.tabla = 'cr_nivel'

-- nombre del cliente
        if @w_tipo in ('O', 'R', 'E')
           select @w_cliente = de_cliente
           from   cob_credito..cr_deudores
           where  de_tramite = @i_tramite
           and    de_rol = 'D'

        if @w_cliente is not null
                select @w_nom_cliente = rtrim(p_p_apellido)+' '+rtrim(p_s_apellido)+' '+rtrim(en_nombre),
                       @w_ciruc_cliente = en_ced_ruc
                from cobis..cl_ente
                where en_ente = @w_cliente
-- nombre del grupo
        if @w_grupo is not null
                select @w_nom_grupo = gr_nombre
                from cobis..cl_grupo
                where gr_grupo = @w_grupo

-- periodicidad de revision
        if @w_per_revision is not null
                select @w_des_per_revision = pe_descripcion
                from cob_credito..cr_periodo
                where pe_periodo = @w_per_revision

-- tipo de operacion
        if @w_toperacion is not null
                select @w_des_toperacion = to_descripcion
                from cob_credito..cr_toperacion
                where to_toperacion =@w_toperacion
                and to_producto = @w_producto

-- moneda
        if @w_moneda is not null
                select @w_des_moneda = mo_descripcion,
                       @w_simbolo_moneda = mo_simbolo                       
                from cobis..cl_moneda
                where mo_moneda = @w_moneda


-- ciudad destino
        if @w_ciudad_destino is not null
                select @w_nom_ciudad = ci_descripcion,
                       @w_provincia  = ci_provincia
                from cobis..cl_ciudad
                where ci_ciudad = @w_ciudad_destino

-- descripcion de razon de cambio de garantia
        if @w_razon is not null
                select @w_des_razon = a.valor
                from cobis..cl_catalogo a, cobis..cl_tabla b
                where a.codigo = @w_razon
                and a.tabla = b.codigo
                and b.tabla = 'cr_razon'

-- descripcion de proposito de cambio de garantia
        if @w_proposito is not null
                select @w_des_proposito = a.valor
                from cobis..cl_catalogo a, cobis..cl_tabla b
                where a.codigo = @w_proposito
                and a.tabla = b.codigo
                and b.tabla = 'cr_proposito'

-- descripcion de efecto de cambio de garantia
        if @w_efecto is not null
                select @w_des_efecto = a.valor
                from cobis..cl_catalogo a, cobis..cl_tabla b
                where a.codigo = @w_efecto
                and a.tabla = b.codigo
                and b.tabla = 'cr_efecto'

-- nombre del usuario que fue sustituido
        if @w_aprob_por is not null
                select @w_nom_aprob_por = substring(fu_nombre,1,30)
                from        cobis..cl_funcionario
                where        fu_login = @w_aprob_por


-- descripcion del comite
        if @w_comite is not null
                select @w_des_comite = a.valor
                from cobis..cl_catalogo a, cobis..cl_tabla b
                where a.codigo = @w_comite
                and a.tabla = b.codigo
                and b.tabla = 'cr_comite'


-- Nombre del Verificador
        if @w_verificador is not null
                select @w_des_verificador = ab_nombre
                from   cob_credito..cr_abogado
                where  ab_abogado = @w_verificador
                and    ab_tipo    = 'V'

/* traer los valores adicionales de las tablas de cartera */
if @w_producto = 'CCA'
begin

   /* calculo en base al No. tramite */
   select @w_numero_operacion = op_operacion,
          @w_fecha_reajuste        = op_fecha_reajuste,
          @w_monto_desembolso        = op_monto,
          @w_periodo_reajuste        = op_periodo_reajuste,
          @w_reajuste_especial        = op_reajuste_especial,
          @w_forma_pago                = op_forma_pago,
          @w_cuenta                = op_cuenta,
          @w_cuota_completa        = op_cuota_completa,
          @w_tipo_cobro                = op_tipo_cobro,
          @w_tipo_reduccion        = op_tipo_reduccion,
          @w_aceptar_anticipos        = op_aceptar_anticipos,
          @w_precancelacion        = op_precancelacion,
          @w_tipo_aplicacion        = op_tipo_aplicacion,
          @w_renovable                = op_renovacion,
          @w_reajustable        = op_reajustable,
          @w_fecha_inicio        = op_fecha_ini,
          @w_periodo               = op_tplazo,
          @w_des_periodo        = td_descripcion,
          @w_tdividendo         = op_tdividendo, --DMO
          @w_num_periodos        = op_plazo,
          @w_clase_bloqueo      = NULL,      ---op_clase_bloqueo,
          @w_op_banco           = op_banco,                        --PRON:1SEP06
          @w_op_compania        = NULL,      ---op_compania,
          @w_op_cliente         = op_cliente,
          @w_op_vinculado       = e.en_vinculacion, --SRO --isnull(op_vinculado,'N'),
          @w_op_causal_vinc     = NULL,     ---op_rubro,
          @w_cuenta_corriente   = NULL,     ---isnull(op_cta_ahorro, @w_cuenta_corriente),       --PRON:7NOV08 cuenta de ahorros cuando es de cca
          @w_cuenta_certificado = NULL,     ---isnull(op_cta_certificado, @w_cuenta_certificado),
          @w_parroquia          = NULL,     ---op_parroquia,
          @w_clase              = op_clase,
          @w_dias_anio 			= op_dias_anio 
   from   cob_cartera..ca_operacion op,
          cob_cartera..ca_tdividendo,
		  cobis..cl_ente e
   where  op_tramite = @i_tramite
   and    td_tdividendo = op_tplazo
   and 	  e.en_ente = op.op_cliente


-- descripcion de la parroquia
        if @w_parroquia is not null
   select @w_des_parroquia = pq_descripcion
      from cobis..cl_parroquia
      where pq_parroquia = convert(int,@w_parroquia)


   --INSTITUCION DEUDOR     --AOL 08ENE07
   select @w_op_compania = isnull(@w_op_compania,0)
   if @w_op_compania > 0
      select @w_desc_compania = en_nombre
      from   cobis..cl_ente
      where  en_ente = @w_op_compania


   -- DATOS DE VINCULACION   --AOL 12ENE07
   if @w_op_vinculado <>'N'
   begin
      select @w_causal_vinc_desc = rtrim(b.valor)
      from   cobis..cl_tabla a, cobis..cl_catalogo b
      where  a.tabla  = 'cl_causal_vinculacion'
      and    b.tabla  = a.codigo
      and    b.codigo = @w_op_causal_vinc

      select @w_causal_vinc_desc  =  rtrim(@w_op_causal_vinc) + '-' +  rtrim(@w_causal_vinc_desc)

      select @w_op_tipo_vinc = en_tipo_vinculacion
      from   cobis..cl_ente
      where  en_ente = @w_op_cliente

      select @w_tipo_vinc_desc = rtrim(b.valor)
      from   cobis..cl_tabla a, cobis..cl_catalogo b
      where  a.tabla  = 'cl_tipo_vinculacion'
      and    b.tabla  = a.codigo
      and    b.codigo = @w_op_tipo_vinc

      select @w_tipo_vinc_desc  =  rtrim(@w_op_tipo_vinc) + '-' +  rtrim(@w_tipo_vinc_desc)

   end

   select @w_numero_op_banco = isnull(@w_numero_op_banco,rtrim(@w_op_banco))   --PRON:1SEP06

--INICIO
--Se añade esto por problema con orquestacion dado que
--se enviaba el numero de tramite en lugar del numero de banco para santander
	if @w_numero_op_banco is null or @w_numero_op_banco = ''
	      SELECT @w_numero_op_banco = opt_banco
	      FROM cob_cartera..ca_operacion_tmp
	      WHERE opt_tramite = @w_tramite
--FIN
   if @w_forma_pago is not null
   begin
        select @w_des_fpago = cp_descripcion
        from cob_cartera..ca_producto
        where cp_producto = @w_forma_pago
   end

select @w_desc_tdividendo = td_descripcion
 from cob_cartera..ca_tdividendo
where td_tdividendo = @w_tdividendo

   -- tasa de interes
   select @w_val_tasaref=  isnull(sum(ro_porcentaje),0)
   from   cob_cartera..ca_rubro_op
   where  ro_operacion  =  @w_numero_operacion
   and    ro_tipo_rubro =  'I'
   and    ro_fpago      in ('P','A')
   and          ro_concepto in (select pa_char from cobis..cl_parametro
          where pa_nemonico ='INT')
		  
   -- Fecha de Vencimiento de una operación
   select @w_fecha_venci = di_fecha_ven
   from   cob_cartera..ca_dividendo
   where  di_operacion = @w_numero_operacion and di_dividendo = 1 
   
--Pegn 19/02/2001 Para que no tome en cuenta el interes
   -- contador de dividendos
   select @w_cont_dividendos = count(*)
   from   cob_cartera..ca_dividendo
   where  di_operacion = @w_numero_operacion

   -- PBE 3039
   select @w_fecha_liq  = op_fecha_liq,
          @w_fecha_venc = op_fecha_fin
     from cob_cartera..ca_operacion
    where op_operacion = @w_numero_operacion

   -- datos de la operacion a reestructurar
   if @w_tipo = 'E'
   begin
      --obtener el numero de banco de la operacion
      select @w_banco_rest = or_num_operacion
      from   cob_credito..cr_op_renovar
      where  or_tramite = @i_tramite

      --obtener los datos de la operacion
      select        @w_operacion_rest        = op_operacion,
                @w_toperacion_rest        = op_toperacion,
                @w_fecha_vto_rest        = op_fecha_fin,
                @w_monto_rest                = op_monto,
                @w_moneda_rest                = op_moneda,
                @w_renovacion_rest        = op_num_renovacion,
                @w_renovable_rest        = op_renovacion,
                @w_fecha_ini_rest        = op_fecha_liq,
                @w_producto_rest        = 'CCA'
      from        cob_cartera..ca_operacion
      where        op_banco = @w_banco_rest

      --obtener el saldo de capital
      --select @w_saldo_rest = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0))
	  select @w_saldo_rest = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
      from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
      where  ro_operacion = @w_operacion_rest
      and    ro_tipo_rubro in ('C')    -- tipo de rubro capital
      and    am_operacion = ro_operacion
      and    am_concepto  = ro_concepto
   end
end

-- Informacion de Datos Adicionales -> Rechazo, motivo y justificacion  
    select @w_motivo_rechazo = tr_motivo_rechazo,
		@w_motivo_uno = tr_motivo_uno,
		@w_motivo_dos = tr_motivo_dos 
	from cob_credito..cr_tr_datos_adicionales
	where tr_tramite = @i_tramite

----------------------------
--Consulta datos de la linea
----------------------------
if exists (select 1 from cob_credito..cr_linea where li_tramite = @w_tramite)
begin

   select @w_fecha_ven = li_fecha_vto,
          @w_rotativa  = li_rotativa,
          @w_linea     = li_numero,
          @w_fecha_ini = li_fecha_inicio,
          @w_dias      = li_dias
     from cob_credito..cr_linea 
    where li_tramite = @i_tramite
end
 
/********* retorno al front-end ****************/
select  @w_tramite,                                --1
        @w_desc_ruta,
        @w_tipo,
        @w_desc_tipo,
        @w_oficina_tr,
        @w_desc_oficina,
        @w_usuario_tr,
        @w_nom_usuario_tr,
        @w_fecha_crea,
        @w_oficial,
        @w_ciudad,
        @w_desc_ciudad,
        @w_estado,
        @w_secuencia,
        @w_numero_op_banco,
        @w_proposito,
        @w_des_proposito,
        @w_razon,
        @w_des_razon,
        @w_txt_razon,
        @w_efecto,
        @w_des_efecto,
        @w_cliente,
        @w_grupo,
        @w_fecha_inicio,
        @w_num_dias,
        @w_per_revision,
        @w_condicion_especial,
        @w_toperacion,
        @w_producto,
        @w_li_num_banco,
        @w_monto,
        @w_moneda,
        @w_periodo,
        @w_num_periodos,                        --40
        @w_destino,
        @w_ciudad_destino,
        @w_renovacion,
        @w_fecha_reajuste,
        isnull(@w_monto_desembolso,@w_monto),       --40 mc
        @w_periodo_reajuste,    --40
        @w_reajuste_especial,
        @w_forma_pago,                                --50
        @w_cuenta,
        @w_cuota_completa,
        @w_tipo_cobro,
        @w_tipo_reduccion,
        @w_aceptar_anticipos,
        @w_precancelacion,
        @w_tipo_aplicacion,
        @w_renovable,
        @w_reajustable,
        @w_val_tasaref,                                --60
        @w_fecha_concesion,
        @w_seg_cre,                                            --@w_sector, OGU modificado
        @w_des_oficial,
        @w_des_sector,
        @w_des_nivel_ap,
        @w_nom_ciudad,
        @w_nom_cliente,                          --60 mc  
        @w_ciruc_cliente,                        --70
        @w_nom_grupo,
        @w_des_per_revision,
        @w_des_segmento,
        @w_des_toperacion,
        @w_des_moneda,
        @w_des_periodo,
        @w_des_destino,
        @w_des_fpago,
        @w_paso,
        @w_cont_dividendos,
        @w_banco_rest,
        @w_operacion_rest,
        @w_toperacion_rest,
        @w_fecha_vto_rest,
        @w_monto_rest,
        @w_saldo_rest,                                --90
        @w_moneda_rest,
        @w_renovacion_rest,
        @w_renovable_rest,
        @w_fecha_ini_rest,
        @w_producto_rest,
    ' ',           -- INICIO NUEVOS DATOS
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    @w_monto, --@w_monto_solicitado,
    ' ',
    @w_periodo, --@w_frec_pago,
    @w_moneda, --@w_moneda_solicitada,
    @w_provincia, --@w_provincia,                                   -- 100 mc
    ' ',                                                             
    @w_num_periodos, --@w_pplazo,
    ' ',
    ' ',
    ' ',
    '', --Adry
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ', --@w_objeto,
    @w_actividad_destino,
    ' ',
    ' ', --@w_origen_fondos,
    @w_des_periodo, --@w_des_frec_pago,
    ' ',
    ' ',
    @w_simbolo_moneda, --@w_simbolo_moneda,
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    @w_motivo_uno,			-- Etapa de rechazo 
    @w_motivo_dos,			-- Etapa de rechazo
    @w_motivo_rechazo,		-- Etapa de rechazo
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',                                             --140 mc
    ' ',
    ' ',
    ' ',
    @w_op_vinculado as es_vinculado, -- Indica si la operación es de un cliente vinculado
    @w_parroquia,
    @w_fecha_venci,
    @w_clase,
    @w_dias_anio,
    @w_cuenta_corriente AS cuenta_ahorros,
    @w_cuenta_certificado AS cuenta_certificada,
    @w_alicuota_aho AS alicuota_ahorros,
    @w_alicuota AS alicuota_certificada,
    @w_doble_alicuota AS doble_alicuota,
    @w_fecha_ven,
    @w_rotativa, 
    @w_linea,
    @w_fecha_ini,
    @w_dias,
    @w_sector
    
    

if @i_es_acta = 'T'
begin
select @w_comite,
       @w_acta
end


return 0


go
