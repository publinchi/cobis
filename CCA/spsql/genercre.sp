/************************************************************************/
/*      Archivo:                genercre.sp                             */
/*      Stored procedure:       sp_variables_generales_cre              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Xavier Maldonado                        */
/*      Fecha de escritura:     Julio 06 2001                           */
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
/*      Retornar al front-end variables generales de trabajo            */
/*      CREDITO TRABAJA CON LA FECHA DE PROCESO DE ESTE PROGRAMA        */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/************************************************************************/  

use cob_cartera
go

-- ********* Se eliminan las tablas temporales por variables tipo tabla ****
--if exists (select * from sysobjects where name = "tmp_dec")
--   drop table tmp_dec
--go
--
--create table tmp_dec
--(
--  letra    char(1),
--  num_dec  tinyint,
--  spid     int
--)-- lock datarows
--go
--
----alter table tmp_dec partition 100
--go
--
--if exists (select * from sysobjects where name = "tmp_en_tmp")
--   drop table tmp_en_tmp
--go
--
--create table tmp_en_tmp
--(
--en_usuario      login,
--en_terminal     varchar,
--en_operacion    int,
--spid            int
--) lock datarows
--go
--
----alter table tmp_en_tmp partition 100
--go
--
--if exists (select * from sysobjects where name = "tmp_mon")
--   drop table tmp_mon
--go
--      
--create table tmp_mon
--(
--   tm_moneda tinyint, 
--   tm_fecha datetime, 
--   tm_trm   money,
--   tm_dec   tinyint,
--   spid     int
--)lock datarows
--go

--alter table tmp_mon partition 100
--go
if exists (select 1 from sysobjects where name = 'sp_variables_generales_cre')
   drop proc sp_variables_generales_cre
go
create proc sp_variables_generales_cre
   @s_ofi       smallint = null,
   @s_user      login,
   @s_term      varchar(30),
   @s_sesn      int
as
declare 
   @w_sp_name             descripcion,
   @w_return              int,
   @w_error               int,
   @w_moneda_local        int,
   @w_est_vigente         catalogo,
   @w_est_no_vigente      catalogo,
   @w_est_vencido         catalogo,
   @w_est_cancelado       catalogo,
   @w_est_castigado       catalogo,
   @w_cod_oficina         varchar(10),
   @w_desc_oficina        descripcion,
   @w_cod_oficial         smallint,
   @w_desc_oficial        descripcion,
   @w_cod_destino         catalogo,
   @w_desc_destino        descripcion,
   @w_cod_ciudad          int,
   @w_desc_ciudad         descripcion,
   @w_num_dec             tinyint,
   @w_est_credito         catalogo,
   @w_operacionca         int,
   @w_banco               cuenta,
   @w_clase_cartera       catalogo,
   @w_desc_clase_cartera  descripcion,
   @w_origen_fondos       catalogo,
   @w_desc_origen_fondos  descripcion,
   @w_tipo_rotativo       varchar(30),
   @w_ipc                 tinyint,
   @w_num_dec_ipc         tinyint,
   @w_trm                 float,
   @w_trm_ipc             float,
   @w_producto            tinyint,
   @w_num_loc             tinyint,
   @w_fecha_proceso       datetime,
   @w_rowcount            int

DECLARE @w_tmp_dec    TABLE (letra      char(1), num_dec     tinyint,  spid         int)
DECLARE @w_tmp_en_tmp TABLE (en_usuario login,   en_terminal varchar,  en_operacion int,   spid   int)
DECLARE @w_tmp_mon    TABLE (tm_moneda  tinyint, tm_fecha    datetime, tm_trm       money, tm_dec tinyint, spid int)

   
-- CARGAR VALORES INICIALES
select @w_sp_name = 'sp_variables_generales_cre'

select @w_fecha_proceso = fp_fecha   --SBU 01/feb/2002
from cobis..ba_fecha_proceso

-- CONSULTA CODIGO DE MONEDA LOCAL
SELECT  @w_moneda_local = pa_tinyint
FROM cobis..cl_parametro
WHERE pa_nemonico = 'MLO'
AND pa_producto = 'ADM'
set transaction isolation level read uncommitted


-- NUMERO DE DECIMALES
select @w_num_dec = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'NDE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 708130
   goto ERROR
end   

-- NUMERO DE DECIMALES
select @w_num_loc = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'NDEOM'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted



if @w_rowcount = 0
begin
   select @w_error = 708130
   goto ERROR
end   

--delete tmp_dec where spid    = @@spid
--delete tmp_en_tmp where spid = @@spid
--delete tmp_mon where spid    = @@spid

insert into @w_tmp_dec values ('N', 0,          @@spid)
insert into @w_tmp_dec values ('S', @w_num_dec, @@spid)

insert into @w_tmp_mon
select ct_moneda,
       ct_fecha,
       ct_valor,
       d.num_dec,
       @@spid
from cob_conta..cb_cotizacion,
     cobis..cl_moneda x, 
     @w_tmp_dec d
where  ct_moneda = mo_moneda
and    d.letra = mo_decimales
and    ct_fecha = (select max(ct_fecha)         --SBU 01/feb/2002
                   from cob_conta..cb_cotizacion
                   where ct_moneda = x.mo_moneda
                   and ct_fecha <= @w_fecha_proceso)
and    d.spid = @@spid



update @w_tmp_mon
set    tm_dec  = @w_num_loc
where  tm_moneda <> @w_moneda_local
and    spid      = @@spid

select distinct tm_moneda, tm_fecha, tm_trm, tm_dec
from   @w_tmp_mon
where  spid = @@spid

select @w_moneda_local

select fi_nombre
from   cobis..cl_filial
where  fi_filial = 1 
set transaction isolation level read uncommitted

-- ESTADOS

select @w_est_no_vigente = es_descripcion
from   ca_estado
where  es_codigo = 0

select @w_est_vigente = es_descripcion
from   ca_estado
where  es_codigo = 1

select @w_est_vencido = es_descripcion
from   ca_estado
where  es_codigo = 2

select @w_est_cancelado = es_descripcion
from   ca_estado
where  es_codigo = 3

select @w_est_castigado = es_descripcion
from   ca_estado
where  es_codigo = 4                              

select @w_est_credito = es_descripcion
from   ca_estado
where  es_codigo = 99                   

select 
@w_est_vigente,
@w_est_no_vigente,
@w_est_vencido,
@w_est_cancelado,
@w_est_vencido,
@w_est_cancelado,
@w_est_castigado    


  select convert(varchar(10),fp_fecha,101)
  from cobis..ba_fecha_proceso


/* NUERO DE DIAS DE LOS TIPOS DE DIVIDENDO */

select   td_tdividendo,td_factor
from     ca_tdividendo
where    td_estado = 'V'
order by td_tdividendo        

/* PARAMETROS POR DEFECTO PARA CREACION DE OPERACIONES */

print 'oficina'  + cast(@s_ofi as varchar) 

select
@w_desc_oficina = of_nombre
from   cobis..cl_oficina
where  of_oficina = @s_ofi
set transaction isolation level read uncommitted

set rowcount 1

select @w_cod_oficina = Y.codigo
from cobis..cl_tabla X,
cobis..cl_catalogo Y
where X.tabla = 'cl_oficina'
and   X.codigo = Y.tabla
and   Y.codigo  = convert(varchar(25),@s_ofi)
set transaction isolation level read uncommitted


select 
@w_cod_oficial   = oc_oficial,
@w_desc_oficial  = fu_nombre
from   cobis..cc_oficial,cobis..cl_funcionario
where  oc_funcionario = fu_funcionario
order  by oc_oficial
set transaction isolation level read uncommitted

set rowcount 1

select @w_cod_destino=y.codigo,@w_desc_destino=valor
from cobis..cl_catalogo y, cobis..cl_tabla t
where t.tabla = 'cr_destino'
and y.tabla   = t.codigo
set transaction isolation level read uncommitted

select @w_cod_ciudad=of_ciudad,@w_desc_ciudad=ci_descripcion
from   cobis..cl_oficina,cobis..cl_ciudad
where  of_oficina = @s_ofi
and    of_ciudad  = ci_ciudad
set transaction isolation level read uncommitted


set rowcount 0


/* BORRADO DE LA TABLA ca_en temporales */

/*AUMENTADO CURSOR PARA BORRAR TODAS LAS OPERACIONES QUE SE HAN QUEDADO EN 
TEMPORALES PARA ESE USUARIO Y ESE TERMINAL 20/10/98*/

insert into @w_tmp_en_tmp
select  *, @@spid
from ca_en_temporales 
where en_usuario  = @s_user
and   en_terminal = @s_term

declare temporales cursor for
select  en_operacion 
from @w_tmp_en_tmp
where spid = @@spid
for read only 

open temporales

fetch temporales into @w_operacionca

if (@@fetch_status = 0)  begin

   while (@@fetch_status = 0 )
   begin
      select @w_banco = opt_banco
      from ca_operacion_tmp 
      where opt_operacion = @w_operacionca
      
      exec sp_borrar_tmp_int
      @s_user   = @s_user,
      @s_term   = @s_term,
      @s_sesn   = @s_sesn,
      @i_banco  = @w_banco

      fetch temporales into @w_operacionca

   end

end

close temporales
deallocate temporales
-- HASTA AQUI AUMENTADO CURSOR 20/10/98

select @w_clase_cartera = '1'

set rowcount 1

/*DESCRIPCIONES DE CLASE DE CARTERA Y ORIGEN DE FONDOS*/
select @w_desc_clase_cartera = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'cr_clase_cartera'
and   X.codigo= Y.tabla
and   Y.codigo= @w_clase_cartera 
set transaction isolation level read uncommitted

select @w_origen_fondos = 'ORD'

select @w_desc_origen_fondos = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'ca_fondos_propios'
and   X.codigo= Y.tabla
and   Y.codigo= @w_origen_fondos 
set transaction isolation level read uncommitted

/*TIPO DE CREDITOS ROTATIVOS*/
select @w_tipo_rotativo = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'ROT'
set transaction isolation level read uncommitted

set nocount on
/*DESPLEGAR AL FRONT-END*/
select @w_cod_oficina
select @w_desc_oficina
select @w_cod_oficial
select @w_desc_oficial
select @w_cod_destino
select @w_desc_destino
select @w_cod_ciudad
select @w_desc_ciudad
select @w_est_credito
select @w_clase_cartera
select @w_desc_clase_cartera
select @w_origen_fondos
select @w_desc_origen_fondos
select @w_tipo_rotativo
set nocount off

set rowcount 0

--delete tmp_dec where spid    = @@spid
--delete tmp_en_tmp where spid = @@spid
--delete tmp_mon where spid    = @@spid

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error


return @w_error
