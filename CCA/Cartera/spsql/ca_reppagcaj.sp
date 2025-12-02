/************************************************************************/
/*   Archivo:                   ca_reppagcaj.sp                         */
/*   Stored procedure:          sp_report_com                           */
/*   Base de datos:             cob_cartera                             */
/*   Producto:                  Cartera                                 */
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

if exists (select 1 from sysobjects where name = 'sp_reppagcaj')
    drop proc sp_reppagcaj
go
create proc sp_reppagcaj
   @i_param1  varchar(10)

as declare
   @i_fecha_ini      datetime,
   @w_error          int,
   @w_path           varchar(250),
   @w_s_app          varchar(250),
   @w_cmd            varchar(250),
   @w_bd             varchar(250),
   @w_tabla          varchar(250),
   @w_fecha_arch     varchar(40),
   @w_comando        varchar(500),
   @w_destino        varchar(250),
   @w_errores        varchar(250),
   @w_erroresc       varchar(250),
   @w_archivoc       varchar(64),
   @w_archivod       varchar(64),
   @w_destinoc       varchar(250),
   @w_archivo        varchar(64),
   @w_nombre         varchar(40),
   @w_msg            varchar(255),
   @w_path_s_app     varchar(250),
   @anio_listado     varchar(10),
   @mes_listado      varchar(10),
   @dia_listado      varchar(10),
   @hora_listado     varchar(10),
   @min_listado      varchar(10),
   @seg_listado      varchar(10),
   @w_fecha_hora     varchar(10)
   

select 
@i_fecha_ini = convert(datetime,@i_param1)


/*PARAMTEROS*/
select @w_path_s_app = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'S_APP'

if @w_path_s_app is null begin
   select @w_msg = 'NO EXISTE PARAMETRO GENERAL S_APP'
   goto ERROR
end


/*FORMAS DE PAGO*/
select cp_producto into #fpagos
from ca_producto
where cp_atx  = 'S'

insert into #fpagos values ('SOBRANTE')

insert into #fpagos 
select pa_char from cobis..cl_parametro
where pa_producto  = 'CCA'
and   pa_nemonico  in ('NDAHO','NDCC')


/*BORRADO DE DATOS*/
truncate table ca_cabecera_pag
truncate table ca_pagos_caja


/* INFORMACION DE PAGOS EN OFICINA */
select
'OFICINA'       = ab_oficina,
'OBLIGACION'    = op_banco,
'NOMBRE'        = op_nombre,
'CEDULA'        = (select en_ced_ruc from cobis..cl_ente where en_ente =  op_cliente),
'EFECTIVO'      = sum(case abd_concepto when 'EFMN' then abd_monto_mn else 0 end),
'CHEQUE'        = sum(case when abd_concepto in ('CHEPRO','CHLOCAL','CHOTPLAZA') then abd_monto_mn else 0 end),
'NOTA DEBITO'   = sum(case when abd_concepto in ('NDAHO','NDCC') then abd_monto_mn else 0 end),
'SOBRANTE'      = sum(case abd_concepto when 'SOBRANTE' then abd_monto_mn else 0 end),
'EST. PAGO'     = ab_estado,
'FECHA DE PAGO' = convert(varchar(10),ab_fecha_pag,103)  into #pagos
from  cob_cartera..ca_operacion,
      cob_cartera..ca_abono,
      cob_cartera..ca_abono_det
where ab_operacion = op_operacion
  and ab_fecha_pag = @i_fecha_ini
  and ab_operacion = abd_operacion
  and ab_secuencial_ing  =  abd_secuencial_ing
  and abd_concepto     in (select cp_producto from #fpagos)
group by ab_oficina,op_cliente,op_banco,op_nombre,ab_estado,ab_fecha_pag
order by ab_oficina


/*REGISTRO DE INFORMACION*/
insert into ca_cabecera_pag
values('OFICINA','OBLIGACION','NOMBRE','CEDULA','EFECTIVO','CHEQUE','NOTA DEBITO','SOBRANTE','EST. PAGO','FECHA DE PAGO')

insert into ca_pagos_caja
select * from #pagos


-----------------
/* HAGO EL BCP */
-----------------
select
@w_s_app      = @w_path_s_app + 's_app',
@w_fecha_arch = convert(varchar, @i_fecha_ini, 112)

select @anio_listado = substring(@w_fecha_arch,1,4),
       @mes_listado  = substring(@w_fecha_arch,5,2), 
       @dia_listado  = substring(@w_fecha_arch,7,2)

select @w_fecha_hora = convert(varchar, getdate(), 108)

select @hora_listado = substring(@w_fecha_hora,1,2)
select @min_listado  = substring(@w_fecha_hora,4,2)
select @seg_listado  = substring(@w_fecha_hora,7,2)
       
       
select @w_fecha_arch = @mes_listado + @dia_listado + @anio_listado + '_' + @hora_listado + @min_listado + @seg_listado
       

select
@w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = 7086

                          
/* TABLA DEL REPORTE */
select
@w_cmd      = @w_s_app + ' bcp -auto -login ',
@w_bd       = 'cob_cartera',
@w_tabla    = 'ca_cabecera_pag',
@w_archivoc = 'cabecera'


select 
@w_destinoc  = @w_path + @w_archivoc +'.txt',
@w_erroresc  = @w_path + @w_archivoc +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destinoc + ' -b5000 -c -e'+@w_erroresc + ' -t"|" ' + '-config '+ @w_s_app+'.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO CABECERA '+@w_destinoc+ ' '+ convert(varchar, @w_error)
   goto ERROR
end



/* TABLA DEL REPORTE */

select
@w_cmd      = @w_s_app+' bcp -auto -login ',
@w_bd       = 'cob_cartera',
@w_tabla    = 'ca_pagos_caja',
@w_archivod = 'reporte_caja'

select 
@w_destino  = @w_path + @w_archivod +'.txt',
@w_errores  = @w_path + @w_archivod +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destino + ' -b5000 -c -e'+@w_errores + ' -t"|" ' + '-config '+@w_s_app+'.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO DATOS '+@w_destino+ ' '+ convert(varchar, @w_error)
   goto ERROR
end



/*** CONCATENACION DE ARCHIVO CABECERA CON ARCHIVO DE DATOS  ***/
select @w_nombre = 'ca_reppagcaj_'+ @w_fecha_arch


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



