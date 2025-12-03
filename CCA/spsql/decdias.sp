/************************************************************************/
/*	Archivo:		       decdias.sp				                    */
/*	Stored procedure:	   sp_decodificador_dias_manual		            */
/*	Base de datos:		   cob_cartera				                    */
/*	Producto: 		       Cartera					                    */
/*	Disenado por:  		   Diego Aguilar  				                */
/*	Fecha de escritura:	   Dic 1999				                        */
/************************************************************************/
/*				               IMPORTANTE				                */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	"MACOSA".							                                */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				                PROPOSITO				                */
/*	Descompone en un tabla una cadena de caracteres        		        */
/************************************************************************/  
/*			                  MODIFICACIONES				            */    
/*	     FECHA		     AUTOR			          RAZON		            */   
/*      DIC-21-2005    EPB                   correccion calculo dias 360*/ 
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_decodificador_dias_manual')
	drop proc sp_decodificador_dias_manual
go

create proc sp_decodificador_dias_manual
        @s_user                         login,
        @s_sesn                         int,
        @i_operacion                    int,
        @i_fila                         int          = 1,
        @i_cuota_mod                    int          = 0,
        @i_fecha_ini                    datetime     = null,
        @i_formato_fecha                int          = 101,
        @i_proceso                      char(1)      = 'N',
        @i_base_calculo                 char(1)      = 'R',
        @i_evitar_feriados              char(1)      = 'N',
        @i_ult_dia_habil                char(1)      = 'N',
	     @i_dias_anio			int          = 360,
        @i_actualiza_tasa               char(1)      = 'N',
        @i_recalcular                   char(1)      = 'N',
        @i_opcion                       char(1)      = 'C',
        @i_str1                         varchar(255) = '',
        @i_str2                         varchar(255) = '',
        @i_str3                         varchar(255) = '',
        @i_str4                         varchar(255) = '',
        @i_str5                         varchar(255) = '',
        @i_str6                         varchar(255) = '',
        @i_str7                         varchar(255) = '',
        @i_str8                         varchar(255) = '',
        @i_str9                         varchar(255) = '',
        @i_str10                        varchar(255) = '',
	     @i_sig_cuota                    int          = 0,
        @o_fila                         int          = null out
as

declare @w_sp_name		descripcion,
	@w_error		int,
        @w_i                    int,
        @w_j                    int,
        @w_k                    int,
        @w_sf                   char(1),
        @w_sc                   char(1),
        @w_valor                varchar(255),
        @w_return               int,
	@w_num_cuota		int,
	@w_dividendo	        int,
        @w_di_fecha_ven         datetime,
	@w_fecha_fin_ini	datetime,
        @dia_fecha_fin          datetime



/* VARIABLES INICIALES */
select @w_sp_name = 'sp_decodificador_dias_manual'

select 
@w_i= @i_fila,
@w_j= 1,
@w_sf = '&',
@w_sc = ';',
@w_num_cuota = 1


/* DECODIFICAR STR0 */
while @i_str1 <> '' begin

   select @w_k = charindex(@w_sc,@i_str1)  --busco ;
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str1)

      if @w_k = 0
         select @w_valor = substring(@i_str1, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str1, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,@i_fila) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end

      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str1, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,@i_fila) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end

      select @w_j = @w_j + 1
      select @i_str1 = substring(@i_str1, @w_k +1, datalength(@i_str1) - @w_k)

   end

end


while @i_str2 <> '' begin

   select @w_k = charindex(@w_sc,@i_str2)
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str2)

      if @w_k = 0
         select @w_valor = substring(@i_str2, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str2, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,@i_fila) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)
      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end


      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str2, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,@i_fila) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end

      
      select @w_j = @w_j + 1
      select @i_str2 = substring(@i_str2, @w_k +1, datalength(@i_str2) - @w_k)

   end

end


while @i_str3 <> '' begin

   select @w_k = charindex(@w_sc,@i_str3)
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str3)

      if @w_k = 0
         select @w_valor = substring(@i_str3, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str3, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,@i_fila) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end


      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str3, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,@i_fila) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end

      
      select @w_j = @w_j + 1
      select @i_str3 = substring(@i_str3, @w_k +1, datalength(@i_str3) - @w_k)

   end

end

while @i_str4 <> '' begin

   select @w_k = charindex(@w_sc,@i_str4)
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str4)

      if @w_k = 0
         select @w_valor = substring(@i_str4, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str4, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,@i_fila) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end


      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str4, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,@i_fila) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end

      
      select @w_j = @w_j + 1
      select @i_str4 = substring(@i_str4, @w_k +1, datalength(@i_str4) - @w_k)

   end

end

while @i_str5 <> '' begin

   select @w_k = charindex(@w_sc,@i_str5)
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str5)

      if @w_k = 0
         select @w_valor = substring(@i_str5, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str5, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end


      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str5, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end

      
      select @w_j = @w_j + 1
      select @i_str5 = substring(@i_str5, @w_k +1, datalength(@i_str5) - @w_k)

   end

end

while @i_str6 <> '' begin

   select @w_k = charindex(@w_sc,@i_str6)
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str6)

      if @w_k = 0
         select @w_valor = substring(@i_str6, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str6, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end


      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str6, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end

      
      select @w_j = @w_j + 1
      select @i_str6 = substring(@i_str6, @w_k +1, datalength(@i_str6) - @w_k)

   end

end



while @i_str7 <> '' begin

   select @w_k = charindex(@w_sc,@i_str7)
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str7)

      if @w_k = 0
         select @w_valor = substring(@i_str7, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str7, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end


      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str7, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end

      
      select @w_j = @w_j + 1
      select @i_str7 = substring(@i_str7, @w_k +1, datalength(@i_str7) - @w_k)

   end

end

while @i_str8 <> '' begin

   select @w_k = charindex(@w_sc,@i_str8)
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str8)

      if @w_k = 0
         select @w_valor = substring(@i_str8, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str8, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end


      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str8, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end

      
      select @w_j = @w_j + 1
      select @i_str8 = substring(@i_str8, @w_k +1, datalength(@i_str8) - @w_k)

   end

end

while @i_str9 <> '' begin

   select @w_k = charindex(@w_sc,@i_str9)
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str9)

      if @w_k = 0
         select @w_valor = substring(@i_str9, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str9, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end


      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str9, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end

      
      select @w_j = @w_j + 1
      select @i_str9 = substring(@i_str9, @w_k +1, datalength(@i_str9) - @w_k)

   end

end

while @i_str10 <> '' begin

   select @w_k = charindex(@w_sc,@i_str10)
 
   if @w_k = 0 begin

      select @w_k = charindex(@w_sf,@i_str10)

      if @w_k = 0
         select @w_valor = substring(@i_str10, 1, datalength(@w_valor))
      else
         select @w_valor = substring(@i_str10, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end


      select @w_i = @w_i + 1,
             @w_j = 1

      break

   end else begin

      select @w_valor = substring (@i_str10, 1, @w_k-1)

      select @w_num_cuota = isnull(max(dia_num_cuota) + 1,1) 
             from ca_diastablamanual  
             where dia_operacion = @i_operacion

      insert into ca_diastablamanual(dia_operacion,dia_num_cuota,dia_fecha_ini,
                                     dia_fecha_fin,dia_num_dias)
      values (@i_operacion, @w_num_cuota, null, @w_valor,null)

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end

      
      select @w_j = @w_j + 1
      select @i_str10 = substring(@i_str10, @w_k +1, datalength(@i_str10) - @w_k)

   end

end

if @i_proceso = 'S' 
begin


    delete ca_dividendo_original_tmp WHERE dot_operacion >= 0
    



   update ca_diastablamanual
   set   dia_fecha_ini = @i_fecha_ini
   where dia_operacion = @i_operacion
   and   dia_num_cuota = 1



   if @i_evitar_feriados = 'S' and @i_recalcular = 'N'
      if exists(select 1 from ca_dividendo_original_tmp
                        where dot_operacion = @i_operacion
                          and dot_dividendo = @i_cuota_mod) 
      begin


      select @dia_fecha_fin = dia_fecha_fin
      from ca_diastablamanual
      where dia_operacion = @i_operacion
      and dia_num_cuota   = @i_cuota_mod
      



         update ca_dividendo_original_tmp
         set dot_fecha_ven = dia_fecha_fin
         from ca_diastablamanual
         where dia_operacion = @i_operacion
         and dia_num_cuota   = @i_cuota_mod
         and dot_operacion   = dia_operacion
         and dot_dividendo   = dia_num_cuota

         if @@error != 0  begin
            select @w_error = 710002
            goto ERROR
         end

         update ca_dividendo_original_tmp
         set dot_fecha_ini = dia_fecha_fin
         from ca_diastablamanual
         where dia_operacion = @i_operacion
         and dia_num_cuota = @i_cuota_mod
         and dot_operacion = dia_operacion
         and dot_dividendo = @i_cuota_mod + 1

         if @@error != 0  begin
            select @w_error = 710002
            goto ERROR
         end

      end

   declare cursor_tabla cursor for
   select  dia_num_cuota, dia_fecha_fin
   from ca_diastablamanual
   where dia_operacion = @i_operacion
   order by dia_num_cuota
   for read only
                    
   open cursor_tabla

   fetch cursor_tabla into @w_dividendo,@w_di_fecha_ven

   while @@fetch_status = 0 
   begin

     if @w_dividendo > 1 
     begin


	update ca_diastablamanual
           set dia_fecha_ini = @w_fecha_fin_ini    --@w_di_fecha_ven
         where dia_operacion = @i_operacion
           and dia_num_cuota = @w_dividendo
        
        select @w_fecha_fin_ini = @w_di_fecha_ven 
     end
     else
        select @w_fecha_fin_ini = @w_di_fecha_ven
  
     fetch cursor_tabla into @w_dividendo,@w_di_fecha_ven
   end
   close cursor_tabla
   deallocate cursor_tabla

   if exists(select 1 from ca_diastablamanual
              where dia_operacion = @i_operacion) 
   begin

	   exec @w_return = sp_calculo_dias_tabla_manual
	   @s_user            = @s_user,
	   @s_sesn            = @s_sesn, 
	   @i_operacionca     = @i_operacion,
	   @i_formato_fecha   = @i_formato_fecha,
           @i_base_calculo    = @i_base_calculo,
           @i_evitar_feriados = @i_evitar_feriados,
           @i_ult_dia_habil   = @i_ult_dia_habil,
           @i_recalcular      = @i_recalcular,
    	   @i_dias_anio	      = @i_dias_anio,
           @i_actualiza_tasa  = @i_actualiza_tasa
 
	   if @w_return <> 0 begin
	      select @w_error = @w_return
	      goto ERROR
	   end
   end   
end



if @i_opcion = 'S' begin

   set rowcount 100

   select convert(varchar(10),dia_fecha_fin,@i_formato_fecha),
          isnull(dia_num_dias,0)
          from ca_diastablamanual
          where dia_operacion = @i_operacion
            and dia_num_cuota > @i_sig_cuota
          order by dia_num_cuota

   if @@rowcount < 100 begin
      set rowcount 0
      delete ca_diastablamanual where dia_operacion = @i_operacion 
   end

end


if @i_opcion = 'I'
   begin
      --print 'ingrese a insertar...'
      update ca_dividendo_original_tmp
         set dot_dividendo = dot_dividendo + 1
       where dot_operacion = @i_operacion
         and dot_dividendo >= @i_fila

      if @@error != 0 begin
         select @w_error = 710002
         goto ERROR
      end

      insert into ca_dividendo_original_tmp
      (dot_operacion, dot_dividendo, dot_fecha_ini, dot_fecha_ven)
      values
      (@i_operacion, @i_fila, @i_fecha_ini, @i_fecha_ini)

      if @@error != 0  begin
         select @w_error = 710001
         goto ERROR
      end
   end



if @i_opcion = 'E'
   if exists(select 1 from ca_dividendo_original_tmp
                        where dot_operacion = @i_operacion
                          and dot_dividendo = @i_fila) begin
      delete ca_dividendo_original_tmp
       where dot_operacion = @i_operacion
         and dot_dividendo = @i_fila

      if @@error != 0     begin
         select @w_error = 710003
         goto ERROR
      end

      update ca_dividendo_original_tmp
         set dot_dividendo = dot_dividendo - 1
       where dot_operacion = @i_operacion
         and dot_dividendo > @i_fila

      if @@error != 0 begin
         select @w_error = 710002
         goto ERROR
      end
   end


return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         
@t_file = null,
@t_from =@w_sp_name,   
@i_num = @w_error
--@i_cuenta= ' '

return @w_error  
go
