/************************************************************************/
/*  Archivo:              ca_trascon.sp                                 */
/*  Stored procedure:     sp_consulta_traslados                         */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         Luisa Fernanda Bernal                         */
/*  Fecha de escritura:   27/Enero/2014                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA'.                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                               CAMBIOS                                */
/*   FECHA     AUTOR          CAMBIO                                    */
/*   Feb-2014  Luisa BErnal   REQ 00375 Traslado cupos cartera          */
/************************************************************************/  
use cob_cartera
go 
if exists (select 1 from sysobjects where name = 'sp_consulta_traslados')
   drop proc sp_consulta_traslados
go


create proc  sp_consulta_traslados(
   @s_user              login,      
   @s_term              varchar(30),
   @s_date              datetime,   
   @s_ofi               int,
   @i_operacion         char(1), 
   @i_fecha_ini         datetime,
   @i_fecha_fin         datetime,
   @i_modo              int = 0,
   @i_opcion            int  = 1,
   @i_oficina           varchar(10) = null,
   @i_siguiente         bigint = null,
   @i_en_linea          char(1)  = 'S'
  -- @o_num_registros     int      = 0  out   
      
)

as
declare
      @w_sp_name                varchar(32),
      @w_error                  int,
      @w_msg                    varchar(100),
      @w_commit                 char(1)
          
            
--- INICIAR VARIABLES DE TRABAJO 
select  
@w_sp_name       = 'sp_consulta_traslados',
@w_commit        = 'N'

if  @i_operacion = 'S' --Opcion Buscar
begin
   
   if @i_opcion =  0 -- Opcion Con oficina
   begin
   
      if @i_modo = 0 --opcion Buscar con oficina
      begin
         set rowcount 20
         select
         'SECUENCIAL'        = bt_secuencial ,
         'ARCHIVO          ' = bt_archivo,
         'OFICINA'           = bt_oficina,         
         'USUARIO'           = bt_usuario,
         'FECHA CARGA '      = bt_fecha_carga 
         from  cob_cartera..ca_bitacora_traslados
         where 
         bt_fecha_carga >= @i_fecha_ini and
         bt_fecha_carga  < @i_fecha_fin + 1 
         and @i_oficina  = bt_oficina
         
        order by bt_secuencial 
        set rowcount 0
         
      end 
      else  --Opcion Siguiente con oficina
      begin              
         set rowcount 20
         select
         'SECUENCIAL'        = bt_secuencial ,
         'ARCHIVO          ' = bt_archivo,
         'OFICINA'           = bt_oficina,         
         'USUARIO'           = bt_usuario,
         'FECHA CARGA '      = bt_fecha_carga 
         from  cob_cartera..ca_bitacora_traslados
         where
         bt_fecha_carga >= @i_fecha_ini and
         bt_fecha_carga  < @i_fecha_fin + 1 
         and @i_oficina  = bt_oficina
         and bt_secuencial  > @i_siguiente
         order by bt_secuencial 
         set rowcount 0
       
      end
   end
   else
   begin
      if @i_modo = 0 --opcion Buscar sin oficina
      begin
         set rowcount 20
         select
         'SECUENCIAL'        = bt_secuencial ,
         'ARCHIVO          ' = bt_archivo,
         'OFICINA'           = bt_oficina,         
         'USUARIO'           = bt_usuario,
         'FECHA CARGA '      = bt_fecha_carga 
         from  cob_cartera..ca_bitacora_traslados
         where 
           bt_fecha_carga >= @i_fecha_ini and
           bt_fecha_carga  < @i_fecha_fin + 1 
           order by bt_secuencial 
           set rowcount 0
         
      end 
      else  --Opcion Siguiente sin oficina
      begin              
         set rowcount 20
         select
         'SECUENCIAL'        = bt_secuencial ,
         'ARCHIVO          ' = bt_archivo,
         'OFICINA'           = bt_oficina,         
         'USUARIO'           = bt_usuario,
         'FECHA CARGA '      = bt_fecha_carga 
         from  cob_cartera..ca_bitacora_traslados
         where 
           bt_fecha_carga >= @i_fecha_ini and
           bt_fecha_carga  < @i_fecha_fin + 1 
           and bt_secuencial  > @i_siguiente
         order by bt_secuencial 
         set rowcount 0
       
      end
   
   end
 
    
   return 0
end

ERRORFIN:

if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end


if @i_en_linea  = 'S' begin

   exec cobis..sp_cerror
   @t_debug  = 'N',
   @t_file   = null,
   @t_from   = @w_sp_name,
   @i_num    = @w_error,
   @i_msg    = @w_msg
   
end else begin

   exec sp_errorlog 
   @i_fecha     = @s_date,
   @i_error     = @w_error, 
   @i_usuario   = @s_user, 
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = 'GENERAL',
   @i_rollback  = 'N',
   @i_descripcion= @w_msg
   
end

return @w_error

go

