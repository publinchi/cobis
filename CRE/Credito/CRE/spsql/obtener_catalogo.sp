/************************************************************************/
/*  Archivo:                obtener_catalogo.sp                         */
/*  Stored procedure:       sp_obtener_catalogo                         */
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
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_obtener_catalogo')
    drop proc sp_obtener_catalogo
go

create proc sp_obtener_catalogo (
	@s_ssn			int         = null,
	@s_user			login       = null,
	@s_sesn			int         = null,
	@s_term			varchar(32) = null,
	@s_date			datetime    = null,
	@s_srv			varchar(30) = null,
	@s_lsrv			varchar(30) = null,
	@s_rol			smallint    = null,
	@s_ofi			smallint    = null,
	@s_org_err		char(1)     = null,
	@s_error		int         = null,
	@s_sev			tinyint     = null,
	@s_msg			descripcion = null,
	@s_org			char(1)     = null,
	@t_debug		char(1)     = 'N',
	@t_file			varchar(14) = null,
	@t_from			varchar(32) = null,
	@t_trn			smallint    = null,
	@i_operacion 	varchar(2),
	@i_modo      	tinyint     = null,
	@i_tipo      	varchar(1)  = null,
	@i_plazo        int         = null
)

as

declare @w_return         int,
        @w_sp_name        varchar(32)

select @w_sp_name = 'sp_obtener_catalogo'

/* Search */
if @i_operacion = 'S'
begin
if @t_trn = 21743
begin
    set rowcount 20
    if @i_modo = 0
        begin
		    if @i_tipo = 'P'
			begin
                select 'CODIGO' = C.codigo,
		                'VALOR' = C.valor
		        from   cobis..cl_tabla T, cobis..cl_catalogo C
                where  T.tabla  = 'cr_plazo_ind'
                and    T.codigo = C.tabla
                order by convert(int,C.codigo)

                if @@rowcount = 0
                exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file,
                     @t_from  = @w_sp_name,
                     @i_num   = 101000 /*'No existe dato en catalogo'*/
			end
	     end
     set rowcount 0
     return 0
end
else
begin
    exec cobis..sp_cerror
       @t_debug   = @t_debug,
       @t_file    = @t_file,
       @t_from    = @w_sp_name,
       @i_num     = 151051
       /*  'No corresponde codigo de transaccion' */
    return 1
end
end
go
