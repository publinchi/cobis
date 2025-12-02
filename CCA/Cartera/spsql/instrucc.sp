/***********************************************************************/
/*	Archivo:			instrucc.sp                    */
/*	Stored procedure:		sp_instroper                   */
/*	Base de Datos:			cob_cartera                    */
/*	Producto:			Cartera	                       */
/*	Disenado por:			Marcelo Poveda                 */
/*	Fecha de Documentacion: 	11/Nov/95                      */
/***********************************************************************/
/*			IMPORTANTE		       		       */
/*	Este programa es parte de los paquetes bancarios propiedad de  */ 
/*	"MACOSA".						       */
/*	Su uso no autorizado queda expresamente prohibido asi como     */
/*	cualquier autorizacion o agregado hecho por alguno de sus      */
/*	usuario sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante	       */
/***********************************************************************/  
/*			       PROPOSITO			       */
/*	   Manejo de las instrucciones operativas de cobis-credito     */
/***********************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_instroper')
	drop proc sp_instroper
go

create proc sp_instroper (
@s_date			datetime = null,
@i_banco		cuenta = null,
@i_operacion            char(1) = null,
@i_modo                 tinyint = null,
@i_tramite              int = 0,
@i_numero               int = 0,
@i_login                login = null,
@i_credito              int  = null
)
as
declare	
@w_sp_name		varchar(32),	
@w_return		int,
@w_secuencial           int,
@w_operacionca          int,
@w_tramite              int,
@w_error                int
			
/* Captura nombre de Stored Procedure */
select @w_sp_name = 'sp_instroper'

if @i_operacion = 'B' begin --Buscar
   if @i_modo = 0 begin --Ejecutadas y no ejecutadas
      set rowcount 20
      select 
      'Operacion' = op_banco,
      'Tramite'=op_tramite, 
      'Numero' = in_numero,
      'Instruccion'=convert(char(30),ti_descripcion),
      'Forma'=in_forma_pago,
      'Cuenta'=in_cuenta,
      'Valor'=in_valor,
      'Aprobado por'=in_login_reg,
      'Ejecutada por'=in_login_eje,
      'Fecha Ejecucion'=in_fecha_eje,
      'Detalle Instr'=convert(varchar(255),in_texto)
      from cob_credito..cr_instrucciones, cob_cartera..ca_operacion,
      cob_credito..cr_tinstruccion
      where (op_banco = @i_banco or @i_banco is null)
      and op_tramite = in_tramite
      and in_estado = 'A'
      and (in_tipo = 'O' or in_tipo is null)
      and ((in_tramite > @i_tramite or (in_tramite = @i_tramite and
      in_numero > @i_numero)) or @i_tramite is null)
      and ti_codigo = in_codigo

      if @@rowcount = 0 begin
         select @w_error = 708196
         goto ERROR
      end

   end

   if @i_modo = 1 begin --No ejecutadas

      select 'Operacion' = op_banco,
      'Tramite'=op_tramite, 
      'Numero' = in_numero,
      'Instruccion'=convert(char(30),ti_descripcion),
      'Forma'=in_forma_pago,
      'Cuenta'=in_cuenta,
      'Valor'=in_valor,
      'Aprobado por'=in_login_reg,
      'Ejecutada por'=in_login_eje,
      'Fecha Ejecucion'=in_fecha_eje,
      'Detalle Instr'=convert(varchar(255),in_texto)
      from cob_credito..cr_instrucciones, cob_cartera..ca_operacion,
      cob_credito..cr_tinstruccion
      where (op_banco = @i_banco or @i_banco is null)
      and op_tramite = in_tramite
      and in_estado = 'A' --Aprobada
      and (in_tipo = 'O' or in_tipo is null) --Operativas
      and ((in_tramite > @i_tramite or (in_tramite = @i_tramite and
      in_numero > @i_numero)) or @i_tramite is null)
      and in_login_eje is not null
      and in_fecha_eje is not null
      and ti_codigo = in_codigo

      if @@rowcount = 0 begin
        select @w_error = 708196
        goto ERROR
      end

   end
end

if @i_operacion = 'E' begin
   if exists (select 1 from cob_credito..cr_instrucciones
   where in_tramite = @i_tramite
   and in_numero = @i_numero
   and in_login_eje is not null
   and in_fecha_eje is not null) begin
      select @w_error = 708198
      goto ERROR
   end 
                   
   update cob_credito..cr_instrucciones set 
   in_login_eje = @i_login,
   in_fecha_eje = @s_date
   where in_tramite = @i_tramite
   and in_numero = @i_numero

   if @@error != 0 begin
      select @w_error = 708197
      goto ERROR
   end
end


if @i_operacion = 'S' begin

   select @w_tramite = isnull(op_tramite,0)
   from ca_operacion
   where op_operacion = @i_credito

   if @w_tramite != 0 begin
 
   if exists (select 1 from cob_credito..cr_instrucciones
   where in_tramite = @i_tramite
   and in_login_eje is not null
   and in_fecha_eje is not null)
   select 1
 end

end

return 0

ERROR:
exec cobis..sp_cerror @t_debug='N',
@t_file=null, @t_from=@w_sp_name,  
@i_num = @w_error
return 1

go
