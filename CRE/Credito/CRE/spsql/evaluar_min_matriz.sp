/************************************************************************/
/*  Archivo:                evaluar_min_matriz.sp                       */
/*  Stored procedure:       sp_evaluar_min_matriz                       */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_evaluar_min_matriz')
    drop proc sp_evaluar_min_matriz
go

create proc sp_evaluar_min_matriz(

@s_user               login    ,
@s_rol                smallint ,
@s_ofi                smallint  = null,
@i_concepto           catalogo ,
@i_clase_cartera      catalogo ,
@i_lin_credito        catalogo ,
@i_destino            catalogo ,
@i_operacionca        int      ,
@i_tramite            int      ,
@i_campana            int      ,
@i_tipo_rubro         char(1)  ,
@o_factor             float  = null out  ,
@o_valor              float  = null out  ,
@o_msg                descripcion = null  out
)
as
declare
@w_concepto           catalogo    ,
@w_campana            int         ,
@w_num_creditos       int         ,
@w_est_novigente      tinyint     ,
@w_est_vigente        tinyint     ,
@w_est_vencido        tinyint     ,
@w_est_cancelado      tinyint     ,
@w_est_castigado      tinyint     ,
@w_est_anulado        tinyint     ,
@w_est_credito        tinyint     ,
@w_matriz_calculo     catalogo    ,
@w_fecha_proceso      datetime    ,
@w_rubro              catalogo    , 
@w_error              int         ,
@w_msg                descripcion ,
@w_sp_name            descripcion ,
@w_descripcion_msg    descripcion ,
@w_cliente            int 

select @w_sp_name =   'sp_evaluar_min_matriz'
                      
exec @w_error     =   cob_cartera..sp_estados_cca
@o_est_novigente  =   @w_est_novigente out,
@o_est_vigente    =   @w_est_vigente   out,
@o_est_vencido    =   @w_est_vencido   out,
@o_est_cancelado  =   @w_est_cancelado out,
@o_est_castigado  =   @w_est_castigado out,
@o_est_anulado    =   @w_est_anulado   out,
@o_est_credito    =   @w_est_credito  out

if @w_error <> 0 return @w_error

select @w_cliente = tr_cliente
from cob_credito..cr_tramite
where tr_tramite = @i_tramite

select @w_num_creditos = count(1)
from cob_cartera..ca_operacion
where op_estado   =  @w_est_cancelado
and op_cliente = @w_cliente

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

select @w_matriz_calculo = ma_matriz                  
from cob_cartera..ca_matriz    
where ma_matriz = 'TASA_MN_LC'  


select @w_descripcion_msg = co_descripcion
from cob_cartera..ca_concepto
where co_concepto = @i_concepto

/*LLEGADO EL CASO QUE SEA SOLO NECESARIO HABILITAR EL CONCEPTO DE INTERES, POR LO TANTO SE EVALUARA TODOS LOS RUBROS Y UNICAMENTE
SE PODRA MODIFICAR LOS RUBROS QUE SE ENCUENTREN PARAMETRIZADOS EN LA MATRIZ*/



if @i_tipo_rubro = 'I'  or @i_tipo_rubro = 'M' or @i_tipo_rubro = 'Q' or @i_tipo_rubro = 'O'begin 
   exec @w_error = cob_cartera..sp_matriz_valor
   @i_matriz         = @w_matriz_calculo,
   @i_fecha_vig      = @w_fecha_proceso ,
   @i_eje1           = @i_lin_credito   ,
   @i_eje2           = @i_campana       ,
   @i_eje3           = @i_concepto      ,
   @i_eje4           = @s_rol           ,
   @i_eje5           = @i_clase_cartera ,
   @i_eje6           = @i_destino       ,
   @i_eje7           = @w_num_creditos  ,
   @o_valor          = @o_factor out    ,
   @o_msg            = @o_msg out
   --select  @w_matriz_calculo,@w_fecha_proceso ,@i_lin_credito,@w_campana,@i_concepto,@s_rol,@i_clase_cartera ,@i_destino,@w_num_creditos,@o_factor
   
   if @w_error <> 0 return @w_error
end
else begin
   exec @w_error = cob_cartera..sp_matriz_valor
   @i_matriz         = @w_matriz_calculo,
   @i_fecha_vig      = @w_fecha_proceso ,
   @i_eje1           = @i_lin_credito   ,
   @i_eje2           = @i_campana       ,
   @i_eje3           = @i_concepto      ,
   @i_eje4           = @s_rol           ,
   @i_eje5           = @i_clase_cartera ,
   @i_eje6           = @i_destino       ,
   @i_eje7           = @w_num_creditos  ,
   @o_valor          = @o_valor out    ,
   @o_msg            = @o_msg out
end

if @o_factor = -999  or @o_valor = -999 begin
   select 
   @o_msg = 'No tiene privilegios para negociar el rubro: '+@w_descripcion_msg,
   @w_error = 705045--buscar el error
   return @w_error
end

return 0

GO

