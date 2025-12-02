/******************************************************************/
/*  Archivo:            validaopi.sp                              */
/*  Stored procedure:   sp_valida_op_ind_tmp                      */
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
/*  31/Jul/19        Lorena Regalado    Quitar validacion para or-*/
/*  den de desembolso y cambios a los miembros del grupo          */
/******************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_valida_op_ind_tmp')
   drop proc sp_valida_op_ind_tmp
go


create proc sp_valida_op_ind_tmp
   @s_user                 login        = NULL,
   @s_sesn                 int            = null,
   @s_ssn                  int            = null,
   @s_term                 varchar (30) = NULL,
   @s_date                 datetime     = NULL,
   @i_secuencial           int             --Secuencial de referencia con el que se grabo la informacion en tablas temporales
                                                                                                                                 

                                                                                                                                                                                                                                                              
as declare
                                                                                                                                                                                                                                                    
   @w_sp_name              varchar(30),
                                                                                                                                                                                                                       
   @w_error                int,
                                                                                                                                                                                                                               
   @w_monto                money,
                                                                                                                                                                                                                             
   @w_cliente              int,
                                                                                                                                                                                                                               
   @w_rol                  varchar(10),
                                                                                                                                                                                                                       
   @w_destino_eco          varchar(10),
                                                                                                                                                                                                                       
   @w_grupo                int,
                                                                                                                                                                                                                               
   @w_mensaje              varchar(255),
                                                                                                                                                                                                                      
   @w_rol_act              varchar(10),
                                                                                                                                                                                                                       
   @w_oficial              smallint,
   @w_cli_actual           int,
   @w_fecha_registro       datetime
                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                                
-- CURSOR DE 
                                                                                                                                                                                                                                                 
declare cursor_operaciones cursor
for 
select iht_cliente, iht_monto, iht_rol,
       iht_destino_eco, 
       (select iot_grupo from cob_cartera..ca_interf_op_tmp
                            where iot_sesn = @i_secuencial)
from cob_cartera..ca_interf_hijas_tmp
where iht_sesn = @i_secuencial
for read only
                   
open  cursor_operaciones
fetch cursor_operaciones into  @w_cliente, @w_monto, @w_rol, @w_destino_eco, @w_grupo
                                                                                                                                                                                                                                                              
while @@fetch_status = 0
begin
     
   if (@@fetch_status = -1)
     return 710004
                                                                                                                                                                                                                                                              
--vprint 'ENTRO AL CURSOR'
                                                                                                                                                                                                                                    
--print 'Cliente :  ' + cast(@w_cliente as varchar)
                                                                                                                                                                                                                                                              
   --CLIENTE: Que el cliente cobis exista en la cl_ente y que sea miembro del grupo de la operaci-¢n grupal: cobis..cl_cliente_grupo
   if not exists (select 1 from cobis..cl_ente
                  where en_ente = @w_cliente)
   begin
       close cursor_operaciones
       deallocate cursor_operaciones
       --print 'Error Miembro del Grupo no es Cliente'
       select @w_error = 725009
       select @w_mensaje = 'Miembro del Grupo ' + ' ' + cast(@w_cliente as varchar) + ' ' +  'no es Cliente Cobis'
       print @w_mensaje
       return @w_error

                                                                                                                                                                                                                                             
   end

/* LRE 31/JULIO/2019 se comenta a solicitud de PQU  
  
--ORDEN DE DESEMBOLSO
if not exists (select 1 from cob_cartera..ca_interf_ordenp_tmp
               where iot_sesn = @i_secuencial
                 and iot_cliente = @w_cliente)

begin
       close cursor_operaciones
       deallocate cursor_operaciones
       select @w_error = 725009
       select @w_mensaje = 'Miembro del Grupo ' + ' ' + cast(@w_cliente as varchar) + ' ' +  'no tiene registrado Orden de Desembolso'
       print @w_mensaje
       return @w_error
end

*/   
                                                                                                                                                                                                                                                               
    --ROL: Que el rol corresponda a uno de estos. P: Presidente, T: Tesorero I: Integrante A: Ahorrador D: Desertor, 
    --estos roles deber-¡an estar en una tabla de cat- logo.
    if not exists (select 1 from cobis..cl_tabla x, cobis..cl_catalogo y
                   where x.tabla = 'cl_rol_grupo'
                   and   x.codigo = y.tabla
                   and   y.codigo  = @w_rol
                   and   y.estado = 'V' )
                                                                                                                                                                                                                     
    begin
                                                                                                                                                                                                                                                     
        close cursor_operaciones
        deallocate cursor_operaciones
        --print 'No Existe C-¢digo de Rol'
        select @w_error = 725012
        select @w_mensaje = 'No Existe Codigo del Rol:' + ' ' + cast(@w_rol as varchar) + ' ' + 'en Catalogo'
        print @w_mensaje
        return @w_error
                                                                                                                                                                                                                                            
    end
                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                              
    --DESTINO ECON+ MICO: Que exista en la tabla de cat- logo cr_destino
    if not exists (select 1 from cobis..cl_tabla x, cobis..cl_catalogo y
        where x.tabla = 'cr_destino'
                   and   x.codigo = y.tabla
                   and   y.codigo  = @w_destino_eco  
                   and   y.estado = 'V' )
                                                                                                                                                                                                                     
    begin
                                                                                                                                                                                                                                                     
       close cursor_operaciones
       deallocate cursor_operaciones
       --print 'No Existe Destino Economico'
       select @w_error = 725010
       select @w_mensaje = 'No Existe Destino Economico:' + ' ' + cast(@w_destino_eco as varchar) + ' ' + 'en Catalogo'
       print @w_mensaje
       return @w_error
                                                                                                                                                                                                                                             
    end
                                                                                                                                                                                                                                                       

                                                                                                                                                                                                                                                              
    --INSERTAR O ACTUALIZAR LA INFORMACION DE LOS MIEMBROS DEL GRUPO
    select @w_rol_act = cg_rol,
           @w_oficial = (select en_oficial from cobis..cl_ente
                         where en_ente = @w_cliente),
           @w_fecha_registro = cg_fecha_reg
    from cobis..cl_cliente_grupo
    where  cg_grupo = @w_grupo
     and   cg_ente  = @w_cliente
                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                              
    if @@rowcount = 0  --Cliente no pertenece al Grupo
    begin
               exec @w_error     =  cob_pac..sp_miembro_grupo_busin
               @s_ssn             = @s_ssn,
               @i_operacion       = 'I',
               @t_trn             = 810,
               @i_grupo           = @w_grupo,
               @i_ente            = @w_cliente,
               @s_user            = @s_user,
               @s_term            = @s_term,
               @s_sesn            = @s_sesn,
               @i_oficial         = @w_oficial,
               @i_fecha_asociacion= @s_date,
               @i_rol             = @w_rol,
               @i_estado          = 'V'
                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
               if @w_error <> 0 begin
                    close cursor_operaciones
                    deallocate cursor_operaciones
                    --select  @w_error = 725015
                    print @w_mensaje
                    return @w_error
                 end
    end
    else
    begin
	exec @w_error     = cob_pac..sp_miembro_grupo_busin
              @i_operacion = 'U',
              @s_sesn      = @s_sesn,
              @s_ssn       = @s_ssn,
              @t_trn       = 810,
              @i_grupo     = @w_grupo,
              @i_ente      = @w_cliente,
              @i_rol       = @w_rol,
              @i_estado    = 'V',
              @i_fecha_asociacion = @w_fecha_registro
                                                                                                                                                                                                                                                              
              if @w_error <> 0 
              begin
                 close cursor_operaciones
                 deallocate cursor_operaciones
                 --select  @w_error = 725014
                 return @w_error
              end		   		   
     end

fetch cursor_operaciones into  @w_cliente, @w_monto, @w_rol, @w_destino_eco, @w_grupo                                                                                                                                                                           
end -- WHILE CURSOR PRINCIPAL
                                                                                                                                                                                                                                 
close cursor_operaciones
deallocate cursor_operaciones
                                                                                                                                                                                                                                 

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
 
                                                                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      

