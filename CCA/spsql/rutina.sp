/************************************************************************/
/*      Archivo:                rutina.sp                               */
/*      Stored procedure:       sp_rutina_justificacion                 */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Xavier Maldonado                        */
/*      Fecha de escritura:     FEb 2004                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*            PROPOSITO                                                 */
/*  Rutina para ajustar una carta en sqr                                */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_asunto_carta')
   drop table ca_asunto_carta
go

create table ca_asunto_carta
(ca_secuencia			int null,
 ca_secuencia_rej               int null,
 ca_asunto			varchar(255))
go

if exists (select 1 from sysobjects where name = 'ca_cuerpo_carta')
   drop table ca_cuerpo_carta
go
create table ca_cuerpo_carta
(ca_secuencia			int null,
 ca_secuencia_rej               int null,
 ca_cuerpo			varchar(255))
go



if exists (select 1 from sysobjects where name = 'sp_rutina_justificacion')
    drop proc sp_rutina_justificacion
go

create proc sp_rutina_justificacion (
@i_fecha_proceso       datetime = null,
@i_secuencial_aviso    int      = null,
@i_modo                int      = null
)
as


declare @w_final int,
        @w_inicial int,
        @w_contador int,
        @w_descripcion varchar(255),
        @w_descripcion_format varchar(255),
        @w_total  int,
        @w_final_total int,
        @w_asunto  varchar(255),
        @w_cuerpo  varchar(255),
        @w_ancho_pagina int,
        @w_data    varchar(255),
        @w_secuencia int,
        @w_secuecial int

select @w_final_total = 0,
       @w_inicial  = 1,
       @w_total    = 0,
       @w_contador = 0,
       @w_descripcion = '',
       @w_total = 0,
       @w_final = 10,
       @w_data  = '',
       @w_secuencia  = 0,
       @w_descripcion_format = ''





/*PARA JUSTIFICAR EL ASUNTO DE LA CARTA*/
if @i_modo = 1
begin
   ---truncate table ca_asunto_carta

   select @w_ancho_pagina = 70

   select @w_data = act_asunto 
   from ca_aviso_cambio_tasas
   where act_fecha_proceso = @i_fecha_proceso
   and   act_generar       = 'S'
   and   act_secuencial    = @i_secuencial_aviso

end


/*PARA JUSTIFICAR EL CUERPO DE LA CARTA*/
if @i_modo = 2
begin
   ---truncate table ca_cuerpo_carta

   select @w_ancho_pagina = 80

   select @w_data = act_parte_cuerpo 
   from ca_aviso_cambio_tasas
   where act_fecha_proceso = @i_fecha_proceso
   and   act_generar       = 'S'
   and   act_secuencial    = @i_secuencial_aviso
end



/*TOTAL DE CARACTERES ENVIADOS*/
select @w_total = datalength(@w_data)


/*LONGITUD DE CARACTERES PARA UNA PAGINA*/
select @w_final_total = @w_ancho_pagina

if @w_total <= 0
begin
   print '@i_fecha_proceso...' + cast(@i_fecha_proceso as varchar)
   print '@i_secuencial_aviso...' + cast(@i_secuencial_aviso as varchar)
   print ''
   return 0
end


if (@w_total <= @w_final_total) 
begin
      select @w_descripcion_format = ltrim(rtrim(@w_data))

      select @w_secuencia = @w_secuencia + 1 

      if @i_modo =  1
      begin
         print 'NO INSERTAR'
         insert into ca_asunto_carta
         values (@w_secuencia, @i_secuencial_aviso, isnull(@w_descripcion_format,'.'))
      end


      if @i_modo =  2
      begin

         print 'NO INSERT'
         insert into ca_cuerpo_carta
         values (@w_secuencia, @i_secuencial_aviso, isnull(@w_descripcion_format,'.'))
      end
end
else
begin


while (@w_final_total <= @w_total) 
begin   

   if ' ' =  (substring(@w_data, @w_final_total,1))
   begin 

      select @w_descripcion  = ''

      if @w_inicial = 1
      begin

         select @w_final = @w_final_total
         select @w_descripcion  =  (substring(@w_data,1,@w_final))
         select @w_inicial = @w_final 
         select @w_final_total = @w_inicial + @w_ancho_pagina
         select @w_contador = 0
         ---print 'DESCRIPCION:' + @w_descripcion

      end
      else
      begin
         select @w_final = @w_ancho_pagina - @w_contador
         select @w_descripcion  = (substring(@w_data,@w_inicial,@w_final))
         select @w_inicial  = @w_inicial + @w_final 
         select @w_final_total = @w_inicial + @w_ancho_pagina
         select @w_contador = 0
         ---print 'DESCRIPCION:' + @w_descripcion
      end

      select @w_descripcion_format = ''
      select @w_descripcion_format = ltrim(rtrim(@w_descripcion))

      select @w_secuencia = @w_secuencia + 1 

      if @i_modo =  1
      begin

         insert into ca_asunto_carta
         values (@w_secuencia, @i_secuencial_aviso, isnull(@w_descripcion_format, '.'))
      end

      if @i_modo =  2
      begin
         insert into ca_cuerpo_carta
         values (@w_secuencia, @i_secuencial_aviso, isnull(@w_descripcion_format, '.'))
      end



      if @w_final_total > @w_total or @w_final <= 0
      begin
        select @w_descripcion  = (substring(@w_data,@w_inicial,@w_final_total))
        ---print 'DESCRIPCION:' + @w_descripcion


        select @w_secuencia = @w_secuencia + 1 

        select @w_descripcion_format = ''
        select @w_descripcion_format = ltrim(rtrim(@w_descripcion))

        if @i_modo =  1
         begin
            insert into ca_asunto_carta
            values (@w_secuencia, @i_secuencial_aviso, isnull(@w_descripcion_format, '.'))
         end

         if @i_modo =  2
         begin
            insert into ca_cuerpo_carta
            values (@w_secuencia, @i_secuencial_aviso, isnull(@w_descripcion_format, '.'))
         end

         break 

      end


   end
   else
   begin

      select @w_final_total = @w_final_total  - 1
      select @w_contador    = @w_contador + 1

      if (@w_final_total > @w_total) or @w_final <= 0
      break

   end
end
end

return 0
go
