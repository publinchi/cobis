/******************************************************************/
/*  Archivo:            interfopi_srv.sp                          */
/*  Stored procedure:   sp_interface_opindiv_srv                  */
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
/*   - Interface de Creacion de Operaciones                       */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  30/May/19        Lorena Regalado    Interface Creacion Grupal */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_interface_opindiv_srv')
   drop proc sp_interface_opindiv_srv
go

create proc sp_interface_opindiv_srv
   @i_secuencial           int,
   @s_date                 datetime,
   @s_user                 login,
   @s_ofi                  smallint,
   @t_trn                  int = 7470,
   @i_interfaz             char(1),
   @i_cliente              int,
   @i_monto                money,
   @i_rol                  char(1),
   @i_destino              varchar(10)

   

as declare
   @w_sp_name              varchar(30),
   @w_error                int
   
  
    
    insert cob_cartera..ca_interf_hijas_tmp  (
	iht_sesn,   iht_user,      iht_ofi,        iht_fecha_proceso,  iht_interfaz, iht_cliente,
	iht_monto,  iht_rol,       iht_destino_eco,iht_operacion)
	values (
    @i_secuencial,     @s_user,       @s_ofi,    @s_date,    @i_interfaz,   @i_cliente,
    @i_monto,   @i_rol,        @i_destino,NULL)
       
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

