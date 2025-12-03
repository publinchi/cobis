/************************************************************************/
/*      Archivo:                        notificagrupo.sp                */
/*      Stored procedure:               sp_notifica_grupo               */
/*      Base de Datos:                  cob_cartera                     */
/*      Producto:                       Cartera                         */
/************************************************************************/
/*                      IMPORTANTE                                      */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                      PROPOSITO                                       */
/* Realiza el envio de notificacion a los gerentes y coordinadores      */
/* responsables de los grupos de credito                                */
/************************************************************************/


use cob_cartera
go

if exists(select * from sysobjects where name = 'sp_notifica_grupo')
   drop proc sp_notifica_grupo
go

create proc sp_notifica_grupo(   
@i_to            varchar(255),        --mail
@i_cc            varchar(255) = null,
@i_bcc           varchar(255) = null,
@i_subject       varchar(510) = null,
@i_funcionario   int,                 --codigo funcionario
@i_nombre        varchar(255) = null, --nombre de funcionario
@i_attachment    varchar(65)  = null, --nombre del archivo adjunto
@i_tipo_notific  varchar(10)
)
as declare 
@w_body          varchar(2000),
@w_error         int,
@w_text_mail     varchar(255),
@w_from          varchar(60),
@w_id            int,
@w_fecha_hoy     varchar(10),
@w_fecha         datetime,
@w_mensaje       varchar(255),
@w_content       varchar(255),
@w_codigo        int,
@w_particion     varchar(20),
@w_cortar        int,
@w_origen        char(1),
@w_tramite       int, 
@w_nombre        varchar(64),
@w_dividendo     varchar(10),
@w_des_dividendo varchar(64),
@w_operacion     int,
@w_dia_venc      int,
@w_dia_desc      varchar(64),
@w_registro      varchar(24),
@w_inter_anio    varchar(5),
@w_inter_mes     varchar(10),
@w_inter_nom_mes varchar(10),
@w_fecha_etcue   datetime
/*
select @w_fecha = getdate()

if @i_to is null or @i_to = ''
begin
    select  @w_mensaje = 'ERROR: FUNCIONARIO NO TIENE CORREO DE NOTIFICACION',
            @w_error = 724622
    goto ERROR  
end

set @w_content = 'TEXT'

select @w_from = isnull(pa_char,50) 
from cobis..cl_parametro 
where pa_nemonico = 'MANO' 
and pa_producto = 'REC'

select @w_id = te_id 
from cobis..ns_template
where te_nombre = 'NotificacionGruposVenci.xslt'

if @i_tipo_notific = 'PFGVG' or @i_tipo_notific = 'PFGVC' 
begin
    select @w_body = 'Adjunto el archivo con la lista de préstamos grupales vencidos.' +  char(13) + char(13) + 'Saludos.'
end
else if (@i_tipo_notific = 'PFPCO')
begin
   
   	SELECT @w_dividendo		= op_tdividendo,
   	       @w_operacion		= op_operacion
   	FROM cob_cartera..ca_operacion 
	WHERE op_tramite = (SELECT max(tg_tramite) 
	FROM cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion
	WHERE tg_grupo = @i_funcionario --1724
	AND op_banco = tg_referencia_grupal
	AND tg_tramite = op_tramite
	AND op_estado = 3)
   	
   	SELECT @w_des_dividendo = td_descripcion FROM cob_cartera..ca_tdividendo
	WHERE td_tdividendo = @w_dividendo
   	
   	SELECT  @w_dia_venc = datepart(dw,di_fecha_ven) FROM ca_dividendo
	WHERE di_operacion = @w_operacion --45988
	AND di_dividendo = 1
   	
   	select @w_dia_desc = (case @w_dia_venc when 1 then 'DOMINGO' 
   	                       when 2 then 'LUNES' when 3 then 'MARTES' 
   	                        when 4 then 'MIÉRCOLES' when 5 then 'JUEVES' 
   	                         when 6 then 'VIERNES' when 7 then 'SÁBADO' end)
   	
   	select @w_body = '<?xml version="1.0" encoding="ISO-8859-1"?><data><cab><dividendo>' + @w_des_dividendo +'</dividendo><dia>' + @w_dia_desc +'</dia></cab></data>'
	set @w_content = 'HTML'
	select @w_id = te_id 
	from cobis..ns_template
	where te_nombre = 'PagoCorresponsal.xslt'
	
	set @i_subject = 'Te informamos tu fecha de pago y monto'
   
end
else if (@i_tipo_notific = 'PFCVE')
begin
   select @w_body = 'Estimado señor(a).' + char(13) 
   select @w_body = @w_body + replace(isnull(@i_nombre, ''), '|', '</br>') + char(13) + char(13) 

   select @w_body = @w_body + 'Enviamos adjunto en este correo el  estado de cuenta del préstamo otorgado a usted, '
   select @w_body = @w_body + 'el archivo contiene el código de referencia para pago en cualquiera de las oficinas de los corresponsales autorizados. '
   select @w_body = @w_body + char(13) + char(13) + char(13) + 'Saludos.'
end
else if (@i_tipo_notific = 'PFIAV')
begin
   select @w_body = 'Estimado señor(a).' + char(13) 
   select @w_body = @w_body + replace(isnull(@i_nombre, ''), '|', '</br>') + char(13) + char(13) 

   select @w_body = @w_body + 'Le informamos lo siguiente: '
   select @w_body = @w_body + char(13) + 'Saludos.'
end
else if (@i_tipo_notific = 'PFGLQ')
begin
   select @w_body = '<?xml version="1.0" encoding="ISO-8859-1"?><data></data>'
   set @w_content = 'HTML'
   select @w_id = te_id 
   from cobis..ns_template
   where te_nombre = 'GarantiaLiquida.xslt'
   
   set @i_subject = 'Realiza el depósito de tu aportación y alcanza tu meta'
   
end
else if (@i_tipo_notific = 'NTGNR')
begin
   
   select @w_particion = substring(@i_attachment,21,len(@i_attachment))
   select @w_cortar = CHARINDEX('.pdf', @w_particion)
   select @w_particion = substring(@w_particion,1,@w_cortar-1)
   select @w_codigo = convert(int, @w_particion)
   
   select @w_origen = ng_origen,
          @w_tramite = ng_tramite
   from cobis..cl_notificacion_general 
   WHERE ng_codigo =  @w_codigo
   
   SELECT @w_nombre = gr_nombre 
   FROM cobis..cl_grupo, cob_workflow..wf_inst_proceso
   WHERE io_campo_3 = @w_tramite
   AND io_campo_1 = gr_grupo
   
   
   if(@w_origen = 'D') --D es desembolso
   begin
	   
	   select @w_body = '<?xml version="1.0" encoding="ISO-8859-1"?><data><cab><name>' + @w_nombre +'</name></cab></data>'
	   set @w_content = 'HTML'
	   select @w_id = te_id 
	   from cobis..ns_template
	   where te_nombre = 'NotificacionGeneral.xslt'
	   
	   set @i_subject = 'Tu crédito ya está disponible'
	   
   end
   else
   begin
       select @w_body = ''
   end

end
else if (@i_tipo_notific = 'CRLCR')
begin
   select @w_particion = substring(@i_attachment,13,len(@i_attachment))
   select @w_cortar = CHARINDEX('.pdf', @w_particion)
   select @w_particion = substring(@w_particion,1,@w_cortar-1)
   select @w_tramite = convert(int, @w_particion)
   
   select top 1 @w_registro = rb_registro_id 
   from cob_credito..cr_b2c_registro , cob_workflow..wf_inst_proceso
   where io_campo_3 = @w_tramite
   and io_id_inst_proc = rb_id_inst_proc
   
   select @w_body = '<?xml version="1.0" encoding="ISO-8859-1"?><data><codigo>' + @w_registro +'</codigo></data>'
   set @w_content = 'HTML'
   select @w_id = te_id 
   from cobis..ns_template
   where te_nombre = 'CreacionLCR.xslt'
   
   set @i_subject = 'Tu crédito ya está disponible'
end
else if(@i_tipo_notific = 'ETCUE')
begin
   print 'ingreso a ETCUE'
   
   select top 1 @w_fecha_etcue=in_fecha_xml from  cob_conta_super..sb_ns_estado_cuenta
   
   select @w_inter_anio = LTRIM(RTRIM(convert(varchar(5),DATENAME(yyyy,@w_fecha_etcue))))
   select @w_inter_mes  = LTRIM(RTRIM(convert(varchar(10),DATENAME(mm,@w_fecha_etcue))))
   
   select @w_inter_nom_mes = (case @w_inter_mes when 'January' then 'Enero' 
                          when 'February' then 'Febrero' when 'March' then 'Marzo' 
                          when 'April' then 'Abril' when 'May' then 'Mayo' 
                          when 'June' then 'Junio' when 'July' then 'Julio' 
                          when 'August' then 'August' when 'August' then 'August' 
                          when 'September' then 'Septiembre' when 'October' then 'Octubre' 
                          when 'November' then 'Noviembre' when 'December' then 'Diciembre' end)
  
   set @w_content = 'HTML'
   select @w_id = te_id 
   from cobis..ns_template 
   where te_nombre = 'NotifInterfacturaEstadoCuenta.xslt'
   
   select @w_body = '<?xml version="1.0" encoding="ISO-8859-1"?><data><mesEnvio>' + convert(varchar(10),@w_inter_nom_mes) +'</mesEnvio><anioEnvio>' +convert(varchar(10),@w_inter_anio)+ '</anioEnvio></data>'
      
end
else
begin
   select @w_body = ''
end

select @w_id       = isnull(@w_id, 0)

print @w_body 
exec @w_error =  cobis..sp_despacho_ins
        @i_cliente          = @i_funcionario,
        @i_template         = @w_id,
        @i_servicio         = 1,
        @i_estado           = 'P',
        @i_tipo             = 'MAIL',
        @i_tipo_mensaje     = 'I',
        @i_prioridad        = 1,
        @i_from             = null,
        @i_to               = @i_to,
        @i_cc               = @i_cc,
        @i_bcc              = @i_bcc,
        @i_subject          = @i_subject,
        @i_body             = @w_body,
        @i_content_manager  = @w_content,
        @i_retry            = 'S',
        @i_fecha_envio      = null,
        @i_hora_ini         = null,
        @i_hora_fin         = null,
        @i_tries            = 0,
        @i_max_tries        = 2,
        @i_var1             = @i_attachment

if @w_error <> 0
begin
    select @w_mensaje = 'ERROR AL ENVIAR NOTIFICACION'
    goto ERROR
end
*/
return 0
/*
ERROR:
exec cobis..sp_ba_error_log
            @t_trn           = 8205,
            @i_operacion     = 'I',
            @i_sarta         = 9999, 
            @i_batch         = 7072,
            @i_fecha_proceso = @w_fecha,
            @i_error         = @w_error,
            @i_detalle       = @w_mensaje

return @w_error 
*/
go
