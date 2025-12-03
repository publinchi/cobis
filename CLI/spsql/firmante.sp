
/************************************************************************/
/*  Archivo:            firmantes.sp                                    */
/*  Stored procedure:   sp_firmantes                                    */
/*  Base de datos:       	cobis                   					*/
/*  Producto:               Clientes              					    */
/*  Disenado por: 			T. Baidal    		                        */
/*  Fecha de escritura: 	13-07-2016	               		 	        */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                              PROPOSITO                               */
/* Este programa es un extracto del sp sp_firmantes operacion 'D'       */
/* para dar solucion de dependencia al eliminar un propietario en la    */
/* pantalla de actualizacion de Cuenta(FTRAN202) -  bug 77278           */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*      FECHA           AUTOR           RAZON                           */
/*  13/Jul/2016 T. Baidal       Emision inicial                         */
/*  20-01-2021  GCO   	        Estandarizacion de clientes             */
/************************************************************************/
use cobis
go
if exists (select 1 from sysobjects where name = 'sp_firmantes')
    drop proc sp_firmantes
go

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE proc sp_firmantes (
    @s_ssn         int,
    @s_srv         varchar(30),
    @s_lsrv        varchar(30),
    @s_user        varchar(30),
    @s_sesn        int,
    @s_term        varchar(64),
    @s_date        datetime,
    @s_ofi         smallint,
    @s_rol         smallint,
    @s_org_err     char(1)     = null,
    @s_error       int         = null,
    @s_sev         tinyint     = null,
    @s_msg         varchar(255)= null,
    @s_org         char(1),
    @s_culture     varchar(10)   = 'NEUTRAL',     
    @t_debug       char(1)     = 'N',
    @t_file        varchar(14) = null,
    @t_from        varchar(32) = null,
    @t_trn         smallint,
    @t_show_version       bit           = 0,     -- mostrar la version del programa    
    @p_lssn        int         = null,
    @p_rssn        int         = null,
    @i_cuenta      varchar(24) = null,
    @i_producto    char(3)     = null,
    @i_moneda      smallint    = null,
    @i_ente        int         = null,
    @i_cedula      varchar(20) = null,
    @i_operacion   char(1),
    @i_rol         char(1)     = 'F'
)
as
declare @w_return   int,
    @w_sp_name      varchar(30),
    @w_ente         int,
    @w_transaccion  int,
    @w_transervicio int,
    @w_det_prod     int,
    @w_producto     TINYINT,
    @w_sp_msg       varchar(132)

/* Captura nombre de Stored Procedure  */
select  @w_sp_name = 'sp_firmantes'

/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

/* ** Delete ** */
if @i_operacion = 'D'
begin
    /* Validacion de transaccion */
    if @t_trn <> 172149
    begin
        exec cobis..sp_cerror
        @t_debug   = @t_debug,
        @t_file    = @t_file,
        @t_from    = @w_sp_name,
	    @s_culture = @s_culture,	        
        @i_num   = 1720070
        return 1
    end

    SELECT @w_producto = 0
    SELECT @w_producto = isnull(pd_producto,0) 
    FROM cobis..cl_producto
    WHERE pd_abreviatura = @i_producto

    IF @@ROWCOUNT = 0 OR @w_producto = 0
    BEGIN
            exec cobis..sp_cerror
            @t_debug   = @t_debug,
            @t_file    = @t_file,
            @t_from    = @w_sp_name,
	        @s_culture = @s_culture,	        
            @i_num   = 1720432
        return 1
    END
    

    select @w_det_prod = dp_det_producto
    from   cobis..cl_det_producto
    where  dp_cuenta   = @i_cuenta
    and    dp_producto = @w_producto
    and    dp_moneda   = @i_moneda

    if @@rowcount = 0
    begin
       /* No existe cuenta_banco */
       exec cobis..sp_cerror
       @t_debug     = @t_debug,
       @t_file      = @t_file,
       @t_from      = @w_sp_name,
       @i_num       = 1720100,
       @i_sev       = 0
       return 1
    end  

    select @w_ente = cl_cliente
    from  cobis..cl_cliente
    where cl_det_producto = @w_det_prod
    and   cl_cliente      = @i_ente

    if @@rowcount = 0
    begin
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file = @t_file,
       @t_from = @w_sp_name,
       @i_num = 1720434
       return 1    
    end

    begin tran
      delete cobis..cl_cliente
      where  cl_det_producto = @w_det_prod
      and    cl_cliente      = @i_ente
      and    cl_rol          = @i_rol

      if @@error <> 0
      begin
         /* Fallo delete */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 1720435
         return 1
      end      
     
    commit tran
    return 0
end

go

