/************************************************************************/
/*  Archivo:                        tabrango.sp                         */
/*  Stored procedure:               sp_tabla_rango                      */
/*  Base de datos:                  cob_cartera                         */
/*  Producto:                       Cobis CARTERA                       */
/*  Disenado por:                   Patricio Navaez                     */
/*  Fecha de escritura:             25-Jul-1997                         */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA"                                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*                                  PROPOSITO                           */
/*  Este programa procesa operaciones de mantenimiento de los rangos    */
/*      que manejan ciertos rubros.                                     */ 
/*  I: Creacion del registro de tipos de datos                          */
/*  U: Actualizacion del registro de tipos de datos                     */
/*  D: Eliminacion del registro de tipos de datos                       */
/*  S: Busqueda del registro de tipos de datos                          */
/*  Q: Consulta del registro de tipos de datos                          */
/************************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_tabla_rango')
   drop proc sp_tabla_rango
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_tabla_rango (
       @t_debug        char(1)     = 'N',
       @t_file         varchar(10) = null,
       @t_from         varchar(32) = null,
       @i_operacion    char(2),
       @i_modo         tinyint     = null,
       @i_concepto     catalogo    = null,
       @i_secuencial   int         = 0,    
       @i_valor1min    money       = null,
       @i_valor1max    money       = null,
       @i_valor2min    money       = null,
       @i_valor2max    money       = null,
       @i_tabla        tinyint     = null, 
       @i_tasa         float       = null,
       @i_valor1       money       = null,
       @i_valor2       money       = null,
       @i_variable     catalogo    = null,
       @i_tipovalor    char(1)     = null,
       @i_valor        money       = null,
       @o_tasa         float       = null out
)
as
declare @w_sp_name              varchar(32),
        @w_return               int,
        @w_siguiente            int,
        @w_repeticiones         tinyint,
        @w_repeticiones2        tinyint,
        @w_secuencial           int, 
        @w_concepto             catalogo, 
        @w_valor1_min           money,
        @w_valor1_max           money,
        @w_valor2_min           money,
        @w_valor2_max           money,
        @w_tasa                 float,
        @w_num_dec              tinyint,
        @w_error                int,
        @w_parametro_fag        catalogo,
        @w_bandera              char(1),
        @w_desbloqueo           char(10),
        @w_activo               char(1)

select @w_sp_name = 'sp_tabla_rango'

/* PARAMETROS GENERALES PARA COMISION FAG*/

select @w_parametro_fag = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and pa_nemonico = 'COMFAG'
set transaction isolation level read uncommitted


/** INSERT **/
if @i_operacion = 'I'
begin
   if @i_concepto =  @w_parametro_fag  and @i_variable is null   begin
   select @w_error = 710369
   goto ERROR
end

/* VERIFICO QUE EXISTA CONCEPTO EN LA DEFINICION DE LAS TABLAS*/
if not exists (select 1 from cob_cartera..ca_campos_tablas_rubros
               where ct_concepto = @i_concepto)
begin
   select @w_error = 710060
   goto ERROR
end
   
if @i_tabla = 1    /*SI POSEE UN SOLO RANGO*/
begin
/* CONTROL QUE LOS RANGOS NO SE REPITAN */
   if exists (select 1
              from  ca_tablas_un_rango
              where tur_concepto   = @i_concepto
              and   tur_valor_min  >= @i_valor1min
              and   tur_valor_min  <= @i_valor1max)              
         	  or exists (select 1
                         from  ca_tablas_un_rango
                         where tur_concepto   =  @i_concepto
                         and   tur_valor_min  <= @i_valor1min
                         and   tur_valor_max  >= @i_valor1min)
   begin
      select @w_error = 710064
      goto ERROR
   end

   select @w_siguiente = isnull(max(tur_secuencial),0)  + 1
   from ca_tablas_un_rango

   /* INSERT A CA_TABLAS UN RANGO */
   begin tran
      insert into ca_tablas_un_rango (
      	     tur_secuencial, tur_concepto, tur_valor_min,
      	     tur_valor_max,  tur_tasa,     tur_tipo,
      	     tur_valor)
      values (@w_siguiente,  @i_concepto,  @i_valor1min,
             @i_valor1max,   @i_tasa,      @i_tipovalor,
             @i_valor)
             
      if @@error != 0
      begin
         select @w_error = 710065
         goto ERROR
      end
   commit tran
end
   
else                     /*SI POSEE DOS RANGOS*/
if @i_tabla = 2 
begin
   select @w_repeticiones = 0
   /* CONTROL QUE LOS RANGOS NO SE REPITAN */
   if exists (select 1
              from  ca_tablas_dos_rangos
              where tdr_concepto    =  @i_concepto
              and   tdr_valor1_min  >= @i_valor1min
              and   tdr_valor1_min  <= @i_valor1max
              and   tdr_valor2_min  >= @i_valor2min
              and   tdr_valor2_min  <= @i_valor2max)
              and   @i_concepto     <> @w_parametro_fag
              or exists (select 1
                         from  ca_tablas_dos_rangos
                         where tdr_concepto    =  @i_concepto
                         and   tdr_valor1_min  >= @i_valor1min
                         and   tdr_valor1_min  <= @i_valor1max
                         and   tdr_valor2_min  <= @i_valor2min
                         and   tdr_valor2_max  >= @i_valor2min)
                         and   @i_concepto     <> @w_parametro_fag
              or exists (select 1
              from   ca_tablas_dos_rangos
              where  tdr_concepto     = @i_concepto
              and    tdr_valor1_min  <= @i_valor1min
              and    tdr_valor1_max  >= @i_valor1min
              and    tdr_valor2_min  >= @i_valor2min
              and    tdr_valor2_min  <= @i_valor2max)
              and    @i_concepto     <> @w_parametro_fag
              or exists (select 1
                         from  ca_tablas_dos_rangos
                         where tdr_concepto     = @i_concepto
                         and   tdr_valor1_min  <= @i_valor1min
                         and   tdr_valor1_max  >= @i_valor1min
                         and   tdr_valor2_min  <= @i_valor2min
                         and   tdr_valor2_max  >= @i_valor2min)
                         and   @i_concepto     <> @w_parametro_fag
   begin
      select @w_error = 710064
      goto ERROR
   end

   select @w_siguiente =  isnull(max(tdr_secuencial),0)  + 1
   from ca_tablas_dos_rangos

   /* INSERT A CA_TABLAS_DOS_RANGOS */
   begin tran
      insert into ca_tablas_dos_rangos (
             tdr_secuencial, tdr_concepto,   tdr_valor1_min,
             tdr_valor1_max, tdr_valor2_min, tdr_valor2_max,
             tdr_tasa,       tdr_variable)
      values (@w_siguiente,  @i_concepto,    @i_valor1min,
              @i_valor1max,  @i_valor2min,   @i_valor2max,
              @i_tasa,       @i_variable)
      if @@error != 0
      begin
         select @w_error = 710065
         goto ERROR
      end

   commit tran
   end
end

/** UPDATE **/

if @i_operacion = 'U'
begin
   /* VERIFICO QUE EXISTA CONCEPTO EN LA DEFINICION DE LAS TABLAS*/
   if not exists (select 1 from cob_cartera..ca_campos_tablas_rubros
                  where ct_concepto = @i_concepto)
   begin
      select @w_error = 710057
      goto ERROR
   end

   if @i_tabla = 1    /*SI POSEE UN SOLO RANGO*/
   begin
      /* UPDATE A CA_TABLAS_UN_RANGO */
      begin tran

      update ca_tablas_un_rango set
      tur_valor_min = @i_valor1min,
      tur_valor_max = @i_valor1max,
      tur_tasa      = @i_tasa,
      tur_tipo      = @i_tipovalor,
      tur_valor     = @i_valor
      where  tur_concepto   = @i_concepto 
      and    tur_secuencial = @i_secuencial

      if @@error != 0
      begin
         select @w_error = 710066
         goto ERROR
      end
      
      /* CONTROL QUE LOS RANGOS NO SE REPITAN */
      if exists (select 1
                 from  ca_tablas_un_rango
                 where tur_concepto   = @i_concepto
                 and   tur_secuencial <> @i_secuencial
                 and   tur_valor_min  >= @i_valor1min
                 and   tur_valor_min  <= @i_valor1max)
      			 or exists (select 1
                            from  ca_tablas_un_rango
                            where tur_concepto   = @i_concepto
                            and   tur_secuencial <> @i_secuencial
                            and   tur_valor_min  <= @i_valor1min
                            and   tur_valor_max  >= @i_valor1min)
      begin
         select @w_error = 710064
         goto ERROR
      end

      commit tran
   end
else                     /*SI POSEE DOS RANGOS*/
begin
   /* UPDATE A CA_TABLAS_DOS_RANGOS */
   begin tran
   update ca_tablas_dos_rangos set
   tdr_valor1_min   = @i_valor1min,
   tdr_valor1_max   = @i_valor1max,
   tdr_valor2_min   = @i_valor2min,
   tdr_valor2_max   = @i_valor2max,
   tdr_tasa         = @i_tasa,
   tdr_variable     = @i_variable
   where tdr_concepto   = @i_concepto   and   
         tdr_secuencial = @i_secuencial
         
   if @@error != 0
   begin
      select @w_error = 710066
      goto ERROR
   end

   /* CONTROL QUE LOS RANGOS NO SE REPITAN */
   if exists (select 1
              from   ca_tablas_dos_rangos
              where  tdr_concepto   = @i_concepto
                 and    tdr_secuencial <> @i_secuencial
                 and    tdr_valor1_min  >= @i_valor1min
                 and    tdr_valor1_min  <= @i_valor1max
                 and    tdr_valor2_min  >= @i_valor2min
                 and    tdr_valor2_min  <= @i_valor2max)
                 and    @i_concepto  <> @w_parametro_fag
                 or exists (select 1
                            from   ca_tablas_dos_rangos
                            where  tdr_concepto   = @i_concepto
                            and    tdr_secuencial <> @i_secuencial
                            and    tdr_valor1_min  >= @i_valor1min
                            and    tdr_valor1_min  <= @i_valor1max
                            and    tdr_valor2_min  <= @i_valor2min
                            and    tdr_valor2_max  >= @i_valor2min)
                            and    @i_concepto  <> @w_parametro_fag
      			 or exists (select 1
      			           from   ca_tablas_dos_rangos
      			           where  tdr_concepto   = @i_concepto
      			           and    tdr_secuencial <> @i_secuencial
      			           and    tdr_valor1_min  <= @i_valor1min
      			           and    tdr_valor1_max  >= @i_valor1min
      			           and    tdr_valor2_min  >= @i_valor2min
      			           and    tdr_valor2_min  <= @i_valor2max)
      			           and    @i_concepto  <> @w_parametro_fag
      			 or exists (select 1
      			           from   ca_tablas_dos_rangos
      			           where  tdr_concepto   = @i_concepto
      			           and    tdr_secuencial <> @i_secuencial
      			           and    tdr_valor1_min  <= @i_valor1min
      			           and    tdr_valor1_max  >= @i_valor1min
      			           and    tdr_valor2_min  <= @i_valor2min
      			           and    tdr_valor2_max  >= @i_valor2min)
      			           and    @i_concepto  <> @w_parametro_fag
      begin
         select @w_error = 710064
         goto ERROR
      end

   commit tran
end
end

/** Eliminacion **/

if @i_operacion = 'D'
begin
   /* ELIMINACION DE CONCEPTO */
   if @i_modo = 0
   begin
      begin tran
      delete   ca_tablas_un_rango
      where    tur_concepto   = @i_concepto
      and      tur_secuencial = @i_secuencial  

      if @@error != 0
      begin
         select @w_error = 710067
         goto ERROR
      end

      commit tran
   end
   else
   if @i_modo = 1 
   begin
      begin tran
      delete   ca_tablas_dos_rangos
      where    tdr_concepto   = @i_concepto
      and      tdr_secuencial = @i_secuencial  

      if @@error != 0
      begin
         select @w_error = 710067
         goto ERROR
      end  
      commit tran 
   end
end

/** Search **/
if @i_operacion = 'S'
begin

   select @i_secuencial = isnull(@i_secuencial,0)

   /*DESCRIPCION DEL CONCEPTO*/ 
   select   co_descripcion
   from     cob_cartera..ca_concepto
   where    co_concepto = @i_concepto

   /*NUMERO DE DECIMALES QUE MANEJA CARTERA*/
   select @w_num_dec = pa_tinyint
   from cobis..cl_parametro
   where pa_nemonico = 'NDE'
   and pa_producto   = 'CCA'
   set transaction isolation level read uncommitted   

   select @w_num_dec

   --print '..@w_parametro_fag...%1!',@w_parametro_fag
   --print '..@i_concepto...%1!',@i_concepto
 
   if @w_parametro_fag = @i_concepto
   select @w_bandera = 'S'

   select @w_bandera   --'S': el rubro es COMISION FAG
    
   select @w_desbloqueo = pa_char 
   from cobis..cl_parametro
   where pa_nemonico = 'DSBLQ'
   and pa_producto = 'CCA'
   
   if @w_desbloqueo = @i_concepto  
   select @w_activo = 'S'
   
   select @w_activo
    
   if @i_modo = 0 /*TABLAS DE UN RANGO*/
   begin   
      select 
      tur_secuencial,
      tur_concepto,
      tur_valor_min,
      tur_valor_max,
      Tasa = convert(money,round(tur_tasa,@w_num_dec)),
      Tipo = tur_tipo,
      Valor = tur_valor       
      from   ca_tablas_un_rango
      where  tur_concepto = @i_concepto
      and    tur_secuencial > @i_secuencial /*BOTON SIGUIENTE*/
      order by tur_secuencial

      if @@rowcount = 0
      begin
         select @w_error = 710068
         goto ERROR
      end

   end 

   if @i_modo = 1 /*TABLAS DE DOS COLUMNAS DE RANGOS*/
   begin
     
      set rowcount  30             
      select
      tdr_secuencial,
      tdr_concepto,
      tdr_valor1_min,
      tdr_valor1_max,
      tdr_valor2_min,
      tdr_valor2_max,
      tdr_tasa,
      tdr_variable
      from  ca_tablas_dos_rangos
      where tdr_concepto = @i_concepto 
      --and tdr_variable = @i_variable
      and tdr_secuencial > @i_secuencial
      order by tdr_secuencial  
      set rowcount 0
      select 30
   end
end

/** Query **/        
if @i_operacion = 'Q'
begin
   if @i_valor2 is null
      /* EXTRAER LA TASA DE LA TABLA DE UN ELEMENTO */
      select @o_tasa = tur_tasa
      from   ca_tablas_un_rango
      where  tur_concepto   = @i_concepto
      and    tur_valor_min <= @i_valor1
      and    tur_valor_max >= @i_valor1
   else
      /* EXTRAER LA TASA DE LA TABLA DE DOS ELEMENTOS */
      select @o_tasa = tdr_tasa
      from   ca_tablas_dos_rangos
      where  tdr_concepto   = @i_concepto
      and    tdr_valor1_min <= @i_valor1
      and    tdr_valor1_max >= @i_valor1
      and    tdr_valor2_min <= @i_valor2
      and    tdr_valor2_max >= @i_valor2

   if @o_tasa is null
   begin
      select @w_error = 710068
      goto ERROR
   end
end

set rowcount 0

return 0
ERROR:
exec cobis..sp_cerror
@t_debug = 'N',         
@t_file = null,
@t_from  = @w_sp_name,   
@i_num = @w_error
--@i_cuenta= ' '

return @w_error
