/************************************************************************/
/*   Archivo:              decoder.sp                                   */
/*   Stored procedure:     sp_decodificador                             */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         RGA  FDLT                                    */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Descompone en un tabla una cadena de caracteres                    */
/************************************************************************/  
/*                          ODIFICACIONES                               */
/*   FECHA                      AUTOR           RAZON                   */
/*   ENE-31-2007               EPB              NR-684                  */
/*   MAY-18/2022               KDR        Se comenta recálculo de Seguro*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_decodificador')
   drop proc sp_decodificador
go

create proc sp_decodificador
   @s_date              datetime,
   @s_ofi               int,
   @s_term              varchar(30),
   @s_user              login,
   @s_sesn              int,
   @t_trn               INT          = NULL,
   @i_operacion         int,
   @i_fila              int          = 1,
   @i_accion            char(1)      = null,
   @i_causacion         char(1)      = 'L',
   @i_concepto          catalogo     = null,
   @i_fecha_ini         datetime     = null,
   @i_dias_anio         smallint     = 360,
   @i_formato_fecha     int          = 101,
   @i_str1              varchar(255) = '',
   @i_str2              varchar(255) = '',
   @i_str3              varchar(255) = '',
   @i_str4              varchar(255) = '',
   @i_str5              varchar(255) = '',
   @i_str6              varchar(255) = '',
   @i_str7              varchar(255) = '',
   @i_str8              varchar(255) = '',
   @i_str9              varchar(255) = '',
   @i_str10             varchar(255) = '',
   @i_reestructuracion  char(1)      = 'N',
   @o_fila              int          = null out
as

declare
   @w_trancount         int,
   @w_sp_name           descripcion,
   @w_error             int,
   @w_i                 int,
   @w_j                 int,
   @w_k                 int,
   @w_sf                char(1),
   @w_sc                char(1),
   @w_valor             varchar(255),
   @w_estado            int,
   @w_oficina           int,
   @w_ciudad_nacional   int

select @w_trancount = @@trancount

-- VARIABLES INICIALES
select @w_sp_name = 'sp_decodificador'

select @w_i= @i_fila,
       @w_j= 1,
       @w_sf = '&',
       @w_sc = ';'

if @i_fila = 1
begin
   delete ca_decodificador
   where  dc_operacion = @i_operacion
   
   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end   
end

-- DECODIFICAR STR0
while @i_str1 <> ''
begin
   select @w_k = charindex(@w_sc,@i_str1)
   
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str1)
      
      if @w_k = 0
         select @w_valor = substring(@i_str1, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str1, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user,  dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values( @s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  A'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_i = @w_i + 1,
             @w_j = 1
      
      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str1, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001 B @w_i' + cast(@w_i as varchar) + '@w_j' + cast(@w_j as varchar) + '@w_valor' + @w_valor 
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str1 = substring(@i_str1, @w_k +1, datalength(@i_str1) - @w_k)
   end
end


while @i_str2 <> ''
begin
   select @w_k = charindex(@w_sc,@i_str2)
   
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str2)
      
      if @w_k = 0
         select @w_valor = substring(@i_str2, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str2, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  C'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_i = @w_i + 1,
             @w_j = 1
      
      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str2, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  D'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str2 = substring(@i_str2, @w_k +1, datalength(@i_str2) - @w_k)
   end
end

while @i_str3 <> ''
begin
   select @w_k = charindex(@w_sc,@i_str3)
   
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str3)
      
      if @w_k = 0
         select @w_valor = substring(@i_str3, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str3, 1, @w_k-1)
      
      insert into ca_decodificador(dc_user,dc_sesn,dc_operacion,dc_fila,      dc_columna,dc_valor)
      values ( @s_user,@s_sesn,@i_operacion, @w_i, @w_j, @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  E'
         select @w_error = 710001
         goto ERROR
      end

      select @w_i = @w_i + 1,
             @w_j = 1

      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str3, 1, @w_k-1)

      insert into ca_decodificador(dc_user,dc_sesn,dc_operacion,dc_fila,
      dc_columna,dc_valor)
      values ( @s_user,@s_sesn,@i_operacion, @w_i, @w_j, @w_valor)

      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  E'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str3 = substring(@i_str3, @w_k +1, datalength(@i_str3) - @w_k)
   end
end

while @i_str4 <> ''
begin
   select @w_k = charindex(@w_sc,@i_str4)
   
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str4)

      if @w_k = 0
         select @w_valor = substring(@i_str4, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str4, 1, @w_k-1)

      insert into ca_decodificador(dc_user,dc_sesn,dc_operacion,dc_fila,
      dc_columna,dc_valor)
      values ( @s_user,@s_sesn,@i_operacion, @w_i, @w_j, @w_valor)

      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  F'
         select @w_error = 710001
         goto ERROR
      end

      select @w_i = @w_i + 1,
             @w_j = 1

      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str4, 1, @w_k-1)
      
      insert into ca_decodificador(dc_user,dc_sesn,dc_operacion,dc_fila,
      dc_columna,dc_valor)
      values ( @s_user,@s_sesn,@i_operacion, @w_i, @w_j, @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  G'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str4 = substring(@i_str4, @w_k +1, datalength(@i_str4) - @w_k)
   end
end

while @i_str5 <> ''
begin
   select @w_k = charindex(@w_sc,@i_str5)
   
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str5)

      if @w_k = 0
         select @w_valor = substring(@i_str5, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str5, 1, @w_k-1)

      insert into ca_decodificador(dc_user,dc_sesn,dc_operacion,dc_fila,
      dc_columna,dc_valor)
      values ( @s_user,@s_sesn,@i_operacion, @w_i, @w_j, @w_valor)

      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  H'
         select @w_error = 710001
         goto ERROR
      end

      select @w_i = @w_i + 1,
             @w_j = 1

      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str5, 1, @w_k-1)

      insert into ca_decodificador(dc_user,dc_sesn,dc_operacion,dc_fila,
      dc_columna,dc_valor)
      values ( @s_user,@s_sesn,@i_operacion, @w_i, @w_j, @w_valor)

      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  I'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str5 = substring(@i_str5, @w_k +1, datalength(@i_str5) - @w_k)
   end
end

while @i_str6 <> ''
begin
   select @w_k = charindex(@w_sc,@i_str6)
 
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str6)
      
      if @w_k = 0
         select @w_valor = substring(@i_str6, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str6, 1, @w_k-1)
      
      insert into ca_decodificador(dc_user,dc_sesn,dc_operacion,dc_fila,
      dc_columna,dc_valor)
      values ( @s_user,@s_sesn,@i_operacion, @w_i, @w_j, @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  J'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_i = @w_i + 1,
             @w_j = 1
      
      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str6, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  K'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str6 = substring(@i_str6, @w_k +1, datalength(@i_str6) - @w_k)
   end
end

while @i_str7 <> ''
begin
   select @w_k = charindex(@w_sc,@i_str7)
   
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str7)
      
      if @w_k = 0
         select @w_valor = substring(@i_str7, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str7, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  L'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_i = @w_i + 1,
             @w_j = 1
      
      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str7, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  M'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str7 = substring(@i_str7, @w_k +1, datalength(@i_str7) - @w_k)
   end
end

while @i_str8 <> ''
begin
   select @w_k = charindex(@w_sc, @i_str8)
   
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str8)
      
      if @w_k = 0
         select @w_valor = substring(@i_str8, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str8, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  N'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_i = @w_i + 1,
             @w_j = 1
      
      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str8, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  O' 
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str8 = substring(@i_str8, @w_k +1, datalength(@i_str8) - @w_k)
   end
end

while @i_str9 <> ''
begin
   select @w_k = charindex(@w_sc,@i_str9)
   
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str9)
      
      if @w_k = 0
         select @w_valor = substring(@i_str9, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str9, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  P'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_i = @w_i + 1,
             @w_j = 1
      
      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str9, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  Q'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str9 = substring(@i_str9, @w_k +1, datalength(@i_str9) - @w_k)
   end
end

while @i_str10 <> ''
begin
   select @w_k = charindex(@w_sc,@i_str10)
   
   if @w_k = 0
   begin
      select @w_k = charindex(@w_sf,@i_str10)
      
      if @w_k = 0
         select @w_valor = substring(@i_str10, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str10, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  R'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_i = @w_i + 1,
             @w_j = 1
      
      break
   end
   ELSE
   begin
      select @w_valor = substring (@i_str10, 1, @w_k-1)
      
      insert into ca_decodificador
            (dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna, dc_valor)
      values(@s_user, @s_sesn, @i_operacion, @w_i,    @w_j,       @w_valor)
      
      if @@error != 0
      begin
         PRINT 'decoder.sp Error 710001  R'
         select @w_error = 710001
         goto ERROR
      end
      
      select @w_j = @w_j + 1
      select @i_str10 = substring(@i_str10, @w_k +1, datalength(@i_str10) - @w_k)
   end
end

select @o_fila = @w_i

if @i_accion = 'A' 
begin
   -- 30SEP2003
   -- VALIDACION DE LA FECHA DE INICIO DE LA OPERACION
   -- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
   select   @w_estado   = op_estado
   from   ca_operacion
   where    op_operacion    = @i_operacion
   
   select @w_ciudad_nacional = pa_int
   from   cobis..cl_parametro
   where  pa_nemonico = 'CIUN'
   and    pa_producto = 'ADM'
   set transaction isolation level read uncommitted
   
   if exists(select 1
             from   cobis..cl_dias_feriados
             where  df_fecha   = @i_fecha_ini
             and    df_ciudad  = @w_ciudad_nacional)
   begin
      select @w_error = 710471 
      goto ERROR
   end 
   ---30SEP2003

   BEGIN TRAN
   
   if @w_estado = 99 or @w_estado = 0
   begin
      update ca_operacion_tmp
      set    opt_fecha_ini = @i_fecha_ini,
             opt_fecha_liq = @i_fecha_ini     
      where  opt_operacion = @i_operacion
   end
   
   update ca_operacion_tmp
   set    opt_causacion = @i_causacion
   where  opt_operacion = @i_operacion
   
   exec @w_error = sp_leer_amortizacion
        @s_user         = @s_user,
        @s_sesn         = @s_sesn, 
        @i_operacionca  = @i_operacion,
        @i_fecha_ini    = @i_fecha_ini,
        @i_dias_gracia  = 0,
        @i_dias_anio    = @i_dias_anio,
        @i_formato_fecha = @i_formato_fecha,
        @i_reestructuracion = @i_reestructuracion
   
   if @w_error <> 0
   begin
      goto ERROR
   end
   --EPB MAR:12-2004RECALCULAR RUBRO PERIODOS DIFERENTES
   
   --- CALCULO DEL SEGURO DE VIDA
   exec @w_error = sp_rubros_periodos_diferentes
        @i_operacion = @i_operacion
   
   if @w_error <> 0
   begin
      goto ERROR
   end
   
   /* KDR 18/05/2022 Se comenta ya que no aplica a versión Finca
   -- CALCULO DEL SEGURO DE VIDA SOBRE VALOR INSOLUTO
   exec @w_error = sp_calculo_seguros_sinsol
        @i_operacion = @i_operacion
   
   if @w_error <> 0
   begin
      goto ERROR
   end
   
   -- CALCULO DE RUBROS CATALOGO
   exec @w_error =  sp_rubros_catalogo
        @i_operacion = @i_operacion
   
   if @w_error != 0
   begin
      goto ERROR
   end
   -- CALCULO DE RUBROS CATALOGO
   --EPB --FIN KDR*/

   COMMIT TRAN
end

if @i_accion = 'B'
begin
   BEGIN TRAN
   
   /*PRINT 'decoder.sp  @s_date  %1!,
                      @s_ofi   %2!,
                      @s_term   %3!,
                      @s_user   %4!',@s_date, @s_ofi,  @s_term, @s_user */
   
   
   exec @w_error = sp_leer_reajustes
        @s_date      = @s_date,
        @s_ofi       = @s_ofi,
        @s_user      = @s_user,
        @s_term      = @s_term,
        @s_sesn      = @s_sesn,
        @i_operacion = @i_operacion,
        @i_formato_fecha = @i_formato_fecha,
        @i_concepto  = @i_concepto
   
   if @w_error <> 0
   begin
      goto ERROR
   end
   
   COMMIT TRAN
end

return 0

ERROR:
while @@trancount > @w_trancount ROLLBACK
exec cobis..sp_cerror
     @t_debug  = 'N',         
     @t_file   = null,
     @t_from   = @w_sp_name,   
     @i_num    = @w_error
--     @i_cuenta = ' '

return @w_error  
go
