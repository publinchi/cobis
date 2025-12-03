/************************************************************************/
/*  Archivo:            ca_matriz.sp                                    */
/*  Stored procedure:   sp_matriz                                       */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           cartera                                         */
/*  Disenado por:  	    RRB                                             */
/*  Fecha de escritura: Feb/2009                                        */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA', representantes exclusivos para el Ecuador de              */
/*  AT&T GIS                                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Mantenimiento Matrices Dimencionales (MATRIZ)                       */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       		 	RAZON                           */
/*                                                                      */
/************************************************************************/
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_matriz')
drop proc sp_matriz
go
create proc sp_matriz
(
@s_ssn         int = null,
@s_user        login = null,
@s_sesn        int = null,
@s_term        varchar(30) = null,
@s_date        datetime = null,
@s_srv         varchar(30) = null,
@s_lsrv        varchar(30) = null,
@s_rol         smallint = NULL,
@s_ofi         smallint = NULL,
@s_org_err     char(1) = NULL,
@s_error       int = NULL,
@s_sev         tinyint = NULL,
@s_msg         descripcion = NULL,
@s_org         char(1) = NULL,
@t_debug       char(1) = 'N',
@t_file        varchar(10) = null,
@t_from        varchar(32) = null,
@i_matriz      varchar(30) = null,
@i_fecha_vig   smalldatetime = null,
@i_descripcion varchar(60) = null,
@i_vlr_default varchar(20) = null,
@i_ejes        int = null ,
@i_operacion   char(1)
)
as
declare 
@w_sp_name	varchar(30),
@w_id_tabla	int

select @w_sp_name = 'sp_matriz'

/* Insertar/Modificar */

if @i_operacion = 'I' begin 
   if exists(select 1 from ca_matriz
             where ma_matriz    = @i_matriz
             and   ma_fecha_vig = @i_fecha_vig)
      begin
      update ca_tabla
      set ma_descripcion = @i_descripcion,
          ma_ejes        = @i_ejes
      where ma_matriz    = @i_matriz         
      and   ma_fecha_vig = @i_fecha_vig
      
      if @@error <> 0 begin
         exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 2107013 ---- Error al actualizar
      end
   end
   else begin
      insert into ca_matriz
      values(@i_matriz, @i_descripcion, @i_fecha_vig, @i_ejes, @i_vlr_default)
      
      if @@error <> 0 begin
         exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 2107013 ---- Error al insertar
      end
   end
end

/* Borra Matriz */

if @i_operacion = 'D' begin
   exec sp_eje
   @t_trn=22224,
   @i_operacion= 'D',
   @i_codigo_tabla = @i_matriz,
   @i_fecha_vig    = @i_fecha_vig
   
   exec  sp_eje_rango
   @t_trn=22225,
   @i_operacion='D',
   @i_codigo_tabla = @i_matriz,
   @i_fecha_vig    = @i_fecha_vig
   
   delete ca_matriz
   where ma_matriz    = @i_matriz
   and   ma_fecha_vig = @i_fecha_vig
   if @@error <> 0 begin
      exec cobis..sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 2107013 ---- Error al borrar
   end
end

/* Consulta Listado */

if @i_operacion = 'S' begin
   select
   'CodigoTabla' = ma_matriz,
   'NombreTabla' = ma_descripcion,
   'Fecha_Vig'   = convert(varchar(10), ma_fecha_vig,103),   
   '#ejes'       = ma_ejes,
   'VlrDefault'  = ma_valor_default
   from ca_matriz
   order by ma_matriz   
end

/* Consulta Unitaria */

if @i_operacion = 'Q' begin
   select
   ma_matriz,
   ma_descripcion,
   convert(varchar(10), ma_fecha_vig,103),
   ma_ejes,
   ma_valor_default
   from ca_matriz
   where ma_matriz    = @i_matriz
   and   ma_fecha_vig = @i_fecha_vig
   
   exec sp_matriz_ptmp
   @i_matriz     = @i_matriz,
   @i_fecha_vig  = @i_fecha_vig 

end

return 0

go
