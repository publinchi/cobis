use cob_credito
go
/************************************************************/
/*   ARCHIVO:         cr_datcred.sp                         */
/*   NOMBRE LOGICO:   sp_datos_credito                      */
/*   PRODUCTO:        COBIS CREDITO                         */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*  Consulta la informacion para generacion de reportes de  */
/*  Prestamos Individuales.                                 */
/*  Operacion Q             */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR            RAZON                   */
/* 13/JUL/2017     WToledo          Emision Inicial         */
/* 18/JUL/2017     PRomero			Operacion T y C 		*/
/* 18/SEP/2017     MTaco            Agregar fecha pago y    */
/*                                  fecha de corte          */
/* 03/Dic/2019     AChiluisa        Aumentar credito revol- */
/*                                  vente                   */
/************************************************************/
if exists(select 1 from sysobjects where name = 'sp_datos_credito')
   drop proc sp_datos_credito
go

create proc sp_datos_credito (
   @s_ssn       int         = null,
   @s_sesn      int         = null,
   @s_ofi       smallint    = null,
   @s_rol       smallint    = null,
   @s_user      login       = null,
   @s_date      datetime    = null,
   @s_term      descripcion = null,
   @t_debug     char(1)     = 'N',
   @t_file      varchar(10) = null,
   @t_from      varchar(32) = null,
   @s_srv       varchar(30) = null,
   @s_lsrv      varchar(30) = null,
   @i_modo      int         = null,
   @i_operacion char(2),
   @i_tramite   int         = null,
   @i_formato_fecha int     = null,
   @i_tipo_cliente char(1)  = 'D' --(D) Deudor, (G)Garante
)
as
declare
   @w_sp_name           varchar(20),
   @w_operacion         int,
   --@w_costo_anual_tot   money,
   --@w_tasa_int_anual    money,
   @w_monto_credito     varchar(200),
   @w_monto_tot_pag     varchar(200),
   @w_lista_comisiones  varchar(300),
   @w_porcentaje_mora   float,
   @w_plazo_credito     varchar(50),
   @w_desc_plz_cred     varchar(100),
   @w_desc_moneda       varchar(100),
   @w_fecha_liq         datetime,
   @w_ente              int,
   @w_tipo_telefono     varchar(10),
   @w_tipo_telefono_cel varchar(10),
   @w_monto_max_fijo    money,
   @w_nombre_comision   varchar(64),
   @w_valor_comis       float,
   @w_ciudad            varchar(50),
   @w_toperacion        catalogo,
   @w_sector            catalogo,
   @w_monto_total		   money,
   @w_monto				   money,
   @w_moneda			   int,
   @w_monto_letras		varchar(254),
   @w_return		      int,
   @w_fecha_pago        datetime,
   @w_fecha_corte       datetime,
   @w_ciclo             int,
   @w_est_novigente     int,
   @w_est_anulado       int,
   @w_est_credito       int

select @w_sp_name = 'sp_datos_credito'

if @i_formato_fecha is null
begin
   select @i_formato_fecha=103
end

/* Estados 
exec cob_externos..sp_estados
@i_producto      = 7,
@o_est_novigente = @w_est_novigente out,
@o_est_anulado   = @w_est_anulado out,
@o_est_credito   = @w_est_credito out
*/
select @w_est_novigente = isnull(@w_est_novigente, 0),
@w_est_anulado = isnull(@w_est_anulado, 6),
@w_est_credito = isnull(@w_est_credito, 99)

if not exists(select tr_tramite from cr_tramite where tr_tramite=@i_tramite)
begin
  exec cobis..sp_cerror
	  @t_debug = @t_debug,
	  @t_file  = @t_file,
	  @t_from  = @w_sp_name,
	  @i_num   = 2110316 --"NO EXISTE TRAMITE"
  return 2110316
end
   
select @w_operacion      = op.op_operacion,
       @w_monto_max_fijo = tr_monto,
       @w_toperacion     = op_toperacion,
       @w_sector         = op_sector
  from cob_credito..cr_tramite,
       cob_credito..cr_deudores,
       cob_cartera..ca_operacion op
       
 where tr_tramite    = @i_tramite
   and tr_tramite    = de_tramite
   and tr_tramite    = op_tramite
   

 

if @i_operacion ='Q' --RPT Caratula Credito Individual
BEGIN

  /* select @w_tasa_int_anual = ro_porcentaje_efa
     from cob_cartera..ca_rubro_op
    where ro_operacion = @w_operacion
      and ro_concepto  = 'INT'
*/
   select @w_monto_credito = tr_monto,
          @w_desc_moneda   = mo_descripcion
     from cr_tramite, cobis..cl_moneda
    where tr_tramite = @i_tramite
      and mo_moneda  = tr_moneda

   select @w_monto_tot_pag = sum(am_cuota)
     from cob_cartera..ca_amortizacion
    where am_operacion = @w_operacion

   select @w_porcentaje_mora = (vd_valor_default / 12)
     from cob_cartera..ca_valor_det
    where vd_tipo   = 'TCMORA'
      and vd_sector = @w_sector --cob_cartera..ca_operacion  op_sector 

    select @w_lista_comisiones = ''

   declare c_comis_prest_ind cursor for
    select va_descripcion, vd_valor_default
      from cob_cartera..ca_valor_det, cob_cartera..ca_valor
     where vd_tipo   in ('TCMORA','TPREPAGO')
       and vd_sector = @w_sector
       and va_tipo   = vd_tipo
       for read only

      open c_comis_prest_ind
     fetch c_comis_prest_ind
      into @w_nombre_comision, @w_valor_comis
     while @@fetch_status = 0
     begin
           if(@w_lista_comisiones != '')
           begin
               select @w_lista_comisiones = @w_lista_comisiones + '; '
           END
           
           select @w_lista_comisiones = @w_lista_comisiones + @w_nombre_comision + ': ' + convert(varchar,@w_valor_comis) + '%'
           fetch c_comis_prest_ind into @w_nombre_comision, @w_valor_comis
           
     end --FIN while @@fetch_status = 0
   close c_comis_prest_ind
   deallocate c_comis_prest_ind

   select @w_desc_plz_cred  = valor,
          @w_plazo_credito  = convert(VARCHAR,op_plazo),
          @w_fecha_liq      = op_fecha_liq
     from cob_cartera..ca_operacion,
          cobis..cl_tabla t,
          cobis..cl_catalogo c
    where op_tramite = @i_tramite
      and op_tplazo  = c.codigo
      and c.tabla = t.codigo
      and t.tabla = 'cr_tplazo_ind'

   -- DESA: Parametro Pendiente @w_costo_anual_tot
   -- select @w_costo_anual_tot  = convert(float,30.5) --aca hacer el cambio para consultar op_valor_cat  de la ca_operacion
  /* select @w_costo_anual_tot  = round(op_valor_cat,2)
     from cob_cartera..ca_operacion
	where op_operacion = @w_operacion
     */ 
   --Fecha limite de pago
   SELECT @w_fecha_pago = min(di_fecha_ven)
     FROM cob_cartera..ca_dividendo 
	WHERE di_operacion  = @w_operacion 
	  AND di_estado  = 0
	  
   --Fecha de corte
    SELECT @w_fecha_corte = fp_fecha 
	  FROM cobis..ba_fecha_proceso

   select 'COSTO_ANUAL_TOT'  = 0, --@w_costo_anual_tot,
          'TASA_INT_ANUAL'   = 0, --@w_tasa_int_anual,
          'MONTO_CREDITO'    = @w_monto_credito,
          'MONTO_TOT_PAG'    = @w_monto_tot_pag,
          'LISTA_COMISIONES' = @w_lista_comisiones,
          'PORCENTAJE_MORA'  = @w_porcentaje_mora,
          'PLAZO_CREDITO'    = @w_plazo_credito,
          'DESCRIP_MONEDA'   = @w_desc_moneda,
          'DESCRIP_PLAZO'    = @w_desc_plz_cred,
          'FECHA_LIQUIDA'    = @w_fecha_liq,
		  'FECHA_LIMITE_PAGO'= convert(varchar(10), @w_fecha_pago, @i_formato_fecha),
		  'FECHA_CORTE'      = convert(varchar(10), @w_fecha_corte, @i_formato_fecha)
   return 0
end --@i_operacion='Q' FIN

if @i_operacion ='Q1' --RPT Caratula Credito Individual - Lista de Pagos
BEGIN

   select 'NUMERO'     = am_dividendo ,
          'MONTO'      = sum(am_cuota),
          'FECHA_VENC' = di_fecha_ven
     from cob_cartera..ca_amortizacion,
          cob_cartera..ca_dividendo
    where am_operacion = @w_operacion
      and am_operacion = di_operacion
      and di_dividendo = am_dividendo
    group by am_dividendo, di_fecha_ven

   return 0
end --@i_operacion='Q1' FIN

if(@i_operacion='T')
begin

	select @w_monto=tr_monto,
			@w_moneda=tr_moneda,
			@w_toperacion=tr_toperacion
	from cr_tramite
	where tr_tramite=@i_tramite
	
	
	/*exec @w_return = cob_interfase..sp_numeros_letras 
	@i_dinero	=	@w_monto,
	@i_moneda	=	@w_moneda,
	@i_idioma	=	'E',
	@t_trn		=   29322,
	@o_texto	=	@w_monto_letras OUT
	*/
	SELECT  @w_monto_letras ='Prueba de Letras'
	
	SELECT @w_return =0
	
	if(@w_return <> 0)
	begin 
		exec cobis..sp_cerror
		 @t_debug = @t_debug,
		 @t_file  = @t_file,
		 @t_from  = @w_sp_name,
		 @i_num   = @w_return
		return @w_return
	end
	
	if @w_toperacion in ('GRUPAL', 'REVOLVENTE')
	BEGIN
	
    	select  'OFICINA'      =  (select of_nombre from cobis..cl_oficina where of_oficina=tr.tr_oficina),
   	
            'FECHA_CREA'   =  convert(varchar(10),tr_fecha_crea ,@i_formato_fecha),
            
            'ASESOR'       = (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial where fu_funcionario = oc_funcionario and oc_oficial=tr.tr_oficial),
            
            'MONTO'        =  tr_monto,
            
            'TASA'         =  (select ro_porcentaje
                           from cob_cartera..ca_rubro_op
                           where ro_concepto='INT'
                           and ro_operacion= tr.tr_numero_op),
                           
            'NUM_PAGOS'    = (select count(di_dividendo) from cob_cartera..ca_dividendo where di_operacion = tr.tr_numero_op),
            
            'FECHA_FIN'    = (select convert(varchar(10),op_fecha_fin ,@i_formato_fecha)
                           from cob_cartera..ca_operacion
                           where op_operacion = tr.tr_numero_op),
            'TIPO_PLAZO'   =  (select td_descripcion
                           from cob_cartera..ca_default_toperacion, cob_cartera..ca_tdividendo
                           where dt_tdividendo=td_tdividendo
                           and dt_toperacion = tr.tr_toperacion),
            'PLAZO'        =  (select dt_plazo
                           from cob_cartera..ca_default_toperacion
                           where dt_toperacion = tr.tr_toperacion),
            'DEUDOR'    =  (select de_cliente
                           from cr_deudores
                           where de_tramite = tr.tr_tramite
                           and de_rol = 'D'),
         'GARANTE'      =  null,
   		 'TIPO_CREDITO'	= (select op_toperacion from cob_cartera..ca_operacion where op_operacion=tr.tr_numero_op),
   		 'CIUD_TR'		= (select ci_descripcion from cobis..cl_ciudad where ci_ciudad =tr.tr_ciudad),
   		 'DIR_OFI'		= (select of_direccion from cobis..cl_oficina where of_oficina=tr.tr_oficina),
   		 'APODERADO'	= (select pa_char from cobis..cl_parametro where pa_nemonico='NASOF' and pa_producto='CRE'),
   		 'ID_OPERACION'	= (select op_banco from cob_cartera..ca_operacion where op_tramite = tr.tr_tramite),
   		 'MONTO_TOTAL'	= (select sum(am_cuota) from cob_cartera..ca_amortizacion  where am_operacion=tr.tr_numero_op and am_dividendo = (select max(am_dividendo)from cob_cartera..ca_amortizacion  where am_operacion=tr.tr_numero_op)),
   		 'PAGO_SEMANAL'	= (select sum(am_cuota) from cob_cartera..ca_amortizacion  where am_operacion=tr.tr_numero_op and am_dividendo=1),
   		 'PRIMER PAGO'	= ((select convert(varchar(10),di_fecha_ven ,@i_formato_fecha) from cob_cartera..ca_dividendo where di_operacion=tr.tr_numero_op and di_dividendo=1)),
   		 'DIR_BANCO'	= 'Av. Prolongación Paseo de la Reforma No. 500 Col. Lomas de Santa Fe, Delegación Álvaro Obregón',
   		 'CP_BANCO'		= '01219',
   		 'MONTO_LETRAS'	= @w_monto_letras,
   		 'FECHA_LIQ'    = (select convert(varchar(10), op_fecha_liq, @i_formato_fecha) from cob_cartera..ca_operacion where op_tramite = tr.tr_tramite)
      from cr_tramite tr
      where tr_tramite = @i_tramite 
      
   end
   else 
   BEGIN
   
      select  'OFICINA'    =  (select of_nombre from cobis..cl_oficina where of_oficina=tr.tr_oficina),
         'FECHA_CREA'   =  convert(varchar(10),tr_fecha_crea ,@i_formato_fecha),
         'ASESOR'       =  (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial
                              where fu_funcionario = oc_funcionario and oc_oficial=tr.tr_oficial),
         'MONTO'        =  tr_monto,
         'TASA'         = (select ro_porcentaje from cob_cartera..ca_rubro_op where ro_concepto='INT' and ro_operacion=op.op_operacion),
         'NUM_PAGOS'    = (select count(di_dividendo) from cob_cartera..ca_dividendo where di_operacion = op.op_operacion),
         'FECHA_FIN'    = convert(varchar(10),op_fecha_fin ,@i_formato_fecha),
         'TIPO_PLAZO'   = (select valor from cobis..cl_tabla t, cobis..cl_catalogo c 
                              where t.codigo = c.tabla and t.tabla = 'cr_tplazo_ind' and c.codigo = op.op_tdividendo),
         'PLAZO'        = op_plazo,
         'DEUDOR'       = (select de_cliente from cr_deudores where de_tramite = tr.tr_tramite and de_rol = 'D'),
         'GARANTE'      = null,
         'TIPO_CREDITO'	= op_toperacion,
         'CIUD_TR'		= (select ci_descripcion from cobis..cl_ciudad where ci_ciudad =tr.tr_ciudad),
         'DIR_OFI'		= (select of_direccion from cobis..cl_oficina where of_oficina=tr.tr_oficina),
         'APODERADO'	= (select pa_char from cobis..cl_parametro where pa_nemonico='NASOF' and pa_producto='CRE'),
         'ID_OPERACION'	= (select op_banco from cob_cartera..ca_operacion where op_tramite = tr.tr_tramite),
         'MONTO_TOTAL'	= (select sum(am_cuota) from cob_cartera..ca_amortizacion  where am_operacion=op.op_operacion and am_dividendo = (select max(am_dividendo)from cob_cartera..ca_amortizacion  where am_operacion=op.op_operacion)),
         'PAGO_SEMANAL'	= (select sum(am_cuota) from cob_cartera..ca_amortizacion  where am_operacion=op.op_operacion and am_dividendo=1),
         'PRIMER PAGO'	= ((select convert(varchar(10),di_fecha_ven ,@i_formato_fecha) from cob_cartera..ca_dividendo where di_operacion=op.op_operacion and di_dividendo=1)),
         'DIR_BANCO'	   = 'Av. Prolongación Paseo de la Reforma No. 500 Col. Lomas de Santa Fe, Delegación Álvaro Obregón',
         'CP_BANCO'		= '01219',
         'MONTO_LETRAS'	= @w_monto_letras,
         'FECHA_LIQ'    = convert(varchar(10), op_fecha_liq, @i_formato_fecha)
      from cr_tramite tr, cob_cartera..ca_operacion op
      where op_tramite = tr_tramite
      and tr_tramite = @i_tramite
 
   end
   
   if @@rowcount=0
   begin
      exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 2110316 --"NO EXISTE TRAMITE"
      return 2110316
   end
end

if(@i_operacion='C')
BEGIN

   select @w_tipo_telefono=pa_char
         from cobis..cl_parametro
         where pa_nemonico='TTD'

   select @w_tipo_telefono_cel=pa_char
         from cobis..cl_parametro
         where pa_nemonico='TTC'

    if(@i_tipo_cliente ='D')
    begin
		select @w_ente	=	tr_cliente
		from cr_tramite
		where tr_tramite = @i_tramite
    end
  /*	else
	begin
		select @w_ente	=	tr_alianza
		from cr_tramite
		where tr_tramite = @i_tramite
	end*/
   
   /* Obtener ciclo individual */
   select @w_ciclo = count(*) from cob_cartera..ca_operacion 
   where op_cliente = @w_ente
   and op_toperacion = @w_toperacion
   and op_tramite <> @i_tramite
   and op_estado not in (@w_est_novigente, @w_est_anulado, @w_est_credito)
   
   if @w_ciclo < 0 or @w_ciclo is null
      select @w_ciclo = 0
   select @w_ciclo = @w_ciclo + 1
   
   select   'ENTE'      =  en.en_ente,
         'NOMBRES'      =  (select UPPER(isnull(en.en_nombre,''))+' ' + UPPER(isnull(en.p_s_nombre,''))+' '+
	                                         UPPER(isnull(en.p_p_apellido,''))+' '+UPPER(isnull(en.p_s_apellido,''))),
         'RFC'          =  en_nit,
         'CURP'         =  en_ced_ruc,
         'SEXO'         =  (select c.valor
                        from cobis..cl_catalogo c,cobis..cl_tabla t
                        where c.tabla  =  t.codigo
                        and t.tabla    =  'cl_sexo'
                        and c.codigo =  en.p_sexo),
         'FECHA_NAC'    =  convert(varchar(10),p_fecha_nac ,@i_formato_fecha),
         
         'NACIONALIDAD' =  (select c.valor
                        from cobis..cl_catalogo c,cobis..cl_tabla t
                        where c.tabla  =  t.codigo
                        and t.tabla    =  'cl_nacionalidad'
                        and   c.codigo =  convert(CHAR,en.en_nacionalidad)),
                        
         'DOMICILIO_PART'= (select di_descripcion
                        from cobis..cl_direccion
                        where di_ente = en.en_ente
						and di_principal='S'),
         'COLONIA'      =  (select pq_descripcion
                        from cobis..cl_parroquia
                        where pq_parroquia = (select di_parroquia
                                          from cobis..cl_direccion
                                          where di_ente = en.en_ente
										  and di_principal='S')),
         'CIUDAD'    =  (select ci_descripcion
                        from cobis..cl_ciudad
                        where ci_ciudad = (select di_ciudad
                                          from cobis..cl_direccion
                                          where di_ente = en.en_ente
										  and di_principal='S')),
         'DELEGACION'   =  (select ci_descripcion
                        from cobis..cl_ciudad
                        where ci_ciudad = (select di_ciudad
                                          from cobis..cl_direccion
                                          where di_ente = en.en_ente
										  and di_principal='S')),
         'CP'        =  (select di_codpostal
                        from cobis..cl_direccion
                        where di_ente = en.en_ente
						and di_principal='S'),
         'ESTADO'    =  (select pv_descripcion
                        from cobis..cl_provincia
                        where pv_provincia = (select di_provincia
                                          from cobis..cl_direccion
                                          where di_ente = en.en_ente
										  and di_principal='S')),
         'TELEFONO'     =  (select te_valor
                        from cobis..cl_telefono
                        where te_tipo_telefono = @w_tipo_telefono
                        and te_ente = en.en_ente
                        and te_direccion = (select di_direccion
                                          from cobis..cl_direccion
                                          where di_ente = en.en_ente
										  and di_principal='S')),
         'CUENTA'    =  ea_cta_banco,
         'OFICINA_CUENTA'= '',
         'CELULAR'      =  (select te_valor
                        from cobis..cl_telefono
                        where te_ente=en.en_ente
                        and      te_tipo_telefono=@w_tipo_telefono_cel
                        and      te_fecha_registro = (select max(te_fecha_registro) from cobis..cl_telefono
                                             where te_ente=en.en_ente
                                             and      te_tipo_telefono=@w_tipo_telefono_cel)),
		'CICLO_ACTUAL'	=	@w_ciclo,
		'ESTADO_CIVIL'	=	(select c.valor
							from cobis..cl_catalogo c,cobis..cl_tabla t
							where c.tabla  =  t.codigo
							and t.tabla    =  'cl_ecivil'
							and   c.codigo =  en.p_estado_civil)
		from cobis..cl_ente en, 
		     cobis..cl_ente_aux enx
         where en_ente = @w_ente
         and en_ente= ea_ente


   select  'NOMBRE_NEG'    =  n.nc_nombre,
   
         'NOMBRE DUEÑO'    = (select UPPER(isnull(c.en_nombre,''))+' ' + UPPER(isnull(c.p_s_nombre,''))+' '+
	                                         UPPER(isnull(c.p_p_apellido,''))+' '+UPPER(isnull(c.p_s_apellido,''))),  
	                                         											 
         'DIRECCION'       =  n.nc_calle + convert(varchar(20),nc_nro),
         
         'COLONIA'         =  (select pq_descripcion  from cobis..cl_parroquia where pq_parroquia = convert(INT, n.nc_colonia)),
         
         'CIUDAD'          =  (select ci_descripcion from cobis..cl_ciudad where ci_ciudad = convert(INT,n.nc_municipio)),
         
         'DELEGACION'      =  (select ci_descripcion from cobis..cl_ciudad where ci_ciudad =  convert(INT,n.nc_municipio)),
         
         'CP'              =  n.nc_codpostal,
         
         'ESTADO'          =  (select pv_descripcion from cobis..cl_provincia  where pv_provincia =  convert(INT,n.nc_estado)),
         
         'TELEFONO'        =  n.nc_telefono
      from cobis..cl_negocio_cliente n,
            cobis..cl_ente c
      where nc_ente=@w_ente
      and nc_ente=en_ente
      and nc_fecha_apertura = (select min(nc_fecha_apertura)
                           from cobis..cl_negocio_cliente
                           where nc_ente=@w_ente)
                           
end

if @i_operacion = 'Q2' --RPT Cargo Recurrente INDIV
begin
   select 'NOMBRE_CLI'   = en_nomlar,
          'NUM_CTA_TARJ' = ea_cta_banco,
          'MONTO_MAX'    = @w_monto_max_fijo,
          'PERIODICIDAD' = td_descripcion,
          'FECH_VENC'    = op_fecha_fin,
          'NUM_CREDITO'  = op_banco
     from cob_cartera..ca_operacion,
          cobis..cl_ente,
          cobis..cl_ente_aux,
          cob_cartera..ca_tdividendo
    where op_operacion  = @w_operacion
      and en_ente = op_cliente
      and en_ente    = ea_ente
      and op_tdividendo = td_tdividendo
    order by ea_ente
   return 0
end --@i_operacion='Q2' FIN

if @i_operacion = 'E' -- Para reporte Credito Revolvente
begin
   declare @w_direcion varchar(250)
   select @w_direcion  = (select pa_char from cobis..cl_parametro where pa_nemonico = 'LPGCC1' and pa_producto = 'CRE') +
                         (select pa_char from cobis..cl_parametro where pa_nemonico = 'LPGCC2' and pa_producto = 'CRE') +
                         (select pa_char from cobis..cl_parametro where pa_nemonico = 'LPGCC3' and pa_producto = 'CRE') +
                         (select pa_char from cobis..cl_parametro where pa_nemonico = 'LPGCC4' and pa_producto = 'CRE') +
                         (select pa_char from cobis..cl_parametro where pa_nemonico = 'LPGCC5' and pa_producto = 'CRE') +
						 (select pa_char from cobis..cl_parametro where pa_nemonico = 'LPGCC6' and pa_producto = 'CRE')

   select 'ID_ENTE'       = en.en_ente,
          'NOMBRE'        = (select UPPER(isnull(en.en_nombre,''))+' ' + UPPER(isnull(en.p_s_nombre,''))+' '+
	                                         UPPER(isnull(en.p_p_apellido,''))+' '+UPPER(isnull(en.p_s_apellido,''))),
		  'FECHA'         = (select convert(varchar(10), fp_fecha, @i_formato_fecha) from cobis..ba_fecha_proceso),
		  'CIUDAD_TRAM'   = (select  ci.ci_descripcion from cobis..cl_ciudad ci, cobis..cl_oficina where of_oficina = tr.tr_oficina and of_ciudad = ci_ciudad),
		  'NOM_INCL_UNO'  =(select isnull(pa_char,'') from cobis..cl_parametro where pa_nemonico = 'NF1CCI' and pa_producto = 'CRE'),
		  'NOM_INCL_DOS'  =(select pa_char from cobis..cl_parametro where pa_nemonico = 'NF2CCI' and pa_producto = 'CRE'),
		  'NOM_BANCO_UNO' =(select pa_char from cobis..cl_parametro where pa_nemonico = 'NB1CCI' and pa_producto = 'CRE'),
		  'NOM_BANCO_DOS' =(select pa_char from cobis..cl_parametro where pa_nemonico = 'NB2CCI' and pa_producto = 'CRE'),
		  'NUM_REGISTRO'  =(select pa_char from cobis..cl_parametro where pa_nemonico = 'RDADHR' and pa_producto = 'CRE'),
		  'DIR_LUG_PAGO'  = @w_direcion,
		  'MONTO'         = 60.00
   from  cr_tramite tr, cobis..cl_ente en
   where tr_tramite = @i_tramite
   and   tr_cliente = en_ente 
   return 0
end --@i_operacion='E' FIN

go
