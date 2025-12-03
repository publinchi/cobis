/************************************************************************/
/*   Archivo:              fvalmas.sp                                   */
/*   Stored procedure:     sp_fval_masivo                               */
/*   Base de datos:        cob_cartera			          	*/
/*   Producto:             Cartera					*/
/*   Disenado por:         Silvia Portilla S.	                        */
/*   Fecha de escritura:   Diciembre 05 -2005	         		*/
/************************************************************************/
/*				IMPORTANTE				*/
/*   Este programa es parte de los paquetes bancarios propiedad de	*/
/*   "MACOSA"							        */
/*   Su uso no autorizado queda expresamente prohibido asi como	        */
/*   cualquier alteracion o agregado hecho por alguno de sus		*/
/*   usuarios sin el debido consentimiento por escrito de la 	        */
/*   Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*   Este procedimiento permite dar mantenimiento a la tabla            */
/*   ca_fval_masivo. En esta tabla se almacena las operaciones que se   */
/*   aplicara fecha valor masivo                                        */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*      FECHA                 AUTOR                  RAZON              */
/*    2005-11-05         Silvia Portilla S.     Emision Inicial         */
/*    2007-Oct-19        Elcira Pelaez          Def. 8921 parametro nodo*/
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_fval_masivo')
   drop proc sp_fval_masivo
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_fval_masivo (
   @s_ssn         int         = null,
   @s_date        datetime    = null,
   @s_user        login       = null,
   @s_term        varchar(30) = null,
   @s_ofi         smallint    = null,
   @s_srv         varchar(30) = null,
   @s_lsrv        varchar(30) = null, 
   @t_rty         char(1)     = null,
   @t_trn         smallint    = null,
   @t_debug       char(1)     = 'N',
   @t_file        varchar(14) = null,
   @t_from        varchar(32) = null,
   @i_operacion   char(1)     = null,
   @i_banco       cuenta      = null,
   @i_fecha       datetime    = null,
   @i_opcion      char(1)     = null,
   @i_estado      char(1)     = null,
   @i_formato_fecha    int = 103
)
as
declare
   @w_estado         tinyint,
   @w_estado_reg     char(1),
   @w_sp_name        varchar(26),
   @w_error          int,
   @w_fecha_cierre   datetime,
   @w_banco          cuenta,
   @w_fecha_valor      datetime


select @w_sp_name = 'sp_fval_masivo'

if @i_operacion = 'I'
begin
   --OBTENER EL ESTADO DE LA OPERACION
   select @w_estado  = op_estado
   from ca_operacion
   where op_banco = @i_banco

   --ELIMINAR LOS DATOS EXISTENTES
   if exists (select 1 from ca_fval_masivo where fm_banco = @i_banco  and   fm_estado in ('I','X'))
   begin
      delete ca_fval_masivo
      where fm_banco = @i_banco
      and   fm_estado  in ('I','X')
   end

   --VALOR POR DEFECTO DEL REGISTRO
   select @w_estado_reg = 'I'

   --VALIDAR EL ESTADO DE LA OPERACION
   if @w_estado in (0,99,6,4)
      select @w_estado_reg = 'X'

   --INSERCION EN LA TABLA 
   insert into ca_fval_masivo
   ( fm_banco,       fm_fecha_valor,   fm_usuario,
     fm_fecha_ing,   fm_terminal,      fm_estado )
   values
   ( @i_banco,       @i_fecha,         @s_user,
    getdate(),       @s_term,          @w_estado_reg  
   )

   --CONTROL DE ERROR   
   if @@error != 0 
   begin
      select @w_error = 711008
      goto ERROR
   end 
end --@i_operacion = 'I'


if @i_operacion = 'Q'  --OPERACIONES CON ESTADO X - ESTADOS NO VALIDOS
begin


  if @i_opcion = 'C'
   select 'No. Operacion ' = fm_banco, 
          'Fecha Valor'    = convert(varchar(10),fm_fecha_valor,103)
   from cob_cartera..ca_fval_masivo
   where fm_usuario = @s_user
   and fm_terminal  = @s_term
   and fm_estado    = @i_estado
--   and fm_fecha_valor = convert(varchar(10),@i_fecha,@i_formato_fecha)
   and fm_fecha_valor = @i_fecha


  if @i_opcion = 'T'
  begin
     if @i_estado = 'I'   
        select 'Fecha Valor' = convert(char(12),fm_fecha_valor,@i_formato_fecha),
               'Usuario'       = fm_usuario,
               'Estado'        = fm_estado,
               'Cantidad'      = count(1),
               'Causal'        = 'Obligaciones para Aplicar Fecha Valor'
        from cob_cartera..ca_fval_masivo
        where fm_usuario   = @s_user
        and   fm_terminal  = @s_term
        and   fm_estado    = 'I'
        group by fm_fecha_valor,fm_usuario,fm_estado
        union
        select 'Fecha Valor' = convert(char(12),fm_fecha_valor,@i_formato_fecha),
               'Usuario'       = fm_usuario,
               'Estado'        = fm_estado,
               'Cantidad'      = count(1),
               'Causal'        = 'Operaciones con Estado de Operacion No Valido'
        from cob_cartera..ca_fval_masivo
        where fm_usuario = @s_user
        and   fm_terminal = @s_term
        and   fm_estado     = 'X'
        group by fm_fecha_valor,fm_usuario,fm_estado

      if @i_estado = 'P'
           select 'Fecha Valor' = convert(char(12),fm_fecha_valor,@i_formato_fecha),
                  'Usuario'       = fm_usuario,
                  'Estado'        = fm_estado,
                  'Cantidad'      = count(1),
                  'Causal'        = 'Obligaciones con Fecha Valor Aplicada'
           from cob_cartera..ca_fval_masivo
           where fm_usuario   = @s_user
           and   fm_terminal  = @s_term
           and   fm_estado    = 'P'
           group by fm_fecha_valor,fm_usuario,fm_estado         

   end  --@i_opcion = 'T'

end  --@i_operacion = 'Q'


if @i_operacion = 'D'
begin
   delete cob_cartera..ca_fval_masivo
   where fm_estado in ('I','X')
   and   fm_usuario = @s_user
   and   fm_terminal = @s_term
    
   if @@error != 0 
   begin

      select @w_error = 711009
      goto ERROR
   end 
end  --@i_operacion = 'D'

if @i_operacion = 'A'  --APLICAR FECHA VALOR
begin
   -- Definir la fecha de cierre del producto

   select @w_fecha_cierre = fc_fecha_cierre
   from cobis..ba_fecha_cierre
   where fc_producto = 7

   if @s_date is null
      select @s_date = @w_fecha_cierre


   --Definir un cursor de las operaciones  a aplicar fecha valor

   declare cur_operacion cursor for
   select fm_banco, fm_fecha_valor
   from cob_cartera..ca_fval_masivo
   where fm_estado = 'I'
   for read only


   open cur_operacion
   fetch cur_operacion into @w_banco, @w_fecha_valor

   while @@fetch_status = 0
   begin
      if (@@fetch_status = -1)
      begin
         exec cobis..sp_cerror
	    @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 708999
   	 return 1 
      end

      --Restaurar la historia de la operación

      exec sp_restaurar
         @i_banco      = @w_banco,
         @i_en_linea  = 'N'

      --Ejecutar el procedimiento de fecha valor

      exec @w_error = sp_fecha_valor
           @s_date        = @w_fecha_cierre,
           @s_lsrv	     = 'BATCH',
           @s_ofi         = @s_ofi,
           @s_ssn         = @s_ssn,
           @s_srv         = 'BATCH',
           @s_term        = @s_term,
           @s_user        = @s_user,
           @i_fecha_valor = @w_fecha_valor,
           @i_banco       = @w_banco,
           @i_operacion   = 'F',  
           @i_observacion = 'FECHA VALOR MASIVO',
           @i_en_linea    = 'N'


      if @w_error <> 0
      begin
         exec sp_errorlog 
              @i_fecha      = @s_date,
              @i_error      = @w_error, 
              @i_usuario    = @s_user,
              @i_tran       = 7999,
              @i_tran_name  = @w_sp_name,
              @i_cuenta     = @w_banco,
              @i_rollback   = 'S'
     
         while @@trancount > 0 rollback
 	 goto SIGUIENTE
      end

         update cob_cartera..ca_fval_masivo
	 set fm_estado = 'P'
	 where fm_banco = @w_banco

	 goto SIGUIENTE

       SIGUIENTE:
      fetch cur_operacion into @w_banco, @w_fecha_valor
    end --cursor
end  --@i_operacion = 'A'







return 0

ERROR:
   exec cobis..sp_cerror
      @t_debug = 'N',
      @t_from  = @w_sp_name,
      @i_num   = @w_error

   return @w_error


go

