/******************************************************************/
/*  Archivo:            segurosindv.sp                            */
/*  Stored procedure:   sp_seguros_indv                           */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Jonathan Tomala                           */
/*  Fecha de escritura: 12-Jul-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Manejo de reglas                                           */
/*   - Creacion de Seguros                                        */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  12/Jul/19        Jonathan Tomala   Creacion sp Seguros indv   */
/*  27/Feb/20        Luis Ponce        CDIG. Quitar prints        */
/******************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_seguros_indv')
   drop proc sp_seguros_indv
go

create proc sp_seguros_indv
   @s_ssn                  int          = null,
   @s_date                 datetime     = null,
   @s_user                 login,
   @s_ofi                  smallint     = null,
   @t_trn                  int          = 77511,
   @i_opcion               char(1),
   @i_modo                 tinyint      = null,
   @i_cliente              int,
   @i_categoria            catalogo     = null,    --tipo seguro
   @i_monto_seguro         money        = null,
   @i_fecha_vig_ini        datetime     = null,
   @i_fecha_vig_fin        datetime     = null,
   @i_tramite              int          = null,
   @i_operacion            int          = null,
   @i_folio                varchar(64)  = null,
   @i_secuencial_trn       int          = null,
   @o_seguro_basico        char(1)      = null out,
   @o_seguro_voluntario    catalogo     = null out
as declare
   @w_sp_name                varchar(30),
   @w_error                  int,
   @w_fecha_vig_ini          datetime,
   @w_fecha_vig_fin          datetime,
   @w_operacion              int,
   @w_frecuencia             varchar(10),
   @w_plazo                  int,
   @w_seguro_basico          varchar(30),
   @w_variables              varchar(150),
   @w_regla                  varchar(60),
   @w_return_variable        VARCHAR(25),
   @w_return_results         VARCHAR(25),
   @w_last_condition_parent  VARCHAR(10),
   @w_precio_mensual         money,
   @w_monto_seguro           money

-- EVALUACION DE DATOS
select @w_operacion = @i_operacion,
       @w_fecha_vig_ini = @i_fecha_vig_ini,
       @w_fecha_vig_fin = @i_fecha_vig_fin
-- SI EXISTE TRAMITE ES PORQUE NO EXISTE OPERACION Y FECHAS, ENTONCES LAS RECUPERO CON EL TRAMITE
IF @i_tramite IS NOT NULL
BEGIN
   SELECT @w_operacion     = b.op_operacion,
          @w_fecha_vig_ini = b.op_fecha_ini,
          @w_fecha_vig_fin = b.op_fecha_fin,
          @w_frecuencia    = b.op_tdividendo,
          @w_plazo         = b.op_plazo
   FROM cob_credito..cr_tramite a
   INNER JOIN cob_cartera..ca_operacion b ON b.op_tramite = a.tr_tramite
   WHERE a.tr_tramite = @i_tramite
END

if @i_opcion in ( 'I' , 'U' , 'S' , 'D' )
begin
    select @w_seguro_basico = pa_char from cobis..cl_parametro where pa_nemonico = 'SGBASI'
end

if @i_opcion = 'I' or @i_opcion = 'U' -- Ingreso de Seguros
begin
    -- EVALUACION DE LAS REGLAS
    -- EVALUACION DE TIPO DE SEGURO
    -- OBTENGO SEGURO BASICO
-- print 'LLEGA POR AQUI'
    if @i_categoria = @w_seguro_basico
    begin
       select @w_variables = @w_frecuencia    + '|'            -- Frecuencia Plazo
                           + convert(VARCHAR,@i_monto_seguro)  -- Monto Rango
             ,@w_regla = 'PRSEGBASIC'
    end
    else
    begin
       select @w_variables = @w_frecuencia    + '|'    -- Frecuencia Plazo
                           + @i_categoria     + '|'    -- Tipo SEGURO
                           + convert(VARCHAR,@w_plazo) -- Plazo
             ,@w_regla = 'PRSEGVOLUN'
    end
    -- EJECUTO LA REGLA
    exec @w_error               = cob_pac..sp_rules_param_run
      @s_rol                   = 3,
      @i_rule_mnemonic         = @w_regla,
      @i_var_values            = @w_variables,
      @i_var_separator         = '|',
      @o_return_variable       = @w_return_variable  OUT,
      @o_return_results        = @w_return_results   OUT,
      @o_last_condition_parent = @w_last_condition_parent OUT
    -- EVALUO SI HUBO ERROR
    if @w_error <> 0
    begin
       goto ERROR
    end
-- print 'VALOR REGLA:[' + trim(@w_return_results) + '][' +  @w_variables + ']'
	
    -- GUARDO RESULTADO
    select @w_precio_mensual = convert(money, isnull(replace(@w_return_results,'|',''),0))
    --REALIZO EL CALCULO DE COSTO = PRECIO MENSUAL x PLAZO
    select @w_monto_seguro = isnull((@w_precio_mensual * @w_plazo),0)
    if @i_opcion = 'I'
    begin
        -- ELIMINO EL REGISTRO PARA QUE SEA REPROCESABLE
        if @i_categoria = @w_seguro_basico
        begin
            delete ca_seguros_op where so_operacion = @w_operacion and so_cliente = @i_cliente and so_tipo_seguro = @w_seguro_basico
        end
        else
        begin
            delete ca_seguros_op where so_operacion = @w_operacion and so_cliente = @i_cliente and so_tipo_seguro != @w_seguro_basico
        end

       -- Insert datos del Seguro
       insert cob_cartera..ca_seguros_op (
               so_cliente,        so_tipo_seguro,    so_monto_seguro,
               so_fecha_inicial,  so_operacion,      so_oper_padre,      so_user,
               so_ofi,            so_fecha_proceso,  so_folio,           so_estado,
               so_fecha_fin,      so_secuencial_trn)
       values (
               @i_cliente,        @i_categoria,      @w_monto_seguro,
               @w_fecha_vig_ini,  @w_operacion,      0,                  @s_user,
               @s_ofi,            @s_date,           @i_folio,           'I',
               @w_fecha_vig_fin,  @i_secuencial_trn)
    end

    if @@error <> 0
    begin
       select @w_error = 725049
       goto ERROR
    end
end

if  @i_opcion = 'Q' -- Consulta de Seguros
begin
   SELECT so_cliente,
          so_tipo_seguro,
          so_monto_seguro,
          so_fecha_inicial,
          so_operacion,
          so_oper_padre,
          so_fecha_proceso,
          so_folio, so_estado,
          so_fecha_fin,
          so_secuencial_trn
   FROM ca_seguros_op
   WHERE so_operacion = @w_operacion
   AND so_cliente = @i_cliente
end

if  @i_opcion = 'D' -- Eliminacion de Seguros
begin
    -- ELIMINO EL REGISTRO PARA QUE SEA REPROCESABLE
    if @i_categoria = @w_seguro_basico
    begin
        delete ca_seguros_op where so_operacion = @w_operacion and so_cliente = @i_cliente and so_tipo_seguro = @w_seguro_basico
    end
    else if @i_categoria = 'X'
    begin
        delete ca_seguros_op where so_operacion = @w_operacion and so_cliente = @i_cliente and so_tipo_seguro != @w_seguro_basico
    end
end

if  @i_opcion = 'S' -- Consulta si tene seguro
begin
    set @o_seguro_basico = 'N'
    set @o_seguro_voluntario = ''
    if exists( select 1 from ca_seguros_op where so_operacion = @w_operacion and so_cliente = @i_cliente and so_tipo_seguro = @w_seguro_basico )
    begin
        set @o_seguro_basico = 'S'
    end
    if exists( select 1 from ca_seguros_op where so_operacion = @w_operacion and so_cliente = @i_cliente and so_tipo_seguro != @w_seguro_basico )
    begin
        select  @o_seguro_voluntario = so_tipo_seguro
        from    ca_seguros_op
        where   so_operacion         = @w_operacion
        and     so_cliente           = @i_cliente
        and     so_tipo_seguro      != @w_seguro_basico
    end
end

return 0

ERROR:
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error

   return @w_error

go

