/************************************************************************/
/*   Archivo:              reporte_sol_complementaria.sp                */
/*   Stored procedure:     sp_reporte_sol_complementaria                */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito                                      */
/*   Disenado por:         Raúl Altamirano Mendez                       */
/*   Fecha de escritura:   Marzo 2018                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Genera informacion requerida para mostrar en reporte de Solicitud  */
/*   Individual Complementaria                                          */
/*                              CAMBIOS                                 */
/************************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_reporte_sol_complementaria' and type = 'P')
  drop proc sp_reporte_sol_complementaria
go

create proc sp_reporte_sol_complementaria(  
@i_ente      int,
@i_operacion char(2),      --'IG', 'DD', 'DE', 'DI', 'NC', 'RP', 'RC'
@i_modo      tinyint = 0,
@i_formato   tinyint = 103,
--PARA TIPO DI
@i_tipo_dir  char(1) = 'F',
@i_tipo      catalogo = null,
--PARA TIPO NC
@i_cod_neg   int = null,
--PARA TIPO RP

--PARA TIPO RC
@i_relacion int = 0,
@i_ente_d   int = null,
@i_tramite  int = null
)
as

declare 
@w_error         int,
@w_return        int,
@w_mensaje       varchar(255),
@w_sp_name       varchar(30),
@w_msg           varchar(255),
@w_ente_i        int,
@w_ente_d        int,
@w_len           int,
@w_cod_area      int,
@w_direccion     int,
@w_telefono_id   int,
@w_telefono_aux  varchar(20),
@w_cod_relacion  tinyint,
@w_mayoria_edad  tinyint,
@w_edad_max      tinyint,
@w_parametro_cli int,
@w_num_externo   int,
@w_num_interno   int,
@w_fecha_proceso datetime,
@w_arma_categoria varchar(255),
@w_categoria_cli  varchar(255),
@w_descripcion_cobis varchar(64),
@w_cod_direccion     int , 
@w_telefono_fijo     varchar(30), 
@w_telefono_celular  varchar(30),
@w_fecha_crea_sol    datetime,
@w_grupo             int,
@w_codigo_act_apr    int,
@w_tramite_grupo     int,
@w_coordinador        varchar(64),
@w_login_coordinador  login,
@w_analista_op        varchar(64),
@w_login_analista     login,
@w_login              login,
@w_codigo_act_rev     int,
@w_est_vigente        tinyint,
@w_cliente            int,
@w_tmercado           varchar(4),
@w_variables          varchar(255),
@w_parent             varchar(255),
@w_result_values      varchar(255),
@w_tipo_operacion     varchar(20),
@w_monto_credito      money,
@w_id_inst_proc       int,
@w_ssn                int,
@w_sesn               int
		
select @w_sp_name = 'sp_reporte_sol_complementaria'

exec @w_error   = cob_cartera..sp_estados_cca
@o_est_vigente  = @w_est_vigente out

if @w_error > 0 begin
   return @w_error
end
--Consulta de la Fecha de Proceso   
select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

--select @i_ente

if @i_operacion = 'IG'          --Seccion de Informacion General
begin
   --print 'Seccion de Informacion General'
   
   --Consulta de Parametro para relación conyuge 
   select @w_cod_relacion = pa_tinyint
   from  cobis..cl_parametro 
   where pa_nemonico = 'COU' 
   and   pa_producto = 'CRE'
   
   --Consulta de Parametro para Edad minima
   select @w_mayoria_edad = pa_tinyint
   from  cobis..cl_parametro 
   where pa_nemonico = 'MDE'
   and   pa_producto = 'ADM'

   --Consulta de Parametro para Edad maxima
   select @w_edad_max = pa_tinyint
   from  cobis..cl_parametro 
   where pa_nemonico = 'EMAX'
   and   pa_producto = 'ADM'
   
   --Consulta de Parametro para Fecha de Vigencia de Datos Personales
   select @w_parametro_cli = pa_int 
   from  cobis..cl_parametro 
   where pa_nemonico = 'FDVP' 
   and   pa_producto = 'CLI' 
  

   select
   cliente                    = @i_ente,   
   p_apellido                 = a.p_p_apellido,
   s_apellido                 = a.p_s_apellido,
   nombre                     = a.en_nombre,
   cedula                     = a.en_ced_ruc,
   pasaporte                  = a.p_pasaporte,
   pais                       = a.en_pais,
   ciudad_nac                 = a.p_ciudad_nac,
   fecha_nac                  = a.p_fecha_nac,
   anios_edad                 = datediff(yy, a.p_fecha_nac, @w_fecha_proceso),
   fechanac                   = convert(char(10), a.p_fecha_nac, @i_formato),
   fechareg                   = convert(char(10), a.en_fecha_crea, @i_formato),
   fechamod                   = convert(char(10), a.en_fecha_mod, @i_formato),
   meses_vigentes             = datediff(mm, a.en_fecha_mod, @w_fecha_proceso),
   fechaing                   = convert(char(10), a.p_fecha_emision, @i_formato),
   fechaexp                   = convert(char(10), a.p_fecha_expira, @i_formato),
   tipoced                    = a.en_tipo_ced,
   tipo_vinculacion           = a.en_tipo_vinculacion,
   nit                        = '',--a.en_rfc,
   cod_sector                 = a.en_sector,
   cod_sexo                   = a.p_sexo,
   profesion                  = a.p_profesion,
   actividad                  = convert(varchar(255), null),
   estado_civil               = a.p_estado_civil,
   tipo                       = a.p_tipo_persona,
   nivel_estudio              = a.p_nivel_estudio,
   grupo                      = a.en_grupo,
   oficial                    = a.en_oficial,
   lugar_doc                  = '',--a.p_depa_nac,
   tipo_vivienda              = a.p_tipo_vivienda,
   num_hijos                  = a.p_num_hijos,
   nivel_ing                  = a.p_nivel_ing,
   nivel_egr                  = a.p_nivel_egr,
   num_cargas                 = a.p_num_cargas,
   oficina_origen             = a.en_oficina ,
   doc_validado               = a.en_doc_validado ,
   rep_superban               = a.en_rep_superban ,
   filial                     = a.en_filial,
   gran_contribuyente         = a.en_gran_contribuyente,
   situacion_cliente          = a.en_situacion_cliente,
   patrim_tec                 = a.en_patrimonio_tec,
   fecha_patrim_bruto         = convert(char(10), a.en_fecha_patri_bruto, @i_formato),
   total_activos              = a.c_total_activos,
   oficial_sup                = a.en_oficial_sup,
   preferen                   = a.en_preferen,
   exc_sipla                  = a.en_exc_sipla,
   exc_por2                   = a.en_exc_por2,
   digito                     = a.en_digito,
   cem                        = a.en_cem,
   c_apellido                 = a.p_c_apellido,
   segnombre                  = a.p_s_nombre,
   depar_doc                  = a.p_dep_doc,
   numord                     = a.p_numord,
   promotor                   = a.en_promotor,
   pais_nacionalidad          = '',--a.p_pais_emi,
   cod_otro_pais              = a.en_cod_otro_pais,
   inss                       = a.en_inss,
   en_nom_tutor               = a.en_nom_tutor,
   carg_pub                   = a.p_carg_pub,
   rel_carg_pub               = a.p_rel_carg_pub,
   situacion_laboral          = a.p_situacion_laboral,
   bienes                     = a.p_bienes,
   otros_ingresos             = 0.0,--a.en_otros_ingresos,
   origen_ingresos            = a.en_origen_ingresos,
   o_ea_observacion_aut       = b.ea_observacion_aut,
   ea_contrato_firmado        = b.ea_contrato_firmado,
   ea_menor_edad              = b.ea_menor_edad,
   c_funcionario              = a.c_funcionario,
   ea_sector_eco              = b.ea_sector_eco,
   ea_actividad               = b.ea_actividad,
   ea_lin_neg                 = b.ea_lin_neg,
   ea_seg_neg                 = b.ea_seg_neg,
   discapacidad               = b.ea_discapacidad,
   pep                        = '',--a.en_persona_pep,
   mnt_pasivo                 = a.c_pasivo,
   vinculacion                = a.en_vinculacion,
   ant_nego                   = '',--b.ea_ant_nego,
   ventas                     = '',--b.ea_ventas,
   ct_ventas                  = '',--ea_ct_ventas,
   ct_operativos              = '',--ea_ct_operativo,
   persona_pub                = '',--en_persona_pub,
   ing_SN                     = '',--en_ing_SN,
   otringr                    = '',--en_otringr ,
   depa_nac                   = '',--p_depa_nac,
   nac_aux                    = '',--en_nac_aux,
   pais_emi                   = '',--p_pais_emi,
   partner                    = '',--ea_partner,
   lista_negra                = ea_lista_negra,
   tecnologico                = ea_tecnologico,
   arma_categoria             = convert(varchar(255), null),
   menor_edad                 = convert(varchar(2), null),
   vigencia                   = convert(tinyint, null),
   desc_actividad             = convert(varchar(200), null),
   sexo                       = convert(varchar(64), null),
   desc_sector                = convert(varchar(64), null),
   desc_situacion_cliente     = convert(varchar(64), null),
   desc_estado_civil          = convert(varchar(64), null),
   desc_niv_estudios          = convert(varchar(64), null),
   desc_tipo_vinculacion      = convert(varchar(64), null),
   desc_tipo                  = convert(varchar(64), null),
   desc_profesion             = convert(varchar(64), null),
   desc_tipo_vivienda         = convert(varchar(64), null),
   desc_promotor              = convert(varchar(64), null),
   desc_lugar_doc             = convert(varchar(64), null),  
   desc_grupo                 = convert(varchar(64), null), 
   desc_oficial               = convert(varchar(50), null),
   login_principal            = convert(varchar(15), null),
   desc_oficial_sup           = convert(varchar(50), null),		 
   login_suplente             = convert(varchar(15), null),
   desc_pais                  = convert(varchar(64), null),
   desc_nacionalidad          = convert(varchar(64), null),
   desc_depar_doc             = convert(varchar(64), null),
   desc_tipo_ced              = convert(varchar(64), null),
   nacio_tipo_ced             = convert(varchar(64), null),  
   cod_conyuge                = convert(int, null),
   nom_conyuge                = convert(varchar(255), null), 
   cod_grupo                  = convert(int, null),
   nom_grupo                  = convert(varchar(64), null),
   dia_reunion                = convert(varchar(10), null),
   desc_dia_reunion           = convert(varchar(64), null),
   hora_reunion               = convert(varchar(8), null),
   total_ingresos             = convert(money, null),
   total_gastos               = convert(money, null),
   capacidad_pago             = convert(money, null),
   tipo_direccion             = convert(varchar(10), null),
   desc_tipo_direccion        = convert(varchar(64), null),
   direccion_correo           = convert(varchar(255), null),
   numero_ife                 = '',--b.ea_numero_ife,
   num_serie_firma            = '',--b.ea_num_serie_firma,
   sucursal                   = convert(varchar(255), null),
   telefono_fijo              = convert(varchar(255), null),
   telefono_celular           = convert(varchar(255), null),
   telefono_recado            = '',--isnull(b.ea_telef_recados,''),
   nombre_persona_recado      = '',--isnull(b.ea_persona_recados,''),
   cta_en_buro_credito        = '',--isnull(b.ea_antecedente_buro,''),
   nombre_coordinador         = convert(varchar(255), null),
   nombre_analista            = convert(varchar(255), null),
--   importe                    = convert(money, null),*/
   tiene_cred_grupal          = 'N'
   into #datos_cliente
   from  cobis..cl_ente as a
   inner join cobis..cl_ente_aux b on (a.en_ente = b.ea_ente)
   where a.en_subtipo = 'P'
   and a.en_ente      = @i_ente
   

   if @@rowcount = 0
   begin
      select @w_error = 101001
      goto ERROR
   end
   
    select @w_arma_categoria = ''
   
   declare categoria cursor for
   select distinct b.valor, pd_descripcion   
   from cobis..cl_cliente,
        cobis..cl_det_producto,
        cobis..cl_producto,
        cobis..cl_homologar_cat, 
		cobis..cl_tabla a, 
		cobis..cl_catalogo b
   where cl_det_producto= dp_det_producto
   and cl_cliente       = @i_ente
   and dp_estado_ser    = 'V'
   and cl_rol           = hc_cat_cobis
   and hc_producto      = dp_producto
   and a.tabla          = 'cl_cat_homologa_banco'
   and a.codigo         = b.tabla
   and b.codigo         = hc_cat_banco   
   and dp_producto      = pd_producto 

 	open categoria
   
   fetch next from categoria into @w_categoria_cli, @w_descripcion_cobis
   
   while @@fetch_status = 0
   begin
      select @w_arma_categoria = @w_arma_categoria  + @w_categoria_cli +  ' - '  + @w_descripcion_cobis + ' | '
	  
      fetch next from categoria into @w_categoria_cli, @w_descripcion_cobis
   end
   
   close categoria
   deallocate categoria
   
    --Direccion de Correo Electronico
   select top 1 
   @w_direccion = di_direccion 
   from cobis..cl_direccion 
   where di_ente = @i_ente
   and di_tipo = 'CE'
   order by di_direccion
   
   update #datos_cliente
   set tipo_direccion = di_tipo,
       desc_tipo_direccion = 'CORREO ELECTRONICO',
       direccion_correo = di_descripcion
   from cobis..cl_direccion
   where cliente = @i_ente
   and   di_ente = cliente
   and   di_direccion = @w_direccion

--Categoria del Cliente
   update #datos_cliente
   set   arma_categoria = @w_arma_categoria,                                                                           --Categoria del Cliente
         menor_edad = case when (anios_edad > @w_mayoria_edad and anios_edad < @w_edad_max) then 'NO' else 'SI' end,   --Edad del Cliente
		 vigencia   = case when (meses_vigentes > @w_parametro_cli) then 1 else 0 end--,                                 --Vigencia del Cliente
		 --total_ingresos = otros_ingresos + ventas,        --Total Ingresos 
		 --total_gastos   = ct_ventas + ct_operativos,      --Total Gastos  
		 --capacidad_pago = ((otros_ingresos + ventas) + (ct_ventas + ct_operativos)) / 4        --Capacidad de Pago
		 --capacidadPago= (IngresosMensuales - (GastosFamiliares + GastosNegocio))/4
		 --capacidad_pago = ((otros_ingresos + ventas) - (ct_ventas + ct_operativos)) / 4 --Capacidad de Pago
   where cliente = @i_ente
   
   --Descripcion de la Actividad Economica
   update #datos_cliente
   set   actividad = nc_actividad_ec
   from  cobis..cl_negocio_cliente
   where nc_ente = @i_ente

   update #datos_cliente
   set   desc_actividad = ac_descripcion
   from  cobis..cl_actividad_ec
   where actividad = ac_codigo

	--Descripcion del Sexo
   update #datos_cliente
   set sexo = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where cod_sexo = c.codigo
   and c.tabla    = t.codigo
   and t.tabla    = 'cl_sexo'   

   --Descripcion del Sector Economico
   update #datos_cliente
   set desc_sector = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where cod_sector = c.codigo
   and c.tabla      = t.codigo
   and t.tabla      = 'cl_sectoreco' 

   --Descripcion de la Situacion Financiera del Cliente
   update #datos_cliente
   set desc_situacion_cliente = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where situacion_cliente = c.codigo
   and c.tabla      = t.codigo
   and t.tabla      = 'cl_situacion_cliente'
   
   --Descripcion del Estado Civil
   update #datos_cliente
   set desc_estado_civil = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where estado_civil = c.codigo
   and c.tabla        = t.codigo
   and t.tabla        = 'cl_ecivil'
   
   --Descripcion del Nivel de Estudios
   update #datos_cliente
   set desc_niv_estudios = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where nivel_estudio = c.codigo
   and c.tabla         = t.codigo
   and t.tabla         = 'cl_nivel_estudio'  
   
   --Descripcion del Tipo de Vinculacion
   update #datos_cliente
   set tipo_vinculacion = case vinculacion when 'S' then '013' else tipo_vinculacion end
   where tipo_vinculacion is not null
   
   update #datos_cliente
   set desc_tipo_vinculacion = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where tipo_vinculacion = c.codigo
   and c.tabla            = t.codigo
   and t.tabla            = 'cl_relacion_banco'
   
   --Descripcion del Tipo
   update #datos_cliente
   set desc_tipo = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where tipo   = c.codigo
   and c.tabla  = t.codigo
   and t.tabla  = 'cl_ptipo'
   
   --Descripcion de la Profesion
   update #datos_cliente
   set desc_profesion = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where profesion = c.codigo
   and c.tabla     = t.codigo
   and t.tabla     = 'cl_profesion'
   
   --Descripcion del Tipo de Vivienda
   update #datos_cliente
   set desc_tipo_vivienda = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where tipo_vivienda = c.codigo
   and c.tabla     = t.codigo
   and t.tabla     = 'cl_tipo_vivienda'
   
   --Descripcion del Promotor
   update #datos_cliente
   set desc_promotor = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where promotor = c.codigo
   and c.tabla    = t.codigo
   and t.tabla    = 'cl_promotor'
   
   --Descripcion del Lugar de Documentacion
   /*update #datos_cliente
   set   desc_lugar_doc = pa_descripcion
   from  cobis..cl_pais
   where lugar_doc = pa_pais
   and   tipoced in ('P', 'E')
   
   update #datos_cliente
   set   desc_lugar_doc = ci_descripcion
   from  cobis..cl_ciudad
   where lugar_doc = ci_ciudad
   and   tipoced not in ('P', 'E')*/
   
   /*update #datos_cliente
   set desc_lugar_doc = pv_descripcion    
   from cobis..cl_provincia
   where pv_provincia = lugar_doc   */--jjvalidate
   /*update #datos_cliente
   set desc_lugar_doc = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where convert(char(4), lugar_doc) = c.codigo
   and c.tabla    = t.codigo
   and t.tabla    = 'cl_provincia'
   and lugar_doc is not null   
   */

   --Nombre del Grupo   
   update #datos_cliente
   set   desc_grupo = gr_nombre
   from  cobis..cl_grupo
   where grupo = gr_grupo
   
   --Nombre de la tabla de Funcionarios:
   --PRINCIPAL
   update #datos_cliente
   set   desc_oficial = substring(fu_nombre, 1, 45),
         login_principal = fu_login
   from  cobis..cc_oficial, 
         cobis..cl_funcionario
   where oc_oficial = oficial
   and oc_funcionario = fu_funcionario
   and isnull(oficial, 0) <> 0

--SUPLENTE
   update #datos_cliente
   set   desc_oficial_sup = substring(fu_nombre, 1, 45),
         login_suplente = fu_login
   from  cobis..cc_oficial, 
         cobis..cl_funcionario
   where oc_oficial = oficial_sup
   and oc_funcionario = fu_funcionario
   and isnull(oficial_sup, 0) <> 0

   --Descripcion del Pais
   /*update #datos_cliente
   set   desc_pais = pa_descripcion
   from  cobis..cl_pais
   where pa_pais = pais_nacionalidad
   and   pais_nacionalidad is not null*/--jjvalidate
   
   --Descripcion de la Nacionalidad o Extrajera
   update #datos_cliente
   set   desc_nacionalidad = (select valor from cobis..cl_catalogo where tabla = (
                              select codigo from cobis..cl_tabla where tabla = 'cl_nacionalidad')
							  and codigo = PA.nac_aux)
   from  #datos_cliente PA
   
   --Descripcion del Departamento de Emision de Documento
   update #datos_cliente
   set desc_depar_doc = pv_descripcion
   from cobis..cl_provincia
   where pv_provincia = depar_doc


  /*update #datos_cliente
   set desc_depar_doc = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where convert(char(4), depar_doc) = c.codigo
   and c.tabla    = t.codigo
   and t.tabla    = 'cl_provincia'
   and depar_doc is not null*/
   
   --Descripcion de la Nacionalidad
   update #datos_cliente
   set   desc_tipo_ced  = td_descripcion,
         nacio_tipo_ced = td_nacionalidad
   from  cobis..cl_tipo_documento
   where td_codigo = tipoced
   and   tipoced is not null

   --Descripcion de los Datos del Conyuge
   update #datos_cliente
   set   cod_conyuge = in_ente_d
   from  cobis..cl_instancia
   where in_relacion = @w_cod_relacion
   and in_ente_i = cliente   
   
   update #datos_cliente
   set   nom_conyuge = en_nombre + ' ' + isnull(p_s_nombre, '') + ' ' + p_p_apellido + ' ' + isnull(p_s_apellido, '')
   from  cobis..cl_ente
   where en_ente = cod_conyuge
   
   
   --Descripcion de los Datos del Grupo del Cliente
   update #datos_cliente
   set   cod_grupo = cg_grupo,
         nom_grupo = gr_nombre,
		 dia_reunion  = gr_dia_reunion,
		 hora_reunion = ltrim(rtrim(right(rtrim(convert(varchar(20), gr_hora_reunion, 100)), 8)))
   from  cobis..cl_cliente_grupo, 
         cobis..cl_grupo
   where cg_ente   = cliente
   and   cg_estado = 'V' 
   and   cg_fecha_desasociacion is null 
   and   gr_grupo  = cg_grupo
   
   --Descripcion del Dia de la Semana
   update #datos_cliente
   set   desc_dia_reunion = upper(c.valor)
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where dia_reunion = c.codigo
   and c.tabla   = t.codigo
   and t.tabla   = 'ad_dia_semana'

   --Descripcion PARENTESCO CARGO PUBLICO
   update #datos_cliente
   set   rel_carg_pub = upper(c.valor)
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where rel_carg_pub = c.codigo
   and c.tabla   = t.codigo
   and t.tabla   = 'cl_parentesco'

 
   --SUCURSAL
   update #datos_cliente
   set sucursal = upper(of_nombre)
   from cobis..cl_oficina
   where of_oficina = oficina_origen
   
   -- Telefonos
   SELECT @w_cod_direccion = di_direccion 
   from  cobis..cl_direccion
   where di_ente = @i_ente
   and di_principal = 'S'

   if @@rowcount = 0
   begin
       select @w_cod_direccion = di_direccion 
       from  cobis..cl_direccion
       where di_ente = @i_ente
   end

   select @w_telefono_fijo = te_valor from cobis..cl_telefono 
   where te_ente = @i_ente 
   and te_direccion = @w_cod_direccion
   and te_tipo_telefono IN ('D')
   
   select @w_telefono_celular = te_valor from cobis..cl_telefono 
   where te_ente = @i_ente 
   and te_direccion = @w_cod_direccion
   and te_tipo_telefono IN ('C')


    --GERENTE
	/*update #datos_cliente
	set   nombre_coordinador = fu_nombre
	from  cobis..cl_funcionario 
	where fu_oficina = oficina_origen 
	and   fu_cargo = (select pa_char from cobis..cl_parametro 
	                  where pa_nemonico = 'PGEREA' and pa_producto = 'CRE')*/
    /*CODIGO ACTIVIDAD APROBACION SOLICITUDES*/
    select @w_codigo_act_apr = pa_int
    from   cobis..cl_parametro --with (nolock)
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'CAAPSO'
    
    /*CODIGO ACTIVIDAD REVISION Y VALIDACION SOLICITUDES*/
    select @w_codigo_act_rev = pa_int
    from   cobis..cl_parametro --with (nolock)
    where pa_nemonico = 'CAREVA'
	                  
    select @w_grupo = cg_grupo
    from cobis..cl_cliente_grupo    
    where cg_ente   = @i_ente
    and   cg_estado = 'V'
    
    /*se comenta por que cuando tenia mas de un tramite no 
	trae info del select @w_tramite_grupo = max(op_tramite)*/	
	/*@w_coordinador y  @w_analista_op
    from cob_cartera..ca_operacion
    where op_cliente = @w_grupo*/
    
    select @w_tramite_grupo = @i_tramite

    select @w_coordinador = fu_nombre,
            @w_login_coordinador = fu_login
    from cob_workflow..wf_inst_proceso  ,
         cob_workflow..wf_inst_actividad,
         cob_workflow..wf_asig_actividad,
         cob_workflow..wf_usuario       , 
         cobis..cl_funcionario    
    where io_campo_3         = @w_tramite_grupo
    and   ia_id_inst_proc    = io_id_inst_proc
    and   ia_id_inst_act     = aa_id_inst_act
    and   aa_id_destinatario = us_id_usuario
    and   us_login           = fu_login
    and   ia_codigo_act      = @w_codigo_act_apr

    update #datos_cliente
	set   nombre_coordinador = @w_coordinador
    
    --Analista y tipo operacion
    select 
       @w_analista_op    = fu_nombre,
       @w_login_analista = fu_login
    from cob_workflow..wf_inst_proceso  ,
         cob_workflow..wf_inst_actividad,
         cob_workflow..wf_asig_actividad,
         cob_workflow..wf_usuario       , 
         cobis..cl_funcionario    
    where io_campo_3         = @w_tramite_grupo
    and   ia_id_inst_proc    = io_id_inst_proc
    and   ia_id_inst_act     = aa_id_inst_act
    and   aa_id_destinatario = us_id_usuario
    and   us_login           = fu_login
    and   ia_codigo_act      = @w_codigo_act_rev  
    
	update #datos_cliente
	set    nombre_analista = @w_analista_op 

	--Importe
	/*update #datos_cliente
	set    importe = tg_monto_aprobado 
	from   cob_credito..cr_tramite_grupal 
    where  tg_tramite = @i_tramite 
	and    tg_cliente = cliente*/--validatejj

	SELECT 
	@w_tipo_operacion = io_campo_4,
	@w_id_inst_proc   = io_id_inst_proc
	FROM cob_workflow..wf_inst_proceso
	WHERE io_campo_3 = @i_tramite


  --SRO. Importe Crédito Revolvente
    if @w_tipo_operacion = 'REVOLVENTE' begin	
      
       exec @w_ssn = cob_cartera..sp_gen_sec 
         @i_operacion  = -1

       exec @w_sesn = cob_cartera..sp_gen_sec 
         @i_operacion  = -1
       
       if @w_login_analista is not null
          select @w_login = @w_login_analista
       else if @w_login_coordinador is not null
          select @w_login = @w_login_coordinador
       else
          select @w_login = '1'--oficial from #datos_cliente
       
       print 'INI Imprimo variables: '
       print @w_ssn
       print @w_login
       print @w_fecha_proceso
       print @w_sesn
       print @w_id_inst_proc
       print 'FIN Imprimo variables: '
       
       /* Evalua regla Cupo Inicial de la Línea de Crédito Revolvente*/
       exec @w_error       = cob_cartera..sp_ejecutar_regla
       @s_ssn              = @w_ssn,
       @s_ofi              = 1,
       @s_user             = @w_login,
       @s_date             = @w_fecha_proceso,
       @s_srv              = 'SRV',
       @s_term             = 'TERM-1',
       @s_rol              = 1,
       @s_lsrv             = 'LSRV',
       @s_sesn             = @w_sesn,
       @i_regla            = 'LCRCUPINI',    
       @i_id_inst_proc     = @w_id_inst_proc,
       @o_resultado1       = @w_result_values  out  

       if @w_error <> 0 begin
          select @w_msg = 'ERROR AL EJECUTAR REGLA Cupo Inicial Línea de Crédito Revolvente' 
          goto ERROR
       end 
       select @w_monto_credito = convert(money, @w_result_values)
	  	   
       /*update #datos_cliente set    
       importe =  @w_monto_credito*/--validatejj
    end

	 
    if exists (select 1 
    from   cob_credito..cr_tramite_grupal,
    cob_cartera..ca_operacion	
    where  tg_operacion = op_operacion
    and    op_tramite   = @i_tramite
    and    op_estado    = @w_est_vigente) 
    begin--
    	print ''
       /*update #datos_cliente
       set tiene_cred_grupal = 'S'
       where  op_tramite = @i_tramite*/--validatejj
    end
   -- Fecha crea solicitud
	select @w_fecha_crea_sol = tr_fecha_crea from cob_credito..cr_tramite where tr_tramite = @i_tramite   

	if @i_modo = 0   --PRIMERA PARTE
   begin
      select
      FECHA_NACIMIENTO          = fechanac,               -- 1  * FECHA DE NACIMIENTO
      TIPO_DOCUMENTO            = tipoced,                -- 2  * TIPO DE DOCUMENTO DE ID (CURP)
      NUMERO_DOCUMENTO          = cedula,                 -- 3  * NUMERO DE DOCUMENTO DE ID (CURP)
      fechaing,                                           -- 4
      fechaexp,                                           -- 5
      CODIGO_ENTIDAD_NACIMIENTO      = lugar_doc,         -- 6  * CODIGO DE ENTIDAD DE NACIMIENTO
      DESCRIPCION_ENTIDAD_NACIMIENTO = upper(isnull(desc_lugar_doc,'')),    -- 7  * DESCRIPCION DE ENTIDAD DE NACIMIENTO
      PRIMER_NOMBRE             = upper(isnull(nombre,'')),                 -- 8  * PRIMER NOMBRE
      APELLIDO_PATERNO          = upper(isnull(p_apellido,'')),             -- 9  * APELLIDO PATERNO
      APELLIDO_MATERNO          = upper(isnull(s_apellido,'')),             -- 10 * APELLIDO MATERNO
      ciudad_nac,                                         -- 11
      DESCRIPCION_GENERO        = sexo,                   -- 12 * DESCRIPCION DEL GENERO
      CODIGO_GENERO             = cod_sexo,               -- 13 * CODIGO DEL GENERO
      CODIGO_ESTADO_CIVIL       = estado_civil,           -- 14 * CODIGO DE ESTADO CIVIL
      DESCRIPCION_ESTADO_CIVIL  = desc_estado_civil,      -- 15 * DESCRIPCION DEL ESTADO CIVIL
      CODIGO_OCUPACION          = profesion,              -- 16 * CODIGO DE OCUPACION
      DESCRIPCION_OCUPACION     = desc_profesion,         -- 17 * DESCRIPCION DE OCUPACION
      CODIGO_ACTIVIDAD          = actividad,              -- 18 * CODIGO DE ACTIVIDAD
      DESCRIPCION_ACTIVIDAD     = desc_actividad,         -- 19 * DESCRIPCION DE ACTIVIDAD
      NUMERO_PASAPORTE          = pasaporte,              -- 20 * NUMERO DE PASAPORTE
      CODIGO_PAIS_NACIMIENTO    = pais_nacionalidad,      -- 21 * CODIGO DE PAIS DE NACIMIENTO
      DESCRIPION_PAIS_NACIMIENTO= desc_pais,              -- 22 * DESCRIPION DE PAIS DE NACIMIENTO
      cod_sector,                                         -- 23
      desc_sector,                                        -- 24
      CODIGO_ESCOLARIDAD        = nivel_estudio,          -- 25 * CODIGO DE LA ESCOLARIDAD
      DESCRIPCION_ESCOLARIDAD   = desc_niv_estudios,      -- 26 * DESCRIPCION DE LA ESCOLARIDAD
      tipo,                                               -- 27
      desc_tipo,                                          -- 28
      tipo_vivienda,                                      -- 29
      desc_tipo_vivienda,                                 -- 30
      NUMERO_DEPENDIENTES       = isnull(num_cargas,0),             -- 31 * NUM. DE DEPENDIENTES
      num_hijos,                                          -- 32
      oficial,                                            -- 33
      desc_oficial,                                       -- 34
      fechareg,                                           -- 35
      fechamod,                                           -- 36
      grupo,                                              -- 37
      desc_grupo,                                         -- 38
      tipo_vinculacion,                                   -- 39
	  desc_tipo_vinculacion,                              -- 40
      NUMERO_RFC                = nit,                    -- 41 * NUMERO DE RFC
      nivel_ing,                                          -- 42
      oficina_origen,                                     -- 43
      situacion_cliente,                                  -- 44
      desc_situacion_cliente,                             -- 45
      patrim_tec,                                         -- 46
      fecha_patrim_bruto,                                 -- 47
      total_activos,                                      -- 48
      oficial_sup,                                        -- 49
      desc_oficial_sup,                                   -- 50
      nivel_egr,                                          -- 51
      SEGUNDO_NOMBRE            = upper(isnull(segnombre,'')),              -- 52 * SEGUNDO NOMBRE
      c_apellido,                                         -- 53
      depar_doc,                                          -- 54
      desc_depar_doc,                                     -- 55
      numord,                                             -- 56
      promotor,                                           -- 57
      desc_promotor,                                      -- 58
      CODIGO_PAIS_NACIONALIDAD      = pais_nacionalidad,  -- 59 * CODIGO DE PAIS DE NACIONALIDAD
      DESCRIPCION_PAIS_NACIONALIDAD = desc_nacionalidad,  -- 60 * DESCRIPCION DE PAIS DE NACIONALIDAD
      cod_otro_pais,                                      -- 61
      inss,                                               -- 62
      menor_edad,                                         -- 63
      CODIGO_CONYUGE                = cod_conyuge,        -- 64 * CODIGO DEL CONYUGE
	  NOMBRE_CONYUGE                = upper(isnull(nom_conyuge,'')),        -- 65 * NOMBRE DEL CONYUGE
      persona_pub,                                        -- 66
      ing_SN,                                             -- 67
      otringr,                                            -- 68
      CODIGO_LUGAR_NACIMIENTO       = depa_nac,           -- 69 * CODIGO DE LUGAR DE NACIMIENTO
      nac_aux,                                            -- 70
      pais_emi,                                           -- 71
	  PERSONA_PEP                   = pep,                -- 72 * PERSONA PEP         
      CARGO_PUBLICO                 = upper(isnull(carg_pub,'')),           -- 73 * CARGO PUBLICO
      PARENTESCO_CARGO_PUBLICO      = rel_carg_pub,       -- 74 * PARENTESCO CARGO PUBLICO,
	  partner,                                            -- 75
      lista_negra,                                        -- 76
      tecnologico,                                        -- 77
      cod_grupo,                                          -- 78
      nom_grupo,                                          -- 79
	  DIA_LOCALIZACION              = upper(isnull(desc_dia_reunion,'')),   -- 80 * DIA DE REUNION 
	  HORA_LOCALIZACION             = hora_reunion,       -- 81 * HORA DE REUNION
	  INGRESOS_VENTAS               = otros_ingresos,     -- 82 * INGRESOS (VENTAS)
      origen_ingresos,                                    -- 83 
      OTROS_INGRESOS                = 0,--ventas,             -- 84 * OTROS INGRESOS  
	  TOTAL_INGRESOS                = total_ingresos,     -- 85 * TOTAL INGRESOS
	  GASTOS_NEGOCIO                = 0,--ct_operativos,      -- 86 * GASTOS DEL NEGOCIO
	  GASTOS_FAMILIARES             = 0,--ct_ventas,          -- 87 * GASTOS FAMILIARES
	  TOTAL_GASTOS                  = total_gastos,       -- 88 * TOTAL DE GASTOS
	  CAPACIDAD_PAGO                = capacidad_pago,     -- 89 * CAPACIDAD DE PAGO
	  SUCURSAL                      = convert(varchar,oficina_origen) +' ' + upper(sucursal),          -- 90 * SUCURSAL
	  IMPORTE_SOLICITADO            = 0,--importe,            -- 91 * IMPORTE SOLICITADO
	  FECHA_SOLICITUD               = convert(char(10), @w_fecha_crea_sol, @i_formato),                -- 92 * FECHA DE SOLICITUD
	  NUMERO_IFE                    = numero_ife,         -- 93 * NUM. IFE
	  NUMERO_SERIE_FIRMA            = isnull(num_serie_firma,''),                 -- 94 * NUMERO DE SERIE DE FIRMA ELECTRONICA
	  TELEFONO_FIJO                 = @w_telefono_fijo,   -- 95 * NUMERO DE TELEFONO FIJO
	  TELEFONO_CELULAR              = @w_telefono_celular,-- 96 * NUMERO DE TELEFONO CELULAR
      TELEFONO_RECADO               = telefono_recado,    -- 97 * NUMERO DE TELEFONO PARA RECADOS
	  NOMBRE_PERSONA_RECADO         = upper(nombre_persona_recado),-- 98 * NOMBRE DE PERSONA PARA RECADOS
	  CTA_EN_BURO_CREDITO           = ltrim(cta_en_buro_credito),  -- 99 * CUENTA CON ANTECEDENTES EN BURO
	  NOMBRE_ASESOR                 = upper(isnull(desc_oficial,'')),--100 * NOMBRE DEL ASESOR
	  NOMBRE_COORDINADOR            = upper(isnull(nombre_coordinador,'')),   --101 * NOMBRE DEL COORDINADOR O GERENTE
	  NOMBRE_ANALISTA               = upper(isnull(nombre_analista,'')), --102 * NOMBRE DEL ANALISTA ADMINISTRATIVO
	  TIPO_DIRECCION                = tipo_direccion,     --103 * TIPO DE DIRECCION VIRTUAL
      CORREO_ELECTRONICO            = direccion_correo,   --104 * DIRECCION DE CORREO ELECTRONICO
      TIENE_CRED_GRUPAL             = tiene_cred_grupal
	  from #datos_cliente
   end
   
end
else if @i_operacion = 'DI'     --Seccion de Direcciones y Correos Electronicos
begin
   --print 'Seccion de Direcciones y Correos Electronicos'
     select 
   cod_direccion      = di_direccion,
   di_tipo            = di_tipo,	
   desc_tipo          = convert(varchar(65), null),
   cod_pais           = di_pais,
   pais               = convert(varchar(65), null),
   cod_provincia      = di_provincia,
   provincia          = convert(varchar(65), null),
   cod_ciudad         = di_ciudad,
   ciudad             = convert(varchar(65), null),
   cod_parroquia      = di_parroquia,
   parroquia          = convert(varchar(65), null),
   direccion          = di_descripcion,
   calle              = di_calle,                                              
   barrio             = di_barrio,
   principal          = di_principal,
   correspondencia    = di_correspondencia,
   cod_departamento   = di_departamento,
   departamento       = convert(varchar(65), null),
   tiempo_residencia  = di_tiempo_reside,
   cod_barrio         = di_rural_urbano,
   latitud            = convert(float, null),
   longitud           = convert(float, null),
   id_codigo_barrio   = di_codbarrio,
   nro_calle          = di_nro,                                               
   cod_postal         = di_codpostal,
   nro_residentes     = '',--di_nro_residentes,
   nro_calle_interno  = '',--di_nro_interno,                                        
   meses_vigencia     = convert(int, null),
   cod_negocio        = '',--di_negocio,
   cod_tipo_vivienda  = convert(varchar(10), null),
   tipo_vivienda      = convert(varchar(65), null),
   ciudad_poblacion   = '',--di_poblacion,
   referencia_domi    = convert(varchar(255), null)
   into #datos_direcciones
   from cobis..cl_direccion
   where 1=2   
   
      if @i_tipo_dir = 'F'
   begin
      insert into #datos_direcciones
      select 
      cod_direccion      = di_direccion,
      di_tipo            = di_tipo,
      desc_tipo          = (select b.valor
      			            from cobis..cl_tabla a, cobis..cl_catalogo b
      			            where a.tabla  = 'cl_tdireccion'
      			            and a.codigo = b.tabla
      			            and b.codigo = convert(varchar(10),c.di_tipo)),
      cod_pais           = di_pais,
      pais               = (select pa_descripcion from cobis..cl_pais where pa_pais = c.di_pais),
      cod_provincia      = c.di_provincia,
      provincia          = (select pv_descripcion
                            from cobis..cl_provincia
                            where pv_provincia = c.di_provincia),
      cod_ciudad         = di_ciudad,
      ciudad             = (select  b.valor
      			            from cobis..cl_tabla a, cobis..cl_catalogo b
      			            where a.tabla  = 'cl_ciudad'
      			            and a.codigo = b.tabla
      			            and convert(int, b.codigo) = c.di_ciudad),
      cod_parroquia      = di_parroquia,
      parroquia          = (select b.valor
      			            from cobis..cl_tabla a, cobis..cl_catalogo b
      			            where a.tabla  = 'cl_parroquia'
      			            and a.codigo = b.tabla
      			            and b.codigo = convert(varchar(10),c.di_parroquia)),
      direccion          = di_descripcion,
      calle              = di_calle,                                              
      barrio             = di_barrio,
      principal          = di_principal,
      correspondencia    = di_correspondencia,
      cod_departamento   = di_departamento,
      departamento       = (select b.valor
                            from cobis..cl_tabla a, cobis..cl_catalogo b
      		                where a.tabla  = 'cl_depart_pais'
      			            and a.codigo = b.tabla
      			            and b.codigo = convert(varchar(10),c.di_departamento)),
      tiempo_residencia  = di_tiempo_reside,
      cod_barrio         = di_rural_urbano,
      latitud            = (select dg_lat_seg from cobis..cl_direccion_geo where dg_ente = c.di_ente and dg_direccion = c.di_direccion),
      longitud           = (select dg_long_seg from cobis..cl_direccion_geo where dg_ente = c.di_ente and dg_direccion = c.di_direccion),
      id_codigo_barrio   = di_codbarrio,
      nro_calle          = di_nro,                                               
      cod_postal         = di_codpostal,
      nro_residentes     = '',--di_nro_residentes,
      nro_calle_interno  = '',--di_nro_interno,
      meses_vigencia     =(datediff(mm, c.di_fecha_modificacion, @w_fecha_proceso)),
      cod_negocio        = '',--di_negocio,
	  cod_tipo_vivienda  = rtrim(di_tipo_prop),
      tipo_vivienda      = (select b.valor
                            from cobis..cl_tabla a, cobis..cl_catalogo b
      		                where a.tabla  = 'cl_tpropiedad'
      			            and a.codigo = b.tabla
      			            and b.codigo = rtrim(c.di_tipo_prop)),
      ciudad_poblacion   = '',--snull(di_poblacion,''),
	  referencia_domi    = ''--di_referencia
      from cobis..cl_direccion c
      where di_ente = @i_ente
	  and   di_tipo <> 'CE'
      and   di_tipo = isnull(@i_tipo, di_tipo)	  
   end 
   else if @i_tipo_dir = 'V'
   begin
      insert into #datos_direcciones
      select 
      cod_direccion      = di_direccion,
      di_tipo            = di_tipo,
      desc_tipo          = 'CORREO ELECTRONICO',
      cod_pais           = di_pais,
      pais               = NULL,
      cod_provincia      = c.di_provincia,
      provincia          = NULL,
      cod_ciudad         = di_ciudad,
      ciudad             = NULL,
      cod_parroquia      = di_parroquia,
      parroquia          = NULL,
      direccion          = di_descripcion,
      calle              = di_calle,                                              
      barrio             = di_barrio,
      principal          = di_principal,
      correspondencia    = di_correspondencia,
      cod_departamento   = di_departamento,
      departamento       = NULL,
      tiempo_residencia  = di_tiempo_reside,
      cod_barrio         = di_rural_urbano,
      latitud            = NULL,
      longitud           = NULL,
      id_codigo_barrio   = di_codbarrio,
      nro_calle          = di_nro,                                                
      cod_postal         = di_codpostal,
      nro_residentes     = '',--di_nro_residentes,
      nro_calle_interno  = '',--di_nro_interno,
      meses_vigencia     =(datediff(mm, c.di_fecha_modificacion, @w_fecha_proceso)),
      cod_negocio        = '',--di_negocio,
	  cod_tipo_vivienda  = rtrim(di_tipo_prop),
      tipo_vivienda      = (select b.valor
                            from cobis..cl_tabla a, cobis..cl_catalogo b
      		                where a.tabla  = 'cl_tpropiedad'
      			            and a.codigo = b.tabla
      			            and b.codigo = rtrim(c.di_tipo_prop)),
      ciudad_poblacion   = '',--isnull(di_poblacion,'')
      referencia_domi    = ''--di_referencia
      from cobis..cl_direccion c
      where di_ente = @i_ente
	  and   di_tipo = 'CE' 
   end
   
   set rowcount 1
   
      select 
   'COD_DIRECCION'    = cod_direccion,           --1
   'COD_TIPO'         = di_tipo,                 --2
   'TIPO'             = upper(isnull(desc_tipo,'')),               --3
   'COD_PAIS'         = cod_pais,                --4  
   'PAIS'             = upper(isnull(pais,'')),                    --5  * PAIS
   'COD_PROVINCIA'    = cod_provincia,           --6
   'PROVINCIA'        = upper(isnull(provincia,'')),               --7  * ESTADO/PROVINCIA
   'COD_CIUDAD'       = cod_ciudad,              --8
   'CIUDAD'           = upper(isnull(ciudad,'')),                  --9  * MUNICIPIO/DELEGACION
   'COD_PAQRROQUIA'   = cod_parroquia,           --10
   'PARROQUIA'        = upper(isnull(parroquia,'')),               --11 * COLONIA
   'DIRECCION'        = upper(isnull(direccion,'')),               --12 * CORREO ELECTRONICO
   'CALLE'            = upper(isnull(calle,'')),                   --13 * DIRECCIÓN (CALLE)
   'BARRIO'           = upper(isnull(barrio,'')),                  --14 
   'PRINCIPAL'        = principal,               --15
   'CORRESPONDENCIA'  = correspondencia,         --16 
   'COD_DEPARTAMENTO' = cod_departamento,        --17
   'DEPARTAMENTO'     = departamento,            --18
   'TIEMPO_RESIDENCIA'= tiempo_residencia,       --19 * ARRAIGO EN EL DOMICILIO
   'COD_BARRIO'       = cod_barrio,              --20
   'LATITUD'          = latitud,                 --21
   'LONGITUD'         = longitud,                --22
   'ID_CODIGO_BARRIO' = id_codigo_barrio,        --23
   'NRO_CALLE'   	  = nro_calle,               --24 * NUM. EXT
   'COD_POSTAL'	      = isnull(cod_postal,''),   --25 * CODIGO POSTAL
   'NRO_RESIDENTES'   = nro_residentes,          --26 * NO. DE PERSONAS VIVIENDO EN ESTE DOMICILIO
   'NRO_CALLE_INTER'  = '',/*(case when nro_calle_interno = -1    --27 * NUM. INT 
                            then null
                        else
                            nro_calle_interno
						end),*/
   'MESES_VIGENCIA'   = meses_vigencia,          --28
   'COD_NEGOCIO'      = cod_negocio,             --29
   'TIPO_VIVIENDA'    = tipo_vivienda,           --30 * TIPO DE VIVIENDA
   'CIUDAD_POBLACION' = ciudad_poblacion,        --31 
   'COD_TIPO_VIVIENDA'= cod_tipo_vivienda,        --30 * CODIGO DE TIPO DE VIVIENDA
   'REFERENCIA_DOMI'  = referencia_domi
   from  #datos_direcciones
   order by cod_direccion
   
   set rowcount 0
   	  
end
else if @i_operacion = 'NC'     --Seccion de Negocios del Cliente
begin
   --print 'Seccion de Negocios del Cliente'
   select top 1 
   @w_direccion = di_direccion 
   from cobis..cl_direccion 
   where di_ente = @i_ente
   and di_tipo = 'AE'
   order by di_direccion

   select top 1 
   @w_telefono_aux = te_valor, 
   @w_telefono_id  = te_secuencial
   from  cobis..cl_telefono 
   where te_ente = @i_ente 
   and   te_direccion = @w_direccion
   and   te_tipo_telefono = 'D'
   
    if len(isnull(@w_telefono_aux, '')) > 9
   begin
      select @w_len = len(@w_telefono_aux) - 9
	  select @w_cod_area = 1,--,substring(@w_telefono_aux, 0, @w_len), 
	         @w_telefono_aux = ''--right(@w_telefono_aux, 10)
   end
   
      select 
   codigo               = nc_codigo, 
   negocio              = nc_nombre,
   giro                 = nc_giro,
   desc_giro            = convert(varchar(64), null),
   fecha_apertura       = convert(varchar(10), nc_fecha_apertura, @i_formato),
   destino_credito      = nc_destino_credito,
   desc_destino_credito = convert(varchar(64), null),
   direccion            = convert(varchar(64), null),
   numero               = nc_nro,
   colonia              = convert(varchar(64), null),
   localidad            = nc_localidad,
   municipio            = convert(varchar(64), null),   
   cod_estado           = convert(varchar(64), null),
   desc_estado          = convert(varchar(64), null),
   cod_postal           = convert(varchar(64), null),
   cod_pais             = nc_pais,
   desc_pais            = convert(varchar(64), null),
   telefono             = @w_telefono_aux,
   tiempo_actividad     = nc_tiempo_actividad,
   tiempo_arraigo       = nc_tiempo_dom_neg,
   tipo_recurso         = nc_recurso,
   desc_tipo_recurso    = convert(varchar(64), null),
   ingreso_mensual      = nc_ingreso_mensual,
   tipo_local           = nc_tipo_local,
   desc_tipo_local      = convert(varchar(64), null),
   cod_actividad        = nc_actividad_ec,
   desc_actividad       = convert(varchar(64), null),
   numero_externo       = convert(int, null),
   numero_interno       = convert(int, null),
   direccion_cod        = @w_direccion
   into #datos_negocio
   from cobis..cl_negocio_cliente
   where nc_ente =  @i_ente
   and   nc_codigo > isnull(@i_cod_neg, 0)
   and   nc_estado_reg = 'V'
   
   --Descripcion del Destino Economico   
   update #datos_negocio
   set   desc_giro = ac_descripcion
   from  cobis..cl_actividad_ec
   where cod_actividad = ac_codigo
      
   --Descripcion del Destino Economico
   update #datos_negocio
   set   desc_destino_credito = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where destino_credito = c.codigo
   and c.tabla = t.codigo
   and t.tabla = 'cl_destino_credito'   
   
   --Descripcion del Estado o Provincia
   /*update #datos_negocio
   set   desc_estado = pv_descripcion
   from cobis..cl_provincia  
   where pv_provincia = cod_estado*/--validatejj
   
   /*update #datos_negocio
   set c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where cod_estado = convert(int, c.codigo)
   and c.tabla = t.codigo
   and t.tabla = 'cl_provincia' */
      --Descripcion del Pais
   /*update #datos_negocio
   set   desc_pais = pa_descripcion
   from  cobis..cl_pais
   where pa_pais = cod_pais*/--validatejj

   --Descripcion del Tipo de Local   
   update #datos_negocio
   set   desc_tipo_local = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where tipo_local = c.codigo
   and c.tabla = t.codigo
   and t.tabla = 'cr_tipo_local'

   --Descripcion del Tipo de Recurso   
   update #datos_negocio
   set   desc_tipo_recurso = c.valor
   from  cobis..cl_catalogo c, 
         cobis..cl_tabla t
   where tipo_recurso = c.codigo
   and c.tabla = t.codigo
   and t.tabla = 'cl_recursos_credito'
   
   --Descripcion de la Actividad Economica
   update #datos_negocio
   set   desc_actividad = ac_descripcion
   from  cobis..cl_actividad_ec
   where cod_actividad = ac_codigo
   
      -- Direccion del negocio
   update #datos_negocio   
   set   direccion      = di_calle,
         numero_externo = 1,--di_nro,
		 numero_interno = 1,--di_nro_interno,
		 colonia        = (select  b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                    where a.tabla  = 'cl_parroquia'
                                      and a.codigo = b.tabla
                                      and b.codigo = convert(varchar(10),c.di_parroquia)),
		 desc_estado    = (select pv_descripcion
                           from cobis..cl_provincia
                           where pv_provincia = c.di_provincia),                                      
		 municipio      = (select  b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                    where a.tabla  = 'cl_ciudad'
                                      and a.codigo = b.tabla
                                      and convert(INT, b.codigo) = c.di_ciudad),
         desc_pais      = (select pa_descripcion FROM cobis..cl_pais WHERE pa_pais = c.di_pais ),
		 cod_postal     = di_codpostal
   from  cobis..cl_direccion c
   where di_ente = @i_ente 
   and   di_direccion = direccion_cod
    select 
   'NEGOCIO'              = upper(isnull(negocio,'')),
   'GIRO'                 = upper(isnull(desc_giro, '')),
   'FECHA_APERTURA'       = fecha_apertura,
   'DESTINO_CREDITO'      = destino_credito,
   'DESC_DESTINO_CREDITO' = desc_destino_credito,
   'DIRECCION'            = upper(isnull(direccion,'')),
   'NUMERO'               = numero,
   'COLONIA'              = upper(isnull(colonia,'')),
   'LOCALIDAD'            = upper(isnull(localidad,'')),
   'MUNICIPIO'            = upper(isnull(municipio,'')),    
   'COD_ESTADO'           = cod_estado,
   'DESC_ESTADO'          = upper(isnull(desc_estado,'')), 
   'COD_POSTAL'           = cod_postal,
   'COD_PAIS'             = cod_pais,
   'DESC_PAIS'            = upper(isnull(desc_pais,'')),
   'TELEFONO'             = isnull(telefono,''),
   'TIEMPO_ACTIVIDAD'     = '',--(select valor from cobis..cl_catalogo where codigo = convert(varchar,tiempo_actividad) and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_referencia_tiempo')),
   'TIEMPO_ARRAIGO'       = '',--(select valor from cobis..cl_catalogo where codigo = convert(varchar,tiempo_arraigo) and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_referencia_tiempo')),
   'TIPO_RECURSO'         = tipo_recurso,
   'DESC_TIPO_RECURSO'    = upper(isnull(desc_tipo_recurso,'')),
   'INGRESO_MENSUAL'      = ingreso_mensual,
   'TIPO_LOCAL'           = tipo_local,
   'DESC_TIPO_LOCAL'      = upper(isnull(desc_tipo_local,'')),
   'COD_ACTIVIDAD'        = cod_actividad,
   'DESC_ACTIVIDAD'       = upper(isnull(desc_actividad,'')),
   'NUMERO_EXTERNO'       = numero_externo,
   'NUMERO_INTERNO'       = (case when numero_interno = -1
                                then null
                            else
                                numero_interno
						    end)
   from #datos_negocio
   order by codigo
   
end
else if @i_operacion = 'RP'     --Seccion de Referencias Personales del Cliente
begin
   --print 'Seccion de Referencias Personales del Cliente'
   
   select
   'NUMERO'                = rp_referencia,
   'NOMBRE'                = upper(isnull(rp_nombre,'')),
   'PRIMER_APELLIDO'       = case 
                             when charindex(' ',rp_p_apellido) < 1
                             then
                                upper(isnull(rp_p_apellido,''))
                             else
                                left(rp_p_apellido, charindex(' ',rp_p_apellido)-1)
                             end,   
   'SEGUNDO_APELLIDO2'     = case 
                             when charindex(' ',rp_p_apellido) < 1
                             then
                                ''
                             else
                                upper(right(rp_p_apellido, len(rp_p_apellido)-charindex(' ',rp_p_apellido)))
                             end,
   'DIRECCION'             = upper(substring(isnull(rp_direccion,''),1,32)),
   'TELEFONO_DOMICILIO'    = RTRIM(rp_telefono_d),
   'TELEFONO_CELULAR'      = isnull(rp_telefono_e,''),
   'TELEFONO_OFICINA'      = isnull(rp_telefono_o,''),
   'OBSERVACIONES'         = isnull(rp_descripcion,''),
   'FECHA_REGISTRO'        = convert(varchar(10), rp_fecha_registro, @i_formato),
   'FECHA_ULT_MODIF'       = convert(varchar(10), rp_fecha_modificacion, @i_formato),
   'VIGENTE'               = rp_vigencia,
   'VERIF.'                = rp_verificacion,
   'DEPARTAMENTO'          = '',--upper(isnull(rp_departamento,'')),
   'CIUDAD'                = 0,--upper(isnull(rp_ciudad,'')),
   'BARRIO'                = 0,--upper(isnull(rp_barrio,'')),
   'OBS.VERIFICADO'        = '',--upper(isnull(rp_obs_verificado,'')),
   'CALLE'                 = upper(isnull(rp_calle,'')),
   'NRO'                   = rp_nro,
   'COLONIA'               = '',--upper(isnull(rp_colonia,'')),
   'LOCALIDAD'             = '',--upper(isnull(rp_localidad,'')),
   'MUNICIPIO'             = '',--upper(isnull(rp_municipio,'')),
   'CODESTADO'             = '',--rp_estado,
   'CODPOSTAL'             = isnull(rp_codpostal,''),
   'CODPAIS'               = rp_pais,
   'TIEMPO_CONOCIDO'       = rp_tiempo_conocido,
   'CORREO'                = isnull(rp_direccion_e,'')
   from  cobis..cl_ref_personal
   where rp_persona = @i_ente   
      
end
else if @i_operacion = 'RC'     --Seccion de Relaciones del Cliente
begin
   --print 'Seccion de Relaciones del Cliente'
   select @w_ente_i = @i_ente, @w_ente_d = @i_ente_d
   
   set rowcount 20
   
   if @i_modo = 0
   begin
      select
      'RELACION' = in_relacion,
      'REL_IZQ'  = substring(convert (char(64), re_izquierda), 1, 25),
      'REL_DER'  = substring(convert (char(64), re_derecha), 1, 25),
      'LADO'     = in_lado,
      'COD_CLI'  = in_ente_d,
      'CLIENTE'  = substring(convert (char(64), en_nomlar), 1, 25)
      from cobis..cl_relacion,
	       cobis..cl_instancia,
	       cobis..cl_ente
      where in_ente_i = @w_ente_i
      and in_relacion = re_relacion
      and in_ente_d   = en_ente
      order by in_relacion, in_ente_d
   end
   else if @i_modo = 1
   begin
      select
      'RELACION' = in_relacion,
      'REL_IZQ'  = substring(convert (char(64), re_izquierda), 1, 25),
      'REL_DER'  = substring(convert (char(64), re_derecha), 1, 25),
      'LADO'     = in_lado,
      'COD_CLI'  = in_ente_d,
      'CLIENTE'  = substring(convert (char(64), en_nomlar), 1, 25)
      from cobis..cl_relacion,
	       cobis..cl_instancia,
	       cobis..cl_ente
      where in_ente_i = @w_ente_i
      and in_relacion = re_relacion
      and in_ente_d   = en_ente
      and ((in_relacion > @i_relacion) or 
	       (in_relacion = @i_relacion and in_ente_d > @w_ente_d))
      order by in_relacion, in_ente_d   
   end
   
   set rowcount 0
end


return 0


ERROR:


exec @w_return = cobis..sp_cerror
@t_debug = 'N',
@t_file   = '',
@t_from   = @w_sp_name,
@i_num    = @w_error

return @w_error

GO
