/******************************************************************/
/*  Archivo:            validaorp.sp                              */
/*  Stored procedure:   sp_valida_orden_pago                      */
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
if exists (select 1 from sysobjects where name = 'sp_valida_orden_pago_tmp')
   drop proc sp_valida_orden_pago_tmp
go

create proc sp_valida_orden_pago_tmp
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
   @w_cliente              int,
   @w_tipo_orden           catalogo,
   @w_banco                catalogo,
   @w_banco_interciclo     cuenta


-- CURSOR DE SEGUROS
declare cursor_ordenp cursor
for 
select 
    iot_cliente, 
    iot_tipo_orden, 
    iot_banco,
	(select iot_banco from cob_cartera..ca_interf_op_tmp where iot_sesn = @i_secuencial )
from cob_cartera..ca_interf_ordenp_tmp
where iot_sesn = @i_secuencial
for read only
                                                                                                                                                                                                                                           
open  cursor_ordenp
fetch cursor_ordenp into  @w_cliente, @w_tipo_orden, @w_banco, @w_banco_interciclo
                                                                                                                                                                                                      

while @@fetch_status = 0
begin
                                                                                                                                                                                                                                                         
   if (@@fetch_status = -1)
     return 710004

--vprint 'ENTRO AL CURSOR'
print 'Cliente :  ' + cast(@w_cliente as varchar)

if @w_banco_interciclo is NULL
begin
--CLIENTE: Que el cliente exista, este c-¢digo es para relacionar las ordenes de pago con los miembros del grupo, que solo sea para miembros del grupo sin rol D
   if not exists (select 1 from cob_cartera..ca_interf_hijas_tmp
                  where iht_sesn = @i_secuencial
                    and iht_cliente = @w_cliente 
                    and iht_rol  <> 'D')  --Desertor
   begin
       close cursor_ordenp
       deallocate cursor_ordenp
       select @w_error = 725025
       select @w_mensaje = 'Cliente en Interface Ordenes de Pago: ' + ' ' + cast(@w_cliente as varchar) + ' ' +  'no existe en Interface de Op. Hijas'
       select @o_mensaje_error = @w_mensaje 
       --print @w_mensaje
       return @w_error
   end
end
else 
begin
  if not exists (select 1 from cob_cartera..ca_interf_op_tmp
                 where iot_sesn    = @i_secuencial
                  and  iot_banco   = @w_banco_interciclo
                  and  iot_cliente = @w_cliente)
  begin
       close cursor_ordenp
       deallocate cursor_ordenp
       select @w_error = 725025
       select @w_mensaje = 'Cliente en Ordenes de Pago,no existe en Interface de Op. Padre'
       select @o_mensaje_error = @w_mensaje
       --print @w_mensaje
       return @w_error
  end

end 


--TIPO ORDEN DE PAGO: Que tenga los valores: B(banco), I (interna)
if @w_tipo_orden not in ('B','I')
   begin
       close cursor_ordenp
       deallocate cursor_ordenp
       select @w_error = 725022
       select @w_mensaje = 'Tipo de Orden de Pago: ' + ' ' + cast(@w_tipo_orden as varchar) + ' ' +  'es diferente de I/B'
       select @o_mensaje_error = @w_mensaje
       --print @w_mensaje
       return @w_error

   end


--BANCO: Que si el tipo de orden de pago era B, entonces el banco exista en la tabla cobis..cl_banco
  if @w_tipo_orden = 'B'
     if not exists (select 1 from cob_bancos..ba_banco
                    where ba_codigo = @w_banco)
     begin
       close cursor_ordenp
       deallocate cursor_ordenp
       select @w_error = 725022
       select @w_mensaje = 'Codigo de Banco: ' + ' ' + cast(@w_banco as varchar) + ' ' +  'No Existe en estructura de Bancos'
       select @o_mensaje_error = @w_mensaje
       --print @w_mensaje
       return @w_error

     end

 
fetch cursor_ordenp into  @w_cliente, @w_tipo_orden, @w_banco, @w_banco_interciclo
                           
end -- WHILE CURSOR PRINCIPAL
                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                             
close cursor_ordenp
deallocate cursor_ordenp



 

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

