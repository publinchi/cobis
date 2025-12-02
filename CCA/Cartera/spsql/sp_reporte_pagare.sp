/************************************************************************/
/*   Archivo:              sp_reporte_pagare.sp                         */
/*   Stored procedure:     sp_reporte_pagare_grupal                     */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Alexander Orbes                              */
/*   Fecha de escritura:   Julio 17-2019                                */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Genera el reporte de pagaré para operaciones grupales              */
/*                                                                      */
/*   MODIFICACIONES                                                     */
/************************************************************************/
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_reporte_pagare_grupal')
   drop proc sp_reporte_pagare_grupal
go

create proc sp_reporte_pagare_grupal
   @s_ofi               smallint    = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               int         = null,
   @i_opbanco           cuenta      = null,
   @i_documento         int         = null
   as 
   declare
   @w_sp_name                      varchar(32),
   @w_param_dir                    varchar(30),
   @w_param_dir_neg                varchar(30),
   @o_letras                       varchar(255),
   @w_moneda                       int,
   @w_monto                        money
   
      -- CAPTURA NOMBRE DE STORED PROCEDURE
   select   @w_sp_name = 'sp_reporte_pagare_grupal'

   select @w_moneda=op_moneda,@w_monto=op_monto from cob_cartera..ca_operacion where op_banco=@i_opbanco
   
   EXEC cob_credito..sp_conv_numero_letras
        @i_dinero=@w_monto,
        @i_moneda=@w_moneda,
        @i_opcion=4,
        @o_letras=@o_letras out
   
   select
   (select id_dato from cob_credito..cr_imp_documento where 
   id_documento=@i_documento) as "RECA",
   op_monto as "MONTO",
   (select ci_descripcion from cobis..cl_ciudad where ci_ciudad = op_ciudad) as "CIUDAD",
   (select gr_dir_reunion from cobis..cl_grupo where gr_grupo = op_grupo) as "DIRGRUPO",
   (select mo_moneda from cobis..cl_moneda where mo_moneda = op_moneda) as "CODMONEDA",
   @o_letras as "MONEDA",
   (select ro_porcentaje from cob_cartera..ca_rubro_op where 
   ro_concepto=(select pa_char from cobis..cl_parametro where pa_nemonico = 'INT' and pa_producto='CCA')
   and ro_operacion=op_operacion) as "PORCENTAJE",
   (select count(*) from cob_cartera..ca_dividendo
   where di_operacion=op_operacion) as "DIVIDENDO",
   (select td_descripcion from cob_cartera..ca_tdividendo
   where td_tdividendo = op_tdividendo) as "FRECUENCIA",
   op_dia_fijo as "VENCIMIENTO",
   (select ro_porcentaje from cob_cartera..ca_rubro_op where 
   ro_concepto=(select pa_char from cobis..cl_parametro where pa_nemonico = 'IMO' and pa_producto='CCA')
   and ro_operacion=op_operacion) as "PRJEMORA"
   from cob_cartera..ca_operacion
   where op_banco=@i_opbanco
   
   select @w_param_dir=pa_char from cobis..cl_parametro where pa_nemonico = 'TDRE'
   select @w_param_dir_neg=pa_char from cobis..cl_parametro where pa_nemonico = 'TDNE'
   
   select 
   (select concat(p_p_apellido,' ',p_s_apellido,' ',en_nombre,' ',p_s_nombre) 
   from cobis..cl_ente where en_ente=op_cliente) as "MIEMBRO",
   case when  not exists (select di_calle from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir) 
   then
   (select di_calle from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir_neg)
   else
   (select di_calle from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir) 
   end   
   as "CALLE",
   case when not exists (select di_casa from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir)
   then
   (select di_casa from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir_neg) 
   else
   (select di_casa from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir)
   end
   as "NRO",
   case when not exists (select di_edificio from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir)
   then
   (select di_edificio from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir_neg)
   else
   (select di_edificio from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir)
   end
    as "NROINT",
   case when not exists (select  pq_descripcion from cobis..cl_parroquia, cobis..cl_direccion
   where pq_parroquia=di_parroquia and di_ente =op_cliente and di_tipo=@w_param_dir) 
   then
   (select  pq_descripcion from cobis..cl_parroquia, cobis..cl_direccion
   where pq_parroquia=di_parroquia and di_ente =op_cliente and di_tipo=@w_param_dir_neg) 
   else
   (select  pq_descripcion from cobis..cl_parroquia, cobis..cl_direccion
   where pq_parroquia=di_parroquia and di_ente =op_cliente and di_tipo=@w_param_dir) 
   end
   as "COLONIA",
   case when not exists (select  pv_descripcion from cobis..cl_provincia, cobis..cl_direccion
   where pv_provincia=di_provincia and di_ente = op_cliente and di_tipo = @w_param_dir) 
   then
   (select  pv_descripcion from cobis..cl_provincia, cobis..cl_direccion
   where pv_provincia=di_provincia and di_ente = op_cliente and di_tipo = @w_param_dir_neg)
   else
   (select  pv_descripcion from cobis..cl_provincia, cobis..cl_direccion
   where pv_provincia=di_provincia and di_ente = op_cliente and di_tipo = @w_param_dir)
   end
   as "ESTADO",
   case when not exists (select ci_descripcion from cobis..cl_ciudad, cobis..cl_direccion
   where ci_ciudad = di_ciudad and di_ente = op_cliente and di_tipo = @w_param_dir) 
   then
   (select ci_descripcion from cobis..cl_ciudad, cobis..cl_direccion
   where ci_ciudad = di_ciudad and di_ente = op_cliente and di_tipo = @w_param_dir_neg)
   else
   (select ci_descripcion from cobis..cl_ciudad, cobis..cl_direccion
   where ci_ciudad = di_ciudad and di_ente = op_cliente and di_tipo = @w_param_dir) 
   end
   as "MUNICIPIO",
   case when not exists (select di_codpostal from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir) 
   then
   (select di_codpostal from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir_neg)
   else
   (select di_codpostal from cobis..cl_direccion where di_ente=op_cliente and di_tipo=@w_param_dir)
   end
   as "CODPOSTAL"
   from cob_cartera..ca_operacion where op_grupal = 'S' and op_ref_grupal = @i_opbanco
   
   select op_grupo as "NUMGRUPO",
   (select gr_nombre from cobis..cl_grupo where gr_grupo =op_grupo) as "NOMBREGRUPO",
   '734128 ',
   '591515 ',
   '1589',
   '00000000000005570833',
   '00000000000005570839',
   '00000000000055708359',
   '4079',
   '01000055708308',
   '5570833',
   '00000000000055708359',
   '00000000000055708359',
   '01000055708300000008',
   'Microfinanciera CAME',
   'CONSEJO DE ASISTENCIA AL MICROEMPRENDEDOR S.A. DE C.V. S.F.P.'
   from cob_cartera..ca_operacion 
   where op_banco = @i_opbanco

   
go
