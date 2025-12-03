/************************************************************************/
/*  ARCHIVO:         tarifas.sp                                         */
/*  NOMBRE LOGICO:   sp_datos_tarifas_ca_rec                            */
/*  PRODUCTO:        Cartera                                            */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/* Ingresar informacion a las tablas de las tarifas para REC.Formato 365*/
/************************************************************************/
/*                            CAMBIOS                                   */
/*      FECHA           AUTOR                   RAZON                   */
/*  30/Oct/2013   Doris A Lozano          CCA 389 Formato 365 tarifas   */
/************************************************************************/
 
use cob_cartera
go

set ansi_nulls off
go

if exists ( select 1 from sysobjects where name = 'sp_datos_tarifas_ca_rec')
   drop proc sp_datos_tarifas_ca_rec
go

create proc sp_datos_tarifas_ca_rec

as declare 
   @w_error        int,
   @w_msg          descripcion,
   @w_fecha        datetime,
   @w_fecha_ini    datetime, 
   @w_producto     tinyint,
   @w_tabla        int,
   @w_fecha_aux    datetime,
   @w_iva          float,
   @w_sp_name      descripcion,
   @w_return       int,
   @w_fecha_proc   datetime,
   @w_numreg       int


select @w_producto = 7

select @w_sp_name = 'sp_datos_tarifas_ca_rec'


--Fecha de Cierre del producto
select @w_fecha  = fc_fecha_cierre
from  cobis..ba_fecha_cierre
where fc_producto = @w_producto 

If @@rowcount = 0
Begin
    select
   @w_error = 2609964,
   @w_msg = 'Error No es Posible Obtener la Fecha de Cierre'
   goto ERROR
End

--Fecha de Proceso
select @w_fecha_proc = fp_fecha
from  cobis..ba_fecha_proceso

If @@rowcount = 0
Begin
    select
   @w_error = 2902764,
   @w_msg = 'No es Posible Obtener la Fecha de Proceso'
   goto ERROR
End

--Se modifica parametro  @i_finsemana a 'S'  para no tener el cuenta el sabado como dia habil CCA 389
select @w_return = 0
exec @w_return = cob_remesas..sp_fecha_habil
@i_fecha     = @w_fecha_proc,
@i_oficina   = 1,
@i_efec_dia  = 'S',
@i_finsemana = 'S',
@w_dias_ret  = 1,
@o_fecha_sig = @w_fecha_aux out

If @w_return <> 0
Begin
    select
   @w_error = 708208,
   @w_msg = 'Error al ejecutar sp_fecha_habil'
   goto ERROR
End


If convert(tinyint,datepart(mm,@w_fecha_aux)) = convert(tinyint,datepart(mm,@w_fecha_proc)) 
Begin
   Print 'No se generara información por validacion de fecha'
   Return 0
End

delete cob_externos..ex_param_tarifas
where pt_aplicativo = @w_producto

if @@error <> 0
begin
   select
   @w_error = 710003,
   @w_msg = 'Error en eliminacion de cob_externos..ex_param_tarifas'
   goto ERROR
end

 
delete cob_externos..ex_datos_tarifas
where dt_aplicativo = @w_producto

if @@error <> 0
begin
   select
   @w_error = 710567,
   @w_msg ='Error en eliminacion de cob_externos..ex_datos_tarifas'
   goto ERROR
end


/* BUSCA PARAMETROS ASOCIADOS A LAS TARIFAS DE CARTERA*/
select pa_char pa_concepto, pa_nemonico, pa_parametro
into #parametros
from cobis..cl_parametro 
where pa_producto = 'CCA' 
and pa_nemonico in (select codigo from cobis..cl_catalogo 
                     where tabla  in (select codigo from cobis..cl_tabla where tabla = 'ca_param_tarifario')
                     and   substring(valor,1,3) = 'CCA')
if @@rowcount = 0
begin
   select
   @w_error = 710093,
   @w_msg = 'Error al buscar parametros de Cartera'
   goto ERROR
end

/* Busca las tarifas con o sin referencia */

select distinct 
ta_nemonico       = pa_nemonico, 
ta_concepto       = co_concepto, 
ta_descripcion    = co_descripcion, 
ta_clase          = va_clase, -- clase de dato  F Factor, V valor
ta_referencial    = ru_referencial, 
ta_concepto_asoc  = ru_concepto_asociado,
ta_sector         = vd_sector, 
ta_tipo           = vd_tipo, 
ta_referencia     = vd_referencia,
ta_valor          = case  when vd_referencia = null then vd_valor_default
                    else  isnull(vr_valor,0) end, 
ta_valor_rep      = case  when vd_referencia = null then vd_valor_default
                    else  isnull(vr_valor,0) end, 
ta_fecha          = vr_fecha_vig,
ta_secuencial     = vr_secuencial,
ta_base_calculo   = '0',
ta_estado         = 'V'   
into #tarifas1
from cob_cartera..ca_concepto, #parametros, cob_cartera..ca_rubro, cob_cartera..ca_valor,    
     ca_valor_referencial vr,
     cob_cartera..ca_valor_det
where co_concepto = pa_concepto
and  ru_concepto  = co_concepto
and  va_tipo      = ru_referencial
and  vd_tipo      = va_tipo
and  vr_tipo = vd_referencia
and  vr_fecha_vig = (select max(vr_fecha_vig) from  cob_cartera..ca_valor_referencial
                      where vr_tipo = vr.vr_tipo)
and vr_secuencial = (select max(vr_secuencial) from  cob_cartera..ca_valor_referencial
                      where vr_tipo = vr.vr_tipo
                        and vr_fecha_vig = vr.vr_fecha_vig)
                        
UNION
select distinct 
ta_nemonico       = pa_nemonico, 
ta_concepto       = co_concepto, 
ta_descripcion    = co_descripcion, 
ta_clase          = va_clase, -- clase de dato  F Factor, V valor
ta_referencial    = ru_referencial, 
ta_concepto_asoc  = ru_concepto_asociado,
ta_sector         = vd_sector, 
ta_tipo           = vd_tipo, 
ta_referencia     = vd_referencia,
ta_valor          = case  when vd_referencia = null then vd_valor_default
                    else  0 end, 
ta_valor_rep      = case  when vd_referencia = null then vd_valor_default
                    else  0 end, 
ta_fecha          = null,
ta_secuencial     = 0,
ta_base_calculo   = '0',
ta_estado         = 'V'   
from cob_cartera..ca_concepto, #parametros, cob_cartera..ca_rubro, cob_cartera..ca_valor,    
     cob_cartera..ca_valor_det
where co_concepto = pa_concepto
and  ru_concepto  = co_concepto
and  va_tipo      = ru_referencial
and  vd_tipo      = va_tipo
and  isnull(vd_referencia,'') not in (select vr_tipo from ca_valor_referencial)
         
                       
/* Verifica si hay referencias asociadas para actualizar el valor y el estado */

update #tarifas1
set ta_valor_rep = isnull (round(ta_valor_rep + ta_valor_rep * (select ta_valor_rep  from #tarifas1 
                                                                 where ta_concepto_asoc = a.ta_referencial
                                                                   and ta_sector = a.ta_sector )/100,0),0)
from #tarifas1 a
where  exists (select 'x' from #tarifas1
   where ta_concepto_asoc = a.ta_referencial
   and ta_sector = a.ta_sector )
  
if @@error <> 0
begin
   select
   @w_error = 710002,
   @w_msg = 'Error al actualizar tarifa en #tarifas1'
   goto ERROR
end



update #tarifas1
set ta_estado = 'X'
where ta_concepto_asoc is not null

if @@error <> 0
begin
   select
   @w_error = 710002,
   @w_msg = 'Error2 al actualizar tarifa en #tarifas1'
   goto ERROR
end



update #tarifas1
set ta_valor_rep = ta_valor_rep * 12
where ta_nemonico = 'SEDEVE'

if @@error <> 0
begin
   select
   @w_error = 710002,
   @w_msg = 'Error3 al actualizar tarifa en #tarifas1'
   goto ERROR
end



/* Genera tarifario para #tarifas1  - Cabecera  */

select  distinct
pt_fecha      = @w_fecha, 
pt_aplicativo = @w_producto, 
pt_nemonico   = ta_nemonico,
pt_concepto   = ta_descripcion, 
pt_campo1     = Convert(varchar(64),'tabla-ca_concepto'), 
pt_campo2     = Convert(varchar(64),'tabla-ca_valor'), 
pt_campo3     = Convert(varchar(64),'catalogo-cr_clase_cartera'),                     
pt_campo4     = '',                         
pt_campo5     = '',                              
pt_campo6     = '',                     
pt_campo7     = '',
pt_campo8     = '',
pt_campo9     = '',
pt_campo10    = '',
pt_forma_calculo = case ta_clase 
                   when 'F' then '03'
                   else '02'
                   end, 
pt_estado        = ta_estado
Into #param_tarifas
from #tarifas1
where ta_estado = 'V'

if @@error <> 0 begin
   select
   @w_error = 710001,
   @w_msg = 'Error al grabar Cabecera #param_tarifas1'
   goto ERROR
end    




/* Genera detalle tarifario para tarifas1 - detalle*/
select 
dt_fecha        = @w_fecha, 
dt_aplicativo   = @w_producto, 
dt_nemonico     = ta_nemonico, 
dt_campo1       = ta_concepto,
dt_campo2       = ta_referencial,
dt_campo3       = ta_sector,
dt_campo4       = '',
dt_campo5       = '',
dt_campo6       = '',
dt_campo7       = '',
dt_campo8       = '',
dt_campo9       = '',
dt_campo10      = '',
dt_base_calculo = ta_base_calculo,
dt_valor        = convert(varchar(32), ta_valor_rep),
dt_estado       = ta_estado    
into #datos_tarifas
from   #tarifas1 
where ta_estado = 'V'

if @@error <> 0 begin
   select
   @w_error = 710001,
   @w_msg = 'Error al grabar Detalle de #tarifas1'
   goto ERROR
end    


/* GENERA TARIFARIO PARA PARAMETROS COBIS   - Cabecera  */ 
select @w_tabla = codigo 
from   cobis..cl_tabla
where  tabla = 'ca_param_tarifario'



/* Genera tarifario para parametros de cartera  - Cabecera */
Insert Into #param_tarifas
select 
pt_fecha      = @w_fecha, 
pt_aplicativo = @w_producto, 
pt_nemonico   = pa_nemonico, -- Convert(Varchar(64), Rtrim(pa_nemonico)+ '-' + pa_producto), 
pt_concepto   = pa_parametro,
pt_campo1     = Convert(Varchar(64),'catalogo-ca_param_tarifario'),
pt_campo2     = '',
pt_campo3     = '',
pt_campo4     = '',
pt_campo5     = '',
pt_campo6     = '',
pt_campo7     = '',
pt_campo8     = '',
pt_campo9     = '',
pt_campo10    = '',
pt_forma_calculo = case pa_tipo
                        when 'F' then '03'
                        else '02'
                   end,
pt_estado        = estado
from  cobis..cl_parametro, cobis..cl_catalogo
where tabla  = @w_tabla
and   codigo = pa_nemonico
and   pa_producto = 'CCA'
and   substring(valor,1,5) = 'PARAM'

if @@error <> 0 begin
   select
   @w_error = 710001,
   @w_msg = 'Error al grabar Cabecera #param_tarifas de Cartera'
   goto ERROR
end


/* Genera tarifario para  parametros de Cartera  - Detalle */
Insert Into #datos_tarifas
select 
dt_fecha        = @w_fecha, 
dt_aplicativo   = @w_producto,
dt_nemonico     = pa_nemonico, 
dt_campo1       = codigo,
dt_campo2       = '',
dt_campo3       = '',
dt_campo4       = '',
dt_campo5       = '',
dt_campo6       = '',
dt_campo7       = '',
dt_campo8       = '',
dt_campo9       = '',
dt_campo10      = '',
dt_base_calculo = '0', -- Convert(Varchar(10),'Parametro'),
dt_valor        = case pa_tipo
                     when 'T' then convert(varchar(20), pa_tinyint)
                     when 'S' then convert(varchar(20), pa_smallint)
                     when 'I' then convert(varchar(20), pa_int)
                     when 'M' then convert(varchar(20), pa_money)
                     when 'F' then convert(varchar(20), pa_float)
                     else 'TIPO DE DATO INCOMPATIBLE'
                  end,
dt_estado       = estado
from  cobis..cl_parametro, cobis..cl_catalogo
where tabla  = @w_tabla
and   codigo = pa_nemonico
and   pa_producto = 'CCA'
and   substring(valor,1,5) = 'PARAM'

if @@error <> 0 begin
   select
   @w_error = 710001,
   @w_msg = 'Error al grabar Detalle #datos_tarifas de Cartera'
   goto ERROR
end


/* GENERA TARIFARIO PARA TRANSACCIONES  DE OTROS INGRESOS -- TADMIN */
select 
tipo = case t.tabla when 'cc_causa_oe' then convert(varchar(4),'E' )
       else convert(varchar(4),'I')  end, 
causa = c.codigo, 
descr = c.valor,
estado = c.estado
into   #tmp_causales
from   cobis..cl_catalogo c, cobis..cl_tabla t
where  t.codigo = c.tabla
and    t.tabla  like '%oioe'
and    c.codigo in (select  codigo  from cobis..cl_catalogo where tabla  = (select codigo from cobis..cl_tabla where tabla = 'ca_param_tarifario')
                    and substring(valor,1,6) = 'TADMIN' )
if @@error <> 0 begin
   select
   @w_error = 710001,
   @w_msg = 'Error al grabar en tabla #tmp_causales'
   goto ERROR
end

if exists(select 1 from cobis..cl_producto where pd_abreviatura = 'CTA')
begin
    select 
    'Trn'          = case tipo 
                   when 'I' then 32 
                   when 'E' then 86
                   when '2734' then 2734
                   else 2735 end,
    'Tipo'         = case tipo 
                   when 'I' then 'Ingresos'
                   when 'E' then 'Egresos'
                   when '2734' then 'Entrega de Efectivo'
                   else 'Recepcion Efectivo' end,
    'Causal'       = causa,
    'Desc_Causal'  = descr,
    'IVA'          = ci_cobro_iva,
    'Costo_Asoc'   = ci_costo,
    'Gasto Bco'    = ci_gasto_banco,
    'Efectivo'     = ci_efectivo,
    'Chq Prop/Ger' = ci_chq_propio,
    'Chq Local'    = ci_chq_local, 
    'Estado'       =  estado,
    'base_calculo' = '0'
    into   #tmp_datos
    from   cob_cuentas..cc_causa_ingegr, #tmp_causales
    where  isnull(ci_costo,0)  > 0
    and    ci_tipo   = tipo
    and    ci_causal = causa
    
    if @@error <> 0 begin
       select
       @w_error = 710001,
       @w_msg = 'Error al grabar en tabla #tmp_datos'
       goto ERROR
    end
end
else
begin
    select
       @w_error = 404000,
       @w_msg = 'PRODUCTO NO INSTALADO'
    goto ERROR
end



/* Genera tarifario para causales oi de TADMIN  - Cabecera */
Insert Into #param_tarifas
select 
pt_fecha      = @w_fecha, 
pt_aplicativo = @w_producto, 
pt_nemonico   = Causal, 
pt_concepto   = Desc_Causal,
pt_campo1     = Convert(Varchar(64),'catalogo-ca_param_tarifario'),
pt_campo2     = '',
pt_campo3     = '',
pt_campo4     = '',
pt_campo5     = '',
pt_campo6     = '',
pt_campo7     = '',
pt_campo8     = '',
pt_campo9     = '',
pt_campo10    = '',
pt_forma_calculo = '02',
pt_estado        = Estado
from  #tmp_datos
if @@error <> 0 begin
   select
   @w_error = 710001,
   @w_msg = 'Error al grabar Cabecera en #param_tarifas de Cartera'
   goto ERROR
end


-- Busca la tarifa de iva aplicada a las transacciones de oi
select @w_iva =  pa_float 
from cobis..cl_parametro 
where pa_nemonico = 'PIVA' 
and pa_producto = 'CTE'

if @@rowcount =  0 begin
   select
   @w_error = 710362,
   @w_msg = 'No existe parametro PIVA'
   goto ERROR
end



/* Genera tarifario para   para causales oi de TADMIN  - Detalle */

Insert Into #datos_tarifas
select 
dt_fecha        = @w_fecha, 
dt_aplicativo   = @w_producto,
dt_nemonico     = Causal, 
dt_campo1       = Causal,
dt_campo2       = '',
dt_campo3       = '',
dt_campo4       = '',
dt_campo5       = '',
dt_campo6       = '',
dt_campo7       = '',
dt_campo8       = '',
dt_campo9       = '',
dt_campo10      = '',
dt_base_calculo = base_calculo,
dt_valor        = convert (varchar(32), case IVA when 'S' then  Costo_Asoc + round(Costo_Asoc * @w_iva /100,0)  else Costo_Asoc  end),
dt_estado       = 'V'
from  #tmp_datos


if @@error <> 0 begin
   select
   @w_error = 710001,
   @w_msg = 'Error al grabar Detalle #datos_tarifas de Cartera - Otros ingresos'
   goto ERROR
end


-- Carga los datos a cob_externos

insert into cob_externos..ex_param_tarifas
select distinct * from #param_tarifas

if @@error <> 0 begin
   select
   @w_error = 710001,
   @w_msg = 'Error al grabar en  cob_externos..ex_param_tarifas'
   goto ERROR
end

select @w_numreg = count(1)
from #param_tarifas
print ' Datos pasados  a cob_externos..ex_param_tarifas :' + cast (@w_numreg  as varchar)

insert into  cob_externos..ex_datos_tarifas
select * from #datos_tarifas

if @@error <> 0 begin
   select
   @w_error = 710001,
   @w_msg = 'Error al grabar en ex_datos_tarifas'
   goto ERROR
end

     
return 0
ERROR:
exec sp_errorlog
@i_fecha        = @w_fecha,
@i_error        = @w_error,
@i_usuario      = 'batch',
@i_tran         = 0,
@i_tran_name = @w_sp_name,
@i_descripcion  = @w_msg,
@i_rollback     = 'N'

print  @w_msg 
return @w_error
go
