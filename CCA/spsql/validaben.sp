/******************************************************************/
/*  Archivo:            validaben.sp                              */
/*  Stored procedure:   sp_valida_benef_tmp                       */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 10-Jun-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Interface de Creacion de Operaciones                       */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  10/Jun/19        Lorena Regalado    Valida datos en tablas    */
/*                                      Temporales                */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_valida_benef_tmp')
   drop proc sp_valida_benef_tmp
go

create proc sp_valida_benef_tmp
   @i_secuencial           int,             --Secuencial de referencia con el que se grabo la informacion en tablas temporales
   @o_mensaje_error        varchar(500) = null out



as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_mensaje              varchar(500),
   @w_fecha_inicial        datetime,
   @w_fecha_desemb         datetime,
   @w_parentesco           catalogo, 
   @w_genero               catalogo, 
   @w_tipo_iden            catalogo, 
   @w_tipo_seguro          catalogo,
   @w_cliente              int,
   @w_cobertura            float


-- CURSOR DE BENEFICIARIOS
declare cursor_benef cursor
for 
select 
    ibt_parentezco ,
    ibt_cliente    ,
    ibt_tipo_seguro
from cob_cartera..ca_interf_benef_tmp
where ibt_sesn = @i_secuencial
for read only
                                                                                                                                                                                                                                           
open  cursor_benef
fetch cursor_benef into  @w_parentesco, @w_cliente, @w_tipo_seguro
                                                                                                                                                                                                      

while @@fetch_status = 0
begin
                                                                                                                                                                                                                                                         
   if (@@fetch_status = -1)
     return 710004

--vprint 'ENTRO AL CURSOR'
--print 'Cliente :  ' + cast(@w_cliente as varchar)


--CLIENTE: Que el cliente exista, este c¢digo es para relacionar los beneficiarios con sus seguros
   if not exists (select 1 from cob_cartera..ca_interf_seguros_tmp
                  where ist_sesn = @i_secuencial and ist_cliente = @w_cliente)
   begin
       close cursor_benef
       deallocate cursor_benef
       select @w_error = 725021
       select @w_mensaje = 'Cliente en Interface Beneficiarios: ' + ' ' + cast(@w_cliente as varchar) + ' ' +  'no existe en Interface Seguros'
       --print @w_mensaje
       select @o_mensaje_error = @w_mensaje
       return @w_error
   end


--PARENTESCO: Que el parentesco exista en la tabla de catalogo cl_parentesco_beneficiario
if not exists (select 1 from cobis..cl_tabla x, cobis..cl_catalogo y
               where x.tabla = 'cl_parentesco_beneficiario'
                and   x.codigo = y.tabla
                and   y.codigo  = @w_parentesco
                and   y.estado = 'V' )			   

   begin
       close cursor_benef
       deallocate cursor_benef
       select @w_error = 725022
       select @w_mensaje = 'C¢digo de Parentesto: ' + ' ' + cast(@w_parentesco as varchar) + ' ' +  'no existe en Catalogo de Parentesco Beneficiario'
       --print @w_mensaje
       select @o_mensaje_error = @w_mensaje
       return @w_error

   end


  --TIPO SEGURO: De un nuevo cat logo de categor¡as: B (B sico), OPR(Obligatorio Premium), OPL(Obligatorio Platinum)
    if not exists (select 1 from cobis..cl_tabla x, cobis..cl_catalogo y
                   where x.tabla = 'ca_tipo_seguro'
                   and   x.codigo = y.tabla
                   and   y.codigo  = @w_tipo_seguro
                   and   y.estado = 'V' )
    begin
        close cursor_benef
        deallocate cursor_benef
        select @w_error = 725016
        select @w_mensaje = 'No Existe Codigo del Tipo de Seguro:' + ' ' + cast(@w_tipo_seguro as varchar) + ' ' + 'en Catalogo'
        --print @w_mensaje
        select @o_mensaje_error = @w_mensaje
        return @w_error
    end

fetch cursor_benef into  @w_parentesco, @w_cliente, @w_tipo_seguro
end -- WHILE CURSOR PRINCIPAL
                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                             
close cursor_benef
deallocate cursor_benef



-- CURSOR DE PARA VALIDAR PORCENTAJES DE COBERTURA POR CLIENTE Y TIPO DE SEGURO
declare cursor_cobertura cursor
for 
select distinct ist_cliente, ist_tipo_seguro, sum(ibt_porcentaje) 
from cob_cartera..ca_interf_seguros_tmp, 
     cob_cartera..ca_interf_benef_tmp
where ist_sesn = @i_secuencial
and   ist_sesn = ibt_sesn 
and   ist_cliente = ibt_cliente
and   ist_tipo_seguro = ibt_tipo_seguro
group by ist_cliente, ist_tipo_seguro
having sum(ibt_porcentaje) <> 100      --Maximo porcentaje de cobertura
order by ist_cliente, ist_tipo_seguro
for read only
                                                                                                                                                                                                                                           
open  cursor_cobertura
fetch cursor_cobertura into  @w_cliente, @w_tipo_seguro, @w_cobertura
                                                                                                                                                                                                      

while @@fetch_status = 0
begin
                                                                                                                                                                                                                                                         
   if (@@fetch_status = -1)
   begin
     select @w_mensaje = 'Error en Cursor de Cobertura en validacion de beneficiarios'
     select @o_mensaje_error = @w_mensaje
     return 710004
   end

--Porcentaje: Que la suma de los porcentajes para un mismo cliente sumen 100
  if @w_cobertura <> 100
  begin
        close cursor_cobertura
        deallocate cursor_cobertura
        select @w_error = 725024
        select @w_mensaje = 'Cliente :' + ' ' + cast(@w_cliente as varchar) + ' ' + 'con cobertura diferente de 100 en Tipo de Seguro: ' + cast(@w_tipo_seguro as varchar) 
        --print @w_mensaje
        select @o_mensaje_error = @w_mensaje
        return @w_error
  end

fetch cursor_cobertura into  @w_cliente, @w_tipo_seguro, @w_cobertura
                           
end -- WHILE CURSOR PRINCIPAL
                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                             
close cursor_cobertura
deallocate cursor_cobertura

 

return 0

ERROR:

   
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error,
    @i_msg    = @w_mensaje,
    @i_sev    = 0
   
   return @w_error
   
go

