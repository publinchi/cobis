/************************************************************************/
/*   Archivo:              gen_ref_emergente.sp                         */
/*   Stored procedure:     sp_genera_referencia_emergente      			*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raúl Altamirano Mendez                       */
/*   Fecha de escritura:   Diciembre 2017                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*  srojas               13-Sept-2018          Modificaciones generación*/
/*                                             de referencias diferentes*/
/*                                             corresponsales.          */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_genera_referencia_emergente')
   drop proc sp_genera_referencia_emergente
go

create proc sp_genera_referencia_emergente
(
   @s_user          login       = null,
   @s_ofi           smallint    = null,
   @s_date          datetime    = null,
   @s_term          varchar(30) = null,
   @i_grupo         int         = null,
   @i_banco         cuenta		 = null,
   @i_fecha_venci   datetime	 = null
)
as 

declare
@w_error                     int,
@w_return                    int,
@w_fecha_proceso             datetime,
@w_fecha_vencimiento         datetime,
@w_banco                     cuenta,
@w_est_vigente               tinyint,
@w_est_vencida               tinyint,
@w_lon_operacion             tinyint,
@w_format_fecha              varchar(30),
@w_toperacion                varchar(30),
@w_param_ISSUER              varchar(30),
@w_sp_name                   varchar(30),
@w_msg                       varchar(255),
@w_par_fp_co_pag_ref         varchar(10),
@w_param_convgar             varchar(30),
@w_param_convpre             varchar(30),
@w_institucion1              varchar(20),
@w_institucion2              varchar(20),
@w_grupo                     int, 
@w_fecha                     datetime, 
@w_corresponsal              varchar(20), 
@w_fecha_venci               datetime, 
@w_monto_pago                money, 
@w_referencia                varchar(40),
@w_ref_santander             varchar(40),
@w_fecha_ini                 datetime ,
@w_ciudad_nacional           int,
@w_mensaje                   varchar(150),
@w_sql                       varchar(5000),
@w_sql_bcp                   varchar(5000),
@w_batch                     int,
@w_formato_fecha             int,
@w_ruta_xml                  varchar(255),
@w_nombre_xml                varchar(30),
@w_id_corresp                varchar(10),
@w_sp_corresponsal           varchar(50),
@w_descripcion_corresp       varchar(30),
@w_fail_tran                 char(1),
@w_convenio                  varchar(30)


select @w_sp_name = 'sp_genera_referencia_emergente'


select @w_toperacion = 'GRUPAL', @w_batch = 7071, @w_formato_fecha = 111 


declare @resultadobcp table (linea varchar(max))


declare @TablaRefGrupos as table 
(
   grupo        int, 
   correo       varchar(255), 
   rol			varchar(30), 
   ente		int, 
   nombre		varchar(60), 
   cargo		varchar(100)
)

declare @TablaInfoPresGroup as table 
(
   grupo			int, 
   cliente			int, 
   operacion		int, 
   tramite			int,
   ope_grupal		cuenta, 
   dividendo		int, 
   fecha_ven		datetime, 
   fecha_ult_pro	datetime
)



/*DETERMINAR FECHA DE PROCESO*/
select @w_fecha_proceso     = fc_fecha_cierre,
       @w_fecha_vencimiento = isnull(@i_fecha_venci, fc_fecha_cierre)
from cobis..ba_fecha_cierre 
where  fc_producto = 7


--HASTA ENCONTRAR EL HABIL ANTERIOR
select  @w_fecha_ini  = dateadd(dd,-1,@w_fecha_proceso)


while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_ini ) 
   select @w_fecha_ini = dateadd(dd,-1,@w_fecha_ini)


exec @w_error = sp_estados_cca
@o_est_vigente  = @w_est_vigente out,
@o_est_vencido  = @w_est_vencida out


select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'


select @w_param_ISSUER = pa_char
from  cobis..cl_parametro 
where pa_nemonico = 'ISSUER' 
and   pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724629
	goto ERROR_PROCESO
end

select @w_param_convpre = pa_char
from  cobis..cl_parametro 
where pa_nemonico = 'CNVPRE' 
and   pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 70188
	goto ERROR_PROCESO
end

select @w_lon_operacion = pa_tinyint
from  cobis..cl_parametro 
where pa_nemonico = 'LOOPA' 
and   pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724653
   goto ERROR_PROCESO
end

select @w_format_fecha = pa_char
from  cobis..cl_parametro 
where pa_nemonico = 'FFOPA' 
and   pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_error = 724654
   goto ERROR_PROCESO
end

select @w_ruta_xml = ba_path_destino
from cobis..ba_batch 
where ba_batch = @w_batch

if (@@error != 0 or @@rowcount != 1 or isnull(@w_ruta_xml, '') = '')
begin
   select @w_error = 724636
   goto ERROR_PROCESO
end

select @w_nombre_xml = b.valor
from  cobis..cl_tabla a, cobis..cl_catalogo b
where a.codigo = b.tabla
and a.tabla = 'ca_param_notif'
and b.codigo = 'PFPCO_NXML'

if (@@error != 0 or @@rowcount != 1 or isnull(@w_nombre_xml, '') = '')
begin
   select @w_error = 724640
   goto ERROR_PROCESO
end


delete from ca_gen_notif_emergente WHERE gne_grupo_id >= 0
delete from ca_gen_notif_emergente_det WHERE gned_grupo_id >= 0
   
if (@@error != 0)
begin
   select @w_error = 724630
	goto ERROR_PROCESO
end


insert into @TablaInfoPresGroup (grupo, cliente, operacion, tramite, ope_grupal, dividendo, fecha_ven, fecha_ult_pro)
select tg_grupo, tg_cliente, tg_operacion, tg_tramite, tg_referencia_grupal, di_dividendo, di_fecha_ven, op_fecha_ult_proceso
from  cob_credito..cr_tramite_grupal, ca_operacion, ca_dividendo (nolock)
where tg_grupo      = @i_grupo
and   tg_cliente	= op_cliente
and   op_operacion	= tg_operacion
and	  op_operacion	= di_operacion 
and   di_estado		= @w_est_vigente
and   op_estado		in (@w_est_vigente, @w_est_vencida)
and   op_toperacion	= @w_toperacion
and   di_fecha_ven	between @w_fecha_ini and @w_fecha_vencimiento
and   op_fecha_ult_proceso = @w_fecha_proceso
		 

if (@@error != 0)
begin
	select @w_error = 724631
	goto ERROR_PROCESO
end

insert into ca_gen_notif_emergente 
(gne_grupo_id, gne_fecha_proceso, gne_grupo_name, gne_op_fecha_liq, gne_op_moneda, 
gne_op_oficina, gne_di_fecha_vig, gne_di_dividendo, gne_di_monto)
select	
grupo, 
@w_fecha_proceso, 
gr_nombre, 
opg.op_fecha_liq, 
opg.op_moneda, 
opg.op_oficina, 
fecha_ven, 
dividendo, 
sum(am_cuota + am_gracia - am_pagado)		
from @TablaInfoPresGroup, ca_dividendo (nolock), ca_amortizacion (nolock), cobis..cl_grupo, ca_operacion opg
where grupo			= gr_grupo
and	  operacion		= di_operacion 
and   di_operacion	= am_operacion
and   di_dividendo	= am_dividendo
and   di_estado		= @w_est_vigente
and   opg.op_banco	= ope_grupal 
group by grupo, tramite, ope_grupal, gr_nombre, fecha_ven, dividendo, opg.op_fecha_liq, opg.op_moneda, opg.op_oficina, opg.op_operacion
order by grupo, tramite, ope_grupal, gr_nombre, fecha_ven, dividendo, opg.op_fecha_liq, opg.op_moneda, opg.op_oficina, opg.op_operacion

if (@@error != 0)
begin
	select @w_error = 724632
	goto ERROR_PROCESO
end

select @w_id_corresp = 0



while 1 = 1  begin
   select top 1
   @w_id_corresp          = co_id,   
   @w_corresponsal        = co_nombre,
   @w_descripcion_corresp = co_descripcion,
   @w_sp_corresponsal     = co_sp_generacion_ref,
   @w_convenio            = co_convenio
   from  ca_corresponsal 
   where co_id            > @w_id_corresp
   and   co_estado        = 'A'
   order by co_id asc
   
   if @@rowcount = 0 break
   
   exec @w_error     = @w_sp_corresponsal
   @i_tipo_tran      = 'PG',
   @i_id_referencia  = @i_grupo,
   @i_monto          = null,
   @i_monto_desde    = null,
   @i_monto_hasta    = null,
   @i_fecha_lim_pago = null,	  
   @o_referencia     = @w_referencia out
   
   
   if @w_error <> 0 begin
     select 
     @w_error = 70207, @w_fail_tran = 'S'
     GOTO ERROR_PROCESO
   end
   
   insert into ca_gen_notif_emergente_det 	  
   (gned_grupo_id, gned_fecha_proceso,  gned_corresponsal, gned_institucion,      gned_referencia, gned_convenio)
   values
   (@i_grupo,      @w_fecha_proceso,    @w_corresponsal,   @w_descripcion_corresp, @w_referencia,   @w_convenio)
     
end


insert into @TablaRefGrupos (grupo, correo, rol, ente, nombre, cargo)
select cg_grupo, di_descripcion, cg_rol, di_ente, en_nomlar, b.valor
from cobis..cl_direccion, cobis..cl_cliente_grupo, cobis..cl_ente,
     cobis..cl_tabla a, cobis..cl_catalogo b
where di_ente = cg_ente
and di_ente = en_ente
and cg_grupo in (select gne_grupo_id from ca_gen_notif_emergente)
and di_tipo in ('CE')
and cg_rol in ('P', 'T', 'S')
and cg_rol = b.codigo
and a.codigo = b.tabla
and a.tabla = 'cl_rol_grupo'

if (@@error != 0)
begin
   select @w_error = 724631
   goto ERROR_PROCESO
end
 
update ca_gen_notif_emergente set 
gne_dest_nombre1 = b.nombre, 
gne_dest_cargo1	= b.cargo, 
gne_dest_email1	= b.correo 
from @TablaRefGrupos b 
where gne_grupo_id  = b.grupo
and b.rol           = 'P'
and gne_fecha_proceso= @w_fecha_proceso

if (@@error != 0)
begin
   select @w_error = 724633
   goto ERROR_PROCESO
end

update ca_gen_notif_emergente set 
gne_dest_nombre2 = b.nombre, 
gne_dest_cargo2	= b.cargo, 
gne_dest_email2	= b.correo
from @TablaRefGrupos b 
where gne_grupo_id  = b.grupo
and b.rol           = 'T'
and gne_fecha_proceso= @w_fecha_proceso

if (@@error != 0)
begin
   select @w_error = 724633
   goto ERROR_PROCESO
end

update ca_gen_notif_emergente set 
gne_dest_nombre3 = b.nombre, 
gne_dest_cargo3	= b.cargo, 
gne_dest_email3	= b.correo
from @TablaRefGrupos b 
where gne_grupo_id  = b.grupo
and b.rol           = 'S'
and gne_fecha_proceso= @w_fecha_proceso

if (@@error != 0)
begin
   select @w_error = 724633
   goto ERROR_PROCESO
end


--select * from ca_gen_notif_emergente


select
@w_sql = 'SELECT gne_grupo_id as grupo_id, ' +
'gne_fecha_proceso as fecha_proceso, ' +
'isnull(gne_grupo_name, ' + char(39) + char(32) + char(39) + ') as grupo_name, ' +
'gne_op_fecha_liq as fecha_liq, ' +
'gne_op_moneda as moneda, ' +
'of_nombre as oficina, ' +
'gne_di_fecha_vig as fecha_vig, ' +
'gne_di_dividendo as dividendo, ' +
'gne_di_monto as monto, ' +
'isnull(gne_dest_nombre1, ' + char(39) + char(32) + char(39) + ') as dest_nombre1, ' +
'isnull(gne_dest_cargo1, ' + char(39) + char(32) + char(39) + ') as dest_cargo1, ' +
'isnull(gne_dest_email1, ' + char(39) + char(32) + char(39) + ') as dest_email1, ' +
'isnull(gne_dest_nombre2, ' + char(39) + char(32)+ char(39) + ') as dest_nombre2, ' +
'isnull(gne_dest_cargo2, ' + char(39) + char(32) + char(39) + ') as dest_cargo2, ' +
'isnull(gne_dest_email2, ' + char(39) + char(32) + char(39) + ') as dest_email2, ' +
'isnull(gne_dest_nombre3, ' + char(39) + char(32) + char(39) + ') as dest_nombre3, ' +
'isnull(gne_dest_cargo3, ' + char(39) + char(32) + char(39) + ') as dest_cargo3, ' +
'isnull(gne_dest_email3 , ' + char(39) + char(32) + char(39) + ') as dest_email3, ' +
'(select isnull(gned_referencia, ' + char(39) + char(32) + char(39) + ') as referencia, '+
'isnull(gned_institucion,' + char(39) + char(32) + char(39) + ') as institucion, '+
'isnull(gned_convenio,' + char(39) + char(32) + char(39) + ') as nro_convenio '+
'from cob_cartera..ca_gen_notif_emergente_det '+
'where gned_fecha_proceso = gne_fecha_proceso '+
'and gned_grupo_id = gne_grupo_id '+
'order by gned_institucion asc '+
'FOR XML PATH(' + char(39) + 'Referencia'+ char (39) + '), TYPE ) '+
'FROM cob_cartera..ca_gen_notif_emergente, cobis..cl_oficina ' +
'where gne_op_oficina = of_oficina ' +
'and convert(varchar, gne_fecha_proceso, ' + 
convert(varchar, @w_formato_fecha) + ') = ' + char(39) + convert(varchar, @w_fecha_proceso, @w_formato_fecha) + char(39) + 
' FOR XML PATH(' + char(39) + 'Pago' + char (39) + '), ROOT(' + char(39) + 'PagoCorresponsal' + char (39) + '), ELEMENTS'


select @w_sql_bcp = 'bcp "' + @w_sql + '" queryout "' + @w_ruta_xml + @w_nombre_xml + '" -c -r -t\t -T'

delete from @resultadobcp

insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

select * from @resultadobcp

--SELECCIONA CON %ERROR% SI NO ENCUENTRA EN EL FORMATO: ERROR = 
if @w_mensaje is null
    select top 1 @w_mensaje = linea 
    from  @resultadobcp 
    where upper(linea) LIKE upper('%Error %')

if @w_mensaje is not null
begin
	select @w_error = 724625
	goto ERROR_PROCESO
end

if exists(select 1 from ca_gen_notif_emergente)
begin
   exec @w_return = sp_ca_ejecuta_notificacion_jar
        @i_param1 = 'PFPCO'
		
   if @w_return != 0 
   begin
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
end

return 0

   
ERROR_PROCESO:
   select @w_msg = mensaje
   from cobis..cl_errores with (nolock)
   where numero = @w_error
   set transaction isolation level read uncommitted  
     
   select @w_msg = @w_msg 
   
   return @w_error

go


