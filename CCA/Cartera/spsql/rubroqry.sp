/************************************************************************/
/*   Archivo:                          rubroqry.sp                      */
/*   Stored procedure:                 sp_rubro_qry                     */
/*   Base de datos:                    cob_cartera                      */
/*   Producto:                         Cartera                          */
/*   Disenado por:                     Sandra Ortiz                     */
/*   Fecha de escritura:               07/07/1994                       */
/************************************************************************/
/*                                     IMPORTANTE                       */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "COBIS".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante.                */
/************************************************************************/  
/*                                     PROPOSITO                        */
/*   Este programa realiza la busqueda normal y especifica de un        */
/*   rubro, asi como tambien genera ayuda de rubros.                    */
/************************************************************************/  
/*                                 MODIFICACIONES                       */
/*   FECHA      AUTOR      RAZON                                        */
/*   03/03/1995  Fabian Espinosa   Manejo de tipo de rubro y            */
/*               provisiones                                            */
/*   12/08/2005  Daniel Upegui     Consulta para devolucion de          */
/*               comisiones, operacion Q, tipo 6                        */
/*   21/04/2009  Jonnatan Peña     manejo de la tasa aplicadas          */
/*               validacion e insercion en la ca_rubro                  */
/*   12/05/2017  Jorge Salazar     CGS-S112643 PARAMETRIZACIÓN APF      */
/*   12/21/2021  Luis Ponce        CDIG Operaciones Pasivas             */
/*   03/08/2021  G. Fernandez      Obtencion de campo ru_financiado     */
/*   31/03/2022  K. Rodríguez      Listar todos los conceptos en mod 0y3*/
/*   06/07/2022  P. Jarrín         Listar rubro Op'S' estado'V' mod0,1,3*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rubro_qry')
   drop proc sp_rubro_qry
go

create proc sp_rubro_qry (
   @s_ssn         int          = null,
   @s_user        login        = null,
   @s_term        varchar (30) = null,
   @s_date        datetime     = null,
   @s_srv         varchar (30) = null,
   @s_lsrv        varchar (30) = null,
   @s_ofi         smallint     = null,
   @t_debug       char (1)     ='N',
   @t_file        varchar (14) = null,
   @t_from        descripcion  = null,
   @t_trn         smallint,
   @i_operacion   char (1),
   @i_tipo        char (1)     = null,
   @i_modo        tinyint      = null,
   @i_toperacion  catalogo     = null,
   @i_moneda      tinyint      = null,
   @i_concepto    catalogo     = ' ',
   @i_transaccion smallint     = null,
   @i_banco       cuenta       = null
)
as
declare 
   @w_sp_name               descripcion,
   @w_return                int,
   @w_operacionca           int,
   @w_moneda                smallint,
   @w_toperacion            catalogo,
   @w_concepto              catalogo,
   @w_valor                 float,
   @v_toperacion            catalogo,
   @v_concepto              catalogo,
   @w_descripcion1          descripcion,
   @w_descripcion2          descripcion,
   @w_descripcion3          descripcion,
   @w_descripcion4          descripcion,
   @w_descripcion5          descripcion,
   @w_descripcion6          descripcion,
   @w_descripcion7          descripcion,
   @w_desc_t_rubro          varchar(10),
   @w_desc_v_calculo        descripcion,
   @w_tperiodo              catalogo,
   @w_referencial           catalogo,
   @w_reajuste              catalogo,
   @w_pit                   catalogo,
   @w_paga_mora             char(1),
   @w_prioridad             tinyint,
   @w_fpago                 char(1),
   @w_tipo_rubro            char(1),
   @w_provisiona            char(1),
   @w_crear_siempre         char(1),
   @w_valor_calculo         char(1),
   @w_periodo               smallint,
   @w_signo_default         char(1),
   @w_valor_default         float,
   @w_signo_maximo          char(1),
   @w_valor_maximo          float,
   @w_signo_minimo          char(1),
   @w_valor_minimo          float,
   @w_valor_referencial     float,
   @w_total_default         float, 
   @w_total_maximo          float,
   @w_total_minimo          float,
   @w_tipo_valor            catalogo,
   @w_monto_calculo         money,
   @w_estado                char(1),
   @w_para_banco            char(1),
   @w_fecha_ini             datetime,
   @w_est_cancelado         catalogo,
   @w_est_vigente           catalogo,
   @w_extraord_cap          char(1),
   @w_anticipado_int        char(1),   
   @w_decimales             char(1),
   @w_num_dec               tinyint,
   @w_sector                catalogo,
   @w_rubro_asociado        catalogo,
   @w_redescuento           float,
   @w_intermediacion        float,
   @w_principal             char(1),
   @w_saldo_operacion       char(1),
   @w_saldo_por_desem       char(1),
   @w_limite                char(1),
   @w_mora_interes          char(1),
   @w_monto_aprobado        char(1),
   @w_porcentaje_cobrar     float,
   @w_tipo_garantia         varchar(64),
   @w_valor_garantia        char(1),
   @w_por_cobertura         char(1),
   @w_des_tipo_garantia     varchar(64),
   @w_des_tabla_tasa        varchar(64),
   @w_tabla_tasa            varchar(30),
   @w_saldo_insoluto        char(1),
   @w_categoria             char(1),
   @w_calcular_devolucion   char(1),
   @w_tasa_aplicar          char(1)

/*  Inicializar nombre del stored procedure  */
select @w_sp_name = 'sp_rubro_qry'

/* ** Search ** */
if @i_operacion = 'S'
begin
   set rowcount 20
/* traer los 20 primeros */
   if @i_modo = 0
   begin
      set rowcount 0  -- KDR Despliegue de todos los rubros a ingresar al préstamo
      select  
      'Codigo Rubro'     = ru_concepto,
      'Rubro'            = convert(varchar(30),co_descripcion),
      'Prioridad'        = ru_prioridad,
      'Paga Mora'        = ru_paga_mora,
      'Forma de Pago'    = ru_fpago,
      'Tipo de Rubro'    = ru_tipo_rubro,
      'Causa'            = ru_provisiona,
      'Default'          = ru_crear_siempre,
      'Valor Referencial'= ru_referencial, 
      'Valor Reajuste'   = ru_reajuste, 
      'Valor P.I.T.'     = ru_pit, 
      'Estado'           = ru_estado,
      'Para el Banco'    = ru_banco,
      'Rubro Asociado'   = ru_concepto_asociado,
      'Valida L¡mite'    = ru_limite,
      'Categoria'        = co_categoria,
      'Tasa aplicar'     = ru_tasa_aplicar,
      'Financiado'       = ru_financiado   --GFP obtencion de campo financiado
      from    ca_rubro, --cobis..cl_catalogo a, cobis..cl_tabla b, 
      ca_concepto   
      where   /*a.codigo      = ru_toperacion
      and     a.tabla       = b.codigo
      and     b.tabla       = 'ca_toperacion'
      and*/     co_concepto   = ru_concepto
      and     ru_toperacion = @i_toperacion
      and     ru_moneda     = @i_moneda
      and     ru_estado     = 'V'
      order by ru_toperacion, ru_moneda, ru_concepto
   end
   
   /* traer los siguientes, a partir del ultimo que se trajo */
   if @i_modo = 1
   begin
      select  
      'Codigo Rubro'      = ru_concepto,
      'Rubro'             = convert(varchar(30),co_descripcion),
      'Prioridad'         = ru_prioridad,
      'Paga Mora'         = ru_paga_mora,
      'Forma de Pago'     = ru_fpago,
      'Tipo de Rubro'     = ru_tipo_rubro,
      'Causa'             = ru_provisiona,
      'Default'           = ru_crear_siempre,
      'Valor Referencial' = ru_referencial, 
      'Valor Reajuste'    = ru_reajuste, 
      'Valor P.I.T.'      = ru_pit, 
      'Estado'            = ru_estado,
      'Para el Banco'     = ru_banco,
      'Rubro Asociado'    = ru_concepto_asociado,
      'Valida L¡mite'     = ru_limite,
      'Categoria'        = co_categoria,
      'Tasa aplicar'     = ru_tasa_aplicar,
      'Financiado'       = ru_financiado   --GFP obtencion de campo financiado
      from    ca_rubro, --cobis..cl_catalogo a, cobis..cl_tabla b,
      ca_concepto
      where /*a.codigo = ru_toperacion
      and   a.tabla = b.codigo
      and   b.tabla = 'ca_toperacion'
      and*/   co_concepto = ru_concepto
      and   ru_toperacion = @i_toperacion
      and   ru_moneda = @i_moneda
      and   ru_concepto > @i_concepto
      and   ru_estado     = 'V'
      order by ru_toperacion, ru_moneda, ru_concepto
   end

   if @i_modo = 3 begin
   
      set rowcount 0  -- KDR Despliegue de todos los rubros a ingresar al préstamo

      if @i_banco is not null
         select @w_operacionca = opt_operacion 
           from ca_operacion_tmp
          where opt_banco = @i_banco
     select
      'Codigo Rubro'     = ru_concepto,
      'Rubro'            = convert(varchar(30),co_descripcion),
      'Prioridad'        = ru_prioridad,
      'Paga Mora'        = ru_paga_mora,
      'Forma de Pago'    = ru_fpago,
      'Tipo de Rubro'    = ru_tipo_rubro,
      'Causa'            = ru_provisiona,
      'Default'          = ru_crear_siempre,
      'Valor Referencial'= ru_referencial, 
      'Valor Reajuste'   = ru_reajuste, 
      'Valor P.I.T.'     = ru_pit, 
      'Estado'           = ru_estado,
      'Para el Banco'    = ru_banco,
      'Rubro Asociado'   = ru_concepto_asociado,
      'Valida L¡mite'    = ru_limite,
      'Categoria'        = co_categoria,
      'Tasa aplicar'     = ru_tasa_aplicar,
      'Financiado'       = ru_financiado  --GFP obtencion de campo financiado
      from    ca_rubro,-- cobis..cl_catalogo a, cobis..cl_tabla b, 
      ca_concepto   
      where   /*a.codigo      = ru_toperacion
      and     a.tabla       = b.codigo
      and     b.tabla       = 'ca_toperacion'
      and*/     co_concepto   = ru_concepto
      and     ru_toperacion = @i_toperacion
      and     ru_moneda     = @i_moneda
      and     ru_concepto   not in (select rot_concepto from ca_rubro_op_tmp 
                                         where rot_operacion = @w_operacionca)
      and     exists (select rot_concepto from ca_rubro_op_tmp 
                                         where rot_operacion = @w_operacionca 
                                         and rot_concepto = ru_concepto_asociado or ru_concepto_asociado is null or ru_concepto_asociado = '') -- KDR15/10/2021 Se agrega filtro cadena vacía en ru_concepto_asociado 
      and     ru_estado     = 'V'
      order by ru_toperacion, ru_moneda, ru_concepto     
   end

      if @i_modo = 4 begin

      if @i_banco is not null
         select @w_operacionca = opt_operacion 
           from ca_operacion_tmp
          where opt_banco = @i_banco
     select
      'Codigo Rubro'     = ru_concepto,
      'Rubro'            = convert(varchar(30),co_descripcion),
      'Prioridad'        = ru_prioridad,
      'Paga Mora'        = ru_paga_mora,
      'Forma de Pago'    = ru_fpago,
      'Tipo de Rubro'    = ru_tipo_rubro,
      'Causa'            = ru_provisiona,
      'Default'          = ru_crear_siempre,
      'Valor Referencial'= ru_referencial, 
      'Valor Reajuste'   = ru_reajuste, 
      'Valor P.I.T.'     = ru_pit, 
      'Estado'           = ru_estado,
      'Para el Banco'    = ru_banco,
      'Rubro Asociado'   = ru_concepto_asociado,
      'Valida L¡mite'    = ru_limite,
      'Categoria'        = co_categoria,
      'Tasa aplicar'     = ru_tasa_aplicar,
      'Financiado'       = ru_financiado  --GFP obtencion de campo financiado
      from    ca_rubro, --cobis..cl_catalogo a, cobis..cl_tabla b, 
      ca_concepto   
      where   /*a.codigo      = ru_toperacion
      and     a.tabla       = b.codigo
      and     b.tabla       = 'ca_toperacion'
      and*/     co_concepto   = ru_concepto
      and     ru_toperacion = @i_toperacion
      and     ru_moneda     = @i_moneda
      and     (ru_concepto > @i_concepto or @i_concepto is null)
      and     exists (select rot_concepto from ca_rubro_op_tmp 
                                         where rot_operacion = @w_operacionca 
                                         and rot_concepto = ru_concepto_asociado or ru_concepto_asociado is null or ru_concepto_asociado = '') -- KDR15/10/2021 Se agrega filtro cadena vacía en ru_concepto_asociado 
      order by ru_toperacion, ru_moneda, ru_concepto   
   end

   set rowcount 0

   return 0
end

/* ** Query ** */
if @i_operacion = 'Q'
begin
   if @i_tipo = '1'
   begin
      select  
      @w_concepto             = ru_concepto,
      @w_descripcion1         = convert(varchar(30),co_descripcion),
      @w_paga_mora            = ru_paga_mora,
      @w_prioridad            = ru_prioridad,
      @w_fpago                = ru_fpago,
      @w_tipo_rubro           = ru_tipo_rubro,
      @w_provisiona           = ru_provisiona,
      @w_crear_siempre        = ru_crear_siempre,
      @w_tperiodo             = ru_tperiodo,
      @w_periodo              = ru_periodo,
      @w_referencial          = ru_referencial,
      @w_reajuste             = ru_reajuste,
      @w_pit                  = ru_pit,
      @w_estado               = ru_estado,
      @w_para_banco           = ru_banco,
      @w_rubro_asociado       = ru_concepto_asociado,
      @w_redescuento          = ru_redescuento,
      @w_intermediacion       = ru_intermediacion,
      @w_principal            = ru_principal,
      @w_saldo_operacion      = ru_saldo_op, 
      @w_saldo_por_desem      = ru_saldo_por_desem,
      @w_limite               = ru_limite,
      @w_mora_interes         = ru_mora_interes,
      @w_monto_aprobado       = ru_monto_aprobado,      -- LAMH   
      @w_porcentaje_cobrar    = ru_porcentaje_cobrar,   -- LAMH
      @w_tipo_garantia        = ru_tipo_garantia,
      @w_valor_garantia       = ru_valor_garantia,
      @w_por_cobertura        = ru_porcentaje_cobertura,
      @w_tabla_tasa           = ru_tabla,
      @w_saldo_insoluto       = ru_saldo_insoluto,  
      @w_categoria            = co_categoria,
      @w_calcular_devolucion  = ru_calcular_devolucion,
      @w_tasa_aplicar         = ru_tasa_aplicar
      from    ca_rubro, ca_concepto
      where   co_concepto   = ru_concepto
      and     ru_toperacion = @i_toperacion
      and     ru_moneda     = @i_moneda
      and     ru_concepto   = @i_concepto
      
      select @w_descripcion2 = td_descripcion
      from   ca_tdividendo
      where  td_tdividendo   = @w_tperiodo
      
      select @w_descripcion3 = va_descripcion
      from   ca_valor
      where  va_tipo = @w_referencial
      
      select @w_descripcion4 = valor
      from   cobis..cl_catalogo x, cobis..cl_tabla y 
      where  y.tabla  = 'cl_estado_ser'
      and    y.codigo = x.tabla
      and    x.codigo = @w_estado
      set transaction isolation level read uncommitted

      select @w_descripcion5 = va_descripcion
      from   ca_valor
      where  va_tipo = @w_reajuste

      select @w_descripcion7 = va_descripcion
      from   ca_valor
      where  va_tipo = @w_pit
     
      select @w_descripcion6 = co_descripcion
      from   ca_concepto
      where  co_concepto = @w_rubro_asociado

       
      select @w_des_tipo_garantia = tc_descripcion
      from   cob_custodia..cu_tipo_custodia
      where  tc_tipo = @w_tipo_garantia

      select @w_des_tabla_tasa = descripcion
      from   cobis..cl_tabla
      where  tabla = @w_tabla_tasa
      set transaction isolation level read uncommitted


      select @w_des_tipo_garantia = ltrim(rtrim(@w_des_tipo_garantia))

      select  
      @w_concepto,
      @w_descripcion1,
      @w_paga_mora ,
      @w_prioridad,
      @w_fpago,
      @w_tipo_rubro,
      @w_provisiona,
      @w_crear_siempre,
      '',                --@w_valor_calculo,
      @w_tperiodo,             --10
      @w_descripcion2,
      @w_periodo,
      @w_referencial,
      @w_descripcion3,
      @w_reajuste,
      @w_descripcion5,
      '',                --@w_deb_automatico,
      @w_estado,
      @w_descripcion4,
      @w_para_banco,          --20
      @w_rubro_asociado,
      @w_descripcion6,
      @w_redescuento,
      @w_intermediacion,
      @w_principal,
      @w_saldo_operacion,
      @w_saldo_por_desem,
      @w_pit,    
      @w_descripcion7,
      @w_limite,              --30
      @w_mora_interes,
      @w_monto_aprobado,
      @w_porcentaje_cobrar,
      @w_tipo_garantia,   
      @w_valor_garantia,  
      @w_por_cobertura,   
      @w_des_tipo_garantia, 
      @w_tabla_tasa,        
      @w_des_tabla_tasa,    
      @w_saldo_insoluto,     --40
      @w_categoria,          
      @w_calcular_devolucion,
      @w_tasa_aplicar 

   end

   if @i_tipo = '2'
   begin
      select
      'Rubro' = ru_concepto,
      'Descripcion' = convert(varchar(30),co_descripcion)
      from    ca_rubro, ca_concepto
      where   ru_concepto   <> @i_concepto 
      and     co_concepto   = ru_concepto
      and     ru_toperacion = @i_toperacion
      and     ru_moneda     = @i_moneda
      and     ru_fpago      <> 'B'
   end

   if @i_tipo = '3'
   begin
      select convert(varchar(30),co_descripcion)
      from    ca_rubro, ca_concepto
      where   ru_concepto   = @i_concepto 
      and     co_concepto   = ru_concepto
      and     ru_toperacion = @i_toperacion
      and     ru_moneda     = @i_moneda
      and     ru_fpago      <> 'B'
   end

   if @i_tipo = '4'  /*RUBRO ASOCIADO*/
   begin
      select
      'Rubro' = ru_concepto,
      'Descripcion' = convert(varchar(30),co_descripcion)
      from    ca_rubro, ca_concepto
      where   ru_concepto   <> @i_concepto 
      and     co_concepto   = ru_concepto
      and     ru_toperacion = @i_toperacion
      and     ru_moneda     = @i_moneda
      and     co_categoria in ('S','O','I')   ---ru_fpago      in ('L','A')
      and     ru_concepto_asociado is null
   end

   if @i_tipo = '5'
   begin
      select convert(varchar(30),co_descripcion)
      from    ca_rubro, ca_concepto
      where   ru_concepto   = @i_concepto 
      and     co_concepto   = ru_concepto
      and     ru_toperacion = @i_toperacion
      and     ru_moneda     = @i_moneda
      and     ru_fpago      in ('L','A')
      and     ru_concepto_asociado is null

   end

   if @i_tipo = '6'
   begin
      select 'Codigo Rubro'   = ro_concepto,
             'Rubro'          = convert(varchar(30),co_descripcion),
             'Valor'          = am_pagado,
             'Cliente'        = op_cliente,
             'LinCredito'     = op_toperacion
      from    ca_rubro_op R, ca_concepto,ca_amortizacion, ca_operacion O
      where   co_concepto   = ro_concepto
      and     ro_operacion  = op_operacion
      and     ro_concepto   = am_concepto
      and     op_operacion  = am_operacion
      and     op_banco      = @i_banco
      and     ro_fpago      = 'A'
      and     ro_tipo_rubro != 'I'
      and     am_dividendo  = 1
      and     not exists(select 1
                         from   ca_devolucion_rubro
                         where  dr_operacion = O.op_operacion
                         and    dr_concepto = R.ro_concepto)
      union
      select 'Codigo Rubro'   = ro_concepto,
             'Rubro'          = convert(varchar(30),co_descripcion),
             'Valor'          = ro_valor,
             'Cliente'        = op_cliente,
             'LinCredito'     = op_toperacion
      from    ca_rubro_op R, ca_concepto, ca_operacion O
      where   co_concepto   = ro_concepto
      and     ro_operacion  = op_operacion
      and     op_banco      = @i_banco
      and     ro_fpago      = 'L'
      and     ro_tipo_rubro != 'I'
      and     not exists(select 1
                         from   ca_devolucion_rubro
                         where  dr_operacion = O.op_operacion
                         and    dr_concepto = R.ro_concepto)
   end

   return 0
end


/* CONSULTA PARA CREDITO */
if @i_operacion = 'V' 
begin

   if substring(@i_banco,1,1) <> '-'  -- Operacion real

      select round(ro_valor +ro_porcentaje,2)
      from ca_rubro_op,ca_operacion
      where ro_concepto  = @i_concepto
      and op_banco     = @i_banco
      and op_operacion = ro_operacion

   else -- Operacion temporal

      select round(rot_valor +rot_porcentaje,2)
      from ca_rubro_op_tmp,ca_operacion_tmp
      where rot_concepto  = @i_concepto
      and opt_banco     = @i_banco
      and opt_operacion = rot_operacion

end

return 0
go
