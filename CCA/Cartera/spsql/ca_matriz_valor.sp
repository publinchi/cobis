/************************************************************************/
/*  Archivo:            ca_matriz_valor.sp                              */
/*  Stored procedure:   sp_man_matriz_valor                             */
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
/*  Mantenimiento Matrices Dimencionales (VALORES MATRIZ)               */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       		 	RAZON                           */
/*                                                                      */
/************************************************************************/
use cob_cartera
go
  
if exists (select 1 from sysobjects where name = 'sp_man_matriz_valor' )
drop proc sp_man_matriz_valor
go


---INC. 56230 ABRIL.13.2012

create proc sp_man_matriz_valor
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
@i_operacion   char(1),
@i_matriz      varchar(10),
@i_fecha_vig   smalldatetime,
@i_rango1      int = 0,
@i_rango2      int = 0,
@i_rango3      int = 0,
@i_rango4      int = 0,
@i_rango5      int = 0,
@i_rango6      int = 0,
@i_rango7      int = 0,
@i_rango8      int = 0,
@i_rango9      int = 0,
@i_rango10     int = 0,
@i_rango11     int = 0,
@i_rango12     int = 0,
@i_rango13     int = 0,
@i_rango14     int = 0,
@i_rango15     int = 0,
@i_valor       float = 0.00,
@i_opcion      tinyint = 0,
@i_siguiente   int = 0,
@i_descripcion varchar(20) = null,
@i_rango       int         = null,
@i_desde       varchar(20) = null,
@i_hasta       varchar(20) = null,
@i_eje         int         = null,
@i_secuencial  int         = null


)
as
declare 
@w_sp_name	varchar(30),
@w_error    int,
@w_sec      int,
@w_fecha_cca datetime

select @w_fecha_cca = convert(varchar(12),fc_fecha_cierre,101)
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_sp_name = 'sp_man_matriz_valor'

--- Insertar/Modificar Tabla


if @i_operacion = 'I' begin 

   if @i_valor is null   begin
      select @i_valor = 0
     end 
    
   if exists(select 1 from ca_matriz_valor
             where mv_matriz    = @i_matriz
             and   mv_fecha_vig = @i_fecha_vig)
   begin 
      update ca_matriz_valor
      set mv_rango1   = @i_rango1,
          mv_rango2   = @i_rango2,
          mv_rango3   = @i_rango3,
          mv_rango4   = @i_rango4,
          mv_rango5   = @i_rango5,
          mv_rango6   = @i_rango6,
          mv_rango7   = @i_rango7,
          mv_rango8   = @i_rango8,
          mv_rango9   = @i_rango9,
          mv_rango10  = @i_rango10,
          mv_rango11  = @i_rango11,
          mv_rango12  = @i_rango12,
          mv_rango13  = @i_rango13,
          mv_rango14  = @i_rango14,
          mv_rango15  = @i_rango15,
          mv_valor    = @i_valor
      where mv_matriz    = @i_matriz
      and   mv_fecha_vig = @i_fecha_vig
 	  if @@error <> 0 begin
 	     PRINT 'ca_matriz_valor.sp Error Actualizando datos en ca_matriz_valor'
         exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 2107013 ---- Error al insertar
      end

  	   --Insercion en tabla de auditoria
	   insert into ca_matriz_valor_ts
	   select @s_user, @s_ofi, @s_term,'U', getdate(),  *
	   from ca_matriz_valor
	   where mv_matriz     = @i_matriz
	   and   mv_fecha_vig  = @i_fecha_vig
	   and   mv_rango1     = @i_rango1
	   and   mv_rango2     = @i_rango2
	   and   mv_rango3     = @i_rango3
	   and   mv_rango4     = @i_rango4
	   and   mv_rango5     = @i_rango5
	   and   mv_rango6     = @i_rango6
	   and   mv_rango7     = @i_rango7
	   and   mv_rango8     = @i_rango8
	   and   mv_rango9     = @i_rango9
	   and   mv_rango10    = @i_rango10
	   and   mv_rango11    = @i_rango11
	   and   mv_rango12    = @i_rango12
	   and   mv_rango13    = @i_rango13
	   and   mv_rango14    = @i_rango14
	   and   mv_rango15    = @i_rango15   
      
   end
   else begin
      insert into ca_matriz_valor
      values (@i_matriz, @i_fecha_vig, @i_rango1, @i_rango2, @i_rango3, @i_rango4, @i_rango5, @i_rango6,
               @i_rango7, @i_rango8, @i_rango9, @i_rango10, @i_rango11, @i_rango12,@i_rango13,@i_rango14,
               @i_rango15,@i_valor)
      if @@error <> 0 begin
         PRINT 'ca_matriz_valor.sp Error Insertando datos' 
         exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 2107013 ---- Error al insertar

         ---Insercion en tabla de auditoria
		 insert into ca_matriz_valor_ts
		 select @s_user, @s_ofi, @s_term,'U', getdate(),  *
		 from ca_matriz_valor
		 where mv_matriz     = @i_matriz
		 and   mv_fecha_vig  = @i_fecha_vig
		 and   mv_rango1     = @i_rango1
		 and   mv_rango2     = @i_rango2
		 and   mv_rango3     = @i_rango3
		 and   mv_rango4     = @i_rango4
		 and   mv_rango5     = @i_rango5
		 and   mv_rango6     = @i_rango6
		 and   mv_rango7     = @i_rango7
		 and   mv_rango8     = @i_rango8
		 and   mv_rango9     = @i_rango9
		 and   mv_rango10    = @i_rango10
		 and   mv_rango11    = @i_rango11
		 and   mv_rango12    = @i_rango12
		 and   mv_rango13    = @i_rango13
		 and   mv_rango14    = @i_rango14
		 and   mv_rango15    = @i_rango15   
         
      end
   end
     
end

--- Borra Matriz 
if @i_operacion = 'D' begin

   delete ca_matriz_valor
   where mv_matriz    = @i_matriz
   and   mv_fecha_vig = @i_fecha_vig

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
identity(int, 1,1) as mvt_secuencial, 
*
into #ca_matriz_valor_tmp
from ca_matriz_valor_tmp
where mvt_matriz    = @i_matriz
and   mvt_fecha_vig = @i_fecha_vig
order by mvt_rango1 , mvt_rango2 ,mvt_rango3, mvt_rango4 ,mvt_rango5 ,mvt_rango6,
         mvt_rango7 ,mvt_rango8, mvt_rango9 ,mvt_rango10 ,mvt_rango11,
         mvt_rango12 ,mvt_rango13 ,mvt_rango14  ,mvt_rango15

set rowcount 30
    select 
   'Eje1'    = mvt_rango1,
   'Eje2'    = mvt_rango2,
   'Eje3'    = mvt_rango3,
   'Eje4'    = mvt_rango4,
   'Eje5'    = mvt_rango5,
   'Eje6'    = mvt_rango6,
   'Eje7'    = mvt_rango7,
   'Eje8'    = mvt_rango8,
   'Eje9'    = mvt_rango9,
   'Eje10'   = mvt_rango10,
   'Eje11'   = mvt_rango11,
   'Eje12'   = mvt_rango12,
   'Eje13'   = mvt_rango13,
   'Eje14'   = mvt_rango14,
   'Eje15'   = mvt_rango15,
   'Valor'   = mvt_valor
from #ca_matriz_valor_tmp
where mvt_matriz    = @i_matriz
and   mvt_fecha_vig = @i_fecha_vig
and   mvt_secuencial > @i_siguiente
order by mvt_rango1 , mvt_rango2 ,mvt_rango3, mvt_rango4 ,mvt_rango5 ,mvt_rango6,
         mvt_rango7 ,mvt_rango8, mvt_rango9 ,mvt_rango10 ,mvt_rango11,
         mvt_rango12 ,mvt_rango13 ,mvt_rango14  ,mvt_rango15
set rowcount 0


end


---Buscar las combinaciones de la matriz con lo seleccionado por el usuario
if @i_operacion = 'Q' begin

	 if @i_valor is null   begin
      select @i_valor = 0
     end

      if not exists (select 1	from ca_matriz_valor
	               where mv_matriz   = @i_matriz
	               and  mv_fecha_vig = @i_fecha_vig
          	       and   mv_rango1     = @i_rango1
				   and   mv_rango2     = @i_rango2
				   and   mv_rango3     = @i_rango3
				   and   mv_rango4     = @i_rango4
				   and   mv_rango5     = @i_rango5
				   and   mv_rango6     = @i_rango6
				   and   mv_rango7     = @i_rango7
				   and   mv_rango8     = @i_rango8
				   and   mv_rango9     = @i_rango9
				   and   mv_rango10    = @i_rango10
				   and   mv_rango11    = @i_rango11
				   and   mv_rango12    = @i_rango12
				   and   mv_rango13    = @i_rango13
				   and   mv_rango14    = @i_rango14
				   and   mv_rango15    = @i_rango15   
	              
	               )
     begin
	      insert into ca_matriz_valor
	      values (@i_matriz, @i_fecha_vig, @i_rango1, @i_rango2, @i_rango3, @i_rango4, @i_rango5, @i_rango6,
	               @i_rango7, @i_rango8, @i_rango9, @i_rango10, @i_rango11, @i_rango12,@i_rango13,@i_rango14,
	               @i_rango15,@i_valor)
	      if @@error <> 0 begin
	         PRINT 'ca_matriz_valor.sp Error Insertando datos ca_matriz_valor' 
	         exec cobis..sp_cerror
	         @t_debug    = @t_debug,
	         @t_file     = @t_file,
	         @t_from     = @w_sp_name,
	         @i_num      = 2107013 ---- Error al insertar
	      end
          ---REGISTRO PARA CONSULTA DEL USUARIO
	      insert into ca_matriz_consulta_tmp 
			(
			mc_sec,     mc_fecha  , mc_hora,    mc_usuario, mc_accion , mc_matriz , mc_rango1 , mc_rango2 , 
			mc_rango3 , mc_rango4 , mc_rango5 , mc_rango6 , mc_rango7 , mc_rango8 , mc_rango9 , 
			mc_rango10, mc_rango11, mc_rango12, mc_rango13, mc_rango14, mc_rango15, mc_valor 
			)
			values
			(
			@w_sec,    @w_fecha_cca, getdate(),@s_user,         'I',      @i_matriz,  @i_rango1, @i_rango2, 
			@i_rango3, @i_rango4, @i_rango5, @i_rango6,    @i_rango7, @i_rango8, @i_rango9, 
			@i_rango10, @i_rango11, @i_rango12,@i_rango13,@i_rango14, @i_rango15,@i_valor			
			)
     end

     
	select isnull(max(mv_valor),0)
	from ca_matriz_valor
	where mv_matriz   = @i_matriz
	and mv_fecha_vig = @i_fecha_vig
	and mv_rango1   = @i_rango1
	and mv_rango2   = @i_rango2
	and mv_rango3   = @i_rango3
	and mv_rango4   = @i_rango4
	and mv_rango5   = @i_rango5
	and mv_rango6   = @i_rango6
	and mv_rango7   = @i_rango7
	and mv_rango8   = @i_rango8
	and mv_rango9   = @i_rango9
	and mv_rango10  = @i_rango10
	and mv_rango11  = @i_rango11
	and mv_rango12  = @i_rango12
	and mv_rango13  = @i_rango13
	and mv_rango14  = @i_rango14
	and mv_rango15  = @i_rango15

end
--- Actualizar Registro valor 
if @i_operacion = 'U' begin

	exec @w_sec = sp_gen_sec
	     @i_operacion = -2

	 if @i_valor is null   begin
      select @i_valor = 0
     end

      if not exists (select 1	from ca_matriz_valor
	               where mv_matriz   = @i_matriz
	               and  mv_fecha_vig = @i_fecha_vig
	               and   mv_rango1     = @i_rango1
				   and   mv_rango2     = @i_rango2
				   and   mv_rango3     = @i_rango3
				   and   mv_rango4     = @i_rango4
				   and   mv_rango5     = @i_rango5
				   and   mv_rango6     = @i_rango6
				   and   mv_rango7     = @i_rango7
				   and   mv_rango8     = @i_rango8
				   and   mv_rango9     = @i_rango9
				   and   mv_rango10    = @i_rango10
				   and   mv_rango11    = @i_rango11
				   and   mv_rango12    = @i_rango12
				   and   mv_rango13    = @i_rango13
				   and   mv_rango14    = @i_rango14
				   and   mv_rango15    = @i_rango15   
		   	              
	               )
     begin
	      insert into ca_matriz_valor
	      values (@i_matriz, @i_fecha_vig, @i_rango1, @i_rango2, @i_rango3, @i_rango4, @i_rango5, @i_rango6,
	               @i_rango7, @i_rango8, @i_rango9, @i_rango10, @i_rango11, @i_rango12,@i_rango13,@i_rango14,
	               @i_rango15,@i_valor)
	      if @@error <> 0 begin
	         PRINT 'ca_matriz_valor.sp Error Insertando datos en ca_matriz_valor' 
	         exec cobis..sp_cerror
	         @t_debug    = @t_debug,
	         @t_file     = @t_file,
	         @t_from     = @w_sp_name,
	         @i_num      = 2107013 ---- Error al insertar
	      end
          ---REGISTRO PARA CONSULTA DEL USUARIO
	      insert into ca_matriz_consulta_tmp 
			(
			mc_sec,     mc_fecha  ,mc_hora,  mc_usuario, mc_accion , mc_matriz , mc_rango1 , mc_rango2 , 
			mc_rango3 , mc_rango4 , mc_rango5 , mc_rango6 , mc_rango7 , mc_rango8 , mc_rango9 , 
			mc_rango10, mc_rango11, mc_rango12, mc_rango13, mc_rango14, mc_rango15, mc_valor 
			)
			values
			(
			@w_sec,    @w_fecha_cca,  getdate(),@s_user,         'I',      @i_matriz,  @i_rango1, @i_rango2, 
			@i_rango3, @i_rango4, @i_rango5, @i_rango6,    @i_rango7, @i_rango8, @i_rango9, 
			@i_rango10, @i_rango11, @i_rango12,@i_rango13,@i_rango14, @i_rango15,@i_valor			
			)
			
     end
     else
     begin	 
		 --Insercion en tabla de auditoria
		   insert into ca_matriz_valor_ts
		   select @s_user, @s_ofi, @s_term,'U', getdate(),  *
		   from ca_matriz_valor
		   where mv_matriz     = @i_matriz
		   and   mv_fecha_vig  = @i_fecha_vig
		   and   mv_rango1     = @i_rango1
		   and   mv_rango2     = @i_rango2
		   and   mv_rango3     = @i_rango3
		   and   mv_rango4     = @i_rango4
		   and   mv_rango5     = @i_rango5
		   and   mv_rango6     = @i_rango6
		   and   mv_rango7     = @i_rango7
		   and   mv_rango8     = @i_rango8
		   and   mv_rango9     = @i_rango9
		   and   mv_rango10    = @i_rango10
		   and   mv_rango11    = @i_rango11
		   and   mv_rango12    = @i_rango12
		   and   mv_rango13    = @i_rango13
		   and   mv_rango14    = @i_rango14
		   and   mv_rango15    = @i_rango15   
		
		   update ca_matriz_valor
		   set mv_valor = @i_valor
		   where mv_matriz     = @i_matriz
		   and   mv_fecha_vig  = @i_fecha_vig
		   and   mv_rango1     = @i_rango1
		   and   mv_rango2     = @i_rango2
		   and   mv_rango3     = @i_rango3
		   and   mv_rango4     = @i_rango4
		   and   mv_rango5     = @i_rango5
		   and   mv_rango6     = @i_rango6
		   and   mv_rango7     = @i_rango7
		   and   mv_rango8     = @i_rango8
		   and   mv_rango9     = @i_rango9
		   and   mv_rango10    = @i_rango10
		   and   mv_rango11    = @i_rango11
		   and   mv_rango12    = @i_rango12
		   and   mv_rango13    = @i_rango13
		   and   mv_rango14    = @i_rango14
		   and   mv_rango15    = @i_rango15      
		
		   if @@rowcount = 0 begin
		       PRINT 'ca_matriz_valor.sp Error Actualizando datos enca_matriz_valor_tmp  @i_matriz ' +  CAST ( @i_matriz as varchar) + ' @i_fecha_vig ' +  CAST (@i_fecha_vig as varchar)
		      exec cobis..sp_cerror
		      @t_debug    = @t_debug,
		      @t_file     = @t_file,
		      @t_from     = @w_sp_name,
		      @i_num      = 2107013 ---- Error al insertar
		   end

		  ---REGISTRO PARA CONSULTA DEL USUARIO
	      insert into ca_matriz_consulta_tmp 
			(
			mc_sec,     mc_fecha  , mc_hora,   mc_usuario, mc_accion , mc_matriz , mc_rango1 , mc_rango2 , 
			mc_rango3 , mc_rango4 , mc_rango5 , mc_rango6 , mc_rango7 , mc_rango8 , mc_rango9 , 
			mc_rango10, mc_rango11, mc_rango12, mc_rango13, mc_rango14, mc_rango15, mc_valor 
			)
			values
			(
			@w_sec,     @w_fecha_cca, getdate(),@s_user,       'U',       @i_matriz,  @i_rango1, @i_rango2, 
			@i_rango3, @i_rango4, @i_rango5, @i_rango6,    @i_rango7, @i_rango8, @i_rango9, 
			@i_rango10, @i_rango11, @i_rango12,@i_rango13,@i_rango14, @i_rango15,@i_valor			
			)		   
 
   end
   select @w_sec
end --U

--- Detalle de Consulta
if @i_operacion = 'L' begin

	insert into ca_matriz_consultaD_tmp 
	(  
	md_sec,        md_fecha      ,md_usuario    ,md_accion     ,md_matriz,md_eje,
	md_descripcion,md_rango      ,md_desde      ,md_hasta
	)
	values
	(
	@i_secuencial,@w_fecha_cca,  @s_user,           'U',          @i_matriz, @i_eje,
	@i_descripcion, @i_rango, @i_desde, @i_hasta
	)

end --L

return 0

go
