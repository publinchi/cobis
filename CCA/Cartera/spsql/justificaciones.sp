/************************************************************************/
/*      Archivo:                justificaciones.sp                      */
/*      Stored procedure:       sp_justificacion_finan                  */
/*      Producto:               Cartera                                 */
/*      Disenado por:           RRB                                     */
/*      Fecha de escritura:     Ago 2010                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera datos para el reporte                                    */
/*      de justificaciones financieras                                  */
/************************************************************************/

use cob_cartera
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'sp_justificacion_finan')
   drop proc sp_justificacion_finan
go

---ORS 673 partiendo dela ver 30 OCT.2013

create proc sp_justificacion_finan
   @i_param1  varchar(10)  , --Archivo fecha carga
   @i_param2  varchar(10)    --Reprocesa (S/N)
as

declare 
@w_sp_name            varchar(32),
@w_error              int,
@w_tramite            int,
@w_est_vigente        tinyint,
@w_est_vencido        tinyint,
@w_est_cancelado      tinyint,
@w_est_castigado      tinyint,
@w_est_suspenso       tinyint,
@w_pa_char_tdn        char(3),
@w_archivo            varchar(8),
@w_reproceso          char(1),
@w_fecha_proceso      datetime,
@w_fecha_liq          datetime,
@w_operacion          int,
@w_saldo_op           money,
@w_garantia           money,
@w_s_app              varchar(250),
@w_cmd                varchar(250),
@w_path               varchar(250),
@w_comando            varchar(500),
@w_batch              int,
@w_errores            varchar(255),
@w_destino            varchar(255),
@w_error_jus          varchar(60),
@w_activos_fijos      money,
@w_tasa_oper          float,
@w_tasa_inter         float,
@w_justificado        money,
@w_fecha_ini          datetime,
@w_fecha_fin          datetime,
@w_linea_jus          catalogo,
@w_tasa_pasiva        float,
@w_monto_str          varchar(60),
@w_a_justificar       money,
@w_nit_banco          varchar(24),
@w_fondo              catalogo,
@w_banco              cuenta,
@w_est_jus            char(1),
@w_numero             varchar(20),
@w_codeudor           char(1),
@w_sup_hipoteca       catalogo,
@w_valor_gar_hipo     varchar(20),
@w_cod_hipoteca       catalogo,
@w_AECI               char(2),
@w_tr_destino         catalogo,
@w_destino_bancoldex  char(2),
@w_destino_plano      char(2),
@w_destino_bancoldex_AECI  char(2),
@w_fi_fecha_nacimiento     char(8),
@w_fi_escolaridad          catalogo,
@w_estudio_bancoldex       char(2),
@w_fi_tipo_sociedad        catalogo,
@w_tipo_soc_bancoldex      char(2),
@w_fi_amortizacion         catalogo,
@w_amortizacion_bancoldex  char(1),
@w_fi_tipo_nit             catalogo,
@w_Tdoc_bancoldex          char(1),
@w_cod_gar_1               char(2),
@w_fi_genero               catalogo,
@w_en_subtipo              catalogo,
@w_mi_num_trabaj_remu      char(3),
@w_fi_ciudad               varchar(5),
@w_ciu_bancoldex           varchar(5),
@w_fecVence_opBAncoldex    datetime,
@w_fi_fecha_vencimiento    datetime,
@w_fecha_maxima            datetime,
@w_valida_fecha_ven        datetime,
@w_SMV                     money,
@w_smlv_ini                money,
@w_smlv_sup                money,
@w_tipo_productor          catalogo,
@w_nro_activos_fijos       money,
@w_tramite_U_T             catalogo


truncate table ca_justifica_fina 
truncate table ca_justificaciones_err
truncate table ca_planoBancoldexJustifica 
truncate table ca_planoBancoldexJustifica_33

---NOTA. A solicitud del banco en hoja Ecel ORS-324 el tipo de garantia Hipoteca y prendaria esta pendiente aun
---       por eso no se utiliza el catalogo  de homologacioens de tipo de garantia en 
---      'T139','HOMOLOGACION CLASES DE GARANTIAS  PARa BANCOLDEX'

select @w_SMV      = pa_money 
from   cobis..cl_parametro with (nolock)
where  pa_producto  = 'ADM'
and    pa_nemonico  = 'SMV'

--PARAEMTRO QUE INDICA QUE SE INLCUYAN O NO LOS TRAMITES TIPO UTILIZACION y CUPO
select @w_tramite_U_T  = pa_char 
from   cobis..cl_parametro with (nolock)
where  pa_producto  = 'CCA'
and    pa_nemonico  = 'BDEXP2'


select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_valida_fecha_ven = dateadd(mm,1,@w_fecha_proceso)

select @w_nit_banco = replace(fi_ruc, '-','')
from cobis..cl_filial
where fi_filial = 1
	

select 
@w_archivo   = @i_param1, --Archivo fecha carga
@w_reproceso = @i_param2   --Reprocesa (S/N)


select @w_path = ba_path_destino 
from cobis..ba_batch 
where ba_arch_fuente = 'cob_cartera..sp_justificacion_finan'

if @@rowcount = 0 begin
   insert into ca_justificaciones
   select @w_fecha_proceso, @w_archivo, 0 , @w_fecha_proceso, 'E', @w_justificado, 'ERROR no se encuentra el sp en la tabla ba_batch'
   goto ERROR_JUSTIFICACION
end


select @w_s_app = pa_char 
from cobis..cl_parametro 
where pa_producto = 'ADM' 
and pa_nemonico = 'S_APP'

select @w_justificado = 0, @w_a_justificar = 0
    
--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_suspenso   = @w_est_suspenso  out

--- CODIGO TELEFONO DEL NEGOCIO 
select @w_pa_char_tdn = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'TDN'

delete ca_justificaciones
where ju_archivo    = @w_archivo 
and   ju_fecha      = @w_fecha_proceso
and   ju_estado_jus = 'E'

if @w_reproceso = 'S' begin

   delete ca_carga_justificaciones
   where cj_archivo = @w_archivo
   
   delete ca_justificaciones
   where ju_archivo = @w_archivo 
   
end

----- CONTROL PARA NO PROCESAR DOS VECES EL MISMO ARCHIVO 

if exists (select 1 from ca_carga_justificaciones where cj_archivo = @w_archivo)
begin
   insert into ca_justificaciones
   select @w_fecha_proceso, @w_archivo, 0 , @w_fecha_proceso, 'E', @w_justificado, 'Error archivo ya procesado'
   goto ERROR_JUSTIFICACION
end

--- cargar archivo plano con parametros de ejecucion -- Archivo entregado por el banco 
select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_carga_justificaciones in '
select @w_destino = @w_path + @w_archivo + '.txt', @w_errores  = @w_path + @w_archivo + '.err'
select @w_comando = @w_cmd + @w_path + @w_archivo + '.txt ' + '-b5000 -c -e' + @w_errores + ' -t"' + char(167) + '" ' + '-config '+ @w_s_app + 's_app.ini'
exec   @w_error   = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error Carga Parametros Revisar Estructura y Ubicacion'
   print @w_comando 
   return 1
end

update ca_carga_justificaciones set 
cj_fecha_carga  = @w_fecha_proceso,
cj_archivo      = @w_archivo,
@w_fecha_ini    = cj_fecha_incio,
@w_fecha_fin    = cj_fecha_fin,
@w_linea_jus    = cj_linea_jus,
@w_tasa_pasiva  = cj_tasa,
@w_a_justificar = cj_monto_jus,
@w_numero       = cj_numero,
@w_AECI         = cj_aeci,
@w_destino_plano  = cj_destino_bancoldex,
@w_fecVence_opBAncoldex = cj_fecVence_opBAncoldex
where cj_fecha_carga is null and cj_archivo is null

if @@rowcount <> 1 begin
   insert into ca_justificaciones
   select @w_fecha_proceso, @w_archivo, 0 , @w_fecha_proceso, 'E', @w_justificado, 'Error Carga Parametros Revisar Estructura y Ubicacion'
   goto ERROR_JUSTIFICACION
end

---hasta esta fecha deben llegar los vencimientos de los creditos a justificar
select @w_fecha_maxima = @w_fecVence_opBAncoldex

	
select @w_fondo = codigo 
from cob_credito..cr_corresp_sib
where tabla      = 'T111'
and   codigo_sib = @w_linea_jus

if @@rowcount = 0 begin
   insert into ca_justificaciones
   select @w_fecha_proceso, @w_archivo, 0 , @w_fecha_proceso, 'E', @w_justificado, 'No existe fondo parametrizado en la tabla T111 (cr_corresp_sib)'
   goto ERROR_JUSTIFICACION
end

--- SE REPORTAN TODAS LAS OPERACIONES DEL ORIGEN DE FONDO A REPORTAR DESEMBOLSADAS EN EL RANGO DE FECHAS 
select
op_banco,
op_operacion,
op_cliente,
op_tramite,
op_nombre,
op_monto,
op_monto_aprobado,
op_fecha_liq,
op_fecha_fin,
op_codigo_externo,
op_origen_fondos,
ro_tasa_int        = convert(varchar(10),'0.00'),
di_desc            = convert(varchar(50),''),
di_ciud            = convert(int,0),
di_dire            = convert(int,0),
cedula             = convert(varchar(11),''),
actividad          = convert(varchar(10),''),
sexo               = convert(varchar(10),''),
tipo_doc           = convert(varchar(10),''),
activos            = convert(money,0),
telefono           = convert(varchar(15),''),
fecha_nac          = convert(varchar(8),''),
patri_br           = 0,
subtipo            = 'P',
op_oficina,
escolaridad        = convert(varchar(10),''),
sociedad           = convert(varchar(10),''),
op_gracia_cap,
op_tdividendo
into #operaciones
from ca_operacion 
where op_estado in (@w_est_vigente,@w_est_vencido,@w_est_castigado,@w_est_suspenso)
and   op_fecha_liq  between @w_fecha_ini and @w_fecha_fin
and   op_toperacion    <> 'ALT_FNG'   
and   op_origen_fondos = @w_fondo
if @@rowcount = 0 begin
   PRINT  'No hay datos para los parametros del archvio de carga @w_fondo' + cast (@w_fondo as varchar)
end
	
--- NO TOMAR EN CUENTA LOS TRAMITES DE TIPO tr_tipo not in ('T', 'U') 
--- SOLO SI EL PARAMTRO ESTA EN N
if @w_tramite_U_T = 'N'
begin
	delete #operaciones
	from cob_credito..cr_tramite
	where tr_tramite = op_tramite
	and   tr_tipo in ('T', 'U')
end
-- BUSCAR LA TASA DE INTERES DE LA OPERACION 
update #operaciones set
ro_tasa_int = isnull(substring(convert(varchar,isnull(round(ro_porcentaje_efa,2),'00.00')) ,1,5) , '00.00') 
from cob_cartera..ca_rubro_op
where ro_operacion = op_operacion
and   ro_concepto = 'INT'

--- BUSCAR LA DIRECCION PRINCIPAL DEL CLIENTE 
update #operaciones set
di_desc = substring(di_descripcion,1,50),
di_dire = di_direccion
from cobis..cl_direccion
where di_ente       = op_cliente
and   di_direccion = 1

--- BUSCAR LA CIUDAD 
update #operaciones set
di_ciud = convert(char(5),of_ciudad)
from cobis..cl_oficina
where of_oficina = op_oficina

--- BUSCAR LOS DATOS DEL CLIENTE

update #operaciones set
cedula    = en_ced_ruc,
escolaridad = p_nivel_estudio,
actividad = en_actividad,
sociedad  = c_tipo_soc,
activos   = c_total_activos,
fecha_nac = convert(varchar(8),p_fecha_nac,112),
patri_br  = isnull(year(en_fecha_patri_bruto),year(op_fecha_liq)),
sexo      = p_sexo,
tipo_doc  = en_tipo_ced
from cobis..cl_ente
where op_cliente = en_ente

--- BUSCAR EL TELEFONO DE LA DIRECCION DE NEGOCIO 
select
te_ente     = te_ente,
te_telefono = case when te_prefijo <> '' then ltrim(rtrim(te_prefijo)) + isnull(te_valor,0) else te_valor end
into #telefonos
from cobis..cl_direccion, cobis..cl_telefono
where di_ente      = te_ente
and   di_direccion = te_direccion
and   di_tipo      = @w_pa_char_tdn
and   di_ente     in (select distinct op_cliente from #operaciones)

update #operaciones set
telefono = te_telefono
from #telefonos
where te_ente = op_cliente

--- INSERCION EN TABLA TEMPORAL DE LOS DATOS OPERACIONES 
insert into cob_cartera..ca_justifica_fina
select  
fi_operacion          = op_operacion,                                        
fi_tramite            = op_tramite,                                         
fi_num_obligacion     = @w_numero,
fi_intermediario      = op_banco,
fi_tipo_nit           = tipo_doc,
fi_nit                = cedula,
fi_nom_beneficiario   = convert(varchar(50),op_nombre),
fi_tipo_sociedad      = sociedad,
fi_direccion          = convert(varchar(50),isnull(di_desc,'')), 
fi_ciudad             = convert(varchar(5),di_ciud) ,
fi_ciu                = isnull(substring(ltrim(rtrim(actividad)),1,4),'0000') ,   
fi_empleos            = '1', 
fi_empleo_genera      = '1', 
fi_activos            = convert(varchar,isnull(convert(int,activos),'0'))  ,     
fi_fecha_corte_act    = convert(varchar(4),patri_br) , 
fi_valor_credito      = convert(varchar,isnull(convert(int,op_monto),'0')),
fi_destino1           = null,    
fi_monto_destino1     = convert(varchar,isnull(convert(int,op_monto),'0')), 
fi_destino2           = null,
fi_monto_destino2     = null,
fi_destino3           = null,
fi_monto_destino3     = null,                                        
fi_fecha_desembolso   = convert(varchar(8),op_fecha_liq,112), 
fi_fecha_vencimiento  = convert(varchar(8),op_fecha_fin,112), 
fi_clase_credito      = '1',
fi_periodo_gracia     = op_gracia_cap,
fi_amortizacion       = op_tdividendo, 
fi_margen             = convert(varchar(5),'00.00'),  
fi_tasa_interes       = convert(varchar(5),ro_tasa_int),
fi_saldo_credito      = null,              
fi_clase_garan_1      = null,
fi_valor_garan_1      = null,
fi_clase_garan_2      = null,
fi_valor_garan_2      = null,
fi_clase_garan_3      = null,
fi_valor_garan_3      = null,                     
fi_genero             = sexo,            
fi_nit_intermediario  = @w_nit_banco,
fi_linea              = @w_linea_jus,
fi_telefono           = telefono,             
fi_fecha_nacimiento   = fecha_nac,
fi_escolaridad        = escolaridad,                                               
fi_destino            = null                                                                                    
from #operaciones
order by op_fecha_liq , op_operacion

--- ELIMINAR PRESTAMOS YA ENVIADOS EN LOS ARCHIVOS DE JUSTIFICACIONES 
delete cob_cartera..ca_justifica_fina
from ca_justificaciones
where fi_intermediario = ju_banco
and   ju_estado_jus    = 'J'

DECLARE cur_financiero cursor for
select 
fi_operacion, 
fi_tramite,
isnull(fi_activos,0),
fi_fecha_desembolso,
convert(float,fi_tasa_interes),
fi_monto_destino1,
fi_intermediario,
fi_fecha_nacimiento,
fi_escolaridad,
fi_tipo_sociedad,
fi_amortizacion,
fi_tipo_nit,
fi_genero,
fi_ciudad,
fi_fecha_vencimiento
from cob_cartera..ca_justifica_fina
order by convert(datetime,fi_fecha_desembolso) 
for update
   
OPEN cur_financiero

FETCH cur_financiero  INTO
@w_operacion,        @w_tramite,            @w_activos_fijos,
@w_fecha_liq,        @w_tasa_oper,          @w_monto_str,
@w_banco,            @w_fi_fecha_nacimiento,@w_fi_escolaridad,
@w_fi_tipo_sociedad, @w_fi_amortizacion,    @w_fi_tipo_nit ,
@w_fi_genero,        @w_fi_ciudad,          @w_fi_fecha_vencimiento

while @@fetch_status = 0 begin

   if @@fetch_status = -1 begin
      close cur_financiero
      return 1
   end
   
   select 
   @w_error_jus  = '',
   @w_est_jus    = 'J',
   @w_garantia   = 0,
   @w_tasa_inter = convert(varchar(5),round(@w_tasa_oper - @w_tasa_pasiva,2))

   if @w_tasa_oper - @w_tasa_pasiva < 0 begin
       select @w_est_jus   = 'E', @w_error_jus = 'Error Tasa de Intermediacion Inferior a 0 ' + cast(@w_tasa_inter as varchar) 
       goto ERROR
   end           

   exec  @w_error = sp_calcula_saldo
   @i_operacion = @w_operacion, 
   @i_tipo_pago = 'A',
   @o_saldo     = @w_saldo_op out
   
   if @w_error <> 0 begin
      select @w_est_jus   = 'E', @w_error_jus = 'Error al calcular el saldo de la operacion: ' + @w_banco
      goto ERROR
   end
   
   if @w_saldo_op = 0
   begin
      select @w_est_jus   = 'E', @w_error_jus = 'Error Saldo de operacion en 0: ' + @w_banco
      goto ERROR
   end   
    
   select @w_codeudor = '',
          @w_cod_gar_1  = ''
   if exists (select 1 from cob_credito..cr_deudores
              where de_tramite = @w_tramite
              and de_rol = 'C')
   begin           
       select @w_cod_gar_1 = '0'
   end
   else
   begin
       select @w_cod_gar_1 = '3'
   end
   
   select @w_activos_fijos = 0,
          @w_mi_num_trabaj_remu = '1'
   if @w_activos_fijos = 0 begin
   
      select @w_activos_fijos      = mi_total_eyb+ mi_total_cxc +(mi_total_mp+mi_total_pep+ mi_total_pt)+mi_total_af ,
             @w_mi_num_trabaj_remu = convert(varchar(3),mi_num_trabaj_remu)
      from cob_credito..cr_microempresa
      where mi_tramite    = @w_tramite       
      
      if @w_mi_num_trabaj_remu = '0' or @w_mi_num_trabaj_remu is null
         select @w_mi_num_trabaj_remu = '1'      
   end  

     if @w_activos_fijos  =  0 begin
      select @w_est_jus = 'E', @w_error_jus = 'La microempresa del prestamo no tiene activos fijos ' + @w_banco
      goto ERROR
     end

     select @w_tipo_productor = tr_tipo_productor
     from cob_credito..cr_tramite
     where tr_tramite = @w_tramite

	select @w_smlv_ini     = limite_inf, --SMLV
           @w_smlv_sup     = limite_sup  --SMLV
	from cob_credito..cr_corresp_sib
	where codigo = @w_tipo_productor
	and   tabla     = 'T142'
	      	
	select @w_nro_activos_fijos = 0
    select @w_nro_activos_fijos = round(@w_activos_fijos / @w_SMV,0)
    if @w_nro_activos_fijos > @w_smlv_sup
    begin
      select @w_est_jus = 'E', @w_error_jus = 'Error Activos Fijos Superiores al tipo de emrpesa ' + @w_banco
      goto ERROR    
    end

	--- Tipo Documento

	select @w_Tdoc_bancoldex = ''
	select @w_Tdoc_bancoldex = codigo_sib
	from cob_credito..cr_corresp_sib
	where codigo = @w_fi_tipo_nit
	and   tabla     = 'T133'
	if @@rowcount = 0 begin
      select @w_est_jus = 'E', @w_error_jus = 'Tipo Documento no homologa con BAncoldex ' + @w_banco + ' @w_fi_tipo_nit' +  @w_fi_tipo_nit
      goto ERROR
	end
	   
	---Destino 
	
	select @w_tr_destino = tr_destino
	from cob_credito..cr_tramite
	where tr_tramite = @w_tramite
	
    if @w_tr_destino is null
       select @w_tr_destino = '01'  ----para probar en desarrollo
       
	select @w_destino_bancoldex = ''
	select @w_destino_bancoldex = codigo_sib
	from cob_credito..cr_corresp_sib
	where codigo = @w_tr_destino
	and   tabla     = 'T136'
	if @@rowcount = 0 begin
      select @w_est_jus = 'E', @w_error_jus = 'Codigo Destino no homolgoa con bancoldex ' + @w_banco
      goto ERROR
	end
	else
	begin
	   if @w_destino_bancoldex <> @w_destino_plano begin
          select @w_est_jus = 'E', @w_error_jus = 'Codigo Destino Diferente al Enviado en el plano ' + @w_banco
          goto ERROR
	   end   
	end

	---Tipo Sociedad
        if @w_fi_tipo_sociedad is null or @w_fi_tipo_sociedad = ''
        begin
           select @w_tipo_soc_bancoldex = '0'  --Persona Natural
        end
        else
        begin
			select @w_tipo_soc_bancoldex = ''
			select @w_tipo_soc_bancoldex = codigo_sib
			from cob_credito..cr_corresp_sib
			where codigo = @w_fi_tipo_sociedad
			and   tabla     = 'T135'
			if @@rowcount = 0 begin
			   select @w_est_jus = 'E', @w_error_jus = 'Tipo Sociedad no Homologa Con Bancoldex ' + @w_banco
               goto ERROR
			end	
		end

		
    ---Tipo Amortizacion
    
        select @w_amortizacion_bancoldex = ''
		select @w_amortizacion_bancoldex = codigo_sib
		from cob_credito..cr_corresp_sib
		where codigo = @w_fi_amortizacion
		and   tabla     = 'T138'
		if @@rowcount = 0 begin
	      select @w_est_jus = 'E', @w_error_jus = 'Tipo Amortizacion no homolgoa con bancoldex ' + @w_banco
	      goto ERROR
		end	
    	
	--Datos  AECI
    
	if @w_AECI = 'S'
	begin
		select @w_destino_bancoldex_AECI = ''
		select @w_destino_bancoldex_AECI = codigo_sib
		from cob_credito..cr_corresp_sib
		where codigo = @w_tr_destino
		and   tabla     = 'T137'
		if @@rowcount = 0 begin
	      select @w_est_jus = 'E', @w_error_jus = 'Destino AECI no homolgoa con bancoldex ' + @w_banco
	      goto ERROR
		end	
	
		-----ESCOLARIDAD 
		select @w_estudio_bancoldex = null
		select @w_estudio_bancoldex = codigo_sib
		from cob_credito..cr_corresp_sib
		where codigo = @w_fi_escolaridad
		and   tabla     = 'T134'
		if @@rowcount = 0 begin
	      select @w_est_jus = 'E', @w_error_jus = 'Escolaridad no Homologa con bancoldex ' + @w_banco
	      goto ERROR
		end	
		
		select @w_en_subtipo  = en_subtipo 
		from cobis..cl_ente,ca_operacion
		where op_tramite = @w_tramite
		and   op_cliente = en_ente
		
		if @w_en_subtipo = 'C'
		begin
		   select @w_fi_genero = '3'
		end
		else
		 begin
			if  @w_fi_genero = 'M' 
			   select @w_fi_genero = '1'
			else
			 if  @w_fi_genero = 'F' 
			     select @w_fi_genero = '2'
	     end
		
	end
	else
	begin
	    ---LOs tres campos van en vacio 
	    select @w_destino_bancoldex_AECI = null,
	           @w_fi_fecha_nacimiento = null,
	           @w_estudio_bancoldex = null,
	           @w_fi_genero = null
	end

	--- Ciudad

	select @w_ciu_bancoldex = @w_fi_ciudad
	select @w_ciu_bancoldex = codigo_sib
	from cob_credito..cr_corresp_sib
	where codigo = @w_fi_ciudad
	and   tabla     = 'T140'
	if @@rowcount = 0 begin
      select @w_est_jus = 'E', @w_error_jus = 'Ciudad no homologa con BAncoldex ' + @w_banco + ' @w_ciu_bancoldex' +  @w_ciu_bancoldex
      goto ERROR
	end
	
	----validacion de fecha de vencimiento
	
	if @w_fi_fecha_vencimiento > @w_fecha_maxima
	begin
      select @w_est_jus = 'E', @w_error_jus = 'FEcha de ven supera el maximo ' + @w_banco + ' @w_fecha_maxima' + cast(@w_fecha_maxima as varchar)
      goto ERROR
	end

	---AL fecha de vencimiento no puede ser mayor a la fecha actaul  + unmes		
	if @w_fi_fecha_vencimiento < @w_valida_fecha_ven
	begin
      select @w_est_jus = 'E', @w_error_jus = 'Fecha de ven supera minimo ' + @w_banco + ' @w_valida_fecha_ven' +  cast (@w_valida_fecha_ven as varchar)
      goto ERROR
	end

   ERROR:   

   insert into ca_justificaciones values(
   @w_fecha_proceso,   @w_archivo,    @w_banco , 
   @w_fecha_liq,       @w_est_jus,    @w_monto_str, 
   @w_error_jus)

   
   if @w_est_jus = 'J' begin
   
      update ca_justifica_fina set 
      fi_saldo_credito    = convert(varchar,convert(int,@w_saldo_op)), 
      fi_clase_garan_1    = @w_cod_gar_1,
      fi_valor_garan_1    = convert(varchar,convert(int,@w_monto_str)), 
      fi_activos          = convert(varchar,convert(int,@w_activos_fijos)),
      fi_margen           = @w_tasa_inter,
      fi_destino1         = @w_destino_bancoldex,
      fi_fecha_nacimiento = @w_fi_fecha_nacimiento,
      fi_escolaridad      = @w_estudio_bancoldex,
      fi_tipo_sociedad    = @w_tipo_soc_bancoldex,
      fi_amortizacion     = @w_amortizacion_bancoldex,
      fi_genero           = @w_fi_genero,
      fi_tipo_nit         = @w_Tdoc_bancoldex,
      fi_destino          = @w_destino_bancoldex_AECI,
      fi_empleo_genera    = @w_mi_num_trabaj_remu,
      fi_ciudad           = @w_ciu_bancoldex
      where fi_intermediario = @w_banco ---current of cur_financiero
      
      ---  print 'en el cursor va @w_a_justificar ' + cast  (@w_a_justificar as varchar)
       
      select @w_justificado = @w_justificado + convert(money,@w_monto_str)
      
   end
   
   if @w_justificado >= @w_a_justificar break
   
   FETCH cur_financiero INTO
   @w_operacion,        @w_tramite,            @w_activos_fijos,
   @w_fecha_liq,        @w_tasa_oper,          @w_monto_str,
   @w_banco,            @w_fi_fecha_nacimiento,@w_fi_escolaridad,
   @w_fi_tipo_sociedad, @w_fi_amortizacion,    @w_fi_tipo_nit,
   @w_fi_genero,        @w_fi_ciudad,          @w_fi_fecha_vencimiento
  
end
 
close cur_financiero
deallocate cur_financiero 

--- Valida monto a justificar solicitado 
if @w_justificado < @w_a_justificar  begin

   delete ca_justificaciones
   where ju_archivo       = @w_archivo 
   and   ju_fecha         = @w_fecha_proceso
   and   ju_estado_jus   <> 'E'

   insert into ca_justificaciones
   select @w_fecha_proceso, @w_archivo, 0 , @w_fecha_proceso, 'E', @w_justificado, 'Valor a Justificar no es cubierto por el Periodo Ingresado'
   
   print 'Valor a Justificar no es cubierto por el Periodo Ingresado @w_justificado' + cast (@w_justificado as varchar) + ' @w_a_justificar ' + cast (@w_a_justificar as varchar  )
   
   goto ERROR_JUSTIFICACION
end
if @w_AECI = 'S'
begin
	insert into ca_planoBancoldexJustifica
	select 
	ltrim(rtrim(fi_nom_beneficiario)), 
	ltrim(rtrim(fi_tipo_nit)),         
	ltrim(rtrim(fi_nit)),              
	ltrim(rtrim(fi_tipo_sociedad)),    
	ltrim(rtrim(fi_direccion)),        
	ltrim(rtrim(fi_telefono)),         
	ltrim(rtrim(fi_ciudad)),           
	ltrim(rtrim(fi_ciu)),              
	ltrim(rtrim(fi_empleos)),          
	ltrim(rtrim(fi_empleo_genera)),    
	ltrim(rtrim(fi_activos)),          
	ltrim(rtrim(fi_fecha_corte_act)),  
	ltrim(rtrim(fi_intermediario)),    
	ltrim(rtrim(fi_valor_credito)),    
	ltrim(rtrim(fi_fecha_desembolso)), 
	ltrim(rtrim(fi_fecha_vencimiento)),
	ltrim(rtrim(fi_periodo_gracia)),   
	ltrim(rtrim(fi_amortizacion)),     
	ltrim(rtrim(fi_tasa_interes)),     
	ltrim(rtrim(fi_margen)),           
	ltrim(rtrim(fi_saldo_credito)),    
	ltrim(rtrim(fi_destino1)),         
	ltrim(rtrim(fi_monto_destino1)),   
	ltrim(rtrim(fi_destino2)),         
	ltrim(rtrim(fi_monto_destino2)),   
	ltrim(rtrim(fi_destino3)),         
	ltrim(rtrim(fi_monto_destino3)),   
	ltrim(rtrim(fi_clase_garan_1)),    
	ltrim(rtrim(fi_valor_garan_1)),    
	ltrim(rtrim(fi_clase_garan_2)),    
	ltrim(rtrim(fi_valor_garan_2)),    
	ltrim(rtrim(fi_clase_garan_3)),    
	ltrim(rtrim(fi_valor_garan_3)),    
	ltrim(rtrim(fi_destino)),          
	ltrim(rtrim(fi_genero)),           
	ltrim(rtrim(fi_fecha_nacimiento)), 
	ltrim(rtrim(fi_escolaridad ))        
	from cob_cartera..ca_justifica_fina, ca_justificaciones 
	where fi_margen       <> '00.00'
	and   fi_intermediario = ju_banco
	and   ju_archivo       = @w_archivo 
	and   ju_fecha         = @w_fecha_proceso
	and   ju_estado_jus   <> 'E'
	order by convert(datetime,fi_fecha_desembolso) 
	----------------------------------------
	--Generar Archivo Plano
	----------------------------------------
	select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_planoBancoldexJustifica out '
	select @w_destino  = @w_path + 'Justificaciones' + '_' + @w_archivo + '.txt',
	       @w_errores  = @w_path + 'Justificaciones' + '_' + @w_archivo + '.err'
	select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e ' + @w_errores + ' -t";" ' + '-config '+ @w_s_app + 's_app.ini'
	
	exec   @w_error = xp_cmdshell @w_comando
	
	if @w_error <> 0 begin
	   print 'Error Generando archivo de Justificaciones AECI = S '
	   print @w_comando 
	   return 1
	end
end
else
begin
	insert into ca_planoBancoldexJustifica_33
	select 
	ltrim(rtrim(fi_nom_beneficiario)), 
	ltrim(rtrim(fi_tipo_nit)),         
	ltrim(rtrim(fi_nit)),              
	ltrim(rtrim(fi_tipo_sociedad)),    
	ltrim(rtrim(fi_direccion)),        
	ltrim(rtrim(fi_telefono)),         
	ltrim(rtrim(fi_ciudad)),           
	ltrim(rtrim(fi_ciu)),              
	ltrim(rtrim(fi_empleos)),          
	ltrim(rtrim(fi_empleo_genera)),    
	ltrim(rtrim(fi_activos)),          
	ltrim(rtrim(fi_fecha_corte_act)),  
	ltrim(rtrim(fi_intermediario)),    
	ltrim(rtrim(fi_valor_credito)),    
	ltrim(rtrim(fi_fecha_desembolso)), 
	ltrim(rtrim(fi_fecha_vencimiento)),
	ltrim(rtrim(fi_periodo_gracia)),   
	ltrim(rtrim(fi_amortizacion)),     
	ltrim(rtrim(fi_tasa_interes)),     
	ltrim(rtrim(fi_margen)),           
	ltrim(rtrim(fi_saldo_credito)),    
	ltrim(rtrim(fi_destino1)),         
	ltrim(rtrim(fi_monto_destino1)),   
	ltrim(rtrim(fi_destino2)),         
	ltrim(rtrim(fi_monto_destino2)),   
	ltrim(rtrim(fi_destino3)),         
	ltrim(rtrim(fi_monto_destino3)),   
	ltrim(rtrim(fi_clase_garan_1)),    
	ltrim(rtrim(fi_valor_garan_1)),    
	ltrim(rtrim(fi_clase_garan_2)),    
	ltrim(rtrim(fi_valor_garan_2)),    
	ltrim(rtrim(fi_clase_garan_3)),    
	ltrim(rtrim(fi_valor_garan_3))
	from cob_cartera..ca_justifica_fina, ca_justificaciones 
	where fi_margen       <> '00.00'
	and   fi_intermediario = ju_banco
	and   ju_archivo       = @w_archivo 
	and   ju_fecha         = @w_fecha_proceso
	and   ju_estado_jus   <> 'E'
	order by convert(datetime,fi_fecha_desembolso) 
	----------------------------------------
	--Generar Archivo Plano Sin AECI 33 campos no mas
	----------------------------------------
	select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_planoBancoldexJustifica_33 out '
	select @w_destino  = @w_path + 'Justificaciones' + '_' + @w_archivo + '.txt',
	       @w_errores  = @w_path + 'Justificaciones' + '_' + @w_archivo + '.err'
	select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e ' + @w_errores + ' -t";" ' + '-config '+ @w_s_app + 's_app.ini'
	
	exec   @w_error = xp_cmdshell @w_comando
	
	if @w_error <> 0 begin
	   print 'Error Generando archivo de Justificaciones Sin AECI'
	   print @w_comando 
	   return 1
	end

end

----------------------------------------
--Generar Archivo Plano ERRORES
----------------------------------------
ERROR_JUSTIFICACION:

insert into ca_justificaciones_err 
select * 
from ca_justificaciones 
where ju_estado_jus = 'E' 
and   ju_archivo    = @w_archivo 
and   ju_fecha      = @w_fecha_proceso

if @@rowcount > 0 begin
   select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_justificaciones_err out '
   select @w_destino = @w_path + 'Justificaciones_' + @w_archivo + '.err ', @w_errores  = @w_path + 'Justificaciones_' + @w_archivo + '.fail'
   select @w_comando = @w_cmd + @w_path + 'Justificaciones_' + @w_archivo + '.err ' + '-b5000 -c -e ' + @w_errores + ' -t"' + char(167) + '" ' + '-config '+ @w_s_app + 's_app.ini'
   exec   @w_error   = xp_cmdshell @w_comando
   if @w_error <> 0 begin
      print 'Error generando Archivo Errores Bancoldex'
      print @w_comando
      return 1
   end
   
end

return 0
   
go



