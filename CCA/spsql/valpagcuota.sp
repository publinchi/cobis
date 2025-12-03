/******************************************************************/
/*  Archivo:            valpagcuota.sp                            */
/*  Stored procedure:   sp_valida_pago_cuota                      */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Adriana Giler                             */
/*  Fecha de escritura: 03-Abr-2019                               */
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
/*   - Validar el pago de la primera cuota de la operacion para   */
/*   solicitar el desbloqueo del valor                            */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/******************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_valida_pago_cuota')
   drop proc sp_valida_pago_cuota
go

create proc sp_valida_pago_cuota
   @i_cuenta           varchar(24),
   @o_desbloquea       tinyint out,
   @o_mensaje          varchar(100) out 
   
as

declare   
   @s_ssn               int,
   @w_sp_name           varchar(30),
   @w_mensaje           varchar(100),
   @w_operacionca       int,
   @w_operacionca_sgte  int,
   @w_desbloquea        tinyint,
   @w_banco             varchar(24)
   
-- VARIABLES INICIALES
select   @w_sp_name    = 'sp_valida_pago_cuota'
  
select @w_operacionca = 0,
       @w_desbloquea  = 0,
       @w_mensaje = ''

select @w_operacionca = max(op_operacion)
from ca_operacion
where op_cuenta = @i_cuenta
  and op_estado not in (3, 0, 99) 
  and op_toperacion in (select b.codigo from cobis..cl_tabla a, cobis..cl_catalogo b
                        where a.tabla = 'ca_bloqueo_toperacion'
                        and  a.codigo = b.tabla
                        and  b.estado = 'V')

                        -- Verificar si la cuota 1 estÃ¡ cancelada
if exists(select 1 from ca_dividendo 
           where di_operacion = @w_operacionca
          and   di_dividendo = 1
          and   di_estado != 3)
begin
    select @w_banco = op_banco
    from ca_operacion
    where op_operacion = @w_operacionca
    
    select @w_desbloquea = 1,
           @w_mensaje = 'Cuenta asociada al prestamo Nro. ' + @w_banco + ', sin pago del primer dividendo'
end

                                
select @o_desbloquea = @w_desbloquea,
       @o_mensaje = @w_mensaje
       
return 0
