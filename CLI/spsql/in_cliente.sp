/************************************************************************/
/*   Stored procedure:     sp_in_cliente                                */
/*   Base de datos:        cobis                                        */
/*   Producto:             CLIENTES                                     */
/*   Disenado por:         ALD                                          */
/*   Fecha de escritura:   30-Abril-2019                                */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de 'COBISCorp'.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                            PROPOSITO                                 */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*  FECHA       AUTOR               RAZON                               */
/*  30/04/19    ALD                 Version Inicial Te Creemos          */
/*  11/06/20    MBA                 Estandarizacion sp y seguridades    */
/* **********************************************************************/

use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select *
             from sysobjects
            where type = 'P'
              and name = 'sp_in_cliente')
  drop proc sp_in_cliente
go

create proc sp_in_cliente(
       @t_debug         char(1)     = 'N',
       @t_file          varchar(14) = null,
       @t_from          varchar(32) = null,
       @t_show_version  bit         = 0,
       @t_trn           int         = 172120,
       @i_cli           int,
       @i_dprod         int,
       @i_rol           char(1),
       @i_cedruc        varchar(35),
       @i_fecha         datetime,
       @i_validar       char(1)     = 'S'
)
as
declare @w_return       int,
        @w_sp_name      varchar(30),
        @w_ctacte       int,
        @w_cta_banco    varchar(20),
        @w_cliente      int,
        @w_det_producto int,
        @w_rol          char(1),
        @w_fecha        datetime,
        @w_sp_msg       varchar(132)

/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_in_cliente'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
  begin
    select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
    select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
    print  @w_sp_msg
    return 0
  end
/*--FIN DE VERSIONAMIENTO--*/ 

/* Chequeo de existencias */  
-- El parametro @i_validar se aniade porque se  pueden crear cuentas  
-- a companias sin rif    MSA  
if @i_validar = 'N'
  begin
    select @w_cliente = en_ente
      from cobis..cl_ente
     where en_ente = @i_cli
    if @@rowcount = 0
      begin
        /* No existe ente */
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 1720109
        return 1720109
      end
  end
else if @i_validar = 'S'
  begin
    select @w_cliente = en_ente
      from cobis..cl_ente
     where en_ente    = @i_cli
       and en_ced_ruc = @i_cedruc
    if @@rowcount = 0
      begin
        select @w_cliente = en_ente
          from cobis..cl_ente
         where en_ente     = @i_cli
           and p_pasaporte = @i_cedruc
        if @@rowcount = 0
          begin
            /* No existe ente */
            exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 1720109
            return 1720109
          end
      end
  end

/* Insercion en la tabla cl_cliente */
-- VALIDACION DE TRANSACCIONES
if (@t_trn <> 172120)
  begin
    exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720075                  
         --NO CORRESPONDE CODIGO DE TRANSACCION
    return 1720075
  end
                                                                                                                                                                                                                                                           
/* Insercion en la tabla cl_cliente */
begin tran

insert into cobis..cl_cliente
       (cl_cliente,        cl_det_producto,      cl_rol,
        cl_ced_ruc,        cl_fecha)
values (@i_cli,            @i_dprod,             @i_rol,
        @i_cedruc,         @i_fecha)
if @@error <> 0
  begin
    /* Error en creacion de registro en cl_cliente */
    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 1720010
    return 1720010
  end

commit tran

return 0

go                                                                                                                                                                                                                                                      
                                                                                                                                                                                                                   