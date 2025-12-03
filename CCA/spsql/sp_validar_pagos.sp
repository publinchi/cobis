/************************************************************************/
/*    Base de datos:          cob_cartera                               */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Javier calderon                         */
/*      Fecha de escritura:     27/06/2017                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                         PROPOSITO                                    */
/*      Tiene como propósito procesar los pagos de los corresponsales   */
/************************************************************************/
/*                            MODIFICACIONES                            */
/* Fecha              Autor                Descripcion                  */
/* 27/11/2017         MTA                  Se aumenta la operacion a la */
/*                                         tabla del log de pagos       */
/* 21/11/2018         SRO                  Referencias numéricas         */
/************************************************************************/
use cob_cartera
go

IF OBJECT_ID ('dbo.sp_validar_pagos') IS NOT NULL
    DROP PROCEDURE dbo.sp_validar_pagos
GO

create proc sp_validar_pagos(
    @i_referencia     varchar(64),
    @i_tipo           char(2),
    @i_codigo_int     varchar(10),
    @i_fecha_pago     varchar(8) = null,
    @i_monto_pago     varchar(14)= null,
    @i_archivo_pago   varchar(255),
    @o_tipo           char(2)    out ,
    @o_codigo_int     int        out ,
    @o_monto_pago     money      out,
    @o_fecha_pago     datetime   out
)
as
declare
@w_fecha_proceso           datetime,
@w_long_param              int,
@w_cadena                  varchar(50),
@w_grupo                   int,
@w_tipo                    char(1),
@w_codigo_interno          int,
@w_tramite_grupal          int,
@w_est_vigente             int,
@w_est_vencido             int,
@w_est_cancelado           int,
@w_est_credito             int,
@w_est_novigente           int,
@w_error                   int,
@w_msg                     varchar(255),
@w_secuencial              int,
@w_es_fecha                int,
@w_num_dec                 smallint,
@w_param_refsantander      int,
@w_param_refsantander_gar  int,
@w_long_ref                int,
@w_operacionca             int,
@w_cuenta                  varchar(24),
@w_precancela_dias         int,
@w_fecha_liq               datetime,
@w_fecha_ven               datetime


select @w_cuenta = ''
select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

select @w_param_refsantander = pa_int
from cobis..cl_parametro
where pa_nemonico = 'REFSTD'

if @@rowcount = 0
   select @w_param_refsantander = 15


select @w_param_refsantander_gar = pa_int
  from cobis..cl_parametro
 where pa_nemonico = 'RFSTDG'

if @@rowcount = 0
  select @w_param_refsantander_gar = 22

--FORMATO [MMDDAAAA]
set DATEFORMAT  mdy
select @w_es_fecha = isdate(substring(@i_fecha_pago,1,2) + '/'+ substring(@i_fecha_pago,3,2)+'/'+substring(@i_fecha_pago,5,4))

if isdate(substring(@i_fecha_pago,1,2) + '/'+ substring(@i_fecha_pago,3,2)+'/'+substring(@i_fecha_pago,5,4))=0
begin
    select @w_error = 70177,
           @w_msg   = 'ERROR: EL FORMATO DE LA FECHA DE PAGO ES INCORRECTO. ' +
                      'FECHA DE PAGO: ' + substring(@i_fecha_pago,1,2) + '/'+ substring(@i_fecha_pago,3,2)+'/'+substring(@i_fecha_pago,5,4)

    goto ERROR_FIN

end

select @o_fecha_pago = convert(datetime, substring(@i_fecha_pago,1,2) + '/'+ substring(@i_fecha_pago,3,2)+'/'+substring(@i_fecha_pago,5,4))


exec cob_cartera..sp_estados_cca
     @o_est_vigente   = @w_est_vigente out,
     @o_est_vencido   = @w_est_vencido out ,
     @o_est_cancelado = @w_est_cancelado out,
     @o_est_credito   = @w_est_credito out,
     @o_est_novigente = @w_est_novigente out


--  PG Pagos Grupales
--  GL Pagos por Garantías Líquidas
--  PI Pagos de Préstamos individuales
select @o_tipo   = case  
                     when @i_tipo in ('GL', 'PG', 'PI', 'CG','CI') then @i_tipo
                     else 'X'
                   end

if @o_tipo = 'X'
begin
   select
   @w_error = 70204, 
   @w_msg   = 'ERROR: TIPO DE REFERENCIA NO VALIDA'
   goto ERROR_FIN
end


begin try
   select @o_codigo_int = convert(int,@i_codigo_int)
end try
begin catch
   select
   @w_error = 70204,  
   @w_msg   = 'ERROR:CODIGO ID NO VALIDO'
   goto ERROR_FIN
end catch

if @o_tipo in ('GL', 'CI') -- garantia liquida y precancelacion
    select  @w_long_ref = @w_param_refsantander_gar
else
    select  @w_long_ref = @w_param_refsantander


-----------------------------------------
--PRECANCELACION OPERACIONES INDIVIDUALES
-----------------------------------------
if @o_tipo = 'CI'
begin
    select @w_precancela_dias = pa_int
    from  cobis..cl_parametro
    WHERE pa_nemonico = 'DIPRE'
    and  pa_producto = 'CCA'

    select @w_precancela_dias = isnull(@w_precancela_dias , 10)

    select @w_operacionca = isnull(op_operacion,0),
           @w_cuenta      = isnull(op_cuenta,''),
           @w_fecha_liq   = op_fecha_liq
    from cob_cartera..ca_operacion
    where op_operacion = @o_codigo_int
      and op_estado not in (@w_est_novigente, @w_est_cancelado)

    if @w_operacionca = 0
    begin
       select @w_error = 70186,
              @w_msg   = 'ERROR PRECANCELA: NO EXISTE EL CRÉDITO RELACIONADO A LA REFERENCIA O NO ACEPTA PAGOS.'
       goto ERROR_FIN
    end
    select @o_codigo_int = @w_operacionca

    -- control de fecha de pago
    select TOP 1 @w_fecha_ven = pr_fecha_ven
    from cob_cartera..ca_precancela_refer
    where pr_operacion = @w_operacionca
    ORDER BY pr_secuencial DESC

    -- VALIDAR SI PAGO LUEGO DE LA FECHA COMPROMETIDA
    if @o_fecha_pago > @w_fecha_ven
    begin
        select @w_error = 70214,
               @w_msg   = 'ERROR: PAGO REALIZADO FUERA DE TIEMPO (1 DIA O MENOS). ' +
                          'FECHA DE PAGO: ' + convert(varchar(10), @o_fecha_pago, 101) + ' ' +
                          'FECHA DE VENC: ' + convert(varchar(10), @w_fecha_ven , 101)
        goto ERROR_FIN
    end
    -- determinar la fecha valor del prestamo para realizar el pago
    IF datediff(dd, @w_fecha_liq, @o_fecha_pago) < @w_precancela_dias -- fecha de liquidacion
    begin
        select @o_fecha_pago = @w_fecha_liq
    end
    else  -- hace fecha valor a la fecha de pago
    begin
        select @o_fecha_pago = @o_fecha_pago
    end

end
--////////////////////////////////////////////////////////////////////////////////////

if datediff(dd,  @o_fecha_pago, @w_fecha_proceso)> 60
begin
    select @w_error = 70179,
           @w_msg   = 'ERROR: EL PAGO TIENE MS DE 60 DÍAS DE ANTIGUEDAD. ' +
                      'FECHA DE PAGO: ' + convert(varchar(10), @o_fecha_pago, 101)
    goto ERROR_FIN
end

if datediff(dd,  @o_fecha_pago, @w_fecha_proceso) <0
begin
    select @w_error = 70178,
           @w_msg   = 'ERROR: LA FECHA DE PAGO ES MAYOR A LA FECHA DE PROCESO. ' +
                      'FECHA DE PAGO: ' + convert(varchar(10), @o_fecha_pago, 101)
    goto ERROR_FIN

end

if len(@i_referencia) <> @w_long_ref
begin
    select @w_error = 70181,
           @w_msg   = 'ERROR: LA LONGITUD DE REFERENCIA NO ES VÁLIDA.'
    goto ERROR_FIN
end

if @i_monto_pago is null
begin
    select @w_error = 70190,
           @w_msg   = 'ERROR: EL VALOR DEL MONTO PAGADO ES NULO.'
    goto ERROR_FIN
end

begin try
   select @o_monto_pago = convert(money, @i_monto_pago)/100
end try
BEGIN catch
    select @w_error = 70182,
           @w_msg   = 'ERROR: EL MONTO DE PAGO NO ES VALIDO. ' +
                      'MONTO DE PAGO: ' + @i_monto_pago
    goto ERROR_FIN
END catch

if @o_monto_pago < 0
   begin
       select @w_error = 70185,
              @w_msg   = 'ERROR: EL MONTO DE PAGO DEBE SER POSITIVO. ' +
                         'MONTO DE PAGO: ' + @i_monto_pago
       goto ERROR_FIN
end



-------------------
--GARANTIA LIQUIDA
-------------------
if @o_tipo = 'GL'
begin

   if not exists (select 1 from cobis..cl_grupo where gr_grupo = @o_codigo_int)
   begin
      select
      @w_error = 70183,
      @w_msg   = 'ERROR: EL GRUPO DE LA REFERENCIA NO EXISTE.'
      goto ERROR_FIN
   end

   if not exists (select 1 from cob_workflow..wf_inst_proceso
                  where io_campo_1  = @o_codigo_int  --Nro del grupo
                  and io_campo_7    = 'S'
                  and io_campo_4    ='GRUPAL'
                  and    io_estado  = 'EJE') begin 

      select
      @w_error = 70184,
      @w_msg   = 'ERROR: NO EXISTE TRAMITE GRUPAL EN CURSO.'
      goto ERROR_FIN
    end 
      
end

-------------------
--OPE. INDIVIDUALES
-------------------
if @o_tipo = 'PI'
begin
   select @w_operacionca = isnull(op_operacion,0),
          @w_cuenta      = isnull(op_cuenta,'')
     from cob_cartera..ca_operacion
    where op_operacion = @o_codigo_int
      and op_estado not in (@w_est_novigente, @w_est_cancelado)

   if @w_operacionca = 0
   begin
      select @w_error = 70186,
             @w_msg   = 'ERROR: NO EXISTE EL CRÉDITO RELACIONADO A LA REFERENCIA O NO ACEPTA PAGOS.'
      goto ERROR_FIN
   end
   select @o_codigo_int = @w_operacionca
end

---------------------------------
--PAGO/CANCELACION OPE. GRUPALES
---------------------------------
if @o_tipo = 'PG' or @o_tipo = 'CG'
begin
    
   select @w_operacionca = isnull(max(ci_operacion),0)
          --@w_cuenta      = isnull(op_cuenta,'')
   from ca_det_ciclo , ca_ciclo , ca_operacion
   where dc_referencia_grupal =  ci_prestamo
   and op_operacion = dc_operacion
   and ci_grupo = @o_codigo_int
   and op_estado not in (@w_est_cancelado,@w_est_novigente)

   if @w_operacionca = 0
   begin
      select
      @w_error = 70186,
      @w_msg   = 'ERROR: NO EXISTEN CREDITOS RELACIONADOS A LA REFERENCIA O NO ACEPTAN PAGOS.'
      goto ERROR_FIN
   end

   select @o_codigo_int = @w_operacionca
end


return 0


ERROR_FIN:
   
   exec @w_secuencial = sp_gen_sec
        @i_operacion  = -5
   
   --Registro para Log pagos referenciados
   insert into cob_cartera..ca_santander_log_pagos
   (sl_secuencial, sl_fecha_gen_orden, sl_banco, sl_cuenta,
    sl_monto_pag,  sl_referencia,      sl_archivo,
    sl_tipo_error, sl_estado,          sl_mensaje_err, sl_ente)
   select @w_secuencial, @w_fecha_proceso, @w_operacionca, @w_cuenta, 
          (convert(money,@i_monto_pago)/100), @i_referencia, @i_archivo_pago, 
          'PR', convert(varchar,@w_error) , @w_msg, @o_codigo_int

    return @w_error
GO
