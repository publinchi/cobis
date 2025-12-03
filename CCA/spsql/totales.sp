/************************************************************************/
/*		Nombre Fisico:			totales.sp								*/
/*      Nombre Logico:          sp_totales                              */
/*      Base de Datos:          cob_cartera                             */
/*      Disenado Por:           Fabian de la Torre                      */
/*      Fecha:                  Sep/2002                                */
/************************************************************************/
/*                              IMPORTANTE                              */
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
/*                              PROPOSITO                               */
/*    Totaliza las transacciones a contabilizar.                        */
/************************************************************************/
/*								MODIFICACIONES							*/
/*		Fecha			Autor					Razon					*/
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion y  */
/*									 @w_calificacion_ant                */
/*									 de char(1) a catalogo 				*/
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_totales')
   drop proc sp_totales
go
 
 
create proc sp_totales
   @i_debug             varchar(1) = 'N',
   @i_fecha             datetime

as declare
   @w_error             int,
   @w_fecha_proceso     datetime,
   @w_mensaje           varchar(255),
   @w_descripcion       varchar(255),
   @w_descripcion_ant   varchar(255),
   @w_tr_ofi_usu        int,
   @w_tr_ofi_oper       int,
   @w_tr_fecha_ref      datetime,
   @w_tr_fecha_mov      datetime,
   @w_tr_tran           catalogo,
   @w_tr_moneda         int,
   @w_toperacion        catalogo,
   @w_tr_estado         catalogo,
   @w_sector            catalogo,
   @w_operacionca       int,
   @w_secuencial        int,
   @w_concepto          catalogo,
   @w_monto             money,
   @w_am_estado         int,
   @w_am_estado_ant     int,
   @w_tr_ofi_usu_ant    int,
   @w_tr_ofi_oper_ant   int,
   @w_tr_fecha_ref_ant  datetime,
   @w_tr_fecha_mov_ant  datetime,
   @w_tr_tran_ant       catalogo,
   @w_tr_moneda_ant     int,
   @w_toperacion_ant    catalogo,
   @w_tr_estado_ant     catalogo,
   @w_sector_ant        catalogo,
   @w_concepto_ant      catalogo,
   @w_monto_ant         money,
   @w_factor            int,
   @w_total             int,
   @w_cv_prv            int,
   @w_fecha             smalldatetime,
   @w_fecha_desde       smalldatetime,
   @w_fecha_hasta       smalldatetime,
   @w_monto_prv         money,
   @w_sp_name           varchar(12),
   @w_gar_admisible     varchar(1),
   @w_calificacion      catalogo,
   @w_gar_admisible_ant varchar(1),
   @w_calificacion_ant  catalogo,
   @w_clase_cart        varchar(1),
   @w_clase_cart_ant    varchar(1),
   @w_clase_cust        varchar(1),
   @w_clase_cust_ant    varchar(1),
   @w_estado            int,
   @w_estado_ant        int,
   @w_categoria         varchar(2),
   @w_categoria_ant     varchar(2), 
   @w_operacion         int,
   @w_ente              int,
   @w_ente_ant          int,
   @w_tr_banco_ant      varchar(24),
   @w_tr_banco          varchar(24)
 


if @i_debug = 'S'
   print '---->sp_totales. Inicio'


/* DETERMINAR FECHA DE PROCESO */
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


/* VARIABLES DE TRABAJO */
select
@w_mensaje         = '',
@w_descripcion_ant = '',
@w_monto_prv       = 0.00,
@w_sp_name         = 'sp_totales'

   
/* CREAR TABLAS DE TRABAJO */
create table #transaccion_cab(
tr_fecha_mov      smalldatetime not null,
tr_ofi_oper       int           not null,    
tr_ofi_usu        smallint      not null,    
tr_fecha_ref      smalldatetime not null,
tr_tran           varchar(10)   not null,        
tr_moneda         smallint      not null,
tr_toperacion     varchar(10)   not null, 
tr_estado         varchar(10)   not null,
tr_operacion      int           not null,   
tr_secuencial     int           not null,
tr_concepto       varchar(10)   not null,
tr_am_estado      tinyint       not null,
tr_sector         varchar(10)   not null,
tr_monto          money         not null,
tr_gar_admisible  varchar(1)    not null,
tr_calificacion   catalogo    not null,
tr_clase_cart     varchar(1)    not null,
tr_clase_cust     varchar(1)    not null,
tr_estado_car     int           not null,
tr_categoria      varchar(2)    not null,
tr_ente           int           not null,
tr_banco          varchar(24)   not null
)

select *
into #totales
from ca_totales
where 1=2

select *
into #totales_det
from ca_totales_det
where 1=2

select *
into #det_trn
from ca_totales_det
where 1=2

select *
into #totales_trn
from ca_totales_trn
where 1=2

create table #transacciones(
operacion   int   not null,
secuencial  int   not null)


/* VERIFICAR QUE NO EXISTA TOTALES CONTABILIZADOS */
if exists (select 1 from ca_totales
           where to_fecha_mov   = @w_fecha_proceso
           and   to_comprobante > 0) begin
   select 
   @w_error   = 710003,
   @w_mensaje = 'YA EXISTEN COMPROBANTES CONTABILIZADOS A LA FECHA'
   goto ERRORFIN
end

/* VERIFICAR QUE EXISTA UN PERIODO DE CORTE ABIERTO EN LA CONTABILIDAD */
if not exists(select 1 from cob_conta..cb_corte
              where co_empresa   = 1
              and   co_fecha_ini = @w_fecha_proceso
              and   co_estado in ('A','V')) begin
   select 
   @w_error   = 710003,
   @w_mensaje = 'ERROR: EL PERIODO DE CORTE PARA LA FECHA DE PROCESO ESTA CERRADO (cb_corte)'
   goto ERRORFIN
end

/* DETERMINAR EL RANGO DE FECHAS DE LAS TRANSACCIONES QUE SE INTENTARAN CONTABILIZAR */
select  
@w_fecha_desde = isnull(min(co_fecha_ini),'01/01/1900'),
@w_fecha_hasta = isnull(max(co_fecha_ini),'01/01/1900')
from cob_conta..cb_corte
where co_empresa = 1
and   co_estado in ('A','V')

/* INSERTAR EN TEMPORALES TOTALES A CONTABILIZAR */
select @w_fecha = @w_fecha_desde

while @w_fecha <= @w_fecha_hasta begin

   if exists(select 1 from ca_totales 
             where to_fecha_mov   = @w_fecha
             and   to_comprobante > 0)
   begin
      select @w_fecha_desde = dateadd(dd,1,@w_fecha)
   end
   
   select @w_fecha = dateadd(dd,1,@w_fecha)

end

/* NOTIFICAR QUE NO EXISTE NADA QUE PROCESAR */
if @w_fecha_desde > @w_fecha_hasta begin
   select 
   @w_error   = 710003,
   @w_mensaje = 'ERROR: EXISTEN COMPROBANTES CONTABILIZADOS EN TODO EL RANGO DE FECHAS'
   goto ERRORFIN
end


/* CONTROL PARA EVITAR REPROCESAR MAS ALLA DE LOS ULTIMOS 'n' DIAS */
if datediff(dd,@w_fecha_desde, @w_fecha_hasta) > 30
   select @w_fecha_desde = dateadd(dd,-90,@w_fecha_hasta)


/* EN CASO DE REPROCESO, ENTRAR BORRANDO TOTALES NO CONTABILIZADOS */
if exists (select 1 from ca_totales 
           where to_fecha_mov between @w_fecha_desde and @w_fecha_hasta) begin

   delete ca_totales_trn
   from ca_totales
   where tot_total    = to_total
   and   to_fecha_mov between @w_fecha_desde and @w_fecha_hasta

   if @@error <> 0 begin
      select 
      @w_error   = 710003,
      @w_mensaje = 'ERROR AL BORRAR RELACION DE TOTALES CON DETALLE'
      goto ERRORFIN
   end 

   delete ca_totales_det
   from ca_totales
   where tod_total    = to_total
   and   to_fecha_mov between @w_fecha_desde and @w_fecha_hasta

   if @@error <> 0 begin
      select 
      @w_error   = 710003,
      @w_mensaje = 'ERROR AL BORRAR DETALLE DE TOTALES'
      goto ERRORFIN
   end

   delete ca_totales
   where to_fecha_mov between @w_fecha_desde and @w_fecha_hasta

   if @@error <> 0 begin
      select 
      @w_error   = 710003,
      @w_mensaje = 'ERROR AL BORRAR TOTALES'
      goto ERRORFIN
   end

end


if @i_debug = 'S'
begin
   print '---->sp_totales. fecha_desde: ' + cast(@w_fecha_desde as varchar)
   print '---->sp_totales. fecha_hasta: ' + cast(@w_fecha_hasta as varchar)
end


/* TRANSACCIONES PRV INGRESADOS HOY */
insert into #transaccion_cab (
tr_fecha_mov,    tr_ofi_oper,    tr_ofi_usu,
tr_fecha_ref,    tr_tran,        tr_moneda,
tr_toperacion,   tr_estado,      tr_operacion,
tr_secuencial,   tr_concepto,    tr_am_estado,
tr_sector,       tr_monto,       tr_gar_admisible,
tr_calificacion, tr_clase_cart,  tr_clase_cust,
tr_estado_car,   tr_categoria,   tr_ente,
tr_banco)
select
tr_fecha_mov,    0,              0,
tr_fecha_mov,    'PRV',          99,
'',              'ING',          tr_operacion,   
tr_secuencial,   dtr_concepto,   dtr_estado,
'',              dtr_monto,      
case when tr_gar_admisible is null then 'S' when tr_gar_admisible = '' then 'S' else tr_gar_admisible end,
case when tr_calificacion is null then 'A' when tr_calificacion = '' then 'A' else tr_calificacion end,'', case when tr_gar_admisible = 'S' then 'I' else 'O' end,
0,               '',             0,
tr_banco
from ca_transaccion, ca_det_trn
where tr_fecha_mov    <= @i_fecha    
and   tr_estado       = 'ING' 
and   tr_secuencial = dtr_secuencial
and   tr_operacion  = dtr_operacion
and   tr_tran       = 'PRV'

if @@error <> 0 begin
   select 
   @w_mensaje = 'ERR: AL INSERTAR TRANSACCION CABECERA 3',
   @w_error   = 710001
   goto ERRORFIN
end


--create index #transaccion_cab_i1 on #transaccion_cab (tr_operacion)
create index transaccion_cab_i1 on #transaccion_cab (tr_operacion)

/* COMPLETAR LOS CAMPOS FALTANTES DESDE LOS DATOS DE LA OPERACION */
update #transaccion_cab set
tr_ofi_usu    = op_oficina,
tr_ofi_oper   = op_oficina,
tr_moneda     = op_moneda,
tr_toperacion = op_toperacion,
tr_sector     = op_sector,
tr_clase_cart = op_clase,
tr_estado_car = op_estado,
tr_ente       = op_cliente
from ca_operacion
where tr_operacion = op_operacion

if @@error <> 0 begin
   select 
   @w_mensaje = 'ERR: ACTUALIZAR LOS CAMPOS FALTANTES CON LOS DATOS DE LA OPERACION',
   @w_error   = 710002
   goto ERRORFIN
end


declare cursor_act cursor for
select op_operacion, op_toperacion
from ca_operacion

open cursor_act

fetch cursor_act into
@w_operacion, @w_toperacion

while @@fetch_status = 0 begin

   if @@fetch_status = -1 begin
      select 
      @w_mensaje = 'ERR: SALIDA INCORRECTA DEL CURSOR',
      @w_error   = 710005
      close cursor_tran
      deallocate cursor_tran
      goto ERRORFIN
   end

   select @w_categoria = dt_categoria
   from ca_default_toperacion
   where dt_toperacion = @w_toperacion

   update #transaccion_cab
   set tr_categoria = @w_categoria
   where tr_operacion = @w_operacion

   fetch cursor_act into
   @w_operacion, @w_toperacion

end
close cursor_act
deallocate cursor_act

/* TRANSACCIONES INGRESADAS HOY (SIN PRVS)*/
insert into #transaccion_cab (
tr_fecha_mov,    tr_ofi_oper,   tr_ofi_usu,
tr_fecha_ref,    tr_tran,       tr_moneda,
tr_toperacion,   tr_estado,     tr_operacion,
tr_secuencial,   tr_concepto,   tr_am_estado,
tr_sector,       tr_monto,      tr_gar_admisible,
tr_calificacion, tr_clase_cart, tr_clase_cust,
tr_estado_car,   tr_categoria,  tr_ente,
tr_banco)
select
tr_fecha_mov,    tr_ofi_oper,   case when tr_tran not in ('PAG','DES') then tr_ofi_usu else tr_ofi_oper end,
tr_fecha_mov,    tr_tran,       tr_moneda,
tr_toperacion,   'ING',         tr_operacion,   
tr_secuencial,   '',            0,
'',              0,             
case when tr_gar_admisible is null then 'S' when tr_gar_admisible = '' then 'S' else tr_gar_admisible end,
case when tr_calificacion is null then 'A' when tr_calificacion = '' then 'a' else tr_gar_admisible end,
'', case when tr_gar_admisible = 'S' then 'I' else 'O' end,
0,               '',            0,
tr_banco
from ca_transaccion 
where tr_fecha_mov    <= @i_fecha  --between @w_fecha_desde and @w_fecha_hasta
and   tr_tran not in ('REJ','CPE','IOC', 'PRV')
and   tr_estado       = 'ING' 

if @@error <> 0 begin
   select 
   @w_mensaje = 'ERR: AL INSERTAR TRANSACCION CABECERA 1',
   @w_error   = 710001
   goto ERRORFIN
end

/* TRANSACCIONES REVERSADAS HOY (SIN PRVS)*/

insert into #transaccion_cab (
tr_fecha_mov,    tr_ofi_oper,   tr_ofi_usu,
tr_fecha_ref,    tr_tran,       tr_moneda,
tr_toperacion,   tr_estado,     tr_operacion,
tr_secuencial,   tr_concepto,   tr_am_estado,
tr_sector,       tr_monto,      tr_gar_admisible,
tr_calificacion, tr_clase_cart, tr_clase_cust,
tr_estado_car,   tr_categoria,  tr_ente,
tr_banco)
select 
tr_fecha_ref,    tr_ofi_oper,   case when tr_tran not in ('PAG','DES') then tr_ofi_usu else tr_ofi_oper end,
tr_fecha_ref,    tr_tran,       tr_moneda,
tr_toperacion,   '',          tr_operacion,   
tr_secuencial,   '',            0,
'',              0,             
case when tr_gar_admisible is null then 'S' when tr_gar_admisible = '' then 'S' else tr_gar_admisible end,
case when tr_calificacion is null then 'A' when tr_calificacion = '' then 'a' else tr_gar_admisible end,
'', case when tr_gar_admisible = 'S' then 'I' else 'O' end,
0,               '',            0,
tr_banco
from ca_transaccion 
where tr_fecha_ref  <= @i_fecha --between @w_fecha_desde and @w_fecha_hasta
and   tr_tran  in ('REJ','CPE','IOC')
and   tr_estado     = 'ING'
--and   tr_fecha_ref <> tr_fecha_mov

if @@error <> 0 begin
   select 
   @w_mensaje = 'ERR: AL INSERTAR TRANSACCION CABECERA 2',
   @w_error   = 710001
   goto ERRORFIN
end

/* MARCA DE FINAL DE REGISTROS */
insert into #transaccion_cab values (
'01/01/2079',   9999,          9999,
'01/01/2079',  'ZZZ',          80,
'EOF',         'EOF',          9999,
9999,          '',             0,
'',             0,             '',
'Z',           'Z',            'Z',
0,             '',             0,
'')
if @@error <> 0 begin
   select 
   @w_mensaje = 'ERR: AL INSERTAR MARCA DE FINAL DE REGISTROS',
   @w_error   = 710001
   goto ERRORFIN
end


/* LIMPIAR TABLAS DE TRABAJO */
truncate table #det_trn
truncate table #transacciones


/* CURSOR PRINCIPAL DE TRANSACCIONES */
declare cursor_tran cursor for
select
tr_tran,            tr_ofi_oper,          tr_ofi_usu,
tr_fecha_mov,       tr_fecha_ref,         tr_moneda,
tr_toperacion,      tr_estado,            tr_operacion,   
tr_secuencial,      tr_concepto,          tr_monto,
tr_am_estado,       tr_sector,            tr_gar_admisible,
tr_calificacion,    tr_clase_cart,        tr_clase_cust,
tr_estado_car,      tr_categoria,         tr_ente,
tr_banco
from #transaccion_cab
order by 
tr_fecha_mov,       tr_tran,              tr_ofi_oper,          
tr_ofi_usu,         tr_fecha_ref,         tr_moneda,
tr_toperacion,      tr_estado,            tr_concepto,
tr_am_estado,       tr_sector,            tr_gar_admisible,
tr_calificacion,    tr_clase_cart,        tr_clase_cust,
tr_estado_car,      tr_categoria,         tr_ente,
tr_banco

open cursor_tran

fetch cursor_tran into
@w_tr_tran,         @w_tr_ofi_oper,       @w_tr_ofi_usu,   
@w_tr_fecha_mov,    @w_tr_fecha_ref,      @w_tr_moneda,
@w_toperacion,      @w_tr_estado,         @w_operacionca,
@w_secuencial,      @w_concepto,          @w_monto,
@w_am_estado,       @w_sector,            @w_gar_admisible,
@w_calificacion,    @w_clase_cart,        @w_clase_cust,
@w_estado,          @w_categoria,         @w_ente,
@w_tr_banco

while @@fetch_status = 0 begin
--   if @w_monto < 0
--      select @w_monto = @w_monto * -1

   if @@fetch_status = -1 begin
      select 
      @w_mensaje = 'ERR: SALIDA INCORRECTA DEL CURSOR',
      @w_error   = 710005
      close cursor_tran
      deallocate cursor_tran
      goto ERRORFIN
   end


   --DETERMINAR TRANSACCION ORIGINAL PARA LA REVERSA
   if @w_tr_tran = 'REV'
   begin
      select @w_tr_tran = tr_tran
      from ca_transaccion
      where tr_operacion = @w_operacionca
      and   tr_secuencial = @w_secuencial * -1

      if @w_tr_tran = 'REV'
      begin
         --No existe transaccion-secuencial asociada a la reversa. Error en Cartera'
         insert into cob_ccontable..cco_error_conaut(
                             ec_empresa,    ec_producto,
            ec_fecha_conta,  ec_numerror,   ec_fecha,
            ec_tran_modulo,  ec_asiento,    ec_mensaje,
            ec_perfil,       ec_oficina,    ec_valor,
            ec_comprobante)
          values (
                             1,             7, 
            @i_fecha,        70001,         @i_fecha,
            @w_total,        0,             'No existe Secuencial en la Reversa',
            'REV',           1,             0,
            0)

         goto NEXT
      end

   end

   select @w_mensaje  = ''

   select @w_descripcion =
   ' Tr:' + ltrim(rtrim(convert(varchar,@w_tr_tran)))         +
   ' OD:' + ltrim(rtrim(convert(varchar,@w_tr_ofi_oper)))     +
   ' OO:' + ltrim(rtrim(convert(varchar,@w_tr_ofi_usu)))      +
   ' FP:' + ltrim(rtrim(convert(varchar,@w_tr_fecha_mov,103)))+
   ' FV:' + ltrim(rtrim(convert(varchar,@w_tr_fecha_ref,103)))+
   ' Mo:' + ltrim(rtrim(convert(varchar,@w_tr_moneda)))       +
   ' To:' + ltrim(rtrim(convert(varchar,@w_toperacion)))      + 
   ' Es:' + ltrim(rtrim(convert(varchar,@w_tr_estado)))       +
   ' Co:' + ltrim(rtrim(convert(varchar,@w_concepto)))        +
   ' ER:' + ltrim(rtrim(convert(varchar,@w_am_estado)))       +
   ' Se:' + ltrim(rtrim(convert(varchar,@w_sector)))

PRINT '@w_descripcion ' + @w_descripcion
PRINT '@w_descripcion_ant ' + @w_descripcion_ant

   /* SI QUIEBRA, GENERAR TOTAL */
   if @w_descripcion_ant <> '' and 
      @w_descripcion_ant <> @w_descripcion  begin

      if abs(@w_monto_prv) >= 0.01 or exists(select 1 from #det_trn) begin

         /* BUSCAR NUEVO SECUENCIAL PARA GRUPO */
         exec @w_total = sp_gen_sec
         @i_operacion = -3

         /* LOS DETALLES DE LA TRANSACCION SUMARIZADA DEPENDE DE LA TRN */
         if @w_concepto_ant <> '' begin

            select @w_cv_prv = null

            select @w_cv_prv = co_codigo * 1000 + @w_am_estado_ant * 10
            from ca_concepto
            where co_concepto = @w_concepto_ant
           
            if @w_cv_prv is null
            begin
               select @w_cv_prv = cp_codvalor * 1000 + @w_am_estado_ant * 10
               from ca_producto
               where cp_producto = @w_concepto_ant
            end

            if @w_cv_prv is null begin
               select 
               @w_mensaje = 'ERR: AL BUSCAR CODIGO VALOR DEL CONCEPTO ' + @w_concepto_ant ,
               @w_error   = 710001
               close cursor_tran
               deallocate cursor_tran
               goto ERRORFIN
            end

--            if @w_monto_prv < 0 
--                select @w_monto_prv = @w_monto_prv * -1

            insert into #totales_det values(
            @w_total,            @w_concepto_ant,      @w_cv_prv,  
            @w_tr_moneda_ant,    @w_sector_ant,        @w_monto_prv,        
            '',                  @w_gar_admisible_ant, @w_calificacion_ant, 
            @w_clase_cart_ant,   @w_clase_cust_ant,    @w_estado_ant,
            @w_categoria_ant,    @w_ente_ant,          @w_tr_banco_ant)

            if @@error <> 0 begin
               select 
               @w_mensaje = 'ERR: AL INSERTAR DETALLE DE TOTALES INT_PR',
               @w_error   = 710001
               close cursor_tran
               deallocate cursor_tran
               goto ERRORFIN
            end

         end else begin

            insert into #totales_det
            select 
            @w_total,          tod_concepto,      tod_codvalor,    
            tod_moneda,        tod_sector,        sum(tod_monto), --case when sum(tod_monto) < 0 then sum(tod_monto) * -1 else sum(tod_monto) end,   
            tod_cuenta,        tod_gar_admisible, tod_calificacion,  
            tod_clase_cart,    tod_clase_cust,    tod_estado,
            tod_categoria,     tod_ente,          tod_banco
            from #det_trn
            group by tod_concepto,tod_codvalor,tod_moneda,tod_sector, tod_cuenta, tod_gar_admisible,tod_calificacion, tod_clase_cart, tod_clase_cust, tod_estado, tod_categoria, tod_ente, tod_banco
            having abs(sum(tod_monto)) >= 0.01
 
            if @@error <> 0 begin
               select 
               @w_mensaje = 'ERR: AL INSERTAR DETALLE DE TOTALES',
               @w_error   = 710001
               close cursor_tran
               deallocate cursor_tran
               goto ERRORFIN
            end

         end

         insert into #totales_trn
         select 
         @w_total, operacion, secuencial
         from #transacciones

         if @@error <> 0 begin
            select 
            @w_mensaje = 'ERR: AL INSERTAR DETALLE DE TOTALES',
            @w_error   = 710001
            close cursor_tran
            deallocate cursor_tran
            goto ERRORFIN
         end

         insert into #totales values(
         @w_total,          @w_tr_fecha_mov_ant, @w_tr_fecha_ref_ant,
         @w_tr_ofi_usu_ant, @w_tr_ofi_oper_ant,  @w_tr_tran_ant,
         @w_tr_moneda_ant,  @w_toperacion_ant,   @w_tr_estado_ant,
         0,                '01/01/1900')

         if @@error <> 0 begin
            select 
            @w_mensaje = 'ERR: AL INSERTAR DETALLE DE TOTALES', 
            @w_error   = 710001
            close cursor_tran
            deallocate cursor_tran
            goto ERRORFIN
         end

      end

      /* LIMPIAR TABLAS DE TRABAJO */
      truncate table #det_trn
      truncate table #transacciones
      select @w_monto_prv = 0.00

   end  -- FIN SI HAY QUIEBRE, GENERAR TOTAL


   /* EN CASO DEL ULTIMO REGISTRO SALIR */
   if @w_tr_tran = 'ZZZ' break


   /* INSERTAR TABLA DE TRANSACCIONES */
   insert into #transacciones values(@w_operacionca, @w_secuencial)

   if @@error <> 0 begin
      select 
      @w_mensaje = 'ERR: AL INSERTAR EN TABLA #transacciones',
      @w_error   = 710001
      close cursor_tran
      deallocate cursor_tran
      goto ERRORFIN
   end

   /* EN CASO DE REVERSA MULTIMPLICAR POR MENOS UNO LOS SALDOS */
   --if @w_tr_estado = 'RV' select @w_factor = -1
   --else select @w_factor = 1

   /* SUMAR DETALLES DE LA TRANSACCION ACTUAL */
   if @w_concepto = '' begin --Tiene detalles

      /* INSERTAR DETALLES DE LA TRANSACCION */
      insert into #det_trn(
      tod_total,        tod_concepto,              tod_codvalor,    
      tod_moneda,       tod_sector,                tod_monto,        
      tod_cuenta,       tod_gar_admisible,         tod_calificacion, 
      tod_clase_cart,   tod_clase_cust,            tod_estado,
      tod_categoria,    tod_ente,                  tod_banco)
      select 
      0,                dtr_concepto,               dtr_codvalor,    
      dtr_moneda,       case when dtr_codvalor < 999 then '' else op_sector end,  dtr_monto,        
      dtr_cuenta,       tr_gar_admisible,           isnull(op_calificacion,'A'), 
      op_clase,         case when tr_gar_admisible = 'S' then 'I' else 'O' end,
      op_estado,        (select dt_categoria from ca_default_toperacion where dt_toperacion = x.op_toperacion ),
      op_cliente,       tr_banco
      from ca_det_trn, ca_operacion x, ca_transaccion
      where dtr_operacion  = @w_operacionca
      and   dtr_secuencial = @w_secuencial
      and   dtr_operacion  = op_operacion
      and   tr_secuencial  = dtr_secuencial
      and   tr_operacion   = dtr_operacion

      if @@error <> 0 begin
         select 
         @w_mensaje = 'ERR: AL INSERTAR DETALLES 1 OP:'+convert(varchar,@w_operacionca)+' TRN:'+convert(varchar,@w_secuencial),
         @w_error   = 710001
         close cursor_tran
         deallocate cursor_tran
         goto ERRORFIN
      end

   end else begin

      select @w_monto_prv = @w_monto_prv + (@w_monto * @w_factor)

   end

   /* RESPALDAR DATOS DEL REGISTRO ANTERIOR */
   select 
   @w_descripcion_ant   = @w_descripcion,
   @w_tr_tran_ant       = @w_tr_tran,
   @w_tr_ofi_usu_ant    = @w_tr_ofi_usu,
   @w_tr_ofi_oper_ant   = @w_tr_ofi_oper,
   @w_tr_fecha_mov_ant  = @w_tr_fecha_mov,
   @w_tr_fecha_ref_ant  = @w_tr_fecha_ref,
   @w_tr_moneda_ant     = @w_tr_moneda,
   @w_toperacion_ant    = @w_toperacion,
   @w_tr_estado_ant     = @w_tr_estado,
   @w_concepto_ant      = @w_concepto,
   @w_monto_ant         = @w_monto,
   @w_am_estado_ant     = @w_am_estado,
   @w_sector_ant        = @w_sector,
   @w_gar_admisible_ant = @w_gar_admisible,
   @w_calificacion_ant  = @w_calificacion,
   @w_clase_cart_ant    = @w_clase_cart,
   @w_clase_cust_ant    = @w_clase_cust,
   @w_estado_ant        = @w_estado,
   @w_categoria_ant     = @w_categoria,
   @w_ente_ant          = @w_ente,
   @w_tr_banco_ant      = @w_tr_banco

   NEXT:

   fetch cursor_tran into
   @w_tr_tran,         @w_tr_ofi_usu,        @w_tr_ofi_oper,   
   @w_tr_fecha_mov,    @w_tr_fecha_ref,      @w_tr_moneda,
   @w_toperacion,      @w_tr_estado,         @w_operacionca,
   @w_secuencial,      @w_concepto,          @w_monto,
   @w_am_estado,       @w_sector,            @w_gar_admisible,
   @w_calificacion,    @w_clase_cart,        @w_clase_cust,
   @w_estado,          @w_categoria,         @w_ente,
   @w_tr_banco

end --end while cursor transacciones

close cursor_tran
deallocate cursor_tran

if @i_debug = 'S'
   print '---->sp_totales. totalizando...'


/* EN CASO QUE TODO SEA EXITOSO ACTUALIZAR TABLA DE TOTALES */
begin tran

insert into ca_totales
select * from #totales

if @@error <> 0 begin
   select 
   @w_mensaje = 'ERR: AL INSERTAR TOTALES DEFINITIVOS',
   @w_error   = 710001
   goto ERRORFIN
end   

insert into ca_totales_det
select * from #totales_det

if @@error <> 0 begin
   select 
   @w_mensaje = 'ERR: AL INSERTAR DETALLE DE TOTALES DEFINITIVOS',
   @w_error   = 710001
   goto ERRORFIN
end   

insert into ca_totales_trn
select * from #totales_trn

if @@error <> 0 begin
   select 
   @w_mensaje = 'ERR: AL INSERTAR RELACION DE TOTALES CON TRN EN DEFINITIVOS',
   @w_error   = 710001
   goto ERRORFIN
end   

commit tran



return 0

ERRORFIN:

if @i_debug = 'S'
   print '--> ERRORFIN:  ' + @w_mensaje

if @@trancount > 0 rollback tran

exec sp_errorlog
@i_fecha     = @w_fecha_proceso, 
@i_error     = @w_error, 
@i_usuario   = 'OPERADOR',
@i_tran      = 7000, 
@i_tran_name = @w_sp_name,
@i_rollback  = 'N',
@i_cuenta    = 'CONTABILIDAD', 
@i_descripcion = @w_mensaje

return @w_error

go

/*  PRUEBAS

truncate table ca_errorlog
truncate table ca_totales
truncate table ca_totales_det 
truncate table ca_totales_trn

exec sp_totales
@i_debug = 'S'

select * from ca_totales
select * from ca_totales_det order by tod_total compute sum(tod_monto) by tod_total
select * from ca_totales_trn
select * from ca_errorlog

select * from ca_concepto
insert into ca_concepto values ("CARTERA", "ALFREDO CARTERA", 99, "R")
insert into ca_concepto values ("CHEGER", "ALFREDO CARTERA", 99, "R")
insert into ca_concepto values ("CHLOCAL", "ALFREDO CARTERA", 99, "R")
insert into ca_concepto values ("EFEMN", "ALFREDO CARTERA", 99, "R")
insert into ca_concepto values ("FNG_CHLO", "ALFREDO CARTERA", 99, "R")
insert into ca_concepto values ("VAC0", "ALFREDO CARTERA", 99, "R")

insert into cob_conta..cb_relparam values (1, 'IN_OR', 0, '4', 7, 'ALFREDO', 'D')
insert into cob_conta..cb_relparam values (1, 'MOCA', 0, '3', 7, 'ALFREDO', 'D')
insert into cob_conta..cb_relparam values (1, 'RI_CL-IN', 0, '2', 7, 'ALFREDO', 'D')
insert into cob_conta..cb_relparam values (1, 'RI_GA_CL', 0, '1', 7, 'ALFREDO', 'D')
*/