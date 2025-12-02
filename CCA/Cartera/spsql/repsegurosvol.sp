/************************************************************************/
/*      Archivo:                repsegurosvol.sp                        */
/*      Stored procedure:       sp_rep_seguros_vol                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     Agosto-2019                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamprohibido asi como           */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                            PROPOSITO                                 */
/* Generación del Reporte Mensual Voluntarios Individual y Grupal       */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_rep_seguros_vol')
   drop proc sp_rep_seguros_vol
go

create proc sp_rep_seguros_vol
(  
   @i_param1  datetime = null 
)
as declare
   @w_return                int,
   @w_sp_name               varchar(32),
   @w_path_destino          varchar(200), 
   @w_s_app                 varchar(40),
   @w_cmd                   varchar(5000),
   @w_destino               varchar(255),
   @w_mensaje               varchar(100),
   @w_path                  varchar(255),
   @w_errores               varchar(255),
   @w_comando               varchar(6000),
   @w_error                 int,
   @w_fec_proceso           datetime,
   @w_fini_periodo          datetime,
   @w_ffin_periodo          datetime,
   @w_titulo                varchar(100),
   @w_periodo               char(6),
   @w_est_cancelado         tinyint,
   @w_est_novigente         tinyint,
   @w_est_anulado           tinyint,
   @w_est_credito           tinyint,
   @w_fecha                 varchar(8),
   @w_hora                  varchar(8)
      
declare @w_operaciones table 
   (
    secuencial              int,
    tipo_producto	        catalogo,
    nombre_cli              varchar(100),
    fecha_nacimiento	    varchar(10),
    fecha_contratacion      varchar(10),    
    fecha_fin	            varchar(10),
    vigencia	            varchar(10),
    tipo_paquete            varchar(50),
    no_certificado          varchar(1),
    credito	                cuenta,
    cliente                 int,
    beneficiario_1	        varchar(100),
    parentesco_1	        varchar(50),
    porcentaje_1	        float,
    beneficiario_2	        varchar(100),
    parentesco_2	        varchar(50),
    porcentaje_2	        float,
    beneficiario_3	        varchar(100),
    parentesco_3	        varchar(50),    
    porcentaje_3	        float
)
    

-- ESTADOS DE CARTERA
exec @w_error = sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,
@o_est_novigente  = @w_est_novigente out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_credito    = @w_est_credito   out

    
-- OBTENIENDO DATOS 
select @w_periodo = left(convert(varchar,fp_fecha,112),6),
       @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso

-- OBTENIENDO FECHA INICIAL Y FINAL DEL PERIODO 
select @w_fini_periodo = convert(datetime, '01/' + 
                         right('00' + convert(varchar, month(@w_fec_proceso)), 2) + '/' + 
                         convert(varchar, year(@w_fec_proceso)), 103), 
       @w_ffin_periodo = @w_fec_proceso
    
insert @w_operaciones     --grupales
select 
    ROW_NUMBER() over(order by a.op_operacion),
    a.op_toperacion,
    isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'') + ' ' + isnull(en_nombre,'')+ ' ' + isnull(p_s_nombre,''),
    convert(varchar,p_fecha_nac,101),
    convert(varchar,b.op_fecha_ini,101),
    convert(varchar,b.op_fecha_fin,101),
    convert(varchar,so_fecha_fin,101),
    
    (select C.valor from cobis..cl_catalogo C, cobis..cl_tabla T
     where T.tabla = 'ca_tipo_seguro'
       and T.codigo = C.tabla
       and C.codigo = S.so_tipo_seguro),
    '',
    a.op_banco,
    b.op_cliente,
    
    (select isnull(bs_apellido_paterno,'') + ' '  + isnull(bs_apellido_materno,'') + ' ' + isnull(bs_nombres,'')
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 1),     --Beneficiario_1
              
    (select C.valor from cobis..cl_catalogo C, cobis..cl_tabla T, cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 1
       and T.tabla = 'cl_parentesco_beneficiario'
       and T.codigo = C.tabla
       and C.codigo = bs_parentesco), --Parentezco_1
              
    (select bs_porcentaje
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion 
       and bs_secuencia = 1),  --Porcentaje_1
       
    (select isnull(bs_apellido_paterno,'') + ' '  + isnull(bs_apellido_materno,'') + ' ' + isnull(bs_nombres,'')
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 2),     --Beneficiario_2
              
    (select C.valor from cobis..cl_catalogo C, cobis..cl_tabla T, cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 2
       and T.tabla = 'cl_parentesco_beneficiario'
       and T.codigo = C.tabla
       and C.codigo = bs_parentesco), --Parentezco_2
       
       
    (select bs_porcentaje
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion 
       and bs_secuencia = 2),  --Porcentaje_2
       
    (select isnull(bs_apellido_paterno,'') + ' '  + isnull(bs_apellido_materno,'') + ' ' + isnull(bs_nombres,'')
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 3),     --Beneficiario_3
              
    (select C.valor from cobis..cl_catalogo C, cobis..cl_tabla T, cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 3
       and T.tabla = 'cl_parentesco_beneficiario'
       and T.codigo = C.tabla
       and C.codigo = bs_parentesco), --Parentezco_3       
       
    (select bs_porcentaje
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion 
       and bs_secuencia = 3)  --3
       
from ca_operacion a,
ca_operacion b,
cobis..cl_ente,
ca_seguros_op S 
where (a.op_estado not in (0, 3, 6, 99) or 
(a.op_estado = 3 and a.op_fecha_ult_proceso between @w_fini_periodo  and @w_fini_periodo))
and a.op_fecha_ini <= @w_fini_periodo
and a.op_grupal = 'S'
and a.op_ref_grupal is null
and a.op_banco = b.op_ref_grupal
and b.op_operacion = S.so_operacion 
and S.so_tipo_seguro != 'B'
and b.op_cliente = en_ente


insert @w_operaciones     --individuales

select 
    ROW_NUMBER() over(order by op_operacion),
    op_toperacion,
    isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'') + ' ' + isnull(en_nombre,'')+ ' ' + isnull(p_s_nombre,''),
    convert(varchar,p_fecha_nac,101),
    convert(varchar,op_fecha_ini,101),
    convert(varchar,op_fecha_fin,101),
    convert(varchar,so_fecha_fin,101),
    
    (select C.valor from cobis..cl_catalogo C, cobis..cl_tabla T
     where T.tabla = 'ca_tipo_seguro'
       and T.codigo = C.tabla
       and C.codigo = S.so_tipo_seguro),
    '',
    op_banco,
    op_cliente,
    
    (select isnull(bs_apellido_paterno,'') + ' '  + isnull(bs_apellido_materno,'') + ' ' + isnull(bs_nombres,'')
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 1),     --Beneficiario_1
              
    (select C.valor from cobis..cl_catalogo C, cobis..cl_tabla T, cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 1
       and T.tabla = 'cl_parentesco_beneficiario'
       and T.codigo = C.tabla
       and C.codigo = bs_parentesco), --Parentezco_1
              
    (select bs_porcentaje
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion 
       and bs_secuencia = 1),  --Porcentaje_1
       
    (select isnull(bs_apellido_paterno,'') + ' '  + isnull(bs_apellido_materno,'') + ' ' + isnull(bs_nombres,'')
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 2),     --Beneficiario_2
              
    (select C.valor from cobis..cl_catalogo C, cobis..cl_tabla T, cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 2
       and T.tabla = 'cl_parentesco_beneficiario'
       and T.codigo = C.tabla
       and C.codigo = bs_parentesco), --Parentezco_2
       
       
    (select bs_porcentaje
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion 
       and bs_secuencia = 2),  --Porcentaje_2
       
    (select isnull(bs_apellido_paterno,'') + ' '  + isnull(bs_apellido_materno,'') + ' ' + isnull(bs_nombres,'')
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 3),     --Beneficiario_3
              
    (select C.valor from cobis..cl_catalogo C, cobis..cl_tabla T, cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion
       and bs_secuencia = 3
       and T.tabla = 'cl_parentesco_beneficiario'
       and T.codigo = C.tabla
       and C.codigo = bs_parentesco), --Parentezco_3       
       
    (select bs_porcentaje
     from cobis..cl_beneficiario_seguro
     where bs_producto = 7
       and bs_nro_operacion = S.so_operacion 
       and bs_secuencia = 3)  --3
       
from ca_operacion a,
cobis..cl_ente,
ca_seguros_op S 
where (a.op_estado not in (0, 3, 6, 99) or 
(a.op_estado = 3 and a.op_fecha_ult_proceso between  @w_fini_periodo  and @w_fini_periodo))
and a.op_fecha_ini <=  @w_fini_periodo
and (op_grupal = 'N' or op_grupal is null)
and op_operacion not in (select dc_operacion from ca_det_ciclo)
and op_operacion = S.so_operacion 
and S.so_tipo_seguro != 'B'
and op_cliente = en_ente

----------------------------------------
--	Generar Archivo Plano
----------------------------------------

select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

select @w_path = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 7

--hora
select @w_hora  = convert(varchar(8), getdate(), 108) --hh:mm:ss
select @w_hora  = substring(@w_hora,1,2) + substring(@w_hora,4,2) --hhmm

--fecha proceso 
select @w_fecha = convert(varchar(8), getdate(), 112) --yyyymmdd
select @w_fecha = substring(@w_fecha,5,2) + substring(@w_fecha,7,2) + substring(@w_fecha,1,4) --mmddyyyy



delete cob_cartera..ca_rep_seguro_voluntario
where rsv_secuencial >= 0

select @w_titulo = 'REPORTE DE FACTURACION MENSUAL DE SEGUROS VOLUNTARIOS CREDITO INDIVIDUAL Y GRUPAL'

insert into cob_cartera..ca_rep_seguro_voluntario values
(0, '', @w_titulo, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '') 

insert into cob_cartera..ca_rep_seguro_voluntario values
(0, 'TIPO PRODUCTO', 'NOMBRE CLIENTE', 'FECHA DE NACIMIENTO', 'FECHA DE CONTRATACION', 'FECHA DE FIN', 'VIGENCIA',
'TIPO DE PAQUETE', 'NO. CERTIFICADO', 'CREDITO', 'CLIENTE', 'BENEFICIARIO 1', 'PARENTESCO 1', 'PORCENTAJE 1', 'BENEFICIARIO 2', 
'PARENTESCO 2', 'PORCENTAJE 2', 'BENEFICIARIO 3', 'PARENTESCO 3', 'PORCENTAJE 3')


insert cob_cartera..ca_rep_seguro_voluntario 
select secuencial,
       tipo_producto,
       nombre_cli,
       fecha_nacimiento,
       fecha_contratacion,  
       fecha_fin,
       vigencia,
       tipo_paquete,
       no_certificado,
       credito,
       convert(varchar(10),cliente),
       beneficiario_1,
       parentesco_1,
       convert(varchar(10),porcentaje_1),
       beneficiario_2,
       parentesco_2,
       convert(varchar(10),porcentaje_2),
       beneficiario_3,
       parentesco_3,    
       convert(varchar(10),porcentaje_3)
from @w_operaciones 
order by secuencial

	
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_rep_seguro_voluntario out '

select 	@w_destino = @w_path + 'repmenvolindgrp_' + @w_fecha + '_' + @w_hora + '.txt',
	    @w_errores = @w_path + 'repmenvolindgrp_' + @w_fecha + '_' + @w_hora + '.err'

select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -T -e ' + @w_errores + ' -t"|" ' + '-config ' + @w_s_app + 's_app.ini'

PRINT ' CMD: ' + @w_comando 

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select
   @w_error = 70171,
   @w_mensaje = 'Error generando Archivo '
   goto ERROR
end


  
return 0

ERROR:
exec cobis..sp_errorlog 
	@i_fecha        = @w_fec_proceso,
	@i_error        = @w_error,
	@i_usuario      = 'usrbatch',
	@i_tran         = 26004,
	@i_descripcion  = @w_mensaje,
	@i_tran_name    = null,
	@i_rollback     = 'S'
    
return @w_error

go
