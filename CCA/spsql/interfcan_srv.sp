/******************************************************************/
/*  Archivo:            interfcan_srv.sp                          */
/*  Stored procedure:   sp_oper_canceladas_srv                    */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 04-Sep-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Interface de Cancelacion de Operaciones                    */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  04/Sep/19        Lorena Regalado    Interface de Operaciones  */
/*                                      Canceladas                */
/*  07/Oct/2019      Luis Ponce         Excluir Operaciones Hijas */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_oper_canceladas_srv')
   drop proc sp_oper_canceladas_srv
go

create proc sp_oper_canceladas_srv
@t_trn   int          = 77535


as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_mensaje              varchar(500),
   @w_operacion            int,
   @w_moneda               int,
   @w_oficina              int,
   @w_return               int,
   @w_cta_grupal           cuenta,
   @w_fecha_proceso        datetime,
   @w_grupo                int,
   @w_tramite              int,
   @w_banco                cuenta,
   @w_est_cancelado        tinyint,
   @w_contador             int,
   @w_fecha_hace_un_mes    datetime,
   @w_sesn                 int,
   @w_usuario              varchar(20)

select @w_contador = 0,
       @w_usuario  = 'USER_REPCAN'

--Obtengo nemonico del estado Cancelado

select @w_est_cancelado = es_codigo
from cob_cartera..ca_estado
where es_descripcion = 'LIQUIDADO'


--Obtengo la fecha de proceso
select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso


select @w_fecha_hace_un_mes = dateadd(dd,-30, @w_fecha_proceso)

--Obtengo secuencial del bloque
exec @w_sesn = ADMIN...rp_ssn 


--print 'Fecha hace un mes: ' + cast(@w_fecha_hace_un_mes as varchar) + 'Fecha proceso ' + cast(@w_fecha_proceso as varchar)



--Obtengo los datos de las Operaciones Canceladas
select op_banco as banco 
into #operaciones_canceladas
from cob_cartera..ca_operacion OP
where op_estado = @w_est_cancelado
and   op_fecha_ult_proceso between  @w_fecha_hace_un_mes and @w_fecha_proceso 
and   op_operacion not in (select ocs_operacion from cob_cartera..ca_operaciones_canceladas_srv where ocs_estado = 'R') --Reportado
and   op_operacion not in (select op_operacion from cob_cartera..ca_operacion where op_operacion = OP.op_operacion and op_grupal = 'S' and op_ref_grupal is not null) --LPO TEC Se exluyen las hijas

select @w_contador = count(*) 
from #operaciones_canceladas

select @w_contador = isnull(@w_contador,0)

if @w_contador > 0
begin
   select banco
   from #operaciones_canceladas

   if @@error = 0
   begin

          insert cob_cartera..ca_operaciones_canceladas_srv 
          select @w_sesn,
                 @w_usuario, 
                 @w_fecha_proceso,
                 op_operacion,
                 op_banco,
                 op_toperacion,
                 (select case when x.op_grupal = 'S' then 'GRUPAL'
                              when x.op_grupal = 'N' and op_ref_grupal is not null then 'INTERCICLO'
                              when (x.op_grupal is null or op_grupal = 'N') and op_ref_grupal is null then 'INDIVIDUAL'
                         end),
                 op_cliente,
                 op_fecha_ult_proceso,
                'R', --Reportada (operacion reportada como cancelada)
                getdate()
          from cob_cartera..ca_operacion x, #operaciones_canceladas
          where op_banco = banco

          if @@rowcount = 0 
          begin
             select @w_error = 701025
             goto ERROR
          end
   end

end 


return 0

ERROR:

        
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error,
    @i_msg    = ' Error en el proceso de interface de Cancelaci¢n de Operaciones',
    @i_sev    = 0
   
   return @w_error
   
go

