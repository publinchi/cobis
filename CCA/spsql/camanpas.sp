/************************************************************************/
/*   Archivo:                 camanpas.sp                               */
/*   Stored procedure:        sp_mante_prepagos_pasivas                 */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Elcira Pelaez                             */
/*   Fecha de Documentacion:  Dic-2002                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de 'COBISCorp'.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                                 PROPOSITO                            */
/*   Dar mantenimiento a la tabla ca_prepagos_pasivas                   */
/************************************************************************/
/*                               MODIFICACIONES                         */
/*  FECHA            AUTOR             RAZON                            */
/*  AGO/2003        Xavier Maldonado         Correcciones               */
/*  FEB/14/2005     Elcira Pelaez            Nuevo Req. 200             */
/*  DIC/29/2005     Elcira Pelaez            Def 5493                   */
/*  MAY/26/2006     Elcira Pelaez            Def. 6247 vales UVR  pesos */
/*  Abr/12/2022     Carlos Tiguaque          Ciudad feriado nacional    */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from cob_cartera..sysobjects where name = 'sp_mante_prepagos_pasivas')
   drop proc sp_mante_prepagos_pasivas
go

create proc sp_mante_prepagos_pasivas
   @s_user                   login,
   @s_date                   datetime,
   @t_trn                    int          = 0,
   @s_sesn                   int          = 0,
   @s_term                   varchar (30) = NULL,
   @s_ssn                    int          = 0,
   @s_srv                    varchar (30) = null,
   @s_lsrv                   varchar (30) = null,
   @i_operacion              char(1),
   @i_fecha                  datetime     = null,
   @i_fecha_aplicar          datetime     = null,
   @i_secuencial             int          = 0,
   @i_opcion                 char(1)      = null,
   @i_modo                   char(1)      = null,
   @i_codigo_prepago         catalogo     = null,
   @i_motivo_rechazo         catalogo     = null,
   @i_banco_seg_piso         catalogo     = null,
   @i_tasa_prepago           float        = null,
   @i_dias                   int          = null,
   @i_banco                  cuenta       = null

as

declare
   @w_sp_name                 varchar(20),
   @w_fecha_cierre            datetime,
   @w_pp_banco                cuenta,
   @w_pp_oficina              int,
   @w_pp_linea                catalogo,
   @w_op_tramite              int,
   @w_op_nombre               descripcion,
   @w_pp_valor_prepago        money,
   @w_pp_moneda               smallint,
   @w_op_margen_redescuento   float,
   @w_op_cliente              int,
   @w_op_operacion            int,
   @w_pp_secuencial_ing       int,
   @w_op_fecha_fin            datetime,
   @w_pp_fecha_generacion     datetime,
   @w_cod_entidad             catalogo,
   @w_int                     catalogo,
   @w_nom_entidad             descripcion,
   @w_cod_prepago_jur         catalogo,
   @w_cod_prepago_vol         catalogo,
   @w_error                   int,
   @w_tipo_novedad            char(1),
   @w_proximo_vto             datetime,
   @w_fecha_pag               datetime,
   @w_modalidad_int           char(1),
   @w_return                  int,
   @w_tipo_iden               catalogo,
   @w_ced_ruc                 cuenta,
   @w_op_estado               int,
   @w_pp_tipo_reduccion       char(1),
   @w_pp_tipo_novedad         char(1),
   @w_pp_fecha_aplicar        datetime,
   @w_numero_cuota            smallint,
   @w_valor_cap               money,
   @w_estado_cuota            tinyint,
   @w_cod_precancelacion      catalogo,
   @w_comentario_actual       descripcion,
   @w_di_num_dias             int,
   @w_operacionca             int,
   @w_cotizacion_hoy          float,
   @w_ciudad_nacional         int

select @w_sp_name = 'sp_mante_prepagos_pasivas'

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @i_operacion = 'D' ---Delete
begin
   if @i_opcion = '0'
   begin
      if @i_modo = '0'
      begin
         delete ca_prepagos_pasivas
         where  pp_secuencial = @i_secuencial ---Seleccionado por el usuario en pantalla
         and    pp_estado_aplicar = 'N'       ---No aplicado el prepago
         and    pp_estado_registro = 'I'      ---Registro no procesado por el batch
         and    pp_codigo_prepago = @i_codigo_prepago
         and    substring(pp_linea,1,3) = @i_banco_seg_piso

         if @@error != 0 begin
            select @w_error =  711038
            goto ERROR
         end
      end ---modo 0

      if @i_modo = '1'
      begin
         delete ca_prepagos_pasivas
         where pp_secuencial = @i_secuencial ---Seleccionado por el usuario en pantalla
         and   pp_estado_aplicar = 'P'       ---Pendiente o Rechazo
         and   pp_estado_registro = 'I'      ---Registro no procesado por el batch
         and   pp_codigo_prepago = @i_codigo_prepago
         and    substring(pp_linea,1,3) = @i_banco_seg_piso
         if @@error != 0 begin
            select @w_error =  711038
            goto ERROR
         end
      end ---modo 1
   end ---opcion 0
end ---Operacion 'D'

if @i_operacion = 'U' ---Update
begin

   if exists (select 1 from cobis..cl_dias_feriados
              where  df_fecha  = @i_fecha_aplicar
              and    df_ciudad = @w_ciudad_nacional)
      begin
        select @w_error =  710465
        goto ERROR
      end


   if @i_opcion = '1'
   begin
      if @i_modo = '0'
      begin
         update ca_prepagos_pasivas
         set    pp_estado_aplicar = 'S'
         where  pp_estado_aplicar  = 'N'       ---No aplicado el prepago
         and    pp_estado_registro = 'I'      ---Registro no procesado por el batch
         and    pp_fecha_generacion = @i_fecha
         and    pp_codigo_prepago = @i_codigo_prepago
         and    substring(pp_linea,1,3) = @i_banco_seg_piso

         if @@error != 0 begin
           select @w_error =  711039
           goto ERROR
         end
      end ---modo 0

      if @i_modo = '1'
      begin
         update ca_prepagos_pasivas
         set    pp_estado_aplicar = 'S'
         where  pp_estado_aplicar  = 'P'      ---Pendientes o rechazos
         and    pp_estado_registro = 'I'      ---Registro no procesado por el batch
         and    pp_fecha_generacion = @i_fecha
         and    pp_codigo_prepago = @i_codigo_prepago
         and    substring(pp_linea,1,3) = @i_banco_seg_piso

         if @@error != 0 begin
            select @w_error =  711039
            goto ERROR
         end
      end ---modo 0
   end ----opcion 1

   if @i_opcion = '2'
   begin


      if @i_modo = '0'
      begin

         ---def. 6247. la cotizacion debe ser la de la fecha a plicar que el usuario
         --            digita antse de generar la consulta.
         exec sp_buscar_cotizacion
         @i_moneda     = 2,
         @i_fecha      = @i_fecha_aplicar,
         @o_cotizacion = @w_cotizacion_hoy output

         ---PRINT 'camampas.sp @w_cotizacion_hoy %1!',@w_cotizacion_hoy


         update ca_prepagos_pasivas
         set    pp_fecha_aplicar = @i_fecha_aplicar
         where  pp_estado_aplicar = 'N'       ---No aplicado el prepago
         and    pp_estado_registro = 'I'      ---Registro no procesado por el batch
         and    pp_fecha_generacion = @i_fecha
         and    pp_codigo_prepago = @i_codigo_prepago
         and    substring(pp_linea,1,3) = @i_banco_seg_piso

         if @@error != 0 begin
            select @w_error =  711036
            goto ERROR
         end

         update ca_prepagos_pasivas
         set    pp_cotizacion = @w_cotizacion_hoy
         where  pp_estado_aplicar = 'N'       ---No aplicado el prepago
         and    pp_estado_registro = 'I'      ---Registro no procesado por el batch
         and    pp_fecha_generacion = @i_fecha
         and    pp_codigo_prepago = @i_codigo_prepago
         and    substring(pp_linea,1,3) = @i_banco_seg_piso
         and    pp_moneda = 2

         if @@error != 0 begin
            select @w_error =  711037
            goto ERROR
         end


      end ---modo 0



      if @i_modo = '1'
      begin
         update ca_prepagos_pasivas
         set    pp_fecha_aplicar = @i_fecha_aplicar
         where  pp_estado_aplicar = 'P'       ---Pendientes o Rechazos
         and    pp_estado_registro = 'I'      ---Registro no procesado por el batch
         and    pp_fecha_generacion = @i_fecha
         and    pp_codigo_prepago = @i_codigo_prepago

         if @@error != 0
           begin
            select @w_error =  708153 --crear el error
            goto ERROR
         end
      end  ---modo 1
   end ----opcion 2

   if @i_opcion = '3' ---Puede rechazar asi este ya apara aplicar
   begin

      update ca_prepagos_pasivas
      set    pp_estado_aplicar   = 'P', ---Pendiente
             pp_estado_registro  = 'I' ,
             pp_causal_rechazo   = @i_motivo_rechazo
      where  pp_estado_registro  = 'I'      ---Registro no procesado por el batch
      and    pp_fecha_generacion = @i_fecha
      and    pp_codigo_prepago   = @i_codigo_prepago
      and    pp_secuencial       = @i_secuencial ---Seleccionado por el usuario en pantalla
      and    substring(pp_linea,1,3) = @i_banco_seg_piso

      if @@error != 0 begin
         select @w_error =  711040
         goto ERROR
      end
   end ----opcion 3

   --Retirar desmarcar los rechazos
   if @i_opcion = '4'
   begin

      update ca_prepagos_pasivas
      set    pp_estado_aplicar   = 'N',      ---Nuevo
             pp_causal_rechazo   = @i_motivo_rechazo
      where  pp_estado_aplicar   = 'P'      ---Rechazado
      and    pp_estado_registro  = 'I'      ---Registro no procesado por el batch
      and    pp_fecha_generacion = @i_fecha
      and    pp_codigo_prepago   = @i_codigo_prepago
      and    pp_secuencial       = @i_secuencial ---Seleccionado por el usuario en pantalla
      and    substring(pp_linea,1,3) = @i_banco_seg_piso

      if @@error != 0 begin
         select @w_error =  711041
         goto ERROR
      end
   end ----opcion 4
end ---Operacion 'U'

---Totales
if @i_operacion = 'O'
begin

     select 'No.Registros'   = count(1),
            'Causal'         = pp_codigo_prepago,
            'TotCapital'     = sum(pp_valor_prepago),
            'TotalIntereses' = sum(pp_saldo_intereses),
            'TotalPrepagos'  = sum(pp_saldo_intereses + pp_valor_prepago)
     from   ca_prepagos_pasivas
     where  pp_codigo_prepago =  @i_codigo_prepago
     and    pp_fecha_generacion =  @i_fecha
     and    pp_estado_aplicar  = 'N'
     and    pp_estado_registro = 'I'  ---No estan procesados aun
     and    substring(pp_linea,1,3) = @i_banco_seg_piso
     group by pp_codigo_prepago

end

--ACTUALIZAR TODO LO DE LA TABLA ETMPORAL
if @i_operacion = 'A'
begin
   begin tran

      update ca_prepagos_pasivas
      set    pp_tasa             = app_tasa,
             pp_dias_de_interes  = app_dias_de_interes,
             pp_comentario       = app_comentario
      from   ca_actualiza_prepagos,
             ca_prepagos_pasivas
      where  app_user             = @s_user
      and    pp_banco             = app_banco
      and    pp_secuencial        = app_secuencial
      and    pp_fecha_generacion  = app_fecha_generacion

     --Elimina de la temporal para los datos del usuario

     delete ca_actualiza_prepagos
     where app_user = @s_user

    commit tran

end

if @i_operacion = 'L'
begin
    delete ca_actualiza_prepagos
    where app_user = @s_user
end

if @i_operacion = 'T'
begin

   if not exists (select 1 from ca_prepagos_pasivas
   where pp_banco =  @i_banco
   and   pp_secuencial =  @i_secuencial)
   begin
      select @w_error =  701049
      goto ERROR


   end

   select @w_comentario_actual = pp_comentario
   from ca_prepagos_pasivas
   where pp_banco =  @i_banco
   and   pp_secuencial =  @i_secuencial

   if    @w_comentario_actual = 'Actualizada'
   begin
     update  ca_prepagos_pasivas
     set pp_comentario = null
     where pp_banco =  @i_banco
     and   pp_secuencial =  @i_secuencial
   end
   else
   begin
      --Validacion de los dias con respecto a la tabla de cuotas del prestamo
      select @w_operacionca = op_operacion
      from ca_operacion
      where op_banco = @i_banco

      select @w_di_num_dias = di_dias_cuota
      from ca_dividendo
      where di_operacion = @w_operacionca
      and di_estado = 1

      if @i_dias > @w_di_num_dias
      begin
         select @w_error = 710011
         goto ERROR
      end

      insert into ca_actualiza_prepagos(
                  app_user,            app_secuencial,             app_banco,  app_dias_de_interes,
                  app_tasa,            app_fecha_generacion,       app_comentario)
                  values
                  (
                  @s_user,             @i_secuencial,              @i_banco,    @i_dias,
                  @i_tasa_prepago,     @i_fecha,                   'Actualizada'
                  )
  end

end

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug  = 'N',
   @t_file   =  null,
   @t_from   =  @w_sp_name,
   @i_num    =  @w_error
   return     @w_error
go

