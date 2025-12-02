/************************************************************************/
/*      Archivo:                ca_maestro_cartera.sp                    */
/*      Stored procedure:       sp_maestro_cartera                       */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Andres Diab                              */
/*      Fecha de escritura:     Octubre 2008                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.	                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Sp para el reporte maestro cartera                              */
/************************************************************************/


use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_maestro_cartera')
   drop proc sp_maestro_cartera
go
create proc sp_maestro_cartera

as
declare

@w_operacionca         int,
@w_tipo_operacion      varchar(10),
@w_fecha_concesion     datetime,
@w_monto               money,
@w_num_cuotas          smallint,
@w_oficial_act         smallint,
@w_period_cuota        smallint,
@w_saldo_cap           money,
@w_dias_vto_div        int,
@w_ejecutivo_act       smallint,
@w_oficina             smallint,
@w_tasa                float,
@w_fecha_ult_pago      datetime,

@w_tipo_credito  	  char(1),
@w_ejecutivo_org	  smallint,
@w_sujcred		  varchar(10),
@w_sector		  varchar(10),
@w_mercado		  varchar(10),
@w_mercado_obj  	  varchar(10),

@w_op_tplazo              varchar(10),
@w_op_plazo               smallint,
@w_ente                   int,
@w_destino                varchar(10),
@w_op_tramite      	  int,

@w_num_hijos		  tinyint,
@w_personas_cargo         tinyint, 
@w_estrato		  varchar(10),
@w_activ_econ		  varchar(10),
@w_procedencia           char(10),

@w_tipoced		  varchar(10),
@w_cedruc		  varchar(30),
@w_nombre		  varchar(20),
@w_papellido		  varchar(20),
@w_sapellido		  varchar(20),
@w_fecha_nac		  varchar(10),
@w_edad			  smallint,
@w_genero		  char(1),
@w_descecivil		  varchar(64),
@w_tvivienda		  varchar(10),
@w_nivelest		  varchar(10),
@w_ciudad_dom             varchar(15),
@w_parroquia_dom          varchar(15),
@w_barrio_dom             varchar(15),
@w_direccion_dom          varchar(30),
@w_telefono_dom		  varchar(16),
@w_ciudad_neg             varchar(15),
@w_parroquia_neg          varchar(15),
@w_barrio_neg             varchar(15),
@w_direccion_neg          varchar(30),
@w_telefono_neg		  varchar(16),

@w_aval			  varchar(50),
@w_codeudor1		  varchar(50),
@w_codeudor2   		  varchar(50),
@w_codeudor3 		  varchar(50),
 
@w_coy_papellido 	  varchar(20),
@w_coy_sapellido 	  varchar(20),
@w_coy_nombres   	  varchar(20),
@w_coy_tipodoc   	  varchar(10),
@w_coy_documento 	  varchar(30),

@w_antiguedad		  datetime,
@w_experiencia            int,
@w_tot_activos		  money,
@w_tot_pasivos		  money,
@w_tot_patrimonio	  money,

@w_no_creditos            smallint,
@w_ci_nota 		  tinyint,

@w_saldo_mora		  money,
@w_tasa_mora		  float,
@w_tasa_comision	  float,
@w_ie_num_cuotas_enmora   smallint,

@w_liq_disp               money,
@w_gastos_pers 		  money,
@w_gastos_gral            money,
@w_gastos_fin   	  money,
@w_ing_brutos             money,
@w_total_ia               money,
@w_tot_dec_jurada  	  money,

@w_tipo_garantia          varchar(50), 
@w_tot_garantia           money, 

@w_par_direccion_neg      char(3),
@w_par_direccion_res      char(3),
@w_error		  int,
@w_var			  int,
@w_op_banco       varchar(24)


/* TIPO DE DIRECCION DE RESIDENCIA */
select @w_par_direccion_res = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'MIS'
and   pa_nemonico = 'TDR'
                
/* TIPO DE DIRECCION DE NEGOCIO */
select @w_par_direccion_neg = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'MIS'
and   pa_nemonico = 'TDN'

select @w_var = ''


/*CURSOR*/
declare cursor_maestro cursor
for

select op_operacion, -- NUMERO OPERACION
       op_cliente,    -- COD ENTE
       op_destino, -- DESTINO ECONOMICO
       op_tramite,  --NUMERO TRAMITE
       op_tplazo,  -- TIPO PLAZO
       op_plazo,    -- PLAZO
       tr_tipo_credito, -- TIPO DE CREDITO
       tr_oficial, -- EJECUTIVO ORIGINAL
       tr_sector, -- BANCA
       tr_mercado, -- MERCADO
       tr_mercado_objetivo, -- MERCADO OBJETIVO
       tr_sujcred,  -- SUJETO CREDITO
       op_banco
from ca_operacion, cob_credito..cr_tramite
where op_estado in (1,2,4,9)
and   tr_tramite = op_tramite
order by op_cliente

for read only

open cursor_maestro
fetch cursor_maestro
into @w_operacionca,
     @w_ente,
     @w_destino,
     @w_op_tramite,
     @w_op_tplazo,
     @w_op_plazo,
     @w_tipo_credito,
     @w_ejecutivo_org,
     @w_sector,
     @w_mercado,
     @w_mercado_obj,
     @w_sujcred, 
     @w_op_banco

while @@fetch_status = 0
begin
   if (@@fetch_status = -1)
   /*ERROR DE LECTURA DEL CURSOR */
   begin
      print 'ERROR DE LECTURA DEL CURSOR'
      return 123456
   end   


/*DATOS DEL CLIENTE*/

exec cobis..sp_datos_cliente
@i_ente        = @w_ente, 
@i_tipo        = @w_par_direccion_res, --Tipo de direccion que se solicita (char(10))
@i_formato_f   = 101,                  --Formato de fecha
@i_frontend    = 'N',                  --Solicitado desde frontend (S o N)
@o_tipoced = @w_tipoced out, --TIPO DE DOCUMENTO
@o_cedruc  = @w_cedruc out, -- NUMERO IDENTIFICACION
@o_nombre  = @w_nombre out, -- NOMBRES CLIENTE
@o_papellido = @w_papellido out, --PRIMER APELLIDO
@o_sapellido = @w_sapellido out, --SEGUNDO APELLIDO
@o_fecha_nac = @w_fecha_nac out, --FECHA NACIMIENTO
@o_genero    = @w_genero out, --SEXO
@o_descecivil = @w_descecivil out, --ESTADO CIVIL
@o_tvivienda  = @w_tvivienda out, -- TIPO VIVIENDA
@o_nivelest   = @w_nivelest out, -- NIVEL DE ESTUDIO
@o_num_hijos     = @w_num_hijos out,      -- NUMERO DE HIJOS
@o_personas_cargo= @w_personas_cargo out, -- NUMERO PERSONAS A CARGO
@o_activ_econ    = @w_activ_econ out,     -- ACTIVIDAD ECONOMICA
@o_estrato       = @w_estrato out,        -- ESTRATO
@o_procedencia   = @w_procedencia out,    -- PROCEDENCIA 
@o_desciudad   = @w_ciudad_dom     out, --CIUDAD DOMICILIO
@o_desparroquia = @w_parroquia_dom out, -- DEPARTAMENTO DOMICILIO
@o_barrio      = @w_barrio_dom    out, --BARRIO DOMICILIO
@o_telefono    = @w_telefono_dom  out , --TELEFONO DOMICILIO
@o_descripcion = @w_direccion_dom out --DIRECCION DOMICILIO

if @@error <> 0
begin
   select @w_error = @@error                                                                                                                                                                                                                                         
end

if @w_ciudad_dom is null
   select @w_ciudad_dom = 'SIN CIUDAD DOM'

if @w_parroquia_dom is null
   select @w_parroquia_dom = 'SIN DEPTO DOM'

if @w_barrio_dom is null
   select @w_barrio_dom = 'SIN BARRIO DOM'

if @w_telefono_dom is null
   select @w_telefono_dom = 'SIN TELEFONO DOM'

if @w_direccion_dom is null
   select @w_direccion_dom = 'SIN DIRECCION DOM'


--select @w_edad = (select datediff(yyyy, convert(datetime,@w_fecha_nac,103),getdate())) --EDAD 
select @w_edad = datediff(year, @w_fecha_nac, getdate())

                            
exec cobis..sp_datos_cliente
@i_ente        = @w_ente,        --ente del cliente
@i_tipo        = @w_par_direccion_neg, --Tipo de direccion que se solicita (char(10))
@i_formato_f   = 101,                  --Formato de fecha
@i_frontend    = 'N',                  --Solicitado desde frontend (S o N)
@o_desciudad   = @w_ciudad_neg     out, --CIUDAD NEGOCIO
@o_desparroquia = @w_parroquia_neg out, -- DEPARTAMENTO NEGOCIO
@o_barrio      = @w_barrio_neg    out,  -- BARRIO NEGOCIO
@o_telefono    = @w_telefono_neg  out, --TELEFONO NEGOCIO
@o_descripcion = @w_direccion_neg out --DIRECCION NEGOCIO

if @@error <> 0
begin
   select @w_error = @@error                                                                                                                                                                                                                                         
end
                         
if @w_ciudad_neg is null
   select @w_ciudad_neg = 'SIN CIUDAD NEG'

if @w_parroquia_neg is null
   select @w_parroquia_neg = 'SIN DEPTO NEG'

if @w_barrio_neg is null
   select @w_barrio_neg = 'SIN BARRIO NEG'

if @w_telefono_neg is null
   select @w_telefono_neg = 'SIN TELEFONO NEG'

if @w_direccion_neg is null
   select @w_direccion_neg = 'SIN DIRECCION NEG'




/*INFORMACION CONYUGUE*/

-- SI EL CONYUGUE ESTA CREADO COMO CLIENTE 
   select 
      @w_coy_papellido = hi_papellido,
      @w_coy_sapellido = hi_sapellido,
      @w_coy_nombres    = hi_nombre,
      @w_coy_tipodoc   = hi_tipo_doc,
      @w_coy_documento = hi_documento
   from cobis..cl_hijos
   where hi_ente = @w_ente 
   and hi_tipo =  'C'

if @@rowcount !=0
begin
   select 
      @w_coy_papellido = ' ',
      @w_coy_sapellido = ' ',
      @w_coy_nombres   = ' ',
      @w_coy_tipodoc   = ' ',
      @w_coy_documento = ' '
end


/*INFORMACION DE LA OPERACION*/

select @w_tipo_operacion  = do_tipo_operacion, --TIPO DE OPERACION
       @w_fecha_concesion = do_fecha_concesion, --FECHA CONCESION
       @w_monto           = do_monto, -- MONTO DEL CREDITO
       @w_num_cuotas      = do_num_cuotas, -- NUMERO DE CUOTAS
       @w_period_cuota    = do_periodicidad_cuota, -- TIPO DE CUOTA
       @w_saldo_cap       = do_saldo_cap, -- SALDO DE CAPITAL
       @w_dias_vto_div    = do_dias_vto_div, --No. DIAS DE VENCIMIENTO
       @w_ejecutivo_act   = do_gerente, -- EJECUTIVO ACTUAL
       @w_oficina         = do_oficina, -- OFICINA
       @w_tasa            = do_tasa, -- TASA INTERES EFECTIVA ANUAL       
       @w_fecha_ult_pago  = do_fecha_pago --FECHA ULTIMO PAGO

from cob_credito..cr_dato_operacion
where do_numero_operacion = @w_operacionca

select @w_ci_nota = ci_nota --NOTA
from cob_credito..cr_califica_int_mod
where ci_cliente = @w_ente


/*NOMBRES Y APELLIDOS DE LOS AVALISTAS */
Select 
top 1 @w_aval = (en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido) 
from cob_credito..cr_deudores, cobis..cl_ente
where de_rol = 'A'
and de_tramite = @w_op_tramite
and en_ente = de_cliente

/* NOMBRE Y APELLIDOS DE LOS CODEUDORES */
select 
top 1 @w_codeudor1 = (en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido) 
from cob_credito..cr_deudores, cobis..cl_ente
where de_rol = 'C'--not in ('D', 'A')
and de_tramite = @w_op_tramite
and en_ente = de_cliente

select 
top 2 @w_codeudor2 = (en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido)
from cob_credito..cr_deudores, cobis..cl_ente
where de_rol = 'C'-- not in ('D', 'A')
and de_tramite = @w_op_tramite
and en_ente = de_cliente

select 
top 3 @w_codeudor3 = (en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido)
from cob_credito..cr_deudores, cobis..cl_ente
where de_rol  = 'C'--not in ('D', 'A')
and de_tramite = @w_op_tramite
and en_ente = de_cliente


/* INFORMACION DE MICROEMPRESA */
select 
       @w_liq_disp    = mi_dispuf, -- LIQUIDEZ DISPONIBLE
       @w_gastos_pers = mi_total_gp, -- GASTOS PERSONALES
       @w_gastos_gral = mi_total_gg, --GASTOS GENERALES
       @w_gastos_fin  = mi_total_gf, --GASTOS FINANCIEROS
       @w_ing_brutos  = mi_total_vtas, -- INGRESOS BRUTOS (VENTAS)
       @w_total_ia    = mi_total_ia, -- INGRESOS ADICIONALES CLIENTE

       @w_antiguedad    = mi_antiguedad, -- ANTIGUEDAD
       @w_experiencia   = mi_experiencia, --EXPERIENCIA
       @w_tot_activos   = (mi_total_eyb  + mi_total_cxc+mi_total_mp+mi_total_pep +mi_total_pt ) + mi_total_af,--TOTAL_ACTIVOS

       @w_tot_pasivos   = (mi_total_af + mi_total_prc + mi_total_ofc + mi_total_opasc + mi_total_prl + mi_total_ofl + mi_total_opasl),-- TOTAL PASIVOS

       @w_tot_patrimonio = ((mi_total_eyb  + mi_total_cxc+mi_total_mp+mi_total_pep +mi_total_pt ) + mi_total_af) - ((mi_total_af + mi_total_prc + mi_total_ofc + mi_total_opasc + mi_total_prl + mi_total_ofl + mi_total_opasl))  --TOTAL PATRIMONIO 
from cob_credito..cr_microempresa
where mi_tramite = @w_op_tramite


/*CANTIDAD DE CREDITOS QUE HA TENIDO*/
if  @w_var <> @w_ente -- MANEJO DE CLIENTE REPETIDO 
begin
   Select @w_no_creditos = count(*) from ca_operacion
   where op_cliente = @w_ente
   
   select @w_var = @w_ente
end

/*SALDO DE CAPITAL EN MORA (CUOTAS VENCIDAS)*/
Select @w_saldo_mora = sum(am_cuota + am_gracia - am_pagado)
from ca_dividendo,ca_amortizacion
where di_operacion = @w_operacionca
and   di_operacion = am_operacion 
and   di_dividendo = am_dividendo 
and   di_estado    = 2
and   am_concepto = 'CAP'

/*TASA DE MORA*/

select @w_tasa_mora = ro_porcentaje
from ca_rubro_op
where ro_operacion = @w_operacionca
and   ro_concepto  = 'IMO'


/*TASA DE COMISION*/

select @w_tasa_comision = ro_porcentaje
from ca_rubro_op
where ro_operacion = @w_operacionca
and   ro_concepto  = 'MIPYMES'


/*NUMERO DE CUOTAS EN MORA*/
      select @w_ie_num_cuotas_enmora = 0
      
      select @w_ie_num_cuotas_enmora = isnull(count(1),0)
      from   ca_dividendo
      where  di_estado = 2
      and    di_operacion = @w_operacionca

/* TOTAL DECLARACION JURADA */
select @w_tot_dec_jurada = sum(dj_total_bien) 
from cob_credito..cr_dec_jurada
where dj_codigo_mic = @w_op_tramite

/* INFORMACION GARANTIA */
select @w_tipo_garantia = cu_descripcion, 
       @w_tot_garantia  = gp_valor_resp_garantia 
from cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia
where gp_garantia = cu_codigo_externo
and gp_tramite = @w_op_tramite

insert into cob_cartera..ca_maestro_cartera_tmp values
(@w_operacionca,  	 @w_tipo_operacion, 	  @w_fecha_concesion, @w_monto,         	@w_num_cuotas,
 @w_period_cuota, 	 @w_saldo_cap,      	  @w_dias_vto_div,    @w_oficial_act,   	@w_oficina,
 @w_tasa,         	 @w_fecha_ult_pago, 	  @w_tipo_credito,    @w_ejecutivo_org, 	@w_sujcred,
 @w_sector,	  	 @w_mercado,        	  @w_mercado_obj,     @w_op_tplazo,     	@w_op_plazo,
 @w_destino,             @w_num_hijos,      	  @w_personas_cargo,  @w_estrato,       	@w_activ_econ,     
 @w_procedencia,         @w_tipoced,        	  @w_cedruc,          @w_nombre,        	@w_papellido,      
 @w_sapellido,           @w_fecha_nac,      	  @w_edad,            @w_genero,        	@w_descecivil,     
 @w_tvivienda,           @w_nivelest,       	  @w_ciudad_dom,      @w_parroquia_dom, 	@w_barrio_dom,     
 @w_direccion_dom,       @w_telefono_dom,   	  @w_ciudad_neg,      @w_parroquia_neg, 	@w_barrio_neg,     
 @w_direccion_neg,       @w_telefono_neg,   	  @w_aval,            @w_codeudor1,           @w_codeudor2,
 @w_codeudor3,           @w_coy_papellido,  	  @w_coy_sapellido,   @w_coy_nombres,         @w_coy_tipodoc,    
 @w_coy_documento,       @w_antiguedad,     	  @w_experiencia,     @w_tot_activos,         @w_tot_pasivos,    
 @w_tot_patrimonio,      @w_no_creditos,    	  @w_ci_nota,         @w_saldo_mora,          @w_tasa_mora,      
 @w_tasa_comision,       @w_ie_num_cuotas_enmora, @w_liq_disp,        @w_gastos_pers,         @w_gastos_gral,    
 @w_gastos_fin,          @w_ing_brutos,           @w_total_ia,        @w_tot_dec_jurada,      @w_tipo_garantia,  
 @w_tot_garantia,        @w_op_banco
)


fetch cursor_maestro
into @w_operacionca,
     @w_ente,
     @w_destino,
     @w_op_tramite,
     @w_op_tplazo,
     @w_op_plazo,
     @w_tipo_credito,
     @w_ejecutivo_org,
     @w_sector,
     @w_mercado,
     @w_mercado_obj,
     @w_sujcred,
     @w_op_banco
end
close cursor_maestro
deallocate cursor_maestro

return
go
