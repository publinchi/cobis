/************************************************************************/
/*      Archivo:                ca_rep_finagro.sp                       */
/*      Stored procedure:       sp_rep_finagro                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Oskar Orozco                            */
/*      Fecha de escritura:     Nov 2014                                */
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
/*               Generacion archivo operaciones FINAGRO                 */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA                   AUTOR                   RAZON           */
/*      28/Nov/2014             Oskar Orozco            Emision Inicial */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_finagro')
   drop proc sp_rep_finagro 
go

create proc sp_rep_finagro (
@i_param1    datetime = NULL,     --FECHA DE PROCESO
@i_param2    char(1)              --TIPO DE REPORTE A = AGROPECUARIA  S = SUSTITUTIVA
)

as 
declare
@w_fecha           varchar(10),
@w_sp_name         varchar(30),
@w_error           int,
@w_maxreg          int,
@w_sec             int,
@w_mensaje         descripcion,
@w_toperacion      char(1),
--PARAMETROS PROPIOS DEL BCP
@w_s_app		    varchar(255),
@w_path			    varchar(255),
@w_nombre		    varchar(255),
@w_nombre_cab	    varchar(255),
@w_destino		    varchar(2500),
@w_errores		    varchar(1500),
@w_nombre_plano     varchar(2500),
@w_fecha1		    varchar(10),
@w_anio			    varchar(4),
@w_mes				varchar(2),
@w_dia				varchar(2),
@w_cmd              varchar(2500),
@w_columna		    varchar(100),
@w_cabecera		    varchar(2500),
@w_nom_tabla	    varchar(100),
@w_comando		    varchar(2500),
@w_col_id		    int

select @w_sp_name    = 'sp_rep_finagro',
       @w_fecha      = convert(varchar(10),@i_param1,101), 
	   @w_toperacion = @i_param2

--LIMPIANDO TABLAS
truncate table cob_cartera..ca_opera_finagro_temp

--OBTENIENDO FECHA DE PROCESO
if @w_fecha = ' ' or @w_fecha is null
begin
   select @w_fecha = convert(varchar(10),fp_fecha,101)
   from cobis..ba_fecha_proceso
end

--OBTENIENDO PARAMETRO DE MAXIMO NUMERO DE REGRISTROS PROCESADOS POR ARCHIVO
select @w_maxreg = pa_int
from cobis..cl_parametro
where pa_nemonico = 'REMRFI'
and   pa_producto = 'CRE'

-----------------------------------------------------------------------------------
--SE LLENAN LAS VARIABLES NECESARIAS PARA LA CREACION DEL BCP

--OBTENIENDO FECHA PARA GENERACIÓN DE ARCHIVO PLANO
select @w_anio  = convert(varchar(4),datepart(yyyy,@w_fecha)),
       @w_mes   = convert(varchar(2),datepart(mm,@w_fecha)), 
       @w_dia   = convert(varchar(2),datepart(dd,@w_fecha))        

select @w_fecha1  = (right('00' + @w_dia,2) + right('00' + @w_mes,2) + @w_anio)

--GENERAR BCP
select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

--GENERACIÓN DE LISTADO
select @w_path = pp_path_destino
from cobis..ba_path_pro 
where pp_producto  = 7 

--GENERAR ARCHIVO DE CABECERAS
select  @w_nombre       = 'repfinagro',
        @w_nom_tabla    = 'ca_opera_finagro_temp',
        @w_col_id       = 0,
        @w_columna      = '',
        @w_cabecera     = convert(varchar(2000), ''),
        @w_nombre_cab   = @w_nombre

--FIN DE LLENADO DE LAS VARIABLES NECESARIAS PARA LA CREACION DEL BCP
-----------------------------------------------------------------------------------

select @w_sec = 0

select of_pagare , of_procesado
into   #ciclo
from   cob_cartera..ca_opera_finagro, cob_credito..cr_corresp_sib
where  of_procesado = 'I'
and    of_lincre    = codigo
and    codigo_sib   = @w_toperacion
and    tabla        = 'T301'
and    of_ini_ope   = convert(varchar(10),convert(datetime, @w_fecha, 101), 103)
order by of_pagare

if @@rowcount = 0
begin
   goto NOREG
END

if @@error <> 0
begin
   print 'NO EXISTEN DATOS PARA PROCESAR, FAVOR VALIDAR'
   goto ERRORFIN
end
 
while 1=1
begin
   select @w_sec = @w_sec + 1
   
   set rowcount @w_maxreg
   
   --OBTENIENDO DATOS EN TABLA DEFINITIVA  
   insert into cob_cartera..ca_opera_finagro_temp
   select of_lincre,	          b.of_pagare,	                 of_ini_ope,		          of_ciudad,
          of_iden_cli,		      of_tipo_iden,	                 of_raz_social,	              of_monto_act,
          of_dir_cli,		      of_plazo,		                 of_fecha_pri_ven,            of_fecha_ven_final,
		  of_frec_cap,		      isnull(of_abono_cap,0),        isnull(of_periodo_gracia,0), of_frec_int,
		  isnull(of_abono_int,0), of_cap_total,       	         of_calc_tasa_tot,            of_prim_cuota_dsd,
		  of_prim_cuota_hst,	  isnull(of_valor_prim_cuota,0), of_inv_rubro,		          isnull(of_porcentaje_fag,0),
		  of_indicativo_fag,	  of_tipo_comision,	             of_val_act,		          of_fecha_balance,
		  of_fecha_act,		      of_dir_inversion,	             of_cod_oficina,	          of_telf_cli,
		  of_seg_cuota_dsd,	      of_seg_cuota_hst,	             of_valor_seg_cuota,          of_telf_cel_cli
   from   #ciclo a ,cob_cartera..ca_opera_finagro b 
   where  a.of_procesado = 'I'
   and    a.of_pagare    = b.of_pagare 
   
   if @@ERROR <> 0
   begin
      print 'ERROR AL INSERTAR EN TABLA cob_cartera..ca_opera_finagro_temp'
      goto ERRORFIN
   end    
   
   select 1 from cob_cartera..ca_opera_finagro_temp
   
   if @@rowcount = 0
   begin
      break
   end  
   
   update cob_cartera..ca_opera_finagro
   set    of_procesado = 'P'
   from cob_cartera..ca_opera_finagro_temp b, 
        cob_cartera..ca_opera_finagro a
   where a.of_pagare = b.Numero_de_pagare
   and   a.of_procesado = 'I'

   if @@ERROR <> 0
   begin
      print 'ERROR AL ACTUALIZAR LOS DATOS PROCESADOS EN TABLA cob_cartera..ca_opera_finagro'
      goto ERRORFIN
   end
     
   update #ciclo
   set    of_procesado = 'P'
   from cob_cartera..ca_opera_finagro_temp b, 
        #ciclo a
   where a.of_pagare = b.Numero_de_pagare
   and   a.of_procesado = 'I'

   if @@ERROR <> 0
   begin
      print 'ERROR AL ACTUALIZAR LOS DATOS PROCESADOS EN TABLA cob_cartera..ca_opera_finagro'
      goto ERRORFIN
   end

   ------------------------------------------------------------------
   --------------------------REALIZANDO BCP--------------------------
   ------------------------------------------------------------------						   
   select  @w_nombre_plano = @w_path + @w_nombre_cab + '_' + @w_toperacion + '_' + convert(varchar(5),@w_sec) +  '_'  + @w_fecha1 +'.txt'

   while 1 = 1 
   begin
      set rowcount 1
      select   @w_columna = c.name,
			   @w_col_id  = c.colid
      from cob_cartera..sysobjects o, cob_cartera..syscolumns c
      where o.id    = c.id
      and   o.name  = @w_nom_tabla
      and   c.colid > @w_col_id
      order by c.colid

      if @@rowcount = 0 
	  begin
	     set rowcount 0
		 break
	  end

      select @w_cabecera = @w_cabecera + @w_columna + '^|'
   end

   select @w_cabecera = left(@w_cabecera, datalength(@w_cabecera) - 2)

   --Escribir Cabecera
   select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano

   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 
   begin
      select @w_error    = 2902797, 
             @w_mensaje  = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
      goto ERRORFIN
   end

   --Ejecucion para Generar Archivo Datos
   select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_opera_finagro_temp out '

   select  @w_destino  = @w_path + 'repfinagro.txt',
		   @w_errores  = @w_path + 'repfinagro.err'
   				
   select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'				

   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 
   begin
      select @w_mensaje = 'ERROR GENERANDO REPORTE ' 
      goto ERRORFIN
   end

   ----------------------------------------
   --Union de archivos (cab) y (dat)
   ----------------------------------------

   select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'repfinagro.txt' + ' ' + @w_nombre_plano							
   exec @w_error = xp_cmdshell @w_comando
   	
   select @w_cmd = 'del ' + @w_destino 
   exec xp_cmdshell @w_cmd
                          
   if @w_error <> 0 
   begin
      select @w_error   = 2902797, 
             @w_mensaje = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
      goto ERRORFIN
   end
   	       
   delete from cob_cartera..ca_opera_finagro_temp WHERE Linea_de_credito >= 0
             
end

return 0

NOREG:
   -----------------------------------------------------------------------------------------------------
   --SE GENERA EL ARCHIVO .lis CUANDO NO EXISTEN REGISTROS PARA PROCESAR
   -----------------------------------------------------------------------------------------------------		   	     								   
   select  @w_nombre_plano = @w_path + @w_nombre_cab + '_' + 'X' + '_' + '1' +  '_'  + @w_fecha1 +'.lis'
   
   select @w_cabecera = 'No existen registros para procesar'       
   
   --Escribir Cabecera
   select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano
         
   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 
   begin
      select @w_error    = 2902797, 
             @w_mensaje  = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
      goto ERRORFIN
   end
return 0  --FIN NOREG


ERRORFIN:
   exec sp_errorlog 
   @i_fecha       = @w_fecha,
   @i_error       = @w_error, 
   @i_tran        = null,
   @i_usuario     = 'op_batch', 
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = '',
   @i_rollback    = 'N',
   @i_descripcion = @w_mensaje   
return 1

go
