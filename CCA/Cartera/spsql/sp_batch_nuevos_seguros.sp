


/************************************************************************/
/*   Archivo:              sp_batch_nuevos_seguros.sp                   */
/*   Stored procedure:     sp_batch_nuevos seguros                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         SMO                                         */
/*   Fecha de escritura:   05/12/2017                                   */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Genera un archivo plano para reportar todos los préstamos que se   */
/*   haya logrado cobrar el seguro exitosamente                         */ 
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      05/12/2017     SMO             Emision Inicial                  */
/*   24/01/2018     Paúl Ortiz         Mejoras #93534 y #93610          */
/*   27/03/2018     María José Taco    Aumentar longitud de campos      */
/*   07/08/2018     SMO                Cambios en select #101737        */
/************************************************************************/
USE cob_cartera

GO

if object_id ('sp_batch_nuevos_seguros') is not null 
	drop proc sp_batch_nuevos_seguros
go

create proc sp_batch_nuevos_seguros 
	@i_param1  DATETIME = null 
as
declare
@w_sp_name             varchar(32),          
@w_path_destino        varchar(200), 
@w_s_app               varchar(40),
@w_cmd                 varchar(5000),
@w_destino             varchar(255),
@w_errores             varchar(255),
@w_comando             varchar(6000),
@w_error               int, 
@w_path                varchar(255),
@w_mensaje             varchar(100),
@w_nro_poliza          varchar(30),
@w_anio_poliza         int,
@w_producto            varchar(30),
@w_long_cobertura      int,
@w_seguro_vida         money,
@w_seguro_infarto_cer  money,
@w_seguro_infarto_mioc money,
@w_seguro_cancer       money,
@w_porc_comision       float,
@w_fecha_proc          datetime,
@w_fecha_fin         datetime,
@w_ffecha              int,
@w_pais                varchar(10),
@w_gen_arch_dom_seg   char(1),
@w_ciudad_nacional    int,
@w_fecha_ini    DATETIME
   

	create table  #seguros_nuevos(
	sn_nro_poliza          varchar (30) null,
	sn_anio_poliza         int          null,
	sn_producto            varchar (30) null,
	sn_ente                int          null,
	sn_buc                 varchar (20) null, 
	sn_sucursal            varchar (70) null,
	sn_nro_prestamo        varchar (24) null,
	sn_nro_certificado     varchar (36) null,
	sn_mes_emision         varchar (2)  null,
	sn_fecha_endoso        varchar (10) null,
	sn_fecha_efectiva      varchar (10) null,
	sn_fecha_expiracion    varchar (10) null,
	sn_long_cobertura      int          null,
	sn_pais                varchar (10) null,
	sn_moneda              varchar (10) null,
	sn_vendedor            varchar (10) null,
	sn_nombre_asegurado    varchar (40) null,
	sn_apellido_paterno    varchar (16) null,
	sn_apellido_materno    varchar (16) null,
	sn_direccion1          varchar (100)null,
	sn_direccion2          varchar (50) null,
	sn_ciudad              varchar (64) null,
	sn_estado              varchar (64) null,
	sn_cod_postal          varchar (30) null,
	sn_telefono            varchar (16) null,
	sn_email               varchar (254)null,
	sn_genero              CHAR (1)     null,
	sn_rfc                 varchar (30) null,
	sn_edad                int          null,
	sn_fecha_nac           varchar (10) null,
    sn_nombre_1            varchar (64) null,
    sn_rfc_1               varchar (30) null,
    sn_fecha_nac_1         varchar (10) null,
    sn_sexo_1              varchar (1) null,
    sn_porcentaje_1        varchar (45) null,
    sn_nombre_2            varchar (64) null,
    sn_rfc_2               varchar (30) null,
    sn_fecha_nac_2         varchar (10) null,
    sn_sexo_2              varchar (1) null,
    sn_porcentaje_2        varchar (45) null,
    sn_nombre_3            varchar (64) null,
    sn_rfc_3               varchar (30) null,
    sn_fecha_nac_3         varchar (10) null,
    sn_sexo_3              varchar (1) null,
    sn_porcentaje_3        varchar (45) null,
    sn_cta_banco           varchar (45) null,
	sn_seguro_vida         numeric(20,2) null,
	sn_seguro_infarto_cer  numeric(20,2) null,
	sn_seguro_infarto_mioc numeric(20,2) null,
	sn_seguro_cancer       numeric(20,2) null,
	sn_monto_prima         numeric(20,2) null,
	sn_comision            numeric(20,2) null,
	sn_direccion           varchar(255)  null
	)

select @w_sp_name             = 'sp_batch_nuevos_seguros'

select @w_fecha_proc          = fp_fecha from cobis..ba_fecha_proceso 
----------------select @w_fecha_proc  = '02/19/2019'

select @w_ffecha              = 103
select @w_nro_poliza          = pa_char  from cobis..cl_parametro where pa_nemonico='NROPOL' and pa_producto='CCA' if @@rowcount = 0 begin select @w_error = 101077 goto ERROR end
select @w_anio_poliza         = pa_int  from cobis..cl_parametro where pa_nemonico='ANIPOL' and pa_producto='CCA' if @@rowcount = 0 begin select @w_error = 101077 goto ERROR end
select @w_producto            = pa_char  from cobis..cl_parametro where pa_nemonico='SEGPRO' and pa_producto='CCA' if @@rowcount = 0 begin select @w_error = 101077 goto ERROR end
select @w_seguro_vida         = pa_money from cobis..cl_parametro where pa_nemonico='SVIDA'  and pa_producto='CCA' if @@rowcount = 0 begin select @w_error = 101077 goto ERROR end
select @w_seguro_infarto_cer  = pa_money from cobis..cl_parametro where pa_nemonico='SINFCE' and pa_producto='CCA' if @@rowcount = 0 begin select @w_error = 101077 goto ERROR end
select @w_seguro_infarto_mioc = pa_money from cobis..cl_parametro where pa_nemonico='SINFMI' and pa_producto='CCA' if @@rowcount = 0 begin select @w_error = 101077 goto ERROR end
select @w_seguro_cancer       = pa_money from cobis..cl_parametro where pa_nemonico='SCAN'   and pa_producto='CCA' if @@rowcount = 0 begin select @w_error = 101077 goto ERROR end
select @w_porc_comision       = pa_float from cobis..cl_parametro where pa_nemonico='COMSEG' and pa_producto='CCA' if @@rowcount = 0 begin select @w_error = 101077 goto ERROR end

select @w_long_cobertura      = 4

select @w_fecha_fin          = @w_fecha_proc
SELECT @w_pais = valor 
FROM cobis..cl_catalogo 
WHERE tabla = (SELECT codigo FROM cobis..cl_tabla WHERE tabla = 'cl_pais') 
AND codigo  = 484 --mexico


--PARAMETRO PARA INDICAR SI SE PAGA O NO EL SEGURO
select @w_gen_arch_dom_seg = pa_char
from   cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'GADOSE'   
   
select @w_gen_arch_dom_seg = isnull(@w_gen_arch_dom_seg, 'N')  

--CIUDAD DE FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

--CONDICION DE SALIDA EN CASO DE DOBLE CIERRE POR FIN DE MES NO SE DEBE EJECUTAR
if exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_fin )
          return 0 
		  
--ENCONTRAR DIA HABIL ANTERIOR
select @w_fecha_ini=dateadd(dd,-1,@w_fecha_fin)
while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_ini) 
   select @w_fecha_ini= dateadd(dd,-1,@w_fecha_ini)  

select  @w_fecha_ini  = dateadd(dd,1,@w_fecha_ini)

--print 'fecha_ini '+convert(varchar(10),@w_fecha_ini)
--print 'fecha_fin '+convert(varchar(10),@w_fecha_fin)


insert into #seguros_nuevos
select
sn_nro_poliza                 =    '',  
sn_anio_poliza                =    @w_anio_poliza,
sn_producto                   =    @w_producto,
sn_ente                       =    se_cliente,
sn_buc                        =    '',
sn_sucursal                   =    '',
sn_nro_prestamo               =    se_banco, 
sn_nro_certificado            =    se_banco, 
sn_mes_emision                =    '',--datepart(mm,@w_fecha_proc),
sn_fecha_endoso               =    '',
sn_fecha_efectiva             =    '',
sn_fecha_expiracion           =    '',
sn_long_cobertura             =    @w_long_cobertura, 
sn_pais                       =    @w_pais,
sn_moneda                     =    'MXN',
sn_vendedor                   =    '', 
sn_nombre_asegurado           =    '',
sn_apellido_paterno           =    '',
sn_apellido_materno           =    '',
sn_direccion1                 =    '',
sn_direccion2                 =    '', 
sn_ciudad                     =    '',
sn_estado                     =    '',
sn_cod_postal                 =    '',
sn_telefono                   =    '',
sn_email                      =    '',
sn_genero                     =    '',
sn_rfc                        =    '',
sn_edad                       =     0,
sn_fecha_nac                  =    '',

sn_nombre_1                   =    '',
sn_rfc_1                      =    '',
sn_fecha_nac_1                =    '',
sn_sexo_1                     =    '',
sn_porcentaje_1               =    '',

sn_nombre_2                   =    '',
sn_rfc_2                      =    '',
sn_fecha_nac_2                =    '',
sn_sexo_2                     =    '',
sn_porcentaje_2               =    '',

sn_nombre_3                   =    '',
sn_rfc_3                      =    '',
sn_fecha_nac_3                =    '',
sn_sexo_3                     =    '',
sn_porcentaje_3               =    '',

sn_cta_banco                  =    '',
sn_seguro_vida                =    round(@w_seguro_vida,2),
sn_seguro_infarto_cer         =    round(@w_seguro_infarto_cer,2),
sn_seguro_infarto_mioc        =    round(@w_seguro_infarto_mioc,2),
sn_seguro_cancer              =    round(@w_seguro_cancer,2),
sn_monto_prima                =    round(se_monto,2),
sn_comision                   =    round((se_monto*@w_porc_comision)/100,2),
sn_direccion                  =    ''
from cob_cartera..ca_seguro_externo 
where (se_estado='S' or @w_gen_arch_dom_seg = 'N')
and se_fecha_reporte is null --para que no reporte repetido las que ya se reportaron

--FECHAS
update #seguros_nuevos set 
sn_mes_emision       = CONVERT(varchar(2),datepart(mm,op_fecha_liq)),
sn_fecha_efectiva    = CONVERT(varchar(10), op_fecha_liq, @w_ffecha),
sn_fecha_expiracion  = CONVERT(varchar(10), dateadd(month,4,op_fecha_liq), @w_ffecha),
sn_sucursal          = convert(varchar, op_oficina),
sn_nro_poliza        = @w_nro_poliza + substring((convert(VARCHAR(10),op_fecha_liq,5)), 7, 2)  + '-'+substring((convert(VARCHAR(10),op_fecha_liq,5)), 4,2)  
from ca_operacion
where op_banco =  sn_nro_prestamo
                                 
--SUCURSAL
update #seguros_nuevos set
sn_sucursal = sn_sucursal +' '+of_nombre 
from cobis..cl_oficina
where of_oficina = convert( int, sn_sucursal)

--DIRECCIONES
select di_ente as ente, max(di_direccion) direccion
into #dir_actuales 
from cobis..cl_direccion
where di_tipo='RE'
and   di_ente in (select sn_ente from #seguros_nuevos)
group by di_ente
           
select 
di_ente        = di_ente,       
di_delegacion  = (select ltrim(rtrim(ci_descripcion)) from cobis..cl_ciudad    where ci_ciudad    = di_ciudad),    
di_estado      = (select ltrim(rtrim(pv_descripcion)) from cobis..cl_provincia where pv_provincia = di_provincia),
di_colonia     = (select ltrim(rtrim(pq_descripcion)) from cobis..cl_parroquia where pq_parroquia = di_parroquia),
di_poblacion   = isnull(di_poblacion , ''),
di_nro         = isnull(convert(varchar,di_nro),''),
di_nro_interno = isnull(convert(varchar,di_nro_interno),''),
di_codpostal   = isnull(di_codpostal,''),
di_calle       = isnull(di_calle,'')
into #direcciones
from cobis..cl_direccion,#dir_actuales
where di_ente = ente
and di_direccion = direccion

update #direcciones
set di_nro_interno = ''
where di_nro_interno in ('0' ,'-1')

update #direcciones
set di_nro = ''
where di_nro in ('0' ,'-1')

update #seguros_nuevos set
sn_direccion =   ltrim(rtrim(di_calle)) + 
                 case when di_nro_interno <>'' then  ' ' +  ltrim(rtrim(di_nro_interno))  else '' end +                          
                 case when di_nro <> '' then  ' ' + ltrim(rtrim(di_nro)) else '' end +
                 case when di_colonia <> '' then ' ' + ltrim(rtrim(di_colonia)) else '' end +
                 case when di_poblacion <> '' then ', '+ ltrim(rtrim(di_poblacion)) else '' end,              
sn_ciudad     = di_delegacion,
sn_estado     = di_estado,
sn_cod_postal = di_codpostal
from #direcciones
where sn_ente = di_ente  


update  #seguros_nuevos
set sn_direccion1 = substring(sn_direccion,1,50),
    sn_direccion2 = substring(sn_direccion,51,50)


--TELEFONOS
select te_ente as ente , max(te_secuencial) as secuencial
into #tel_actuales
from  cobis..cl_telefono 
where  te_tipo_telefono = 'D'
and    te_ente in(select sn_ente from  #seguros_nuevos)
group by te_ente 

select 
te_ente  = te_ente,
te_valor = te_valor   
into #telefonos
from cobis..cl_telefono, #tel_actuales
where te_ente       = ente 
and   te_secuencial = secuencial
		   
update #seguros_nuevos set
sn_telefono = te_valor 
from #telefonos
where sn_ente = te_ente 

--EMAIL 
select di_ente as ente, max(di_direccion) direccion
into #mail_actuales 
from cobis..cl_direccion
where di_tipo='CE'
and   di_ente in (select sn_ente from #seguros_nuevos)
group by di_ente		   
		   
select 
di_ente        = di_ente,       
di_mail        = di_descripcion
into #mails
from cobis..cl_direccion,#mail_actuales
where di_ente = ente
and di_direccion = direccion		   

update #seguros_nuevos set 
sn_email = di_mail
from #mails
where sn_ente = di_ente  		   
		   
		   
--DATOS DEL CLIENTE 		   
update 	#seguros_nuevos set 
sn_nombre_asegurado    =  isnull(en_nombre,'')+' '+isnull(p_s_nombre,''),  	   
sn_apellido_paterno    =  isnull(p_p_apellido,''),  		   
sn_apellido_materno    =  isnull(p_s_apellido,''),
sn_genero              =  isnull(p_sexo,''),          
sn_rfc                 =  isnull(en_rfc,''),                  		   
sn_edad                =  datediff(year, isnull(p_fecha_nac,@w_fecha_proc), @w_fecha_proc),             		   
sn_fecha_nac           =  convert(varchar(10), isnull(p_fecha_nac,@w_fecha_proc), @w_ffecha),   		   
sn_buc                 =  convert(varchar,en_ente)
from cobis..cl_ente 
where en_ente = sn_ente 	   
		   
---alter table #seguros_nuevos drop column sn_ente --ELIMINAR COLUMNA QUE NO ES PARTE DEL REPORTE

/* INSERTAR EN LA TABLA DEFINITIVA PARA EL BCP */
TRUNCATE TABLE ca_seguros_nuevos

INSERT into ca_seguros_nuevos(
sn_nro_poliza          ,sn_anio_poliza         ,sn_producto            ,sn_buc                 ,
sn_sucursal            ,sn_nro_prestamo        ,sn_nro_certificado     ,sn_mes_emision         ,
sn_fecha_endoso        ,sn_fecha_efectiva      ,sn_fecha_expiracion    ,sn_long_cobertura      ,
sn_pais                ,sn_moneda              ,sn_vendedor            ,sn_nombre_asegurado    ,
sn_apellido_paterno    ,sn_apellido_materno    ,sn_direccion1          ,sn_direccion2          ,
sn_ciudad              ,sn_estado              ,sn_cod_postal          ,sn_telefono            ,
sn_email               ,sn_genero              ,sn_rfc                 ,sn_edad                ,
sn_fecha_nac           ,sn_seguro_vida         ,sn_seguro_infarto_cer  ,sn_seguro_infarto_mioc ,
sn_seguro_cancer       ,sn_monto_prima         ,sn_comision            ,
sn_nombre_1            ,sn_rfc_1               ,sn_fecha_nac_1         ,
sn_sexo_1              ,sn_porcentaje_1        ,sn_nombre_2            ,
sn_rfc_2               ,sn_fecha_nac_2         ,sn_sexo_2              ,
sn_porcentaje_2        ,sn_nombre_3            ,sn_rfc_3               ,
sn_fecha_nac_3         ,sn_sexo_3              ,sn_porcentaje_3        ,
sn_cta_banco           
)
SELECT 
sn_nro_poliza          ,sn_anio_poliza         ,sn_producto            ,sn_buc                 ,
sn_sucursal            ,sn_nro_prestamo        ,sn_nro_certificado     ,sn_mes_emision         ,
sn_fecha_endoso        ,sn_fecha_efectiva      ,sn_fecha_expiracion    ,sn_long_cobertura      ,
sn_pais                ,sn_moneda              ,sn_vendedor            ,sn_nombre_asegurado    ,
sn_apellido_paterno    ,sn_apellido_materno    ,sn_direccion1          ,sn_direccion2          ,
sn_ciudad              ,sn_estado              ,sn_cod_postal          ,sn_telefono            ,
sn_email               ,sn_genero              ,sn_rfc                 ,sn_edad                ,
sn_fecha_nac           ,sn_seguro_vida         ,sn_seguro_infarto_cer  ,sn_seguro_infarto_mioc ,
sn_seguro_cancer       ,sn_monto_prima         ,sn_comision            ,
sn_nombre_1            ,sn_rfc_1               ,sn_fecha_nac_1         ,
sn_sexo_1              ,sn_porcentaje_1        ,sn_nombre_2            ,
sn_rfc_2               ,sn_fecha_nac_2         ,sn_sexo_2              ,
sn_porcentaje_2        ,sn_nombre_3            ,sn_rfc_3               ,
sn_fecha_nac_3         ,sn_sexo_3              ,sn_porcentaje_3        ,
sn_cta_banco           
FROM #seguros_nuevos 
	   				
select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'
	
	
select @w_path = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 7
		
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_seguros_nuevos out '

select 
@w_destino  = @w_path + 'SEGUROS_TUIIO_' +  replace(CONVERT(varchar(10), @w_fecha_proc, @w_ffecha),'/', '')+ '.txt',
@w_errores  = @w_path + 'SEGUROS_TUIIO_' +  replace(CONVERT(varchar(10), @w_fecha_proc, @w_ffecha),'/', '')+ '.err'

select @w_comando = @w_cmd + @w_destino+ ' -b5000 -w -T -e ' + @w_errores + ' -t"|" ' + '-config ' + @w_s_app + 's_app.ini'

PRINT ' CMD: ' + @w_comando 

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select
   @w_error = 724679,
   @w_mensaje = 'Error generando Archivo de Nuevos Seguros'
   goto ERROR
end
  	
update cob_cartera..ca_seguro_externo 
set se_fecha_reporte = @w_fecha_proc
from #seguros_nuevos
where se_banco = sn_nro_prestamo

return 0  
 
ERROR:
exec cobis..sp_errorlog 
@i_fecha        = @w_fecha_proc,
@i_error        = @w_error,
@i_usuario      = 'usrbatch',
@i_tran         = 26004,
@i_descripcion  = @w_mensaje,
@i_tran_name    =null,
@i_rollback     ='S'
return @w_error

go
