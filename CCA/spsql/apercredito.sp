/************************************************************************/
/*      Archivo:                apercredito.sp                          */
/*      Stored procedure:       sp_apertura_credito                     */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Jonnatan Peña                           */
/*      Fecha de escritura:     Jul. 2009                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*     La presente consulta con opción de impresión en formato Crystal  */
/*     Report, genera los reportes de apertura de credito rotativo y    */
/*     simple, para mostralos por pantalla y enviarlos a impresion.     */
/************************************************************************/

use cob_cartera
go
set ansi_warnings off
go
if exists (select 1 from sysobjects where name = 'sp_apertura_credito')
   drop proc sp_apertura_credito 
go

---INC 116772
create proc sp_apertura_credito  (  
   @i_banco              varchar(24) ,
   @i_impresion          tinyint     = null,
   @i_num_impresion      tinyint     = null,
   @i_estado             tinyint     = null,
   @o_num_impresion      tinyint     = null out 
)
as

declare 
   @w_sp_name             varchar(32),
   @w_return              int,
   @w_error               int, 
   @w_msg                 varchar(100), 
   @w_cedula              varchar(20),
   @w_desciudad           varchar(100),    
   @w_nombre              varchar(100),
   @w_papellido           varchar(100), 
   @w_sapellido           varchar(100),
   @w_rol                 char(1),
   @w_tramite             int,
   @w_cliente             int,
   @w_nombre_completo     varchar(100),
   @w_monto_apr           money, 
   @w_monto_letras        varchar(255),
   @w_apercre_letras      varchar(255),
   @w_parametro_apecr     catalogo,
   @w_operacionca         int,
   @w_factor              money,
   @w_valor_apercre       money,
   @w_oficina             smallint,
   @w_des_ciudad          varchar(64),
   @w_cod_ciudad          int,
   @w_iva                 float,
   @w_iva_apercre         money,
   @w_monto_total         money,
   @w_cliente_rl          int,
   @w_cedula_rl           varchar(14),
   @w_nombre_comp_rl      varchar(100),
   @w_plazo_cupo          smallint,
   @w_plazo_util          smallint,
   @w_plazo_cupo_letras   varchar(255),
   @w_plazo_util_letras   varchar(255),
   @w_direccion           varchar(100),
   @w_telefono            varchar(15),
   @w_posicion			  tinyint,
   @w_num_impresion       tinyint,
   @w_linea				  cuenta,
   @w_fecha_liq           varchar(10),
   @w_tipo_doc            varchar(3),
   @w_resultado_matriz    int,
   @w_matriz_calculo      catalogo,
   @w_campana             int,
   @w_fecha_proceso       datetime,
   @w_porcentaje_efa      float,                    
   @w_referencial         varchar(50),           
   @w_referencia          varchar(50),           
   @w_sector              char(1),               
   @w_secuen_ref          int,                   
   @w_fecha_ref           datetime,              
   @w_porcentaje_ref      float,
   @w_tipo_tramite        char(1),
   @w_tasa_ef_anual       float,
   @w_tasa_referencial    float		 

select @w_num_impresion = 0   
select @w_sp_name       = 'sp_apertura_credito'

select @w_parametro_apecr = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'APECR'   


select @w_parametro_apecr = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'APECR'   

select @w_plazo_util = pa_int / 30
from   cobis..cl_parametro
where  pa_nemonico = 'VIGCUP'

create table #datos (
   cliente       int          null,   
   nombre_clien  varchar(100) null,
   tipo_doc      varchar(3)   null,      
   cedula        varchar(20)  null,       
   rol           char(1)      null,
   direccion     varchar(100) null,
   telefono      varchar(15)  null,
   ciudad        varchar(64)  null
)

--- DETERMINAR ULTIMO TRAMITE DE LA OPERACION
select @w_tramite = max(tr_tramite)
from cob_credito..cr_tramite
where tr_numero_op_banco = @i_banco
and   tr_estado <> 'Z'
and   tr_tipo = 'E'

if exists(select 1 from ca_operacion where op_banco=@i_banco and op_lin_credito is not null)begin
select 
@w_cliente      = op_cliente,
@w_cedula       = en_ced_ruc,
@w_tramite      = isnull(@w_tramite, op_tramite),
@w_monto_apr    = li_monto,
@w_operacionca  = op_operacion,
@w_oficina      = op_oficina,
@w_direccion    = (select di_descripcion  from cobis..cl_direccion where di_principal = 'S' and di_ente = op_cliente), 
@w_telefono     = (select te_valor  from cobis..cl_telefono where te_direccion = 1 and te_secuencial = 1 and te_ente = op_cliente),
@w_plazo_cupo   = op_plazo,
@w_linea        = op_lin_credito,
@w_fecha_liq    = convert(varchar(10),op_fecha_liq,103) 
from cobis..cl_ente, ca_operacion, cob_credito..cr_linea
where op_banco = @i_banco
and en_ente = op_cliente
and li_num_banco = op_lin_credito
end   
else
begin
select 
@w_cliente      = op_cliente,
@w_cedula       = en_ced_ruc,
@w_tramite      = isnull(@w_tramite, op_tramite),
@w_monto_apr    = op_monto,
@w_operacionca  = op_operacion,
@w_oficina      = op_oficina,
@w_plazo_cupo   = op_plazo,
@w_fecha_liq    = convert(varchar(10),op_fecha_liq,103),
@w_sector       = op_sector
from  cobis..cl_ente,ca_operacion
where op_banco = @i_banco
and en_ente = op_cliente
end

/*select @w_porcentaje_efa = ro_porcentaje_efa
from cob_cartera..ca_rubro_op
where ro_operacion = @w_operacionca
and ro_tipo_rubro = 'I'

select  
from ca_operacion 
where  op_operacion = @w_operacionca  --clase de cartera
*/

select @w_referencial = ro_referencial     
from cob_cartera..ca_rubro_op
where ro_operacion = @w_operacionca 
and ro_tipo_rubro = 'I'

select @w_referencia = vd_referencia --trae el verdadero nombre de la tasa referencial
from cob_cartera..ca_valor,
cob_cartera..ca_valor_det
where va_tipo = vd_tipo
and va_tipo = @w_referencial
and vd_sector = @w_sector

select  
@w_secuen_ref  = max(vr_secuencial), 
@w_fecha_ref = max(vr_fecha_vig)  
from cob_cartera..ca_valor_referencial
where vr_tipo = @w_referencia

select  @w_porcentaje_ref = vr_valor
from cob_cartera..ca_valor_referencial
where vr_tipo = @w_referencia
and   vr_secuencial = @w_secuen_ref 
and   vr_fecha_vig = @w_fecha_ref

select @w_tasa_referencial = @w_porcentaje_ref

select @w_iva = pa_float
from  cobis..cl_parametro
where pa_nemonico = 'PIVA'
and pa_producto = 'CTE'

select @w_factor = ro_valor
from ca_rubro_op
where ro_concepto = @w_parametro_apecr
and ro_operacion = @w_operacionca

select @w_factor = isnull(@w_factor, 0)

/* VALOR DE APERCRED*/
select @w_valor_apercre = round(@w_factor,0)

/* VALOR DE IVA-APERCRED*/
select @w_iva_apercre = round(@w_valor_apercre*@w_iva/100,0)

select @w_monto_total = isnull(sum(@w_valor_apercre + @w_iva_apercre),0)

exec @w_error = cob_interface..sp_numeros_letras 
@t_trn        = 29322,
@i_dinero     = @w_monto_total,
@i_moneda     = 0,
@i_idioma     = 'E',
@o_texto      = @w_apercre_letras out

if @w_error <> 0  return @w_error       

exec @w_error = cob_interface..sp_numeros_letras 
@t_trn      = 29322,
@i_dinero   = @w_monto_apr,
@i_moneda   = 0,
@i_idioma   = 'E',
@o_texto    = @w_monto_letras out

if @w_error <> 0  return @w_error       

exec @w_error = cob_interface..sp_numeros_letras 
@t_trn      = 29322,
@i_dinero   = @w_plazo_cupo,
@i_moneda   = 0,
@i_idioma   = 'E',
@o_texto    = @w_plazo_cupo_letras out

if @w_error <> 0  return @w_error       

select @w_posicion = (select charindex('PESOS',@w_plazo_cupo_letras))

select @w_plazo_cupo_letras = (select substring(@w_plazo_cupo_letras,1,(@w_posicion-1)))

select @w_tasa_ef_anual = isnull(sum(ro_porcentaje_efa),0)
from ca_rubro_op with (nolock)
where ro_operacion  =  @w_operacionca
and   ro_tipo_rubro =  'I'
and   ro_fpago      in ('P','A')
   



exec @w_error = cob_interface..sp_numeros_letras 
@t_trn      = 29322,
@i_dinero   = @w_plazo_util,
@i_moneda   = 0,
@i_idioma   = 'E',
@o_texto    = @w_plazo_util_letras out

if @w_error <> 0  return @w_error       

select @w_posicion = (select charindex('PESOS',@w_plazo_util_letras))

select @w_plazo_util_letras = (select substring(@w_plazo_util_letras,1,(@w_posicion-1)))

select @w_cod_ciudad  = of_ciudad 
from cobis..cl_oficina
where of_oficina = @w_oficina

select @w_des_ciudad = ci_descripcion 
from cobis..cl_ciudad
where ci_ciudad = @w_cod_ciudad

insert into #datos
select de_cliente, en_nombre  + ' ' + p_p_apellido + ' ' + p_s_apellido, substring(en_tipo_ced,1,3), substring(en_ced_ruc,1,12), de_rol,
      (select di_descripcion  from cobis..cl_direccion where di_principal = 'S' and di_ente = de_cliente), 
      (select te_valor  from cobis..cl_telefono where te_direccion = 1 and te_secuencial = 1 and te_ente = de_cliente),
       @w_des_ciudad
from cob_credito..cr_deudores, cobis..cl_ente  
where de_tramite = @w_tramite  
and  de_cliente = en_ente 

if @@error <> 0 begin                                                                   
   select                                                                                
   @w_error = 71001,                                                                     
   @w_msg   = 'ERROR AL INSERTAR LA INFORMACION EN LA TABLA'         
   goto ERROR                                                                            
end 

--Para Cliente Juridico
select cliente_jur = cliente
into #juridico
from #datos, cobis..cl_ente
where cliente    = en_ente
and   en_subtipo = 'C'

if exists(select 1 from #juridico) begin

   --Datos del Representante Legal
   select @w_cliente_rl = in_ente_i
   from cobis..cl_instancia, #juridico
   where in_relacion = 205
   and   in_lado     = 'I'
   and   in_ente_d   = cliente_jur

   select 
   @w_nombre_comp_rl = en_nombre  + ' ' + p_p_apellido + ' ' + p_s_apellido,
   @w_tipo_doc       = substring(en_tipo_ced,1,3),
   @w_cedula_rl      = substring(en_ced_ruc,1,12)
   from cobis..cl_ente
   where en_ente = @w_cliente_rl

   update #datos set
   cliente      = @w_cliente_rl,
   nombre_clien = @w_nombre_comp_rl,
   tipo_doc     = @w_tipo_doc,    
   cedula       = @w_cedula_rl   
   from #juridico
   where cliente = cliente_jur

   select @w_nombre_completo = nombre_clien
   from #datos
   where cliente = @w_cliente_rl
   and   rol     = 'D' 

end
else
begin

   select @w_nombre_completo = nombre_clien
   from #datos
   where cliente = @w_cliente
   and   rol     = 'D' 
end

select @o_num_impresion = @w_num_impresion   

select
@w_tramite,
@w_cedula,
@w_nombre_completo,
@w_monto_apr,
@w_monto_letras,
@w_monto_total,
@w_apercre_letras,
@w_des_ciudad,
@w_plazo_cupo,
@w_plazo_cupo_letras,
@w_plazo_util,
@w_plazo_util_letras,
@w_fecha_liq,
@w_num_impresion,  
@w_des_ciudad,
@w_tasa_ef_anual, ---16
@w_tasa_referencial ---17
           


select
cliente,       
nombre_clien,
tipo_doc,
cedula,      
rol,
direccion,
telefono,
ciudad         
from #datos
order by rol desc

                 
if @@error <> 0 begin                                                                   
   select                                                                                
   @w_error = 710250,                                                                    
   @w_msg   = 'ERROR AL CONSULTAR LA INFORMACION EN LA TABLA'        
   goto ERROR                                                                            
end                                                                               
                             
return 0  

ERROR:

Exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null, 
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error     

GO