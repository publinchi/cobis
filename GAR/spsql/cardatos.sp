/*************************************************************************/
/*   Archivo:              cardatos.sp                                   */
/*   Stored procedure:     sp_cardatos                                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_cardatos') IS NOT NULL
   drop  PROC dbo.sp_cardatos
go

create proc dbo.sp_cardatos		
(
   @s_ssn          int          = null, --SERS 21/12/2007 Campos para la tran. servicio
   @i_secuencial   int	        = 0,	--SERS 21/12/2007 
   @t_trn          smallint     = null, --SERS 21/12/2007
   @s_date         datetime     = null, --SERS 21/12/2007
   @s_user         login        = null, --SERS 21/12/2007
   @s_term         varchar(30)  = null, --SERS 21/12/2007
   @s_ofi          smallint     = null, --SERS 21/12/2007
   @s_srv          varchar(30)  = null, --SERS 21/12/2007
   @s_lsrv         varchar(30)  = null, --SERS 21/12/2007
   @i_operacion    char(1)      = null, 
   @t_debug        char(1)      = 'N', 
   @t_file         varchar(14)  = null, 
   @i_banco	       char(50)     = null, 	--SERS 21/12/2007
   @i_opert	       char(50)     = null, 	--SERS 21/12/2007
   @i_tramite	     char(50)     = null, 	--SERS 21/12/2007
   @i_cliente	     char(50)     = null,	--SERS 21/12/2007
   @i_documen	     varchar(64)  = null, 	--SERS 21/12/2007
   @i_modo	       char(1)      = null,	--SERS 21/12/2007
   @i_garan        char(50)     = null
   
)
as
declare
   @w_today        datetime,     /* fecha del dia */ 
   @w_return       int,          /* valor que retorna */
   @w_sp_name      varchar(32),   /* nombre stored proc*/
   @gar1		       int,
   @gar2		       int,
   @garT		       int,
   @w_sucursal     smallint,  /* PAC 01/Ago/2008 */
   @w_oficina      smallint   /* PAC 01/Ago/2008 */


select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_cardatos'

if @i_operacion='C'	
begin
	if @i_modo='1'
	begin
                /*******************************************************************/
                /*PAC 01/Ago/2008 para buscar la sucursal de custodia dependiendo  */
                /*de la garantía que se envia por parámetro. El front En recive    */
                /*estos datos y verifica si se encuentra en guayaquil y desea      */
                /*imprimir nformato de quito, presente un mensaje de advertencia,  */
                /*caso contrario imprime normalmente el documento, y de la misma   */
                /*forma cuando es de quito*/
                /*******************************************************************/
                select @w_sucursal = null, @w_oficina = null
                select
                   @w_sucursal = cu_sucursal,
                   @w_oficina = cu_oficina
                from
                   cob_custodia..cu_custodia
                where
                   cu_codigo_externo = @i_garan
                /*******************************************************************/
		select cu_tipo,op_banco,op_operacion,op_tramite,op_cliente,op_nombre,
		      cu_codigo_externo,op_fecha_ult_proceso,op_estado
		into #tempo
		from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia,
		cob_cartera..ca_operacion,cob_custodia..cu_tipo_custodia
		where gp_garantia = cu_codigo_externo
		and gp_tramite = op_tramite
		and cu_tipo <> 'GARGPE'
		and cu_tipo in (select distinct(Y.codigo) from cobis..cl_tabla X, cobis..cl_catalogo Y
				where X.tabla in ('cu_tgar_vehpesados', 'cu_tgar_vehlivianos')
				and X.codigo = Y.tabla)
		and cu_tipo = tc_tipo		
		and gp_garantia=@i_garan
		union
		select cu_tipo,op_banco,op_operacion,op_tramite,op_cliente,op_nombre,	--SS 07/Nov/2007
		      cu_codigo_externo,op_fecha_ult_proceso,op_estado
		from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia,
		cob_cartera_his..ca_operacion,cob_custodia..cu_tipo_custodia
		where gp_garantia = cu_codigo_externo
		and gp_tramite = op_tramite
		and cu_tipo <> 'GARGPE'
		and cu_tipo in (select distinct(Y.codigo) from cobis..cl_tabla X, cobis..cl_catalogo Y
				where X.tabla in ('cu_tgar_vehpesados', 'cu_tgar_vehlivianos')
				and X.codigo = Y.tabla)
		and cu_tipo = tc_tipo		
		and gp_garantia=@i_garan
	
	      select op_banco,cu_codigo_externo,op_cliente,op_operacion,op_tramite,op_nombre,		
	       (select max(en_nomlar)	
		       from cob_credito..cr_deudores,
		       cob_credito..cr_tramite,
		       cobis..cl_ente
		       where de_tramite=tr_tramite
		       and de_ced_ruc=en_ced_ruc 
		       and de_rol='C'
		       and tr_tramite=a.op_tramite) as codeudor,	--SS 21/Dic/2007
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE' 
			and it_nombre ='MARCA') as marca,	
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='VERSION') as version,	
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='COLOR') as color,	
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='MODELO') as modelo,	
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='ANIO') as anio,		
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='CLASE') as clase,	
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
			cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='MOTOR') as motor,	
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='SERIE') as serie,	
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='TONELAJE') as tonelaje,
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
 		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='CARROCERIA') as carroceria,
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='LINEA') as linea,
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='USO') as uso,
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where  ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='CILINDRAJE') as cilindraje,
		(select	max(ic_valor_item)
			from cob_custodia..cu_item_custodia,
		     	cob_custodia..cu_item
			where ic_codigo_externo = a.cu_codigo_externo
			and ic_tipo_cust      = it_tipo_custodia
			and ic_item           = it_item
			and ic_tipo_cust <> 'GARGPE'
			and it_nombre ='PLACA') as placa,
		(select min(en_nomlar)
		       from cob_credito..cr_deudores,
		       cob_credito..cr_tramite,
		       cobis..cl_ente
		       where de_tramite=tr_tramite
		       and de_ced_ruc=en_ced_ruc 
		       and de_rol='O'
		       and tr_tramite=a.op_tramite) as concesionario,
		--op_fecha_ult_proceso,   
		convert(varchar,op_fecha_ult_proceso,111) as fec_ult_pro, --SS 18/Ene/2008 Operaciones Canceladas cambio de formato en fecha
		op_estado as estado
                ,@w_sucursal as sucursal, --PAC 25 01/Ago/2008 envia al front end la sucursal
                @w_oficina   as oficina   --PAC 26 01/Ago/2008 envia al front end la oficina                
              into #tempo_aux
	      from #tempo a
              
              /* Adaptive Server has expanded all '*' elements in the following statement */ select
                 a.op_banco, a.cu_codigo_externo, a.op_cliente, a.op_operacion, a.op_tramite, a.op_nombre, a.codeudor, a.marca, a.version, a.color, a.modelo, a.anio, a.clase, a.motor, a.serie, a.tonelaje, a.carroceria, a.linea, a.uso, a.cilindraje, a.placa, a.concesionario, a.fec_ult_pro, a.estado, a.sucursal, a.oficina                         ,
                 (select en_ced_ruc
		              from cob_credito..cr_deudores,
		                   cob_credito..cr_tramite t,
                         cobis..cl_ente
                    where de_tramite=tr_tramite
                      and de_ced_ruc=en_ced_ruc 
                      and de_rol='C'
		                and tr_tramite=a.op_tramite
                    having max(en_nomlar) = en_nomlar) as ced_deudor,	--PAC 27 01/Ago/2008 envia al front end la cedula del codeudor
                  (select en_ced_ruc
		               from cobis..cl_ente
                    where en_ente = a.op_cliente) as ced_codeudor,           --PAC 28 01/Ago/2008 envia al front end la cedula del deudor
		         --- Espa - 10/Jul/2009 - I 
		        (select cu_tipo
		           from #tempo b
		          where b.op_tramite =  a.op_tramite)
		         --- Espa - 10/Jul/2009 - F
              from
                  #tempo_aux a
	end
	else
	begin
		select @gar1=count(*)
		from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia,
		cob_cartera..ca_operacion,cob_custodia..cu_tipo_custodia
		where gp_garantia = cu_codigo_externo
		and gp_tramite = op_tramite
		and cu_tipo <> 'GARGPE'
		and cu_tipo in (select distinct(Y.codigo) from cobis..cl_tabla X, cobis..cl_catalogo Y
				where X.tabla in ('cu_tgar_vehpesados', 'cu_tgar_vehlivianos')
				and X.codigo = Y.tabla)
		and cu_tipo = tc_tipo
		and gp_garantia=@i_garan
	   
	   select @gar2=count(*)
		from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia, --SS 07/Nov/2007
		cob_cartera_his..ca_operacion,cob_custodia..cu_tipo_custodia
		where gp_garantia = cu_codigo_externo
		and gp_tramite = op_tramite
		and cu_tipo <> 'GARGPE'
		and cu_tipo in (select distinct(Y.codigo) from cobis..cl_tabla X, cobis..cl_catalogo Y
				where X.tabla in ('cu_tgar_vehpesados', 'cu_tgar_vehlivianos')
				and X.codigo = Y.tabla)
		and cu_tipo = tc_tipo		
		and gp_garantia=@i_garan

	  select @garT = @gar1 + @gar2

	  select @garT

	End
end

if @i_operacion='I'
	begin	
		--SERS 21/Dic/2007 Inserta las impresiones a la transaccion de servicio		
		insert into cob_custodia..ts_cust_det ( 
				secuencial,tipo_transaccion,clase,fecha,usuario,terminal,oficina,tabla, 
				op_banco,op_operacion,op_tramite,op_cliente,garantia,comentarios,Doc_Impresos,Fecha_imp) 
		select @s_ssn,@t_trn, "I", @s_date, @s_user, @s_term, @s_ofi,"cu_custodia",
	    	       @i_banco,@i_opert,@i_tramite,@i_cliente,@i_garan,'Imprime Garantia',@i_documen,getdate()

	end
go