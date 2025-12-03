/**************************************************************************/
/*  Archivo:                    sp_eliminar_integrante.sp                 */
/*  Stored procedure:           sp_eliminar_integrante                    */
/*  Base de Datos:              cob_credito                               */
/*  Producto:                   Credito                                   */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido sin el debido                    */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada y por lo tanto, derivará en acciones legales civiles         */
/*   y penales en contra del infractor según corresponda.                 */
/**************************************************************************/
/*                          PROPOSITO                                     */
/*  Este stored procedure permite eliminar a integrantes de un tramite    */
/*  grupal y un grupo                                                     */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA          AUTOR                            RAZON                 */
/*  27/May/2022   Dilan Morales           implementacion                  */
/*  10/Jun/2022   Dilan Morales           Correccion para validar roles   */
/*  20/Ene/2023   Patricia Jarrin         Proceso Fiadores Grupal- S766352*/
/*  17/Mar/2023   Bruno Duenas            Validar estado catalogo         */
/*  23-Oct-2023   P. Jarrin.              Ajuste Tasa S923938-R214406     */
/*  18/Dec/2023   Bruno Duenas            R221684-Cambio registro TS      */
/**************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_eliminar_integrante' and type = 'P')
    drop proc sp_eliminar_integrante
go

create proc sp_eliminar_integrante
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
  @i_tramite_individual int         = null,
  @i_tramite_grupal     int         = null,
  @i_id_cliente         int         = null,
  @i_id_grupo           int         = null,
  @i_eliminar_delgrupo  tinyint     = null,
  @i_eliminar_deltramite tinyint    = null  
)
as

declare
    @w_sp_name              varchar (30),
    @w_return               int,
    @w_error                int,
    @w_tramite              int,
    @w_est_novigente_cca    tinyint,
    @w_est_anulado_cca      tinyint,
    @w_est_credito_cca      tinyint,
    @w_est_anulado_tr       char(1),
    @w_tg_monto_aprobado    money,
    @w_monto                money,
    @w_monto_recomendado    money,
    @w_monto_max            money,
    @w_ahorro               money,
    @w_tr_cod_actividad     catalogo,
    @w_sector               catalogo,
    @w_participa_ciclo      char(1),
    @w_ssn                  int,
    --Quitar rp_ssn
    @w_cod_tramites         varchar(max)
    
    
    
BEGIN TRAN 
-- CARGAR VALORES INICIALES
select @w_sp_name = 'sp_eliminar_integrante'


-- DMO SE VALIDA QUE EXISTA
if not exists(
select 1 from cob_credito..cr_tramite_grupal 
where tg_tramite        = @i_tramite_grupal 
and tg_cliente          = @i_id_cliente 
and tg_grupo            = @i_id_grupo
and tg_participa_ciclo  = 'S')
BEGIN

    select @w_error = 2110129 --No existe integrante
    goto ERROR

END


if exists(select 1 from 
    (select distinct cg_rol 
    from cobis..cl_cliente_grupo 
    inner join 
    cob_credito..cr_tramite_grupal 
    on cg_ente   = tg_cliente 
    where cg_estado  = 'V'
    and tg_tramite = @i_tramite_grupal 
    and cg_grupo   = tg_grupo
    and tg_monto   > 0
    and tg_cliente <> @i_id_cliente 
    and tg_participa_ciclo = 'S') as G
RIGHT join 
    (select b.codigo 
    from   cobis..cl_tabla a,cobis..cl_catalogo b
    where  a.tabla = 'cl_rol_controlar' 
    and a.codigo = b.tabla
    and b.estado = 'V') as R
on  G.cg_rol = R.codigo
WHERE G.cg_rol IS NULL 
)
begin
    select @w_error = 2108051 --LOS INTEGRANTES DEL COMITE DEBEN PARTICIPAR
    goto ERROR
end


-- SE ELIMINA AL INTEGRANTE DEL TRAMITE GRUPAL
if(@i_eliminar_deltramite = 1)
BEGIN 

    --DMO SE VALIDA TASA OPERACION HIJAS
    exec @w_return =  cob_credito..sp_actualiza_tasa_grupal   
         @s_user      = @s_user,
         @s_term      = @s_term,
         @s_ofi       = @s_ofi,
         @s_date      = @s_date,    
         @i_tramite   = @i_tramite_grupal,
         @i_operacion = 'V'

    if @w_return <> 0
    begin
        select @w_error = @w_return
        goto ERROR
    end          
             
    --DMO INSERT EN ts_tramite_grupal ANTES DE ACTUALIZAR
    insert into cob_credito..ts_tramite_grupal
    (
    secuencial,         tipo_transaccion,   clase,              
    fecha,              usuario,            terminal,
    oficina,            tabla,              lsrv,               
    srv,                tramite,            grupo,
    cliente,            monto,              grupal,             
    operacion,          prestamo,           referencia_grupal,
    cuenta,             cheque,             participa_ciclo,    
    monto_aprobado,     ahorro,             monto_max,
    bc_ln,              incremento,         monto_ult_op,       
    monto_max_calc,     nueva_op,           monto_min_calc,
    conf_grupal,        destino,            sector,             
    monto_recomendado,  estado,             id_rechazo,
    descripcion_rechazo
    )
    select
    @s_ssn,                 21847 ,                 'P',                
    @s_date,                @s_user,                @s_term,
    @s_ofi,                 'cr_tramite_grupal',    @s_lsrv,            
    @s_srv,                 tg_tramite,             tg_grupo,
    tg_cliente,             tg_monto,               tg_grupal,          
    tg_operacion,           tg_prestamo,            tg_referencia_grupal,
    tg_cuenta,              tg_cheque,              tg_participa_ciclo, 
    tg_monto_aprobado,      tg_ahorro,              tg_monto_max,
    tg_bc_ln,               tg_incremento,          tg_monto_ult_op,    
    tg_monto_max_calc,      tg_nueva_op,            tg_monto_min_calc,
    tg_conf_grupal,         tg_destino,             tg_sector,          
    tg_monto_recomendado,   tg_estado,              tg_id_rechazo,
    tg_descripcion_rechazo
    from cob_credito..cr_tramite_grupal
    where tg_cliente    = @i_id_cliente
    and tg_grupo        = @i_id_grupo
    and tg_tramite      = @i_tramite_grupal
    
    --ERROR EN CREACION DE TRANSACCION DE SERVICIO
    if @@error <> 0 
    begin
        select @w_error = 1720049
        goto ERROR
    end 
    
    
    --DMO UPDATE PARA QUE EL CLIENTE NO PARTICIPE EN EL TRAMITE GRUPAL
    select  @w_tg_monto_aprobado    = 0 ,
            @w_monto                = 0,
            @w_tr_cod_actividad     = null ,
            @w_sector               = null,
            @w_monto_recomendado    = 0,
            @w_ahorro               = 0, 
            @w_monto_max            = 0,
            @w_participa_ciclo      = 'N'
            
    
    update cob_credito..cr_tramite_grupal
        set    
        tg_monto             = @w_monto,
        tg_participa_ciclo   = @w_participa_ciclo,
        tg_monto_aprobado    = @w_tg_monto_aprobado,
        tg_ahorro            = @w_ahorro,
        tg_monto_max         = @w_monto_max, 
        tg_destino           = @w_tr_cod_actividad,
        tg_sector            = @w_sector,
        tg_monto_recomendado = @w_monto_recomendado  
    where  tg_tramite           = @i_tramite_grupal
    and    tg_cliente           = @i_id_cliente
    and    tg_grupo             = @i_id_grupo
    
    
    --DMO INSERT DE REGISTRO PARA  EL CLIENTE QUE YA NO PARTICIPE EN EL TRAMITE GRUPAL
    insert into cob_credito..ts_tramite_grupal
    (
    secuencial,         tipo_transaccion,   clase,              
    fecha,              usuario,            terminal,
    oficina,            tabla,              lsrv,               
    srv,                tramite,            grupo,
    cliente,            monto,              grupal,             
    operacion,          prestamo,           referencia_grupal,
    cuenta,             cheque,             participa_ciclo,    
    monto_aprobado,     ahorro,             monto_max,
    bc_ln,              incremento,         monto_ult_op,       
    monto_max_calc,     nueva_op,           monto_min_calc,
    conf_grupal,        destino,            sector,             
    monto_recomendado,  estado,             id_rechazo,
    descripcion_rechazo
    )
    select
    @s_ssn,                 21848 ,                 'A',                
    @s_date,                @s_user,                @s_term,
    @s_ofi,                 'cr_tramite_grupal',    @s_lsrv,            
    @s_srv,                 tg_tramite,             tg_grupo,
    tg_cliente,             @w_monto,               tg_grupal,          
    tg_operacion,           tg_prestamo,            tg_referencia_grupal,
    tg_cuenta,              tg_cheque,              @w_participa_ciclo, 
    @w_tg_monto_aprobado,   @w_ahorro ,             @w_monto_max,
    tg_bc_ln,               tg_incremento,          tg_monto_ult_op,    
    tg_monto_max_calc,      tg_nueva_op,            tg_monto_min_calc,
    tg_conf_grupal,         @w_tr_cod_actividad,    @w_sector,          
    @w_monto_recomendado,   tg_estado,              tg_id_rechazo,
    tg_descripcion_rechazo
    from cob_credito..cr_tramite_grupal
    where tg_cliente    = @i_id_cliente
    and tg_grupo        = @i_id_grupo
    and tg_tramite      = @i_tramite_grupal
    
    --ERROR EN CREACION DE TRANSACCION DE SERVICIO
    if @@error <> 0 
    begin
        select @w_error = 1720049
        goto ERROR
    end 
    
    
    --DMO INSERT EN ts_tramite ANTES DE ACTUALIZAR
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
   monto_solicitado,                     tipo_plazo ,                            tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito,                         alianza,                                exp_cliente, 
   monto_max_tr)

   select 
   @s_ssn,                               21120,                                  'P',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite,                              tr_tipo,
   tr_oficina,                           tr_usuario,                              tr_fecha_crea,
   tr_oficial,                           tr_sector,                               tr_ciudad,
   tr_estado,                            tr_nivel_ap,                             tr_fecha_apr,
   tr_usuario_apr,                       tr_truta,                                tr_numero_op,
   tr_numero_op_banco,                   tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                             tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion,                        tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   tr_num_acciones,                      tr_responsable,                          tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,                         tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg,                           tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito,                      tr_alianza,                              tr_experiencia,                       
   tr_monto_max
   from  cob_credito..cr_tramite
   where tr_tramite = @i_tramite_individual
   
   if @@error <> 0
   begin
      ---ERROR EN INSERCION DE TRANSACCION DE SERVICION
      select @w_error = 1720049
      goto  ERROR
   end
    
        --Estados de cartera
    exec    @w_return           = cob_cartera..sp_estados_cca
            @o_est_novigente    = @w_est_novigente_cca out,
            @o_est_anulado      = @w_est_anulado_cca   out,
            @o_est_credito      = @w_est_credito_cca   out
    
    if @w_return <> 0
    begin
        select @w_error = @w_return
        goto ERROR
    end
    
    select @w_est_anulado_tr = 'X'   
    
    update cob_credito..cr_tramite  
    set tr_estado = @w_est_anulado_tr
    where tr_tramite =  @i_tramite_individual
    
    
    --DMO INSERT EN ts_tramite DESPUES DE ACTULIZAR
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
   monto_solicitado,                     tipo_plazo ,                            tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito,                         alianza,                                exp_cliente, 
   monto_max_tr)

   select 
   @s_ssn,                               21020 ,                                  'A',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite,                              tr_tipo,
   tr_oficina,                           tr_usuario,                              tr_fecha_crea,
   tr_oficial,                           tr_sector,                               tr_ciudad,
   @w_est_anulado_tr,                    tr_nivel_ap,                             tr_fecha_apr,
   tr_usuario_apr,                       tr_truta,                                tr_numero_op,
   tr_numero_op_banco,                   tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                             tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion,                        tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   tr_num_acciones,                      tr_responsable,                          tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,                         tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg,                           tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito,                      tr_alianza,                              tr_experiencia,                       
   tr_monto_max
   from  cob_credito..cr_tramite
   where tr_tramite = @i_tramite_individual
   
   if @@error <> 0
   begin
      --ERROR EN INSERCION DE TRANSACCION DE SERVICION
      select @w_error = 1720049
      goto  ERROR
   end
    
    
    update cob_cartera..ca_operacion
    set op_estado = @w_est_anulado_cca   
    where op_tramite =  @i_tramite_individual
    
    --DMO SE ACTUALIZA TASA OPERACION HIJAS
    exec @w_return =  cob_credito..sp_actualiza_tasa_grupal     
         @s_user      = @s_user,
         @s_term      = @s_term,
         @s_ofi       = @s_ofi,
         @s_date      = @s_date,    
         @i_tramite   = @i_tramite_grupal,
         @i_operacion = 'U'

    if @w_return <> 0
    begin
        select @w_error = @w_return
        goto ERROR
    end             
    
END


--DMO SE ELIMINA INTEGRANTE DE LOS TRAMITES GRUPALES ASOCIADOS Y DEL GRUPO
if(@i_eliminar_delgrupo = 1)
BEGIN
    
        if  exists(
        select 1 from cob_cartera..ca_operacion 
        where op_operacion in (
        select tg_operacion FROM cob_credito..cr_tramite_grupal 
        where tg_grupo          = @i_id_grupo 
        and tg_cliente          = @i_id_cliente 
        and tg_participa_ciclo  = 'S'
        )
        and op_estado not in (99 , 0 , 3, 6)
        )
        BEGIN 
            select @w_error = 1720235 -- TIENE OPERACIONES PENDIENTES
            goto ERROR
        END
        

        select @w_cod_tramites = STRING_AGG(convert(varchar(max), tg_tramite),',')
        FROM cob_credito..cr_tramite_grupal with (nolock), 
             cob_workflow..wf_inst_proceso with (nolock)
        where tg_tramite          = io_campo_3
        and   tg_grupo            = @i_id_grupo 
        and   tg_cliente          = @i_id_cliente 
        and   tg_participa_ciclo  = 'N'
        and   io_estado in('EJE','SUS')
        
        --INSERT EN ts_tramite_grupal ANTES DE ACTUALIZAR (Solo 1 registro)
        insert into cob_credito..ts_tramite_grupal
        (
        secuencial,         tipo_transaccion,   clase,              
        fecha,              usuario,            terminal,
        oficina,            tabla,              lsrv,               
        srv,                tramite,            grupo,
        cliente,            monto,              grupal,             
        operacion,          prestamo,           referencia_grupal,
        cuenta,             cheque,             participa_ciclo,    
        monto_aprobado,     ahorro,             monto_max,
        bc_ln,              incremento,         monto_ult_op,       
        monto_max_calc,     nueva_op,           monto_min_calc,
        conf_grupal,        destino,            sector,             
        monto_recomendado,  estado,             id_rechazo,
        descripcion_rechazo
        )
        select top 1
        @s_ssn,                 21846,                  'B',                
        @s_date,                @s_user,                @s_term,
        @s_ofi,                 'cr_tramite_grupal',    @s_lsrv,            
        @s_srv,                 tg_tramite,             tg_grupo,
        tg_cliente,             tg_monto,               tg_grupal,          
        tg_operacion,           tg_prestamo,            tg_referencia_grupal,
        tg_cuenta,              tg_cheque,              tg_participa_ciclo, 
        tg_monto_aprobado,      tg_ahorro,              tg_monto_max,
        tg_bc_ln,               tg_incremento,          tg_monto_ult_op,    
        tg_monto_max_calc,      tg_nueva_op,            tg_monto_min_calc,
        tg_conf_grupal,         tg_destino,             tg_sector,          
        tg_monto_recomendado,   tg_estado,              tg_id_rechazo,
        @w_cod_tramites
        FROM cob_credito..cr_tramite_grupal with (nolock), 
             cob_workflow..wf_inst_proceso with (nolock)
        where tg_tramite          = io_campo_3
        and   tg_grupo            = @i_id_grupo 
        and   tg_cliente          = @i_id_cliente 
        and   tg_participa_ciclo  = 'N'
        and   io_estado in('EJE','SUS')
        --ERROR EN CREACION DE TRANSACCION DE SERVICIO
        if @@error <> 0 
        begin
            select @w_error = 1720049
            goto ERROR
        end 
        
        
        
        declare cur_tramites_grupales cursor for (
        select tg_tramite
        FROM cob_credito..cr_tramite_grupal with (nolock), 
             cob_workflow..wf_inst_proceso with (nolock)
        where tg_tramite          = io_campo_3
        and   tg_grupo            = @i_id_grupo 
        and   tg_cliente          = @i_id_cliente 
        and   tg_participa_ciclo  = 'N'
        and   io_estado in('EJE','SUS')
        )
        open cur_tramites_grupales 
            
        fetch cur_tramites_grupales
        into @w_tramite
        while(@@fetch_status = 0)
        BEGIN
        
            delete cob_credito..cr_tramite_grupal 
            where   tg_tramite          = @w_tramite
            and     tg_grupo            = @i_id_grupo 
            and     tg_cliente          = @i_id_cliente 
            
            fetch cur_tramites_grupales
            into @w_tramite
        END
    close cur_tramites_grupales
    deallocate cur_tramites_grupales

    insert into cobis..ts_cliente_grupo (
    secuencial, tipo_transaccion, clase,  --1
    srv,        lsrv,             ente,   --2
    grupo,      usuario,          terminal,--3
    oficial,    fecha_reg,        rol,     --4
    estado,     calif_interna,    fecha_desasociacion--5
    )
    select                               
    @s_ssn,      172041,              'B',       --1
    @s_srv,      @s_lsrv,           cg_ente,   --2
    cg_grupo,    @s_user,           @s_term,   --3
    cg_oficial,  cg_fecha_reg,      cg_rol, --4
    cg_estado,   cg_calif_interna,  cg_fecha_desasociacion--5
    from cobis..cl_cliente_grupo
    where cg_ente   = @i_id_cliente
    and cg_grupo    = @i_id_grupo
    -- Si no se puede insertar transaccion de servicio, error --
    if @@error <> 0
    begin
        select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
        goto ERROR
    end
    
    delete cobis..cl_cliente_grupo
    where   cg_grupo    = @i_id_grupo 
    and     cg_ente     = @i_id_cliente   
    
    if @@error <> 0
    begin
        select @w_error = 725059 
        goto ERROR
    end
    
    --Registro antes del cambio
    insert into cobis..ts_persona_prin (
    secuencia,      tipo_transaccion,       clase,
    fecha,          usuario,                terminal,
    srv,            lsrv,                    persona,
    nombre,         p_apellido,             s_apellido,
    sexo,           cedula,                 tipo_ced,
    pais,           profesion,              estado_civil,
    actividad,      num_cargas,             nivel_ing,
    nivel_egr,      tipo,                   filial,
    oficina,        fecha_nac,              grupo,
    oficial,        comentario,             retencion,
    fecha_mod,      fecha_expira,           sector,
    ciudad_nac,     nivel_estudio,          tipo_vivienda,
    calif_cliente,  tipo_vinculacion,       pais_nac,
    provincia_nac,  naturalizado,           forma_migratoria,
    nro_extranjero, calle_orig,             exterior_orig,
    estado_orig,     hora)
    select
    @s_ssn,         172003,             'P',
    getdate(),      @s_user,            @s_term,
    @s_srv,         @s_lsrv,            en_ente,
    en_nombre,      p_p_apellido,       p_s_apellido,
    p_sexo,         en_ced_ruc,         en_tipo_ced,
    en_pais,        p_ocupacion,        p_estado_civil,
    en_actividad,   p_num_cargas,       p_nivel_ing,
    p_nivel_egr,    en_subtipo,         en_filial,
    en_oficina,     p_fecha_nac,        en_grupo,
    en_oficial,     en_comentario,      en_retencion,
    en_fecha_mod,   p_fecha_expira,     en_sector,
    p_ciudad_nac,   p_nivel_estudio,    p_tipo_vivienda,
    en_calificacion, en_tipo_vinculacion, en_pais_nac,
    en_provincia_nac, en_naturalizado, en_forma_migratoria,
    en_nro_extranjero, en_calle_orig, en_exterior_orig,
    en_estado_orig,  getdate()
   from cobis..cl_ente
   where en_ente = @i_id_cliente

    --ERROR EN CREACION DE TRANSACCION DE SERVICIO
    if @@error <> 0 begin
       select @w_error = 1720049
       goto ERROR
    end
    
    update cobis..cl_ente
    set     en_grupo    = null 
    where   en_ente     = @i_id_cliente  
    
    if @@error <> 0
    begin
        select @w_error = 725014 
        goto ERROR
    end

    --Registro despues del cambio
    insert into cobis..ts_persona_prin (
    secuencia,      tipo_transaccion,       clase,
    fecha,          usuario,                terminal,
    srv,            lsrv,                    persona,
    nombre,         p_apellido,             s_apellido,
    sexo,           cedula,                 tipo_ced,
    pais,           profesion,              estado_civil,
    actividad,      num_cargas,             nivel_ing,
    nivel_egr,      tipo,                   filial,
    oficina,        fecha_nac,              grupo,
    oficial,        comentario,             retencion,
    fecha_mod,      fecha_expira,           sector,
    ciudad_nac,     nivel_estudio,          tipo_vivienda,
    calif_cliente,  tipo_vinculacion,       pais_nac,
    provincia_nac,  naturalizado,           forma_migratoria,
    nro_extranjero, calle_orig,             exterior_orig,
    estado_orig,     hora)
    select
    @s_ssn,         172003,             'A',
    getdate(),      @s_user,            @s_term,
    @s_srv,         @s_lsrv,            @i_id_cliente,
    en_nombre,      p_p_apellido,       p_s_apellido,
    p_sexo,         en_ced_ruc,         en_tipo_ced,
    en_pais,        p_ocupacion,        p_estado_civil,
    en_actividad,   p_num_cargas,       p_nivel_ing,
    p_nivel_egr,    en_subtipo,         en_filial,
    en_oficina,     p_fecha_nac,        en_grupo,
    en_oficial,     en_comentario,      en_retencion,
    en_fecha_mod,   p_fecha_expira,     en_sector,
    p_ciudad_nac,   p_nivel_estudio,    p_tipo_vivienda,
    en_calificacion, en_tipo_vinculacion, en_pais_nac,
    en_provincia_nac, en_naturalizado, en_forma_migratoria,
    en_nro_extranjero, en_calle_orig, en_exterior_orig,
    en_estado_orig,  getdate()
   from cobis..cl_ente
   where en_ente = @i_id_cliente

    --ERROR EN CREACION DE TRANSACCION DE SERVICIO
    if @@error <> 0 begin
       select @w_error = 1720049
       goto ERROR
    end
    
END

if exists (select 1 from cob_credito..cr_gar_propuesta where gp_tramite = @i_tramite_individual  and gp_deudor = @i_id_cliente)
begin
   IF OBJECT_ID('tempdb..#tmp_gar_prin') IS NOT NULL
    drop table #tmp_gar_prin
    create table #tmp_gar_prin(
    cu_custodia  int,
    gp_garantia  varchar(64) 
    ) 
    
    IF OBJECT_ID('tempdb..#tmp_tramite') IS NOT NULL
    drop table #tmp_tramite
    create table #tmp_tramite(
    id_tramite  int 
    )   

    IF OBJECT_ID('tempdb..#tmp_garantia') IS NOT NULL
    drop table #tmp_garantia
    create table #tmp_garantia(
    cu_custodia  int,
    gp_garantia  varchar(64) 
    ) 
    
    IF OBJECT_ID('tempdb..#tmp_resultado') IS NOT NULL
    drop table #tmp_resultado
    create table #tmp_resultado(
    cu_custodia  int,
    gp_garantia  varchar(64) 
    ) 
         
    insert into #tmp_tramite
    select op_tramite
      from cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion with(nolock)
     where tg_operacion = op_operacion and tg_tramite = @i_tramite_grupal 
       and tg_participa_ciclo = 'S'
       and tg_cliente != @i_id_cliente

     insert into #tmp_garantia
     select cu_custodia, gp_garantia 
       from cob_credito..cr_gar_propuesta, 
            cob_custodia..cu_custodia
      where gp_garantia = cu_codigo_externo
        and cu_garante   = @i_id_cliente
        and gp_tramite in (select id_tramite
                             from #tmp_tramite)

    insert into #tmp_gar_prin
    select cu_custodia, gp_garantia 
       from cob_credito..cr_gar_propuesta, 
            cob_custodia..cu_custodia
      where gp_garantia = cu_codigo_externo
        and gp_tramite  = @i_tramite_individual
        and gp_deudor   = @i_id_cliente

    insert into #tmp_resultado
    select cu_custodia, ltrim(rtrim(gp_garantia)) 
      from #tmp_garantia
    union
    select cu_custodia,  ltrim(rtrim(gp_garantia))  
      from #tmp_gar_prin
        
      --Eliminar Garantia
      delete from cob_custodia..cu_custodia
      where cu_custodia  in (select cu_custodia
                               from #tmp_resultado)
      
      if @@error <> 0
      begin
         select @w_error = 1907001
         goto ERROR
      end

      --Eliminar Cliente Garantia
      delete from cob_custodia..cu_cliente_garantia
      where cg_custodia in (select cu_custodia
                              from #tmp_resultado)
      if @@error <> 0
      begin
         select @w_error = 1907001
         goto ERROR
      end

      --Eliminar Garantiaas Propuestas
      delete from cob_credito..cr_gar_propuesta
      where gp_garantia in ( select gp_garantia 
                               from #tmp_resultado)
      if @@error <> 0
      begin
         select @w_error = 1907001
         goto ERROR
      end
end  
 
COMMIT TRAN

return 0

ERROR:
   ROLLBACK TRAN
   exec cobis..sp_cerror
   @t_debug     ='N',
   @t_file      ='',
   @t_from      =@w_sp_name, 
   @i_num       = @w_error
   return @w_error


GO