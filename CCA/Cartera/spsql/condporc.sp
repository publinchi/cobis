/************************************************************************/
/*      Archivo              :     condporc.sp                          */
/*      Stored procedure     :     sp_condonacion_porcentaje            */
/*      Base de datos        :     cob_cartera                          */
/*      Producto             :     cartera                              */
/*      Fecha de escritura   :     Abril-2009                           */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'                                                     */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                          PROPOSITO                                   */
/*                                                                      */
/************************************************************************/
USE cob_cartera
GO
if exists (select 1 from sysobjects where name = 'sp_condonacion_porcentaje')
           drop proc sp_condonacion_porcentaje
go
create proc sp_condonacion_porcentaje
   @t_trn            int = null,
   @i_operacion      char(1) ='S',
   @i_funcionario    smallint,
   @i_concepto       catalogo ,
   @i_porcentaje     float = null,
   @o_porcentaje     float = null out
as
declare
   @w_error                int,
   @w_sp_name              descripcion,
   @w_monto                money,
   @w_monto_ant            money,
   @w_porcentaje           float,
   @w_funcionario          smallint

--- CARGADO DE VARIABLES DE TRABAJO
select @w_sp_name        = 'sp_condonacion_porcentaje'

if @i_operacion = 'S' begin
      select  @w_porcentaje = ca_porcentaje
      from  ca_condonacion_autorizacion
      where ca_funcionario = @w_funcionario
      and   ca_concepto = @i_concepto
      if @w_porcentaje is null
         select @w_porcentaje = 0
      select  @w_porcentaje
end

if @i_operacion = 'Q' begin
      select @w_porcentaje = ca_porcentaje
      from  ca_condonacion_autorizacion, 
            cl_funcionario
      where ca_funcionario = fu_funcionario
      and   ca_concepto = @i_concepto
      
      if @w_porcentaje is null
         select @w_porcentaje = 0

end


if @i_operacion = 'I' begin 
    insert into ca_condonacion_autorizacion
      (ca_funcionario, ca_concepto,ca_porcentaje)
    values
      ( @w_funcionario, @i_concepto, @w_porcentaje)
    if @@error <>0 begin
        select @w_error = '710345'
        goto ERROR
    end
end

if @i_operacion = 'D' begin
    delete  ca_condonacion_autorizacion
    where ca_funcionario = @w_funcionario
    and   ca_concepto = @i_concepto
    if @@error <>0
    begin
       select @w_error = '710346'
       goto ERROR
    end
end

if @i_operacion = 'U' begin 
    update ca_condonacion_autorizacion
    set ca_porcentaje = @i_porcentaje
    where ca_funcionario = @w_funcionario
    and   ca_concepto = @i_concepto
    if @@error <>0 begin
        select @w_error = '710347'
        goto ERROR
    end
end

goto FIN

ERROR:

exec cobis..sp_cerror
   @t_debug  = 'N',
   @t_file   = null,
   @t_from   = @w_sp_name,
   @i_num    = @w_error

return @w_error

FIN:

return 0
go