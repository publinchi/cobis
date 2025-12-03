use cob_cartera
go

/************************************************************************/
/*   Archivo:              sp_crear_prestamo.sp                         */
/*   Stored procedure:     sp_crear_prestamo                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Jorge Salazar                                */
/*   Fecha de escritura:   Mar-26-2017                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      ABR-05-2017    Jorge Salazar    Emision Inicial - Version MX    */
/*      MAY-25-2017    Jorge Salazar    CGS-S112643                     */
/*      OCT-18-2019    A. Miramon       Ajuste en calculo de CAT        */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_crear_prestamo')
    drop proc sp_crear_prestamo
go

create proc sp_crear_prestamo
(
   @s_srv                varchar(30),
   @s_lsrv               varchar(30),
   @s_ssn                int,
   @s_user               login,
   @s_term               varchar(30),
   @s_date               datetime,
   @s_sesn               int,
   @s_ofi                smallint,
   @s_rol                smallint,
   ---------------------------------------
   @t_trn                int          = null,
   ---------------------------------------
   @i_tipo               varchar(1)   = 'O',
   @i_anterior           cuenta       = null,
   @i_migrada            cuenta       = null,
   @i_tramite            int          = null,
   @i_cliente            int          = 0,
   @i_nombre             descripcion  = null,
   @i_codeudor           int          = 0,
   @i_sector             catalogo     = null,
   @i_toperacion         catalogo     = null,
   @i_oficina            smallint     = null,
   @i_moneda             tinyint      = null,
   @i_comentario         varchar(255) = null,
   @i_oficial            smallint     = null,
   @i_fecha_ini          datetime     = null,
   @i_monto              money        = null,
   @i_monto_aprobado     money        = null,
   @i_destino            catalogo     = null,
   @i_lin_credito        cuenta       = null,
   @i_ciudad             int          = null,
   @i_forma_pago         catalogo     = null,
   @i_cuenta             cuenta       = null,
   @i_formato_fecha      int          = 101,
   @i_no_banco           varchar(1)   = 'S',
   @i_clase_cartera      catalogo     = null,
   @i_origen_fondos      catalogo     = null,
   @i_fondos_propios     varchar(1)   = 'S',
   @i_ref_exterior       cuenta       = null, 
   @i_sujeta_nego        varchar(1)   = 'N' , 
   @i_convierte_tasa     varchar(1)   = null, 
   @i_tasa_equivalente   varchar(1)   = null,
   @i_fec_embarque       datetime     = null,
   @i_reestructuracion   varchar(1)   = null,
   @i_numero_reest       int          = null,
   @i_num_renovacion     int          = 0,
   @i_tipo_cambio        varchar(1)   = null,
   @i_grupal             varchar(1)   = null,
   @i_tasa               float        = null,
   @i_en_linea           varchar(1)   = 'S',
   @i_externo            varchar(1)   = 'S',
   @i_desde_web          varchar(1)   = 'S',
   @i_banca              catalogo     = null,
   @i_salida             varchar(1)   = 'N',
   @i_borra_tmp          varchar(1)   = 'N',
   ---------------------------------------
   @o_banco              cuenta       = null out,
   @o_operacion          int          = null out,
   @o_tramite            int          = null out,
   @o_msg                varchar(100) = null out
)as 

declare
   @w_sp_name            varchar(64),
   @w_return             int,
   @w_error              int,   
   @w_fecha_proceso      datetime,
   @w_operacion          int,   
   @w_banco              cuenta,
   @w_ced_ruc            varchar(15),
   @w_ced_ruc_codeudor   varchar(15),
   @w_nombre             varchar(60),
   @w_prod_cobis         smallint,   
   @w_tramite            int,
   @w_tplazo             catalogo,
   @w_plazo              smallint,
   @w_commit             char(1)

-- AMG 2019/10/18 - Calculo de CAT
declare 
   @w_cat float
  

--PRINT 'CARGAR VALORES INICIALES'
select
@w_sp_name  = 'sp_crear_prestamo',
@w_commit   = 'N'


--PRINT 'CONSULTAR FECHA DE PROCESO'
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7


if @@trancount = 0 begin
   begin tran
   select @w_commit = 'S'
end


---------------------------------------------
--PRINT 'CONSULTAR INFORMACION DEL DEUDOR PRINCIPAL ' + CONVERT(VARCHAR, @i_cliente)
select
@w_ced_ruc = en_ced_ruc,
@w_nombre  = rtrim(p_p_apellido)+' '+rtrim(isnull(p_s_apellido,''))+' '+rtrim(en_nombre)
from  cobis..cl_ente
where en_ente = @i_cliente
--PRINT CONVERT(VARCHAR, @@rowcount)
set transaction isolation level read uncommitted

if @w_ced_ruc is null or @w_nombre is null begin
   --PRINT CONVERT(VARCHAR, @@rowcount) + ' ' + @w_ced_ruc + ' ' + @w_nombre
   select @w_error = 710200  --No existe cliente solicitado
   goto ERROR_PROCESO
end


--PRINT 'REGISTRAR DEUDOR PRINCIPAL'
exec @w_return = sp_codeudor_tmp
@s_sesn        = @s_sesn,
@s_user        = @s_user,
@i_borrar      = 'S',
@i_secuencial  = 1,
@i_titular     = @i_cliente,
@i_operacion   = 'A',
@i_codeudor    = @i_cliente,
@i_ced_ruc     = @w_ced_ruc,
@i_rol         = 'D',
@i_externo     = 'N'

if @w_return != 0 begin
   select @w_error = @w_return
   goto ERROR_PROCESO
end


--PRINT 'VERIFICAR ENVIO DE CODEUDOR'
if isnull(@i_codeudor, 0) != 0 begin
   --PRINT 'CONSULTAR INFORMACION DEL CODEUDOR'
   select @w_ced_ruc_codeudor = en_ced_ruc
   from cobis..cl_ente
   where  en_ente = @i_codeudor
   set transaction isolation level read uncommitted
   
   if @w_ced_ruc_codeudor is null begin
      select @w_error = 710200  --No existe cliente solicitado
      goto ERROR_PROCESO
   end


   --PRINT 'REGISTRAR CODEUDOR'
   exec @w_return = sp_codeudor_tmp
   @s_sesn        = @s_sesn,
   @s_user        = @s_user,
   @i_borrar      = 'N',
   @i_secuencial  = 2,
   @i_titular     = @i_cliente,
   @i_operacion   = 'A',
   @i_codeudor    = @i_codeudor,
   @i_ced_ruc     = @w_ced_ruc_codeudor,
   @i_rol         = 'C',
   @i_externo     = 'N'

   if @w_return != 0 begin 
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
end

--PRINT 'CREACION DE LA OPERACION'
exec @w_return      = cob_cartera..sp_crear_operacion
@s_user             = @s_user,
@s_sesn             = @s_sesn,
@s_term             = @s_term,
@s_date             = @s_date,
@i_anterior         = @i_anterior,
@i_comentario       = @i_comentario,
@i_oficial          = @i_oficial,
@i_destino          = @i_destino,
@i_monto_aprobado   = @i_monto_aprobado,
@i_fondos_propios   = @i_fondos_propios,
@i_ciudad           = @i_ciudad,
@i_cliente          = @i_cliente,
@i_nombre           = @w_nombre,
@i_sector           = @i_sector,
@i_oficina          = @i_oficina,
@i_toperacion       = @i_toperacion,
@i_monto            = @i_monto,
@i_moneda           = @i_moneda,
@i_fecha_ini        = @i_fecha_ini,
@i_lin_credito      = @i_lin_credito,
@i_migrada          = @i_migrada,
@i_formato_fecha    = @i_formato_fecha,
@i_forma_pago       = @i_forma_pago,
@i_cuenta           = @i_cuenta,
@i_clase_cartera    = @i_clase_cartera,
@i_origen_fondos    = @i_origen_fondos,
@i_sujeta_nego      = @i_sujeta_nego,   -- sujeta a negociacion
@i_ref_exterior     = @i_ref_exterior,  -- numero de referencia exterior
@i_convierte_tasa   = @i_convierte_tasa,  
@i_tasa_equivalente = @i_tasa_equivalente,  
@i_fec_embarque     = @i_fec_embarque,
@i_reestructuracion = @i_reestructuracion,
@i_tipo_cambio      = @i_tipo_cambio,
@i_grupal           = @i_grupal,
@i_tasa             = @i_tasa,
@i_banca            = @i_banca,
@o_banco            = @w_banco output

if @w_return != 0 begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end


--PRINT 'OBTENER NUMERO DE OPERACION DESDE TEMPORAL'
select 
@w_operacion  = opt_operacion,
@w_prod_cobis = opt_prd_cobis
from ca_operacion_tmp
where opt_banco = @w_banco

if @@rowcount = 0 begin
   select @w_error = 701050  --No existe Operacion Temporal
   goto ERROR_PROCESO
end


--PRINT 'GENERAR TRAMITE DEBIDO A LA CREACION DIRECTA EN CCA (VERIFICAR AL FINAL)'
exec @w_return    = cob_credito..sp_tramite_cca
@s_ssn            = @s_ssn,
@s_user           = @s_user,
@s_sesn           = @s_sesn,
@s_term           = @s_term,
@s_date           = @s_date,
@s_srv            = @s_srv,
@s_lsrv           = @s_lsrv,
@s_ofi            = @s_ofi,
@i_oficina_tr     = @i_oficina,
@i_fecha_crea     = @i_fecha_ini,
@i_oficial        = @i_oficial,
@i_sector         = @i_sector,
@i_banco          = @w_banco,
@i_linea_credito  = @i_lin_credito,
@i_toperacion     = @i_toperacion,
@i_producto       = 'CCA',
@i_tipo           = @i_tipo,
@i_monto          = @i_monto,
@i_moneda         = @i_moneda,
@i_periodo        = @w_tplazo,
@i_num_periodos   = @w_plazo,
@i_destino        = @i_destino,
@i_ciudad_destino = @i_ciudad,
@i_renovacion     = @i_num_renovacion,
@i_clase          = @i_clase_cartera, 
@i_cliente        = @i_cliente,
@o_tramite        = @w_tramite out

if @w_return != 0 begin
   select @w_error = @w_return
   goto ERROR_PROCESO
end


update ca_operacion_tmp
set opt_tramite = @w_tramite
where opt_banco   = @w_banco
      
if @@error <> 0  begin
   select @w_error = 2103001
   goto ERROR_PROCESO
end

--PRINT 'TRASLADO DE INFORMACION DESDE LAS TMP A DEFINITIVAS'
exec @w_return = sp_operacion_def
@s_date      = @s_date,
@s_sesn      = @s_sesn,
@s_user      = @s_user,
@s_ofi       = @s_ofi,
@i_banco     = @w_banco,
@i_claseoper = @w_banco

if @w_return != 0 begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end


if isnull(@w_tramite, 0) > 0 begin
   update cob_credito..cr_tramite
   set tr_numero_op = @w_operacion
   where tr_tramite   = @w_tramite

   if @@error <> 0 begin
      select @w_error = 2103001
      goto ERROR_PROCESO
   end


   --------------------------------------------
   if not exists (select 1 from cob_credito..cr_deudores
                  where de_tramite = @w_tramite) begin
      --print 'ingreso informacion de los deudores'

      insert into cob_credito..cr_deudores 
      (de_tramite, de_cliente, de_rol, de_ced_ruc)
      select
      @w_tramite, cl_cliente, cl_rol, cl_ced_ruc
      from cobis..cl_det_producto, cobis..cl_cliente
      where dp_cuenta = @w_banco
      and   dp_producto = 7
      and   cl_det_producto = dp_det_producto

      if @@error <> 0 begin
         select @w_error = 2103001
         goto ERROR_PROCESO
      end
   end
   ------------------------------------------
end

--PRINT 'ELIMINACION DE LA INFORMACION EN TEMPORALES'
if @i_borra_tmp = 'S'
begin
   exec @w_return = sp_borrar_tmp
        @s_sesn   = @s_sesn,
        @s_user   = @s_user,
        @s_term   = @s_term,
        @i_banco  = @w_banco

   if @w_return != 0
   begin 
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
end

	-- AMG 2019/10/18 - Calculo de CAT
   exec @w_return = sp_calculo_cat @i_banco = @w_banco, @o_cat = @w_cat out
   --PRINT 'cat: ' + convert(VARCHAR, @w_cat)
   
   if @w_return != 0
   begin 
      select @w_error = @w_return
      goto ERROR_PROCESO
   end

   update cob_cartera..ca_operacion SET 
   		op_valor_cat = @w_cat
   where op_operacion = @w_operacion

   if @@error <> 0 begin
      select @w_error = 2103001
      goto ERROR_PROCESO
   end


-- LGU-FIN 2017-11-11


--PRINT 'ENVIO DE LOS NUMEROS DE OPERACION Y TRAMITE GENERADOS'
select
@o_banco     = @w_banco,
@o_operacion = @w_operacion,
@o_tramite   = @w_tramite
---------------------------------------------

if @w_commit = 'S' begin 
   commit tran
   select @w_commit = 'N'
end

return 0


ERROR_PROCESO:
--PRINT 'ERROR NUMERO ' + CONVERT(VARCHAR, @w_error)
if @w_commit = 'S'
   rollback tran

return @w_error

go

