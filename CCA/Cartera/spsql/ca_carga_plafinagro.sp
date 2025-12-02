/************************************************************************/
/*  Archivo:            ca_carga_Plafinagro.sp                          */
/*  Stored procedure:   sp_carga_cambiolinea_finagro                    */
/*  Base de datos:      cob_credito                                     */
/*  Producto:           Cob_cartera                                     */
/*  Disenado por:       Elcira Pelaez                                  */
/*  Fecha de escritura: Dic.2014                                       */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA', representantes exclusivos para el Ecuador de la           */
/*  'NCR CORPORATION'.                                                  */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/* Este proceso  carga esde un plano entregado las operaciones que      */
/* seran objeto de cambio de linea de FINAGRO  a lineas diferentes      */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR          RAZON                                    */
/*  DIC.2014    Elcira Pelaez  Emision Inicial                          */
/*  ABR.2015    Julian Mendi   No se requiere tener garantia FAG para   */
/*                             permitir el cambio de linea RQ500 ATSK655*/
/*  AGO.2015    Julian Mendi   ATSK-1060.                               */  
/*                             Se generan dos archivos para reportar los*/
/*                             Mensaje, uno para el usuario final y otro*/
/*                             para soporte tecnico.                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_carga_cambiolinea_finagro')
   drop proc sp_carga_cambiolinea_finagro
go
---Jul.21.2015
create proc sp_carga_cambiolinea_finagro( 
@i_param1   datetime,   ---Fecha proceso
@i_param2   varchar(50) ---Archivo entegado por finagro
)
as       

declare  
@w_msg                       varchar(300),
@w_path                      varchar(250),
@w_file                      varchar(250),
@w_s_app                     varchar(250),
@w_sqr                       varchar(250),
@w_cmd                       varchar(250),
@w_bd                        varchar(250),
@w_tabla                     varchar(250),
@w_fecha_arch                varchar(10),
@w_comando                   varchar(1000),
@w_fuente                    varchar(250),
@w_errores                   varchar(250),
@w_path_s_app                varchar(250),
@w_sp_name                   varchar(250),
@w_error                     int,
@w_acciones                  int,
@w_acciones1                 int,
@w_fecha                     datetime,
@w_banco                     cuenta,
@w_lin_origen                catalogo,
@w_lin_destino               catalogo,
@w_identificacion            varchar(30),
@w_tipo_idet                 catalogo,
@w_en_tipo_ced               catalogo,
@w_com_des_fag               varchar(30),
@w_cod_pagare                varchar(30),
@w_operacion                 int,
@w_estado                    int,
@w_tramite                   int,
@w_archivo                   varchar(50),
@w_us_finagro                login,
@w_us_finagro1               login,
@w_us_finagro2               login,
@w_mes                       varchar(2),
@w_dia                       varchar(2),  
@w_anio                      varchar(4),   
@w_hora                      varchar(2),  
@w_minuto                    varchar(2),  
@w_segundo                   varchar(2),   
@w_fecha_archivo             datetime,   
@w_fecha1                    varchar(15)

   

select @w_sp_name = 'sp_carga_cambiolinea_finagro'
select @w_fecha   = @i_param1

select @w_fecha_archivo = getdate()

select @w_hora    = convert(varchar(2),datepart(hh,@w_fecha_archivo)), 
	    @w_minuto  = convert(varchar(2),datepart(mi,@w_fecha_archivo)), 
	    @w_segundo = convert(varchar(2),datepart(ss,@w_fecha_archivo))  

select @w_fecha1  = (right('00'+ @w_hora,2) + right('00'+ @w_minuto,2) + right('00'+ @w_segundo,2))


-------------------------------------------
--SRA: Lectura de Parametros Generales
-------------------------------------------

select @w_sqr        = 'cob_cartera..sp_carga_cambiolinea_finagro'

-- OBTIENE PATH DE EJECUCION
select @w_path_s_app = pa_char
from cobis..cl_parametro
where pa_nemonico = 'S_APP'
and   pa_producto = 'ADM'
if @w_path_s_app  is null
begin
    select @w_error = 710585,
           @w_msg   = 'NO SE ENCUENTRA EL s_app '
    goto ERROR
end    

-- OBTIENE PATH DESTINO
select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente = @w_sqr

if @w_path is null
begin
    select @w_error = 710585,
           @w_msg   = 'NO SE ENCUENTRA EL NRO DE BATCH CREADO en cobis..ba_batch'
    goto ERROR
end    

--NOMBRE DE USUARIO QUE SE GUARDA EN LA ca_errorlog
select @w_us_finagro1 = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'USLIFI'

if @@rowcount = 0
begin
    select @w_error = 708153,
    @w_msg   = 'ERROR PARAMETRO USLIFI NO EXISTE'
    goto ERROR
end

-- ATSK-1060
select @w_us_finagro2 = @w_us_finagro1 + '_USR'
select @w_us_finagro  = @w_us_finagro1

-- OBTIENE RUBRO DE DESEMBOLSO PARA FAG
select @w_com_des_fag = pa_char
from cobis..cl_parametro
where pa_nemonico = 'CMFAGD'
and   pa_producto = 'CCA'

if @@rowcount = 0
begin
    select @w_error = 708153,
    @w_msg   = 'ERROR PARAMETRO CMFAGD NO EXISTE'
    select @w_us_finagro = @w_us_finagro2    	
    goto ERROR
end

select @w_cod_pagare = pa_char
from cobis..cl_parametro
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODPAC'

if @@rowcount = 0
begin
    select @w_error = 708153,
    @w_msg   = 'ERROR PARAMETRO CODPAC NO EXISTE'
    select @w_us_finagro = @w_us_finagro2    	
    goto ERROR
end
 
select
   @w_s_app      =  's_app',
   @w_fecha_arch = convert(varchar(10), @w_fecha, 112),
   @w_cmd        = @w_s_app + ' bcp -auto -login ',
   @w_bd         = 'cob_cartera',
   @w_file       = @i_param2,  
   @w_tabla      = 'ca_oper_cambio_linea_FINAGRO',
   @w_fuente     = @w_path + @w_file ,
   @w_errores    = @w_path + 'CAMBIOLINFINA' + '_' + @w_fecha_arch + '.err',
   @w_archivo    = ltrim(rtrim(@i_param2))

       
---COPIA DE LA TABLA cob_cartera..ca_proc_cam_linea_finagro 
insert into cob_cartera..ca_proc_cam_linea_finagro_copy
select * 
from cob_cartera..ca_proc_cam_linea_finagro
where pc_estado = 'P'

if @@ERROR <> 0
begin
    select @w_error = 710585,
    @w_msg   = 'ERROR RESPALDANDO LA TABLA ca_proc_cam_linea_finagro'
    goto ERROR
end
   
delete from cob_cartera..ca_proc_cam_linea_finagro
where pc_estado = 'P'

if @@ERROR <> 0
begin
    select @w_error = 710585,
    @w_msg   = 'ERROR AL ELIMINAR OPERACIONES PROCESADAS DE ca_proc_cam_linea_finagro'
    goto ERROR
end

delete from cob_cartera..ca_errorlog
where er_usuario    = @w_us_finagro2

if @@ERROR <> 0
begin
    select @w_error = 710585,
    @w_msg   = 'ERROR AL ELIMINAR OPERACIONES REGISTRADAS ANTERIORMENTE EN EL LOG'
    goto ERROR
end
      
---VALIDAR EXISTENCIA DEL ARCHIVO DE CARGA EN LA TABLA DE COPIA
if exists (select 1 from  cob_cartera..ca_proc_cam_linea_finagro_copy
           where pc_archivo =   @w_archivo)
begin
    select @w_error = 710585,
    @w_msg   = 'EL ARCHIVO ' + @w_archivo + ' YA HA SIDO CARGADO POR FAVOR REVISAR'
    select @w_us_finagro = @w_us_finagro2    
    goto ERROR
end           

--- Proceso de carga del Archivo de Operaciones Entregadas
truncate table ca_oper_cambio_linea_FINAGRO
                                                                                                                                                                                       
select  @w_comando = @w_path_s_app + @w_cmd + @w_bd + '..' + @w_tabla + ' in ' + @w_fuente + ' -c -e' + @w_errores + ' -t"|" ' + '-config ' + @w_path_s_app + @w_s_app + '.ini'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 
begin
select @w_comando
    select @w_error = 710585,
    @w_msg   = 'ERROR CARGANDO PLANO ENTREGADO ' + cast(@w_fuente as varchar)
    select @w_us_finagro = @w_us_finagro2    
    goto ERROR
end

if exists (select 1 
           from ca_oper_cambio_linea_FINAGRO, ca_proc_cam_linea_finagro
           where banco_cobis = pc_banco_cobis)
begin
   
   delete ca_proc_cam_linea_finagro 
   from ca_oper_cambio_linea_FINAGRO, 
        ca_proc_cam_linea_finagro
   where banco_cobis = pc_banco_cobis

   if @@ERROR <> 0
   begin
      select @w_error = 710585,
      @w_msg   = 'ERROR ELIMINANDO OPERACIONES DE CARGA QUE YA EXISTIAN ' + cast(@w_archivo as varchar)
      select @w_us_finagro = @w_us_finagro2      
      goto ERROR
   end

   print 'SE ELIMINARON Y SE CARGARON NUEVAMENTE'

end
   
select 
banco    = banco_cobis, 
linea_or = linea_origen,   
linea    = linea_destino,
nro_ide  = identificacion,
tipo_ide = tipo_identificacion,
orden    =  ROW_NUMBER() OVER(ORDER BY banco_cobis)
into #tmp_CAMBIOLINFINAGRO
from ca_oper_cambio_linea_FINAGRO
order by banco_cobis

select @w_acciones = count(1) from #tmp_CAMBIOLINFINAGRO

select @w_acciones1 = 1
while  @w_acciones1 <= @w_acciones
begin
    select 
    @w_banco          = banco,
    @w_lin_origen     = linea_or,
    @w_lin_destino    = linea,
    @w_identificacion = nro_ide,
    @w_tipo_idet      = tipo_ide
   from #tmp_CAMBIOLINFINAGRO
   where  orden = @w_acciones1

   ---INICIO VALIDACION
   PRINT 'Operacion que va procesando es : ' + cast( @w_banco as varchar)

   --VALIDA SI LA OPERACION YA SE ENCUENTRA PROCESADA
   if exists (select 1 
           from ca_proc_cam_linea_finagro_copy 
           where pc_banco_cobis = @w_banco)
   begin
      select @w_msg   = 'LA OPERACION YA SE ENCUENTRA PROCESADA'
      select @w_error = 701025
      select @w_us_finagro = @w_us_finagro2
      goto ERROR_SIG
   end


   -- VALIDA ESTADO DE LA OPERACION
   select @w_operacion = op_operacion,
          @w_estado    = op_estado,
          @w_tramite   = op_tramite
   from cob_cartera..ca_operacion
	where op_banco = @w_banco
   if @@rowcount = 0
   begin
      select @w_msg = 'LA OPERACION  NO EXISTE  ' 
      select @w_error = 701016
      select @w_us_finagro = @w_us_finagro2            
      goto ERROR_SIG
   end
   
   ----VALIDACION DE ESTADO 
   if @w_estado not in (1,2,9)
   if @@rowcount = 0
   begin
      select @w_msg = 'LA OPERACION SE ENCUENTRA EN ESTADO NO VALIDO'
      select @w_error = 701016
      select @w_us_finagro = @w_us_finagro2            
      goto ERROR_SIG
   end
   
   --- VALIDA LINEA DESTINO
   if not exists (select 1 from ca_rubro
                  where ru_toperacion =   @w_lin_destino
                  ) 
   begin
      select @w_msg = 'LA LINEA DESTINO NO ESTA CREADA  - ' + @w_lin_destino
      select @w_error = 701025
      select @w_us_finagro = @w_us_finagro2            
      goto ERROR_SIG
   end


   if exists (select 1 from cobis..cl_catalogo c
              where c.tabla = (select codigo from cobis..cl_tabla t where t.tabla = 'ca_toperacion')
              and c.codigo = @w_lin_destino 
              and c.estado <> 'V')
   begin
      select @w_msg = 'LA LINEA DESTINO SE ENCUENTRA EN ESTADO NO VIGENTE  - ' + @w_lin_destino 
      select @w_error = 701025
      select @w_us_finagro = @w_us_finagro2               
      goto ERROR_SIG
   end

    if exists (select 1 from ca_default_toperacion 
              where dt_toperacion =  @w_lin_destino 
              and dt_estado  <> 'V')
   begin
      select @w_msg = 'LA LINEA DESTINO SE ENCUENTRA EN ESTADO NO VIGENTE  - ' + @w_lin_destino 
      select @w_error = 701025
      select @w_us_finagro = @w_us_finagro2               
      goto ERROR_SIG
   end

   if not exists (select 1 from cob_credito..cr_corresp_sib s, cobis..cl_tabla t, cobis..cl_catalogo c  
                       where s.descripcion_sib = t.tabla
                       and t.codigo            = c.tabla
                       and s.tabla             = 'T301'
                       and c.codigo            = @w_lin_origen
                       and c.estado            = 'V')
   begin
      select @w_msg = 'LA LINEA ORIGEN ENVIADA NO CORRESPONDE A LINEAS FINAGRO - ' + @w_lin_origen 
      select @w_error = 701025
      select @w_us_finagro = @w_us_finagro2            
      goto ERROR_SIG
   end

   if exists (select 1 from cob_credito..cr_corresp_sib s, cobis..cl_tabla t, cobis..cl_catalogo c  
                       where s.descripcion_sib = t.tabla
                       and t.codigo            = c.tabla
                       and s.tabla             = 'T301'
                       and c.codigo            = @w_lin_destino
                       and c.estado            = 'V')
    begin
      select @w_msg = 'LA LINEA DESTINO ENVIADA CORRESPONDE A LINEAS FINAGRO - ' + @w_lin_destino
      select @w_error = 701025
      select @w_us_finagro = @w_us_finagro2            
      goto ERROR_SIG
   end

   -- VALIDA EXISTENCIA IDENTIFICACION
   select @w_en_tipo_ced = en_tipo_ced 
   from cobis..cl_ente 
   where  en_ced_ruc = @w_identificacion

   if @@rowcount = 0
   begin
      select @w_msg = 'NUMERO DE IDENTIFICACION NO EXISTE  - ' + @w_identificacion
      select @w_error = 701025
      select @w_us_finagro = @w_us_finagro2            
      goto ERROR_SIG
   end

   -- VALIDA EXISTENCIA TIPO DE IDENTIFICACION
   if @w_en_tipo_ced <> @w_tipo_idet
   begin
      select @w_msg = 'TIPO DE IDENTIFICACION NO COINCIDE CON EL NUMERO DE IDENTIFICACION  - ' + @w_tipo_idet
      select @w_error = 701025
      select @w_us_finagro = @w_us_finagro2            
      goto ERROR_SIG
   end

   -- VALIDA EXISTENCIA CEDULA
   if not exists (select 1 from cobis..cl_ente ,ca_operacion 
                  where en_ced_ruc = @w_identificacion
                  and en_ente = op_cliente 
                  and op_operacion = @w_operacion
                  ) 
   begin
      select @w_msg = 'EL NUMERO DE IDENTIFICACION NO CORRESPONDE AL NUMERO DE OBLIGACION ENVIADO - ' + @w_identificacion
      select @w_error = 701025
      select @w_us_finagro = @w_us_finagro2            
      goto ERROR_SIG
   end

   insert into ca_proc_cam_linea_finagro(pc_archivo,        pc_tipo_ide,         pc_identificacion,         pc_banco_cobis,
                                         pc_linea_origen,   pc_linea_destino,    pc_tramite,                pc_fecha_proc,
                                         pc_estado,         pc_reverso_pagos,    pc_reverso_desem,          pc_retirar_gar,
                                         pc_cambio_linea,   pc_desembolso,       pc_aplica_pagos,           pc_monto_comision, 
                                         pc_iva_comision)

   values                               (@w_archivo,        @w_tipo_idet,        @w_identificacion,         @w_banco,
                                         @w_lin_origen,     @w_lin_destino,      @w_tramite,                @w_fecha,
                                         'I',               0,                   0,                         0,
                                         0,                 0,                   0,                         0,
                                         0)
   
   if @@error <> 0
   begin
      select @w_msg = 'ERROR AL INGRESAR  - ' + @w_banco
      select @w_error = 710371
      goto ERROR_SIG
   end
   
   goto SIGUIENTE
   
   ERROR_SIG:
      exec sp_errorlog 
      @i_fecha       = @w_fecha,
      @i_error       = @w_error,
      @i_usuario     = @w_us_finagro,
      @i_tran        = 7999,
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = @w_banco,
      @i_descripcion = @w_archivo,
      @i_anexo       = @w_msg,
      @i_rollback    = 'N'
      
      select @w_error = 0
      select @w_us_finagro = @w_us_finagro1
      
   SIGUIENTE:
   select @w_acciones1 = @w_acciones1 + 1

end

---VALIDAR LA CARGA EN TABLA DEFNITIVA
if not exists (select 1 from ca_proc_cam_linea_finagro)
begin
   select @w_error = 0
   select @w_us_finagro = @w_us_finagro1
   select @w_msg = 'NO SE CARGO NINGUN REGISTRO, REVISAR REPORTE DE ERRORES'
  goto ERROR
end

---FIN VALIDAR CARGA EN TABLA DEFINITIVA
    
return 0

ERROR:
   if @w_msg is null 
   begin
      select @w_msg = mensaje
      from cobis..cl_errores
      where numero = @w_error
   end

   PRINT  'Error ' + cast ( @w_msg as varchar)
   exec sp_errorlog 
   @i_fecha     = @w_fecha,
   @i_error     = @w_error,
   @i_usuario   = @w_us_finagro,
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = ' ',
   @i_descripcion = @w_archivo,
   @i_anexo       = @w_msg,
   @i_rollback  = 'N'

   exec sp_err_camlinfin @i_param1,'NULL'   

   select @w_error = 0
   return 1   
go
