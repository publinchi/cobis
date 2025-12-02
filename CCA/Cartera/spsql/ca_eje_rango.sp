/************************************************************************/
/*  Archivo:            ca_eje_rango.sp                                 */
/*  Stored procedure:   sp_eje_rango                                    */
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
/*  Mantenimiento Matrices Dimencionales (EJES-RANGOS)                  */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       		 	RAZON                           */
/*                                                                      */
/************************************************************************/
use cob_cartera
go
  
if exists (select 1 from sysobjects where name = 'sp_eje_rango' )
drop proc sp_eje_rango
go

---SEP.07.2012 INC.79290  partendo de la version 12

create proc sp_eje_rango
(
@s_ssn           int = null,
@s_user          login = null,
@s_sesn          int = null,
@s_term          varchar(30) = null,
@s_date          datetime = null,
@s_srv           varchar(30) = null,
@s_lsrv          varchar(30) = null,
@s_rol           smallint = NULL,
@s_ofi           smallint = NULL,
@s_org_err       char(1) = NULL,
@s_error         int = NULL,
@s_sev           tinyint = NULL,
@s_msg           descripcion = NULL,
@s_org           char(1) = NULL,
@t_debug         char(1) = 'N',
@t_file          varchar(10) = null,
@t_from          varchar(32) = null,
@i_operacion     char(1),
@i_matriz        varchar(10),
@i_fecha_vig     smalldatetime,
@i_eje           int = null,
@i_rango         int = null,
@i_rango_desde   varchar(20) = null,
@i_rango_hasta   varchar(20) = null,
@i_secuencial     int = 0,
@i_modo           int = 0,
@i_indicador      char(1) =  null
)
as
declare 
@w_sp_name	   varchar(30),
@w_rei         int,
@w_rango_desde varchar(20),
@w_rango_hasta varchar(20),
@w_max_rango   int ,
@w_error       int,
@w_maximo      int,
@w_existe      char(1),
@w_total_reg   int

select @w_sp_name = 'sp_eje_rango',
       @w_maximo  = 0      

--- Insertar/Modificar  

if @i_operacion = 'I' begin 
   begin tran
   if exists(select 1 from ca_eje_rango_tmp
             where ert_matriz          = @i_matriz
             and   ert_fecha_vig       = @i_fecha_vig
             and   ert_eje             = @i_eje
             and   ert_rango_desde     = @i_rango_desde
             and   ert_rango_hasta     = @i_rango_hasta)
   begin          
     print 'Error al insertar, Registro ya existe'     
     return 0
   end
   
   if exists(select * from ca_eje_rango_tmp
             where ert_matriz    = @i_matriz
             and   ert_fecha_vig = @i_fecha_vig
             and   ert_eje       = @i_eje
             and   ert_rango     = @i_rango)
   begin 
      update ca_eje_rango_tmp
      set ert_rango_desde   = @i_rango_desde,
          ert_rango_hasta   = @i_rango_hasta          
          where ert_matriz    = @i_matriz
          and   ert_fecha_vig = @i_fecha_vig
          and   ert_eje       = @i_eje
          and   ert_rango     = @i_rango
 	  if @@error <> 0 begin
         exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 2107013 ---- Error al insertar
      end      
      --Insercion en tabla de auditoria
      exec @w_error  = sp_tran_servicio
      @s_user      = @s_user,
      @s_date      = @s_date, 
      @s_ofi       = @s_ofi,
      @s_term      = @s_term,
      @i_tabla     = 'eje_rango', 
      @i_clave1    = @i_matriz, 
      @i_clave2    = @i_fecha_vig,
      @i_clave3    = 'U',
      @i_clave4    = @i_eje,
      @i_clave5    = @i_rango
      
   end
   else begin
      insert into ca_eje_rango_tmp
      values (@i_matriz, @i_fecha_vig, @i_eje, @i_rango, @i_rango_desde, @i_rango_hasta)
      if @@error <> 0 begin
         exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 2107013 ---- Error al insertar
         end
         
      --Insercion en tabla de auditoria   
      exec @w_error  = sp_tran_servicio
      @s_user      = @s_user,
      @s_date      = @s_date, 
      @s_ofi       = @s_ofi,
      @s_term      = @s_term,
      @i_tabla     = 'eje_rango', 
      @i_clave1    = @i_matriz, 
      @i_clave2    = @i_fecha_vig,
      @i_clave3    = @i_operacion,
      @i_clave4    = @i_eje,
      @i_clave5    = @i_rango   
      
   end  
  
   goto VALIDA_RANGO
end

--- Borra Matriz  
if @i_operacion = 'D' begin
   begin tran
   
   --Insercion en tabla de auditoria
   exec @w_error  = sp_tran_servicio
   @s_user      = @s_user,
   @s_date      = @s_date, 
   @s_ofi       = @s_ofi,
   @s_term      = @s_term,
   @i_tabla     = 'eje_rango', 
   @i_clave1    = @i_matriz, 
   @i_clave2    = @i_fecha_vig,
   @i_clave3    = @i_operacion,
   @i_clave4    = @i_eje,
   @i_clave5    = @i_rango
   
   delete ca_eje_rango_tmp
   where ert_matriz    = @i_matriz
   and   ert_fecha_vig = @i_fecha_vig
   and   ert_eje       = @i_eje
   and   ert_rango     = @i_rango

   if @@error <> 0
   begin
   exec cobis..sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 2107013 ---- Error al borrar
   end   
         
   if @i_eje = 1 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango1 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango1 = mvt_rango1 - 1 where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango1 > @i_rango
   end
   if @i_eje = 2 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango2 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango2 = mvt_rango2 - 1 where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango2 > @i_rango
   end
   if @i_eje = 3 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango3 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango3 = mvt_rango3 - 1 where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango3 > @i_rango
   end
   if @i_eje = 4 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango4 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango4 = mvt_rango4 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango4 > @i_rango
   end
   if @i_eje = 5 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango5 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango5 = mvt_rango5 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango5 > @i_rango
   end
   if @i_eje = 6 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango6 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango6 = mvt_rango6 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango6 > @i_rango
   end

   if @i_eje = 7 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango7 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango7 = mvt_rango7 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango7 > @i_rango
   end

   if @i_eje = 8 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango8 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango8 = mvt_rango8 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango8 > @i_rango
   end
   if @i_eje = 9 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango9 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango9 = mvt_rango9 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango9 > @i_rango
   end
   if @i_eje = 10 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango10 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango10 = mvt_rango10 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango10 > @i_rango
   end
   if @i_eje = 11 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango11 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango11 = mvt_rango11 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango11 > @i_rango
   end
   if @i_eje = 12 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango12 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango12 = mvt_rango12 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango12 > @i_rango
   end
   if @i_eje = 13 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango13 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango13 = mvt_rango13 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango13 > @i_rango
   end
   if @i_eje = 14 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango14 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango14 = mvt_rango14 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango14 > @i_rango
   end
   if @i_eje = 15 begin
      delete ca_matriz_valor_tmp where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango15 = @i_rango
      update ca_matriz_valor_tmp set mvt_rango15 = mvt_rango15 - 1  where mvt_matriz = @i_matriz and mvt_fecha_vig = @i_fecha_vig and mvt_rango15 > @i_rango
   end
   
   update ca_eje_rango_tmp
   set ert_rango = ert_rango - 1
   where ert_matriz    = @i_matriz
   and   ert_fecha_vig = @i_fecha_vig
   and   ert_eje       = @i_eje
   and   ert_rango     > @i_rango 
      
   goto VALIDA_RANGO
end

--- Consulta Listado  

if @i_operacion = 'S' begin

   if @i_modo = '1'
   begin
    ----Carga Total, Limpia la Tabla y carga todo con un Sec.
    ---Para controlar la carga de 20 en 20
	if @i_secuencial = 0
	begin
		truncate table ca_EjeRango_Listmp
		insert into ca_EjeRango_Listmp
		select
	   'Eje'               = ert_eje,
	   'Rango'             = ert_rango,
	   'Desde'             = ert_rango_desde,
	   'Hasta'             = ert_rango_hasta
	   from ca_eje_rango_tmp
	   where ert_matriz    = @i_matriz
	   and   ert_fecha_vig = @i_fecha_vig
	   and   (ert_eje       = @i_eje or @i_eje is null)
	   order by ert_eje, ert_rango

	   ----Enviar las primeras 20	   
       
	    set rowcount 20

	     select
	    'Sec'               = rmt_secuencial,
  	    'Eje'               = rmt_eje,
	    'Rango'             = rmt_rango,
	    'Desde'             = rmt_desde,
	    'Hasta'             = rmt_hasta
	     from ca_EjeRango_Listmp
	     where rmt_secuencial    > @i_secuencial
	     order by rmt_eje, rmt_rango	    
	    
	     set rowcount 0
	     select @w_total_reg =0
	     select @w_total_reg = count(1)
	     from ca_EjeRango_Listmp
	     
	     select @w_total_reg
    end
    ELSE
    begin

	    set rowcount 20

	     select
	    'Sec'               = rmt_secuencial,
  	    'Eje'               = rmt_eje,
	    'Rango'             = rmt_rango,
	    'Desde'             = rmt_desde,
	    'Hasta'             = rmt_hasta
	     from ca_EjeRango_Listmp
	     where rmt_secuencial    > @i_secuencial
	     order by rmt_eje, rmt_rango	    
	    
	    
	     set rowcount 0       
    end
   end 
   ELSE
   begin
    ---La seleccion comoestaba antes
	select
	   'Eje'               = ert_eje,
	   'Rango'             = ert_rango,
	   'Desde'             = ert_rango_desde,
	   'Hasta'             = ert_rango_hasta
	   from ca_eje_rango_tmp
	   where ert_matriz    = @i_matriz
	   and   ert_fecha_vig = @i_fecha_vig
	   and   (ert_eje       = @i_eje or @i_eje is null)
	   order by ert_eje, ert_rango    
   end  

end


if @i_operacion = 'R' begin
   if @i_modo = 0
   begin
      truncate table ca_eje_xmatriz_tmp 

	     select 
		'eje'=er_eje,
		'cantidad'= count(1)
		into #ejes_grandes
		from ca_eje_rango,ca_eje
		where er_matriz    = @i_matriz
		and   er_eje       = ej_eje
		and   er_matriz    = ej_matriz
		group by er_eje
		having count(1)  > 5
      
    
      insert into ca_eje_xmatriz_tmp  
      select  er_matriz,er_eje,ej_descripcion, er_rango,er_rango_desde, er_rango_hasta,ej_rango
      from ca_eje_rango,ca_eje e
      where er_matriz    = @i_matriz
      and   er_eje       = ej_eje
      and   er_matriz    = ej_matriz
      order by er_eje, er_rango
      ---and not exists (select 1 from  #ejes_grandes  where ej_eje = eje)
      
      set rowcount 20
      select 
	   'Eje'      = rmt_eje,
	   'Descripcion'  = rmt_descripcion,
	   'Rango'        = rmt_rango,
	   'Desde'        = rmt_desde,
	   'Hasta'        = rmt_hasta,   
	   'sec.'         = rmt_secuencial,
	   'Ind.Rango'    = rmt_indicador_rango  
	   from ca_eje_xmatriz_tmp
	   where rmt_matriz    = @i_matriz
	   and   rmt_secuencial > @i_secuencial
	   order by  rmt_secuencial,rmt_eje
	   
	   set rowcount 0  
	   
	
   end
   
   if @i_modo = 1
   begin
       ---print '@i_secuencial ' + cast (@i_secuencial as varchar)
        set rowcount 20
       select 
	   'Eje'      = rmt_eje,
	   'Descripcion'  = rmt_descripcion,
	   'Rango'        = rmt_rango,
	   'Desde'        = rmt_desde,
	   'Hasta'        = rmt_hasta,   
	   'sec.'         = rmt_secuencial,
	   'Ind.Rango'    = rmt_indicador_rango     
	   from ca_eje_xmatriz_tmp
	   where rmt_matriz    = @i_matriz
	   and   rmt_secuencial > @i_secuencial
	   order by  rmt_secuencial ,rmt_eje  
       set rowcount 0
   end
   
   
   
end

--- Consulta Unitaria  

if @i_operacion = 'Q' begin
select
   er_eje,
   er_rango,
   er_rango_desde,
   er_rango_hasta   
   from ca_eje_rango
   where er_matriz    = @i_matriz
   and   er_fecha_vig = @i_fecha_vig
   and   er_eje       = @i_eje
   and   er_rango     = @i_rango
end

if @i_operacion = 'H' begin

   ---print 'ca_eje_Rango @i_indicador ' + cast (@i_indicador as varchar) + '@i_eje: ' + cast (@i_eje as varchar) + '@i_rango_desde' + cast (@i_rango_desde as varchar) + '@i_rango_hasta: ' + cast (@i_rango_hasta as varchar) + '@i_fecha_vig: ' + cast (@i_fecha_vig as varchar)

   if @i_indicador = 'S'
   begin
          ---HAY RANGO DESDE y HASTA
	      if exists (select 1 from ca_eje_rango
	                 where er_matriz = @i_matriz
	                  and   er_fecha_vig = @i_fecha_vig
	                 and   er_eje       = @i_eje
	                 and   er_rango     > 0
	                 and   er_rango_desde   = @i_rango_desde
	                 and   er_rango_hasta   = @i_rango_hasta)
	  begin             
	       select @w_existe = 'S'
	  end
	  else
	  begin
	     select @w_existe = 'N'
	  end
  end 
  ELSE
  begin
          ---SOLO HAY RANGO DESDE
  	      if exists (select 1 from ca_eje_rango
	                 where er_matriz = @i_matriz
	                  and   er_fecha_vig = @i_fecha_vig
	                 and   er_eje       = @i_eje
	                 and   er_rango     >0
	                 and   er_rango_desde   = @i_rango_desde)
	  begin             
	       select @w_existe = 'S'
	  end
	  else
	  begin
	     select @w_existe = 'N'
	  end
  end
  
  select @w_existe
  
end --H

--- Consulta Definitivas  
if @i_operacion = 'T' begin
   exec sp_matriz_pdef
   @s_user      = @s_user,
   @s_date      = @s_date, 
   @s_ofi       = @s_ofi,
   @s_term      = @s_term,
   @i_matriz    = @i_matriz,
   @i_fecha_vig = @i_fecha_vig,
   @i_operacion = @i_operacion 
end

goto FIN

VALIDA_RANGO:
if exists (select 1 from ca_eje
           where ej_matriz = @i_matriz
           and   ej_eje    = @i_eje
           and   ej_rango  = 'S')
begin
   select @w_max_rango = max(ert_rango)
   from ca_eje_rango_tmp
   where ert_matriz    = @i_matriz
   and   ert_fecha_vig = @i_fecha_vig
   and   ert_eje       = @i_eje
   select @w_rei = 1

   while @w_rei < @w_max_rango begin
   
      select @w_rango_hasta = ert_rango_hasta
      from ca_eje_rango_tmp
      where ert_matriz    = @i_matriz
      and   ert_fecha_vig = @i_fecha_vig
      and   ert_eje       = @i_eje
      and   ert_rango     = @w_rei
      
      select @w_rango_desde = ert_rango_desde
      from ca_eje_rango_tmp
      where ert_matriz    = @i_matriz
      and   ert_fecha_vig = @i_fecha_vig
      and   ert_eje       = @i_eje 
      and   ert_rango     = @w_rei + 1          
      print @w_rango_desde
      print @w_rango_hasta
      if @w_rango_hasta <> @w_rango_desde begin
         print 'Error Rango inconsistente. Por Favor Verifique Rango Ingresado o Modificado'
         rollback tran
         return 0
      end
      else begin
         select @w_rei = @w_rei + 1
      end
   end
end
commit tran

FIN:
return 0

go
