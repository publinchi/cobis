/************************************************************************/
/*   Archivo:              conrefind.sp                                 */
/*   Stored procedure:     sp_cons_ref_ind                              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Maria Jose Taco                              */
/*   Fecha de escritura:   Diciembre 2017                               */
/************************************************************************/
/*                            IMPORTANTE                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Programa consulta la referencia de liquidacion anticipada de       */
/*   prestamos                                                          */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA        AUTOR             RAZON                                */
/*  12/Dic/2017  Ma. Jose Taco     Emision inicial                      */
/*  21/Nov/2018  SRO               Referencias Numéricas                */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cons_ref_ind')
   drop proc sp_cons_ref_ind
go

create proc sp_cons_ref_ind 
@s_user            login       = null,
@s_term            varchar(32) = null, 
@i_operacion       varchar(10) = null,
@i_ente            int          = null,
@i_monto_pre       money        = null,
@i_tipo            char(1)     = null
as 
declare
@w_sp_name         varchar(64),
@w_error           int,
@w_fecha_proceso   datetime,
@w_est_vigente     int,
@w_monto_op        money,
@w_monto_pre       money,
@w_monto_seg       money,
@w_pagado_seg      char(1),
@w_nombre          varchar(64),
--
@w_fecha_liq       varchar(10),
@w_nombre_banco    VARCHAR(100),
@w_fecha_ven       varchar(10),
@w_num_abono       INT,
@w_nom_oficina     VARCHAR(100),
@w_referencia      VARCHAR(100),
@w_convenio        INT,
@w_secuencial      int         



select @w_sp_name = 'sp_cons_inst_tram'

exec cob_cartera..sp_estados_cca
     @o_est_vigente   = @w_est_vigente out
 
select @w_fecha_proceso = fp_fecha FROM cobis..ba_fecha_proceso


if (@i_operacion = 'C')
begin
   exec @w_error          = sp_precancela_refer
        @s_user           = @s_user,
        @s_term           = @s_term,
        @i_operacion      = @i_operacion, -- C =consulta montos // I = inserta tabla
        @i_fecha_proceso  = @w_fecha_proceso,
        @i_cliente        = @i_ente,
        @i_banco          = null,
        @i_monto_pre      = 0,
        @i_tipo           = @i_tipo,
        @o_monto_op       = @w_monto_op   output,
        @o_monto_pre      = @w_monto_pre  output,
        @o_monto_seg      = @w_monto_seg  output,
        @o_pagado_seg     = @w_pagado_seg output,
        @o_nombre         = @w_nombre     output,
        @o_secuencial     = @w_secuencial
		
	
   if @w_error <> 0 begin
      goto ERROR_FIN
   end
   
   select @w_monto_op,
          @w_monto_pre, 
          @w_monto_seg,
          @w_pagado_seg
end

if (@i_operacion = 'I')
begin
   exec sp_precancela_refer
        @s_user           = @s_user,
        @s_term           = @s_term,
        @i_operacion      = @i_operacion, -- C =consulta montos // I = inserta tabla
        @i_fecha_proceso  = @w_fecha_proceso,
        @i_cliente        = @i_ente,
        @i_banco          = null,
        @i_monto_pre      = @i_monto_pre,
        @i_tipo           = @i_tipo,
        @o_monto_op       = @w_monto_op     output,
        @o_monto_pre      = @w_monto_pre    output, 
        @o_monto_seg      = @w_monto_seg    output,
        @o_pagado_seg     = @w_pagado_seg   output,
        @o_fecha_liq      = @w_fecha_liq    output,
        @o_nombre         = @w_nombre       output,
        @o_fecha_ven      = @w_fecha_ven    output,
        @o_num_abono      = @w_num_abono    output,
        @o_nom_oficina    = @w_nom_oficina  output,
        @o_referencia     = @w_referencia   output,
        @o_convenio       = @w_convenio     output,
        @o_secuencial     = @w_secuencial   output

   if @w_error <> 0 begin
      goto ERROR_FIN
   end   
   
   select 
   pr_monto_op,
   pr_monto_pre,
   pr_monto_seg,
   pr_fecha_liq,
   pr_nombre_cl,
   pr_fecha_ven,
   pr_nombre_of		
   from ca_precancela_refer
   where pr_cliente  = @i_ente
   and pr_secuencial = @w_secuencial
   
   
   select 
   prd_institucion,
   prd_referencia,
   prd_convenio
   from ca_precancela_refer_det
   where prd_cliente = @i_ente
   and prd_secuencial = @w_secuencial
   order by prd_institucion
   
   
end
return 0

ERROR_FIN:
   exec cobis..sp_cerror 
       @t_from = @w_sp_name, 
       @i_num  = @w_error
   return @w_error
go

