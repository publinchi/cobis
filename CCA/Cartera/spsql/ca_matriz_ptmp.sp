/************************************************************************/
/*   Archivo:              ca_matriz_ptmp.sp                            */
/*   Stored procedure:     sp_matriz_ptmp                               */
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
/*   Paso a tablas temporales de una Matriz Dimensional                 */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_matriz_ptmp')
   drop proc sp_matriz_ptmp
go

create proc sp_matriz_ptmp
@i_matriz       catalogo,
@i_fecha_vig    smalldatetime
as
declare 
@w_error         int,
@w_sp_name       descripcion,
@w_eje		     int,
@w_rangos        int,
@w_rangos1       int,
@w_rangos2       int,
@w_rangos3       int,
@w_rangos4       int,
@w_rangos5       int,
@w_rangos6       int,
@w_rangos7       int,
@w_rangos8       int,
@w_rangos9       int,
@w_rangos10       int,
@w_rangos11       int,
@w_rangos12       int,
@w_rangos13       int,
@w_rangos14       int,
@w_rangos15       int,

@w_rangos_1      int,
@w_rangos_2      int,
@w_rangos_3      int,
@w_rangos_4      int,
@w_rangos_5      int,
@w_rangos_6      int,
@w_rangos_7      int,
@w_rangos_8      int,
@w_rangos_9      int,
@w_rangos_10      int,
@w_rangos_11      int,
@w_rangos_12      int,
@w_rangos_13      int,
@w_rangos_14      int,
@w_rangos_15      int,

@w_rango_1       int,
@w_rango_2       int,
@w_rango_3       int,
@w_rango_4       int,
@w_rango_5       int,
@w_rango_6       int,
@w_rango_7       int,
@w_rango_8       int,
@w_rango_9       int,
@w_rango_10       int,
@w_rango_11       int,
@w_rango_12       int,
@w_rango_13       int,
@w_rango_14       int,
@w_rango_15       int,

@w_ejes_rangos   int,
@w_ejes_rangos_1 int, 
@w_repeticiones  int,
@w_repet_cont    int
 
select @w_sp_name = 'sp_matriz_ptmp'

create table #ejes_rangos
(
eje		        tinyint null,
rangos          int     null,
repeticiones    int     null
)

/* PASO ca_matriz */

delete ca_matriz_tmp
where mat_matriz = @i_matriz
and   mat_fecha_vig = @i_fecha_vig

if @@error <> 0 begin
   select @w_error = 707076
   goto ERROR
end       
   
insert into ca_matriz_tmp
select * from ca_matriz
where ma_matriz = @i_matriz
and   ma_fecha_vig = @i_fecha_vig

if @@rowcount = 0  begin
   select @w_error = 703127
   goto ERROR
end    

/* PASO ca_eje */

delete ca_eje_tmp
where ejt_matriz = @i_matriz
and   ejt_fecha_vig = @i_fecha_vig

if @@error <> 0 begin
   select @w_error = 707077
   goto ERROR
end 

insert into ca_eje_tmp
select * from ca_eje
where ej_matriz    = @i_matriz
and   ej_fecha_vig = @i_fecha_vig

if @@rowcount = 0 begin      
   select @w_error = 703128
   goto ERROR
end                        

/* PASO ca_eje_rango */

delete ca_eje_rango_tmp
where ert_matriz = @i_matriz
and   ert_fecha_vig = @i_fecha_vig

if @@error <> 0 begin
   select @w_error = 707078
   goto ERROR
end 

insert into ca_eje_rango_tmp
select * from ca_eje_rango
where er_matriz    = @i_matriz
and   er_fecha_vig = @i_fecha_vig

if @@rowcount = 0 begin      
   select @w_error = 703129
   goto ERROR
end                        

/* PASO ca_matriz_valor */

delete ca_matriz_valor_tmp
where mvt_matriz = @i_matriz
and   mvt_fecha_vig = @i_fecha_vig

if @@error <> 0 begin
   select @w_error = 707079
   goto ERROR
end 


insert into ca_matriz_valor_tmp
select * from ca_matriz_valor
where  mv_matriz    = @i_matriz
and    mv_fecha_vig = @i_fecha_vig

if @@rowcount = 0 begin      
   select @w_error = 703130
   goto ERROR
end                        

return 0

ERROR:
return @w_error


go

