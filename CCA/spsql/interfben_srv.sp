/******************************************************************/
/*  Archivo:            interfben_srv.sp                          */
/*  Stored procedure:   sp_interface_benef_srv                    */
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
/*   - Interface de Creacion de beneficiarios                     */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  30/May/19        Lorena Regalado    Interface Creacion Benef  */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_interface_benef_srv')
   drop proc sp_interface_benef_srv
go

create proc sp_interface_benef_srv
   @i_secuencial           int,
   @s_date                 datetime,
   @s_user                 login,
   @s_ofi                  smallint,
   @t_trn                  int          = 7472,
   @i_interfaz             char(1),
   @i_cliente              int,
   @i_tipo_seguro          catalogo,
   @i_nombres              varchar(30),  --validar en el mis
   @i_apellido_paterno     varchar(16),
   @i_apellido_materno     varchar(16),
   @i_fecha_nacimiento     datetime,
   @i_porcentaje           float,
   @i_parentesco           varchar(10),
   @i_calle                varchar(100),
   @i_nro_exterior         varchar(15),
   @i_nro_interior         varchar(15),
   @i_codigo_postal        varchar(5),
   @i_colonia              varchar(10),
   @i_telefono             varchar(15)
   
   


as declare
   @w_sp_name              varchar(30),
   @w_error                int
   

    insert cob_cartera..ca_interf_benef_tmp  (
	ibt_sesn,            ibt_user,              ibt_ofi,               ibt_fecha_proceso,
	ibt_interfaz,        ibt_cliente,           ibt_tipo_seguro,       ibt_nombres,	         ibt_apellido_paterno,
	ibt_apellido_materno,ibt_fecha_nacimiento,  ibt_porcentaje,        ibt_parentezco,       ibt_operacion,
	ibt_calle,           ibt_nro_exterior,      ibt_nro_interior,      ibt_codigo_postal,    ibt_colonia,     
	ibt_telefono)
	values (
    @i_secuencial,      @s_user,                @s_ofi,                @s_date,
    @i_interfaz,        @i_cliente,             @i_tipo_seguro,	       @i_nombres,            @i_apellido_paterno,             
    @i_apellido_materno,@i_fecha_nacimiento,    @i_porcentaje,         @i_parentesco,	      NULL,
	@i_calle,           @i_nro_exterior,        @i_nro_interior,       @i_codigo_postal,      @i_colonia,
	@i_telefono)

       
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

