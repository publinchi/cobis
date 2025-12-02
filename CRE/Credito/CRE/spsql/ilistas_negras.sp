/************************************************************************/
/*  Archivo:                ilistas_negras.sp                           */
/*  Stored procedure:       sp_ilistas_negras                           */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*  Realiza la insercion de las malas referencias recibidas             */
/*  de Quien es Quien.                                                  */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  08/AGO/2017       PRomero          EMISION INICIAL                  */
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_ilistas_negras')
    drop proc sp_ilistas_negras
go

create proc sp_ilistas_negras (
    @s_ssn       int         = null,
    @s_sesn      int         = null,
    @s_ofi       smallint    = null,
    @s_rol       smallint    = null,
    @s_user      login       = null,
    @s_date      datetime    = null,
    @s_term      descripcion = null,
    @t_debug     char(1)     = 'N',
    @t_file      varchar(10) = null,
    @t_from      varchar(32) = null,
    @s_srv       varchar(30) = null,
    @s_lsrv      varchar(30) = null,
    @s_culture   varchar(10) = null,
    @s_org       varchar(5)  = null,
    @i_operacion char(2),
    @i_fecha_reg            datetime  = null,
    @i_id_lista             varchar(25)  = null,
    @i_nombre               varchar(100)  = null,
    @i_apellido_paterno     varchar(100)  = null,
    @i_apellido_materno     varchar(100)  = null,
    @i_curp                 varchar(20)  = null,
    @i_rfc                  varchar(15)  = null,
    @i_fecha_nac            datetime  = null,
    @i_tipo_lista           varchar(10)  = null,
    @i_estado               varchar(20)  = null,
    @i_dependencia          varchar(200)  = null,
    @i_puesto               varchar(200)  = null,
    @i_iddispo              varchar(10)  = null,
    @i_curp_ok              varchar(8)  = null,
    @i_id_rel               varchar(25)  = null,
    @i_parentesco           varchar(20)  = null,
    @i_razon_social         varchar(250)  = null,
    @i_rfc_moral            varchar(15)  = null,
    @i_num_seg_social       varchar(50)  = null,
    @i_imss                 varchar(50)  = null,
    @i_ingresos             varchar(20)  = null,
    @i_nom_completo         varchar(300)  = null,
    @i_apellidos            varchar(200)  = null,
    @i_entidad              varchar(50)  = null,
    @i_sexo                 varchar(10)  = null,
    @i_area                 varchar(100) = null,
    @o_id                   int         = null out
)
as
declare
   @w_sp_name           varchar(20),
   @w_id                int,
   @w_return            int,
   @w_mensaje           varchar(30)

if(@i_operacion ='I')
BEGIN

    if exists(select 1 from cob_credito..cr_lista_negra where ln_fecha_reg  < CONVERT(date, getdate()))
    BEGIN
        --SE ELIMINA REGISTROS DE CARGA ANTERIOR
        delete from cob_credito..cr_lista_negra
        where ln_fecha_reg  < CONVERT(date, getdate())

        --SE ACTUALIZA SEQNOS
        /*update cobis..cl_seqnos
        set siguiente = 0
        where tabla ='cr_lista_negra'*/
    END

    exec @w_return  = cobis..sp_cseqnos
      @t_debug   = @t_debug,
	  @t_file    = @t_file,
	  @t_from    = @w_sp_name,
	  @i_tabla   = 'cr_lista_negra',
	  @o_siguiente = @w_id out

    if @w_return > 0
      begin
         exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from = @w_sp_name,
            @i_num  = @w_return
            return @w_return
      end

    INSERT INTO cr_lista_negra
        (ln_id,
        ln_fecha_reg,
        ln_id_lista,
        ln_nombre,
        ln_apellido_paterno,
        ln_apellido_materno,
        ln_curp,
        ln_rfc,
        ln_fecha_nac,
        ln_tipo_lista,
        ln_estado,
        ln_dependencia,
        ln_puesto,
        ln_iddispo,
        ln_curp_ok,
        ln_id_rel,
        ln_parentesco,
        ln_razon_social,
        ln_rfc_moral,
        ln_num_seg_social,
        ln_imss,
        ln_ingresos,
        ln_nom_completo,
        ln_apellidos,
        ln_entidad,
        ln_sexo,
        ln_area)
    VALUES
        (
            @w_id,
            getDate(),
            @i_id_lista ,
            @i_nombre ,
            @i_apellido_paterno,
            @i_apellido_materno,
            @i_curp,
            @i_rfc,
            @i_fecha_nac,
            @i_tipo_lista,
            @i_estado,
            @i_dependencia ,
            @i_puesto ,
            @i_iddispo,
            @i_curp_ok,
            @i_id_rel ,
            @i_parentesco,
            @i_razon_social,
            @i_rfc_moral  ,
            @i_num_seg_social,
            @i_imss ,
            @i_ingresos,
            @i_nom_completo ,
            @i_apellidos,
            @i_entidad,
            @i_sexo,
            @i_area
        )

    if @@error != 0
    begin
        exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2103001
        return 2103001
    end

    select @o_id=@w_id
end

return 0
go
