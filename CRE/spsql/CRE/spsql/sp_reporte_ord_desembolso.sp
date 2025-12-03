/********************************************************************/
/*   NOMBRE LOGICO:         sp_reporte_ord_desembolso               */
/*   NOMBRE FISICO:         sp_reporte_ord_desembolso.sp            */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          P. Jarrin.                              */
/*   FECHA DE ESCRITURA:    15-Mar-2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Obtener los datos necesarios para el reporte Orden de          */
/*   Desembolso                                                     */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   15-Mar-2023      P. Jarrin.       Emision Inicial - S779077    */
/*   24-Mar-2023      P. Jarrin.       Se agrega formato - S801301  */
/*   30-Mar-2023      P. Jarrin.       Se agrega orden - S801301    */
/*   13-Nov-2023      D. Morales.      R219218:Se actualiza cuota   */
/*   01-Dic-2023      D. Morales.      R220687:Se excluyen op       */
/*                                     con estado 6                 */
/*   30-Sep-2024      D. Morales       R244659:Se añade nolock      */
/*                                     ca_rubro_op                  */
/********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_reporte_ord_desembolso')
   drop proc sp_reporte_ord_desembolso
go

create proc sp_reporte_ord_desembolso(
        @s_ssn               int          = null,
        @s_date              datetime     = null,
        @s_user              login        = null,
        @s_term              descripcion  = null,
        @s_corr              char(1)      = null,
        @s_ssn_corr          int          = null,
        @s_ofi               smallint     = null,
        @t_rty               char(1)      = null,
        @t_debug             char(1)      = 'N',
        @t_file              varchar(14)  = null,
        @t_trn               smallint     = null,  
        @t_show_version      bit          = 0,
        @i_tramite           int,
        @i_operacion         char(1)
)
as
declare @w_sp_name              varchar(32),
        @w_sp_msg               varchar(100),
        @w_return               int,        
        @w_error                int,
        @w_formato_fecha        int, 
        @w_producto_renov       varchar(10),
        @w_filial               varchar(200),
        @w_fecha_imp            varchar(10),
        @w_banco                varchar(10),
        @w_telefono             varchar(200),
        @w_banco_padre          varchar(24),
        @w_ciclo                varchar(10),
        @w_simbolo              varchar(10),
        @w_formato              varchar(10),
        @w_op_cuota             varchar(200)		


declare @w_tabla_datos as table(
        filial               varchar(200),
        oficina              varchar(200),
        fecha_imp            varchar(200),
        numero               varchar(200),
        cliente              varchar(200),
        nombre_completo      varchar(200),
        fecha_desembolso     varchar(200),
        grupo                varchar(200),
        nombre_grupo         varchar(200),
        ciclo                varchar(200),
        fecha_ven            varchar(200),
        asesor               varchar(200),
        nombre_asesor        varchar(200),
        cuota                varchar(200),
        producto             varchar(200),
        nombre_producto      varchar(200),
        tasa_nominal         varchar(200),
        prestamo             varchar(200),
        tasa_efectiva        varchar(200),
        frecuencia_pago      varchar(200),
        tasa_mora            varchar(200),
        monto_aprobado_aux   money,
        monto_aprobado       varchar(200),
        descuentos_aux       money,     
        otros_aux            money,     
        descuentos           varchar(200),
        total_entrega        varchar(200),
        ciudad               varchar(200),
        telefono             varchar(200),
        rol                  char(1),
        orden                smallint,
        operacion            int		
)

select  @w_sp_name           = 'sp_reporte_ord_desembolso',
        @w_filial            = '',
        @w_fecha_imp         = '', 
        @w_banco             = '', 
        @w_telefono          = '', 
        @w_banco_padre       = '', 
        @w_ciclo             = '',
        @w_formato_fecha     = 103,
        @w_formato           = '#,##0.00'       
        
if @t_trn <> 21868
begin
exec cobis..sp_cerror
     select @w_return = 151051
     goto ERROR_FIN
end

select @w_producto_renov = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'REESFP'    


--Search Data
if @i_operacion = 'S'
begin
 
    select 
           @w_filial       = (select fi_nombre from cobis..cl_filial, cobis..cl_oficina where fi_filial = of_filial and of_oficina =  op_oficina),
           @w_fecha_imp    = (select convert(varchar(10),fp_fecha ,@w_formato_fecha) from cobis..ba_fecha_proceso),
           @w_banco_padre  = op_banco, 
           @w_telefono     = (select to_valor from cobis..cl_telefono_of, cobis..cl_oficina where to_oficina = of_oficina and to_oficina = op_oficina and to_secuencial = of_telefono),
           @w_ciclo        = 'Ciclo: ' + convert(varchar,isnull((select ci_ciclo from cob_cartera..ca_ciclo where ci_tramite = tr_tramite),0)),
           @w_simbolo      = (select mo_simbolo from cobis..cl_moneda where mo_moneda = op_moneda)
     from cob_credito..cr_tramite tr, cob_cartera..ca_operacion op
    where tr_tramite = op_tramite
      and tr_tramite = @i_tramite 
  
    if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin 
        insert into @w_tabla_datos
        (
            filial,
            oficina,
            fecha_imp,
            numero,
            cliente,
            nombre_completo,
            fecha_desembolso,
            grupo,
            nombre_grupo,
            ciclo,
            fecha_ven,
            asesor,
            nombre_asesor,
            producto,
            nombre_producto,
            tasa_nominal,
            prestamo,
            tasa_efectiva,
            frecuencia_pago,
            tasa_mora,
            monto_aprobado_aux,
            monto_aprobado,
            descuentos_aux,
            otros_aux,
            descuentos,
            total_entrega,
            ciudad,
            telefono,
            rol,
			operacion
        )
        select  
            @w_filial,
            (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
            @w_fecha_imp,
            @w_banco_padre,
            op_cliente,
            isnull(trim(en_nombre), '') + ' ' + isnull(trim(p_s_nombre), '') + ' ' + isnull(trim(p_p_apellido), '') + ' ' + isnull(trim(p_s_apellido), '') + ' ' + isnull(trim(p_c_apellido), ''),
            (convert(varchar(10),op_fecha_liq,@w_formato_fecha)),
            op_grupo,
            (select gr_nombre from cobis..cl_grupo where gr_grupo = op_grupo),
            @w_ciclo,
            (convert(varchar(10),op_fecha_fin ,@w_formato_fecha)),
            op_oficial,
            (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial where fu_funcionario = oc_funcionario and oc_oficial = op_oficial),
            op_toperacion,
            (select isnull(trim(valor),'') from cobis..cl_catalogo c, cobis..cl_tabla t where c.tabla = t.codigo and t.tabla = 'ca_toperacion' and c.codigo = trim(op_toperacion)),         
            (select convert(decimal(10,2),(isnull(ro_porcentaje,0))) from cob_cartera..ca_rubro_op with(nolock)  where ro_concepto = 'INT' and ro_operacion = op_operacion),
            op_banco,
            convert(decimal(10,2),(isnull(op_tasa_cap,0))), 
            (select td_descripcion from cob_cartera..ca_tdividendo where td_tdividendo = op_tdividendo),
            (select convert(decimal(10,2),(isnull(ro_porcentaje,0))) from cob_cartera..ca_rubro_op with(nolock)  where ro_concepto = 'IMO' and ro_operacion = op_operacion),          
            isnull(op_monto,0),
            '',
            isnull((select isnull(dm_monto_mop,0) from cob_cartera..ca_desembolso where dm_producto = @w_producto_renov and dm_operacion = op_operacion),0),
            (select isnull(sum(isnull(ro_valor,0)),0) from cob_cartera..ca_rubro_op with(nolock)  where ro_fpago = 'L' and ro_operacion  = op_operacion),
            '',
            '',
            (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
            @w_telefono,
            (select cg_rol from cobis..cl_cliente_grupo where  cg_ente = en_ente and cg_grupo = en_grupo),
			op_operacion
         from cob_cartera..ca_operacion, cobis..cl_ente
        where op_cliente    = en_ente
          and op_ref_grupal = @w_banco_padre
		  and op_estado not in (6)
        order by op_cliente  
    
        update @w_tabla_datos
           set orden = 1
         where rol = 'P'

        update @w_tabla_datos
           set orden = 2
         where rol not in ('P' , 'M')

        update @w_tabla_datos
           set orden = 3
         where rol = 'M'
     
    end
    else
    begin
       insert into @w_tabla_datos
        (
            filial,
            oficina,
            fecha_imp,
            numero,
            cliente,
            nombre_completo,
            fecha_desembolso,
            grupo,
            nombre_grupo,
            ciclo,
            fecha_ven,
            asesor,
            nombre_asesor,
            producto,
            nombre_producto,
            tasa_nominal,
            prestamo,
            tasa_efectiva,
            frecuencia_pago,
            tasa_mora,
            monto_aprobado_aux,
            monto_aprobado,
            descuentos_aux,
            otros_aux,
            descuentos,
            total_entrega,
            ciudad,
            telefono,
			operacion
        )
        select 
            @w_filial,
            (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
            @w_fecha_imp,
            @w_banco_padre,
            op_cliente,
            isnull(trim(en_nombre), '') + ' ' + isnull(trim(p_s_nombre), '') + ' ' + isnull(trim(p_p_apellido), '') + ' ' + isnull(trim(p_s_apellido), '') + ' ' + isnull(trim(p_c_apellido), ''),
            (convert(varchar(10),op_fecha_liq,@w_formato_fecha)),           
            (select gr_grupo from cobis..cl_grupo where gr_grupo in (select en_grupo from cobis..cl_ente where en_ente = op_cliente)),
            (select gr_nombre from cobis..cl_grupo where gr_grupo in (select en_grupo from cobis..cl_ente where en_ente = op_cliente)),
            '',
            (convert(varchar(10),op_fecha_fin ,@w_formato_fecha)),
            op_oficial,
            (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial where fu_funcionario = oc_funcionario and oc_oficial = op_oficial),
            op_toperacion,
            (select isnull(trim(valor),'') from cobis..cl_catalogo c, cobis..cl_tabla t where c.tabla = t.codigo and t.tabla = 'ca_toperacion' and c.codigo = trim(op_toperacion)),
            (select convert(decimal(10,2),(isnull(ro_porcentaje,0))) from cob_cartera..ca_rubro_op with(nolock)  where ro_concepto = 'INT' and ro_operacion = op_operacion),
            op_banco,           
            convert(decimal(10,2),(isnull(op_tasa_cap,0))), 
            (select td_descripcion from cob_cartera..ca_tdividendo where td_tdividendo = op_tdividendo),
            (select convert(decimal(10,2),(isnull(ro_porcentaje,0))) from cob_cartera..ca_rubro_op with(nolock)  where ro_concepto = 'IMO' and ro_operacion = op_operacion),
            isnull(op_monto,0),
            '',
            isnull((select isnull(dm_monto_mop,0) from cob_cartera..ca_desembolso where dm_producto = @w_producto_renov and dm_operacion = op_operacion),0),
            (select isnull(sum(isnull(ro_valor,0)),0) from cob_cartera..ca_rubro_op with(nolock)  where ro_fpago = 'L' and ro_operacion  = op_operacion),
            '',
            '',
            (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
            @w_telefono,
			op_operacion
         from cob_cartera..ca_operacion, cobis..cl_ente
        where op_cliente = en_ente
          and op_banco = @w_banco_padre
        order by op_cliente
    end
	
	update @w_tabla_datos
	set cuota = (select convert(varchar,format(sum(isnull(am_cuota,0)), @w_formato))
                 from cob_cartera..ca_amortizacion
                 where am_operacion = operacion
				 and am_dividendo = 1)

    select  
            filial,
            oficina,
            fecha_imp,
            numero,
            cliente,
            nombre_completo,
            fecha_desembolso,
            grupo,
            nombre_grupo = nombre_grupo + ' ' + ciclo,
            ciclo,
            fecha_ven,
            asesor,
            nombre_asesor,
            cuota = @w_simbolo + ' ' + cuota,
            producto,
            nombre_producto,
            tasa_nominal,
            prestamo,
            tasa_efectiva,
            frecuencia_pago,
            tasa_mora,
            monto_aprobado = @w_simbolo + ' ' + convert(varchar,format(monto_aprobado_aux, @w_formato)),
            descuentos     = @w_simbolo + ' ' + convert(varchar,format((descuentos_aux + otros_aux), @w_formato)),
            total_entrega  = @w_simbolo + ' ' + convert(varchar,format((monto_aprobado_aux - (descuentos_aux + otros_aux)), @w_formato)),
            ciudad,
            telefono
    from @w_tabla_datos 
    order by orden asc 
  
end

return 0

ERROR_FIN:
exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_return  
    
return @w_return
go
