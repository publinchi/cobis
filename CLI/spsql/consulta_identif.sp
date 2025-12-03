/************************************************************************/
/*   Archivo:            consulta_identif.sp                            */
/*   Stored procedure:   sp_consulta_identif                            */
/*   Base de datos:      cobis                                          */
/*   Producto:           Clientes                                       */
/*   Disenado por:       ACU                                            */
/*   Fecha de escritura: 15-Septiembre-21                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_crear_persona                           */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      15/09/21        ACU       Emision Inicial                       */
/************************************************************************/

use cobis
go

IF OBJECT_ID ('dbo.sp_consulta_identif') IS NOT NULL
    DROP procedure dbo.sp_consulta_identif
go

create proc sp_consulta_identif
(
  @s_culture          varchar(10) = 'NEUTRAL',
  @s_ssn              int         = null,
  @s_user             login       = null,
  @s_term             varchar(30) = null,
  @s_date             datetime    = null,
  @s_srv              varchar(30) = null,
  @s_lsrv             varchar(30) = null,
  @s_ofi              smallint    = null,
  @s_rol              smallint    = null,
  @s_org_err          char(1)     = null,
  @s_error            int         = null,
  @s_sev              tinyint     = null,
  @s_msg              descripcion = null,
  @s_org              char(1)     = null,
  @t_debug            char(1)     = 'N',
  @t_file             varchar(10) = null,
  @t_from             varchar(32) = null,
  @t_trn              int,
  @t_show_version     bit         = 0,    -- MOSTRAR LA VERSION DEL PROGRAMA
  @i_operacion        char(1)     = 'Q',
  @i_numero_ident     varchar(20) = null,
  @i_tipo_ident       catalogo    = null,
  @i_modo             tinyint     = 0,    -- Modo 0: Devuelve resulset  Modo 1 : Devuelve solo el codigo del Cliente
  @o_cliente          int         = null out,
  @o_subtipo          char(2)     = null out,
  @o_nomlar           varchar(254)= null out
  
)
as
declare
  @w_today                 datetime,
  @w_sp_name               varchar(32),
  @w_error                 int,
  @w_en_ente               int,
  @w_en_subtipo            char(2),
  @w_sp_msg                varchar(132),
  @w_en_nomlar             varchar(254)

select @w_sp_name = 'sp_consulta_identif',
       @w_sp_msg  = ''
       
if @t_show_version = 1 
begin
   select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
   select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
   print  @w_sp_msg
   return 0
end

exec cobis..sp_ad_establece_cultura
     @o_culture = @s_culture out

-------------------------------------------------------------------------------------------------------------
--Dado el numero y tipo de identificacion o el codigo del cliente  se encuentra el codigo , subtipo y nombre
-------------------------------------------------------------------------------------------------------------
if @i_operacion = 'Q'

begin
   if @t_trn = 172112  --CONSULTA DE DATOS COMPLEMENTARIOS
   begin

      if (@i_numero_ident is null or @i_tipo_ident is null)
      begin
        select @w_error = 1720325 --EL CLIENTE NO EXISTE PARA EL PARAMETRO CEDULA Y TIPO DE DOCUMENTO 
        goto ERROR
      end
      
      select  @w_en_ente     = en_ente,
              @w_en_subtipo  = en_subtipo,
              @w_en_nomlar   = en_nomlar
      from    cobis..cl_ente
      where   en_ced_ruc        = @i_numero_ident
      and     trim(en_tipo_ced) = @i_tipo_ident
      
      if @@rowcount = 0 
      begin
         select @w_error = 1720035 --ERROR: NO EXISTE EL CLIENTE
         goto ERROR
      end
      
      if @i_modo = 0 --Retorna Datos del Cliente
      begin 
         select 
         en_subtipo,
         en_ente,
         en_nomlar --Este campo para persona juridica se esta realizando una historia para ver en que campo  mismo se guardara el nombre, asi que puede variar.
         from cl_ente
         where en_ente   = @w_en_ente
         and en_subtipo  = @w_en_subtipo
         
         if @@rowcount = 0
         begin
            select @w_error = 1720035--ERROR: NO EXISTE EL CLIENTE
            goto ERROR
         end
      end
      
      if @i_modo = 1 --Retorna solo codigo del cliente
      begin
         select @o_cliente  = @w_en_ente,
                @o_subtipo  = @w_en_subtipo,
                @o_nomlar   = @w_en_nomlar              
      end     
   end
   else
   begin
      select @w_error   =  1720075--No corresponde codigo de transaccion.                                                                                              
      goto ERROR
   end 
end

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug    = @t_debug,
        @t_file     = @t_file,
        @t_from     = @w_sp_name,
        @s_culture  = @s_culture,
        @i_num      = @w_error
   
   return @w_error

go

