/************************************************************************/
/*   Archivo:             rep_tipogar.sp                                */
/*   Stored procedure:    sp_rep_tipo_gar                               */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            cartera						               	*/
/*   Disenado por:        Luis Carlos Moreno C.			                */
/*   Fecha de escritura:  Diciembre/2011                                */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios	                */
/*	propiedad de "MACOSA", representantes exclusivos para	            */
/*  el Ecuador de "NCR".                      			                */
/*  Su uso no autorizado queda expresamente prohibido asi como  		*/
/*  cualquier alteracion o agregado hecho por alguno de sus    			*/
/*  usuarios sin el debido consentimiento por escrito de la    			*/
/*  Presidencia Ejecutiva de MACOSA o su representante.    			    */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Generar un reporte mensual por tipo de garantia colateral           */
/*  con la siguiente estructura:                                        */
/*  - Oficina                                                           */
/*  - Credito                                                           */
/*  - Tipo Garantia                                                     */
/*  - Subtipo Garantia                                                  */
/*  - Fecha Desembolso                                                  */
/*  - Fecha Siniestro                                                   */
/*  - Valor Cobrado Siniestro                                           */
/*  - Fecha Aplicacion                                                  */
/*  - Valor Aplicado                                                    */
/*  - Pagos Recibidos Despues de Aplicado                               */
/*  - Valor Pendiente Pago Siniestro                                    */
/*  - Estado Obligacion                                                 */
/*  - Dias Mora                                                         */
/*  - Total Oficina                                                     */
/*  - Total Banco                                                       */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA     AUTOR             RAZON                                   */
/*  15-11-11  L.Moreno          Emisión Inicial - Req: 254              */
/*  25-02-14  I.Berganza        Req: 397 - Reportes FGA                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_tipo_gar')
   drop proc sp_rep_tipo_gar
go

create procedure sp_rep_tipo_gar
@i_param1       datetime = null

as

declare @w_sp_name              varchar(32),
        @w_sp_name_batch        varchar(30),
        @w_fecha_proceso	    datetime,
        @w_s_app                varchar(30),
        @w_path                 varchar(255),
		@w_error                int,
		@w_cabecera             varchar(1000),
		@w_comando              varchar(1000),
        @w_cabecera_tot         varchar(200),
        @w_cabecera_tot_arch    varchar(200),
		@w_cmd                  varchar(300),
		@w_msg				    varchar(100),
        @w_oficina              int,
		@w_nombre_plano         varchar(200),
		@w_plano_errores        varchar(200),
		@w_fecha_arch           varchar(8),
		@w_hora_arch            varchar(4)
set nocount on

select @w_sp_name   = 'sp_rep_tipo_gar'

/* Crea tabla temporal para la generacion del reporte */
if not object_id('registro_rec') is null
   drop table registro_rec

create table registro_rec
(
registro varchar(500)
)

/* Crea tablas temporales del proceso */
create table #reporte_garantias_tmp
(
   rg_oficina        int          null,
   rg_credito        cuenta       null,
   rg_tipo_gar       varchar(10)  null,
   rg_subtipo_gar    varchar(255) null,
   rg_fec_desem      varchar(10)  null,
   rg_vlr_desem      money        null,
   rg_fec_siniestro  varchar(10)  null, 
   rg_vlr_siniestro  money        null,
   rg_fec_apli       varchar(10)  null,
   rg_vlr_apli       money        null,
   rg_pagos_rec_mes  money        null,
   rg_vlr_pend_sin   money        null,
   rg_estado         int          null,
   rg_dias_mora      int          null
)

create table #reporte_garantias_tmp_ofi
(
   rg_oficina        int          null,
   rg_credito        cuenta       null,
   rg_tipo_gar       varchar(10)  null,
   rg_subtipo_gar    varchar(255) null,
   rg_fec_desem      varchar(10)  null,
   rg_vlr_desem      money        null,
   rg_fec_siniestro  varchar(10)  null, 
   rg_vlr_siniestro  money        null,
   rg_fec_apli       varchar(10)  null,
   rg_vlr_apli       money        null,
   rg_pagos_rec_mes  money        null,
   rg_vlr_pend_sin   money        null,
   rg_estado         int          null,
   rg_dias_mora      int          null
)

create table #total_garantias_tmp
(
   cantidad             numeric  null,
   valor                money null
)

/* OBTIENE FECHA DE PROCESO */
select @w_fecha_proceso = @i_param1

if @w_fecha_proceso is null
begin
   select @w_fecha_proceso = max(do_fecha)
   from cob_conta_super..sb_dato_operacion with (nolock)
   where do_aplicativo = 7
end

-- OBTIENE DATOS PARA EL INFORME
insert into #reporte_garantias_tmp(
rg_oficina                          ,rg_credito                    ,rg_tipo_gar         ,
rg_subtipo_gar                      ,rg_fec_desem                  ,rg_vlr_desem        ,
rg_fec_siniestro                    ,rg_vlr_siniestro              ,rg_pagos_rec_mes    ,
rg_vlr_pend_sin                     ,rg_estado                     ,rg_dias_mora)
select
do_oficina                          ,do_banco                      ,do_tipo_garantias   ,
pr_3nivel_gar        ,convert(varchar(10),do_fecha_concesion,120)  ,do_monto            ,
convert(varchar(10),pr_fecha,120)   ,pr_vlr                        ,pr_vlr_amort        ,
pr_vlr-pr_vlr_amort  ,do_estado_cartera                            ,do_edad_mora
from cob_conta_super..sb_pago_recono with (nolock),
     cob_conta_super..sb_dato_operacion with (nolock)
where do_fecha    = pr_fecha_rep
and   do_banco    = pr_banco
and   pr_estado   <> 'R'
and   do_fecha    = @w_fecha_proceso

/* Actualiza los campos de fecha de aplicacion y valor de aplicacion a partir de la tabla de abonos */
update #reporte_garantias_tmp
set rg_fec_apli = ab_fecha_pag,
rg_vlr_apli = abd_monto_mn
from
cob_cartera..ca_operacion,
cob_cartera..ca_abono a,
cob_cartera..ca_abono_det d
where op_banco = rg_credito
and   ab_operacion = op_operacion
and   abd_operacion = ab_operacion
and   abd_secuencial_ing = ab_secuencial_ing
and   abd_concepto in (select c.codigo
                       from cobis..cl_tabla t, cobis..cl_catalogo c
                       where t.tabla = 'ca_fpago_reconocimiento'
                       and   t.codigo = c.tabla) -- Req. 397 Formas de pago por reconocimiento
and   ab_estado = 'A'

if @@error <> 0
begin
  select @w_error = 721329, @w_msg = 'ERROR AL ACTUALIZAR LA FECHA Y EL VALOR DE APLICACION'
  goto ERROR_INF
end

/* Asigna variables para el nombre del archivo */
select @w_fecha_arch    = substring(convert(varchar(10),@w_fecha_proceso,103),1,2)+ substring(convert(varchar(10),@w_fecha_proceso,103),4,2)+substring(convert(varchar(10),@w_fecha_proceso,103),7,4),
       @w_hora_arch     = substring(convert(varchar,GetDate(),108),1,2) + substring(convert(varchar,GetDate(),108),4,2),
       @w_sp_name_batch = 'cob_cartera..sp_rep_tipo_gar'

/* Obtiene el path donde se va a generar el informe : VBatch\Clientes\Listados */
select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente = @w_sp_name_batch

if @@rowcount = 0 begin
  select @w_error = 721329, @w_msg = 'ERROR EN LA BUSQUEDA DEL PATH EN LA TABLA ba_batch'
  goto ERROR_INF
end

/* Obtiene el parametro de la ubicacion del kernel\bin en el servidor */
select @w_s_app   = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM' and
      pa_nemonico = 'S_APP'
                                                                                                                                                                                                                                                       
if @@rowcount = 0 begin
  select @w_error = 721329, @w_msg = 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
  goto ERROR_INF
end

/* Obtiene las oficinas que tienen pagos por reconocimiento */
select distinct oficina=rg_oficina, estado='I'
into #oficinas
from #reporte_garantias_tmp
order by rg_oficina

/* Configura encabezado de las columnas */
select @w_cabecera = 'Oficina|Credito|Tipo Garantia|Subtipo Garantia|Fecha Desembolso|Vlr Desembolso|Fec Siniestro|Vlr Siniestro|Fecha Aplic|Vlr Aplic|Pagos Recibidos|Vlr Pend|Estado|Dias Mora'
select @w_cabecera_tot = 'Cantidad|Valor'
select @w_cabecera_tot_arch = 'Cantidad Total|Valor Total'

/* Obtiene los nombres de los informes */
   select @w_nombre_plano     = @w_path + 'REPO_TIP_GAR_' + @w_fecha_arch + '_' + @w_hora_arch + '.txt',
          @w_plano_errores    = @w_path + 'REPO_TIP_GAR_' + @w_fecha_arch + '_' + @w_hora_arch + '.err'

select @w_comando = 'echo >' + @w_nombre_plano
exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0
begin
   select @w_error = 808022, @w_msg = 'ERROR AL ESCRIBIR ENCABEZADO DEL INFORME.'
   goto ERROR_INF
end

while 1=1
begin
   set rowcount 1
   select @w_oficina = oficina
   from   #oficinas
   where estado = 'I'

   if @@rowcount = 0
   begin
      set rowcount 0
      break
   end

   set rowcount 0

   /* Limpia la tabla de reporte por oficina */
   truncate table #reporte_garantias_tmp_ofi

   /* Inserta los registros de reconocimiento asociados a la oficina */
   insert into #reporte_garantias_tmp_ofi
   select * from #reporte_garantias_tmp
   where rg_oficina = @w_oficina

   if @@error <> 0
   begin
      select @w_error = 721329, @w_msg = 'ERROR AL INSERTAR LOS RECONOCIMIENTOS PARA LA OFICINA ' + cast(@w_oficina as varchar)
      goto ERROR_INF
   end

   /* Limpia tabla de totales */
   truncate table #total_garantias_tmp

   /* Inserta registro de total para la oficina */
   insert into #total_garantias_tmp
   select count(1), sum(isnull(rg_vlr_apli,0))
   from #reporte_garantias_tmp
   where rg_oficina = @w_oficina

   if @@error <> 0
   begin
      select @w_error = 721329, @w_msg = 'ERROR AL GENERAR TOTALES PARA LA OFICINA ' + cast(@w_oficina as varchar)
      goto ERROR_INF
   end

   /* Inserta Cabecera Reporte */
   insert into registro_rec
   values (@w_cabecera)

   if @@error <> 0
   begin
      select @w_error = 721329, @w_msg = 'ERROR AL INSERTAR CABECERA PARA LA OFICINA ' + cast(@w_oficina as varchar)
      goto ERROR_INF
   end

   /* Inserta Detalle Reporte */
   insert into registro_rec
   select cast(rg_oficina as varchar)+ '|' + rg_credito + '|' + rg_tipo_gar + '|' + rg_subtipo_gar + '|' + 
          cast(rg_fec_desem as varchar) + '|' + cast(rg_vlr_desem as varchar) + '|' + cast(rg_fec_siniestro as varchar) + '|' + 
          cast(rg_vlr_siniestro as varchar) + '|' + cast(rg_fec_apli as varchar) + '|' + cast(rg_vlr_apli as varchar) + '|' + 
          cast(rg_pagos_rec_mes as varchar) + '|' + cast(rg_vlr_pend_sin as varchar) + '|' + cast(rg_estado as varchar) + '|' + 
          cast(rg_dias_mora as varchar)
   from #reporte_garantias_tmp_ofi

   if @@error <> 0
   begin
      select @w_error = 721329, @w_msg = 'ERROR AL INSERTAR DETALLE PARA LA OFICINA ' + cast(@w_oficina as varchar)
      goto ERROR_INF
   end

   /* Inserta Cabecera Totales Reporte */
   insert into registro_rec
   values (@w_cabecera_tot)

   if @@error <> 0
   begin
      select @w_error = 721329, @w_msg = 'ERROR AL INSERTAR CABECERA TOTAL PARA LA OFICINA ' + cast(@w_oficina as varchar)
      goto ERROR_INF
   end

   /* Inserta Detalle Totales Reporte */
   insert into registro_rec
   select cast(cantidad as varchar) + '|' + cast(valor as varchar)
   from #total_garantias_tmp

   if @@error <> 0
   begin
      select @w_error = 721329, @w_msg = 'ERROR AL INSERTAR DETALLE TOTAL PARA LA OFICINA ' + cast(@w_oficina as varchar)
      goto ERROR_INF
   end

   /* Actualiza a estado Procesado la oficina */
   update #oficinas
   set estado = 'P'
   where oficina = @w_oficina
   and   estado  = 'I'

   if @@error <> 0
   begin
      select @w_error = 721329, @w_msg = 'ERROR AL AL ACTUALIZAR ESTADO OFICINA ' + cast(@w_oficina as varchar)
      goto ERROR_INF
   end

end

/* Limpia tabla de totales */
truncate table #total_garantias_tmp

/* Inserta registro de total del proceso */
insert into #total_garantias_tmp
select count(1), sum(isnull(rg_vlr_apli,0))
from #reporte_garantias_tmp

/* Inserta Cabecera Reporte */
insert into registro_rec
values (@w_cabecera_tot_arch)

/* Inserta Detalle Totales Reporte */
insert into registro_rec
select cast(cantidad as varchar) + '|' + cast(valor as varchar)
from #total_garantias_tmp

/*-------------------------------------------------------------------------------------*/
/*                 GENERA REPORTE - ARCHIVO: REPO_TIP_GAR_YYYYMMDDHHMM.txt             */
/*-------------------------------------------------------------------------------------*/
select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..registro_rec  out '
select @w_comando = @w_cmd + @w_nombre_plano + ' -c -e' + @w_plano_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'
exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select @w_error = 721329, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
   print @w_comando
   goto ERROR_INF
end
else begin
   select @w_comando = 'del ' + @w_plano_errores
   exec @w_error = xp_cmdshell @w_comando
   if @w_error <> 0 begin
      select @w_error = 721329, @w_msg = 'ERROR AL BORRAR EL ARCHIVO DE ERRORES BCP.'
      print @w_comando
      goto ERROR_INF
   end
end

return 0

ERROR_INF:
                                                                                                                                                                                                                                                 
exec sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = @w_error, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return 1
go