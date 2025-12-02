/************************************************************************/
/*    Archivo:                ca_notif_clfin_xmora.sp                   */
/*    Stored Procedure:       sp_notif_centre_lineasf_xmora             */
/*    Base de datos:          cob_cartera                               */
/*    Disenado por:           Elcira Pelaez Burbano                     */
/*    Fecha de escritura:     AGO.2015                                  */
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
/*   Finagro por otra linea finagro de Sustitutiva a linea Agropecuaria */
/*   con las operaciones cuyo cambio de línea fue exitoso               */
/************************************************************************/
/*                           MODIFICACION                               */
/*    FECHA                    AUTOR               RAZON                */
/************************************************************************/

use cob_cartera
go

SET ANSI_NULLS OFF
GO

if exists (select 1 from sysobjects where name = 'sp_notif_centre_lineasf_xmora')
   drop proc sp_notif_centre_lineasf_xmora
go
---AGO.04.2015
create proc sp_notif_centre_lineasf_xmora (
@i_param1 datetime --Fecha del Proceso
)
as
declare
@w_sp_name              varchar(32),  
@w_msg                  varchar(255),
@w_error                int,
@w_fecha_proceso        datetime,
@w_ente                 int,
@w_email                varchar(84),
@w_user                 varchar(60),
@w_dom                  varchar(60),
@w_cuerpo_correo        NVARCHAR(MAX),
@w_correos              NVARCHAR(MAX),
@w_genera_notif         char(1),
@w_tipo_ide             catalogo,
@w_identificacion       varchar(30),
@w_banco                varchar(20),
@w_linea_destino        catalogo,
@w_nombre               varchar(254),
@w_oficina              int,
@w_nombre_ofi           descripcion,
@w_subject              varchar(100),
@w_usuario              login,
@w_usuario1             login,
@w_usuario2             login

set nocount on

select
@w_fecha_proceso = @i_param1,
@w_error         = 0
---USUARIO EXCLUSIVO PARA CAMBIO LINEA FINAGRO
select @w_usuario1 = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'USLIFI'
and   pa_producto = 'CCA'

select @w_usuario2 = @w_usuario1 + '_USR'
select @w_usuario  = @w_usuario1

select 
@w_sp_name = 'sp_notif_centre_lineasf_xmora',
@w_subject = 'OPERACIONES CON CAMBIO ENTRE LINEAS FINAGRO x MORA ' + convert(varchar(10), @w_fecha_proceso,103)

create table #correos(
nomente int,
nemail  varchar(84)
)

---------------------------------------------------
-- Generación automática de correos de notificacion
---------------------------------------------------
  
--BANDERA ENVIO NOTIFICACIONES FINAGRO S/N
select @w_genera_notif = pa_char  
from   cobis..cl_parametro   with (nolock) 
where  pa_nemonico     = 'NOTFIN'  
and    pa_producto     = 'MIS'

if @@ROWCOUNT = 0
begin
  select 
  @w_msg   = 'ERROR, PARAMETRO GENERAL ENVIO NOTIFICACIONES FINAGRO NO EXISTE',
  @w_error = 708153
  select @w_usuario  = @w_usuario2  
  goto ERRORFIN
end

-- SI NO GENERA NOTIFICACIONES FINALIZA REGISTRANDO UN MENSAJE PARA INFORMACION
if @w_genera_notif = 'N'
begin 
  select @w_msg = 'ca_notif_clfin_xmora.sp --> PARAMETRO USLIFI esta PARAMETRIZADO EN N  '
  goto ERRORFIN
end

----SI NO HAY DATOS CARGADOS SIMPLEMENTE GENERE UN ERROR
if not exists ( select 1 from cob_cartera..ca_oper_cambio_linea_x_mora where cl_estado     = 'I')
begin
  select @w_msg = 'ca_notif_clfin_xmora.sp --> NO HA DATOS PROCESADOS EN LA TABLA cob_cartera..ca_oper_cambio_linea_x_mora'
  goto ERRORFIN
end



/* ONTIENE LAS DIRECCIONES DE CORREO DESTINO */
insert into #correos
select en_ente, di_descripcion 
from   cobis..cl_ente with (nolock),
       cobis..cl_direccion with (nolock),
       cobis..cl_tabla a with (nolock),
       cobis..cl_catalogo b with (nolock) 
where  en_ente  = case when isnumeric(b.valor) = 1 then b.valor else 0 end 
and    a.tabla  = 'ca_correos_finagro'
and    b.tabla  = a.codigo
and    en_ente  = di_ente
and    b.estado = 'V'
and    di_tipo  = '001'
	
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
      select @w_usuario  = @w_usuario2      
      goto ERRORFIN
   end

   if CHARINDEX('à',@w_email,1)>0 or CHARINDEX('è',@w_email,1)>0 or CHARINDEX('ì',@w_email,1)>0 or CHARINDEX('=',@w_email,1)>0 or CHARINDEX('ù',@w_email,1)>0 
   begin
      select
      @w_msg   = 'ERROR EN LA VALIDACION DEL CORREO ELECTRONICO PARA ENVIO, ' + @w_email,
      @w_error = 100211
      select @w_usuario  = @w_usuario2      
      goto ERRORFIN
   end
   
   if CHARINDEX('@',@w_email,1)>0 and CHARINDEX('.', @w_email, CHARINDEX( '@', @w_email))>0 --VALIDA QUE EXISTA ARROBA Y PUNTO DESPUES DEL ARROBA 
   begin
      if CHARINDEX('@' , @w_email, CHARINDEX('@',@w_email,1)+1)>0 
      begin
      select
         @w_msg   = 'ERROR EN LA VALIDACION DEL CORREO ELECTRONICO PARA ENVIO, ' + @w_email,
         @w_error = 100211
         select @w_usuario  = @w_usuario2         
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
            select @w_user  = REPLACE(@w_user, ' ', '_') 
            select @w_email = @w_user + '@' + @w_dom --RETORNA EMAIL CON ESPACIOS CONVERTIDOS
         end
         else
            select @w_email = @w_user + '@' + @w_dom --RETORNA EMAIL 
         end
         else
         begin
            select 
            @w_msg   = 'ERROR EN LA VALIDACION DEL CORREO ELECTRONICO PARA ENVIO, '+ @w_email,
            @w_error = 100211
            select @w_usuario  = @w_usuario2            
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
         select @w_usuario  = @w_usuario2         
         goto ERRORFIN
      end  
   end
   select @w_correos = @w_correos + @w_email + ' '
end --end while

--ENVIA CORREO    
if @w_correos <> ''
begin
   select @w_correos = LTRIM(RTRIM(@w_correos))
   select @w_correos = REPLACE(@w_correos,' ', ';') 

   --OBTIENE OPERACIONES PROCESADAS A LAS QUE SE REALIZO CAMBIO DE LINEA
   select 
   en_tipo_ced,
   en_ced_ruc,
   cl_banco,
   cl_linea_destino,
   en_nomlar,
   en_oficina_prod,
   cl_estado
   into  #procesadas_x_centrelineas
   from  cob_cartera..ca_oper_cambio_linea_x_mora with (nolock), 
         cobis..cl_ente with (nolock)
   where cl_fecha = @w_fecha_proceso
   and   en_ente   = cl_ccliente
   and   cl_estado     = 'I'
   order by cl_banco

   select @w_banco = ''
   select @w_cuerpo_correo = 'NOTIFICACIÓN: EL PROCESO HA FINALIZADO DE MANERA EXITOSA, LOS SIGUIENTES CRÉDITOS CARTERA SUSTITUTIVA FINAGRO,  FUERON MODIFICADOS A CARTERA AGROPECUARIA FINAGRO: ' + char(10) 

   
   --GENERAR EL CUERPO DEL MENSAJE
   while 1=1
   begin
      select top 1 
      @w_tipo_ide       = en_tipo_ced,
      @w_identificacion = en_ced_ruc,
      @w_banco          = cl_banco,
      @w_linea_destino  = cl_linea_destino,
      @w_nombre         = en_nomlar,
      @w_oficina        = en_oficina_prod
      from  #procesadas_x_centrelineas
      where cl_banco  > @w_banco

      if @@rowcount = 0
         break

              if exists (select 1 
                           from   cobis..ad_usuario_rol with (nolock),
                                  cobis..cl_funcionario with (nolock),
                                  cobis..cl_ente with (nolock)
                           where  ur_rol     = 47
                           and    ur_estado  = 'V'
                           and    ur_login   = fu_login
                           and    fu_oficina = @w_oficina
                           and    fu_estado  = 'V'
                           and    en_ced_ruc = cast(fu_nomina as varchar)
               )
            begin             
               select @w_cuerpo_correo = @w_cuerpo_correo + char(10) + CHAR(10) + 'OPERACION: ' + isnull(@w_banco,'Sin Banco') + '  CEDULA: ' + isnull(@w_identificacion,'Sin Identificacion') + '  NOMBRE: ' + isnull(@w_nombre,'Sin Nombre') + '  LINEA DE CREDITO: ' + isnull(@w_linea_destino,'Sin Linea') + '  OFICINA: ' + isnull(cast(@w_oficina as varchar),'Sin Oficina') 
               update cob_cartera..ca_oper_cambio_linea_x_mora
               set cl_estado = 'P'
               where cl_fecha = @w_fecha_proceso
               and   cl_banco = @w_banco              
            end
            ELSE
            begin
            update #procesadas_x_centrelineas
            set cl_estado = 'E'
            where cl_banco = @w_banco 
            end
   end  ---envio notificacion
   
   if exists (select 1 from #procesadas_x_centrelineas where cl_estado <> 'E')
   begin
      exec @w_error = cobis..sp_send_notification
      @i_to         = @w_correos,
      @i_subject    = @w_subject,
      @i_body       = @w_cuerpo_correo,
      @o_msg        = @w_msg out

      if @w_error <> 0
         goto ERRORFIN
      else
         print cast(@w_msg as varchar(255))

      --OBTIENE OFICINAS PROCESADAS PARA ENVIO DE CORREO A DIRECTORES DE CADA OFICINA
      select distinct en_oficina_prod
      into #oficinas
      from #procesadas_x_centrelineas

      select @w_oficina = 0


      --PROCESA UNA A UNA LAS OFICINAS
      while  1=1
      begin
         select top 1 
         @w_oficina = en_oficina_prod
         from  #oficinas
         where en_oficina_prod > @w_oficina

         if @@rowcount = 0
            break
         
         select 
         @w_banco         = '',
         @w_cuerpo_correo = 'NOTIFICACION: EL PROCESO HA FINALIZADO DE MANERA EXITOSA, LOS SIGUIENTES CREDITOS FINAGRO FUERON CAMBIADOS A LA NUEVA LINEA:' + CHAR(10)

         
         /*GENERAR EL CUERPO DEL MENSAJE*/
         while 1=1
         begin
            select top 1
            @w_tipo_ide       = en_tipo_ced,
            @w_identificacion = en_ced_ruc,
            @w_banco          = cl_banco,
            @w_linea_destino  = cl_linea_destino,
            @w_nombre         = en_nomlar
            from  #procesadas_x_centrelineas
            where cl_banco  > @w_banco
            and   en_oficina_prod = @w_oficina
            order by en_oficina_prod

            if @@rowcount = 0
               break
               
            if exists (select 1 
                       from   cobis..ad_usuario_rol with (nolock),
                              cobis..cl_funcionario with (nolock),
                              cobis..cl_ente with (nolock)
                       where  ur_rol     = 47
                       and    ur_estado  = 'V'
                       and    ur_login   = fu_login
                       and    fu_oficina = @w_oficina
                       and    fu_estado  = 'V'
                       and    en_ced_ruc = cast(fu_nomina as varchar)
               )
            begin                
              select @w_cuerpo_correo = @w_cuerpo_correo + char(10) + char(10) + 'OPERACION: ' + isnull(@w_banco,'Sin Banco') + '  CEDULA: ' + isnull(@w_identificacion,'Sin Identificacion') + '  NOMBRE: ' + isnull(@w_nombre,'Sin Nombre') + '  LINEA DE CREDITO: ' + isnull(@w_linea_destino,'Sin Linea')
            end
         end  ---por cuerpo del correo

         -- OBTIENE NOMBRE DE LA OFICINA
         select @w_nombre_ofi = of_nombre 
         from cobis..cl_oficina 
         where of_oficina = @w_oficina

         -- OBTIENE CEDULA DEL DIRECTOR DE LA OFICINA ASOCIADA AL CLIENTE
         select @w_ente = en_ente
         from   cobis..ad_usuario_rol with (nolock),
                cobis..cl_funcionario with (nolock),
                cobis..cl_ente with (nolock)
         where  ur_rol     = 47
         and    ur_estado  = 'V'
         and    ur_login   = fu_login
         and    fu_oficina = @w_oficina
         and    fu_estado  = 'V'
         and    en_ced_ruc = cast(fu_nomina as varchar)

         if @@rowcount = 0
         begin
           select
           @w_msg = 'NO SE ENCONTRO DIRECTOR PARA LA OFICINA ' + @w_nombre_ofi 
                         + ' CODIGO ' + convert(varchar,@w_oficina) + ' NUMERO DE OPERACION: ' + convert(varchar,@w_banco), 
           @w_error = 2101023
           select @w_usuario  = @w_usuario2           
           goto ERROR_SIG
         end

         --OBTIENE CORREO ELECTRONICO DEL DIRECTOR DE LA OFICINA
         select top 1
         @w_correos    = di_descripcion
         from  cobis..cl_direccion with (nolock)
         where di_ente = @w_ente
         and   di_tipo = '001'

         if @@rowcount = 0
         begin
           select
           @w_msg = 'NO SE PUDO ENTREGAR EL CORREO A LA OFICINA ' + @w_nombre_ofi 
                  + ' CODIGO ' + convert(varchar,@w_oficina) + ' NUMERO DE OPERACION: ' + convert(varchar,@w_banco) 
                  + ' DIRECTOR ' + CONVERT(varchar,@w_ente),           
           @w_error = 151203
           select @w_usuario  = @w_usuario2           
           goto ERROR_SIG
         end

         if @w_correos <> ''
         begin
            exec @w_error = cobis..sp_send_notification
            @i_to         = @w_correos,
            @i_subject    = @w_subject,
            @i_body       = @w_cuerpo_correo,
            @o_msg        = @w_msg out

            if @w_error <> 0
            begin
               update cob_cartera..ca_oper_cambio_linea_x_mora
               set cl_estado = 'P'
               where cl_fecha = @w_fecha_proceso
               
               if @@error <> 0 
               begin
                  select @w_msg =  'ERROR PONIENDO EL ESTADO EN P en la  TABLA ca_oper_cambio_linea_x_mora '
                  goto ERRORFIN
               end
               goto ERRORFIN
            end   
            else
               print cast(@w_msg as varchar(255))
         end
         goto SIGUIENTE
   
         ERROR_SIG:
            exec sp_errorlog 
            @i_fecha       = @w_fecha_proceso,
            @i_error       = @w_error,
            @i_usuario     = @w_usuario,
            @i_tran        = 7999,
            @i_tran_name   = @w_sp_name,
            @i_cuenta      = @w_banco,
            @i_descripcion = @w_msg,
            @i_anexo       = @w_msg,
            @i_rollback    = 'N'
      
         select @w_error = 0
         select @w_usuario = @w_usuario1
   
         SIGUIENTE:         
      end
   end
end

set nocount off

return 0

ERRORFIN:

   PRINT  cast(@w_msg as varchar(255))
   exec sp_errorlog 
   @i_fecha       = @w_fecha_proceso,
   @i_error       = @w_error,
   @i_usuario     = @w_usuario,
   @i_tran        = 7999,
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = ' ',
   @i_descripcion = @w_msg,
   @i_anexo       = @w_msg,
   @i_rollback    = 'N'

   return 0

go
 