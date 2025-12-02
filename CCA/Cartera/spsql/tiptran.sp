/************************************************************************/
/*   Archivo:                 tiptran.sp                                */
/*   Stored procedure:        sp_tiptran                                */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Marcelo Poveda                            */
/*   Fecha de Documentacion:  07/Sep/95                                 */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Este stored procedure permite manejar los tipos de transaccion.    */
/*   Q: Consulta y modificacion de tipos de transaccion                 */
/*   U: Actualizacion de tipos de transaccion                           */
/*   F: Ayuda de tipos de transaccion                                   */
/*   L: Validacion de tipos de transaccion                              */
/************************************************************************/
/*   MODIFICACIONES                                                     */
/*   FECHA      AUTOR         RAZON                                     */
/*   07/Sep/95   Marcelo Poveda      Emision Inicial                    */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_tiptran')
   drop proc sp_tiptran
go

create proc sp_tiptran
   @i_operacion   char(1)     = null,
   @i_descripcion descripcion = null,
   @i_reversa     char(1)     = null,
   @i_codigo      catalogo    = null
as
declare 
   @w_sp_name  varchar(32),
   @w_error    int

--Captura nombre de Stored Procedure
select @w_sp_name = 'sp_tiptran'

--Consulta de las transacciones

if @i_operacion = 'Q'
begin
   select Codigo = tt_codigo,
          Descripcion =substring(tt_descripcion, 1, 25),
          Reversar = tt_reversa
   from   ca_tipo_trn
   order by tt_codigo
end

if @i_operacion = 'U'
begin
   BEGIN TRAN
   update ca_tipo_trn
   set    tt_descripcion = @i_descripcion,
          tt_reversa = @i_reversa
   where  tt_codigo = @i_codigo
   COMMIT TRAN
end

-- Caso para F5

if @i_operacion = 'F'
begin
   select Codigo      = tt_codigo,
          Descripcion = tt_descripcion
   from   ca_tipo_trn
   order by tt_codigo
end

-- Caso para LostFocus

if @i_operacion = 'L'
begin
   select tt_descripcion
   from   ca_tipo_trn
   where  tt_codigo = @i_codigo
   
   if @@rowcount = 0
   begin
      select @w_error = 101001
      goto ERROR
   end
end

return 0

ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file = null,
     @t_from = @w_sp_name,
     @i_num = @w_error

return @w_error 
 
go
