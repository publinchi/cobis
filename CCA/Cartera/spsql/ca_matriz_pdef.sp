/************************************************************************/
/*   Archivo:              ca_matriz_pdef.sp                            */
/*   Stored procedure:     sp_matriz_pdef                               */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         RRB                                          */
/*   Fecha de escritura:   Febrero/2009                                 */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Paso a tablas definitivas de una Matriz Dimensional                */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_matriz_pdef')
   drop proc sp_matriz_pdef
go

create proc sp_matriz_pdef
@s_date       datetime,
@s_user       login,
@s_ofi        smallint,
@s_term       varchar(30),  
@t_debug      char(1) = 'N',
@t_file       varchar(10) = null,
@t_from       varchar(32) = null,
@i_matriz     catalogo,
@i_fecha_vig  smalldatetime,
@i_operacion  char(1)
as
declare 
@w_error      int,
@w_sp_name    descripcion

select @w_sp_name = 'sp_matriz_pdef'

/* PASO ca_matriz */

delete ca_matriz
where ma_matriz = @i_matriz
and   ma_fecha_vig = @i_fecha_vig

if @@error != 0 begin
   select @w_error = 707072
   goto ERROR
end       
   
insert into ca_matriz
select * from ca_matriz_tmp
where mat_matriz = @i_matriz
and   mat_fecha_vig = @i_fecha_vig

if @@rowcount = 0  begin
   select @w_error = 703123
   goto ERROR
end    

/* PASO ca_eje */

delete ca_eje
where ej_matriz = @i_matriz
and   ej_fecha_vig = @i_fecha_vig

if @@error != 0 begin
   select @w_error = 707073
   goto ERROR
end 

insert into ca_eje
select * from ca_eje_tmp
where ejt_matriz    = @i_matriz
and   ejt_fecha_vig = @i_fecha_vig

if @@rowcount = 0 begin      
   select @w_error = 703124
   goto ERROR
end                        

/* PASO ca_eje_rango */

delete ca_eje_rango
where er_matriz = @i_matriz
and   er_fecha_vig = @i_fecha_vig

if @@error != 0 begin
   select @w_error = 707074
   goto ERROR
end 

insert into ca_eje_rango
select * from ca_eje_rango_tmp
where ert_matriz    = @i_matriz
and   ert_fecha_vig = @i_fecha_vig

if @@rowcount = 0 begin      
   select @w_error = 703125
   goto ERROR
end                        

/* PASO ca_matriz_valor */

delete ca_matriz_valor
where mv_matriz = @i_matriz
and   mv_fecha_vig = @i_fecha_vig

if @@error != 0 begin
   select @w_error = 707075
   goto ERROR
end 

insert into ca_matriz_valor
select * from ca_matriz_valor_tmp
where mvt_matriz    = @i_matriz
and   mvt_fecha_vig = @i_fecha_vig

if @@rowcount = 0 begin
   select @w_error = 703126
   goto ERROR
end    
-- TRANSACCION DE SERVICIO 
   exec @w_error  = sp_tran_servicio
   @s_user      = @s_user,
   @s_date      = @s_date, 
   @s_ofi       = @s_ofi,
   @s_term      = @s_term,
   @i_tabla     = 'matriz', 
   @i_clave1    = @i_matriz, 
   @i_clave2    = @i_fecha_vig,
   @i_clave3    = @i_operacion
   
   if @w_error != 0 begin
      exec cobis..sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = @w_error
   end

return 0

ERROR:
return @w_error


go
