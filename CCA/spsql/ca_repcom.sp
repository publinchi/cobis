/************************************************************************/
/*   Archivo:                   ca_repcom.sp                            */
/*   Stored procedure:          sp_report_com                           */
/*   Base de datos:             cob_cartera                             */
/*   Producto:                  Cartera                                 */
/*   Disenado por:              Ivonne Torres                           */
/*   Fecha de escritura:        Febrero-2010                            */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Reporte acumulado por oficina con periodicidad diaria y acumulada  */
/*   al corte de mes.                                                   */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_report_com')
    drop proc sp_report_com
go
create proc sp_report_com
@i_param1  varchar(10),
@i_param2  varchar(10)
as

set ansi_warnings off

declare
@w_error              int,           -- VALOR QUE RETORNA
@w_sp_name            varchar(32),   -- NOMBRE STORED PROC
@w_msg                varchar(255),  -- MENSAJE DE ERROR
@w_fecha_hora         datetime,      -- FECHA Y HORA DE CORRDIDA
@w_path_s_app         varchar(250),
@w_fecha              datetime,      -- FECHA EN QUE SE REPORTA EL VALOR DE COBERTURA
@w_path               varchar(250),
@w_s_app              varchar(250),
@w_cmd                varchar(250),
@w_bd                 varchar(250),
@w_tabla              varchar(250),
@w_fecha_arch         varchar(10),
@w_comando            varchar(500),
@w_destino            varchar(250),
@w_errores            varchar(250),
@w_erroresc           varchar(250),
@w_archivoc           varchar(64),
@w_archivod           varchar(64),
@w_destinoc           varchar(250),
@w_archivo            varchar(64),
@w_nombre             varchar(60),
@i_fecha_ini          datetime,
@i_fecha_fin          datetime,
@anio_listado         varchar(10),
@mes_listado          varchar(10),
@dia_listado          varchar(10)
   

select @w_fecha_hora = getdate()


select 
@i_fecha_ini = convert(datetime,@i_param1),
@i_fecha_fin = convert(datetime,@i_param2)


select @w_path_s_app = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'S_APP'

if @w_path_s_app is null begin
   select @w_msg = 'NO EXISTE PARAMETRO GENERAL S_APP'
   goto ERROR
end


if exists (select * from sysobjects where name = 'cabecera')
    drop table cabecera

create table cabecera
(oficina      varchar(30),
 of_nombre    varchar(30),
 pend_des     varchar(30),
 mont_pdes    varchar(30),
 num_desem    varchar(30),
 mon_desem    varchar(30),
 mora_30ma    varchar(30),
 mora_30me    varchar(30),
 mora_total   varchar(30),
 cart_actn    varchar(30),
 cart_actm    varchar(30),
 sol_pendn    varchar(30),
 sol_pendm    varchar(30),
 sol_pendren  varchar(30),
 sol_pendrem  varchar(30),
 sol_pentotn  varchar(30),
 sol_pentotm  varchar(30),
 clientes     varchar(30)
)

-- SE CARGAN TODAS LAS OFICINAS

if exists (select * from sysobjects where name = 'reporte0028')
    drop table reporte0028

create table reporte0028
(oficina      int,
 of_nombre    varchar(64),
 pend_des     int   null,
 mont_pdes    money null,
 num_desem    int   null,
 mon_desem    money null,
 mora_30ma    money null,
 mora_30me    money null,
 mora_total   money null,
 cart_actn    int   null,
 cart_actm    money null,
 sol_pendn    int   null,
 sol_pendm    money null,
 sol_pendren  int   null,
 sol_pendrem  money null,
 sol_pentotn  int   null,
 sol_pentotm  money null,
 clientes     int   null
)

insert into reporte0028
select distinct(op_oficina),
       (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
from cob_cartera..ca_operacion
where op_estado not in (0,6,99)
and   op_toperacion != 'ALT_FNG'
order by op_oficina

----------------------------------------
-- OPERACIONES PENDIENTES DE DESEMBOLSO
----------------------------------------

select cod_ofi = op_oficina, 
       campo   = count(op_operacion), 
       monto   = sum(op_monto)                 -- MONTO DE LAS OPERACIONES PENDIENTES DE DESEMBOLSO
into #temporal
from cob_cartera..ca_operacion 
where op_estado     = 0
and   op_fecha_ini  <= @i_fecha_fin
and   op_oficina    in (select oficina from reporte0028)
and   op_toperacion != 'ALT_FNG'
group by op_oficina

update reporte0028
   set pend_des    = campo,
       mont_pdes   = monto
  from #temporal, reporte0028
 where oficina  = cod_ofi


----------------------------------------
-- OPERACIONES DESEMBOLSADAS
----------------------------------------

select cod_ofi = op_oficina, 
       campo   = count(op_operacion), 
       monto   = sum(op_monto)                  -- MONTO DE OPERACIONES DESEMBOLSADAS
into #temporal1
from cob_cartera..ca_operacion 
where op_estado not in (0,6,99)
and   op_fecha_liq >= @i_fecha_ini
and   op_fecha_liq <= @i_fecha_fin
and   op_oficina in(select oficina from reporte0028)
and   op_toperacion != 'ALT_FNG'
group by op_oficina

update reporte0028
   set num_desem    = campo,
       mon_desem    = monto
  from #temporal1
 where oficina  = cod_ofi


----------------------------------------
-- MORA MAYOR 30 SIN CASTIGOS
----------------------------------------

select cod_ofi = do_oficina, 
       campo   = sum(do_saldo_cap) 
into #temporal2
from cob_conta_super..sb_dato_operacion
where do_fecha = @i_fecha_fin
and   do_tipo_reg = 'D'
and   do_aplicativo= 7
and   do_edad_mora > 30
and   do_estado_contable not in (3,4,0,99)
and   do_oficina in(select oficina from reporte0028)
group by do_oficina


update reporte0028
   set mora_30ma  = campo
  from #temporal2
 where oficina  = cod_ofi


----------------------------------------
-- MORA MENOR 30
----------------------------------------

select cod_ofi = do_oficina, 
       campo   = sum(do_saldo_cap) 
into #temporal3
from cob_conta_super..sb_dato_operacion
where do_fecha      = @i_fecha_fin
and   do_tipo_reg   = 'D'
and   do_aplicativo = 7
and   do_edad_mora  <= 30
and   do_edad_mora  > 0
and   do_oficina in(select oficina from reporte0028)
and   do_estado_contable not in(3,4,0,99)
group by do_oficina

update reporte0028
   set mora_30me    = campo
  from #temporal3
 where oficina  = cod_ofi


----------------------------------------
-- MORA TOTAL
----------------------------------------
update reporte0028
set mora_total = mora_30ma + mora_30me
WHERE oficina >= 0



----------------------------------------
-- CARTERA ACTIVA       
----------------------------------------
select cod_ofi = do_oficina, 
       campo   = count(do_banco), 
       monto   = sum(do_saldo_cap) 
into #temporal5
from cob_conta_super..sb_dato_operacion
where do_fecha          = @i_fecha_fin
and   do_tipo_reg       = 'D'
and   do_aplicativo     = 7
and   do_tipo_operacion != 'ALT_FNG'
and   do_estado_contable not in(3,4,0,99)
and   do_oficina in(select oficina from reporte0028)
group by do_oficina

update reporte0028
   set cart_actn  = campo,
       cart_actm  = monto
  from #temporal5
 where oficina  = cod_ofi



----------------------------------------
-- SOLICITUDES PENDIENTES - NUEVAS
----------------------------------------

select cod_ofi = op_oficina, 
       campo   = count(op_operacion),
       monto   = sum(op_monto_aprobado)
       into #temporal6
from ca_operacion, cob_credito..cr_tramite
where op_estado        = 99
and   op_tramite       = tr_tramite
and   op_fecha_ini    <= @i_fecha_fin
and   tr_tipo_credito  = 'N'
and   tr_estado        in('N', 'D')
group by op_oficina


update reporte0028
   set sol_pendn  = campo,
       sol_pendm  = monto
  from #temporal6
 where oficina  = cod_ofi


----------------------------------------
-- PENDIENTES - RENOVACIONES
----------------------------------------

select cod_ofi = op_oficina, 
       campo   = count(op_operacion),
       monto   = sum(op_monto_aprobado)
       into #temporal7
from ca_operacion, cob_credito..cr_tramite
where op_estado        = 99
and   op_tramite       = tr_tramite
and   op_fecha_ini    <= @i_fecha_fin
and   tr_tipo_credito  = 'R'
and   tr_estado        in('N', 'D')
group by op_oficina


update reporte0028
   set sol_pendren  = campo,
       sol_pendrem = monto
  from #temporal7
 where oficina  = cod_ofi


----------------------------------------
-- PENDIENTES - TOTAL
----------------------------------------
update reporte0028
   set sol_pentotn = sol_pendn + sol_pendren,
       sol_pentotm = sol_pendm + sol_pendrem
WHERE oficina > = 0
       
       

-----------------------------------------
-- POTENCIAL DE CLIENTES PARA RENOVACION
-----------------------------------------
create table #calif4
(banco         varchar(30),
 cod_ofi       int,
 op_operacion  int,
 cliente       int,
 tramite       int null,
 todoses       int null,
 est3          int null,
 vencido       int null,
 porcentaje    float null
)

/*CLIENTES QUE NO VAN*/
select distinct(ci_cliente) as cliente into #cliente_nota
 from cob_credito..cr_califica_int_mod 
where ci_nota < 4

insert into #calif4
select op_banco,op_oficina, op_operacion, op_cliente, op_tramite,0,0,0,0
from cob_cartera..ca_operacion
where op_cliente not in (select cliente from #cliente_nota)
and  op_estado in (1,2,9,4)


/*OPERACIONES QUE CUMPLEN EL 70% DE SUS CUOTAS PAGADAS*/
select di_operacion, numop = count(di_dividendo)
into #todos
from cob_cartera..ca_dividendo, #calif4
where di_operacion = op_operacion 
group by di_operacion

select di_operacion, numop = count(di_dividendo)
into #est3
from cob_cartera..ca_dividendo, #calif4
where di_operacion = op_operacion 
and   di_estado = 3
group by di_operacion

select di_operacion, numop = count(di_dividendo)
into #vencidos
from cob_cartera..ca_dividendo, #calif4
where di_operacion = op_operacion 
and   di_estado = 2
group by di_operacion


update #calif4
set todoses = numop
from #todos
where di_operacion = op_operacion

update #calif4
set est3 = numop
from #est3
where di_operacion = op_operacion

update #calif4
set vencido = numop
from #vencidos
where di_operacion = op_operacion


update #calif4
set porcentaje = (est3 * 100)/todoses
from #calif4
where todoses > 0

select cod_ofi = cod_ofi, numcliente = count(cliente)
into #clientes
from #calif4
where porcentaje >= 70
and   vencido     = 0
group by cod_ofi

update reporte0028
 set clientes    = numcliente
  from #clientes
 where oficina  = cod_ofi


-----------------
/* HAGO EL BCP */
-----------------
select
@w_s_app      = @w_path_s_app+'s_app'

select
@w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = 7086

-- CABECERA

insert into cabecera values('Oficina',                   'Nombre_Oficina',       'Pend_des_#',        
                            'Pend_des_Valor',            'Desembolsos_#',        'Desembolsos_Valor',         
                            'Mora_Mayor_30',             'Mora_Menor_30',        'Mora_Total',           
                            'Cartera_Activa_#',          'Cartera_Activa_Valor', 'Sol_nuevas_#',         
                            'Sol_nuevas_Valor',          'Sol_renovaciones_#',   'Sol_renovaciones_Valor',
                            'Total_sol_pend_#',          'Total_sol_pend_Valor', 'Potencial_clientes_renov_#')
                         
                          
/* TABLA DEL REPORTE */

select
@w_cmd      = @w_s_app+' bcp -auto -login ',
@w_bd       = 'cob_cartera',
@w_tabla    = 'cabecera',
@w_archivoc  = 'cabecera'

select 
@w_destinoc  = @w_path + @w_archivoc +'.txt',
@w_erroresc  = @w_path + @w_archivoc +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destinoc + ' -b5000 -c -e'+@w_erroresc + ' -t"~" ' + '-config '+@w_s_app+'.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO CABECERA '+@w_destinoc+ ' '+ convert(varchar, @w_error)
   goto ERROR
end


/* -- DATOS  */

/* TABLA DEL REPORTE */

select
@w_cmd      = @w_s_app+' bcp -auto -login ',
@w_bd       = 'cob_cartera',
@w_tabla    = 'reporte0028',
@w_archivod = 'datos'

select 
@w_destino  = @w_path + @w_archivod +'.txt',
@w_errores  = @w_path + @w_archivod +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destino + ' -b5000 -c -e'+@w_errores + ' -t"~" ' + '-config '+@w_s_app+'.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO '+@w_destino+ ' '+ convert(varchar, @w_error)
   goto ERROR
end



select @w_fecha_arch = convert(varchar, @w_fecha_hora, 112),
       @anio_listado = substring(@w_fecha_arch,1,4),
       @mes_listado  = substring(@w_fecha_arch,5,2), 
       @dia_listado  = substring(@w_fecha_arch,7,2)

select @w_fecha_arch = @mes_listado + @dia_listado + @anio_listado 


/*** CONCATENACION DE ARCHIVO CABECERA CON ARCHIVO DE DATOS  ***/
if @i_fecha_ini = @i_fecha_fin
   select @w_nombre = 'ca_repcom' + @w_fecha_arch
else
   select @w_nombre = 'ca_repcom' + @w_fecha_arch


select
@w_archivo  = @w_path + @w_nombre +'.txt',
@w_comando = 'type ' + @w_destinoc + ' ' + @w_destino + ' > ' + @w_archivo

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end


/*** ELIMINACION DE ARCHIVO DE CABECERA Y DATOS  ***/

select
@w_comando = 'rm ' + @w_destinoc 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end

select
@w_comando = 'rm ' + @w_erroresc 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end


select
@w_comando = 'rm ' + @w_destino 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end

select
@w_comando = 'rm ' + @w_errores 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end


return 0
ERROR:
   print @w_msg 
   exec @w_error = sp_errorlog
        @i_fecha      = @w_fecha_hora,
        @i_error      = 1900000,
        @i_usuario    = 'sa',
        @i_tran       = 7086,
        @i_tran_name  = @w_msg,
        @i_rollback   = 'N'

return 1900000

go



