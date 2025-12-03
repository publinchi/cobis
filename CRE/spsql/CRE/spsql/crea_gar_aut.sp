/************************************************************************/
/*      Archivo:                cr_crea_gar_aut.sp                      */
/*      Stored procedure:       sp_crea_gar_aut                         */
/*      Producto:               Crédito                                 */
/*      Disenado por:           Soraya Ramírez                          */
/*      Fecha de escritura:     19-03-2009                              */
/* **********************************************************************/
/*                            IMPORTANTE                                */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    'COBISCORP'                                                       */
/*    Su  uso no autorizado  queda expresamente  prohibido asi como     */
/*    cualquier   alteracion  o  agregado  hecho por  alguno de sus     */
/*    usuarios   sin el debido  consentimiento  por  escrito  de la     */
/*    Presidencia Ejecutiva de COBISCORP o su representante.            */
/* **********************************************************************/
/*                             PROPOSITO                                */
/* Creación automática de una garantía tipo Pagaré                      */
/************************************************************************/
/*                            MODIFICACIONES                            */
/* FECHA      AUTOR           RAZON                                     */
/* 19/03/2009 S. Ramírez   Requerimiento CC-CREDITO-NR3-PCC             */
/* 11/01/2024 B. Dueñas    R220801 - Agregar info localización          */
/************************************************************************/

use cob_credito
go

if exists(select * from sysobjects where name = 'sp_crea_gar_aut')
    drop proc sp_crea_gar_aut
go
create proc sp_crea_gar_aut(
      @t_from                varchar(30) = null,
      @s_date                datetime    = null,
      @s_user                login       = null,
      @s_term                varchar(64) = null,
      @s_ofi                 smallint    = null,
      @i_op_oficina          smallint    = null,            -- Oficina de Cartera
      @i_op_ciudad           int         = null,            -- Ciudad de Cartera
      @i_op_clase            catalogo    = null,            -- Clase de Cartera
      @i_op_fecha_liq        datetime    = null,            -- Fecha de Liquidación de Cartera
      @i_op_nombre           descripcion = null,            -- Nombre del Cliente de Cartera
      @i_op_cliente          int         = null,            -- Código del Cliente
      @i_op_tramite          int,                           -- Número de Trámite
      @i_op_oficial          smallint    = null,            -- Código del Oficial
      @i_operacion           char(1)     = null             -- Cuando se rechaza el tramite

)
as
declare @w_tipo              varchar(30),
        @w_custodia          int,
        @w_codigo_externo    varchar(64),
        @w_filial            int,
        @w_error             int,
        @w_valor_monto       money,
        @w_periodicidad      char(1),
        @w_abierta_cerrada   char(1),
        @w_porcen_cobertura  float,
        @w_sp_name           varchar(50),
        @w_fecha_proceso     datetime,
        @w_monloc            tinyint,
        @w_return            int,
        @w_secservicio       int,
        @w_tipo_tramite      char(1),
        @w_valor_intervalo   smallint,
        @w_commit            char(1),
        @w_msg               varchar(100),
        @w_pais              int,
        @w_provincia         int


-------------------------------------------------------------
--Lee parametros y datos generales del tipo de garantía PAGARE
-------------------------------------------------------------
select @w_sp_name     = 'sp_in_tramite',
       @w_valor_monto = 1 --El valor de la garantia tipo Pagare es 1 peso

select @w_filial = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'FILIAL'
and pa_producto = 'CRE'

select @w_valor_monto = pa_money
from cobis..cl_parametro
where pa_nemonico = 'VGP'
and pa_producto = 'CRE'

select @w_tipo = pa_char
from cobis..cl_parametro
where pa_nemonico = 'CODPAC'
and pa_producto = 'GAR'


-- Informacion de ubicación geográfica
if (@i_op_ciudad is not null)
begin
    
    select @w_pais = pa_smallint from cobis..cl_parametro where pa_nemonico = 'CP' and pa_producto = 'ADM'

    select @w_provincia = ci_provincia
    from   cobis..cl_ciudad
    where  ci_ciudad = @i_op_ciudad
    and    ci_pais   = @w_pais

end

------------------------------------------------------------------------
--SRA: Cuando el tramite regresa de Cartera y se rechaza la garantia
--tipo automática debe cambiar de estado 'F' a 'A': Anulada
------------------------------------------------------------------------

if @i_operacion = 'R'
   begin
      select @w_codigo_externo = cu_codigo_externo
      from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta
      where gp_tramite= @i_op_tramite
      and gp_garantia = cu_codigo_externo
      and cu_tipo = @w_tipo
      and cu_estado= 'F'
      and cu_descripcion = 'Garantia Automatica Tipo Pagare'

      if @w_codigo_externo <> ''
         begin
            update cob_custodia..cu_custodia
            set cu_estado = 'A'
            where cu_codigo_externo = @w_codigo_externo
            and cu_estado = 'F'
            if @@error <>  0
               begin
                   select
                   @w_error = 2110314 --'ERROR AL ACTUALIZAR TABLA cu_custodia'
                 goto ERROR
               end

            update cob_credito..cr_gar_propuesta
            set gp_est_garantia = 'A'
            where gp_garantia   = @w_codigo_externo
            and gp_tramite      = @i_op_tramite
            and gp_est_garantia = 'F'
            if @@error <>  0
                begin
                    select
                    @w_error = 2110315 --'ERROR AL ACTUALIZAR TABLA cr_gar_propuesta'
                  goto ERROR
                end
         end
      return 0
   end


---------------------------------------------
--Se inserta una sola vez la garantía PAGARE
---------------------------------------------

if exists(select 1 from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta where gp_tramite= @i_op_tramite and gp_garantia = cu_codigo_externo and cu_tipo = @w_tipo and cu_estado= 'F')

return 0

else
   begin

      select @w_abierta_cerrada   = tc_adecuada,
             @w_periodicidad      = tc_periodicidad,
             @w_porcen_cobertura  = tc_porcen_cobertura
      from cob_custodia..cu_tipo_custodia
      where tc_tipo = @w_tipo


      -----------------------
      --Lee fecha de proceso
      -----------------------
      select @w_fecha_proceso = fp_fecha
      from cobis..ba_fecha_proceso

      --------------------------------
      --Lee parametro de moneda local
      --------------------------------
      select @w_monloc = pa_tinyint
      from cobis..cl_parametro
      where pa_nemonico = 'MLOCR'
      and pa_producto = 'CRE'

      --------------------------------
      --Lee valor del intervalo
      --------------------------------

      select @w_valor_intervalo = td_factor
      from   cob_cartera..ca_tdividendo
      where  td_tdividendo = @w_periodicidad

      ----------------------------------------------------------------------------------------------------------
      --La garantía tipo Pagare  se crea automáticamente para tipos de Tramite:
      --Solicitud Nueva 'O', Renovación 'R', Nueva utilización de cupo 'T' y Unificación utilización de cupo 'U'
      ----------------------------------------------------------------------------------------------------------


            if not exists (select 1 from cob_custodia..cu_seqnos
                           where  se_filial    = @w_filial
                           and    se_sucursal  = @i_op_oficina
                           and    se_tipo_cust = @w_tipo)
               begin
                  insert into cob_custodia..cu_seqnos values
                  (@w_filial,@i_op_oficina,@w_tipo,1)
                  select @w_custodia = 1
               end
            else
               begin
                  update cob_custodia..cu_seqnos
                  set    se_actual    = se_actual + 1
                  where  se_filial    = @w_filial
                  and    se_sucursal  = @i_op_oficina
                  and    se_tipo_cust = @w_tipo

                  select @w_custodia = se_actual
                  from cob_custodia..cu_seqnos
                  where  se_filial    = @w_filial
                  and    se_sucursal  = @i_op_oficina
                  and    se_tipo_cust = @w_tipo
               end

            exec @w_return = cob_custodia..sp_externo
               @i_filial    =  @w_filial,
               @i_sucursal  =  @i_op_oficina,
               @i_tipo      =  @w_tipo,
               @i_custodia  =  @w_custodia,
               @o_compuesto =  @w_codigo_externo out

            --------------------------------
            --Inserta en cu_custodia
            --------------------------------

            begin tran
            insert into cob_custodia..cu_custodia (
                    cu_abierta_cerrada,     cu_ciudad_gar,                      cu_ciudad_prenda,             cu_clase_custodia,
                    cu_codigo_externo,      cu_compartida,                      cu_cuantia,                   cu_custodia,
                    cu_estado,
                    cu_fecha_ingreso,       cu_fecha_reg,                       cu_filial,                    cu_fuente_valor,
                    cu_inspeccionar,        cu_moneda,                          cu_nro_inspecciones,
                    cu_oficina,             cu_oficina_contabiliza,             cu_periodicidad,              cu_porcentaje_cobertura,
                    cu_propietario,         cu_propuesta,
                    cu_sucursal,            cu_tipo,                            cu_ubicacion,
                    cu_usuario_crea,        cu_valor_actual,
                    cu_valor_compartida,    cu_valor_inicial,
                    cu_motivo_noinsp,       cu_descripcion,                     cu_intervalo,                 cu_canton,
                    cu_provincia,           cu_pais
                    )
            values (
                    @w_abierta_cerrada,      @i_op_ciudad,                      @i_op_oficina,                 '',
                    @w_codigo_externo,       'N',                               'D',                          @w_custodia,
                    'F',
                    @i_op_fecha_liq,         @w_fecha_proceso,                  @w_filial,                    'VARCUS',
                    'N',                     @w_monloc,                         0,
                    @i_op_oficina,           @i_op_oficina,                     @w_periodicidad,              @w_porcen_cobertura,
                    @i_op_nombre,            0,
                    @i_op_oficina,           @w_tipo,                           '5',
                    @s_user,                 @w_valor_monto,
                    0,                       @w_valor_monto,
                    '99',                    'Garantia Automatica Tipo Pagare', @w_valor_intervalo,           @i_op_ciudad,
                    @w_provincia,            @w_pais
                    )
            if @@error <> 0
                  begin
                     rollback tran
                     select
                     @w_error   = 1903001
                     goto ERROR
                  end

            -------------------------------------------------
            --Inserta en transaccion de servicio cu_custodia
            -------------------------------------------------
            exec @w_secservicio = cob_custodia..sp_gensec
            insert into cob_custodia..ts_custodia (
                  secuencial,                          tipo_transaccion,       clase,                  fecha,
                  usuario,                             terminal,               oficina,                tabla,
                  filial,                              sucursal,               tipo,                   custodia,
                  propuesta,                           estado,                 fecha_ingreso,          valor_inicial,
                  valor_actual,                        moneda,                 instruccion,
                  fuente_valor,                        ciudad_prenda,          periodicidad,           usuario_modifica,
                  abierta_cerrada,                     oficina_contabiliza,    depositario,            descripcion
            )
            values (
                  @w_secservicio,                      19090,                  'N',                    getdate(),
                  @s_user,                             @s_term,                @s_ofi,                 'cu_custodia',
                  @w_filial,                           @i_op_oficina,          @w_tipo,                @w_custodia,
                  0,                                   'F',                    @i_op_fecha_liq,        @w_valor_monto,
                  @w_valor_monto,                      @w_monloc,              'Garantia Automatica Tipo  Pagare',
                  'VARCUS',                            @i_op_ciudad,           @w_periodicidad,        @s_user,
                  @w_abierta_cerrada,                  @i_op_oficina,          @i_op_nombre,           @w_codigo_externo
            )
             if @@error <> 0
                begin
                   rollback tran
                   select
                   @w_error   = 1903003
                   goto ERROR
                end

            -------------------------------
            --Inserta deudores de garantía
            -------------------------------
            insert cob_custodia..cu_cliente_garantia (
                    cg_filial,      cg_sucursal,               cg_tipo_cust,       cg_custodia,
                    cg_ente,        cg_principal,              cg_codigo_externo,  cg_oficial,
                    cg_nombre
            )
            select  @w_filial,      @i_op_oficina,             @w_tipo,            @w_custodia,
                    de_cliente,     de_rol,                    @w_codigo_externo,  @i_op_oficial,
                    @i_op_nombre
            from cob_credito..cr_deudores
            where de_tramite = @i_op_tramite
            and   de_rol= 'D'
            if @@error <> 0
                begin
                   rollback tran
                   select
                   @w_error   = 1903001
                   goto ERROR
                end

            -------------------------------------------------------
            --Inserta en transaccion de servicio cu_cliente_garantia
            --------------------------------------------------------
            insert into cob_custodia..ts_cliente_garantia (
                  secuencial,      tipo_transaccion,         clase,
                  fecha,           usuario,                  terminal,
                  oficina,         tabla,                    filial,
                  sucursal,        tipo_cust,                custodia,
                  ente,            principal,                codigo_externo
            )
            values (
                  @w_secservicio,  19040,                    'N',
                  @s_date,         @s_user,                  @s_term,
                  @s_ofi,          'cu_cliente_garantia',    @w_filial,
                  @i_op_oficina,   @w_tipo,                  @w_custodia,
                  @i_op_cliente,   'D',                      @w_codigo_externo
            )

             if @@error <> 0
                begin
                   rollback tran
                   select
                   @w_error   = 1903003
                   goto ERROR
                end

            -----------------------------------
            --Inserta relación trámite-custodia
            -----------------------------------
            insert into cob_credito..cr_gar_propuesta (
              gp_tramite,           gp_garantia,            gp_clasificacion,    gp_exceso,
              gp_monto_exceso,      gp_abierta,             gp_deudor,           gp_est_garantia,
              gp_porcentaje,        gp_valor_resp_garantia, gp_fecha_mod)
            values (
              @i_op_tramite,        @w_codigo_externo,      'a',                 'N',
              0,                    @w_abierta_cerrada,     @i_op_cliente,       'F',
              100,                  @w_valor_monto,         @w_fecha_proceso)

           if @@error <> 0
                begin
                   rollback tran
                   select
                   @w_error   = 2103001
                   goto ERROR
                end
     commit tran
   end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_from  = @w_sp_name,
@i_num   = @w_error
return @w_error
go
