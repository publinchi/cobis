/************************************************************************/
/* Archivo:                sp_dat_crear_cheques.sp                      */
/* Stored procedure:       sp_dat_crear_cheques                         */
/* Base de datos:          cob_cartera                                  */
/* Producto:               Cartera                                      */
/* Disenado por:           Juan Carlos Guzmán                           */
/* Fecha de escritura:     Junio/2022                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/* Esta aplicacion es parte de los paquetes bancarios propiedad de      */
/* COBISCorp.                                                           */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier alteracion o agregado  hecho por alguno de sus             */
/* usuarios sin el debido consentimiento por escrito de COBISCorp.      */
/* Este programa esta protegido por la ley de derechos de autor         */
/* y por las convenciones  internacionales   de  propiedad inte-        */
/* lectual.    Su uso no  autorizado dara  derecho a COBISCorp para     */
/* obtener ordenes  de secuestro o retencion y para  perseguir          */
/* penalmente a los autores de cualquier infraccion.                    */
/************************************************************************/  
/*                              PROPOSITO                               */
/* SP para proceso eventual de generar los cheques con error desde la   */
/* opción de desembolso desde Cartera con Cheques.                      */
/************************************************************************/
/*                            CAMBIOS                                   */
/* FECHA         AUTOR         RAZON                                    */
/* 13/06/2022    J. Guzman     Version inicial                          */ 
/* 17/06/2022    J. Guzman     Cambio en envio de parametro oficina en  */
/*                             sp_tran_general                          */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dat_crear_cheques')
    drop proc sp_dat_crear_cheques
go

create proc sp_dat_crear_cheques (
   @i_user          varchar(30),
   @i_fecha_ini     datetime,
   @i_fecha_fin     datetime
)
as declare
   @w_sp_name          varchar(30),
   @w_return           int,
   @w_error            int,
   @w_ssn              int,
   @w_beneficiario     varchar(255),
   @w_forma_desem      varchar(10), 
   @w_cod_banco_ach    bigint, 
   @w_cuenta           varchar(30), 
   @w_monto_mn         money, 
   @w_desembolso       int, 
   @w_fecha_proceso    datetime, 
   @w_causal           varchar(14),
   @w_banco            varchar(30),
   @w_oficina_chq      smallint,
   @w_sec_chq          int,
   @w_operacionca      int,
   @w_secuencial_dem   int  


---  VARIABLES DE TRABAJO  
select @w_sp_name = 'sp_dat_crear_cheques'

declare cur_cheques_por_crear cursor for
select dm_cod_banco,   dm_cuenta,     dm_producto, dm_beneficiario, 
       dm_monto_mn,    dm_desembolso, dm_fecha,    op_banco,
       dm_oficina_chg, dm_operacion,  dm_secuencial
from ca_desembolso, ca_operacion
Where dm_operacion = op_operacion
and   dm_producto  = 'DESCHEQUE'
and   op_estado    = 0
and   op_banco not in (select th_documento 
                       from cob_bancos..ba_tran_cheque 
                       where th_estado in ('I', 'E'))
and   dm_fecha between @i_fecha_ini and @i_fecha_fin

open cur_cheques_por_crear
fetch cur_cheques_por_crear into
   @w_cod_banco_ach, @w_cuenta,      @w_forma_desem,   @w_beneficiario,
   @w_monto_mn,      @w_desembolso,  @w_fecha_proceso, @w_banco,
   @w_oficina_chq,   @w_operacionca, @w_secuencial_dem
   
while(@@fetch_status = 0)
begin
   if (@@fetch_status = -1)
   begin
      select @w_error  = 710004

      close cur_cheques_por_crear    
      deallocate cur_cheques_por_crear

      goto ERROR
   end

   select @w_causal = c.valor 
   from cobis..cl_tabla t, cobis..cl_catalogo c
   where t.tabla  = 'ca_fpago_causalbancos'
   and   t.codigo = c.tabla
   and   c.estado = 'V'
   and   c.codigo = @w_forma_desem
   
   exec @w_ssn = master..rp_ssn


   exec @w_return = cob_bancos..sp_tran_general  
      @i_operacion      ='I',
      @i_banco          = @w_cod_banco_ach,  
      @i_cta_banco      = @w_cuenta, 
      @i_fecha          = @w_fecha_proceso, 
      @i_tipo_tran      = 103, 
      @i_causa          = @w_causal,      
      @i_documento      = @w_banco,           
      @i_concepto       = 'DESEMBOLSO CARTERA',
      @i_beneficiario   = @w_beneficiario,
      @i_valor          = @w_monto_mn,   
      @i_producto       = 7,
      @i_sec_monetario  = @w_desembolso,
      @t_trn            = 171013, 
      @s_user           = @i_user,
      @s_ssn            = @w_ssn,
      @s_corr           = 'I',
      @s_ofi            = @w_oficina_chq,
      @o_secuencial     = @w_sec_chq out
	  
      if @w_return != 0
      begin
         select @w_error = @w_return
		 
         close cur_cheques_por_crear    
         deallocate cur_cheques_por_crear
		 
         goto ERROR
      end

      update ca_desembolso
      set dm_carga = @w_sec_chq
      where dm_operacion  = @w_operacionca
      and   dm_producto   = @w_forma_desem
      and   dm_secuencial = @w_secuencial_dem    

      if @@error != 0 
      begin
         select @w_error = 710305
         goto ERROR
      end
	  
      fetch cur_cheques_por_crear into
         @w_cod_banco_ach, @w_cuenta,      @w_forma_desem,   @w_beneficiario,
         @w_monto_mn,      @w_desembolso,  @w_fecha_proceso, @w_banco,
         @w_oficina_chq,   @w_operacionca, @w_secuencial_dem
	
end -- END WHILE

close cur_cheques_por_crear    
deallocate cur_cheques_por_crear

return 0


ERROR:

exec cobis..sp_cerror  
   @t_from = @w_sp_name, 
   @i_num = @w_error

return 1

go
