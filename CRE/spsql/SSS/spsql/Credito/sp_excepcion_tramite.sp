/***********************************************************************/
/*    Base de Datos:           cob_credito                             */
/*    Stored procedure:        sp_excepcion_tramite                    */
/*    Producto:                Credito                                 */
/*    Disenado por:            Aldo Benavides                          */
/*    Fecha de Documentacion:  14/Jul/95                               */
/***********************************************************************/
/*                            IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de    */
/*    'COBISCORP S.A.'.                                                */
/*    Su uso no autorizado queda expresamente prohibido asi como       */
/*    cualquier autorizacion o agregado hecho por alguno de sus        */
/*    usuario sin el debido consentimiento por escrito de la           */
/*    Presidencia Ejecutiva de COBISCORP S.A. o su representante       */
/***********************************************************************/
/*                            PROPOSITO                                */
/*    Este stored procedure permite realizar las siguientes            */
/*    operaciones en la tabla cr_excepcion_tramite                     */
/*    Insert, Update, de las autorizaciones de las Reglas asociadas    */
/*    a un tramite.                                                    */
/***********************************************************************/
/*                           MODIFICACIONES                            */
/*     FECHA              AUTOR                     RAZON              */
/*    20/Abr/2015     Aldo Benavides    Emision Inicial                */
/*    20/Ago/2015     Mariela Cabay     Agrega operación C para        */
/*                                      consulta de excepciones        */
/*    07/SEP/2015     Aldo Benavides    Exepción 15                    */
/*    21/Dic/2021     Patricio Mora     ORI-S574998-GFI                */
/*    11/ENE/2022     Patricio Mora     Ajustes pantalla recomendación */
/*                                      aprobación excepciones         */
/***********************************************************************/
use cob_credito
go

if object_id ('sp_excepcion_tramite') is not null
    drop procedure sp_excepcion_tramite
go

create proc sp_excepcion_tramite
(
    @t_trn                int          = null,
    @s_date               date,
    @i_operacion          char,
    @i_tramite            int          = null,
    @i_regla              varchar(30)  = null,
    @i_autorizante        varchar(30)  = null,
    @i_autorizada         bit          = 0,
    @i_cliente            int          = null,
    @i_observacion        varchar(150) = null,
    @i_actividad          varchar(64)  = null,
    @i_tipo_autorizacion  char         = null,
    @i_grupo              int          = null
)                         
as                        
declare                   
    @w_sp_name            varchar (25),
    @w_error              int,
    @w_codigo_actividad   int,
    @w_tramite            int,
    @w_inst_proc          int,
    @w_rl_acronym         char(10),
    @w_grupo              int,
    @w_cliente            int,
    @w_rl_id              int
    
select @w_sp_name = 'sp_excepcion_tramite'

/*
if @t_trn not in (21798, 21796)
 begin --Tipo de transaccion no corresponde
    select @w_error = 2101006
    goto ERROR
 end
*/

select @w_codigo_actividad = ac_codigo_actividad
  from cob_workflow..wf_actividad
 where ac_nombre_actividad = @i_actividad

if @i_operacion = 'I'
begin
    insert into cr_excepcion_tramite 
               (et_tramite,    et_regla,       et_fecha_autorizacion, et_autorizante,
                et_autorizada, et_observacion, et_tipo_autorizacion,  et_actividad)
        values (@i_tramite,    @i_regla,       @s_date,               @i_autorizante,
                @i_autorizada, @i_observacion, @i_tipo_autorizacion,  @w_codigo_actividad)
    if @@error <> 0
     begin
       /* error en insercion de registro */
       select @w_error = 2103001
       goto ERROR
     end
end

if @i_operacion = 'U'
begin
 if exists (select 1 
              from cr_excepcion_tramite
             where et_tramite   = @i_tramite
               and et_regla     = @i_regla)
             --and et_actividad = @w_codigo_actividad)
    update cr_excepcion_tramite
       set et_fecha_autorizacion = @s_date,
           et_autorizante        = isnull(@i_autorizante,et_autorizante),
           et_autorizada         = @i_autorizada,
           et_observacion        = @i_observacion,
           et_tipo_autorizacion  = @i_tipo_autorizacion
         --et_actividad          = @w_codigo_actividad
     where et_tramite   = @i_tramite
       and et_regla     = @i_regla
    -- and et_actividad = @w_codigo_actividad
 else
  begin --PQU 01/13/2021
    insert into cr_excepcion_tramite 
               (et_tramite,    et_regla,             et_fecha_autorizacion, et_autorizante,
                et_autorizada, et_tipo_autorizacion, et_observacion,        et_actividad)
         values(@i_tramite,    @i_regla,             @s_date,               @i_autorizante,
                @i_autorizada, @i_tipo_autorizacion, @i_observacion,        @w_codigo_actividad)
    if @@error <> 0
     begin
     /* Error en insercion de registro */
        select @w_error = 2103001
        goto ERROR
     end
  end   --FIN PQU 01/13/2021
end

if @i_operacion = 'S'
begin
    select et_regla,
           et_fecha_autorizacion,
           et_autorizante,
           et_autorizada,
           et_observacion,
           et_tipo_autorizacion,
          (select ac_nombre_actividad 
             from cob_workflow..wf_actividad 
            where ac_codigo_actividad = et.et_actividad)
      from cr_excepcion_tramite et
     where et_tramite = @i_tramite
end

if @i_operacion = 'C'
begin
    select tr_tramite, 
           tr_numero_op_banco, 
           bp_name, 
           et_regla, 
           rl_name, 
           et_fecha_autorizacion, 
           et_autorizante, 
           fu_nombre,
 case when et_autorizada = 0 
      then 'No' 
      when et_autorizada = 1 
      then 'Si' 
       end autorizada, '' 
        as et_observacion
      from cob_credito..cr_excepcion_tramite,
           cob_credito..cr_tramite,
           cobis..cl_funcionario,
           cob_pac..bpl_rule,
           cob_fpm..fp_bankingproducts
     where et_tramite     = tr_tramite 
       and et_autorizante = fu_login 
       and et_regla       = rl_acronym 
       and tr_toperacion  = bp_product_id 
       and tr_cliente     = @i_cliente
end

if @i_operacion = 'G'
begin
   select @w_tramite = tg_operacion
     from cob_credito..cr_tramite_grupal
    where tg_tramite = @i_tramite
      and tg_cliente = @i_cliente

   select @w_inst_proc = io_id_inst_proc
     from cob_workflow..wf_inst_proceso
    where io_campo_3   = @i_tramite

    insert into cob_credito..cr_excepcion_tramite 
               (et_tramite,    et_regla,       et_fecha_autorizacion, et_autorizante,      et_cliente,
                et_autorizada, et_observacion, et_tipo_autorizacion,  et_actividad,        et_grupo)
        values (@w_tramite,    @i_regla,       @s_date,               @i_autorizante,      @i_cliente,
                @i_autorizada, @i_observacion, @i_tipo_autorizacion,  @w_codigo_actividad, @i_grupo)
    if @@error <> 0
     begin
       /* error en insercion de registro */
       select @w_error = 2103001
       goto ERROR
     end

   select @w_rl_acronym = et_regla,
          @w_grupo      = et_grupo,
          @w_cliente    = et_cliente
     from cob_credito..cr_excepcion_tramite
    where et_tramite    = @w_tramite
      and et_regla      = @i_regla
      and et_cliente    = @i_cliente
      and et_grupo      = @i_grupo
   
   select @w_rl_id   = rl_id
     from cob_pac..bpl_rule
    where rl_acronym = @w_rl_acronym
   
   update cob_pac..bpl_rule_process_his_cli
      set rphc_resultado_regla = 'APROBADO'
    where rphc_id_inst_proc    = @w_inst_proc
      and rphc_rule_id         = @w_rl_id
      and rphc_grupo_id        = @w_grupo
      and rphc_cliente_id      = @w_cliente
end

return 0

ERROR:
   exec cobis..sp_cerror
        @t_from  = @w_sp_name,
        @i_num   = @w_error
 return @w_error

go
