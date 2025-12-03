/************************************************************************/
/*  Archivo:                riesgo_i.sp                                 */
/*  Stored procedure:       sp_riesgo_i                                 */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_riesgo_i')
    drop proc sp_riesgo_i
go

create proc sp_riesgo_i (
   @t_trn               smallint = null,
   @t_debug		char(1) = 'N',
   @t_file              varchar(14) = null,
   --@s_ssn               int      = null,
   --@s_user              login    = null,
   @s_sesn              int    = null,
   @s_term              descripcion = null,
   @s_date              datetime = null,
   @s_srv               varchar(30) = null,
   @s_lsrv              varchar(30) = null,
   @s_rol               smallint = null,
   @s_ofi               smallint  = null,
   @s_org_err           char(1) = null,
   @s_error             int = null,
   @s_sev               tinyint = null,
   @s_msg               descripcion = null,
   @s_org               char(1) = null,
   @i_cliente           int = null,
   @i_tramite           int = null,
   @i_detalle           char(1) = 'S',
   @i_limite            char(1) = null,
   @i_aprobado          char(1) = 'N', --ENVIAR SOLO TRAMITES APROBADOS O NO
   @i_indirecto         char(1) = 'S', --TOMAR EN CUENTA RIESGO INDIRECTO
   @i_ind_tr            char(1) = 'S', --TOMAR EN CUENTA INDIRECTOS EN TRAMITE
   @i_interes           char(1) = 'S', --SUMAR INTERES AL RIESGO
   @i_agrupado          char(1) = 'N', --AGRUPAR EN DIRECTO, INDIRECTO, CONTINGENTE
   @i_tipo_ctz          char(1) = 'B', --C COTIZACION DE CREDITO, B CONTABILIDAD
   @i_grupo             int     = null,
   @i_componente        char(1) = 'N',  --INDICA SI DEBE MAPEAR EL VALOR DE LOS COMPONENTES DEL RIESGO
   @o_opcion            money = null out,
   @o_opcion2           money = null out --TOTAL RIESGO CONTINGENTE
)
as
declare
   @w_today              datetime,     /* FECHA DEL DIA */ 
   @w_return             int,          /* VALOR QUE RETORNA */
   @w_sp_name            varchar(32),  /* NOMBRE STORED PROC*/
   @w_tipo               descripcion,
   @w_tipo_rubro         char(1),
   @w_garper             varchar(30),   --pga18jul2001 
   @w_conexion           int,
   @w_cliente_null	 char(1),
   @w_rowcount           int
   
   select @w_today = getdate() --@s_date
   select @w_sp_name = 'sp_riesgo_i'
   select @w_conexion = @@spid

   delete from cr_cliente_temporal
   where  cl_idconn = @w_conexion
   delete from cr_ope_temporal
   where  op_idconn = @w_conexion
   delete from cr_previa_temporal
   where  pr_idconn = @w_conexion
   delete from cr_resultado1_temporal
   where  idconn    = @w_conexion


   /* VALIDACION DE CAMPOS NULOS */
   /******************************/
   if @i_cliente is null and @i_grupo is null
   begin
      /* CAMPOS NOT NULL CON VALORES NULOS */
      exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_num   = 2101001
      return 1 
   end

   SELECT @i_indirecto  = pa_char
   FROM cobis..cl_parametro
   WHERE pa_nemonico = 'RIESIN'    
   and   pa_producto = 'CRE'
   select @w_rowcount = @@rowcount
   set transaction isolation level READ UNCOMMITTED
   
   if @i_indirecto is null or @w_rowcount = 0
   BEGIN
      /* Error, no existe valor de Parametro */
      SELECT @w_return = 2110350
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = @w_return
      return @w_return
   END


   /* LLENAR TABLA TEMPORAL DE CLIENTES */
   if @i_cliente is not null
   begin
      insert into cr_cliente_temporal (
      cl_idconn,	cl_cliente,	cl_tipo )
      values(
      @w_conexion,	@i_cliente,	'C')
      if @@error != 0
      begin
         exec cobis..sp_cerror
         @t_from   = @w_sp_name,
         @i_num    = 2103036  /* ERROR INSERTANDO DATOS EN TABAL TEMPORAL DE CLIENTE */
         return 1 
      end
      select @i_grupo	= en_grupo
      from   cobis..cl_ente
      where en_ente	= @i_cliente
      set transaction isolation level read uncommitted
      select @w_cliente_null = 'N'
   end
   else
      select @w_cliente_null = 'S'

   /* INSERTAR REGISTROS DE LOS MIEMBROS DEL GRUPO */
   if @i_grupo is not null and @i_grupo > 0
   begin
      insert into cr_cliente_temporal (
      cl_idconn,	cl_cliente,	cl_tipo )
      select 
      @w_conexion ,	en_ente,	'G'
      from	cobis..cl_ente,
		cobis..cl_cliente_grupo --(index cl_cliente_grupo_Key) 
      where cg_grupo	=  @i_grupo
      and   cg_ente     >= 0 
      and   cg_ente	=  en_ente
      and   cg_ente	<> @i_cliente

      if @@error != 0
      begin
         exec cobis..sp_cerror
         @t_from   = @w_sp_name,
         @i_num    = 2103036  /* ERROR INSERTANDO DATOS EN TABAL TEMPORAL DE CLIENTE */
         return 1 
      end
   end

   insert into cr_cliente_temporal (
   cl_idconn,	cl_cliente,	cl_tipo )
   select distinct
   @w_conexion,	in_ente_d,	'R'
   from cobis..cl_instancia
   where in_relacion in (select convert(smallint, c.codigo)
					   from	   cobis..cl_tabla t, 
						   cobis..cl_catalogo c
                                           where   t.tabla  = 'cr_relaciones'
					   and     c.estado = 'V'
                                           and     t.codigo = c.tabla)
   and in_ente_i = @i_cliente
   and  in_ente_d not in (select cl_cliente
                         from   cr_cliente_temporal
                         where  cl_idconn = @w_conexion
                         and    cl_tipo	  in ('G','C'))

   if @@error != 0
   begin
      exec cobis..sp_cerror
      @t_from   = @w_sp_name,
      @i_num    = 2103036  /* ERROR INSERTANDO DATOS EN TABLA TEMPORAL DE CLIENTE */
      return 1 
   end

   /*  LLENAR LOS DATOS DE OPERACIONES DONDE LOS CLIENTES SON DEUDORES */
   insert into cr_ope_temporal
      (op_idconn, op_operacion, op_banco, op_toperacion, 
      op_producto,
      op_abreviatura,	
      op_tipo_riesgo, 
      op_saldo_cap, op_saldo_otr, op_saldo_int,	
      op_disponible, op_estado, op_tramite, op_estado_tr,		
      op_tipo_cl, op_rol_cl )
   select 
      @w_conexion, do_numero_operacion, do_numero_operacion_banco, do_tipo_operacion,
      do_codigo_producto,	
      (select pd_abreviatura
          from cobis..cl_producto
          where pd_producto = x.do_codigo_producto
          and x.do_codigo_producto <> 21),
      (case @w_cliente_null
       when 'N' then case cl_tipo
                     when 'G' then 'INDIRECTO'
                     when 'R' then 'INDIRECTO'
                     when 'C' then 'DIRECTO'
                end
       else case cl_tipo
            when 'R' then 'INDIRECTO'
            when 'G' then 'DIRECTO'    
            end
       end),
      do_saldo_cap*ct_valor, do_saldo_otros*ct_valor, (isnull(do_saldo_int,0) + isnull(do_saldo_int_contingente,0))*ct_valor,
      0, do_estado_contable, 'N', 'A',
      cl_tipo, 'D'
   from	 cr_cliente_temporal, 
	 cr_dato_operacion x, 
	 cr_corresp_sib,
         cob_conta..cb_cotizacion --(index cb_cotizacion_Key)       --pga18abr2001
   where do_codigo_cliente	= cl_cliente
   and   cl_idconn		= @w_conexion
   and   do_tipo_reg		= 'D'
   and   do_estado_contable	in (1,2)       --pga18abr2001
   and   tabla			= 'T6'
   and   codigo			= do_tipo_operacion
   and   ct_moneda		= do_moneda
   and   ct_fecha		= (select max(ct_fecha)
				   from   cob_conta..cb_cotizacion
				   where  ct_moneda >= 0  
                                   and    ct_moneda = x.do_moneda
				   and	  ct_fecha <= @w_today)

   if @@error != 0
   begin
      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2103037  /* ERROR INSERTANDO DATOS EN TABLA TEMPORAL DE OPERACIONES */
      return 1             
   end
   
   /*  LLENAR LAS OPERACIONES DONDE LOS CLIENTES SON 'CODEUDORES' PARA PRODUCTOS COBIS */
   insert into cr_ope_temporal
      (op_idconn, op_operacion, op_banco, op_toperacion,
      op_producto,		
      op_abreviatura,			
      op_tipo_riesgo, 
      op_saldo_cap, op_saldo_otr, op_saldo_int,
      op_disponible, op_estado, op_tramite, op_estado_tr,
      op_tipo_cl, op_rol_cl)
   select 
      @w_conexion, do_numero_operacion, do_numero_operacion_banco, do_tipo_operacion,
      do_codigo_producto, 
      (select pd_abreviatura
          from cobis..cl_producto
          where pd_producto = x.do_codigo_producto
          and x.do_codigo_producto <> 21),
      (case @w_cliente_null
       when 'N' then case de_rol
                     when 'A' then 'DIRECTO'
		     when 'S' then 'DIRECTO'
                     when 'C' then 'INDIRECTO'
                     else case cl_tipo
                          when 'G' then 'INDIRECTO'
                          when 'R' then 'INDIRECTO'
                          when 'C' then 'DIRECTO'
                          end
                     end
       else case cl_tipo
            when 'R' then 'INDIRECTO'
            when 'G' then 'DIRECTO'    
            end
       end),
      do_saldo_cap*ct_valor, do_saldo_otros*ct_valor, (isnull(do_saldo_int,0) + isnull(do_saldo_int_contingente,0))*ct_valor,
      0, do_estado_contable, 'N', 'A',
      cl_tipo, de_rol
   from   cr_cliente_temporal, 
	  cr_tramite, 
	  cr_deudores, 
	  cr_dato_operacion x, 
	  cr_corresp_sib,
          cob_conta..cb_cotizacion, --(index cb_cotizacion_Key),
          cobis..cl_producto
   where  cl_idconn	= @w_conexion
   and    de_cliente	= cl_cliente
   and    de_rol	in ('C','S','A')  -- CODEUDOR
   and    tr_tramite    = de_tramite
   and    do_tipo_reg   = 'D'
   and    pd_producto	= do_codigo_producto
   and    tr_numero_op	= do_numero_operacion
   and    do_estado_contable in (1,2)       --pga 18abr2001
   and    tr_producto	= pd_abreviatura
   and    tabla		= 'T6'
   and    codigo	= do_tipo_operacion
   and    ct_moneda	= do_moneda
   and    ct_fecha = (select max(ct_fecha)
		      from   cob_conta..cb_cotizacion
 	    	      where  x.do_moneda = ct_moneda
                      and    ct_fecha	 <= @w_today)
  
   if @@error != 0
   begin
      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2103037  /* ERROR INSERTANDO DATOS EN TABLA TEMPORAL DE OPERACIONES */
      return 1             
   end

   /* LLENAR LAS OPERACIONES DONDE LOS CLIENTES SON 'CODEUDORES' PARA PRODCUTOS NO COBIS */
   insert into cr_ope_temporal
      (op_idconn, op_operacion, op_banco, op_toperacion,
      op_producto, 
      op_abreviatura, 
      op_tipo_riesgo, 
      op_saldo_cap, op_saldo_otr, op_saldo_int,		
      op_disponible, op_estado, op_tramite, op_estado_tr,		
      op_tipo_cl, op_rol_cl )
   select
      @w_conexion,	do_numero_operacion, do_numero_operacion_banco,	do_tipo_operacion,
      do_codigo_producto, 
      (select pd_abreviatura
          from cobis..cl_producto
          where pd_producto = x.do_codigo_producto
          and x.do_codigo_producto <> 21),
      (case @w_cliente_null
       when 'N' then case cl_tipo
                     when 'G' then 'INDIRECTO'
                     when 'R' then 'INDIRECTO'
                     when 'C' then 'DIRECTO'
                end
       else case cl_tipo
            when 'R' then 'INDIRECTO'
            when 'G' then 'DIRECTO'    
            end
       end),
      do_saldo_cap*ct_valor, do_saldo_otros*ct_valor, (isnull(do_saldo_int,0) + isnull(do_saldo_int_contingente,0))*ct_valor,
      0, do_estado_contable, 'N', 'A', 
      a.cl_tipo, 'C'
   from  cr_cliente_temporal a, 
	 cobis..cl_cliente_no_cobis b, 
	 cobis..cl_det_producto_no_cobis,
         cr_dato_operacion x, cr_corresp_sib,
         cob_conta..cb_cotizacion --(index cb_cotizacion_Key)
   where cl_idconn = @w_conexion
   and   b.cl_cliente        = a.cl_cliente
   and   b.cl_rol            = 'C'  -- CODEUDOR
   and   dp_det_producto     = b.cl_det_producto
   and   do_tipo_reg               = 'D'
   and   do_numero_operacion = dp_numero_operacion
   and   do_codigo_producto  = dp_codigo_producto
   and   do_estado_contable in (1,2)
   and   tabla               = 'T6'
   and   codigo              = do_tipo_operacion
   and   ct_moneda           = do_moneda
   and   ct_fecha = (select max(ct_fecha)
		     from cob_conta..cb_cotizacion --(index cb_cotizacion_Key)
		     where x.do_moneda = ct_moneda
                     and ct_fecha <= @w_today)

   if @@error != 0
   begin
      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2103037  /* ERROR INSERTANDO DATOS EN TABLA TEMPORAL DE OPERACIONES */
      return 1   
   end      
   /* LLENAR LA TABLA TEMPORAL CON LOS TRAMITES DE OPERACI0NES ESPECIFICAS */
   /* EN PROCESO, DE LOS CLIENTES QUE ESTAN EN LA TABLA TEMPORAL cr_cliente_temporal */
   insert into cr_ope_temporal
      (op_idconn, op_operacion, op_banco, op_toperacion,
      op_producto, op_abreviatura, 
      op_tipo_riesgo, 
      op_saldo_cap, op_saldo_int, op_saldo_otr,	
      op_disponible, op_estado, op_tramite, op_estado_tr, 
      op_tipo_cl, op_rol_cl)
   select
      @w_conexion,	tr_tramite, convert(varchar(24),tr_tramite),tr_toperacion, 
      21, 'TRA',                          
      (case @w_cliente_null
       when 'N' then case cl_tipo
                     when 'G' then 'INDIRECTO'
                     when 'R' then 'INDIRECTO'
                     when 'C' then 'DIRECTO'
                end
       else case cl_tipo
            when 'R' then 'INDIRECTO'
            when 'G' then 'DIRECTO'    
            end
       end),
      0, 0, 0,
      (tr_monto * ct_valor), 1, 'S', tr_estado,
      cl_tipo, 'D'
   from  cr_cliente_temporal, 
         cr_tramite x, 
	 cob_cartera..ca_operacion,
         cob_conta..cb_cotizacion --(index cb_cotizacion_Key)
   where cl_idconn	= @w_conexion
   and	 op_tramite	= tr_tramite
   and   tr_cliente	= cl_cliente
   and   tr_estado	not in ('Z','X','R','S') -- NO HAN SIDO RECHAZADAS DEFINITIVAMENTE
   and   tr_tipo	in ('O','R')   -- OPERACIONES ESPECIFICAS
   and	 op_estado	in (0,99)
   and	 op_naturaleza  = 'A'
   and   ct_moneda      = x.tr_moneda
   and   ct_fecha	= (select max(ct_fecha)
      			   from   cob_conta..cb_cotizacion
			   where  ct_moneda = x.tr_moneda
			   and    ct_fecha  <= @w_today)

   if @@error != 0
   begin

      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2103037  /* ERROR INSERTANDO DATOS EN TABLA TEMPORAL DE OPERACIONES */
      return 1  
   end

   /* LLENAR LA TABLA TEMPORAL CON LOS TRAMITES DE OPERACI0NES ESPECIFICAS */
   /* EN PROCESO, DE LOS CLIENTES QUE ESTAN EN LA TABLA TEMPORAL cr_cliente_temporal */
   /* Y SON CODEUDORES							     */
   insert into cr_ope_temporal
   (op_idconn, op_operacion, op_banco, op_toperacion,
    op_producto, op_abreviatura, 
    op_tipo_riesgo, 
    op_saldo_cap, op_saldo_int,	op_saldo_otr, op_disponible,
    op_estado, op_tramite, op_estado_tr, op_tipo_cl, op_rol_cl )
   select
   @w_conexion,	tr_tramite, convert(varchar(24),tr_tramite), tr_toperacion,
   21, 'TRA',
   (case @w_cliente_null
   when 'N' then case de_rol
                 when 'A' then 'DIRECTO'
                 when 'S' then 'DIRECTO'
                 when 'C' then 'INDIRECTO'
                 else case cl_tipo
                      when 'G' then 'INDIRECTO'
                      when 'R' then 'INDIRECTO'
                      when 'C' then 'DIRECTO'
                      end
                 end
   else case cl_tipo
        when 'R' then 'INDIRECTO'
        when 'G' then 'DIRECTO'    
        end
   end),
   0, 0, 0, (tr_monto * ct_valor),
   1, 'S', tr_estado, cl_tipo, de_rol
   from  cr_cliente_temporal, 
	 cr_deudores, 
	 cr_tramite x, 
	 cob_cartera..ca_operacion,
         cob_conta..cb_cotizacion --(index cb_cotizacion_Key)
   where de_cliente	= cl_cliente
   and   tr_tramite	= de_tramite
   and   tr_tramite	= op_tramite
   and   op_tramite	= de_tramite
   and   de_rol		in ('C','S','A')
   and   tr_tipo	in ('O','R')   -- OPERACIONES ESPECIFICAS
   and   tr_estado	not in ('Z','X','R','S') -- NO HAN SIDO RECHAZADAS DEFINITIVAMENTE
   and	 op_estado	in (0,99)
   and	 op_naturaleza  = 'A'
   and   cl_idconn	= @w_conexion 
   and   ct_moneda      = tr_moneda
   and   ct_fecha	= (select max(ct_fecha)
			   from   cob_conta..cb_cotizacion
			   where  ct_moneda = x.tr_moneda
			   and	  ct_fecha  <= @w_today)

   if @@error != 0
   begin

      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2103037  /* ERROR INSERTANDO DATOS EN TABLA TEMPORAL DE OPERACIONES */
      return 1  
   end

   /* ELIMINAR OPERACIONES QUE SE HAN DUMPLICADO CON LAS DEL CLIENTE */
   delete cr_ope_temporal
   where op_idconn = @w_conexion 
   and   op_tipo_cl in ('G','R','E')
   and (op_banco + '-' + convert(varchar(3),op_producto)) in 
       (select (op_banco + '-' + convert(varchar(3),op_producto))
        from cr_ope_temporal
        where op_idconn = @w_conexion
        and    op_tipo_cl = 'C' )

   if @@error != 0
   begin

      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2107016  /* ERROR ELIMINANDO DUPLICADOS EN LA TABLA TEMPORAL DE OPERACIONES */
      return 1             
   end

   /* ELIMINAR OPERACIONES DE RELACIONADOS QUE SE HAN DUPLICADO CON LAS DE GRUPO */

   delete cr_ope_temporal
   where op_idconn = @w_conexion 
   and   op_tipo_cl in ('R','E')
   and (op_banco + '-' + convert(varchar(3),op_producto)) in 
       (select(op_banco + '-' + convert(varchar(3),op_producto))
        from cr_ope_temporal
        where op_idconn = @w_conexion
        and    op_tipo_cl = 'G' )

   if @@error != 0
   begin

      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2107016  /* ERROR ELIMINANDO DUPLICADOS EN LA TABLA TEMPORAL DE OPERACIONES */
      return 1    
   end


   /* ELIMINAR LAS OPERACIONES CON EL GRUPO QUE SE HAN DUPLICADO CON LAS DE RELACIONADOS */
   /* CON EL CLIENTE */
   delete cr_ope_temporal
   where op_idconn = @w_conexion 
   and   op_tipo_cl = 'E'
   and (op_banco + '-' + convert(varchar(3),op_producto)) in 
       (select(op_banco + '-' + convert(varchar(3),op_producto))
        from cr_ope_temporal
        where op_idconn = @w_conexion
        and    op_tipo_cl = 'R' )

   if @@error != 0
   begin

      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2107016  /* ERROR ELIMINANDO DUPLICADOS EN LA TABLA TEMPORAL DE OPERACIONES */
      return 1    
   end


   /* ELIMINAR LAS OPERACIONES DEL GRUPO, QUE SE HAN DUPLICADO Y LO QUE CAMBIA ES */
   /* EL ROL DEL CLIENTE */
   delete cr_ope_temporal
   where op_idconn = @w_conexion 
   and   op_tipo_cl = 'G'
   and   op_rol_cl  = 'C'
   and (op_banco+'-'+convert(varchar(3),op_producto)) in 
       (select(op_banco+'-'+convert(varchar(3),op_producto))
        from cr_ope_temporal
        where op_idconn = @w_conexion
        and   op_tipo_cl = 'G'
        and   op_rol_cl  = 'D' )

   if @@error != 0
   begin

      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2107016  /* ERROR ELIMINANDO DUPLICADOS EN LA TABLA TEMPORAL DE OPERACIONES */
      return 1    
   end

   /* ELIMINAR LAS OPERACIONES DE RELACIONADOS, QUE SE HAN DUPLICADO Y LO QUE CAMBIA */
   /* ES EL ROL DEL CLIENTE */
   delete cr_ope_temporal
   where op_idconn = @w_conexion 
   and   op_tipo_cl = 'R'
   and   op_rol_cl  = 'C'
   and (op_banco+'-'+convert(varchar(3),op_producto)) in 
       (select(op_banco+'-'+convert(varchar(3),op_producto))
        from cr_ope_temporal
        where op_idconn = @w_conexion
        and   op_tipo_cl = 'R'
        and   op_rol_cl  = 'D' )

   if @@error != 0
   begin

      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2107016  /* ERROR ELIMINANDO DUPLICADOS EN LA TABLA TEMPORAL DE OPERACIONES */
      return 1    
   end

   /* ELIMINAR LAS OPERACIONES DE RELACIONADOS CON EL GRUPO, QUE SE HAN DUPLICADO Y */
   /* LO QUE CAMBIA ES EL ROL DEL CLIENTE */

   delete cr_ope_temporal
   where op_idconn  = @w_conexion 
   and   op_tipo_cl = 'E'
   and   op_rol_cl  = 'C'
   and (op_banco+'-'+convert(varchar(3),op_producto)) in 
       (select(op_banco+'-'+convert(varchar(3),op_producto))
        from cr_ope_temporal
        where op_idconn = @w_conexion
        and   op_tipo_cl = 'E' 
        and   op_rol_cl  = 'D')

   if @@error != 0
   begin

      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2107016  /* ERROR ELIMINANDO DUPLICADOS EN LA TABLA TEMPORAL DE OPERACIONES */
      return 1   
   end

   --pga 18jul2001 ini
   /* ELIMINAR LAS OPERACIONES DE RELACIONADOS CON EL GRUPO, QUE SE HAN DUPLICADO Y */
   /* LO QUE CAMBIA ES EL ROL DEL CLIENTE AVALISTA*/
   delete cr_ope_temporal
   where op_idconn  = @w_conexion
   and   op_tipo_cl = 'G'
   and   op_rol_cl  = 'A'
   and (op_banco+'-'+convert(varchar(3),op_producto)) in 
       (select(op_banco+'-'+convert(varchar(3),op_producto))
        from cr_ope_temporal
        where op_idconn  = @w_conexion
        and   op_tipo_cl = 'G'
        and   op_rol_cl  = 'D')

   if @@error != 0
   begin
      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2107016  /* ERROR ELIMINANDO DUPLICADOS EN LA TABLA TEMPORAL DE OPERACIONES */
      return 1   
   end
   /* ELIMINAR LAS OPERACIONES DE RELACIONADOS QUE SE HAN DUPLICADO Y */
   /* LO QUE CAMBIA ES EL ROL DEL CLIENTE AVALISTA*/
   delete cr_ope_temporal
   where op_idconn  = @w_conexion 
   and   op_tipo_cl = 'R'
   and   op_rol_cl  = 'A'
   and (op_banco+'-'+convert(varchar(3),op_producto)) in 
       (select(op_banco+'-'+convert(varchar(3),op_producto))
        from cr_ope_temporal
        where op_idconn  = @w_conexion
        and   op_tipo_cl = 'R' 
        and   op_rol_cl  = 'D')

   if @@error != 0
   begin

      exec cobis..sp_cerror
      @t_from   = @w_sp_name, 
      @i_num    = 2107016  /* ERROR ELIMINANDO DUPLICADOS EN LA TABLA TEMPORAL DE OPERACIONES */
      return 1   
   end
   --pga 18jul2001 fin

   /* LLENAR TABLA PREVIA DE RESULTADOS */
   if @i_indirecto = 'S'
   -- INCLUIR RIESGO INDIRECTO EN LA CALCULO
   begin
      --OPERACIONES ACTIVAS
      if @i_interes = 'S'
      -- INCLUIR CAPITAL, INTERES Y OTROS RIESGOS
      begin
         --INGRESAR LAS OPERACIONES EN ESTADO VIGENTE
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura, pr_banco,
         pr_por_vencer,  pr_vencido,     pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,     pr_rol_cl,
         pr_tipo_op )
         select 
         @w_conexion , op_toperacion,                             op_abreviatura,  op_banco,
         op_saldo_cap+ op_saldo_int + op_saldo_otr, 0,               0,
         op_tipo_riesgo,                            op_tipo_cl,      op_rol_cl,
         'A' 
         from cr_ope_temporal
         where op_idconn = @w_conexion
         and   op_tramite    = 'N'
         and   op_toperacion <> 'CEM' --pga18jul2001 en vez de CUPO 
         and   op_estado     = 1
         
         if @@error != 0
         begin

            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR, INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1             
         end
           
         /* INGRESAR LAS OPERACIONES VENCIDAS */
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura, pr_banco,
         pr_por_vencer,  pr_vencido,     pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,     pr_rol_cl,
         pr_tipo_op )
         select 
         @w_conexion , op_toperacion,         op_abreviatura,  				op_banco,
         0,			op_saldo_cap + op_saldo_int + op_saldo_otr,     0,
         op_tipo_riesgo,        op_tipo_cl,      				op_rol_cl,
         'A' 
         from cr_ope_temporal
         where op_idconn = @w_conexion 
         and   op_tramite    = 'N'    -- OPERACIONES ACTIVAS
         and   op_toperacion <> 'CEM' -- EXCLUIR CUPOS  --pga18jul2001 en vez de CUPO 
         and   op_estado     = 2      -- ESTADO VENCIDAS

         if @@error != 0
         begin

            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR, INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1             
         end         
      end
      else
      -- INCLUIR SOLO EL CAPITAL EN EL RIESGO
      begin
         -- INGRESAR OPERACIONES EN ESTADO VIGENTE
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura, pr_banco,
         pr_por_vencer,  pr_vencido,     pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,     pr_rol_cl,
         pr_tipo_op )
         select 
         @w_conexion , op_toperacion,    op_abreviatura,  op_banco,
         op_saldo_cap,     0,               0,
         op_tipo_riesgo,   op_tipo_cl,      op_rol_cl,
         'A' 
         from cr_ope_temporal
         where op_idconn = @w_conexion 
         and   op_tramite    = 'N'     -- OPERACIONES ACTIVAS
         and   op_toperacion <> 'CEM' -- EXCLUIR CUPOS--pga18jul2001 en vez de CUPO 
         and   op_estado     = 1       -- ESTADO VIGENTES
         
         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR, INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1    
         end
            
         -- INGRESAR OPERACIONES VENCIDAS
         insert into cr_previa_temporal (
         pr_idconn , pr_toperacion,  pr_abreviatura, pr_banco,
         pr_por_vencer,  pr_vencido,     pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,     pr_rol_cl,
         pr_tipo_op )
         select 
         @w_conexion , op_toperacion,    op_abreviatura,  op_banco,
         0,                op_saldo_cap,    0,
         op_tipo_riesgo,   op_tipo_cl,      op_rol_cl,
         'A' 
         from cr_ope_temporal
         where op_idconn = @w_conexion 
         and   op_tramite    = 'N'     -- OPERACIONES ACTIVAS
         and   op_toperacion <> 'CEM' -- EXCLUIR CUPOS --pga18jul2001 en vez de CUPO 
         and   op_estado     = 2       -- ESTADO VENCIDAS

         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR, INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1    
         end
      end
         
      -- DISPONIBLE
      -- (1) DISPONIBLE EN CEM
      insert into cr_previa_temporal (
      pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
      pr_por_vencer,  pr_vencido,      pr_disponible,
      pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
      pr_tipo_op )
      select
      op_idconn, op_toperacion,  op_abreviatura,  op_banco,
      0,              0,               op_disponible,
      op_tipo_riesgo, op_tipo_cl,      op_rol_cl,
      'C'
      from cr_ope_temporal
      where op_idconn = @w_conexion
      and   op_toperacion = 'CEM'  --pga18jul2001 en vez de CUPO 
      and   op_tramite = 'N'
      if @@error != 0
      begin
         exec cobis..sp_cerror
         @t_from   = @w_sp_name, 
         @i_num    = 2103038  /*  ERROR, INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
         return 1
      end
                   
      -- (2)TRAMITES APROBADOS
      insert into cr_previa_temporal (
      pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
      pr_por_vencer,  pr_vencido,      pr_disponible,
      pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
      pr_tipo_op )
      select
      @w_conexion , op_toperacion,  op_abreviatura,  op_banco,
      0,              0,               op_disponible,
      op_tipo_riesgo, op_tipo_cl,      op_rol_cl,
      'D'
      from cr_ope_temporal
      where op_idconn = @w_conexion 
      and   op_estado_tr  = 'A'
      and   op_tramite = 'S'

      if @@error != 0
      begin
         exec cobis..sp_cerror
         @t_from   = @w_sp_name, 
         @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
         return 1
      end     
               
      -- TRAMITES EN PROCESO
      if @i_aprobado = 'N'
      begin
         if @i_indirecto = 'S'
         --INCLUIR TODOS LOS TRAMITES EN PROCESO
         begin
            insert into cr_previa_temporal (
            pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
            pr_por_vencer,  pr_vencido,      pr_disponible,
            pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
            pr_tipo_op )
            select
            @w_conexion , op_toperacion,  op_abreviatura,  op_banco,
            0,              0,               op_disponible,
            op_tipo_riesgo, op_tipo_cl,      op_rol_cl,
            'T'
            from cr_ope_temporal
            where op_idconn = @w_conexion 
            and   op_estado_tr <> 'A'
            and   op_tramite = 'S'
            if @@error != 0
            begin

               exec cobis..sp_cerror
               @t_from   = @w_sp_name, 
               @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
               return 1
            end
         end
         else
         -- EXCLUIR LOS TRAMITES EN PROCESOS INDIRECTOS
         begin
            insert into cr_previa_temporal (
            pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
            pr_por_vencer,  pr_vencido,      pr_disponible,
            pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
            pr_tipo_op )
            select
            @w_conexion , op_toperacion,  op_abreviatura,  op_banco,
            0,              0,               op_disponible,
            op_tipo_riesgo, op_tipo_cl,      op_rol_cl,
            'T'
            from cr_ope_temporal
            where op_idconn = @w_conexion 
            and   op_estado_tr <> 'A'
            and   op_tipo_riesgo <> 'INDIRECTO'
            and   op_tramite = 'S'
            if @@error != 0
            begin

               exec cobis..sp_cerror
               @t_from   = @w_sp_name, 
               @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
               return 1
            end
         end
      end

      -- SI EL PARAMETRO @i_tramite  ES NO NULO, 
      -- INCLUIR EL TRAMITE SI ESTE NO EXISTE EN cr_previa_temporal
      if @i_tramite is not null and
         not exists (select 1
                     from cr_previa_temporal
                     where pr_idconn = @w_conexion
                     and   pr_banco = convert(varchar(24),@i_tramite))
      begin
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
         pr_por_vencer,  pr_vencido,      pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
         pr_tipo_op )
         select
         @w_conexion , op_toperacion,  op_abreviatura,  op_banco,
         0,              0,               op_disponible,
         op_tipo_riesgo, op_tipo_cl,      op_rol_cl,
         'D'
         from cr_ope_temporal
         where op_idconn = @w_conexion 
         and   op_banco = convert(varchar(24),@i_tramite)
         and   op_tramite = 'S'
         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1
         end
      end
   end
  else
   -- EXCLUIR RIESGO INDIRECTO EN EL CALCULO
   begin
      -- OPERACIONES ACTIVAS
      if @i_interes = 'S'
      -- INCLUIR CAPITAL, INTERES Y OTROS EN EL RIESGO
      begin
         -- INGRESAR LAS OPERACIONES EN ESTADO VIGENTES
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
         pr_por_vencer,  pr_vencido,      pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
         pr_tipo_op )
         select
         @w_conexion, op_toperacion,                              op_abreviatura,  op_banco,
         op_saldo_cap + op_saldo_int + op_saldo_otr, 0,               0,
         op_tipo_riesgo,                             op_tipo_cl,      op_rol_cl,
         'A'
         from cr_ope_temporal
         where op_idconn = @w_conexion
         and   op_tramite    = 'N'            -- OPERACIONES ACTIVAS
         and   op_toperacion <> 'CEM'        -- EXCLUIR LOS CUPOS --pga18jul2001 en vez de CUPO 
         and   op_tipo_riesgo <> 'INDIRECTO'  -- ECLUIR INDIRECTO
         and   op_estado     = 1              -- ESTADO VIGENTES
         if @@error != 0
         begin

            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1
         end
              
         -- INGRESAR LAS OPERACIONES VENCIDAS
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
         pr_por_vencer,  pr_vencido,      pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
         pr_tipo_op )
         select
         @w_conexion,op_toperacion,  op_abreviatura,                              op_banco,
         0,              op_saldo_cap + op_saldo_int + op_saldo_otr,  0,
         op_tipo_riesgo, op_tipo_cl,                                  op_rol_cl,
         'A'
         from cr_ope_temporal
         where op_idconn      = @w_conexion
         and   op_tramite     = 'N'            -- OPERACIONES ACTIVAS
         and   op_toperacion  <> 'CEM'        -- EXCLUIR LOS CUPOS --pga18jul2001 en vez de CUPO 
         and   op_tipo_riesgo <> 'INDIRECTO'  -- ECLUIR INDIRECTO
         and   op_estado      = 2              -- ESTADO VENCIDAS
         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1
         end
      end
      else
      -- INCLUIR SOLO CAPITAL EN EL RIESGO
      begin
         -- INGRESAR LAS OPERACIONES EN ESTADO VIGENTES
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
         pr_por_vencer,  pr_vencido,      pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
         pr_tipo_op )
         select
         @w_conexion, op_toperacion,    op_abreviatura,  op_banco,
         op_saldo_cap,     0,               0,
         op_tipo_riesgo,   op_tipo_cl,      op_rol_cl,
         'A'
         from cr_ope_temporal
         where op_idconn = @w_conexion
         and   op_tramite    = 'N'            -- OPERACIONES ACTIVAS
         and   op_toperacion <> 'CEM'        -- EXCLUIR LOS CUPOS --pga18jul2001 en vez de CUPO 
         and   op_tipo_riesgo <> 'INDIRECTO'  -- ECLUIR INDIRECTO
         and   op_estado     = 1              -- ESTADO VIGENTES
         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1
         end
            
         -- INGRESAR LAS OPERACIONES VENCIDAS
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
         pr_por_vencer,  pr_vencido,      pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
         pr_tipo_op )
         select
         @w_conexion, op_toperacion,  op_abreviatura,  op_banco,
         0,              op_saldo_cap,    0,
         op_tipo_riesgo, op_tipo_cl,      op_rol_cl,
         'A'
         from cr_ope_temporal
         where op_idconn = @w_conexion
         and   op_tramite    = 'N'            -- OPERACIONES ACTIVAS
         and   op_toperacion <> 'CEM'        -- EXCLUIR LOS CUPOS --pga18jul2001 en vez de CUPO 
         and   op_tipo_riesgo <> 'INDIRECTO'  -- ECLUIR INDIRECTO
         and   op_estado     = 2              -- ESTADO VENCIDAS
         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1
         end
      end
      -- DISPONIBLE
      -- (1) DISPONIBLE EN CEM
      insert into cr_previa_temporal (
      pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
      pr_por_vencer,  pr_vencido,      pr_disponible,
      pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
      pr_tipo_op )
      select
      @w_conexion, op_toperacion,   op_abreviatura,  op_banco,
      0,               0,               op_disponible,
      op_tipo_riesgo,  op_tipo_cl,      op_rol_cl,
      'C'
      from cr_ope_temporal
      where op_idconn = @w_conexion
      and   op_toperacion = 'CEM'        -- EXCLUIR LOS CUPOS --pga18jul2001 en vez de CUPO 
      and   op_tipo_riesgo <> 'INDIRECTO'  -- ECLUIR INDIRECTO
      and   op_tramite    = 'N'            -- OPERACIONES ACTIVAS
      if @@error != 0
      begin
         exec cobis..sp_cerror
         @t_from   = @w_sp_name, 
         @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
         return 1
      end     
                 
      -- (2) TRAMITES APROBADOS
      insert into cr_previa_temporal (
      pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
      pr_por_vencer,  pr_vencido,      pr_disponible,
      pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
      pr_tipo_op )
      select
      @w_conexion, op_toperacion,    op_abreviatura,  op_banco,
      0,                0,               op_disponible,
      op_tipo_riesgo,   op_tipo_cl,      op_rol_cl,
      'D'
      from cr_ope_temporal
      where op_idconn = @w_conexion
      and   op_estado_tr  = 'A'
      and   op_tipo_riesgo <> 'INDIRECTO'  -- ECLUIR INDIRECTO
      and   op_tramite    = 'S'            -- OPERACIONES ACTIVAS
      if @@error != 0
      begin
         exec cobis..sp_cerror
         @t_from   = @w_sp_name, 
         @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
         return 1
      end
         
      -- TRAMITES EN PROCESO
      if @i_aprobado = 'N'
      begin
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
         pr_por_vencer,  pr_vencido,      pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
         pr_tipo_op )
         select
         @w_conexion, op_toperacion,  op_abreviatura,  op_banco,
         0,              0,               op_disponible,
         op_tipo_riesgo, op_tipo_cl,      op_rol_cl,
         'T'
         from cr_ope_temporal
         where op_idconn = @w_conexion
         and   op_estado_tr  <> 'A'
         and   op_tipo_riesgo <> 'INDIRECTO'  -- ECLUIR INDIRECTO
         and   op_tramite    = 'S'            -- OPERACIONES ACTIVAS
         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1
         end
      end
              
      -- SI EL PARAMETRO @i_tramite ES NO NUL, INCLUIR EL TRAMITE SI NO EXISTE EN cr_previa_temporal
      if @i_tramite is not null and
         not exists (select 1
                     from cr_previa_temporal
                     where pr_idconn = @w_conexion
                     and   pr_banco = convert(varchar(24), @i_tramite))
      begin
         insert into cr_previa_temporal (
         pr_idconn, pr_toperacion,  pr_abreviatura,  pr_banco,
         pr_por_vencer,  pr_vencido,      pr_disponible,
         pr_tipo_riesgo, pr_tipo_cl,      pr_rol_cl,
         pr_tipo_op )
         select
         @w_conexion, op_toperacion,  op_abreviatura,  op_banco,
         0,              0,               op_disponible,
         op_tipo_riesgo, op_tipo_cl,      op_rol_cl,
         'D'
         from cr_ope_temporal
         where op_idconn     = @w_conexion
         and   op_banco      = convert(varchar(24), @i_tramite)
         and   op_tramite    = 'S'            -- OPERACIONES ACTIVAS
         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from   = @w_sp_name, 
            @i_num    = 2103038  /*  ERROR INSERTANDO DATOS EN TABLA PREVIA DE RESULTADOS */
            return 1
         end
      end
   end
              
   -- CALCULAR PARAMETROS DE OUTPUT
   select @o_opcion = sum(pr_por_vencer + pr_vencido + pr_disponible)
   from cr_previa_temporal
   where pr_idconn = @w_conexion
   and   pr_tipo_op <> 'C'

   --select * from cr_previa_temporal
            
   select @o_opcion = isnull(@o_opcion,0)
           
   -- LLENAR TABLA DE RESULTADOS
   -- ESTA TABLA SE LLENA PARA ENVIAR LOS RESULTADOS A FRONT END
   if @i_detalle = 'S'
   begin
      if @i_cliente is not null
      -- RIESGO DEL CLIENTE
      begin
         if exists (select 1 from cr_previa_temporal
                    where pr_idconn = @w_conexion
                    and  pr_tipo_op = 'C'
                    and  pr_rol_cl = 'G')
         begin
            insert into cr_resultado1_temporal(
            idconn, tipo_riesgo, por_vencer, vencido,
            disponible,  total )
            select
            @w_conexion, 'CEM GRUPO',      null,   null,
            pr_disponible,    pr_disponible
            from cr_previa_temporal
            where pr_idconn      = @w_conexion
            and   pr_tipo_op     = 'C'
            and   pr_rol_cl      = 'G'

            if @@error != 0
            begin
               exec cobis..sp_cerror
               @t_from   = @w_sp_name, 
               @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
               return 1
            end
         end

         if exists (select 1 from cr_previa_temporal
                    where  pr_idconn = @w_conexion
                    and  pr_tipo_op = 'C'
                    and  pr_rol_cl = 'D')
         begin
            insert into cr_resultado1_temporal(
            idconn, tipo_riesgo, por_vencer, vencido,
            disponible,  total )
            select
            @w_conexion, 'CEM CLIENTE',      null,   null,
            pr_disponible,      pr_disponible
            from cr_previa_temporal
            where pr_idconn      = @w_conexion
            and   pr_tipo_op     = 'C'
            and   pr_rol_cl     = 'D'

            if @@error != 0
            begin
               exec cobis..sp_cerror
               @t_from   = @w_sp_name, 
               @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
               return 1
            end
         end

         if @i_agrupado = 'S'
         -- AGRUPAR POR DIRECTO - INDIRECTO
         begin
            insert into cr_resultado1_temporal (
            idconn, tipo_riesgo, por_vencer, vencido,
            disponible,  total )
            select 
            @w_conexion, pr_tipo_riesgo,     sum(pr_por_vencer), sum(pr_vencido),
            sum(pr_disponible), (sum(pr_por_vencer)+ sum(pr_vencido)+ sum(pr_disponible))
            from cr_previa_temporal
            where pr_idconn = @w_conexion
            and   pr_tipo_op <> 'C'
            group by pr_tipo_riesgo

            if @@error != 0
            begin
               exec cobis..sp_cerror
               @t_from   = @w_sp_name, 
               @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
               return 1
            end
         end -- FIN DE MOSTRAR RIESGO AGRUPADO
         else  -- SIN AGRUPAR
         begin
            -- INSERTAR RIESGO DIRECTO
            if exists (select 1 from cr_previa_temporal
                       where pr_idconn = @w_conexion
                       and  pr_tipo_op <> 'C'
                       and  pr_tipo_riesgo = 'DIRECTO')
            begin
               insert into cr_resultado1_temporal(
               idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total )
               values (
               @w_conexion,'RIESGO DIRECTO',null, null,
               null, null )

               if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
                 
               -- INSERTAR DATOS COMO DEUDOR
               if exists (select 1 from cr_previa_temporal
                          where  pr_idconn      = @w_conexion
                          and    pr_tipo_op    <> 'C'
                          and    pr_rol_cl      = 'D'
                          and    pr_tipo_riesgo = 'DIRECTO')
               begin
                  -- INSERTAR SUBTITULO
                  insert into cr_resultado1_temporal(
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  values (
                  @w_conexion, 'A) COMO DEUDOR', null, null,
                  null,             null )
                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end                
                      
                  -- OPERACIONES ACTIVAS
                  insert into cr_resultado1_temporal(
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, pr_toperacion,      sum(pr_por_vencer), sum(pr_vencido),
                  sum(pr_disponible), (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'A'
                  and   pr_rol_cl      = 'D'
                  and   pr_tipo_riesgo = 'DIRECTO'
                  group by pr_toperacion

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                    
                  -- DISPONIBLE
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, 'Tramites Aprobados', null, null,
                  sum(pr_disponible), (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'D'
                  and   pr_rol_cl      = 'D'
                  and   pr_tipo_riesgo = 'DIRECTO'
   and   pr_banco       <> convert(varchar(24), @i_tramite)  -- EXCLUIR TRAMITE

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                  
                  -- TRAMITES EN PROCESO      
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, '(+) Tramites en Proceso', null, null,
                  null, (sum(pr_por_vencer)+ sum(pr_vencido)+sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'T'
                  and   pr_rol_cl      = 'D'
                  and   pr_tipo_riesgo = 'DIRECTO'
                  and   pr_banco       <> convert(varchar(24), @i_tramite)  -- EXCLUIR TRAMITE

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end

                  -- INSERTAR EL TRAMITE
                  if @i_tramite is not null
                  begin
                     --select * from cr_previa_temporal  --OJO

                     insert into cr_resultado1_temporal (
                     idconn, tipo_riesgo, por_vencer, vencido,
                     disponible,  total )
                     select
                     @w_conexion, '(+) ESTE TRAMITE', null, null,
                     null, pr_disponible
                     from cr_previa_temporal
                     where pr_idconn      = @w_conexion
                     and   pr_banco       = convert(varchar(24), @i_tramite)  --INCLUIR TRAMITES
                     and   pr_abreviatura = 'TRA'
                     and   pr_tipo_riesgo = 'DIRECTO'

                     if @@error != 0
                     begin
                        exec cobis..sp_cerror
                        @t_from   = @w_sp_name,
                        @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                        return 1
                     end
                  end
               end
                    
               -- INSERTAR DATOS COMO CODEUDOR
               if exists (select 1 from cr_previa_temporal
                          where  pr_idconn      = @w_conexion
                          and    pr_tipo_op    <> 'C'
                          and    pr_rol_cl      = 'C'
                          and    pr_tipo_riesgo = 'DIRECTO')
               begin
                  -- INSERTAR SUBTITULO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  values (
                  @w_conexion,'B) COMO CODEUDOR', null, null,
                  null, null )

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                    
                  -- OPERACIONES ACTIVAS
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, pr_toperacion,      sum(pr_por_vencer), sum(pr_vencido),
                  sum(pr_disponible), (sum(pr_por_vencer)+ sum(pr_vencido)+sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'A'
                  and   pr_rol_cl      = 'C'
                  and   pr_tipo_riesgo = 'DIRECTO'
                  group by pr_toperacion

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                      
                  -- DISPONIBLE
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, 'Tramites Aprobados', null, null,
                  sum(pr_disponible), (sum(pr_por_vencer) + sum(pr_vencido) + sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'D'
                  and   pr_rol_cl      = 'C'
                  and   pr_banco       <> convert(varchar(24), @i_tramite)  -- EXCLUIR TRAMITE
		  and   pr_tipo_riesgo = 'DIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                    
                  -- TRAMITE EN PROCESO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion,'(+) Tramites en Proceso', null, null,
                  null, (sum(pr_por_vencer) + sum(pr_vencido) + sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'T'
                  and   pr_rol_cl      = 'C'
                  and   pr_banco       <> convert(varchar(24), @i_tramite)  -- EXCLUIR TRAMITE
		  and   pr_tipo_riesgo = 'DIRECTO'

                  if @@error != 0
                  begin

                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
               end  -- FIN COMO CODEUDOR               

                -- INSERTAR SUBTOTAL
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total)
                  select
                  @w_conexion, 'SUBTOTAL RIESGO DIRECTO', null, null,
                  null, (sum(pr_por_vencer) + sum(pr_vencido) + sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn = @w_conexion
                  and pr_tipo_op <> 'C'
		  and pr_tipo_riesgo = 'DIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
            end -- FIN DE RIESGO DIRECTO
                
            -- INSERTAR RIESGO INDIRECTO
            if exists (select 1 from cr_previa_temporal
                       where  pr_idconn = @w_conexion
		       and    pr_tipo_op <> 'C'
		       and    pr_tipo_riesgo = 'INDIRECTO')
            begin
               -- INSERTAR SUBTITULO
               insert into cr_resultado1_temporal (
          idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total )
               values(@w_conexion,
               'RIESGO INDIRECTO', null, null,
               null, null )

               if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
                  
               -- INSERTAR DATOS DEL GRUPO
               if exists (select 1 from cr_previa_temporal
                          where pr_idconn  = @w_conexion
                          and   pr_tipo_op <> 'C'
                          and   pr_tipo_cl in ('G', 'E')
			  and   pr_tipo_riesgo = 'INDIRECTO')
               begin
                  -- INSERTAR SUBTITULO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  values (@w_conexion,
                  'A) GRUPO', null, null,
                  null, null )

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                   
                  -- ENDEUDAMIENTO ACTUAL
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, 'Endeudamiento Actual', sum(pr_por_vencer), sum(pr_vencido),
                  sum(pr_disponible),     (sum(pr_por_vencer) + sum(pr_vencido) + sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     in ('A','D')
                  and   pr_tipo_cl     in ('G','E')
		  and   pr_tipo_riesgo = 'INDIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                      
                  -- TRAMITES EN PROCESO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, '(+) Tramites en Proceso', null, null,
                  null, (sum(pr_por_vencer) + sum(pr_vencido) + sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'T'
                  and   pr_tipo_cl     in ('G','E')
		  and   pr_tipo_riesgo = 'INDIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
               end

               -- INSERTAR DATOS DE LOS RELACIONADOS
               if exists (select 1 from cr_previa_temporal
                          where pr_idconn      = @w_conexion
                          and   pr_tipo_op    <>  'C'
			  and   pr_tipo_cl     = 'R' 
			  and   pr_tipo_riesgo = 'INDIRECTO')
               begin
                  -- INSERTAR SUBTITULO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  values (
                  @w_conexion, 'B) RELACIONADOS', null, null,
                  null, null )

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                      
                  -- ENDEUDAMIENTO ACTUAL
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, 'Endeudamiento Actual', sum(pr_por_vencer), sum(pr_vencido),
                  sum(pr_disponible), (sum(pr_por_vencer) + sum(pr_vencido) + sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn       = @w_conexion
                  and   pr_tipo_op     in ('A','D')
                  and   pr_tipo_cl     = 'R'
	          and   pr_tipo_riesgo = 'INDIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                        
                  -- TRAMITES EN PROCESO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, '(+) Tramites en Proceso', null, null,
                  null, (sum(pr_por_vencer) + sum(pr_vencido) + sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'T'
                  and   pr_tipo_cl     = 'R'
		  and   pr_tipo_riesgo = 'INDIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
               end  -- FIN DE RIESGO DE RELACIONADOS
                      

               -- pga25jul2001 inicio
               -- INSERTAR DATOS COMO AVALISTA
               if exists (select 1 from cr_previa_temporal
                          where  pr_idconn      = @w_conexion
                          and    pr_tipo_op    <> 'C'
                          and    pr_rol_cl      = 'A'
			  and    pr_tipo_riesgo = 'INDIRECTO')
               begin
                  -- INSERTAR SUBTITULO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  values (
                  @w_conexion, 'C) COMO AVALISTA', null, null,
                  null, null )

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                    
                  -- OPERACIONES ACTIVAS
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, pr_toperacion,      sum(pr_por_vencer), sum(pr_vencido),
                  sum(pr_disponible), (sum(pr_por_vencer)+ sum(pr_vencido)+sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'A'
                  and   pr_rol_cl     = 'A'
		  and   pr_tipo_riesgo = 'INDIRECTO'
                  group by pr_toperacion

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                      
                  -- DISPONIBLE
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, 'Tramites Aprobados', null, null,
                  sum(pr_disponible), (sum(pr_por_vencer) + sum(pr_vencido) + sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'D'
                  and   pr_rol_cl      = 'A'
                  and   pr_banco       <> convert(varchar(24), @i_tramite)  -- EXCLUIR TRAMITE
		  and   pr_tipo_riesgo = 'INDIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                    
                  -- TRAMITE EN PROCESO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion,'(+) Tramites en Proceso', null, null,
                  null, (sum(pr_por_vencer) + sum(pr_vencido) + sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'T'
                  and   pr_rol_cl      = 'A'
	          and   pr_tipo_riesgo = 'INDIRECTO'
                  and   pr_banco       <> convert(varchar(24), @i_tramite)  -- EXCLUIR TRAMITE

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
               end -- FIN COMO AVALISTA
               -- pga25jul2001 fin

               -- INSERTAR SUBTOTAL
               insert into cr_resultado1_temporal (
               idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total )
               select
               @w_conexion, 'SUBTOTAL DE RIESGO', null, null,
               null, (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
               from cr_previa_temporal
               where pr_idconn  = @w_conexion
               and pr_tipo_op <> 'C'
	       and pr_tipo_riesgo = 'INDIRECTO'

               if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
            end  -- FIN DE RIESGO INDIRECTO
         end     -- FIN DE MOSTRAR RIESGO MAS DETALLADO
      end        -- FIN DE RIESGO DEL CLIENTE
      else
      -- RIESGO DEL GRUPO
      begin
         if exists (select 1 from cr_previa_temporal
                    where pr_idconn = @w_conexion
                    and  pr_tipo_op = 'C'
		    and  pr_rol_cl = 'G')
         begin
            insert into cr_resultado1_temporal(
            idconn, tipo_riesgo, por_vencer, vencido,
            disponible,  total )
            select
            @w_conexion, 'CEM GRUPO',      null,   null,
            pr_disponible,      pr_disponible
            from cr_previa_temporal
            where pr_idconn      = @w_conexion
            and   pr_tipo_op     = 'C'
	    and   pr_rol_cl     = 'G'

            if @@error != 0
            begin
               exec cobis..sp_cerror
               @t_from   = @w_sp_name, 
               @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
               return 1
            end
         end

         if @i_agrupado = 'S'
         -- AGRUPAR POR DIRECTO - INDIRECTO
         begin
            insert into cr_resultado1_temporal (
            idconn, tipo_riesgo, por_vencer, vencido,
            disponible,  total )
            select
            @w_conexion, pr_tipo_riesgo,     sum(pr_por_vencer), sum(pr_vencido),
            sum(pr_disponible), (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
            from cr_previa_temporal
            where pr_idconn = @w_conexion
	    and   pr_tipo_op <> 'C'
            group by pr_tipo_riesgo

            if @@error != 0
            begin
               exec cobis..sp_cerror
               @t_from   = @w_sp_name, 
               @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
               return 1
            end
         end -- FIN DE MOSTRAR RIESGO AGRUPADO
         else
         begin
            -- INSERTAR RIESGO DIRECTO
            if exists (select 1 from cr_previa_temporal
                       where pr_idconn = @w_conexion
 		       and pr_tipo_op <> 'C'
		       and pr_tipo_riesgo = 'DIRECTO')
            begin
               insert into cr_resultado1_temporal (
               idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total )
               values (
               @w_conexion, 'RIESGO DIRECTO', null, null,
               null, null )

               if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
                     
               -- OPERACIONES ACTIVAS
               insert into cr_resultado1_temporal (
               idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total )
               select
               @w_conexion, pr_toperacion,      sum(pr_por_vencer), sum(pr_vencido),
               sum(pr_disponible), (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
               from cr_previa_temporal
               where pr_idconn      = @w_conexion
               and   pr_tipo_op     = 'A'
               and   pr_tipo_cl     = 'G'
	       and   pr_tipo_riesgo = 'DIRECTO'
               group by pr_toperacion

               if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
                
               -- DISPONIBLE
               insert into cr_resultado1_temporal (
               idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total )
               select
               @w_conexion, 'Tramites Aprobados', null, null,
               sum(pr_disponible), (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
               from cr_previa_temporal
               where pr_idconn      = @w_conexion
               and   pr_tipo_op     = 'D'
               and   pr_tipo_cl     = 'G'
               and   pr_banco       <> convert(varchar(24), @i_tramite)  -- EXCLUIR TRAMITE
	       and   pr_tipo_riesgo = 'DIRECTO'

               if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
                  
               -- TRAMITES EN PROCESO
               insert into cr_resultado1_temporal (
               idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total )
               select
               @w_conexion, '(+) Tramites en Proceso', null, null,
               null, (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
               from cr_previa_temporal
               where pr_idconn      = @w_conexion
               and   pr_tipo_op     = 'T'
               and   pr_tipo_cl     = 'G'
	       and   pr_tipo_riesgo = 'DIRECTO'
               and   pr_banco       <> convert(varchar(24), @i_tramite)  -- EXCLUIR TRAMITE

               if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
                   
               -- INSERTAR TRAMITE
               if @i_tramite is not null
               begin
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, '(+) ESTE TRAMITE', null, null,
                  null, pr_disponible
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_banco       = convert(varchar(24), @i_tramite)  -- EXCLUIR TRAMITE
                  and   pr_abreviatura = 'TRA'
		  and   pr_tipo_riesgo = 'DIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end                     
               end
                  
               -- INSERTAR SUBTOTAL
               insert into cr_resultado1_temporal (
               idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total)
               select
               @w_conexion, 'SUBTOTAL RIESGO DIRECTO', null, null,
               null, (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
               from cr_previa_temporal
               where pr_idconn = @w_conexion
               and pr_tipo_op <> 'C'
	       and pr_tipo_riesgo = 'DIRECTO'

               if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
            end -- FIN DE RIESGO DIRECTO
                
            -- INSERTAR RIESGO INDIRECTO
            if exists (select 1 from cr_previa_temporal
                       where pr_idconn  = @w_conexion
		       and pr_tipo_op <> 'C'
		       and pr_tipo_riesgo = 'INDIRECTO')
            begin
               -- INSERTAR SUBTITULO
               insert into cr_resultado1_temporal (
               idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total )
               values (
               @w_conexion, 'RIESGO INDIRECTO', null, null,
               null, null )

	       if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
                     
               -- INSERTAR DATOS DE RELACIONADOS
               if exists (select 1 from cr_previa_temporal
                          where pr_idconn      = @w_conexion
                          and   pr_tipo_op   <>  'C'
			  and   pr_tipo_cl     = 'E'
			  and   pr_tipo_riesgo = 'INDIRECTO')
               begin
                  -- INSERTAR SUBTITULO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  values (
                  @w_conexion, 'A) RELACIONADOS', null, null,
                  null, null )

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                           
                  -- ENDEUDAMIENTO ACTUAL
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, 'Endeudamiento Actual', sum(pr_por_vencer), sum(pr_vencido),
                  sum(pr_disponible), (sum(pr_por_vencer)+ sum(pr_vencido)+sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     in ('A','D')
                  and   pr_tipo_cl     = 'E'
		  and   pr_tipo_riesgo = 'INDIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
                       
                  -- TRAMITES EN PROCESO
                  insert into cr_resultado1_temporal (
                  idconn, tipo_riesgo, por_vencer, vencido,
                  disponible,  total )
                  select
                  @w_conexion, '(+) Tramites en Proceso', null, null,
                  null, (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
                  from cr_previa_temporal
                  where pr_idconn      = @w_conexion
                  and   pr_tipo_op     = 'T'
                  and   pr_tipo_cl     = 'E'
		  and   pr_tipo_riesgo = 'INDIRECTO'

                  if @@error != 0
                  begin
                     exec cobis..sp_cerror
                     @t_from   = @w_sp_name, 
                     @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                     return 1
                  end
               end -- FIN DE RIESGO DE RELACIONADOS
                       
               -- INSERTAR SUBTOTAL
               insert into cr_resultado1_temporal (
               idconn, tipo_riesgo, por_vencer, vencido,
               disponible,  total )
               select
               @w_conexion, 'SUBTOTAL RIESGO INDIRECTO', null, null,
               null, (sum(pr_por_vencer)+sum(pr_vencido)+sum(pr_disponible))
               from cr_previa_temporal
               where pr_idconn   = @w_conexion
  	       and pr_tipo_op <> 'C'
	       and pr_tipo_riesgo = 'INDIRECTO'

               if @@error != 0
               begin
                  exec cobis..sp_cerror
                  @t_from   = @w_sp_name, 
                  @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
                  return 1
               end
            end -- FIN DE RIESGO INDIRECTO
         end    -- FIN DE MOSTRAR RIESGO MAS DETALLADO
      end       -- FIN DE RIESGO DE GRUPO
              
      -- INSERCION TOTAL
      insert into cr_resultado1_temporal (
      idconn , tipo_riesgo, por_vencer, vencido,
      disponible,  total )
      values (
      @w_conexion, 'RIESGO TOTAL', null, null,
      null, @o_opcion )
      if @@error != 0
      begin
         exec cobis..sp_cerror
         @t_from   = @w_sp_name, 
         @i_num    = 2103039  /*  ERROR, INSERTANDO DATOS EN TABLA DE RESULTADOS */
         return 1
      end
            
      -- RETORNAR AL FRONT END
      select 
      'DESCRIPCION' = tipo_riesgo,
      'VIGENTE'     = por_vencer,
      'VENCIDO'     = vencido,
      'DISPONIBLE'  = disponible,
      'TOTAL'       = total
      from  cr_resultado1_temporal
      where idconn = @w_conexion

      select @o_opcion

      if @i_componente = 'S'

      select
	 'PRODUCTO'   = op_producto,
         'OPERACION'  = op_banco,
         'L.CREDITO'  = op_toperacion,
         'T.RIESGO'   = op_tipo_riesgo, 
	 'VALOR'      = op_disponible,
         'SALDO CAP.' = op_saldo_cap,               
         'SALDO INT.' = op_saldo_int,              
         'SALDO OTR.' = op_saldo_otr, 
         'TIPO'       = op_tipo_cl, 
         'ROL'        = op_rol_cl 
      from cob_credito..cr_ope_temporal
      where op_idconn =  @w_conexion

   end   -- FIN DE if @i_detalle

return 0

GO
