/************************************************************************/
/*  Archivo:            ca_eje.sp                                       */
/*  Stored procedure:   sp_eje                                          */
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
/*  Mantenimiento Matrices Dimencionales (EJES)                         */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       		 	RAZON                           */
/*                                                                      */
/************************************************************************/
use cob_cartera
go
  
if exists (select 1 from sysobjects where name = 'sp_eje' )
drop proc sp_eje
go
---FEb.27.2012. LLS39777

create proc sp_eje
(
@s_ssn            int = null,
@s_user           login = null,
@s_sesn           int = null,
@s_term           varchar(30) = null,
@s_date           datetime = null,
@s_srv            varchar(30) = null,
@s_lsrv           varchar(30) = null,
@s_rol            smallint = NULL,
@s_ofi            smallint = NULL,
@s_org_err        char(1) = NULL,
@s_error          int = NULL,
@s_sev            tinyint = NULL, 
@s_msg            descripcion = NULL,
@s_org            char(1) = NULL,
@t_debug          char(1) = 'N',
@t_file           varchar(10) = null,
@t_from           varchar(32) = null,
@i_operacion      char(1),
@i_matriz         varchar(10),
@i_fecha_vig      smalldatetime,
@i_eje            int = null,
@i_descripcion    varchar(60) = null,
@i_tipo_dato      char(1) = null,
@i_rango          char(1) = null,
@i_valor_default  varchar(60) = null,
@i_modo           char(1) = null,
@i_sec            int     = 0

)
as
declare 
@w_sp_name	varchar(30)

select @w_sp_name = 'sp_eje'

--- Codigos de Transacciones 

--- Insertar/Modificar 
if @i_operacion = 'I' begin 
   if exists(select 1 from ca_eje_tmp
             where ejt_matriz    = @i_matriz
             and   ejt_fecha_vig = @i_fecha_vig
             and   ejt_eje       = @i_eje)
   begin  
      print @i_valor_default    
      update ca_eje_tmp
      set ejt_tipo_dato       = @i_tipo_dato,
	      ejt_rango           = @i_rango,
          ejt_valor_default   =  @i_valor_default       
          where ejt_matriz    = @i_matriz
          and   ejt_fecha_vig = @i_fecha_vig
          and   ejt_eje       = @i_eje
 	  if @@error <> 0 begin
         exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 2107013 ---- Error al insertar
      end
   end
   else begin
      insert into ca_eje_tmp
      values (@i_matriz, @i_descripcion, @i_fecha_vig, @i_eje, @i_tipo_dato, @i_rango,@i_valor_default)
      if @@error <> 0 begin
         exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 2107013 ---- Error al insertar
         end
   end
end

--- Borra Matriz  
if @i_operacion = 'D' begin
   delete ca_eje
   where ej_matriz    = @i_matriz
   and   ej_fecha_vig = @i_fecha_vig
   and   ej_eje       = @i_eje
   if @@error <> 0
   begin
   exec cobis..sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 2107013 ---- Error al borrar
   end
end

--- Consulta Listado  

if @i_operacion = 'S' begin
select
   'N£mero Eje'        = ejt_eje,
   'Descripci¢n'       = ejt_descripcion,
   'TipoDato'          = ejt_tipo_dato,
   'Rango'             = ejt_rango ,
   'Valor por Defecto' = ejt_valor_default 
   from ca_eje_tmp
   where ejt_matriz    = @i_matriz
   and   ejt_fecha_vig = @i_fecha_vig
   order by ejt_eje
end

--- Consulta Unitaria  

if @i_operacion = 'Q' begin
select
   ej_eje,
   ej_descripcion,
   ej_tipo_dato,
   ej_rango,
   ej_valor_default
   from ca_eje
   where ej_matriz    = @i_matriz
   and   ej_fecha_vig = @i_fecha_vig
   and   ej_eje       = @i_eje
end

if @i_operacion = 'T' begin
   select
   'Eje'      = ej_eje,
   'Descripcion'  = ej_descripcion,
   'Rango'        = 'NULL',
   'Desde'        = 'NULL',
   'Hasta'        = 'NULL'
   from ca_eje e
   where ej_matriz    = @i_matriz
   and   ej_fecha_vig = @i_fecha_vig
   and exists (select  1
               from ca_eje_rango
                where er_matriz    = e.ej_matriz
                and   er_eje       = e.ej_eje)
   order by ej_eje
end

if @i_operacion = 'W' begin

	select 
	   'Eje'      = er_eje,
	   'Descripcion'  = substring(ej_descripcion,1,20),
	   'Rango'        = ej_rango,
	   'Cantidad'     = count(1)
	from ca_eje_rango,ca_eje
	where er_matriz    = @i_matriz
	and   er_eje       = ej_eje
	and   er_matriz    = ej_matriz
	group by er_eje,ej_descripcion,ej_rango
end

if @i_operacion = 'C' begin

   if @i_fecha_vig is null
   begin
	   select @i_fecha_vig = fc_fecha_cierre
	   from  cobis..ba_fecha_cierre
	   where fc_producto = 7
   end
   

   if @i_modo = '0'
   begin
	    select 
		 mc_sec,
		 mc_hora,
	     mc_usuario, 
	     mc_accion,
	     mc_matriz,
	     mc_rango1,
	     mc_rango2,
	     mc_rango3,
	     mc_rango4,
	     mc_rango5,
	     mc_rango6,
	     mc_rango7,
	     mc_rango8,
	     mc_rango9,
	     mc_rango10,
	     mc_rango11,
	     mc_rango12,
	     mc_rango13,
	     mc_rango14,
	     mc_rango15,
	     mc_valor
		from ca_matriz_consulta_tmp
		where mc_matriz    = @i_matriz
		and   mc_fecha     = @i_fecha_vig
		order by mc_sec
	end
	ELSE
	begin
	 select 
	   'Sec.'            = md_sec,
	   'Usuario'          = md_usuario,
	   'Matriz'           = md_matriz,
	   'Número Eje'        = md_eje,
	   'Descripcion'       = md_descripcion,
	   'Rango'             = md_rango,
	   'Desde'             = md_desde,
	   'Hasta'             = md_hasta,
	   'Accion'            = md_accion
	   from ca_matriz_consultaD_tmp
	   where  md_sec = @i_sec
	   and    md_fecha = @i_fecha_vig
	   and    md_matriz = @i_matriz
	   order by md_eje
	
	end
end


return 0

go
