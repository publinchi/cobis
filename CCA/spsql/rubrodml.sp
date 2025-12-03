/************************************************************************/
/*          Archivo:                        rubrodml.sp                 */
/*          Stored procedure:               sp_rubro_dml                */
/*          Base de datos:                  cob_cartera                 */
/*          Producto:                       Credito y Cartera           */
/*          Disenado por:                   Sandra Ortiz                */
/*          Fecha de escritura:             08/12/1993                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*                              PROPOSITO                               */
/*  Este programa maneja los rubros de una operacion                    */
/*  I: Insercion de rubro                                               */
/*  U: Actualizacion de rubro                                           */
/*  D: Eliminacion de rubro                                             */
/************************************************************************/
/*                             MODIFICACIONES                           */
/*  FECHA       AUTOR       RAZON                                       */
/*  08/26/1993  S. Estevez  Actualizacion tabla-rubro                   */
/*  09/24/1993  R. Minga V. Emision Inicial                             */
/*  06/07/1994  Peter Espinosa  Modificacion al nuevo modelo            */
/*  09/30/1994  Peter Espinosa  Nuevo codigo para Tran. Serv.           */
/*  03/03/1995  Fabian Espinosa Manejo del campo de tipo de             */
/*                  rubro y provision                                   */
/*  11/May/1999 XSA(CONTEXT)    Manejo de los campos de calculo         */
/*                  Saldo_Operacion y                                   */
/*                  Saldo_por_Desembolsar para los                      */
/*                  tipos de rubro CALCULADO.                           */
/*  21/04/2009   Jonnatan Peña     manejo de la tasa aplicadas          */
/*               validacion e insercion en la ca_rubro                  */
/*  05/11/2020  EMP-JJEC        Rubros Financiados                      */
/*  19/11/2020  EMP-JJEC        Control Tasa INT Maxima/Minima          */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rubro_dml')
    drop proc sp_rubro_dml
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_rubro_dml (
   @s_user                 login,
   @s_term                 varchar(30),
   @s_date                 datetime,
   @s_ofi                  smallint    = null,
   @t_debug                char(1)     = 'N',
   @t_file                 varchar(14) = null,
   @t_from                 descripcion = null,
   @i_operacion            char(2),
   @i_modo                 tinyint     = null,
   @i_toperacion           catalogo    = null,
   @i_moneda               tinyint     = null,
   @i_concepto             catalogo    = null,
   @i_valor                money       = null,
   @i_porcentaje           float       = null,
   @i_ptje_maximo          float       = null,
   @i_ptje_minimo          float       = null,
   @i_fecha_reg            datetime    = null,
   @i_funcionario          login       = null,
   @i_mora                 char (1)    = null,
   @i_fpago                char(1)     = null,
   @i_prioridad            tinyint     = 0,
   @i_trubro               char(1)     = null,
   @i_provisiona           char(1)     = null,
   @i_crear_siempre        char(1)     = null,
   @i_tperiodo             catalogo    = null,
   @i_periodo              smallint    = null,
   @i_referencial          catalogo    = null,
   @i_tasa_pit             catalogo    = null,
   @i_reajuste             catalogo    = null,
   @i_estado               char(1)     = null,
   @i_para_banco           char(1)     = null,
   @i_concepto_asociado    catalogo    = null,
   @i_redescuento          float       = null,
   @i_intermediacion       float       = null,
   @i_principal            char(1)     = 'N',
   @i_saldo_operacion      char(1)     = null,
   @i_saldo_por_desem      char(1)     = null,
   @i_limite               char(1)     = null,
   @i_mora_interes         char(1)     = null,
   @i_iva_siempre          char(1)     = null,
   @i_porcentaje_cobrar    float       = null,
   @i_monto_aprobado       char(1)     = null,
   @i_valor_garantia       char(1)     = null,
   @i_cober_garantia       char(1)     = null,
   @i_tipo_garantia        varchar(64) = null,
   @i_tabla                varchar(30) = null,
   @i_saldo_insoluto       char(1)     = null,
   @i_calcular_devolucion  char(1)     = null,
   @i_tasa_aplicar         char(1)     = null,
   @i_financiado           char(1)     = null,
   @i_tasa_maxima          float       = null,
   @i_tasa_minima          float       = null
)
as

declare
   @w_sp_name              descripcion,
   @w_return               int,
   @w_toperacion           catalogo,
   @w_moneda               tinyint,
   @w_concepto             catalogo,
   @w_mora                 char (1),
   @w_prioridad            tinyint,
   @w_fpago                char(1),
   @w_trubro               char(1),
   @w_provisiona           char(1),
   @w_crear_siempre        char(1),
   @w_tperiodo             catalogo,
   @w_periodo              smallint,
   @w_referencial          catalogo,
   @w_reajuste             catalogo,
   @w_para_banco           char(1),
   @w_estado               char(1),
   @w_concepto_asociado    catalogo,
   @w_clave1               varchar(255),
   @w_clave2               varchar(255),
   @w_clave3               varchar(255),
   @v_toperacion           catalogo,
   @v_moneda               tinyint,
   @v_concepto             catalogo,
   @v_valor                money,
   @v_porcentaje           float,
   @v_ptje_maximo          float,
   @v_ptje_minimo          float,
   @v_fecha_reg            datetime,
   @v_mora                 char (1),
   @v_prioridad            tinyint,
   @v_fpago                char(1),
   @v_trubro               char(1),
   @v_provisiona           char(1),
   @v_crear_siempre        char(1),
   @v_tperiodo             catalogo,
   @v_periodo              smallint,
   @v_referencial          catalogo,
   @v_reajuste             catalogo,
   @v_estado               char(1),
   @v_limite               char(1),
   @v_mora_interes         char(1),
   @v_tasa_aplicar         char(1),
   @w_redescuento          float,
   @w_intermediacion       float,
   @w_error                int,
   @w_limite               char(1),
   @w_mora_interes         char(1),
   @w_tperiodo_p           catalogo,
   @w_tasa_aplicar         char(1),
   @w_financiado           char(1),
   @v_financiado           char(1),
   @w_tasa_maxima          float,
   @w_tasa_minima          float,
   @v_tasa_maxima          float,
   @v_tasa_minima          float
   
/*  Inicializar nombre del stored procedure  */
select 
@w_sp_name = 'sp_rubro_dml'

select  
@w_redescuento = null,
@w_intermediacion = null


if @i_periodo is not null begin
   ---PRINT 'entro a actualizar tperiodo %1!',@i_periodo
   select @w_tperiodo_p = dt_tdividendo
   from ca_default_toperacion
   where dt_toperacion = @i_toperacion
   select @i_tperiodo = @w_tperiodo_p
end
else
select @i_tperiodo = null

/* ** Insert ** */
if @i_operacion = 'I' begin
   /* verificar que exista el tipo de operacion */
   exec @w_return = cobis..sp_catalogo
   @t_debug     = @t_debug,
   @t_file      = @t_file,
   @t_from      = @w_sp_name,
   @i_tabla     = 'ca_toperacion',
   @i_operacion = 'E',
   @i_codigo    = @i_toperacion

   /* si no existe, error */
   if @w_return != 0
   begin
      select @w_error = 101000 
      goto ERROR
   end

   /* verificar que exista la moneda */
   if not exists(select 1 from cobis..cl_moneda
                 where mo_moneda = @i_moneda)
   begin
   /* si no existe, error */
      select @w_error = 101045 
      goto ERROR
   end

   /* verificar que exista el concepto */
   if not exists(select 1 from ca_concepto
                 where co_concepto =  @i_concepto)
   begin
      select @w_error = 101000 
      goto ERROR
   end

   /*CONTROLAR SI LA OPERACION ESTA DEFINIDA COMO REAJUSTABLE ENTONCES DEBE
     INGRESAR EL VALOR A REAJUSTAR EN LOS RUBRO INTERES*/
   if exists(select 1
             from ca_default_toperacion
             where dt_toperacion  = @i_toperacion
             and   dt_moneda      = @i_moneda
             and   dt_reajustable = 'S')
   begin
      if @i_trubro = 'I' and @i_reajuste is null
      begin
         select @w_error = 710121
         goto ERROR 
      end 
   end
   
   begin tran

   insert into ca_rubro (
   ru_toperacion,           ru_moneda,             ru_concepto,
   ru_paga_mora,            ru_prioridad,          ru_fpago,
   ru_tipo_rubro,           ru_provisiona,         ru_crear_siempre,
   ru_tperiodo,             ru_periodo,            ru_referencial, 
   ru_reajuste,             ru_estado,             ru_banco,
   ru_concepto_asociado,    ru_redescuento,        ru_intermediacion,
   ru_principal,            ru_saldo_op,           ru_saldo_por_desem,
   ru_pit,                  ru_limite,             ru_mora_interes,
   ru_iva_siempre,          ru_porcentaje_cobrar,  ru_monto_aprobado,
   ru_tipo_garantia,        ru_valor_garantia,     ru_porcentaje_cobertura,
   ru_tabla,                ru_saldo_insoluto,     ru_calcular_devolucion,
   ru_tasa_aplicar,         ru_financiado,         ru_tasa_maxima,
   ru_tasa_minima)
   values (
   @i_toperacion,           @i_moneda,             @i_concepto,
   @i_mora,                 @i_prioridad,          @i_fpago,
   @i_trubro,               @i_provisiona,         @i_crear_siempre,
   @i_tperiodo,             @i_periodo,            @i_referencial,
   @i_reajuste,             @i_estado,             @i_para_banco,
   @i_concepto_asociado,    @i_redescuento,        @i_intermediacion,
   @i_principal,            @i_saldo_operacion,    @i_saldo_por_desem,
   @i_tasa_pit,             @i_limite,             @i_mora_interes,
   @i_iva_siempre,          @i_porcentaje_cobrar,  @i_monto_aprobado,
   @i_tipo_garantia,        @i_valor_garantia,     @i_cober_garantia,
   @i_tabla,                @i_saldo_insoluto,     @i_calcular_devolucion,
   @i_tasa_aplicar,         @i_financiado,         @i_tasa_maxima,
   @i_tasa_minima)

   /* si no se pudo insertar, error */
   if @@error != 0
   begin
      select @w_error = 703003 
      GOTO ERROR
   end


   select @w_clave1 = convert(varchar(255),@i_toperacion)
   select @w_clave2 = convert(varchar(255),@i_moneda)
   select @w_clave3 = convert(varchar(255),@i_concepto)
      
   exec @w_return = sp_tran_servicio
   @s_user    = @s_user,
   @s_date    = @s_date,
   @s_ofi     = @s_ofi,
   @s_term    = @s_term,
   @i_tabla   = 'ca_rubro',
   @i_clave1  = @w_clave1,
   @i_clave2  = @w_clave2,
   @i_clave3  = @w_clave3
      
   if @w_return != 0
   begin
      PRINT 'rubrodml.sp salio por error de sp_tran_servioio'
      select @w_error = @w_return   
      GOTO ERROR
   end

   commit tran

return 0

end

/* ** Update ** */
if @i_operacion = 'U'
begin
   /* seleccionar los datos anteriores */
   select @w_toperacion = ru_toperacion,
   @w_moneda            = ru_moneda,
   @w_concepto          = ru_concepto,
   @w_mora              = ru_paga_mora,
   @w_prioridad         = ru_prioridad,
   @w_fpago             = ru_fpago,
   @w_trubro            = ru_tipo_rubro,
   @w_provisiona        = ru_provisiona,
   @w_crear_siempre     = ru_crear_siempre,
   @w_tperiodo          = ru_tperiodo,
   @w_periodo           = ru_periodo,
   @w_referencial       = ru_referencial,
   @w_reajuste          = ru_reajuste,
   @w_estado            = ru_estado,
   @w_para_banco        = ru_banco,
   @w_concepto_asociado = ru_concepto_asociado,
   @w_redescuento       = ru_redescuento,
   @w_intermediacion    = ru_intermediacion,
   @w_limite            = ru_limite,
   @w_mora_interes      = ru_mora_interes,
   @w_tasa_aplicar      = ru_tasa_aplicar,
   @w_financiado        = ru_financiado,
   @w_tasa_maxima       = ru_tasa_maxima,
   @w_tasa_minima       = ru_tasa_minima
   from ca_rubro
   where  ru_toperacion = @i_toperacion
   and    ru_moneda     = @i_moneda
   and    ru_concepto   = @i_concepto

   /* si no existen datos anteriores, error */
   if @@rowcount = 0
   begin
      select @w_error = 701003      
      GOTO ERROR
   end

   /* guardar el dato anterior y el actual */
   select
   @v_mora          = @w_mora,
   @v_prioridad     = @w_prioridad,
   @v_fpago         = @w_fpago,
   @v_trubro        = @w_trubro,
   @v_provisiona    = @w_provisiona,
   @v_crear_siempre = @w_crear_siempre,
   @v_tperiodo      = @w_tperiodo,
   @v_periodo       = @w_periodo,
   @v_referencial   = @w_referencial,
   @v_reajuste      = @w_reajuste,
   @v_estado        = @w_estado,
   @v_limite        = @w_limite,
   @v_mora_interes  = @w_mora_interes,
   @v_tasa_aplicar  = @w_tasa_aplicar
               
   if @w_mora = @i_mora
      select @w_mora = null,
      @v_mora = null
   else
      select @w_mora = @i_mora

   if @w_prioridad = @i_prioridad
      select @w_prioridad = null,
      @v_prioridad = null
   else
      select  @w_prioridad = @i_prioridad

   if @w_fpago = @i_fpago
      select  @w_fpago = null,
      @v_fpago = null
   else
      select    @w_fpago = @i_fpago

   if @w_trubro = @i_trubro
      select    @w_trubro = null,
      @v_trubro = null
   else
      select  @w_trubro = @i_trubro
    
   if @w_provisiona = @i_provisiona
      select    @w_provisiona = null,
      @v_provisiona = null
   else
      select  @w_provisiona = @i_provisiona

   if @w_crear_siempre = @i_crear_siempre
      select    @w_crear_siempre = null,
      @v_crear_siempre = null
   else
      select    @w_crear_siempre = @i_crear_siempre

   if @w_toperacion = @i_toperacion
      select    @w_toperacion = null,
      @v_toperacion = null
   else
      select    @w_toperacion = @i_toperacion

   if @w_periodo = @i_periodo
      select    @w_periodo = null,
      @v_periodo = null
   else
      select    @w_periodo = @i_periodo

   if @w_referencial = @i_referencial
      select   @w_referencial = null,
      @v_referencial = null
   else
      select    @w_referencial = @i_referencial

   if @w_reajuste = @i_reajuste
      select    @w_reajuste = null,
      @v_reajuste = null
   else
      select    @w_reajuste = @i_reajuste

   if @w_estado = @i_estado
      select    @w_estado = null,
      @v_estado = null
   else
      select    @w_estado = @i_estado

   if @w_limite = @i_limite
      select    @w_limite = null,
      @v_limite = null
   else
      select    @w_limite = @i_limite


   if @w_mora_interes = @i_mora_interes
      select    @w_mora_interes = null,
      @v_mora_interes = null
   else
      select @w_mora_interes = @i_mora_interes

   if @w_tasa_aplicar = @i_tasa_aplicar
      select @w_tasa_aplicar = null,
      @v_tasa_aplicar = null
   else
      select  @w_tasa_aplicar = @i_tasa_aplicar

   if @w_financiado = @i_financiado
      select @w_financiado = null,
             @v_financiado = null
   else
      select  @w_financiado = @i_financiado

   if @w_tasa_maxima = @i_tasa_maxima
      select @w_tasa_maxima = null,
             @v_tasa_maxima = null
   else
      select @w_tasa_maxima = @i_tasa_maxima
      
   if @w_tasa_minima = @i_tasa_minima
      select @w_tasa_minima = null,
             @v_tasa_minima = null
   else
      select @w_tasa_minima = @i_tasa_minima


   /*CONTROLAR SI LA OPERACION ESTA DEFINIDA COMO REAJUSTABLE ENTONCES DEBE
   INGRESAR EL VALOR A REAJUSTAR EN LOS RUBRO INTERES*/
   /*AUMENTADO 01/01/98*/
   if exists(select 1
             from  ca_default_toperacion
             where dt_toperacion  = @i_toperacion
             and   dt_moneda      = @i_moneda
             and   dt_reajustable = 'S')
   begin
      if @i_trubro = 'I' and @i_reajuste is null 
      begin
         select @w_error = 710121
         goto ERROR
      end
   end
 
   begin tran

      select @w_clave1 = convert(varchar(255),@i_toperacion)
      select @w_clave2 = convert(varchar(255),@i_moneda)
      select @w_clave3 = convert(varchar(255),@i_concepto)

      exec @w_return = sp_tran_servicio
      @s_user    = @s_user,
      @s_date    = @s_date,
      @s_ofi     = @s_ofi,
      @s_term    = @s_term,
      @i_tabla   = 'ca_rubro',
      @i_clave1  = @w_clave1,
      @i_clave2  = @w_clave2,
      @i_clave3  = @w_clave3
    
      if @w_return != 0
      begin
         select @w_error = @w_return   
         GOTO ERROR
      end

      /* modificar con los nuevos datos */
      /*para BCO_ESTADO (campos ru_redescuento y ru_intermediacion)*/
      update ca_rubro
      set ru_paga_mora        = @i_mora,
      ru_prioridad            = @i_prioridad,
      ru_fpago                = @i_fpago,
      ru_tipo_rubro           = @i_trubro,
      ru_provisiona           = @i_provisiona,
      ru_crear_siempre        = @i_crear_siempre,
      ru_tperiodo             = @i_tperiodo,
      ru_periodo              = @i_periodo,
      ru_referencial          = @i_referencial,
      ru_pit                  = @i_tasa_pit,
      ru_reajuste             = @i_reajuste,
      ru_estado               = @i_estado,
      ru_banco                = @i_para_banco,
      ru_concepto_asociado    = @i_concepto_asociado,
      ru_redescuento          = @i_redescuento,
      ru_intermediacion       = @i_intermediacion,
      ru_principal            = @i_principal,
      ru_saldo_op             = @i_saldo_operacion,
      ru_saldo_por_desem      = @i_saldo_por_desem,
      ru_limite               = @i_limite,
      ru_mora_interes         = @i_mora_interes,
      ru_iva_siempre          = @i_iva_siempre,
      ru_porcentaje_cobrar    = @i_porcentaje_cobrar,
      ru_monto_aprobado       = @i_monto_aprobado,
      ru_tipo_garantia        = @i_tipo_garantia,
      ru_valor_garantia       = @i_valor_garantia,
      ru_porcentaje_cobertura = @i_cober_garantia,
      ru_tabla                = @i_tabla,
      ru_saldo_insoluto       = @i_saldo_insoluto,
      ru_calcular_devolucion  = @i_calcular_devolucion,
      ru_tasa_aplicar         = @i_tasa_aplicar,
      ru_financiado           = @i_financiado,
      ru_tasa_maxima          = @i_tasa_maxima,
      ru_tasa_minima          = @i_tasa_minima     
      where  ru_toperacion = @i_toperacion
      and    ru_moneda     = @i_moneda
      and    ru_concepto   = @i_concepto

      /* si no lo encuentra, error */
      if @@error != 0
      begin
         select @w_error = 705003      
         GOTO ERROR
      end

   commit tran
end

/* ** Delete ** */
if @i_operacion = 'D'
begin
   /* seleccionar los datos anteriores */
   select @w_toperacion = ru_toperacion,
   @w_moneda            = ru_moneda,
   @w_concepto          = ru_concepto,
   @w_mora              = ru_paga_mora,
   @w_prioridad         = ru_prioridad,
   @w_fpago             = ru_fpago,
   @w_trubro            = ru_tipo_rubro,
   @w_provisiona        = ru_provisiona,
   @w_crear_siempre     = ru_crear_siempre,
   @w_tperiodo          = ru_tperiodo,
   @w_periodo           = ru_periodo,
   @w_referencial       = ru_referencial,
   @w_reajuste          = ru_reajuste,
   @w_concepto_asociado = ru_concepto_asociado,
   @w_limite            = ru_limite,
   @w_tasa_aplicar      = ru_tasa_aplicar
   from ca_rubro
   where  ru_toperacion = @i_toperacion
   and    ru_moneda     = @i_moneda
   and    ru_concepto   = @i_concepto

   /* si no existen datos anteriores */
   if @@rowcount = 0
   begin
      select @w_error = 701003      
      GOTO ERROR
   end

   /* verificar que no existan rubro utilizados en operaciones,
   integridad referencial */
   if exists (select  1
      from    ca_rubro_op,ca_operacion
      where   op_toperacion = @i_toperacion
      and     op_moneda     = @i_moneda
      and     ro_operacion  = op_operacion
      and     ro_concepto   = @i_concepto )
   begin
      select @w_error = 701006      
      GOTO ERROR
   end

   begin tran
      /* borrar el rubro indicado */
      delete from ca_rubro
      where ru_toperacion = @i_toperacion
      and   ru_moneda     = @i_moneda
      and   ru_concepto   = @i_concepto

      /* si no lo puede borrar, error */
      if @@error != 0
      begin
         select @w_error = 707003      
         GOTO ERROR
      end

   commit tran

end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go
