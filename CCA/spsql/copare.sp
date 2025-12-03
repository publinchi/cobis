/************************************************************************/
/*  NOMBRE LOGICO:        copare.sp                                     */
/*  NOMBRE FISICO:        sp_consulta_pagos_recibidos                   */
/*  BASE DE DATOS:        cob_cartera                                   */
/*  PRODUCTO:             CARTERA                                       */
/*  DISENADO POR:         Guisela Fernandez                             */
/*  FECHA DE ESCRITURA:   14/Jun/2023                                   */
/************************************************************************/
/*                      IMPORTANTE                                      */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  En este programa se obtine los pagos realizados por fecha de proceso*/
/*  y usuario                                                           */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR         RAZON                                   */
/*  14/06/2023   G. Fernandez   Emisión Inicial                         */
/*  03/08/2023   G. Fernandez   Se habilita código para num factura     */
/*  04/09/2023   G. Fernandez   Se ingresa valores por defecto para     */
/*                              mostrar reporte                         */
/*  01/07/2024   K. Rodriguez   R238554 Get Datos por lotes (paginacion)*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_pagos_recibidos')
   drop proc sp_consulta_pagos_recibidos
go
create proc sp_consulta_pagos_recibidos
(
   @s_user                         login        = null,
   @s_ofi                          smallint     = null,
   @s_rol                          smallint     = null,
   @s_date                         datetime     = null,
   @t_trn                          int          = null,
   @i_operacion                    char(1)      = 'S',
   @i_lote                         smallint     = 0,
   @o_fin_lote                     char(1)      = null out
)
as  
declare
   @w_sp_name            descripcion,
   @w_error              int,
   @w_nom_oficina        descripcion,
   @w_total_regs         int,
   @w_sec_id             int,
   @w_records            smallint
   
select @w_sp_name = 'sp_consulta_pagos_recibidos',
       @w_records = 300


if @i_lote = 0 -- Primer lote de registros
begin

   delete ca_pagos_recibidos_tmp 
   where prt_usuario_consulta = @s_user

   --Genera universo de operaciones
   insert into ca_pagos_recibidos_tmp (
      prt_usuario_consulta,
	  prt_id            , 
      prt_producto      ,
      prt_forma_pago    ,
      prt_ref_grupal    ,
      prt_ref_individual,
      prt_monto         ,
      prt_fecha_proceso ,
      prt_fecha_valor   ,
      prt_cod_grupo     ,
      prt_nom_grupo     ,
      prt_cod_cliente   ,
      prt_nom_cliente   ,
      prt_estado        ,
      prt_usuario       ,
      prt_num_factura
      )
   select
   @s_user,
   row_number() over(order by op_toperacion, abd_concepto, op_ref_grupal, op_banco),
   (select c.valor from cobis..cl_tabla  t,cobis..cl_catalogo c where t.codigo = c.tabla and t.tabla = 'ca_toperacion' and c.codigo = op_toperacion),
   abd_concepto,
   case when op_grupal = 'S' then op_ref_grupal else null end,
   op_banco,
   abd_monto_mop,
   tr_fecha_mov,
   tr_fecha_ref,
   op_grupo,
   case when op_grupal = 'S' then (select gr_nombre from cobis..cl_grupo where gr_grupo = op_grupo) else '- SIN GRUPO -' end,
   op_cliente,
   op_nombre,
   (select es_descripcion from ca_estado where es_codigo = op_estado),
   tr_usuario,
   di_num_control
   from  ca_abono_det with (nolock), 
         ca_operacion with (nolock),
		 ca_transaccion with (nolock), 
		 ca_producto, 
		 ca_abono with (nolock)
   left join cob_externos..ex_dte_identificacion on ab_ssn = di_cod_secuencial -- Para obtener numero de Facturacion Electronica 
   where ab_operacion     = abd_operacion
   and ab_secuencial_ing  = abd_secuencial_ing
   and ab_operacion       = op_operacion
   and ab_operacion       = tr_operacion
   and ab_secuencial_pag  = tr_secuencial
   and tr_tran            = 'PAG'
   and tr_estado          <> 'RV'
   and abd_concepto       = cp_producto
   and cp_categoria       <> 'COND'
   and tr_ofi_usu         = @s_ofi
   and tr_fecha_mov       = @s_date
   and tr_usuario         not in (select  c.valor from cobis..cl_tabla  t,cobis..cl_catalogo c
                                  where t.tabla = 'ca_usuarios_excluidos_rep_fac'
                                  and t.codigo = c.tabla)
   order by op_toperacion, abd_concepto, op_ref_grupal, op_banco
   
   select @w_total_regs = @@rowcount
   
   if @w_total_regs = 0
   begin
      if not exists(select 1 from ca_pagos_recibidos_tmp where prt_usuario_consulta = @s_user)
         insert into ca_pagos_recibidos_tmp values (@s_user, 1, 'No existe registros', '', '', '', 0, '', '', 0 , '', 0 , '', '', '', '')
   end



end

select @w_nom_oficina = of_nombre 
from cobis..cl_oficina
where of_oficina = @s_ofi

--Datos de la cabecera
select 'OFICINA'       = @w_nom_oficina,
       'FECHA PROCESO' = convert(varchar(10),@s_date, 103)

--Listado de productos
select distinct prt_producto
from ca_pagos_recibidos_tmp
where prt_usuario_consulta = @s_user

--Listado de Productos y forma de pagos
select distinct prt_producto, prt_forma_pago
from ca_pagos_recibidos_tmp
where prt_usuario_consulta = @s_user


select @w_sec_id = @i_lote * @w_records

set rowcount @w_records
--Listado de pagos recibidos
select 
'Producto'        =    prt_producto,
'Forma Pago'      =    prt_forma_pago,
'Ref. Grupal'     =    isnull(prt_ref_grupal,''),
'Ref_Individual'  =    prt_ref_individual,
'Monto'           =    prt_monto,
'Fecha Proceso'   =    convert(varchar(10),prt_fecha_proceso, 103),
'Fecha Valor'     =    convert(varchar(10),prt_fecha_valor, 103),
'Cod. Grupo'      =    prt_cod_grupo,
'Nom. Grupo'      =    prt_nom_grupo,
'Cod. Cliente'    =    prt_cod_cliente,
'Nom. Cliente'    =    prt_nom_cliente,
'Estado'          =    prt_estado,
'Usuario'         =    prt_usuario,
'Factura'         =    isnull(prt_num_factura, '')
from ca_pagos_recibidos_tmp
where prt_usuario_consulta = @s_user
and   prt_id > @w_sec_id
order by prt_id

select @w_total_regs = @@rowcount

set rowcount 0

-- Después de últimos registros, se borrar tabla
if @w_total_regs < @w_records or (select max(prt_id) 
                                  from ca_pagos_recibidos_tmp 
                                  where prt_usuario_consulta = @s_user) = @w_sec_id + @w_records  -- últimos registros
begin

   delete ca_pagos_recibidos_tmp 
   where prt_usuario_consulta = @s_user
   
   select @o_fin_lote = 'S'

end
else
   select @o_fin_lote = 'N'

return 0

ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = '',
     @t_from  = @w_sp_name,
     @i_num   = @w_error

return @w_error
go
