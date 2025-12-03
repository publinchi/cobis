/******************************************************************/
/*  Archivo:            interfinc_srv.sp                          */
/*  Stored procedure:   sp_interface_incentivos_srv               */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Adriana Giler                             */
/*  Fecha de escritura: 22-Jul-2019                               */
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
/*   - Interface de Incentivos de creditos                        */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  22/Jul/19        Adriana Giler      Interface Incentivos      */
/******************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_interface_incentivos_srv')
   drop proc sp_interface_incentivos_srv
go

create proc sp_interface_incentivos_srv
   @s_ssn                  int,
   @s_date                 datetime,
   @s_user                 login,
   @s_ofi                  smallint,
   @t_trn                  int          = 77518,
   @i_interfaz             char(1),
   @i_tipo_operacion       char(1),     --C: crédito, D: débito
   @i_causa                varchar(10) ,
   @i_monto                money
   

as declare
   @w_sp_name              varchar(30),
   @w_error                int
   
   if not exists (select 1 from cob_cartera..ca_interf_op_tmp
                  where iot_sesn = @s_ssn)
    begin
        select @w_error = 725002
        goto ERROR
    end

    if isnull(@i_tipo_operacion,'') = '' or isnull(@i_causa,'') = '' or isnull(@i_monto,0)= 0
    begin
        select @w_error = 725060
        goto ERROR
    end
    
      
    insert cob_cartera..ca_interf_incentivo_tmp ( 
    iic_sesn,       iic_user,           iic_ofi,    iic_fecha_proceso, 
    iic_interfaz,   iic_tipo_operacion, iic_causa,  iic_monto )
	values (
    @s_ssn,        @s_user,            @s_ofi,       @s_date,
    @i_interfaz,   @i_tipo_operacion,  @i_causa,     @i_monto)
       
    if @@error <> 0
    begin
       select @w_error = 725060
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

