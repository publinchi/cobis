/************************************************************************/
/*   Archivo:             ordesem_gru.sp                                */
/*   Stored procedure:    sp_orden_desembolso_gru                       */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Adriana Chiluisa                              */
/*   Fecha de escritura:  25/May./2017                                  */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta para imprimir el reporte de orden de desembolso           */
/*                         MODIFICACIONES                               */
/*      FECHA           AUTOR      RAZON                                */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_orden_desembolso_gru')
   drop proc sp_orden_desembolso_gru
go

create proc sp_orden_desembolso_gru (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               smallint    = null,
   @i_operacion         char(1)     = null,
   @i_banco             cuenta      = null,
   @i_formato_fecha     int         = null,
   @i_opcion            varchar(10) = null,
   @i_modo              int         = null
)
as
declare
   @w_sp_name                      varchar(32),
   @w_ruc                          varchar(64),
   @w_sucursal                     varchar(64),
   @w_fecha                        varchar(10),
   @w_num_recibo                   varchar(10),
   @w_num_operacion                varchar(10), 
   @w_deudor_principal             varchar(64),   
   @w_nombre_grupo                 varchar(30),    
   @w_identificacion               varchar(64),   
   @w_fecha_liq                    varchar(10),
   @w_fecha_desemb                 varchar(10),
   @w_telefono                     varchar(10),
   @w_fecha_ven                    varchar(10),
   @w_direccion                    varchar(64),                 
   @w_ciudad                       varchar(10),
   @w_telefono_Pie                 varchar(10),
   @w_autorizado_por               varchar(10),
   @w_recibe_conforme              varchar(10),
   @w_moneda                       int,
   @w_grupo                        int,
   @w_ente_p                       int    

   
select @w_sp_name       = 'sp_orden_desembolso_gru',
       @i_formato_fecha = 103
print '---INicioAAA:'+@i_opcion+'---OPer:'+@i_operacion+'---Modo:'+convert(varchar,@i_modo)
select @w_moneda = op_moneda
from   ca_operacion
where  op_banco = @i_banco

-- CABECERA DE LA IMPRESION
if @i_operacion = 'C'
begin
    select @w_fecha            = convert(varchar(10), @s_date, @i_formato_fecha)
    
    select @w_grupo    = tg_grupo 
    from   cob_credito..cr_tramite_grupal
    where  tg_prestamo = @i_banco
	
	select @w_sucursal     = of_nombre
	from cob_cartera..ca_operacion, cobis..cl_oficina, cobis..cl_filial
	where  fi_filial  = 1
    and    fi_filial  = of_filial
    and    of_oficina = op_oficina
    and    op_banco  = @i_banco	

    select @w_fecha_ven = convert(varchar(10),di_fecha_ven,@i_formato_fecha),
           @w_fecha_liq = convert(varchar(10),op_fecha_liq,@i_formato_fecha),
		   @w_fecha_desemb = (select convert(varchar(10),dm_fecha,@i_formato_fecha) from cob_cartera..ca_desembolso where dm_operacion = op_operacion)
    from   ca_operacion OP
    inner join cobis..cl_catalogo A on op_banco     = @i_banco and op_toperacion = A.codigo
    inner join cobis..cl_moneda     on op_moneda    = mo_moneda
    left outer join ca_dividendo DI on op_operacion = di_operacion and di_estado = 1
		   
    select @w_ruc              = gr_ruc,
           @w_nombre_grupo     = substring(gr_nombre,1,30)
    from   cobis..cl_grupo 
	where  gr_grupo = @w_grupo 		   
	
    select @w_deudor_principal = (select UPPER(isnull(en_nombre,''))+' ' + UPPER(isnull(p_s_nombre,''))+' '+
	                                         UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,''))),
	       @w_identificacion   = en_ced_ruc,
		   @w_ente_p           = en_ente
    from   cob_credito..cr_tramite_grupal, cobis..cl_ente
    where  tg_prestamo = @i_banco
    AND    tg_cliente  = en_ente
	
    select TOP 1 @w_telefono   = te_valor                --??
	from  cobis..cl_direccion, cobis..cl_telefono 
    where di_ente      = te_ente
    and   di_direccion = te_direccion
    --and   di_principal = 'S'
    and   di_ente      =  @w_ente_p

    select 'NUM_RUC'           = @w_ruc, --**
           'SUCURSAL'          = @w_sucursal, --**
           'FECHA'             = @w_fecha, --**
           'NUM_RECIBO'        = @w_num_recibo,
           'NUM_OPERACION'     = @i_banco,--@w_num_operacion,
           'DEUDOR'            = @w_deudor_principal,
           'GRUPO'             = @w_nombre_grupo,
           'IDENTIFICACION'    = @w_identificacion,
           'FECHA_LIQUIDACI'   = @w_fecha_liq,
           'FECHA_DESEMBOLSO'  = @w_fecha_desemb,
           'TELEFONO'          = @w_telefono,
           'FECHA_OTHER'       = @w_fecha_ven
end -- C

-- DETALLE
if @i_operacion = 'D'
begin
  if @i_opcion = '1'
  begin
      declare @w_operacion int
	  select  @w_operacion = op_operacion from cob_cartera..ca_operacion where op_banco = @i_banco
	    
      select DISTINCT 'OFICINA_DESEMB_ID'   = dm_oficina,
               'OFICINA_DESEMB_DESC' = (select of_nombre from cobis..cl_oficina where of_oficina = DS.dm_oficina),
               'FORMA DE DESEMBOLSO' = (select cp_descripcion from ca_producto where cp_producto = DS.dm_producto), --dm_producto,       
               'REFERENCIA'          = dm_cuenta,
               'MONEDA'              = dm_moneda,
               'MONEDA_DESC'         = (select mo_descripcion from cobis..cl_moneda where mo_moneda = DS.dm_moneda),      
               'COTIZACION'          = dm_cotizacion_mds,
               'MONTO'               = dm_monto_mds,
			   'NUMERO_BANCO'        = ''
        from   ca_desembolso DS
        where  dm_operacion = @w_operacion
  end
  if @i_opcion = '2'
  begin 
      declare @w_toperacion varchar(10)
      SELECT @w_toperacion = op_toperacion FROM cob_cartera..ca_operacion WHERE op_banco = @i_banco
	  if(@w_toperacion = 'GRUPAL')
	  begin
	      select   'OFICINA_DESEMB_ID'   = '',
                   'OFICINA_DESEMB_DESC' = '',
                   'FORMA DE DESEMBOLSO' = '',
                   'REFERENCIA'          = '',
                   'MONEDA'              = 0,
                   'MONEDA_DESC'         = '',      
                   'COTIZACION'          = 0,
                   'MONTO'               = tg_monto,
		    	   'NUMERO_BANCO'        = OP.op_banco,				                            
                   'NOMBRE_CLIENTE'	     = (select UPPER(isnull(en_nombre,''))+' '+UPPER(isnull(p_s_nombre,''))+' '+UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,'')) from cobis..cl_ente where en_ente = GR.tg_cliente),
				   'ID_CLIENTE'          = tg_cliente,
				   'FECHA_PROCESO'       = (select convert(varchar(10), fp_fecha, @i_formato_fecha) from cobis..ba_fecha_proceso),
				   'DIRECCION'           = isnull((select TOP 1 convert(varchar(40), isnull(di_calle,'')) +', '+ 
                                                   convert(varchar(40), isnull(di_nro,''))+', '+
                                                   (select valor from cobis..cl_catalogo where codigo = di_parroquia
	                                                and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_parroquia'))+', '+
													(SELECT pv_descripcion FROM cobis..cl_provincia WHERE pv_provincia = di_provincia)+', '+
													isnull(di_codpostal,'')
                                                    from cobis..cl_direccion where di_ente = tg_cliente and di_tipo = 'RE'),''),
					'FECHA_LIQUID' = (select convert(varchar(10), op_fecha_liq, @i_formato_fecha)),
					'ROL'          = CG.cg_rol,
				    'DESCRIP_ROL'  = ltrim((SELECT valor FROM cobis..cl_catalogo CL 
					                  WHERE tabla = (SELECT codigo FROM cobis..cl_tabla WHERE tabla = 'cl_rol_grupo')
									   AND CL.codigo = CG.cg_rol))
          from   cob_credito..cr_tramite_grupal GR, cobis..cl_cliente_grupo CG, cob_cartera..ca_operacion OP
          where  tg_referencia_grupal = @i_banco
		  AND    GR.tg_operacion = OP.op_operacion
		  AND 	 GR.tg_cliente   = CG.cg_ente
		  AND    GR.tg_grupo     = CG.cg_grupo
	      and    tg_monto > 0
	  end
	  else
	  begin
	  	  select   'OFICINA_DESEMB_ID'   = '',
                   'OFICINA_DESEMB_DESC' = '',
                   'FORMA DE DESEMBOLSO' = '',
                   'REFERENCIA'          = '',
                   'MONEDA'              = 0,
                   'MONEDA_DESC'         = '',
                   'COTIZACION'          = 0,
                   'MONTO'               = op_monto,
		    	   'NUMERO_BANCO'        = op_banco,
				   'NOMBRE_CLIENTE'	     = (select UPPER(isnull(en_nombre,''))+' '+UPPER(isnull(p_s_nombre,''))+' '+UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,'')) from cobis..cl_ente where en_ente = op_cliente),
				   'ID_CLIENTE'          = op_cliente,
				   'FECHA_PROCESO'       = (select convert(varchar(10), fp_fecha, @i_formato_fecha) from cobis..ba_fecha_proceso),
				   'DIRECCION'           = isnull((select TOP 1 convert(varchar(40), isnull(di_calle,'')) +', '+ 
                                                   convert(varchar(40), isnull(di_nro,''))+', '+
                                                   (select valor from cobis..cl_catalogo where codigo = di_parroquia
	                                                and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_parroquia'))+', '+
												    (SELECT pv_descripcion FROM cobis..cl_provincia WHERE pv_provincia = di_provincia)+', '+
													isnull(di_codpostal,'')
                                                    from cobis..cl_direccion where di_ente = op_cliente and di_tipo = 'RE'),''),
				   'FECHA_LIQUID' = (select convert(varchar(10), op_fecha_liq, @i_formato_fecha)),
				   'ROL' = '',
				   'DESCRIP_ROL' = ''
		 from  cob_cartera..ca_operacion OP 
		 where op_banco = @i_banco
	  end	 
  end  
end -- D

return 0

go
