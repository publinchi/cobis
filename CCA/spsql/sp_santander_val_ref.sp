/************************************************************************/
/*    Base de datos:            cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sonia Rojas                             */
/*      Fecha de escritura:     13/09/2017                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                         PROPOSITO                                    */
/*      Tiene como prop√≥sito procesar los pagos de los corresponsales   */
/*                        MOFICACIONES                                  */
/* 24/07/2018         SRO                  Validaciones referencias     */
/*                                           SANTANDER                  */
/************************************************************************/  
use cob_cartera
go


if exists(select 1 from sysobjects where name ='sp_santander_val_ref')
	drop proc sp_santander_val_ref
GO


CREATE proc sp_santander_val_ref(
    @s_ssn              int                = null,
    @s_user             login              = null,
    @s_sesn             int                = null,
    @s_term             varchar(30)        = null,
    @s_date             datetime           = null,
    @s_srv              varchar(30)        = null,
    @s_lsrv             varchar(30)        = null,
    @s_ofi              smallint           = null,
    @s_servicio         int                = null,
    @s_cliente          int                = null,
    @s_rol              smallint           = null,
    @s_culture          varchar(10)        = null,
    @s_org              char(1)            = null,
    @i_referencia       varchar(255)       = null, -- Obligatorio 
	@i_fecha_pago       varchar(8)         = null, -- Fecha de Pago
    @i_monto_pago       varchar(14)        = null, -- Monto de Pago
    @i_archivo_pago     varchar(255),              -- Archivo de Pago, opcional
    @o_tipo             char(2)            out,    -- Tipo de transacciÛn
    @o_codigo_interno   varchar(10)        out,    -- CÛdigo interno
    @o_fecha_pago       datetime           out,    -- Fecha de pago
    @o_monto_pago       money              out     -- Monto de pago
)
as
declare 
   @w_sp_name                 varchar(30),
   @w_tipo_tran               char(2),             -- Obligatorio si operacion = 'G', (GL) Garantia LÌquida, (PG) PrÈstamo Grupal, (PI) PrÈstamo Individual, 
                                                  -- (CG)CancelacciÛn de CrÈdito Grupal, (CI)CancelaciÛn de CrÈdito Individual
   @w_codigo_int              int,
   @w_error                   int,
   @w_msg                     varchar(255),
   @w_tipo_tran_corresp       char(2)
   
   select @w_sp_name  = 'sp_santander_val_ref'
   
   select @w_tipo_tran_corresp = substring(@i_referencia,1,2) 
   
 --  select @w_tipo_tran = case  
 --                             when @w_tipo_tran_corresp in ('GL','00') then 'GL'                      
 --                             when @w_tipo_tran_corresp in ('PG','01') then 'PG'
 --                             when @w_tipo_tran_corresp in ('CG','02') then 'CG'
 --                             when @w_tipo_tran_corresp in ('PI','03') then 'PI'
 --							  when @w_tipo_tran_corresp in ('PR','04') then 'CI'
 --                             else @w_tipo_tran_corresp 
 --                        end

   select @w_tipo_tran = @w_tipo_tran_corresp   
   if @w_tipo_tran_corresp in ('GL','00')
      select @w_tipo_tran = 'GL'
   if @w_tipo_tran_corresp in ('PG','01')
      select @w_tipo_tran = 'PG'
   if @w_tipo_tran_corresp in ('CG','02')
      select @w_tipo_tran = 'CG'
   if @w_tipo_tran_corresp in ('PI','03')
      select @w_tipo_tran = 'PI'
   if @w_tipo_tran_corresp in ('PR','04')
       select @w_tipo_tran = 'CI'
	  
   if  @w_tipo_tran <> 'GL'
   and @w_tipo_tran <> 'PG'
   and @w_tipo_tran <> 'PI'
   and @w_tipo_tran <> 'CG'
   and @w_tipo_tran <> 'CI' begin
      select @w_error = 70204,
             @w_msg   = 'ERROR: TIPO DE TRANSACCI”N NO V¡ÅLIDA'
      goto ERROR_FIN
   end
   
   
   select @w_codigo_int = substring(@i_referencia,3,12)

   exec @w_error    = sp_validar_pagos 
   @i_referencia    = @i_referencia,   
   @i_fecha_pago    = @i_fecha_pago,
   @i_monto_pago    = @i_monto_pago,
   @i_archivo_pago  = @i_archivo_pago,
   @i_tipo          = @w_tipo_tran,
   @i_codigo_int    = @w_codigo_int,
   @o_tipo          = @o_tipo           out ,
   @o_codigo_int    = @o_codigo_interno out,
   @o_monto_pago    = @o_monto_pago     out ,
   @o_fecha_pago    = @o_fecha_pago     out 
   
   
   if @w_error <> 0 begin
      select @w_error = @w_error,
             @w_msg = 'ERROR AL VALIDAR LA REFERENCIA SANTANDER'	  
      goto ERROR_FIN
   end

return 0


ERROR_FIN:

exec cobis..sp_cerror 
    @t_from = @w_sp_name, 
    @i_num  = @w_error, 
    @i_msg  = @w_msg
return @w_error

go