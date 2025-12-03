/************************************************************************/
/*      Archivo:                ca_rep_saldosfag.sp                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Finagro                                 */
/*      Disenado por:           Alejandra Celis                         */
/*      Fecha de escritura:     05/12/2015                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Reporte Mensual de saldos Op Finagro. Req  516 Emision Inicial      */
/*                                                                      */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA          AUTOR                    RAZON                       */
/*  05/13/2015   Alejandra Celis        Creacion Inicial NR 516         */
/************************************************************************/
use
cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_saldosfag')
   drop proc sp_rep_saldosfag 
go

create proc sp_rep_saldosfag (
@i_param1    varchar(10) = NULL,     --FECHA DE INICIO
@i_param2    varchar(10) = NULL      --FECHA DE FIN
)

as 
declare
@w_fecha_ini       varchar(10),
@w_fecha_fin       varchar(10),
@w_sp_name         varchar(30),
@w_error           int,
@w_mensaje         descripcion,

--PARAMETROS PROPIOS DEL BCP
@w_s_app		   varchar(255),
@w_path			   varchar(255),
@w_nombre		   varchar(255),
@w_nombre_cab	   varchar(255),
@w_destino		   varchar(2500),
@w_errores		   varchar(1500),
@w_nombre_plano	   varchar(2500),
@w_cmd             varchar(2500),
@w_columna		   varchar(100),
@w_cabecera		   varchar(2500),
@w_nom_tabla	   varchar(100),
@w_comando		   varchar(2500),
@w_fecha_proceso   varchar(10),
@w_fecha_dia       datetime,
@w_col_id		   int,
@w_archivo         varchar(50),
@w_anio            varchar(4),
@w_mes             varchar(2),
@w_dia             varchar(2),
@w_cont            int  ,
@w_fecha_entrada  datetime,
@w_fecha_finmes   datetime
select @w_sp_name = 'sp_rep_saldosfag',
       @w_fecha_ini   = convert(varchar,@i_param1,101),
       @w_fecha_fin   = convert(varchar,@i_param2,101)
      
select @w_fecha_dia = GETDATE()
select @w_fecha_entrada = convert(datetime,@i_param2,101)
if @w_fecha_ini is null or @w_fecha_fin is null
begin 
   print 'ERROR : NO EXISTE FECHA PARA REALIZAR PROCESO'
   select @w_mensaje =  'ERROR : NO EXISTE FECHA PARA REALIZAR PROCESO'
   --GOTO ERRORFIN
end


if CONVERT(datetime,@w_fecha_ini) > CONVERT(datetime,@w_fecha_fin )
begin 
   print 'ERROR : FECHA INICIAL MAYOR QUE FECHA FINAL'
   select @w_mensaje =  'ERROR : FECHA INICIAL MAYOR QUE FECHA FINAL'
   --GOTO ERRORFIN
end

if exists (select 1 from sysobjects where name = 'ca_saldosfag' and type = 'U' )
begin
   drop table ca_saldosfag
end
select @w_fecha_entrada =DATEADD(mm,1,@w_fecha_entrada)
select @w_fecha_finmes = dateadd(dd,-DATEPART(dd,@w_fecha_entrada), @w_fecha_entrada)

select @w_anio = convert(varchar(4),datepart(yyyy,@w_fecha_finmes)),
       @w_mes  = right('00' + convert(varchar(2),datepart(mm,@w_fecha_finmes)),2), 
       @w_dia  = right('00' + convert(varchar(2),datepart(dd,@w_fecha_finmes)),2) 

select @w_fecha_proceso = ( right('00' + @w_dia,2) + right('00'+ @w_mes,2)+@w_anio )      

select
banco                 = of_pagare,
estado                = do_estado_cartera,
fecha_ult_pago        = do_fecha_ult_pago,
fecha_ven             = do_fecha_vencimiento,
ref_arch              = 'AS' + @w_fecha_proceso + '_752',
nit_intermediario     = '9002150711' ,--CONVERT(int,null),
num_certificado       = convert(varchar(18),(select vo_num_gar from cob_cartera..ca_val_oper_finagro    where of_pagare= vo_operacion)),
num_identificacion    = of_iden_cli,
llave_credito         =  convert(varchar(18),(isnull((select vo_oper_finagro from cob_cartera..ca_val_oper_finagro    where of_pagare= vo_operacion),of_pagare))),
cod_moneda            = (case when do_moneda = 0 then 'COP' else null end),
calificacion          = do_calificacion, 
reservado             = convert(varchar(11),null),
capital               = convert(int,do_saldo_cap), 
intereses             = 0,
fecha_corte           = @w_fecha_proceso,
cuotas_mora           = do_num_cuotaven, 
fecha_ing_mora        = (case when do_num_cuotaven > 0 then (isnull(right('00' + convert(varchar(2),datepart(dd,do_fecha_ini_mora)),2)  + right('00' + convert(varchar(2),datepart(mm,do_fecha_ini_mora)),2) + convert(varchar(4),datepart(yyyy,do_fecha_ini_mora)),'0')) else '0' end),
fecha_can_prestamo    = CONVERT(varchar(8),null),
dias_mora             = (case when do_num_cuotaven > 0 then (datediff (dd,do_fecha_ini_mora,@w_fecha_finmes)) else 0 end) 
into #ca_saldosfag
from ca_opera_finagro ,cob_conta_super..sb_dato_operacion 
where of_procesado       <> 'L'
and   of_indicativo_fag  = 'S'
and   of_pagare = do_banco
and   do_fecha = @w_fecha_fin

delete #ca_saldosfag
where estado = 3 
and   fecha_ult_pago = fecha_ven


--Actualiza Nro de certificado
update #ca_saldosfag
set   num_certificado =cu_codigo_externo
from  cob_cartera..ca_operacion, cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia
where banco = op_banco 
and   gp_tramite  = op_tramite
and   gp_est_garantia = 'V'
and   cu_codigo_externo = gp_garantia
and   cu_tipo = 2105
and   cu_estado = 'V'
and   num_certificado is null

--ACTUALIZANDO Fecha Cancelacion
select fecha_op = b.do_banco, fecha_can = max(do_fecha_ult_pago)
into   #fecha_cancela
from   cob_conta_super..sb_dato_operacion b ,#ca_saldosfag
where  b.do_banco = banco
and    b.do_fecha_ult_pago  between @w_fecha_ini and @w_fecha_fin
and    b.do_fecha_ult_pago  < b.do_fecha_vencimiento
and    b.do_estado_cartera = 3
group by b.do_banco


update #ca_saldosfag
set   fecha_can_prestamo = isnull(right('00' + convert(varchar(2),datepart(dd,fecha_can)),2)  + right('00' + convert(varchar(2),datepart(mm,fecha_can)),2) + convert(varchar(4),datepart(yyyy,fecha_can)),'0')
from  #fecha_cancela
where banco  = fecha_op


update #ca_saldosfag
set   fecha_can_prestamo = isnull(fecha_can_prestamo,'0')
where fecha_can_prestamo is null


update #ca_saldosfag
set   num_certificado =cu_codigo_externo
from  cob_cartera..ca_operacion, cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia
where banco = op_banco 
and   gp_tramite  = op_tramite
and   gp_est_garantia in('X','C')
and   cu_codigo_externo = gp_garantia
and   cu_tipo = 2105
and   cu_estado in('X','C')
and   fecha_can_prestamo is not null

select 
ref_arch              ,
nit_intermediario     ,
num_certificado       ,
num_identificacion    ,
llave_credito         ,
cod_moneda            ,
calificacion          ,
reservado             ,
capital               ,
intereses             ,
fecha_corte           ,
cuotas_mora           ,
fecha_ing_mora        ,
fecha_can_prestamo    ,
dias_mora             
into ca_saldosfag
from #ca_saldosfag


--OBTENIENDO NOMBRE DE ARCHIVO FISICO
select @w_archivo = 'AS' + @w_fecha_proceso + '_752'

--------------------------REALIZANDO BCP--------------------------

--GENERAR BCP
select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

--GENERACIÓN DE LISTADO
select @w_path = pp_path_destino
from cobis..ba_path_pro 
where pp_producto  = 7

select @w_nombre_plano = @w_path + @w_archivo +  '.cvs'
print @w_nombre_plano

select @w_cont = count(1) from ca_saldosfag

if isnull(@w_cont,0) = 0
begin
  
   select  @w_error     = 2902798, 
		   @w_mensaje   = 'NO EXISTEN DATOS PARA PROCESAR'
   select  @w_comando = 'echo ' + @w_mensaje + ' > '  + @w_nombre_plano

   		   
end
else
begin
								
----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
   select @w_cmd     =  'bcp "select * from cob_cartera..ca_saldosfag  " queryout ' 
   select @w_comando   = @w_cmd + @w_nombre_plano + ' -b5000 -c -t";" -T -S'+ @@servername + ' -ePLANOsaldosfag.err' 
end

exec @w_error = xp_cmdshell @w_comando

If @w_error <> 0 Begin
   select @w_mensaje = 'Error Generando BCP Plano SALDOS FAG ' + @w_comando
   Goto ERRORFIN 
End                            

RETURN 0
ERRORFIN:
   exec @w_error = sp_errorlog
        @i_fecha      = @w_fecha_dia,
        @i_error      = @w_error,
        @i_usuario    = 'op_batch',
        @i_tran       = 7130,
        @i_tran_name  = @w_mensaje,
        @i_rollback   = 'N',
        @i_descripcion = @w_sp_name

go

