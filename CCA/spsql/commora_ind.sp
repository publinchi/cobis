use cob_cartera
go

/************************************************************************/
/*      Archivo:                commora_ind.sp                          */
/*      Stored procedure:       sp_generar_commora_ind                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Javier calderon                         */
/*      Fecha de escritura:     27/06/2017                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							                      */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                         PROPOSITO                                    */
/*      Tiene como propósito cargar la comision por mora en las         */
/*      operaciones Individuales vencidas                               */
/************************************************************************/  
  

if exists(select 1 from sysobjects where name = 'sp_generar_commora_ind')
   drop proc sp_generar_commora_ind
go

create proc sp_generar_commora_ind
@i_param1              datetime    = null

as

declare
@w_sp_name        VARCHAR(30),
@w_error          INT,
@w_est_vencido    int,
@w_moneda         TINYINT,
@w_num_dec        int,
@w_commora        catalogo,
@w_commora_ref    catalogo,
@w_tasa_commora   FLOAT,
@w_fecha_proceso  DATETIME,
@w_di_dividendo   int,
@w_tg_grupo       int, 
@w_tg_referencia_grupal VARCHAR(15),
@w_cuota_grupal   MONEY,
@w_tot_commora    MONEY,
@w_total_vencido  MONEY,
@w_banco          VARCHAR(15),
@w_op_operacionca INT,
@w_cuota          MONEY,
@w_valor_commora  MONEY,
@w_descripcion    VARCHAR(60),
@w_commit         CHAR(1),
@w_toperacion     catalogo,
@i_fecha_proceso  DATETIME,
@i_oficina        int,
@w_oficina        smallint,
@w_operacion      int,
@w_ciudad_nacional int,
@w_fecha_ini      datetime 

select 
@w_sp_name    = 'sp_generar_commora_ind',
@w_moneda     = 0, -- Moneda Local
@w_commora    = 'COMMORA',
@w_commit     = 'N',
@w_toperacion = 'INDIVIDUAL'

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'


select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7



/* ESTADOS DE LA CARTERA */
exec @w_error   = sp_estados_cca
@o_est_vencido   = @w_est_vencido   out

if @w_error <> 0
begin 
SELECT @w_descripcion = 'Error !:No exite estado vencido'
goto ERRORFIN
end

--- NUMERO DE DECIMALES 
exec @w_error = sp_decimales
@i_moneda      = @w_moneda ,
@o_decimales   = @w_num_dec out

if @w_error <> 0
begin 
SELECT @w_descripcion = 'Error !:No existe parametro para número de decimales'
goto ERRORFIN
end


/*DETERMINAR TASA DEL COMMORA */
select
@w_commora_ref   = ru_referencial
from   ca_rubro
where  ru_toperacion = @w_toperacion
and    ru_moneda     = @w_moneda
and    ru_concepto   = @w_commora

if @@rowcount = 0 begin
   select 
   @w_descripcion = 'NO ESTA PARAMETRIZADO EL RUBRO COMMORA PARA ESTE TIPO DE OPERACION',
   @w_error       = 701178
   goto ERRORFIN
end

/* DETERMINAR LA TASA DE LA COMISION DE MORA */
select 
@w_tasa_commora  = vd_valor_default / 100
from   ca_valor, ca_valor_det
where  va_tipo   = @w_commora_ref
and    vd_tipo   = @w_commora_ref
and    vd_sector = 1 /* sector comercial */

if @@rowcount = 0 begin
    select 
	@w_descripcion = 'NO EXISTE TASA REFERENCIAL: '+@w_commora_ref,
	@w_error = 701085
    goto ERRORFIN
end
   

--CONDICION DE SALIDA EN CASO DE DOBLE CIERRE POR FIN DE MES NO SE DEBE EJECUTAR
if exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_proceso )
          return 0    
   
--HASTA ENCONTRAR EL HABIL ANTERIOR
select  @w_fecha_ini  = dateadd(dd,-1,@w_fecha_proceso)

while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_ini ) 
   select @w_fecha_ini = dateadd(dd,-1,@w_fecha_ini)   
   

/*DETERMINAR LAS OPERACIONES INDIVIDUALES A CARGAR LA COMISION DE MORA*/
select distinct op_operacion, op_banco, di_dividendo, op_oficina
into #individuales  
from cob_cartera..ca_operacion ,  cob_cartera..ca_dividendo
where op_operacion         = di_operacion
and   di_estado            = @w_est_vencido
and   op_fecha_ult_proceso = @w_fecha_proceso
and   op_toperacion        = @w_toperacion
and   di_fecha_ven         between @w_fecha_ini and  dateadd(dd,-1,@w_fecha_proceso)
ORDER BY op_operacion 

if @@error <> 0 begin
    select 
	@w_descripcion = 'ERROR AL CREAR UNIVERSO DE OPERACIONES INDIVUDUALES A PROCESAR',
	@w_error = 710001
    goto ERRORFIN
END
   
declare cursor_indiv cursor for 
SELECT op_operacion,  op_banco, di_dividendo, op_oficina
FROM #individuales
for read only

OPEN cursor_indiv

fetch cursor_indiv into @w_operacion, @w_banco , @w_di_dividendo, @w_oficina

while @@fetch_status = 0  begin

   select @w_cuota = sum(am_cuota) * @w_tasa_commora 
   from ca_amortizacion, ca_operacion
   where op_operacion = am_operacion
   and   am_dividendo = @w_di_dividendo
   and   op_operacion = @w_operacion
   and   am_concepto  = 'CAP'

   exec @w_error     = sp_otros_cargos
   @s_date           = @w_fecha_proceso,
   @s_user           = 'usrbatch',
   @s_term           = 'consola',
   @s_ofi            = @w_oficina,
   @i_banco          = @w_banco,
   @i_moneda         = @w_moneda, 
   @i_operacion      = 'I',
   @i_toperacion     = @w_toperacion,
   @i_desde_batch    = 'N',   
   @i_en_linea       = 'N',
   @i_tipo_rubro     = 'O',
   @i_concepto       = @w_commora ,
   @i_monto          = @w_cuota,      
   @i_div_desde      = @w_di_dividendo,      
   @i_div_hasta      = @w_di_dividendo,
   @i_comentario     = 'GENERADO POR: sp_generar_commora'      
         
   if @w_error != 0  begin
      select @w_descripcion = 'Error ejecutando sp_otros_cargos por batch insertar COMMORA a la operación : ' + @w_banco 
      goto ERROR    
   end
   
   GOTO SIGUIENTE
   
   ERROR:
   exec sp_errorlog 
   @i_fecha       = @i_param1,
   @i_error       = @w_error,
   @i_usuario     = 'usrbatch',
   @i_tran        = 7999,
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = @w_banco,
   @i_descripcion = @w_descripcion, 
   @i_rollback  = 'S'


SIGUIENTE:
   fetch  cursor_indiv into @w_operacion, @w_banco , @w_di_dividendo, @w_oficina
  

end --WHILE CURSOR INDIVIDUALES

close cursor_indiv
deallocate cursor_indiv

return 0 
ERRORFIN:

if @w_commit = 'S' begin
   select @w_commit = 'N'
   rollback tran
end

exec sp_errorlog 
@i_fecha       = @i_param1,
@i_error       = @w_error,
@i_usuario     = 'usrbatch',
@i_tran        = 7999,
@i_tran_name   = @w_sp_name,
@i_cuenta      = @w_banco,
@i_descripcion = @w_descripcion, 
@i_rollback  = 'S'

return 0

go