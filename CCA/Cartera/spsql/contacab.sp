/************************************************************************/
/*   Archivo:              contacab.sp                                  */
/*   Stored procedure:     sp_conta_car                                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian Quintero                              */
/*   Fecha de escritura:   Ene. 1998                                    */
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
/*   Saldos de Cartera por diferentes conceptos para Herramienta de     */
/*   Cuadre Contable.  Tabla cob_ccontable..cco_boc.  CABECERA          */
/*                                                                      */
/*                            MODIFICACIONES                            */
/*   FECHA                  AUTOR                  RAZON                */
/*   07/20/2003    Julio C Quintero          Ajuste Cuentas Din micas y */
/*                                       Control de Errores             */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_conta_car_cab')
   drop proc sp_conta_car_cab
go

create proc sp_conta_car_cab
   @i_filial   int,
   @i_fecha    datetime
as
declare
   @w_sp_name           descripcion,
   @w_anexo             varchar(255),
   @w_error		int

begin
 
   select @w_sp_name = 'sp_conta_car_cab'

   if exists (select 1 from cob_ccontable..cco_boc 
               where bo_empresa = @i_filial
                 and bo_producto = 7
                 and bo_fecha = @i_fecha)
      delete cob_ccontable..cco_boc 
       where bo_empresa = @i_filial
         and bo_producto = 7
         and bo_fecha = @i_fecha             

   insert into cob_ccontable..cco_boc (
	  bo_empresa,bo_producto,bo_fecha,bo_cuenta,bo_oficina,bo_area,bo_moneda,bo_tipo,
          bo_val_opera_mn,bo_val_opera_me,bo_val_conta_mn,bo_val_conta_me,
          bo_diferencia_mn,bo_diferencia_me)
		   
   select bo_empresa,bo_producto,bo_fecha,bo_cuenta,bo_oficina,bo_area,bo_moneda,bo_tipo,
          sum(bo_val_opera_mn),sum(bo_val_opera_me),sum(bo_val_conta_mn),sum(bo_val_conta_me),
          sum(bo_diferencia_mn),sum(bo_diferencia_me)
     from cob_ccontable..cco_boc_det
    where bo_empresa = @i_filial
      and bo_producto = 7
      and bo_fecha = @i_fecha
    group by bo_empresa,bo_producto,bo_fecha,bo_cuenta,bo_oficina,bo_area,bo_moneda,bo_tipo
    order by bo_empresa,bo_producto,bo_fecha,bo_cuenta,bo_oficina,bo_area,bo_moneda,bo_tipo 

    if @@error != 0 -- ERROR GRAVE
    begin
               rollback tran
               select @w_anexo = 'EMPRESA: ' + convert(varchar(2),@i_filial)
               select @w_anexo = @w_anexo + '  PRODUCTO : CARTERA'
               select @w_anexo = @w_anexo + '  FECHA : ' + convert(varchar(10), @i_fecha,101)
               goto ERROR_GRAL
    end


return 0

ERROR_GRAL:
   exec sp_errorlog 
        @i_fecha     = @i_fecha,
        @i_error     = @w_error,
        @i_usuario   = 'CUADRECAR',
        @i_tran      = 7000,
        @i_tran_name = @w_sp_name,
        @i_rollback  = 'N',
        @i_cuenta    = 'TODAS',
        @i_anexo     = @w_anexo

   begin tran
   update ca_procesos_contacar_tmp
   set    estado = 'P'
   where  proceso > 0
   commit

end

go
