/******************************************************************/
/*  Archivo:            interfseg_srv.sp                          */
/*  Stored procedure:   sp_interface_seguros_srv                  */
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
/*  30/May/19        Lorena Regalado    Interface Creacion Seguros*/
/******************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_interface_seguros_srv')
   drop proc sp_interface_seguros_srv
go

create proc sp_interface_seguros_srv
   @i_secuencial           int,
   @s_date                 datetime,
   @s_user                 login,
   @s_ofi                  smallint,
   @t_trn                  int          = 7471,
   @i_interfaz             char(1),
   @i_cliente              int,
   @i_categoria            catalogo,    --tipo seguro
   @i_monto_seguro         money,    
   @i_fecha_vig_ini        datetime     = null,
   @i_fecha_vig_fin        datetime     = null,
   @i_folio                varchar(64)  = null

   

as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_fecha_desemb         datetime
   
   if @i_fecha_vig_ini is null
   begin
        select @w_fecha_desemb = iot_fecha_desemb 
        from cob_cartera..ca_interf_op_tmp
        where iot_sesn = @i_secuencial

        if @@rowcount = 0
        begin
            select @w_error = 725002
            goto ERROR
        end

        select @i_fecha_vig_ini = @w_fecha_desemb

   end

      
    insert cob_cartera..ca_interf_seguros_tmp ( 
	ist_sesn,      ist_user,           ist_ofi,               ist_fecha_proceso,
	ist_interfaz,  ist_cliente,        ist_tipo_seguro,       ist_monto_seguro,
	ist_fecha_inicial,  ist_fecha_final, ist_operacion,         ist_folio)
	values (
    @i_secuencial, @s_user,            @s_ofi,                @s_date,
    @i_interfaz,   @i_cliente,         @i_categoria,          @i_monto_seguro,
    @i_fecha_vig_ini,@i_fecha_vig_fin,   NULL,				  @i_folio)
       
    if @@error <> 0
    begin
       select @w_error = 725049
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

