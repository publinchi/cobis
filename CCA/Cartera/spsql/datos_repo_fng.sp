 /************************************************************************/
/*   Nombre Fisico:        datos_repo_fng.sp                            */
/*   Nombre Logico:        sp_abona_rubro                               */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         EPB                                          */
/*   Fecha de escritura:   Mayo/2007                                    */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Procedimiento que carga datos para la generacionde reportes        */
/*   para el FNG Unicamente procesa operaciones que tengan el rubro     */
/*   comision FNG en cualquiera de sus modalidades                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'tmp_gar_especial')
   drop table tmp_gar_especial
go

create table tmp_gar_especial
(ge_tipo       varchar(64)  null)

go


if exists (select 1 from sysobjects where name = 'sp_repositorio_rep_FNG')
   drop proc sp_repositorio_rep_FNG
go

create proc sp_repositorio_rep_FNG 
@i_fecha               datetime ---Fecha  de fin de mes

as

declare
@w_operacion                int,   
@w_registros                int,
@w_secuencial               int,
@w_tran                     char(3),
@w_valor_febrero            money,
@w_valor_marzo              money,
@w_nit_intermediario        char(9), 
@w_regional                 int,
@w_departamento             int,
@w_ciudad                   int,
@w_oficina                  int,
@w_banco                    cuenta,
@w_cliente                  int,
@w_cedula                   varchar(30),
@w_nombre_completo          varchar(60),
@w_nro_pagare               cuenta,
@w_nro_garantia_fng         cuenta,
@w_moneda                   smallint,
@w_valor_desembosado_pesos  money ,
@w_valor_desembosado_uvr    money,
@w_plazo_meses              smallint,
@w_calificacion_cliente     catalogo,
@w_periodicida_pago         char(15),
@w_saldo_cap                money,
@w_periodo_gracia_meses     smallint,
@w_dir_cliente              varchar(60),
@w_telefono_cliente         varchar(30),
@w_codigo_dep_economica     tinyint,
@w_actividad                catalogo,
@w_cod_dep_ente             catalogo,
@w_ciiu                     catalogo,
@w_tasa_nominal             float,
@w_toperacion               catalogo,
@w_modalidad_comision       catalogo,
@w_tasa_comision            float,
@w_cobertura                money,
@w_destino_credito          char(1),
@w_probabilidad             int,
@w_cuotas_mora              int,
@w_ciudad_vivi_financiada   int,
@w_val_vivi_financiada      money,
@w_dir_vivi_financiada      varchar(60), 
@w_saldo_cap_comision       money,
@w_uvr_calculo_comision     float,
@w_comision_facturada_mes   money,
@w_iva_facturada_mes        money,
@w_total_com_iva_facturada  money,
@w_total_com_iva_recaudada  money,
@w_reversos_com_iva         money,
@w_fecha_liq                datetime,
@w_fecha_inicio_mora        char(10),
@w_fecha_vencimiento        char(10),
@w_fecha_cancelacion        char(10),
@w_fecha_demanda            char(10),
@w_cod_dir                  tinyint,
@w_nom_oficina              varchar(20),
@w_nom_departamento         varchar(20),
@w_nom_regional             varchar(20),
@w_cotizacion_des           float,
@w_fecha_ini_mes            datetime,
@w_fecha_comision           datetime,
@w_cotizacion_calculo       float,
@w_parampagare_cobis        catalogo,
@w_dividendo                smallint,
@w_di_fecha_ven             datetime,
@w_monto                    money,
@w_tramite                  int,
@w_cod_moneda               smallint,
@w_nom_ciudad               varchar(50),
@w_matricula_inmoviliaria   varchar(16),
@w_op_estado                smallint,
@w_ro_concepto              catalogo,
@w_ro_concepto_iva          catalogo,
@w_ro_valor                 money,
@w_ro_fpago                 char(1),
@w_otra_garantia            varchar(30),
@w_tipo_gar_hipotecaria     varchar(30),
@w_tplazo          	       catalogo,
@w_plazo       	          smallint,
@w_tdividendo  	          catalogo,
@w_periodo_int 	          smallint,
@w_gracia_cap               smallint,
@w_dias_plazo               int,
@w_op_destino               catalogo,
@w_dias_div                 int,
@w_asalariado               catalogo,
@w_fecha_cotizacion         datetime,
@w_codigo_per_pago          smallint,
@w_td_tdividendo            catalogo,
@w_nro_fng                  catalogo,
@w_saldo_capital            money,
@w_fecha_saldo              datetime,
@w_cotizacion_cap           float,
@w_reversos_com_iva_des     money,
@w_total_com_iva_recaudada_des money






select @w_registros  = 0,
       @w_probabilidad  = 0.00 --Falta definir en SARC

select @w_fecha_ini_mes = dateadd(mm,-1,@i_fecha)


select @w_parampagare_cobis = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'CODPAG'
and pa_producto = 'GAR'
set transaction isolation level read uncommitted

select @w_asalariado = pa_char 
 from cobis..cl_parametro
where pa_nemonico = 'AASA'
and pa_producto = 'MIS'
set transaction isolation level read uncommitted

--CARGAR TIPOS DE GARANTIAS ESPECIAL
exec  sp_gar_esp_tramite 

--LIMPIAR LAs TABLAS DE TRABAJO
delete ca_repositorio_reporte_FNG WHERE rr_cliente >= 0
delete ca_can_reporte_FNG WHERE ca_banco IS NOT NULL

declare cursor_operacion cursor
for 

select a.opt_operacion
 from  ca_operacion_total a
where a.opt_tipo != 'R'
and opt_estado in (1,2,3,4,9)
and   exists (select 1 from ca_rubro_op
              where ro_operacion = a.opt_operacion 
              and   ro_concepto in (select codigo
                                    from cobis..cl_catalogo a
                                    where a.tabla = (select codigo from cobis..cl_tabla
                                                     where tabla = 'ca_rubros_fng')))

open cursor_operacion

fetch cursor_operacion
into  @w_operacion

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin
   
   
  --INICIALIZAR VARIABLES

      select 
      @w_nit_intermediario        = '',
      @w_regional                 = 0,
      @w_departamento             = 0,
      @w_ciudad                   = 0,        
      @w_oficina                  = 0,
      @w_banco                    = '',
      @w_cliente                  = 0,
      @w_cedula                   = '', 
      @w_nombre_completo          = '', 
      @w_nro_pagare               = '',
      @w_nro_garantia_fng         = '',
      @w_moneda                   = 0, 
      @w_valor_desembosado_pesos  = 0.00,
      @w_valor_desembosado_uvr    = 0.00,   
      @w_plazo_meses              = 0,
      @w_calificacion_cliente     = 'A',    
      @w_periodicida_pago         = '',
      @w_saldo_cap                = 0.00,
      @w_periodo_gracia_meses     = 0,
      @w_dir_cliente              = '',             
      @w_telefono_cliente         = '',
      @w_codigo_dep_economica     = 0,
      @w_ciiu                     = '',
      @w_tasa_nominal             = 0.00,            
      @w_toperacion               = '',
      @w_modalidad_comision       = '',
      @w_tasa_comision            = 0.00,
      @w_cobertura                = 0.00,                
      @w_destino_credito          = '',
      @w_probabilidad             = 0,
      @w_cuotas_mora              = 0,             
      @w_ciudad_vivi_financiada   = 0,
      @w_val_vivi_financiada      = 0.00,
      @w_dir_vivi_financiada      = '',
      @w_saldo_cap_comision       = 0.00,      
      @w_uvr_calculo_comision     = 0.00,
      @w_comision_facturada_mes   = 0.00,  
      @w_iva_facturada_mes        = 0.00,
      @w_total_com_iva_facturada  = 0.00, 
      @w_total_com_iva_recaudada  = 0.00,  
      @w_reversos_com_iva         = 0.00,
      @w_fecha_liq                = null,
      @w_fecha_inicio_mora        = '00/00/0000',       
      @w_fecha_vencimiento        = '00/00/0000',
      @w_fecha_demanda            = '00/00/0000',
      @w_nom_oficina              = '',
      @w_nom_departamento         = '',        
      @w_nom_regional             = '',
      @w_fecha_comision           = null,
      @w_otra_garantia            = '',
      @w_matricula_inmoviliaria   = '',
      @w_actividad                = '',
      @w_nro_fng                  = null,
      @w_saldo_capital            = 0.00,
      @w_cotizacion_cap           = 0.00,
      @w_nom_ciudad               = null,
      @w_reversos_com_iva_des     = 0.00,
      @w_total_com_iva_recaudada_des = 0.00

   
     --DATOS MAESTRA DE CARTERA
     select @w_banco       = op_banco,
            @w_cliente     = op_cliente,
            @w_tramite     = op_tramite,
            @w_cod_dir     = op_direccion,
            @w_oficina     = op_oficina,
            @w_ciudad      = op_ciudad,
            @w_toperacion  = op_toperacion,
            @w_cod_moneda  = op_moneda,
            @w_monto       = op_monto,
            @w_fecha_liq   = op_fecha_liq,
            @w_op_estado   = op_estado,
            @w_tplazo      = op_tplazo,
            @w_plazo       = op_plazo,
            @w_op_destino  = op_destino,
            @w_fecha_vencimiento = convert(char(10),op_fecha_fin,101),
            @w_gracia_cap        = op_gracia_cap,
            @w_periodo_int       = op_periodo_int,
            @w_tdividendo        = op_tdividendo
     from ca_operacion
     where op_operacion = @w_operacion
     
     if @w_cod_dir is null  or @w_cod_dir = 0
        select @w_cod_dir = 1
     
     --DATOS MAESTRA DE CLIENTES
     select @w_cedula               = en_ced_ruc,
            @w_nombre_completo      = substring(en_nombre,1,27) +' ' + substring(p_p_apellido,1,15) +' ' + substring(p_s_apellido,1,15),
            @w_actividad            = en_actividad,
            @w_ciiu                 = en_actividad
     from cobis..cl_ente
     where en_ente = @w_cliente
    
    ---ojoooooooooooo TXX
    if @w_actividad = @w_asalariado
       select @w_codigo_dep_economica = 10
    else
      select @w_codigo_dep_economica = 20
    
    
     ---NIT BAANDO
     select @w_nit_intermediario = fi_ruc
     from cobis..cl_filial
     where fi_abreviatura = 'BAC'
     
     --DATOS DE DIRECCION YTELEFONO
    
      select @w_dir_cliente      = substring(di_descripcion,1,60),
             @w_telefono_cliente = (select te_valor from cobis..cl_telefono where te_direccion = DI.di_direccion and te_ente = DI.di_ente)
      from   cobis..cl_direccion DI
      where  di_direccion  = @w_cod_dir
      and    di_ente       = @w_cliente
      set transaction isolation level read uncommitted
    
      select  @w_nro_garantia_fng = gp_garantia,
              @w_nro_fng          = cu_num_dcto
      from cob_credito..cr_gar_propuesta, 
           cob_custodia..cu_custodia a,
           cob_custodia..cu_tipo_custodia
      where gp_tramite  =   @w_tramite
      and gp_garantia   =  cu_codigo_externo
      and a.cu_tipo       =  tc_tipo
      and   a.cu_estado  != 'C'
      and   exists (select 1 from tmp_gar_especial
                     where ge_tipo = a.cu_tipo)


      if @w_op_estado <> 3 
      begin
            --CODIGOS DEPARTAMENTO Y NOM CIUDAD
              select @w_departamento     = ci_provincia,
                     @w_nom_ciudad       = ci_descripcion
              from cobis..cl_ciudad
              where ci_ciudad = @w_ciudad
            
            ---NOMBRE DEPARTAMENTO
         
               select @w_nom_departamento     = pv_descripcion
               from cobis..cl_provincia
               where pv_provincia = @w_departamento
               
            --REGIONAL NOMBRE REGIONAL
            
            select @w_regional     =  convert(int,codigo),
                   @w_nom_regional = substring(descripcion_sib,1,50)
            
            from cobis..cl_oficina,
                   cob_credito..cr_corresp_sib
            where  of_oficina = @w_oficina
            and   convert(int,codigo) = of_regional
            and   tabla = 'T21'
      
            select @w_nom_oficina = of_nombre
            from cobis..cl_oficina
            where  of_oficina = @w_oficina
            
            
            if @w_cod_moneda  = 0
               select @w_moneda = 1
             else
               select @w_moneda = 2

             if @w_cod_moneda  <> 0
              begin
               
                  select @w_valor_desembosado_uvr = @w_monto

                  exec sp_buscar_cotizacion
                       @i_moneda     = @w_cod_moneda,
                       @i_fecha      = @w_fecha_liq,
                       @o_cotizacion = @w_cotizacion_des output
                  
                  select @w_valor_desembosado_pesos = round(@w_monto * @w_cotizacion_des,0)
              end  
              else
              begin
                  select @w_valor_desembosado_pesos = @w_monto
                  select @w_valor_desembosado_uvr  = 0.00
              end

              
             --SALDO CAPITAL A LA FECHA DE CIERRE EN LA MONEDA DE LA OPERACION
             --ESTE SALDO DEBE SER EL ULTIMO DEL CIERRE DE CARTERA A FIN DE MES

               select @w_fecha_saldo = max(sc_fecha)
               from ca_saldos_cartera_mensual

               select @w_saldo_capital = isnull(sum(sc_valor),0.00)
               from ca_saldos_cartera_mensual,
                    ca_concepto
               where sc_fecha = @w_fecha_saldo
               and sc_operacion = @w_operacion
               and sc_concepto = co_concepto
               and   co_categoria = 'C'            


             if @w_cod_moneda  <> 0
              begin
                  exec sp_buscar_cotizacion
                       @i_moneda     = @w_cod_moneda,
                       @i_fecha      = @w_fecha_saldo,
                       @o_cotizacion = @w_cotizacion_cap output
                  --EL SALDO CAP esa en Moneda nacional en la ca_saldos_Cartera
                  if @w_cotizacion_cap > 0
                     select @w_saldo_cap = round(@w_saldo_capital / @w_cotizacion_cap,4)
                  else
                     select @w_saldo_cap = @w_saldo_capital
                  
              end  
              else
              begin
                  select @w_saldo_cap = @w_saldo_capital
              end

             
             ---CALIFICACION CLIENTE
             select @w_calificacion_cliente = do_calificacion
             from cob_credito..cr_dato_operacion
             where do_codigo_cliente = @w_cliente
       
      
             --DIVIDENDO FACTURADO EN EL MES
             ---PRINT '@w_fecha_ini_mes  %1!  @i_fecha %2!',@w_fecha_ini_mes ,@i_fecha
             
             select @w_dividendo = di_dividendo,
                    @w_di_fecha_ven = di_fecha_ven
             from   ca_dividendo
             where di_operacion = @w_operacion
             and   di_fecha_ven between @w_fecha_ini_mes and @i_fecha
         
             select @w_fecha_cotizacion =  @w_di_fecha_ven   
             select @w_fecha_comision = @w_di_fecha_ven
         
             ---COTIZACION CALCULO COMISION
             
             select @w_uvr_calculo_comision = 1
             if @w_moneda <> 0
             begin
                  exec sp_buscar_cotizacion
                       @i_moneda     = @w_cod_moneda,
                       @i_fecha      = @w_fecha_cotizacion,
                       @o_cotizacion = @w_cotizacion_calculo output
                    
              select @w_uvr_calculo_comision = @w_cotizacion_calculo
            end
            
            --- PAGARE COBIS y Nro GARANTIA ESPECIAL
      
            select @w_nro_pagare = gp_garantia
            from cob_credito..cr_gar_propuesta,
                 cob_custodia..cu_custodia,
                 cob_custodia..cu_tipo_custodia
            where  gp_tramite = @w_tramite
            and cu_codigo_externo = gp_garantia
            and cu_tipo      =  @w_parampagare_cobis
            and cu_tipo = tc_tipo
        
           ---DATOS GARANTIA HIPOTECARIA
      
            select  @w_otra_garantia           = ic_codigo_externo,
                    @w_matricula_inmoviliaria  = ic_valor_item,
                    @w_tipo_gar_hipotecaria    = tc_tipo
            from cob_custodia..cu_item_custodia,
                 cob_custodia..cu_tipo_custodia,
                 cob_credito..cr_gar_propuesta,
                 cob_credito..cr_corresp_sib
            where gp_tramite = @w_tramite
            and   tabla = 'T78'
            and   gp_garantia    = ic_codigo_externo 
            and   ic_item        = convert(int,codigo_sib)
            and   ic_tipo_cust      =  tc_tipo
            and   tc_tipo              = codigo 
            and   ic_codigo_externo = gp_garantia 
      
            select @w_ciudad_vivi_financiada = 0,--cu_ciudad_gar, AGI Comentado por que no existe campo en la estructura cu_custodia
                   @w_val_vivi_financiada    = cu_valor_inicial ,
                   @w_dir_vivi_financiada     = cu_direccion_prenda
             from cob_custodia..cu_custodia
            where cu_codigo_externo = @w_otra_garantia
            
                      
             ---DATOS DE LA COMISION
             
            --SALDO DE CAPITAL A LA FEHA DE CALCULO EN LA MONEDA DE LA OPERACION
            select @w_saldo_cap_comision = sum(am_cuota)
            from   ca_amortizacion
            where am_operacion = @w_operacion
            and   am_concepto = 'CAP'
            and   am_dividendo >= @w_dividendo
            
            
            select @w_ro_concepto = ro_concepto,
                   @w_ro_valor    = ro_valor,
                   @w_ro_fpago    = ro_fpago,
                   @w_tasa_comision = ro_porcentaje
            from   ca_rubro_op
            where ro_operacion = @w_operacion
            and   ro_concepto in (select a.codigo 
                                 from cobis..cl_catalogo a
                                 where a.tabla = (select codigo
                                                  from cobis..cl_tabla 
                                                  where tabla = 'ca_rubros_fng'))
                                                  
            if @w_ro_fpago  = 'L'
               select @w_comision_facturada_mes = @w_ro_valor
            else
               select @w_comision_facturada_mes = am_cuota
               from ca_amortizacion
               where am_operacion = @w_operacion
               and   am_concepto = @w_ro_concepto
               and   am_dividendo = @w_dividendo
            
            select @w_ro_concepto_iva = ro_concepto,
                   @w_ro_valor        = ro_valor,  
                   @w_ro_fpago        = ro_fpago
            from   ca_rubro_op         
            where ro_operacion = @w_operacion         
            and ro_concepto_asociado = @w_ro_concepto
            
      
           if @w_ro_fpago  = 'L'
               select @w_iva_facturada_mes = @w_ro_valor,
                      @w_modalidad_comision = 'U'
            else
            begin
               select @w_iva_facturada_mes = am_cuota
               from ca_amortizacion
               where am_operacion = @w_operacion
               and   am_concepto = @w_ro_concepto_iva
               and   am_dividendo = @w_dividendo
               
               if @w_ro_fpago  = 'A'
                  select @w_modalidad_comision = 'AA'

               if @w_ro_fpago  = 'P'                  
                  select @w_modalidad_comision = 'MENSUAL'
            end         
            
             select @w_total_com_iva_facturada = isnull(@w_comision_facturada_mes,0) + isnull(@w_iva_facturada_mes,0)
             
             --RECAUSOS POR CONCEPTO FNG
             select @w_total_com_iva_recaudada  = isnull(sum(dtr_monto_mn),0.00)
             from ca_transaccion,
                  ca_det_trn
             where tr_operacion = @w_operacion
             and   tr_tran = 'PAG'
             and   tr_fecha_mov  between @w_fecha_ini_mes and @i_fecha
             and   tr_estado in ('CON','ING','RV')
             and   dtr_operacion = @w_operacion
             and   tr_operacion = dtr_operacion
             and   tr_secuencial = dtr_secuencial
             and   dtr_concepto in (@w_ro_concepto,@w_ro_concepto_iva)

             select @w_total_com_iva_recaudada_des  = isnull(sum(dtr_monto_mn),0.00)
             from ca_transaccion,
                  ca_det_trn
             where tr_operacion = @w_operacion
             and   tr_tran = 'DES'
             and   tr_fecha_mov  between @w_fecha_ini_mes and @i_fecha
             and   tr_estado in ('CON','ING','RV')
             and   dtr_operacion = @w_operacion
             and   tr_operacion = dtr_operacion
             and   tr_secuencial = dtr_secuencial
             and   dtr_concepto in (@w_ro_concepto,@w_ro_concepto_iva)             
      
             select @w_total_com_iva_recaudada = @w_total_com_iva_recaudada + @w_total_com_iva_recaudada_des
             
             --REVERSIONES POR CONCEPTO FNG
             select @w_reversos_com_iva  = isnull(sum(dtr_monto_mn),0.00)
             from ca_transaccion,
                  ca_det_trn
             where tr_operacion = @w_operacion
             and   tr_tran = 'PAG'
             and   tr_fecha_mov  between @w_fecha_ini_mes and @i_fecha
             and   tr_estado = 'RV'
             and   dtr_operacion = @w_operacion
             and   tr_operacion = dtr_operacion
             and   tr_secuencial = dtr_secuencial
             and   dtr_concepto in (@w_ro_concepto,@w_ro_concepto_iva)  

             select @w_reversos_com_iva_des  = isnull(sum(dtr_monto_mn),0.00)
             from ca_transaccion,
                  ca_det_trn
             where tr_operacion = @w_operacion
             and   tr_tran = 'PAG'
             and   tr_fecha_mov  between @w_fecha_ini_mes and @i_fecha
             and   tr_estado = 'RV'
             and   dtr_operacion = @w_operacion
             and   tr_operacion = dtr_operacion
             and   tr_secuencial = dtr_secuencial
             and   dtr_concepto in (@w_ro_concepto,@w_ro_concepto_iva)  


             select @w_reversos_com_iva = @w_reversos_com_iva + @w_reversos_com_iva_des
             

            select @w_dias_plazo = td_factor 
            from   ca_tdividendo
            where  td_tdividendo = @w_tplazo
               
            select @w_plazo_meses = isnull((@w_plazo * @w_dias_plazo)/30,0)    
            
            select @w_destino_credito = codigo_sib
            from cob_credito..cr_corresp_sib
            where tabla = 'T79'
            and  codigo = @w_op_destino
         
            if @w_destino_credito is null or @w_destino_credito = ''
               select @w_destino_credito = '1'
             
             
             select @w_cuotas_mora = count(1)
             from ca_dividendo
             where di_operacion = @w_operacion
             and   di_estado = 2
             
              
            select @w_fecha_inicio_mora = isnull(convert(char(10),min(di_fecha_ven),103),'00/00/0000')
            from ca_dividendo
            where di_operacion = @w_operacion
            and   di_estado = 2


            select @w_fecha_demanda = isnull(convert(char(10),co_fecha_demanda,103),'00/00/0000') 
            from cob_credito..cr_cobranza
            where co_cliente = @w_cliente

            select @w_dias_div = td_factor *  @w_periodo_int
            from   ca_tdividendo
            where  td_tdividendo = @w_tdividendo

            select @w_periodo_gracia_meses = 0
            if  @w_gracia_cap > 0
                select @w_periodo_gracia_meses = isnull((@w_dias_div * @w_gracia_cap) / 30,0)
                  
             select @w_tasa_nominal = ro_porcentaje
             from ca_rubro_op
             where ro_operacion = @w_operacion
             and   ro_tipo_rubro = 'I'
             
             
             select @w_periodicida_pago = td_descripcion,
                    @w_td_tdividendo    = td_tdividendo
             from   ca_tdividendo
             where  td_tdividendo = @w_tdividendo


            select @w_codigo_per_pago = (convert(smallint,a.codigo ))
            from cobis..cl_catalogo a
            where tabla = (select codigo
                          from cobis..cl_tabla
                          where tabla = 'ca_periodo_pago'
                         )
            and  a.valor = @w_td_tdividendo
            and  a.estado = 'V'
             
              
             
             insert into  ca_repositorio_reporte_FNG (
               rr_nit_intermediario,        rr_regional,                rr_departamento,            rr_ciudad,             
               rr_oficina,                  rr_banco,                   rr_cliente,                 rr_cedula, 
               rr_nombre_completo,          rr_nro_pagare,              rr_nro_garantia_fng,        rr_moneda, 
               rr_valor_desembosado_pesos,  rr_valor_desembosado_uvr,   rr_plazo_meses,             rr_calificacion_cliente,    
               rr_periodicida_pago,         rr_saldo_cap,               rr_periodo_gracia_meses,    rr_dir_cliente,             
               rr_telefono_cliente,         rr_codigo_dep_economica,    rr_ciiu,                    rr_tasa_nominal,            
               rr_toperacion,               rr_modalidad_comision,      rr_tasa_comision,
               rr_cobertura,                rr_destino_credito,         rr_probabilidad,            rr_cuotas_mora,             
               rr_ciudad_vivi_financiada,   rr_val_vivi_financiada,     rr_dir_vivi_financiada,     rr_saldo_cap_comision,      
               rr_uvr_calculo_comision,     rr_comision_facturada_mes,  rr_iva_facturada_mes,       rr_total_com_iva_facturada, 
               rr_total_com_iva_recaudada,  rr_reversos_com_iva,        rr_fecha_liq,               rr_fecha_inicio_mora,       
               rr_fecha_vencimiento,        rr_fecha_demanda,           rr_nom_oficina,             rr_nom_departamento,        
               rr_nom_regional,             rr_fecha_comision,          rr_otra_garantia,           rr_matricula_inmoviliaria,
               rr_codigo_per_pago,          rr_nro_fng,                 rr_nom_ciudad
               )
               values
               (
               @w_nit_intermediario,        @w_regional,                @w_departamento,            @w_ciudad,             
               @w_oficina,                  @w_banco,                   @w_cliente,                 @w_cedula, 
               @w_nombre_completo,          @w_nro_pagare,              @w_nro_garantia_fng,        @w_moneda, 
               @w_valor_desembosado_pesos,  @w_valor_desembosado_uvr,   @w_plazo_meses,             @w_calificacion_cliente,    
               @w_periodicida_pago,         @w_saldo_cap,               @w_periodo_gracia_meses,    @w_dir_cliente,             
               @w_telefono_cliente,         @w_codigo_dep_economica,    @w_ciiu,                    @w_tasa_nominal,            
               @w_toperacion,               @w_modalidad_comision,      @w_tasa_comision,            
               @w_cobertura,                @w_destino_credito,         @w_probabilidad,            @w_cuotas_mora,             
               @w_ciudad_vivi_financiada,   @w_val_vivi_financiada,     @w_dir_vivi_financiada,     @w_saldo_cap_comision,      
               @w_uvr_calculo_comision,     @w_comision_facturada_mes,  @w_iva_facturada_mes,       @w_total_com_iva_facturada, 
               @w_total_com_iva_recaudada,  @w_reversos_com_iva,        @w_fecha_liq,               @w_fecha_inicio_mora,       
               @w_fecha_vencimiento,        @w_fecha_demanda,           @w_nom_oficina,             @w_nom_departamento,        
               @w_nom_regional,             @w_fecha_comision,          @w_otra_garantia,           @w_matricula_inmoviliaria,
               @w_codigo_per_pago,          @w_nro_fng,                 @w_nom_ciudad
               )
            
        end
        ELSE
        if @w_op_estado = 3
        begin

            select @w_fecha_cancelacion = convert(char(10),isnull(max(can_fecha_can),'01/01/1900'),103)
            from ca_activas_canceladas
            where can_operacion = @w_operacion
            and can_fecha_can between @w_fecha_ini_mes and @i_fecha
            
            if @w_fecha_cancelacion <> '01/01/1900'
            begin
               --Insertar informacion canceladas
   
               insert into ca_can_reporte_FNG 
               (
               ca_nit_intermediario,     ca_nro_garantia_fng,     ca_banco,
               ca_nombre_completo,       ca_cedula,               ca_fecha_can
               )
               values
               (
               @w_nit_intermediario,     @w_nro_fng,              @w_banco,
               @w_nombre_completo,       @w_cedula,               @w_fecha_cancelacion
               )
            end
        end --estado 3
        

   
   fetch cursor_operacion
   into  @w_operacion
   
end --while @@fetch_status = 0
   
close cursor_operacion
deallocate cursor_operacion

go 
   
   
   
   