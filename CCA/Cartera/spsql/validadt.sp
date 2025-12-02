/******************************************************************/
/*  Archivo:            validadt.sp                               */
/*  Stored procedure:   sp_valida_datos                           */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 04-Jun-2019                               */
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
/*  04/Jun/19        Lorena Regalado    Valida datos en tablas    */
/*                                      Temporales                */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_valida_datos')
   drop proc sp_valida_datos
go

create proc sp_valida_datos
   @i_secuencial           int,
   @s_sesn                 int            = null,
   @s_ssn                  int            = null,
   @s_user                 login,
   @s_term                 varchar(30)    = null,
   @s_date                 datetime       = NULL,
   @i_banco                cuenta         = NULL,      --Operacion Grupal para los interciclos
   @i_es_interciclo        char(1)        = 'N',
   @o_fecha_primer_pago    datetime       = NULL out,   --Solo para operaciones de interciclo
   @o_mensaje_error        varchar(500)   = NULL out 



as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_fecha_primer_pago    datetime,
   @w_mensaje              varchar(500)
   
------------------------------------------------ 
--VALIDA DATOS DE INTERFACE EN TABLAS TEMPORALES
------------------------------------------------     



--Valido Datos Operacion Padre

execute @w_error = sp_valida_op_tmp
 @i_secuencial = @i_secuencial,
 @i_es_interciclo =  @i_es_interciclo,
 @o_fecha_primer_pago = @w_fecha_primer_pago out  --solo para operaciones de interciclo

print 'Estoy en Valida datos : ' + cast(@w_fecha_primer_pago as varchar)

select @o_fecha_primer_pago = @w_fecha_primer_pago

if @w_error <> 0
begin
 select @w_mensaje = mensaje from cobis..cl_errores
 where numero = @w_error
 select @o_mensaje_error = @w_mensaje
 
 return @w_error 
end 

--print 'A'
if @i_banco is NULL
begin
  --Valido Datos Operaciones Hijas
  execute @w_error = sp_valida_op_ind_tmp
          @i_secuencial = @i_secuencial,
          @s_ssn        = @s_ssn,
          @s_sesn       = @s_sesn,
          @s_user       = @s_user,
          @s_term       = @s_term,
          @s_date       = @s_date


  if @w_error <> 0 
  begin
     select @w_mensaje = mensaje from cobis..cl_errores
	 where numero = @w_error
     select @o_mensaje_error = @w_mensaje
	 return @w_error   --goto ERROR 
  end 	 

end

--print 'B'

--Valido Datos de Seguros
execute @w_error = sp_valida_seguros_tmp
@i_secuencial = @i_secuencial,
@o_mensaje_error = @w_mensaje out   --LRE 01AGO2019

if @w_error <> 0 
begin
   /*select @w_mensaje = mensaje from cobis..cl_errores
   where numero = @w_error */

   select @o_mensaje_error = @w_mensaje
   return @w_error
end 

--print 'C'

--Valido Datos de Beneficiarios
execute @w_error = sp_valida_benef_tmp
@i_secuencial = @i_secuencial,
@o_mensaje_error = @w_mensaje out   --LRE 01AGO2019


if @w_error <> 0 
begin
   /*select @w_mensaje = mensaje from cobis..cl_errores
   where numero = @w_error */

   select @o_mensaje_error = @w_mensaje
   return @w_error
end 

--print 'D'

--Valido Datos de Ordenes de Pago
execute @w_error = sp_valida_orden_pago_tmp
@i_secuencial = @i_secuencial,
@o_mensaje_error = @w_mensaje out   --LRE 01AGO2019

if @w_error <> 0 
begin
--print 'error al validar orp'
  /* select @w_mensaje = mensaje from cobis..cl_errores
   where numero = @w_error */

   select @o_mensaje_error = @w_mensaje
   return @w_error
end

--print 'E'
  

return 0

ERROR:

        
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error,
    @i_msg    = ' Error en Validacion de Informacion Operaciones Hijas',
    @i_sev    = 0
   
   return @w_error
   
go

