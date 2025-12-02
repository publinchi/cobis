/**************************************************************************/
/*   NOMBRE LOGICO:      histdef.sp                                       */
/*   NOMBRE FISICO:      sp_historia_def                                  */
/*   BASE DE DATOS:      cob_cartera                                      */
/*   PRODUCTO:           Credito y Cartera                                */
/*   DISENADO POR:       Fabian de la Torre                               */
/*   FECHA DE ESCRITURA: FEB. 2018                                        */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/***********************************************************************  */
/*                             MODIFICACIONES                             */
/*   Fecha         Autor                Razon                             */
/*   23/08/2021    Kevin Rodríguez      Carga de historicos de la tabla   */
/*                                      ca_control_rubros_diferidos       */
/*   01/06/2022    Guisela Fernandez    Se comenta prints                 */
/*   25/12/2023    Kevin Rodriguez     R220437 Mantener ciudad tab maestra*/
/***********************************************************************  */

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_historia_def' and type = 'P')
   drop proc sp_historia_def
go


create proc sp_historia_def
@i_operacionca    int,
@i_secuencial     int = null,
@i_tiene_rub_dif  char(1) = 'N' -- KDR-20/08/2021 Bandera si la operacion tiene rubros diferidos
   
as 

declare
@w_error                int,
@w_commit               char(1),
@w_rc                   int,
@w_dividendo_desde      smallint,
@w_rowcount_act         int,
@w_estado_op            tinyint,
@w_base_origen          char(1), 
@w_toperacion           descripcion 


/* INICIALIZAR VARIABLES DE TRABAJO */
select 
@w_error       = 0,
@w_commit      = 'N',
@w_base_origen = 'N' -- no está


/* DETERMINAR DONDE ESTAN LAS TABLA HIS */
select @w_base_origen = 'H' from cob_cartera_his..ca_operacion_his where oph_operacion = @i_operacionca and oph_secuencial = @i_secuencial
select @w_base_origen = 'P' from cob_cartera..ca_operacion_his     where oph_operacion = @i_operacionca and oph_secuencial = @i_secuencial

if @w_base_origen = 'N' begin
   select @w_error = 710318
   goto ERROR
end 
 

select * into #operacion         from cob_cartera..ca_operacion_his         where 1=2
select * into #rubro_op          from cob_cartera..ca_rubro_op_his          where 1=2
select * into #dividendo         from cob_cartera..ca_dividendo_his         where 1=2
select * into #amortizacion      from cob_cartera..ca_amortizacion_his      where 1=2
select * into #correccion        from cob_cartera..ca_correccion_his        where 1=2
select * into #cuota_adicional   from cob_cartera..ca_cuota_adicional_his   where 1=2
select * into #valores           from cob_cartera..ca_valores_his           where 1=2
select * into #diferidos         from cob_cartera..ca_diferidos_his         where 1=2
select * into #facturas          from cob_cartera..ca_facturas_his          where 1=2
select * into #traslado_interes  from cob_cartera..ca_traslado_interes_his  where 1=2
select * into #comision_diferida from cob_cartera..ca_comision_diferida_his where 1=2
select * into #seguros           from cob_cartera..ca_seguros_his           where 1=2
select * into #seguros_det       from cob_cartera..ca_seguros_det_his       where 1=2
select * into #seguros_can       from cob_cartera..ca_seguros_can_his       where 1=2
select * into #operacion_ext     from cob_cartera..ca_operacion_ext_his     where 1=2


/* RECUPERAR EL HISTORICO DEL PRESTAMO DESDE LA BASE DE DATOS ORIGEN */
if @w_base_origen = 'P' begin

   insert into #operacion         select *  from cob_cartera..ca_operacion_his         where  oph_operacion = @i_operacionca and  oph_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #rubro_op          select *  from cob_cartera..ca_rubro_op_his          where  roh_operacion = @i_operacionca and  roh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #dividendo         select *  from cob_cartera..ca_dividendo_his         where  dih_operacion = @i_operacionca and  dih_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #amortizacion      select *  from cob_cartera..ca_amortizacion_his      where  amh_operacion = @i_operacionca and  amh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #correccion        select *  from cob_cartera..ca_correccion_his        where  coh_operacion = @i_operacionca and  coh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #cuota_adicional   select *  from cob_cartera..ca_cuota_adicional_his   where  cah_operacion = @i_operacionca and  cah_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #valores           select *  from cob_cartera..ca_valores_his           where  vah_operacion = @i_operacionca and  vah_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #diferidos         select *  from cob_cartera..ca_diferidos_his         where difh_operacion = @i_operacionca and difh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #facturas          select *  from cob_cartera..ca_facturas_his          where fach_operacion = @i_operacionca and fach_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #traslado_interes  select *  from cob_cartera..ca_traslado_interes_his  where  tih_operacion = @i_operacionca and  tih_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #comision_diferida select *  from cob_cartera..ca_comision_diferida_his where  cdh_operacion = @i_operacionca and  cdh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #seguros           select *  from cob_cartera..ca_seguros_his           where  seh_operacion = @i_operacionca and  seh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #seguros_det       select *  from cob_cartera..ca_seguros_det_his       where sedh_operacion = @i_operacionca and sedh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #seguros_can       select *  from cob_cartera..ca_seguros_can_his       where sech_operacion = @i_operacionca and sech_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #operacion_ext     select *  from cob_cartera..ca_operacion_ext_his     where  oeh_operacion = @i_operacionca and  oeh_secuencial = @i_secuencial if @@error <> 0 return 710001

end else begin

 
   insert into #operacion          select * from cob_cartera_his..ca_operacion_his         where  oph_operacion = @i_operacionca and  oph_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #rubro_op           select * from cob_cartera_his..ca_rubro_op_his          where  roh_operacion = @i_operacionca and  roh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #dividendo          select * from cob_cartera_his..ca_dividendo_his         where  dih_operacion = @i_operacionca and  dih_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #amortizacion       select * from cob_cartera_his..ca_amortizacion_his      where  amh_operacion = @i_operacionca and  amh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #correccion         select * from cob_cartera_his..ca_correccion_his        where  coh_operacion = @i_operacionca and  coh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #cuota_adicional    select * from cob_cartera_his..ca_cuota_adicional_his   where  cah_operacion = @i_operacionca and  cah_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #valores            select * from cob_cartera_his..ca_valores_his           where  vah_operacion = @i_operacionca and  vah_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #diferidos          select * from cob_cartera_his..ca_diferidos_his         where difh_operacion = @i_operacionca and difh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #facturas           select * from cob_cartera_his..ca_facturas_his          where fach_operacion = @i_operacionca and fach_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #traslado_interes   select * from cob_cartera_his..ca_traslado_interes_his  where  tih_operacion = @i_operacionca and  tih_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #comision_diferida  select * from cob_cartera_his..ca_comision_diferida_his where  cdh_operacion = @i_operacionca and  cdh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #seguros            select * from cob_cartera_his..ca_seguros_his           where  seh_operacion = @i_operacionca and  seh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #seguros_det        select * from cob_cartera_his..ca_seguros_det_his       where sedh_operacion = @i_operacionca and sedh_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #seguros_can        select * from cob_cartera_his..ca_seguros_can_his       where sech_operacion = @i_operacionca and sech_secuencial = @i_secuencial if @@error <> 0 return 710001
   insert into #operacion_ext      select * from cob_cartera_his..ca_operacion_ext_his     where  oeh_operacion = @i_operacionca and  oeh_secuencial = @i_secuencial if @@error <> 0 return 710001 
end

/* DETERMINAR LA PRIMERA CUOTA RESPALDADA EN EL HISTORICO */
select @w_dividendo_desde = isnull(min(dih_dividendo), 0) -1
from   #dividendo
where  dih_operacion  = @i_operacionca
and    dih_secuencial = @i_secuencial


/* BORRAR CAMPO SECUENCIAL QUE NO ES PARTE DE LAS TABLAS DEFINITIVAS*/
alter table #operacion         drop column  oph_secuencial if @@error <> 0 return 710002
alter table #rubro_op          drop column  roh_secuencial if @@error <> 0 return 710002
alter table #dividendo         drop column  dih_secuencial if @@error <> 0 return 710002
alter table #amortizacion      drop column  amh_secuencial if @@error <> 0 return 710002
alter table #correccion        drop column  coh_secuencial if @@error <> 0 return 710002
alter table #cuota_adicional   drop column  cah_secuencial if @@error <> 0 return 710002
alter table #valores           drop column  vah_secuencial if @@error <> 0 return 710002
alter table #diferidos         drop column difh_secuencial if @@error <> 0 return 710002
alter table #facturas          drop column fach_secuencial if @@error <> 0 return 710002
alter table #traslado_interes  drop column  tih_secuencial if @@error <> 0 return 710002
alter table #comision_diferida drop column  cdh_secuencial if @@error <> 0 return 710002
alter table #seguros           drop column  seh_secuencial if @@error <> 0 return 710002
alter table #seguros_det       drop column sedh_secuencial if @@error <> 0 return 710002
alter table #seguros_can       drop column sech_secuencial if @@error <> 0 return 710002
alter table #operacion_ext     drop column  oeh_secuencial if @@error <> 0 return 710002


/* PONER A SALVO LOS CAMPOS QUE NO SE DEBEN RECUPERAR DEL HISTÓRICO */
update #operacion set
oph_toperacion       = op_toperacion,
oph_clase            = op_clase,
oph_cliente          = op_cliente,
oph_nombre           = op_nombre,
oph_tipo_linea       = op_tipo_linea,
oph_forma_pago       = op_forma_pago,
oph_codigo_externo   = op_codigo_externo,
oph_cuenta           = op_cuenta,
oph_direccion        = op_direccion,
oph_tipo_empresa     = op_tipo_empresa,
oph_estado_cobranza  = op_estado_cobranza,
oph_oficial          = op_oficial,
oph_oficina          = op_oficina,
oph_ciudad           = op_ciudad,
oph_gar_admisible    = op_gar_admisible,
oph_calificacion     = op_calificacion
from   ca_operacion
where  op_operacion = oph_operacion

if @@rowcount = 0 or @@error <> 0 begin
   select @w_error = 710318
   goto ERROR
end





/* BORRAR REGISTROS A REEMPLAZAR */
delete ca_operacion         where op_operacion  = @i_operacionca if @@error <> 0 return 710003
delete ca_rubro_op          where ro_operacion  = @i_operacionca if @@error <> 0 return 710003
delete ca_dividendo         where di_operacion  = @i_operacionca and di_dividendo > @w_dividendo_desde if @@error <> 0 return 710003
delete ca_amortizacion      where am_operacion  = @i_operacionca and am_dividendo > @w_dividendo_desde if @@error <> 0 return 710003
delete ca_correccion        where co_operacion  = @i_operacionca if @@error <> 0 return 710003
delete ca_cuota_adicional   where ca_operacion  = @i_operacionca if @@error <> 0 return 710003
delete ca_valores           where va_operacion  = @i_operacionca if @@error <> 0 return 710003 
delete ca_diferidos         where dif_operacion = @i_operacionca if @@error <> 0 return 710003
delete ca_facturas          where fac_operacion = @i_operacionca if @@error <> 0 return 710003
delete ca_traslado_interes  where ti_operacion  = @i_operacionca if @@error <> 0 return 710003
delete ca_comision_diferida where cd_operacion  = @i_operacionca if @@error <> 0 return 710003
delete ca_seguros           where se_operacion  = @i_operacionca if @@error <> 0 return 710003
delete ca_seguros_det       where sed_operacion = @i_operacionca if @@error <> 0 return 710003
delete ca_seguros_can       where sec_operacion = @i_operacionca if @@error <> 0 return 710003
delete ca_operacion_ext     where oe_operacion  = @i_operacionca if @@error <> 0 return 710003

/* RECUPERAR REGISTROS DEL HISTÓRICO */
insert ca_operacion         select * from #operacion         if @@error <> 0 or @@rowcount = 0 return 710269
insert ca_rubro_op          select * from #rubro_op          if @@error <> 0 or @@rowcount = 0 return 710270
insert ca_dividendo         select * from #dividendo         if @@error <> 0 or @@rowcount = 0 return 710271
insert ca_amortizacion      select * from #amortizacion      if @@error <> 0 or @@rowcount = 0 return 710271
insert ca_correccion        select * from #correccion        if @@error <> 0 return 710272
insert ca_cuota_adicional   select * from #cuota_adicional   if @@error <> 0 return 710273
insert ca_valores           select * from #valores           if @@error <> 0 return 710275
insert ca_diferidos         select * from #diferidos         if @@error <> 0 return 710579
insert ca_facturas          select * from #facturas          if @@error <> 0 return 708153
insert ca_traslado_interes  select * from #traslado_interes  if @@error <> 0 return 711005
insert ca_comision_diferida select * from #comision_diferida if @@error <> 0 return 724588
insert ca_seguros           select * from #seguros           if @@error <> 0 return 708229
insert ca_seguros_det       select * from #seguros_det       if @@error <> 0 return 708230
insert ca_seguros_can       select * from #seguros_can       if @@error <> 0 return 708229
insert ca_operacion_ext     select * from #operacion_ext     if @@error <> 0 return 724597

-- KDR-20/08/2021 Recuperar historicos de Rubros Diferidos de una operación.
if @i_tiene_rub_dif = 'S'
begin
   select * into #rubros_diferidos  from cob_cartera..ca_control_rubros_diferidos_his     where 1=2 -- Creación Nueva estructura
   if @w_base_origen = 'P' begin
      insert into #rubros_diferidos  select * from cob_cartera..ca_control_rubros_diferidos_his where  crdh_operacion = @i_operacionca and  crdh_secuencial = @i_secuencial 
	  if @@error <> 0 return 710001 
   end
   
   alter table #rubros_diferidos  drop column  crdh_secuencial if @@error <> 0 return 710002 
   delete ca_control_rubros_diferidos where crd_operacion  = @i_operacionca if @@error <> 0 return 710003
   insert ca_control_rubros_diferidos select * from #rubros_diferidos  if @@error <> 0 return 711104
   
end

---VALIDACIONES DESPUES DE RECUPERAR LA OPERACION
select 
@w_estado_op  = op_estado, 
@w_toperacion = op_toperacion   
from   ca_operacion
where  op_operacion = @i_operacionca
   
if @w_estado_op <> 0  and @w_toperacion <> 'REVOLVENTE'--DESEMBOLSADA
begin
   if not exists (select 1
   from   ca_dividendo
   where  di_operacion = @i_operacionca 
   and    di_estado not in (0,3) )
   
   begin
      --GFP se suprime print
      --print 'histdef.sp SE RECUPERO DIVIDENDOS CON ERRORES '+ cast(@w_error as varchar) + ' OBLIGACION ' + cast(@i_operacionca as varchar) + ' SEC ' + cast(@i_secuencial as varchar)
      return  710575
   end
end

return 0

ERROR:

return @w_error

go
