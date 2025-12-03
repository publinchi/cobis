/************************************************************************/
/*  Archivo:                situacion_poliza.sp                         */
/*  Stored procedure:       sp_situacion_poliza                         */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_situacion_poliza')
    drop proc sp_situacion_poliza
go

create proc sp_situacion_poliza(
        @t_file               varchar(14) = null,
        @t_debug              char(1)= 'N',
        @i_subopcion          char(1)= null,
        @s_sesn               int    = null,
        @s_date               datetime = null,
        @s_user               login  = null,
        @s_ssn                int      = null,
        @s_term               descripcion = null,
        @s_srv                varchar(30) = null,
        @s_lsrv               varchar(30) = null,
        @s_rol                smallint = null,
        @s_ofi                smallint  = null,
        @s_org_err            char(1) = null,
        @s_error              int = null,
        @s_sev                tinyint = null,
        @s_msg                descripcion = null,
        @i_cliente            int    = null,
        @i_tramite            int    = null,
        @i_tipo_deuda         char(1)= 'T',
        @i_impresion          char(1)= 'S',  --Si se lo llama desde la impresion del MAC viene 'N'
        @i_formato_fecha      tinyint= 111,
        @t_show_version       bit = 0, -- Mostrar la version del programa OCU
        @i_act_can            char(1)  = 'N',   -- MCA: para determinar Activos (N) y Cancelados + Activos (S)
        @i_tramite_d          int      = null,
		@i_vista_360          char(1)  = null
    )
as
declare
   @w_sp_name       varchar(32),
   @w_def_moneda    tinyint,
   @w_fecha         datetime,
   @w_vencido       catalogo,
   @w_vigente       catalogo,
   @w_cancelado     catalogo,
   @w_estado_poliza catalogo,
   @w_cliente       int,
   @w_tramite       int,
   @w_poliza        cuenta,
   @w_spid          smallint --OCU#

select     @w_sp_name = 'sp_situacion_poliza'

if @t_show_version = 1
begin
    print 'Stored procedure sp_situacion_poliza, Version 4.0.0.0'
    return 0
end

--OCU# obtengo numero de proceso
select @w_spid = @@spid



/** Cargo Moneda Local **/
select @w_def_moneda = pa_tinyint
  from cobis..cl_parametro
 where pa_producto = 'ADM'
   and pa_nemonico = 'MLO'

if @@rowcount = 0
begin
   /*Registro no existe */
   exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101005
   return 1
end


/** Cargo fecha de proceso  **/
  select @w_fecha = fp_fecha
  from cobis..ba_fecha_proceso


/** CARGA PARAMETRO DE ESTADO VIGENTE DE LA POLIZA **/
    select @w_vigente = pa_char
      from cobis..cl_parametro
     where pa_producto = 'GAR'
       and pa_nemonico = 'PVG'

/** CARGA PARAMETRO DE ESTADO VENCIDO DE LA POLIZA **/
    select @w_vencido = pa_char
      from cobis..cl_parametro
     where pa_producto = 'GAR'
       and pa_nemonico = 'POV'

/** CARGA PARAMETRO DE ESTADO CANCELADO DE LA POLIZA **/
    select @w_cancelado = pa_char
      from cobis..cl_parametro
     where pa_producto = 'GAR'
       and pa_nemonico = 'POC'


    if @i_act_can = 'S'  --(Activos y Cancelados)
        select @w_estado_poliza=  @w_vencido + ',' +  @w_vigente + ',' + @w_cancelado
    else if @i_act_can = 'N' --(Activos)
        select @w_estado_poliza=  @w_vencido + ',' +  @w_vigente

-- CREACION DE TABLA TEMPORAL DE COTIZACIONES
insert into cr_cotiz3_tmp
            (spid,moneda, cotizacion)
select  @w_spid, a.ct_moneda, a.ct_compra
  from  cob_credito..cb_cotizaciones a

-- insertar un regsitro para moneda local en caso de no existir
if not exists(select * from cr_cotiz3_tmp where moneda = @w_def_moneda and spid = @w_spid)
   insert into cr_cotiz3_tmp (spid, moneda, cotizacion)
    values (@w_spid, @w_def_moneda, 1)

/** POLIZAS ASOCIADAS DIRECTAMENTE AL TRAMITE **/
if @i_tipo_deuda = 'D' or @i_tipo_deuda = 'T'
BEGIN

    /** CARGA LAS POLIZAS ASOCIADAS AL TRAMITE **/
    insert into cr_situacion_poliza (
       sp_cliente,
       sp_tramite,
       sp_usuario,
       sp_secuencia,
       sp_tipo_con,
       sp_cliente_con,
       sp_identico,
       sp_producto,
       sp_poliza,
       sp_tramite_d,
       sp_estado,
       sp_comentario,
       sp_aseguradora,
       sp_tipo_pol,
       sp_desc_pol,
       sp_fecha_ven,
       sp_anualidad,
       sp_endoso,
       sp_endoso_ml,
       sp_codigo,
       sp_moneda,
       sp_sec_poliza,
       sp_tipo_deuda,
       sp_avaluo,
       sp_fechaActivacion,
       sp_fechaCancelacion)

    select distinct
          sc_cliente,
          sc_tramite,
          sc_usuario,
          sc_secuencia,
          sc_tipo_con,
          sc_cliente_con,
          sc_identico,
          'POL',
          X.po_poliza,
          0, -- pa_tramite
          (select A.valor
             from cobis..cl_catalogo A,cobis..cl_tabla B
            where B.codigo = A.tabla
              and B.tabla = 'cu_estado_poliza'
              and A.codigo = X.po_estado_poliza),
          X.po_descripcion,
          X.po_aseguradora,
          'A', -- X.po_tipo_seguro,
          null, -- JES --> (select ts_nombre from cob_custodia..cu_tipo_seguro where ts_codigo = X.po_tipo_seguro),
          convert(varchar(10),po_fvigencia_fin,@i_formato_fecha),
          0, -- JES --> X.po_total_prima,
          0, -- JES --> X.po_monto_endoso,
          0, -- JES --> X.po_monto_endoso * cotizacion,
          null, -- JES --> pa_garantia,
          X.po_moneda,
          null, -- JES --> X.po_secuencial,
          'D',
          0, -- JES --> in_avaluo,
          X.po_fvigencia_inicio, --Fecha de activación
          X.po_fvigencia_fin  -- Fecha de cancelación
    from  cob_custodia..cu_poliza X LEFT JOIN cob_custodia..cu_inspeccion ON X.po_codigo_externo = in_codigo_externo,
          --cob_custodia..cu_poliza_asociada,
          cob_credito..cr_situacion_cliente, cob_credito..cr_deudores, cr_cotiz3_tmp
   where  de_cliente     = sc_cliente
     and  sc_tramite     = @i_tramite
     and  sc_usuario     = @s_user
     and  sc_secuencia   = @s_sesn
     and  X.po_moneda    = moneda
     and  X.po_estado_poliza in (select @w_estado_poliza)--(@w_vencido, @w_vigente )
     --and  X.po_codigo_externo *= in_codigo_externo
     and  spid = @w_spid
END


/** POLIZAS ASOCIADAS INDIRECTAMENTE AL TRAMITE X LA GARANTIA**/
if @i_tipo_deuda = 'I' or @i_tipo_deuda = 'T'
BEGIN
    insert into cr_situacion_poliza (
       sp_cliente,
       sp_tramite,
       sp_usuario,
       sp_secuencia,
       sp_tipo_con,
       sp_cliente_con,
       sp_identico,
       sp_producto,
       sp_poliza,
       sp_tramite_d,
       sp_estado,
       sp_comentario,
       sp_aseguradora,
       sp_tipo_pol,
       sp_desc_pol,
       sp_fecha_ven,
       sp_anualidad,
       sp_endoso,
       sp_endoso_ml,
       sp_codigo,
       sp_moneda,
       sp_sec_poliza,
       sp_tipo_deuda,
       sp_fechaActivacion,
       sp_fechaCancelacion)

    select distinct
          sc_cliente,
          sc_tramite,
          sc_usuario,
          sc_secuencia,
          sc_tipo_con,
          sc_cliente_con,
          sc_identico,
          'POL',
          X.po_poliza,
          0, -- JES --> pa_tramite,
          (select A.valor
             from cobis..cl_catalogo A,cobis..cl_tabla B
            where B.codigo = A.tabla
              and B.tabla = 'cu_estado_poliza'
              and A.codigo = X.po_estado_poliza),
          X.po_descripcion,
          X.po_aseguradora,
          'A',  -- JES --> X.po_tipo_seguro,
          null, -- JES --> (select ts_nombre from cob_custodia..cu_tipo_seguro where ts_codigo = X.po_tipo_seguro),
          convert(varchar(10),po_fvigencia_fin,@i_formato_fecha),
          0, -- JES --> X.po_total_prima,
          0, -- JES --> X.po_monto_endoso,
          0, -- JES --> X.po_monto_endoso * cotizacion,
          null, -- JES --> pa_garantia,
          X.po_moneda,
          null, -- JES --> X.po_secuencial,
          'I',
   X.po_fvigencia_inicio, --Fecha de activación
          X.po_fvigencia_fin  -- Fecha de cancelación
   from  cr_situacion_gar,
         cr_situacion_cliente,
         -- JES --> cob_custodia..cu_poliza_asociada,
         cob_custodia..cu_poliza X,
         cr_cotiz3_tmp
   -- JES --> where sg_codigo         = pa_garantia
   where sg_usuario        = @s_user
   and   sg_secuencia      = @s_sesn
   and   sg_tramite        = @i_tramite
   and   sc_usuario        = @s_user
   and   sc_secuencia      = @s_sesn
   and   sc_tramite        = sg_tramite
   and   sg_cliente        = sc_cliente
   -- JES --> and   X.po_secuencial   = pa_secuencial
   and   X.po_moneda       = moneda
   and   X.po_estado_poliza in (select @w_estado_poliza)--( @w_vencido, @w_vigente)
   and   spid              = @w_spid

   if @@error <> 0
   begin
   /* Error en insercion de registro */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 2103001
        rollback
    return 1
   end

   select @w_tramite = 0

     set rowcount 1
     select @w_tramite = sp_tramite_d,
            @w_cliente = sp_cliente,
            @w_poliza  = sp_poliza
      from cr_situacion_poliza
     where sp_cliente  > 0
       and sp_tramite   = @i_tramite
       and sp_usuario   = @s_user
       and sp_secuencia = @s_sesn
       and sp_tipo_deuda= 'D'
       and sp_tramite   >= @w_tramite
     order by sp_tramite_d, sp_poliza
     set rowcount 0

   While @w_tramite > 0
   BEGIN
       /** BORRA POLIZAS DUPLICADAS **/
       delete cr_situacion_poliza
        where sp_cliente   = @w_cliente
          and sp_tramite   = @i_tramite
          and sp_usuario   = @s_user
          and sp_secuencia = @s_sesn
          and sp_tipo_deuda= 'I'
          and sp_poliza    = @w_poliza
          and sp_tramite_d = @w_tramite

     set rowcount 1
       /** BUSCA SIGUIENTE POLIZAS **/
      select @w_tramite = sp_tramite_d,
             @w_cliente = sp_cliente,
             @w_poliza  = sp_poliza
       from cr_situacion_poliza
      where sp_cliente  > 0
        and sp_tramite   = @i_tramite
        and sp_usuario   = @s_user
        and sp_secuencia = @s_sesn
        and sp_tipo_deuda= 'D'
        and ((sp_tramite_d = @w_tramite and sp_poliza > isnull( @w_poliza, '')) or sp_tramite_d > @w_tramite )
       order by sp_tramite_d, sp_poliza

       if @@rowcount = 0
          select @w_tramite = 0

     set rowcount 0

   END
   set rowcount 0
END

delete from cr_cotiz3_tmp where spid = @w_spid --tabla de cotizaciones
return 0


GO
