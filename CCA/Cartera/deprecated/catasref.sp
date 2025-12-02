/************************************************************************/
/*	Archivo:            catasref.sp                                 */
/*	Stored procedure:   sp_carga_tasa_referencial                   */
/*	Base de datos:      cob_cartera                                 */
/*	Producto:           Cartera                                     */
/*	Disenado por:       Marcelo Poveda (MACOSA)                     */
/*	Fecha de escritura: Marzo 2001                                  */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*                          PROPOSITO                                   */
/*      Obtener la informacion de tablas de tasas referenciales del     */
/*      ADMIN para cargar estructuras actuales de CARTERA               */
/************************************************************************/  
/*                          MODIFICACIONES                              */
/*      FECHA       AUTOR        RAZON                                  */ 
/************************************************************************/ 

use cob_cartera
go
set ansi_nulls off
go

if exists (select 1 from sysobjects where name = 'sp_carga_tasa_referencial')
   drop proc sp_carga_tasa_referencial
go
---INC. 112524 ABR.22.2013
create proc sp_carga_tasa_referencial
@s_date              datetime     = NULL,
@s_ofi               smallint     = NULL,
@s_term              varchar(30)  = NULL,
@s_user              login        = NULL,
@i_tasa              catalogo     = NULL
as
declare
@w_return            int,
@w_sp_name           descripcion,
@w_tr_tasa           catalogo,
@w_tr_descripcion    descripcion,
@w_tr_estado         catalogo,
@w_pi_cod_pizarra    int,
@w_pi_modalidad      char(1),
@w_pi_caracteristica char(1),
@w_pi_periodo        smallint,
@w_pi_valor          float,
@w_pi_fecha_inicio   datetime,
@w_td_dividendo      catalogo,
@w_ca_estado         catalogo,
@w_rowcount          int,
@w_error             int,
@w_factor            smallint,
@w_tperiodo          smallint,
@w_periodo           smallint

--- INICIALIZACION DE VARIABLES 
select 
@s_date    = isnull(@s_date, getdate()),
@s_term    = isnull(@s_term, 'consola'),
@s_user    = isnull(@s_user, 'cartera'),
@s_ofi     = isnull(@s_ofi, 0),
@w_sp_name = 'catasref.s'


--- CURSOR DE CATALOGO DE TASAS 
declare cursor_tasas cursor for
/*select 
tr_tasa, 
tr_descripcion, 
tr_estado
from   cobis..te_tasas_referenciales
where  (tr_tasa = @i_tasa or @i_tasa is null)
for read only
*/
SELECT
b.codigo,
b.valor,
b.estado
FROM cobis..cl_tabla a, cobis..cl_catalogo b
where a.codigo = b.tabla
and   a.tabla = 'te_tasa_referencia' 
and   estado = 'V'
AND  (b.codigo = @i_tasa or @i_tasa is null)
for read only

open cursor_tasas

fetch cursor_tasas into 
@w_tr_tasa, 
@w_tr_descripcion, 
@w_tr_estado

while @@fetch_status = 0 begin

   --- INICIALIZACION DE VARIABLES 
   select @w_pi_cod_pizarra = 0,
   @w_td_dividendo = 'D'

   --- ACTUALIZACION TABLA CARTERA 
   if @w_tr_estado <> 'V' begin
      update cob_cartera..ca_tasa_valor
      set    tv_estado = @w_tr_estado
      where  tv_nombre_tasa = @w_tr_tasa

      goto SIGUIENTE
   end

   --- CONSULTAR EN CARACTERISTICA DE TASA 
   select @w_ca_estado = ca_estado
   from   cobis..te_caracteristicas_tasa
   where  ca_tasa      = @w_tr_tasa
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 
   goto SIGUIENTE

   
   if @w_ca_estado <> 'V' begin
      update cob_cartera..ca_tasa_valor
      set    tv_estado = @w_ca_estado
      where  tv_nombre_tasa = @w_tr_tasa

      goto SIGUIENTE    
   end

   --- SELECCION CARACTERISTICAS DE TASAS 
   select @w_pi_cod_pizarra = max(pi_cod_pizarra)
   from   cobis..te_tpizarra
   where  pi_referencia   = @w_tr_tasa
   set transaction isolation level read uncommitted

   if @w_pi_cod_pizarra = 0 or @w_pi_cod_pizarra is null  
      goto SIGUIENTE

   select @w_pi_modalidad        = pi_modalidad,
          @w_pi_caracteristica   = pi_caracteristica,
          @w_pi_periodo          = pi_periodo,
          @w_pi_valor            = pi_valor,
          @w_pi_fecha_inicio     = pi_fecha_inicio
   from   cobis..te_tpizarra
   where  pi_cod_pizarra = @w_pi_cod_pizarra
   and    pi_referencia  = @w_tr_tasa
   set transaction isolation level read uncommitted
   
   --- CARACTERISTICA EFECTIVA 
   if @w_pi_caracteristica = 'E'
      select @w_pi_modalidad = 'V'   
   
   select 
   @w_tperiodo = ca_periodo,
   @w_periodo  = ca_num_periodo
   from cobis..te_caracteristicas_tasa
   where ca_tasa = @w_tr_tasa
   
   if @@rowcount = 0 begin
      select  @w_error = 724527
      goto ERROR
   end 
   
   --select @w_factor = case 
   --                   when @w_tperiodo = '1'  then 360
   --                   when @w_tperiodo = '2'  then  60
   --                   when @w_tperiodo = '3'  then  90
   --                   when @w_tperiodo = '4'  then  120
   --                   when @w_tperiodo = '5'  then  150
   --                   when @w_tperiodo = '6'  then 180
   --                   when @w_tperiodo = '7'  then 210
   --                   when @w_tperiodo = '8'  then 240
   --                   when @w_tperiodo = '9'  then 270
   --                   when @w_tperiodo = '10'  then 300
   --                   when @w_tperiodo = '11'  then 330
   --                   when @w_tperiodo = '12' then  30
   --                   else -1
   --                   end

   select @w_factor = -1 
   if @w_tperiodo = '1' 
      select @w_factor = 360 
   if @w_tperiodo = '2'  
      select @w_factor = 60
   if @w_tperiodo = '3'  
      select @w_factor = 90
   if @w_tperiodo = '4'  
      select @w_factor = 120
   if @w_tperiodo = '5'  
      select @w_factor = 150
   if @w_tperiodo = '6'  
      select @w_factor = 180
   if @w_tperiodo = '7'  
      select @w_factor = 210
   if @w_tperiodo = '8'  
      select @w_factor = 240
   if @w_tperiodo = '9' 
      select @w_factor = 270
   if @w_tperiodo = '10'
      select @w_factor = 300
   if @w_tperiodo = '11'
      select @w_factor = 330
   if @w_tperiodo = '12' 
      select @w_factor = 30
   
   if @w_factor = -1 begin
      print '@w_factor 1   ' + cast (@w_factor as varchar) + 'periodos : ' +  cast ( @w_periodo as varchar) +  ' @w_tperiodo ' + cast (@w_tperiodo as varchar)
      select @w_error = 724525 --tipo de tipo de periodo no reconocido en cartera
      goto ERROR
   end 
         
   --- CONVERTIR PERIODO A CODIGOS DE CARTERA 
   select @w_td_dividendo = td_tdividendo
   from   cob_cartera..ca_tdividendo
   where  td_factor = @w_factor 
   ---and    td_estado = 'V' puede estar bloqueadopar autilizarlo de nuevo pero para las tasas credas dee permitir laconversion

   if @@rowcount = 0 begin
      print '@w_factor 2   ' + cast (@w_factor as varchar) + 'periodos : ' +  cast ( @w_periodo as varchar)
      select @w_error = 724525 --tipo de periodo no parametrizado en la tabla de tipos de dividendos (ca_tdividendo)
      goto ERROR
   end 

   --- ACTUALIZAR CA_TASA_VALOR 
   if exists (select 1 from cob_cartera..ca_tasa_valor
   where  tv_nombre_tasa = @w_tr_tasa)
      update cob_cartera..ca_tasa_valor
      set    tv_modalidad      = @w_pi_modalidad,
             tv_periodicidad   = @w_td_dividendo,
             tv_tipo_tasa      = @w_pi_caracteristica,
             tv_estado         = @w_tr_estado
      where  tv_nombre_tasa    = @w_tr_tasa
   else
      insert cob_cartera..ca_tasa_valor values
      (@w_tr_tasa,     @w_tr_descripcion, @w_pi_modalidad,
       @w_td_dividendo,@w_tr_estado,      @w_pi_caracteristica)


   declare cursor_referenciales cursor for
   select 
   pi_valor, 
   pi_fecha_inicio
   from   cobis..te_tpizarra
   where  pi_referencia = @w_tr_tasa 
   for read only

   open cursor_referenciales 

   fetch cursor_referenciales into 
   @w_pi_valor,
   @w_pi_fecha_inicio

   while @@fetch_status = 0 begin

      delete cob_cartera..ca_cambios_treferenciales
      where ct_fecha_ing    = @w_pi_fecha_inicio
      and   ct_referencial  = @w_tr_tasa
      and   ct_valor        = @w_pi_valor
   
      insert into cob_cartera..ca_cambios_treferenciales (
      ct_fecha_ing,
      ct_referencial,
      ct_valor
      )
      values 
      (
      @w_pi_fecha_inicio,
      @w_tr_tasa,
      @w_pi_valor
      )

      ---- INSERTAR VALORES EN CA_VALOR_REFERENCIAL 
      exec sp_valor_referencial
      @s_user          = @s_user,
      @s_date          = @s_date,
      @s_ofi           = @s_ofi,
      @s_term          = @s_term,
      @i_operacion     = 'I',
      @i_tipo          = @w_tr_tasa,
      @i_fecha_vig     = @w_pi_fecha_inicio,
      @i_valor         = @w_pi_valor,
      @i_formato_fecha = 111

      fetch cursor_referenciales  into 
      @w_pi_valor,
      @w_pi_fecha_inicio
   end
   close cursor_referenciales 
   deallocate cursor_referenciales 

   SIGUIENTE:
   fetch cursor_tasas into 
   @w_tr_tasa, 
   @w_tr_descripcion,
   @w_tr_estado
end
close cursor_tasas
deallocate cursor_tasas

return 0

ERROR:

exec cobis..sp_cerror
     @t_debug = 'N',
     @t_from  = @w_sp_name,
     @i_num   = @w_error
   
return @w_error

go

