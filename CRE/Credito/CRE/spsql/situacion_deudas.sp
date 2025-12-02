/************************************************************************/
/*  Archivo:                situacion_deudas.sp                         */
/*  Stored procedure:       sp_situacion_deudas                         */
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

if exists(select 1 from sysobjects where name ='sp_situacion_deudas')
    drop proc sp_situacion_deudas
go


create proc sp_situacion_deudas(									 
										
															   
    @s_ssn	              int     = null,
    @s_user		          login   = null,
    @s_sesn               int    = null,
    @s_term               descripcion = null,
    @s_date               datetime = null,
    @s_srv		          varchar(30) = null,
    @s_lsrv	  	          varchar(30) = null,
    @s_rol		          smallint = null,
    @s_ofi                smallint  = null,
    @s_org_err		      char(1) = null,
    @s_error		      int = null,
    @s_sev		          tinyint = null,
    @s_msg		          descripcion = null,
    @t_file               varchar(14) = null,
    @t_show_version       bit = 0,
    @i_tipo_deuda         char(1) = 'D',		
    @i_limite	          char(1) = null,
    @i_aprobado           char(1) = null,
    @i_tramite            int     = null,
    @i_cliente            int     = null,
    @i_grupo              int     = null,
    @i_impresion          char(1) = 'S',
    @i_formato_fecha      int     = 111,
    @i_act_can            char(1) = 'N' -- Activos (N) y Cancelados + Activos (S)
  ) 
as
declare
   @w_sp_name		 varchar(32),    
   @w_def_moneda	 tinyint,
   @w_riesgo		 money,
   @w_fecha		 datetime,
   @w_est_vencido        tinyint,
   @w_est_nvigente       tinyint,
   @w_est_cancelado	 tinyint,
   @w_est_precancelado	 tinyint,
   @w_est_credito	 tinyint,
   @w_est_anulado        tinyint,
   @w_est_cex	         tinyint,
   @w_est_castigado	 tinyint, 
   @w_est_novigente	 tinyint,
   @w_est_vigente	 tinyint,
   @w_saldo_vencido      money,
   @w_saldo_x_vencer     money,
   @w_secuencia          int,
   @w_cartera_pv	 money,
   @w_tipo_riesgo	 varchar(12),
   @w_estado		 varchar(30),
   @w_moneda		 tinyint,
   @w_etapa		 varchar(3),
   @w_tramite		 int,
   @w_toperacion	 catalogo,
   @w_fecha_ult          datetime,
   @w_tabla_calif        int,			
   @w_tipo_personal      catalogo,		
   @w_seguro             char(1),               
   @w_fecha_embarque     descripcion,		
   @w_operacion_int      int,
   @w_cancelada          catalogo,               
   @w_tipo_garantia      catalogo,               
   @w_descrip_gar        catalogo,               
   @w_error              int,
   @w_spid               smallint, 
   @w_spidCur            smallint,
   @w_tipo_dividendo_cat int,
   @w_estado_garantia    varchar(64),
   @w_estado_cartera     varchar(64),
   @w_ced_ruc_cliente    varchar(30),
   @w_motivo_rechazo     int,
   @w_tipo_grupo		 	varchar(5), --SRO G. Solidario
   @w_tg_tramite			int, --SRO G. Solidario
   @w_tramite_individual    int,
   @w_porcentaje			money,
   @w_saldo_capital			money,
   @w_total					money,
   @w_dc_ciclo_grupo        int

select @w_sp_name = 'sp_situacion_deudas',
	@t_file    = 'situacion_deudas.sp'

if @t_show_version = 1
begin
    print 'Stored procedure sp_situacion_deudas, Version 4.0.0.6'
    return 0
end

-- Obtengo numero de proceso 
select @w_spid = @@SPID

PRINT 'Numero proceso ' + convert(VARCHAR, @w_spid)

delete from cr_cotiz3_tmp          where spid = @w_spid --tabla de cotizaciones
delete from cr_ope1_tmp            where spid = @w_spid 
--PQU 05/03/2021 delete from cr_temp4_tmp           where spid = @w_spid  
   
-- Cargo Moneda Local
select @w_def_moneda = pa_tinyint  
from   cobis..cl_parametro
where  pa_nemonico = 'MLOCR'   

if @@rowcount = 0
begin   /*Registro no existe */
   select @w_error = 2101005
   goto ERROR
end

-- Cargo fecha de proceso
select @w_fecha = fp_fecha
from cobis..ba_fecha_proceso

exec sp_dia_habil
     @i_fecha  = @w_fecha,
     @o_fecha  = @w_fecha_ult out

select @w_fecha_ult = isnull( @w_fecha_ult, @w_fecha)

-- CREACION DE TABLA TEMPORAL DE COTIZACIONES 

insert into cr_cotiz3_tmp  (spid, moneda, cotizacion)
select	@w_spid, a.ct_moneda, a.ct_compra
from   cob_credito..cb_cotizaciones a

-- Insertar un registro para moneda local en caso de no existir
if not exists(select * from cr_cotiz3_tmp where moneda = @w_def_moneda and spid = @w_spid)
insert into cr_cotiz3_tmp (spid, moneda, cotizacion)
values (@w_spid, @w_def_moneda, 1)

-- Cargo parametros
select @w_est_precancelado = pa_tinyint  
from cobis..cl_parametro  
where pa_nemonico = 'ESTPRE' 
and pa_producto = 'CRE'

select @w_est_credito = pa_tinyint  
from cobis..cl_parametro  
where pa_nemonico = 'ESTCRE'
and pa_producto = 'CRE'

select @w_est_cancelado = pa_tinyint  
from cobis..cl_parametro  
where pa_nemonico = 'ESTCAN'
and pa_producto = 'CRE'

select @w_est_anulado = pa_tinyint  
from cobis..cl_parametro  
where pa_nemonico = 'ESTANU'
and pa_producto = 'CRE'

select @w_est_vencido = pa_tinyint  
from cobis..cl_parametro 
where pa_nemonico = 'ESTVEN'
and pa_producto = 'CRE'

select @w_est_vigente = pa_tinyint  
from cobis..cl_parametro 
where pa_nemonico = 'ESTVG'
and pa_producto = 'CRE'

select @w_est_nvigente = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'ESTNVG'
and pa_producto = 'CRE'

select @w_cancelada = pa_char
from cobis..cl_parametro 
where pa_producto = 'CRE'
  and pa_nemonico = 'ECANLN'

select 	@w_est_cex = 98,
	@w_est_castigado = 4,
	@w_est_novigente = 0

-- Codigo de catalogo: ca_tdividendo
select @w_tipo_dividendo_cat = codigo
from   cobis..cl_tabla 
where  tabla = 'ca_tdividendo'	

-- Codigo de catalogo: cr_motivo_rechazo
select @w_motivo_rechazo = codigo 
from cobis..cl_tabla
where tabla = 'cr_motivo_rechazo'

--SRO.Inicio Grupo Solidario
select @w_tipo_grupo = gr_tipo
--from cobis..cl_grupo_view
from cobis..cl_grupo
where gr_grupo = @i_grupo
--SRO. Fin Grupo Solidario

-- Riesgos Directos
if @i_tipo_deuda = 'D' or @i_tipo_deuda = 'T'
BEGIN
   -- PRINT 'PQU Primer insert'	   
   insert into cr_ope1_tmp 
   (spid, cliente,   tramite,       numero_op,    
    numero_op_banco,    
    producto,   tipo_riesgo,  tipo_tr,   estado,     monto,        moneda,             toperacion,  usuario, 
    secuencia,  tipo_con,     cliente_con,  tramite_d, linea, mrc,  fecha_apt,
    anticipo,   rol)
   select distinct   
     @w_spid, sc_cliente_con, sc_tramite, case tr_tipo when 'R' then op_operacion else tr_numero_op end, 
                              case tr_tipo when 'R' then op_banco else tr_numero_op_banco end, 
     tr_producto, 'D',  tr_tipo,   tr_estado,  tr_monto,     tr_moneda,          tr_toperacion,  sc_usuario, 
     sc_secuencia, sc_tipo_con, sc_cliente_con,  tr_tramite, li_num_banco, 0, tr_fecha_crea, -- isnull(tr_fecha_apr, tr_fecha_crea), YPA 03/08/2015
     null,--tr_tram_anticipo,    
      de_rol
    from cr_tramite  LEFT JOIN cob_cartera..ca_operacion ON tr_tramite=op_tramite
   LEFT JOIN cr_linea ON tr_linea_credito =li_numero,
        cr_deudores, 
        cr_situacion_cliente
   where de_cliente = sc_cliente
     and tr_tipo in ('O', 'R', 'F')
     and (tr_estado != 'R'
     and tr_estado != 'Z')
     and de_tramite    = tr_tramite
     and sc_usuario    = @s_user
     and sc_secuencia  = @s_sesn
     and sc_tramite    = isnull( @i_tramite, 0)
     --PQU 02/03/2021 esto no aplica and tr_toperacion not in ( 'CCE', 'CDE', 'CDI', 'GRB')
     and sc_tipo_con not in ('G','S')
     and op_tramite not in (select tg_tramite from cob_credito..cr_tramite_grupal)--PQU _view)

   if @@error <> 0
   begin   /* Error en insercion de registro */
      select @w_error = 2103001
      goto ERROR
   end


    if @w_tipo_grupo = 'G'
    begin
   insert into cr_ope1_tmp 
											  
   (spid, cliente,   tramite,       numero_op,    
    numero_op_banco,    
    producto,   tipo_riesgo,  tipo_tr,   estado,     monto,        moneda,             toperacion,  usuario, 
    secuencia,  tipo_con,     cliente_con,  tramite_d, linea, mrc,  fecha_apt,
    anticipo) 
   select distinct   
    @w_spid, sc_cliente_con, sc_tramite, case tr_tipo when 'R' then op_operacion else tr_numero_op end, 
    case tr_tipo when 'R' then op_banco else tr_numero_op_banco end, 
  tr_producto, 'D',  tr_tipo,   tr_estado,  tr_monto,     tr_moneda,          tr_toperacion,  sc_usuario, 
    sc_secuencia, sc_tipo_con, sc_cliente_con,  tr_tramite, 
    (select li_num_banco from cr_linea where li_num_banco = A.op_lin_credito and li_grupo = C.cg_grupo), 
    0, tr_fecha_crea, --isnull(tr_fecha_apr, tr_fecha_crea), Y.Pacheco 03/08/2015
    null--tr_tram_anticipo 
   from cr_tramite,
        cr_deudores, cob_cartera..ca_operacion A,
        cr_situacion_cliente,
        cobis..cl_cliente_grupo  C
   where de_cliente = sc_cliente
     and tr_tipo in ('O', 'R', 'F')
     and (tr_estado != 'R'
     and tr_estado != 'Z')
     and de_tramite    = tr_tramite
     and tr_tramite  = op_tramite
     and sc_usuario    = @s_user
     and sc_secuencia  = @s_sesn
     and sc_tramite    = isnull( @i_tramite, 0)
     --PQU 02/03/2021 esto no aplica --and tr_toperacion not in ( 'CCE', 'CDE', 'CDI', 'GRB')
     and sc_tipo_con = 'G'
     and cg_ente = sc_cliente
     and cg_grupo = @i_grupo
end
    else if @w_tipo_grupo = 'S'
    begin

        if @i_act_can = 'N'
        begin
            select @w_tg_tramite = max(tg_tramite)
              from cob_credito..cr_tramite_grupal,--PQU 03/03/2021 --_view,
                   cob_cartera..ca_operacion
             where tg_tramite = op_tramite
               and tg_grupo 	= @i_grupo
			and op_ref_grupal is null
			--and op_estado 	= @w_est_cancelado
			and op_estado not in (@w_est_nvigente,@w_est_credito)--PQU le quite el estado cancelado,@w_est_anulado

			--ERA obtencion del ciclo del grupo para interciclos
			select @w_dc_ciclo_grupo = dc_ciclo_grupo
			from cob_cartera..ca_operacion, cob_cartera..ca_det_ciclo
			where dc_referencia_grupal = op_banco
			and op_tramite = @w_tg_tramite
			AND dc_tciclo = 'I'
        end

        --PRINT 'PQU Segundo  insert'
        insert into cr_ope1_tmp
        (spid, cliente,   tramite,       numero_op,
            numero_op_banco,
            producto,   tipo_riesgo,  tipo_tr,   estado,     monto,        moneda,             toperacion,  usuario,
            secuencia,  tipo_con,     cliente_con,  tramite_d, linea, mrc,  fecha_apt
            --anticipo
            )
        select distinct
            @w_spid, sc_cliente_con, sc_tramite, case tr_tipo when 'R' then op_operacion else tr_numero_op end,
            case tr_tipo when 'R' then op_banco else tr_numero_op_banco end,
            tr_producto, 'D',  tr_tipo,   tr_estado,  tr_monto,     tr_moneda,          tr_toperacion,  sc_usuario,
            sc_secuencia, sc_tipo_con, sc_cliente_con,  tr_tramite,
            (select li_num_banco from cr_linea where li_num_banco = A.op_lin_credito and li_grupo = sc.sc_cliente),
            0, tr_fecha_crea --isnull(tr_fecha_apr, tr_fecha_crea), Y.Pacheco 03/08/2015
        -- tr_tram_anticipo
        from cr_tramite,
             cr_deudores, cob_cartera..ca_operacion A,
             cr_situacion_cliente sc
        where de_cliente      = sc_cliente
            and de_tramite    = tr_tramite
            and tr_tramite    = op_tramite
            and (tr_tramite	  = @w_tg_tramite or @i_act_can = 'S')
            and tr_tipo in ('O', 'R', 'F')
            and (tr_estado <> 'R'
            and tr_estado <> 'Z')
            and sc_tramite    = isnull(@i_tramite, 0)
            and sc_usuario    = @s_user
            and sc_secuencia  = @s_sesn
            and tr_toperacion not in ( 'CCE', 'CDE', 'CDI', 'GRB')
            and sc_tipo_con   = 'S'
            and tr_monto IS NOT NULL
            AND tr_numero_op_banco IS NOT null
            and sc_cliente_con = @i_grupo
            
            PRINT 'w_tg_tramite ' + convert(VARCHAR, @w_tg_tramite )
            PRINT '@i_act_can ' + convert(VARCHAR, @i_act_can )
            PRINT '@i_tramite ' + convert(VARCHAR, @i_tramite )
            PRINT '@i_grupo ' + convert(VARCHAR, @i_grupo )
            PRINT '@s_user ' + convert(VARCHAR, @s_user )
            PRINT '@s_sesn ' + convert(VARCHAR, @s_sesn )
            
         -- SELECT * FROM cr_ope1_tmp  --PQU temporal QUITAR  

		--INTERCICLOS
		--PRINT 'PQU Tercer insert'
		insert into cr_ope1_tmp
		(spid, cliente,   tramite,       numero_op,
		numero_op_banco,
		producto,   tipo_riesgo,  tipo_tr,   estado,     monto,        moneda,             toperacion,  usuario,
		secuencia,  tipo_con,     cliente_con,  tramite_d, linea, mrc,  fecha_apt
		--anticipo
		)
		select distinct
		@w_spid, sc_cliente_con, sc_tramite, case tr_tipo when 'R' then op_operacion else tr_numero_op end,
		case tr_tipo when 'R' then op_banco else tr_numero_op_banco end,
		tr_producto, 'D',  tr_tipo,   tr_estado,  tr_monto,     tr_moneda,          tr_toperacion,  sc_usuario,
		sc_secuencia, sc_tipo_con, sc_cliente_con,  tr_tramite,
		(select li_num_banco from cr_linea where li_num_banco = A.op_lin_credito and li_grupo = sc_cliente),
		0, tr_fecha_crea --isnull(tr_fecha_apr, tr_fecha_crea), Y.Pacheco 03/08/2015
		-- tr_tram_anticipo
		from cr_tramite,
		cr_deudores, cob_cartera..ca_operacion A, cob_cartera..ca_det_ciclo,
		cr_situacion_cliente
		where de_cliente      = sc_cliente
		and de_tramite    = tr_tramite
		and tr_tramite    = op_tramite
		and op_ref_grupal = dc_referencia_grupal
		and sc_cliente_con = dc_grupo
		--and (tr_tramite	  = @w_tg_tramite or @i_act_can = 'S')
		and tr_tipo in ('O', 'R', 'F')
		and (tr_estado <> 'R' and tr_estado <> 'Z')		
		--and sc_tramite    = isnull(@i_tramite, 0)
		and sc_usuario    = @s_user
		and sc_secuencia  = @s_sesn
		and tr_toperacion not in ( 'CCE', 'CDE', 'CDI', 'GRB')
		and sc_tipo_con   = 'S'
		and op_grupal = 'N'
		and tr_monto IS NOT NULL
		AND tr_numero_op_banco IS NOT null
		and sc_cliente_con = @i_grupo
		and dc_tciclo = 'I'
		and dc_ciclo_grupo = isnull(@w_dc_ciclo_grupo,0)

	   
    end
--comentado
   if @@error <> 0
   begin   /* Error en insercion de registro */
      select @w_error = 2103001
      goto ERROR
   end 

   if @i_act_can = 'S'
   begin
	/* Inicio Consulta solicitudes rechazadas*/
	select @w_ced_ruc_cliente = en_ced_ruc 
		from cobis..cl_ente where en_ente = @i_cliente

	delete cr_soli_rechazadas_tmp where spid = @w_spid

	insert into cr_soli_rechazadas_tmp (spid, numero_id, fecha_carga, numero_operacion, fecha_rechazo, motivo, usuario, modulo)
    select distinct @w_spid, sr_numero_id, sr_fecha_carga, sr_numero_operacion, sr_fecha_rechazo, sr_motivo, sr_usuario, 'MIGRADAS'
		from cob_credito..cr_solicitudes_rechazadas where sr_numero_id = @w_ced_ruc_cliente

	insert into cr_soli_rechazadas_tmp (spid, numero_id, fecha_carga, numero_operacion, fecha_rechazo, motivo, usuario, modulo)
	select  @w_spid, 
			'Trámite' = convert(varchar(10),A.tr_tramite), 
			'Fecha Solicitud' = convert(varchar,B.io_fecha_crea,@i_formato_fecha), 
			A.tr_numero_op_banco,
			'Fecha Rechazo' = convert(varchar,G.aa_fecha_fin,@i_formato_fecha),
            'Motivo de Rechazo' = (select C.valor
                                     from cobis..cl_catalogo C, cobis..cl_tabla D
                                    where C.tabla = D.codigo
                                     and  D.tabla = 'cr_motivo_rechazo'
                                     and C.codigo = E.tr_motivo_rechazo
                                     and E.tr_tramite = A.tr_tramite),
			'Responsable Rechazo' = (select fu_nombre
                                       from cobis..cl_funcionario
                                      where fu_login = I.us_login),
			A.tr_producto

	from cob_credito..cr_tramite  A,
         cob_workflow..wf_inst_proceso B, 
         cobis..cl_ente J,
         cob_credito..cr_tr_datos_adicionales E,
         cob_workflow..wf_inst_actividad F, 
         cob_workflow..wf_asig_actividad G, cob_workflow..wf_usuario I
	where A.tr_estado = 'Z'
	  and A.tr_tramite= B.io_campo_3
	  and A.tr_tramite  = E.tr_tramite
	  and B.io_campo_1 = J.en_ente 
	  and en_ente = @i_cliente
           and E.tr_tramite = A.tr_tramite
	  and F.ia_id_inst_proc = B.io_id_inst_proc
  	  and G.aa_id_inst_act = F.ia_id_inst_act
	  and G.aa_estado = 'COM'
	  and F.ia_id_inst_act = (select max(H.ia_id_inst_act) 
                                from cob_workflow..wf_inst_actividad H 
                               where H.ia_id_inst_proc = B.io_id_inst_proc 
                                 and H.ia_estado = 'COM')	  
	  and I.us_id_usuario = G.aa_id_destinatario 
      and A.tr_tramite >0

   if @@error != 0 
   begin   /* Error en insercion de registro */
      select @w_error = 2103001
      goto ERROR
   end 
	/* Fin Consulta solicitudes rechazadas*/
	end

END

/**  DEUDAS INDIRECTAS   **/
if @i_tipo_deuda = 'I' or @i_tipo_deuda = 'T'
BEGIN
--PRINT 'Inserta deudas indirectas'

   /** OBTIENE CODIGO DE GARANTIAS TIPO PERSONAL **/
   select @w_tipo_personal = pa_char
 from cobis..cl_parametro
    where pa_producto = 'GAR'
      and pa_nemonico = 'GARPER'					

   if @@rowcount = 0
   begin      /*Registro no existe */
       select @w_error = 2101005
       goto ERROR
   end

   if @i_act_can = 'S' 
      select @w_estado_garantia = 'A'
   else if @i_act_can = 'N' 
         select @w_estado_garantia= 'C,A'

 --PRINT 'PQU Cuarto insert'
   insert into cr_ope1_tmp
   (spid, cliente,   tramite,    numero_op,    numero_op_banco,    producto,   tipo_riesgo, 
    tipo_tr,   estado,     monto,        moneda,             toperacion,  usuario, 
    secuencia, tipo_con,   cliente_con,  tramite_d, linea, mrc,  fecha_apt,
    anticipo)  
   select distinct   
    @w_spid, sc_cliente_con, sc_tramite, tr_numero_op, tr_numero_op_banco, tr_producto, 'I', 
    tr_tipo,   tr_estado,  tr_monto,     tr_moneda,          tr_toperacion,  sc_usuario, 
    sc_secuencia, sc_tipo_con, sc_cliente_con,  tr_tramite, li_num_banco, 0, tr_fecha_crea, -- isnull(tr_fecha_apr, tr_fecha_crea),Y.Pacheco
    null --tr_tram_anticipo
   from cr_situacion_cliente,
        cr_gar_propuesta,
        cob_custodia..cu_custodia,
        cob_custodia..cu_tipo_custodia,
       cr_tramite LEFT JOIN cr_linea ON tr_linea_credito=li_numero
   where sc_usuario    = @s_user
    and  sc_secuencia  = @s_sesn
    and  sc_tramite    = isnull( @i_tramite, 0)
    and  cu_garante    = sc_cliente
    and  cu_tipo       = tc_tipo
    --PQU and  cu_estado    not in ( select @w_estado_garantia) or ((@i_act_can = 'S' and cu_estado in ('C','A')) or (@i_act_can = 'N' and cu_estado = 'V')) 
	and cu_estado not in ('C,A')  --PQU
    and  cu_tipo = @w_tipo_personal
    and  gp_garantia   = cu_codigo_externo
    and  gp_tramite    = tr_tramite																						  
    and  (tr_tipo != 'L' or (tr_tipo != 'L' and tr_toperacion not in ('SGC', 'VISA') ) ) 
    and  tr_tramite  not in (select distinct tramite_d from cr_ope1_tmp where spid = @w_spid)
    and  tr_toperacion not in ( 'CCE', 'CDE', 'CDI', 'GRB')
     and  sc_tipo_con not in ('G','S')

   if @@error != 0 
   begin       /* Error en insercion de registro */
       print 'aaaaaaaaaaa 3'
       select @w_error = 2103001
       goto ERROR
   end

   if @w_tipo_grupo = 'G'
   begin
   insert into cr_ope1_tmp 
   (spid, cliente,   tramite,    numero_op,    numero_op_banco,    producto,   tipo_riesgo, 
    tipo_tr,   estado,     monto,        moneda,             toperacion,  usuario, 
    secuencia, tipo_con,   cliente_con,  tramite_d, linea, mrc,  fecha_apt,
    anticipo)  
																						  
   select distinct   
    @w_spid, sc_cliente_con, sc_tramite, tr_numero_op, tr_numero_op_banco, tr_producto, 'I', 
    tr_tipo,   tr_estado,  tr_monto,     tr_moneda,          tr_toperacion,  sc_usuario, 
    sc_secuencia, sc_tipo_con, sc_cliente_con, tr_tramite, li_num_banco, 0, tr_fecha_crea, --isnull(tr_fecha_apr, tr_fecha_crea),Y.Pacheco
    null --tr_tram_anticipo
   from cr_situacion_cliente,
        cr_gar_propuesta,
        cob_custodia..cu_custodia,
        cob_custodia..cu_tipo_custodia,
        cr_tramite, 
        cr_linea,
        cobis..cl_cliente_grupo 
   where sc_usuario    = @s_user
    and  sc_secuencia  = @s_sesn
    and  sc_tramite    = isnull( @i_tramite, 0)
    and  cu_garante    = sc_cliente
    and  cu_tipo       = tc_tipo
    --PQU and  ((cu_estado     not in (select @w_estado_garantia)) or ((@i_act_can = 'S' and cu_estado in ('C','A')) or (@i_act_can = 'N' and cu_estado = 'V')))
	and cu_estado not in ('C,A') --PQU
    and  tc_clase_garantia = @w_tipo_personal
    and  gp_garantia   = cu_codigo_externo
    and  gp_tramite    = tr_tramite
    and  tr_linea_credito = li_numero		
    and  (tr_tipo <> 'L' or (tr_tipo <> 'L' and tr_toperacion not in ('SGC', 'VISA') ) ) 
    and  tr_tramite  not in (select distinct tramite_d from cr_ope1_tmp where spid = @w_spid) 
    and  tr_toperacion not in ( 'CCE', 'CDE', 'CDI', 'GRB')
    and sc_tipo_con = 'G'
    and cg_ente = sc_cliente
    and cg_grupo = @i_grupo
    and li_grupo = cg_grupo
    end
    else if  @w_tipo_grupo = 'S'
    BEGIN
    --PRINT 'PQU Quinto insert'
        insert into cr_ope1_tmp
        (spid, cliente,   tramite,    numero_op,    numero_op_banco,    producto,   tipo_riesgo,
        tipo_tr,   estado,     monto,        moneda,             toperacion,  usuario,
        secuencia, tipo_con,   cliente_con,  tramite_d, linea, mrc,  fecha_apt
        --anticipo
        )
        select distinct
        @w_spid, sc_cliente_con, sc_tramite, op_operacion, op_banco, tr_producto, 'I',
        tr_tipo,   tr_estado,  tr_monto,     tr_moneda,          tr_toperacion,  sc_usuario,
        sc_secuencia, sc_tipo_con, sc_cliente_con, tr_tramite, tr_numero_op_banco, 0, tr_fecha_crea --isnull(tr_fecha_apr, tr_fecha_crea),Y.Pacheco
        --   tr_tram_anticipo
        from cr_situacion_cliente,
             cr_gar_propuesta,
             cob_custodia..cu_custodia,
             cob_custodia..cu_tipo_custodia,
             cr_tramite,
             cobis..cl_cliente_grupo,
             cob_cartera..ca_operacion
        where  sc_cliente   = cu_garante
        and  cu_tipo        = tc_tipo
        and  gp_garantia    = cu_codigo_externo
        and  tr_tramite     = op_tramite
        and  gp_tramite     = tr_tramite
        and  sc_usuario     = @s_user
        and  sc_secuencia   = @s_sesn
        and  sc_tramite     = isnull( @i_tramite, 0)
        --PQU and  cu_estado    not in (select @w_estado_garantia) --('C','A')
		and  cu_estado    not in ('C','A') --PQU
        and  cu_tipo        = @w_tipo_personal
        and  (tr_tipo <> 'L' or (tr_tipo <> 'L' and tr_toperacion not in ('SGC', 'VISA') ) )
        and  tr_tramite  not in (select distinct tramite_d from cr_ope1_tmp where spid = @w_spid)
        and  tr_toperacion not in ( 'CCE', 'CDE', 'CDI', 'GRB')
        and sc_tipo_con = 'S'
        and cg_ente = sc_cliente
        and cg_grupo = @i_grupo


				
												 
   if @@error != 0 
   begin       /* Error en insercion de registro */
   print 'aaaaaaaaaaa 4'
       select @w_error = 2103001
       goto ERROR
   end
  end
END

-- Actualizo tipo y plazo si ya tiene número de operación
update cr_ope1_tmp  
set  opestado  = op_estado,
     monto_des = op_monto,
     tipoop    = op_tipo,
     plazo     = op_plazo,
     frecuencia_pago = op_tplazo
from cob_cartera..ca_operacion 
where numero_op = op_operacion
and   spid      = @w_spid 

--Actualizo plazo y tipo de plazo si no se tiene número de operación
update cr_ope1_tmp  
set    plazo           = o.tr_plazo,
       frecuencia_pago = o.tr_frec_pago,
	   monto           = o.tr_monto
from   cob_credito..cr_tramite o,  cr_ope1_tmp t
where  t.tramite_d = o.tr_tramite 
and    t.numero_op is null
and    spid      = @w_spid 

--Actualizo el motivo del credito para indirectos
update cr_ope1_tmp  
set    motivo_credito = (select max(isnull(a.tr_destino_descripcion,''))
							from cr_tr_datos_adicionales a
							where a.tr_tramite = t.tramite_d)
from cob_credito..cr_tramite o,cr_ope1_tmp t
where t.tramite_d = o.tr_tramite 
and   spid      = @w_spid 

update cr_ope1_tmp 
set tipoop = 'N'
where tipoop is null
and   spid   = @w_spid 

-- Inserto Operaciones de CCA

if @i_act_can = 'S' 
begin
    select @w_estado_cartera=  convert(varchar,@w_est_credito )+ ',' +  convert(varchar,@w_est_anulado) + ','+ 
            convert(varchar,@w_est_cex )+ ',' + convert(varchar,@w_est_novigente)
end
else if @i_act_can = 'N' 
begin
         select @w_estado_cartera=  convert(varchar,@w_est_credito )+ ',' +  convert(varchar,@w_est_anulado) + ','+ 
                     convert(varchar,@w_est_cancelado )+ ','+ convert(varchar,@w_est_cex )+ ',' +
                                    convert(varchar,@w_est_novigente)
end

PRINT  'Estado cartera' + @w_estado_cartera

--PRINT 'Tipo grupo ' + @w_tipo_grupo
--ERA Aumento seccion para Grupo Solidario con ciclo
PRINT 'PQU Tipo grupo ' + @w_tipo_grupo
if @w_tipo_grupo = 'S'
begin 
PRINT 'PQU inserta a situacion deudas para grupo solidario'
	insert into  cr_situacion_deudas
	(sd_cliente,            sd_usuario,           sd_tramite,
	 sd_secuencia,          sd_tipo_con,          sd_cliente_con,
	 sd_identico,           sd_tipo_op,           sd_fecha_apr,
	 sd_fecha_vct,          sd_moneda,            sd_tramite_d,
	 sd_operacion,          sd_numero_operacion,  sd_categoria, --15
	 sd_desc_categoria,
	 sd_producto,           
	 sd_desc_tipo_op,
	 sd_tasa,
	 sd_tipoop_car, --20
	 sd_monto_orig,
	 sd_saldo_vencido,
	 sd_total_cargos, --Saldo Capital
	 sd_contrato_act,  
	 sd_saldo_x_vencer, --25
	 sd_saldo_promedio, --Cuota Actual
	 sd_ult_fecha_pg,
	 sd_prox_pag_int,
	 sd_calificacion,
	 sd_tarjeta_visa,    --Linea
	 sd_estado,
	 sd_limite_credito,
	 sd_monto_riesgo,
	 sd_tipo_deuda,        sd_subtipo,
	 sd_beneficiario, sd_rol,
	 sd_dias_atraso,
	 sd_plazo,
	 sd_tipo_plazo,
	 sd_motivo_credito,
	 sd_refinanciamiento,
	 sd_restructuracion,
	 sd_fecha_cancelacion,
	 sd_ciclo
	)

	select distinct
	a.cliente_con,         a.usuario,            a.tramite,  --PQU cambio de a.cliente a a.cliente_con
	a.secuencia,           a.tipo_con,           a.cliente_con,
	op_estado,             a.toperacion,         op_fecha_liq,
	op_fecha_fin,          a.moneda,             a.tramite_d,
	a.numero_op,           a.numero_op_banco,    '05', --15
	null,
	'CCA',                 (select rtrim(c.valor) from cobis..cl_catalogo c
			inner join cobis..cl_tabla t on t.codigo = c.tabla
			where t.tabla = 'ca_toperacion'
			and c.codigo = a.toperacion ),
	--TASA
	(select sum(ro_porcentaje)
	from   cob_cartera..ca_rubro_op
	where  ro_fpago in ('P', 'A', 'T')
	and    ro_tipo_rubro = 'I'
	and    ro_operacion = a.numero_op),
	-- Cambios vinculación cliente
	a.tipoop,
	op_monto,
	--SALDO VENCIDO
	(select sum(isnull(am_acumulado,0) + isnull(am_gracia,0)- isnull(am_pagado,0) )--- isnull(am_exponencial,0))
	from   cob_cartera..ca_dividendo,
		cob_cartera..ca_rubro_op,
		cob_cartera..ca_amortizacion
	where  CHARINDEX(convert(varchar,a.opestado), @w_estado_cartera)=0 --( @w_est_credito, @w_est_anulado, @w_est_cancelado, @w_est_cex, @w_est_castigado, @w_est_novigente )
	and    a.tipoop   <> 'R'
	and    di_operacion = a.numero_op
	and    am_operacion = a.numero_op
	and    ro_operacion = a.numero_op
	and    di_operacion = am_operacion
	and    di_dividendo = am_dividendo
	and    ro_concepto  = am_concepto
	and    ro_operacion = am_operacion
	and    di_estado = @w_est_vencido
	and    ro_fpago not in ('L','T')
	and    a.producto  = 'CCA' ),
	--SALDO CAPITAL
	(select sum(isnull(am_acumulado,0) + isnull(am_gracia,0)- isnull(am_pagado,0) )--- isnull(am_exponencial,0))
	from   cob_cartera..ca_dividendo,
		  cob_cartera..ca_rubro_op,
		  cob_cartera..ca_amortizacion
	where CHARINDEX(convert(varchar,a.opestado), @w_estado_cartera)=0   -- ( @w_est_credito, @w_est_anulado, @w_est_cancelado, @w_est_cex, @w_est_castigado, @w_est_novigente )
	and    a.tipoop   <> 'R'
	and    di_operacion = a.numero_op
	and    am_operacion = a.numero_op
	and    ro_operacion = a.numero_op
	and    di_operacion = am_operacion
	and    di_dividendo = am_dividendo
	and    ro_concepto  = am_concepto
	and    ro_operacion = am_operacion
	and    di_estado <> @w_est_cancelado
	and    ro_tipo_rubro = 'C'
	and    ro_fpago not in ('L','T')
	and    a.producto  = 'CCA' ),
	--SALDO TOTAL
	(select sum(case op_tipo_cobro  when 'P' then isnull(am_cuota,0) + isnull(am_gracia,0)- isnull(am_pagado,0) --- isnull(am_exponencial,0)
											else isnull(am_acumulado ,0) + isnull(am_gracia,0)- isnull(am_pagado,0)-- - isnull(am_exponencial,0)
								  end )
	from   cob_cartera..ca_rubro_op,
		  cob_cartera..ca_amortizacion,
		  cob_cartera..ca_dividendo,
		  cob_cartera..ca_operacion
	where  op_operacion = a.numero_op
	and    a.tipoop    <> 'R'
	and    a.producto  = 'CCA'
	and    di_operacion = a.numero_op
	and    am_operacion = a.numero_op
	and    ro_operacion = a.numero_op
	and    di_operacion = am_operacion
	and    di_dividendo = am_dividendo
	and    ro_concepto  = am_concepto
	and    ro_operacion = am_operacion
	and    di_estado <> @w_est_cancelado
	and    ro_fpago not in ('L','T')
	),
	--SALDO POR VENCER
	0,
	--CUOTA ACTUAL
	0,
	fecha_lip,
	fecha_nip,
	--null, --calificacion
	(select cast(cast(ROUND(AVG(isnull(ca_calificacion,0)),2) as numeric(18,2)) as varchar(32))
	from cob_cartera..ca_calif_operacion
	where ca_fecha_proceso= (select max(ca_fecha_proceso)
		from cob_cartera..ca_calif_operacion
			where ca_operacion=o.op_operacion)
	and ca_operacion=o.op_operacion),
	--'end calificacion',
	op_lin_credito,
	es_descripcion,
	a.mrc,
	-- RIESGO DE CARTERA
	0,
	a.tipo_riesgo,
	case a.tipo_tr when 'R' then 'S'
		when 'O' then
	case a.anticipo when 1 then '/S'
	else null end
	else null
	END,
	es_descripcion,
	a.rol,
	0,--fschnabel no existe op_fecha_mora
	/*(select case  when (
	(select isnull((datediff(day,
	(convert(varchar(10),(select op_fecha_mora FROM cob_cartera..ca_operacion WHERE op_banco = a.numero_op_banco),101)),
	(convert(varchar(10),(select fp_fecha from cobis..ba_fecha_proceso),101)))), 0))
	> 0)
	then
	(select isnull((datediff(day,
	(convert(varchar(10),(select op_fecha_mora FROM cob_cartera..ca_operacion WHERE op_banco = a.numero_op_banco),101)),
	(convert(varchar(10),(select fp_fecha from cobis..ba_fecha_proceso),101)))), 0))
	end),   --FBO 2016/10/19 */


	op_plazo,
	(select valor
	from cobis..cl_catalogo
	where tabla = @w_tipo_dividendo_cat
	and codigo = o.op_tplazo),
	(select max(isnull(tr_destino_descripcion,''))
	from cr_tr_datos_adicionales
	where tr_tramite = a.tramite_d),
	case isnull(o.op_anterior, '')  when '' then 'N' else 'S' end,  -- Refinanciamiento
	'N', --fschnabel no existe op_num_reest
	--case isnull(o.op_num_reest,0) when 0 then 'N' else 'S' end ,  -- Reestructuracion
	case o.op_estado    when @w_est_cancelado then o.op_fecha_ult_proceso  else null  end,  -- Fecha Cancelacion
	ci_ciclo
	from   cr_ope1_tmp a,
	cob_cartera..ca_operacion o,
	cob_cartera..ca_estado,
	cob_cartera..ca_ciclo
	where  op_tramite   =  tramite_d
	and (op_ref_grupal = ci_prestamo or op_operacion = ci_operacion)--PQU 03/03/2021 and    op_operacion = ci_operacion
	and    op_tipo not  in ('V','R')
	and     tipo_riesgo <> 'I'
	--and   op_estado    not in ( select @w_estado_cartera )
	and     CHARINDEX(convert(varchar,op_estado), @w_estado_cartera)=0
	and   a.numero_op  is not null
	and    op_estado     = es_codigo
	and    spid          = @w_spid
    order by ci_ciclo, a.numero_op --PQU 03/03/2021
										  
	if @@error <> 0
	begin   -- Error en insercion de registro
		select @w_error = 2103001
		goto ERROR
	end

  --SELECT * FROM cr_situacion_deudas --PQU quitar
end
else 
begin 
PRINT 'PQU Inserta en cr_situacion_deudas parte 2'

insert into  cr_situacion_deudas
(sd_cliente,            sd_usuario,           sd_tramite,
 sd_secuencia,          sd_tipo_con,          sd_cliente_con,
 sd_identico,           sd_tipo_op,           sd_fecha_apr,
 sd_fecha_vct,          sd_moneda,            sd_tramite_d,
 sd_operacion,          sd_numero_operacion,  sd_categoria, --15
 sd_desc_categoria,
 sd_producto,           
 sd_desc_tipo_op,
 sd_tasa, 
 sd_tipoop_car,--20
 sd_monto_orig,
 sd_saldo_vencido, 
 sd_total_cargos,	--Saldo Capital
 sd_contrato_act,
 sd_saldo_x_vencer,--25
 sd_saldo_promedio,	--Cuota Actual
 sd_ult_fecha_pg,
 sd_prox_pag_int,
 sd_calificacion,	
 sd_tarjeta_visa,  --Linea
 sd_estado,          
 sd_limite_credito,
 sd_monto_riesgo,
 sd_tipo_deuda,        sd_subtipo, 
 sd_beneficiario, sd_rol, 
 sd_dias_atraso,
 sd_plazo, 
 sd_tipo_plazo, 
 sd_motivo_credito,
 sd_refinanciamiento,
 sd_restructuracion,
 sd_fecha_cancelacion
)

select distinct
 a.cliente,             a.usuario,            a.tramite,
 a.secuencia,           a.tipo_con,           a.cliente_con, 
 op_estado,             a.toperacion,         op_fecha_liq,
 op_fecha_fin,          a.moneda,             a.tramite_d,
 a.numero_op,           a.numero_op_banco,    '05',--15
 null,
    'CCA',                 (select rtrim(c.valor) from cobis..cl_catalogo c
            inner join cobis..cl_tabla t on t.codigo = c.tabla
            where t.tabla = 'ca_toperacion'
            and c.codigo = a.toperacion ),
--TASA
(select sum(ro_porcentaje)               
from   cob_cartera..ca_rubro_op
where  ro_fpago in ('P', 'A', 'T')
and    ro_tipo_rubro = 'I'
and    ro_operacion = a.numero_op),
-- Cambios vinculación cliente
a.tipoop,
op_monto,
--SALDO VENCIDO
(select sum(isnull(am_acumulado,0) + isnull(am_gracia,0)- isnull(am_pagado,0))--PQU 03/03/2021 esta versión no maneja exponencial - isnull(am_exponencial,0))
 from   cob_cartera..ca_dividendo,
        cob_cartera..ca_rubro_op,
        cob_cartera..ca_amortizacion
 where  CHARINDEX(convert(varchar,a.opestado), @w_estado_cartera)=0 --( @w_est_credito, @w_est_anulado, @w_est_cancelado, @w_est_cex, @w_est_castigado, @w_est_novigente )
 and    a.tipoop   != 'R'
 and    di_operacion = a.numero_op
 and    am_operacion = a.numero_op
 and    ro_operacion = a.numero_op
 and    di_operacion = am_operacion 
 and    di_dividendo = am_dividendo
 and    ro_concepto  = am_concepto
 and    ro_operacion = am_operacion
 and    di_estado = @w_est_vencido  
 and    ro_fpago not in ('L','T')   		
 and    a.producto  = 'CCA' ),
--SALDO CAPITAL
 (select sum(isnull(am_acumulado,0) + isnull(am_gracia,0)- isnull(am_pagado,0)) --PQU 03/03/2021 esta versión no maneja exponencial - isnull(am_exponencial,0))
   from   cob_cartera..ca_dividendo,
          cob_cartera..ca_rubro_op,
          cob_cartera..ca_amortizacion
   where CHARINDEX(convert(varchar,a.opestado), @w_estado_cartera)=0   -- ( @w_est_credito, @w_est_anulado, @w_est_cancelado, @w_est_cex, @w_est_castigado, @w_est_novigente )
   and    a.tipoop   != 'R'
   and    di_operacion = a.numero_op
   and    am_operacion = a.numero_op
   and    ro_operacion = a.numero_op
   and    di_operacion = am_operacion 
   and    di_dividendo = am_dividendo
   and    ro_concepto  = am_concepto
   and    ro_operacion = am_operacion
   and    di_estado != @w_est_cancelado
   and    ro_tipo_rubro = 'C'    
   and    ro_fpago not in ('L','T')   		
   and    a.producto  = 'CCA' ),
--SALDO TOTAL
(select sum(case op_tipo_cobro  when 'P' then isnull(am_cuota,0) + isnull(am_gracia,0)- isnull(am_pagado,0) 
                                          else isnull(am_acumulado ,0) + isnull(am_gracia,0)- isnull(am_pagado,0) 
                                  end )
   from   cob_cartera..ca_rubro_op,   
          cob_cartera..ca_amortizacion, 
          cob_cartera..ca_dividendo,
          cob_cartera..ca_operacion
   where  op_operacion = a.numero_op
   and    a.tipoop    != 'R'
   and    a.producto  = 'CCA' 
   and    di_operacion = a.numero_op
   and    am_operacion = a.numero_op
   and    ro_operacion = a.numero_op
   and    di_operacion = am_operacion 
   and    di_dividendo = am_dividendo
   and    ro_concepto  = am_concepto
   and    ro_operacion = am_operacion
   and    di_estado != @w_est_cancelado
   and    ro_fpago not in ('L','T')   		   		
   ),
--SALDO POR VENCER
   0,
--CUOTA ACTUAL    
   0,
   fecha_lip,
   fecha_nip,
   --null, --calificacion
   (select cast(cast(ROUND(AVG(isnull(ca_calificacion,0)),2) as numeric(18,2)) as varchar(32))
	from cob_cartera..ca_calif_operacion
	where ca_fecha_proceso= (select max(ca_fecha_proceso)
		from cob_cartera..ca_calif_operacion
			where ca_operacion=o.op_operacion)
	and ca_operacion=o.op_operacion),
	--'end calificacion',
   op_lin_credito,
   es_descripcion,	
   a.mrc,		
   -- RIESGO DE CARTERA
   0,     
   a.tipo_riesgo, 
   case a.tipo_tr when 'R' then 'S'
                  when 'O' then
                     case a.anticipo when 1 then '/S'
                     else null end 
                  else null 
   END,                  
   es_descripcion, 
   a.rol,
   0, --PQU 03/03/2021 no existe en este core op_fecha_mora									  
   /*(select case  when (
	(select isnull((datediff(day, 
   (convert(varchar(10),(select op_fecha_mora FROM cob_cartera..ca_operacion WHERE op_banco = a.numero_op_banco),101)), 
   (convert(varchar(10),(select fp_fecha from cobis..ba_fecha_proceso),101)))), 0)) 
   > 0)
   then 
   (select isnull((datediff(day, 
   (convert(varchar(10),(select op_fecha_mora FROM cob_cartera..ca_operacion WHERE op_banco = a.numero_op_banco),101)), 
   (convert(varchar(10),(select fp_fecha from cobis..ba_fecha_proceso),101)))), 0)) 
   end),   --FBO 2016/10/19 */ --fin PQU 03/03/2021


   op_plazo,
   (select valor 
      from cobis..cl_catalogo
     where tabla = @w_tipo_dividendo_cat 
	   and codigo = o.op_tplazo),
   (select max(isnull(tr_destino_descripcion,''))
      from cr_tr_datos_adicionales 
	 where tr_tramite = a.tramite_d),
   case isnull(o.op_anterior, '')  when '' then 'N' else 'S' end,  -- Refinanciamiento 
	'N', --PQU 03/03/2021 no existe op_num_reest									
   --PQU 03/03/2021 case isnull(o.op_num_reest,0) when 0 then 'N' else 'S' end ,  -- Reestructuracion 
   case o.op_estado    when @w_est_cancelado then o.op_fecha_ult_proceso  else null  end  -- Fecha Cancelacion
from   cr_ope1_tmp a,
       cob_cartera..ca_operacion o,
       cob_cartera..ca_estado
where  op_tramite   =  tramite_d 
and    op_tipo not  in ('V','R')
and     tipo_riesgo <> 'I'
and	   CHARINDEX(convert(varchar,op_estado), @w_estado_cartera)=0
--AND op_estado NOT IN (99,6,3,98,0)
and    a.numero_op  is not null
and    op_estado     = es_codigo
and    spid          = @w_spid 

if @@error != 0 
begin   -- Error en insercion de registro 
    select @w_error = 2103001
    goto ERROR
   
end
END

update cr_situacion_deudas
set    sd_saldo_x_vencer = isnull(sd_contrato_act,0),
       sd_monto_ml = isnull(sd_contrato_act,0) * cotizacion, 
       sd_monto    = isnull(sd_contrato_act,0),
       sd_monto_riesgo = isnull(sd_contrato_act,0) * cotizacion,
       sd_total_cargos = isnull(sd_total_cargos,0) * cotizacion
 from cr_ope1_tmp a, 
      cr_cotiz3_tmp d 
where numero_op_banco = sd_numero_operacion
  and sd_moneda       = d.moneda 
  and sd_usuario      = @s_user
  and sd_secuencia    = @s_sesn
  and sd_tramite      = isnull(@i_tramite, 0)
  and a.spid          = @w_spid 
  and a.spid          = d.spid  

-- Inserto Todos los Trßmites Aprobados y No Aprobados
if @i_aprobado = 'N'
begin

   --ORIGINALES
   insert into  cr_situacion_deudas
   (sd_cliente,         sd_usuario,          sd_tramite,
    sd_secuencia,       sd_tipo_con,         sd_cliente_con,
    sd_identico,        sd_producto,         sd_aprobado,
    sd_tramite_d,       sd_moneda,           sd_tipo_op,
    sd_tipoop_car,      sd_monto_orig,
    sd_monto,           sd_saldo_vencido,    sd_saldo_x_vencer, 
    sd_monto_ml,
    sd_desc_tipo_op,
    sd_tarjeta_visa,
    sd_monto_riesgo,
    sd_tipo_deuda  ,    sd_fecha_apr,        sd_fecha_vct,
    sd_tasa ,           sd_estado,           sd_val_utilizado,
    sd_val_utilizado_ml, sd_total_cargos,    sd_subtipo, sd_calificacion,--PQU 03/03/2021 se añade 2 columnas)
	sd_numero_operacion, sd_operacion)	--PQU 03/03/2021 se añade 2 columnas
   select distinct 
    sc_cliente,        sc_usuario,          sc_tramite,
    sc_secuencia,      sc_tipo_con,         sc_cliente_con,
    sc_identico,       producto,            'N',
    tramite_d,         a.moneda,            toperacion,
    tipoop, monto,
    monto,             0,                   monto,
    monto * cotizacion,
        (select rtrim(c.valor) from cobis..cl_catalogo c
            inner join cobis..cl_tabla t on t.codigo = c.tabla
            where t.tabla = 'ca_toperacion'
            and c.codigo = a.toperacion ),
    a.linea,
    monto * cotizacion,
    a.tipo_riesgo, fecha_apt ,          c.op_fecha_fin,

    (select sum(ro_porcentaje)                --Tasa
     from   cob_cartera..ca_rubro_op, cob_cartera..ca_operacion 
     where  ro_fpago in ('P', 'A', 'T')
     and    ro_tipo_rubro = 'I'
     and    ro_operacion = op_operacion and op_tramite   = a.tramite_d),
     es_descripcion, monto,
     monto * cotizacion, monto * cotizacion,
     case a.tipo_tr when 'O' then 
                    case a.anticipo when 1 then ' /S'
                    else null end 
                    else null   
     END, --calificacion
	 (select cast(cast(ROUND(AVG(isnull(ca_calificacion,0)),1) as int) as varchar(1))
	from cob_cartera..ca_calif_operacion
	where ca_fecha_proceso= (select max(ca_fecha_proceso)
	from cob_cartera..ca_calif_operacion
	where ca_operacion=a.numero_op)
	and ca_operacion=a.numero_op),
	--'end calificacion'
	numero_op_banco, numero_op --PQU 03/03/2021
   from  cr_ope1_tmp a left outer join 
         cob_cartera..ca_operacion c on(a.tramite_d = c.op_tramite) left outer join 
         cob_cartera..ca_estado on (es_codigo = op_estado),
         cr_cotiz3_tmp b, 
         cr_situacion_cliente
   where cliente        = sc_cliente
   and   secuencia      = sc_secuencia
   and   (tipo_tr       in ('O','R') or (tipo_tr = 'F' and @i_impresion = 'N'))
   and   (numero_op is NOT null  or a.opestado in (0, 99)) --1,3,99  --PQU aumenté el NOT
   and   a.moneda       = b.moneda
   and   sc_usuario     = @s_user
   and   sc_secuencia   = @s_sesn
   and   sc_tramite     = isnull( @i_tramite, 0)
   and   tipoop        != 'R'
        and   a.tramite_d    = c.op_tramite
        and   es_codigo      = op_estado
   and   a.producto  = 'CCA' 
   and   a.spid      = @w_spid 
   and   a.spid      = b.spid  
   --AND op_estado NOT IN (99,6,3,98,0)  --PQU temporal
   and  tipo_riesgo = 'I'


  if @w_tipo_grupo = 'S'
    begin
        if @i_act_can = 'S'
        begin

            insert into  cr_situacion_deudas
            (sd_cliente,   		sd_usuario,           sd_tramite,  --3
            sd_secuencia,  		sd_tipo_con,          sd_cliente_con,--6
            sd_identico,   		sd_tipo_op,           sd_fecha_apr,--9
            sd_fecha_vct,  		sd_moneda,            sd_tramite_d,--12
            sd_operacion,  		sd_numero_operacion,  sd_categoria, --15
            sd_desc_categoria,	sd_producto,          sd_desc_tipo_op, --18
            sd_tasa,			sd_tipoop_car,		  sd_monto_orig,--21
            sd_saldo_vencido, 	sd_total_cargos,	  sd_contrato_act,--24
            sd_saldo_x_vencer,	sd_saldo_promedio,	  sd_ult_fecha_pg,--27
            sd_prox_pag_int,	sd_calificacion,	  sd_tarjeta_visa,--30
            sd_estado,       	sd_limite_credito,    sd_monto_riesgo,--33
            sd_tipo_deuda,      sd_subtipo,           sd_beneficiario,--36
            sd_rol,         	sd_dias_atraso,       sd_plazo,--39
            sd_tipo_plazo,  	sd_motivo_credito,    sd_refinanciamiento,--42
            sd_restructuracion, sd_fecha_cancelacion)
            select distinct
            a.cliente,
            a.usuario,
            a.tramite,--3
            a.secuencia,
            a.tipo_con,
            a.cliente_con,--6
            op_estado,
            a.toperacion,
            o.op_fecha_liq,--9
            op_fecha_fin,
            a.moneda,
            a.tramite_d,--12
            a.numero_op,
            o.op_banco, --SRO G.Solidario,
            '05',--15
            null,
            'CCA',
            (select rtrim(c.valor) from cobis..cl_catalogo c
                                                            inner join cobis..cl_tabla t on t.codigo = c.tabla
                                                            where t.tabla = 'ca_toperacion'
                                                            and c.codigo = a.toperacion ), --18
            (select sum(ro_porcentaje)
            from   cob_cartera..ca_rubro_op
            where  ro_fpago in ('P', 'A', 'T')
            and    ro_tipo_rubro = 'I'
            and    ro_operacion = a.numero_op),--19
            a.tipoop,
            op_monto, --21
            --SALDO VENCIDO
            (select sum(isnull(am_acumulado,0) + isnull(am_gracia,0)- isnull(am_pagado,0) )--- isnull(am_exponencial,0))
            from    cob_cartera..ca_operacion,
			        cob_cartera..ca_dividendo,
                    cob_cartera..ca_rubro_op,
                    cob_cartera..ca_amortizacion
            where  op_ref_grupal= a.numero_op
            and    op_operacion = di_operacion
            and    di_operacion = am_operacion
			and    di_dividendo = am_dividendo
			and    ro_operacion = am_operacion            
            and    ro_concepto  = am_concepto
            and    di_estado = @w_est_vencido
            and    ro_fpago not in ('L','T')
            and    op_estado not in (3,0,99,6)	),  --22
            --SALDO CAPITAL
			(select sum(isnull(am_acumulado,0) + isnull(am_gracia,0)- isnull(am_pagado,0) )--- isnull(am_exponencial,0))
            from    cob_cartera..ca_operacion,
			        cob_cartera..ca_dividendo,
                    cob_cartera..ca_rubro_op,
                    cob_cartera..ca_amortizacion
            where  op_ref_grupal= a.numero_op
            and    op_operacion = di_operacion
            and    di_operacion = am_operacion
			and    di_dividendo = am_dividendo
			and    ro_operacion = am_operacion            
            and    ro_concepto  = am_concepto
            and    di_estado <> @w_est_cancelado
			and    ro_tipo_rubro = 'C'
            and    ro_fpago not in ('L','T')
            and    op_estado not in (3,0,99,6)	),  --23            
            --SALDO TOTAL
            (select sum(case op_tipo_cobro  when 'P' then isnull(am_cuota,0) + isnull(am_gracia,0)- isnull(am_pagado,0) --- isnull(am_exponencial,0)
                                                    else isnull(am_acumulado ,0) + isnull(am_gracia,0)- isnull(am_pagado,0)-- - isnull(am_exponencial,0)
                                            end )
            from    cob_cartera..ca_operacion,
			        cob_cartera..ca_dividendo,
                    cob_cartera..ca_rubro_op,
                    cob_cartera..ca_amortizacion
            where  op_ref_grupal= a.numero_op
            and    op_operacion = di_operacion
            and    di_operacion = am_operacion
			and    di_dividendo = am_dividendo
			and    ro_operacion = am_operacion            
            and    ro_concepto  = am_concepto
            and    di_estado <> @w_est_cancelado
			and    op_estado not in (3,0,99,6)	),  --24
            --SALDO por vencer
            (select sum(case op_tipo_cobro  when 'P' then isnull(am_cuota,0) + isnull(am_gracia,0)- isnull(am_pagado,0) --- isnull(am_exponencial,0)
                                                    else isnull(am_acumulado ,0) + isnull(am_gracia,0)- isnull(am_pagado,0)-- - isnull(am_exponencial,0)
                                            end )
            from    cob_cartera..ca_operacion,
			        cob_cartera..ca_dividendo,
                    cob_cartera..ca_rubro_op,
                    cob_cartera..ca_amortizacion
            where  op_ref_grupal= a.numero_op
            and    op_operacion = di_operacion
            and    di_operacion = am_operacion
			and    di_dividendo = am_dividendo
			and    ro_operacion = am_operacion            
            and    ro_concepto  = am_concepto
            and    di_estado not in (@w_est_vencido,@w_est_cancelado)
            and    ro_fpago not in ('L','T')            
			and    op_estado not in (3,0,99,6)	),  --25
            0,  --26
            fecha_lip,--27
            fecha_nip, --28
            --null,  --calificacion 
			(select cast(cast(ROUND(AVG(isnull(ca_calificacion,0)),1) as int) as varchar(1))
	        from cob_cartera..ca_calif_operacion
	        where ca_fecha_proceso= (select max(ca_fecha_proceso)
	        from cob_cartera..ca_calif_operacion
	        where ca_operacion=a.numero_op)
	        and ca_operacion=a.numero_op),  --PQU 05/05/2021 calificacion  29
            op_lin_credito,  --30
            es_descripcion,
            a.mrc,
            0,   --33
            a.tipo_riesgo,
            case a.tipo_tr when 'R' then 'S'
                                when 'O' then
                                    case a.anticipo when 1 then '/S'
                                    else null end
                                else null
                            end,
                            es_descripcion,
            a.rol,
            0,
            op_plazo,
            (select valor
                from cobis..cl_catalogo
                where tabla = @w_tipo_dividendo_cat
                and codigo = o.op_tplazo),
            (select max(isnull(tr_destino_descripcion,''))
                from cr_tr_datos_adicionales
                where tr_tramite = a.tramite_d),
            case isnull(o.op_anterior, '')  when '' then 'N' else 'S' end,
            'N',
            case o.op_estado  when @w_est_cancelado then o.op_fecha_ult_proceso  else null  end
            from    cr_ope1_tmp a,
                    cob_cartera..ca_operacion o,
                    cob_cartera..ca_estado,
                    cob_credito..cr_tramite_grupal_view tg
            where  op_tramite   =  tramite_d
            and    op_operacion  =  tg.tg_operacion
            and    op_tipo not  in ('V','R')
            --and    CHARINDEX(convert(varchar,op_estado), @w_estado_cartera)=0
            and    a.numero_op  is not null
            and    op_estado     = es_codigo
            and    tipo_riesgo   = 'D'
            and    spid          = @w_spid
            and    cliente       = @i_grupo
		    and  op_operacion  not in (select distinct sd_operacion from cr_situacion_deudas where spid = @w_spid) --PQU 03/03/2021 para eliminar datos repetidos en historicos																																				   

        end
        else if @i_act_can = 'N'
        begin
            PRINT 'PQU inserta deudas directas'

            select @w_porcentaje = 0
            select @w_saldo_vencido = 0
            select @w_saldo_capital = 0
            select @w_total = 0


            select @w_tg_tramite = max(tg_tramite)
              from cob_credito..cr_tramite_grupal,--PQU 03/03/2021 no existe esta vista _view,
                   cob_cartera..ca_operacion
             where tg_tramite = op_tramite
               and tg_grupo   = @i_grupo
               and op_estado  = @w_est_cancelado
               
            insert into  cr_situacion_deudas
            (sd_cliente,       sd_usuario,           sd_tramite,  --3
            sd_secuencia,      sd_tipo_con,          sd_cliente_con,
            sd_identico,       sd_tipo_op,           sd_fecha_apr,
            sd_fecha_vct,      sd_moneda,            sd_tramite_d, --12
            sd_operacion,      sd_numero_operacion,  sd_categoria,
            sd_desc_categoria, sd_producto,          sd_desc_tipo_op,
            sd_tasa,           sd_tipoop_car,        sd_monto_orig, --21
            sd_saldo_vencido,  sd_total_cargos,      sd_contrato_act,
            sd_saldo_x_vencer, sd_saldo_promedio,    sd_ult_fecha_pg,
            sd_prox_pag_int,   sd_calificacion,      sd_tarjeta_visa, --30
            sd_estado,         sd_limite_credito,    sd_monto_riesgo, --33
            sd_tipo_deuda,     sd_subtipo,           sd_beneficiario,
            sd_rol,            sd_dias_atraso,       sd_plazo,
            sd_tipo_plazo,     sd_motivo_credito,    sd_refinanciamiento,
            sd_restructuracion,sd_fecha_cancelacion)
            select distinct
                sc_cliente_con,--PQU cambio a sc_cliente_con para grupos
                sc_usuario,       --2
                sc_tramite,--3
                sc_secuencia, --4
                sc_tipo_con,     --5
                sc_cliente_con, --6
                1,--SRO G.Solidario--7
                A.op_toperacion,      --8
                A.op_fecha_liq,--9
                op_fecha_fin,     --10
                A.op_moneda,          --11
                tr_tramite,--12
                A.op_operacion,--13
                A.op_banco,    --14
                '05', --15
                null, --16
                'CCA',          --17
                (select rtrim(c.valor) from cobis..cl_catalogo c
                                                                inner join cobis..cl_tabla t on t.codigo = c.tabla
                                                                where t.tabla = 'ca_toperacion'
                                                                and c.codigo = A.op_toperacion ),--18
                0,    --19
                A.op_tipo,    --20
                op_monto,--21
            --SALDO VENCIDO
            (select isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0)- isnull(am_pagado,0)),0)
            from    cob_cartera..ca_operacion,
			        cob_cartera..ca_dividendo,
                    cob_cartera..ca_rubro_op,
                    cob_cartera..ca_amortizacion
            where  op_ref_grupal= A.op_banco
            and    op_operacion = di_operacion
            and    di_operacion = am_operacion
			and    di_dividendo = am_dividendo
			and    ro_operacion = am_operacion            
            and    ro_concepto  = am_concepto
            and    di_estado = @w_est_vencido
            and    ro_fpago not in ('L','T')
            and    op_estado not in (3,0,99,6)	),  --22
            --SALDO CAPITAL
			(select sum(isnull(am_acumulado,0) + isnull(am_gracia,0)- isnull(am_pagado,0) )--- isnull(am_exponencial,0))
            from    cob_cartera..ca_operacion,
			        cob_cartera..ca_dividendo,
                    cob_cartera..ca_rubro_op,
                    cob_cartera..ca_amortizacion
            where  op_ref_grupal= A.op_banco
            and    op_operacion = di_operacion
            and    di_operacion = am_operacion
			and    di_dividendo = am_dividendo
			and    ro_operacion = am_operacion            
            and    ro_concepto  = am_concepto
            and    di_estado <> @w_est_cancelado
			and    ro_tipo_rubro = 'C'
            and    ro_fpago not in ('L','T')
            and    op_estado not in (3,0,99,6)	),  --23            
            --SALDO TOTAL
            (select sum(case op_tipo_cobro  when 'P' then isnull(am_cuota,0) + isnull(am_gracia,0)- isnull(am_pagado,0) --- isnull(am_exponencial,0)
                                                    else isnull(am_acumulado ,0) + isnull(am_gracia,0)- isnull(am_pagado,0)-- - isnull(am_exponencial,0)
                                            end )
            from    cob_cartera..ca_operacion,
			        cob_cartera..ca_dividendo,
                    cob_cartera..ca_rubro_op,
                    cob_cartera..ca_amortizacion
            where  op_ref_grupal= A.op_banco
            and    op_operacion = di_operacion
            and    di_operacion = am_operacion
			and    di_dividendo = am_dividendo
			and    ro_operacion = am_operacion            
            and    ro_concepto  = am_concepto
            and    di_estado <> @w_est_cancelado
			and    op_estado not in (3,0,99,6)	),  --24
            --SALDO por vencer
            (select sum(case op_tipo_cobro  when 'P' then isnull(am_cuota,0) + isnull(am_gracia,0)- isnull(am_pagado,0) --- isnull(am_exponencial,0)
                                                    else isnull(am_acumulado ,0) + isnull(am_gracia,0)- isnull(am_pagado,0)-- - isnull(am_exponencial,0)
                                            end )
            from    cob_cartera..ca_operacion,
			        cob_cartera..ca_dividendo,
                    cob_cartera..ca_rubro_op,
                    cob_cartera..ca_amortizacion
            where  op_ref_grupal= A.op_banco
            and    op_operacion = di_operacion
            and    di_operacion = am_operacion
			and    di_dividendo = am_dividendo
			and    ro_operacion = am_operacion            
            and    ro_concepto  = am_concepto
            and    di_estado not in (@w_est_vencido,@w_est_cancelado)
            and    ro_fpago not in ('L','T')            
			and    op_estado not in (3,0,99,6)	),  --25
                null,--26
                null,--27
                null, --28
                (select cast(cast(ROUND(AVG(isnull(ca_calificacion,0)),1) as int) as varchar(1))
	            from cob_cartera..ca_calif_operacion
	            where ca_fecha_proceso= (select max(ca_fecha_proceso)
	            from cob_cartera..ca_calif_operacion
	            where ca_operacion=A.op_operacion)
	            and ca_operacion=A.op_operacion), --29  PQU 05/05/2021
                null, --30
                es_descripcion,
                null,
                0,
                'D', 	--34
                case A.op_tipo when 'R' then 'S'
                                    when 'O' then
                                        null
                                        --case a.anticipo when 1 then '/S'
                                        --else null end
                                    else null
                                end, --35
                convert(varchar,sc_cliente), --36
                sc_rol,    --37, rol
                0,    --38
                op_plazo,--39
                (select valor
                    from cobis..cl_catalogo
                    where tabla = @w_tipo_dividendo_cat
                    and codigo = A.op_tplazo),--40
                (select max(isnull(tr_destino_descripcion,''))
                    from cr_tr_datos_adicionales
                    where tr_tramite = tr_tramite),--41
                case isnull(A.op_anterior, '')  when '' then 'N' else 'S' end, --42
                'N', --43
                case A.op_estado  when @w_est_cancelado then A.op_fecha_ult_proceso  else null  end --44
            from cr_tramite,
                 cr_deudores,
                 cob_cartera..ca_operacion A,
                 cob_cartera..ca_estado,
                 cr_situacion_cliente
           where de_cliente    = sc_cliente
             and de_tramite    = tr_tramite
             and tr_tramite    = op_tramite
             and op_estado     = es_codigo
             and tr_tramite    = @w_tg_tramite
             and tr_tipo       in ('O', 'R', 'F')
             and (tr_estado    <> 'R'
             and tr_estado     <> 'Z')
             and sc_tramite    = isnull(@i_tramite, 0)
             and sc_usuario    = @s_user
             and sc_secuencia  = @s_sesn
             and tr_toperacion not in ( 'CCE', 'CDE', 'CDI', 'GRB')
             and sc_tipo_con   = 'S'

        end
		--Aqui actualizar
        update cr_situacion_deudas
        set    --sd_saldo_x_vencer = isnull(sd_contrato_act,0),
               --sd_monto_ml = isnull(sd_contrato_act,0) * cotizacion, 
               --sd_monto    = isnull(sd_contrato_act,0),
               sd_monto_riesgo = isnull(sd_total_cargos,0) * cotizacion--,
               --sd_total_cargos = isnull(sd_total_cargos,0) * cotizacion
        from  cr_cotiz3_tmp d 
        where sd_usuario      = @s_user
          and sd_secuencia    = @s_sesn
          and sd_tramite      = isnull(@i_tramite, 0)
          and d.spid          = @w_spid 
          
    end
  
end
else -- SOLO TRAMITES APROBADOS
begin

   --ORIGINALES
   insert into  cr_situacion_deudas
   (sd_cliente,         sd_usuario,         sd_tramite,
    sd_secuencia,       sd_tipo_con,    sd_cliente_con,
    sd_identico,        sd_producto,        sd_tramite_d,
    sd_moneda,          sd_tipo_op,         sd_aprobado,
    sd_monto,           sd_saldo_vencido,   sd_saldo_x_vencer, 
    sd_monto_ml,        sd_tarjeta_visa,		
    sd_monto_riesgo,
    sd_tipo_deuda,      sd_fecha_apr,       sd_fecha_vct,
    sd_tasa,            sd_estado , sd_calificacion)			
   select distinct 
    sc_cliente,         sc_usuario,         sc_tramite,
    sc_secuencia,       sc_tipo_con,        sc_cliente_con,
    sc_identico,        'TRA',              tramite_d,
    a.moneda,           toperacion,         'S',
    monto,              0,                  monto * cotizacion,
    monto * cotizacion, a.linea,			
    monto * cotizacion,
    a.tipo_riesgo,         fecha_apt ,          c.op_fecha_fin,

    (select sum(ro_porcentaje)                --Tasa
     from   cob_cartera..ca_rubro_op, cob_cartera..ca_operacion 
     where  ro_fpago in ('P', 'A', 'T')
     and    ro_tipo_rubro = 'I'
     and    ro_operacion = op_operacion and op_tramite   = a.tramite_d),
     es_descripcion,
	  (select cast(cast(ROUND(AVG(isnull(ca_calificacion,0)),1) as int) as varchar(1))
	 from cob_cartera..ca_calif_operacion
	 where ca_fecha_proceso= (select max(ca_fecha_proceso)
			from cob_cartera..ca_calif_operacion
			where ca_operacion=a.numero_op)
	and ca_operacion=a.numero_op)
   from  cr_ope1_tmp a left outer join 
         cob_cartera..ca_operacion c on(a.tramite_d = c.op_tramite) left outer join 
         cob_cartera..ca_estado on (es_codigo = op_estado),
         cr_cotiz3_tmp b, 
         cr_situacion_cliente
         
   where cliente       = sc_cliente
   and   secuencia     = sc_secuencia
   and   (tipo_tr        =  'O' or (tipo_tr = 'F' and @i_impresion = 'N'))
   and   estado       = 'A' 
   and   (numero_op is null) 
   and   a.moneda      = b.moneda
   and   sc_usuario    = @s_user
   and   sc_secuencia  = @s_sesn
   and   sc_tramite    = isnull( @i_tramite, 0)
   and   tipoop != 'R'
				
											 
   and   a.spid        = @w_spid 
   and   a.spid        = b.spid  

   if @@error != 0 
   begin      -- Error en insercion de registro 
      print 'aaaaaaaaaaa 9'
      select @w_error = 2103001
      goto ERROR
   end

 --RENOVACIONES
   insert into  cr_situacion_deudas
   (sd_cliente,       sd_usuario,       sd_secuencia,
    sd_tramite,       sd_tipo_con,      sd_cliente_con,
    sd_identico,      sd_producto,      sd_tramite_d,
    sd_moneda,        sd_tipo_op,       sd_aprobado,
    sd_monto,
    sd_saldo_x_vencer, 
    sd_saldo_vencido,
    sd_monto_ml,
    sd_tarjeta_visa,
    sd_monto_riesgo,
    sd_tipo_deuda, sd_calificacion )		
   select
    sc_cliente,       sc_usuario,       sc_secuencia,
    sc_tramite,       sc_tipo_con,      sc_cliente_con,
    sc_identico,      'TRA',            tramite_d,
    a.moneda,         toperacion,       'S',
    monto, 
    monto * b.cotizacion,
    0,
    monto * b.cotizacion, 
    a.linea,
    monto * b.cotizacion,
    a.tipo_riesgo,
	 (select cast(cast(ROUND(AVG(isnull(ca_calificacion,0)),1) as int) as varchar(1))
	from cob_cartera..ca_calif_operacion
	where ca_fecha_proceso= (select max(ca_fecha_proceso)
			from cob_cartera..ca_calif_operacion
			where ca_operacion=a.numero_op)
	and ca_operacion=a.numero_op)
   from  cr_ope1_tmp a, cr_cotiz3_tmp b , cr_situacion_cliente
   where cliente       = sc_cliente
   and   secuencia     = sc_secuencia
   and   tipo_tr       = 'R'
   and   estado       = 'A'    
   and   (numero_op is null) 
   and   sc_usuario    = @s_user
   and   sc_secuencia  = @s_sesn
   and   sc_tramite    = isnull( @i_tramite, 0)
   and   tipoop != 'R'
   and   a.moneda      = b.moneda
   and   tipo_riesgo <> 'I'--PQU 03/03/2021 esto está repetido and   tipoop != 'R'
   and   tramite_d not in (select sd_tramite_d from cr_situacion_deudas 
                            where sd_usuario = @s_user  and sd_secuencia  = @s_sesn
                              and sd_tramite = isnull( @i_tramite, 0))
   and   a.spid       = @w_spid 
   and   a.spid       = b.spid     
   if @@error != 0 
   begin      -- Error en insercion de registro 
      print 'aaaaaaaaaaa 10'
      select @w_error = 2103001
      goto ERROR 
   end
end
--Actualizo datos solo para Riesgos Indirectos donde no existe número de operación
update cr_situacion_deudas
	set sd_tipo_plazo     = (select valor 
                              from cobis..cl_catalogo
						      where tabla = @w_tipo_dividendo_cat 
						      and codigo = a.frecuencia_pago),
        sd_plazo          = plazo,
		sd_motivo_credito = motivo_credito,
		sd_contrato_act = monto
from cr_ope1_tmp a, cr_situacion_deudas sd
	 where  a.tramite_d =  sd.sd_tramite_d 
	 and a.numero_op is null 
	 and sd.sd_tipo_deuda = 'I'
	 
--Identifico rol para Riesgos Indirectos
update cr_situacion_deudas
	set sd_rol = 'G'
from cr_ope1_tmp a, cr_situacion_deudas sd
where a.numero_op = sd.sd_operacion
and sd.sd_tipo_deuda = 'I'

if @@error != 0 
   begin      -- Error en insercion de registro 
print 'aaaaaaaaaaa 11'
      select @w_error = 2103001
      goto ERROR 
   end
   
--PQU 03/03/2021 Se actualiza la informacion del ciclo  
update cr_situacion_deudas
set sd_ciclo = dc_ciclo_grupo
from cr_situacion_deudas, cob_cartera..ca_det_ciclo--, cr_ope1_tmp
where sd_operacion = dc_operacion						  
														 
--SELECT * FROM cr_situacion_deudas
		
--PQU 03/03/2021 se añade 
delete from cr_cotiz3_tmp          where spid = @w_spid --tabla de cotizaciones
delete from cr_ope1_tmp            where spid = @w_spid
--fin PQU	  
			   
return 0

ERROR:
PRINT 'PQU Entro al error'
   delete from cr_cotiz3_tmp          where spid = @w_spid --tabla de cotizaciones
   delete from cr_ope1_tmp            where spid = @w_spid 
   --PQU 05/03/2021 delete from cr_temp4_tmp           where spid = @w_spid  

   exec cobis..sp_cerror 
        @t_debug='N',@t_file='',  
        @t_from =@w_sp_name, @i_num = @w_error
   return @w_error


GO

