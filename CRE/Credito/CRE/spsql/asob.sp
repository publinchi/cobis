/************************************************************************/
/*  Archivo:                asob.sp                                     */
/*  Stored procedure:       sp_asob                                     */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_asob' and type = 'P')
   drop proc sp_asob
go

---INC. 107362 feb.15.2013
create proc sp_asob( 
   @i_fecha    datetime    = '',
   @i_report   varchar(64) = null
)
as
declare  
   @w_sp_name            varchar(32),
   @w_error              int,
   @w_tipo_cus_fng       varchar(64),
   @w_path               varchar(250),
   @w_file               varchar(250),
   @w_s_app              varchar(250),
   @w_sqr                varchar(250),
   @w_cmd                varchar(250),
   @w_bd                 varchar(250),
   @w_tabla              varchar(250),
   @w_fecha_arch         varchar(10),
   @w_comando            varchar(500),
   @w_destino            varchar(250),
   @w_errores            varchar(250),
   @w_path_s_app         varchar(250),
   @w_est_vencido        tinyint,
   @w_ref_credito        varchar(24),
   @w_ref                varchar(24),
   @w_fecha_ini          varchar(10),
   @w_mes_ini            int, 
   @w_anio_ini           int

   
   
select 
   @w_sp_name       = 'sp_asob',
   @w_tipo_cus_fng  = '2200',      -- TIPO CUSTODIA FONDO NACIONAL DE GARANTIAS
   @w_est_vencido   = 2
 
declare @fng2 table (
   ref_archi            char(10),    
   nit_inter            varchar(20),
   num_garantia         varchar(20),
   en_ced_ruc           varchar(16),
   ref_credito          varchar(18),
   cod_moneda           varchar(3),
   clif_robli           char(2),
   cam_reser            char(1),
   sal_fec_corte_infor  numeric(12, 0), 
   sal_total_obli       numeric(12, 0),
   fecha_corte          char(8),
   num_cuotas_mora      int,
   fec_inicio_mora      char(8),
   fec_cancelacion      char(8),
   desmarcadas   char(1)
)
 
select @w_mes_ini = datepart(mm, @i_fecha)

select @w_anio_ini = datepart(yy, @i_fecha)

select @w_fecha_ini = convert(varchar,@w_mes_ini) +'/' + '01' + '/' + convert(varchar,@w_anio_ini)

delete cr_fng2_tmp
where fecha_corte >= '01/01/1900' --optimizado para mysql PNA

select 
do_fecha             = do_fecha,
op_operacion         = convert(int, 0),
op_tramite           = do_tramite,
op_banco             = do_banco,
op_cliente           = do_codigo_cliente,
op_moneda            = do_moneda,
op_estado            = do_estado_cartera,
op_fecha_ult_proceso = convert(datetime, '01/01/1900'),
do_calificacion      = do_calificacion,
do_saldo_cap         = do_saldo_cap,
do_saldo             = do_saldo,
do_num_cuotaven      = do_num_cuotaven,
do_fecha_ini_mora    = do_fecha_ini_mora,
do_fecha_concesion   = do_fecha_concesion
into #operaciones
from cob_conta_super..sb_dato_operacion with (index = idx3)
where do_fecha            = @i_fecha
and   do_aplicativo       = 7
and   do_naturaleza       = '1'
and  do_estado_cartera not in (4, 3)  -- SE EXCLUYEN LAS OPERACIONES CASTIGADAS

if @@error <> 0
begin
   print 'ERROR EN INSERCION DE TABLA DE OPERACIONES'
   return 1
end

--Insertar operaciones canceladas en el mes
insert into #operaciones
select 
do_fecha             = do_fecha,
op_operacion         = convert(int, 0),
op_tramite           = do_tramite,
op_banco             = do_banco,
op_cliente           = do_codigo_cliente,
op_moneda            = do_moneda,
op_estado            = do_estado_cartera,
op_fecha_ult_proceso = convert(datetime, '01/01/1900'),
do_calificacion      = do_calificacion,
do_saldo_cap         = do_saldo_cap,
do_saldo             = do_saldo,
do_num_cuotaven      = do_num_cuotaven,
do_fecha_ini_mora    = do_fecha_ini_mora,
do_fecha_concesion   = do_fecha_concesion
 from cob_conta_super..sb_dato_operacion with (index = idx3)
where do_fecha            = @i_fecha
and   do_aplicativo       = 7
and   do_naturaleza       = '1'
and (do_estado_cartera = 3 and do_fecha_ult_pago between @w_fecha_ini and @i_fecha)

if @@error <> 0
begin
   print 'ERROR EN INSERCION DE OP CANCELADAS EN TABLA DE OPERACIONES'
   return 1
end

---Eliminar de este grupo las que antes tenian estado 4 CASTIGADO

delete #operaciones
from #operaciones T
where op_estado = 3
and exists (select 1 from cob_conta_super..sb_dato_operacion with (index = idx3)
            where do_fecha            < @i_fecha
            and   do_aplicativo       = 7
            and   do_estado_cartera   = 4
            and   do_banco = T.op_banco
            )
            

create index idx1 on #operaciones(op_tramite)

if @@error <> 0
begin
   print 'ERROR EN CREACION DE INDICE EN TABLA DE OPERACIONES'
   return 1
end



-- NO REPORTAR LAS OPERACIONES CREADAS Y CANCELADAS EN EL MISMO MES
delete #operaciones
where op_estado                        = 3
and   datepart(mm, do_fecha_concesion) = datepart(mm, @i_fecha)
and   datepart(yy, do_fecha_concesion) = datepart(yy, @i_fecha)

if @@error <> 0
begin
   print 'ERROR EN ELIMINACION DE OPERACIONES CREADAS Y CANCELADAS EN EL MISMO MES'
   return 1
end


update #operaciones set 
op_operacion         = B.op_operacion,
op_fecha_ult_proceso = B.op_fecha_ult_proceso
from #operaciones A, cob_cartera..ca_operacion B
where A.op_banco = B.op_banco

if @@error <> 0
begin
   print 'ERROR EN ACTUALIZACION DE TABLA DE OPERACIONES'
   return 1
end


if @i_report is null
begin
   insert into @fng2
   select  ref_archi             = 'AS'+ replace(convert(varchar, do_fecha, 103),'/',''),
           nit_inter             = '9002150711',
           num_garantia          = cu_num_dcto,
           num_id_ente           = en_ced_ruc,
           ref_credito           = rtrim(ltrim(op_banco)),
           cod_moneda            = (select codigo_sib
                                    from cob_credito..cr_corresp_sib
                                    where tabla  = 'T87'
                                    and   codigo = O.op_moneda), 
           clif_robli            = do_calificacion,
           cam_reser             = ' ',
           sal_fec_corte_infor   = case when cu_estado = 'C' then 0 else do_saldo_cap end,
           sal_total_obli        = case when cu_estado = 'C' then 0 else do_saldo end,
           fecha_corte           = replace(convert(char(10), do_fecha, 103),'/',''),
           num_cuotas_mora       = do_num_cuotaven,
           fec_inicio_mora       = case do_num_cuotaven 
                                      when  0 then 
                                             ' '
                                      else
                                        isnull(replace(convert(char(10),do_fecha_ini_mora, 103),'/',''), ' ')
                                      end,                 
           fec_cancelacion       = case op_estado
                                      when 3 then
                                         replace(convert(char(10), op_fecha_ult_proceso, 103),'/','')
                                      else
                                         ' '
                                   end,
          desmarcadas     = case when cu_estado = 'X' then 'S' else 'N' end
   from cob_custodia..cu_tipo_custodia TC, 
        cob_custodia..cu_custodia, 
        cob_credito..cr_gar_propuesta, 
        #operaciones O,
        cobis..cl_ente e
   where tc_tipo_superior          = @w_tipo_cus_fng
   and   cu_tipo                   = tc_tipo
   and   cu_estado               not in ('P', 'A')
   and   gp_garantia               = cu_codigo_externo
   and   op_tramite                = gp_tramite
   and   en_ente                   = op_cliente

            
   if @@error <> 0
   begin
      print 'ERROR EN INSERCION DE VARIABLE TABLA DEL ANEXO 7 - 1'
      return 1
   end
end
else
begin
   insert into @fng2
   select  ref_archi             = 'AS'+ replace(convert(varchar, @i_fecha, 103),'/',''),
           nit_inter             = '9002150711',
           num_garantia          = cu_num_dcto,
           num_id_ente           = en_ced_ruc,
           ref_credito           = op_banco,
           cod_moneda            = (select codigo_sib
                                    from cob_credito..cr_corresp_sib
                                    where tabla  = 'T87'
                                    and   codigo = O.op_moneda), 
           clif_robli            = do_calificacion,
           cam_reser             = ' ',
           sal_fec_corte_infor   = case when cu_estado = 'C' then 0 else do_saldo_cap end,
           sal_total_obli        = case when cu_estado = 'C' then 0 else do_saldo end,
           fecha_corte           = replace(convert(char(10), do_fecha, 103),'/',''),
           num_cuotas_mora       = do_num_cuotaven,
           fec_inicio_mora       = case do_num_cuotaven 
                                      when  0 then 
                                             ' '
                                      else
                                        isnull(replace(convert(char(10),do_fecha_ini_mora, 103),'/',''), ' ')
                                      end,         
           fec_cancelacion       = case op_estado
                                      when 3 then
                                         replace(convert(char(10), op_fecha_ult_proceso, 103),'/','')
                                      else
                                         ' '
                                   end,
         desmarcadas     = case when cu_estado = 'X' then 'S' else 'N' end
   from cob_custodia..cu_custodia,
        cob_credito..cr_gar_propuesta,
        #operaciones O,
        cobis..cl_ente e
   where cu_tipo                   = @i_report
   and   cu_estado               not in ('P', 'A')
   and   gp_garantia               = cu_codigo_externo
   and   op_tramite                = gp_tramite
   and   en_ente                   = op_cliente

             
   if @@error <> 0
   begin
      print 'ERROR EN INSERCION DE VARIABLE TABLA DEL ANEXO 7 - 2'
      return 1
   end
end
 
---Borrar todas las de estado X menos las cargadas en el ultimo mes en la tabla 
select * into #desmarcadasMes
from cob_cartera..ca_desmarca_fng_his
where df_fecha  between @w_fecha_ini and @i_fecha
and   df_aplicativo = 7


delete @fng2
where desmarcadas = 'S'
and ref_credito not in (select df_banco from #desmarcadasMes)

--- INSERT EN LA TABLA DEL SQR 
 
insert into cr_fng2_tmp
select distinct  ref_archi,    
   nit_inter,
   num_garantia,
   en_ced_ruc,
   ref_credito,
   cod_moneda,
   clif_robli,
   cam_reser,
   sal_fec_corte_infor, 
   sal_total_obli,
   fecha_corte,
   num_cuotas_mora,
   fec_inicio_mora,
   fec_cancelacion
from @fng2
 
if @@error <> 0
begin
   print 'ERROR EN INSERCION DE TABLA TEMPORAL DEL ANEXO 7'
   return 1
end

---BORRAR LAS OPERACIONES QUE TIENE SALDO 0 Y NO TIENE FECHA DE CANCLEACION
---POR QUE TIENE LA GARANTIA CANCELADA
delete cr_fng2_tmp
where fec_cancelacion = ' '
and   sal_total_obli  = 0
 
select @w_path_s_app = pa_char
from cobis..cl_parametro
where pa_nemonico = 'S_APP'
 
select
   @w_sqr        = 'cob_custodia..sp_fng_7_ex',
   @w_file       = 'FNG7',
   @w_s_app      = @w_path_s_app + 's_app',
   @w_fecha_arch = convert(varchar, @i_fecha, 112)
 
select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente = @w_sqr
                                                                                                                                                                                                                             
select
   @w_cmd      = @w_s_app + ' bcp -auto -login ',
   @w_bd       = 'cob_credito',
   @w_tabla    = 'cr_fng2_tmp',
   @w_destino  = @w_path + @w_file + '_' + @w_fecha_arch + '.csv',
   @w_errores  = @w_path + @w_file + '_' + @w_fecha_arch + '.err'
 
select
   @w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destino + 
                ' -b5000 -c -e' + @w_errores + ' -t";" ' + '-config ' + @w_s_app + '.ini'
 
exec @w_error = xp_cmdshell @w_comando
 
if @w_error <> 0
begin
   print 'ERROR EN EJECUCION DEL BCP'
   return @w_error
end
 
return 0

GO
