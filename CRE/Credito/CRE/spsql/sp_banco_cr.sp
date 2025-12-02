/**************************************************************************/
/*  Archivo:                    sp_banco_cr.sp                            */
/*  Stored procedure:           sp_banco_cr                               */
/*  Base de Datos:              cob_credito                               */
/*  Producto:                   Credito                                   */
/**************************************************************************/
/*                          IMPORTANTE                                    */
/*  Este programa es parte de los paquetes bancarios propiedad de         */
/*  'COBISCORP'.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como            */
/*  cualquier autorizacion o agregado hecho por alguno de sus             */
/*  usuario sin el debido consentimiento por escrito de la                */
/*  Presidencia Ejecutiva de COBISCORP o su representante.                */
/**************************************************************************/
/*                          PROPOSITO                                     */
/*  Este stored procedure permite obtener registros de la tabla           */
/*    cob_bancos..ba_banco                                                */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA          AUTOR                            RAZON                 */
/*  27/Jul/2021   Dilan Morales           implementacion                  */
/**************************************************************************/
use cob_credito
go


IF OBJECT_ID ('dbo.sp_banco_cr') IS NOT null
    DROP PROCEDURE dbo.sp_banco_cr
GO

create PROCEDURE sp_banco_cr
(
    @t_show_version         bit             = 0, 
    @s_ssn                  int             = null, 
    @s_srv                  varchar(30)     = null, 
    @s_lsrv                 varchar(30)     = null, 
    @s_date                 datetime        = null, 
    @s_user                 login           = null, 
    @s_term                 descripcion     = null, 
    @s_corr                 char(1)         = null, 
    @s_ssn_corr             int             = null, 
    @s_ofi                  smallint        = null, 
    @t_rty                  char(1)         = null, 
    @t_trn                  int             = null, 
    @t_debug                char(1)         = 'N', 
    @t_file                 varchar(14)     = null, 
    @t_from                 varchar(30)     = null, 
    @i_operacion            char(1), 
    @i_modo                 smallint        = null,
    @i_tipo                 char(6)         = null,
    @i_formato_fecha        int             = 103
) AS

    DECLARE
        @w_mensaje      varchar(80), 
        @w_return       int, /*  valor que retorna  */        
        @w_sp_name      varchar(32), /*  descripcion del stored procedure */   
        @w_tipo_banco   char(1)
    
    SELECT @w_sp_name = 'sp_banco_cr'
    
    IF (@t_show_version = 1)
    BEGIN
        SELECT @w_mensaje = 'Stored procedure sp_banco, Version 1.0.0'
        
        PRINT CONVERT(VARCHAR, @w_mensaje)
        
        RETURN 0
    END
    PRINT '@t_trn: ' +convert(VARCHAR(100),@t_trn)
    IF (@t_trn <> 775073 AND @i_operacion = 'Q')
    BEGIN
        /*  Tipo de transaccion no corresponde  */
        EXEC cobis..sp_cerror 
            @t_debug = @t_debug, 
            @t_file = @t_file, 
            @t_from = @w_sp_name, 
            @i_num = 801077
        
        RETURN 1
    END
    
    IF (@i_operacion = 'Q')
    BEGIN
        if(@i_tipo = 'MOE')
        begin
            select @w_tipo_banco = 'M'
        end
        
        if(@i_tipo = 'DESCOR')
        begin
            select @w_tipo_banco = 'B'
        end
    
    
        select 
            'ba_codigo'         = ba_codigo,
            'ba_nombre'         = ba_nombre,
            'ba_tipo'           = ba_tipo,
            'ba_ifi'            = ba_ifi,
            'ba_transito'       = ba_transito,
            'ba_usuario'        = ba_usuario,
            'ba_fecha_crea'     = CONVERT(CHAR(10), ba_fecha_crea, @i_formato_fecha),
            'ba_fecha_actual'   = CONVERT(CHAR(10), ba_fecha_actual, @i_formato_fecha)
        
        from cob_bancos..ba_banco
        where ba_tipo = @w_tipo_banco or @w_tipo_banco is null
        
        IF (@@rowcount = 0)
        BEGIN
            
            /*  No existen bancos  */
            EXEC cobis..sp_cerror 
                @t_debug = @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num = 171007
            
            RETURN 1
        END
        
        RETURN 0
    END

GO

