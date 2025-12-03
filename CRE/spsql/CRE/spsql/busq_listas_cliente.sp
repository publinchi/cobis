/************************************************************************/
/*  Archivo:                busq_listas_cliente.sp                      */
/*  Stored procedure:       sp_busq_listas_cliente                      */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_busq_listas_cliente' and type = 'P')
   drop proc sp_busq_listas_cliente
go

create proc sp_busq_listas_cliente
(
 @s_ssn        int         = 1,
 @s_user       login       = 'OPERADOR',
 @s_sesn       int         = 1,
 @s_term       varchar(30) = 'CONSOLA',
 @s_date       datetime    = null,
 @s_srv        varchar(30) = 'HOST',
 @s_lsrv       varchar(30) = 'LOCAL HOST',
 @s_ofi        smallint    = null,
 @s_servicio   int         = null,
 @s_cliente    int         = null,
 @s_rol        smallint    = null,
 @s_culture    varchar(10) = null,
 @s_org        char(1)     = null,
 @i_ente       int,
 @o_resultado  smallint    = NULL out
)
as
declare
@w_sp_name       varchar(100),
@w_error         int,
@w_msg_error     varchar(255),
@w_ape_paterno   varchar(16),
@w_ape_materno   varchar(16),
@w_nombre        varchar(64),
@w_razon_social  varchar(128),
@w_resultado_ng     int,
@w_resultado_ln     int,
@w_resultado        int,
@w_origen_lista     varchar(2)

select @w_sp_name    = 'sp_busq_listas_cliente'

if @i_ente is null return 0

EXEC sp_negative_file
@i_ente      = @i_ente ,
@o_resultado = @w_resultado_ng OUT

if(@w_resultado_ng = 1)
begin
    print 'Ingreso a consultar Listas Negras'
	EXEC sp_li_negra_cliente
    @i_ente      = @i_ente ,
    @o_resultado = @w_resultado_ln OUT
	
	if(@w_resultado_ln = 1)
	begin
        select @o_resultado  = 1
	end
	else if(@w_resultado_ln = 3 )
	begin
	    select @w_origen_lista = 'LN'
        select @o_resultado  = 3
	end
	
end
else if(@w_resultado_ng>1 )
begin
    select @w_origen_lista = 'NG'
    select @o_resultado  = 3
end
	print '@w_origen_lista: '+@w_origen_lista

return 0


GO
