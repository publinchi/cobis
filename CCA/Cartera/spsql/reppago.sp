/**************************************************************************/
/*   Archivo:             reppago.sp                                      */
/*   Stored procedure:    sp_reppago                                      */
/*   Base de datos:       cob_cartera                                     */
/*   Producto:            Credito y Cartera                               */
/*   Disenado por:        Silvia Portilla S.                              */
/*   Fecha de escritura:  Febrero 2010                                    */
/**************************************************************************/
/*                              IMPORTANTE                                */
/*   Este  programa  es parte  de los  paquetes  bancarios  propiedad de  */
/*   'MACOSA'.  El uso no autorizado de este programa queda expresamente  */
/*   prohibido as¡ como cualquier alteraci¢n o agregado hecho por alguno  */
/*   alguno  de sus usuarios sin el debido consentimiento por escrito de  */
/*   la Presidencia Ejecutiva de MACOSA o su representante.               */
/**************************************************************************/
/*                              PROPOSITO                                 */
/*   Permite obtener los datos de los pagos realizados en cartera         */
/**************************************************************************/
/*                             MODIFICACIONES                             */
/*      FECHA                 AUTOR                PROPOSITO              */
/*   2-Febrero-2010       Silvia Portilla S.      Emision Inicial         */
/**************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reppago')
   drop proc sp_reppago
go

create proc sp_reppago
(
   @i_param1   varchar(255) = null,
   @i_param2   varchar(255) = null   
)
as
declare
  @w_operacionca       int,
  @w_banco             varchar(20),
  @w_tran              varchar(10),
  @w_secuencial        int,
  @w_secuencial_ref    int,
  @w_fecha_mov         datetime,
  @w_cliente           int,
  @w_oficina_dest      smallint,
  @w_empresa           smallint,
  @w_perfil            varchar(10),
  @w_secuencial_ing    int,
  @w_fecha_pag         varchar(10),
  @w_fecha_ing         varchar(10),
  @w_oficina_orig      smallint,
  @w_max_op            int,
  @w_op_ini            int,
  @w_op_fin            int,
  @w_cedula            varchar(30),
  @w_concepto          catalogo,
  @w_monto_mn          money,
  @w_cuenta            char(14),
  @w_codval            smallint,
  @i_fecha_ini         datetime,
  @i_fecha_fin         datetime,
  @w_return            int,
  @w_sp_name           varchar(32),
  @w_fecha_proceso     datetime,
  @w_error             int


select @i_fecha_ini = convert(datetime,@i_param1),
       @i_fecha_fin = convert(datetime,@i_param2),
       @w_sp_name   = 'sp_reppago'


select @w_fecha_proceso  = fp_fecha
from cobis..ba_fecha_proceso 

truncate table ca_cpagos_tmp

declare cur_ope cursor for select 
tr_operacion,    tr_banco,            tr_tran, 
tr_secuencial,   tr_secuencial_ref,   tr_fecha_mov,
op_cliente,      op_oficina,          1,
to_perfil,       ab_secuencial_ing,   convert(varchar,ab_fecha_pag,103), 
convert(varchar,ab_fecha_ing,103),    ab_oficina 
from cob_cartera..ca_transaccion, cob_cartera..ca_operacion, 
     cob_cartera..ca_abono, cob_cartera..ca_trn_oper
where tr_operacion = op_operacion
--and (tr_operacion >= @w_op_ini and tr_operacion  < @w_op_fin)
and tr_fecha_ref between @i_fecha_ini and @i_fecha_fin
and tr_tran       = 'PAG'
and tr_operacion  = ab_operacion
and op_operacion  = ab_operacion
and tr_secuencial = abs(ab_secuencial_pag)
and to_toperacion = op_toperacion
and to_tipo_trn   = tr_tran
and tr_estado     = 'CON'

open cur_ope
fetch cur_ope into 
@w_operacionca,  @w_banco,            @w_tran,  
@w_secuencial,   @w_secuencial_ref,   @w_fecha_mov,  
@w_cliente,      @w_oficina_dest,  @w_empresa,  
@w_perfil,       @w_secuencial_ing,   @w_fecha_pag,
@w_fecha_ing,    @w_oficina_orig

while @@fetch_status = 0 
begin      
   select @w_cedula = isnull(en_ced_ruc, p_pasaporte) 
   from cobis..cl_ente
   where en_ente = @w_cliente

   declare cur_ab cursor for select
   abd_concepto, abd_monto_mn, (select dp_cuenta 
                                from cob_conta..cb_det_perfil noholdlock, cob_cartera..ca_producto
                                where dp_codval = cp_codvalor
                                and cp_producto = A. abd_concepto
                                and dp_producto = 7
                                and dp_perfil = 'RPA_ACT'
                                and dp_codval = cp_codvalor)
   from cob_cartera..ca_abono_det A
   where abd_operacion    = @w_operacionca
   and abd_secuencial_ing = @w_secuencial_ing
   and abd_tipo = 'PAG'

   for read only
   open  cur_ab
   fetch cur_ab into @w_concepto,@w_monto_mn, @w_cuenta    

   while @@fetch_status = 0 
   begin      
      if @w_concepto = 'PAGOBANCOS'
         select @w_cuenta = dtr_cuenta
         from ca_det_trn with (nolock)
         where dtr_operacion = @w_operacionca
         and dtr_concepto    = @w_concepto

      select @w_cuenta = isnull(@w_cuenta,"")
      
      insert into ca_cpagos_tmp(
      cpt_faplic,        cpt_fefect,      cpt_ofi_ori,
      cpt_ofi_des,       cpt_forma,       cpt_cta_cta,
      cpt_valor,         cpt_operacion,   cpt_cedula )  
      values(
      @w_fecha_pag,      @w_fecha_ing,    @w_oficina_orig, 
      @w_oficina_dest,   @w_concepto,     @w_cuenta,
      @w_monto_mn,       @w_banco,        @w_cedula ) 

      fetch cur_ab into @w_concepto,@w_monto_mn, @w_cuenta    

   end  
   close cur_ab
   deallocate cur_ab

   fetch cur_ope into 
   @w_operacionca,  @w_banco,            @w_tran,  
   @w_secuencial,   @w_secuencial_ref,   @w_fecha_mov,  
   @w_cliente,      @w_oficina_dest,     @w_empresa,  
   @w_perfil,       @w_secuencial_ing,   @w_fecha_pag,
   @w_fecha_ing,    @w_oficina_orig
end
close cur_ope
deallocate cur_ope


exec @w_return = sp_exec_repg
   @i_fecha_ini =  @i_fecha_ini,
   @i_fecha_fin =  @i_fecha_fin

if @w_return <> 0
begin
     exec sp_errorlog 
      @i_fecha     = @w_fecha_proceso,
      @i_error     = @w_error,
      @i_usuario   = 'batch',
      @i_tran      = @w_error,
      @i_tran_name = @w_sp_name,
      @i_cuenta    = '',
      @i_rollback  = 'N'

   return 1
end


return 0
go

 