/************************************************************************/
/*  Archivo:                nro_ciclo_cliente.sp                        */
/*  Stored procedure:       sp_nro_ciclo_cliente                        */
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

if exists(select 1 from sysobjects where name ='sp_nro_ciclo_cliente')
    drop proc sp_nro_ciclo_cliente
go

create proc sp_nro_ciclo_cliente (
    @t_debug            char(1)     = 'N',
    @t_file             varchar(14) = null,
    @t_from             varchar(30) = null,
    @i_cliente          int,
    @o_resultado        int  OUTPUT
)
as
declare @w_sp_name                  varchar(64),
        @w_error                    int,
        @w_grupo                    int,
        @w_num_prestamos            int,
        @w_nro_ciclo_cliente        int,
        @w_codigo_estado            int,
        @w_num_operaciones          int,
        @w_resultado                int


select @w_sp_name   = 'sp_nro_ciclo_cliente'
select @w_resultado = 0


SELECT @w_codigo_estado = es_codigo
from cob_cartera..ca_estado
where es_descripcion    = 'CANCELADO'


if @i_cliente is null
BEGIN

   select @w_error = 2109003

   exec   @w_error  = cobis..sp_cerror
   @t_debug  = 'N',
   @t_file   = '',
   @t_from   = @w_sp_name,
   @i_num    = @w_error
   return @w_error


END


--Ciclos en otra entidad financieras
select @w_nro_ciclo_cliente = isnull(ea_nro_ciclo_oi,0)
  from cobis..cl_ente_aux
 where ea_ente 				= @i_cliente

--Ciclos en esta entidad financiera
select @w_num_prestamos = isnull(count(op_operacion),0)
  from cob_cartera..ca_operacion
 where op_estado 		= @w_codigo_estado
   and op_cliente 		= @i_cliente


if @w_nro_ciclo_cliente = 0 and @w_num_prestamos = 0
	select @w_resultado = 1
else
	select @w_resultado = @w_nro_ciclo_cliente + @w_num_prestamos

if @t_debug = 'S'
begin
	print '@w_resultado: ' + convert(varchar, @w_resultado )
end

select @o_resultado  =   @w_resultado

if @o_resultado is null
begin
	select @w_error = 6904007 --No existieron resultados asociados a la operacion indicada
	exec   @w_error  = cobis..sp_cerror
			@t_debug  = 'N',
			@t_file   = '',
			@t_from   = @w_sp_name,
			@i_num    = @w_error
	return @w_error
end

return 0
go
