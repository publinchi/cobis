/************************************************************************/
/*    Archivo:                ca_correo_llave_fin.sp                    */
/*    Stored Procedure:       sp_correo_llave_fin                       */
/*    Base de datos:          cob_cartera                               */
/*    Disenado por:           Edwin Rodriguez.                          */
/*    Fecha de escritura:     20/01/2015                                */
/*    Producto:               Cartera                                   */
/************************************************************************/
/*                            IMPORTANTE                                */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    'COBISCORP S.A'.                                                  */
/*    Su uso no autorizado queda expresamente prohibido asi como        */
/*    cualquier alteracion o agregado hecho por alguno de sus           */
/*    usuarios sin el debido consentimiento por escrito de la           */
/*    Presidencia Ejecutiva de COBISCORP S.A o su representante.        */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Generar notificacion por email del proceso de cambio de linea de   */
/*   Finagro con las operaciones cuyo cambio de línea fue exitoso       */
/************************************************************************/
/*                           MODIFICACION                               */
/*    FECHA                   AUTOR                     RAZON           */
/*  20/01/2015           Edwin Rodriguez        CCA 479 Finagro Fase2   */
/*  20-Mar-2015          Andres Muñoz           CAMBIO ESQUEMA CORREO   */
/************************************************************************/

use cob_cartera
go

SET ANSI_NULLS OFF
GO

if exists (select 1 from sysobjects where name = 'sp_correo_llave_fin')
   drop proc sp_correo_llave_fin
go

create proc sp_correo_llave_fin (
@i_fecha_proceso        varchar(255), --FECHA DEL PROCESO
@i_ruta                 varchar(255)  --RUTA ARCHIVO
)
as
declare
@w_sp_name              varchar(32),
@w_msg                  varchar(124),
@w_error                int,
@w_fecha_proceso        datetime,
@w_ente                 int,
@w_email                varchar(84),
@w_user                 varchar(60),
@w_dom                  varchar(60),
@w_cuerpo_correo        NVARCHAR(MAX),
@w_correos              NVARCHAR(MAX),
@w_genera_notif         char(1),
@w_fecha                datetime,
@w_tipo_ide             catalogo,
@w_identificacion       varchar(30),
@w_banco                varchar(20),
@w_linea_destino        catalogo,
@w_nombre               varchar(254),
@w_oficina              int,
@w_subject              varchar(100),
@w_correo_fin           char(1),
@w_correctos            int,
@w_errores              int,
@wtotales               int

set nocount on
   
select
@w_fecha_proceso = @i_fecha_proceso,
@w_error         = 0

select
@w_sp_name = 'sp_correo_llave_fin',
@w_subject = 'NOTIFICACION LLAVE FINAGRO ' + convert(varchar(10), @w_fecha_proceso,103)

create table #correos(
nomente int,
nemail varchar(84)
)

--VALIDA FECHA DE PROCESO
select @w_fecha = GETDATE() -- Para tener una fecha default

if @w_fecha_proceso is null
   select @w_fecha_proceso = @w_fecha
 
---------------------------------------------------
-- Generación automática de correos de notificacion
---------------------------------------------------
  
--OBTIENE ENVIO NOTIFICACIONES FINAGRO
select @w_correo_fin = pa_char  
from   cobis..cl_parametro   with (nolock)
where  pa_nemonico = 'GCLLFI'  
and    pa_producto = 'CCA'

if @@ROWCOUNT = 0
begin
  select
  @w_msg   = 'ERROR, PARAMETRO GENERAL ENVIO NOTIFICACIONES FINAGRO NO EXISTE',
  @w_error = 708153
  goto ERRORFIN
end

/* ONTIENE LAS DIRECCIONES DE CORREO DESTINO */
insert into #correos
select en_ente, di_descripcion
from   cobis..cl_ente with (nolock),
       cobis..cl_direccion with (nolock),
       cobis..cl_tabla a with (nolock),
       cobis..cl_catalogo b with (nolock) 
where  en_ente = case when isnumeric(b.valor) = 1 then b.valor else 0 end 
and    a.tabla = 'ca_correo_llave_fin'
and    b.tabla = a.codigo
and    en_ente = di_ente
and    b.estado = 'V'
and    di_tipo = '001'

select
@w_correos = '',
@w_ente    = 0,
@w_email   = '',
@w_user    = '',
@w_dom     = ''
    
/* VALIDA QUE LA DIRECCIONES DE CORREO SEAN CORRECTAS*/
while 1=1
   begin
   set rowcount 1
   select 
   @w_ente  = nomente,
   @w_email = nemail 
   from  #correos
   where nomente > @w_ente
   order by nomente asc
 
   if @@rowcount = 0
   begin
      set rowcount 0
      break
   end
   set rowcount 0

   select @w_email = LTRIM(RTRIM(@w_email))
   select @w_email = REPLACE(@w_email,',', '.') 
   select @w_email = REPLACE(@w_email,'@ ', '@')
   select @w_email = REPLACE(@w_email,' @',  '@')
   select @w_email = REPLACE(@w_email,'. ', '.') 
   select @w_email = REPLACE(@w_email,' .', '.')
   select @w_email = REPLACE(@w_email,'ñ', 'n')

   --VALIDA ACENTOS, SI ENCUENTRA ACENTO INVALIDA EL EMAIL
   if CHARINDEX('á',@w_email,1)>0 or CHARINDEX('é',@w_email,1)>0 or CHARINDEX('í',@w_email,1)>0 or CHARINDEX('ó',@w_email,1)>0 or CHARINDEX('ú',@w_email,1)>0
   begin
      select
      @w_msg   = 'ERROR EN LA VALIDACION DEL CORREO ELECTRONICO PARA ENVIO, ' + @w_email,
      @w_error = 100211
      goto ERRORFIN
   end

   if CHARINDEX('à',@w_email,1)>0 or CHARINDEX('è',@w_email,1)>0 or CHARINDEX('ì',@w_email,1)>0 or CHARINDEX('=',@w_email,1)>0 or CHARINDEX('ù',@w_email,1)>0
   begin
      select
      @w_msg   = 'ERROR EN LA VALIDACION DEL CORREO ELECTRONICO PARA ENVIO, ' + @w_email,
      @w_error = 100211
      goto ERRORFIN
   end

   if CHARINDEX('@',@w_email,1)>0 and CHARINDEX('.', @w_email, CHARINDEX( '@', @w_email))>0 --VALIDA QUE EXISTA ARROBA Y PUNTO DESPUES DEL ARROBA 
   begin
      if CHARINDEX('@' , @w_email, CHARINDEX('@',@w_email,1)+1)>0 
      begin
         select
         @w_msg   = 'ERROR EN LA VALIDACION DEL CORREO ELECTRONICO PARA ENVIO, ' + @w_email,
         @w_error = 100211
         goto ERRORFIN
      end --ENCUENTRA 2 ARROBAS Y RETORNA NULO    

      select @w_user = SUBSTRING(@w_email,1,CHARINDEX( '@',@w_email)-1)
      select @w_dom  = SUBSTRING(@w_email,CHARINDEX( '@',@w_email)+1, 100)
      select @w_user = LTRIM(RTRIM(@w_user)) 
      select @w_dom  = LTRIM(RTRIM(@w_dom))

      --VALIDA QUE EL DOMINIO TENGA 2 O TRES CARACTERES
      if LEFT(RIGHT(@w_dom, 3), 1)='.' or LEFT(RIGHT(@w_dom, 4), 1)='.' 
      begin
         --REEMPLAZA ESPACIOS POR '_' SOLO EN USUARIO, NO EN DOMINIO 
         if CHARINDEX(' ', @w_user)>0 
         begin
            select @w_user= REPLACE(@w_user, ' ', '_') 
            select @w_email =  @w_user +  '@' + @w_dom --RETORNA EMAIL CON ESPACIOS CONVERTIDOS
         end
         else
            select @w_email = @w_user + '@'  + @w_dom --RETORNA EMAIL 
			end
         else
         begin
            select
            @w_msg   = 'ERROR EN LA VALIDACION DEL CORREO ELECTRONICO PARA ENVIO, '+ @w_email,
            @w_error = 100211
            goto ERRORFIN

         end -- RETORNA NULO, EL DOMINIO TENIA MAS DE 3 LETRAS O MENOS DE 2
      end
   else
   begin
      if @w_email <> ''
      begin
         select
         @w_msg   = 'ERROR EN LA VALIDACION DEL CORREO ELECTRONICO PARA ENVIO, '+ @w_email,
         @w_error = 100211
         goto ERRORFIN
      end  
   end
   select @w_correos = @w_correos + @w_email + ' '
end --end while  

--ENVIA CORREO    
if @w_correos <> ''
begin
   select @w_correos=LTRIM(RTRIM(@w_correos))
   select @w_correos=REPLACE(@w_correos,' ', ';') 

   select @w_banco = ''
   select @w_cuerpo_correo = 'NOTIFICACION: EL PROCESO HA FINALIZADO DE MANERA EXITOSA, SE PROCESA LOS SIGUIENTES REGISTROS: ' + CHAR(10)

   select @wtotales = COUNT(1)
   from   #ca_val_oper_finagro_log

   select @w_correctos = COUNT(1)
   from   #ca_val_oper_finagro_log
   where  estado = 'P'

   select @w_errores = COUNT(1)
   from   #ca_val_oper_finagro_log
   where  estado = 'E'

   select @w_cuerpo_correo = @w_cuerpo_correo + CHAR(10) + 'REGISTRO TOTALES:  ' + isnull(convert(varchar(10),@wtotales),'0') + CHAR(10) +
                             'REGISTROS PROCESADOS CORRECTAMENTE:  ' + isnull(convert(varchar(10),@w_correctos),'0') + CHAR(10) +
                             'REGISTROS PROCESADOS CON ERRORES:  ' + isnull(cast(@w_errores as varchar),'0') + CHAR(10) + CHAR(10) + 
                             'POR FAVOR VERIFICAR EN SU DIRECTORIO COMPARTIDO, EL ARCHIVO RESULTADO: "Resultado_opera_finagro_DD_MM_AAAA.txt"'

   exec @w_error = cobis..sp_send_notification
   @i_to         = @w_correos,
   @i_subject    = @w_subject,
   @i_body       = @w_cuerpo_correo,
   @o_msg        = @w_msg out 

   if @w_error <> 0 
      goto ERRORFIN
   else
      print cast(@w_msg as varchar(255))
end

set nocount off

return 0

ERRORFIN:
   PRINT  cast (@w_msg as varchar(255))
   exec sp_errorlog 
   @i_fecha     = @w_fecha,
   @i_error     = @w_error,
   @i_usuario   = 'batch',
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = ' ',
   @i_descripcion = @w_msg,
   @i_rollback  = 'N'

   return @w_error
go
 
