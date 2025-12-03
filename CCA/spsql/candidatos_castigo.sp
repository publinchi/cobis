/************************************************************************/
/*   Archivo:             candidatos_castigo.sp                         */
/*   Stored procedure:    sp_carga_masivos_ext                          */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Fecha de escritura:  Nov-26-2003                                   */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA"                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  

use cob_cartera
go

/*CREACION DE TABLA TEMPORAL PARA EL REPORTE */
if exists (select 1 from sysobjects where id = object_id('pro_cast_cartera'))
   drop table cob_cartera..pro_cast_cartera
go

create table cob_cartera..pro_cast_cartera
(
cod_ofi            smallint    null,  
nombre             varchar(64) null,   
banco              varchar(24) null, 
cliente            int         null,
monto              money       null, 
sald_cap           money       null, 
sald_inte          money       null, 
sald_otr           money       null, 
tipo               varchar(10) null, 
dias_mora          int         null,
ejecutivo          smallint    null,
ejecutivo_ori      smallint    null,
actividad          varchar(10) null,
fondo              varchar(10) null,
blanco             varchar(50) null,
blanco_1           varchar(50) null,
val_garantia       money       null,
estado_cartera     int         null
)

if exists (select 1 from sysobjects where name = 'sp_candidatos_castigo')
   drop proc sp_candidatos_castigo
go

create proc sp_candidatos_castigo
@i_param1 varchar(255)

as

delete cob_cartera..pro_cast_cartera WHERE cod_ofi >= 0

declare 
@w_fecha          datetime,
@w_dias_mora      int,
@w_path           varchar(250),
@w_cmd            varchar(250),
@w_s_app          varchar(250),
@w_destino        varchar(250),
@w_comando        varchar(1000),
@w_error          int,
@w_errores        varchar(250),
@w_nombre_plano   varchar(500),
@w_col_id         int,
@w_columna        varchar(30),
@w_cabecera       varchar(2500)

select @w_dias_mora =  convert(int, @i_param1)

select @w_fecha = max(do_fecha)
from cob_conta_super..sb_dato_operacion with(index = idx3)
where do_aplicativo = 7

select distinct 
cliente   = do_codigo_cliente
into #clientes
from cob_conta_super..sb_dato_operacion with (index = idx3)
where do_fecha            = @w_fecha
and   do_aplicativo       = 7
and   (do_estado_contable = 1 or do_estado_contable = 2)
and   do_edad_mora       >= @w_dias_mora

--Encontrar clientes castigados para ver si al momento de la ejecucion tiene creditos vigentes en mora
select distinct 
ca_cliente   = do_codigo_cliente
into #clientes_cast
from cob_conta_super..sb_dato_operacion with (index = idx3)
where do_fecha            = @w_fecha
and   do_aplicativo       = 7
and   do_estado_contable = 3

delete #clientes_cast
from #clientes
where ca_cliente = cliente

create index idx1 on #clientes_cast (ca_cliente)

insert into #clientes
select distinct ca_cliente
from cob_conta_super..sb_dato_operacion, #clientes_cast
where do_fecha            = @w_fecha
and   do_aplicativo       = 7
and   do_codigo_cliente   = ca_cliente
and   (do_estado_contable = 1 or do_estado_contable = 2)
and   do_edad_mora        > 0

select 
oficina   = do_oficina,
nombre    = convert(varchar(64), ''),
banco     = do_banco,
cliente   = do_codigo_cliente,
monto     = do_monto,
sal_cap   = do_saldo_cap,
sal_int   = do_saldo_int,
sal_otr   = do_saldo - do_saldo_int - do_saldo_cap,
tipo      = do_tipo_operacion,
dias_mora = do_edad_mora,
ejecutivo = do_oficial,
ejec_orig = do_oficial,
actividad = convert(varchar(10),''),
fondo     = convert(varchar(10),''),
val_garan = do_valor_garantias,
est_cart  = do_estado_cartera
into #operaciones
from cob_conta_super..sb_dato_operacion with (index = idx3)
where do_fecha          = @w_fecha
and   do_aplicativo     = 7
and   do_codigo_cliente in (select cliente from #clientes)

update #operaciones set
nombre    = en_nomlar,
actividad = en_actividad
from cobis..cl_ente
where cliente = en_ente

update #operaciones set
fondo     = op_origen_fondos,
ejecutivo = isnull(ejecutivo, op_oficial),
ejec_orig = isnull(ejec_orig, op_oficial)
from ca_operacion
where op_banco = banco

insert   cob_cartera..pro_cast_cartera
select 
oficina   ,
nombre    ,
banco     ,
cliente   ,
monto     ,
sal_cap   ,
sal_int   ,
sal_otr   ,
tipo      ,
dias_mora ,
ejecutivo ,
ejec_orig ,
actividad ,
fondo     ,
'',    
'',
val_garan,
est_cart
from #operaciones 



----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------

select @w_s_app = pa_char 
from cobis..cl_parametro 
where pa_producto = 'ADM' 
and   pa_nemonico = 'S_APP'

select @w_path  = ba_path_destino 
from cobis..ba_batch 
where ba_arch_fuente = 'cob_cartera..sp_candidatos_castigo'

select 
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = convert(varchar(2000), '')

select 
@w_nombre_plano = @w_path + 'pro_cast_ca.txt'

while 1 = 1 begin
   set rowcount 1
   select @w_columna = c.name,
          @w_col_id  = c.colid
   from sysobjects o, syscolumns c
   where o.id    = c.id
   and   o.name  = 'pro_cast_cartera'
   and   c.colid > @w_col_id
   order by c.colid

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   select @w_cabecera = @w_cabecera + @w_columna + '^!'
end

select @w_cabecera = left(@w_cabecera, datalength(@w_cabecera) - 2)

--Escribir Cabecera
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando Archivo Candidatos Castigo cabecera'
   print @w_comando
   return 1
end


-- Generar Archivo Plano de Datos

select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..pro_cast_cartera out '
select @w_destino = @w_path + 'pro_cast_ca_dat.txt', @w_errores  = @w_path + 'pro_cast_ca_dat.err'
select @w_comando = @w_cmd + @w_path + 'pro_cast_ca_dat.txt -b5000 -c -e' + @w_errores + ' -t"!" ' + '-config '+ @w_s_app + 's_app.ini'

exec   @w_error   = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error generando Archivo Candidatos Castigo'
   print @w_comando
   return 1
end


----------------------------------------
--Union de archivos
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'pro_cast_ca_dat.txt' + ' ' + @w_nombre_plano

select @w_comando

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando Archivo Candidatos Castigo con cabecera'
   print @w_comando
   return 1
end

return 0
go

