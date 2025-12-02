/******************************************************************/
/*  Archivo:            interfdes_srv.sp                          */
/*  Stored procedure:   sp_interface_desemb                       */
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
/*  30/May/19        Lorena Regalado    Interface Creacion Desembo*/
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_interface_desemb')
   drop proc sp_interface_desemb
go

create proc sp_interface_desemb
   @i_interfaz             char(1),
   @s_sesn                 int,
   @s_date                 datetime,
   @s_user                 login,
   @s_ofi                  smallint,
   @t_trn                  int          = null,
   @i_tipo_operacion       char(1),
   @i_causa                varchar(10),
   @i_monto                money

   

as declare
   @w_sp_name              varchar(30),
   @w_error                int
   
 

    insert into cob_cartera..ca_interface_des_tmp  values (
    @s_sesn,       @s_user,            @s_ofi,    @s_date,
    @i_interfaz,   @i_tipo_operacion,  @i_causa,   @i_monto,
    NULL)
       
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

