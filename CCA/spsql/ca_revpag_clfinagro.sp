/************************************************************************/
/*   Archivo:             ca_revpag_clfinagro.sp                        */
/*   Stored procedure:    sp_reverso_pag_cambiolfinagro                 */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez Burbano                         */
/*   Fecha de escritura:  Ene.2015                                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/************************************************************************/
/*   Reversa los pagos que tengan las operaciones que FINAGRO no parobo */
/*   y se cargaron en una tabla  de nombre ca_proc_cam_linea_finagro    */
/*   AUTOR        FECHA        CAMBIO                                   */
/*   EPB          Enero.2015   Emision Inicial. NR 479 Bancamia         */
/*   Julian Mendi AGO.2015     ATSK-1060.                               */  
/*                             Se generan dos archivos para reportar los*/
/*                             Mensaje, uno para el usuario final y otro*/
/*                             para soporte tecnico.                    */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_reverso_pag_cambiolfinagro')
   drop proc sp_reverso_pag_cambiolfinagro
go

SET ANSI_NULLS ON
GO
---Jul.29.2015
CREATE proc sp_reverso_pag_cambiolfinagro
  @i_param1   datetime
as declare              
   @w_usuario           catalogo,
   @w_usuario1          login,
   @w_usuario2          login,   
   @w_term              catalogo,
   @w_error             int,
   @w_sp_name           varchar(64),
   @w_fecha             datetime,
   @w_sec_cons          int,
   @w_operacion         int,
   @w_banco             cuenta,
   @w_sec_pago          int,
   @w_sec               int,
   @w_ofi               int,
   @w_fpago             catalogo,
   @w_foram_reversa_org  catalogo,
   @w_parametro_freverso catalogo,
   @w_fecha_cca          datetime,
   @w_msg                varchar(255)
   
---USUARIO EXCLUSIVO PARA CAMBIO LINEA FINAGRO
select @w_usuario1 = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'USLIFI'
and   pa_producto = 'CCA'

select @w_usuario2 = @w_usuario1 + '_USR'
select @w_usuario  = @w_usuario1

---FORMA REVERSO DE PAGOS PARA CAMBIO DE LINEA
select @w_parametro_freverso = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'FREVER'
and   pa_producto = 'CCA'

select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select 
@w_sp_name           = 'sp_reverso_pag_cambiolfinagro',
@w_fecha             = @i_param1,
@w_term              = 'BATCH_CCA',
@w_ofi               = 1

----SI NO HAY DATOS CARGADOS SIMPLEMENTE GENERE UN ERROR
if not exists ( select 1 from ca_proc_cam_linea_finagro)
begin
  select @w_msg = 'NO SE HAN CARGADO DATOS EN LA TABLA DE TRABAJO DE FINAGRO'  
  select @w_usuario  = @w_usuario2
  goto ERROR_FINAL
end

---SELECCION DE LAS OPERACIONES A REVERSION DE PAGOS

create table  #rev_pagos_cambinFINAgro
(sec             numeric(10,0) identity not null,
 operacion       int                    not null, 
 banco           cuenta                 not null,
 sec_pago        int                    not null, 
) 


---VALIDACION FORMA DE REVERSO QUE EXISTA PARAMETRIZADA
if not exists(select 1 from ca_producto
              where cp_producto = @w_parametro_freverso)
begin
  select @w_msg = 'NO EXISTE FORMA DE REVERSO PARA CAMBIO DE LINEA FINAGRO'
  select @w_usuario  = @w_usuario2  
  goto ERROR
end

---MARCAR PRIMERO COMO PROCESADOS LOS QUE NO TIENEN PAGOS QUE REVERTIR
update ca_proc_cam_linea_finagro
set    pc_reverso_pagos = '1'
where pc_fecha_proc = @w_fecha
and   pc_estado     = 'I'
and   pc_reverso_pagos = '0'
and   pc_banco_cobis not  in (select op_banco 
                              from ca_operacion,ca_abono
                              where ab_operacion = op_operacion
                              and   ab_estado = 'A'
                              )

insert into #rev_pagos_cambinFINAgro
select ab_operacion,
       op_banco,
       ab_secuencial_pag
from ca_proc_cam_linea_finagro,
     ca_abono,
     ca_operacion
where ab_operacion = op_operacion
and   pc_fecha_proc =   @w_fecha
and   op_banco = pc_banco_cobis
and   pc_estado <> 'P'
and   pc_reverso_pagos = 0
and   ab_estado = 'A'
and   ab_usuario <>  @w_usuario 

order by ab_operacion,ab_secuencial_pag desc
if @@rowcount = 0
begin
  PRINT ''
  PRINT 'ATENCION NO HAY  PAGOS PARA REVESAR SE PUEDE CONTINUAR '
  ---SE MARCAN COMO PROCESADO  TODO
   update ca_proc_cam_linea_finagro  
   set   pc_reverso_pagos = '1',
         pc_estado         = 'I'
   where pc_fecha_proc = @w_fecha
  return 0
end
PRINT ''
PRINT 'PAGOS A REVERSAR'
select * from #rev_pagos_cambinFINAgro

select @w_sec_cons = 0
while 1 = 1 
begin

      set rowcount 1

      select @w_sec_cons  = sec,
             @w_operacion = operacion,
             @w_banco     = banco,
             @w_sec_pago  = sec_pago
      from #rev_pagos_cambinFINAgro
      where sec > @w_sec_cons
      order by sec 

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0
      ---Revisar la forma de pago para parametrizar la reversa con un reaplica
      select @w_fpago = abd_concepto
      from ca_abono,ca_abono_det
      where ab_operacion = @w_operacion
      and   ab_operacion = abd_operacion
      and   ab_secuencial_ing = abd_secuencial_ing
      and   ab_secuencial_pag = @w_sec_pago
   
      select @w_foram_reversa_org = cp_producto_reversa
      from ca_producto
      where cp_producto = @w_fpago
      
      update ca_producto
      set cp_producto_reversa = @w_parametro_freverso
      from ca_producto
      where cp_producto = @w_fpago
      
      print 'banco que va '+ cast(@w_banco as varchar) + ' @w_sec_pago '  +  cast (@w_sec_pago as varchar)

      exec @w_error = sp_fecha_valor 
      @s_date              = @w_fecha_cca,
      @s_user              = @w_usuario,
      @s_term              = @w_term,
      @i_secuencial        = @w_sec_pago,
      @i_banco             = @w_banco,
      @i_operacion         = 'R', ---R = Reverso
      @i_observacion       = 'CAMBIO LINEA DE FINAGRO A OTRA',
      @i_en_linea          = 'N'
      
      if @w_error <> 0 
      begin
         select @w_msg 'ERROR REVERSANDO PAGO'
         select @w_usuario  = @w_usuario2         
         goto ERROR
      end                 
      
      update ca_producto
      set cp_producto_reversa = @w_foram_reversa_org
      from ca_producto
      where cp_producto = @w_fpago
      
   
   goto SIGUIENTE
   
   ERROR:
      begin
         exec sp_errorlog 
         @i_fecha       = @w_fecha,
         @i_error       = @w_error,
         @i_usuario     = @w_usuario,
         @i_tran        = 7999,
         @i_tran_name   = @w_sp_name,
         @i_cuenta      = @w_banco,
         @i_descripcion = @w_msg,
         @i_rollback    = 'N'

         select @w_error = 0
         select @w_usuario  = @w_usuario1  
      
         update ca_proc_cam_linea_finagro  
         set pc_estado = 'E',
             pc_reverso_pagos = '0'
         where pc_banco_cobis = @w_banco
         and   pc_fecha_proc = @w_fecha
         
         goto SALIR
      end
   
   SIGUIENTE:
      update ca_proc_cam_linea_finagro  
      set   pc_reverso_pagos = '1',
            pc_estado         = 'I'
      where pc_banco_cobis = @w_banco
      and   pc_fecha_proc = @w_fecha
      
  SALIR:
  PRINT 'Va el Siguiente Registro para Reverso de Pagos'      
  
end
print ''
print ''
print ' REVISAR ESTADO DE LOS PAGOS'  
print ''
select banco,ab_secuencial_pag,ab_estado
from #rev_pagos_cambinFINAgro,
     ca_abono
where ab_operacion = operacion
and   ab_secuencial_pag = sec_pago     

ERROR_FINAL:
  begin
      print cast(@w_msg as varchar(225))
      exec sp_errorlog 
      @i_fecha       = @w_fecha,
      @i_error       = 7999, 
      @i_tran        = null,
      @i_usuario     = @w_usuario, 
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = '',
      @i_rollback    = 'N',
      @i_descripcion = @w_msg,
      @i_anexo       = @w_msg
      return 0
   end

return 0   
go
