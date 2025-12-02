/************************************************************************/
/*      Archivo           :  cr_opcns.sp                                */
/*      Base de datos     :  cob_cartera                                */
/*      Producto          :  Cartera                                    */
/*      Disenado por      :  Walther Toledo                             */
/*      Fecha de escritura:  21-Oct-16                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA", representantes exclusivos para el Ecuador de la       */
/*      "NCR CORPORATION".                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este reporte saca un listado de lus usuario que  pertenecen al  */
/*      buro de credito.                                                */
/*                                                                      */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*      FECHA           AUTOR           RAZON                           */
/*      19/Dic/16      W. Toledo     Emision inicial                    */
/************************************************************************/
USE cob_conta_super
GO
if exists (select 1 from sysobjects where name = 'sp_ca_burocred')
   drop proc sp_ca_burocred
go

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

create proc sp_ca_burocred
   @t_show_version bit      = 0,
   @i_param1       datetime = NULL 
as
DECLARE @i_fecha DATETIME,
   @w_nombre_fuente    VARCHAR(30),
   @w_cabecera         VARCHAR(500),
   @w_etiqseg          CHAR(4),
   @w_version          char(2),
   @w_sec_neg          char(2),
   @w_id_usu           char(4),
   @w_prod_linea       char(4),
   @w_nom_usu          char(16),
   @w_reserv_uno       char(2),
   @w_fecha_tran       varchar(8),
   @w_reserv_dos       char(10),
   @w_inf_adc_usu       char(98),
   @w_mensaje          varchar(150),
   @w_date_proceso     varchar(10),
   @w_hor_listado      VARCHAR(2),
   @w_min_listado      VARCHAR(2),
   @w_mes              char(2),
   @w_dia              char(2),
   @w_anio             char(4),
   @w_hor              int,
   @w_min              INT,
   @w_apep             char(2),
   @w_apem             char(4),
   @w_nomp             char(4),
   @w_noms             char(4),
   @w_fecn             char(4),
   @w_rfc              char(4),
   @w_nac              char(4),
   @w_nmx              char(4),
   @w_hclv             char(4),
   @w_estc             char(4),
   @w_sexo             char(4),
   @w_idtf             char(4),
   @w_clvp             char(4),
   @w_pais_mx          char(4),
   @w_error            int,
   @w_s_app            varchar(255),
   @w_path             varchar(255),
   @w_nombre           varchar(255),
   @w_sp_name          varchar(20),
   @w_comando          varchar(2500),
   @w_nombre_det       varchar(255),
   @w_nombre_cab       varchar(255),
   @w_path_destino     varchar(30),
   @w_cmd              varchar(2500),
   @w_nombre_plano     varchar(2500),
   @w_destino          varchar(2500),
   @w_errores          varchar(1500),
   @w_msg              descripcion,
   @w_creq             char(1)
   
select @w_sp_name = 'sp_ca_burocred'
    ----CAPTURA DE PARAMETROS
    select @w_etiqseg = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='ETISEG'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro ETISEG'
       goto ERRORFIN
    end

    select @w_version = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='VERSIO'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro VERSIO'
       goto ERRORFIN
    end

    select @w_sec_neg = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='MCCSNE'
    
    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro MCCSNE'
       goto ERRORFIN
    end

    select @w_id_usu = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='MCUSUA'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro MCUSUA'
       goto ERRORFIN
    end

    select @w_prod_linea = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='MCPRLI'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro MCPRLI'
       goto ERRORFIN
    end

    select @w_nom_usu = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='NOMUSU'
    
    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro NOMUSU'
       goto ERRORFIN
    end

    select @w_reserv_uno = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='RESUNO'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro RESUNO'
       goto ERRORFIN
    end

    select @w_reserv_dos = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='RESDOS'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro RESDOS'
       goto ERRORFIN
    end

    select @w_apep = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='APEP'
    
    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro APEP'
       goto ERRORFIN
    end

    select @w_apem = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='APEM'
    
    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro APEM'
       goto ERRORFIN
    end

    select @w_nomp = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='NOMP'
    
    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro NOMS'
       goto ERRORFIN
    end

    select @w_noms = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='NOMS'
    
    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro NOMS'
       goto ERRORFIN
    end

    select @w_fecn = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='FECN'
    
    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro FECN'
       goto ERRORFIN
    end

    select @w_rfc = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='RFC'
    
    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro RFC'
       goto ERRORFIN
    end

    select @w_nac = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='NAC'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro NAC'
       goto ERRORFIN
    end

    select @w_nmx = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='NMX'
    
    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro NMX'
       goto ERRORFIN
    end

    select @w_hclv = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='HCLV'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro HCLV'
       goto ERRORFIN
    end

    select @w_estc = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='ESTC'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro ESTC'
       goto ERRORFIN
    end

    select @w_sexo = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='SX'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro SX'
       goto ERRORFIN
    end

    select @w_idtf = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='IDTF'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro IDTF'
       goto ERRORFIN
    end

    select @w_clvp = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='CLVP'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro CLVP'
       goto ERRORFIN
    end


    SELECT @w_pais_mx = pa_smallint FROM cobis..cl_parametro,cobis..cl_pais
    WHERE pa_smallint =pa_pais
    AND pa_producto='CCA' 
    and pa_nemonico='CPM'
    AND pa_tipo='S'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro CPM'
       goto ERRORFIN
    end

    select @w_creq = pa_char 
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico ='CREQ'

    if @@rowcount = 0 begin
       select @w_error = 101077, @w_mensaje = ' ERROR en sp_ca_burocred :: No existe parametro CREQ'
       goto ERRORFIN
    end

select @i_fecha = @i_param1 --Campo 17
select @w_date_proceso = convert(VARCHAR(30),@i_fecha,103)
select @w_dia = substring(@w_date_proceso,1,2)
select @w_mes = substring(@w_date_proceso,4,2)
select @w_anio = substring(@w_date_proceso,7,4)
select @w_fecha_tran =  @w_dia + @w_mes + @w_anio
select @w_hor = datepart(hour,@i_fecha)
select @w_min = datepart(minute,@i_fecha)

if @w_hor < 10 select @w_hor_listado = '0' + convert(CHAR(1),@w_hor)
else           select @w_hor_listado = convert(CHAR(2),@w_hor)

if @w_min < 10 select  @w_min_listado = '0' + convert(CHAR(1),@w_min)
else           select  @w_min_listado = convert(CHAR(2),@w_min)


select @w_cabecera = @w_etiqseg + @w_version + @w_sec_neg + @w_id_usu + @w_prod_linea + @w_nom_usu + 
                     @w_reserv_uno + @w_fecha_tran + @w_reserv_dos 
					 
					 
--CABECERA DEL REPORTE					 
insert into sb_cabecera_buro_credito (cabecera)
select @w_cabecera

--DETALLE DEL REPORTE
				
insert into sb_reporte_buro_credito ( apellido_paterno,     apellido_materno, apellido_adicional,     primer_nombre, 
                                      segundo_nombre,       fecha_nacimiento, rfc,                    prefijo_profesional ,   
                                      sufijo_cliente,       nacionalidad ,    tipo_residencia,        licencia  ,             
                                      estado_civil ,        sexo_cli  ,       numero_social,          registro_electoral,  
									  clave_identificacion, clave_pais,       numero_dependientes,    edades_dependientes,  
                                      fecha_defuncion,      indicador_defuncion  									  
									  )  				  
SELECT

@w_apep  + convert(VARCHAR(26),len(dc_p_apellido)) + UPPER(RTRIM(dc_p_apellido)),
case dc_s_apellido WHEN NULL THEN 'NO PROPORCIONADO' ELSE  @w_apem  + convert(VARCHAR(26),len(dc_s_apellido)) +  UPPER(RTRIM(dc_s_apellido))  END ,
@w_creq,
@w_nomp + convert(VARCHAR(26),len(SUBSTRING(dc_nombre, 1, charindex(' ', dc_nombre) )))+UPPER(RTRIM(SUBSTRING(dc_nombre, 1, charindex(' ', dc_nombre) ))),
@w_noms + convert(VARCHAR(26),len(SUBSTRING(dc_nombre,(LEN(dc_nombre) - CHARINDEX(' ',dc_nombre) ), LEN(dc_nombre)))) +
case SUBSTRING(dc_nombre,(LEN(dc_nombre) - CHARINDEX(' ',dc_nombre) ), LEN(dc_nombre)) 
when null then '00' else UPPER(RTRIM(SUBSTRING(dc_nombre,(LEN(dc_nombre) - CHARINDEX(' ',dc_nombre) ), LEN(dc_nombre))))end, 						
@w_fecn +  case when convert(VARCHAR,len(replace (convert (VARCHAR,dc_fecha_nac,103),'/',''))) 
		   < 10 then '0'+ convert(VARCHAR,len(replace (convert (VARCHAR,dc_fecha_nac,103),'/',''))) 
		   else  convert(VARCHAR,len(replace (convert (VARCHAR,dc_fecha_nac,103),'/',''))) end + replace (convert (VARCHAR,dc_fecha_nac,103),'/',''),								 
case (select DISTINCT dc_pais FROM sb_equivalencias, sb_dato_cliente  where  convert(VARCHAR,dc_pais) = eq_valor_arch)
when @w_pais_mx then @w_rfc  +  convert(VARCHAR,len(substring(dc_nombre,1,4) + substring( convert (VARCHAR,dc_fecha_nac,112),1,6)))+ substring(dc_nombre,1,4) + substring( convert (VARCHAR,dc_fecha_nac,112),1,6)+@w_hclv
else @w_rfc END,
@w_creq,
@w_creq,
@w_nac + '0' + case (select DISTINCT dc_pais FROM sb_equivalencias, sb_dato_cliente  where  convert(VARCHAR,dc_pais) = eq_valor_arch)
			   when @w_pais_mx then convert(varchar ,len(@w_nmx)) + @w_nmx ELSE @w_nac  END,  					  
@w_creq,
@w_creq,
@w_estc + '01' +  case dc_estado_civil when  'CA'  THEN 'M' 
					                   when  'SO'  THEN 'S'
					                   when  'VI'  THEN 'W'
					                   when  'UN'  THEN 'F'
					                   WHEN  'DI'  THEN 'D'
					                   else @w_estc end ,				   
@w_sexo + '0' + convert(varchar(1), len(dc_sexo)) + dc_sexo,
@w_creq,
@w_creq,
@w_idtf + convert(varchar(1), len(dc_ced_ruc)) + dc_ced_ruc,
@w_clvp + case dc_pais when null then @w_clvp else convert(varchar(1), len(dc_pais)) + dc_pais end,
@w_creq,
@w_creq,
@w_creq,
@w_creq	
								
FROM sb_dato_cliente
where dc_fecha     =   @i_fecha
and   dc_nombre    <>  ''
and   dc_fecha_nac <>  ''


/* Iniciando BCP */
select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'


--Seleccionando el path destino para archivo de salida
/*select @w_path = pp_path_destino
from   cobis..ba_path_pro
where  pp_producto = 7*/
select @w_path = 'C:\Cobis\vbatch\cartera\listados\'


----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select
@w_nombre       = 'REPORTE_BURO_CREDITO_CAB' ,
@w_nombre_det   = 'REPORTE_BURO_CREDITO_DET' ,
@w_nombre_cab   = @w_nombre
--select @w_nombre_plano = @w_path +  @w_nombre_cab + '_'+ replace(convert(varchar,@i_param1,102),'.','')+'.txt'
select @w_nombre_plano =   @w_nombre_cab + '_'+ replace(convert(varchar,getdate(),102),'.','')
 --bcp cabecera
 print 'nombre archivo' + ' ' + @w_nombre_plano
 select @w_comando = @w_s_app + 's_app bcp -auto -login cob_conta_super..sb_cabecera_buro_credito out '

select

@w_destino  = @w_path + @w_nombre  +'.txt',
@w_errores  = @w_path + @w_nombre +'.err'

select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0
begin
   select @w_msg = 'Error Generando Archivo Reporte de: '+ '@w_nombre',
   @w_error = 2902797

 --  goto ERRORFIN
end

--bcp detalle
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_conta_super..sb_reporte_buro_credito out '
select
@w_destino  = @w_path + @w_nombre_det  +'.txt',
@w_errores  = @w_path + @w_nombre_det +'.err'

select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0
begin
   select @w_msg = 'Error Generando Archivo Reporte de: '+ '@w_nombre_det',
   @w_error = 2902797

 --  goto ERRORFIN
end
--UNIFICACION DE ARCHIVOS
select
@w_destino  = @w_path +  @w_nombre_plano +'.txt',
@w_errores  = @w_path +  @w_nombre_plano +'.err'

select @w_comando = 'echo ' +  ' > '  +  @w_destino
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   goto ERRORFIN
end

select @w_comando = 'copy ' + @w_destino + ' + ' + @w_path + @w_nombre + '.txt' + ' + ' + @w_path + @w_nombre_det + '.txt'  +  ' ' + @w_destino

select @w_comando
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   goto ERRORFIN
end

-- BORRADO DE ARCHIVOS INTERMEDIOS
select
   @w_comando = 'del ' +
   @w_path + @w_nombre     + ' ' + @w_path + @w_nombre_det 
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'EJECUCION comando bcp FALLIDA (Eliminacion de Archivos intermedios .txt). REVISAR ARCHIVOS DE LOG GENERADOS. '
   goto ERRORFIN
end



print 'cadena' + ' ' +  @w_comando
truncate table sb_cabecera_buro_credito
truncate table  sb_reporte_buro_credito
 
return 0
ERRORFIN:
 exec cobis..sp_errorlog 
 @i_fecha        = @i_fecha,
@i_error        = @w_error,
@i_usuario      = 'batch',
@i_tran         = 26004,
@i_descripcion  = @w_msg,
@i_tran_name    ='BURO',
@i_rollback     ='S'
		
return @w_error
go








	

 









