/**************************************************************************/
/*   Archivo:             ca_carga_oper_finagro.sp                        */
/*   Stored procedure:    sp_val_carga_oper_finagro                       */
/*   Base de datos:       cob_cartera                                     */
/*   Producto:            Cartera                                         */
/*   Disenado por:                                                        */
/*   Fecha de escritura:  DIC2014                                         */
/**************************************************************************/
/*                              IMPORTANTE                                */
/*   Este programa es parte de los paquetes bancarios propiedad de        */
/*   'MACOSA'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como           */
/*   cualquier alteracion o agregado hecho por alguno de sus              */
/*   usuarios sin el debido consentimiento por escrito de la              */
/*   Presidencia Ejecutiva de MACOSA o su representante.                  */
/**************************************************************************/
/*                              PROPOSITO                                 */
/*   Carga Archivo Finagro/llave finagro                                  */
/**************************************************************************/
/*                               MODIFICACIONES                           */
/*  FECHA              AUTOR          CAMBIO                              */
/*  DIC-2014         LIANA COTO     EMISION INICIAL                       */  
/*                                  REQ479 FINAGRO -- LLAVE               */
/**************************************************************************/ 
--ca_carga_oper_finagro.sp

use 
cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_val_carga_oper_finagro')
   drop proc sp_val_carga_oper_finagro 
go

create proc sp_val_carga_oper_finagro (
@i_param1    varchar(250),      --NOMBRE DEL ARCHIVO A CARGAR
@i_param2    datetime
)

as 
declare   
@w_s_app       varchar(100),
@w_path        varchar(100),
@w_error       int,
@w_msg         varchar(100),
@w_comando     varchar(500),
@w_fecha_proc  datetime,
@w_sp_name     varchar(50),
@w_anio	       varchar(4),
@w_mes         varchar(2),
@w_dia         varchar(2),
@w_fecha1      varchar(10),
@w_nom_arch    varchar(250),
@w_correo_fin  char(1),
@w_rollb       char(1),
@w_mensaje     varchar(200)
  
select @w_sp_name = 'sp_val_carga_oper_finagro',
       @w_rollb   = 'N'

if exists (select * from sysobjects where name = 'ca_val_oper_finagro_1')
   drop table ca_val_oper_finagro_1

create table ca_val_oper_finagro_1  (cadena varchar(1000) not null)

/*OBTIENE LA RUTA DEL S_APP*/
select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'S_APP'
   
if @@rowcount = 0 begin
   select 
   @w_error = 2101084, 
   @w_msg = 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
   goto ERROR
end

/*OBTIENE LA RUTA DONDE SE CARGA EL ARCHIVO PLANO*/
select @w_path = pp_path_destino
from  cobis..ba_path_pro
where pp_producto = 7

if @@rowcount = 0 begin
   select  
   @w_error = 2101084,
   @w_msg = 'ERROR EN LA BUSQUEDA DEL PATH EN LA TABLA ba_batch'
end

--OBTENIENDO FECHA DE PROCESO 
select @w_fecha_proc = fp_fecha
from cobis..ba_fecha_proceso
  
if @@rowcount = 0 
begin
   select 
   @w_msg = 'ERROR AL OBTENER FECHA DE PROCESO'
   GOTO ERROR
end  

delete cob_cartera..ca_val_oper_finagro_tmp WHERE vo_ced_ruc >= ''

/*SE CARGA LA INFORMACION DESDE EL ARCHIVO PLANO*/

/*CARGA EN VARIABLE @W_COMANDO*/
select @w_comando = @w_s_app +'s_app'+ ' bcp -auto -login cob_cartera..ca_val_oper_finagro_tmp in ' + 
                    @w_path + @i_param1 + 
                    ' -b100 -c -e '+'Tarjetas.err'  +  ' -F2 -t "|" -config '+ @w_s_app + 's_app.ini'        

/*SE EJECUTA CON CMDSHELL*/
exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select 
   @w_msg = 'ERROR AL LEER ARCHIVO '+@i_param1+ ' '+ convert(varchar, @w_error)
   select @w_mensaje = 'ARCHIVO: ' + @i_param1 + ' NO EXISTE O ESTA INCONSISTENTE'
   --goto ERROR
   goto ERROR_IMP
end

--VALIDACION DE ARCHIVO VACIO
select 1 from cob_cartera..ca_val_oper_finagro_tmp

if @@rowcount  = 0 begin
   select @w_mensaje = 'NO EXISTEN REGISTROS EN EL ARCHIVO' + @i_param1
   GOTO ERROR_IMP
   GOTO CORREO
end

create table #ca_val_oper_finagro_log(
vo_ced_ruc        varchar(13)    null,
vo_tipo_ruc       char(2)        null,
vo_operacion      varchar(25)    null,
vo_oper_finagro   varchar(30)    null,
vo_num_gar        varchar(30)    null,
estado            char(1)        null,
fecha             datetime       null,
comentario        varchar(100)   null)

insert into #ca_val_oper_finagro_log(
vo_ced_ruc,       vo_tipo_ruc,         vo_operacion,        vo_oper_finagro,
vo_num_gar,       estado,              fecha,               comentario)
select 
vo_ced_ruc,       vo_tipo_ruc,         vo_operacion,        vo_oper_finagro,
vo_num_gar,       'I',                 @i_param2,           ''
from ca_val_oper_finagro_tmp
	
if @@error <> 0 
begin
   select 
   @w_error = 708154, 
   @w_msg   = 'ERROR AL INSERTAR LA TABLA TEMPORAL #ca_val_oper_finagro_log'
   GOTO ERROR
end

--VALIDACION DE LA RELACION CEDULA TIPO DOCUMENTO
update #ca_val_oper_finagro_log 
set estado        =  'E',
    fecha         =  @i_param2,
    comentario    =  'TIPO Y NUMERO DE DOCUMENTO NO COINCIDEN'
from cobis..cl_ente
where (vo_ced_ruc = en_ced_ruc
and   vo_tipo_ruc <> en_tipo_ced)
or    (vo_ced_ruc <> en_ced_ruc
and   vo_tipo_ruc = en_tipo_ced)


if @@error <> 0 
begin
   select 
   @w_error = 708152, 
   @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
   GOTO ERROR
end

--VALIDACION DE EXISTENCIA DE LA CEDULA
update #ca_val_oper_finagro_log 
set estado        =  'E',
    fecha         =  @i_param2,
    comentario    =  'NUMERO DE CEDULA NO EXISTE '
where  vo_ced_ruc not in (select en_ced_ruc from cobis..cl_ente)

if @@error <> 0 
begin
   select 
   @w_error = 708152, 
   @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
   GOTO ERROR
end

--VALIDACION DE EXISTENCIA DE LA OPERACION
update #ca_val_oper_finagro_log 
set estado        =  'E',
    fecha         =  @i_param2,
    comentario    =  'NUMERO DE OBLIGACION NO EXISTE '
where vo_operacion not in (select op_banco from cob_cartera..ca_operacion 
                           where op_estado in (select es_codigo from cob_cartera..ca_estado 
                                               where  es_procesa = 'S'))

if @@error <> 0 
begin
   select
   @w_error = 708152, 
   @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
   GOTO ERROR
end

--VALIDACION DE REGISTROS CORRECTOS
update #ca_val_oper_finagro_log 
set estado        =  'P',
    fecha         =  @i_param2,
    comentario    =  'OPERACION PROCESADA CORRECTAMENTE'
from cob_cartera..ca_operacion, cobis..cl_ente
where vo_operacion = op_banco
and   op_cliente = en_ente
and   vo_ced_ruc   = en_ced_ruc
and   vo_tipo_ruc  = en_tipo_ced

if @@error <> 0 
begin
   select
   @w_error = 708152, 
   @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
   GOTO ERROR
end

--VALIDACION EXISTENCIA LLAVE FINAGRO
update #ca_val_oper_finagro_log 
set estado        =  'E',
    fecha         =  @i_param2,
    comentario    =  'NO FUE ENVIADA LA LLAVE FINAGRO'
from cob_cartera..ca_operacion, cobis..cl_ente
where vo_oper_finagro is null
or    vo_oper_finagro = ''

if @@error <> 0 
begin
   select
   @w_error = 708152, 
   @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
   GOTO ERROR
end

--VALIDACION EXISTENCIA COD GARANTIA
update #ca_val_oper_finagro_log 
set estado        =  'E',
    fecha         =  @i_param2,
    comentario    =  'NO FUE ENVIADO NUMERO GARANTIA FAG'
from cob_cartera..ca_operacion, cobis..cl_ente
where vo_num_gar is null
or    vo_num_gar = ''

if @@error <> 0 
begin
   select
   @w_error = 708152, 
   @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
   GOTO ERROR
end

update #ca_val_oper_finagro_log 
set estado        =  'E',
    fecha         =  @i_param2,
    comentario    =  'OBLIGACION NO CORRESPONDE AL DOCUMENTO ENVIADO'
from cob_cartera..ca_operacion, cobis..cl_ente
where vo_operacion = op_banco
and   op_cliente = en_ente
and   vo_ced_ruc   <> en_ced_ruc

if @@error <> 0 
begin
   select
   @w_error = 708152, 
   @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
   GOTO ERROR
end

update #ca_val_oper_finagro_log 
set estado        =  'E',
    fecha         =  @i_param2,
    comentario    =  'NUMERO DE CEDULA NO EXISTE '
where  vo_ced_ruc not in (select en_ced_ruc from cobis..cl_ente)

if @@error <> 0 
begin
   select
   @w_error = 708152, 
   @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
   GOTO ERROR
end

--VALIDACION DE EXISTENCIA DE LA OPERACION
update #ca_val_oper_finagro_log 
set estado        =  'E',
    fecha         =  @i_param2,
    comentario    =  'OPERACION SE ENCUENTRA EN ESTADO CANCELADO'
where vo_operacion in (select op_banco from cob_cartera..ca_operacion 
                           where op_estado = 3 )

if @@error <> 0 
begin
   select
   @w_error = 708152, 
   @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
   GOTO ERROR
end

--OPERACIONES QUE YA TIENEN LLAVES FINAGRO
select A.* 
into #oper_finagro 
from #ca_val_oper_finagro_log A, ca_val_oper_finagro B
where A.vo_operacion = B.vo_operacion

if @@error <> 0 
begin
   select
   @w_error = 708154, 
   @w_msg   = 'ERROR AL INSERTAR LA TABLA TEMPORAL #oper_finagro'
   GOTO ERROR
end

if exists (select 1 from #oper_finagro) begin
   update cob_cartera..ca_val_oper_finagro set
   vo_operacion            = B.vo_operacion,
   vo_oper_finagro         = B.vo_oper_finagro,   --NUMERO DE OPERACION FINAGRO
   vo_num_gar              = B.vo_num_gar,
   vo_fecha                = B.fecha,          --FECHA DE CARGA
   vo_comentario           = B.comentario
   from #ca_val_oper_finagro_log A, #oper_finagro B 
   where ca_val_oper_finagro.vo_operacion = B.vo_operacion
   and   A.vo_operacion = B.vo_operacion 
   and   A.vo_ced_ruc   = B.vo_ced_ruc
   and   A.vo_tipo_ruc  = B.vo_tipo_ruc
   and   A.estado          = 'P'

   if @@error <> 0 
   begin
      select
      @w_error = 708152, 
      @w_msg   = 'ERROR AL ACTUALIZAR LA TABLA #ca_val_oper_finagro_log'
      GOTO ERROR
   end
end

insert into cob_cartera..ca_val_oper_finagro_log
select vo_operacion,
       vo_ced_ruc,
       vo_tipo_ruc,
       vo_oper_finagro,
       vo_num_gar,
       estado,
       GETDATE(),
       comentario 
from #ca_val_oper_finagro_log

if @@error <> 0 
begin
   select
   @w_error = 708154, 
   @w_msg   = 'ERROR AL INSERTAR LA TABLA TEMPORAL #oper_finagro'
   GOTO ERROR
end

insert into cob_cartera..ca_val_oper_finagro
select vo_operacion,
       vo_ced_ruc,
       vo_tipo_ruc,
       vo_oper_finagro,
       vo_num_gar,
       estado,
       fecha,
       comentario  
from #ca_val_oper_finagro_log A
where A.vo_operacion not in (select B.vo_operacion from #oper_finagro B)
and   A.estado          = 'P'

if @@error <> 0 
begin
   select
   @w_error = 708154, 
   @w_msg   = 'ERROR AL INSERTAR LA TABLA TEMPORAL #oper_finagro'
   GOTO ERROR
end 

insert into ca_val_oper_finagro_1 (cadena) values ('FECHA|OPERACION_COBIS|CEDULA|TIPO_CEDULA|OPERACION_FINAGRO|NUMERO_GARATIA_FAG|ESTADO|MENSAJE')

insert into ca_val_oper_finagro_1 (cadena)
select isnull(convert(varchar(20),fecha, 103),      ' ')  + '|' + isnull(convert(varchar(20),vo_operacion), ' ')  + '|' + 
       isnull(convert(varchar(20),vo_ced_ruc),      ' ')  + '|' + isnull(convert(varchar(2),vo_tipo_ruc),  ' ')  + '|' + 
       isnull(convert(varchar(20),vo_oper_finagro), ' ')  + '|' + isnull(convert(varchar(20),vo_num_gar), ' ')  + '|' + 
       isnull(convert(varchar(2),estado),           ' ')  + '|' + isnull(convert(varchar(100),comentario),   ' ')
from #ca_val_oper_finagro_log

------------------------------------------------------------------
--------------------------REALIZANDO BCP--------------------------
------------------------------------------------------------------

--OBTENIENDO FECHA PARA GENERACIÓN DE ARCHIVO PLANO
select @w_anio = convert(varchar(4),datepart(yyyy,@w_fecha_proc)),
       @w_mes  = convert(varchar(2),datepart(mm,@w_fecha_proc)), 
       @w_dia  = convert(varchar(2),datepart(dd,@w_fecha_proc))        

select @w_fecha1  = (right('00' + @w_mes,2)+ '_' + right('00' + @w_dia,2)+ '_' + @w_anio)
select @i_param1 = SUBSTRING(@i_param1,1,(len (@i_param1)-4))

select @w_nom_arch = 'Resultado_' + @i_param1 + /*@w_fecha1 +*/ '.txt'
      
--CREA EL COMANDO PARA EXPORTAR LA TABLA TEMPORAL
select @w_comando = @w_s_app + 's_app'+ ' bcp -auto -login cob_cartera..ca_val_oper_finagro_1 out ' + 
                    @w_path  + @w_nom_arch +
                    ' -c -e'+'ERROR_AL_GENERAR_EL_ARCHIVO.err' + ' -t"|" ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP' + @w_comando
   goto ERROR 
end 

GOTO CORREO

return 0

ERROR_IMP:

insert into ca_val_oper_finagro_1 (cadena)
values (@w_mensaje)

------------------------------------------------------------------
--------------------------REALIZANDO BCP--------------------------
------------------------------------------------------------------

--OBTENIENDO FECHA PARA GENERACIÓN DE ARCHIVO PLANO DE ERROR
select @w_anio = convert(varchar(4),datepart(yyyy,@w_fecha_proc)),
       @w_mes  = convert(varchar(2),datepart(mm,@w_fecha_proc)), 
       @w_dia  = convert(varchar(2),datepart(dd,@w_fecha_proc))        

select @w_fecha1  = (right('00' + @w_mes,2)+ '_' + right('00' + @w_dia,2)+ '_' + @w_anio)
select @i_param1 = SUBSTRING(@i_param1,1,(len (@i_param1)-4))

select @w_nom_arch = 'Resultado_' + @i_param1 /*+ @w_fecha1 +*/+ '.txt'
      
--CREA EL COMANDO PARA EXPORTAR LA TABLA TEMPORAL
select @w_comando = @w_s_app + 's_app'+ ' bcp -auto -login cob_cartera..ca_val_oper_finagro_1 out ' + 
                    @w_path  + @w_nom_arch +
                    ' -c -e'+'ERROR_AL_GENERAR_EL_ARCHIVO.err' + ' -t"|" ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP' + @w_comando
   goto ERROR 
end

return 0

CORREO:

select @w_correo_fin = pa_char  
from cobis..cl_parametro   with (nolock) 
where pa_nemonico = 'NOTFIN'  
and   pa_producto = 'MIS'

if @@ROWCOUNT = 0
begin
  select @w_msg = 'ERROR, PARAMETRO GENERAL ENVIO NOTIFICACIONES FINAGRO NO EXISTE',
         @w_error = 708153
  goto ERROR
end

if @w_correo_fin = 'S' begin

   select @w_path = @w_path + @i_param1

   exec cob_cartera..sp_correo_llave_fin
   @i_fecha_proceso = @i_param2,
   @i_ruta          = @w_path 
end



ERROR:
   print cast(@w_msg as varchar(225))

   exec sp_errorlog 
   @i_fecha       = @w_fecha_proc,
   @i_error       = @w_error, 
   @i_tran        = null,
   @i_usuario     = 'op_batch', 
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = '',
   @i_rollback    = 'N',
   @i_descripcion = @w_msg   
   return @w_error

go