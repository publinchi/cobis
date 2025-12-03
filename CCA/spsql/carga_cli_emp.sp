/*******************************************************************************/
/*  Archivo:             carga_cli_emp.sp                                      */
/*  Store Procedure:     sp_carga_cliente_emproblemado                         */
/*  Base de Datos:       cob_cartera                                           */
/*  Producto:            Cartera                                               */
/*  Diseñado por:        Pedro Rafael Montenegro Rosales                       */
/*  Fecha de Escritura:  16/Nov/2016                                           */
/*******************************************************************************/
/*                    IMPORTANTE                                               */
/*  Este programa es parte de los paquetes bancarios propiedad de "MACOSA",    */
/*  representantes exclusivos para el Ecuador de la "NCR CORPORATION".         */
/*  Su uso no autorizado queda expresamente prohibido asi como cualquier       */
/*  alteracion o agregado hecho por alguno de sus usuarios sin el debido       */
/*  consentimiento por escrito de la Presidencia Ejecutiva de MACOSA o su      */
/*  representante.                                                             */
/*******************************************************************************/
/*                     PROPOSITO                                               */
/* Carga de archivo de depositos, retiros, NC, ND                         */
/*******************************************************************************/
/*                         MODIFICACIONES                                      */
/* FECHA       AUTOR                            RAZON                          */
/* 16/Nov/2016 Pedro Rafael Montenegro Rosales  Emision Inicial                */
/*******************************************************************************/

use cob_cartera
go

if exists (select * from sysobjects where name = 'sp_carga_cliente_emproblemado')
   drop proc sp_carga_cliente_emproblemado
go

create proc sp_carga_cliente_emproblemado 
(    
   @t_show_version      bit              = 0,
   @i_param1            varchar(100)     = null,	--nombre archivo
   @i_param2            varchar(300)     = null		--ruta archivo
) 
as
declare  @w_sp_name           varchar(64),
         @w_s_app             varchar(64),
         @w_comando           varchar(4000),
         @w_ruta_archivo      varchar(500),
         @w_error             int,
         @w_mensaje           varchar(150),
         @w_contador          int,
         @w_fecha_proceso     datetime,
         @w_existe            int,
         @w_return            int,
         @w_id_archivo        int

/* TABLA DE ERRORES DE BCP*/
declare @resultadobcp table (linea varchar(max))

--Captura nombre de Stored Procedure.---------------
select @w_sp_name   =  'sp_carga_cliente_emproblemado'

---- VERSIONAMIENTO DEL PROGRAMA -------------------
if @t_show_version = 1
begin
   print 'Stored Procedure = ' + @w_sp_name + ' Version = 4.0.0.0'
   return 0
end

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

/***PARAMETRO S_APP***/
select @w_s_app = pa_char
   from cobis..cl_parametro
   where pa_producto = 'ADM'
   and pa_nemonico = 'S_APP'

/***RUTA DEL ARCHIVO***/
select @w_ruta_archivo = @i_param2 + @i_param1

if @w_ruta_archivo is null
begin
   select
      @w_mensaje = 'DEBE INGRESAR UN ARCHIVO Y UNA RUTA',
      @w_error = 724577
      goto ERROR
end

EXEC master.dbo.xp_fileexist @w_ruta_archivo, @w_existe OUT
IF @w_existe != 1
begin
   select
      @w_mensaje = 'NO EXISTE ARCHIVO MENCIONADO',
      @w_error = 724578
      goto ERROR
end

set nocount on
begin
   --TRANSACCIONES
   truncate table ca_cli_emproblemado_tmp

   select
         @w_comando = @w_s_app + 's_app' + ' bcp -auto -login cob_cartera..ca_cli_emproblemado_tmp in '
                 + @w_ruta_archivo +  ' -C -c -t"|" ' + '-config ' + @w_s_app + 's_app.ini'

   /* EJECUTAR CON CMDSHELL */
   delete from @resultadobcp
   insert into @resultadobcp
   exec xp_cmdshell
         @w_comando

   select @w_mensaje = null

   --SELECCIONA MENSAJE DE ERROR
   select top 1 @w_mensaje = upper(@i_param1) + ' ' + linea 
      from @resultadobcp 
      where linea LIKE 'Error%'

   --SELECCIONA CON %ERROR% SI NO ENCUENTRA EN EL FORMATO: ERROR = 
   if @w_mensaje is null
      select top 1 @w_mensaje = upper(@i_param1) + ' ' + linea 
         from @resultadobcp 
         where linea LIKE '%Error%'

   if @w_mensaje is not null
   begin
      select @w_error = 724579
      goto ERROR
   end

   select @w_contador = isnull(count(*),0) from cob_cartera..ca_cli_emproblemado_tmp
   if @w_contador = 0
   begin
      select
         @w_mensaje = 'NO HAY REGISTROS EN LA ca_cli_emproblemado_tmp ',
         @w_error = 724580
      goto ERROR
   end

   if exists (select 1 from cob_cartera..ca_arch_cli_emproblemado where ace_nombre_arch = @i_param1)
   begin
      select @w_existe = 1
      select @w_id_archivo = ace_archivo from cob_cartera..ca_arch_cli_emproblemado where ace_nombre_arch = @i_param1
   end
   else
   begin
      select @w_existe = 0
      
      exec @w_return = cobis..sp_cseqnos
            --@t_debug     = @t_debug,
            --@t_file      = @t_file,
            @t_from      = @w_sp_name,
            @i_tabla     = 'ca_arch_cli_emproblemado',
            @o_siguiente = @w_id_archivo out

      if @w_return > 0
      begin
         select @w_error = @w_return
         goto ERROR
      end
   end
   
   select @w_contador = isnull(max(ce_secuencia), 0) from cob_cartera..ca_cli_emproblemado where ce_cli_emp = @w_id_archivo
      
   if (@w_existe = 0)
   begin
      insert into cob_cartera..ca_arch_cli_emproblemado (ace_archivo, ace_nombre_arch, ace_usuario, ace_fec_proceso) 
                                                  values (@w_id_archivo, @i_param1, 'operador', getdate())

      if (@@error > 0)
      begin
         select @w_error = 724581
         goto ERROR
      end
   end
   else
   begin
      update cob_cartera..ca_arch_cli_emproblemado set ace_fec_act = getdate()
         where ace_archivo = @w_id_archivo

      if (@@error > 0 or @@rowcount <= 0)
      begin
         select @w_error = 724587
         goto ERROR
      end
   end   

   insert into cob_cartera..ca_cli_emproblemado (ce_cli_emp, ce_secuencia, ce_fecha, ce_ced_ruc, ce_nomlar, ce_ejecutor, ce_emproblemado)
      select @w_id_archivo, ROW_NUMBER() OVER(order by cet_fecha asc) + @w_contador, cet_fecha, cet_ced_ruc, cet_nomlar, cet_ejecutor, cet_emproblemado
         from cob_cartera..ca_cli_emproblemado_tmp
         where (convert(varchar, cet_fecha) + cet_ced_ruc + cet_nomlar) not in (select (convert(varchar, ce_fecha) + ce_ced_ruc + ce_nomlar) from cob_cartera..ca_cli_emproblemado where ce_cli_emp = @w_id_archivo)
   
   if (@@error > 0 or @@rowcount <= 0)
   begin
      select @w_error = 724582
      goto ERROR
   end
   
--INI AGI. 22ABR19.  Se comenta porque no existe el sp sp_valida_cliente_emproblemado
/*      
   exec @w_return = cob_cartera..sp_valida_cliente_emproblemado
      @t_show_version   = @t_show_version,
      @i_archivo_emp    = @w_id_archivo

   return @w_return
*/   --FIN AGI
end

return 0

ERROR:
exec cobis..sp_cerror
   @t_from = @w_sp_name,
   @i_num  = @w_error,
   @i_msg  = @w_mensaje
return @w_error
go
