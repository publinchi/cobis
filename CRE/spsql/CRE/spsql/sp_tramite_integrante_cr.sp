/**************************************************************************/
/*  Archivo:                    sp_tramite_integrante_cr.sp               */
/*  Stored procedure:           sp_tramite_integrante_cr                  */
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
/*  27/Jul/2021   Dilan Morales          implementacion                   */
/*  02/Abr/2024   Dilan Morales          R229984:Se añade i_pago_solidario*/
/*  30/Sep/2024   Dilan Morales        R244659:Se añade nolock ca_operacion*/
/**************************************************************************/
use cob_credito
go

IF OBJECT_ID ('sp_tramite_integrante_cr') IS NOT NULL
    DROP PROCEDURE sp_tramite_integrante_cr
GO

CREATE proc sp_tramite_integrante_cr (
    @s_ssn                  int             = null,
    @s_sesn                 int             = null,
    @s_culture              varchar(10)     = null,
    @s_user                 login           = null,
    @s_term                 varchar(30)     = null,
    @s_date                 datetime        = null,
    @s_srv                  varchar(30)     = null,
    @s_lsrv                 varchar(30)     = null,
    @s_ofi                  smallint        = null,
    @s_rol                  smallint        = NULL,
    @s_org_err              char(1)         = NULL,
    @s_error                int             = NULL,
    @s_sev                  tinyint         = NULL,
    @s_msg                  descripcion     = NULL,
    @s_org                  char(1)         = NULL,
    @t_show_version         bit             = 0,    -- Mostrar la version del programa
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  int             = null,
    @i_operacion            char(1),                -- Opcion con que se ejecuta el programa
    @i_tramite_grupal       int             = NULL,
    @i_pago_solidario       char(1)         = 'N'  
)
as
declare @w_sp_name              varchar(32),
        @w_error                int,
        @w_banco_padre          varchar(24)
select @w_sp_name = 'sp_tramite_integrante_cr'
if @i_operacion = 'Q'
begin

   select @w_banco_padre = op_banco from    cob_cartera..ca_operacion with(nolock) where op_tramite = @i_tramite_grupal
   
   if @w_banco_padre is null
   begin
            select @w_error = 2110122
            goto ERROR
    end 
    
    if @i_pago_solidario = 'S'
    begin
        SELECT  'OPERACION' =   op_operacion,
            'CODIGO'    =   en_ente,
            'TRAMITE'   =   op_tramite+'', 
            'NOMBRE'    =   isnull(en_nombre,'') + ' ' + isnull(p_s_nombre,'') + ' ' + isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,''),
            'PARTICIPA' =   tg_participa_ciclo
        FROM cob_cartera..ca_operacion with(nolock)
        inner join cob_credito..cr_tramite_grupal on tg_operacion = op_operacion
        inner join cobis..cl_ente on op_cliente = en_ente
        where op_ref_grupal = @w_banco_padre 
        and tg_participa_ciclo = 'S'
        and exists(select 1 from cob_credito..cr_op_renovar where or_tramite = op_tramite)
        
        if @@rowcount =0
        begin
            select @w_error = 2110122
            goto ERROR
        end
    end
    else 
    begin
        SELECT  'OPERACION' =   op_operacion,
            'CODIGO'    =   en_ente,
            'TRAMITE'   =   op_tramite+'', 
            'NOMBRE'    =   isnull(en_nombre,'') + ' ' + isnull(p_s_nombre,'') + ' ' + isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,''),
            'PARTICIPA' =   tg_participa_ciclo
        FROM cob_cartera..ca_operacion with(nolock)
        inner join cob_credito..cr_tramite_grupal on tg_operacion = op_operacion
        inner join cobis..cl_ente on op_cliente = en_ente
        where op_ref_grupal = @w_banco_padre 
        and tg_participa_ciclo = 'S'
        
        if @@rowcount =0
        begin
            select @w_error = 2110122
            goto ERROR
        end
    end
end
return 0

ERROR:
    begin --Devolver mensaje de Error
        select @w_error
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = @w_error

        return @w_error
    end

GO
