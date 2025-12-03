/********************************************************************/
/*   NOMBRE LOGICO:      sp_consulta_atx                            */
/*   NOMBRE FISICO:      consatx.sp                                 */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Z.BEDON                                    */
/*   FECHA DE ESCRITURA: 03-Ene-1998                                */
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
/*   Ingreso de abonos                                              */
/*   S: Seleccion de negociacion de abonos automaticos              */
/*   Q: Consulta de negociacion de abonos automaticos               */
/*   I: Insercion de abonos                                         */
/*   U: Actualizacion de negociacion de abonos automaticos          */
/*   D: Eliminacion de negociacion de abonos automaticos            */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   03-Ene-1998  Z.Bedon         Emision Inicial                   */
/*   28-Feb-2019  Adriana Giler   Nuevas Consultas desde ATX.       */
/*   10-Jul-2019  Luis Ponce      Consulta Op.Grupales e Interciclos*/
/*   16-Jun-2021  Aldair Fortiche se agregan variables de salidas,  */
/*                                se agrega una consulta para buscar*/
/*                                por cedula y tipo de cedula y     */
/*                                finalmente se valida para cons    */
/*                                grupales e individuales para      */
/*                                ATX Teller                        */
/*   23-Sep-2021  Kevin Rodríguez Consulta préstamos por otras iden-*/
/*                                tificaciones y validación permitir*/
/*                                pagos por estado gestión cobranza */
/*   27-May-2022  Juan C. Guzman  Accion 'R' para consultar info de */
/*                                pagos a prestamos desde teller    */
/*                                para reversion de pagos.          */
/*   08-Feb-2023  WLO             CCA-S775772-ENL                   */
/*   15-Mar-2023  KDR             S795163 Montos de Abono grupal    */
/*   22-Ago-2023  G. Fernandez    R213765 Coreccion nom. de campo en*/
/*                                resulset y comentario rowcount op6*/
/*   28-Ago-2023  G. Fernandez    Se elimina comentarios de rowcount*/
/********************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_atx')
	drop proc sp_consulta_atx
go


create proc sp_consulta_atx
       	@s_user				login 		= null,
       	@s_term				varchar(30) = null,
       	@s_date				datetime 	= null,
       	@s_sesn				int 		= null,
       	@s_ofi 				smallint 	= null,
        @t_debug        	char(1) 	= 'N',
        @t_file         	varchar(20)	= null,
        @t_corr         	char(1)     = null,
       	@i_accion			char(1),
       	@i_opcion			char(1)		= null,
        @i_ced_ruc          numero 		= null,
        @i_tipo_ced         char(4)    	= null,
        @i_banco            cuenta 		= null,
        @i_cod_cliente      int 		= null,
        @i_nom_cliente      varchar(64) = null,
        @i_cta_banco        varchar(24) = null,
        @i_nom_grupo        varchar(64) = null,
        @i_operacion        int         = 0,
        @i_formato_fecha    int         = null,
        @i_cod_grupo        int         = null,--WLO_S775772

        @o_nom_cliente      varchar(64)	= null out,
        @o_cta_banco        cuenta      = null out,
        @o_estado           varchar(20) = null out,
        @o_monto            money  		= null out,
        @o_monto_max        money  		= null out,
        @o_moneda           tinyint 	= null out,
        @o_fecha_vig        varchar(20) = null out,
        @o_nombre_moneda    varchar(64) = null out,
        @o_tipo             char(1) 	= null out,
        @o_valor_vencido    money       = null out,
        @o_cuota_ven        money  		= null out,
        @o_cuota_vig        money  		= null out,
        @o_total_pag        money  		= null out,
        @o_liquidar         money  		= null out,
        @o_tipo_credito     varchar(64) = null out,
        @o_tipo_cartera     varchar(64) = null OUT,
        @o_codigo_grupo     INT         = NULL OUT,
        @o_nombre_grupo     VARCHAR(64) = NULL OUT,
        @o_cuota_ven_interc MONEY       = NULL OUT,
        @o_cuota_vig_interc MONEY       = NULL OUT,
        @o_total_pag_interc MONEY       = NULL OUT,
        @o_liquidar_interc  MONEY       = NULL OUT,
        @o_tipo_op_grupal   CHAR(1)     = NULL OUT,
        @o_toperacion       catalogo    = NULL OUT,
        @o_monto_vencido 	MONEY      	= NULL,
		@o_monto_vigente 	MONEY     	= NULL,
		@o_total            MONEY     	= NULL,
		@o_total_liquidar   MONEY     	= NULL
                       
as
declare @w_sp_name		descripcion,
        @w_return		int,
        @w_fecha_hoy	datetime,
        @w_error        int,
        @w_producto     tinyint,
        @w_operacionca  int,
        @w_moneda_local smallint,
        @w_estado       tinyint,
        @w_fecha_max    datetime,
        @w_opcion       INT,
        @w_tipo_grupal  CHAR(1)

select	@w_sp_name 		= 'sp_consulta_atx',
        @w_fecha_hoy 	= convert(varchar,@s_date,101),
        @w_error     	= 0

if @i_banco is not null --WLO_S775772
begin
   select 	@w_operacionca = op_operacion,
          	@w_estado      = op_estado
   from   	ca_operacion
   where  	op_banco = @i_banco
   --INI WLO_S775772
   and  (((op_grupal = 'N') or (op_grupal = 'S' and op_ref_grupal is not null)) and op_estado not in (0,99,3,6)
      or ((op_grupal = 'S' and op_ref_grupal is null) and op_estado = 3)
        )
   --FIN WLO_S775772
   
   --if @w_estado = 3 and @t_corr <> 'S'      --@t_corr = 'S'  es para reversos, y aqui se valida que no se realicen pagos a op. canceladas
   if (@@rowcount = 0 and isnull(@t_corr,'N') <> 'S') --WLO_S775772
   begin
      select @w_error = 701010--141031
      goto ERROR
   end
end --WLO_S775772

if @i_accion = 'Q' 
begin
   select @w_fecha_max = max(ct_fecha)
   from   cob_conta..cb_cotizacion

   select ct_moneda, ct_valor
   from   cob_conta..cb_cotizacion
   where  ct_fecha = @w_fecha_max
   set transaction isolation level read uncommitted


   if @i_banco is not null begin
      select 
	      @o_nom_cliente    = vx_nombre,
	      @o_monto          = vx_monto,
	      @o_monto_max      = vx_monto_max,
	      @o_moneda         = vx_moneda,
	      @o_valor_vencido  = vx_valor_vencido
      from ca_valor_atx
      where vx_banco = @i_banco

       if @@rowcount = 0
       begin
          select 
	          @o_nom_cliente    = op_nombre,
	          @o_monto          = 0,
	          @o_monto_max      = 0,
	          @o_moneda         = op_moneda,
	          @o_valor_vencido  = 0
          from  ca_operacion
          where op_banco = @i_banco
          ---select @w_error = 710524
          ---goto ERROR
       end

	select 	@w_producto = pd_producto
    from 	cobis..cl_producto
	where 	pd_abreviatura = 'CCA'
	set transaction isolation level read uncommitted

	select  @o_fecha_vig = convert(varchar(10),fc_fecha_cierre,101)
	from 	cobis..ba_fecha_cierre
	where 	fc_producto = @w_producto

	select @o_nombre_moneda = mo_descripcion
	from cobis..cl_moneda
	where mo_moneda = @o_moneda

	select @o_nombre_moneda = mo_descripcion      
	from cobis..cl_moneda
	where mo_moneda = @o_moneda

	select @o_tipo = op_tipo
	from ca_operacion
	where op_banco = @i_banco
   end
end

if @i_accion = 'A' begin

   if @i_ced_ruc is null

      select 	@i_ced_ruc = en_ced_ruc
      from 		cobis..cl_ente
      where 	en_ente = @i_cod_cliente
      set transaction isolation level read uncommitted

   select 	@o_nom_cliente = vx_nombre
   from 	ca_valor_atx
   where 	vx_ced_ruc = @i_ced_ruc

   if @@rowcount = 0 begin
      select @w_error = 701025
      goto ERROR
   end  

   select 
   'OPERACION'         = vx_banco,
   'MONEDA'            = vx_moneda,           -- SIEMPRE EN PESOSvx_moneda, 
   'MONTO VENCIDO'     = vx_valor_vencido,
   'MONTO PAGO'        = vx_monto,  ----Incluye lo vencido
   'MONTO CANCELACION' = vx_monto_max
   
   from ca_valor_atx
   where vx_ced_ruc = @i_ced_ruc
    and   vx_monto_max  > 0

   if @@rowcount = 0 begin
      select @w_error = 701025
      goto ERROR
   end 
end


if @i_accion = 'C'
begin
   
    if @i_cod_cliente is not null select @w_opcion = 1
    if @i_nom_cliente is not null select @w_opcion = 2
    if @i_banco       is not null select @w_opcion = 3
    if @i_cta_banco   is not null select @w_opcion = 4
    if @i_nom_grupo   is not null select @w_opcion = 5
    if @i_ced_ruc is not null and @i_tipo_ced is not null 
    	select @w_opcion = 6
    if @i_cod_grupo   is not null select @w_opcion = 7 --WLO_S775772

    if @w_opcion = 1  --Por Cod.Cliente
    begin
        set rowcount 20
               --INI WLO_S775772
        select 'OPERACION'    = op_banco,
               'PRODUCTO'     = isnull((select valor
                                        from   cobis..cl_tabla t, cobis..cl_catalogo c
                                        where  t.tabla  = 'ca_toperacion'
                                        and    c.tabla  = t.codigo
                                        and    c.codigo = A.op_toperacion
                                        and    c.estado = 'V'), ''),
               'CLIENTE'      = op_nombre,
               'PRESTAMO'     = op_operacion,
               'GRUPO'        = isnull((select gr_nombre 
                                        from   cobis..cl_grupo, cobis..cl_ente 
                                        where  en_ente = A.op_cliente
                                        and    gr_grupo = en_grupo), ''),
               'NRO. CUENTA'  = IsNull(ah_cta_banco,''),
               --'TIPO CUENTA'  = IsNull((select pb_descripcion from cob_remesas..pe_pro_bancario
               --                  where pb_pro_bancario = ah_prod_banc),''),
               'T. OPER'      = isnull((select 'GRUPAL'
                                        from    cob_cartera..ca_operacion
                                        where   op_ref_grupal is null
                                        and     op_grupal      = 'S'
                                        and     op_banco       = A.op_banco),'')
               --FIN WLO_S775772
        from ca_operacion A
        LEFT OUTER JOIN cob_ahorros..ah_cuenta on ah_cta_banco = op_cuenta
        where op_cliente = @i_cod_cliente
        and  op_operacion > @i_operacion
        --and  op_estado not in (0,99,3) --WLO_S775772
        --INI WLO_S775772
        and  (((op_grupal = 'N') or (op_grupal = 'S' and op_ref_grupal is not null)) and op_estado not in (0,99,3,6)
           or ((op_grupal = 'S' and op_ref_grupal is null) and op_estado = 3)
             )
        --FIN WLO_S775772
        order by op_operacion
        
        if @@rowcount = 0 
		begin
		   select @w_error = 151172-- 'No existen registros'
		   goto ERROR
		end
    end
    
    if @w_opcion = 2  --Por Nombre Cliente
    begin
        set rowcount 20
               --INI WLO_S775772
        select 'OPERACION'    = op_banco,
               'PRODUCTO'     = isnull((select valor
                                        from   cobis..cl_tabla t, cobis..cl_catalogo c
                                        where  t.tabla  = 'ca_toperacion'
                                        and    c.tabla  = t.codigo
                                        and    c.codigo = A.op_toperacion
                                        and    c.estado = 'V'), ''),
               'CLIENTE'      = op_nombre,
               'PRESTAMO'     = op_operacion,
               'GRUPO'        = isnull((select gr_nombre 
                                        from   cobis..cl_grupo, cobis..cl_ente 
                                        where  en_ente = A.op_cliente
                                        and    gr_grupo = en_grupo), ''),
               'NRO. CUENTA'  = IsNull(ah_cta_banco,''),
               --'TIPO CUENTA'  = IsNull((select pb_descripcion from cob_remesas..pe_pro_bancario
               --                  where pb_pro_bancario = ah_prod_banc),''),
               'T. OPER'      = isnull((select 'GRUPAL'
                                        from    cob_cartera..ca_operacion
                                        where   op_ref_grupal is null
                                        and     op_grupal      = 'S'
                                        and     op_banco       = A.op_banco),'')
               --FIN WLO_S775772
        from ca_operacion A
        LEFT OUTER JOIN cob_ahorros..ah_cuenta on ah_cta_banco = op_cuenta
        where op_nombre like '%' + @i_nom_cliente + '%'
        --and  op_estado not in (0,99,3) --WLO_S775772
        --INI WLO_S775772
        and  (((op_grupal = 'N') or (op_grupal = 'S' and op_ref_grupal is not null)) and op_estado not in (0,99,3,6)
           or ((op_grupal = 'S' and op_ref_grupal is null) and op_estado = 3)
             )
        --FIN WLO_S775772
        and  op_operacion > @i_operacion
        order by op_operacion
        
        if @@rowcount = 0 
		begin
		   select @w_error = 151172-- 'No existen registros'
		   goto ERROR
		end
    end
   
    if @w_opcion = 3  -- Por Numero de Operacion
    begin
        set rowcount 20
               --INI WLO_S775772
        select 'OPERACION'    = op_banco,
               'PRODUCTO'     = isnull((select valor
                                        from   cobis..cl_tabla t, cobis..cl_catalogo c
                                        where  t.tabla  = 'ca_toperacion'
                                        and    c.tabla  = t.codigo
                                        and    c.codigo = A.op_toperacion
                                        and    c.estado = 'V'), ''),
               'CLIENTE'      = op_nombre,
               'PRESTAMO'     = op_operacion,
               'GRUPO'        = isnull((select gr_nombre 
                                        from   cobis..cl_grupo, cobis..cl_ente 
                                        where  en_ente = A.op_cliente
                                        and    gr_grupo = en_grupo), ''),
               'NRO. CUENTA'  = IsNull(ah_cta_banco,''),
               --'TIPO CUENTA'  = IsNull((select pb_descripcion from cob_remesas..pe_pro_bancario
               --                  where pb_pro_bancario = ah_prod_banc),''),
               'T. OPER'      = isnull((select 'GRUPAL'
                                        from    cob_cartera..ca_operacion
                                        where   op_ref_grupal is null
                                        and     op_grupal      = 'S'
                                        and     op_banco       = A.op_banco),'')
               --FIN WLO_S775772
        from ca_operacion A
        LEFT OUTER JOIN cob_ahorros..ah_cuenta on ah_cta_banco = op_cuenta
        where op_banco = @i_banco  
        --and  op_estado not in (0,99,3) --WLO_S775772
        --INI WLO_S775772
        and  (((op_grupal = 'N') or (op_grupal = 'S' and op_ref_grupal is not null)) and op_estado not in (0,99,3,6)
           or ((op_grupal = 'S' and op_ref_grupal is null) and op_estado = 3)
             )
        --FIN WLO_S775772
        and  op_operacion > @i_operacion         
        order by op_operacion
        
        if @@rowcount = 0 
		begin
		   select @w_error = 151172-- 'No existen registros'
		   goto ERROR
		end
    end
    
    if @w_opcion = 4  --Por Cuenta de Ahorro
    begin
        set rowcount 20
               --INI WLO_S775772
        select 'OPERACION'    = op_banco,
               'PRODUCTO'     = isnull((select valor
                                        from   cobis..cl_tabla t, cobis..cl_catalogo c
                                        where  t.tabla  = 'ca_toperacion'
                                        and    c.tabla  = t.codigo
                                        and    c.codigo = A.op_toperacion
                                        and    c.estado = 'V'), ''),
               'CLIENTE'      = op_nombre,
               'PRESTAMO'     = op_operacion,
               'GRUPO'        = isnull((select gr_nombre 
                                        from   cobis..cl_grupo, cobis..cl_ente 
                                        where  en_ente = A.op_cliente
                                        and    gr_grupo = en_grupo), ''),
               'NRO. CUENTA'  = ah_cta_banco,
               --'TIPO CUENTA'  = pb_descripcion,
               'T. OPER'      = isnull((select 'GRUPAL'
                                        from    cob_cartera..ca_operacion
                                        where   op_ref_grupal is null
                                        and     op_grupal      = 'S'
                                        and     op_banco       = A.op_banco),'')
               --FIN WLO_S775772
        from ca_operacion A, cob_ahorros..ah_cuenta, cob_remesas..pe_pro_bancario
        where ah_cta_banco =  @i_cta_banco
        and   op_cuenta = ah_cta_banco
        and   pb_pro_bancario = ah_prod_banc
        --and  op_estado not in (0,99,3) --WLO_S775772
        --INI WLO_S775772
        and  (((op_grupal = 'N') or (op_grupal = 'S' and op_ref_grupal is not null)) and op_estado not in (0,99,3,6)
           or ((op_grupal = 'S' and op_ref_grupal is null) and op_estado = 3)
             )
        --FIN WLO_S775772
        and   op_operacion > @i_operacion     
        order by op_operacion
        
        if @@rowcount = 0 
		begin
		   select @w_error = 151172-- 'No existen registros'
		   goto ERROR
		end
    end
    
    if @w_opcion = 5 -- Por Nombre de Grupo
    begin
        set rowcount 20
               --INI WLO_S775772
        select distinct
               'OPERACION'    = op_banco,
               'PRODUCTO'     = isnull((select valor
                                        from   cobis..cl_tabla t, cobis..cl_catalogo c
                                        where  t.tabla  = 'ca_toperacion'
                                        and    c.tabla  = t.codigo
                                        and    c.codigo = A.op_toperacion
                                        and    c.estado = 'V'), ''),
               'CLIENTE'      = op_nombre,
               'PRESTAMO'     = op_operacion,
               'GRUPO'        = gr_nombre,
               'NRO. CUENTA'  = IsNull(ah_cta_banco,''),
               --'TIPO CUENTA'  = IsNull((select pb_descripcion from cob_remesas..pe_pro_bancario
               --                  where pb_pro_bancario = ah_prod_banc),''),
               'T. OPER'      = isnull((select 'GRUPAL'
                                        from    cob_cartera..ca_operacion
                                        where   op_ref_grupal is null
                                        and     op_grupal      = 'S'
                                        and     op_banco       = A.op_banco),'')
               --FIN WLO_S775772
        from cobis..cl_grupo, cobis..cl_ente, ca_operacion A with (nolock)
        LEFT OUTER JOIN cob_ahorros..ah_cuenta on ah_cta_banco = op_cuenta
        where gr_nombre like '%' + @i_nom_grupo + '%'  
        and  en_grupo = gr_grupo
        --INI WLO_S775772
        and  op_grupo   = gr_grupo
        --and  op_estado not in (0,99,3,6)
        and  (((op_grupal = 'N') or (op_grupal = 'S' and op_ref_grupal is not null)) and op_estado not in (0,99,3,6) and  op_cliente = en_ente
           or ((op_grupal = 'S' and op_ref_grupal is null) and op_estado = 3)
             )
        --FIN WLO_S775772
        and  op_operacion > @i_operacion
        order by op_operacion
        
      	if @@rowcount = 0 
		begin
		   select @w_error = 151172-- 'No existen registros'
		   goto ERROR
		end
    end
    
    if @w_opcion = 6  --Por Ced/Ruc
    begin
	   
	   CREATE TABLE #operaciones_cli (
	      oc_operacion      VARCHAR (24),
		  oc_producto       VARCHAR (64),
		  oc_cliente        VARCHAR (160),
		  oc_prestamo       INT,
		  oc_grupo          VARCHAR (160),
		  oc_cuenta         VARCHAR (24)
	   )
	   
	   set rowcount 20
	   
	   insert into #operaciones_cli
	   select op_banco,
              isnull((select valor
               from cobis..cl_tabla t, cobis..cl_catalogo c
               where t.tabla  = 'ca_toperacion'
               and   c.tabla  = t.codigo
               and   c.codigo = op_toperacion
               and   c.estado = 'V'), ''),
              op_nombre, 
              op_operacion,
              isnull((select gr_nombre from cobis..cl_grupo
               where gr_grupo = en_grupo), ''),
              isnull(ah_cta_banco,'')
       from cobis..cl_ente, ca_operacion A 
       LEFT OUTER JOIN cob_ahorros..ah_cuenta on ah_cta_banco = op_cuenta
       where en_ced_ruc    = @i_ced_ruc   
	   and	 en_tipo_ced   = @i_tipo_ced
       and   op_cliente    = en_ente
       and   op_operacion  > @i_operacion   
       and   op_estado not in (0,99,3,6) --WLO_S775772
       order by op_operacion
	   
	   if @@rowcount = 0 
	   begin
	      insert into #operaciones_cli
		  select op_banco,
                 isnull((select valor
                  from cobis..cl_tabla t, cobis..cl_catalogo c
                  where t.tabla  = 'ca_toperacion'
                  and   c.tabla  = t.codigo
                  and   c.codigo = op_toperacion
                  and   c.estado = 'V'), ''),
                 op_nombre, 
                 op_operacion,
                 isnull((select gr_nombre from cobis..cl_grupo
                  where gr_grupo = en_grupo), ''),
                 isnull(ah_cta_banco,'')
          from cobis..cl_ente, cobis..cl_ident_ente, ca_operacion A 
          LEFT OUTER JOIN cob_ahorros..ah_cuenta on ah_cta_banco = op_cuenta
          where ie_numero     = @i_ced_ruc   
	      and	ie_tipo_doc   = @i_tipo_ced
          and   op_cliente    = ie_ente
		  and   ie_ente       = en_ente
          and   op_operacion  > @i_operacion    
          and   op_estado not in (0,99,3,6) --WLO_S775772
          order by op_operacion
		  
		  if @@rowcount = 0
	      begin
	   	     select @w_error = 151172-- 'No existen registros'
	   	     goto ERROR
	      end

	   end
	   
	   select 'OPERACION'    = oc_operacion,
              'PRODUCTO'     = oc_producto,
              'CLIENTE'      = oc_cliente, 
              'PRESTAMO'     = oc_prestamo,
              'GRUPO'        = oc_grupo,
              'NRO. CUENTA'  = oc_cuenta,
              --INI WLO_S775772
              'T. OPER'      = isnull((select 'GRUPAL'
                                       from    cob_cartera..ca_operacion
                                       where   op_ref_grupal is null
                                       and     op_grupal      = 'S'
                                       and     op_banco       = oc_operacion),'')
              --FIN WLO_S775772
       from #operaciones_cli

    end

    --INI WLO_S775772
    if @w_opcion = 7  --Por Codigo de grupo
    begin
        set rowcount 20
        
        select distinct
               'OPERACION'    = op_banco,
               'PRODUCTO'     = isnull((select valor
                                        from   cobis..cl_tabla t, cobis..cl_catalogo c
                                        where  t.tabla  = 'ca_toperacion'
                                        and    c.tabla  = t.codigo
                                        and    c.codigo = A.op_toperacion
                                        and    c.estado = 'V'), ''),
               'CLIENTE'      = op_nombre,
               'PRESTAMO'     = op_operacion,
               'GRUPO'        = gr_nombre,
               'NRO. CUENTA'  = IsNull(ah_cta_banco,''),
               'T. OPER'      = isnull((select 'GRUPAL'
                                        from    cob_cartera..ca_operacion
                                        where   op_ref_grupal is null
                                        and     op_grupal      = 'S'
                                        and     op_banco       = A.op_banco),'')
        from cobis..cl_grupo, cobis..cl_ente, ca_operacion A with (nolock)
        LEFT OUTER JOIN cob_ahorros..ah_cuenta on ah_cta_banco = op_cuenta
        where gr_grupo  = @i_cod_grupo
        and  en_grupo   = gr_grupo        
        and  (((op_grupal = 'N') or (op_grupal = 'S' and op_ref_grupal is not null)) and op_estado not in (0,99,3,6) and  op_cliente = en_ente
           or ((op_grupal = 'S' and op_ref_grupal is null) and op_estado = 3)
             )
        and  op_grupo   = gr_grupo
        and  op_operacion > @i_operacion
        order by op_operacion
        
        if @@rowcount = 0 
        begin
           select @w_error = 151172-- 'No existen registros'
           goto ERROR
        end
    end
    --FIN WLO_S775772

end

if @i_accion = 'O'
BEGIN
    
    if exists (select 1 from ca_operacion_datos_adicionales where oda_operacion = @w_operacionca and oda_aceptar_pagos = 'N')
	begin
		select @w_error = 725094
		goto ERROR
	end
	
	if exists(		select 	1
					from 	ca_operacion
					where 	op_ref_grupal is null
					and 	op_grupal = 'S'
					AND 	op_banco = @i_banco)
	BEGIN
		select @i_opcion = 'G'
	END
	else
	begin
		select @i_opcion = 'I'
	end
	
	IF @i_opcion = 'G'
	BEGIN 

        exec @w_error = sp_pago_grupal_consulta_montos
        @i_canal          = '4',      -- 1: Cartera, 2: Batch, 3: Web service, 4: ATX
        @i_banco          = @i_banco, -- Numero de operacion grupal padre
        @i_operacion      = 'R',
		@o_monto_vencido  = @o_monto_vencido out,
		@o_monto_vigente  = @o_monto_vigente out,
		@o_total          = @o_total out,
		@o_total_liquidar = @o_total_liquidar out
		
        if @w_error <> 0
        begin
           select @w_error = @w_error
           goto ERROR
        end
		
        select 	   'nomCliente'   	= op_nombre,
				   'tipoCredito'  	= C.valor,
		           'estado'        	= es_descripcion,
		           'ctaBanco'     	= ah_cta_banco,
		           'montoVencido'   = @o_monto_vencido, 
				   'montoVigente'   = @o_monto_vigente,
				   'totalMonto'     = @o_total,
				   'totalLiquidar'  = @o_total_liquidar,
				   'tipoPago'	 	= op_tipo_cobro
	    from 		cobis..cl_tabla B, 
	    			cobis..cl_catalogo C,
	    			ca_estado, 
	    			ca_operacion A   
	    left outer join cob_ahorros..ah_cuenta on ah_cta_banco = op_cuenta
	    where 		op_banco = @i_banco
	    and   		es_codigo = case op_estado when 3 then 66 else op_estado  end
	    and   		B.tabla in ( 'ca_toperacion', 'cl_banca_cliente')
	    and   		C.tabla = B.codigo
	    and   		C.codigo = op_toperacion
                   
	   
	END
    ELSE IF @i_opcion = 'I'
   	BEGIN	   
	   	EXEC @w_error = cob_cartera..sp_qr_pagos 
							@i_banco				= @i_banco,
							@i_formato_fecha		= @i_formato_fecha,
							@i_operacion			= 'X', ---> Para mostrar montos en atx teller
							@i_tipo_pago_can		= 'A',
							@i_cancela				= 'N',
							@i_calcula_devolucion	= 'N',
							@t_trn					= 7144,
							@s_user					= @s_user,
							@s_term					= @s_term,
							@s_ofi					= @s_ofi,
							@s_date					= @s_date,
							@o_monto_vencido   		= @o_monto_vencido 	out, 
							@o_monto_vigente   		= @o_monto_vigente 	out,
							@o_total           		= @o_total 			out,
							@o_total_liquidar  		= @o_total_liquidar out
					
		IF @w_error <> 0
		BEGIN
		   select @w_error = @w_error
		   goto ERROR
		END
										
		select 	   'nomCliente'   	= op_nombre,
				   'tipoCredito'  	= C.valor,
		           'estado'        	= es_descripcion,
		           'ctaBanco'     	= ah_cta_banco,
		           'montoVencido'   = @o_monto_vencido, 
				   'montoVigente'   = @o_monto_vigente,
				   'totalMonto'     = @o_total,
				   'totalLiquidar'  = @o_total_liquidar,
				   'tipoPago'	 	= op_tipo_cobro
	    from 		cobis..cl_tabla B, 
	    			cobis..cl_catalogo C,
	    			ca_estado, 
	    			ca_operacion A   
	    LEFT OUTER JOIN cob_ahorros..ah_cuenta on ah_cta_banco = op_cuenta
	    where 		op_banco = @i_banco
	    and   		es_codigo = op_estado
	    and   		B.tabla IN ( 'ca_toperacion', 'cl_banca_cliente')
	    and   		C.tabla = B.codigo
	    and   		C.codigo = op_toperacion

   	END 
end

if @i_accion = 'R'
begin
   select 'OPERACION'      = sa_operacion,
          'FECHA PROCESO'  = convert(varchar, tm_fecha, 101),
          'FECHA REAL'     = convert(varchar, sa_fecha_real, 101)+' ' + convert(varchar, sa_fecha_real, 108),
          'SSN CORR'       = tm_ssn_host,
          'OFICINA'        = (select of_nombre from cobis..cl_oficina where of_oficina = sa_oficina),
          'VALOR EFE'      = sa_valor_efe,
          'VALOR CHQ'      = sa_valor_cheq,
          'USUARIO'        = tm_usuario,
          'COD CAJA'       = (select dc_codigo from cob_teller..re_definicion_caja where dc_id = tm_idcaja),
          'ID CAJA'        = tm_idcaja
   from ca_secuencial_atx, 
        cob_teller..re_tran_monet
   where sa_estado     = 'A'
   and   sa_operacion  = tm_cta_banco
   and   tm_correccion = 'N'
   and   tm_ssn_host   = sa_secuencial_ssn
   and   sa_fecha_ing  = @s_date
   and   sa_operacion  = @i_banco
   order by tm_hora desc
   
   if @@rowcount = 0
   begin
      select @w_error = 725148
      goto ERROR
   end
end

--INI WLO_S775772
if @i_accion = 'L'
begin
   exec @w_error = sp_pago_grupal_consulta_montos
      @i_canal     = '4', -- 1: Cartera, 2: Batch, 3: Web service, 4: ATX
      @i_banco     = @i_banco,--Numero de operacion grupal padre
      @i_operacion = 'S'

   if @w_error <> 0
   begin
      select @w_error = @w_error
      goto ERROR
   end
end
--FIN WLO_S775772

return 0

ERROR:
   exec cobis..sp_cerror
	   @t_debug = 'N',    
	   @t_file  = null,
	   @t_from  = @w_sp_name,   
	   @i_num   = @w_error
	   
   return @w_error

go
