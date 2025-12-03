/************************************************************************/
/*  Archivo:              sp_gen_conta_linea.sp                         */
/*  Stored procedure:     sp_gen_conta_linea                            */
/*  Base de datos:        cob_credito                                   */
/*  Producto:             credito                                       */
/*  Disenado por:         William Lopez                                 */
/*  Fecha de escritura:   23/Dic/2021                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCORP.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCORP para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  Generacion de transacciones de contabilizacion de lineas de credito */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  23/Dic/2021   William Lopez   Emision Inicial-ORI-S575137-GFI       */
/************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name = 'sp_gen_conta_linea' and type = 'P')
   drop procedure sp_gen_conta_linea
go

create proc sp_gen_conta_linea (
   @s_ssn         int         = null,
   @s_user        login       = null,
   @s_term        descripcion = null,
   @s_ofi         smallint    = null,
   @s_date        datetime    = null,
   @i_linea       cuenta      = null
)
as 
declare
   @w_sp_name     varchar(30),
   @w_return      int,
   @w_tramite     int,
   @w_monto       money,
   @w_moneda      tinyint,
   @w_contabiliza char(1),
   @w_linea_int   int

--OBTIENE DATOS DE LA LINEA
select @w_linea_int    = li_numero,
       @w_monto        = li_monto,
       @w_moneda       = li_moneda,
       @w_tramite      = li_tramite,
       @w_contabiliza  = 'S'
from   cr_linea
where  li_num_banco = @i_linea

if @w_contabiliza = 'S'
begin
   if not exists (select 1 
                  from   cr_transaccion_linea
                  where  tl_linea       = @w_linea_int
                  and    tl_transaccion = 'V'
                  and    tl_estado      in ('I', 'C'))
   begin
      exec @w_return = sp_transacciones_linea
           @s_user        = @s_user,
           @s_date        = @s_date,
           @s_term        = @s_term,
           @s_ofi         = @s_ofi,
           @t_trn         = 21447,
           @i_transaccion = 'V',
           @i_linea       = @w_linea_int,
           @i_secuencial  = 1,
           @i_valor       = @w_monto,
           @i_valor_ref   = @w_monto,
           @i_moneda      = @w_moneda,
           @i_estado      = 'I'
      
      if @w_return != 0
      begin
         return @w_return
      end

      exec @w_return = sp_transacciones_linea
           @s_user        = @s_user,
           @s_date        = @s_date,
           @s_term        = @s_term,
           @s_ofi         = @s_ofi,
           @t_trn         = 21469,
           @i_transaccion = 'E',
           @i_linea       = @w_linea_int,
           @i_valor       = @w_monto,
           @i_valor_ref   = @w_monto,
           @i_moneda      = @w_moneda
      
      if @w_return != 0
      begin
         return @w_return
      end

   end
end

/** CAMBIO DE ESTADO DE LAS GARANTIAS ASOCIADAS A LA LINEA **/
exec @w_return  = cob_custodia..sp_activar_garantia
     @s_date      = @s_date,
     @s_user      = @s_user,
     @s_ofi       = @s_ofi,
     @s_ssn       = @s_ssn,
     @s_term      = @s_term,
     @i_tramite   = @w_tramite,
     @i_opcion    = 'L'

if @w_return != 0
begin
   return @w_return
end

return 0
go
