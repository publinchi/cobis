USE cob_interface
GO
/************************************************************/
/*   ARCHIVO:         sp_solicitud_linea_int.sp             */
/*   NOMBRE LOGICO:   sp_solicitud_linea_int                */
/*   PRODUCTO:        COBIS                                 */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*   Exponer el servicio para apertura de linea de credito  */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/* 21/SEP/2021     EBA         Emision Inicial              */
/*  17/03/2022     pmoreno     Emplear usuario entregado en */
/*                             parametros para crear tramite*/
/* 22/03/2021      pmoreno     Cambio de canal a 3 para     */
/*                             servicio rest                */
/* 23/03/2022      wlopez      Mejora, control de creacion  */
/*                             de instancias de proceso     */ 
/* 24/03/2022     pmoreno      Envio fecha_ini sp validacion*/ 
/* 04/04/2022     pquezada     Cambio en envío de cod oficin*/   
/************************************************************/

if exists (select 1 from sysobjects where name = 'sp_solicitud_linea_int')
   drop proc sp_solicitud_linea_int
go

CREATE PROCEDURE sp_solicitud_linea_int (
        @s_ssn                  int          = null,
        @s_date                 datetime     = null,
        @s_user                 login        = null,
        @s_term                 varchar(64)  = null,
        @s_ofi                  smallint     = null,
        @s_srv                  varchar(30)  = null,
        @s_rol                  smallint     = null,
        @s_sesn                 int          = null,
        @s_org                  char(1)      = null,
        @s_culture              varchar(10)  = null,
        @s_lsrv                 varchar(30)  = null,
        @t_trn                  smallint     = null,
        @t_debug                char(1)      = 'N',
        @t_file                 varchar(14)  = null,
        @t_from                 varchar(30)  = null,
        @i_operacion            char(1)      = null,
        @i_process_nemonic      catalogo     = null,
        @i_oficina              smallint     = null,
        @i_ciudad               int          = null,
        @i_sector               catalogo     = null,
        @i_oficial              smallint     = null,
        @i_moneda               tinyint      = null,
        @i_num_dias             int          = 0,
        @i_toperacion           catalogo     = null,
        @i_origen_fondos        catalogo     = null,
        @i_fecha_ini            datetime     = null,
        @i_fecha_fin            datetime     = null,
        @i_cliente              int          = 0,
        @i_monto                money,
        @i_rotativo             char(1),
        @i_canal                tinyint      = 3,    --Canal: 3=Servicio Rest
        @i_truta                tinyint      = null,
        @i_tramite              int          = null,
        @i_linea_credito        varchar(10)  = null,
        @o_inst_proceso         int          = null out,
        @o_siguiente_alterno    varchar(255) = null out,
        @o_tramite              int          = null out

)
as
declare @w_sp_name              varchar(32),
        @w_error                int,
        @w_return               int,
        @w_codigo_proceso       smallint,
        @w_fecha_inicio         datetime,
        @w_fecha_fin            datetime,
        @w_num_dias             int,
        @w_num_dias_param       int,
        @w_monto_maximo         money,
        @w_monto_minimo         money,
        @w_inst_proceso         int,
        @w_siguiente_alterno    varchar(255),
        @w_tramite              int,
        @w_secuencial           numeric,
        @w_process_id           varchar(30),
        @w_tipo                 char(1),
        @w_usuario_tr           login

select @w_usuario_tr = fu_login 
from cobis..cl_funcionario 
where fu_funcionario = (select oc_funcionario from cobis..cc_oficial where oc_oficial = @i_oficial)

select @i_canal = 3 -- PMO, asigna canal de servicio rest

select @w_sp_name = 'sp_solicitud_linea_int',
       @w_error           = 0,
       @w_return          = 0,
       @w_num_dias        = 0,
       @w_num_dias_param  = 0,
       @w_monto_maximo    = 0,
       @w_monto_minimo    = 0,
       @w_inst_proceso    = 0

      
select @w_codigo_proceso = pr_codigo_proceso 
from   cob_workflow..wf_proceso 
where  pr_nemonico = @i_process_nemonic
if @@rowcount = 0
begin
   select @w_error = 2110175 --Debe enviar un tipo de Flujo
   goto ERROR
end

select @w_secuencial = max(bph_codsequential) 
from   cob_fpm..fp_bankingproductshistory 
where  bph_product_id = @i_toperacion
if isnull(@w_secuencial, 0) = 0
begin   
   select @w_error = 2110176 --Debe enviar el tipo de Operacion
   goto ERROR
end

select @w_process_id = pph_process_id  
from   cob_fpm..fp_processbyproducthistory 
where  bph_codsequentialfk = @w_secuencial 
and    pph_flow_id         = @w_codigo_proceso
if @@rowcount = 0
begin
   select @w_error = 2110177 --No se encontro un proceso para el tipo de flujo y operacion enviada
goto ERROR
end

if @w_process_id = 'ORI'
begin
    select @w_tipo = 'L'
end
else
begin
   select @w_error = 2110177 --No se encontro un proceso para el tipo de flujo y operacion enviada
   goto ERROR
end

--si envian num dias y fecha fin null enviar error
if @i_num_dias = 0 and @i_fecha_fin is NULL
begin
   select @w_error = 2110200 --Fecha fin y numero de dias no pueden ser nulos
   goto ERROR
end

-- si ambas son distintas de NULL
-- comprobar que la fecha fin = fecha inicio + num de dias
if @i_num_dias <>0 and @i_fecha_fin is not NULL
begin
   select @w_fecha_fin = dateadd(dd, @i_num_dias,@i_fecha_ini)
   if @i_fecha_fin <> @w_fecha_fin
   begin
      select @w_error = 2110201 --La fecha fin no coincide con los datos enviados
        goto ERROR
   end
end

--Validar si envian el nro de dias y no la fecha fin entonces se calcula la fecha fin
if @i_num_dias <> 0 and @i_fecha_fin is null
begin
   select @w_fecha_fin = dateadd(dd, @i_num_dias,@i_fecha_ini)
   select @w_num_dias = @i_num_dias
end

--si vino fecha fin y num dias null calculo el numero de dias
if @i_num_dias = 0
begin
   select @w_num_dias = datediff(dd, @i_fecha_ini, @i_fecha_fin) 
end

select @w_num_dias_param = pl_plazo_maximo 
from   cob_credito..cr_parametros_linea
where  pl_toperacion = @i_toperacion
if @@rowcount = 0
begin
   select @w_error = 2110202 --No se encontro parametro de plazo para el tipo de producto
   goto ERROR
end

if @w_num_dias > @w_num_dias_param
begin
   select @w_error = 2110203 --El numero de dias no puede ser mayor al parametrizado
   goto ERROR
end

select @w_monto_maximo = dl_monto_maximo,
       @w_monto_minimo = dl_monto_minimo
from   cob_credito..cr_datos_linea
where  dl_toperacion = @i_toperacion
and    dl_moneda     = @i_moneda
if @@rowcount = 0
begin
   select @w_error = 2110204 --No se ecuentran montos parametrizados para el tipo de operacion
   goto ERROR
end

if @i_monto is not null
begin
   if @i_monto > @w_monto_maximo or @i_monto < @w_monto_minimo
   begin
      select @w_error = 2110205 --El monto no se encuentra en el rango parametrizado
        goto ERROR
   end
end


--Validaciones

exec @w_error            = cob_interface..sp_val_solicitud_linea_int
     @i_toperacion        = @i_toperacion,
     @i_oficina           = @i_oficina,
     @i_ciudad            = @i_ciudad,
     @i_sector            = @i_sector,
     @i_oficial           = @i_oficial,
     @i_moneda            = @i_moneda,
     @i_origen_fondos     = @i_origen_fondos,
     @i_cliente           = @i_cliente,
     @i_fecha_ini         = @i_fecha_ini, --PMO
     @i_rotativo          = @i_rotativo

if @w_error != 0
begin
   goto ERROR
end
if @w_error = 0 and @i_operacion = 'I'
begin
    exec @w_error            = cob_credito..sp_tramite
         @s_srv               = @s_srv,
         @s_user              = @w_usuario_tr, --@s_user, PMO
         @s_term              = @s_term,
         @s_ofi               = @i_oficina, --PQU oficina del trámite @s_ofi,
         @s_rol               = @s_rol,
         @s_ssn               = @s_ssn,
         @s_lsrv              = @s_lsrv,
         @s_date              = @s_date,
         @s_sesn              = @s_sesn,
         @s_org               = @s_org,
         @s_culture           =  @s_culture,
         @t_trn               = 21020,
         @i_operacion         = 'I',
         @i_tipo              = @w_tipo,
         @i_truta             = @i_truta,
         @i_oficina_tr        = @i_oficina,
         @i_usuario_tr        = @w_usuario_tr, --@s_user, PMO
         @i_oficial           = @i_oficial,
         @i_sector            = @i_sector,
         @i_ciudad            = @i_ciudad,
         @i_cliente           = @i_cliente,
         @i_fecha_inicio      = @i_fecha_ini,
         @i_num_dias          = @w_num_dias,
         @i_rotativa          = @i_rotativo,
         @i_toperacion        = @i_toperacion,
         @i_monto     = @i_monto,
         @i_moneda            = @i_moneda,
         @i_cliente_cca       = @i_cliente,
         @i_deudor            = @i_cliente,
         @i_origen_fondo      = @i_origen_fondos,
         @o_tramite           = @w_tramite out
       
    if @w_error != 0
    begin
       goto ERROR
    end

    exec @w_error            = cob_workflow..sp_inicia_proceso_wf
         @s_ssn               = @s_ssn,
         @s_user              = @w_usuario_tr, --@s_user, PMO
         @s_sesn              = @s_sesn,
         @s_term              = @s_term,
         @s_date              = @s_date,
         @s_srv               = @s_srv,
         @s_lsrv              = @s_lsrv,
         @s_rol               = @s_rol,
         @s_ofi               = @i_oficina, --PQU oficina del trámite @s_ofi,
         @s_culture           = @s_culture,
         @i_login             = @w_usuario_tr, --@s_user, PMO
         @i_id_proceso        = @w_codigo_proceso,
         @i_campo_1           = @i_cliente,
         @i_canal             = @i_canal,
         @i_campo_3           = 0,
         @i_id_empresa        = 1,
         @i_campo_4           = @i_toperacion,
         @i_campo_5           = 0,
         @i_campo_6           = 0.0,
         @t_trn               = 73506,
         @o_siguiente         = @w_inst_proceso      out,
         @o_siguiente_alterno = @w_siguiente_alterno out
       
    if @w_error != 0
    begin
       goto ERROR
    end
   
   if @w_inst_proceso > 0
    begin
      exec @w_error       = cob_workflow..sp_m_inst_proceso_wf
           @s_ssn          = @s_ssn,
           @s_user         = @w_usuario_tr, --@s_user, PMO
           @s_sesn         = @s_sesn,
           @s_term         = @s_term,
           @s_date         = @s_date,
           @s_srv          = @s_srv,
           @s_lsrv         = @s_lsrv,
           @s_rol          = @s_rol,
           @s_ofi          = @i_oficina, --PQU oficina del trámite @s_ofi,
           @i_login        = @w_usuario_tr, --@s_user, PMO
           @i_id_inst_proc = @w_inst_proceso,
           @i_campo_1      = @i_cliente,
           @i_campo_3      = @w_tramite,
           @i_id_empresa   = 1,
           @i_campo_4      = @i_toperacion,
           @i_operacion    = 'U',
           @i_campo_5      = 0,
           @i_campo_6      = 0.0,
           @t_trn          = 73506

      if @w_error != 0
      begin
         goto ERROR
      end
    end
   
   if @w_error = 0
    begin
      --Mostrar instancia de proceso corto, instancia de proceso largo, numero de tramite
      select @o_inst_proceso      = @w_inst_proceso,
             @o_siguiente_alterno = @w_siguiente_alterno,
             @o_tramite           = @w_tramite
    end
   
end

if @w_error = 0 and @i_operacion = 'U'
begin

    exec @w_error            = cob_credito..sp_tramite
         @s_srv               = @s_srv,
         @s_user              = @w_usuario_tr, --@s_user, PMO
         @s_term              = @s_term,
         @s_ofi               = @i_oficina, --PQU oficina del trámite @s_ofi,
         @s_rol               = @s_rol,
         @s_ssn               = @s_ssn,
         @s_lsrv              = @s_lsrv,
         @s_date              = @s_date,
         @s_sesn              = @s_sesn,
         @s_org               = @s_org,
         @s_culture           =  @s_culture,
         @t_trn               = 21120,
         @i_operacion         = 'U',
         @i_tramite           = @i_tramite,
         @i_tipo              = @w_tipo,
         @i_oficina_tr        = @i_oficina,
         @i_oficial           = @i_oficial,
         @i_sector            = @i_sector,
         @i_ciudad            = @i_ciudad,
         @i_cliente           = @i_cliente,
         @i_fecha_inicio      = @i_fecha_ini,
         @i_num_dias          = @w_num_dias,
         @i_rotativa          = @i_rotativo,
         @i_linea_credito     = @i_linea_credito,
         @i_monto             = @i_monto,
         @i_moneda            = @i_moneda,
         @i_cliente_cca       = @i_cliente,
         @i_deudor            = @i_cliente,
         @i_origen_fondo      = @i_origen_fondos

    if @w_error != 0
    begin
       goto ERROR
    end    

end

return 0

ERROR:    --Rutina que dispara sp_cerror dado el codigo de error
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return 1
GO

