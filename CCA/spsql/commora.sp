
use cob_cartera
go

/************************************************************************/
/*      Archivo:                commora.sp                              */
/*      Stored procedure:       sp_generar_commora                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Javier calderon                         */
/*      Fecha de escritura:     27/06/2017                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							                            */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                         PROPOSITO                                    */
/*      Tiene como prop=sito cargar la comision por mora en las         */
/*      operaciones grupales vencidas                                   */
/************************************************************************/
/*                              CAMBIOS                                 */
/*   FECHA             AUTOR             CAMBIO                         */
/*  MAR-2019         Lorena Regalado  Calculo CMO Operaciones Individ.  */
/*  SEP-2019         Lorena Regalado  Calcula CMO Operaciones Grupales  */
/************************************************************************/
  
  

if exists(select 1 from sysobjects where name = 'sp_generar_commora')
   drop proc sp_generar_commora
go

create proc sp_generar_commora
@i_param1              datetime    = null

as

declare
@w_sp_name        VARCHAR(30),
@w_error          INT,
@w_est_vencido    int,
@w_est_cancelado  int, 
@w_est_anulado    int, 
@w_moneda         TINYINT,
@w_num_dec        int,
@w_commora        catalogo,
@w_nem_cmora      catalogo,
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
@w_fecha_ini      datetime,
@w_ciudad_nacional  int,
@w_gracia_mora  int,
@w_tipo_mora    char(1),
@w_fecha_fin    datetime,
@w_num_reg      int,
@w_cont_commora int, 
@w_acum_commora money,
@w_tfactor           catalogo,  --LRE
@w_sector            catalogo,  --LRE
@w_valor_commora_def money,     --LRE
@w_operacion         int,       --LRE
@w_factor_conv       float,     --LRE
@w_tplazo            catalogo,  --LRE  
@w_ofi_oper          smallint,   --LRE
@w_est_novigente     smallint    --LRE

select 
@w_sp_name    = 'sp_generar_commora',
@w_moneda     = 0, -- Moneda Local
@w_commit     = 'N'

select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'


print 'fecha proceso: ' + cast(@w_fecha_proceso as varchar)

/* ESTADOS DE LA CARTERA */
exec @w_error   = sp_estados_cca
@o_est_vencido   = @w_est_vencido   out,
@o_est_cancelado = @w_est_cancelado out,
@o_est_anulado   = @w_est_anulado   out,
@o_est_novigente = @w_est_novigente out

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
SELECT @w_descripcion = 'Error !:No existe parametro para n˙mero de decimales'
goto ERRORFIN
end


/*NUMERO DE DIAS COMMORA*/
select @w_gracia_mora = pa_int
from cobis..cl_parametro
where pa_nemonico = 'NCMORA'
and   pa_producto = 'CCA'

if @@rowcount = 0 begin
   select @w_descripcion = 'Error !:No exite parametro general',
          @w_error = 70175
   goto ERRORFIN
end


select @w_gracia_mora = isnull(@w_gracia_mora, 0)


/********************************************/
--PROCESAR CRêDITOS INDIVIDUALES
--LRE 18/Mar/2019
/********************************************/

--LRE INI 
--Determinar Nemonico de la Comision Mora
select @w_nem_cmora = pa_char
from cobis..cl_parametro
where pa_nemonico = 'NCMO'
and   pa_producto = 'CCA'

if @@rowcount = 0 begin
   select @w_descripcion = 'Error !:No exite parametro general', 
          @w_error = 70175
   goto ERRORFIN
end

--CODIGO DEL FACTOR DE CONVERSION
select @w_tfactor = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'FACCON'

--LRE FIN 


--CONDICION DE SALIDA EN CASO DE DOBLE CIERRE POR FIN DE MES NO SE DEBE EJECUTAR
if exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_proceso )
begin
print 'Sale'
          return 0    

end

--HASTA ENCONTRAR EL HABIL ANTERIOR
select  @w_fecha_ini  = dateadd(dd,-1,@w_fecha_proceso)

--print 'fecha ini: ' + cast(@w_fecha_ini as varchar)


while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_ini ) 
   select @w_fecha_ini = dateadd(dd,-1,@w_fecha_ini)

select @w_fecha_fin = dateadd (dd,(@w_gracia_mora)*-1,@w_fecha_proceso)
select @w_fecha_ini = dateadd (dd,(@w_gracia_mora)*-1,@w_fecha_ini)

print 'FECHA INI: ' + cast(@w_fecha_ini as varchar)
print 'FECHA FIN: ' + cast(@w_fecha_fin as varchar)



/*DETERMINAR EL UNIVERSO DE OPERACIONES INDIVIDUALES */
select op_banco, op_operacion, di_dividendo, op_sector, op_tdividendo, op_toperacion, op_oficina
into #operaciones
from ca_operacion, ca_dividendo
where op_operacion           = di_operacion
and   di_estado              = @w_est_vencido
and   op_fecha_ult_proceso   = @w_fecha_proceso
and   (isnull(op_grupal, 'N') = 'N' or op_grupal = 'S' )  --LRE Se incluyen las operaciones grupales
and   di_fecha_ven         between @w_fecha_ini and @w_fecha_fin 
and   op_estado  not in (@w_est_cancelado,@w_est_anulado, @w_est_novigente)
ORDER BY op_operacion, di_dividendo


if @@error <> 0 begin
    select 
	@w_descripcion = 'ERROR AL CREAR UNIVERSO DE OPERACIONES A PROCESAR',
	@w_error = 710001
    goto ERRORFIN
END



declare cursor_operaciones cursor for 
SELECT op_banco, op_operacion, di_dividendo, op_sector, op_tdividendo, op_toperacion, op_oficina
FROM #operaciones
for read only

OPEN cursor_operaciones

fetch cursor_operaciones into @w_banco, @w_operacion, @w_di_dividendo, @w_sector, @w_tplazo, @w_toperacion, @w_ofi_oper

while @@fetch_status = 0  begin

   /* CONTROL PARA EVITAR REPROCESAR UNA OPERACION YA CARGADO CON COMMORA*/
   if exists (
   select 1 from ca_amortizacion 
   where am_operacion  = @w_operacion
   and   am_dividendo  = @w_di_dividendo 
   and   am_concepto   = @w_nem_cmora)

   begin
    goto SIGUIENTE_IND
   end
   
   /*DETERMINAR TASA DEL COMMORA */
   select
   @w_commora_ref   = ru_referencial
   from   ca_rubro
   where  ru_toperacion = @w_toperacion
   and    ru_moneda     = @w_moneda
   and    ru_concepto   = @w_nem_cmora

   if @@rowcount = 0 begin
      select 
      @w_descripcion = 'NO ESTA PARAMETRIZADO EL RUBRO COMMORA PARA ESTE TIPO DE OPERACION',
      @w_error = 701178
      goto ERRORFIN
   end


   /* DETERMINAR VALOR DE LA COMISION DE MORA */
   select 
   @w_valor_commora_def  = vd_valor_default 
   from   ca_valor, ca_valor_det
   where  va_tipo   = @w_commora_ref
   and    vd_tipo   = @w_commora_ref
   and    vd_sector = @w_sector

   if @@rowcount = 0 begin
      select 
	@w_descripcion = 'NO EXISTE TASA REFERENCIAL: '+@w_commora_ref,
	@w_error = 701085
      goto ERRORFIN
   end

   if @w_tfactor = '1'
      select @w_factor_conv = fc_esquema_1
      from ca_factor_conversion
      where fc_cod_frec = @w_tplazo
                                                                                                                                                                                                                 
   else
      select @w_factor_conv = fc_esquema_2
      from ca_factor_conversion
      where fc_cod_frec = @w_tplazo
                                                                                                                                                                                                                 
            
   /*if @w_tplazo = 'D' 
      select @w_factor_conv * @w_dias_div*/
                                                                                                                                                                                                                                                              
   select @w_valor_commora  = @w_valor_commora_def * @w_factor_conv  
   select @w_valor_commora  = round(@w_valor_commora, @w_num_dec)

                                                                                                                                                                                              
                    
      exec @w_error     = sp_otros_cargos
      @s_date           = @w_fecha_proceso,
      @s_user           = 'USER_CMO',
      @s_term           = 'TERM1',
      @s_ofi            = @w_ofi_oper,
      @i_banco          = @w_banco,
      @i_moneda         = @w_moneda, 
      @i_operacion      = 'I',
      @i_toperacion     = @w_toperacion,
      @i_desde_batch    = 'N',   
      @i_en_linea       = 'N',
      @i_tipo_rubro     = 'O',
      @i_concepto       = @w_nem_cmora, --@w_commora ,
      @i_monto          = @w_valor_commora,      
      @i_div_desde      = @w_di_dividendo,      
      @i_div_hasta      = @w_di_dividendo,
      @i_comentario     = 'GENERADO POR: sp_generar_commora'      
            
      if @w_error != 0  begin
         select @w_descripcion = 'Error ejecutando sp_otros_cargos por batch insertar COMMORA a la operacion : ' + @w_banco 
         goto ERRORFIN
      end
    
    
   if @w_commit = 'S' begin
      select @w_commit = 'N'
      commit tran
   end

   
   SIGUIENTE_IND:
   fetch next from cursor_operaciones into @w_banco, @w_operacion, @w_di_dividendo, @w_sector, @w_tplazo, @w_toperacion, @w_ofi_oper


end --WHILE CURSOR OPERACIONES

close cursor_operaciones
deallocate cursor_operaciones


return 0

ERRORFIN:

if @w_commit = 'S' begin
   select @w_commit = 'N'
   rollback tran
end


exec sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = @w_error,
@i_usuario     = 'usrbatch',
@i_tran        = 7999,
@i_tran_name   = @w_sp_name,
@i_cuenta      = @w_banco,
@i_descripcion = @w_descripcion, 
@i_rollback  = 'S'

return @w_error

go