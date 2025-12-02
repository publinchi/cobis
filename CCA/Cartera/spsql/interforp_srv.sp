/******************************************************************/
/*  Archivo:            interforp_srv.sp                          */
/*  Stored procedure:   sp_interface_ordenp_srv                   */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 30-May-2019                               */
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
/*   - Interface de Creacion de Seguros                           */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  30/May/19        Lorena Regalado    Interface Creacion Benef  */
/******************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_interface_ordenp_srv')
   drop proc sp_interface_ordenp_srv
go


create proc sp_interface_ordenp_srv
   @i_secuencial           int,
   @s_date                 datetime,
   @s_user                 login,
   @s_ofi                  smallint,
   @t_trn                  int          = 7473,
   @i_interfaz             char(1),
   @i_cliente              int,
   @i_monto_desembolso     money,
   @i_tipo_orden           catalogo,
   @i_banco                catalogo,  
   @i_lote                 varchar(15)

   
   

as declare
   @w_sp_name              varchar(30),
   @w_error                int
   
      
    insert cob_cartera..ca_interf_ordenp_tmp (
    iot_sesn,         iot_user,           iot_ofi,              iot_fecha_proceso,
	iot_interfaz,     iot_cliente,        iot_monto_desembolso, iot_tipo_orden,
	iot_banco,        iot_operacion,      iot_oper_hija,        iot_lote)
	values (
    @i_secuencial,    @s_user,            @s_ofi,                @s_date,
    @i_interfaz,      @i_cliente,         @i_monto_desembolso,   @i_tipo_orden,
    @i_banco,         NULL,               NULL,                  @i_lote)
       
    if @@error <> 0
    begin
       select @w_error = 708165
       goto ERROR
    end
 
   

return 0

ERROR:
     
    
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error
   
   return @w_error
   
go

