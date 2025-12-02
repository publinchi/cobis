/***********************************************************************/
/*      Archivo:                        sp_grupo_tran_castigo.sp       */
/*      Stored procedure:               sp_grupo_tran_castigo          */
/*      Base de Datos:                  cob_credito                    */
/*      Producto:                       Credito                        */
/*      Disenado por:                   Jose Escobar                   */
/***********************************************************************/
/*        IMPORTANTE                                                   */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "COBISCORP", representantes exclusivos para el Ecuador de la       */
/*  "COBISCORP CORPORATION".                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier alteracion o agregado hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de la            */
/*  Presidencia Ejecutiva de COBISCORP o su representante.             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*  Mantenimiento a la tabla grupo_tran_castigo que tiene la cabecera  */
/*  con los paquetes de operaciones para proceso de Castigo            */
/*                                                                     */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/*      05/Ago/2015     Jose Escobar            Emision Inicial        */
/*                                                                     */
/***********************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_grupo_tran_castigo')
    drop proc sp_grupo_tran_castigo
go

create proc sp_grupo_tran_castigo (
    @s_ssn                  int         = null,
    @s_srv                  varchar(30) = null,
    @s_rol                  smallint    = null,
    @s_org                  char(1)     = null,
    @s_user                 login       = null,
    @s_sesn                 int         = null,
    @s_ofi                  int         = null,
    @s_date                 datetime    = null,
    @s_term                 varchar(30) = null,
    @t_trn                  smallint    = null,
    @t_debug                char(1)     = 'N',
    @t_file                 varchar(14) = null,
    @t_from                 varchar(30) = null,
    @i_ssn                  int         = 0,
    @i_operacion            char(1)     = null,
    @i_tran_castigo         int         = null,
    @i_recomendada          char(1)     = null,
    @i_observacion          varchar(255)= null
)

as
declare @w_sp_name              varchar(32),
        @w_error                int,
        @w_grupo                int,
        @w_padre                int,
        @w_estado               char(1),
        @w_emplazamiento        catalogo

set @w_sp_name = 'sp_grupo_tran_castigo'

if (@t_trn <> 22314 and @i_operacion = 'T')
begin --Tipo de transaccion no corresponde
   select @w_error = 2101006
   goto ERROR
end


if @i_operacion = 'T' /* Insercion del registro temporal*/
begin
    if @i_ssn = 0 -- null
    begin
        set @i_ssn = @s_ssn
    end

    BEGIN TRAN
        insert into  cr_grupo_tran_castigo_tmp
              ( gtm_grupo , gtm_tran_castigo , gtm_recomendada )
        values( @i_ssn    , @i_tran_castigo  , @i_recomendada  )
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2103001
            goto ERROR
        end

        if @i_recomendada = 'N'
        begin
            insert into cr_observacion_castigo_tmp
                  ( oct_grupo , oct_tran_castigo , oct_observacion )
            values( @i_ssn    , @i_tran_castigo  , @i_observacion  )
            if @@error <> 0
            begin
                ROLLBACK TRAN
                select @w_error = 2103001
                goto ERROR
            end
        end
        else
        begin
            delete cr_observacion_castigo_tmp
            where  oct_grupo        = @i_ssn
            and    oct_tran_castigo = @i_tran_castigo
            if @@error <> 0
            begin
                ROLLBACK TRAN
                select @w_error = 710003
                goto ERROR
            end
        end

        select 'ssn' = @i_ssn
    COMMIT tran
    return 0
end --FIN - @i_operacion = 'T'


return 0

ERROR:
    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = @w_error
    return @w_error


go
