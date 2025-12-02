use cob_cartera
go

if exists (select
             1
           from   sysobjects
           where  name = 'sp_reporte_benefgrp ')
  drop proc sp_reporte_benefgrp 
go

CREATE proc sp_reporte_benefgrp(
/*************************************************************************/
/*  Archivo:            sp_reporte_benefgrp.sp                           */
/*  Stored procedure:   sp_reporte_benefgrp                              */
/*  Base de datos:      cob_cartera                                      */
/*  Producto:           Cartera                                          */
/*  Disenado por:       A Antonio Martinez D                             */
/*  Fecha de escritura: 24-Sep-2019                                      */
/*************************************************************************/
/*              IMPORTANTE                                               */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad         */
/*  de COBISCorp.                                                        */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como     */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus     */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.    */
/*  Este programa esta protegido por la ley de   derechos de autor       */
/*  y por las    convenciones  internacionales   de  propiedad inte-     */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir         */
/*  penalmente a los autores de cualquier   infraccion.                  */
/*************************************************************************/
/*              PROPOSITO                                                */
/*  Permite generar el Reporte de Beneficiarios Banca Grupal para los    */
/*  productos grupales BCOMUNAL, B52COMUNAL                              */
/*************************************************************************/
/*              MODIFICACIONES                                           */
/*  FECHA          AUTOR          RAZON                                  */
/*  24/Sep/2019    AAMD            Emision inicial                       */
/*************************************************************************/
@s_filial           int          = 1,
@t_trn              int          = 77540,
@i_nroprestamo            varchar(255)     --NRO Prestamo
)
as
declare
@w_mensaje            varchar(255),
@w_sp_name            varchar(20),
@w_error              int,
@w_desc_ope_grp 	  varchar(64),
@w_desc_estado		  varchar(64),
@w_desc_ciudad		  varchar(64),
@w_desc_fecha		  varchar(35),
@w_desc_grupo		  varchar(64),
@w_desc_reca		  varchar(64),
@w_desc_filial        varchar(30)

set ansi_warnings off
SET Language 'Spanish'

if @i_nroprestamo is not NULL AND @i_nroprestamo <> ''
	begin	
		-- Obtengo los datos de la estructura general del reporte
		select 
		@w_desc_ope_grp = COALESCE((select cc.valor 
		   from cobis.dbo.cl_catalogo cc
		  where cc.tabla = (select ct.codigo 
		       		          from cobis.dbo.cl_tabla ct
		              		 where ct.tabla = 'ca_grupal') 
		    and cc.estado = 'V' 
		    and cc.codigo = co.op_toperacion), 'No definido'),
		@w_desc_estado = COALESCE((select cc.valor
				  from cobis.dbo.cl_catalogo cc
				 where cc.tabla = (select ct.codigo 
									 from cobis.dbo.cl_tabla ct 
									where ct.tabla = 'cl_oficina')
									  and cc.estado = 'V' 
								      and cc.codigo = co.op_oficina), 'No definido')  + ' ' +
		COALESCE((select cc.valor
				  from cobis.dbo.cl_catalogo cc
				 where cc.tabla = (select ct.codigo 
									 from cobis.dbo.cl_tabla ct 
									where ct.tabla = 'cl_provincia')
									  and cc.estado = 'V' 
								      and cc.codigo = (select of_provincia from cobis..cl_oficina where of_oficina=co.op_oficina)), 'No definido'),
		@w_desc_ciudad = COALESCE((select cc.valor
				  from cobis.dbo.cl_catalogo cc
				 where cc.tabla = (select ct.codigo 
									 from cobis.dbo.cl_tabla ct 
									where ct.tabla = 'cl_ciudad')
									  and cc.estado = 'V' 
								      and cc.codigo = (select of_ciudad from cobis..cl_oficina where of_oficina=co.op_oficina)), 'No definido'),
		@w_desc_fecha = CONVERT(VARCHAR, DATEPART(day, GETDATE()))+' de '+  
		    DATENAME(month, GETDATE())+' de '+
		    CONVERT(VARCHAR,DATEPART(YEAR, GETDATE())), 
		@w_desc_grupo = (select cg.gr_nombre from cobis.dbo.cl_grupo cg where cg.gr_grupo = co.op_grupo),
		@w_desc_reca = (select cid.id_dato 
		   from cob_credito.dbo.cr_imp_documento cid,
				cob_credito.dbo.cr_tramite ct
		  where cid.id_tipo_tramite = ct.tr_tipo
			and ct.tr_tramite = co.op_tramite
			and	cid.id_mnemonico = 'CABENGCBG' 
			and cid.id_toperacion = co.op_toperacion)
		from cob_cartera.dbo.ca_operacion co
		where co.op_grupal = 'S'
		and co.op_ref_grupal is null
		and co.op_banco = @i_nroprestamo
		
		-- Obtenemos el nombre de la filial
		select @w_desc_filial = fi_nombre 
		from cobis..cl_filial
		where fi_filial = @s_filial
		
		select @w_desc_ope_grp as 'descOpeGrp',
			   @w_desc_estado as 'estado',
			   @w_desc_ciudad as 'ciudad',
		       @w_desc_fecha as 'fechaImpresion',
		       @w_desc_grupo as 'descGrupo',
		       @w_desc_reca as 'reca',
		       @w_desc_filial as 'descFilial'
		
		-- obtenemos los miembros del grupo
		select co.op_operacion as 'opeGrpCte',
		CONCAT(ce.p_p_apellido,' ',ce.p_s_apellido,' ',ce.en_nombre,' ',ce.p_s_nombre) as 'nombreCte',
		ct.tr_tipo as 'tipoTramite'
		from cob_cartera.dbo.ca_operacion co,
			 cobis.dbo.cl_ente ce,
			 cob_credito.dbo.cr_tramite ct
		where co.op_cliente = ce.en_ente
		and co.op_tramite = ct.tr_tramite
		and co.op_grupal = 'S' 
		and co.op_ref_grupal = @i_nroprestamo
		order by CONCAT(ce.p_p_apellido,' ',ce.p_s_apellido,' ',ce.en_nombre,' ',ce.p_s_nombre)
		
		-- obtenemos los beneiciarios del grupo
		select cbs.bs_nro_operacion as 'opeGrpBenef',
		CONCAT(cbs.bs_apellido_paterno,' ',cbs.bs_apellido_materno,' ',cbs.bs_nombres) as 'nombreBenef',
		cbs.bs_porcentaje as 'porcentajeBenef'
		from cob_cartera.dbo.ca_operacion co,
		cobis.dbo.cl_beneficiario_seguro cbs
		where co.op_operacion = cbs.bs_nro_operacion
		and co.op_grupal = 'S' 
		and co.op_ref_grupal = @i_nroprestamo
		order by cbs.bs_nro_operacion , CONCAT(cbs.bs_apellido_paterno,' ',cbs.bs_apellido_materno,' ',cbs.bs_nombres)
		
		return 0
	end
else
	begin
       select @w_error = 70203
       goto   ERROR
    end

ERROR: 

   select @w_mensaje = @w_sp_name + ' --> ' + @w_mensaje
   print @w_mensaje
   
   return 1

go
