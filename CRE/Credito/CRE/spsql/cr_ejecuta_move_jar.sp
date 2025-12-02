/************************************************************************/
/*  Archivo:                cr_ejecuta_move_jar.sp                      */
/*  Stored procedure:       sp_cr_ejecuta_move_jar                      */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
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
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_cr_ejecuta_move_jar')
    drop proc sp_cr_ejecuta_move_jar
go

create proc sp_cr_ejecuta_move_jar 
as
declare
   @w_sp_name     varchar(30),
   @w_numerr      int,
   @w_mensaje     varchar(255),
   @w_fecha       datetime,
   @w_comando     varchar(255),
   @w_path_from   varchar(100),
   @w_path_to     varchar(100),
   @w_path_bat    varchar(100),
   -- ---------------------------
   @w_primer_dia_def_habil  datetime,
   @w_primer_dia_mes  varchar(2),
   @w_primer_dia      varchar(10),
   @w_ciudad_nacional int,   
   @w_fecha_proc      datetime,
   @w_fecha_cierre	 datetime,
   @w_mes             varchar(2),
   @w_ano             varchar(4)


declare @resultadobcp table (linea varchar(max))

select @w_sp_name= 'sp_cr_ejecuta_move_jar'

select
   @w_path_bat = pp_path_fuente,   --C:\Cobis\VBatch\Credito\Objetos\
   @w_path_from = pp_path_destino + 'estctaext', --C:\Cobis\VBatch\Credito\listados\estctaext
   @w_path_to   = pp_path_destino + 'estctagen' --C:\Cobis\VBatch\Credito\listados\estctagen
from cobis..ba_path_pro 
where pp_producto = 21
if (@@error != 0 or @@rowcount != 1)
begin
   select 
      @w_numerr = 724627,
      @w_mensaje = 'ERROR CONSULTAR PATH PARA MOVER ARCHIVOS'
	goto ERRORFIN
end

-- CALCULO PARA DETERMINAR EL PRIMER DIA HABIL DEL MES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select @w_fecha_cierre   = fp_fecha from cobis..ba_fecha_proceso
select @w_primer_dia_mes = datepart(dd,dateadd(dd,1,dateadd(dd, datepart(dd,@w_fecha_cierre )*(-1),@w_fecha_cierre )))
select @w_mes 		       = datepart(mm, @w_fecha_cierre)
select @w_ano 		       = datepart(yy, @w_fecha_cierre)
select @w_primer_dia 	 = @w_mes + '/' + @w_primer_dia_mes + '/' + @w_ano 
select @w_primer_dia_def_habil  = convert(datetime, @w_primer_dia)

while exists(select 1 from cobis..cl_dias_feriados
          where df_ciudad = @w_ciudad_nacional
          and   df_fecha  = @w_primer_dia_def_habil ) begin
   select @w_primer_dia_def_habil = dateadd(day,1,@w_primer_dia_def_habil)
end
-- ---------------------------------------------------------------------------------------
--SI ES INICIO DE MES  SE EJECUTA
--if(@w_fecha_cierre = @w_primer_dia_def_habil)
--begin
   select @w_comando = 'move /y ' + @w_path_from + '\*.* ' + @w_path_to

   /* EJECUTAR CON CMDSHELL */
   delete from @resultadobcp

   insert into @resultadobcp exec xp_cmdshell @w_comando
   
   --SELECCIONA CON %ERROR% SI NO ENCUENTRA EN EL FORMATO: ERROR = 
   select top 1 @w_mensaje = linea
      from @resultadobcp 
      where upper(linea) LIKE upper('%Error%')
      and not (upper(linea) LIKE upper('%Error StatusLogger%'))
   if @w_mensaje is not null
   begin
       select
           @w_mensaje = 'ERROR EJECUTANDO MOVE FILES --> ' + @w_mensaje,
           @w_numerr = 724626      
       goto ERRORFIN
   end
--end

return 0

ERRORFIN:
   exec cobis..sp_cerror
      @t_debug	= 'N',                                                                                                                                                                                                        
      @t_file	= '',
      @t_from  = @w_sp_name,
      @i_num	= @w_numerr,
      @i_msg	= @w_mensaje
  
return @w_numerr


GO

