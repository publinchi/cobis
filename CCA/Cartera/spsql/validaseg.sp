/******************************************************************/
/*  Archivo:            validaseg.sp                              */
/*  Stored procedure:   sp_valida_seguros_tmp                      */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 05-Jun-2019                               */
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
/*  05/Jun/19        Lorena Regalado    Valida datos en tablas    */
/*                                      Temporales                */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_valida_seguros_tmp')
   drop proc sp_valida_seguros_tmp
go

create proc sp_valida_seguros_tmp
   @i_secuencial           int,             --Secuencial de referencia con el que se grabo la informacion en tablas temporales
   @o_mensaje_error        varchar(500) = null out


as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_monto                money,
   @w_cliente              int,
   @w_mensaje              varchar(500),
   @w_rol_act              varchar(10),
   @w_oficial              smallint,
   @w_plazo_op             smallint,
   @w_plazo                smallint,
   @w_tipo_seguro          varchar(10), 
   @w_monto_seguro         money, 
   @w_fecha_inicial        datetime,
   @w_fecha_desemb         datetime,
   @w_grupo                int,
   @w_banco                cuenta 


-- CURSOR DE SEGUROS
declare cursor_seguros cursor
for 
select ist_cliente, ist_tipo_seguro, ist_monto_seguro, ist_fecha_inicial,
       (select iot_fecha_desemb 
        from cob_cartera..ca_interf_op_tmp
        where iot_sesn = @i_secuencial),
       (select iot_plazo 
        from cob_cartera..ca_interf_op_tmp
        where iot_sesn = @i_secuencial),
       (select iot_banco 
        from cob_cartera..ca_interf_op_tmp
        where iot_sesn = @i_secuencial)		
from cob_cartera..ca_interf_seguros_tmp
where ist_sesn = @i_secuencial
for read only
                                                                                                                                                                                                                                           
open  cursor_seguros
fetch cursor_seguros into  @w_cliente, @w_tipo_seguro, @w_monto_seguro, @w_fecha_inicial, @w_fecha_desemb, @w_plazo_op, @w_banco
                                                                                                                                                                                                      

while @@fetch_status = 0
begin
                                                                                                                                                                                                                                                         
   if (@@fetch_status = -1)
     return 710004

--vprint 'ENTRO AL CURSOR'
print 'Cliente :  ' + cast(@w_cliente as varchar)

 
   --CLIENTE: Que el cliente cobis exista en la cl_ente 
   if not exists (select 1 from cobis..cl_ente
                  where en_ente = @w_cliente)
   begin
       close cursor_seguros
       deallocate cursor_seguros
       select @w_error = 725017
       select @w_mensaje = 'Cliente en Interface Seguros: ' + ' ' + cast(@w_cliente as varchar) + ' ' +  'no es Cliente Cobis'
       select @o_mensaje_error = @w_mensaje 
       return @w_error
       --goto ERROR
   end
   
    --CLIENTE: Que sea uno de los miembros que participa en el credito
	if @w_banco is not NULL
	begin
	
	     select @w_grupo = op_grupo
	     from cob_cartera..ca_operacion
	     where op_banco = @w_banco
	     and   op_grupal = 'S'
	
	
         if not exists (select 1 from cob_cartera..ca_operacion 
	                    where op_cliente = @w_cliente 
						 and  op_grupo   = @w_grupo 
				         and  op_ref_grupal = @w_banco)
		 begin
				close cursor_seguros
				deallocate cursor_seguros
				select @w_error = 725013
				select @w_mensaje = 'El Cliente: ' + ' ' + cast(@w_cliente as varchar) + ' ' + 'No es miembro del grupo: ' + cast(@w_grupo as varchar) + 'Banco: ' + @w_banco
				--print @w_mensaje
                                select @o_mensaje_error = @w_mensaje 
				return @w_error
         end		 
	
    end
	
    --TIPO SEGURO: De un nuevo catalogo de categor¡as: B (B sico), OPR(Obligatorio Premium), OPL(Obligatorio Platinum)
    if not exists (select 1 from cobis..cl_tabla x, cobis..cl_catalogo y
                   where x.tabla = 'ca_tipo_seguro'
                   and   x.codigo = y.tabla
                   and   y.codigo  = @w_tipo_seguro
                   and   y.estado = 'V' )
    begin
        close cursor_seguros
        deallocate cursor_seguros
        select @w_error = 725016
        select @w_mensaje = 'No Existe Codigo del Tipo de Seguro:' + ' ' + cast(@w_tipo_seguro as varchar) + ' ' + 'en Catalogo'
        --print @w_mensaje
        select @o_mensaje_error = @w_mensaje 
        return @w_error
    end

    --MONTO DEL SEGURO
    if @w_monto_seguro <= 0
    begin
        close cursor_seguros
        deallocate cursor_seguros
        --print 'Error monto del seguro no puede ser menor o igual a 0'
        select @w_mensaje = 'Error monto del seguro no puede ser menor o igual a 0'
        select @w_error = 725020
        select @o_mensaje_error = @w_mensaje 
        return @w_error
    end

                                                                                                                                                                                                                                         
    --FECHA DE VIGENCIA: Fecha de vigencia inicial
    --Que la fecha de vigencia no sea menor a la fecha de desembolso de la operaci¢n grupal
      if @w_fecha_inicial < @w_fecha_desemb
      begin
        close cursor_seguros
        deallocate cursor_seguros
        --print 'Error, La fecha de vigencia del seguro : ' + cast(@w_fecha_inicial as varchar) + ' ' + 'no puede ser menor que la fecha de desembolso: '   + cast(@w_fecha_desemb as varchar)
        select @w_mensaje = 'La fecha de vigencia del seguro : ' + cast(@w_fecha_inicial as varchar) + ' ' + 'no puede ser menor que la fecha de desembolso: '   + cast(@w_fecha_desemb as varchar)
        select @w_error = 725019
        select @o_mensaje_error = @w_mensaje 
        return @w_error
      end


fetch cursor_seguros into  @w_cliente, @w_tipo_seguro, @w_monto_seguro, @w_fecha_inicial, @w_fecha_desemb, @w_plazo_op, @w_banco 
                           
end -- WHILE CURSOR PRINCIPAL
                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                             
close cursor_seguros
deallocate cursor_seguros



 

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

