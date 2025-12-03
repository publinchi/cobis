/************************************************************************/
/*   Archivo:              casimcomp.sp                                 */
/*   Stored procedure:     sp_simula_comp                               */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Ivan Jimenez                                 */
/*   Fecha de escritura:   15/Nov/2006                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Simula los comprobantes contables de Cartera para una obligacion   */
/*   con una transaccion y una fecha dada                               */
/*                             MODIFICACIONES                           */
/*   FECHA              AUTOR           RAZON                           */
/*   15/Nov/2006        Ivan Jimenez    Emision Inicial                 */
/*   20/Mar/2007        Elcira Pelaez   def.Pruebas BAC                 */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_simula_comp')
   drop proc sp_simula_comp
go
create proc sp_simula_comp(
   @s_ssn           int        = null,
   @s_date          datetime   = null,
   @s_user          login      = null,
   @s_term          varchar(64)= null,
   @s_ofi           smallint   = null,
   @t_trn           smallint   = null,
   @i_contador       int        = 0,
   @i_operacion     char(1),
   @i_banco         cuenta,
   @i_num_tran      int
)
as
declare
   @w_error       int,
   @w_sp_name     descripcion,
   @w_cuenta_log  cuenta,
   @w_cont_min    int,
   @w_cont_max    int,
   @w_est_tran    catalogo 
   
   select @w_sp_name = 'sp_simula_comp'

if @i_operacion = 'Q'
begin
   if @i_contador = 0   
   begin
      select @w_est_tran = tr_estado
      from ca_transaccion
      where tr_banco = @i_banco
      and   tr_secuencial = @i_num_tran
      
      if @w_est_tran <>  'ING'
      begin
         PRINT 'LA TRANSACCION CONSULTADA NO ESTA EN ESTADO INGRESADO'
         select @w_error = 710238
         Goto ERROR
      end      
      
      delete ca_simula_comp
      where sc_terminal = @s_term
      and   sc_oficina  = @s_ofi
--      print 'llamando a sp_caconta'
      exec @w_error = sp_caconta
         @s_user        = @s_user,
         @s_term        = @s_term,
         @s_ofi         = @s_ofi,
         @i_fecha       = @s_date,
         @i_banco       = @i_banco,
         @i_actualizar  = 'N',
         @i_num_tran    = @i_num_tran,
         @i_causacion   = 'S',
         @i_proceso     = 0

      if @w_error != 0 
      begin
         Goto ERROR
      end
   end
   
   set rowcount 20
   select 'Asiento'   = sc_asiento,
          'Cuenta      '   = sc_cuenta,
          'Oficina Dest'   = sc_oficina_dest,
          'Area_Dest   '   = sc_area_dest,
          'Credito     '   = sc_credito,
          'Debito      '   = sc_debito,
          'Concepto    '   = sc_concepto
   from  ca_simula_comp
   where sc_terminal = @s_term
   and   sc_oficina  = @s_ofi
   and   sc_asiento  > @i_contador
   set rowcount 0
end -- @i_operacion = 'Q'

if @i_operacion = 'H'
begin
   if @i_contador = 0   
   begin
      -- MOSTRAR DATOS DE CA_ERRORLOG
      select @w_cuenta_log = convert(varchar,@i_banco) + ':' + convert(varchar,@i_num_tran)
      
      delete from ca_simula_comp_err
      where sce_terminal = @s_term
      and   sce_oficina  = @s_ofi
      
      insert into ca_simula_comp_err
      select   distinct 
               @s_term,        @s_ofi,
               0,              er_error,
               er_descripcion, er_anexo
      from  ca_errorlog
      where er_fecha_proc > '01/01/1900' 
      and   er_cuenta   =  @w_cuenta_log
      
      select @w_cont_min = 0
      select @w_cont_max = 0
      
      while @w_cont_min = 0
      begin
         select @w_cont_max = @w_cont_max + 1

         set rowcount 1    
         update ca_simula_comp_err
         set   sce_contador = @w_cont_max
         where sce_terminal = @s_term
         and   sce_oficina  = @s_ofi
         and   sce_contador = 0
         set rowcount 0

         select @w_cont_max = max(sce_contador)
         from  ca_simula_comp_err
         where sce_terminal = @s_term
         and   sce_oficina  = @s_ofi

         select @w_cont_min = min(sce_contador)
         from  ca_simula_comp_err
         where sce_terminal = @s_term
         and   sce_oficina  = @s_ofi
         
         select @w_cont_min = isnull(@w_cont_min, 1)
      end
   end
   
   set rowcount 20
   select 'Error'       = sce_error,
          'Descripcion' = sce_descripcion,
          'Anexo'       = sce_anexo
   from  ca_simula_comp_err
   where sce_terminal = @s_term
   and   sce_oficina  = @s_ofi
   and   sce_contador > @i_contador
   set rowcount 20
end

return 0

ERROR:

exec cobis..sp_cerror
   @t_debug  ='N',
   @t_file   = null,
   @t_from   = @w_sp_name,
   @i_num    = @w_error,
   @i_sev    = 1
--   @i_cuenta = @i_banco

return @w_error
go
