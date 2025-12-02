/************************************************************************/
/*      Archivo:                insreaju.sp                             */
/*      Stored procedure:       sp_insertar_reajustes                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           P. Narvaez                              */
/*      Fecha de escritura:     17/12/1997                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Mantenimiento de Reajueste                                      */
/*      SEP 2006        FQ              Optimizacion 152                */
/*      01/Dic/2006     E. Pelaez       defecto -7536 BAC		         */
/*      ENE-31-2007     EPB             NR-684                          */
/*      feb-2007             Elcira Pelaez       def. 7935 BAC          */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_insertar_reajustes')
   drop proc sp_insertar_reajustes
go
---TIKET 167070 Mayo 2015
create proc sp_insertar_reajustes
@s_date                 datetime,
@s_ofi                  int,
@s_term                 varchar(30),
@s_user                 login,
@i_banco                cuenta    = null,
@i_especial             char(1)   = null,
@i_fecha_reajuste       datetime  = null,
@i_concepto             catalogo  = null,
@i_referencial          catalogo  = null,
@i_signo                char(1)   = null,
@i_factor               float     = null,
@i_porcentaje           float     = null,
@i_desagio              char(1)   = 'N'
as
declare 
   @w_return            int ,
   @w_operacionca       int ,
   @w_sp_name           descripcion,
   @w_secuencial        int,
   @w_concepto          catalogo,
   @w_factor_int        int,
   @w_longitud          varchar,
   @w_estado_op         smallint

-- VARIABLES INICIALES
select @w_sp_name = 'sp_insertar_reajustes'

---DEF-7536
-- DATOS GENERALES DEL PRESTAMO

select @w_factor_int = convert(int,@i_factor)

if  datalength(convert(varchar,@w_factor_int)) > 2
    return 710402

select @w_operacionca = op_operacion,
       @w_estado_op   = op_estado
from   ca_operacion with (nolock)
where  op_banco       = @i_banco

if @w_estado_op = 4
begin
  PRINT 'ATENCION Operacion en estado CASTIGADO no puede tener Reajuste de Tasa'
  return 701010
end 

select @w_secuencial = re_secuencial
from   ca_reajuste with (nolock)
where  re_operacion  = @w_operacionca
and    re_fecha     =  @i_fecha_reajuste


if @w_secuencial is null -- INSERCION
begin
   -- GENERACION DEL SECUENCIAL DE REAJUSTE
   exec @w_secuencial = sp_gen_sec
        @i_operacion  = @w_operacionca
   
   insert into ca_reajuste with (rowlock)
         (re_secuencial,         re_operacion,     re_fecha,
          re_reajuste_especial,  re_desagio)
   values(@w_secuencial,         @w_operacionca,   @i_fecha_reajuste,
          @i_especial,           @i_desagio) 
   
   if @@error <> 0
      return 710045
   
   -- INSERCION DEL DETALLE DE REAJUSTE
    
   insert into ca_reajuste_det with (rowlock)
         (red_secuencial,  red_operacion,    red_concepto,  red_referencial,
          red_signo,       red_factor,       red_porcentaje)
   values(@w_secuencial,   @w_operacionca,   @i_concepto,   @i_referencial,
          @i_signo,        @i_factor,        @i_porcentaje )
   
   if @@error <> 0
      return 710046

   --NR-684 Para control de lo insertado

   if @s_date is not null and @s_user is not null and @s_ofi is not null and @s_term is not null 
   begin
      insert into ca_reajuste_ts with (rowlock)
      select @s_date, getdate(), @s_user, @s_ofi, @s_term, RE.*
      from   ca_reajuste RE with (nolock)
      where  re_operacion  = @w_operacionca
      and    re_secuencial = @w_secuencial
      
      if @@error <> 0
         return 710048
   end 
   ELSE
     PRINT 'insreaju.sp Error insertando en ca_reajuste_ts'
      
end
ELSE
begin-- MODIFICACION
   update ca_reajuste with (rowlock)
   set    re_reajuste_especial = @i_especial
   where  re_secuencial        = @w_secuencial
   and    re_operacion         = @w_operacionca
   
   if @@error <> 0
      return 710041
   
   -- CHEQUEAR SI EXISTE YA UN REGISTRO PARA EL NUEVO CONCEPTO
   select @w_concepto = red_concepto
   from   ca_reajuste_det with (nolock)
   where  red_secuencial  = @w_secuencial
   and    red_operacion   = @w_operacionca
   and    red_concepto    = @i_concepto
   
   if @w_concepto is null
   begin
      insert into ca_reajuste_det with (rowlock)
            (red_secuencial, red_operacion,  red_concepto, red_referencial,
             red_signo,      red_factor,     red_porcentaje)
      values(@w_secuencial,  @w_operacionca, @i_concepto, @i_referencial,
             @i_signo,       @i_factor,      @i_porcentaje)
   end
   ELSE
   begin 
      -- MODIFICACION DEL DETALLE DE REAJUSTE
      update ca_reajuste_det with (rowlock)
      set    red_referencial   = @i_referencial,
             red_signo         = @i_signo,
             red_factor        = @i_factor,
             red_porcentaje    = @i_porcentaje
      where  red_secuencial = @w_secuencial
      and    red_operacion  = @w_operacionca
      and    red_concepto   = @w_concepto
      
      if @@error <> 0
         return 710046
   end
end

return 0

go
